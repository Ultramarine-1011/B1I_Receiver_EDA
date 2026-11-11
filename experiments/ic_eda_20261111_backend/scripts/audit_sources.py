"""Audit V6 provenance and regenerate its RTL in a disposable local tree."""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile

experiment = Path(__file__).resolve().parent.parent
repository = experiment.parents[1]
night = repository / "experiments/ic_eda_20261110/night_opt"
baseline = night.parent / "baseline"
record = {"source_sha256": hashlib.sha256((night / "rtl/tracking_channel_minimal.sv").read_bytes()).hexdigest()}
record["runs"] = {}
for label in ("full_v6_hier_10ns", "full_v6_cached_10ns"):
    folder = night / "evidence" / label
    matching, changed, unavailable = [], [], []
    for line in (folder / "input_manifest.sha256").read_text().splitlines():
        digest, relative = line.split(None, 1)
        path = night / relative
        if path.exists():
            (matching if hashlib.sha256(path.read_bytes()).hexdigest() == digest else changed).append(relative)
        else:
            unavailable.append(relative)
    assert "rtl/tracking_channel_minimal.sv" in matching
    # Reproduction uses the frozen in-run scripts when current wrappers evolved.
    with tarfile.open(folder / "synthesis_inputs.tar.gz") as archive:
        frozen = archive.extractfile("rtl/tracking_channel_minimal.sv").read()
        assert hashlib.sha256(frozen).hexdigest() == record["source_sha256"]
        script_changes = {}
        for name in changed:
            captured = archive.extractfile(name).read()
            script_changes[name] = {"frozen_sha256": hashlib.sha256(captured).hexdigest(),
                                    "current_sha256": hashlib.sha256((night / name).read_bytes()).hexdigest()}
    record["runs"][label] = {"matching_files": len(matching), "changed_after_run": script_changes,
                              "unavailable_files": unavailable}

cache = []
for line in (night / "evidence/full_v6_cached_10ns/cached_arithmetic.sha256").read_text().splitlines():
    expected, name = line.split(None, 1)
    path = night / "evidence/full_v6_hier_10ns" / Path(name).name
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    assert actual == expected
    cache.append({"file": path.name, "sha256": actual})
record["original_cache_files"] = cache

scratch = experiment / "work/generator_repo"
generated = scratch / "experiments/ic_eda_20261110/night_opt"
for name in ("scripts", "rtl", "tb", "filelists"):
    shutil.copytree(night / name, generated / name, dirs_exist_ok=True)
(generated / "evidence").mkdir(exist_ok=True)
(generated / "work").mkdir(exist_ok=True)
shutil.copyfile(night / "evidence/module_dc.tar.gz", generated / "evidence/module_dc.tar.gz")
for relative in ("divider_opt/rtl", "divider_opt/tb", "baseline/sources"):
    shutil.copytree(night.parent / relative, generated.parent / relative, dirs_exist_ok=True)
shutil.copytree(repository / "tb", scratch / "tb", dirs_exist_ok=True)
commands = [
    ["prepare_radix.py"], ["prepare_constants.py"], ["prepare_accepted.py"],
    ["prepare_hier.py", "--activate"], ["prepare.py"], ["prepare_loop_equivalence.py"],
]
outputs = []
for arguments in commands:
    result = subprocess.run([sys.executable, str(generated / "scripts" / arguments[0])] + arguments[1:],
                            capture_output=True, text=True, encoding="utf-8")
    outputs.append({"arguments": arguments, "exit_code": result.returncode,
                    "stdout": result.stdout, "stderr": result.stderr})
    if result.returncode:
        raise RuntimeError(result.stderr)
actual = hashlib.sha256((generated / "rtl/tracking_channel_minimal.sv").read_bytes()).hexdigest()
assert actual == record["source_sha256"], actual
record["generator_reproduction"] = {"sha256": actual, "byte_identical": True, "commands": outputs}
protected = {}
for directory in (repository / "student_release/student_release/rtl", repository / "rtl", repository / "261102"):
    for path in directory.rglob("*"):
        if path.is_file():
            protected[path.relative_to(repository).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
record["protected_source_hashes"] = protected
(experiment / "evidence/source_audit.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
print("V6_SOURCE_REGENERATION_PASS", actual, "protected_files", len(protected))
