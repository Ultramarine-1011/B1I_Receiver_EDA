"""Proportional G report/link/size checks, without EDA execution."""
import json, re, subprocess
from pathlib import Path
from g_resource_audit import ROOT, sha


def main():
    paths = [ROOT/p for p in ('GOAL.md','STATUS.md','WORKLOG.md','docs/G_PERFORMANCE_DESIGN.md',
        'docs/COURSE_MASTER_PLAN.md','docs/PERFORMANCE_EVALUATION.md','docs/SYNTHESIS_READINESS.md',
        'docs/TBD.md','docs/NEXT_STEPS.md','reports/g_stage/FINAL_REPORT.md')]
    links = []
    for p in paths:
        text = p.read_text(encoding='utf-8-sig')
        for target in re.findall(r'\]\(([^)]+)\)', text):
            if '://' in target or target.startswith('#'): continue
            target = target.split('#')[0]
            resolved = (p.parent / target).resolve()
            assert resolved.exists(), ('broken local document link', p, target)
            links.append({'file': p.relative_to(ROOT).as_posix(), 'target': target})
    report = (ROOT/'reports/g_stage/FINAL_REPORT.md').read_text(encoding='utf-8-sig')
    for row in ('| P01 |','| P02 |','| P03 |','| P04 |','| P05 |','| P06 |','| P07 |','| P08 |','| P09 |'):
        assert row in report, row
    assert report.count('持续实时未证明') >= 2 and '离线因果重放' in report
    names = subprocess.check_output(['git','diff','--cached','--name-only','-z'], cwd=ROOT).decode().split('\0')
    sized = []
    for name in filter(None, names):
        p = ROOT/name
        assert p.stat().st_size <= 1048576, ('large staged artifact', name)
        assert not (p.suffix.lower() in ('.bin','.if2') or name.startswith(('work/','tmp/'))), name
        sized.append({'path': name, 'bytes': p.stat().st_size})
    result = {'status':'G_DOCUMENT_AND_STAGED_ARTIFACT_AUDIT_PASS','local_links_checked':len(links),
              'links':links,'staged_files':sized,'source_sha256':sha(Path(__file__))}
    out=ROOT/'reports/g_stage/document_audit.json'
    out.write_text(json.dumps(result,indent=2)+'\n')
    print('G_DOCUMENT_AND_STAGED_ARTIFACT_AUDIT_PASS',f'links={len(links)} staged_files={len(sized)} no_large_IF_BIN_cache')


if __name__=='__main__': main()
