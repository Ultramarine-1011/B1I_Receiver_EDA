`timescale 1ns/1ps
module tb_navigation_d1;
    logic clk=0;always #5 clk=~clk;
    logic reset_n=0,locked=1,prompt_valid=0;
    logic signed [27:0] prompt_i=0;
    logic [63:0] prompt_ref=0,prompt_end_ref=0;
    logic [42:0] end_code_phase_q=0;
    logic [31:0] end_code_period_count=0;
    logic [32:0] end_code_step_q=33'h020000000;
    logic [5:0] prn=6;
    logic [3:0] channel=0;
    logic [7:0] generation=1;
    logic nh_valid,frame_valid,time_valid,bch_valid,record_valid,record_ready=0;
    logic [4:0] nh_phase;
    logic [255:0] record_data,saved;
    logic bits[0:641];logic [29:0] raw[0:19];logic [25:0] info[0:19];
    logic stalled=0;
    integer phase=7,inverted=0,case_number=0,records=0,cycles=0;
    localparam logic [19:0] NH=20'b00000100110101001110;
    navigation_d1 dut(.*);
    always @(negedge clk) begin cycles=cycles+1;record_ready=cycles%37>=19;end
    always @(posedge clk) if(reset_n) begin
        if(stalled && (!record_valid || record_data!==saved)) $fatal(1,"navigation backpressure stability");
        stalled=record_valid && !record_ready;saved=record_data;
        if(record_valid && record_ready) begin
            if(records>=10 || record_data[7:0]!=2 || record_data[22:18]!=5'b11111 || !time_valid || !frame_valid)
                $fatal(1,"navigation validity/duplicate");
            if(record_data[125:96]!=raw[10+records] || record_data[151:126]!=info[10+records] ||
               record_data[155:152]!=4'(records+1) || record_data[158:156]!=2 || record_data[178:159]!=100006)
                $fatal(1,"navigation fields word=%0d",records+1);
            if(record_data[95:32]!=64'((40+300+30*(records+1))*20-phase)*16368+(case_number==0 ? -64'sd3 : 64'sd2))
                $fatal(1,"navigation end anchor ref=%0d expected_word=%0d",record_data[95:32],records+1);
            if(record_data[239:208]!=(case_number==0 ? 32'h10000000 : 32'd0) || record_data[207:197]!=0)
                $fatal(1,"navigation fractional anchor");
            records=records+1;
        end
    end
    initial begin
        $readmemh("bits.mem",bits);$readmemh("raw.mem",raw);$readmemh("info.mem",info);
        for(integer c=0;c<2;c=c+1) begin
            @(negedge clk);reset_n=0;prompt_valid=0;stalled=0;
            repeat(3) @(negedge clk);reset_n=1;records=0;case_number=c;
            phase=c==0 ? 7 : 19;inverted=c;
            for(integer e=0;e<12840-phase;e=e+1) begin
                prompt_ref=64'(e)*16368;prompt_end_ref=64'(e+1)*16368;
                end_code_phase_q=c==0 ? 43'h070000000 : (43'd2046<<32)-43'h040000000;
                end_code_period_count=32'(e+1);
                prompt_i=28'((bits[(e+phase)/20]^NH[19-((e+phase)%20)]^1'(inverted)) ? -100000 : 100000);
                prompt_valid=1;@(negedge clk);
                prompt_valid=0;repeat(5) @(negedge clk);
                if(e<12800-phase-1 && record_valid) $fatal(1,"navigation declared before two complete frames");
            end
            repeat(50) @(negedge clk);
            if(records!=10 || !nh_valid || nh_phase!=phase || !frame_valid || !time_valid) $fatal(1,"missing confirmed navigation");
            $display("NAVIGATION_D1_CASE_PASS case=%0d nh_phase=%0d inverted=%0d records=%0d",c,phase,inverted,records);
            locked=0;repeat(5) @(negedge clk);
            if(record_valid || nh_valid || frame_valid || time_valid) $fatal(1,"lost validity retained");
            locked=1;
        end
        $display("NAVIGATION_D1_PASS cases=2 two_frame_confirmation=1 backpressure=1 lost_reset=1");$finish;
    end
    initial begin #3000000;$fatal(1,"navigation timeout");end
endmodule
