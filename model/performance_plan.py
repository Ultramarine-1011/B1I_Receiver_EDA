"""Produce an honest scenario inventory and runnable commands, not fake results."""
import argparse,hashlib,json
from pathlib import Path
from performance_metrics import RULES,dynamic_d03

ROOT=Path(__file__).resolve().parents[1]

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--output',type=Path,default=ROOT/'reports/f_stage/performance');args=ap.parse_args()
    args.output.mkdir(parents=True,exist_ok=True)
    public=ROOT/'student_release/student_release/input/scenario.if2'
    official={'id':'teacher_public_static_100s','origin':'official','path':str(public.relative_to(ROOT)),
       'bytes':public.stat().st_size if public.exists() else None,'sha256':None,'fs':16368000,'if_hz':4092000,
       'duration_s':100,'visible_d1_satellites':6,'cn0_db_hz':40,'pdop':None,'noise_seed':None,
       'position_truth':None,'dynamic':False,'interruption':False,'metadata_source':'teacher README/input_contract.json'}
    if public.exists():
        h=hashlib.sha256()
        with public.open('rb') as f:
            for block in iter(lambda:f.read(4*1024*1024),b''):h.update(block)
        official['sha256']=h.hexdigest()
    missing={
      'P01':'40dB-Hz full phase/frequency midpoint/NH coverage scenarios and independent truth',
      'P02':'individual queued/accepted/verified task cycle traces',
      'P03':'100 present plus 100 absent independent seeds per CN0 and offline truth',
      'P04':'10 independent >=180s >=6D1 PDOP<=4 cold-start scenarios plus causal online solver',
      'P05':'per-CN0 cold-start scenes, complete 60s followup and causal solver',
      'P06':'60s independent code/frequency and transmitted D1 word truth at each CN0',
      'P07':'12D1/40dB-Hz legal D01-D04 scenes and code/frequency/word truth',
      'P08':'legal nominal 2s signal interruption and restored valid observation scene',
      'P09':'fixed ECEF truth and uniform geometry/seed/model, full 60s after causal confirmation'}
    plan={'source':'V1.7 chapter7 pp65-68','rules':RULES,'available':[official],
          'formal_tasks':[{'id':k,'status':'BLOCKED_INPUT' if k!='P02' else 'NOT_RUN','needed':v} for k,v in missing.items()],
          'low_cost':[{'id':'channel_control','origin':'self_generated','command':'.\\scripts\\run_f_stage.ps1 -Task all','formal_performance':False},
                      {'id':'public_short','origin':'official','command':'.\\scripts\\run_fast_verilator.ps1 -Channels 4 -DurationSeconds 2 -EvidenceDirectory reports/f_stage/real2','formal_performance':False}],
          'p01_dimensions':{'lag_samples':{'first':0,'last':16367,'count':16368},'doppler_hz':list(range(-10000,10001,500))+list(range(-9750,10000,500)),
                             'nh_phases':list(range(20))},'d03_boundary_reference':dynamic_d03()}
    (args.output/'scenario_plan.json').write_text(json.dumps(plan,indent=2)+'\n',encoding='utf-8')
    table=['# 性能报告模板（未执行值保持空）','','正式要求见docs/PERFORMANCE_EVALUATION.md；手算/控制层PASS不填正式receiver PASS。','',
           '| 项 | 状态 | 场景/哈希/配置/种子/真值 | 试验次数/失败 | 信号秒/周期/clk处理秒/墙钟 | 指标/CI/原因 |','|---|---|---|---|---|---|']
    table += [f'| {k} | '+('NOT_RUN' if k=='P02' else 'BLOCKED_INPUT')+f' | 未具备完整条件 | — | — | {v} |' for k,v in missing.items()]
    (args.output/'PERFORMANCE_REPORT_TEMPLATE.md').write_text('\n'.join(table)+'\n',encoding='utf-8')
    print('PERFORMANCE_PLAN_CREATED official_input_sha256='+str(official['sha256'])+' formal_receiver_tests=NOT_RUN/BLOCKED_INPUT')

if __name__=='__main__':main()
