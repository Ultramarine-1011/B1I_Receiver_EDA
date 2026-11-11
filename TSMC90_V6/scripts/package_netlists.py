"""Archive real mapped netlists and reusable arithmetic DDCs, keeping local originals."""
import hashlib
import json
from pathlib import Path
import tarfile

EXPERIMENT = Path(__file__).resolve().parent.parent
evidence = EXPERIMENT / "evidence"
files = [EXPERIMENT / "Results" / name for name in ("mapped.v", "mapped.ddc")]
files += sorted((evidence / "full_v6_hier_10ns").glob("*.ddc"))
assert len(files) == 7
archive = evidence / "dc_netlists.tar.gz"
manifest = []
with tarfile.open(archive, "w:gz") as output:
    for path in files:
        relative = ("full_v6_cached_10ns/" + path.name if path.parent == EXPERIMENT / "Results"
                    else path.relative_to(evidence).as_posix())
        output.add(path, arcname=relative)
        manifest.append({"path": relative, "bytes": path.stat().st_size,
                         "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
with tarfile.open(archive, "r:gz") as packed:
    for entry in manifest:
        assert hashlib.sha256(packed.extractfile(entry["path"]).read()).hexdigest() == entry["sha256"]
record = {"archive": archive.name, "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
          "bytes": archive.stat().st_size, "files": manifest}
(evidence / "netlist_archive.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
print("NETLIST_ARCHIVE_PASS files=" + str(len(files)) + " bytes=" + str(archive.stat().st_size))
