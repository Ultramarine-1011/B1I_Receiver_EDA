"""First real-IF PCPS grid bit-exact model; candidates float cross-check.
Does not provide any data/configuration to the receiver.
"""
from pathlib import Path
import csv,json,sys
from fft_fixed import COS,SIN,transform
from b1i_prn_golden import generate_prn
ROOT=Path(__file__).resolve().parents[1]
N=4096;M=4092
def main():
    payload=(ROOT/'student_release/student_release/input/scenario.if2').open('rb').read(M*4)
    x=[((b>>s)&3)*2-3 for b in payload for s in (6,4,2,0)]
    code=[((1-2*b)*65536,0) for b in generate_prn(6) for _ in (0,1)]+[(0,0)]*4
    spectrum=transform(code)
    power=[0]*N
    for w in range(4):
        values=[];phase=0
        for m in range(M):
            pos=(w*M+m)*4;br=x[pos]-x[pos+2];bi=-x[pos+1]+x[pos+3]
            wr=COS[phase>>20];wi=SIN[phase>>20]
            values.append((((br*wr+bi*wi)*2048)>>30,((bi*wr-br*wi)*2048)>>30))
            phase=(phase-2624000*4)&0xffffffff
        values+= [(0,0)]*4
        signal=transform(values)
        products=[(ar*br+ai*bi,ai*br-ar*bi) for (ar,ai),(br,bi) in zip(signal,spectrum)]
        assert all(-2**31<=v<2**31 for z in products for v in z)
        corr=transform(products,inverse=True)
        power=[p+re*re+im*im for p,(re,im) in zip(power,corr)]
    rows=list(csv.DictReader((ROOT/'reports/e_stage/pcps_first_grid.csv').open()))
    assert len(rows)==N
    for k,row in enumerate(rows): assert int(row['index'])==k and int(row['power'])==power[k],(k,row,power[k])
    expected=json.loads((ROOT/'reports/e_stage/pcps_float_diagnostic.json').read_text())['results']
    ref={r['prn']:r for r in expected}
    results=list(csv.DictReader((ROOT/'reports/e_stage/pcps_real_candidates.csv').open()))
    assert len(results)==32
    from pcps_exact_candidates import candidates
    exact=candidates()
    errors=[]
    for row in results:
        prn=int(row['prn']);r=ref[prn]
        for field in ('lag_samples','doppler_word','peak','mean','detected'):
            assert int(row[field])==exact[prn][field],(prn,field,row,exact[prn])
        # Floats use exact +/-10kHz; RTL FCW rounding is <0.012Hz, twiddle quantization <0.002turn.
        if int(row['detected']):
            assert int(row['lag_samples'])==r['lag_samples']
            assert abs(int(row['doppler_word'])*16368000/2**32-r['hz'])<0.02
        ratio=int(row['peak'])/int(row['mean']);error=abs(ratio-r['ratio'])/r['ratio']
        assert error<0.03,(row,r,error)
        assert int(row['detected'])==int(ratio>8)
        errors.append(error)
    print(f'PCPS_FIXED_SCORE_PASS exact_first_grid_bins={N} exact_global_candidates={len(results)} max_ratio_relative_error={max(errors):.8g}')
if __name__=='__main__':main()
