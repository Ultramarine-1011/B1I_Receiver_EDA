"""Archive completed standalone DC experiments, retaining their expanded local copies."""
import hashlib
import json
from pathlib import Path
import tarfile

EXPERIMENT = Path(__file__).resolve().parent.parent
evidence = EXPERIMENT / "evidence"
labels = ["v4_57", "r4_57", "r16_57", "nr_57", "v4_29", "nr_29",
          "v4_conversion", "signed_conversion"]
sources = evidence / "probe_sources"
sources.mkdir(exist_ok=True)
radix = (EXPERIMENT / "work/radix_probes.sv").read_bytes()
initial = radix.split(b"module norm_nr_57", 1)[0].rstrip(b"\n") + b"\n"
manifest = (evidence / "v4_57/input_manifest.sha256").read_text(encoding="utf-8")
expected = next(line.split()[0] for line in manifest.splitlines() if line.endswith("work/radix_probes.sv"))
assert hashlib.sha256(initial).hexdigest() == expected, "Initial probe reconstruction differs"
(sources / "radix_initial.sv").write_bytes(initial)
(sources / "radix_nr.sv").write_bytes(radix)
(sources / "conversion_probes.sv").write_bytes((EXPERIMENT / "work/conversion_probes.sv").read_bytes())

archive = evidence / "module_dc.tar.gz"
manifest = []
with tarfile.open(archive, "w:gz") as output:
    for label in labels + ["probe_sources"]:
        for path in sorted((evidence / label).rglob("*")):
            if path.is_file():
                relative = path.relative_to(evidence).as_posix()
                output.add(path, arcname=relative)
                manifest.append({"path": relative, "bytes": path.stat().st_size,
                                 "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
record = {"archive": archive.name, "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
          "bytes": archive.stat().st_size, "files": manifest}
(evidence / "module_archive.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
print("MODULE_ARCHIVE_PASS files=" + str(len(manifest)) + " bytes=" + str(archive.stat().st_size))
