"""Independent truth scoring of actual RTL BIN using the unmodified teacher decoder.

Truth is read only by this scorer; the receiver sees IF bits and search ranges.
Limits declared here before successful RTL execution: code <0.15 chip, tail
frequency <3 Hz, phase <0.04 turn modulo Costas polarity, float Prompt <2%.
"""
from pathlib import Path
import sys, math, json
from b1i_prn_golden import generate_prn
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'student_release/student_release/tools'))
from decode_records import decode
FS=16_368_000; N=16368
NH='00000100110101001110'
def fold(v,period): return v-period*math.floor(v/period+0.5)
def main():
    results=[]
    for c,(prn,lag,hz) in enumerate([(6,0,0),(6,16,1000),(12,-8,-1000)]):
        raw=(ROOT/f'reports/local/e0_case{c}.bin').read_bytes()
        assert len(raw)%32==0
        records=[decode(raw[i:i+32]) for i in range(0,len(raw),32)]
        (ROOT/f'reports/local/e0_case{c}.jsonl').write_text(''.join(json.dumps(r)+'\n' for r in records))
        acq=[r for r in records if r['type']=='acquisition']
        track=[r for r in records if r['type']=='tracking']
        assert len(acq)==1 and acq[0]['detected'] and acq[0]['prn']==prn
        assert acq[0]['lag_samples']==lag%N and acq[0]['sample_index']==0
        assert sum(r['type']=='end' for r in records)==1 and records[-1]['type']=='end'
        assert records[-1]['sample_index']==4_092_000 and not records[-1]['underrun'] and not records[-1]['overflow']
        assert len(track)>=247 and sum(r['locked'] for r in track)>=50
        assert all(abs(b['sample_index']-a['sample_index']-N)<=2 for a,b in zip(track,track[1:]))
        assert all(r['schema_version']==3 and r['generation']==1 and r['prn']==prn for r in track)
        codes=[abs(fold(r['code_chip']+r['code_fraction']/2**32-(r['sample_index']-lag)/8,2046)) for r in track]
        tail=track[-30:]
        frequencies=[abs(r['doppler_word']*FS/2**32-hz) for r in tail]
        phases=[abs(fold(0.04+(4_092_000+hz)*r['sample_index']/FS-r['carrier_phase']/2**32,0.5)) for r in tail]
        assert max(codes)<0.15,(c,max(codes))
        assert max(frequencies)<3,(c,max(frequencies))
        assert max(phases)<0.04,(c,max(phases))
        # Direct float synthesis/correlation on first complete window; using
        # actual emitted oscillator state, independent PRN, no DUT internals.
        code=[1-2*b for b in generate_prn(prn)]
        r=track[0]; ii=qq=0.0
        first_ref=N if lag==0 else N+lag%N
        first_phase=(r['carrier_phase']-(2**30+r['doppler_word'])*(r['sample_index']-first_ref))%2**32
        for n in range(first_ref,first_ref+N):
            s=code[((n-lag)%N)//8]*(1-2*int(NH[((n-lag+N)//N)%20]))
            a=2*s*math.cos(2*math.pi*(0.04+(4_092_000+hz)*n/FS))
            x=-3 if a < -1 else -1 if a < 0 else 1 if a < 1 else 3
            local_index=((n-first_ref)//8)%2046
            theta=2*math.pi*(first_phase/2**32+(2**30+r['doppler_word'])*(n-first_ref)/2**32)
            ii+=x*2047*math.cos(theta)*code[local_index]
            qq-=x*2047*math.sin(theta)*code[local_index]
        relative=math.hypot(r['prompt_i']*16-ii,r['prompt_q']*16-qq)/math.hypot(ii,qq)
        assert relative<0.02,(c,relative)
        results.append(dict(case=c,prn=prn,lag=lag,hz=hz,tracking=len(track),locked=sum(r['locked'] for r in track),
                            max_code_error_chip=max(codes),tail_max_frequency_error_hz=max(frequencies),
                            tail_max_phase_error_turn=max(phases),first_prompt_float_relative_error=relative,
                            acquisition_cycles=acq[0]['acquisition_cycles']))
    (ROOT/'reports/local/e0_metrics.json').write_text(json.dumps(results,indent=2)+'\n')
    print('RECEIVER_E0_INDEPENDENT_SCORE_PASS',json.dumps(results))
if __name__=='__main__': main()
