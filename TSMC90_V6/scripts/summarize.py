"""Extract final metrics only from completed DC reports and GNU time output."""
import json
from pathlib import Path
import re

EXPERIMENT = Path(__file__).resolve().parent.parent


def number(pattern, text):
    match = re.search(pattern, text)
    return float(match[1]) if match else None


def summarize(directory):
    result = json.loads((directory / "result.json").read_text(encoding="utf-8"))
    record = {"label": directory.name, "process": result}
    timer = (directory / "time.txt").read_text(encoding="utf-8")
    elapsed = re.search(r"Elapsed \(wall clock\) time [^\n]+: ([\d:.]+)", timer)
    if elapsed:
        parts = [float(value) for value in elapsed[1].split(":")]
        seconds = 0
        for part in parts:
            seconds = 60*seconds+part
        record["wall_seconds"] = seconds
    record["peak_rss_kib"] = number(r"Maximum resident set size \(kbytes\): (\d+)", timer)
    log = (directory / "run.log").read_text(encoding="utf-8", errors="replace")
    record["dc_error_lines"] = re.findall(r"^Error:[^\n]*", log, re.M)
    host_path = directory / "host_result.json"
    if host_path.exists():
        host = json.loads(host_path.read_text(encoding="utf-8"))
        record["host_deadline_signalled"] = host["host_deadline_signalled"]
        record["host_elapsed_s"] = host["host_elapsed_s"]
    completed = result["return_code"] == 0 and result["stop_reason"] is None
    record["completed"] = completed and "REPORTS_DONE" in log and not record["dc_error_lines"]
    if re.search(r"^(?:HIER|CACHED)_PREFLIGHT_PASS$", log, re.M):
        record["stage"] = "elaboration_only"
        record["completed"] = completed and not record["dc_error_lines"]
        return record
    if not record["completed"]:
        return record
    qor = (directory / "qor.rpt").read_text(encoding="utf-8")
    timing = (directory / "timing_max.rpt").read_text(encoding="utf-8")
    record["cell_area_um2"] = number(r"Cell Area:\s+([\d.]+)", qor)
    record["critical_path_length_ns"] = number(r"Critical Path Length:\s+([\d.]+)", qor)
    record["logic_levels"] = number(r"Levels of Logic:\s+([\d.]+)", qor)
    record["worst_setup_slack_ns"] = number(r"slack \([^)]*\)\s+(-?[\d.]+)", timing)
    record["setup_wns_ns"] = min(0, record["worst_setup_slack_ns"])
    record["setup_tns_ns"] = -abs(number(r"Total Negative Slack:\s+(-?[\d.]+)", qor))
    record["setup_violating_paths"] = number(r"No. of Violating Paths:\s+([\d.]+)", qor)
    record["worst_hold_slack_ns"] = number(r"Worst Hold Violation:\s+(-?[\d.]+)", qor)
    record["hold_violating_paths"] = number(r"No. of Hold Violations:\s+([\d.]+)", qor)
    start = re.search(r"Startpoint:\s+([^\n]+)", timing)
    end = re.search(r"Endpoint:\s+([^\n]+)", timing)
    record["startpoint"] = start[1] if start else None
    record["endpoint"] = end[1] if end else None
    record["unmapped_cells"] = number(r"(?:BASELINE|PROBE)_UNMAPPED (\d+)", log)
    return record


if __name__ == "__main__":
    records = [summarize(path.parent) for path in sorted((EXPERIMENT / "evidence").glob("*/result.json"))]
    (EXPERIMENT / "metrics.json").write_text(json.dumps(records, indent=2), encoding="utf-8")
    for record in records:
        print(record["label"], "complete=" + str(record["completed"]),
              "area=" + str(record.get("cell_area_um2")), "wall=" + str(record.get("wall_seconds")))
