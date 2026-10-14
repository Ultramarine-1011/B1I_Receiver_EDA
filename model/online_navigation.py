"""Causal replay of actual RTL NAV/OBS handshakes. Never recovers NAV from Prompt.

The unmodified teacher's D1 fields, orbit and PVT solver are reused. Each OBS
captures only ephemerides/anchors already available at its own handshake.
Positions are evaluated on receipt of four eligible observations, with no
later backfill. Solver wall service is measured separately, not converted to
ASIC cycles or added to accepted-sample time.
"""
from __future__ import annotations
import argparse,json,math,sys,time
from pathlib import Path
from collections import defaultdict
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'student_release/student_release/tools'))
import route_a_position as route
from decode_records import decode
from prompt_d1 import decode_word
from performance_metrics import causal_ttff
from g_resource_audit import sha

class OnlineNavigation:
    def __init__(self):
        self.partial={};self.frames=defaultdict(dict);self.eph={};self.anchors=defaultdict(list)
        self.ledger=[];self.positions=[];self.epochs=defaultdict(dict);self.solved=set()
        self.first=defaultdict(dict);self.failures=[];self.retired=set();self.last_sequence=-1
        self.last_sample=-1;self.last_cycle=-1;self.last_obs_epoch=-1;self.service_s=0.0

    def milestone(self,key,name,event):
        if name not in self.first[key]:self.first[key][name]=dict(event)

    def invalidate(self,key):
        self.eph.pop(key,None)
        for bucket in self.epochs.values():
            if key[0] in bucket and bucket[key[0]][0]==key:bucket.pop(key[0])

    def consume(self,r,event):
        seq=event['sequence'];avail=event['available_sample'];cycle=event['hardware_cycle']
        if seq!=self.last_sequence+1 or avail<self.last_sample or cycle<=self.last_cycle:
            raise ValueError('sequence/availability/cycle order violated')
        # Tracking/NAV references name a projected local code boundary, which
        # can project ahead of accepted_sample. They are not permission
        # to read future input; causality is determined by the handshake.
        if r['type']=='common_observation' and avail<r['sample_index']:
            raise ValueError('OBS source epoch is in the future')
        self.last_sequence=seq;self.last_sample=avail;self.last_cycle=cycle
        key=(r['prn'],r.get('generation',0));kind=r['type']
        base=dict(event,prn=key[0],generation=key[1],channel=r['channel'],source_sample=r['sample_index'])
        if kind=='acquisition' and r.get('detected'):self.milestone((r['prn'],1),'acquisition',base)
        if kind=='tracking':
            for flag in ('locked','nh_valid','frame_valid','time_valid'):
                if r.get(flag):self.milestone(key,flag,base)
        if kind=='lost':
            self.retired.add(key);self.partial.pop(key,None);self.frames.pop(key,None)
            self.invalidate(key);self.anchors.pop(key,None)
            return
        if kind=='navigation':self.navigation(r,base,key)
        elif kind=='common_observation':self.observation(r,base,key)

    def navigation(self,r,base,key):
        if key in self.retired:return
        if not all(r.get(k) for k in ('locked','nh_valid','frame_valid','time_valid','bch_valid')):
            self.partial.pop(key,None);return
        number=r['word_number']
        try:
            bits,_=decode_word([(r['raw_word']>>i)&1 for i in range(29,-1,-1)],number==1)
            info=0
            for b in bits:info=(info<<1)|b
            if info!=r['information']:raise ValueError('raw/information mismatch')
        except ValueError as err:
            self.failures.append({'sequence':base['sequence'],'reason':str(err)});self.partial.pop(key,None);return
        nav=dict(r,**{k:v for k,v in base.items() if k not in r})
        self.anchors[key].append(nav)
        self.milestone(key,'first_nav_word',base)
        state=self.partial.get(key)
        if number==1:state=[];self.partial[key]=state
        if state is None or number!=len(state)+1 or (state and any(r[k]!=state[0][k] for k in ('sow','subframe_id'))):
            self.partial.pop(key,None);return
        state.append(nav)
        if number!=10:return
        self.partial.pop(key,None)
        try:frame=route.decode_subframe([w['information'] for w in state])
        except ValueError as err:self.failures.append({'sequence':base['sequence'],'reason':str(err)});return
        if (frame['subframe_id'],frame['sow'])!=(r['subframe_id'],r['sow']):
            self.failures.append({'sequence':base['sequence'],'reason':'decoded frame metadata mismatch'});return
        sf=frame['subframe_id']
        if sf not in (1,2,3):return
        if sf==1 and frame['health']!=0:
            self.invalidate(key)
        # Complete SF1/SF2/SF3 from the same 30s D1 frame; do not combine old
        # SF3 with a new SF1/SF2, even when issue numbers happen to match.
        frame_start=(frame['sow']-6*(sf-1))%604800
        frame.update(generation=key[1],last_sample_index=r['sample_index'],used_nav=[w['sequence'] for w in state],frame_start=frame_start)
        self.frames[key][sf]=frame
        frames=self.frames[key]
        if set(frames)!={1,2,3} or len({f['frame_start'] for f in frames.values()})!=1:return
        eph=route.build_ephemerides({key[0]:list(frames.values())}).get(key[0])
        if eph is None:return
        sequences=sorted(s for f in frames.values() for s in f['used_nav'])
        ready=dict(base,kind='nav',valid=True,ephemeris_ready=True,used_raw_nav=sequences,frame_start=frame_start)
        self.eph[key]=(eph,ready)
        self.ledger.append(ready);self.milestone(key,'ephemeris_ready',ready)

    def observation(self,r,base,key):
        epoch=r['sample_index'];epoch_id=r['common_epoch_id']
        if epoch<self.last_obs_epoch:raise ValueError('OBS epoch moved backwards')
        if epoch>self.last_obs_epoch:
            self.epochs.clear();self.last_obs_epoch=epoch
        flags=all(r.get(k) for k in ('active','locked','nh_valid','frame_valid','time_valid','bch_valid','measurement_valid'))
        entry=dict(base,kind='obs',epoch_sample=epoch,epoch_id=epoch_id,valid=flags)
        self.ledger.append(entry)
        if flags:self.milestone(key,'first_valid_obs',base)
        if not flags or key in self.retired or key not in self.eph:return
        eph,ready=self.eph[key]
        if ready['available_sample']>base['available_sample']:raise AssertionError('future ephemeris')
        try:tx,anchor,_=route.transmit_sow(r,self.anchors[key],None)
        except ValueError:return
        bucket=self.epochs[(epoch,epoch_id)]
        if key[0] in bucket:raise ValueError('duplicate PRN in epoch')
        bucket[key[0]]=(key,eph,ready,entry,tx,anchor)
        if len(bucket)<4 or (epoch,epoch_id) in self.solved:return
        self.solved.add((epoch,epoch_id))
        values=list(bucket.values());measurements=[(key[0],tx,eph) for key,eph,ready,entry,tx,anchor in values]
        before=time.perf_counter();reason=None
        try:
            xyz,bias,residual,sow,details=route.solve_position(measurements)
            states=np.asarray([route.broadcast_state(e,tx)[0] for _,tx,e in measurements])
            rho=np.asarray([item['corrected_pseudorange_m'] for item in details])
            rotated=np.asarray([route.rotate_earth(sat,min(.15,max(.05,(r-bias)/route.C))) for sat,r in zip(states,rho)])
            vectors=xyz-rotated;distances=np.linalg.norm(vectors,axis=1);unit=vectors/distances[:,None]
            matrix=np.column_stack((unit,np.ones(len(unit))))
            covariance=np.linalg.inv(matrix.T@matrix);pdop=float(np.sqrt(np.trace(covariance[:3,:3])))
            final_update,*_=np.linalg.lstsq(matrix,rho-distances-bias,rcond=None)
            # Numerical solver convergence, not a position-accuracy gate.
            valid=bool(np.isfinite(xyz).all() and math.isfinite(bias) and math.isfinite(pdop) and
                5e6<float(np.linalg.norm(xyz))<8e6 and np.linalg.norm(final_update[:3])<.001 and abs(final_update[3])<.001)
            if not valid:reason='nonfinite_or_nonphysical_solution'
        except (ValueError,np.linalg.LinAlgError,OverflowError) as err:
            xyz=np.full(3,np.nan);bias=pdop=None;residual=[];sow=None;details=[];final_update=np.full(4,np.nan);valid=False;reason=str(err)
        elapsed=time.perf_counter()-before;self.service_s+=elapsed
        used_nav=sorted({ready['sequence'] for _,_,ready,_,_,_ in values})
        used_raw=sorted({s for _,_,ready,_,_,_ in values for s in ready['used_raw_nav']}|{anchor['sequence'] for _,_,_,_,_,anchor in values})
        solution={'valid':valid,'reason':reason,'epoch_sample':epoch,'common_epoch_id':epoch_id,
          'available_sample':base['available_sample'],'hardware_cycle':base['hardware_cycle'],'output_sequence':base['sequence'],
          'used_obs':[entry['sequence'] for _,_,_,entry,_,_ in values],'used_nav':used_nav,'used_raw_nav':used_raw,
          'ecef_m':xyz.tolist() if valid else None,'receiver_clock_bias_m':bias,'pdop':pdop,'reference_sow':sow,
          'final_solver_update_norm_m':float(np.linalg.norm(final_update[:3])) if np.isfinite(final_update).all() else None,
          'residual_rms_m':math.sqrt(sum(float(v)**2 for v in residual)/len(residual)) if len(residual) else None,
          'host_solver_service_seconds':elapsed,'observations':details}
        self.positions.append(solution)
        if valid:
            for key,*_ in values:self.milestone(key,'first_position',base)

