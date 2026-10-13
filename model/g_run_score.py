"""Audit actual G driver records and join traceable P02/time/service measurements."""
import argparse,json,re,sys
from pathlib import Path
from collections import Counter
from g_resource_audit import sha
from performance_metrics import FS,time_domains
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'student_release/student_release/tools'))
from decode_records import decode

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--folder',type=Path,required=True);a=ap.parse_args();p=a.folder
    manifest=json.loads((p/'sources.json').read_text(encoding='utf-8-sig'))
    bin=p/'receiver_records.bin';stats=json.loads(Path(str(bin)+'.service.json').read_text());counts=Counter();previous=(-1,-1);seq=0;end=None
    acquisition_outputs=[]
    with bin.open('rb') as f,Path(str(bin)+'.availability.jsonl').open() as s:
        while raw:=f.read(32):
            assert len(raw)==32;r=decode(raw);e=json.loads(s.readline())
            assert e['sequence']==seq and e['available_sample']>=previous[0] and e['hardware_cycle']>previous[1]
            assert e['available_sample']<=stats['samples'];assert end is None
            counts[r['type']]+=1
            if r['type']=='acquisition':acquisition_outputs.append(dict(r,**e))
            if r['type']=='end':end=r
            previous=(e['available_sample'],e['hardware_cycle']);seq+=1
        assert not s.readline()
    assert end and not end['underrun'] and not end['overflow'] and end['sample_index']==stats['samples']
    assert stats['records']==seq and stats['processed_samples']==stats['samples']
    events=[json.loads(line) for line in Path(str(bin)+'.events.jsonl').read_text().splitlines()]
    tasks={};starts={};trials=[]
    for e in events:
        task=e['task_id'];key=(task,e['prn'])
        if e['kind']=='capture_task_accepted':tasks[task]=e
        elif e['kind']=='prn_compute_start':starts[key]=e
        elif e['kind']=='coarse_result':
            start=starts[key];queue=tasks[task]
            trials.append({'task_id':task,'prn':e['prn'],'capture_request_cycle':queue['hardware_cycle'],
                'capture_reference_available_sample':queue['available_sample'],'prn_compute_start_cycle':start['hardware_cycle'],
                'queue_after_shared_capture_cycles':start['hardware_cycle']-queue['hardware_cycle'],
                'coarse_compute_cycles':e['hardware_cycle']-start['hardware_cycle'],'coarse_detected':bool(e['detected']),
                'coarse_result_cycle':e['hardware_cycle'],'verified_result_cycle':None,'first_output_cycle':None})
        elif e['kind']=='verified_result':
            matches=[t for t in trials if (t['task_id'],t['prn'])==key]
            if matches:
                t=matches[-1];t['verified_result_cycle']=e['hardware_cycle'];t['verified_detected']=bool(e['detected'])
                t['refine_and_review_cycles']=e['hardware_cycle']-t['coarse_result_cycle']
                t['prn_compute_to_verified_cycles']=e['hardware_cycle']-t['prn_compute_start_cycle']
    for r in acquisition_outputs:
        matches=[t for t in trials if t['prn']==r['prn'] and t['verified_result_cycle'] is not None and t['verified_result_cycle']<=r['hardware_cycle'] and t['first_output_cycle'] is None]
        if matches:
            t=matches[-1];t.update(first_output_cycle=r['hardware_cycle'],first_output_available_sample=r['available_sample'],
                output_sequence=r['sequence'],lag_samples=r['lag_samples'],doppler_word=r['doppler_word'],detected=r['detected'],
                verification_to_output_cycles=r['hardware_cycle']-t['verified_result_cycle'])
    # A type5 cycle field is deliberately not used as a per-PRN start time.
    service=dict(stats,minimum_average_clock_hz=stats['cycles']*FS/stats['samples'],
      run_minimum_average_clock_hz=stats['run_cycles']*FS/stats['run_samples'] if stats['run_samples'] else None,
      input_ready_duty=stats['input_ready_cycles']/sum(stats['state_cycles']),
      output_ready_duty=stats['output_ready_cycles']/sum(stats['state_cycles']),
      records_per_signal_second=seq*FS/stats['samples'],
      limits='Measured file-driven ready handshake service. Hypothetical backlog uses its observed service schedule; paced finite-FIFO tests are separate. No physical timing closure or 12D1 proof.')
    report={'status':'PARTIAL','head':manifest['head'],'input':manifest['input'],'config':{'channels':manifest['channels'],'narrow':manifest['narrow']},
       'bin_sha256':sha(bin),'sidecar_sha256':sha(Path(str(bin)+'.availability.jsonl')),'record_types':dict(counts),
       'time_domains':time_domains(stats['samples'],stats['cycles'],stats['wall_seconds']), 'service':service,'acquisition_tasks':trials,
       'scoring_sources':{name:sha(ROOT/name) for name in ('model/g_run_score.py','model/performance_metrics.py','student_release/student_release/tools/decode_records.py')},
       'formal_performance':'PARTIAL/BLOCKED_INPUT; structural completion is not a formal performance PASS'}
    (p/'metrics.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('G_ACTUAL_RTL_DATA_PATH_AUDIT_PASS',f'records={seq} samples={stats["samples"]} task_results={len(trials)} bin_sha256={report["bin_sha256"]}')

if __name__=='__main__':main()
