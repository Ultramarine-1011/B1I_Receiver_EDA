"""Historical G closeout audit; invoke explicitly, outside record validation.

No simulation, input generation, DUT mutation, or truth-assisted reception.
"""
import json, subprocess, sys
from collections import defaultdict
from pathlib import Path
from g_resource_audit import ROOT, sha

OUT = ROOT / 'reports/g_stage'
sys.path.insert(0, str(ROOT / 'student_release/student_release/tools'))
from decode_records import decode


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))


def main():
    manifests = []
    for p in sorted(OUT.rglob('sources.json')):
        m = read(p)
        checks = []
        for s in m['sources']:
            original = Path(s['path'])
            candidate = original
            snapshot = False
            if sha(candidate).lower() != s['sha256'].lower():
                # The CN40 run predates extra coarse diagnostics in this TB.
                if p.parent.name == 'acquisition' and original.name == 'tb_g_acquisition.sv':
                    candidate = p.parent / 'tb_snapshot.sv'
                    snapshot = True
                else:
                    raise AssertionError(('compiled source mismatch', p, original))
            assert sha(candidate).lower() == s['sha256'].lower(), candidate
            checks.append({'path': original.relative_to(ROOT).as_posix(),
                           'sha256': s['sha256'].lower(), 'snapshot_used': snapshot})
        manifests.append({'manifest': p.relative_to(ROOT).as_posix(),
                          'manifest_sha256': sha(p), 'head_at_build': m['head'],
                          'source_count': len(checks), 'checks': checks})

    completed_logs = []
    paths = ['real51/run.log', 'real52/run.log', 'recovery/run.log',
             'fixed_fifo102400/run.log', 'acquisition/run.log', 'acquisition_cn50/run.log',
             'service/c1/run.log', 'service/c4/run.log', 'service/c12/run.log']
    paths += [f'tracking/{k}.run.log' for k in ('static', 'D01', 'D02', 'D03', 'D04')]
    paths += [f'holding/hold_cn{c}.run.log' for c in (50, 40)]
    for rel in paths:
        p = OUT / rel
        log = p.read_text(encoding='utf-8-sig')
        assert 'EXIT_CODE: 0' in log and 'file not found' not in log, p
        completed_logs.append({'path': p.relative_to(ROOT).as_posix(), 'sha256': sha(p), 'exit_code': 0})
    small = (OUT / 'fixed_fifo64/run.log').read_text(encoding='utf-8-sig')
    assert 'G_FIXED_SOURCE_FIFO_OVERFLOW' in small and 'EXIT_CODE: 1' in small
    assert read(OUT / 'fixed_fifo64/status.json')['status'] == 'FAIL'
    validations = read(OUT / 'real52/validation_commands.json')
    assert len(validations) == 8 and all(v['exit_code'] == 0 for v in validations)
    assert 'EXIT_CODE: 0' in (OUT / 'evaluation_tests.log').read_text(encoding='utf-8-sig')
    assert 'Ran 18 tests' in (OUT / 'evaluation_tests.log').read_text(encoding='utf-8-sig')

    raw = (OUT / 'real52/receiver_records.bin').read_bytes()
    side = [json.loads(l) for l in (OUT / 'real52/receiver_records.bin.availability.jsonl').read_text().splitlines()]
    assert len(raw) // 32 == len(side) == 208429
    nav_obs = {}
    last_sample = last_cycle = -1
    for i, s in enumerate(side):
        assert s['sequence'] == i and s['available_sample'] >= last_sample and s['hardware_cycle'] > last_cycle
        last_sample, last_cycle = s['available_sample'], s['hardware_cycle']
        r = decode(raw[i*32:(i+1)*32])
        if r['type'] in ('navigation', 'common_observation'):
            r.update(s); nav_obs[i] = r
    positions = read(OUT / 'real52/causal/key_positions.json')
    summary = read(OUT / 'real52/causal/summary.json')
    assert [p['common_epoch_id'] for p in positions] == [49, 50, 51]
    for p in positions:
        observations = [nav_obs[i] for i in p['used_obs']]
        assert p['valid'] and len(observations) == 4 and len({o['prn'] for o in observations}) == 4
        assert all(o['measurement_valid'] and o['sample_index'] == p['epoch_sample'] for o in observations)
        assert max(o['sequence'] for o in observations) == p['output_sequence']
        assert max(o['available_sample'] for o in observations) == p['available_sample']
        obs_by_prn = {o['prn']: o for o in observations}
        for seq in p['used_raw_nav']:
            n = nav_obs[seq]; o = obs_by_prn[n['prn']]
            assert n['type'] == 'navigation' and n['bch_valid'] and n['generation'] == o['generation']
            assert n['sequence'] < o['sequence'] and n['available_sample'] <= o['available_sample']
    for m in summary['milestones'].values():
        e = m['ephemeris_ready']; words = [nav_obs[i] for i in e['used_raw_nav']]
        assert len(words) == 30 and {r['subframe_id'] for r in words} == {1, 2, 3}
        assert all(r['generation'] == e['generation'] and r['prn'] == e['prn'] for r in words)
        assert {(r['sow']-6*(r['subframe_id']-1)) % 604800 for r in words} == {e['frame_start']}
        for sf in (1, 2, 3):
            assert [r['word_number'] for r in words if r['subframe_id'] == sf] == list(range(1, 11))
        assert max(r['sequence'] for r in words) == e['sequence']
    assert summary['ttff']['status'] == 'COMPLETED' and not summary['ttff']['rejected']
    assert summary['ttff']['ttff_signal_seconds'] == positions[-1]['available_sample'] / 16368000
    for p, h in summary['evaluation_sources'].items():
        assert sha(ROOT / p) == h, ('causal evaluator changed after replay', p)

    bins = []
    for name in ('real51', 'real52', 'recovery', 'fixed_fifo102400'):
        folder = OUT / name; m = read(folder / 'metrics.json')
        assert sha(folder / 'receiver_records.bin') == m['bin_sha256']
        assert sha(folder / 'receiver_records.bin.availability.jsonl') == m['sidecar_sha256']
        assert m['record_types']['end'] == 1
        bins.append({'folder': name, 'bin_sha256': m['bin_sha256'], 'sidecar_sha256': m['sidecar_sha256'],
                     'record_types': m['record_types'], 'time_domains': m['time_domains']})

    r = read(OUT / 'recovery/recovery_metrics.json')
    assert r['status'] == 'SELF_GENERATED_PASS' and r['recovered_generation'] == 3
    a = r['reacquisition_events'][0]
    phase_error = (a['sample_index'] + a['lag_samples'] + 8184) % 16368 - 8184
    assert abs(phase_error) <= 1 and a['doppler_word'] == 0
    for key in ('first_recovered_locked', 'first_recovered_nav', 'first_recovered_valid_obs'):
        assert r[key]['generation'] == 3 and r[key]['sequence'] > a['sequence']
    assert r['healthy_demodulation_window']['expected_words'] == 20
    assert r['healthy_demodulation_window']['missing_words'] == 0
    assert r['invalidly_valid_obs_after_actual_loss'] == 0

    registry = read(OUT / 'resource_audit.json')['scenarios']
    acq = []
    for name in ('acquisition', 'acquisition_cn50'):
        specs = read(OUT / name / 'scenarios.json'); metrics = read(OUT / name / 'metrics.json')
        cases = []
        for s, score in zip(specs['cases'], metrics['scores']):
            mem = ROOT / 'work/g_stage' / name / f"case{s['index']}.mem"
            assert sha(mem) == s['mem_sha256']
            cases.append(dict(s, observed_status=score['status']))
        registry.append({'id': name, 'origin': 'self_generated_module_IF_samples', 'cases': cases,
                         'scenarios_sha256': sha(OUT / name / 'scenarios.json'),
                         'formal_suite_qualification': False, 'ephemeris_truth': None,
                         'receiver_ecef_truth': None, 'pdop': None,
                         'frequency_kind': 'carrier_only_offset; no propagation code-rate offset',
                         'code_generator_at_generation': specs.get('generator_sha256'),
                         'note': 'Missing generation-time source hash remains unknown; stored per-case stimulus and truth hashes are audited.'})
        acq.append({'name': name, 'status': metrics['status'], 'subset_status': metrics['completed_subset_status'],
                    'detection': metrics['statistics']['detection'], 'false_alarm': metrics['statistics']['false_alarm']})
    tracking = []
    truth_paths = list((OUT / 'tracking').glob('*.truth.json')) + list((OUT / 'holding').glob('*.truth.json')) + [OUT / 'recovery/truth.json']
    for p in truth_paths:
        t = read(p); assert sha(ROOT / t['if_path']) == t['if_sha256']
        row = {k:v for k,v in t.items() if k not in ('transmitted_raw_words', 'transmitted_information')}
        row.update(id=p.stem, truth_manifest=p.relative_to(ROOT).as_posix(), truth_sha256=sha(p),
                   ephemeris_truth=None, receiver_ecef_truth=None, pdop=None,
                   nav_word_truth='independent transmitted payload arrays in truth manifest; not qualified ephemerides',
                   time_truth='local sample/frame start only; no qualified GNSS propagation time',
                   code_phase_truth='continuous generator trajectory, offline scoring only',
                   doppler_truth='continuous generator trajectory, offline scoring only', formal_suite_qualification=False)
        registry.append(row)
        if p.parent.name != 'recovery':
            m = read(p.with_name(p.name.replace('.truth.json', '.metrics.json')))
            tracking.append({'case': p.stem, 'status': m['status'], 'cn0_db_hz': m['cn0_db_hz'],
                             'scored_seconds': m['scored_seconds'], 'quality': m['quality'],
                             'locked_ratio': m['scored_locked_ratio']})
    registry += [
        {'id': 'E100', 'origin': 'historical_actual_RTL', 'evidence': 'reports/e_stage/final',
         'current_G_rerun': False, 'sha256': 'c9c4d23d1bc53bc44687a65c6473e5169fdedc0601ec71c5b1c69aa4eccdd501'},
        {'id': 'F20', 'origin': 'historical_actual_RTL', 'evidence': 'reports/f_stage/real20', 'current_G_rerun': False},
        {'id': 'F12NAV', 'origin': 'synthetic_Prompt_module_stimulus', 'evidence': 'reports/f_stage/f3_current/nav',
         'formal_suite_qualification': False},
        {'id': 'G_bank_1_4_12', 'origin': 'teacher_public_IF_with_artificial_digital_channel_initialization',
         'evidence': 'reports/g_stage/service/summary.json', 'formal_suite_qualification': False}]
    (OUT / 'scenario_registry.json').write_text(json.dumps(registry, indent=2)+'\n')
    result = {'status': 'G_DELIVERY_EVIDENCE_AUDIT_PASS',
              'head_at_audit': subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip(),
              'scope': 'completed run logs, exact compiled source/input hashes, actual NAV/OBS causal dependencies; no official performance qualification',
              'compiled_source_manifests': manifests, 'completed_simulations': completed_logs,
              'actual_record_runs': bins, 'current_public52_validation_checks': len(validations),
              'causal_position_epochs': [p['common_epoch_id'] for p in positions],
              'causal_ttff_seconds': summary['ttff']['ttff_signal_seconds'],
              'causal_dependency_audit': 'all raw NAV precede their own same-generation OBS; complete same-frame 30 words per PRN',
              'recovery_independent_phase_error_samples': phase_error,
              'acquisition_summary': acq, 'tracking_summary': tracking,
              'service': read(OUT / 'service/summary.json'),
              'finite_fifo102400_peak_words': read(OUT / 'fixed_fifo102400/receiver_records.bin.service.json')['fifo_high_water_words'],
              'formal_realtime': 'UNVERIFIED; missing clock/SRAM/service model and sustained twelve-D1 load',
              'audit_source_sha256': sha(Path(__file__))}
    (OUT / 'delivery_audit.json').write_text(json.dumps(result, indent=2)+'\n')
    print('G_DELIVERY_EVIDENCE_AUDIT_PASS', f'manifests={len(manifests)} completed_simulations={len(paths)} positions=49/50/51 recovered_generation=3')
    print(json.dumps({'acquisition': acq, 'tracking': tracking, 'service': result['service'],
                      'recovery_times_s': {k:r[k]['available_sample']/16368000 for k in ('first_recovered_locked','first_recovered_nav','first_recovered_valid_obs')}}, ensure_ascii=False))


if __name__ == '__main__':
    main()
