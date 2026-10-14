"""Two-star B1I modulation: valid NAV/OBS established before a 2s RF drop."""
import json,math
from pathlib import Path
import numpy as np
from g_signal_scenarios import FS,d1_words,pack,NH,ROOT
from b1i_prn_golden import generate_prn
from g_resource_audit import sha

def main():
    folder=ROOT/'work/g_stage/signals/recovery';folder.mkdir(parents=True,exist_ok=True);p=folder/'scenario.if2'
    seconds=40;begin=20;end=22;raw,info=d1_words(8)
    codes={prn:1-2*np.asarray(generate_prn(prn),dtype=np.int8) for prn in (6,7)}
    bits=np.asarray([int(b) for w in raw for b in f'{w:030b}']);nh=np.asarray([int(b) for b in NH]);total=seconds*FS
    with p.open('wb') as f:
        for start in range(0,total,FS//10):
            n=np.arange(start,min(start+FS//10,total),dtype=np.int64);epoch=n//16368
            sign=(1-2*nh[epoch%20])*(1-2*bits[(epoch//20)%len(bits)])
            x6=2*codes[6][(n//8)%2046]*sign*np.cos(2*np.pi*((.04+n/4)%1))
            x6=np.where((n>=begin*FS)&(n<end*FS),0.,x6)
            x7=2*codes[7][(n//8)%2046]*sign*np.cos(2*np.pi*((.13+n/4)%1))
            analog=x6+x7;x=np.select([analog<-1,analog<0,analog<1],[-3,-1,1],default=3);f.write(pack(x))
    truth={'kind':'recovery','origin':'self_generated_B1I_modulation_module_diagnostic','duration_s':seconds,'samples':total,
      'fs_hz':FS,'if_hz':4092000,'prns':[6,7],'if_path':p.relative_to(ROOT).as_posix(),'if_sha256':sha(p),
      'generator_sha256':sha(Path(__file__)),'amplitude_each_star':2,'cn0_db_hz':None,'noise_variance':0,'noise_seed':None,
      'interruption_start_s':begin,'interruption_end_s':end,'navigation_start_sow':100000,
      'transmitted_raw_words':raw,'transmitted_information':info,
      'independent_code_truth':'code phase n/8 modulo2046, per-star carrier doppler0; captured relative lag=(-capture_ref)%16368',
      'limits':'Noiseless two-star primary/NH/BCH modulation. Arbitrary navigation payloads are not qualified ephemerides; no geometry/PDOP/ECEF truth. Not an official nominal P08 scene.'}
    (folder/'truth.json').write_text(json.dumps(truth,indent=2)+'\n')
    print(f'G_RF_RECOVERY_STIMULUS_CREATED seconds={seconds} outage={begin}-{end}s bytes={p.stat().st_size} sha256={truth["if_sha256"]}')

if __name__=='__main__':main()
