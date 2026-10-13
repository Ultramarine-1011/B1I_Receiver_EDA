"""Synthetic Prompt-only NH/D1 module stimuli, not receiver/teacher records."""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
NH=[int(c) for c in '00000100110101001110']
PREAMBLE=int('11100010010',2)

def encode(info):
    value=info<<4
    remainder=value
    for k in range(14,3,-1):
        if (remainder>>k)&1: remainder^=0x13<<(k-4)
    return value | (remainder&15)

def interleave(a,b):
    out=0
    for k in range(14,-1,-1): out=(out<<2) | (((a>>k)&1)<<1) | ((b>>k)&1)
    return out

def main():
    dest=ROOT/'tb/vectors/nh_d1';dest.mkdir(parents=True,exist_ok=True)
    header=(PREAMBLE<<4)|1
    first=(header<<15)|encode(0x345)
    second=interleave(encode(0x155),encode(0x6AB)) ^ (1<<5)
    third=interleave(encode(0x3E1),encode(0x321)) ^ 3
    words=[first,second,third]
    information=[(header<<11)|0x345,(0x155<<11)|0x6AB,(0x3E1<<11)|0x321]
    corrections=[0,1,2]
    bits=[0]*40+[int(c) for word in words for c in f'{word:030b}']+[0]*2
    (dest/'nav_bits.mem').write_text(''.join(f'{b:x}\n' for b in bits),encoding='ascii')
    (dest/'expected_words.mem').write_text(''.join(f'{(w<<28)|(info<<2)|corr:015x}\n' for w,info,corr in zip(words,information,corrections)),encoding='ascii')
    (dest/'manifest.json').write_text(json.dumps(dict(kind='synthetic_prompt_module_test_not_teacher_reception',nh=NH,words=words,information=information,corrected_bits=corrections,phases=[0,7,19],inverted=[0,1,0],bits=len(bits)),indent=2),encoding='utf-8')
    print('NH_D1_VECTORS_PASS words=3 BCH_errors_per_word=0,1,2 phases=0,7,19')
if __name__=='__main__':main()
