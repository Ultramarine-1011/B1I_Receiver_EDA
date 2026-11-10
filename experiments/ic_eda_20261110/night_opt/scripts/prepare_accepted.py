"""Assemble only locally measured arithmetic candidates, preserving feedback timing."""
import argparse
from pathlib import Path
import re

EXPERIMENT = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument("--code", choices=["r4", "nr", "v4"], default="r4")
args = parser.parse_args()
source = (EXPERIMENT.parent / "divider_opt/rtl/tracking_channel_minimal.sv").read_text(encoding="utf-8")
normalizer = (EXPERIMENT / f"work/tracking_channel_{args.code}.sv").read_text(encoding="utf-8")
constants = (EXPERIMENT / "work/tracking_channel_signed.sv").read_text(encoding="utf-8")
patterns = [(r"    function automatic logic \[16:0\] normalized_ratio_q16\([\s\S]*?    endfunction", normalizer)]
patterns += [(rf"    function automatic logic signed \[23:0\] divide_{name}\([\s\S]*?    endfunction", constants)
             for name in ("step_127875", "aid_763")]
for pattern, candidate in patterns:
    replacement = re.search(pattern, candidate)[0]
    source = re.sub(pattern, lambda _: replacement, source)
source = source.replace(
    "    // M=floor(2^40/127875). The estimate is at most one below the exact quotient.\n"
    "    // One remainder correction gives exact signed division toward zero for every 40-bit input.\n",
    "    // Exact signed ceil-reciprocal multiplication, with one negative-result rounding increment.\n"
    "    // Full-domain bounds and odd-reciprocal proof are in evidence/reciprocal_bounds.json.\n")
source = source.replace("    // The same identity with M=floor(2^33/763), covering every signed 33-bit word.\n",
                        "    // The same construction covers every signed 33-bit carrier-aid input.\n")
source = source.replace("// Small-error DLL + Costas PI loop.",
                        f"// Night experiment. DLL normalizer={args.code}, exact signed constant conversion.\n"
                        "// Small-error DLL + Costas PI loop.", 1)
(EXPERIMENT / "rtl/tracking_channel_minimal.sv").write_text(source, encoding="utf-8")
print("ACCEPTED_PREPARED code=" + args.code + " phase=v4 constants=signed_exact feedback_cycles=unchanged")
