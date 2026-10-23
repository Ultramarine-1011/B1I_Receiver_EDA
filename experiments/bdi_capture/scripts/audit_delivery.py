#!/usr/bin/env python3
"""Verify source identity and recorded results of an existing BDI run.

No simulation is run. Exit 0: PASS; 1: FAIL; 2: missing teacher dependency.
"""
import argparse
import csv
import hashlib
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

EXPERIMENT = Path(__file__).resolve().parents[1]
ROOT = EXPERIMENT.parents[1]
CASES = {'main', 'gaps', 'phase3', 'terminal', 'zero', 'restart'}
SOURCES = {
    'work/teacher_bdi_capture/bdi_prn_code_pkg.sv',
    'work/teacher_bdi_capture/bdi_signal_source.sv',
    'rtl/b1i_prn_gen.sv',
    'experiments/bdi_capture/rtl/bdi_sliding_capture.sv',
    'experiments/bdi_capture/tb/tb_bdi_capture.sv',
}
TEACHER = {n for n in SOURCES if n.startswith('work/')}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def audit(run, result):
    missing = sorted(n for n in TEACHER if not (ROOT/n).is_file())
    result['missing_dependencies'] = missing
    if missing:
        raise FileNotFoundError('teacher dependencies missing; extract ZIP to work/teacher_bdi_capture/: '
                                + ', '.join(missing))
    summary = json.loads((run/'run_summary.json').read_text())
    require(summary['status'] == 'PASS' and set(summary['source_sha256']) == SOURCES,
            'invalid simulation status or incomplete source hash set')
    for name, value in summary['source_sha256'].items():
        require(sha(ROOT/name) == value, f'current raw source SHA256 differs from simulation: {name}')
        require(summary['mirror_sha256'][Path(name).name] == value,
                f'build mirror SHA256 differs from simulation source: {name}')
    result['current_source_sha256'] = summary['source_sha256']
    require(set(summary['cases']) == CASES, 'six acceptance cases required')
    for command in summary['commands']:
        log = (run/command['log']).read_text()
        require(command['exit_code'] == 0 and log.rstrip().endswith('EXIT_CODE: 0'),
                f'command or log exit failure: {command["log"]}')
    for case, record in summary['cases'].items():
        require(record['status'] == 'PASS', f'case failed: {case}')
        require(record['tb_result'] in (run/case/'simulation.log').read_text().splitlines(),
                f'TB PASS record mismatch: {case}')
        require(sha(run/case/'windows.csv') == record['csv_sha256'], f'CSV SHA256 mismatch: {case}')
        with (run/case/'windows.csv').open(newline='') as f:
            rows = list(csv.DictReader(f))
        require(len(rows) == record['windows'], f'window count mismatch: {case}')
    require(json.loads((run/'reference/reference.json').read_text()) == summary['reference'],
            'reference evidence differs from run summary')
    result['existing_simulation_evidence'] = {'status': 'PASS', 'cases': sorted(CASES),
                                             'commands': len(summary['commands']), 'rerun': 'NOT_RUN'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--output', type=Path, help='new JSON path; existing files are never overwritten')
    args = parser.parse_args()
    stamp = datetime.now(timezone(timedelta(hours=8))).strftime('%Y%m%d_%H%M%S_%f')
    output = (args.output or ROOT/f'work/bdi_delivery_audit_{stamp}.json').resolve()
    if output.exists():
        parser.error(f'refusing to overwrite existing evidence: {output}')
    result = {'status': 'FAIL', 'scope': 'existing run sources, exits and outputs',
              'run': str(args.run.resolve())}
    try:
        audit(args.run.resolve(), result)
        result['status'], code = 'PASS', 0
    except FileNotFoundError as error:
        result['status'] = 'BLOCKED_INPUT' if result.get('missing_dependencies') else 'FAIL'
        result['error'], code = str(error), 2 if result['status'] == 'BLOCKED_INPUT' else 1
    except (ValueError, KeyError, OSError) as error:
        result['error'], code = str(error), 1
    result['exit_code'] = code
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open('x', encoding='utf-8') as f:
        f.write(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    print(f'BDI_CURRENT_DELIVERY_{result["status"]}: {output}')
    if code:
        print(result['error'])
    return code


if __name__ == '__main__':
    raise SystemExit(main())
