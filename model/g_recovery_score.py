"""Independent RF outage/D1 word scoring of the self-generated G receiver run."""
import json,sys,math
from pathlib import Path
from collections import defaultdict
from performance_metrics import word_quality,recovery_quality,FS
from g_resource_audit import sha
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'student_release/student_release/tools'))
from decode_records import decode

def main():
    folder=ROOT/'reports/g_stage/recovery';truth=json.loads((folder/'truth.json').read_text())
    assert truth['kind']=='recovery' and truth['interruption_end_s']-truth['interruption_start_s']==2
    raw=(folder/'receiver_records.bin').read_bytes();side=[json.loads(l) for l in (folder/'receiver_records.bin.availability.jsonl').read_text().splitlines()]
    groups=defaultdict(list);words=[]
    for i in range(0,len(raw),32):
        r=decode(raw[i:i+32]);r.update(side[i//32]);groups[r['prn']].append(r)
        if r['type']=='navigation':
            # The source emits a known repeated sequence of complete frames.
            # Match its broadcast SOW and word number, never BCH flag alone.
            frame=(r['sow']-truth.get('navigation_start_sow',100000))//6;index=frame*10+r['word_number']-1
            expected=truth['transmitted_information'][index] if 0<=index<len(truth['transmitted_information']) else None
            words.append({'prn':r['prn'],'sequence':r['sequence'],'decoded_information':r['information'],
               'expected_information':expected,'bch_valid':r['bch_valid']})
    begin=int(truth['interruption_start_s']*FS);end=int(truth['interruption_end_s']*FS)
    affected=groups[6];healthy=groups[7]
    lost=[r for r in affected if r['type']=='lost' and r['sample_index']>=begin]
    reacq=[r for r in affected if r['type']=='acquisition' and r['detected'] and r['available_sample']>=end]
    # A missing-signal candidate may briefly assert lock after RF returns, then
    # time out. Recovery milestones must belong to the actual later assignment,
    # rather than simply taking any flagged record after the RF end time.
    assigned_tracking=[r for r in affected if reacq and r['type']=='tracking' and r['sequence']>reacq[0]['sequence']]
    recovered_generation=assigned_tracking[0]['generation'] if assigned_tracking else None
    recovered=[r for r in affected if reacq and r['sequence']>reacq[0]['sequence'] and r.get('generation')==recovered_generation]
    locked=[r for r in recovered if r['type']=='tracking' and r['locked']]
    obs=[r for r in recovered if r['type']=='common_observation' and r['measurement_valid']]
    nav=[r for r in recovered if r['type']=='navigation']
    loss_sample=lost[0]['sample_index'] if lost else None
    bad_obs=[r for r in affected if r['type']=='common_observation' and r['measurement_valid'] and loss_sample is not None and loss_sample<=r['sample_index']<end]
    pre_obs=[r for r in affected if r['type']=='common_observation' and r['measurement_valid'] and r['sample_index']<begin]
    healthy_outage=[r for r in healthy if r['type']=='tracking' and begin<=r['sample_index']<end]
    # Emitted-only consistency must not be called the P06 transmitted-word
    # accuracy. Count every expected word in a complete, synchronized source
    # window for the continuously healthy channel, including missing outputs.
    healthy_nav=[r for r in healthy if r['type']=='navigation']
    stable_start=math.ceil(healthy_nav[0]['available_sample']/(6*FS))*6 if healthy_nav else None
    stable_end=math.floor(truth['duration_s']/6)*6
    expected_words=[];observed_by_index={}
    for r in healthy_nav:
        frame=(r['sow']-truth.get('navigation_start_sow',100000))//6
        index=frame*10+r['word_number']-1
        if index in observed_by_index:raise AssertionError('duplicate transmitted word in healthy generation')
        observed_by_index[index]=r
    if stable_start is not None:
        for frame in range(stable_start//6,stable_end//6):
            for w in range(10):
                index=frame*10+w;r=observed_by_index.get(index)
                expected_words.append({'expected_information':truth['transmitted_information'][index],
                    'decoded_information':r['information'] if r else None,'bch_valid':r['bch_valid'] if r else False})
    false_candidates=[r for r in affected if r['type']=='acquisition' and r['detected'] and begin<=r['sample_index'] and r['sample_index']+4*16368<=end]
    trace={'interruption_start_sample':begin,'interruption_end_sample':end,'loss_sample':lost[0]['sample_index'] if lost else None,
       'first_recovered_valid_observation_sample':obs[0]['available_sample'] if obs else None}
    health_ratio=sum(r['locked'] for r in healthy_outage)/len(healthy_outage) if healthy_outage else None
    diagnosis_pass=bool(pre_obs and lost and reacq and locked and obs and not bad_obs and health_ratio is not None and health_ratio>=.95)
    result={'status':'SELF_GENERATED_PASS' if diagnosis_pass else 'FAIL','scope':'real 2s target RF removal while healthy PRN7 continues; reduced search/noiseless B1I modulation, no geometry/qualified ephemeris',
       'if_sha256':truth['if_sha256'],'truth_sha256':sha(folder/'truth.json'),'bin_sha256':sha(folder/'receiver_records.bin'),
       'pre_interruption_valid_obs':len(pre_obs),'healthy_tracking_rows_during_outage':len(healthy_outage),'healthy_lock_ratio':health_ratio,
       'invalidly_valid_obs_after_actual_loss':len(bad_obs),
       'recovered_generation':recovered_generation,
       'milestone_selection':'same generation as first tracking after the post-RF reacquisition output; excludes the RF-absent candidate generation',
       'lost_events':lost,'reacquisition_events':reacq,'first_recovered_locked':locked[0] if locked else None,
       'first_recovered_nav':nav[0] if nav else None,'first_recovered_valid_obs':obs[0] if obs else None,
       'timing':recovery_quality(trace),'emitted_word_truth_consistency':word_quality(words),
       'emitted_word_scope':'Only emitted records; not the transmitted-word denominator and not a sensitivity working point',
       'healthy_demodulation_window':{'source_start_s':stable_start,'source_end_s':stable_end,
            'selection':'next complete 6s source frame after first actual NAV availability, to last complete source frame before EOF',
            'expected_words':len(expected_words),'missing_words':sum(w['decoded_information'] is None for w in expected_words),
            'quality':word_quality(expected_words),'scope':'short noiseless healthy-channel diagnostic, not a per-CN0 formal demodulation sweep'},
       'false_detected_candidates_during_RF_absence':false_candidates,
       'evaluation_source_sha256':sha(Path(__file__)),
       'formal_P08':'BLOCKED_INPUT; self-generated waveform lacks qualified nominal scenario metadata/geometry and formal receiver input coverage'}
    (folder/'recovery_metrics.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('G_RF_RECOVERY_SCORE_COMPLETE',result['status'],f'healthy_lock_ratio={health_ratio} recovered_OBS={len(obs)} words={len(words)}')
if __name__=='__main__':main()
