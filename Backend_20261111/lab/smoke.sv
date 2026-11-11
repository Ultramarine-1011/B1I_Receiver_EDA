`timescale 1ns/1ps
`ifdef SYNTHESIS
module backend_smoke(input logic clk,reset_n,enable,output logic [7:0] count);
    always @(posedge clk or negedge reset_n)
        if(!reset_n) count<=0;
        else count<={count[6:0],enable};
endmodule
`endif

`ifndef SYNTHESIS
module tb;
    reg clk=0,reset_n=0,enable=0;
    wire [7:0] count;
    integer expected=0;
    integer iteration;
    real clock_ns=10.0;
    string corner,vcd;
    backend_smoke dut(.*);
    initial begin
        if($value$plusargs("CLOCK_NS=%f",clock_ns)) begin end
        if(clock_ns<=0) $fatal(1,"Invalid clock period");
        forever #(clock_ns/2.0) clk=~clk;
    end
    initial begin
        `ifdef GLS_MIN
        corner="MINIMUM";
        $sdf_annotate("output/final_min.sdf",dut,,"logs/sdf.log","MINIMUM");
        `else
        corner="MAXIMUM";
        $sdf_annotate("output/final_max.sdf",dut,,"logs/sdf.log","MAXIMUM");
        `endif
        if($value$plusargs("VCD=%s",vcd)) begin
            $dumpfile(vcd);
            $dumpvars(0,tb.dut);
        end
        repeat(4) @(negedge clk);
        #0.01;
        if(count!==0) $fatal(1,"Reset failed");
        reset_n=1;
        enable=1;
        for(iteration=0;iteration<300;iteration=iteration+1) begin
            @(negedge clk); #0.01;
            expected=((expected<<1)|enable)&255;
            if(count!==expected[7:0]) $fatal(1,"Count mismatch");
            enable=iteration%7==0;
        end
        $display("LAB_GLS_SMOKE_PASS corner=%s cycles=300",corner);
        $finish;
    end
endmodule
`endif
