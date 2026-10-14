"""Offline independent P01/P03 scoring. Failed detections remain in counts."""
import json,math,argparse
from pathlib import Path
from performance_metrics import acquisition_statistics,FS
from g_resource_audit import sha
ROOT=Path(__file__).resolve().parents[1]
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--folder',type=Path,default=ROOT/'reports/g_stage/acquisition');a=ap.parse_args();folder=a.folder
    specs=json.loads((folder/'scenarios.json').read_text())
    rows=[json.loads(line) for line in (folder/'acquisition_results.jsonl').read_text().splitlines()]
    trials=[];scores=[]
    for s in specs['cases']:
        candidates=[r for r in rows if r['case_index']==s['index']]
        assert len(candidates)==2 and {r['prn'] for r in candidates}=={6,7}
        r=next(r for r in candidates if r['prn']==6);hz=r['doppler_word']*FS/2**32
        lag_error=(r['lag_samples']-s['lag_samples']+8184)%16368-8184
        verified=bool(s['target_present'] and r['detected'] and abs(lag_error)<=s['independent_lag_tolerance_samples'] and abs(hz-s['doppler_hz'])<=s['independent_frequency_tolerance_hz'])
        trials.append(dict(id=s['id'],seed=s['seed'],target_present=s['target_present'],verified_success=verified,
            detected=bool(r['detected']),observation_seconds=.004,accepted_cycle=r['accepted_cycle'],verified_cycle=r['verified_cycle'],queued_cycle=r['accepted_cycle']))
        case_pass=verified if s['target_present'] else not r['detected']
        scores.append(dict(id=s['id'],status='SELF_GENERATED_PASS' if case_pass else 'FAIL',verified_success=verified,detected=bool(r['detected']),lag_error_samples=lag_error if s['target_present'] else None,
            frequency_error_hz=hz-s['doppler_hz'] if s['target_present'] else None,observed=r))
    result={'status':'PARTIAL','completed_subset_status':'SELF_GENERATED_PASS' if all(s['status']=='SELF_GENERATED_PASS' for s in scores) else 'FAIL',
       'origin':'SELF_GENERATED','scope':specs['scope'],'coverage':specs['coverage'],
       'statistics':acquisition_statistics(trials),'scores':scores,
       'raw_results_sha256':sha(folder/'acquisition_results.jsonl'),'scenario_manifest_sha256':sha(folder/'scenarios.json'),
       'evaluation_sources':{name:sha(ROOT/name) for name in ('model/g_acquisition_score.py','model/performance_metrics.py')},
       'formal_P01_P03':'BLOCKED_INPUT; short marginal coverage/6+2 independent seeds do not meet full coverage or 100+100/10s criteria'}
    (folder/'score_input.json').write_text(json.dumps({'metric':'acquisition','trials':trials},indent=2)+'\n')
    (folder/'metrics.json').write_text(json.dumps(result,indent=2)+'\n')
    print('G_INDEPENDENT_ACQUISITION_SCORE_COMPLETE',json.dumps(result['statistics']))
if __name__=='__main__':main()
