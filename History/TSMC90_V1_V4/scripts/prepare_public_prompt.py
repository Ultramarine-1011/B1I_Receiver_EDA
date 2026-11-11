"""Replay previously recorded public-IF Prompt windows through the new RTL arithmetic."""
import csv
import hashlib
import json
from pathlib import Path
import os

experiment = Path(__file__).resolve().parent.parent
repository = Path(os.environ.get("B1I_PROJECT_ROOT", experiment.parent.parent.parent / "B1I_Receiver_EDA"))
source = repository / "reports/e_stage/real_tracking_loop.csv"
rows = list(csv.DictReader(source.open(encoding="utf-8")))
assert len(rows) == 995
for row in rows:
    ip, qp = int(row["ip"]), int(row["qp"])
    numerator = (qp << 16) * (-1 if ip < 0 else 1)
    denominator = abs(ip) + abs(qp)
    ratio = ((1 if numerator >= 0 else -1) * (abs(numerator) // denominator)) if denominator else 0
    assert (ratio * 10430) >> 16 == int(row["pll_q16"]), row
vectors = experiment / "work/public_prompt.txt"
vectors.write_text("".join(f"{row['ip']} {row['qp']} {row['pll_q16']}\n" for row in rows), encoding="utf-8")
result = {"source": str(source.relative_to(repository)), "windows": len(rows),
          "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
          "vectors_sha256": hashlib.sha256(vectors.read_bytes()).hexdigest(),
          "scope": "Previously recorded public-IF Prompt arithmetic replay, with no new RF acceptance claim"}
(experiment / "evidence/public_prompt_source.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
print("PUBLIC_PROMPT_PREPARE_PASS windows=995")
