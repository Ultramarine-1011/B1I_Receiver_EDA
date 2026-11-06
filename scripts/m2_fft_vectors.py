# Python 2.6. Build the three FFT vectors from the checked-in Q30 tables.
# Does not rewrite rom/fft_cos_q30.mem or rom/fft_sin_q30.mem.
import math
import os
import random
import sys

N = 4096


def load_signed(path):
    values = []
    handle = open(path, 'r')
    for line in handle:
        text = line.strip()
        if not text or text.startswith('//'):
            continue
        word = int(text, 16)
        if word >= 2147483648:
            word -= 4294967296
        values.append(word)
    handle.close()
    if len(values) != N:
        raise SystemExit('%s has %d words' % (path, len(values)))
    return values


def bit_reverse(index):
    out = 0
    for _ in range(12):
        out = (out << 1) | (index & 1)
        index >>= 1
    return out


def transform(values, inverse, cos_table, sin_table):
    data = [(0, 0)] * N
    for index, sample in enumerate(values):
        data[bit_reverse(index)] = sample
    span = 2
    while span <= N:
        half = span // 2
        step = N // span
        base = 0
        while base < N:
            for j in range(half):
                ar, ai = data[base + j]
                br, bi = data[base + j + half]
                wr = cos_table[j * step]
                wi = sin_table[j * step]
                if not inverse:
                    wi = -wi
                tr = (br * wr - bi * wi) >> 30
                ti = (br * wi + bi * wr) >> 30
                data[base + j] = ((ar + tr) >> 1, (ai + ti) >> 1)
                data[base + j + half] = ((ar - tr) >> 1, (ai - ti) >> 1)
            base += span
        span *= 2
    return data


def store(path, values):
    handle = open(path, 'w')
    for value in values:
        handle.write('%08x\n' % (value & 0xffffffff))
    handle.close()


def main():
    rom = sys.argv[1]
    dest = sys.argv[2]
    if not os.path.isdir(dest):
        os.makedirs(dest)
    cos_table = load_signed(os.path.join(rom, 'fft_cos_q30.mem'))
    sin_table = load_signed(os.path.join(rom, 'fft_sin_q30.mem'))
    tone = []
    for k in range(N):
        tone.append((
            int(round(100000 * math.cos(2 * math.pi * 317 * k / N))),
            int(round(100000 * math.sin(2 * math.pi * 317 * k / N))),
        ))
    rng = random.Random(1301)
    noise = []
    for _ in range(N):
        noise.append((rng.randint(-2 ** 20, 2 ** 20), rng.randint(-2 ** 20, 2 ** 20)))
    cases = [
        ([(2 ** 20, 0)] + [(0, 0)] * (N - 1), False),
        (tone, False),
        (noise, True),
    ]
    for case_id, (values, inverse) in enumerate(cases):
        fixed = transform(values, inverse, cos_table, sin_table)
        for field, part in (('r', 0), ('i', 1)):
            store(os.path.join(dest, 'in%d_%s.mem' % (case_id, field)), [sample[part] for sample in values])
            store(os.path.join(dest, 'out%d_%s.mem' % (case_id, field)), [sample[part] for sample in fixed])
    print 'M2_FFT_VECTORS_DONE cases=3'


if __name__ == '__main__':
    main()
