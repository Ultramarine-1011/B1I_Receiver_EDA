#!/usr/bin/env python3
"""Read-only integrity and current-source evidence audit; writes own JSON only."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

EXPERIMENT = Path(__file__).resolve().parents[1]
ROOT = EXPERIMENT.parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run', type=Path, required=True)
    args = parser.parse_args()
    run = args.run.resolve()
    baseline = json.loads((EXPERIMENT/'evidence/baseline.json').read_text(encoding='utf-8-sig'))
    allowed = {'STATUS.md','WORKLOG.md'}
    changed, missing = [], []
    for name, value in baseline['files'].items():
        p = ROOT/name
        if not p.is_file(): missing.append(name)
        elif sha(p) != value: changed.append(name)
    assert not missing, f'pre-existing files removed: {missing}'
    assert set(changed) <= allowed, f'protected files changed: {set(changed)-allowed}'
    summary = json.loads((run/'run_summary.json').read_text())
    assert summary['status'] == 'PASS'
    for name, value in summary['source_sha256'].items():
        assert sha(ROOT/name) == value, f'current RTL/TB differs from simulation: {name}'
    rtl = (EXPERIMENT/'rtl/bdi_sliding_capture.sv').read_text()
    module_header = rtl.split('    localparam', 1)[0]
    inputs = re.findall(r'input\s+logic(?:\s+signed)?(?:\s+\[[^\]]+\])?\s+(\w+)', module_header)
    assert inputs == ['clk','rst_n','if_sample','if_valid'], inputs
    assert '$readmem' not in rtl and 'bdi_prn_code_pkg' not in rtl
    assert 'b1i_prn_gen local_prn' in rtl
    assert sha(ROOT/'rtl/b1i_prn_gen.sv') == baseline['files']['rtl/b1i_prn_gen.sv']
    head = subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    assert head == baseline['head'], 'HEAD changed during no-commit task'
    readme = EXPERIMENT/'README.md'
    links = re.findall(r'!?\[[^\]]*\]\(([^)]+)\)',readme.read_text(encoding='utf-8'))
    for link in links:
        if '://' not in link:
            target = (readme.parent/link.split('#')[0]).resolve()
            if target != run/'delivery_audit.json':
                assert target.exists(), f'broken link {link}'
    whitespace = []
    for p in EXPERIMENT.rglob('*'):
        if not p.is_file() or 'runs' in p.relative_to(EXPERIMENT).parts or 'evidence' in p.relative_to(EXPERIMENT).parts:
            continue
        if p.suffix in ('.py','.sv','.md','.ps1') or p.name == '.gitignore':
            for k,line in enumerate(p.read_text(encoding='utf-8-sig').splitlines(),1):
                if line.rstrip() != line: whitespace.append(f'{p}:{k}')
    assert not whitespace, whitespace
    result = {'status':'PASS', 'baseline_files':len(baseline['files']),
              'unchanged_protected_files':len(baseline['files'])-len(changed),
              'intentional_state_log_changes':changed, 'missing_files':missing,
              'current_rtl_tb_hash_match':'PASS', 'dut_inputs':inputs,
              'teacher_and_original_prn':'SHA256 unchanged',
              'head_unchanged':head, 'readme_links_checked':len(links),
              'reference_and_runner_sha256_at_audit': {
                  str(p.relative_to(EXPERIMENT)): sha(p) for p in
                  [EXPERIMENT/'model/reference.py', EXPERIMENT/'scripts/run.py', EXPERIMENT/'run.ps1']},
              'source_whitespace':'PASS', 'full_receiver_DC_ICC':'NOT_RUN'}
    (run/'delivery_audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('BDI_DELIVERY_AUDIT_PASS:', json.dumps(result,ensure_ascii=False))


if __name__ == '__main__':
    main()
