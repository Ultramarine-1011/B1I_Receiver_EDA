"""Short independent B1I code/NH/real-IF vectors, not full GNSS/PVT scenes."""
import argparse,json,math,re
from pathlib import Path
import numpy as np
from b1i_prn_golden import generate_prn
from nh_d1_vectors import encode,PREAMBLE
from g_resource_audit import sha
ROOT=Path(__file__).resolve().parents[1]
FS=16368000;N=16368;NH=np.array([int(x) for x in '00000100110101001110'])

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--cn0',type=float,default=40);ap.add_argument('--name',default='acquisition');a=ap.parse_args()
    if not re.fullmatch(r'[a-zA-Z0-9_]+',a.name):raise ValueError('simple diagnostic directory name required')
    folder=ROOT/'work/g_stage'/a.name;folder.mkdir(parents=True,exist_ok=True)
    # Marginal boundaries/representative pairings, explicitly not the full
    # lag x frequency x NH Cartesian product (26,516,160 combinations).
    settings=[(0,-10000,0),(1,10000,19),(8191,-9750,7),(8192,9750,1),(16366,-250,19),(16367,250,7)]
    specs=[dict(id=f'present_{i}',target_present=True,source_prn=6,lag_samples=lag,doppler_hz=hz,nh_phase=nh,seed=4100+i) for i,(lag,hz,nh) in enumerate(settings)]
    specs += [dict(id=f'absent_{i}',target_present=False,source_prn=7,lag_samples=40+i,doppler_hz=0,nh_phase=i,seed=4200+i) for i in range(2)]
    n=np.arange(4*N);amplitude=math.sqrt(4*10**(a.cn0/10)/FS)
    for i,s in enumerate(specs):
        phase=(n-s['lag_samples'])%N
        code=1-2*np.asarray(generate_prn(s['source_prn']))[(phase//8).astype(int)]
        epoch=(n-s['lag_samples'])//N+s['nh_phase']
        # Use a legitimate BCH-coded D1 word's local data segment. This short
        # window contains <=5ms; no orbit or receiver position is supplied.
        raw=(((PREAMBLE<<4)|1)<<15)|encode((1<<8)|0)
        data_bit=(raw>>(29-(epoch//20)%30))&1
        sign=code*(1-2*NH[epoch%20])*(1-2*data_bit)
        analog=amplitude*sign*np.cos(2*np.pi*((.04+(4092000+s['doppler_hz'])*n/FS)%1))
        analog+=np.random.default_rng(s['seed']).normal(size=len(n))
        x=np.select([analog<-1,analog<0,analog<1],[-3,-1,1],default=3)
        mem=folder/f'case{i}.mem';mem.write_text(''.join(f'{int(v)&7:x}\n' for v in x),encoding='ascii')
        s.update(index=i,mem_sha256=sha(mem),samples=4*N,cn0_db_hz=a.cn0,signal_amplitude=amplitude,
            prequantization_signal_power=amplitude**2/2,noise_variance=1,noise_psd_w_per_hz=2/FS,
            fs_hz=FS,if_hz=4092000,observation_seconds=.004,candidates=[6,7],target_prn=6,
            independent_lag_tolerance_samples=1,independent_frequency_tolerance_hz=100,
            frequency_kind='carrier_only_offset',origin='self_generated_short_B1I_modulation_no_geometry_or_full_ephemeris')
    report={'status':'NOT_RUN','generator_sha256':sha(Path(__file__)),'cases':specs,'scope':'P01 boundary diagnostics/P03 short independent seeds; not formal 10s or 100+100 statistics',
       'search':{'prns':[6,7],'doppler_first_hz':-10000,'last_hz':10000,'step_hz':500,'refine_lag_radius':16,'refine_frequency_radius':5},
       'coverage':{'discrete_lag_samples':sorted({s['lag_samples'] for s in specs if s['target_present']}),'all_possible_lags':16368,
                   'nh_phases':sorted({s['nh_phase'] for s in specs if s['target_present']}),'all_nh_phases':20,
                   'frequency_test_values_hz':sorted({s['doppler_hz'] for s in specs if s['target_present']}),'full_phase_frequency_nh_combinations':16368*81*20},
       'cost_estimate':'8 cases x 2 PRNs x 41 coarse frequency cells, plus each detected candidate 33x11x65472 refinement samples; expect minutes, not full Cartesian coverage'}
    out=ROOT/'reports/g_stage'/a.name;out.mkdir(parents=True,exist_ok=True)
    (out/'scenarios.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(f'G_ACQUISITION_STIMULUS_CREATED cases=8 duration_each=0.004s cn0={a.cn0} independent_seeds=8 origin=self_generated')

if __name__=='__main__':main()
