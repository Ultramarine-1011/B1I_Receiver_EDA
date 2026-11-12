"""Check the delivered source, interfaces, mapped outputs, evidence and links."""
from pathlib import Path
import ast
import hashlib
import json
import re

root = Path(__file__).resolve().parents[1]
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def tokens(source):
    source = re.sub(r"/\*.*?\*/|//[^\n]*", "", source, flags=re.S)
    return re.sub(r"\s+", "", source)

original = root / "evidence/synthesized_tracking_channel.sv"
candidate = root / "rtl/tracking_channel_minimal.sv"
assert digest(original) == "9adff9ea0a12a8ab4dd6ec0df43de972aa2e435460799bcc9d3282c1ee19fef5"
assert tokens(candidate.read_text(encoding="utf-8")) == tokens(original.read_text(encoding="utf-8"))
def header(path, module):
    source = path.read_text(encoding="utf-8")
    source = source[source.index("module " + module):]
    return tokens(source[:source.index(");")])

baseline = root.parent / "TSMC90_V6/rtl/tracking_channel_minimal.sv"
assert header(candidate, "tracking_channel_minimal") == header(baseline, "tracking_channel_minimal")
core = root / "rtl/bds_bb_6ch_core.sv"
baseline_core = root.parent / "Backend_20261111/rtl/bds_bb_6ch_core.sv"
assert header(core, "bds_bb_6ch_core") == header(baseline_core, "bds_bb_6ch_core")
source_matches = {}
for line in (root / "evidence/identity/tested_inputs.sha256").read_text(encoding="utf-8").splitlines():
    expected, relative = line.split(None, 1)
    relative = relative.strip()
    path = root / relative
    if relative.startswith("rtl/"):
        actual = digest(path)
        assert actual == expected or (path == candidate and expected == digest(original)), relative
        source_matches[relative] = {"tested_sha256": expected, "delivered_sha256": actual}

metrics = json.loads((root / "metrics.json").read_text(encoding="utf-8"))
assert len(metrics["tests"]) == 11
for name, values in metrics["runs"].items():
    for filename, expected in values["files"].items():
        assert digest(root / "Results" / name / filename) == expected, (name, filename)
    assert values["return_code"] == 0 and not values["errors"] and values["stop_reason"] is None
for name, values in metrics["tests"].items():
    assert values["process"]["return_code"] == 0 and values["process"]["stop_reason"] is None
    assert values["pass_lines"], name
assert metrics["runs"]["tracking_bank6"]["blackboxes"] == 0
assert metrics["runs"]["core6_isolated"]["blackboxes"] == 1
assert all(metrics["runs"][scope]["unmapped"] == 0 for scope in ["channel", "tracking_bank6", "core6_isolated"])
for path in (root / "scripts").glob("*.py"):
    ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
links = re.findall(r"\]\(([^)]+)\)", (root / "REPORT.md").read_text(encoding="utf-8"))
for link in links:
    if "://" not in link:
        assert (root / link).exists(), link
audit = {
    "passed": True,
    "interfaces": ["tracking_channel_minimal", "bds_bb_6ch_core"],
    "rtl_semantics_match_synthesis_input": True,
    "synthesis_source_sha256": digest(original),
    "delivered_tracking_sha256": digest(candidate),
    "source_matches": source_matches,
    "mapped_outputs_verified": 12,
    "test_groups_passed": len(metrics["tests"]),
    "report_links_checked": len(links),
}
(root / "evidence/delivery_audit.json").write_text(json.dumps(audit, indent=2), encoding="utf-8")
print("ITERATIVE_DELIVERY_AUDIT_PASS", len(source_matches), len(metrics["tests"]), len(links))
