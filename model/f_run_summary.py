"""Join actual run logs, BIN fields and handshake availability, no receiver truth."""
import hashlib,json,re,sys
from pathlib import Path
from performance_metrics import time_domains
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'student_release/student_release/tools'))
from decode_records import decode

def main():
    root=ROOT/'reports/f_stage';summary={}
    for name in ('real2','real20','driver_tail64'):
        folder=root/name;log=(folder/'run.log').read_text(encoding='utf-8-sig')
        match=re.search(r'FAST_RTL_PASS samples=(\d+) records=(\d+) cycles=(\d+) wall_seconds=([\d.]+)',log)
        if not match or 'EXIT_CODE: 0' not in log:raise AssertionError(('missing actual run PASS',name))
        samples,records,cycles=map(int,match.groups()[:3]);wall=float(match[4]);p=folder/'receiver_records.bin'
        ledger=Path(str(p)+'.availability.jsonl');first_nav=[];last_avail=-1;last_cycle=-1;end=None
        with p.open('rb') as f,ledger.open(encoding='utf-8') as a:
            count=0
            while raw:=f.read(32):
                r=decode(raw);event=json.loads(a.readline())
                if event['sequence']!=count or event['available_sample']<last_avail or event['hardware_cycle']<=last_cycle:
                    raise AssertionError('availability sequence/time is inconsistent')
                if event['available_sample']>samples:raise AssertionError('availability after final sample')
                if r['type']=='navigation' and r['prn'] not in [n['prn'] for n in first_nav]:
                    first_nav.append({'prn':r['prn'],'generation':r['generation'],'word_source_seconds':r['sample_index']/16368000,
                                      'first_nav_output_available_seconds':event['available_sample']/16368000,'hardware_cycle':event['hardware_cycle']})
                if r['type']=='end':
                    if end is not None or r['sample_index']!=samples or r['underrun'] or r['overflow']:raise AssertionError('end invalid')
                    end=r
                last_avail=event['available_sample'];last_cycle=event['hardware_cycle'];count+=1
            if count!=records or a.readline():raise AssertionError('BIN/availability counts differ')
        summary[name]={'status':'RUN_AND_AVAILABILITY_AUDIT_PASS','bin_bytes':p.stat().st_size,'bin_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),
            'records':records,'time_domains':time_domains(samples,cycles,wall,clock_hz=100000000),
            'first_nav':first_nav,'timing_limit':'100MHz is an explicit arithmetic assumption, not the course target clock. No online TTFF claimed.'}
    (root/'run_summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8');print('F_RUN_AVAILABILITY_AUDIT_PASS real2/real20/tail64; TTFF=NOT_RUN')

if __name__=='__main__':main()
