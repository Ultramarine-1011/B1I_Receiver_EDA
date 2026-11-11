"""Check current-source evidence, arithmetic bounds and protected repository scope."""
import argparse
import hashlib
import json
from pathlib import Path
import os
import re
import subprocess

EXPERIMENT = Path(__file__).resolve().parent.parent
REPOSITORY = Path(os.environ.get("B1I_PROJECT_ROOT", EXPERIMENT.parent.parent / "B1I_Receiver_EDA"))
parser = argparse.ArgumentParser()
parser.add_argument("--require-full", action="store_true")
args = parser.parse_args()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


cases = [
    ("v6/arithmetic", "DIVIDER_EQUIVALENCE_PASS checks=214883"),
    ("v6/constant", "CONSTANT_DIVISION_EQUIVALENCE_PASS checks=210169"),
    ("v6/loop", "LOOP_EQUIVALENCE_PASS checks=100625 fields=18"),
    ("hier_preflight/tracking", "TRACKING_MINIMAL_PASS cases=2"),
    ("v6/fll", "TRACKING_MINIMAL_PASS cases=2"),
    ("hier_preflight/six", "SIX_RECEIVER_PASS mode=nominal samples=49104000 cycles=50518067"),
    ("hier_preflight/recovery", "SIX_RECEIVER_PASS mode=recovery samples=49104000 cycles=50516937"),
]
checks = []
for name, marker in cases:
    directory = EXPERIMENT / "evidence" / name
    log = (directory / "run.log").read_text(encoding="utf-8")
    assert marker in log, name
    assert not re.search(r"MISMATCH|%Error|SIX_RECEIVER_FAIL|Fatal:", log), name
    assert "EXIT_CODE 0" in log, name
    manifest = json.loads((directory / "sources.json").read_text(encoding="utf-8-sig"))
    for source in manifest["sources"]:
        original = source["path"].replace("\\", "/")
        relative = original.split("/windows-vmware-br-br-br-br/windows-vmware-br-br-br-br/", 1)[-1]
        if relative.startswith("experiments/ic_eda_20261110/night_opt/"):
            path = EXPERIMENT / relative.removeprefix("experiments/ic_eda_20261110/night_opt/")
        else:
            path = REPOSITORY / relative
        if path == EXPERIMENT / "scripts/run_local.ps1":
            frozen = subprocess.check_output(["git", "show", "b8b887c:" + relative], cwd=EXPERIMENT)
            assert hashlib.sha256(frozen.replace(b"\n", b"\r\n")).hexdigest() == source["sha256"].lower() or hashlib.sha256(frozen).hexdigest() == source["sha256"].lower()
        else:
            assert digest(path) == source["sha256"].lower(), (name, path)
    checks.append({"case": name, "marker": marker, "status": "PASS"})

for name in ("compile_exit.txt", "run_exit.txt", "loop_compile_exit.txt", "loop_run_exit.txt",
             "constant_compile_exit.txt", "constant_run_exit.txt"):
    assert (EXPERIMENT / "evidence/vcs_v6" / name).read_text().strip() == "0", name

for proof in json.loads((EXPERIMENT / "evidence/reciprocal_bounds.json").read_text()):
    divisor = proof["divisor"]
    maximum = proof["maximum_magnitude"]
    scale = 1 << proof["shift"]
    multiplier = proof["multiplier"]
    error = divisor*multiplier-scale
    quotient, remainder = divmod(maximum, divisor)
    bound = max((quotient-1)*error+(divisor-1)*multiplier, quotient*error+remainder*multiplier)
    assert 0 <= error < divisor and bound == proof["maximum_excess"] < scale
    assert multiplier % 2 == 1 and maximum < scale

v4 = (EXPERIMENT.parent / "History/TSMC90_V1_V4/rtl/tracking_channel_minimal.sv").read_text(encoding="utf-8")
current = (EXPERIMENT / "rtl/tracking_channel_minimal.sv").read_text(encoding="utf-8")
assert v4[v4.index("module tracking_channel_minimal"):v4.index("    localparam")] == current[
    current.index("module tracking_channel_minimal"):current.index("    localparam")]
assert v4[v4.index("    always_ff"):v4.index("endmodule")] == current[
    current.index("    always_ff"):current.index("endmodule")]
assert digest(EXPERIMENT / "rtl/tracking_channel_minimal.sv") == "ad3766423995a8ee7d8d2da0c4c87e271df794d25aea277517ed1994e3abee88"

protected = []
for line in (EXPERIMENT.parent / "History/TSMC90_B0/frozen_sha256.txt").read_text().splitlines():
    expected, relative = line.split(None, 1)
    if relative.startswith("sources/"):
        frozen = EXPERIMENT.parent / "History/TSMC90_B0" / relative
        owning = REPOSITORY / relative.removeprefix("sources/")
        assert digest(frozen) == expected and digest(owning) == expected, relative
        protected.append(relative)

archive = json.loads((EXPERIMENT / "evidence/module_archive.json").read_text())
assert digest(EXPERIMENT / "evidence/module_dc.tar.gz") == archive["sha256"]
final = EXPERIMENT / "Results"
complete = (final / "result.json").exists()
if complete:
    result = json.loads((final / "result.json").read_text())
    log = (final / "run.log").read_text(encoding="utf-8")
    complete = result["return_code"] == 0 and result["stop_reason"] is None
    complete = complete and "BASELINE_REPORTS_DONE B0" in log and "BASELINE_UNMAPPED 0" in log
    if complete:
        assert not re.search(r"^Error:", log, re.M)
        for name in ("mapped.v", "mapped.ddc", "mapped.sdc", "area.rpt", "qor.rpt",
                     "timing_max.rpt", "timing_min.rpt", "constraints.rpt", "check_timing_post.rpt"):
            assert (final / name).stat().st_size > 0, name
if args.require_full:
    assert complete, "Complete channel synthesis is unavailable"
record = {"functional_checks": checks, "protected_sources_checked": len(protected),
          "arithmetic_proofs": "PASS", "top_ports_parameters_and_sequential_block": "IDENTICAL",
          "current_rtl_sha256": digest(EXPERIMENT / "rtl/tracking_channel_minimal.sv"),
          "full_channel_synthesis_complete": bool(complete)}
(EXPERIMENT / "evidence/delivery_checks.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
print(json.dumps(record, indent=2))
