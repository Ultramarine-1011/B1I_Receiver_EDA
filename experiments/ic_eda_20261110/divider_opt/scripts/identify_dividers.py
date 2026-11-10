"""Isolate each original variable division for DC width attribution, without mapping."""
from pathlib import Path

experiment = Path(__file__).resolve().parent.parent
source = (experiment / "work/norm_probes.sv").read_text(encoding="utf-8").split("module norm_optimized", 1)[0]
probes = []
for kind in ("code", "phase"):
    lines = []
    for line in source.replace("module norm_original", "module identify_" + kind, 1).splitlines():
        text = line.strip()
        if kind == "code" and text.startswith(("phase_numerator=", "if(ip<0)", "dphase=")):
            continue
        if kind == "phase" and text.startswith(("code_numerator=", "dcode=")):
            continue
        if text == "always_comb begin":
            lines.append(line)
            lines.append("        " + ("dphase=0;" if kind == "code" else "dcode=0;"))
        else:
            lines.append(line)
    probes.append("\n".join(lines))
(experiment / "work/identify_dividers.sv").write_text("\n".join(probes), encoding="utf-8")
