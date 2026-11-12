"""Stage the already verified V6 and frozen dependency sources for this experiment."""
import hashlib
import json
from pathlib import Path
import os
import shutil
import tarfile
import time
import argparse

experiment = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument("--lab-bundle", action="store_true")
arguments = parser.parse_args()
repository = Path(os.environ.get("B1I_PROJECT_ROOT", experiment.parent.parent / "B1I_Receiver_EDA"))
night = experiment.parent / "TSMC90_V6"
baseline = night.parent / "History/TSMC90_B0"
stage = experiment / "work/stage"
stage.mkdir(parents=True, exist_ok=True)
shutil.copytree(baseline / "sources", stage / "sources", dirs_exist_ok=True)
shutil.copytree(night / "filelists", stage / "filelists", dirs_exist_ok=True)
(stage / "rtl").mkdir(exist_ok=True)
shutil.copyfile(night / "rtl/tracking_channel_minimal.sv", stage / "rtl/tracking_channel_minimal.sv")
for name in ["bds_bb_6ch_core.sv", "receiver_channel.sv", "navigation_d1.sv", "nh20_sync.sv"]:
    candidate = experiment / "rtl" / name
    if candidate.exists():
        shutil.copyfile(candidate, stage / "sources/student_release/student_release/rtl" / name)
period = experiment / "rtl/b1i_period_reduce.sv"
if period.exists():
    shutil.copyfile(period, stage / "rtl/b1i_period_reduce.sv")
    filelist = stage / "filelists/B1.txt"
    sources = filelist.read_text().splitlines()
    sources.insert(1, "rtl/b1i_period_reduce.sv")
    filelist.write_text("\n".join(sources) + "\n", encoding="utf-8", newline="\n")
shutil.copytree(experiment / "scripts", stage / "scripts", dirs_exist_ok=True)
shutil.copytree(experiment / "probes", stage / "probes", dirs_exist_ok=True)
shutil.copytree(experiment / "lab", stage / "lab", dirs_exist_ok=True)
shutil.copyfile(night / "scripts/baseline.sdc", stage / "scripts/baseline.sdc")
current_scripts = {p.relative_to(experiment / "scripts").as_posix()
                   for p in (experiment / "scripts").rglob("*") if p.is_file()}
files = sorted(p for p in stage.rglob("*")
               if p.is_file() and p.name != "inputs.sha256" and
               (not p.is_relative_to(stage / "scripts") or
                p.relative_to(stage / "scripts").as_posix() in current_scripts))
manifest = {p.relative_to(stage).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
(stage / "inputs.sha256").write_text("".join(f"{digest}  {name}\n" for name, digest in manifest.items()), encoding="utf-8", newline="\n")
(experiment / "evidence").mkdir(exist_ok=True)
(experiment / "work/staged_inputs.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
start = experiment / "evidence/host_start.json"
if not start.exists():
    start.write_text(json.dumps({"host_unix_s": time.time(), "budget_hours": 4.5}, indent=2), encoding="utf-8")
def stage_filter(member):
    relative = member.name.split("/work/stage/", 1)[-1]
    if member.isdir() or relative == "inputs.sha256" or relative in manifest:
        return member
    return None


with tarfile.open(experiment / "work/input.tar.gz", "w:gz") as archive:
    for path in sorted(stage.iterdir()):
        archive.add(path, arcname=path.name, filter=stage_filter)
print("STAGED_V6", manifest["rtl/tracking_channel_minimal.sv"])
if arguments.lab_bundle:
    # Standalone Linux tree, with fixtures and source. PDK data stays on its host.
    bundle = experiment / "work/LAB_INPUTS.tar.gz"
    selected = [repository / "student_release/student_release/rtl",
                repository / "rtl/bds_bb_6ch_pad_top.sv",
                repository / "synth/m2_isolate/acquisition_pcps_blackbox.sv",
                experiment / "lab", experiment / "scripts/reports.tcl",
                experiment / "LAB_RUNBOOK.md", stage]
    selected += [repository / "tb/fixtures/six_channel" / name
                 for name in ["six.if2", "recovery.if2"] + [f"bits{channel}.mem" for channel in range(6)]]
    with tarfile.open(bundle, "w:gz") as archive:
        for path in selected:
            if not path.exists():
                raise FileNotFoundError(path)
            if path.is_relative_to(experiment):
                name = Path('experiments/ic_eda_20261111_backend') / path.relative_to(experiment)
            elif path.is_relative_to(repository / 'tb/fixtures/six_channel'):
                name = Path('work/six_channel_20261102') / path.name
            else:
                name = path.relative_to(repository)
            if path == stage:
                archive.add(path, arcname=name.as_posix(), filter=stage_filter)
            else:
                archive.add(path, arcname=name.as_posix())
    digest = hashlib.sha256(bundle.read_bytes()).hexdigest()
    bundle.with_suffix(".gz.sha256").write_text(digest + "  LAB_INPUTS.tar.gz\n", encoding="utf-8", newline="\n")
    print("LAB_BUNDLE", bundle, bundle.stat().st_size, digest)