def replay(bin_path,sidecar,output):
    output.mkdir(parents=True,exist_ok=True);online=OnlineNavigation();count=0;end=None
    with bin_path.open('rb') as f,sidecar.open(encoding='utf-8-sig') as s:
        while raw:=f.read(32):
            if len(raw)!=32:raise ValueError('partial BIN record')
            line=s.readline()
            if not line:raise ValueError('missing sidecar entry')
            r=decode(raw)
            if r['type']=='lost':r['generation']=(int.from_bytes(raw,'little')>>24)&255
            if end is not None:raise ValueError('record after end')
            event=json.loads(line);online.consume(r,event);count+=1
            if r['type']=='end':end=r
        if s.readline():raise ValueError('extra sidecar entries')
    if end is None or end['underrun'] or end['overflow']:raise ValueError('missing/invalid end')
    if online.last_sample!=end['sample_index']:raise ValueError('end/availability sample mismatch')
    window=end['sample_index']/route.FS
    score=causal_ttff(sorted(online.ledger,key=lambda e:e['sequence']),online.positions,window_s=window)
    summary={'status':'PARTIAL','scope':'causal replay of actual RTL NAV/OBS, no Prompt reconstruction',
       'record_count':count,'bin_sha256':sha(bin_path),'sidecar_sha256':sha(sidecar),'observed_seconds':window,
       'positions':len(online.positions),'valid_positions':sum(p['valid'] for p in online.positions),'ttff':score,
       'milestones':{f'{k[0]}:{k[1]}':v for k,v in online.first.items()},'navigation_failures':online.failures,
       'solver_service_seconds':online.service_s,
       'evaluation_sources':{name:sha(ROOT/name) for name in ('model/online_navigation.py','model/performance_metrics.py',
           'student_release/student_release/tools/decode_records.py','student_release/student_release/tools/route_a_position.py','student_release/student_release/tools/prompt_d1.py')},
       'time_boundary':'available_sample is the final required RTL handshake. Replay CPU service is separately measured; no scheduled real-time PVT engine or clock target is established.',
       'formal_P04_P05':'BLOCKED_INPUT: one public development scene, <180s, 4 tracked satellites, PDOP qualification and independent trials absent'}
    (output/'key_positions.json').write_text(json.dumps(online.positions[:3],indent=2,allow_nan=False)+'\n',encoding='utf-8')
    for name,rows in (('positions.jsonl',online.positions),('evaluation_ledger.jsonl',sorted(online.ledger,key=lambda e:e['sequence']))):
        (output/name).write_text(''.join(json.dumps(row,allow_nan=False)+'\n' for row in rows),encoding='utf-8')
    (output/'summary.json').write_text(json.dumps(summary,indent=2,allow_nan=False)+'\n',encoding='utf-8')
    print('CAUSAL_RTL_REPLAY_COMPLETE',f'records={count} positions={summary["positions"]} valid={summary["valid_positions"]} TTFF={score["status"]}')
    return summary

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--bin',type=Path,required=True);ap.add_argument('--sidecar',type=Path,required=True);ap.add_argument('--output',type=Path,required=True)
    a=ap.parse_args();replay(a.bin,a.sidecar,a.output)

if __name__=='__main__':main()
