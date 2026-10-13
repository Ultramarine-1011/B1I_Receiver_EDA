`timescale 1ns/1ps
// Synthetic Prompt-level D1 words: tests 12 independent decoders, not 12 IF stars.
module nav_bank_case #(parameter integer C=0)(output logic done=0);
    logic clk=0,reset_n=0,locked=1,prompt_valid=0,record_valid,record_ready=0;
    logic signed [27:0] prompt_i=0;
    logic [63:0] prompt_ref=0,prompt_end_ref=0;
    logic [42:0] end_code_phase_q=0;logic [31:0] end_code_period_count=0;
    logic [32:0] end_code_step_q=33'h020000000;
    logic [5:0] prn=6'(6+C);logic [3:0] channel=4'(C);logic [7:0] generation=8'(C+1);
    logic nh_valid,frame_valid,time_valid,bch_valid;logic [4:0] nh_phase;
    logic [255:0] record_data,held;logic stalled=0;
    logic bits[0:641];logic [29:0] raw[0:19];logic [25:0] info[0:19];
    integer records=0,cycles=0,phase=C%3==0 ? 0 : C%3==1 ? 7 : 19;
    localparam logic [19:0] NH=20'b00000100110101001110;
    always #5 clk=~clk;
    navigation_d1 dut(.*);
    always @(negedge clk) begin cycles++;record_ready=(cycles+C)%37>=19;end
    always @(posedge clk) if(reset_n) begin
        if(stalled && (!record_valid || held!==record_data)) $fatal(1,"nav bank stall channel=%0d",C);
        stalled=record_valid&&!record_ready;held=record_data;
        if(record_valid&&record_ready) begin
            if(records>=10 || record_data[7:0]!=2 || record_data[22:18]!=5'b11111 ||
               record_data[13:8]!=prn || record_data[17:14]!=channel || record_data[31:24]!=generation)
                $fatal(1,"nav bank identity/validity channel=%0d",C);
            if(record_data[125:96]!=raw[10+records] || record_data[151:126]!=info[10+records] ||
               record_data[155:152]!=4'(records+1) || record_data[158:156]!=2 || record_data[178:159]!=100006)
                $fatal(1,"nav bank contents channel=%0d word=%0d",C,records+1);
            records++;
        end
    end
    initial begin
        $readmemh("bits.mem",bits);$readmemh("raw.mem",raw);$readmemh("info.mem",info);
        repeat(3) @(negedge clk);reset_n=1;
        for(integer e=0;e<12840-phase;e++) begin
            prompt_ref=64'(e)*16368;prompt_end_ref=64'(e+1)*16368;end_code_period_count=32'(e+1);
            prompt_i=28'((bits[(e+phase)/20]^NH[19-((e+phase)%20)]^1'(C%2)) ? -100000 : 100000);
            prompt_valid=1;@(negedge clk);prompt_valid=0;repeat(5) @(negedge clk);
        end
        repeat(50) @(negedge clk);
        if(records!=10 || !time_valid || !frame_valid || nh_phase!=phase) $fatal(1,"nav bank missing channel=%0d",C);
        locked=0;repeat(5) @(negedge clk);
        if(record_valid || nh_valid || frame_valid || time_valid) $fatal(1,"nav loss state channel=%0d",C);
        done=1;
    end
endmodule
module tb_navigation_bank;
    logic [11:0] done;
    for(genvar c=0;c<12;c++) begin: cases
        nav_bank_case #(.C(c)) channel(done[c]);
    end
    initial begin wait(&done);$display("NAVIGATION_BANK_PASS prompt_level=1 independent_channels=12 words=120 phase=0/7/19 polarity=both identity/generation/backpressure/loss");$finish;end
    initial begin #3000000;$fatal(1,"nav bank timeout");end
endmodule
