"""Independently recompute discriminator results from actual closed-loop I/Q."""
import csv
import hashlib
import json
from pathlib import Path

experiment = Path(__file__).resolve().parent.parent


def truncate(numerator, denominator):
    return (1 if numerator >= 0 else -1) * (abs(numerator) // denominator) if denominator else 0


summaries = []
for path in [experiment / "work/run_tracking/tracking_loop.csv", experiment / "work/run_fll/tracking_loop.csv"]:
    count = 0
    code_signs, phase_signs = set(), set()
    with path.open(encoding="utf-8") as stream:
        for row in csv.DictReader(stream):
            values = {name: int(value) for name, value in row.items()}
            early = values["ie"] ** 2 + values["qe"] ** 2
            late = values["il"] ** 2 + values["ql"] ** 2
            code = truncate(truncate((early-late) << 16, early+late) * 11, 32)
            phase = truncate((values["qp"] << 16) * (-1 if values["ip"] < 0 else 1),
                             abs(values["ip"]) + abs(values["qp"]))
            phase = (phase * 10430) >> 16
            assert code == values["dll_error_q16"], (path, count, "DLL", code, values)
            assert phase == values["pll_error_q16"], (path, count, "PLL", phase, values)
            assert values["feedback_ref"] - values["window_ref"] == 16369, (path, count, "timing")
            code_signs.add((code > 0) - (code < 0))
            phase_signs.add((phase > 0) - (phase < 0))
            count += 1
    assert count == 1998, (path, count)
    summaries.append({"file": str(path.relative_to(experiment)), "windows": count,
                      "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                      "code_signs": sorted(code_signs), "phase_signs": sorted(phase_signs)})
assert len(summaries) == 2, summaries
result = {"status": "PASS", "scenarios": summaries, "feedback_ref_minus_window_ref": 16369}
(experiment / "evidence/scenario_arithmetic.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
print(json.dumps(result, indent=2))
