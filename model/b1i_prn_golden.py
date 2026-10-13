#!/usr/bin/env python3
"""Independent software model for BeiDou B1I MEO/IGSO ranging codes.

The model represents ICD stages as a Python list in stage-1 through stage-11
order.  This differs from the packed RTL representation and produces VCS
reference vectors plus a SHA-256 manifest.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple


INITIAL: Tuple[int, ...] = tuple(int(bit) for bit in "01010101010")
G1_FEEDBACK_TAPS = (1, 7, 8, 9, 10, 11)
G2_FEEDBACK_TAPS = (1, 2, 3, 4, 5, 8, 9, 11)

G2_PHASE_TAPS: Dict[int, Tuple[int, int]] = {
    6: (1, 9),
    7: (1, 10),
    8: (1, 11),
    9: (2, 7),
    10: (3, 4),
    11: (3, 5),
    12: (3, 6),
    13: (3, 8),
    14: (3, 9),
    15: (3, 10),
    16: (3, 11),
    17: (4, 5),
    18: (4, 6),
    19: (4, 8),
    20: (4, 9),
    21: (4, 10),
    22: (4, 11),
    23: (5, 6),
    24: (5, 8),
    25: (5, 9),
    26: (5, 10),
    27: (5, 11),
    28: (6, 8),
    29: (6, 9),
    30: (6, 10),
    31: (6, 11),
    32: (8, 9),
    33: (8, 10),
    34: (8, 11),
    35: (9, 10),
    36: (9, 11),
    37: (10, 11),
}


def xor_stages(state: Sequence[int], stages: Iterable[int]) -> int:
    value = 0
    for stage in stages:
        value ^= state[stage - 1]
    return value


def shift(state: Sequence[int], feedback_taps: Iterable[int]) -> List[int]:
    return [xor_stages(state, feedback_taps), *state[:-1]]


def verify_lfsr_period(feedback_taps: Iterable[int]) -> None:
    state = list(INITIAL)
    for step_index in range(1, 2048):
        state = shift(state, feedback_taps)
        if tuple(state) == INITIAL:
            if step_index != 2047:
                raise AssertionError(f"unexpected LFSR period {step_index}")
            return
    raise AssertionError("LFSR did not return to its initial state")


def generate_prn(prn: int) -> List[int]:
    if prn not in G2_PHASE_TAPS:
        raise ValueError("supported MEO/IGSO PRNs are 6 through 37")

    g1 = list(INITIAL)
    g2 = list(INITIAL)
    chips: List[int] = []

    # Emit the first 2046 chips of the 2047-chip Gold sequence.  The next
    # call/period starts again at the ICD initial phase.
    for _ in range(2046):
        chips.append(g1[10] ^ xor_stages(g2, G2_PHASE_TAPS[prn]))
        g1 = shift(g1, G1_FEEDBACK_TAPS)
        g2 = shift(g2, G2_FEEDBACK_TAPS)
    return chips


def write_vectors(output_dir: Path, prns: Iterable[int]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "source": "BDS-SIS-ICD-2.1 section 4.3, figure 4-1, table 4-2",
        "length_chips": 2046,
        "initial_phase": "01010101010",
        "vectors": {},
    }

    sequences = {}
    for prn in prns:
        chips = generate_prn(prn)
        payload = "".join(str(chip) + "\n" for chip in chips)
        vector_name = f"b1i_prn_{prn:02d}.mem"
        (output_dir / vector_name).write_text(payload, encoding="ascii", newline="\n")
        digest = hashlib.sha256(bytes(chips)).hexdigest()
        manifest["vectors"][str(prn)] = {
            "file": vector_name,
            "sha256_of_chip_bytes": digest,
            "first_32_chips": "".join(str(chip) for chip in chips[:32]),
        }
        sequences[prn] = chips

    all_sequences = [generate_prn(prn) for prn in range(6, 38)]
    if len({tuple(chips) for chips in all_sequences}) != 32:
        raise AssertionError("MEO/IGSO PRNs 6 through 37 must all be distinct")
    all_meo_igso = [chip for chips in all_sequences for chip in chips]
    all_vector_name = "b1i_prn_06_37.mem"
    (output_dir / all_vector_name).write_text(
        "".join(str(chip) + "\n" for chip in all_meo_igso),
        encoding="ascii",
        newline="\n",
    )
    manifest["all_meo_igso_vector"] = {
        "file": all_vector_name,
        "layout": "PRN-major, PRN 6 through 37, 2046 chips per PRN",
        "sha256_of_chip_bytes": hashlib.sha256(bytes(all_meo_igso)).hexdigest(),
    }

    unique_sequences = {tuple(chips) for chips in sequences.values()}
    if len(unique_sequences) != len(sequences):
        raise AssertionError("selected PRNs did not produce distinct sequences")

    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
        newline="\n",
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=Path("tb/vectors"))
    parser.add_argument("--prn", type=int, nargs="+", default=[6, 12, 23, 37])
    args = parser.parse_args()

    verify_lfsr_period(G1_FEEDBACK_TAPS)
    verify_lfsr_period(G2_FEEDBACK_TAPS)
    write_vectors(args.output_dir, args.prn)
    print("B1I_GOLDEN_MODEL_PASS")


if __name__ == "__main__":
    main()
