`timescale 1ns/1ps
module tb_receiver_e0;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0, start=0;
    logic [31:0] stream_data[0:2];
    logic [2:0] stream_valid=0, stream_ready, stream_last=0, record_valid, record_ready=0;
    logic [63:0] sample_index[0:2];
    logic [255:0] record_data[0:2];
    logic prn6[0:2045],prn12[0:2045];
    integer words[0:2],samples[0:2],tracks[0:2],acquisitions[0:2],ends[0:2],locked_count[0:2];
    integer fd[0:2];
    integer cycles=0;
    localparam integer TOTAL=4092000; // 250 ms, including >160-window lock evidence
    function automatic integer lag(input integer c);
        lag=c==0 ? 0 : c==1 ? 16 : -8;
    endfunction
    function automatic integer hz(input integer c);
        hz=c==0 ? 0 : c==1 ? 1000 : -1000;
    endfunction
    function automatic logic [1:0] adc(input integer c,input integer n);
        real analog;
        integer chip,sign_code,nh_sign;
        logic [19:0] nh;
        begin
            nh=20'b00000100110101001110;
            chip=((n-lag(c)+16368)%16368)/8;
            sign_code=(c==2 ? prn12[chip] : prn6[chip]) ? -1 : 1;
            nh_sign=nh[19-(((n-lag(c)+16368)/16368)%20)] ? -1 : 1;
            analog=2*sign_code*nh_sign*$cos(6.283185307179586*(0.04+(4092000.0+hz(c))*real'(n)/16368000.0));
            adc=analog < -1 ? 0 : analog < 0 ? 1 : analog < 1 ? 2 : 3;
        end
    endfunction
    for(genvar c=0;c<3;c=c+1) begin: cases
        logic [255:0] saved;
        logic stalled=0;
        logic [63:0] last_track_ref=0;
        student_receiver_core #(.USE_PCPS(0),.SEARCH_PRN(c==2 ? 12 : 6),
            .SEARCH_LAG_FIRST(c==2 ? 16352 : 0),.SEARCH_LAG_LAST(c==2 ? 16360 : c==0 ? 16 : 24),
            .SEARCH_LAG_STEP(8),.SEARCH_DOPPLER_FIRST(-262400),.SEARCH_DOPPLER_LAST(262400),
            .SEARCH_DOPPLER_STEP(262400)) dut(
            .clk(clk),.reset_n(reset_n),.start(start),.stream_data(stream_data[c]),
            .stream_valid(stream_valid[c]),.stream_ready(stream_ready[c]),.stream_last(stream_last[c]),
            .sample_index(sample_index[c]),.record_data(record_data[c]),
            .record_valid(record_valid[c]),.record_ready(record_ready[c])
        );
        always @(posedge clk) if(reset_n) begin
            if(stream_valid[c] && stream_ready[c]) words[c]=words[c]+1;
            if(dut.single.receiver.sample_valid && dut.single.receiver.sample_ready) begin
                if(dut.single.receiver.sample_ref!=64'(samples[c]) || dut.single.receiver.sample_bits!=adc(c,samples[c]))
                    $fatal(1,"IF sample loss/repetition case=%0d n=%0d",c,samples[c]);
                samples[c]=samples[c]+1;
            end
            if(stalled && (!record_valid[c] || record_data[c]!==saved)) $fatal(1,"record backpressure stability");
            stalled=record_valid[c] && !record_ready[c]; saved=record_data[c];
            if(record_valid[c] && record_ready[c]) begin
                if(ends[c]!=0) $fatal(1,"record after end");
                for(integer b=0;b<32;b=b+1) $fwrite(fd[c],"%c",record_data[c][8*b+:8]);
                case(record_data[c][7:0])
                    5: begin
                        acquisitions[c]=acquisitions[c]+1;
                        if(!record_data[c][18] || record_data[c][95:32]!=0 ||
                           record_data[c][109:96]!=14'((lag(c)+16368)%16368) ||
                           $signed(record_data[c][159:128])!=32'(hz(c)*262400/1000))
                            $fatal(1,"acquisition mismatch case=%0d lag=%0d frequency=%0d",c,record_data[c][109:96],$signed(record_data[c][159:128]));
                    end
                    1: begin
                        if(!record_data[c][23] || record_data[c][31:24]!=8'hc1) $fatal(1,"schema3 marker");
                        if(tracks[c]!=0 && (record_data[c][95:32]<last_track_ref+16366 || record_data[c][95:32]>last_track_ref+16370)) $fatal(1,"Prompt boundary ref discontinuity");
                        if(record_data[c][119:96]!==24'($signed(dut.single.receiver.tracking.ip) >>> 4)) $fatal(1,"Prompt scale");
                        last_track_ref=record_data[c][95:32]; tracks[c]=tracks[c]+1;
                        if(record_data[c][18]) locked_count[c]=locked_count[c]+1;
                    end
                    6: begin
                        if(samples[c]!=TOTAL || words[c]!=TOTAL/16 || record_data[c][95:32]!=TOTAL || record_data[c][19:18]!=0)
                            $fatal(1,"end before drain or incorrect count");
                        ends[c]=ends[c]+1;
                    end
                    default: $fatal(1,"unexpected record type");
                endcase
            end
        end
        initial begin: producer
            stream_data[c]=0; sample_index[c]=0;
            wait(reset_n); wait(start); @(negedge clk);
            for(integer n=0;n<TOTAL;n=n+16) begin
                // Deterministic input gaps, independent of signal sample time.
                if(n%128==0) repeat(2) @(negedge clk);
                for(integer lane=0;lane<16;lane=lane+1) stream_data[c][2*lane+:2]=adc(c,n+lane);
                sample_index[c]=64'(n); stream_last[c]=(n==TOTAL-16); stream_valid[c]=1;
                do @(posedge clk); while(!stream_ready[c]);
                @(negedge clk); stream_valid[c]=0;
            end
        end
    end
    always @(negedge clk) begin
        cycles=cycles+1;
        // Stall in long bursts at output and also cross final record delivery.
        record_ready=cycles%37<11 ? 3'b000 : 3'b111;
    end
    initial begin
        $readmemh("../../tb/vectors/b1i_prn_06.mem",prn6);
        $readmemh("../../tb/vectors/b1i_prn_12.mem",prn12);
        for(integer c=0;c<3;c=c+1) begin
            words[c]=0;samples[c]=0;tracks[c]=0;acquisitions[c]=0;ends[c]=0;locked_count[c]=0;
            fd[c]=$fopen($sformatf("../../reports/local/e0_case%0d.bin",c),"wb");
            if(fd[c]==0) $fatal(1,"output open");
        end
        repeat(4) @(negedge clk); reset_n=1; start=1;
        @(negedge clk); start=0;
        wait(ends[0]==1 && ends[1]==1 && ends[2]==1);
        repeat(30) @(negedge clk);
        for(integer c=0;c<3;c=c+1) begin
            $fclose(fd[c]);
            if(acquisitions[c]!=1 || tracks[c]<247 || locked_count[c]<50) $fatal(1,"insufficient tracking case=%0d tracks=%0d lock=%0d",c,tracks[c],locked_count[c]);
            $display("E0_CASE_PASS case=%0d samples=%0d tracks=%0d locked=%0d",c,samples[c],tracks[c],locked_count[c]);
        end
        $display("RECEIVER_E0_PASS cases=3 samples_per_case=%0d backpressure=1",TOTAL); $finish;
    end
    initial begin #300000000; $fatal(1,"RECEIVER_E0_TIMEOUT"); end
endmodule
