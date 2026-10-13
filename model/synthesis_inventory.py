"""Source risk inventory only: not gate area, synthesis, STA or ASIC acceptance."""
import hashlib,json,re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1];RTL=ROOT/'student_release/student_release/rtl'
ITEMS={
 'acquisition_pcps.sv':{'patterns':[r'raw\[',r'base_r\[0:',r'code_r\[0:',r'cosine\[0:',r'accumulated_power\[0:',r'\$readmemh'],
    'declared_array_bits':65472*3+2*16368*16+4*4096*32+2*4096*32+4096*64},
 'fft4096_serial.sv':{'patterns':[r're\[0:',r'product_rr=',r're\[a_address\]<=',r're\[b_address\]<=',r'\$readmemh'],
    'declared_array_bits':4*4096*32},
 'tracking_channel_minimal.sv':{'patterns':[r'code_numerator /',r'phase_numerator /',r'for\(integer k=0;k<16',r'carrier_delta_word=',r'/763'],
    'instances_at_12_channels':12},
 'receiver_channel.sv':{'patterns':[r'channel_reset_n=',r'navigation_d1 navigation',r'logic \[255:0\]',r'assign sample_ready='],
    'instances_at_12_channels':12},
 'navigation_d1.sv':{'patterns':[r'words\[0:9\]',r'sync_reset_n=',r'/64\'\(bit_meta_step\)']},
 'tracking_record_framer.sv':{'patterns':[r'/64\'\(end_code_step\)']},
 'receiver_multichannel.sv':{'patterns':[r'sample_ready=&slot_ready',r'code_advance=',r'initial_code_phase=',r'epoch_id=',r'epoch_event=',r'handover_ref=']},
 'satellite_manager.sv':{'patterns':[r'recovery_floor\[0:63\]',r'\$countones',r'slot_generation\[c\]<63']}}

def main():
    result={'scope':'source/static risk inventory, no DC/PPA/STA/DRC/LVS','items':[]}
    for name,spec in ITEMS.items():
        p=RTL/name;text=p.read_text(encoding='utf-8');lines=text.splitlines()
        hits=[{'line':n,'text':line.strip()} for n,line in enumerate(lines,1) if any(re.search(x,line) for x in spec['patterns'])]
        result['items'].append({'file':str(p.relative_to(ROOT)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),
            **{k:v for k,v in spec.items() if k!='patterns'},'evidence':hits})
    result['pcps_plus_fft_declared_array_bits']=ITEMS['acquisition_pcps.sv']['declared_array_bits']+ITEMS['fft4096_serial.sv']['declared_array_bits']
    out=ROOT/'reports/f_stage/synthesis';out.mkdir(parents=True,exist_ok=True)
    (out/'source_inventory.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print('SYNTHESIS_SOURCE_INVENTORY_COMPLETE declared_arrays_bits='+str(result['pcps_plus_fft_declared_array_bits'])+' formal_ASIC=NOT_RUN')

if __name__=='__main__':main()
