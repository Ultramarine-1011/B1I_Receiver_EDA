"""Two consecutive complete D1 frames for the navigation wrapper, synthetic only."""
from pathlib import Path
from nh_d1_vectors import encode,interleave,PREAMBLE
import json
ROOT=Path(__file__).resolve().parents[1]
def main():
    dest=ROOT/'work/navigation';dest.mkdir(parents=True,exist_ok=True)
    words=[];infos=[]
    for frame in range(2):
        sow=100000+6*frame;sfid=frame+1
        header=(PREAMBLE<<4)|1;tail=(sfid<<8)|(sow>>12)
        raw=(header<<15)|encode(tail);words.append(raw);infos.append((header<<11)|tail)
        for w in range(2,11):
            payload=((sow&4095)<<10)|0x255 if w==2 else (0x17531*w+frame*0x4321)&0x3fffff
            words.append(interleave(encode(payload>>11),encode(payload&2047)));infos.append(payload)
    bits=[0]*40+[int(b) for w in words for b in f'{w:030b}']+[0]*2
    (dest/'bits.mem').write_text(''.join(f'{b:x}\n' for b in bits),encoding='ascii')
    (dest/'raw.mem').write_text(''.join(f'{w:08x}\n' for w in words),encoding='ascii')
    (dest/'info.mem').write_text(''.join(f'{w:07x}\n' for w in infos),encoding='ascii')
    (ROOT/'reports/e_stage/navigation_vectors.json').write_text(json.dumps(dict(kind='synthetic_prompt_not_teacher_records',sow=[100000,100006],sfid=[1,2],words=words,information=infos),indent=2)+'\n')
    print('NAVIGATION_VECTORS_PASS frames=2 words=20')
if __name__=='__main__':main()
