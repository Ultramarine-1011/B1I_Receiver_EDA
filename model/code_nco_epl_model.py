#!/usr/bin/env python3
"""Reference models, parameter scans, and VCS vectors for Code NCO + E/P/L."""

from __future__ import annotations

import argparse
import csv
import json
import math
from dataclasses import dataclass
from fractions import Fraction
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple

from b1i_prn_golden import generate_prn


FS_HZ = 16_368_000
RC_HZ = 2_046_000
B1I_CARRIER_HZ = 1_561_098_000
CODE_LENGTH = 2046
BASELINE_PHASE_FRAC = 32
BASELINE_DELTA = Fraction(1, 4)  # Half-spacing: E=q+delta, L=q-delta.
BASELINE_WINDOW_SAMPLES = 16_368
MAX_TOTAL_CARRIER_OFFSET_HZ = 10_000
MAX_CODE_RATE_OFFSET_HZ = Fraction(
    RC_HZ * MAX_TOTAL_CARRIER_OFFSET_HZ, B1I_CARRIER_HZ
)


def code_pm(bit: int) -> int:
    return 1 if bit == 0 else -1


def phase_mod(phase: Fraction) -> Fraction:
    return phase % CODE_LENGTH


def phase_index(phase: Fraction) -> int:
    return math.floor(phase_mod(phase))


@dataclass
class FullPrecisionCodeNco:
    """Exact-rational reference for the sample-before-update timing contract."""

    prn: int
    phase: Fraction
    period_count: int
    step: Fraction
    delta: Fraction = BASELINE_DELTA

    def __post_init__(self) -> None:
        self.sequence = generate_prn(self.prn)
        self.phase = phase_mod(self.phase)

    def current(self) -> Tuple[int, int, int]:
        early = self.sequence[phase_index(self.phase + self.delta)]
        prompt = self.sequence[phase_index(self.phase)]
        late = self.sequence[phase_index(self.phase - self.delta)]
        return early, prompt, late

    def accept_sample(self) -> bool:
        next_unwrapped = self.phase + self.step
        wrapped = next_unwrapped >= CODE_LENGTH
        self.phase = phase_mod(next_unwrapped)
        if wrapped:
            self.period_count += 1
        return wrapped


@dataclass
class FixedCodeNco:
    prn: int
    phase_q: int
    period_count: int
    step_q: int
    frac_bits: int = BASELINE_PHASE_FRAC
    delta: Fraction = BASELINE_DELTA

    def __post_init__(self) -> None:
        self.scale = 1 << self.frac_bits
        self.modulus = CODE_LENGTH * self.scale
        self.delta_q = int(self.delta * self.scale)
        self.phase_q %= self.modulus
        self.sequence = generate_prn(self.prn)

    def _index(self, phase_q: int) -> int:
        return (phase_q % self.modulus) >> self.frac_bits

    def current(self) -> Tuple[int, int, int]:
        early = self.sequence[self._index(self.phase_q + self.delta_q)]
        prompt = self.sequence[self._index(self.phase_q)]
        late = self.sequence[self._index(self.phase_q - self.delta_q)]
        return early, prompt, late

    def accept_sample(self) -> bool:
        total = self.phase_q + self.step_q
        wrapped = total >= self.modulus
        if wrapped:
            total -= self.modulus
            self.period_count += 1
        self.phase_q = total
        return wrapped


class EplCorrelator:
    def __init__(self, window_samples: int = BASELINE_WINDOW_SAMPLES) -> None:
        self.window_samples = window_samples
        self.reset()

    def reset(self) -> None:
        self.acc = [0, 0, 0, 0, 0, 0]
        self.outputs = [0, 0, 0, 0, 0, 0]
        self.count = 0
        self.start_ref = 0
        self.window_ref = 0
        self.window_done = 0

    def clock(
        self,
        valid: int,
        i_sample: int,
        q_sample: int,
        codes: Tuple[int, int, int],
        sample_ref: int,
    ) -> None:
        self.window_done = 0
        if not valid:
            return

        if self.count == 0:
            self.start_ref = sample_ref

        products: List[int] = []
        for bit in codes:
            sign = code_pm(bit)
            products.extend((i_sample * sign, q_sample * sign))
        sums = [a + p for a, p in zip(self.acc, products)]

        if self.count == self.window_samples - 1:
            self.outputs = sums
            self.window_ref = self.start_ref
            self.window_done = 1
            self.acc = [0, 0, 0, 0, 0, 0]
            self.count = 0
        else:
            self.acc = sums
            self.count += 1


