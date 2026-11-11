#!/usr/bin/env python3
"""Independent ICD stage-list reference; no generated data enters the DUT."""
from __future__ import annotations
import argparse
import json
import re
from pathlib import Path

N = 16368
NH = '00000100110101001110'
HEAD = '11100010010'
TEACHER_WRONG = [1736, 0, 56, 1736, 1792, 56, 1792, 1848, 0, 0]


def code(prn: int) -> list[int]:
    g1 = [int(x) for x in '01010101010']
    g2 = g1.copy()
    assert prn == 6, 'this experiment is MEO-6 / PRN6 only'
    taps = (1, 9)
    result = []
    for _ in range(2046):
        result.append(g1[10] ^ g2[taps[0]-1] ^ g2[taps[1]-1])
        f1 = sum(g1[t-1] for t in (1, 7, 8, 9, 10, 11)) % 2
        f2 = sum(g2[t-1] for t in (1, 2, 3, 4, 5, 8, 9, 11)) % 2
        g1, g2 = [f1, *g1[:-1]], [f2, *g2[:-1]]
    return result


def window(phase: int, window_index: int, source_phase: int = 10) -> dict:
    chips = code(6)
    nav = int((HEAD + '1'*50)[(window_index//20) % 61])
    nh = int(NH[window_index % 20])
    # Source [1,0,-1,0]; local cos [0,-7,0,7], sin [7,0,-7,0].
    # Chip boundaries are multiples of 8; each chip contributes four +/-7 Qs.
    q = sum((-1 if (chips[(source_phase+k) % 2046] ^ nav ^ nh
                       ^ chips[(phase+k) % 2046]) else 1) * 28
            for k in range(2046))
    return {'window': window_index+1, 'phase': phase, 'i': 0,
            'q': q, 'energy': abs(q)}


def generate(teacher: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    chips = code(6)
    text = (teacher/'bdi_prn_code_pkg.sv').read_text(encoding='utf-8-sig')
    table = re.search(r"2046'b([01]{2046})", text).group(1)
    assert table == ''.join(map(str, chips)), 'ICD / teacher table mismatch'
    (output/'prn6.mem').write_text(''.join(f'{b}\n' for b in chips), encoding='ascii')
    rows = [window(min(k, 10), k) for k in range(13)]
    assert all(r['energy'] == 57288 for r in rows[10:])
    assert [r['q'] for r in rows[10:12]] == [-57288, 57288]
    (output/'energy.mem').write_text(''.join(f"{r['energy']:08x}\n" for r in rows), encoding='ascii')
    differences = [{'phase': k, 'document_energy': value, 'cyclic_table_energy': rows[k]['energy']}
                   for k, value in enumerate(TEACHER_WRONG) if value != rows[k]['energy']]
    result = {'table_check': 'PASS: all 2046 chips', 'threshold': 8192,
              'valid_samples_per_window': N, 'first_source_20_chips':
              ''.join(str(chips[(10+k) % 2046]) for k in range(20)),
              'reference_windows': rows, 'document_wrong_phase_values': TEACHER_WRONG,
              'document_low_value_differences': differences}
    (output/'reference.json').write_text(json.dumps(result, indent=2)+'\n')
    print('BDI_REFERENCE_PASS: ICD=teacher table (2046 chips); full-window golden generated')
    print('DOCUMENT_LOW_VALUE_DIFFERENCES:', json.dumps(differences))
    return result


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--teacher', type=Path, required=True)
    p.add_argument('--output', type=Path, required=True)
    a = p.parse_args()
    generate(a.teacher, a.output)
