"""Independent six-satellite quantized IF and D1 truth; never supplies DUT state."""
import argparse
import json
from pathlib import Path
import numpy as np
from b1i_prn_golden import generate_prn
from nh_d1_vectors import encode, interleave, PREAMBLE, NH

FS = 16368000
LAGS = [0, 720, 1600, 2400, 3200, 4000]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=Path('work/six_channel_20261102'))
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    all_bits = []
    for c in range(6):
        # 1.6 s acquisition/NH training, then a valid, channel-specific D1 frame.
        sow = 100000 + 6*c
        header = (PREAMBLE << 4) | 1
        words = [(header << 15) | encode((1 << 8) | (sow >> 12))]
        for w in range(2, 11):
            payload = ((sow & 4095) << 10) | c if w == 2 else ((w*0x17531) ^ (c*0x329ab)) & 0x3fffff
            words.append(interleave(encode(payload >> 11), encode(payload & 2047)))
        bits = [0]*80 + [int(b) for word in words for b in f'{word:030b}'] + [0]*20
        all_bits.append(np.array(bits, dtype=np.int8))
        (args.out / f'bits{c}.mem').write_text(''.join(f'{b}\n' for b in bits), encoding='ascii')
    truth = dict(kind='self_generated_six_star_IF_not_teacher', fs=FS, if_hz=4092000,
                 prns=list(range(6, 12)), lags=LAGS, doppler_hz=[0]*6,
                 seconds=3, bits=[x.tolist() for x in all_bits],
                 quantizer='sum six +/-1 real quarter-IF signals; thresholds -2,0,2')
    (args.out / 'truth.json').write_text(json.dumps(truth, indent=2)+'\n', encoding='utf-8')
    # Also serve accelerated independent Prompt tests (phase and polarity differ).
    codes = [np.array(generate_prn(6+c), dtype=np.int8) for c in range(6)]
    nh = np.array(NH, dtype=np.int8)
    for recovery in (False, True):
        total = FS * 3
        with (args.out / ('recovery.if2' if recovery else 'six.if2')).open('wb') as f:
            for first in range(0, total, 262144):
                n = np.arange(first, min(first+262144, total), dtype=np.int64)
                analog = np.zeros(len(n), dtype=np.int8)
                for c in range(6):
                    t = n-LAGS[c]
                    ms = t//16368
                    b = all_bits[c][(t//327360) % len(all_bits[c])]
                    sign = codes[c][(t//8) % 2046] ^ nh[ms % 20] ^ b ^ ((n//2) & 1) ^ (c % 2)
                    amplitude = 1-2*sign
                    if recovery and c == 0:
                        amplitude = np.where((n >= FS//2) & (n < FS*7//10), 0, amplitude)
                    analog += amplitude.astype(np.int8)
                adc = np.where(analog < -2, 0, np.where(analog < 0, 1, np.where(analog < 2, 2, 3))).astype(np.uint8)
                packed = (adc[0::4] << 6) | (adc[1::4] << 4) | (adc[2::4] << 2) | adc[3::4]
                f.write(packed.tobytes())
    print('SIX_VECTORS_PASS independent_primary_codes=6 mixed_IF=6 full_D1_frame_per_channel=1')


if __name__ == '__main__':
    main()
