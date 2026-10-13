"""Structural checks for a receiver binary capture."""
from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path

from decode_records import decode


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("--expected-samples", type=int, required=True)
    parser.add_argument("--require-tracking", action="store_true")
    parser.add_argument("--require-navigation", action="store_true")
    parser.add_argument("--require-common-observation", action="store_true")
    parser.add_argument("--minimum-acquisitions", type=int, default=1)
    args = parser.parse_args()

    data = args.input.read_bytes()
    if not data or len(data) % 32:
        raise SystemExit("FAIL: output is empty or not aligned to 32-byte records")
    records = [decode(data[n : n + 32]) for n in range(0, len(data), 32)]
    counts = Counter(str(item["type"]) for item in records)
    acquisitions = [item for item in records if item["type"] == "acquisition"]
    ends = [item for item in records if item["type"] == "end"]

    detected_prns = {int(item["prn"]) for item in acquisitions if item.get("detected")}
    if len(detected_prns) < args.minimum_acquisitions:
        raise SystemExit(
            f"FAIL: successful acquisitions {len(detected_prns)} "
            f"< required {args.minimum_acquisitions}; PRNs={sorted(detected_prns)}"
        )
    if len(ends) != 1:
        raise SystemExit(f"FAIL: expected one end record, got {len(ends)}")
    if records[-1]["type"] != "end":
        raise SystemExit("FAIL: end record is not the final record")
    end = ends[0]
    if end["sample_index"] != args.expected_samples:
        raise SystemExit(
            f"FAIL: end sample count {end['sample_index']} != {args.expected_samples}"
        )
    if end.get("underrun") or end.get("overflow"):
        raise SystemExit("FAIL: end record reports underrun or overflow")
    if args.require_tracking and not any(
        item["type"] == "tracking" and item.get("locked") for item in records
    ):
        raise SystemExit("FAIL: no locked tracking record")
    if args.require_navigation and not any(
        item["type"] == "navigation" for item in records
    ):
        raise SystemExit("FAIL: no navigation record")
    if args.require_common_observation and not any(
        item["type"] == "common_observation" and item.get("active") for item in records
    ):
        raise SystemExit("FAIL: no active common-epoch observation record")

    epoch_samples: dict[int, set[int]] = {}
    epoch_prns: set[tuple[int, int]] = set()
    for item in records:
        if item["type"] != "common_observation":
            continue
        epoch_id = int(item["common_epoch_id"])
        sample = int(item["sample_index"])
        if sample != epoch_id * 16_368_000:
            raise SystemExit(
                f"FAIL: common epoch {epoch_id} sample {sample} is not on its one-second boundary"
            )
        key = (epoch_id, int(item["prn"]))
        if key in epoch_prns:
            raise SystemExit(f"FAIL: duplicate common observation for epoch/PRN {key}")
        epoch_prns.add(key)
        epoch_samples.setdefault(epoch_id, set()).add(sample)
    bad_epochs = {epoch: samples for epoch, samples in epoch_samples.items() if len(samples) != 1}
    if bad_epochs:
        raise SystemExit(f"FAIL: common epoch contains different sample indices: {bad_epochs}")

    print(f"PASS records={len(records)} bytes={len(data)} types={dict(counts)}")


if __name__ == "__main__":
    main()
