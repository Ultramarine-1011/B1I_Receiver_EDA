`timescale 1ns/1ps
// External-PAD IF test. Truth is confined to the checker.
module tb;
    reg clk=0,rst_n=0,if_valid=0,cfg_valid=0,cfg_enable=1;
    reg [1:0] if_data=0;
    reg [2:0] cfg_channel=0;
    reg [5:0] cfg_prn=6;
    wire pad_clk=clk,pad_rst_n=rst_n,pad_if_valid=if_valid,pad_cfg_valid=cfg_valid,pad_cfg_enable=cfg_enable;
    wire [1:0] pad_IF=if_data;
    wire [2:0] pad_cfg_channel=cfg_channel;
    wire [5:0] pad_cfg_prn=cfg_prn;
    wire pad_if_ready;
    wire [5:0] pad_capture_ok,pad_bit_sync_ok,pad_nav_data,pad_nav_valid;
    wire VDD=1'b1,VSS=1'b0,VDDPST=1'b1,VSSPST=1'b0;
    bds_bb_6ch_pad_top dut(
        .pad_clk(pad_clk),.pad_rst_n(pad_rst_n),.pad_IF(pad_IF),
        .pad_if_valid(pad_if_valid),.pad_if_ready(pad_if_ready),
        .pad_cfg_valid(pad_cfg_valid),.pad_cfg_channel(pad_cfg_channel),
        .pad_cfg_prn(pad_cfg_prn),.pad_cfg_enable(pad_cfg_enable),
        .pad_capture_ok(pad_capture_ok),.pad_bit_sync_ok(pad_bit_sync_ok),
        .pad_nav_data(pad_nav_data),.pad_nav_valid(pad_nav_valid)
        `include "dut_pg.svh"
    );
    real clock_ns=10.0;
    string directory,mode,corner,vcd,filename,interval_path;
    integer input_file,truth_file,byte_value,pair=4,scan_value,truth_value;
    integer source[0:5],lag[0:5],truth[0:2399];
    integer bits_seen[0:5],last_index[0:5],captures[0:5],losses[0:5];
    integer index,configuration_step=0,interval_file;
    longint samples=0,cycles=0,dump_begin=45830400,dump_end=46485120;
    longint pace_phase=0,pace_clock_hz;
    bit paced_window=0;
    reg [5:0] old_nav=0,old_capture=0;
    reg taken=0,held=0,eof=0,dumping=0,dump_finished=0;
    initial begin
        if($value$plusargs("CLOCK_NS=%f",clock_ns)) begin end
        if(clock_ns<=0) $fatal(1,"Invalid clock period");
        if(1.0e9/clock_ns<16368000.0) $fatal(1,"Clock cannot accept 16.368 MHz IF");
        forever #(clock_ns/2.0) clk=~clk;
    end
    task automatic tick;
        @(posedge clk);
        if(rst_n && (pad_if_ready!==0 && pad_if_ready!==1)) $fatal(1,"if_ready X/Z");
        // The external receiver samples the preceding launch at this edge.
        // This follows the output-delay budget through the PAD cells.
        if(rst_n) begin
            if((^{pad_capture_ok,pad_bit_sync_ok,pad_nav_valid})===1'bx) $fatal(1,"PAD output X/Z");
            if((pad_nav_valid & ~pad_bit_sync_ok)!=0 || (pad_bit_sync_ok & ~pad_capture_ok)!=0) $fatal(1,"Invalid output status");
            if((old_nav & pad_nav_valid)!=0) $fatal(1,"nav_valid longer than one cycle");
            for(integer c=0;c<6;c=c+1) begin
                if(pad_capture_ok[c] && !old_capture[c]) captures[c]=captures[c]+1;
                if(!pad_capture_ok[c] && old_capture[c]) losses[c]=losses[c]+1;
                if(pad_nav_valid[c]) begin
                    index=(samples-lag[source[c]]+163680)/327360-1;
                    if(index<0 || index>=400) $fatal(1,"Navigation index out of range");
                    if(pad_nav_data[c]!==truth[source[c]*400+index][0]) $fatal(1,"Navigation mismatch ch=%0d sample=%0d index=%0d",c,samples,index);
                    if(last_index[c]>=0 && index!=last_index[c]+1) $fatal(1,"Missing/duplicate navigation bit");
                    last_index[c]=index;
                    bits_seen[c]=bits_seen[c]+1;
                end
            end
        end else if(pad_capture_ok!==0 || pad_bit_sync_ok!==0 || pad_nav_valid!==0) $fatal(1,"Reset did not clear status");
        old_nav=pad_nav_valid;
        old_capture=pad_capture_ok;
        taken=if_valid && pad_if_ready;
        if(paced_window && if_valid && !pad_if_ready) $fatal(1,"Fixed-rate IF overrun in the power window");
        if(taken) samples=samples+1;
        cycles=cycles+1;
        @(negedge clk); #0.01;
        if(!dumping && !dump_finished && samples>=dump_begin && rst_n) begin
            interval_file=$fopen(interval_path,"w");
            if(interval_file==0) $fatal(1,"Activity interval file cannot be opened");
            $fwrite(interval_file,"%.3f\n",$realtime);
            $dumpfile(vcd);
            $dumpvars(0,tb.dut);
            dumping=1;
        end
        if(dumping && samples>=dump_end) begin
            $fwrite(interval_file,"%.3f\n",$realtime);
            $fclose(interval_file);
            $dumpoff;
            dumping=0;dump_finished=1;
        end
        if(cycles>100000000) $fatal(1,"Cycle timeout");
    endtask
    initial begin
        if(!$value$plusargs("IF_DIR=%s",directory) || !$value$plusargs("VCD=%s",vcd) ||
           !$value$plusargs("INTERVAL=%s",interval_path)) $fatal(1,"Required runtime argument missing");
        if(!$value$plusargs("MODE=%s",mode)) mode="nominal";
        if(mode!="nominal" && mode!="permuted" && mode!="recovery" && mode!="smoke") $fatal(1,"Unknown mode");
        if($value$plusargs("DUMP_BEGIN_SAMPLE=%d",dump_begin)) begin end
        if($value$plusargs("DUMP_END_SAMPLE=%d",dump_end)) begin end
        if(dump_end<=dump_begin) $fatal(1,"Invalid activity window");
        `ifdef GLS_MIN
        corner="MINIMUM";
        $sdf_annotate("output/final_min.sdf",dut,,"logs/sdf.log","MINIMUM");
        `else
        corner="MAXIMUM";
        $sdf_annotate("output/final_max.sdf",dut,,"logs/sdf.log","MAXIMUM");
        `endif
        lag[0]=0;lag[1]=720;lag[2]=1600;lag[3]=2400;lag[4]=3200;lag[5]=4000;
        for(integer c=0;c<6;c=c+1) begin
            source[c]=mode=="permuted" ? (c*5+1)%6 : c;
            bits_seen[c]=0;last_index[c]=-1;captures[c]=0;losses[c]=0;
            filename=$sformatf("%s/bits%0d.mem",directory,c);
            truth_file=$fopen(filename,"r");
            if(truth_file==0) $fatal(1,"Truth file missing %s",filename);
            for(integer k=0;k<400;k=k+1) begin
                scan_value=$fscanf(truth_file,"%d",truth_value);
                if(scan_value!=1 || (truth_value!=0 && truth_value!=1)) $fatal(1,"Invalid bit truth");
                truth[c*400+k]=truth_value;
            end
            $fclose(truth_file);
        end
        repeat(8) tick();
        rst_n=1;tick();
        for(integer c=0;c<6;c=c+1) begin
            cfg_valid=1;cfg_channel=c;cfg_prn=6+source[c];tick();
            cfg_valid=0;repeat(c+1) tick();
        end
        if(mode=="recovery") filename={directory,"/recovery.if2"};
        else filename={directory,"/six.if2"};
        input_file=$fopen(filename,"rb");
        if(input_file==0) $fatal(1,"IF file missing %s",filename);
        while(!eof) begin
            if(!held) begin
                if(pair==4) begin byte_value=$fgetc(input_file);pair=0;end
                if(byte_value<0) eof=1;
                else begin if_data=(byte_value>>(6-2*pair))&3;pair=pair+1;held=1;end
            end
            if(!eof) begin
                paced_window=samples>=dump_begin && samples<dump_end;
                if(paced_window) begin
                    pace_clock_hz=longint'(1.0e9/clock_ns);
                    pace_phase=pace_phase+16368000;
                    if_valid=pace_phase>=pace_clock_hz;
                    if(if_valid) pace_phase=pace_phase-pace_clock_hz;
                end else if_valid=cycles%37!=0;
                cfg_valid=0;
                if(mode=="recovery" && configuration_step==0 && samples>=14731200) begin
                    cfg_valid=1;cfg_channel=2;cfg_prn=8;cfg_enable=0;configuration_step=1;
                end else if(mode=="recovery" && configuration_step==1 && samples>=15058560) begin
                    cfg_valid=1;cfg_channel=2;cfg_prn=8;cfg_enable=1;configuration_step=2;
                end
                tick();
                if(taken) held=0;
                if(mode=="smoke" && samples==1000) eof=1;
            end
        end
        $fclose(input_file);
        if_valid=0;cfg_valid=0;repeat(100) tick();
        if(mode!="smoke") begin
            if(samples!=49104000 || pad_capture_ok!==6'b111111 || pad_bit_sync_ok!==6'b111111) $fatal(1,"Six-channel final coverage missing");
            for(integer c=0;c<6;c=c+1) begin
                if(bits_seen[c]<35) $fatal(1,"Insufficient navigation coverage ch=%0d",c);
                if(mode=="recovery" && (c==0 || c==2)) begin
                    if(captures[c]!=2 || losses[c]!=1) $fatal(1,"Recovery coverage missing");
                end else if(captures[c]!=1 || losses[c]!=0) $fatal(1,"Cross-channel state corruption");
                $display("LAB_SIX_CHANNEL ch=%0d bits=%0d captures=%0d losses=%0d",c,bits_seen[c],captures[c],losses[c]);
            end
            if(!dump_finished) $fatal(1,"Activity interval did not finish");
        end
        rst_n=0;repeat(4) tick();
        $display("LAB_GLS_SIX_PASS mode=%s corner=%s samples=%0d cycles=%0d",mode,corner,samples,cycles);
        $finish;
    end
endmodule