def round_fraction(value: Fraction) -> int:
    return round(value)


def code_step_q(code_rate_hz: Fraction, frac_bits: int) -> int:
    return round_fraction(code_rate_hz * (1 << frac_bits) / FS_HZ)


def write_nco_scan(report_dir: Path) -> List[Dict[str, float]]:
    rows: List[Dict[str, float]] = []
    for frac_bits in (16, 20, 24, 28, 32, 36):
        scale = 1 << frac_bits
        rate_lsb = FS_HZ / scale
        worst_error = rate_lsb / 2.0
        plus_step = code_step_q(Fraction(RC_HZ) + MAX_CODE_RATE_OFFSET_HZ, frac_bits)
        minus_step = code_step_q(Fraction(RC_HZ) - MAX_CODE_RATE_OFFSET_HZ, frac_bits)
        plus_rate = plus_step * FS_HZ / scale
        minus_rate = minus_step * FS_HZ / scale
        endpoint_error = max(
            abs(plus_rate - float(Fraction(RC_HZ) + MAX_CODE_RATE_OFFSET_HZ)),
            abs(minus_rate - float(Fraction(RC_HZ) - MAX_CODE_RATE_OFFSET_HZ)),
        )
        rows.append(
            {
                "fractional_bits": frac_bits,
                "phase_state_bits": 11 + frac_bits,
                "rate_lsb_chips_per_s": rate_lsb,
                "worst_rounding_error_chips_per_s": worst_error,
                "endpoint_error_at_max_offset_chips_per_s": endpoint_error,
                "worst_drift_1ms_chips": worst_error * 0.001,
                "worst_drift_1s_chips": worst_error,
                "worst_drift_180s_chips": worst_error * 180.0,
            }
        )

    path = report_dir / "code_nco_width_scan.csv"
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    return rows


def triangle_correlation(error_chips: float) -> float:
    return max(1.0 - abs(error_chips), 0.0)


def normalized_power_discriminator(early: float, late: float) -> float:
    pe = early * early
    pl = late * late
    return 0.0 if pe + pl == 0.0 else (pe - pl) / (pe + pl)


def circular_correlation(signal: Sequence[int], shift_samples: int) -> float:
    length = len(signal)
    return sum(
        signal[index] * signal[(index + shift_samples) % length]
        for index in range(length)
    ) / length


def write_spacing_scan(report_dir: Path) -> List[Dict[str, float]]:
    samples_per_chip = 8
    prn_pm = [code_pm(bit) for bit in generate_prn(6)]
    sampled = [chip for chip in prn_pm for _ in range(samples_per_chip)]
    deltas = (Fraction(1, 8), Fraction(1, 4), Fraction(1, 2))
    rows: List[Dict[str, float]] = []

    for delta in deltas:
        delta_float = float(delta)
        delta_samples = int(delta * samples_per_chip)
        for error_samples in range(-12, 13):
            error = error_samples / samples_per_chip
            ideal_e = triangle_correlation(error + delta_float)
            ideal_p = triangle_correlation(error)
            ideal_l = triangle_correlation(error - delta_float)
            discrete_e = circular_correlation(sampled, error_samples + delta_samples)
            discrete_p = circular_correlation(sampled, error_samples)
            discrete_l = circular_correlation(sampled, error_samples - delta_samples)
            rows.append(
                {
                    "delta_half_spacing_chips": delta_float,
                    "el_total_spacing_chips": 2.0 * delta_float,
                    "prompt_error_chips": error,
                    "ideal_early": ideal_e,
                    "ideal_prompt": ideal_p,
                    "ideal_late": ideal_l,
                    "ideal_discriminator": normalized_power_discriminator(ideal_e, ideal_l),
                    "discrete_early": discrete_e,
                    "discrete_prompt": discrete_p,
                    "discrete_late": discrete_l,
                    "discrete_discriminator": normalized_power_discriminator(
                        discrete_e, discrete_l
                    ),
                }
            )

    path = report_dir / "epl_spacing_scan.csv"
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    return rows


