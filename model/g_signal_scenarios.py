"""Reuse local PRN/BCH generators for isolated IF/trajectory diagnostics.

No geometry/ephemeris/PVT simulator is implemented. Only modulation and
continuous equivalent line-of-sight trajectories are generated. Truth is a
separate offline manifest; RTL receives IF bits and test initialization only.
"""
import argparse,json,math,re
from pathlib import Path
import numpy as np
from b1i_prn_golden import generate_prn
from nh_d1_vectors import encode,interleave,PREAMBLE
from g_resource_audit import sha
ROOT=Path(__file__).resolve().parents[1]
FS=16368000;RC=2046000;RF=1561098000;C=299792458;NH='00000100110101001110'

def segments(kind):
    if kind=='D01':return [(1.5,2),(1.5,-2),(1.5,-2),(1.5,2)]*5
    if kind=='D02':return [(1,5),(2,0),(1,-5),(1,-5),(2,0),(1,5)]*4
    if kind=='D03':return [(1,j) for _ in range(6) for j in (5,-5,-5,5,0)]
    if kind=='D04':return [(2,-2),(2,2),(2,2),(2,-2)]*4
    return []

def trajectory(kind,t,dynamic_start=2.):
    t=np.asarray(t);u=np.maximum(t-dynamic_start,0.);distance=np.zeros_like(t);velocity=np.zeros_like(t);accel=np.zeros_like(t)
    d=v=a=start=0.
    if kind=='D04':v=49.5
    for dt,j in segments(kind):
        q=np.clip(u-start,0,dt);mask=(u>=start)&(u<start+dt)
        distance=np.where(mask,d+v*q+a*q*q/2+j*q**3/6,distance)
        velocity=np.where(mask,v+a*q+j*q*q/2,velocity);accel=np.where(mask,a+j*q,accel)
        d+=v*dt+a*dt*dt/2+j*dt**3/6;v+=a*dt+j*dt*dt/2;a+=j*dt;start+=dt
    mask=u>=start;distance=np.where(mask,d+v*(u-start),distance);velocity=np.where(mask,v,velocity);accel=np.where(mask,a,accel)
    if kind=='D04':
        # Hold initial v during the 2s settling section; offset the dynamic
        # integral so distance and carrier/code phase remain continuous.
        distance=np.where(t<dynamic_start,49.5*t,49.5*dynamic_start+distance)
        velocity=np.where(t<dynamic_start,49.5,velocity)
    return distance,velocity,accel

def d1_words(frames=8):
    words=[];infos=[]
    for frame in range(frames):
        sow=100000+6*frame;sfid=frame%5+1
        header=(PREAMBLE<<4)|1;tail=(sfid<<8)|(sow>>12)
        words.append((header<<15)|encode(tail));infos.append((header<<11)|tail)
        for w in range(2,11):
            p=((sow&4095)<<10)|0x255 if w==2 else (0x17531*w+frame*0x4321)&0x3fffff
            words.append(interleave(encode(p>>11),encode(p&2047)));infos.append(p)
    return words,infos

