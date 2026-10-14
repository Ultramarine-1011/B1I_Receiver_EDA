"""Plot only transitions exported from actual ModelSim WLF; never invent samples."""
from pathlib import Path
import sys,re,json,csv,hashlib,shutil
ROOT=next(p for p in Path(__file__).resolve().parents if (p/'AGENTS.md').is_file() and (p/'student_release').is_dir())
sys.path.insert(0,str(ROOT/'work/plotdeps'))
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter
AREA=ROOT/'work/report_waveforms'
ASSETS=ROOT/'docs/report_assets'
EVIDENCE=ROOT/'reports/local/report_refresh_2026-10-14'

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def read_vcd(stem):
    scope=[];names={};traces={};time=0
    for line in (AREA/(stem+'.vcd')).read_text().splitlines():
        if line.startswith('$scope '):scope.append(line.split()[2])
        elif line.startswith('$upscope'):scope.pop()
        elif line.startswith('$var '):
            p=line.split();key='.'.join(scope+[p[4]]);names[p[3]]=(key,int(p[2]));traces[key]=[]
        elif line.startswith('#'):time=int(line[1:])/1000 # VCD is 1ps; plot times are ns
        elif line.startswith('b'):
            p=line.split()
            if len(p)!=2 or p[1] not in names:continue
            key,width=names[p[1]]
            value=None if re.search('[xz]',p[0],re.I) else int(p[0][1:],2)
            if not traces[key] or traces[key][-1][1]!=value:traces[key].append((time,value))
    return names,traces

def value_text(v,width,style):
    if v is None:return 'X'
    if style=='hex':return f'0x{v:0{(width+3)//4}x}'
    if style=='signed' and v>=2**(width-1):v-=2**width
    return str(v)

def plot(stem,filename,title,lo,hi,signals):
    names,traces=read_vcd(stem)
    widths={name:width for name,width in names.values()}
    if stem=='navigation':
        key='tb_navigation_d1.record_data'
        for label,shift,width in [('nav_word_number',152,4),('nav_sow',159,20)]:
            derived='tb_navigation_d1.'+label
            traces[derived]=[]
            for t,v in traces[key]:
                field=None if v is None else (v>>shift)&(2**width-1)
                if not traces[derived] or traces[derived][-1][1]!=field:traces[derived].append((t,field))
            widths[derived]=width
    fig,ax=plt.subplots(figsize=(15.8,0.55*len(signals)+1.5),layout='constrained')
    count=len(signals);yticks=[];labels=[];rows=[]
    for i,(key,style) in enumerate(signals):
        assert key in traces,(stem,key)
        y=count-i;yticks.append(y);labels.append(key.split('.',1)[1])
        events=traces[key];current=None
        for t,v in events:
            if t<=lo:current=v
            else:break
        clip=[(lo,current)]+[(t,v) for t,v in events if lo<t<=hi]
        for t,v in clip:rows.append((t/1000,key,value_text(v,widths[key],style)))
        clip.append((hi,clip[-1][1]));width=widths[key]
        ax.axhline(y-0.44,color='#e2e8f0',lw=0.5)
        if width==1:
            xx=[t/1000 for t,v in clip];yy=[y+0.24 if v==1 else y-0.24 for t,v in clip]
            ax.step(xx,yy,where='post',color='#146b53',lw=1.5)
            ax.text(hi/1000,y,value_text(clip[-1][1],width,style),ha='right',va='center',fontsize=9,bbox=dict(facecolor='white',edgecolor='none',alpha=.9))
        else:
            for j in range(len(clip)-1):
                a,v=clip[j];b=clip[j+1][0]
                ax.plot([a/1000,b/1000],[y-.19,y-.19],color='#176ca4',lw=1)
                ax.plot([a/1000,b/1000],[y+.19,y+.19],color='#176ca4',lw=1)
                if j:ax.plot([a/1000,a/1000],[y-.19,y+.19],color='#176ca4',lw=1)
                if (b-a)/(hi-lo)>0.028:
                    ax.text((a+b)/2000,y,value_text(v,width,style),ha='center',va='center',fontsize=9,bbox=dict(facecolor='white',edgecolor='none',alpha=.92))
    ax.set_yticks(yticks,labels,fontsize=10);ax.tick_params(axis='y',length=0)
    ax.set_xlim(lo/1000,hi/1000);ax.set_ylim(.35,count+.7)
    ax.grid(axis='x',alpha=.25);ax.xaxis.set_major_formatter(ScalarFormatter(useOffset=False))
    ax.ticklabel_format(axis='x',style='plain',useOffset=False)
    ax.set_xlabel('ModelSim simulation time (us); this is NOT IF signal time',fontsize=10)
    ax.set_title(title+'\nActual WLF -> VCD transitions; rendered trace, NOT a GUI screenshot',loc='left',fontsize=12)
    for side in ['top','right','left']:ax.spines[side].set_visible(False)
    fig.savefig(ASSETS/(filename+'.png'),dpi=150)
    plt.close(fig)
    csvpath=EVIDENCE/(filename+'_events.csv')
    with csvpath.open('w',newline='',encoding='utf-8') as f:
        writer=csv.writer(f);writer.writerow(['simulation_time_us','signal','actual_value']);writer.writerows(sorted(rows))
    return {'image':filename+'.png','kind':'actual_RTL_VCD_rendered_trace_not_GUI_screenshot','source_wlf':str((AREA/(stem+'.wlf')).relative_to(ROOT)).replace('\\','/'),'wlf_sha256':sha(AREA/(stem+'.wlf')),'source_vcd':str((AREA/(stem+'.vcd')).relative_to(ROOT)).replace('\\','/'),'vcd_sha256':sha(AREA/(stem+'.vcd')),'image_sha256':sha(ASSETS/(filename+'.png')),'simulation_window_ns':[lo,hi],'events_csv':str(csvpath.relative_to(ROOT)).replace('\\','/'),'events_sha256':sha(csvpath),'signals':[k for k,s in signals]}