def spacing_summary(rows: Sequence[Dict[str, float]]) -> List[Dict[str, float]]:
    summary = []
    for delta in (0.125, 0.25, 0.5):
        selected = [row for row in rows if row["delta_half_spacing_chips"] == delta]
        by_error = {row["prompt_error_chips"]: row for row in selected}
        discrete_slope = (
            by_error[0.125]["discrete_discriminator"]
            - by_error[-0.125]["discrete_discriminator"]
        ) / 0.25
        ideal_slope = -2.0 / (1.0 - delta)
        summary.append(
            {
                "delta_half_spacing_chips": delta,
                "el_total_spacing_chips": 2.0 * delta,
                "spacing_samples_at_8_samples_per_chip": delta * 8.0,
                "ideal_near_zero_slope_per_chip": ideal_slope,
                "discrete_near_zero_slope_per_chip": discrete_slope,
                "both_arms_nonzero_half_range_chips": 1.0 - delta,
                "sign_correct_pull_in_half_range_chips": 1.0 + delta,
                "sample_phase_quantization_half_lsb_chips": 1.0 / 16.0,
            }
        )
    return summary


def write_accumulator_scan(report_dir: Path) -> List[Dict[str, int]]:
    rows = []
    for iq_width in (3, 4, 8, 12, 16):
        max_product_magnitude = 1 << (iq_width - 1)
        worst_sum_magnitude = BASELINE_WINDOW_SAMPLES * max_product_magnitude
        min_width = iq_width + math.ceil(math.log2(BASELINE_WINDOW_SAMPLES + 1))
        rows.append(
            {
                "iq_width": iq_width,
                "window_samples": BASELINE_WINDOW_SAMPLES,
                "max_product_magnitude": max_product_magnitude,
                "worst_sum_magnitude": worst_sum_magnitude,
                "minimum_signed_accumulator_width": min_width,
                "baseline_guard_bits": 0,
            }
        )
    path = report_dir / "accumulator_width_scan.csv"
    with path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    return rows


def make_events(
    accepted_target: int,
    sample_ref_start: int,
    stall_modulus: int,
    stall_residue: int,
) -> List[Tuple[int, int, int, int]]:
    values = (-4, -3, -1, 0, 1, 3, 2, -2)
    events = []
    accepted = 0
    clock_index = 0
    while accepted < accepted_target:
        valid = 0 if (clock_index % stall_modulus) == stall_residue else 1
        if valid:
            i_sample = values[accepted % len(values)]
            q_sample = values[(accepted * 3 + 1) % len(values)]
            sample_ref = sample_ref_start + accepted
            accepted += 1
        else:
            i_sample = 0
            q_sample = 0
            sample_ref = sample_ref_start + accepted
        events.append((valid, i_sample, q_sample, sample_ref))
        clock_index += 1
    return events


def write_case(
    path: Path,
    prn: int,
    init_phase: Fraction,
    init_period: int,
    code_rate: Fraction,
    events: Sequence[Tuple[int, int, int, int]],
) -> Dict[str, float]:
    frac_bits = BASELINE_PHASE_FRAC
    scale = 1 << frac_bits
    init_phase_q = int(init_phase * scale)
    step_q = code_step_q(code_rate, frac_bits)
    fixed = FixedCodeNco(prn, init_phase_q, init_period, step_q, frac_bits)
    full = FullPrecisionCodeNco(
        prn, init_phase, init_period, Fraction(code_rate, FS_HZ), BASELINE_DELTA
    )
    correlator = EplCorrelator(BASELINE_WINDOW_SAMPLES)
    max_phase_error = 0.0

    with path.open("w", encoding="ascii", newline="\n") as stream:
        stream.write(
            f"{prn} {init_phase_q:x} {init_period} {step_q:x} {len(events)}\n"
        )
        for valid, i_sample, q_sample, sample_ref in events:
            pre_phase = fixed.phase_q
            pre_period = fixed.period_count
            codes = fixed.current()

            full_phase_q = int(full.phase * scale) % (CODE_LENGTH * scale)
            modular_error = abs(pre_phase - full_phase_q)
            modular_error = min(modular_error, CODE_LENGTH * scale - modular_error)
            max_phase_error = max(max_phase_error, modular_error / scale)

            correlator.clock(valid, i_sample, q_sample, codes, sample_ref)
            if valid:
                fixed_wrap = fixed.accept_sample()
                full.accept_sample()
            else:
                fixed_wrap = False

            row = [
                valid,
                i_sample,
                q_sample,
                sample_ref,
                f"{pre_phase:x}",
                pre_period,
                *codes,
                f"{fixed.phase_q:x}",
                fixed.period_count,
                int(fixed_wrap),
                correlator.window_done,
                *correlator.outputs,
                correlator.window_ref,
            ]
            stream.write(" ".join(str(value) for value in row) + "\n")

    return {
        "file": path.name,
        "prn": prn,
        "events": len(events),
        "accepted_samples": sum(event[0] for event in events),
        "init_phase_chips": float(init_phase),
        "init_period_count": init_period,
        "desired_code_rate_hz": float(code_rate),
        "step_q": step_q,
        "max_fixed_vs_exact_phase_error_chips": max_phase_error,
    }


