"""Verify retrieved IC_EDA evidence and write the experiment metrics."""

import hashlib
import json
import re
from pathlib import Path


root = Path(__file__).resolve().parents[1]
repo = root.parents[2]
run_name = Path((root / "latest_run.txt").read_text().strip()).name
reports = root / "runs" / run_name / "reports"
dc = reports / "dc"
vcs = reports / "vcs"


def read(path):
    return path.read_text(encoding="utf-8", errors="strict")


def number(pattern, text):
    return float(re.search(pattern, text, re.MULTILINE).group(1))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


dc_log = read(dc / "run.log")
vcs_log = read(vcs / "run.log")
assert read(dc / "exit_code.txt").strip() == "0"
assert read(vcs / "exit_code.txt").strip() == "0"
assert "IC_EDA_DC_COMPILE_DONE\n" in dc_log
assert "IC_EDA_UNMAPPED_CELLS 0\n" in dc_log
assert "B1I_PRN_REGRESSION_PASS\n" in vcs_log
assert len(re.findall(r"^PRN \d+: 2046 chips and wrap verified$", vcs_log, re.M)) == 32
for path in [dc / "run.log", vcs / "run.log", *dc.glob("*.rpt")]:
    assert not re.search(r"^(Error:|Error-|Fatal:|FATAL:)", read(path), re.M), path
assert read(dc / "check_design_post.rpt").strip() == "1"
assert "Warning:" not in read(dc / "check_timing.rpt")

source_count = 0
for line in read(reports / "source_sha256.txt").splitlines():
    expected, guest_path = line.split(maxsplit=1)
    relative = guest_path.split("/ic_eda_smoke_20261110/", 1)[1]
    assert digest(root / relative) == expected, relative
    source_count += 1
for path in [root / "rtl/b1i_prn_gen.sv", root / "tb/tb_b1i_prn_gen.sv", *root.glob("tb/vectors/*.mem")]:
    assert digest(path) == digest(repo / path.relative_to(root)), path

area_text = read(dc / "area.rpt")
area = number(r"^Total cell area:\s+([\d.]+)", area_text)
combinational = number(r"^Combinational area:\s+([\d.]+)", area_text)
sequential = number(r"^Noncombinational area:\s+([\d.]+)", area_text)
assert abs(area - combinational - sequential) < 0.00001
assert number(r"^Number of macros/black boxes:\s+(\d+)", area_text) == 0
timing = read(dc / "timing_max.rpt")
arrival = number(r"^  data arrival time\s+([\d.]+)", timing)
required = number(r"^  data required time\s+([\d.]+)", timing)
slack = number(r"^  slack \(MET\)\s+([\d.]+)", timing)
assert abs(required - arrival - slack) < 0.000001
violations = re.findall(r"(-[\d.]+) \(VIOLATED\)", read(dc / "constraints.rpt"))
assert len(violations) == 48
hold_tns = round(sum(map(float, violations)), 6)

dc_time = read(dc / "time.txt")
vcs_time = read(vcs / "time.txt")
elapsed_pattern = r"Elapsed \(wall clock\) time .*:\s+(\d+:\d+\.\d+)"
metadata = read(root / "reports/environment/library_metadata.txt")
final_probe = read(root / "reports/environment/final_probe.txt")
inv_size = re.search(r"^MACRO INVX1\n.*?SIZE ([\d.]+) BY ([\d.]+)", final_probe, re.M | re.S)
assert abs(float(inv_size[1]) * float(inv_size[2]) - 2.1168) < 0.000001
config_hashes = re.findall(r"[0-9a-f]{64}  /(?:home/ICer/\.bashrc|etc/sysconfig/network-scripts/ifcfg-ens33)", final_probe)
inventory = read(root / "reports/environment/system_tools.txt")
assert len(config_hashes) == 2
assert all(entry in inventory for entry in config_hashes)
assert "8022bc0d744d01fcc93b8c7387d9de6d33d674c29c81beba0e0496d2dde1702a" in metadata
assert "8022bc0d744d01fcc93b8c7387d9de6d33d674c29c81beba0e0496d2dde1702a" in final_probe
for line in read(root / "transfer_sha256.txt").splitlines():
    expected, guest_path = line.split(maxsplit=1)
    assert digest(root / Path(guest_path).name) == expected, guest_path
for document in [root / "REPORT.md", root / "STATUS.md", root / "WORKLOG.md"]:
    for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", read(document)):
        assert (document.parent / target).exists(), (document.name, target)

metrics = {
    "run": run_name,
    "git_head": "fb662d36e85e9cffe02a4b8f003887808f73007c",
    "top": "b1i_prn_gen",
    "library": "/home/ic_libs/TSMC.90/aci/sc-x/synopsys/typical.db",
    "pvt": {"process": "typical", "voltage_v": 1.0, "temperature_c": 25},
    "clock_period_ns": 10.0,
    "output_load_pf": 0.006604,
    "area_um2": area,
    "leaf_cells": 173,
    "sequential_cells": 41,
    "critical_path_arrival_ns": arrival,
    "worst_setup_slack_ns": slack,
    "setup_wns_ns": 0.0,
    "setup_tns_ns": 0.0,
    "hold_wns_ns": min(map(float, violations)),
    "hold_tns_ns_from_printed_endpoints": hold_tns,
    "hold_tns_ns_qor_rounded": -2.92,
    "hold_violating_endpoints": len(violations),
    "dc_exit_code": 0,
    "dc_elapsed": re.search(elapsed_pattern, dc_time)[1],
    "dc_peak_rss_kib": int(number(r"Maximum resident set size \(kbytes\):\s+(\d+)", dc_time)),
    "vcs_exit_code": 0,
    "vcs_elapsed": re.search(elapsed_pattern, vcs_time)[1],
    "vcs_peak_rss_kib": int(number(r"Maximum resident set size \(kbytes\):\s+(\d+)", vcs_time)),
    "verified_manifest_files": source_count,
    "results": {
        "ssh_command": "PASS",
        "scp_upload_download": "PASS",
        "rtl_functional_regression": "PASS",
        "logic_synthesis": "PASS",
        "timing_reports": "PASS",
        "setup_constraints": "PASS",
        "hold_constraints": "FAIL",
        "gate_level_simulation": "NOT_RUN",
        "physical_design": "NOT_RUN",
        "primetime_analysis": "NOT_RUN",
    },
}
(root / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps(metrics, ensure_ascii=False, indent=2))
print("IC_EDA_EVIDENCE_VERIFIED")
