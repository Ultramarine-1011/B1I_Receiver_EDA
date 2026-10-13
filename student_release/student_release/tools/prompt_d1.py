"""Recover BeiDou B1I D1 words from schema-2 RTL tracking prompts.

Only receiver records are used.  Signal-source truth and RINEX files are not
inputs to this module.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import json
import math
from pathlib import Path
from typing import Iterable

import numpy as np

from decode_records import decode


FS = 16_368_000.0
IF_HZ = 4_092_000.0
NH20 = np.asarray((1, 1, 1, 1, 1, -1, 1, 1, -1, -1,
                   1, -1, 1, -1, 1, 1, -1, -1, -1, 1), dtype=np.float64)
PREAMBLE_BITS = [int(bit) for bit in f"{0b11100010010:011b}"]


def _syndrome(codeword: list[int]) -> tuple[int, ...]:
    register = [0, 0, 0, 0]
    for bit in codeword:
        old_d0, old_d1 = register[0], register[1]
        register[0] = bit ^ register[3]
        register[1] = old_d0 ^ register[0]
        register[3] = register[2]
        register[2] = old_d1
    return tuple(register)


def _bch_decode(codeword: list[int]) -> tuple[list[int], int]:
    candidate = list(codeword)
    if _syndrome(candidate) == (0, 0, 0, 0):
        return candidate[:11], 0
    for index in range(15):
        candidate[index] ^= 1
        if _syndrome(candidate) == (0, 0, 0, 0):
            return candidate[:11], 1
        candidate[index] ^= 1
    raise ValueError("uncorrectable BCH(15,11) word")


def decode_word(word: list[int], first: bool) -> tuple[list[int], int]:
    if len(word) != 30:
        raise ValueError("D1 words contain 30 encoded bits")
    if first:
        tail, corrected = _bch_decode(word[15:])
        return word[:15] + tail, corrected
    left, right = word[0::2], word[1::2]
    a, corrected_a = _bch_decode(left)
    b, corrected_b = _bch_decode(right)
    return a + b, corrected_a + corrected_b


def _bits_to_int(bits: list[int]) -> int:
    value = 0
    for bit in bits:
        value = (value << 1) | bit
    return value


def _boundary_sample_offset(row: dict) -> float:
    """Sub-sample distance from recorded last sample to the local code wrap."""
    if int(row.get("schema_version", 0)) < 3 or "code_fraction" not in row:
        return 0.0
    step_word = 0x20000000 + int(int(row["doppler_word"]) / 763)
    step_chips = step_word / 2.0**32
    residual_chips = int(row["code_fraction"]) / 2.0**32
    if step_chips <= 0.0:
        return 0.0
    # observation_sample_index names the sample whose NCO update crossed the
    # boundary.  The exact wrap lies residual/step samples before it.
    return max(-1.0, min(0.0, -residual_chips / step_chips))


def _carrier_wiped(rows: list[dict], frequency_hz: float) -> tuple[np.ndarray, np.ndarray]:
    samples = np.asarray([int(row["sample_index"]) for row in rows], dtype=np.int64)
    relative_time = (samples - samples[0]).astype(np.float64) / FS
    prompt = np.asarray([complex(int(row["prompt_i"]), int(row["prompt_q"])) for row in rows])
    local_phase = np.asarray([int(row["carrier_phase"]) for row in rows], dtype=np.float64)
    local_phase *= 2.0 * math.pi / 2.0**32
    # IF is exactly Fs/4, so reducing the sample index modulo four avoids a
    # large-angle floating-point loss for long simulations.
    if_phase = (samples & 3).astype(np.float64) * (math.pi / 2.0)
    absolute = prompt * np.exp(1j * local_phase) * np.exp(-1j * if_phase)
    return absolute * np.exp(-2j * math.pi * frequency_hz * relative_time), relative_time


def _secondary_solution(rows: list[dict], coarse_hz: float) -> tuple[float, int, float, np.ndarray]:
    def evaluate(frequency_hz: float, count: int) -> tuple[float, int, complex, np.ndarray, np.ndarray]:
        candidate_wiped, candidate_times = _carrier_wiped(rows, frequency_hz)
        probe = candidate_wiped[:count]
        probe_times = candidate_times[:count]
        indices = np.arange(count)
        phase_score = -1.0
        phase_number = 0
        phase_vector = 0.0 + 0.0j
        for phase in range(20):
            corrected = probe * NH20[(indices + phase) % 20]
            products = corrected[1:] * np.conj(corrected[:-1])
            gaps = np.diff(probe_times)
            current = indices[1:]
            mask = (((current + phase) % 20) != 0) & (gaps > 0.0008) & (gaps < 0.0012)
            selected = products[mask]
            if not len(selected):
                continue
            vector = np.sum(selected / np.maximum(np.abs(selected), 1e-30))
            score = float(abs(vector) / len(selected))
            if score > phase_score:
                phase_score, phase_number, phase_vector = score, phase, vector
        return phase_score, phase_number, phase_vector, candidate_wiped, candidate_times

    grid_limit = min(len(rows), 10000)
    grid = [coarse_hz + offset for offset in range(-400, 401, 25)]
    grid_results = [(evaluate(candidate, grid_limit)[0], candidate) for candidate in grid]
    frequency = max(grid_results)[1]
    best_phase = 0
    best_score = -1.0
    wiped = np.empty(0, dtype=np.complex128)
    # Use the full channel span.  A few thousand milliseconds are sufficient
    # for NH acquisition, but a 0.05 Hz residual rotates the BPSK axis by more
    # than 180 degrees over a long D1 subframe and can turn complemented BCH
    # codewords into apparently valid words.
    limit = len(rows)
    for _ in range(4):
        best_score, best_phase, best_vector, wiped, times = evaluate(frequency, limit)
        if best_score < 0:
            raise ValueError("no continuous prompt sequence for NH search")
        mean_gap = float(np.mean(np.diff(times[:limit])))
        residual = float(np.angle(best_vector) / (2.0 * math.pi * mean_gap))
        frequency += residual
        if abs(residual) < 0.002:
            break
    wiped, _ = _carrier_wiped(rows, frequency)
    return frequency, best_phase, best_score, wiped


def _soft_bits(rows: list[dict], wiped: np.ndarray,
               nh_phase: int) -> tuple[list[int], list[int], float, float]:
    indices = np.arange(len(rows))
    corrected = wiped * NH20[(indices + nh_phase) % 20]
    starts = [index for index in range(len(rows) - 19) if (index + nh_phase) % 20 == 0]
    values: list[complex] = []
    valid_starts: list[int] = []
    for start in starts:
        samples = [int(row["sample_index"]) for row in rows[start:start + 20]]
        gaps = np.diff(np.asarray(samples, dtype=np.int64)) / FS
        if len(gaps) != 19 or np.any(gaps < 0.0008) or np.any(gaps > 0.0012):
            continue
        values.append(complex(np.sum(corrected[start:start + 20])))
        valid_starts.append(start)
    if not values:
        raise ValueError("no complete NH-aligned D1 bits")
    soft = np.asarray(values, dtype=np.complex128)
    bit_times = np.asarray([int(rows[start + 10]["sample_index"]) for start in valid_starts],
                           dtype=np.float64) / FS
    # Remove the time-varying residual carrier phase.  Squaring removes the
    # D1 BPSK sign, so unwrapping this phase does not assume one constant
    # Doppler over the whole recording.
    phase_2 = np.unwrap(np.angle(soft * soft))
    soft *= np.exp(-0.5j * phase_2)
    bit_residual = 0.0
    axis = 0.5 * float(np.angle(np.sum(soft * soft)))
    decisions = np.real(soft * np.exp(-1j * axis))
    return [int(value < 0) for value in decisions], valid_starts, axis, bit_residual


def _subframes(bits: list[int], starts: list[int], rows: list[dict], prn: int,
               generation: int, frequency_hz: float) -> list[dict]:
    found: list[dict] = []
    occupied: set[int] = set()
    for polarity in (0, 1):
        candidate = [bit ^ polarity for bit in bits]
        for offset in range(0, len(candidate) - 299):
            if offset in occupied or candidate[offset:offset + 11] != PREAMBLE_BITS:
                continue
            words = [candidate[offset + index * 30:offset + (index + 1) * 30]
                     for index in range(10)]
            try:
                decoded = [decode_word(word, index == 0) for index, word in enumerate(words)]
            except ValueError:
                continue
            information = [item[0] for item in decoded]
            header = information[0]
            if header[:11] != PREAMBLE_BITS:
                continue
            sfid = _bits_to_int(header[15:18])
            sow = _bits_to_int(header[18:26])
            # SOW occupies the final eight bits of word 1 and the first twelve
            # information bits of word 2.
            sow = (sow << 12) | _bits_to_int(information[1][:12])
            if sfid not in range(1, 6) or sow >= 604800:
                continue
            for word_index, (raw_word, (info, corrected)) in enumerate(zip(words, decoded), start=1):
                bit_end = offset + word_index * 30 - 1
                row_index = starts[bit_end] + 19
                found.append({
                    "type": "navigation",
                    "type_id": 2,
                    "prn": prn,
                    "channel": int(rows[row_index]["channel"]),
                    "sample_index": int(rows[row_index]["sample_index"]),
                    "sample_fraction": _boundary_sample_offset(rows[row_index]),
                    "locked": bool(rows[row_index].get("locked")),
                    "nh_valid": True,
                    "frame_valid": True,
                    "time_valid": True,
                    "bch_valid": True,
                    "generation": generation,
                    "raw_word": _bits_to_int(raw_word),
                    "information": _bits_to_int(info),
                    "word_number": word_index,
                    "subframe_id": sfid,
                    "sow": sow,
                    "corrected_bits": corrected,
                    "software_recovered": True,
                    "carrier_doppler_hz": frequency_hz,
                })
            occupied.update(range(offset, offset + 300))
    return sorted(found, key=lambda item: int(item["sample_index"]))


def recover_navigation(records: Iterable[dict]) -> tuple[list[dict], list[dict]]:
    materialized = list(records)
    acquisitions: dict[int, float] = {}
    for row in materialized:
        if row.get("type") == "acquisition" and row.get("detected"):
            acquisitions[int(row["prn"])] = int(row["doppler_word"]) * FS / 2.0**32
    groups: dict[tuple[int, int], list[dict]] = defaultdict(list)
    for row in materialized:
        if row.get("type") == "tracking" and int(row.get("schema_version", 0)) >= 2:
            groups[(int(row["prn"]), int(row["generation"]))].append(row)

    navigation: list[dict] = []
    reports: list[dict] = []
    for (prn, generation), rows in sorted(groups.items()):
        rows.sort(key=lambda item: int(item["sample_index"]))
        if len(rows) < 300:
            continue
        coarse = acquisitions.get(prn)
        if coarse is None:
            coarse = float(np.median([int(row["doppler_word"]) for row in rows])) * FS / 2.0**32
        try:
            frequency, nh_phase, coherence, wiped = _secondary_solution(rows, coarse)
            # Resolve the 1 kHz ambiguity before dynamic phase unwrapping.
            # The acquisition bin is measured from the original IF samples.
            frequency += round((coarse - frequency) / 1000.0) * 1000.0
            wiped, _ = _carrier_wiped(rows, frequency)
            bits, starts, carrier_axis, bit_residual = _soft_bits(rows, wiped, nh_phase)
            frequency += bit_residual
            words = _subframes(bits, starts, rows, prn, generation, frequency)
        except ValueError as exc:
            reports.append({"prn": prn, "generation": generation, "status": "failed", "reason": str(exc)})
            continue
        navigation.extend(words)
        reports.append({
            "prn": prn,
            "generation": generation,
            "status": "complete" if words else "bits_only",
            "prompt_count": len(rows),
            "bit_count": len(bits),
            "coarse_doppler_hz": coarse,
            "refined_doppler_hz": frequency,
            "nh_phase": nh_phase,
            "nh_coherence": coherence,
            "carrier_axis_rad": carrier_axis,
            "bit_residual_hz": bit_residual,
            "subframe_count": len(words) // 10,
        })
    return sorted(navigation, key=lambda item: int(item["sample_index"])), reports


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("-o", "--output", type=Path, required=True)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    raw = args.input.read_bytes()
    if not raw or len(raw) % 32:
        raise SystemExit("receiver BIN is empty or not aligned to 32-byte records")
    records = [decode(raw[offset:offset + 32]) for offset in range(0, len(raw), 32)]
    navigation, reports = recover_navigation(records)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("".join(json.dumps(row) + "\n" for row in navigation), encoding="utf-8")
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(reports, indent=2) + "\n", encoding="utf-8")
    print(f"Prompt D1: channels={len(reports)} words={len(navigation)} subframes={len(navigation) // 10}")


if __name__ == "__main__":
    main()
