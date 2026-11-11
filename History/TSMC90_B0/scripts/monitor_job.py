"""Corrected supervisor, Python 2.7/3. Original B0 runner stays frozen separately.

Usage: monitor_job.py REPORT_DIR BUDGET_SECONDS COMMAND [ARG ...]
Run from a fresh work directory. GNU time remains alive while the DC group stops.
"""
from __future__ import print_function
import csv
import atexit
import json
import os
import signal
import subprocess
import sys
import time

report, budget = os.path.abspath(sys.argv[1]), float(sys.argv[2])
os.makedirs(report)


def monotonic_seconds():
    with open("/proc/uptime") as source:
        return float(source.read().split()[0])


def children_snapshot(parent):
    rows = []
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        try:
            with open("/proc/"+entry+"/stat") as source:
                raw = source.read()
            fields = raw[raw.rfind(")")+2:].split()
            rows.append([int(entry), int(fields[1]), int(fields[2]), 0])
        except (IOError, OSError):
            continue
    selected = set([parent])
    old_size = -1
    while old_size != len(selected):
        old_size = len(selected)
        selected.update(row[0] for row in rows if row[1] in selected)
    return [row for row in rows if row[0] in selected and row[0] != parent]


command = ["/usr/bin/time", "-v", "-o", os.path.join(report, "time.txt"), "setsid"]+sys.argv[3:]
with open(os.path.join(report, "command.json"), "w") as output:
    json.dump({"argv": command, "cwd": os.getcwd(), "budget_s": budget}, output, indent=2)
log = open(os.path.join(report, "run.log"), "w")
process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)


def cleanup_on_error():
    if process.poll() is None:
        groups = set(row[2] for row in children_snapshot(process.pid) if row[2] != os.getpgrp())
        for group in groups:
            try:
                os.killpg(group, signal.SIGKILL)
            except OSError as error:
                if error.errno != 3:
                    raise
        if not groups:
            process.terminate()
        process.wait()


atexit.register(cleanup_on_error)
start = monotonic_seconds()
stop_time = None
stop_reason = None
next_sample = 0
with open(os.path.join(report, "resources.csv"), "w") as output:
    writer = csv.writer(output)
    writer.writerow(["monotonic_elapsed_s", "rss_kib", "hwm_kib", "mem_available_kib", "swap_used_kib"])
    while process.poll() is None:
        elapsed = monotonic_seconds()-start
        children = children_snapshot(process.pid)
        if elapsed >= next_sample:
            rss, hwm = 0, 0
            for pid, _, _, _ in children:
                try:
                    with open("/proc/%d/status" % pid) as source:
                        status = dict(line.split(":", 1) for line in source if ":" in line)
                    rss += int(status.get("VmRSS", "0").split()[0])
                    hwm = max(hwm, int(status.get("VmHWM", "0").split()[0]))
                except (IOError, OSError):
                    continue
            with open("/proc/meminfo") as source:
                memory = dict((line.split(":")[0], int(line.split()[1])) for line in source)
            swap = memory["SwapTotal"]-memory["SwapFree"]
            available = memory.get("MemAvailable", memory["MemFree"])
            writer.writerow([elapsed, rss, hwm, available, swap])
            output.flush()
            next_sample = elapsed+5
            if available < 256*1024 and swap > 2*1024*1024:
                stop_reason = "MEMORY_PRESSURE"
        if elapsed >= budget and stop_reason is None:
            stop_reason = "TIMEOUT"
        if stop_reason is not None:
            # setsid makes the command's PGID independent of GNU time's PGID.
            groups = set(row[2] for row in children if row[2] != os.getpgrp())
            stop_signal = signal.SIGTERM if stop_time is None else signal.SIGKILL
            if stop_time is None or elapsed-stop_time >= 10:
                for group in groups:
                    try:
                        os.killpg(group, stop_signal)
                    except OSError as error:
                        if error.errno != 3:
                            raise
                if stop_time is None:
                    stop_time = elapsed
        time.sleep(0.5)
return_code = process.wait()
log.close()
result = {"return_code": return_code, "stop_reason": stop_reason,
          "monotonic_elapsed_s": monotonic_seconds()-start,
          "time_report_nonempty": os.path.getsize(os.path.join(report, "time.txt")) > 0}
with open(os.path.join(report, "result.json"), "w") as output:
    json.dump(result, output, indent=2)
print(json.dumps(result))
sys.exit(0 if return_code == 0 and stop_reason is None else 1)
