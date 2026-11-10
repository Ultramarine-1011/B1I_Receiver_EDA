"""Enforce the real host 20-minute limit when guest uptime runs slower than wall time.

One JSON request arrives on stdin. The password is only used in memory.
Attach immediately after launch with the DC PID, run directory and host launch epoch.
"""
import json
from pathlib import Path
import shlex
import sys
import time

experiment = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(experiment.parent / "baseline/work/python"))
import paramiko

request = json.load(sys.stdin)
client = paramiko.SSHClient()
client.load_host_keys(str(experiment.parent / "known_hosts"))
client.connect(request["host"], username="ICer", password=request["password"],
               look_for_keys=False, allow_agent=False, timeout=15)
run = request["run"]
result_path = shlex.quote(run + "/reports/result.json")
elapsed_before_attach = time.time() - request["started_at_epoch"]
attached = time.monotonic()
deadline = attached + request["budget_s"] - elapsed_before_attach


def command(text):
    _, output, error = client.exec_command(text, timeout=15)
    stdout, stderr = output.read(), error.read()
    return output.channel.recv_exit_status(), stdout.decode(), stderr.decode()


result = {}
while True:
    code, stdout, stderr = command("if test -s " + result_path + "; then cat " + result_path + "; fi")
    if code != 0:
        raise RuntimeError("Deadline observation failed: " + stderr)
    if stdout.strip():
        result = {"status": "COMPLETED", "vm_result": json.loads(stdout)}
        break
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        # Signal only the attached DC in its verified work directory. GNU time survives.
        remote_python = (
            "import os,signal\n"
            f"pid={int(request['pid'])}\n"
            f"expected={run + '/work'!r}\n"
            "if os.path.exists('/proc/%d' % pid):\n"
            "    assert os.readlink('/proc/%d/cwd' % pid)==expected\n"
            "    os.kill(pid,signal.SIGTERM)\n"
            "    print('HOST_DEADLINE_SIGNALLED')\n"
            "else:\n"
            "    print('HOST_DEADLINE_PROCESS_GONE')\n"
        )
        code, stdout, stderr = command("/usr/bin/python -c " + shlex.quote(remote_python))
        result = {"status": "HOST_TIME_BUDGET", "signal_exit": code,
                  "signal_stdout": stdout, "signal_stderr": stderr}
        break
    time.sleep(min(20, remaining))
result["host_elapsed_s"] = elapsed_before_attach + time.monotonic() - attached
result["budget_s"] = request["budget_s"]
result["run"] = run
Path(request["save"]).write_text(json.dumps(result, indent=2), encoding="utf-8")
client.close()
print(json.dumps(result))
