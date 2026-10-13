#!/usr/bin/env python3
"""Research scans and explicit whole-interval gates beyond tail-only metrics."""
from __future__ import annotations
import argparse
import csv
from dataclasses import asdict
import hashlib
import json
from pathlib import Path
import time

import numpy as np
from tracking_reference import Scenario, run, SOURCE_SHA256


def score_trace(path: Path, dynamic_start: float | None):
    with path.open() as stream:
        rows = list(csv.DictReader(stream))
    time_s = np.array([float(r['time_s']) for r in rows])
    phase = np.array([float(r['carrier_error_turns']) for r in rows])
    code = np.array([float(r['code_error_chips']) for r in rows])
    freq = np.array([float(r['frequency_error_hz']) for r in rows])
    lock = np.array([int(r['carrier_lock']) and int(r['code_lock']) for r in rows])
    mask = time_s >= (dynamic_start if dynamic_start is not None else 1.5)
    assert mask.any() and np.all(np.abs(np.diff(time_s)-0.001) < 1e-10)
    # Costas ambiguity crossings AFTER acquisition are scored, not hidden by fold.
    slips = int(np.sum(np.abs(np.diff(phase[mask])) > 0.25))
    block_means = [abs(np.mean(freq[mask][start:start+1000]))
                   for start in range(0, int(mask.sum())-999, 1000)]
    return dict(scored_seconds=float(mask.sum())*0.001,
        max_phase_error_turns=float(np.max(np.abs(phase[mask]))),
        max_code_error_chips=float(np.max(np.abs(code[mask]))),
        max_frequency_error_hz=float(np.max(np.abs(freq[mask]))),
        max_one_second_mean_frequency_hz=max(block_means) if block_means else None,
        lock_fraction=float(np.mean(lock[mask])), ambiguity_crossings=slips,
        trace_sha256=hashlib.sha256(path.read_bytes()).hexdigest())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--suite', choices=('fll', 'long'), required=True)
    parser.add_argument('--report-dir', type=Path, required=True)
    args = parser.parse_args()
    args.report_dir.mkdir(parents=True, exist_ok=True)
    started = time.perf_counter()
    if args.suite == 'fll':
        scenarios = [Scenario(name='positive_200_noise45', seconds=3,
            cn0_dbhz=45, initial_frequency_error_hz=200, seed=3101),
            Scenario(name='negative_200_noise40', seconds=3, prn=23,
            cn0_dbhz=40, initial_frequency_error_hz=-200,
            true_carrier_phase_turns=-0.249, seed=3102)]
        gains = (0.05, 0.1, 0.2, 0.5)
    else:
        scenarios = [Scenario(name='long_bounded_dynamic_noise45', prn=37, seconds=32,
            cn0_dbhz=45, dynamic_start_s=1, acceleration_hz_s=26.036,
            jerk_hz_s2=-26.036, seed=3201)]
        gains = (0.2,)
    records = []
    for gain in gains:
        for scenario in scenarios:
            filename = args.report_dir / f'{scenario.name}_gain{gain}.csv'
            result = run(scenario, dll_bw=5, pll_bw=15, fll_gain=gain, save_trace=filename)
            whole = score_trace(filename, scenario.dynamic_start_s if args.suite == 'long' else None)
            passed = (result['screen_pass'] and result['first_lock_time_s'] is not None
                and result['first_lock_time_s'] <= 1.5
                and whole['max_phase_error_turns'] <= 0.08
                and whole['max_code_error_chips'] <= 0.15
                and whole['max_one_second_mean_frequency_hz'] is not None
                and whole['max_one_second_mean_frequency_hz'] <= 1.0
                and whole['lock_fraction'] >= 0.95 and whole['ambiguity_crossings'] == 0)
            if args.suite == 'long':
                passed = passed and whole['scored_seconds'] >= 30
            record = dict(scenario=asdict(scenario), tail=result, whole_interval=whole, passed=passed)
            records.append(record)
            print(json.dumps(record), flush=True)
    summary = dict(suite=args.suite, kind='full_precision_not_fixed_or_rtl',
        source_sha256=SOURCE_SHA256,
        quality_source_sha256=hashlib.sha256(Path('model/quality_model.py').read_bytes()).hexdigest(),
        validation_source_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        host_elapsed_s=time.perf_counter()-started, records=records)
    (args.report_dir/'summary.json').write_text(json.dumps(summary, indent=2)+'\n', encoding='utf-8')
    if args.suite == 'long':
        assert all(r['passed'] for r in records), 'LONG_DYNAMIC_REFERENCE_FAIL'
        print('LONG_DYNAMIC_REFERENCE_PASS')
    else:
        print('FLL_GAIN_STUDY_COMPLETE')


if __name__ == '__main__':
    main()
