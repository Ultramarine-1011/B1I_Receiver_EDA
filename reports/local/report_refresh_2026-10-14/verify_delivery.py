from pathlib import Path
import json,hashlib,re,subprocess
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'AGENTS.md').is_file() and (p/'student_release').is_dir())
AREA=ROOT/'work/report_waveforms';E=ROOT/'reports/local/report_refresh_2026-10-14';A=ROOT/'docs/report_assets'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
pro=json.loads((A/'waveform_provenance.json').read_text(encoding='utf8'))
fail=[]
for row in pro['sources']:
    p=ROOT/row['path']
    if sha(p).lower()!=row['sha256'].lower():fail.append('changed compile source '+row['path'])
for name in ['tb_nh_d1.sv','tb_navigation_d1.sv','tb_p02_probe.sv','tb_tracking_minimal.sv']:
    original=(ROOT/'tb'/name).read_text(encoding='utf-8')
    expected=original.replace('../../tb/vectors/',ROOT.as_posix()+'/tb/vectors/').replace('../../reports/local/',AREA.as_posix()+'/')
    if (AREA/name).read_text(encoding='utf8')!=expected:fail.append('non-path change in '+name)
inputs=[]
for source,target in [('tb/vectors/b1i_prn_06.mem','b1i_prn_06.mem'),('work/navigation/bits.mem','bits.mem'),('work/navigation/raw.mem','raw.mem'),('work/navigation/info.mem','info.mem')]:
    if sha(ROOT/source)!=sha(AREA/target):fail.append('input copy mismatch '+target)
    inputs.append({'source':source,'actual_copy':'work/report_waveforms/'+target,'sha256':sha(AREA/target)})
for source in ['tb/vectors/nh_d1/nav_bits.mem','tb/vectors/nh_d1/expected_words.mem','student_release/student_release/rom/fft_cos_q30.mem','student_release/student_release/rom/fft_sin_q30.mem','student_release/student_release/rtl/carrier_quarter_lut.svh']:
    inputs.append({'source':source,'sha256':sha(ROOT/source)})
for row in pro['images']:
    if sha(A/row['image'])!=row['image_sha256']:fail.append('image hash '+row['image'])
    if sha(ROOT/row['source_wlf'])!=row['wlf_sha256']:fail.append('WLF hash '+row['image'])
    if sha(ROOT/row['source_vcd'])!=row['vcd_sha256']:fail.append('VCD hash '+row['image'])
    if sha(ROOT/row['events_csv'])!=row['events_sha256']:fail.append('CSV hash '+row['image'])
for row in pro['reused_svg']:
    if sha(A/row['image'])!=sha(ROOT/row['source']):fail.append('SVG copy '+row['image'])
for name,marker in [('modelsim_nh_d1.log','NH_D1_MODULE_PASS cases=3 words=9'),('modelsim_tb_navigation_d1.log','NAVIGATION_D1_PASS cases=2'),('modelsim_tb_p02_probe.log','P02_RTL_TIMING_PROBE_PASS'),('modelsim_tb_tracking_minimal.log','TRACKING_WAVE_PARTIAL_30000US_NOT_FULL_REGRESSION')]:
    text=(E/name).read_text(encoding='utf-8-sig')
    if marker not in text or not text.rstrip().endswith('EXIT_CODE: 0') or re.search(r'\*\* (?:Fatal|Error):',text):fail.append('run evidence '+name)
protected=['rtl','model','tb','student_release','docs/archive','plan.md','AGENTS.md','GOAL.md','EDA_ENV_STATUS.md']
rc=subprocess.run(['git','diff','--quiet','HEAD','--',*protected],cwd=ROOT).returncode
if rc!=0:fail.append('protected tracked paths changed')
preserved={}
expected_bin='c9c4d23d1bc53bc44687a65c6473e5169fdedc0601ec71c5b1c69aa4eccdd501'
for source in ['student_release/student_release/output/receiver_records.bin','reports/e_stage/final/receiver_records.bin']:
    actual=sha(ROOT/source);preserved[source]=actual
    if actual!=expected_bin:fail.append('E100 preserved BIN '+source)
# Assert the actual measurements used in the report tables, without rerunning RTL.
for folder,samples,nav,obs,valid in [('e_stage/final',1636800000,560,396,324),('f_stage/real20',327360000,40,76,4)]:
    data=json.loads((ROOT/'reports'/folder/'metrics.json').read_text(encoding='utf-8-sig'))
    actual=(data['samples'],sum(c['navigation'] for c in data['channels']),sum(c['observations'] for c in data['channels']),sum(c['valid_observations'] for c in data['channels']))
    if actual!=(samples,nav,obs,valid):fail.append('table metrics '+folder)
g=json.loads((ROOT/'reports/g_stage/real52/metrics.json').read_text(encoding='utf-8-sig'))
if (g['service']['samples'],g['record_types']['navigation'],g['record_types']['common_observation'])!=(851136000,240,204):fail.append('G52 table')
pro['actual_inputs_and_includes']=inputs
pro['artifact_hash_audit']='PASS' if not fail else 'FAIL'
(A/'waveform_provenance.json').write_text(json.dumps(pro,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
result={'status':'PASS' if not fail else 'FAIL','protected_paths_unchanged':rc==0,'TB_copies_only_path_changes':True if not any('non-path' in s for s in fail) else False,'E100_hashes':preserved,'images_checked':len(pro['images'])+len(pro['reused_svg']),'inputs_checked':len(inputs),'run_logs_checked':4,'real_E_F_G_table_metrics_checked':True,'failures':fail}
(E/'delivery_audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(json.dumps(result,ensure_ascii=False))
if fail:raise SystemExit(1)
