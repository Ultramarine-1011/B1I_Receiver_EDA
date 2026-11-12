`timescale 1ns/1ps
// Prompt-level verification of the mapped six-channel shell and navigation.
// Acquisition results and tracker Prompt outputs are injected at their ports.
module mapped_prompt_case #(parameter integer C=0)(
    input logic clk,reset_n,start,nav_valid,nav_data,bit_sync,
    output logic locked=0,prompt_valid=0,
    output logic signed [27:0] prompt_i=0,
    output logic [63:0] prompt_ref=0,
    output logic done=0
);
    localparam logic [19:0] NH=20'b00000100110101001110;
    logic bits[0:399];
    integer phase=C*3,polarity=C%2,expected_index=0,emitted=0;
    always @(posedge clk) begin
        #1;
        if(!reset_n || !locked) begin
            if(nav_valid || bit_sync) $fatal(1,"stale validity ch=%0d",C);
        end else if(nav_valid) begin
            if(!bit_sync || nav_data!==bits[expected_index])
                $fatal(1,"mapped serial mismatch ch=%0d index=%0d got=%0d expected=%0d",C,expected_index,nav_data,bits[expected_index]);
            expected_index++;emitted++;
        end
    end
    initial begin
        case(C)
            0:$readmemh("bits0.mem",bits);1:$readmemh("bits1.mem",bits);2:$readmemh("bits2.mem",bits);
            3:$readmemh("bits3.mem",bits);4:$readmemh("bits4.mem",bits);5:$readmemh("bits5.mem",bits);
        endcase
        wait(start);repeat(3+C*7) @(negedge clk);
        for(integer r=0;r<2;r++) begin
            @(negedge clk);locked=1;expected_index=110;
            for(integer e=0;e<4000-phase;e++) begin
                @(negedge clk);prompt_ref=64'(e)*16368;
                prompt_i=(bits[(e+phase)/20]^NH[19-((e+phase)%20)]^1'(polarity)) ? -28'sd100000 : 28'sd100000;
                prompt_valid=1;@(negedge clk);prompt_valid=0;
                repeat((e+C)%4+3) @(negedge clk);
            end
            repeat(8) @(negedge clk);
            if(expected_index!=200) $fatal(1,"mapped missing bits ch=%0d index=%0d",C,expected_index);
            @(negedge clk);locked=0;repeat(100+C) @(negedge clk);
        end
        if(emitted!=180) $fatal(1,"mapped count ch=%0d",C);
        done=1;
    end
endmodule

module tb_mapped_core_navigation;
    logic clk=0,rst_n=0,start=0;
    wire if_ready;
    wire [5:0] capture_ok,bit_sync_ok,nav_data,nav_valid;
    wire [5:0] locked,prompt_valid,done;
    wire signed [27:0] prompt_i[0:5];
    wire [63:0] prompt_ref[0:5];
    always #5 clk=~clk;
    bds_bb_6ch_core dut(.clk(clk),.rst_n(rst_n),.IF(2'b00),.if_valid(1'b0),.if_ready(if_ready),
        .cfg_valid(1'b0),.cfg_channel(3'd0),.cfg_prn(6'd6),.cfg_enable(1'b1),
        .capture_ok(capture_ok),.bit_sync_ok(bit_sync_ok),.nav_data(nav_data),.nav_valid(nav_valid));
    for(genvar c=0;c<6;c++) begin: stimuli
        mapped_prompt_case #(.C(c)) test(.clk(clk),.reset_n(rst_n),.start(start),
            .nav_valid(nav_valid[c]),.nav_data(nav_data[c]),.bit_sync(bit_sync_ok[c]),
            .locked(locked[c]),.prompt_valid(prompt_valid[c]),.prompt_i(prompt_i[c]),
            .prompt_ref(prompt_ref[c]),.done(done[c]));
    end
    initial begin
        force dut.acquisition.sample_ready=1'b0;
        force dut.acquisition.result_valid=1'b1;
        force dut.acquisition.detected=1'b1;
        force dut.acquisition.result_prn=6'd6;
        force dut.acquisition.result_ref=64'd0;
        force dut.refine.result_valid=1'b1;
        force dut.refine.detected=1'b1;
        force dut.refine.result_lag=14'd0;
        force dut.refine.result_doppler=32'd0;
        // @TRACKER_FORCES@
        repeat(4) @(negedge clk);rst_n=1;
        repeat(100) @(negedge clk);
        if(capture_ok!==6'h3f || if_ready!==1'b1) $fatal(1,"mapped assignment/ready failed capture=%h",capture_ok);
        start=1;
        wait(&done);
        @(negedge clk);rst_n=0;
        repeat(3) @(negedge clk);
        if(capture_ok!==0 || bit_sync_ok!==0 || nav_valid!==0) $fatal(1,"mapped final reset failed");
        $display("MAPPED_CORE_NAVIGATION_PASS channels=6 bits=1080 phases=0/3/6/9/12/15 polarity=both loss/restart/stagger/gaps reset=pass prompt_level=1 sdf=0");
        $finish;
    end
    initial begin #6000000;$fatal(1,"mapped navigation timeout");end
endmodule
