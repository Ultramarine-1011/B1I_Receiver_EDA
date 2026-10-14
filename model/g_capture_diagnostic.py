"""Independent float power profile explains the strong-signal NH midpoint case.

Diagnostic only: known code/frequency truth stays outside RTL. This does not
replace actual acquisition results or change their declared success tolerances.
"""
import json,math
from pathlib import Path
import numpy as np
from b1i_prn_golden import generate_prn
from g_resource_audit import ROOT,sha
def main():
    folder=ROOT/'reports/g_stage/acquisition_cn50';spec=json.loads((folder/'scenarios.json').read_text())['cases'][2]
    p=ROOT/'work/g_stage/acquisition_cn50/case2.mem'
    raw=np.asarray([int(x,16) for x in p.read_text().splitlines()])
    x=np.where(raw>=4,raw-8,raw);n=np.arange(len(x));lag=spec['lag_samples'];fs=spec['fs_hz']
    code=(1-2*np.asarray(generate_prn(6)))[((n-lag)%16368)//8]
    profile=[]
    for hz in range(-10250,-9249,50):
        wiped=x*code*np.exp(-2j*np.pi*((4092000+hz)*n/fs%1))
        vector=wiped.reshape(4,16368).sum(axis=1);power=float(np.sum(np.abs(vector)**2))
        profile.append({'doppler_hz':hz,'four_window_noncoherent_power':power})
    peak=max(profile,key=lambda r:r['four_window_noncoherent_power'])
    result={'classification':'independent_float_diagnostic_not_receiver_PASS','source_mem_sha256':sha(p),'truth_doppler_hz':spec['doppler_hz'],
       'truth_lag_samples':lag,'truth_nh_phase':spec['nh_phase'],'float_objective_peak':peak,'profile':profile,
       'interpretation':'If the float objective also peaks away from true frequency, the observed bias comes from the fixed 1ms integration/NH boundary objective rather than a demonstrated RTL arithmetic mismatch. Keep the actual independent truth failure.'}
    (folder/'nh_frequency_objective_diagnostic.json').write_text(json.dumps(result,indent=2)+'\n')
    print('G_NH_FREQUENCY_OBJECTIVE_DIAGNOSTIC',json.dumps(peak),'true_hz',spec['doppler_hz'])
if __name__=='__main__':main()
