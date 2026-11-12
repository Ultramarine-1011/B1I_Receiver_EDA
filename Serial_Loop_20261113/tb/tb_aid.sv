`timescale 1ns/1ps
module tb_aid;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,start=0,done;
    logic signed [32:0] value;
    logic signed [23:0] result,reference_result;
    integer n,cycles;
    tracking_aid_iterative dut(.*);
    reference_tracking_divide_aid reference_dut(.value(value),.result(reference_result));
    initial begin
        repeat(3) @(negedge clk);reset_n=1;
        for(n=0;n<20016;n=n+1) begin
            value={$random,$random};
            case(n)
                0:value=0;1:value=1;2:value=-1;3:value=763;4:value=-763;
                5:value=(33'sd1<<32);6:value=(33'sd1<<32)-1;
                7:value=(33'sd1<<31);8:value=-(33'sd1<<31);
                default:begin end
            endcase
            start=1;@(negedge clk);start=0;cycles=0;
            while(!done && cycles<20) begin @(negedge clk);cycles=cycles+1;end
            if(cycles!=17 || result!==reference_result || result!==24'(value/33'sd763))
                $fatal(1,"aid mismatch n=%0d value=%0d result=%0d reference=%0d cycles=%0d",n,value,result,reference_result,cycles);
        end
        $display("AID_ITERATIVE_PASS vectors=20016 latency=17 signed33=1");$finish;
    end
endmodule
