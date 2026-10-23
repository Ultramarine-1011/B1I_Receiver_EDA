#!/usr/bin/env python3
"""Current delivery integrity, separate from the preserved historical audit.

No simulation is run. Exit 0: PASS; 1: FAIL; 2: missing teacher dependency.
"""
import argparse
import csv
import hashlib
import io
import json
import re
import subprocess
import tarfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

EXPERIMENT = Path(__file__).resolve().parents[1]
ROOT = EXPERIMENT.parents[1]
MERGED_MAIN = 'b17f3d06501a101ec7c5b7f92891514d5b1943c1'
CASES = {'main', 'gaps', 'phase3', 'terminal', 'zero', 'restart'}
SOURCES = {
    'work/teacher_bdi_capture/bdi_prn_code_pkg.sv',
    'work/teacher_bdi_capture/bdi_signal_source.sv',
    'rtl/b1i_prn_gen.sv',
    'experiments/bdi_capture/rtl/bdi_sliding_capture.sv',
    'experiments/bdi_capture/tb/tb_bdi_capture.sv',
}
TEACHER = {n for n in SOURCES if n.startswith('work/')} | {
    'work/teacher_bdi_capture/README.md',
    'work/teacher_bdi_capture/简化BDI信号发生器和捕获判断说明.docx',
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def audit(run, result):
    head = git('rev-parse', 'HEAD').decode().strip()
    result['head'] = head
    require(subprocess.run(['git', 'merge-base', '--is-ancestor', MERGED_MAIN, head],
                           cwd=ROOT, check=False).returncode == 0,
            'HEAD must contain merged main b17f3d0; fetch full history if unavailable')

    # Pin protected tracked files to the known merged tree, including baseline,
    # old failures/audits/logs/PNG and H0. Reports use the accepted merged version.
    scopes = ['rtl', 'tb', 'constraints', 'reports/local/h0_vm',
              'scripts/h0_vm_smoke.sh', 'scripts/h0_dc_prn.tcl',
              'docs/H0_VM_SMOKE.md', 'docs/ACQUISITION_REPORT.md',
              'docs/TRACKING_REPORT.md', 'docs/NH_D1_REPORT.md',
              'experiments/bdi_capture']
    editable = {'experiments/bdi_capture/README.md',
                'experiments/bdi_capture/scripts/audit_delivery.py'}
    checked, eol_only = 0, []
    # Suppress archive's checkout conversion without changing Git configuration.
    with tarfile.open(fileobj=io.BytesIO(git('-c', 'core.autocrlf=false',
                                           'archive', MERGED_MAIN, *scopes))) as archive:
        for member in archive.getmembers():
            if not member.isfile() or member.name in editable:
                continue
            path = ROOT/member.name
            require(path.is_file(), f'missing protected file: {member.name}')
            expected = archive.extractfile(member).read()
            actual = path.read_bytes()
            if hashlib.sha256(actual).digest() != hashlib.sha256(expected).digest():
                # Accept only Git's exact CRLF checkout conversion for text.
                # Simulation-source hashes below still compare raw file bytes.
                require(b'\0' not in expected and actual.replace(b'\r\n', b'\n') == expected,
                        f'protected SHA256 mismatch against merged main: {member.name}')
                eol_only.append(member.name)
            checked += 1
    result['merged_tree_integrity'] = {'status': 'PASS', 'files': checked,
                                     'checkout_crlf_only': eol_only}

    baseline = json.loads((EXPERIMENT/'evidence/baseline.json').read_text(encoding='utf-8-sig'))
    historical = json.loads((EXPERIMENT/'runs/20261019_164411/delivery_audit.json').read_text())
    require(historical['status'] == 'PASS' and historical['head_unchanged'] == baseline['head'],
            'historical audit and baseline do not correspond')
    result['historical_integrity'] = {'status': 'PRESERVED', 'head': baseline['head'],
                                      'scope': '2026-10-19 runtime, not current HEAD equality'}
    missing = sorted(n for n in TEACHER if not (ROOT/n).is_file())
    result['missing_dependencies'] = missing
    if missing:
        raise FileNotFoundError('teacher dependencies missing; extract ZIP to work/teacher_bdi_capture/: '
                                + ', '.join(missing))
    for name in sorted(TEACHER):
        require(sha(ROOT/name) == baseline['files'][name], f'teacher SHA256 mismatch: {name}')
    result['teacher_sha256'] = {n: sha(ROOT/n) for n in sorted(TEACHER)}

    require(run == EXPERIMENT/'runs/20261019_164411',
            '--run must select the immutable six-case acceptance run 20261019_164411')
    summary = json.loads((run/'run_summary.json').read_text())
    require(summary['status'] == 'PASS' and set(summary['source_sha256']) == SOURCES,
            'invalid simulation status or incomplete source hash set')
    for name, value in summary['source_sha256'].items():
        require(sha(ROOT/name) == value, f'current raw source SHA256 differs from simulation: {name}')
        require(summary['mirror_sha256'][Path(name).name] == value,
                f'build mirror SHA256 differs from simulation source: {name}')
    require(sha(ROOT/'rtl/b1i_prn_gen.sv') == baseline['files']['rtl/b1i_prn_gen.sv'],
            'original PRN differs from historical baseline')
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

    rtl = (EXPERIMENT/'rtl/bdi_sliding_capture.sv').read_text()
    inputs = re.findall(r'input\s+logic(?:\s+signed)?(?:\s+\[[^\]]+\])?\s+(\w+)',
                        rtl.split('    localparam', 1)[0])
    require(inputs == ['clk', 'rst_n', 'if_sample', 'if_valid'], f'DUT inputs: {inputs}')
    require('$readmem' not in rtl and 'bdi_prn_code_pkg' not in rtl
            and 'b1i_prn_gen local_prn' in rtl, 'DUT source boundary violation')
    result['dut_inputs'] = inputs
    readme = EXPERIMENT/'README.md'
    links = re.findall(r'!?\[[^\]]*\]\(([^)]+)\)', readme.read_text(encoding='utf-8'))
    for link in links:
        if '://' not in link:
            require((readme.parent/link.split('#')[0]).resolve().exists(), f'broken link: {link}')
    result['readme_links_checked'] = len(links)
    whitespace = []
    for p in EXPERIMENT.rglob('*'):
        if not p.is_file() or {'runs', 'evidence'} & set(p.relative_to(EXPERIMENT).parts):
            continue
        if p.suffix in ('.py', '.sv', '.md', '.ps1') or p.name == '.gitignore':
            for k, line in enumerate(p.read_text(encoding='utf-8-sig').splitlines(), 1):
                if line.rstrip() != line:
                    whitespace.append(f'{p}:{k}')
    require(not whitespace, f'trailing whitespace: {whitespace}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', type=Path, required=True)
    parser.add_argument('--output', type=Path, help='new JSON path; existing files are never overwritten')
    args = parser.parse_args()
    stamp = datetime.now(timezone(timedelta(hours=8))).strftime('%Y%m%d_%H%M%S_%f')
    output = (args.output or ROOT/f'work/bdi_delivery_audit_{stamp}.json').resolve()
    if output.exists():
        parser.error(f'refusing to overwrite existing evidence: {output}')
    result = {'status': 'FAIL', 'scope': 'current main delivery integrity; no new simulation',
              'trusted_merged_main': MERGED_MAIN, 'run': str(args.run.resolve()),
              'full_receiver_VCS_DC_ICC': 'NOT_RUN',
              'large_local_VCD_samples': 'NOT_REQUIRED; historical hashes retained in run evidence'}
    try:
        audit(args.run.resolve(), result)
        result['status'], code = 'PASS', 0
    except FileNotFoundError as error:
        result['status'] = 'BLOCKED_INPUT' if result.get('missing_dependencies') else 'FAIL'
        result['error'], code = str(error), 2 if result['status'] == 'BLOCKED_INPUT' else 1
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError, tarfile.TarError) as error:
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
