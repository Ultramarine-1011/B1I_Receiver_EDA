"""Compare direct-clock BIN to actual unmodified teacher player/writer run.
Clock startup may differ; only cycle counters are ignored, every other bit is exact.
"""
from pathlib import Path
import argparse,json,sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'student_release/student_release/tools'))
from decode_records import decode
def main():
    ap=argparse.ArgumentParser();ap.add_argument('reference',type=Path);ap.add_argument('actual',type=Path);args=ap.parse_args()
    def read(path):
        b=path.read_bytes();assert len(b)%32==0
        return [(decode(b[i:i+32]),int.from_bytes(b[i:i+32],'little')) for i in range(0,len(b),32)]
    ref=read(args.reference);new=read(args.actual)
    def key(r):return r['type_id'],r['prn'],r['channel'],r['sample_index']
    expected={key(r):v for r,v in ref if r['type']!='end'}
    actual_keys=[]
    for r,value in new:
        if r['type']=='end':continue
        k=key(r);assert k in expected,k
        mask=(1<<256)-1
        if r['type']=='acquisition':mask^=((1<<32)-1)<<224
        assert value&mask==expected[k]&mask,(r,decode(expected[k].to_bytes(32,'little')))
        actual_keys.append(k)
    assert len(actual_keys)==len(set(actual_keys))
    print(f'RECEIVER_TRANSPORT_EQUIVALENCE_PASS records={len(actual_keys)} exact_non_cycle_bits=1')
if __name__=='__main__':main()
