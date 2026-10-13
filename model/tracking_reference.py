#!/usr/bin/env python3
"""Full-precision single-channel research model on actual quantized real IF.

Signal truth is confined to SignalSource and scoring. TrackingLoops sees only
E/P/L and measured input energy. This is a parameter-study reference, not a
bit-accurate model or evidence that the RTL closed loop is complete.
"""
from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass
import hashlib
import json
import math
from pathlib import Path
import time

import numpy as np

from b1i_prn_golden import generate_prn
from quality_model import LockEvidence, self_test as quality_self_test

FS = 16_368_000
RC = 2_046_000
IF = 4_092_000
RF = 1_561_098_000
LENGTH = 2046
N = 16368
TU = N / FS
DELTA = 0.25
SOURCE_SHA256 = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()


def fold_costas(turns):
    """BPSK phase modulo pi, interval [-1/4, +1/4) turn."""
    return (turns + 0.25) % 0.5 - 0.25


def pi_coefficients(bandwidth_hz: float, damping: float = math.sqrt(0.5)):
    # Bn = wn/2 * (zeta + 1/(4*zeta)); Kd=K0=1 in physical
    # phase/frequency units. The equation uses Hz noise bandwidth, not 2*pi*Bn.
    wn = 8 * damping * bandwidth_hz / (4 * damping * damping + 1)
    return 2 * damping * wn, wn * wn


def linearized_poles(bandwidth_hz: float, delay_samples=128, discriminator_gain=1.0):
    """Window-average measurement + accepted-sample feedback delay model.

    State is phase error, old frequency command, pending command, integral.
    This includes NCO integration, window averaging and held control, unlike
    merely quoting continuous-time PI poles.
    """
    kp, ki = pi_coefficients(bandwidth_hz)
    delay = delay_samples / FS

    def advance(state):
        phase, old, pending, integral = state
        mean_error = discriminator_gain * (phase - old*(delay-delay*delay/(2*TU))
                         - pending*(TU/2-delay+delay*delay/(2*TU)))
        integral_new = integral + ki*TU*mean_error
        return np.array([phase-delay*old-(TU-delay)*pending,
                         pending, integral_new+kp*mean_error, integral_new])
    matrix = np.column_stack([advance(v) for v in np.eye(4)])
    poles = np.linalg.eigvals(matrix)
    return dict(bandwidth_hz=bandwidth_hz, delay_samples=delay_samples,
                gain=discriminator_gain, kp_per_s=kp, ki_per_s2=ki,
                poles=[[float(z.real), float(z.imag)] for z in poles],
                max_magnitude=float(max(abs(poles))))


@dataclass
class Scenario:
    name: str = 'quiet'
    prn: int = 6
    seconds: float = 2.0
    true_code_phase: float = 0.0
    initial_code_error: float = 0.3
    true_carrier_phase_turns: float = 0.19
    total_offset_hz: float = 3000.0
    motion_offset_hz: float = 2000.0
    initial_frequency_error_hz: float = 100.0
    initial_code_rate_error_cps: float = 0.2
    cn0_dbhz: float | None = None
    acceleration_hz_s: float = 0.0
    jerk_hz_s2: float = 0.0
    dynamic_start_s: float = 0.5
    symbol_flip: bool = True
    seed: int = 790115


