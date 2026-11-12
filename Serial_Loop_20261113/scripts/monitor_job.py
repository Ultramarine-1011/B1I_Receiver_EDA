"""Bound one tool process group and preserve its actual exit and resource log.

Python 2.7/3, adapted from the existing V6 supervisor. RSS_LIMIT_KIB is optional.
"""
from __future__ import print_function
import atexit
import csv
import json
import os
import signal
import subprocess
import sys
import time

report = os.path.abspath(sys.argv[1])
budget = float(sys.argv[2])
rss_limit = int(os.environ.get("RSS_LIMIT_KIB", "8388608"))
os.makedirs(report)


def now():
    with open("/proc/uptime") as stream:
        return float(stream.read().split()[0])


def descendants(parent):
    rows = []
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        try:
            with open("/proc/" + entry + "/stat") as stream:
                raw = stream.read()
            fields = raw[raw.rfind(")") + 2:].split()
            rows.append((int(entry), int(fields[1]), int(fields[2])))
        except (IOError, OSError):
            continue
    selected = set([parent])
    previous_size = -1
    while previous_size != len(selected):
        previous_size = len(selected)
        selected.update(row[0] for row in rows if row[1] in selected)
    return [row for row in rows if row[0] in selected and row[0] != parent]


command = ["/usr/bin/time", "-v", "-o", os.path.join(report, "time.txt"), "setsid"] + sys.argv[3:]
with open(os.path.join(report, "command.json"), "w") as stream:
    json.dump({"argv": command, "cwd": os.getcwd(), "budget_s": budget,
               "rss_limit_kib": rss_limit}, stream, indent=2)
log = open(os.path.join(report, "run.log"), "w")
process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
stop_reason = None


def request_stop(signum, frame):
    global stop_reason
    stop_reason = "SUPERVISOR_SIGNAL_" + str(signum)


signal.signal(signal.SIGTERM, request_stop)
signal.signal(signal.SIGINT, request_stop)


def signal_children(selected, sig):
    groups = set(row[2] for row in selected if row[2] != os.getpgrp())
    for group in groups:
        try:
            os.killpg(group, sig)
        except OSError as error:
            if error.errno != 3:
                raise


def cleanup():
    if process.poll() is None:
        signal_children(descendants(process.pid), signal.SIGKILL)
        process.terminate()
        process.wait()


atexit.register(cleanup)
start = now()
stop_time = None
stopping_groups = set()
next_sample = 0
peak_rss = 0
clock_ticks = os.sysconf("SC_CLK_TCK")
last_ticks, last_sample = 0, start
with open(os.path.join(report, "resources.csv"), "w") as stream:
    writer = csv.writer(stream)
    writer.writerow(["monotonic_elapsed_s", "rss_kib", "hwm_kib", "mem_available_kib",
                     "swap_used_kib", "cpu_ticks", "cpu_percent_one_core"])
    while process.poll() is None:
        elapsed = now() - start
        selected = descendants(process.pid)
        if elapsed >= next_sample:
            rss, hwm, ticks = 0, 0, 0
            for pid, _, _ in selected:
                try:
                    with open("/proc/%d/status" % pid) as source:
                        status = dict(line.split(":", 1) for line in source if ":" in line)
                    rss += int(status.get("VmRSS", "0").split()[0])
                    hwm = max(hwm, int(status.get("VmHWM", "0").split()[0]))
                    with open("/proc/%d/stat" % pid) as source:
                        raw = source.read()
                    fields = raw[raw.rfind(")") + 2:].split()
                    ticks += int(fields[11]) + int(fields[12])
                except (IOError, OSError):
                    continue
            with open("/proc/meminfo") as source:
                memory = dict((line.split(":")[0], int(line.split()[1])) for line in source)
            swap = memory["SwapTotal"] - memory["SwapFree"]
            available = memory.get("MemAvailable", memory["MemFree"])
            percent = 100.0 * (ticks - last_ticks) / clock_ticks / max(0.01, start + elapsed - last_sample)
            writer.writerow([elapsed, rss, hwm, available, swap, ticks, percent])
            stream.flush()
            peak_rss = max(peak_rss, rss)
            last_ticks, last_sample = ticks, start + elapsed
            next_sample = elapsed + 5
            if rss_limit and rss >= rss_limit:
                stop_reason = "RSS_LIMIT"
            if available < 256 * 1024 and swap > 2 * 1024 * 1024:
                stop_reason = "MEMORY_PRESSURE"
        if elapsed >= budget and stop_reason is None:
            stop_reason = "TIMEOUT"
        if stop_reason is not None:
            stopping_groups.update(row[2] for row in selected if row[2] != os.getpgrp())
            if stop_time is None:
                signal_children(selected, signal.SIGTERM)
                stop_time = elapsed
            elif elapsed - stop_time >= 10:
                signal_children(selected, signal.SIGKILL)
        time.sleep(0.5)
return_code = process.wait()
# The orchestration process can exit before its separately grouped tool does.
# Finish terminating every observed tool group even after GNU time has exited.
if stop_reason is not None:
    live_groups = set(stopping_groups)
    while live_groups and now() - start - stop_time < 10:
        for group in list(live_groups):
            try:
                os.killpg(group, 0)
            except OSError as error:
                if error.errno != 3:
                    raise
                live_groups.remove(group)
        if live_groups:
            time.sleep(0.1)
    signal_children([(0, 0, group) for group in live_groups], signal.SIGKILL)
log.close()
result = {"return_code": return_code, "stop_reason": stop_reason,
          "monotonic_elapsed_s": now() - start, "peak_sampled_rss_kib": peak_rss,
          "time_report_nonempty": os.path.getsize(os.path.join(report, "time.txt")) > 0}
with open(os.path.join(report, "result.json"), "w") as stream:
    json.dump(result, stream, indent=2)
print(json.dumps(result))
sys.exit(0 if return_code == 0 and stop_reason is None else 1)
