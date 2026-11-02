"""Collect actual six-channel run results and plot recorded state transitions."""
import csv
import hashlib
import json
import re
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports/six_channel_20261102'
WORK = ROOT / 'work/six_channel_20261102'


def main():
    summary = {}
    truth = json.loads((WORK/'truth.json').read_text(encoding='utf-8'))
    for mode, log in [('nominal', 'receiver_run.log'), ('permuted', 'permuted_run.log'),
                      ('recovery', 'recovery_run.log'), ('paced', 'paced_run.log')]:
        text = (OUT / log).read_text(encoding='utf-8-sig')
        match = re.search(r'SIX_RECEIVER_PASS mode=(\w+) samples=(\d+) cycles=(\d+) stalled_cycles=(\d+) maximum_stall=(\d+) parallel=(\d+)', text)
        assert match and 'EXIT_CODE: 0' in text and 'SIX_RECEIVER_FAIL' not in text, log
        fields = ['samples', 'cycles', 'stalled_cycles', 'maximum_stall', 'parallel']
        item = dict(zip(fields, map(int, match.groups()[1:])))
        item['nav_bits_per_channel'] = [int(x) for x in re.findall(r'nav_bits=(\d+)', text)]
        item['captures_per_channel'] = [int(x) for x in re.findall(r'captures=(\d+)', text)]
        item['losses_per_channel'] = [int(x) for x in re.findall(r'losses=(\d+)', text)]
        item['wall_seconds'] = float(re.search(r'WALL_SECONDS: ([\d.]+)', text)[1])
        item['hardware_cycles_per_sample'] = item['cycles']/item['samples']
        acquisitions = []
        for ch, sample, ref, coarse_lag, lag, doppler in re.findall(
                r'SIX_ASSIGN ch=(\d+) sample=(\d+) capture_ref=(\d+) coarse_lag=(\d+) lag=(\d+) doppler=(-?\d+)', text):
            ch, sample, ref, lag, doppler = map(int, (ch, sample, ref, lag, doppler))
            source = (ch*5+1) % 6 if mode == 'permuted' else ch
            expected_lag = (truth['lags'][source]-ref) % 16368
            error = (lag-expected_lag+8184) % 16368-8184
            assert abs(error) <= 1 and doppler == 0, (mode, ch, lag, expected_lag, doppler)
            acquisitions.append(dict(channel=ch, capture_ref=ref, lag=lag,
                                     expected_lag=expected_lag, error_samples=error))
        assert len(acquisitions) == sum(item['captures_per_channel']), mode
        item['acquisition_alignment'] = acquisitions
        item['rejected_history_candidates'] = text.count('SIX_REJECT_HISTORY')
        if mode == 'recovery':
            assert item['rejected_history_candidates'] >= 3
        wave = (WORK/f'{mode}.vcd').read_text(encoding='ascii')
        assert '$timescale 1ps $end' in wave
        nav_code = re.search(r'\$var\s+wire\s+6\s+(\S+)\s+nav_valid\b', wave)[1]
        clk_code = re.search(r'\$var\s+wire\s+1\s+(\S+)\s+clk\b', wave)[1]
        now = previous = 0
        starts = [None]*6
        widths, clock_edges = [], []
        for line in wave.splitlines():
            if line.startswith('#') and line[1:].isdigit():
                now = int(line[1:])
            elif line.startswith('b') and line.split()[-1] == nav_code:
                value = int(line.split()[0][1:], 2)
                for c in range(6):
                    if (value >> c) & 1 and not (previous >> c) & 1:
                        starts[c] = now
                    elif (previous >> c) & 1 and not (value >> c) & 1:
                        widths.append(now-starts[c]); starts[c] = None
                previous = value
            elif line in ('0'+clk_code, '1'+clk_code) and len(clock_edges) < 20:
                clock_edges.append(now)
        assert not any(starts) and len(widths) == sum(item['nav_bits_per_channel']), (mode, len(widths))
        assert all(width == 10000 for width in widths), (mode, sorted(set(widths)))
        assert len(clock_edges) == 20 and all(b-a == 5000 for a, b in zip(clock_edges, clock_edges[1:])), mode
        item['waveform_nav_pulses'] = len(widths)
        item['waveform_nav_pulse_width_ps'] = 10000 if widths else None
        item['waveform_clock_half_period_ps'] = 5000
        assert item['parallel'] == 6 and len(item['nav_bits_per_channel']) == 6
        summary[mode] = item
        rows = list(csv.DictReader((WORK / f'{mode}.csv').open(encoding='ascii')))
        (OUT / f'{mode}_events.csv').write_text((WORK / f'{mode}.csv').read_text(encoding='ascii'), encoding='ascii')
        if mode in ('nominal', 'recovery'):
            fig, axes = plt.subplots(6, 1, figsize=(11, 9), sharex=True)
            for c, ax in enumerate(axes):
                x = [0] + [int(r['sample'])/16368000 for r in rows]
                for field, offset, color in [('capture', 0, '#20807c'), ('locked', 1.25, '#1768ac'), ('sync', 2.5, '#a34477')]:
                    y = [offset] + [offset + ((int(r[field]) >> c) & 1)*.8 for r in rows]
                    ax.step(x, y, where='post', label=field, color=color, linewidth=1.2)
                nav_x = [int(r['sample'])/16368000 for r in rows if int(r['nav_valid']) & (1 << c)]
                ax.scatter(nav_x, [3.65]*len(nav_x), marker='|', color='#e19829', s=18, label='nav_valid')
                ax.set_ylim(-.15, 4); ax.set_yticks([.4, 1.65, 2.9], ['capture', 'lock', 'bit sync'])
                ax.set_ylabel(f'CH{c}', rotation=0, labelpad=24);ax.grid(axis='x', alpha=.2)
            axes[0].set_title(f'Six-channel {mode}: actual RTL event trace (RF sample time)')
            axes[-1].set_xlabel('Accepted RF samples / 16.368 MHz (s)')
            axes[0].legend(loc='upper left', ncol=4, fontsize=8)
            fig.tight_layout();fig.savefig(OUT / f'{mode}_states.png', dpi=150);plt.close(fig)
    required = {
        'final_navigation/navigation_run.log': 'SIX_NAVIGATION_PASS',
        'legacy_channels/tb_channel_bank.run.log': 'CHANNEL_BANK_PASS',
        'legacy_channels/tb_channel_reuse.run.log': 'CHANNEL_REUSE_PASS',
        'legacy_navigation/tb_navigation_bank.run.log': 'NAVIGATION_BANK_PASS',
        'legacy_e0/tb_receiver_e0.run.log': 'RECEIVER_E0_PASS',
        'legacy_e0/tb_receiver_tail.run.log': 'RECEIVER_TAIL_PASS',
        'legacy_e0/e0_score.log': 'RECEIVER_E0_INDEPENDENT_SCORE_PASS',
        'legacy_timing/tb_p02_probe.run.log': 'P02_RTL_TIMING_PROBE_PASS',
        'public_legacy6/run.log': 'FAST_RTL_PASS',
    }
    for name, marker in required.items():
        text = (OUT / name).read_text(encoding='utf-8-sig')
        assert marker in text and 'EXIT_CODE: 0' in text, name
    public_structure = (OUT / 'public_legacy6/structure.log').read_text(encoding='utf-8-sig')
    assert 'EXIT_CODE: 0' in public_structure and 'PASS records=' in public_structure
    def records(path):
        data = path.read_bytes()
        assert len(data) % 32 == 0
        return [int.from_bytes(data[k:k+32], 'little') for k in range(0, len(data), 32)]
    def key(value):
        return value & 255, (value >> 8) & 63, (value >> 32) & ((1 << 64)-1)
    frozen = {key(v): v for v in records(ROOT/'reports/f_stage/real2/receiver_records.bin')}
    compared = 0
    for value in records(OUT/'public_legacy6/receiver_records.bin'):
        kind, prn, _ = key(value)
        if kind in (1, 4, 5) and prn in (8, 11, 13, 21):
            mask = (1 << 256)-1
            if kind == 5:
                mask ^= ((1 << 32)-1) << 224
            assert key(value) in frozen and value & mask == frozen[key(value)] & mask, key(value)
            compared += 1
    assert compared == 1184
    summary['frozen_f2_shared_records_bit_exact'] = compared
    summary['regressions'] = list(required)
    (OUT / 'summary.json').write_text(json.dumps(summary, indent=2)+'\n', encoding='utf-8')
    files = [*WORK.glob('*.if2'), *WORK.glob('bits*.mem'), WORK/'truth.json', *WORK.glob('*.vcd'),
             *sorted((ROOT/'261102').iterdir())]
    manifest = [dict(path=str(p.relative_to(ROOT)), bytes=p.stat().st_size,
                     sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in files]
    (OUT / 'stimulus_and_waveforms.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    nav_bits = sum(sum(summary[mode]['nav_bits_per_channel']) for mode in ('nominal', 'permuted', 'recovery'))
    print(f'SIX_REPORT_PASS modes=4 independent_IF_navigation_bits={nav_bits} prompt_navigation_bits=1080 regressions=all_present')


if __name__ == '__main__':
    main()
