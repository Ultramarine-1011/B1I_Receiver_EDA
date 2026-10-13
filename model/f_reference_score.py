"""Current public-IF prefix vs frozen E BIN, without claiming a new 100s run."""
import argparse,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'student_release/student_release/tools'))
from decode_records import decode

def read(path):
    with path.open('rb') as f:
        while block:=f.read(32):
            if len(block)!=32:raise ValueError('truncated record')
            yield decode(block),int.from_bytes(block,'little')

def main():
    ap=argparse.ArgumentParser();ap.add_argument('directory',type=Path);args=ap.parse_args()
    ref=ROOT/'reports/e_stage/final/receiver_records.bin';actual=args.directory/'receiver_records.bin'
    current=list(read(actual));end=current[-1][0];limit=end['sample_index'];keys={}
    baseline_lock_drop={};ever={};previous={};reference_order=[]
    def key(r):return r['type_id'],r['prn'],r['channel'],r['sample_index']
    for r,value in read(ref):
        if r['type']!='end':reference_order.append(key(r))
        if r['type']=='tracking':
            p=r['prn'];ever[p]=ever.get(p,False) or r['locked']
            if previous.get(p,False) and not r['locked']:baseline_lock_drop[p]=baseline_lock_drop.get(p,0)+1
            previous[p]=r['locked']
        if r['type']!='end' and r['sample_index']<=limit+16368:keys[key(r)]=value
    observed=set();counts={}
    for r,value in current:
        if r['type']=='end':continue
        k=key(r)
        if k in observed:raise AssertionError(('duplicate current key',k))
        observed.add(k);mask=(1<<256)-1
        if r['type']=='acquisition':mask^=((1<<32)-1)<<224
        if k not in keys or value&mask!=keys[k]&mask:raise AssertionError(('E prefix difference',r))
        counts[r['type']]=counts.get(r['type'],0)+1
    # NAV records carry the older word source time, and complete subframes are
    # emitted as a batch. Source-time clipping would wrongly demand future NAV.
    # Compare the observed output prefix in record order instead.
    required=set(reference_order[:len(observed)])
    if not required<=observed:raise AssertionError(('missing prefix records',len(required-observed)))
    result={'status':'E_PREFIX_BIT_EXACT_PASS','current_signal_seconds':limit/16368000,'non_end_records':len(observed),
            'exact_non_cycle_bits':True,'counts':counts,'baseline_100s_post_lock_drops':baseline_lock_drop,
            'limitation':'Current prefix only; E original 100s remains frozen, not a new current-source 100s validation.'}
    (args.directory/'e_prefix_equivalence.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result))

if __name__=='__main__':main()
