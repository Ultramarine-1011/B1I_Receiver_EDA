"""Independent float signal/correlation for a small RTL acquisition test.

Only IF samples enter DUT. Expected lag/frequency/detection remain in TB.
No scan of extra algorithm parameters; deterministic high-SNR static cases.
"""
from pathlib import Path
import json, math, hashlib, csv, sys
from b1i_prn_golden import generate_prn

ROOT=Path(__file__).resolve().parents[1]
FS=16_368_000; IF=4_092_000; N=16368
CASES=[
    dict(name='aligned', source_prn=6, receiver_prn=6, lag=0, hz=0, max_lag=16, frequency_grid=[0], detected=1),
    dict(name='positive', source_prn=6, receiver_prn=6, lag=16, hz=1000, max_lag=32, frequency_grid=[-1000,0,1000], detected=1),
    dict(name='negative', source_prn=12, receiver_prn=12, lag=8, hz=-1000, max_lag=24, frequency_grid=[-1000,0,1000], detected=1),
    dict(name='wrong_prn', source_prn=6, receiver_prn=12, lag=0, hz=0, max_lag=0, frequency_grid=[0], detected=0),
]

def check_cells():
    manifest=json.loads((ROOT/'tb/vectors/acquisition/manifest.json').read_text())
    rows=list(csv.DictReader((ROOT/'reports/local/acquisition_cells.csv').open()))
    expected=[(case,candidate) for case,item in enumerate(manifest) for candidate in item['candidates']]
    assert len(rows)==len(expected)==31
    worst=0.0
    for row,(case,ref) in zip(rows,expected):
        assert int(row['case'])==case and int(row['lag_samples'])==ref['lag']
        assert int(row['doppler_word'])==round(ref['hz']*2**32/FS)
        # Predeclared 2% bound relative to max(cell power, window energy):
        # covers 10-bit nearest phase + integer amplitude quantization, including null cells.
        error=abs(int(row['power'])-ref['power'])/max(ref['power'],ref['energy'])
        assert error<=0.02, (row,ref,error)
        assert abs(int(row['energy'])-ref['energy'])/ref['energy']<=0.002
        worst=max(worst,error)
    print(f'ACQUISITION_FLOAT_SCORE_PASS cells=31 max_normalized_power_error={worst:.8g} limit=0.02')

def main():
    dest=ROOT/'tb/vectors/acquisition'; dest.mkdir(parents=True,exist_ok=True)
    manifest=[]
    for case in CASES:
        prn=[1-2*b for b in generate_prn(case['source_prn'])]
        local=[1-2*b for b in generate_prn(case['receiver_prn'])]
        x=[]
        for n in range(N):
            signal=2*prn[((n-case['lag'])%N)//8]*math.cos(2*math.pi*(0.13+(IF+case['hz'])*n/FS))
            x.append(-3 if signal < -1 else -1 if signal < 0 else 1 if signal < 1 else 3)
        payload=''.join(f'{(v+3)//2:x}\n' for v in x)
        (dest/(case['name']+'.mem')).write_text(payload,encoding='ascii')
        candidates=[]
        for hz in case['frequency_grid']:
            cs=[2047*math.cos(2*math.pi*(IF+hz)*n/FS) for n in range(N)]
            sn=[-2047*math.sin(2*math.pi*(IF+hz)*n/FS) for n in range(N)]
            energy=sum(v*v*(c*c+s*s) for v,c,s in zip(x,cs,sn))
            for lag in range(0,case['max_lag']+1,8):
                ii=sum(v*c*local[((n-lag)%N)//8] for n,(v,c) in enumerate(zip(x,cs)))
                qq=sum(v*s*local[((n-lag)%N)//8] for n,(v,s) in enumerate(zip(x,sn)))
                candidates.append(dict(lag=lag,hz=hz,power=ii*ii+qq*qq,energy=energy))
        best=max(candidates,key=lambda a:a['power'])
        if case['detected']:
            assert (best['lag'],best['hz'])==(case['lag'],case['hz']), (case,best)
        assert int(best['power']>16*best['energy'])==case['detected'], (case,best)
        item=dict(**case,float_best=best,cells=len(candidates),candidates=candidates,sha256=hashlib.sha256(payload.encode()).hexdigest())
        manifest.append(item)
        print('ACQUISITION_VECTOR_PASS',case['name'],'cells',len(candidates),'best',best['lag'],best['hz'],'power/energy',best['power']/best['energy'])
    (dest/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print('ACQUISITION_VECTORS_PASS cases=4')
if __name__=='__main__':
    check_cells() if '--check' in sys.argv else main()
