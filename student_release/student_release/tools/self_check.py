"""Student-side functional self-check for the public fixed-record format."""
from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path

from decode_records import decode


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path, help="receiver_records.bin")
    parser.add_argument("--expected-samples", type=int, required=True)
    parser.add_argument("--minimum-acquisitions", type=int, default=4)
    parser.add_argument("--require-tracking", action="store_true")
    parser.add_argument("--require-navigation", action="store_true")
    parser.add_argument("--require-common-observation", action="store_true")
    args = parser.parse_args()

    data = args.input.read_bytes()
    if not data or len(data) % 32:
        raise SystemExit("FAIL: output is empty or not aligned to 32-byte records")
    records = [decode(data[n:n + 32]) for n in range(0, len(data), 32)]
    counts = Counter(str(item["type"]) for item in records)

    ends = [item for item in records if item["type"] == "end"]
    if len(ends) != 1 or records[-1]["type"] != "end":
        raise SystemExit("FAIL: output must contain exactly one final end record")
    end = ends[0]
    if int(end["sample_index"]) != args.expected_samples:
        raise SystemExit(
            f"FAIL: end sample count {end['sample_index']} != {args.expected_samples}"
        )
    if end.get("underrun") or end.get("overflow"):
        raise SystemExit("FAIL: end record reports underrun or overflow")

    acquisitions = [item for item in records if item["type"] == "acquisition"]
    detected_prns = sorted({int(item["prn"]) for item in acquisitions if item.get("detected")})
    if len(detected_prns) < args.minimum_acquisitions:
        raise SystemExit(
            f"FAIL: detected PRNs {detected_prns}; "
            f"need at least {args.minimum_acquisitions}"
        )

    locked = [item for item in records if item["type"] == "tracking" and item.get("locked")]
    navigation = [item for item in records if item["type"] == "navigation"]
    common = [item for item in records if item["type"] == "common_observation"]
    common_valid = [item for item in common if item.get("measurement_valid")]

    if args.require_tracking and not locked:
        raise SystemExit("FAIL: no locked tracking record")
    if args.require_navigation and not navigation:
        raise SystemExit("FAIL: no navigation record")
    if args.require_common_observation and not common_valid:
        raise SystemExit("FAIL: no measurement-valid common observation")

    keys = set()
    for item in common:
        key = (int(item["common_epoch_id"]), int(item["prn"]))
        if key in keys:
            raise SystemExit(f"FAIL: duplicate common observation {key}")
        keys.add(key)

    print("PASS student self-check")
    print(f"records={len(records)} types={dict(counts)}")
    print(f"detected_prns={detected_prns}")
    print(f"locked_tracking={len(locked)} navigation={len(navigation)} "
          f"common={len(common)} measurement_valid={len(common_valid)}")


if __name__ == "__main__":
    main()
