"""Export measured positive-case RTL Prompt only; no truth or forged records."""
from pathlib import Path
import csv,hashlib,json
ROOT=Path(__file__).resolve().parents[1]
def main():
    source=ROOT/'reports/local/tracking_loop.csv'
    rows=[r for r in csv.DictReader(source.open()) if r['case']=='0' and r['locked'] is not None]
    assert len(rows)==999
    dest=ROOT/'tb/vectors/nh_d1/actual_tracking_prompt.vec'
    dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_text(str(len(rows))+'\n'+''.join(r['ip']+' '+r['window_ref']+'\n' for r in rows),encoding='ascii')
    dest.with_suffix('.json').write_text(json.dumps(dict(source='reports/local/tracking_loop.csv',source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),columns=['ip','window_ref'],count=len(rows),kind='actual_RTL_on_synthetic_IF_not_teacher_scenario'),indent=2),encoding='utf-8')
    print('TRACKING_PROMPT_EXPORT_PASS windows=999 fields=ip,window_ref truth_fields=none')
if __name__=='__main__':main()
