"""Independent primary-code stimulus for F tests; no acquisition answers."""
from pathlib import Path
from b1i_prn_golden import generate_prn

if __name__ == '__main__':
    folder=Path(__file__).resolve().parents[1]/'work/f_stage'
    folder.mkdir(parents=True,exist_ok=True)
    for prn in (6,7):
        (folder/f'b1i_prn_{prn:02d}.mem').write_text(''.join(f'{x}\n' for x in generate_prn(prn)),encoding='ascii')
    print('F_SIGNAL_VECTORS_PASS PRN6/7 primary codes only; no DUT truth path')
