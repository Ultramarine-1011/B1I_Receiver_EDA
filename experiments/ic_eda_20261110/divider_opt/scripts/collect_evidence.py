"""Pack completed DC runs and small diagnostic evidence on the Linux guest (Python 2/3)."""
from __future__ import print_function
import glob
import hashlib
import json
import os
import tarfile

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
destination = os.path.join(root, "work/export")
if not os.path.isdir(destination):
    os.makedirs(destination)
runs = sorted(glob.glob(os.path.join(root, "runs/*")))
reports = []
mapped = []
for run in runs:
    if not os.path.isfile(os.path.join(run, "reports/result.json")):
        raise RuntimeError("Run still incomplete: " + run)
    for path in glob.glob(os.path.join(run, "reports/*")):
        if os.path.isfile(path):
            (mapped if os.path.basename(path) in ("mapped.v", "mapped.ddc") else reports).append(path)
    reports.extend(path for path in glob.glob(os.path.join(run, "*")) if os.path.isfile(path))
for directory in ("work/identify_run", "work/v2_elab", "work/v4_elab", "work/v4_const_elab", "work/probe_v3_run", "work/probe_v3_fixed"):
    for path in glob.glob(os.path.join(root, directory, "*")) + glob.glob(os.path.join(root, directory, "reports/*")):
        if os.path.isfile(path) and path.endswith((".rpt", ".log", ".json", ".txt", ".csv")):
            reports.append(path)
for pattern in ("work/vcs_arithmetic/*.log", "work/vcs_arithmetic/*.txt", "work/*.sv", "work/*.tcl"):
    reports.extend(glob.glob(os.path.join(root, pattern)))

summary = {}
for name, paths in (("dc_evidence.tar.gz", reports), ("mapped_outputs.tar.gz", mapped)):
    archive_path = os.path.join(destination, name)
    with tarfile.open(archive_path, "w:gz") as archive:
        for path in sorted(set(paths)):
            archive.add(path, arcname=os.path.relpath(path, root), recursive=False)
    with open(archive_path, "rb") as stream:
        digest = hashlib.sha256(stream.read()).hexdigest()
    summary[name] = {"files": len(set(paths)), "bytes": os.path.getsize(archive_path), "sha256": digest}
with open(os.path.join(destination, "manifest.json"), "w") as stream:
    json.dump(summary, stream, indent=2)
print(json.dumps(summary))
