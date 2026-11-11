"""VMware Tools transport. Read credentials from stdin without persisting them."""
import json
from pathlib import Path
import subprocess
import sys

request = json.load(sys.stdin)
vmrun = r"C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
vmx = r"C:\IC_EDA_Lite_20220604\IC_EDA_Lite\IC_EDA_Lite\IC_EDA.vmx"
prefix = [vmrun, "-gu", "ICer", "-gp", request["password"]]


def invoke(arguments):
    result = subprocess.run(prefix + arguments, capture_output=True, timeout=90)
    if result.returncode:
        # Do not include argv, which contains the authentication value.
        raise RuntimeError("VMware Tools failed: " + result.stdout.decode(errors="replace")
                           + result.stderr.decode(errors="replace"))
    return result.stdout.decode(errors="replace")


for local, remote in request.get("upload", []):
    invoke(["copyFileFromHostToGuest", vmx, local, remote])
if "command" in request:
    work = Path(__file__).resolve().parent.parent / "work"
    work.mkdir(exist_ok=True)
    script = work / "guest_command.sh"
    script.write_text("#!/bin/bash\nexport LC_ALL=C\nexec > /tmp/backend_command.txt 2>&1\n"
                      + request["command"] + "\n", encoding="utf-8", newline="\n")
    invoke(["copyFileFromHostToGuest", vmx, str(script), "/tmp/backend_command.sh"])
    invoke(["runProgramInGuest", vmx, "/bin/bash", "/tmp/backend_command.sh"])
    output = work / "guest_command.txt"
    invoke(["copyFileFromGuestToHost", vmx, "/tmp/backend_command.txt", str(output)])
    print(output.read_text(encoding="utf-8", errors="replace"))
if "script" in request:
    invoke(["runProgramInGuest", vmx, "-noWait", "/bin/bash", request["script"]])
for remote, local in request.get("download", []):
    Path(local).parent.mkdir(parents=True, exist_ok=True)
    invoke(["copyFileFromGuestToHost", vmx, remote, local])
    if request.get("print_downloads"):
        print(Path(local).read_text(encoding="utf-8", errors="replace"))
print("GUEST_TRANSPORT_PASS")
