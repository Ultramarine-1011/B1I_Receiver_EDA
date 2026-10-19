#!/usr/bin/env python3
"""Run from existing WSL Ubuntu; standard library only. Never edits dependencies."""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

EXPERIMENT = Path(__file__).resolve().parents[1]
ROOT = EXPERIMENT.parents[1]
sys.path.insert(0, str(EXPERIMENT/'model'))
from reference import generate, window, code, N


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path)
    parser.add_argument('--cases', nargs='+', default=[
        'main', 'gaps', 'phase3', 'terminal', 'zero', 'restart'])
    args = parser.parse_args()
    stamp = datetime.now(timezone(timedelta(hours=8))).strftime('%Y%m%d_%H%M%S')
    out = args.output or EXPERIMENT/'runs'/stamp
    out = out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    mirror = Path(tempfile.mkdtemp(prefix='bdi_capture_'))
    teacher = ROOT/'work/teacher_bdi_capture'
    sources = [teacher/'bdi_prn_code_pkg.sv', teacher/'bdi_signal_source.sv',
               ROOT/'rtl/b1i_prn_gen.sv', EXPERIMENT/'rtl/bdi_sliding_capture.sv',
               EXPERIMENT/'tb/tb_bdi_capture.sv']
    manifest = {'status': 'RUNNING', 'time_singapore': stamp,
                'output': str(out), 'build_mirror': str(mirror),
                'source_sha256': {str(p.relative_to(ROOT)): digest(p) for p in sources},
                'commands': [], 'cases': {}}

    def save():
        (out/'run_summary.json').write_text(json.dumps(manifest, indent=2)+'\n')

    def command(argv: list[str], cwd: Path, logfile: Path, timeout: int = 180):
        record = {'argv': argv, 'cwd': str(cwd), 'log': str(logfile.relative_to(out))}
        manifest['commands'].append(record)
        save()
        print('COMMAND:', ' '.join(argv), flush=True)
        started = time.monotonic()
        with logfile.open('w', encoding='utf-8') as log:
            log.write('COMMAND_JSON: '+json.dumps(argv)+'\nCWD: '+str(cwd)+'\n')
            log.flush()
            try:
                result = subprocess.run(argv, cwd=cwd, stdout=log, stderr=subprocess.STDOUT,
                                        timeout=timeout, check=False)
                record['exit_code'] = result.returncode
            except subprocess.TimeoutExpired:
                record['exit_code'] = 124
            record['wall_seconds'] = round(time.monotonic()-started, 3)
            log.write('\nEXIT_CODE: '+str(record['exit_code'])+'\n')
        save()
        print('EXIT:', record['exit_code'], 'SECONDS:', record['wall_seconds'],
              'LOG:', record['log'], flush=True)
        if record['exit_code'] != 0:
            print(logfile.read_text(errors='replace')[-6000:], flush=True)
            raise RuntimeError(f'command failed; see {logfile}')

    try:
        for path in sources:
            shutil.copy2(path, mirror/path.name)
        manifest['mirror_sha256'] = {p.name: digest(mirror/p.name) for p in sources}
        assert all(digest(p) == digest(mirror/p.name) for p in sources)
        command(['verilator', '--version'], mirror, out/'verilator_version.log')
        command(['g++', '--version'], mirror, out/'compiler_version.log')
        command([sys.executable, str(EXPERIMENT/'model/reference.py'), '--teacher', str(teacher),
                 '--output', str(out/'reference')], mirror, out/'reference.log')
        reference = json.loads((out/'reference/reference.json').read_text())
        manifest['reference'] = reference
        save()
        command(['verilator', '--binary', '--timing', '--trace', '--assert', '-Wall',
                 '-Wno-fatal', '-Wno-BLKSEQ', '-Wno-SYNCASYNCNET', '-Wno-UNUSEDSIGNAL',
                 '--top-module', 'tb_bdi_capture', '-j', '2',
                 '--Mdir', str(mirror/'obj_dir'), *[p.name for p in sources]],
                mirror, out/'build.log')
        warnings = [line for line in (out/'build.log').read_text().splitlines() if line.startswith('%Warning')]
        manifest['build_warnings'] = warnings
        assert not any('bdi_sliding_capture.sv:' in line or 'tb_bdi_capture.sv:' in line for line in warnings), \
            'new experiment RTL/TB has a compiler warning'
        executable = str(mirror/'obj_dir/Vtb_bdi_capture')
        for case in args.cases:
            case_dir = out/case
            case_dir.mkdir()
            for p in (out/'reference').glob('*.mem'):
                shutil.copy2(p, case_dir/p.name)
            argv = [executable, f'+CASE={case}']
            if case == 'main': argv += ['+TRACE=capture.vcd']
            command(argv, case_dir, case_dir/'simulation.log', 120)
            log = (case_dir/'simulation.log').read_text()
            assert log.count('BDI_CAPTURE_PASS ') == 1, 'missing/duplicate TB PASS marker'
            rows = list(csv.DictReader((case_dir/'windows.csv').open()))
            expected_count = {'phase3': 6, 'terminal': 2, 'restart': 26}.get(case, 13)
            assert len(rows) == expected_count, f'{case}: incomplete windows'
            for row in rows:
                k = int(row['window'])-1
                p = int(row['result_phase'])
                assert int(row['accepted']) == (k+1)*N
                e = int(row['energy'])
                i, q = int(row['i_result']), int(row['q_result'])
                assert e == abs(i)+abs(q)
                if case in ('main', 'gaps', 'restart', 'phase3'):
                    source_phase = 3 if case == 'phase3' else 10
                    assert p == min(k, source_phase)
                    ref = window(p, k, source_phase)
                    assert (i, q, e) == (ref['i'], ref['q'], ref['energy'])
                    assert int(row['hit']) == int(k == source_phase)
                    assert int(row['acquired']) == int(k >= source_phase)
                else:
                    assert int(row['hit']) == 0 and int(row['acquired']) == 0
                    assert p == k
                    if case == 'zero': assert e == 0
                    if case == 'terminal': assert e == 21
            manifest['cases'][case] = {'status': 'PASS', 'windows': len(rows),
                'max_energy': max(int(r['energy']) for r in rows),
                'hit_windows': [int(r['window']) for r in rows if r['hit'] == '1'],
                'csv_sha256': digest(case_dir/'windows.csv'),
                'tb_result': next(line for line in log.splitlines() if line.startswith('BDI_CAPTURE_PASS '))}
            if case == 'main':
                vcd = case_dir/'capture.vcd'
                with vcd.open() as f:
                    header = ''
                    for line in f:
                        header += line
                        if '$enddefinitions' in line: break
                for name in ('consumed_rx_code', 'consumed_local_code', 'i_product', 'q_product',
                             'i_acc', 'q_acc', 'i_result', 'q_result', 'energy', 'dump',
                             'candidate_phase', 'result_phase', 'captured_phase', 'hit'):
                    assert f' {name} ' in header, f'missing trace signal {name}'
                manifest['waveform'] = {'path': str(vcd.relative_to(out)), 'bytes': vcd.stat().st_size,
                                         'sha256': digest(vcd), 'required_signals': 'PASS'}
            save()
        assert all(digest(p) == manifest['source_sha256'][str(p.relative_to(ROOT))] for p in sources)
        manifest['status'] = 'PASS'
        save()
        (EXPERIMENT/'runs/LATEST.txt').write_text(str(out)+'\n')
        print('BDI_EXPERIMENT_PASS:', out, flush=True)
        return 0
    except Exception as error:
        manifest['status'] = 'FAIL'
        manifest['error'] = repr(error)
        save()
        print('BDI_EXPERIMENT_FAIL:', repr(error), 'EVIDENCE:', out, flush=True)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
