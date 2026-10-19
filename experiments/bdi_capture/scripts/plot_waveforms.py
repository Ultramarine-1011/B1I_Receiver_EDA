#!/usr/bin/env python3
"""Plot actual post-NBA transaction CSV; never synthesizes waveform values."""
from __future__ import annotations
import argparse
import hashlib
import json
import sys
from pathlib import Path

EXPERIMENT = Path(__file__).resolve().parents[1]
# Reuse this project's already-installed plotting dependency, if necessary.
try:
    import matplotlib
except ImportError:
    sys.path.insert(0, str(EXPERIMENT.parents[1]/'work/plotdeps'))
    import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--run', type=Path, required=True)
    args = parser.parse_args()
    run = args.run.resolve()
    path = run/'main/samples.csv'
    data = np.genfromtxt(path, delimiter=',', names=True)
    data = data[(data['valid'] == 1) & (data['accepted'] <= 13*16368)]
    assert len(data) == 13*16368
    figures = run/'figures'
    figures.mkdir(exist_ok=True)
    plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 10,
                         'axes.spines.top': False, 'axes.spines.right': False,
                         'svg.fonttype': 'none'})
    products = []

    def finish(fig, name):
        fig.savefig(figures/f'{name}.png', dpi=160, facecolor='white')
        fig.savefig(figures/f'{name}.svg', facecolor='white')
        products.append(name)
        plt.close(fig)

    x = data['accepted']/16368
    dumps = data[data['dump'] == 1]
    fig, axes = plt.subplots(6, 1, figsize=(12, 10), sharex=True, layout='constrained')
    fig.suptitle('MEO-6 / PRN 6: complete serial search + two verification windows\n'
                 'Actual RTL data; 16,368 accepted samples = 1 ms; threshold = 8,192', fontsize=14)
    axes[0].step(x, data['consumed_phase'], where='post', color='#2563eb', label='integrating phase')
    axes[0].step(x, data['result_phase'], where='post', color='#b45309', alpha=.7, label='last result phase')
    axes[0].set_ylabel('phase / chip'); axes[0].set_yticks([0, 5, 9, 10]); axes[0].legend(loc='upper left', ncol=2)
    stride = np.unique(np.r_[np.arange(0,len(data),24),np.where(data['dump'])[0],np.where(data['dump'])[0]-1])
    axes[1].plot(x[stride], data['i_acc'][stride], color='#b45309', label='I accumulator')
    axes[1].plot(x[stride], data['q_acc'][stride], color='#0f766e', label='Q accumulator')
    axes[1].set_ylabel('signed sum'); axes[1].legend(loc='upper left', ncol=2)
    axes[2].step(x, data['i_result'], where='post', color='#b45309', label='I result')
    axes[2].step(x, data['q_result'], where='post', color='#0f766e', label='Q result')
    axes[2].set_ylabel('final I / Q'); axes[2].legend(loc='upper left', ncol=2)
    axes[3].step(x, data['energy'], where='post', color='#7c3aed', label='energy = |I| + |Q|')
    axes[3].axhline(8192, color='#dc2626', ls='--', label='threshold 8192')
    axes[3].scatter(dumps['accepted']/16368, dumps['energy'], color='#7c3aed', s=20)
    axes[3].annotate('57,288 at phase 10', xy=(11,57288), xytext=(7.5,46000),
                     arrowprops={'arrowstyle':'->','color':'#4c1d95'})
    axes[3].set_ylabel('energy'); axes[3].legend(loc='upper left', ncol=2)
    axes[4].vlines(dumps['accepted']/16368, 0, 1, color='#2563eb')
    axes[4].set_ylabel('dump'); axes[4].set_yticks([0,1]); axes[4].set_ylim(-.1,1.3)
    axes[4].text(.2,1.08,'Each event is one system clock; spacing = 16,368 accepted samples', fontsize=9)
    axes[5].step(x, data['acquired'], where='post', color='#0f766e', label='acquired (sticky)')
    axes[5].vlines(11, 0, 1, color='#dc2626', lw=2, label='hit (one clock)')
    axes[5].set_ylabel('decision'); axes[5].set_yticks([0,1]); axes[5].set_ylim(-.1,1.3)
    axes[5].legend(loc='upper left', ncol=2)
    axes[-1].set_xlabel('Nominal input time / ms (sample count / 16,368)')
    axes[-1].set_xlim(0,13.1); axes[-1].set_xticks(range(14))
    for ax in axes: ax.grid(alpha=.2)
    finish(fig,'01_search_overview')

    def chip_zoom(phase, name):
        subset = data[(data['consumed_phase'] == phase) & (data['sample_index'] < 128)]
        # First occurrence only: subsequent verification windows repeat phase 10.
        subset = subset[:128]
        t = subset['sample_index']
        fig, axes = plt.subplots(8,1,figsize=(12,11),sharex=True,layout='constrained')
        energy = int(dumps[dumps['result_phase'] == phase][0]['energy'])
        relation = 'mismatch + low correlation' if phase == 0 else 'all 16,368 samples aligned + main peak'
        fig.suptitle(f'Phase {phase}: {relation}\nFirst 16 chips shown; complete window energy = {energy:,}',fontsize=14)
        def steps(ax, values, label, color):
            ax.step(t,subset[values],where='post',label=label,color=color); ax.legend(loc='upper right',ncol=2,fontsize=8)
        steps(axes[0],'rx_code','RX code, aligned to consumed IF','#2563eb')
        steps(axes[1],'local_code','local PRN 6','#0f766e')
        steps(axes[2],'if_sample','signed IF','#7c3aed')
        steps(axes[3],'cos','local cos','#b45309'); steps(axes[3],'sin','local sin','#0f766e')
        steps(axes[4],'i_product','I product','#b45309'); steps(axes[4],'q_product','Q product','#0f766e')
        steps(axes[5],'i_acc','I accumulator','#b45309'); steps(axes[5],'q_acc','Q accumulator','#0f766e')
        steps(axes[6],'energy','energy (last completed window)','#7c3aed')
        steps(axes[7],'dump','dump','#2563eb'); steps(axes[7],'hit','hit','#dc2626')
        for ax in axes[:2]: ax.set_yticks([0,1]); ax.set_ylim(-.15,1.3)
        for ax in axes:
            ax.grid(alpha=.2); ax.set_xlim(0,128)
            for edge in range(0,129,8): ax.axvline(edge,color='#64748b',lw=.5,alpha=.25)
        axes[-1].set_xlabel('Accepted sample index within window (8 samples / chip)')
        finish(fig,name)

    chip_zoom(0,'02_wrong_phase_code_products')
    chip_zoom(10,'03_aligned_phase_code_products')

    fig, axes = plt.subplots(5,1,figsize=(12,9),sharex=True,layout='constrained')
    fig.suptitle('Full-window accumulation: wrong phase 0 versus aligned phase 10',fontsize=14)
    for phase, color, style in [(0,'#b45309','-'),(10,'#0f766e','-')]:
        s = data[data['consumed_phase'] == phase][:16368]
        ix = np.r_[np.arange(0,len(s)-1,16),len(s)-2,len(s)-1]
        t = (s['sample_index']+1)/16368
        axes[0].plot(t[ix],s['i_acc'][ix],label=f'I acc, phase {phase}',color=color,ls=style)
        axes[1].plot(t[ix],s['q_acc'][ix],label=f'Q acc, phase {phase}',color=color,ls=style)
        axes[2].plot(t[ix],s['q_result'][ix],label=f'Q result, phase {phase}',color=color,drawstyle='steps-post')
        axes[3].plot(t[ix],s['energy'][ix],label=f'energy, phase {phase}',color=color,drawstyle='steps-post')
        axes[4].plot(t[ix],s['dump'][ix],label=f'dump, phase {phase}',color=color,drawstyle='steps-post')
    axes[1].annotate('Aligned Q accumulates to -57,288\nthen clears on dump; Q result retains it',
                     xy=(.95,-54400),xytext=(.22,-42000),arrowprops={'arrowstyle':'->'},fontsize=9)
    axes[3].axhline(8192,color='#dc2626',ls='--',label='threshold')
    for ax,label in zip(axes,['I accumulator','Q accumulator','latched Q','latched energy','dump']):
        ax.set_ylabel(label); ax.grid(alpha=.2); ax.legend(loc='upper left',ncol=2,fontsize=8)
    axes[-1].set_xlabel('Nominal time within integration window / ms')
    axes[-1].set_xlim(0,1.01)
    finish(fig,'04_full_window_comparison')

    boundary = 11*16368
    s = data[(data['accepted'] >= boundary-6) & (data['accepted'] <= boundary+6)]
    t = s['accepted']-boundary
    fig, axes = plt.subplots(8,1,figsize=(12,11),sharex=True,layout='constrained')
    fig.suptitle('First hit at window 11: final sample, dump, energy and phase labels\n'
                 'Transaction snapshots and post-edge registers; one tick = one accepted sample',fontsize=13)
    def line(ax,key,label,color):
        ax.step(t,s[key],where='post',label=label,color=color)
        ax.plot(t,s[key],'.',color=color,ms=4)
    line(axes[0],'sample_index','sample index (0..16367)','#2563eb')
    line(axes[1],'rx_code','RX code','#2563eb'); line(axes[1],'local_code','local code','#0f766e')
    line(axes[2],'i_product','I product','#b45309'); line(axes[2],'q_product','Q product','#0f766e')
    line(axes[3],'q_acc','Q accumulator clears','#0f766e')
    line(axes[4],'q_result','Q result retains -57288','#0f766e')
    line(axes[5],'energy','energy','#7c3aed'); axes[5].axhline(8192,color='#dc2626',ls='--',label='threshold')
    line(axes[6],'candidate_phase','candidate phase','#2563eb'); line(axes[6],'result_phase','result phase','#b45309')
    line(axes[7],'dump','dump','#2563eb'); line(axes[7],'hit','hit','#dc2626'); line(axes[7],'acquired','acquired','#0f766e')
    for ax in axes:
        ax.axvline(0,color='#64748b',ls=':',lw=1); ax.grid(alpha=.2); ax.legend(loc='upper left',ncol=3,fontsize=8)
    axes[-1].set_xlabel('Clock offset from first hit / accepted samples')
    axes[-1].set_xticks(range(-6,7)); axes[-1].set_xlim(-6,6)
    finish(fig,'05_dump_hit_detail')
    manifest = {'source': str(path), 'source_sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                'accepted_samples_plotted': len(data), 'matplotlib': matplotlib.__version__,
                'figures': products, 'axis': 'nominal time from counted accepted samples; VCD uses compressed 2ns clocks'}
    (figures/'provenance.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('BDI_WAVEFORM_PLOTS_PASS:', figures, 'figures=',len(products))


if __name__ == '__main__':
    main()