class SignalSource:
    """Synthetic testbench only. NH-like flips are stimulus, never side inputs.

    ADC uses thresholds -1, 0, +1 in sigma units and output -3,-1,+1,+3.
    Thresholds are an engineering stimulus choice; course mapping is retained.
    C/N0 uses real white noise variance 1: A=sqrt(4*10^(C/N0/10)/Fs).
    """

    def __init__(self, scenario: Scenario):
        self.spec = scenario
        self.prn = 1 - 2 * np.array(generate_prn(scenario.prn), dtype=np.int8)
        self.rng = np.random.default_rng(scenario.seed)
        self.symbols = np.random.default_rng(scenario.seed + 1).choice((-1, 1), 4096)

    def truth(self, samples):
        s = self.spec
        t = samples / FS
        dynamic_phase, dynamic_frequency = self.dynamic_motion(t)
        carrier = s.true_carrier_phase_turns + (IF + s.total_offset_hz) * t + dynamic_phase
        # Only motion affects code; oscillator-only offset is deliberately excluded.
        code = s.true_code_phase + RC * t + RC / RF * (s.motion_offset_hz * t + dynamic_phase)
        frequency = s.total_offset_hz + dynamic_frequency
        return code, carrier, frequency

    def dynamic_motion(self, t):
        """Bounded continuous acceleration/frequency/phase, not infinite jerk.

        Eight equal segments: +J,0,-J,0,-J,0,+J,0 (or sign reversal).
        Acceleration returns to zero and frequency to its starting value.
        Repeating cycles preserve phase; |df/dt| <= A and |d2f/dt2| <= J.
        """
        a_limit = abs(self.spec.acceleration_hz_s)
        if a_limit == 0:
            return np.zeros_like(t), np.zeros_like(t)
        jerk = self.spec.jerk_hz_s2 or 2 * self.spec.acceleration_hz_s
        duration = a_limit / abs(jerk)
        dt = np.maximum(t - self.spec.dynamic_start_s, 0)
        cycles = np.floor(dt / (8 * duration))
        remainder = dt % (8 * duration)
        phase = np.zeros_like(t)
        frequency = np.zeros_like(t)
        phase_start = frequency_start = acceleration_start = 0.0
        for segment, factor in enumerate((1, 0, -1, 0, -1, 0, 1, 0)):
            j = jerk * factor
            u = np.clip(remainder - segment * duration, 0, duration)
            choose = (remainder >= segment * duration) & (remainder < (segment+1) * duration)
            p = phase_start + frequency_start*u + acceleration_start*u*u/2 + j*u*u*u/6
            f = frequency_start + acceleration_start*u + j*u*u/2
            phase = np.where(choose, p, phase)
            frequency = np.where(choose, f, frequency)
            phase_start += frequency_start*duration + acceleration_start*duration**2/2 + j*duration**3/6
            frequency_start += acceleration_start*duration + j*duration**2/2
            acceleration_start += j*duration
        assert abs(frequency_start) < 1e-8 and abs(acceleration_start) < 1e-8
        return phase + cycles*phase_start, frequency

    def samples(self, sample_indices):
        code, carrier, _ = self.truth(sample_indices)
        chips = self.prn[np.floor(code % LENGTH).astype(np.int64)]
        if self.spec.symbol_flip:
            epoch = np.floor(code / LENGTH).astype(np.int64)
            chips = chips * self.symbols[epoch % len(self.symbols)]
        if self.spec.cn0_dbhz is None:
            analog = 2 * chips * np.cos(2 * np.pi * (carrier % 1))
        else:
            amplitude = math.sqrt(4 * 10**(self.spec.cn0_dbhz / 10) / FS)
            analog = amplitude * chips * np.cos(2 * np.pi * (carrier % 1))
            analog += self.rng.normal(size=len(sample_indices))
        return np.select((analog < -1, analog < 0, analog < 1), (-3, -1, 1), default=3)


