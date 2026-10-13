"""Vectorized integer golden: every PRN/frequency/lag, without DUT state.
Uses NumPy only as an array calculator; no floating FFT for expected RTL words.
"""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'work/plotdeps'))
import numpy as np
from fft_fixed import COS,SIN,reverse
from b1i_prn_golden import generate_prn
N=4096;M=4092
def fft_int(real,imag,inverse=False):
    order=np.array([reverse(k) for k in range(N)])
    r=np.array(real[...,order],dtype=np.int64,copy=True);i=np.array(imag[...,order],dtype=np.int64,copy=True)
    for stage in range(1,13):
        span=2**stage;half=span//2;tw=np.arange(half)*(N//span)
        shape=r.shape[:-1]+(N//span,span)
        rr=r.reshape(shape);ii=i.reshape(shape)
        ar=rr[...,:half].copy();ai=ii[...,:half].copy();br=rr[...,half:].copy();bi=ii[...,half:].copy()
        wr=np.asarray(COS,dtype=np.int64)[tw];wi=np.asarray(SIN,dtype=np.int64)[tw]*(1 if inverse else -1)
        tr=(br*wr-bi*wi)>>30;ti=(br*wi+bi*wr)>>30
        rr[...,:half]=(ar+tr)>>1;ii[...,:half]=(ai+ti)>>1
        rr[...,half:]=(ar-tr)>>1;ii[...,half:]=(ai-ti)>>1
    assert np.max(np.abs(r))<2**31 and np.max(np.abs(i))<2**31
    return r,i
def candidates():
    payload=(ROOT/'student_release/student_release/input/scenario.if2').open('rb').read(M*4)
    b=np.frombuffer(payload,dtype=np.uint8)
    x=np.stack([(b>>s)&3 for s in (6,4,2,0)],axis=1).reshape(4,M,4).astype(np.int64)*2-3
    br=x[:,:,0]-x[:,:,2];bi=-x[:,:,1]+x[:,:,3]
    fcw=np.arange(-2624000,2624001,131200,dtype=np.int64)
    phase=(fcw[:,None]*4*np.arange(M)[None,:])&0xffffffff
    wr=np.asarray(COS,dtype=np.int64)[phase>>20][:,None,:];wi=np.asarray(SIN,dtype=np.int64)[phase>>20][:,None,:]
    xr=np.pad(((br[None,:,:]*wr+bi[None,:,:]*wi)*2048)>>30,((0,0),(0,0),(0,4)))
    xi=np.pad(((bi[None,:,:]*wr-br[None,:,:]*wi)*2048)>>30,((0,0),(0,0),(0,4)))
    sr,si=fft_int(xr,xi)
    out={}
    for prn in range(6,38):
        code=np.pad(np.repeat((1-2*np.asarray(generate_prn(prn),dtype=np.int64))*65536,2),(0,4))
        cr,ci=fft_int(code,np.zeros(N,dtype=np.int64))
        rr=sr*cr+si*ci;ri=si*cr-sr*ci
        assert np.max(np.abs(rr))<2**31 and np.max(np.abs(ri))<2**31
        ir,ii=fft_int(rr,ri,True);power=np.sum(ir*ir+ii*ii,axis=1)
        f,l=np.unravel_index(np.argmax(power),power.shape)
        lag=(4*(int(l) if l<2048 else int(l)-4096))%16368
        peak=int(power[f,l]);mean=int(np.sum(power[f]))>>12
        out[prn]=dict(lag_samples=lag,doppler_word=int(fcw[f]),peak=peak,mean=mean,detected=int(peak>8*mean))
    return out
