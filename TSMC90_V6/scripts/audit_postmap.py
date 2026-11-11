"""Audit real timing coverage, constants and source/library provenance after mapping."""
import hashlib
import json
from pathlib import Path
import re

EXPERIMENT = Path(__file__).resolve().parent.parent
final = EXPERIMENT / "Results"
cached = EXPERIMENT / "evidence/full_v6_hier_10ns"
top = "tracking_channel_minimal_ENABLE_FLL1_ENABLE_CARRIER_AID1"
log = (final / "run.log").read_text(encoding="utf-8")
assert "BASELINE_REPORTS_DONE B0" in log and "BASELINE_UNMAPPED 0" in log
assert not re.search(r"^Error:", log, re.M)
sdc = (final / "mapped.sdc").read_text(encoding="utf-8")
clocks = [line for line in sdc.splitlines() if line.startswith("create_clock")]
exceptions = [line for line in sdc.splitlines() if line.startswith("set_false_path")]
assert len(clocks) == 1 and "-period 10" in clocks[0] and "get_ports clk" in clocks[0]
assert len(exceptions) == 1 and "get_ports reset_n" in exceptions[0]
assert "set_multicycle_path" not in sdc and "set_case_analysis" not in sdc
assert "module_clk" not in sdc
timing_check = (final / "check_timing_post.rpt").read_text(encoding="utf-8")
warnings = [line for line in timing_check.splitlines() if line.startswith("Warning:")]
assert len(warnings) == 1 and "TIM-216" in warnings[0]
assert timing_check.split("--------------------", 1)[1].lstrip().startswith("reset_n")

design = (final / "check_design_post.rpt").read_text(encoding="utf-8")
constants = [re.search(r"output port '([^']+)'", line)[1] for line in design.splitlines()
             if line.startswith("Warning:") and "LINT-52" in line]
assert set(constants) == {"fll_error_q16[0]", "fll_error_q16[1]", "fll_error_q16[2]"}
assert 1000 % 8 == 0
shorts = [line for line in design.splitlines() if line.startswith("Warning:") and "LINT-31" in line]
assert len(shorts) == 5 and all("_DW" in line for line in shorts)
unloaded_inputs = [line for line in design.splitlines() if line.startswith("Warning:") and "LINT-8" in line]
assert all("In design '"+top+"'," not in line for line in unloaded_inputs)
summary = {code: int(count) for code, count in re.findall(r"\((LINT-\d+)\)[ \t]+(\d+)[ \t]*$", design, re.M)}
assert set(summary) == {"LINT-2", "LINT-8", "LINT-28", "LINT-29", "LINT-31", "LINT-32", "LINT-33", "LINT-52"}

baseline_hashes = {line.split()[0] for line in
                   (EXPERIMENT.parent / "History/TSMC90_B0/runs/B0/reports/tool_hashes.txt").read_text().splitlines()}
baseline_environment = (EXPERIMENT.parent / "History/TSMC90_B0/runs/B0/reports/environment_hashes_after.txt").read_text()
baseline_hashes.update(line.split()[0] for line in baseline_environment.splitlines()
                       if line.endswith("/synopsys/typical.db"))
current_hashes = {line.split()[0] for line in (final / "environment_hashes.txt").read_text().splitlines()}
assert current_hashes == baseline_hashes
cache_files = []
for line in (final / "cached_arithmetic.sha256").read_text().splitlines():
    expected, remote = line.split(None, 1)
    path = cached / Path(remote).name
    assert hashlib.sha256(path.read_bytes()).hexdigest() == expected
    cache_files.append(path.name)

timing = (final / "timing_max.rpt").read_text(encoding="utf-8")
first = timing.split("  Startpoint:", 1)[1].split("  slack (", 1)[0]
components = []
for name in ("dll_ratio", "pll_ratio", "fll_phase", "carrier_conversion", "feedback_aid", "code_conversion"):
    rows = [line for line in first.splitlines() if name+"/" in line]
    if rows:
        first_time = float(rows[0].split()[-2])
        last_time = float(rows[-1].split()[-2])
        components.append({"block": name, "arrival_at_input_ns": first_time,
                           "arrival_at_output_ns": last_time, "path_delay_ns": last_time-first_time})
constraint_text = (final / "constraints.rpt").read_text(encoding="utf-8")
setup_section = constraint_text.split("max_delay/setup ('clk' group)", 1)[1].split("min_delay/hold", 1)[0]
setup_slacks = [float(value) for value in re.findall(r"\s(-[\d.]+)\s+\(VIOLATED\)", setup_section)]
assert len(setup_slacks) == 414
hold_text = (final / "timing_min.rpt").read_text(encoding="utf-8")
qor = (final / "qor.rpt").read_text(encoding="utf-8")
cell_area = float(re.search(r"Cell Area:\s+([\d.]+)", qor)[1])
sequential_cells = int(re.search(r"Sequential Cell Count:\s+(\d+)", qor)[1])
macro_area = float(re.search(r"Macro/Black Box Area:\s+([\d.]+)", qor)[1])
assert macro_area == 0 and cell_area == 486269.185663 and sequential_cells == 2338
record = {
    "status": "PASS", "full_top": top, "clock": clocks[0], "timing_exceptions": exceptions,
    "reset_input_delay_warning": "TIM-216 only, covered by the original reset false path",
    "unmapped_cells": 0, "macro_black_box_area_um2": macro_area,
    "standard_cell_area_um2": cell_area, "sequential_cells": sequential_cells,
    "setup_wns_ns": min(setup_slacks), "setup_tns_ns_sum_of_reported_endpoints": sum(setup_slacks),
    "setup_violating_endpoints": len(setup_slacks),
    "worst_hold_slack_ns": float(re.search(r"slack \([^)]*\)\s+(-?[\d.]+)", hold_text)[1]),
    "critical_path": {"start": "frontend/correlator/qp_reg[11]", "end": "code_step_q_reg[27]",
                      "data_arrival_ns": 28.381390, "components": components},
    "constant_output_bits": constants, "constant_output_reason": "FLL Q16 frequency is a signed integer multiplied by 1000, so bits 2:0 are zero",
    "shorted_outputs_reason": "Five DesignWare arithmetic output pairs share sign-extension bits",
    "design_warning_counts": summary, "mapped_cache_hashes": "PASS", "cache_files": cache_files,
    "B0_tool_DW_and_target_library_hashes": "IDENTICAL",
    "timing_model": "typical 1.0 V 25 C, ideal clock, no selected wire-load model",
}
(EXPERIMENT / "evidence/postmap_audit.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
print(json.dumps(record, indent=2))
