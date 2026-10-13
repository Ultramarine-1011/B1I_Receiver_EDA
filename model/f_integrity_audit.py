"""Verify frozen E/teacher inputs, current reports and bounded document links."""
import argparse,hashlib,json,re,subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(4*1024*1024),b''):h.update(b)
    return h.hexdigest()

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--final',action='store_true');args=ap.parse_args()
    out=ROOT/'reports/f_stage';out.mkdir(parents=True,exist_ok=True)
    original=json.loads((ROOT/'reports/e_stage/final/final_integrity.json').read_text(encoding='utf-8-sig'))
    integrity=[]
    for item in original:
        p=ROOT/Path(item['path'].replace('\\','/'));actual=sha(p)
        match=actual.lower()==item['actual'].lower();integrity.append({'path':str(p.relative_to(ROOT)),'sha256':actual,'e_baseline_match':match})
        if not match:raise AssertionError(('frozen source changed',p))
    for p in [ROOT/'student_release/student_release/output/receiver_records.bin',ROOT/'reports/e_stage/final/receiver_records.bin']:
        h=sha(p)
        if h!='c9c4d23d1bc53bc44687a65c6473e5169fdedc0601ec71c5b1c69aa4eccdd501':raise AssertionError(('E bin changed',p,h))
        integrity.append({'path':str(p.relative_to(ROOT)),'sha256':h,'e_baseline_match':True})
    docs=['GOAL.md','STATUS.md','docs/COURSE_MASTER_PLAN.md','docs/F_MULTICHANNEL_DESIGN.md','docs/PERFORMANCE_EVALUATION.md','docs/SYNTHESIS_READINESS.md']
    links=[]
    for name in docs:
        p=ROOT/name
        for target in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
            if '://' in target or target.startswith('#'):continue
            target=target.split('#')[0]
            if not (p.parent/target).exists():raise AssertionError(('broken link',name,target))
            links.append({'source':name,'target':target})
    rtl=[{'path':str(p.relative_to(ROOT)),'sha256':sha(p)} for p in sorted((ROOT/'student_release/student_release/rtl').glob('*')) if p.suffix in ('.sv','.svh')]
    runtime_audit=[]
    if args.final:
        manifest=json.loads((out/'real20/sources.json').read_text(encoding='utf-8-sig'))
        for item in manifest['sources']:
            p=Path(item['path'])
            if p.suffix=='.cpp':p=out/'real20/driver_snapshot.cpp'
            h=sha(p)
            if h.lower()!=item['sha256'].lower():raise AssertionError(('real20 compiled source differs',p))
            runtime_audit.append({'path':str(p.relative_to(ROOT)),'sha256':h,'real20_compiled_match':True})
        old=(out/'real20/driver_snapshot.cpp').read_text(encoding='utf-8')
        new=(ROOT/'scripts/receiver_fast.cpp').read_text(encoding='utf-8')
        new=re.sub(r'            // An EOF exactly.*?ordinary RUN EOF still drains promptly\.\n','',new,flags=re.S)
        if old.replace('++end_wait>10000000','++end_wait>2000000000ULL')!=new:
            raise AssertionError('driver changed beyond documented EOF watchdog')
        checks=[('f3_current/tb_channel_bank.run.log','CHANNEL_BANK_PASS'),('f3_current/tb_channel_reuse.run.log','CHANNEL_REUSE_PASS'),
                ('f3_current/tb_satellite_manager.run.log','SATELLITE_MANAGER_PASS'),('f3_current/tb_f_transport.run.log','F_TRANSPORT_PASS'),
                ('f3_current/tb_navigation_bank.run.log','NAVIGATION_BANK_PASS'),('f3_recovery/tb_f_integration.run.log','F_INTEGRATION_PASS'),
                ('legacy_e0/e0_score.log','RECEIVER_E0_INDEPENDENT_SCORE_PASS'),('performance/metrics_self_test.log','PERFORMANCE_METRICS_SELF_TEST_PASS'),
                ('performance/tb_p02_probe.run.log','P02_RTL_TIMING_PROBE_PASS'),('real20/run.log','FAST_RTL_PASS'),('driver_tail64/run.log','FAST_RTL_PASS')]
        for name,marker in checks:
            log=(out/name).read_text(encoding='utf-8-sig')
            if marker not in log or 'EXIT_CODE: 0' not in log:raise AssertionError(('current PASS log absent',name))
    result={'status':'F_FROZEN_SOURCE_AND_LINK_AUDIT_PASS','head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'integrity':integrity,'links_checked':len(links),'current_rtl':rtl,'real20_runtime_sources':runtime_audit,
        'limits':'Integrity and document links only. RTL behavior needs per-test current source manifests.'}
    (out/'integrity_audit.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(result['status'],f'frozen_files={len(integrity)} links={len(links)}')

if __name__=='__main__':main()
