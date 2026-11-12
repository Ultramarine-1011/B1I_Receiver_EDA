`timescale 1ns/1ps
module tb_six_if #(
    parameter integer PACED=0,RECOVERY=0
);
    logic clk=0;
    always #5 clk=~clk;
    logic rst_n=0,if_valid=0,if_ready,cfg_valid=0,cfg_enable=1;
    logic [1:0] IF=0;
    logic [2:0] cfg_channel=0;
    logic [5:0] cfg_prn=6,capture_ok,bit_sync_ok,nav_data,nav_valid;
    bds_bb_6ch_core #(.FIRST_DOPPLER(0),.LAST_DOPPLER(0),
        .REFINE_LAG_RADIUS(4),.REFINE_FREQUENCY_RADIUS(0)) dut(.*);
    logic bits0[0:399],bits1[0:399],bits2[0:399],bits3[0:399],bits4[0:399],bits5[0:399];
    integer captures[0:5],losses[0:5],nav_count[0:5],last_index[0:5],tail_lock[0:5];
    integer lag[0:5];
    logic [5:0] old_capture=0,old_nav=0;
    longint sent=0,cycles=0,input_phase=0;
    integer high_water=0,fd,packed_byte,pair=4,index,got,expected,cfg_step=0;
    logic held=0,parallel_seen=0;
    longint processed;
    assign processed=dut.engine.sample_count;
    for(genvar c=0;c<6;c++) begin: accepted_sample_check
        always @(posedge clk) if(rst_n && dut.engine.sample_event && dut.engine.active[c] &&
            processed>=dut.engine.assigned_ref[c] && !dut.engine.release_slot[c] &&
            !dut.engine.channels[c].slot.tracking.frontend.sample_accepted)
            $fatal(1,"common IF skipped ch=%0d sample=%0d",c,processed);
    end
    always @(posedge clk) if(rst_n) begin
        cycles=cycles+1;
        if(if_valid && if_ready) sent=sent+1;
        if(if_valid && if_ready && sent%1636800==0)
            $display("SIX_IF_PROGRESS sent=%0d capture=%h locked=%h sync=%h",sent,capture_ok,dut.engine.locked,bit_sync_ok);
        if(dut.occupancy>high_water) high_water=dut.occupancy;
        if(dut.engine.overflow) $fatal(1,"record overflow");
        if(processed>sent || sent-processed>64) $fatal(1,"IF queue accounting");
        if(nav_valid & ~bit_sync_ok) $fatal(1,"invalid navigation output");
        if(old_nav & nav_valid) $fatal(1,"navigation pulse wider than one clock");
        if(dut.engine.locked==63) parallel_seen=1;
        for(integer c=0;c<6;c=c+1) begin
            if(capture_ok[c] && !old_capture[c]) captures[c]=captures[c]+1;
            if(!capture_ok[c] && old_capture[c]) losses[c]=losses[c]+1;
            if(processed>(PACED ? 4910400 : 21000000) && dut.engine.locked[c]) tail_lock[c]=tail_lock[c]+1;
            if(nav_valid[c]) begin
                index=((processed-lag[c]+163680)/327360)-1;
                got=nav_data[c];expected=0;
                if(index<0 || index>=400) $fatal(1,"navigation index outside truth");
                case(c)
                    0:expected=bits0[index];1:expected=bits1[index];2:expected=bits2[index];
                    3:expected=bits3[index];4:expected=bits4[index];5:expected=bits5[index];
                endcase
                if(got!==expected || (last_index[c]>=0 && index!=last_index[c]+1))
                    $fatal(1,"navigation mismatch ch=%0d sample=%0d index=%0d got=%0d expected=%0d previous=%0d",
                        c,processed,index,got,expected,last_index[c]);
                last_index[c]=index;nav_count[c]=nav_count[c]+1;
            end
        end
        old_capture=capture_ok;old_nav=nav_valid;
    end
    initial begin
        $readmemh("../tb/bits0.mem",bits0);$readmemh("../tb/bits1.mem",bits1);
        $readmemh("../tb/bits2.mem",bits2);$readmemh("../tb/bits3.mem",bits3);
        $readmemh("../tb/bits4.mem",bits4);$readmemh("../tb/bits5.mem",bits5);
        lag[0]=0;lag[1]=720;lag[2]=1600;lag[3]=2400;lag[4]=3200;lag[5]=4000;
        for(integer c=0;c<6;c=c+1) begin
            captures[c]=0;losses[c]=0;nav_count[c]=0;last_index[c]=-1;tail_lock[c]=0;
        end
        fd=$fopen(RECOVERY ? "../tb/recovery.if2" : "../tb/six.if2","rb");
        if(!fd) $fatal(1,"IF file missing");
        repeat(8) @(negedge clk);rst_n=1;
        for(integer c=0;c<6;c=c+1) begin
            cfg_valid=1;cfg_channel=c;cfg_prn=6+c;@(negedge clk);
            cfg_valid=0;repeat(c+1) @(negedge clk);
        end
        while(sent<(PACED ? 6547200 : 49104000)) begin
            if(!held) begin
                if(pair==4) begin
                    packed_byte=$fgetc(fd);pair=0;
                    if(packed_byte<0) $fatal(1,"unexpected IF EOF");
                end
                IF=(packed_byte >> (6-2*pair)) & 3;pair=pair+1;held=1;
            end
            if(PACED) begin
                input_phase=input_phase+16368000;if_valid=input_phase>=100000000;
                if(if_valid) input_phase=input_phase-100000000;
                if(if_valid && !if_ready) $fatal(1,"fixed-rate IF overrun");
            end else if_valid=cycles%37!=0;
            cfg_valid=0;
            if(RECOVERY && cfg_step==0 && sent>=14731200) begin
                cfg_valid=1;cfg_channel=2;cfg_prn=8;cfg_enable=0;cfg_step=1;
            end else if(RECOVERY && cfg_step==1 && sent>=15058560) begin
                cfg_valid=1;cfg_channel=2;cfg_prn=8;cfg_enable=1;cfg_step=2;
            end
            // The producer holds the same input until the queue accepts it.
            if(if_valid && if_ready) held=0;
            @(negedge clk);
        end
        if_valid=0;cfg_valid=0;repeat(512) @(negedge clk);
        if(processed!=sent || dut.occupancy!=0) $fatal(1,"IF queue failed to drain");
        if(!parallel_seen || dut.engine.locked!=63 || capture_ok!=63) $fatal(1,"six-channel final lock missing");
        for(integer c=0;c<6;c=c+1) begin
            if(!captures[c] || tail_lock[c]<1000 || (!PACED && nav_count[c]<35)) $fatal(1,"channel coverage ch=%0d",c);
            if(RECOVERY && (c==0 || c==2)) begin
                if(captures[c]!=2 || losses[c]!=1) $fatal(1,"recovery coverage ch=%0d",c);
            end else if(captures[c]!=1 || losses[c]!=0) $fatal(1,"cross-channel state corruption ch=%0d",c);
            $display("SIX_IF_CHANNEL ch=%0d captures=%0d losses=%0d bits=%0d",c,captures[c],losses[c],nav_count[c]);
        end
        rst_n=0;repeat(4) @(negedge clk);
        if(capture_ok || bit_sync_ok || nav_valid || dut.occupancy) $fatal(1,"global reset did not clear state");
        $display("SIX_IF_ITERATIVE_PASS paced=%0d recovery=%0d samples=%0d cycles=%0d fifo_high_water=%0d",PACED,RECOVERY,sent,cycles,high_water);
        $finish;
    end
    initial begin #1100000000; $fatal(1,"six-channel timeout");end
endmodule
