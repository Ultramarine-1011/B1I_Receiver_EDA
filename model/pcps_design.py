"""Independent FFT search diagnostic: never supplies initialization to RTL.

Public IF only. Quarter-IF wipe + /4 decimation, 4096-point padded correlation,
4 x 1ms noncoherent power, PRNs 6..37, -10..10kHz/500Hz. Padding is not an
exact circular B1I correlation: candidate lag requires exact serial refinement.
"""
from pathlib import Path
import sys, json, time
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'work/plotdeps'))
import numpy as np
from b1i_prn_golden import generate_prn
FS=16368000; M=4092; FFT=4096
def main():
    started=time.monotonic()
    payload=(ROOT/'student_release/student_release/input/scenario.if2').open('rb').read(4*M)
    b=np.frombuffer(payload,dtype=np.uint8)
    x=np.stack([(b>>s)&3 for s in (6,4,2,0)],axis=1).reshape(4,M,4).astype(np.float64)*2-3
    base=(x[:,:,0]-x[:,:,2])+1j*(-x[:,:,1]+x[:,:,3])
    freqs=np.arange(-10000,10001,500)
    ffts=np.fft.fft(base[None,:,:]*np.exp(-2j*np.pi*freqs[:,None,None]*np.arange(M)[None,None,:]*4/FS),n=FFT,axis=2)
    out=[]
    for prn in range(6,38):
        code=np.repeat(1-2*np.asarray(generate_prn(prn)),2)
        spectrum=np.fft.fft(code,n=FFT)
        power=np.sum(np.abs(np.fft.ifft(ffts*np.conj(spectrum)[None,None,:],axis=2))**2,axis=1)
        f,l=np.unravel_index(np.argmax(power),power.shape)
        signed_l=int(l) if l<FFT//2 else int(l)-FFT
        out.append(dict(prn=prn,hz=int(freqs[f]),fft_index=int(l),lag_samples=(4*signed_l)%16368,
                        peak=float(power[f,l]),mean=float(np.mean(power[f])),ratio=float(power[f,l]/np.mean(power[f]))))
    out.sort(key=lambda r:r['ratio'],reverse=True)
    report=dict(description=__doc__,seconds=time.monotonic()-started,ms=4,results=out)
    (ROOT/'reports/e_stage/pcps_float_diagnostic.json').write_text(json.dumps(report,indent=2)+'\n')
    print('PCPS_FLOAT_DIAGNOSTIC',json.dumps(report))
if __name__=='__main__':main()
