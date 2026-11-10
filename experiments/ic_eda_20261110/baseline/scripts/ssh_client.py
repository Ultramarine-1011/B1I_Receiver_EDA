"""One authenticated action. Credentials arrive on stdin and are never saved."""
import json
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(root / "work" / "python"))
import paramiko

request = json.load(sys.stdin)
client = paramiko.SSHClient()
client.load_host_keys(str(root.parent / "known_hosts"))
client.connect(request["host"], username="ICer", password=request["password"],
               look_for_keys=False, allow_agent=False, timeout=15)
if "upload" in request:
    with client.open_sftp() as sftp:
        for local, remote in request["upload"]:
            sftp.put(local, remote)
if "command" in request:
    _, stdout, stderr = client.exec_command(request["command"], timeout=request.get("timeout", 30))
    output, error = stdout.read(), stderr.read()
    code = stdout.channel.recv_exit_status()
    if "save" in request:
        Path(request["save"]).write_bytes(output + error)
    print(json.dumps({"exit_code": code, "stdout": output.decode("utf-8", "replace"),
                      "stderr": error.decode("utf-8", "replace")}))
if "download" in request:
    with client.open_sftp() as sftp:
        for remote, local in request["download"]:
            sftp.get(remote, local)
client.close()
