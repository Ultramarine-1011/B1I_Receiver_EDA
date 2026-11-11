"""Launch one isolated job and enforce its budget using host monotonic time."""
import argparse
import json
from pathlib import Path
import os
import shlex
import time
import sys

EXPERIMENT = Path(__file__).resolve().parent.parent
REPOSITORY = Path(os.environ.get("B1I_PROJECT_ROOT", EXPERIMENT.parent.parent / "B1I_Receiver_EDA"))
sys.path.insert(0, str(EXPERIMENT.parent / "History/TSMC90_B0/work/python"))
import paramiko


def connect():
    # Credentials are supplied over stdin, used in memory and never saved.
    request = json.load(sys.stdin)
    client = paramiko.SSHClient()
    client.load_host_keys(str(EXPERIMENT.parent / "History/PRN_Environment/known_hosts"))
    client.connect(request["host"], username="ICer", password=request["password"],
                   look_for_keys=False, allow_agent=False, timeout=15)
    return client

parser = argparse.ArgumentParser()
parser.add_argument("kind", choices=["radix", "conversion", "channel", "channel_hier", "preflight", "cached", "cached_preflight"])
parser.add_argument("label")
parser.add_argument("budget", type=int)
parser.add_argument("--attach", action="store_true")
args = parser.parse_args()
root = "/home/ICer/ic_eda_night_20261110"
run = root + "/runs/" + args.label
evidence = EXPERIMENT / "evidence" / args.label
evidence.mkdir(exist_ok=True)
client = connect()


def command(text):
    _, stdout, stderr = client.exec_command(text, timeout=30)
    output, error = stdout.read(), stderr.read()
    code = stdout.channel.recv_exit_status()
    if code:
        raise RuntimeError("Remote job command failed " + str(code) + ": " + error.decode())
    return output.decode()


started = time.monotonic()
if not args.attach:
    command("test ! -e " + shlex.quote(run))
launch = ("nohup bash " + root + "/scripts/run_scoped.sh " +
          shlex.quote(args.kind) + " " + shlex.quote(args.label) + " " + str(args.budget) +
          " > " + shlex.quote(root + "/" + args.label + ".launcher.log") +
          " 2>&1 < /dev/null & echo $!")
if not args.attach:
    command(launch)
print("LAUNCHED " + run, flush=True)
deadline_signalled = False
last_progress = 0
try:
    while True:
        result = command("if test -s " + run + "/reports/result.json; then cat " +
                         run + "/reports/result.json; fi")
        elapsed = time.monotonic() - started
        if result.strip():
            record = {"host_elapsed_s": elapsed, "host_deadline_signalled": deadline_signalled,
                      "attached_existing_job": args.attach,
                      "budget_s": args.budget, "run": run, "result": json.loads(result)}
            (evidence / "host_result.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
            print(json.dumps(record), flush=True)
            break
        # Leave 15 seconds for orderly DC exit and GNU time finalization.
        if elapsed >= args.budget - 15 and not deadline_signalled:
            script = ("import os,signal\nexpected=" + repr(run + "/work") + "\n"
                      "for entry in os.listdir('/proc'):\n"
                      " if not entry.isdigit(): continue\n"
                      " try:\n"
                      "  if os.readlink('/proc/'+entry+'/cwd')==expected:\n"
                      "   with open('/proc/'+entry+'/comm') as f: name=f.read().strip()\n"
                      "   if name=='common_shell_ex' or name=='common_shell_exec':\n"
                      "    os.kill(int(entry),signal.SIGTERM)\n"
                      "    print('HOST_DEADLINE_TERM',entry)\n"
                      " except OSError: pass\n")
            print(command("/usr/bin/python -c " + shlex.quote(script)), flush=True)
            deadline_signalled = True
        if elapsed >= last_progress + 60:
            tail = command("tail -n 3 " + run + "/reports/run.log 2>/dev/null || true")
            print("ELAPSED %.1f\n%s" % (elapsed, tail), flush=True)
            last_progress = elapsed
        if elapsed > args.budget + 30:
            raise RuntimeError("DC did not terminate after the host deadline")
        time.sleep(3)
    # Preserve all run reports locally. Intermediate WORK databases stay on the VM.
    with client.open_sftp() as sftp:
        for filename in sftp.listdir(run + "/reports"):
            sftp.get(run + "/reports/" + filename, str(evidence / filename))
        for filename in ("input_manifest.sha256", "environment_hashes.txt", "input_check.txt"):
            sftp.get(run + "/" + filename, str(evidence / filename))
        if not args.attach:
            sftp.get(run + "/synthesis_inputs.tar.gz", str(evidence / "synthesis_inputs.tar.gz"))
        if args.kind in ("cached", "cached_preflight"):
            sftp.get(run + "/cached_arithmetic.sha256", str(evidence / "cached_arithmetic.sha256"))
finally:
    client.close()
