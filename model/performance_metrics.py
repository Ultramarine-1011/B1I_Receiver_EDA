"""V1.7 evaluation primitives. Scores require recorded evidence, never DUT truth.

Input JSON is an offline evaluation trace. CLI computes metrics or runs hand
examples; it does not assert that a course scenario has been passed.
"""
from __future__ import annotations
import argparse,json,math,statistics
from pathlib import Path

FS=16368000
RULES={'acquisition_trials_present':100,'acquisition_trials_absent':100,
       'cold_starts':10,'acquisition_window_s':10,'cold_start_window_s':180,
       'followup_s':60,'dynamic_s':30,'interruption_s':2,
       'detection_rate':0.90,'false_alarm_rate':0.01,'overall_successes':9,
       'position_ratio':0.95,'code_rms_chip':0.1,'frequency_rms_hz':5,'word_accuracy':0.99}

def wilson(successes,total,z=1.959963984540054):
    if not 0<=successes<=total:raise ValueError('invalid Bernoulli counts')
    if not total:return {'n':0,'rate':None,'ci95':None}
    p=successes/total;den=1+z*z/total
    middle=(p+z*z/(2*total))/den
    radius=z*math.sqrt(p*(1-p)/total+z*z/(4*total*total))/den
    return {'n':total,'rate':p,'ci95':[max(0,middle-radius),min(1,middle+radius)]}

def time_domains(samples,cycles,wall_seconds,clock_hz=None,fs=FS):
    if min(samples,cycles,wall_seconds)<0 or fs<=0 or (clock_hz is not None and clock_hz<=0):raise ValueError('invalid time')
    return {'signal_seconds':samples/fs,'hardware_cycles':cycles,'assumed_clock_hz':clock_hz,
            'processing_seconds':None if clock_hz is None else cycles/clock_hz,
            'host_wall_seconds':wall_seconds,'minimum_average_clock_hz':None if not samples else cycles*fs/samples}

def acquisition_statistics(trials):
    present=[t for t in trials if t['target_present']];absent=[t for t in trials if not t['target_present']]
    # Timeouts remain in the denominators. Correct identity/lag/frequency needs
    # independent offline verification, not merely a detected bit.
    detection=wilson(sum(bool(t.get('verified_success')) for t in present),len(present))
    false_alarm=wilson(sum(bool(t.get('detected')) for t in absent),len(absent))
    costs=[]
    for t in trials:
        start,accept,end=(t.get(k) for k in ('queued_cycle','accepted_cycle','verified_cycle'))
        if start is not None and accept is not None and accept<start:raise ValueError('negative acquisition queue time')
        if accept is not None and end is not None and end<accept:raise ValueError('negative processing time')
        costs.append({'id':t['id'],'completed':bool(t.get('verified_success')),
                      'queue_cycles':None if start is None or accept is None else accept-start,
                      'processing_and_verification_cycles':None if end is None or accept is None else end-accept,
                      'censored_lower_bound_seconds':None if t.get('verified_success') else t.get('observation_seconds',10)})
    independent=all(t.get('seed') is not None for t in trials) and all(len({t['seed'] for t in group})==len(group) for group in (present,absent))
    complete_windows=all(t.get('observation_seconds',0)>=10 for t in trials)
    enough=len(present)==100 and len(absent)==100 and independent and complete_windows
    return {'status':'MEASURED' if enough else 'PARTIAL_SAMPLE_COUNT','detection':detection,'false_alarm':false_alarm,
            'working_point_observed':enough and detection['rate']>=0.9 and false_alarm['rate']<=0.01,
            'independent_seeds':independent,'complete_10s_windows':complete_windows,'trials':costs}

def cold_start_statistics(trials):
    independent=all(t.get('seed') is not None for t in trials) and len({t['seed'] for t in trials})==len(trials)
    completed=[t for t in trials if t['ttff']['status']=='COMPLETED']
    times=[t['ttff']['ttff_signal_seconds'] for t in completed]
    followups=[t.get('followup_valid_epochs',0)/60 for t in completed]
    enough=len(trials)==10 and independent
    return {'status':'MEASURED' if enough else 'PARTIAL_SAMPLE_COUNT','completion':wilson(len(completed),len(trials)),
            'completed_ttff_seconds':times,'ttff_median_seconds':statistics.median(times) if times else None,
            'ttff_p95_seconds':quantile95(times),'censored':[t['ttff'] for t in trials if t not in completed],
            'followup_valid_ratio':followups,'working_point_observed':enough and len(completed)>=9 and
                   all(t.get('followup_observed_epochs')==60 and r>=0.95 for t,r in zip(completed,followups))}

