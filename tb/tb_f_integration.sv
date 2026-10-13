`timescale 1ns/1ps
// Two self-generated B1I primary/NH signals. Narrow test search saves cost;
// production full-range defaults are tested separately on the public IF.
module tb_f_integration;
    logic clk=0,reset_n=0,start=0;
    logic [31:0] stream_data=0;logic stream_valid=0,stream_ready,stream_last=0;
    logic [63:0] sample_index=0;
    logic [255:0] record_data,saved;logic record_valid,record_ready=1,stalled=0;
    logic prn6[0:2045],prn7[0:2045];
    integer words=0,cycles=0,ends=0,acq6=0,acq7=0,lost6=0,tracks6=0,tracks7=0;
    integer count6_after7=0,generation6=0,tail_lock6=0,tail_lock7=0;
    logic seen_background_samples=0,seen_background_compute=0,reacquired=0,input_held=0;
    localparam integer TOTAL=16368*3200;
    always #5 clk=~clk;
    receiver_multichannel #(.CHANNELS(12),.REFINE_LAG_RADIUS(4),.REFINE_FREQUENCY_RADIUS(0),
        .SEARCH_FIRST_PRN(6),.SEARCH_LAST_PRN(7),
        .SEARCH_FIRST_DOPPLER(0),.SEARCH_LAST_DOPPLER(0)) dut(.*);
    function automatic logic [1:0] adc(input integer n);
        real analog;
        integer chip,millisecond,sign6,sign7,nh_sign;
        logic [19:0] nh;
        begin
            chip=(n%16368)/8;millisecond=n/16368;nh=20'b00000100110101001110;
            nh_sign=nh[19-(millisecond%20)] ? -1 : 1;
            sign6=prn6[chip] ? -1 : 1;sign7=prn7[chip] ? -1 : 1;
            // PRN7 joins after 90ms; PRN6 has a 130ms outage after initial lock.
            analog=(((millisecond<350 || millisecond>=480) ? sign6 : 0)+
                    (millisecond>=90 ? sign7 : 0))*nh_sign*$cos(6.283185307179586*(0.04+real'(n)/4));
            adc=analog < -0.5 ? 0 : analog < 0 ? 1 : analog < 0.5 ? 2 : 3;
        end
    endfunction
    always @(posedge clk) if(reset_n) begin
        cycles++;if(cycles>90000000) $fatal(1,"timeout");
        input_held=stream_valid&&!stream_ready;
        if(stream_valid&&stream_ready) begin
            words++;
            if(words%102300==0) $display("F_INPUT_PROGRESS ms=%0d cycles=%0d",words/1023,cycles);
        end
        // DUT state encodings RUN=8, BG_CAPTURE=2, BG_SEARCH=3.
        // Hierarchical enum-item references trigger a Verilator5.032 compiler fault.
        if(dut.state==4'd8 && dut.sample_valid && dut.sample_ready) begin
            if(dut.bg_state==3'd2 && dut.active[0]) seen_background_samples=1;
            if(dut.bg_state==3'd3 && dut.active[0]) seen_background_compute=1;
        end
        if(stalled && (!record_valid || record_data!==saved)) $fatal(1,"record backpressure instability");
        stalled=record_valid&&!record_ready;saved=record_data;
        if(record_valid&&record_ready) begin
            if(ends) $fatal(1,"record after end");
            case(record_data[7:0])
                1: begin
                    if(record_data[13:8]==6) begin tracks6++;if(acq7) count6_after7++;end
                    else if(record_data[13:8]==7) tracks7++;
                    else $fatal(1,"wrong tracking identity");
                    if(!record_data[18] && (record_data[21:19]!=0)) $fatal(1,"stale validity after loss");
                    if(record_data[95:32]>=64'd49104000 && record_data[18]) begin
                        if(record_data[13:8]==6) tail_lock6++;else tail_lock7++;
                    end
                end
                3: begin
                    $display("F_LOST prn=%0d ref=%0d generation=%0d",record_data[13:8],record_data[95:32],record_data[31:24]);
                    if(record_data[13:8]==6) lost6++; else $fatal(1,"unexpected other loss");
                end
                4: if(record_data[22]) $fatal(1,"false valid OBS without decoded D1");
                5: if(record_data[18]) begin
                    $display("F_ACQUISITION prn=%0d ref=%0d channel=%0d lag=%0d",record_data[13:8],record_data[95:32],record_data[17:14],record_data[109:96]);
                    if(record_data[13:8]==6) begin acq6++;if(acq6>1) reacquired=1;end
                    else if(record_data[13:8]==7) acq7++;
                    else $fatal(1,"wrong acquisition identity");
                end
                6: begin
                    ends++;if(record_data[95:32]!=TOTAL || record_data[19:18]!=0) $fatal(1,"end count/flags");
                end
                default: $fatal(1,"unexpected record %0d",record_data[7:0]);
            endcase
        end
    end
    for(genvar c=0;c<12;c++) begin: sample_score
        always @(posedge clk) if(reset_n && dut.state==4'd8 && dut.sample_valid && dut.sample_ready &&
            dut.active[c] && dut.sample_ref>=dut.channels[c].slot.effective_ref && !dut.release_event[c] &&
            !dut.channels[c].slot.tracking.frontend.sample_accepted)
            $fatal(1,"common sample missed channel=%0d ref=%0d",c,dut.sample_ref);
    end
    initial begin
        $readmemh("b1i_prn_06.mem",prn6);$readmemh("b1i_prn_07.mem",prn7);
        repeat(4) @(negedge clk);reset_n=1;start=1;
        @(negedge clk);start=0;
        while(words<TOTAL/16) begin
            @(negedge clk);
            if(!input_held) begin
                stream_valid=words<TOTAL/16 && cycles%31!=0;sample_index=64'(words*16);stream_last=words==TOTAL/16-1;
                for(integer k=0;k<16;k++) stream_data[k*2+:2]=adc(words*16+k);
            end
            record_ready=cycles%47>=17;
        end
        @(negedge clk);stream_valid=0;stream_last=0;record_ready=1;
        while(!ends) @(negedge clk);
        repeat(10) @(negedge clk);
        if(acq6<2 || acq7!=1 || lost6<1 || tracks6<300 || tracks7<300 || count6_after7<100 ||
           !seen_background_samples || !seen_background_compute || !reacquired || tail_lock6<100 || tail_lock7<100)
            $fatal(1,"coverage acq=%0d/%0d lost6=%0d tracks=%0d/%0d after7=%0d bg=%0d/%0d tail_lock=%0d/%0d",acq6,acq7,lost6,tracks6,tracks7,count6_after7,seen_background_samples,seen_background_compute,tail_lock6,tail_lock7);
        $display("F_INTEGRATION_PASS synthetic_primary_NH=1 channels=12 samples=%0d cycles=%0d acq6=%0d acq7=%0d lost6=%0d tracks6=%0d tracks7=%0d",TOTAL,cycles,acq6,acq7,lost6,tracks6,tracks7);$finish;
    end
endmodule
