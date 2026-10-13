"""Cross-check actual RTL word outputs using unchanged teacher prompt_d1.py."""
import csv,sys,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'student_release/student_release/tools'))
from prompt_d1 import decode_word

def main():
    manifest=json.loads((ROOT/'tb/vectors/nh_d1/manifest.json').read_text())
    rows=list(csv.DictReader((ROOT/'reports/local/nh_d1_words.csv').open()))
    assert len(rows)==9
    for row in rows:
        number=int(row['word'])
        raw=int(row['raw'],16)
        bits=[int(c) for c in f'{raw:030b}']
        info,corrected=decode_word(bits,first=number==1)
        info_integer=int(''.join(map(str,info)),2)
        assert info_integer==int(row['information'],16)==manifest['information'][number-1]
        assert corrected==int(row['corrected_bits'])==manifest['corrected_bits'][number-1]
    print('TEACHER_PROMPT_D1_WORD_DIAGNOSTIC_PASS words=9; synthetic Prompt module experiment, not teacher-scenario navigation')
if __name__=='__main__':main()