def tracking_quality(rows,reacquisitions=0,duration_s=60,fs=FS):
    if len({r['sample_ref'] for r in rows})!=len(rows):raise ValueError('duplicate tracking sample reference')
    if any(b['sample_ref']<=a['sample_ref'] for a,b in zip(rows,rows[1:])):raise ValueError('tracking time moved backwards')
    if any(r.get('code_error_chip') is None or r.get('frequency_error_hz') is None for r in rows):
        return {'status':'BLOCKED_INPUT','reason':'independent code/frequency truth missing'}
    expected=duration_s*1000;valid=[r for r in rows if r.get('valid')];bins={}
    for r in valid:bins.setdefault(r['sample_ref']//fs,[]).append(r['frequency_error_hz'])
    # Average frequency within each complete 1-second window, then RMS of means.
    averaged=[statistics.mean(a) for a in bins.values() if len(a)==1000]
    code=math.sqrt(sum(r['code_error_chip']**2 for r in valid)/len(valid)) if valid else None
    frequency=math.sqrt(sum(x*x for x in averaged)/len(averaged)) if averaged else None
    complete=len(rows)==expected and len(valid)==expected and len(averaged)==duration_s
    return {'status':'MEASURED' if complete else 'PARTIAL_WINDOW','code_rms_chip':code,'frequency_1s_mean_rms_hz':frequency,
            'complete_frequency_windows':len(averaged),'expected_prompts':expected,'valid_prompts':len(valid),
            'reacquisitions':reacquisitions,'holding_working_point_observed':complete and reacquisitions==0 and
                      all(r.get('locked') for r in rows) and code<=0.1 and frequency<=5}

def word_quality(words):
    if not words or any('expected_information' not in w for w in words):
        return {'status':'BLOCKED_INPUT','reason':'independent transmitted D1 word truth missing'}
    correct=sum(w.get('decoded_information')==w['expected_information'] for w in words)
    return {'status':'MEASURED','correct':wilson(correct,len(words)),
            'bch_passed':sum(bool(w.get('bch_valid')) for w in words),
            'demodulation_working_point_observed':correct/len(words)>=0.99}

def dynamic_quality(tracking,words,observation_counts,duration_s):
    if duration_s<30 or set(observation_counts)!=set(range(12)):
        return {'status':'PARTIAL_DYNAMIC_COVERAGE','reason':'requires all 12 channels and at least 30 seconds'}
    t=[tracking_quality(tracking[c],duration_s=duration_s) for c in range(12)]
    w=[word_quality(words[c]) for c in range(12)]
    ratios={c:observation_counts[c]/duration_s for c in range(12)}
    return {'status':'MEASURED' if all(a['status']=='MEASURED' for a in t+w) else 'PARTIAL_OR_BLOCKED',
            'tracking':t,'words':w,'valid_observation_ratios':ratios,
            'dynamic_quality_observed':all(a['holding_working_point_observed'] for a in t if a['status']=='MEASURED') and
                  all(a.get('demodulation_working_point_observed') for a in w) and len(t)==12 and
                  all(a['status']=='MEASURED' for a in t+w) and all(0.95<=r<=1 for r in ratios.values())}

def recovery_quality(trace,fs=FS):
    begin,end=trace['interruption_start_sample'],trace['interruption_end_sample']
    if end-begin!=2*fs:return {'status':'PARTIAL_SCENARIO','reason':'requires nominal 2-second interruption'}
    loss=trace.get('loss_sample');obs=trace.get('first_recovered_valid_observation_sample')
    if loss is None or obs is None:return {'status':'INCOMPLETE','detection_seconds':None if loss is None else (loss-begin)/fs,'recovery_seconds':None}
    if loss<begin or obs<end:raise ValueError('loss/recovery event contradicts scenario time')
    return {'status':'MEASURED','detection_seconds':(loss-begin)/fs,'recovery_seconds':(obs-end)/fs}

def causal_ttff(records,solutions,fs=FS,start_sample=0,window_s=180):
    """Only new OBS with NAV already available at that OBS handshake count.

    Position solver traces must identify their exact NAV/OBS sequence numbers.
    No full-file Route A output can be silently supplied as this trace.
    """
    by_seq={r['sequence']:r for r in records}
    if len(by_seq)!=len(records):raise ValueError('duplicate sequence')
    previous_avail=-1
    for r in records:
        if r['available_sample']<previous_avail:raise ValueError('availability moved backwards')
        previous_avail=r['available_sample']
    last_epoch=None;run=0;confirmed=None;rejected=[];valid=[]
    for s in solutions:
        obs=[by_seq[k] for k in s['used_obs']];nav=[by_seq[k] for k in s['used_nav']]
        epoch=s['epoch_sample'];out=s['available_sample']
        identities={(r['prn'],r['generation']) for r in obs if r.get('valid')}
        reason=None
        if not s.get('valid') or len(identities)<4:reason='invalid_solution_or_insufficient_observations'
        elif not obs or not nav or any(r['kind']!='obs' or r['epoch_sample']!=epoch or not r.get('valid') for r in obs):reason='wrong_epoch_or_record_kind'
        elif any(r['kind']!='nav' or not r.get('valid') or not r.get('ephemeris_ready') for r in nav):reason='invalid_or_incomplete_ephemeris'
        elif any(r['available_sample']>out for r in obs+nav) or out<epoch:reason='future_information'
        elif len(set(s['used_obs']))!=len(s['used_obs']) or len({r['prn'] for r in obs})!=len(obs):reason='duplicate_or_reused_observation'
        elif any(not any((n['prn'],n['generation'])==(o['prn'],o['generation']) and
                                        n['available_sample']<=o['available_sample'] for n in nav) for o in obs):reason='retrospective_ephemeris_backfill'
        if reason:
            rejected.append({'epoch_sample':epoch,'reason':reason});run=0;last_epoch=None;continue
        if last_epoch is not None and epoch<=last_epoch:raise ValueError('non-increasing position epochs')
        run=run+1 if last_epoch is not None and epoch-last_epoch==fs else 1
        last_epoch=epoch;valid.append(s)
        if run>=3 and confirmed is None:confirmed=s
    done=confirmed is not None and confirmed['available_sample']<=start_sample+window_s*fs
    return {'status':'COMPLETED' if done else 'CENSORED','ttff_signal_seconds':(confirmed['available_sample']-start_sample)/fs if done else None,
            'confirmation_epoch_sample':confirmed['epoch_sample'] if done else None,
            'lower_bound_seconds':None if done else window_s,'valid_epochs':len(valid),'rejected':rejected}

def quantile95(values):
    if not values:return None
    a=sorted(values);x=(len(a)-1)*0.95;lo=int(x);hi=math.ceil(x)
    return a[lo]+(a[hi]-a[lo])*(x-lo)

def position_statistics(epochs,truth_ecef,latitude_deg,longitude_deg,confirmation_epoch_sample,fs=FS,confirmation_available_sample=None):
    if truth_ecef is None:return {'status':'BLOCKED_INPUT','reason':'position truth unavailable'}
    # Defined complete 60 epochs after confirmation, no successful-only window.
    available=confirmation_epoch_sample if confirmation_available_sample is None else confirmation_available_sample
    start=(available//fs+1)*fs;stop=start+60*fs
    rows=[r for r in epochs if start<=r['epoch_sample']<stop]
    if len({r['epoch_sample'] for r in rows})!=len(rows):raise ValueError('duplicate position epoch')
    valid=[r for r in rows if r.get('valid')]
    a,b=map(math.radians,(latitude_deg,longitude_deg));enu=[]
    for r in valid:
        x,y,z=(v-t for v,t in zip(r['ecef_m'],truth_ecef))
        enu.append((-math.sin(b)*x+math.cos(b)*y,
                    -math.sin(a)*math.cos(b)*x-math.sin(a)*math.sin(b)*y+math.cos(a)*z,
                    math.cos(a)*math.cos(b)*x+math.cos(a)*math.sin(b)*y+math.sin(a)*z))
    metric={}
    for name,v in [('horizontal_m',[math.hypot(e,n) for e,n,u in enu]),('vertical_abs_m',[abs(u) for e,n,u in enu]),
                   ('three_dimensional_m',[math.sqrt(e*e+n*n+u*u) for e,n,u in enu])]:
        metric[name]={'rms':math.sqrt(sum(x*x for x in v)/len(v)) if v else None,'p95':quantile95(v)}
    expected=set(range(start,stop,fs));missing=sorted(expected-{r['epoch_sample'] for r in rows})
    return {'status':'MEASURED' if len(rows)==60 and not missing else 'PARTIAL_WINDOW','expected_epochs':60,'recorded_epochs':len(rows),
            'missing_epoch_samples':missing,
            'valid_epochs':len(valid),'valid_ratio':len(valid)/60,'errors':metric,
            'enu_bias_m':[statistics.mean(v[k] for v in enu) for k in range(3)] if enu else None}

def dynamic_d03():
    state={'t_s':0.0,'distance_m':0.0,'velocity_m_s':0.0,'acceleration_m_s2':0.0};result=[dict(state)]
    for _ in range(6):
        for j in (5,-5,-5,5,0):
            v,a=state['velocity_m_s'],state['acceleration_m_s2'];dt=1.0
            state={'t_s':state['t_s']+dt,'distance_m':state['distance_m']+v*dt+a*dt*dt/2+j*dt**3/6,
                   'velocity_m_s':v+a*dt+j*dt*dt/2,'acceleration_m_s2':a+j*dt}
            result.append(dict(state))
    return result

def self_test():
    assert time_domains(20,40,2,10,10)['processing_seconds']==4
    assert wilson(0,0)['rate'] is None and wilson(90,100)['ci95'][0]<0.9<wilson(90,100)['ci95'][1]
    trials=[{'id':f'p{i}','seed':i,'observation_seconds':10,'target_present':True,'verified_success':i<90} for i in range(100)]+[
            {'id':f'a{i}','seed':i,'observation_seconds':10,'target_present':False,'detected':i==0} for i in range(100)]
    assert acquisition_statistics(trials)['working_point_observed']
    records=[{'sequence':p,'kind':'nav','prn':6+p,'generation':1,'valid':True,'ephemeris_ready':True,'available_sample':1} for p in range(4)]
    solutions=[]
    for epoch in (10,20,30):
        obs=[]
        for p in range(4):
            seq=len(records);obs.append(seq);records.append({'sequence':seq,'kind':'obs','prn':6+p,'generation':1,
                'valid':True,'available_sample':epoch,'epoch_sample':epoch})
        solutions.append({'used_obs':obs,'used_nav':list(range(4)),'valid':True,'epoch_sample':epoch,'available_sample':epoch+2})
    assert causal_ttff(records,solutions,fs=10)['ttff_signal_seconds']==3.2
    broken=[dict(r) for r in records];broken[0]['available_sample']=15
    # Sort ledger in actual output order; solutions still bind by sequence.
    broken.sort(key=lambda r:r['available_sample'])
    assert causal_ttff(broken,solutions,fs=10)['status']=='CENSORED'
    positions=[{'epoch_sample':i,'valid':i!=60,'ecef_m':[4,3,0]} for i in range(1,61)]
    score=position_statistics(positions,[0,0,0],0,0,0,fs=1)
    assert score['errors']['horizontal_m']['rms']==3 and score['errors']['vertical_abs_m']['rms']==4
    assert score['errors']['three_dimensional_m']['rms']==5 and score['valid_ratio']==59/60 and score['enu_bias_m']==[3,0,4]
    assert position_statistics([],None,0,0,0)['status']=='BLOCKED_INPUT'
    d=dynamic_d03();assert len(d)==31 and abs(d[-1]['distance_m']-60)<1e-10
    assert d[-1]['velocity_m_s']==0 and d[-1]['acceleration_m_s2']==0
    assert not acquisition_statistics([dict(t,seed=0) for t in trials])['working_point_observed']
    rows=[{'sample_ref':i*16368,'valid':True,'locked':True,'code_error_chip':0.01,'frequency_error_hz':5 if i%2 else -5} for i in range(1000)]
    assert tracking_quality(rows,duration_s=1)['frequency_1s_mean_rms_hz']==0
    assert word_quality([{'expected_information':1,'decoded_information':1,'bch_valid':False}])['correct']['rate']==1
    assert recovery_quality({'interruption_start_sample':0,'interruption_end_sample':20,'loss_sample':1,
        'first_recovered_valid_observation_sample':30},fs=10)['recovery_seconds']==1
    assert cold_start_statistics([{'seed':i,'ttff':{'status':'COMPLETED','ttff_signal_seconds':i},'followup_valid_epochs':57,'followup_observed_epochs':60} for i in range(10)])['working_point_observed']
    print('PERFORMANCE_METRICS_SELF_TEST_PASS hand_examples=times/wilson/censoring/causal_TTFF/ENU/60s/D03; not_receiver_performance')

def main():
    p=argparse.ArgumentParser();p.add_argument('--self-test',action='store_true');p.add_argument('--input',type=Path);p.add_argument('--output',type=Path)
    args=p.parse_args()
    if args.self_test:self_test();return
    if not args.input or not args.output:p.error('--input and --output required')
    data=json.loads(args.input.read_text(encoding='utf-8-sig'));kind=data['metric']
    if kind=='acquisition':result=acquisition_statistics(data['trials'])
    elif kind=='cold_start':result=cold_start_statistics(data['trials'])
    elif kind=='tracking':result=tracking_quality(data['rows'],data.get('reacquisitions',0),data.get('duration_s',60),data.get('fs',FS))
    elif kind=='words':result=word_quality(data['words'])
    elif kind=='recovery':result=recovery_quality(data['trace'],data.get('fs',FS))
    elif kind=='ttff':result=causal_ttff(data['records'],data['solutions'],data.get('fs',FS),data.get('start_sample',0),data.get('window_s',180))
    elif kind=='position':result=position_statistics(data['epochs'],data.get('truth_ecef'),data['latitude_deg'],data['longitude_deg'],data['confirmation_epoch_sample'],data.get('fs',FS),data.get('confirmation_available_sample'))
    elif kind=='timing':result=time_domains(**data['timing'])
    else:raise ValueError(f'unknown metric {kind}')
    args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()