def sig(prefix,*args):return [(prefix+'.'+n,style) for n,style in args]
ASSETS.mkdir(exist_ok=True)
images=[]
images.append(plot('acquisition','acquisition_pcps_refine','PCPS and exact-period refinement | PRN6 / 0Hz / noiseless reduced grid',9620350,9620460,sig('tb_p02_probe',('coarse_valid','unsigned'),('coarse_detected','unsigned'),('prn','unsigned'),('coarse_lag','unsigned'),('coarse_doppler','signed'),('coarse_peak','unsigned'),('coarse_mean','unsigned'),('fine_valid','unsigned'),('fine_detected','unsigned'),('fine_lag','unsigned'),('fine_doppler','signed'),('fine_peak','unsigned'))))
images.append(plot('tracking','tracking_feedback_timing','Correlator -> feedback -> NCO | current RTL / FLL=0 / carrier aid=0 / partial run',29810220,29810300,sig('tb_tracking_minimal',('window_done','unsigned'),('feedback_valid','unsigned'),('window_ref','unsigned'),('feedback_ref','unsigned'),('ie','signed'),('ip','signed'),('il','signed'),('qp','signed'),('dll_error_q16','signed'),('pll_error_q16','signed'),('code_step_q','hex'),('carrier_step_word','hex'),('locked','unsigned'))))
images.append(plot('nh_d1','nh_d1_words','NH20 and BCH word decoding | synthetic Prompt / phase0 / normal polarity',19500,25000,sig('tb_nh_d1',('nh_locked','unsigned'),('nh_phase','unsigned'),('bit_valid','unsigned'),('data_bit','unsigned'),('word_valid','unsigned'),('word_number','unsigned'),('raw_word','hex'),('information','hex'),('corrected_bits','unsigned'),('bch_valid','unsigned'))))
images.append(plot('navigation','navigation_confirmation','Two complete subframes -> type2 publication | synthetic Prompt / NH19 / inverted / SOW100006',1537370,1537660,sig('tb_navigation_d1',('nh_valid','unsigned'),('nh_phase','unsigned'),('dut.word_valid','unsigned'),('dut.word_number','unsigned'),('dut.sow','unsigned'),('frame_valid','unsigned'),('time_valid','unsigned'),('bch_valid','unsigned'),('record_valid','unsigned'),('record_ready','unsigned'),('nav_word_number','unsigned'),('nav_sow','unsigned'))))
raw=json.loads((EVIDENCE/'wave_sources.json').read_text(encoding='utf-8-sig'))
for entry in raw:entry['path']=str(Path(entry['path']).relative_to(ROOT)).replace('\\','/')
logs={p.name:{'sha256':sha(p),'exit_code':int(re.findall(r'EXIT_CODE: (\d+)',p.read_text(encoding='utf-8-sig'))[-1])} for p in EVIDENCE.glob('modelsim*.log')}
provenance={'date':'2026-10-14 Asia/Singapore','source_baseline_main':'7dfa40b','rtl_changed':False,'archive_changed':False,'simulator':'ModelSim SE-64 10.5 (2016.02)','scope':{'acquisition':'tb_p02_probe full reduced-grid self-check PASS (not formal P02 coverage)','nh_d1':'tb_nh_d1 full 3 cases / 9 words PASS','navigation':'tb_navigation_d1 full 2 cases / 20 type2 words PASS','tracking':'original tb_tracking_minimal stopped at 30000us / 182 feedbacks / sample_ref2997948 / locked0; NOT full regression'},'testbench_isolation':'Four original TB copies changed only ../../tb/vectors/ and ../../reports/local/ paths. No test criteria or receiver sources changed. Other TB inputs copied byte-for-byte to isolated directory.','gui_capture':{'count':0,'attempt':'ModelSim GUI and WLF were opened and inspected before interruption; no screenshot PNG was saved. After network interruption node_repl initialization failed twice (including reset) with failed to write kernel assets / system cannot find the path / os error3. No runtime/security/license configuration was changed.','fallback':'These four PNGs are standard plots of actual exported VCD transitions, explicitly marked NOT GUI screenshots; two original CSV-derived SVGs are also reused.'},'sources':raw,'logs':logs,'images':images,'reused_svg':[{'image':'acquisition_serial_cells.svg','source':'reports/local/acquisition_cells.svg','sha256':sha(ROOT/'reports/local/acquisition_cells.svg'),'scope':'A-D serial 4 cases / 31 grid cells; from actual acquisition_cells.csv'},{'image':'tracking_diagnostics.svg','source':'reports/local/tracking_diagnostics.svg','sha256':sha(ROOT/'reports/local/tracking_diagnostics.svg'),'scope':'A-D static 2x1s loop, from actual tracking_loop.csv'}],'plot_recipe':'reports/local/report_refresh_2026-10-14/plot_actual_traces.py','plot_recipe_sha256':sha(Path(__file__))}
(ASSETS/'waveform_provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
shutil.copyfile(__file__,EVIDENCE/'plot_actual_traces.py')
for recipe in ['run_waveforms.ps1','collect_more.ps1']:shutil.copyfile(AREA/recipe,EVIDENCE/recipe)
print(json.dumps({'status':'ACTUAL_TRACE_RENDER_PASS','images':len(images),'gui_screenshots':0,'all_logs_exit_zero':all(x['exit_code']==0 for x in logs.values())}))
