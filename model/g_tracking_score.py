"""Score actual RTL loop snapshots against the independent signal trajectory."""
import argparse,csv,json,math
from pathlib import Path
import numpy as np
from g_signal_scenarios import trajectory,FS,RC,RF,C
from performance_metrics import tracking_quality
from g_resource_audit import sha
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--trace',type=Path,required=True);ap.add_argument('--truth',type=Path,required=True);ap.add_argument('--output',type=Path,required=True)
    a=ap.parse_args();truth=json.loads(a.truth.read_text());rows=list(csv.DictReader(a.trace.open()))
    refs=np.asarray([int(r['window_ref'])+16368 for r in rows]);t=refs/FS;d,v,_=trajectory(truth['kind'],t)
    truecode=RC*t+RC/RF*truth['base_doppler_hz']*t-RC*d/C;truefreq=truth['base_doppler_hz']-RF*v/C
    scored=[]
    for r,c,f in zip(rows,truecode,truefreq):
        ref=int(r['window_ref'])
        if ref<2*FS:continue
        err=(int(r['end_code_phase_q'])/2**32-c+1023)%2046-1023
        hz=(int(r['carrier_step_word'])-2**30)*FS/2**32
        # Every emitted NCO snapshot is measurable, including windows where
        # the loop declines an energy-gated update. Do not discard those errors
        # or make an incomplete 1s frequency bin from the private usable flag.
        scored.append({'sample_ref':ref,'valid':True,'locked':bool(int(r['locked'])),
            'code_error_chip':float(err),'frequency_error_hz':float(hz-f)})
    duration=int(truth['duration_s'])-2;quality=tracking_quality(scored,duration_s=duration)
    passed=bool(quality.get('holding_working_point_observed'))
    result={'status':'SELF_GENERATED_PASS' if passed else 'FAIL','scope':'loop-only independent B1I IF diagnostic, no reacquisition manager, no D1/OBS/PVT qualification',
      'kind':truth['kind'],'signal_sha256':truth['if_sha256'],'truth_sha256':sha(a.truth),'trace_sha256':sha(a.trace),
      'cn0_db_hz':truth['cn0_db_hz'],'noise_seed':truth['noise_seed'],'scored_seconds':duration,'quality':quality,
      'scored_locked_ratio':sum(r['locked'] for r in scored)/len(scored) if scored else None,
      'loop_usable_ratio_diagnostic':sum(int(r['usable']) for r in rows if int(r['window_ref'])>=2*FS)/len(scored) if scored else None,
      'warm_cn0_db_hz':truth.get('warm_cn0_db_hz'),
      'evaluation_sources':{str(p.relative_to(Path(__file__).resolve().parents[1])).replace('\\','/'):sha(p) for p in (Path(__file__),Path(__file__).with_name('g_signal_scenarios.py'),Path(__file__).with_name('performance_metrics.py'))},
      'formal_P06_P07':'BLOCKED_INPUT; module self-generated holding is not a qualified teacher sensitivity sweep or twelve-D1 scene',
      'complete_60s_holding_window':duration>=60 and quality['status']=='MEASURED' and truth['kind']=='static'}
    a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,indent=2)+'\n')
    print('G_TRACKING_INDEPENDENT_SCORE_COMPLETE',json.dumps(result))
if __name__=='__main__':main()