def pack(x):
    q=((np.asarray(x,dtype=np.int8)+3)//2).astype(np.uint8).reshape(-1,4)
    return ((q[:,0]<<6)|(q[:,1]<<4)|(q[:,2]<<2)|q[:,3]).tobytes()

def generate(kind,seconds,folder,seed,cn0,warm_cn0=None):
    folder.mkdir(parents=True,exist_ok=True);p=folder/'scenario.if2';rng=np.random.default_rng(seed)
    codes={prn:1-2*np.asarray(generate_prn(prn),dtype=np.int8) for prn in (6,7)}
    raw,info=d1_words(max(8,math.ceil(seconds/6)+1));bits=np.asarray([int(b) for w in raw for b in f'{w:030b}'])
    amplitude=2. if cn0 is None else math.sqrt(4*10**(cn0/10)/FS)
    offset=9990. if kind=='D04' else 0.
    nh=np.asarray([int(b) for b in NH]);total=int(seconds*FS)//16*16
    with p.open('wb') as f:
        for start in range(0,total,FS//10):
            n=np.arange(start,min(start+FS//10,total),dtype=np.int64);t=n/FS
            d,v,_=trajectory(kind,t);code=RC*t+RC/RF*offset*t-RC*d/C;carrier=.04+(4092000+offset)*t-RF*d/C
            epoch=np.floor(code/2046).astype(np.int64);data=bits[(epoch//20)%len(bits)]
            sign=codes[6][np.floor(code%2046).astype(int)]*(1-2*nh[epoch%20])*(1-2*data)
            amp=amplitude if warm_cn0 is None else np.where(t<2,math.sqrt(4*10**(warm_cn0/10)/FS),amplitude)
            analog=amp*sign*np.cos(2*np.pi*(carrier%1))
            if kind=='recovery':
                analog=np.where((t>=.6)&(t<2.6),0.,analog)
                epoch7=n//16368
                sign7=codes[7][(n//8)%2046]*(1-2*nh[epoch7%20])*(1-2*bits[(epoch7//20)%len(bits)])
                analog+=amplitude*sign7*np.cos(2*np.pi*((.13+n/4)%1))
            if cn0 is not None:analog+=rng.normal(size=len(n))
            x=np.select([analog<-1,analog<0,analog<1],[-3,-1,1],default=3);f.write(pack(x))
    report={'kind':kind,'origin':'self_generated_B1I_modulation_module_diagnostic','duration_s':total/FS,'samples':total,'generator_sha256':sha(Path(__file__)),
       'if_path':p.relative_to(ROOT).as_posix(),'if_sha256':sha(p),'fs_hz':FS,'if_hz':4092000,'prns':[6,7] if kind=='recovery' else [6],
       'cn0_db_hz':cn0,'warm_cn0_db_hz':warm_cn0,'amplitude':amplitude,'prequantization_signal_power':amplitude**2/2,'noise_variance':None if cn0 is None else 1,
       'noise_seed':seed if cn0 is not None else None,'rf_hz':RF,'dynamic_start_s':2,'base_doppler_hz':offset,'code_rate_includes_base_doppler':True,
       'trajectory_segments':segments(kind),'transmitted_raw_words':raw,'transmitted_information':info,
       'interruption_start_s':.6 if kind=='recovery' else None,'interruption_end_s':2.6 if kind=='recovery' else None,
       'limits':'Valid PRN/NH/BCH modulation; arbitrary payloads are not qualified broadcast ephemerides. No orbital/geometry/PDOP/ECEF truth, not a 12D1 formal P07/P08 or PVT scene.'}
    (folder/'truth.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('G_IF_DIAGNOSTIC_CREATED',kind,f'samples={total} bytes={p.stat().st_size} sha256={report["if_sha256"]}',flush=True)
    return report

def validate_trajectories(folder):
    result=[]
    for kind in ('D01','D02','D03','D04'):
        duration=sum(dt for dt,j in segments(kind));t=np.arange(0,duration+2+.001,.001)
        d,v,a=trajectory(kind,t)
        assert np.max(np.abs(v))<=50.00001 and np.max(np.abs(a))<=5.00001
        # Independent derivative consistency at interior samples, exclude jerk
        # switches for numerical finite differences, and check join states.
        error=np.max(np.abs(np.diff(d)/.001-(v[1:]+v[:-1])/2))
        assert error<.00001,(kind,error)
        if kind=='D03':assert abs(d[-1]-60)<1e-8 and abs(v[-1])<1e-8 and abs(a[-1])<1e-8
        hz=(9990 if kind=='D04' else 0)-RF*v/C;assert np.max(np.abs(hz))<=10000
        result.append({'id':kind,'duration_s':duration,'max_velocity_m_s':float(np.max(np.abs(v))),
            'max_acceleration_m_s2':float(np.max(np.abs(a))),'final_distance_m':float(d[-1]),'max_total_doppler_hz':float(np.max(np.abs(hz))),
            'distance_derivative_error_m_s':float(error),'classification':'trajectory_definition_self_test_not_receiver_P07'})
    folder.mkdir(parents=True,exist_ok=True);(folder/'trajectory_validation.json').write_text(json.dumps(result,indent=2)+'\n')
    print('G_CONTINUOUS_TRAJECTORY_SELF_TEST_PASS D01-D04 D03_distance=60m no_reset_of_phase=1')

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--kind',choices=['static','recovery','D01','D02','D03','D04','validate'],required=True)
    ap.add_argument('--seconds',type=float,default=4);ap.add_argument('--seed',type=int,default=4300);ap.add_argument('--cn0',type=float)
    ap.add_argument('--warm-cn0',type=float);ap.add_argument('--name')
    a=ap.parse_args()
    if a.kind=='validate':validate_trajectories(ROOT/'reports/g_stage/dynamics');return
    name=a.name or a.kind
    if not re.fullmatch(r'[a-zA-Z0-9_]+',name):raise ValueError('simple diagnostic directory name required')
    generate(a.kind,a.seconds,ROOT/f'work/g_stage/signals/{name}',a.seed,a.cn0,a.warm_cn0)
if __name__=='__main__':main()
