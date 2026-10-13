#!/usr/bin/env python3
"""Independent real-valued and integer Carrier NCO/Mixer models.

Phase: unsigned turns modulo one. Current phase mixes current sample; step
then advances phase. Frequency-word updates never reset phase. RTL LUT is
quarter-wave, while this golden builds a full-circle sin/cos table directly.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from pathlib import Path

import numpy as np

FS_HZ = 16_368_000
IF_HZ = 4_092_000
PHASE_BITS = 32
ADDRESS_BITS = 10
AMPLITUDE_BITS = 12
INPUT_BITS = 3
MIXER_BITS = INPUT_BITS + AMPLITUDE_BITS - 1
AMPLITUDE_SCALE = (1 << (AMPLITUDE_BITS - 1)) - 1

# Engineering budgets, declared before candidate selection. These are not
# course receiver performance requirements and do not prove closed-loop lock.
FREQUENCY_ROUNDING_BUDGET_HZ = 0.01
OSCILLATOR_PEAK_ERROR_BUDGET = 0.0035
OSCILLATOR_RMS_ERROR_BUDGET = 0.0025


def frequency_word(frequency_hz: float, phase_bits: int = PHASE_BITS) -> int:
    if not 0 <= frequency_hz < FS_HZ:
        raise ValueError("full IF + offset frequency must be in [0, Fs)")
    return round(frequency_hz / FS_HZ * (1 << phase_bits)) % (1 << phase_bits)


class RealCarrier:
    """Full-precision mathematical oscillator, no address or amplitude LUT."""

    def __init__(self, phase_turns: float = 0.0) -> None:
        self.phase = phase_turns % 1.0

    def sample(self, x: float, frequency_hz: float) -> complex:
        theta = 2 * math.pi * self.phase
        value = x * complex(math.cos(theta), -math.sin(theta))
        self.phase = (self.phase + frequency_hz / FS_HZ) % 1.0
        return value


class FixedCarrier:
    """Clock-event model including reset, reload priority and registered I/Q."""

    def __init__(self) -> None:
        size = 1 << ADDRESS_BITS
        self.sine = [round(AMPLITUDE_SCALE * math.sin(2 * math.pi * k / size))
                     for k in range(size)]
        self.cosine = [round(AMPLITUDE_SCALE * math.cos(2 * math.pi * k / size))
                       for k in range(size)]
        self.reset()

    def reset(self) -> None:
        self.phase = 0
        self.configured = 0
        self.i = self.q = self.ref = self.iq_valid = 0

    def clock(self, rst_n: int, init: int, init_phase: int, valid: int,
              x: int, ref: int, step: int) -> tuple[int, ...]:
        accepted = int(bool(rst_n and not init and valid and self.configured))
        if not rst_n:
            self.reset()
        elif init:
            self.phase = init_phase
            self.configured = 1
            self.i = self.q = self.ref = self.iq_valid = 0
        else:
            self.iq_valid = accepted
            if accepted:
                shift = PHASE_BITS - ADDRESS_BITS
                address = ((self.phase + (1 << (shift - 1))) >> shift) % (1 << ADDRESS_BITS)
                self.i = x * self.cosine[address]
                self.q = -x * self.sine[address]
                self.ref = ref
                self.phase = (self.phase + step) % (1 << PHASE_BITS)
        assert -(1 << (MIXER_BITS - 1)) <= self.i < (1 << (MIXER_BITS - 1))
        assert -(1 << (MIXER_BITS - 1)) <= self.q < (1 << (MIXER_BITS - 1))
        return accepted, self.phase, self.configured, self.iq_valid, self.i, self.q, self.ref


def scan_parameters() -> tuple[list[dict], list[dict], dict]:
    frequency_rows = []
    for bits in (24, 28, 32, 36):
        lsb = FS_HZ / (1 << bits)
        frequency_rows.append(dict(
            phase_bits=bits, frequency_lsb_hz=lsb,
            worst_rounding_error_hz=lsb / 2,
            max_1ms_phase_error_deg=360 * lsb / 2 * 0.001,
            max_30s_open_loop_phase_error_deg=360 * lsb / 2 * 30,
            meets_budget=lsb / 2 <= FREQUENCY_ROUNDING_BUDGET_HZ))

    phase = np.arange(1 << 18, dtype=np.float64) / (1 << 18)
    ideal = np.exp(-2j * np.pi * phase)
    lut_rows = []
    for address_bits in (8, 10, 12):
        size = 1 << address_bits
        address = np.floor(phase * size + 0.5).astype(np.int64) % size
        angles = 2 * np.pi * np.arange(size) / size
        for amplitude_bits in (8, 10, 12, 14):
            scale = (1 << (amplitude_bits - 1)) - 1
            table = (np.rint(scale * np.cos(angles))
                     - 1j * np.rint(scale * np.sin(angles))) / scale
            error = np.abs(table[address] - ideal)
            peak, rms = float(error.max()), float(np.sqrt(np.mean(error ** 2)))
            # Additional half-LSB magnitude bound protects against finite scan
            # grid understating a bin-edge worst case.
            analytic_bound = 2 * math.sin(math.pi / (2 * size)) + math.sqrt(2) / (2 * scale)
            lut_rows.append(dict(address_bits=address_bits, amplitude_bits=amplitude_bits,
                quarter_table_entries=size // 4 + 1,
                quarter_table_bits=(size // 4 + 1) * amplitude_bits,
                peak_complex_error=peak, rms_complex_error=rms,
                analytic_peak_error_bound=analytic_bound,
                meets_budget=(analytic_bound <= OSCILLATOR_PEAK_ERROR_BUDGET
                              and rms <= OSCILLATOR_RMS_ERROR_BUDGET)))
    selected_frequency = next(r for r in frequency_rows if r['meets_budget'])
    selected_lut = min((r for r in lut_rows if r['meets_budget']),
                       key=lambda r: r['quarter_table_bits'])
    assert selected_frequency['phase_bits'] == PHASE_BITS
    assert selected_lut['address_bits'] == ADDRESS_BITS
    assert selected_lut['amplitude_bits'] == AMPLITUDE_BITS
    selected = dict(phase_bits=PHASE_BITS, address_bits=ADDRESS_BITS,
                    amplitude_bits=AMPLITUDE_BITS, amplitude_scale=AMPLITUDE_SCALE,
                    input_bits=INPUT_BITS, mixer_bits=MIXER_BITS,
                    worst_full_input_product=(1 << (INPUT_BITS - 1)) * AMPLITUDE_SCALE,
                    worst_course_input_product=3 * AMPLITUDE_SCALE,
                    epl_accumulator_bits=MIXER_BITS + 14)
    return frequency_rows, lut_rows, selected


def generate_events() -> list[tuple[int, ...]]:
    events = []
    step = frequency_word(IF_HZ)
    sample_ref = 0

    def add(rst=1, init=0, phase=0, valid=1, x=3, word=None):
        nonlocal sample_ref
        events.append((rst, init, phase, valid, x, sample_ref, step if word is None else word))
        if valid:
            sample_ref += 1

    add(rst=0)
    add(rst=0, init=1, phase=0xffffffff)
    add()  # valid before configuration is discarded
    add(init=1)  # init cancels simultaneous valid
    for index in range(64):
        add(valid=int(index % 11 != 3), x=(-4, -3, -1, 0, 1, 2, 3)[index % 7])

    # Every phase address, either side of every rounding boundary, each quadrant
    # and modulo-one wrap. Reloads are deliberately simultaneous with valid.
    shift = PHASE_BITS - ADDRESS_BITS
    for address in range(1 << ADDRESS_BITS):
        for fraction in (0, (1 << (shift - 1)) - 1, 1 << (shift - 1)):
            phase = (address << shift) + fraction
            add(init=1, phase=phase, x=-4)
            add(x=-4, word=1)
            add(valid=0, x=3, word=0xffffffff)

    # Positive/negative offsets and arbitrary control changes, no phase reload.
    for offset in (10_000, -10_000, 125, -125, 0):
        word = frequency_word(IF_HZ + offset)
        for index in range(4096):
            add(valid=int(index % 13 != 5), x=(-3, -1, 1, 3)[index % 4], word=word)
    add(rst=0)
    add()
    add(init=1, phase=0xffffffff)
    for _ in range(8):
        add(x=-4)
    return events


def write_vectors(path: Path) -> dict:
    model = FixedCarrier()
    rows = []
    accepted_count = 0
    max_mixer_error = 0.0
    events = generate_events()
    for event in events:
        rst, init, init_phase, valid, x, ref, step = event
        previous_phase = model.phase
        expected = model.clock(*event)
        if expected[0]:
            accepted_count += 1
            real = RealCarrier(previous_phase / (1 << PHASE_BITS))
            full = real.sample(x, step * FS_HZ / (1 << PHASE_BITS))
            error = abs(complex(model.i, model.q) / AMPLITUDE_SCALE - full)
            max_mixer_error = max(max_mixer_error, error)
            assert error <= abs(x) * OSCILLATOR_PEAK_ERROR_BUDGET + 1e-12
            # Independent real-valued state advancement versus modular integer.
            assert abs(real.phase - model.phase / (1 << PHASE_BITS)) < 1e-12
        rows.append(' '.join(map(str, (*event, *expected))))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(str(len(rows)) + '\n' + '\n'.join(rows) + '\n', encoding='ascii')
    return dict(events=len(rows), accepted_samples=accepted_count,
                max_fullprecision_mixer_error=max_mixer_error,
                sha256=hashlib.sha256(path.read_bytes()).hexdigest())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--report-dir', type=Path, default=Path('reports/carrier'))
    parser.add_argument('--vector-file', type=Path, default=Path('tb/vectors/carrier/carrier.vec'))
    args = parser.parse_args()
    args.report_dir.mkdir(parents=True, exist_ok=True)
    frequency_rows, lut_rows, selected = scan_parameters()
    for name, rows in (('frequency_scan.csv', frequency_rows), ('lut_scan.csv', lut_rows)):
        with (args.report_dir / name).open('w', newline='', encoding='utf-8') as stream:
            writer = csv.DictWriter(stream, fieldnames=rows[0].keys())
            writer.writeheader()
            writer.writerows(rows)
    quarter = [round(AMPLITUDE_SCALE * math.sin(2 * math.pi * k / (1 << ADDRESS_BITS)))
               for k in range((1 << (ADDRESS_BITS - 2)) + 1)]
    # Source values for the separately committed synthesizable quarter-wave ROM.
    summary = dict(selected=selected, budgets=dict(
        frequency_rounding_hz=FREQUENCY_ROUNDING_BUDGET_HZ,
        oscillator_peak=OSCILLATOR_PEAK_ERROR_BUDGET,
        oscillator_rms=OSCILLATOR_RMS_ERROR_BUDGET),
        frequency_scan=frequency_rows, lut_scan=lut_rows,
        quarter_wave_integer_values=quarter, regression=write_vectors(args.vector_file))
    (args.report_dir / 'analysis.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    print('CARRIER_MODEL_PASS', json.dumps(summary['regression']))


if __name__ == '__main__':
    main()