class TrackingLoops:
    """Window-domain receiver. No scenario, source, true phase or true rate."""

    def __init__(self, initial_frequency_hz: float, initial_code_rate_cps: float,
                 dll_bw: float, pll_bw: float, fll_gain: float, use_fll: bool):
        self.dk_p, self.dk_i = pi_coefficients(dll_bw)
        self.pk_p, self.pk_i = pi_coefficients(pll_bw)
        self.code_integral = initial_code_rate_cps - RC
        self.carrier_integral = initial_frequency_hz
        self.carrier_command = initial_frequency_hz
        self.code_command = initial_code_rate_cps
        self.fll_gain = fll_gain
        self.mode = 'FLL' if use_fll else 'PLL'
        self.previous_prompt = None
        self.frequency_ema = 0.0
        self.phase_energy_ema = 0.25**2
        self.valid_count = self.good_count = self.bad_count = 0
        self.carrier_lock = False
        self.code_lock = False
        self.dll_error_ema = 0.0
        self.mode_switches = 0
        self.lock_evidence = LockEvidence()

    def update_lock(self, usable):
        self.carrier_lock, self.code_lock = self.lock_evidence.update(
            usable, self.mode == 'PLL', self.phase_energy_ema,
            self.frequency_ema, self.dll_error_ema)

    def update(self, e: complex, p: complex, l: complex, input_energy: float):
        pe, pp, pl = abs(e)**2, abs(p)**2, abs(l)**2
        phase_error = float(fold_costas(np.angle(p) / (2 * np.pi)))
        frequency_error = 0.0
        usable = pp > 4 * input_energy and pe + pl > 8 * input_energy
        if not usable:
            self.previous_prompt = None
            self.bad_count += 1
            self.good_count = 0
            self.update_lock(False)
            return dict(valid=False, phase_error_turns=phase_error,
                        fll_error_hz=0.0, dll_error_chips=0.0)
        self.valid_count += 1
        if self.previous_prompt is not None:
            difference = p * self.previous_prompt.conjugate()
            frequency_error = float(fold_costas(np.angle(difference) / (2 * np.pi)) / TU)
            self.frequency_ema += 0.05 * (frequency_error - self.frequency_ema)
        self.previous_prompt = p

        discriminator = (pe - pl) / (pe + pl)
        # Positive discriminator means local code is behind; positive rate
        # feedback decreases the error. Kd magnitude for ideal BPSK is 8/3.
        code_error = discriminator * (1 - DELTA) / 2
        self.code_integral = float(np.clip(self.code_integral + self.dk_i * TU * code_error, -25, 25))
        self.code_command = RC + float(np.clip(self.code_integral + self.dk_p * code_error, -25, 25))
        self.dll_error_ema += 0.02 * (code_error - self.dll_error_ema)

        if self.mode == 'FLL':
            self.carrier_command += self.fll_gain * frequency_error
            self.carrier_integral = self.carrier_command
            if self.valid_count >= 80 and abs(self.frequency_ema) < 8:
                self.mode = 'PLL'
                self.mode_switches += 1
                # Bumpless command on this update; phase itself is never reset.
                self.carrier_integral = self.carrier_command - self.pk_p * phase_error
        else:
            self.carrier_integral += self.pk_i * TU * phase_error
            self.carrier_command = self.carrier_integral + self.pk_p * phase_error
        self.carrier_integral = float(np.clip(self.carrier_integral, -10_000, 10_000))
        self.carrier_command = float(np.clip(self.carrier_command, -10_000, 10_000))
        self.phase_energy_ema += 0.02 * (phase_error**2 - self.phase_energy_ema)
        self.update_lock(True)
        return dict(valid=True, phase_error_turns=phase_error,
                    fll_error_hz=frequency_error, dll_error_chips=code_error)


def phase_window(start: float, old_rate: float, new_rate: float,
                 delay_samples: int, modulus: float):
    k = np.arange(N, dtype=np.float64)
    phase = start + (old_rate * np.minimum(k, delay_samples)
                     + new_rate * np.maximum(k - delay_samples, 0)) / FS
    end = (start + (old_rate * delay_samples + new_rate * (N-delay_samples)) / FS) % modulus
    return phase % modulus, end


