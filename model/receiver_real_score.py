"""Record-only diagnostics and declared E1 lock/cadence acceptance, no truth.
Optional public prompt_d1 carrier/NH analysis is reported independently.
"""
from pathlib import Path
import sys,json,math,argparse,csv,statistics
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'work/plotdeps'))
sys.path.insert(0,str(ROOT/'student_release/student_release/tools'))
from decode_records import decode
from prompt_d1 import _secondary_solution
def main():
    ap=argparse.ArgumentParser();ap.add_argument('directory',type=Path);args=ap.parse_args()
    dest=args.directory
    data=(dest/'receiver_records.bin').read_bytes();assert len(data)%32==0
    records=[decode(data[n:n+32]) for n in range(0,len(data),32)]
    end=records[-1];assert end['type']=='end' and sum(r['type']=='end' for r in records)==1
    assert not end['underrun'] and not end['overflow']
    acquisitions=[r for r in records if r['type']=='acquisition' and r['detected']]
    assert len(acquisitions)>=1
    summaries=[]
    for acquisition in acquisitions:
        prn=acquisition['prn'];rows=[r for r in records if r['type']=='tracking' and r['prn']==prn]
        assert len(rows)>=900
        assert all(abs(b['sample_index']-a['sample_index']-16368)<=2 for a,b in zip(rows,rows[1:]))
        assert all(r['schema_version']==3 and r['generation']==1 for r in rows)
        frequency,phase,coherence,_=_secondary_solution(rows,acquisition['doppler_word']*16368000/2**32)
        tail=rows[-200:];lock=sum(r['locked'] for r in tail)/len(tail)
        assert lock>=0.95,(prn,lock)
        median_hz=statistics.median(r['doppler_word']*16368000/2**32 for r in tail)
        assert abs(median_hz-frequency)<10,(prn,median_hz,frequency)
        summaries.append(dict(prn=prn,lag=acquisition['lag_samples'],acquisition_hz=acquisition['doppler_word']*16368000/2**32,
                              tracking_windows=len(rows),locked_windows=sum(r['locked'] for r in rows),tail_lock=lock,
                              tail_median_hz=median_hz,independent_prompt_frequency_hz=frequency,
                              independent_nh_phase=phase,independent_nh_coherence=coherence))
    report=dict(status='E1_RECORD_SCORE_PASS',samples=end['sample_index'],records=len(records),channels=summaries,
                limitation='No signal-source truth. Teacher frequency/NH diagnostics do not replace RTL navigation.')
    (dest/'metrics.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report))
if __name__=='__main__':main()
