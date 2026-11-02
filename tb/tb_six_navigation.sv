`timescale 1ns/1ps
// Accelerated Prompt-level test of the very same navigation/bit output path.
module six_nav_case #(parameter integer C=0)(output logic done=0);
    logic clk=0,reset_n=0,locked=0,prompt_valid=0;
    logic signed [27:0] prompt_i=0;
    logic [63:0] prompt_ref=0;
    logic nh_valid,frame_valid,time_valid,bch_valid,bit_sync_valid,nav_bit_valid,nav_bit;
    logic [4:0] nh_phase;
    logic record_valid;logic [255:0] record_data;
    logic bits[0:399];
    integer phase=C*3,polarity=C%2,emitted=0,round_number=0,expected_index=0;
    localparam logic [19:0] NH=20'b00000100110101001110;
    always #5 clk=~clk;
    navigation_d1 dut(.clk(clk),.reset_n(reset_n),.locked(locked),.prompt_valid(prompt_valid),
        .prompt_i(prompt_i),.prompt_ref(prompt_ref),.prompt_end_ref(prompt_ref+64'd16368),
        .end_code_phase_q(43'd0),.end_code_period_count(32'(prompt_ref/16368+1)),
        .end_code_step_q(33'h020000000),.prn(6'(C+6)),.channel(4'(C)),.generation(8'(round_number+1)),
        .nh_valid(nh_valid),.frame_valid(frame_valid),.time_valid(time_valid),.bch_valid(bch_valid),
        .nh_phase(nh_phase),.bit_sync_valid(bit_sync_valid),.nav_bit_valid(nav_bit_valid),.nav_bit(nav_bit),
        .record_valid(record_valid),.record_ready(1'b1),.record_data(record_data));
    always @(posedge clk) begin
        #1;
        if(!reset_n || !locked) begin
            if(nav_bit_valid || bit_sync_valid) $fatal(1,"stale validity ch=%0d",C);
        end else if(nav_bit_valid) begin
            if(!bit_sync_valid || !nh_valid || nav_bit!==bits[expected_index])
                $fatal(1,"serial bit mismatch ch=%0d index=%0d got=%0d expected=%0d",C,expected_index,nav_bit,bits[expected_index]);
            expected_index++;emitted++;
        end
    end
    initial begin
        case(C)
            0:$readmemh("bits0.mem",bits);1:$readmemh("bits1.mem",bits);2:$readmemh("bits2.mem",bits);
            3:$readmemh("bits3.mem",bits);4:$readmemh("bits4.mem",bits);5:$readmemh("bits5.mem",bits);
        endcase
        repeat(3+C*7) @(negedge clk);reset_n=1;
        for(integer r=0;r<2;r++) begin
            @(negedge clk);locked=1;round_number=r;expected_index=110;
            for(integer e=0;e<4000-phase;e++) begin
                @(negedge clk);prompt_ref=64'(e)*16368;
                prompt_i=(bits[(e+phase)/20]^NH[19-((e+phase)%20)]^1'(polarity)) ? -28'sd100000 : 28'sd100000;
                prompt_valid=1;@(negedge clk);prompt_valid=0;
                repeat((e+C)%4+3) @(negedge clk);
            end
            repeat(8) @(negedge clk);
            if(expected_index!=200 || int'(nh_phase)!=phase) $fatal(1,"missing bits/phase ch=%0d index=%0d phase=%0d",C,expected_index,nh_phase);
            @(negedge clk);locked=0;repeat(10+C) @(negedge clk);
        end
        if(emitted!=180) $fatal(1,"count ch=%0d",C);
        done=1;
    end
endmodule
module tb_six_navigation;
    logic [5:0] done;
    for(genvar c=0;c<6;c++) begin: channels
        six_nav_case #(.C(c)) test(done[c]);
    end
    initial begin wait(&done);$display("SIX_NAVIGATION_PASS channels=6 bits=1080 NH_phases=0/3/6/9/12/15 polarities=both loss/restart/stagger/gaps");$finish;end
    initial begin #6000000;$fatal(1,"six navigation timeout");end
endmodule
