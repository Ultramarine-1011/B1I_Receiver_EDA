"""Extract final reports and measured resource data without using progress tables."""
import csv
import datetime
import hashlib
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent


def number(pattern, content):
    match = re.search(pattern, content, re.MULTILINE)
    return float(match.group(1)) if match else None


metrics = {}
for stage in ("B0", "B1"):
    report = root / "runs" / stage / "reports"
    if not (report / "result.json").exists():
        metrics[stage] = json.loads((report / "gate.json").read_text())
        continue
    result = json.loads((report / "result.json").read_text())
    time_text = (report / "time.txt").read_text()
    wall = re.search(r"Elapsed \(wall clock\) time \(h:mm:ss or m:ss\):\s*([\d:.]+)", time_text)
    wall_seconds = None
    if wall:
        wall_seconds = 0.0
        for part in wall.group(1).split(":"):
            wall_seconds = 60*wall_seconds+float(part)
    samples = list(csv.DictReader((report / "resources.csv").open()))
    result.update({
        "dc_command_wall_s": wall_seconds,
        "time_peak_rss_kib": number(r"Maximum resident set size \(kbytes\):\s*(\d+)", time_text),
        "user_cpu_s": number(r"User time \(seconds\):\s*([\d.]+)", time_text),
        "system_cpu_s": number(r"System time \(seconds\):\s*([\d.]+)", time_text),
        "vm_min_mem_available_kib": min(int(row["mem_available_kib"]) for row in samples),
        "sampled_peak_cpu_pct_1core": max(float(row["tree_cpu_pct_1core"]) for row in samples),
        "area_um2": None,
        "critical_path_ns": None,
        "worst_setup_slack_ns": None,
        "setup_wns_ns": None,
        "setup_tns_ns": None,
        "hold_wns_ns": None,
        "hold_tns_ns": None,
        "hold_violating_endpoints": None,
    })
    if (report / "dc_process.csv").exists():
        direct = list(csv.DictReader((report / "dc_process.csv").open()))
        result["direct_dc_peak_hwm_kib"] = max(int(row["hwm_kib"]) for row in direct)
        result["direct_dc_last_cpu_ticks"] = int(direct[-1]["cpu_ticks"])
    if (report / "completion_observation.json").exists():
        observation = json.loads((report / "completion_observation.json").read_text())
        command = json.loads((report / "command.json").read_text())
        started = datetime.datetime.fromisoformat(command["started_utc"].replace("Z", "+00:00")).timestamp()
        result["observed_guest_wall_to_final_log_s"] = observation["log_final_mtime_epoch_s"]-started
        result["wall_measurement"] = "UTC start timestamp to final termination-message log mtime, includes stop handling"
        result["peak_memory_measurement"] = "5-second cumulative DC VmHWM sampling, GNU time report unavailable"
    if result["status"] == "PASS":
        area = (report / "area.rpt").read_text()
        timing = (report / "timing_max.rpt").read_text()
        qor = (report / "qor.rpt").read_text()
        result["area_um2"] = number(r"Total cell area:\s*([\d.]+)", area)
        result["critical_path_ns"] = number(r"data arrival time\s+([-\d.]+)", timing)
        result["worst_setup_slack_ns"] = number(r"slack \([A-Z]+\)\s+([-\d.]+)", timing)
        result["setup_wns_ns"] = min(0, result["worst_setup_slack_ns"])
        result["setup_tns_ns"] = -abs(number(r"Design\s+WNS:\s*[-\d.]+\s+TNS:\s*([-\d.]+)", qor))
        result["leaf_cell_count"] = int(number(r"Leaf Cell Count:\s*(\d+)", qor))
        result["combinational_area_um2"] = number(r"Combinational Area:\s*([\d.]+)", qor)
        result["sequential_area_um2"] = number(r"Noncombinational Area:\s*([\d.]+)", qor)
        result["hold_wns_ns"] = -abs(number(r"Design \(Hold\)\s+WNS:\s*([-\d.]+)", qor))
        result["hold_tns_ns"] = -abs(number(r"Design \(Hold\)\s+WNS:\s*[-\d.]+\s+TNS:\s*([-\d.]+)", qor))
        result["hold_violating_endpoints"] = int(number(r"No\. of Hold Violations:\s*([\d.]+)", qor))
    metrics[stage] = result

input_hashes = {}
for line in (root / "frozen_sha256.txt").read_text().splitlines():
    expected, relative = line.split("  ", 1)
    actual = hashlib.sha256((root / relative).read_bytes()).hexdigest()
    input_hashes[relative] = actual == expected
if not all(input_hashes.values()):
    raise SystemExit("Frozen input hash mismatch")
output = {"stages": metrics, "frozen_files_verified": len(input_hashes)}
(root / "metrics.json").write_text(json.dumps(output, indent=2)+"\n")
print(json.dumps(output, indent=2))
