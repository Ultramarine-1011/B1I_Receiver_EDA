"""Classify digital service measurements and attach actual public-input hashes."""
import json,hashlib
from pathlib import Path
from g_resource_audit import ROOT,sha

def main():
    source=ROOT/'student_release/student_release/input/scenario.if2';whole=sha(source)
    with source.open('rb') as f:prefix=hashlib.sha256(f.read(409200)).hexdigest()
    rows=[]
    for c in (1,4,12):
        folder=ROOT/f'reports/g_stage/service/c{c}';p=folder/'metrics.json';r=json.loads(p.read_text())
        log=(folder/'run.log').read_text(encoding='utf-8-sig')
        assert 'G_BANK_SERVICE_PASS' in log and 'EXIT_CODE: 0' in log and r['samples']==1636800
        r.update(status='PARTIAL',structural_validation='ALL_ACTIVE_SAMPLE_CONSUMPTION_AND_DRAIN_PASS',channels=c,
                 input={'origin':'teacher_public_development_IF_with_artificial_digital_channel_initialization',
                        'path':source.relative_to(ROOT).as_posix(),'whole_file_sha256':whole,'tested_prefix_bytes':409200,'prefix_sha256':prefix},
                 input_ready_duty=r['ready_cycles']/r['cycles'],records_per_signal_second=r['records']/.1,
                 output_ready_duty=1.0,output_service_scope='record_ready held high; no external stalled output qualification',
                 evaluation_source_sha256=sha(Path(__file__)),
                 formal_realtime_status='BLOCKED_INPUT: clock/SRAM/output service assumptions and sustained twelve-D1 load absent')
        p.write_text(json.dumps(r,indent=2)+'\n');rows.append(r)
    (ROOT/'reports/g_stage/service/summary.json').write_text(json.dumps(rows,indent=2)+'\n')
    print('G_ALL_ACTIVE_DIGITAL_SERVICE_AUDIT_PASS configurations=1/4/12; performance_class=PARTIAL no_official_realtime_claim')
if __name__=='__main__':main()
