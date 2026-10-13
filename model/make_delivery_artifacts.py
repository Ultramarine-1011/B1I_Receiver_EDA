"""Render current RTL evidence; assertions fail if runs/data are incomplete."""
from pathlib import Path
import csv,json,re,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'work/plotdeps'))
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'reports/local'
FS=16368000; N=16368
def main():
    text=(OUT/'tb_tracking_minimal.run.log').read_text(encoding='utf-8-sig')
    assert 'TRACKING_MINIMAL_PASS cases=2' in text and 'EXIT_CODE: 0' in text
    rows=list(csv.DictReader((OUT/'tracking_loop.csv').open()))
    assert len(rows)==1998
    metrics=[]
    for line in text.splitlines():
        if line.startswith('TRACKING_CASE_METRIC'):
            metrics.append({k:float(v) for k,v in re.findall(r'(\w+)=([\d.]+)',line)})
    assert len(metrics)==2
    plt.rcParams.update({'font.size':10,'axes.grid':True,'grid.alpha':0.2})
    fig,axes=plt.subplots(4,2,figsize=(12,11),sharex='col',constrained_layout=True)
    fig2,feedback=plt.subplots(2,2,figsize=(12,6),sharex='col',constrained_layout=True)
    for case in (0,1):
        r=[x for x in rows if int(x['case'])==case]
        assert len(r)==999
        ref=np.array([int(x['feedback_ref']) for x in r],dtype=np.float64)
        wr=np.array([int(x['window_ref']) for x in r],dtype=np.int64)
        assert np.all(np.diff(wr)==N) and np.all(ref-wr==N+1)
        state_ref=ref+1
        t=state_ref/FS
        sign=1 if case==0 else -1
        code=np.array([int(x['code_phase_q']) for x in r])/2**32
        code_error=(code-state_ref/8+1023)%2046-1023
        carrier=np.array([int(x['carrier_phase_word']) for x in r])/2**32
        phase_error=(sign*0.04+(4092000+sign*5)*state_ref/FS-carrier+0.25)%0.5-0.25
        hz=(np.array([int(x['carrier_step']) for x in r])-2**30)*FS/2**32
        axes[0,case].plot(t,code_error,label='Measured NCO code error')
        axes[1,case].plot(t,phase_error,label='Measured NCO carrier error')
        axes[2,case].plot(t,hz-sign*5,label='Measured frequency error')
        axes[3,case].plot(t,np.array([int(x['ip']) for x in r])/1e6,label='Prompt I')
        axes[3,case].plot(t,np.array([int(x['qp']) for x in r])/1e6,label='Prompt Q',alpha=0.7)
        for index,(unit,bound) in enumerate([('chip',0.1),('turn',0.02),('Hz',1.0)]):
            axes[index,case].set_ylabel(unit)
            axes[index,case].axhline(bound,color='gray',ls='--',lw=0.7)
            axes[index,case].axhline(-bound,color='gray',ls='--',lw=0.7)
        axes[0,case].set_title(f'Case {case}: initial code {sign*0.25:+.2f} chip, carrier {sign*5:+d} Hz')
        axes[3,case].set_ylabel('Prompt (million integer counts)')
        axes[3,case].set_xlabel('Accepted sample time (s)')
        axes[3,case].legend(loc='lower right')
        for ax in axes[:,case]: ax.axvspan(0.8,1,color='#009E73',alpha=0.07)
        feedback[0,case].plot(t,np.array([int(x['dll_error_q16']) for x in r])/65536,label='DLL discriminator (chip)')
        feedback[0,case].plot(t,np.array([int(x['pll_error_q16']) for x in r])/65536,label='Costas discriminator (turn)')
        feedback[0,case].legend()
        feedback[1,case].plot(t,np.array([int(x['code_correction_q16']) for x in r])/65536,label='Code correction (chip/s)')
        feedback[1,case].plot(t,np.array([int(x['carrier_correction_q16']) for x in r])/65536,label='Carrier correction (Hz)')
        feedback[1,case].legend(); feedback[1,case].set_xlabel('Accepted sample time (s)')
    fig.suptitle('Current RTL on synthetic quantized IF with ICD NH20; shade = scoring tail\nWindow snapshots shown; full-sample RMS is reported by the self-checking TB')
    fig2.suptitle('Window-derived feedback; no truth input to controller')
    for figure,name in [(fig,'tracking_diagnostics'),(fig2,'tracking_feedback')]:
        figure.savefig(OUT/(name+'.svg'));figure.savefig(OUT/(name+'.png'),dpi=120);plt.close(figure)
    a=list(csv.DictReader((OUT/'acquisition_cells.csv').open()));assert len(a)==31
    figure,ax=plt.subplots(1,2,figsize=(10,4),constrained_layout=True)
    for column,case in enumerate((1,2)):
        selected=[x for x in a if int(x['case'])==case]
        for word in sorted({int(x['doppler_word']) for x in selected}):
            subset=[x for x in selected if int(x['doppler_word'])==word]
            ax[column].plot([int(x['lag_samples']) for x in subset],[int(x['power'])/int(x['energy']) for x in subset],'-o',label=f'{word*FS/2**32:.0f} Hz')
        ax[column].set_xlabel('lag (IF samples)');ax[column].set_ylabel('RTL peak power / window energy')
        ax[column].set_title('Positive offset' if case==1 else 'Negative offset');ax[column].legend()
    figure.savefig(OUT/'acquisition_cells.svg');figure.savefig(OUT/'acquisition_cells.png',dpi=120);plt.close(figure)
    (OUT/'tracking_metrics.json').write_text(json.dumps(dict(kind='actual_RTL_on_synthetic_IF',metrics=metrics,feedback_delay_to_effective_sample=3,source_csv='tracking_loop.csv'),indent=2),encoding='utf-8')
    print('DELIVERY_ARTIFACTS_PASS current_trace_rows=1998 acquisition_cells=31 plots=3')
if __name__=='__main__':main()
