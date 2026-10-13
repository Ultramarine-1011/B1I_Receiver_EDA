"""G0: immutable baseline, local resources and exact input gaps. No DUT truth."""
import hashlib,json,subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'reports/g_stage'
E_SHA='c9c4d23d1bc53bc44687a65c6473e5169fdedc0601ec71c5b1c69aa4eccdd501'

def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda:f.read(4*1024*1024),b''):h.update(b)
    return h.hexdigest()

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    frozen=json.loads((ROOT/'reports/e_stage/final/final_integrity.json').read_text(encoding='utf-8-sig'))
    checks=[]
    for item in frozen:
        p=ROOT/item['path'].replace('\\','/');actual=sha(p)
        assert actual.lower()==item['actual'].lower(),('frozen file changed',p)
        checks.append({'path':p.relative_to(ROOT).as_posix(),'sha256':actual,'match':True})
    for name in ('student_release/student_release/output/receiver_records.bin','reports/e_stage/final/receiver_records.bin'):
        p=ROOT/name;assert sha(p)==E_SHA,('E success BIN changed',p)
        checks.append({'path':name,'sha256':E_SHA,'match':True})
    f=json.loads((ROOT/'reports/f_stage/real20/sources.json').read_text(encoding='utf-8-sig'))
    rtl=[]
    for item in f['sources']:
        if item['path'].endswith('.cpp'):continue
        tail=item['path'].replace('\\','/').split('/student_release/student_release/')[-1]
        p=ROOT/'student_release/student_release'/tail
        actual=sha(p);assert actual.lower()==item['sha256'].lower(),('F RTL changed',p)
        rtl.append({'path':p.relative_to(ROOT).as_posix(),'sha256':actual,'f_compiled_match':True})
    contract=json.loads((ROOT/'student_release/student_release/input/input_contract.json').read_text())
    scene={'id':contract['package_id'],'origin':'teacher_public_development','path':'student_release/student_release/input/scenario.if2',
           'sha256':sha(ROOT/'student_release/student_release/input/scenario.if2'),'fs_hz':contract['sample_rate_hz'],
           'if_hz':contract['if_frequency_hz'],'duration_s':100,'visible_d1_satellites':6,'prns':None,
           'cn0_db_hz':40,'prequantization_power':None,'noise_seed':None,'pdop':None,'ephemeris_truth':None,
           'time_truth':None,'code_phase_truth':None,'doppler_truth':None,'nav_word_truth':None,
           'receiver_ecef_truth':None,'dynamic_truth':None,'metadata':'teacher README + input_contract.json',
           'formal_suite_qualification':False}
    resources=[]
    for folder in ('student_release/student_release/input','model','tb','EDA_CONTEXT_COMPRESSED'):
        for p in sorted((ROOT/folder).rglob('*')):
            if p.is_file() and p.suffix in ('.if2','.json','.py','.sv','.pdf'):
                resources.append({'path':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size})
    gaps={
      'P01':'independent phase/frequency/NH truth and qualified 40dB-Hz coverage cases',
      'P02':'no input block for measured diagnostics; per-task instrumentation required',
      'P03':'per-CN0 100 present + 100 absent independent seeded 10s cases, target/candidate truth',
      'P04':'10 independent cold starts, >=180s, >=6D1, PDOP<=4, different frame starts',
      'P05':'CN0 sweep with independent cold starts and full 60s post-confirmation followup',
      'P06':'60s seeded CN0 sweep with independent code/doppler/transmitted-word truth',
      'P07':'12D1 40dB-Hz IF and continuous D01-D04 truth, >=30s after sync',
      'P08':'qualified nominal IF with real 2s RF interruption and valid NAV/OBS recovery',
      'P09':'independent fixed ECEF truth, consistent geometry/model and complete 60s window'}
    report={'status':'G0_FROZEN_BASELINE_AUDIT_PASS','head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
            'frozen':checks,'f_compiled_rtl':rtl,'scenarios':[scene], 'local_resource_inventory':resources,
            'formal_gaps':gaps,'generator_audit':'No complete GNSS IF/navigation/geometry generator exists locally. Primary/NH and Prompt generators can be reused for isolated diagnostics only.'}
    (OUT/'resource_audit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('G0_FROZEN_BASELINE_AUDIT_PASS',f'frozen={len(checks)} rtl={len(rtl)} resources={len(resources)} E_BIN={E_SHA}')

if __name__=='__main__':main()
