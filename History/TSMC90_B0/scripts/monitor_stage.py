"""Python 2.7/3 supervisor. Keep all evidence even when DC exceeds its budget."""
from __future__ import print_function
import csv
import datetime
import json
import os
import signal
import subprocess
import sys
import time

stage, budget = sys.argv[1], int(sys.argv[2])
root = os.getcwd()
report = os.path.join(root, "runs", stage, "reports")
work = os.path.join(root, "runs", stage, "work")
os.makedirs(work)
os.symlink(os.path.join(root, "sources"), os.path.join(work, "sources"))
os.symlink(os.path.join(root, "scripts"), os.path.join(work, "scripts"))
os.symlink(os.path.join(root, "filelists"), os.path.join(work, "filelists"))

def save_system(name):
    with open(os.path.join(report, name), "w") as output:
        subprocess.call(["bash", "-c", "date -Is; hostname; uname -a; free -m; swapon -s; df -h .; ulimit -a; ps -eo pid,ppid,pgid,etime,pcpu,rss,comm --sort=-rss | head -18"], stdout=output, stderr=subprocess.STDOUT)

save_system("system_before.txt")
command = ["/usr/bin/time", "-v", "-o", os.path.join(report, "time.txt"),
           "timeout", "--signal=TERM", "--kill-after=10s", str(budget),
           "/home/synopsys/syn/O-2018.06-SP1/bin/dc_shell", "-64bit", "-f", "scripts/dc_baseline.tcl"]
with open(os.path.join(report, "command.json"), "w") as output:
    json.dump({"argv": command, "cwd": work, "budget_seconds": budget, "max_cores": 1,
               "started_utc": datetime.datetime.utcnow().isoformat()+"Z"}, output, indent=2)
log_path = os.path.join(report, "run.log")
log = open(log_path, "w")
start = time.time()
process = subprocess.Popen(command, cwd=work, stdout=log, stderr=subprocess.STDOUT, preexec_fn=os.setsid)
with open(os.path.join(report, "supervised_pid.txt"), "w") as output:
    output.write(str(process.pid)+"\n")
resource = open(os.path.join(report, "resources.csv"), "w")
writer = csv.writer(resource)
writer.writerow(["elapsed_s", "dc_pid", "dc_rss_kib", "dc_hwm_kib", "tree_rss_kib", "tree_cpu_pct_1core", "mem_available_kib", "swap_used_kib", "pswpin_pages", "pswpout_pages", "log_bytes"])
clock_ticks = os.sysconf("SC_CLK_TCK")
previous_ticks, previous_time = 0, start
max_rss, max_tree, max_swap = 0, 0, 0
stop_reason = None

def snapshot():
    rows = {}
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        try:
            with open("/proc/"+entry+"/stat") as source:
                raw = source.read()
            fields = raw[raw.rfind(")")+2:].split()
            rows[int(entry)] = (int(fields[1]), int(fields[11])+int(fields[12]))
        except (IOError, OSError):
            continue
    selected = set([process.pid])
    old_count = -1
    while old_count != len(selected):
        old_count = len(selected)
        selected.update(pid for pid, values in rows.items() if values[0] in selected)
    total_rss, total_ticks, dc_pid, dc_rss, dc_hwm = 0, 0, 0, 0, 0
    for pid in selected:
        if pid not in rows:
            continue
        try:
            with open("/proc/%d/status" % pid) as source:
                status = dict(line.split(":", 1) for line in source if ":" in line)
            rss = int(status.get("VmRSS", "0").split()[0])
            total_rss += rss
            total_ticks += rows[pid][1]
            if "dc_shell" in status.get("Name", ""):
                dc_pid, dc_rss = pid, rss
                dc_hwm = int(status.get("VmHWM", "0").split()[0])
        except (IOError, OSError):
            continue
    return total_rss, total_ticks, dc_pid, dc_rss, dc_hwm

while process.poll() is None:
    now = time.time()
    tree_rss, ticks, dc_pid, dc_rss, dc_hwm = snapshot()
    with open("/proc/meminfo") as source:
        memory = dict((line.split(":")[0], int(line.split()[1])) for line in source)
    with open("/proc/vmstat") as source:
        vmstat = dict(line.split() for line in source)
    swap = memory["SwapTotal"]-memory["SwapFree"]
    cpu = max(0, ticks-previous_ticks)*100.0/clock_ticks/max(0.01, now-previous_time)
    writer.writerow([round(now-start, 3), dc_pid, dc_rss, dc_hwm, tree_rss, round(cpu, 2),
                     memory.get("MemAvailable", memory["MemFree"]), swap,
                     vmstat["pswpin"], vmstat["pswpout"], os.path.getsize(log_path)])
    resource.flush()
    max_rss, max_tree, max_swap = max(max_rss, dc_hwm), max(max_tree, tree_rss), max(max_swap, swap)
    previous_ticks, previous_time = ticks, now
    if now-start > budget+20:
        stop_reason = "SUPERVISOR_TIMEOUT"
        os.killpg(process.pid, signal.SIGKILL)
        break
    # Stop severe memory pressure before prolonged swap thrashing consumes the run.
    if memory.get("MemAvailable", memory["MemFree"]) < 256*1024 and swap > 2*1024*1024:
        stop_reason = "MEMORY_PRESSURE"
        os.killpg(process.pid, signal.SIGTERM)
        time.sleep(10)
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGKILL)
        break
    time.sleep(5)
return_code = process.wait()
elapsed = time.time()-start
resource.close()
log.close()
with open(log_path) as source:
    content = source.read()
completed = "BASELINE_REPORTS_DONE "+stage in content
errors = [line for line in content.splitlines() if line.startswith(("Error:", "Fatal:", "FATAL:"))]
for filename in os.listdir(report):
    if filename.endswith(".rpt"):
        with open(os.path.join(report, filename)) as source:
            errors.extend(line.strip() for line in source if line.startswith(("Error:", "Fatal:")))
status = "PASS" if return_code == 0 and completed and not errors else "FAIL"
if return_code == 124 or stop_reason == "SUPERVISOR_TIMEOUT":
    status = "TIMEOUT"
result = {"stage": stage, "status": status, "return_code": return_code,
          "supervisor_elapsed_s": elapsed, "sampled_dc_hwm_kib": max_rss,
          "sampled_tree_peak_rss_kib": max_tree, "vm_peak_swap_used_kib": max_swap,
          "stop_reason": stop_reason, "reports_complete": completed, "errors": errors,
          "final_area": "AVAILABLE" if status == "PASS" else "NOT_AVAILABLE",
          "final_timing": "AVAILABLE" if status == "PASS" else "NOT_AVAILABLE"}
with open(os.path.join(report, "result.json"), "w") as output:
    json.dump(result, output, indent=2)
save_system("system_after.txt")
print(json.dumps(result))
sys.exit(0 if status == "PASS" else 1)
