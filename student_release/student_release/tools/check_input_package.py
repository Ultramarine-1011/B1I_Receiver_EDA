"""Check the public IF2 package without exposing or using signal truth."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path, nargs="?", default=Path(__file__).parents[1])
    args = parser.parse_args()

    root = args.package.resolve()
    contract = json.loads((root / "input" / "input_contract.json").read_text(encoding="utf-8"))
    sample_file = root / "input" / contract["sample_file"]
    if not sample_file.exists():
        raise SystemExit(f"FAIL: missing {sample_file}")

    expected_samples = int(contract["sample_count"])
    expected_bytes = (expected_samples + 3) // 4
    actual_bytes = sample_file.stat().st_size
    if actual_bytes != expected_bytes:
        raise SystemExit(f"FAIL: byte count {actual_bytes} != {expected_bytes}")

    digest = hashlib.sha256()
    with sample_file.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)

    print(f"PASS package={root}")
    print(f"samples={expected_samples} bytes={actual_bytes}")
    print(f"sha256={digest.hexdigest()}")


if __name__ == "__main__":
    main()
