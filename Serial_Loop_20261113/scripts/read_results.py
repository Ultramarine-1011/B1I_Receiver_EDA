"""Extract the local VMware results and derive metrics from actual tool reports."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import tarfile

root = Path(__file__).resolve().parents[1]
collected = root / "work/collected"
collected.mkdir(parents=True, exist_ok=True)
for name in ["v2_results", "v2_tests", "v1_evidence"]:
    archive = root / "work" / (name + ".tar.gz")
    with tarfile.open(archive) as stream:
        stream.extractall(collected / name, filter="data")
results = {}
for source, name in [("channel_retry1", "channel"), ("bank_retry1", "tracking_bank6"),
                     ("core_retry1", "core6_isolated"), ("teacher_capture", "teacher_capture")]:
    directory = collected / "v2_results" / source / "reports"
    destination = root / "Results" / name
    shutil.copytree(directory, destination, dirs_exist_ok=True)
    area = (directory / "area.rpt").read_text()
    log = (directory / "run.log").read_text()
    process = json.loads((directory / "result.json").read_text())
    clock = (directory / "time.txt").read_text()
    def match(pattern, text, conversion=float):
        return conversion(re.search(pattern, text).group(1))
    elapsed = match(r"Elapsed \(wall clock\) time.*?:\s*([\d:.]+)", clock, str)
    wall_seconds = 0.0
    for part in elapsed.split(":"):
        wall_seconds = wall_seconds * 60 + float(part)
    data = {
        "area_um2": match(r"Total cell area:\s*([\d.]+)", area),
        "setup_wns_ns": match(r"slack \([^)]*\)\s*([-\d.]+)", (directory / "timing_max.rpt").read_text()),
        "hold_wns_ns": match(r"slack \([^)]*\)\s*([-\d.]+)", (directory / "timing_min.rpt").read_text()),
        "dc_wall_s": wall_seconds,
        "supervised_wall_s": process["monotonic_elapsed_s"],
        "peak_rss_kib": match(r"Maximum resident set size \(kbytes\):\s*(\d+)", clock, int),
        "return_code": process["return_code"],
        "stop_reason": process["stop_reason"],
        "errors": re.findall(r"^Error:.*|^Fatal:.*", log, re.M),
        "files": {name: hashlib.sha256((directory / name).read_bytes()).hexdigest()
                  for name in ["mapped.v", "mapped.ddc", "mapped.sdc"]},
    }
    cells = re.search(r"BACKEND_LEAF (\d+) UNMAPPED (\d+) BLACKBOX (\d+)", log)
    if cells:
        data.update(dict(zip(["leaf_cells", "unmapped", "blackboxes"], map(int, cells.groups()))))
    qor = directory / "qor.rpt"
    if qor.exists():
        text = qor.read_text()
        data["logic_levels"] = match(r"Levels of Logic:\s*([\d.]+)", text)
        data["sequential_cells"] = match(r"Sequential Cell Count:\s*(\d+)", text, int)
        data["setup_violations"] = match(r"No. of Violating Paths:\s*([\d.]+)", text)
        data["hold_violations"] = match(r"No. of Hold Violations:\s*([\d.]+)", text)
    assert process["return_code"] == 0 and process["stop_reason"] is None and not data["errors"], name
    results[name] = data
tests = {}
for log in sorted((collected / "v2_tests").glob("*/simulation/run.log")):
    name = log.parents[1].name
    if name in ["tracking_minimal", "tracking_legacy"]:
        continue
    name = name.removesuffix("_counter")
    process = json.loads((log.parent / "result.json").read_text())
    tests[name] = {
        "process": process,
        "pass_lines": re.findall(r"^.*_PASS.*$", log.read_text(), re.M),
    }
    assert process["return_code"] == 0 and process["stop_reason"] is None and tests[name]["pass_lines"], name
assert set(tests) == {"unit_normalize", "unit_aid", "if_fifo", "tracking_equivalence", "tracking_minimal", "tracking_legacy",
                      "six_paced", "six_nominal", "six_recovery", "mapped_normalize", "mapped_aid"}
baseline = json.loads((root.parent / "Backend_20261111/metrics.json").read_text())["runs"]["clean_v6_channel"]
comparisons = {
    "single_channel_area_reduction_percent": 100 * (1 - results["channel"]["area_um2"] / baseline["area_um2"]),
    "single_channel_logic_depth_reduction_percent": 100 * (1 - results["channel"]["logic_levels"] / baseline["logic_levels"]),
    "single_channel_peak_rss_reduction_percent": 100 * (1 - results["channel"]["peak_rss_kib"] / baseline["peak_rss_kib"]),
    "single_channel_setup_improvement_ns": results["channel"]["setup_wns_ns"] - baseline["setup_wns_ns"],
    "bank_area_reduction_percent": 100 * (1 - results["tracking_bank6"]["area_um2"] / 2998743.597369),
    "isolated_core_area_reduction_percent": 100 * (1 - results["core6_isolated"]["area_um2"] / 4133400.635689),
    "isolated_core_setup_improvement_ns": results["core6_isolated"]["setup_wns_ns"] + 10.948631,
}
report = {"technology": "TSMC90 typical", "clock_ns": 10, "runs": results, "tests": tests,
          "comparisons": comparisons, "baseline_single_channel": baseline,
          "scope": {"tracking_bank6": "six independently configured complete trackers",
                    "core6_isolated": "six trackers, control, navigation, 64-sample IF FIFO, one acquisition blackbox, no PAD"}}
(root / "metrics.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
shutil.copytree(collected / "v2_results/collection", root / "evidence/identity", dirs_exist_ok=True)
print(json.dumps({"runs": results, "comparisons": comparisons, "test_pass_lines":
                  {name: value["pass_lines"] for name, value in tests.items()}}, indent=2))
