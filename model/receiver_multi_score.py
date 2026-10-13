"""Validate all four actual receiver channels; no scene identity/frequency truth."""
from pathlib import Path
import sys,json,argparse,statistics
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'work/plotdeps'))
sys.path.insert(0,str(ROOT/'student_release/student_release/tools'))
from decode_records import decode
from prompt_d1 import recover_navigation
def main():
    ap=argparse.ArgumentParser();ap.add_argument('directory',type=Path);ap.add_argument('--require-navigation',action='store_true');args=ap.parse_args()
    dest=args.directory;raw=(dest/'receiver_records.bin').read_bytes();assert len(raw)%32==0
    records=[decode(raw[n:n+32]) for n in range(0,len(raw),32)]
    end=records[-1];assert end['type']=='end' and sum(r['type']=='end' for r in records)==1
    assert not end['underrun'] and not end['overflow']
    acq=[r for r in records if r['type']=='acquisition' and r['detected']]
    assert len(acq)==4 and len({r['prn'] for r in acq})==4 and {r['channel'] for r in acq}=={0,1,2,3}
    summaries=[]
    for a in acq:
        rows=[r for r in records if r['type']=='tracking' and r['prn']==a['prn']]
        assert len(rows)>=900
        assert all(r['channel']==a['channel'] and r['generation']==1 and r['schema_version']==3 for r in rows)
        assert all(abs(b['sample_index']-a['sample_index']-16368)<=2 for a,b in zip(rows,rows[1:]))
        tail=rows[-200:];tail_lock=sum(r['locked'] for r in tail)/len(tail)
        assert tail_lock>=0.95,(a['prn'],tail_lock)
        nav=[r for r in records if r['type']=='navigation' and r['prn']==a['prn']]
        obs=[r for r in records if r['type']=='common_observation' and r['prn']==a['prn']]
        assert len(obs)==end['sample_index']//16368000-1
        assert len({r['common_epoch_id'] for r in obs})==len(obs)
        for r in obs:
            assert r['sample_index']==r['common_epoch_id']*16368000 and r['generation']==1 and r['channel']==a['channel']
            if r['measurement_valid']:assert all(r[k] for k in ('locked','nh_valid','frame_valid','time_valid','bch_valid','active'))
        valid_obs=sum(r['measurement_valid'] for r in obs)
        if args.require_navigation:
            assert len(nav)>=10 and valid_obs>=1,(a['prn'],len(nav),valid_obs)
            assert all(all(r[k] for k in ('locked','nh_valid','frame_valid','time_valid','bch_valid')) for r in nav)
        summaries.append(dict(prn=a['prn'],channel=a['channel'],acquisition_lag=a['lag_samples'],acquisition_fcw=a['doppler_word'],
                              prompts=len(rows),locked=sum(r['locked'] for r in rows),tail_lock=tail_lock,
                              tail_median_doppler_hz=statistics.median(r['doppler_word']*16368000/2**32 for r in tail),
                              navigation=len(nav),observations=len(obs),valid_observations=valid_obs))
    if args.require_navigation:
        software,diag=recover_navigation(records)
        expected={(r['prn'],r['sow'],r['subframe_id'],r['word_number'],r['raw_word'],r['information']) for r in software}
        nav=[r for r in records if r['type']=='navigation']
        for r in nav: assert (r['prn'],r['sow'],r['subframe_id'],r['word_number'],r['raw_word'],r['information']) in expected,r
        (dest/'independent_prompt_diagnostic.json').write_text(json.dumps(diag,indent=2)+'\n')
    result=dict(status='MULTI_REAL_SCORE_PASS',samples=end['sample_index'],records=len(records),channels=summaries,
                navigation_required=args.require_navigation)
    (dest/'metrics.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
if __name__=='__main__':main()
