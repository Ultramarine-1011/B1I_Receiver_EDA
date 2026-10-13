#!/usr/bin/env python3
"""Clock-event golden for one-cycle mixer/code alignment and fixed windows."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path

from carrier_model import FixedCarrier, frequency_word, IF_HZ
from code_nco_epl_model import FixedCodeNco, EplCorrelator, BASELINE_WINDOW_SAMPLES


def case(path, prn, initial_phase, initial_carrier, code_step, count, ref_base):
    nco = FixedCodeNco(prn, initial_phase, 123, code_step)
    carrier = FixedCarrier()
    carrier.clock(1, 1, initial_carrier, 0, 0, 0, frequency_word(IF_HZ))
    correlator = EplCorrelator()
    opened = initial_phase == 0
    previous_epoch = False
    pending = None
    energy_acc = energy_output = 0
    accepted = windows = 0
    rows = []
    for tick in range(count):
        valid = int(tick < count-2 and tick % 13 != 4)
        sample_ref = ref_base + accepted
        x = (-4, -3, -1, 1, 3, 0, 2, -2)[accepted % 8]
        step = frequency_word(IF_HZ + (10000 if tick < count//2 else -10000))
        if pending is not None and pending[0]:
            _, i, q, codes, ref = pending
            energy_acc += i*i + q*q
            correlator.clock(1, i, q, codes, ref)
            if correlator.window_done:
                energy_output = energy_acc
                energy_acc = 0
                windows += 1
        else:
            correlator.clock(0, 0, 0, (0,0,0), 0)
        # Pipeline enable corresponds to the SAME current input sample as codes.
        opened = opened or previous_epoch
        codes = nco.current()
        carrier.clock(1, 0, 0, valid, x, sample_ref, step)
        pending = (bool(valid and opened), carrier.i, carrier.q, codes, sample_ref)
        previous_epoch = nco.accept_sample() if valid else False
        accepted += valid
        row = [valid, x, sample_ref, step, nco.phase_q, nco.period_count,
               carrier.phase, int(previous_epoch), correlator.window_done,
               *correlator.outputs, correlator.window_ref, energy_output]
        assert all(-(1 << 27) <= value < (1 << 27) for value in correlator.outputs)
        assert 0 <= energy_output < (1 << 42)
        rows.append(' '.join(map(str, row)))
    assert windows >= 1
    path.write_text(f'{prn} {initial_phase} 123 {initial_carrier} {code_step} {count}\n'
                    + '\n'.join(rows)+'\n', encoding='ascii')
    return dict(file=str(path), prn=prn, events=count, accepted=accepted, windows=windows,
                sha256=hashlib.sha256(path.read_bytes()).hexdigest())


def main():
    root = Path('tb/vectors/frontend')
    root.mkdir(parents=True, exist_ok=True)
    cases = [case(root/'aligned.vec', 6, 0, 0, 1 << 29, 36000, 1000),
             case(root/'wrap.vec', 12, (2045 << 32)+(3 << 30), 0xffffffff,
                  (1 << 29)+1000, 18000, 100000),
             case(root/'negative.vec', 23, (123 << 32)+(3 << 29), 123456789,
                  (1 << 29)-1000, 36000, 200000)]
    Path('reports/carrier/frontend_model.json').write_text(json.dumps(cases, indent=2)+'\n', encoding='utf-8')
    print('FRONTEND_MODEL_PASS', json.dumps(cases))


if __name__ == '__main__':
    main()