def write_vectors(vector_dir: Path) -> List[Dict[str, float]]:
    vector_dir.mkdir(parents=True, exist_ok=True)
    cases = []
    cases.append(
        write_case(
            vector_dir / "nco_epl_nominal.vec",
            6,
            Fraction(0),
            0,
            Fraction(RC_HZ),
            make_events(2 * BASELINE_WINDOW_SAMPLES + 16, 1000, 11, 3),
        )
    )
    cases.append(
        write_case(
            vector_dir / "nco_epl_positive_adjust.vec",
            12,
            Fraction(8183, 4),  # 2045.75 chips, crosses the PRN boundary quickly.
            7,
            Fraction(RC_HZ) + MAX_CODE_RATE_OFFSET_HZ,
            make_events(128, 100_000, 7, 2),
        )
    )
    cases.append(
        write_case(
            vector_dir / "nco_epl_negative_adjust.vec",
            23,
            Fraction(1, 8),
            21,
            Fraction(RC_HZ) - MAX_CODE_RATE_OFFSET_HZ,
            make_events(128, 200_000, 5, 1),
        )
    )
    cases.append(
        write_case(
            vector_dir / "nco_epl_midstream_reload.vec",
            37,
            Fraction(987, 8),  # 123.375 chips.
            99,
            Fraction(RC_HZ),
            make_events(96, 300_000, 6, 4),
        )
    )
    return cases


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report-dir", type=Path, default=Path("reports"))
    parser.add_argument("--vector-dir", type=Path, default=Path("tb/vectors/code_nco_epl"))
    args = parser.parse_args()
    args.report_dir.mkdir(parents=True, exist_ok=True)

    nco_rows = write_nco_scan(args.report_dir)
    spacing_rows = write_spacing_scan(args.report_dir)
    spacing_rows_summary = spacing_summary(spacing_rows)
    accumulator_rows = write_accumulator_scan(args.report_dir)
    cases = write_vectors(args.vector_dir)

    summary = {
        "fixed_inputs": {
            "fs_hz": FS_HZ,
            "rc_hz": RC_HZ,
            "b1i_carrier_hz": B1I_CARRIER_HZ,
            "max_total_carrier_offset_hz": MAX_TOTAL_CARRIER_OFFSET_HZ,
            "conservative_max_code_rate_offset_hz": float(MAX_CODE_RATE_OFFSET_HZ),
        },
        "selected_baseline": {
            "phase_format": "unsigned Q11.32 chips modulo 2046",
            "phase_fractional_bits": BASELINE_PHASE_FRAC,
            "epl_delta_half_spacing_chips": float(BASELINE_DELTA),
            "epl_total_spacing_chips": float(2 * BASELINE_DELTA),
            "window_samples": BASELINE_WINDOW_SAMPLES,
            "accumulator_width_formula": "IQ_WIDTH + ceil(log2(WINDOW_SAMPLES + 1))",
            "accumulator_guard_bits": 0,
        },
        "nco_scan": nco_rows,
        "spacing_summary": spacing_rows_summary,
        "accumulator_scan": accumulator_rows,
        "vector_cases": cases,
    }
    (args.report_dir / "code_nco_epl_analysis.json").write_text(
        json.dumps(summary, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print("CODE_NCO_EPL_MODEL_PASS")


if __name__ == "__main__":
    main()

