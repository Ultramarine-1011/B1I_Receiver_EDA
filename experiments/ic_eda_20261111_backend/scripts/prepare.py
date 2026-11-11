"""Stage the already verified V6 and frozen dependency sources for this experiment."""
import hashlib
import json
from pathlib import Path
import shutil
import tarfile
import time
import argparse

experiment = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument("--lab-bundle", action="store_true")
arguments = parser.parse_args()
repository = experiment.parents[1]
night = repository / "experiments/ic_eda_20261110/night_opt"
baseline = night.parent / "baseline"
stage = experiment / "work/stage"
stage.mkdir(parents=True, exist_ok=True)
shutil.copytree(baseline / "sources", stage / "sources", dirs_exist_ok=True)
shutil.copytree(night / "filelists", stage / "filelists", dirs_exist_ok=True)
(stage / "rtl").mkdir(exist_ok=True)
shutil.copyfile(night / "rtl/tracking_channel_minimal.sv", stage / "rtl/tracking_channel_minimal.sv")
shutil.copytree(experiment / "scripts", stage / "scripts", dirs_exist_ok=True)
shutil.copytree(experiment / "probes", stage / "probes", dirs_exist_ok=True)
shutil.copytree(experiment / "lab", stage / "lab", dirs_exist_ok=True)
shutil.copyfile(night / "scripts/monitor_job.py", stage / "scripts/monitor_job.py")
shutil.copyfile(night / "scripts/baseline.sdc", stage / "scripts/baseline.sdc")
files = sorted(p for p in stage.rglob("*") if p.is_file() and p.name != "inputs.sha256")
manifest = {p.relative_to(stage).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
(stage / "inputs.sha256").write_text("".join(f"{digest}  {name}\n" for name, digest in manifest.items()), encoding="utf-8", newline="\n")
(experiment / "evidence").mkdir(exist_ok=True)
(experiment / "evidence/staged_inputs.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
start = experiment / "evidence/host_start.json"
if not start.exists():
    start.write_text(json.dumps({"host_unix_s": time.time(), "budget_hours": 4.5}, indent=2), encoding="utf-8")
with tarfile.open(experiment / "work/input.tar.gz", "w:gz") as archive:
    for path in sorted(stage.iterdir()):
        archive.add(path, arcname=path.name)
print("STAGED_V6", manifest["rtl/tracking_channel_minimal.sv"])
if arguments.lab_bundle:
    # Standalone Linux tree, with fixtures and source. PDK data stays on its host.
    bundle = experiment / "work/LAB_INPUTS.tar.gz"
    selected = [repository / "student_release/student_release/rtl",
                repository / "rtl/bds_bb_6ch_pad_top.sv",
                repository / "synth/m2_isolate/acquisition_pcps_blackbox.sv",
                experiment / "lab", experiment / "scripts/reports.tcl",
                experiment / "LAB_RUNBOOK.md", stage]
    selected += [repository / "work/six_channel_20261102" / name
                 for name in ["six.if2", "recovery.if2"] + [f"bits{channel}.mem" for channel in range(6)]]
    with tarfile.open(bundle, "w:gz") as archive:
        for path in selected:
            if not path.exists():
                raise FileNotFoundError(path)
            archive.add(path, arcname=path.relative_to(repository).as_posix())
    digest = hashlib.sha256(bundle.read_bytes()).hexdigest()
    bundle.with_suffix(".gz.sha256").write_text(digest + "  LAB_INPUTS.tar.gz\n", encoding="utf-8", newline="\n")
    print("LAB_BUNDLE", bundle, bundle.stat().st_size, digest)
