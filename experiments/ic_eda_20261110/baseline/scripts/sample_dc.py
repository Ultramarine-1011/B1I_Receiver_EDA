"""Attach to the actual DC common_shell_exec PID without restarting synthesis."""
from __future__ import print_function
import csv
import os
import sys
import time

pid = int(sys.argv[1])
report = sys.argv[2]
with open(os.path.join(report, "dc_process_identity.txt"), "w") as output:
    output.write("pid=%d\nexe=%s\n" % (pid, os.readlink("/proc/%d/exe" % pid)))
    with open("/proc/%d/cmdline" % pid, "rb") as source:
        output.write(source.read().replace(b"\x00", b" ").decode("utf-8")+"\n")
with open(os.path.join(report, "dc_process.csv"), "w") as output:
    writer = csv.writer(output)
    writer.writerow(["epoch_s", "pid", "rss_kib", "hwm_kib", "cpu_ticks", "state"])
    while os.path.exists("/proc/%d/status" % pid):
        try:
            with open("/proc/%d/status" % pid) as source:
                status = dict(line.split(":", 1) for line in source if ":" in line)
            with open("/proc/%d/stat" % pid) as source:
                raw = source.read()
            fields = raw[raw.rfind(")")+2:].split()
            writer.writerow([time.time(), pid, int(status.get("VmRSS", "0").split()[0]),
                             int(status.get("VmHWM", "0").split()[0]), int(fields[11])+int(fields[12]), fields[0]])
            output.flush()
        except (IOError, OSError):
            break
        time.sleep(5)