def run(s: Scenario, dll_bw=2.0, pll_bw=15.0, fll_gain=0.2,
        use_fll=True, feedback_delay_samples=128, save_trace: Path | None = None):
    assert 0 <= feedback_delay_samples < N
    source = SignalSource(s)
    prn = 1 - 2 * np.array(generate_prn(s.prn), dtype=np.int8)
    carrier_initial = s.total_offset_hz - s.initial_frequency_error_hz
    true_initial_code_rate = RC + RC / RF * s.motion_offset_hz
    code_initial = true_initial_code_rate - s.initial_code_rate_error_cps
    loops = TrackingLoops(carrier_initial, code_initial, dll_bw, pll_bw, fll_gain, use_fll)
    q = (s.true_code_phase + s.initial_code_error) % LENGTH
    # Receiver-only initialization policy: run NCOs to the next local code
    # epoch, then start fixed N-sample windows. This does NOT use true NH phase.
    warmup = math.ceil((LENGTH-q) * FS / code_initial) if q else 0
    q = (q + warmup * code_initial / FS) % LENGTH
    theta = (warmup * (IF+carrier_initial) / FS) % 1
    index = warmup
    old_code = pending_code = code_initial
    old_carrier = pending_carrier = carrier_initial
    records = []
    for k in range(round(s.seconds / TU)):
        indices = index + np.arange(N)
        x = source.samples(indices)
        code_phase, q = phase_window(q, old_code, pending_code, feedback_delay_samples, LENGTH)
        carrier_phase, theta = phase_window(theta, IF+old_carrier, IF+pending_carrier,
                                             feedback_delay_samples, 1)
        mixed = x * np.exp(-2j * np.pi * carrier_phase)
        e, p, l = (np.sum(mixed * prn[np.floor((code_phase+d) % LENGTH).astype(np.int64)])
                   for d in (DELTA, 0, -DELTA))
        error = loops.update(e, p, l, float(np.sum(x*x)))
        middle = N // 2
        true_code, true_carrier, true_frequency = source.truth(np.array([index+middle]))
        code_error = float((code_phase[middle] - true_code[0] + LENGTH/2) % LENGTH - LENGTH/2)
        phase_error = float(fold_costas(true_carrier[0] - carrier_phase[middle]))
        records.append(dict(time_s=(index+middle)/FS, code_error_chips=code_error,
            carrier_error_turns=phase_error, frequency_error_hz=float(true_frequency[0]-pending_carrier),
            prompt_power=float(abs(p)**2), code_command_cps=loops.code_command,
            carrier_command_hz=loops.carrier_command, mode=loops.mode,
            carrier_lock=int(loops.carrier_lock), code_lock=int(loops.code_lock), **error))
        old_code, old_carrier = pending_code, pending_carrier
        pending_code, pending_carrier = loops.code_command, loops.carrier_command
        index += N
    tail = records[max(len(records)//2, len(records)-500):]
    def rms(field):
        return math.sqrt(np.mean([r[field]**2 for r in tail]))
    locked = [r['time_s'] for r in records if r['carrier_lock'] and r['code_lock']]
    summary = dict(name=s.name, dll_bw_hz=dll_bw, pll_bw_hz=pll_bw, fll_gain=fll_gain,
        use_fll=use_fll, feedback_delay_samples=feedback_delay_samples,
        warmup_samples=warmup, code_rms_chips=rms('code_error_chips'),
        carrier_rms_turns=rms('carrier_error_turns'), frequency_rms_hz=rms('frequency_error_hz'),
        first_lock_time_s=min(locked) if locked else None,
        tail_lock_fraction=float(np.mean([r['carrier_lock'] and r['code_lock'] for r in tail])),
        valid_window_fraction=float(np.mean([r['valid'] for r in records])),
        mode_switches=loops.mode_switches)
    # Predeclared engineering screening gates, NOT final course acceptance.
    summary['screen_pass'] = (summary['code_rms_chips'] <= 0.1
        and summary['carrier_rms_turns'] <= 0.05 and summary['frequency_rms_hz'] <= 5
        and summary['tail_lock_fraction'] >= 0.95)
    if save_trace:
        save_trace.parent.mkdir(parents=True, exist_ok=True)
        with save_trace.open('w', newline='', encoding='utf-8') as stream:
            writer = csv.DictWriter(stream, fieldnames=records[0].keys())
            writer.writeheader()
            writer.writerows(records)
    return summary


def self_test_math():
    quality_self_test()
    for turn in (-0.249, -0.1, 0, 0.1, 0.249):
        assert abs(fold_costas(turn) - fold_costas(turn+0.5)) < 1e-15
    a, b = pi_coefficients(15)
    assert abs(a-40) < 1e-12 and abs(b-800) < 1e-10
    phase, end = phase_window(0.0, 1.0, 2.0, 128, 1)
    assert phase[0] == 0 and abs(phase[128] - 128/FS) < 1e-15
    assert abs(end - (128+2*(N-128))/FS) < 1e-15
    # Positive physical phase/frequency errors must produce positive correction.
    loop = TrackingLoops(0, RC, 2, 15, 0.2, False)
    loop.update(20000+0j, 20000*np.exp(0.2j), 10000+0j, 1)
    assert loop.carrier_command > 0 and loop.code_command > RC
    source = SignalSource(Scenario(acceleration_hz_s=26.036, jerk_hz_s2=-26.036))
    grid = np.linspace(0, 32, 32001)
    phase, frequency = source.dynamic_motion(grid)
    assert np.max(np.abs(frequency)) <= 52.073
    assert np.max(np.abs(np.diff(frequency)/0.001)) <= 26.037
    assert np.max(np.abs(np.diff(phase)/0.001 - frequency[1:])) < 0.027
    for bw in (1, 2, 5, 10, 15):
        assert linearized_poles(bw)['max_magnitude'] < 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--suite', choices=('smoke', 'scan', 'stress'), default='smoke')
    parser.add_argument('--report-dir', type=Path, default=Path('reports/tracking_reference'))
    args = parser.parse_args()
    self_test_math()
    args.report_dir.mkdir(parents=True, exist_ok=True)
    start = time.perf_counter()
    scenarios = [Scenario(name='quiet_positive'),
        Scenario(name='quiet_negative', prn=12, initial_code_error=-0.3,
                 initial_frequency_error_hz=-100, initial_code_rate_error_cps=-0.2),
        Scenario(name='noise45', prn=23, cn0_dbhz=45, seconds=3),
        Scenario(name='dynamic', prn=37, acceleration_hz_s=26.036,
                 jerk_hz_s2=-26.036, seconds=3)]
    if args.suite == 'stress':
        scenarios = [Scenario(name='noisy_corner_behind', seconds=3, cn0_dbhz=45,
            initial_code_error=-0.375, initial_code_rate_error_cps=7,
            initial_frequency_error_hz=200, true_carrier_phase_turns=0.249,
            total_offset_hz=9700, motion_offset_hz=5000, seed=20260928),
            Scenario(name='noisy_corner_ahead', seconds=3, cn0_dbhz=45, prn=12,
            initial_code_error=0.375, initial_code_rate_error_cps=-7,
            initial_frequency_error_hz=-200, true_carrier_phase_turns=-0.249,
            total_offset_hz=-9700, motion_offset_hz=-5000, seed=20260929),
            Scenario(name='oscillator_only', seconds=3, cn0_dbhz=45, prn=23,
            initial_frequency_error_hz=200, total_offset_hz=9000,
            motion_offset_hz=0, true_carrier_phase_turns=0.49, seed=20260930),
            Scenario(name='bounded_dynamic', seconds=4, cn0_dbhz=45, prn=37,
            acceleration_hz_s=26.036, jerk_hz_s2=-26.036, seed=20260931)]
        candidates = [(5, 15, 0.2, True), (10, 15, 0.2, True)]
    elif args.suite == 'scan':
        scenarios = [Scenario(name='pullin_100', seconds=2),
                     Scenario(name='noise45', seconds=3, cn0_dbhz=45),
                     Scenario(name='rate_error_7', seconds=3, initial_code_rate_error_cps=7)]
        # One-axis sweeps avoid attributing an improvement to two changes at once.
        candidates = sorted(set([(dll, 15, 0.2, True) for dll in (1, 2, 5, 10)]
            + [(2, pll, 0.2, fll) for pll in (5, 10, 15) for fll in (False, True)]))
    else:
        candidates = [(2, 15, 0.2, True)]
    results = []
    for dll, pll, gain, fll in candidates:
        for scenario in scenarios:
            name = f'{scenario.name}_dll{dll}_pll{pll}_fll{int(fll)}'
            result = run(scenario, dll, pll, gain, fll,
                         save_trace=args.report_dir / (name+'.csv'))
            results.append(dict(scenario=asdict(scenario), result=result))
            print(json.dumps(result), flush=True)
    summary = dict(kind='full_precision_research_not_rtl_validation',
                   source_sha256=SOURCE_SHA256,
                   linearized_pi_poles=[linearized_poles(bw) for bw in (1,2,5,10,15)],
                   suite=args.suite, host_elapsed_s=time.perf_counter()-start, results=results)
    (args.report_dir / 'summary.json').write_text(json.dumps(summary, indent=2)+'\n', encoding='utf-8')
    print('TRACKING_REFERENCE_STUDY_COMPLETE', args.suite, flush=True)


if __name__ == '__main__':
    main()
