"""Archive generated netlists and large raw reports, retaining per-file SHA256."""
import hashlib
import json
from pathlib import Path
import tarfile

experiment = Path(__file__).resolve().parent.parent
evidence = experiment / "evidence"
media = {".v", ".ddc", ".sdf", ".vcd", ".saif"}
selected = sorted(path for path in evidence.rglob("*") if path.is_file()
                  and path.suffix not in {".gz", ".zip"}
                  and (path.suffix in media or path.stat().st_size > 1024*1024))
archive = evidence / "artifacts.tar.gz"
manifest = []
with tarfile.open(archive, "w:gz") as output:
    for path in selected:
        name = path.relative_to(evidence).as_posix()
        output.add(path, arcname=name)
        manifest.append({"path": name, "bytes": path.stat().st_size,
                         "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
with tarfile.open(archive) as captured:
    for record in manifest:
        assert hashlib.sha256(captured.extractfile(record["path"]).read()).hexdigest() == record["sha256"]
record = {"archive": archive.name, "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
          "files": manifest}
(evidence / "artifacts.json").write_text(json.dumps(record, indent=2), encoding="utf-8", newline="\n")
ignore = experiment / ".gitignore"
lines = ignore.read_text().splitlines()
for path in selected:
    name = "/" + path.relative_to(experiment).as_posix()
    if name not in lines:
        lines.append(name)
ignore.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
print("ARTIFACT_ARCHIVE_PASS files", len(manifest), "bytes", archive.stat().st_size)
