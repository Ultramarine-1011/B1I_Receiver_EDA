`timescale 1ns/1ps
module tb_normalize;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,start=0,done;
    logic [56:0] code_magnitude,code_denominator;
    logic [28:0] phase_magnitude,phase_denominator;
    logic signed [56:0] dot_value,cross_value;
    logic [16:0] code_ratio,phase_ratio,reference_code,reference_phase;
    logic signed [15:0] angle,reference_angle;
    tracking_normalize_iterative dut(.*);
    tracking_ratio_code code_reference(.magnitude(code_magnitude),.denominator(code_denominator),.result(reference_code));
    tracking_ratio_phase phase_reference(.magnitude(phase_magnitude),.denominator(phase_denominator),.result(reference_phase));
    tracking_atan atan_reference(.dot_value(dot_value),.cross_value(cross_value),.result(reference_angle));
    logic [72:0] dividend;
    logic [16:0] integer_code,integer_phase;
    integer n,cycles;
    initial begin
        repeat(3) @(negedge clk);reset_n=1;
        for(n=0;n<20016;n=n+1) begin
            code_denominator={$random,$random} & 57'h1ffffffffffffff;
            code_magnitude=code_denominator==0 ? 0 : ({$random,$random} % code_denominator);
            phase_denominator={$random} & 29'h1fffffff;
            phase_magnitude=phase_denominator==0 ? 0 : ({$random} % phase_denominator);
            dot_value={$random,$random} & 57'h1ffffffffffffff;
            cross_value={$random,$random} & 57'h1ffffffffffffff;
            case(n)
                0: begin code_denominator=0;code_magnitude=0;phase_denominator=0;phase_magnitude=0;dot_value=0;cross_value=0;end
                1: begin code_magnitude=code_denominator;phase_magnitude=phase_denominator;dot_value=-(57'sd1<<55);cross_value=(57'sd1<<55);end
                2: begin code_denominator=1;code_magnitude=1;phase_denominator=1;phase_magnitude=1;dot_value=-(57'sd1<<56);cross_value=-(57'sd1<<56);end
                3: begin code_magnitude=0;phase_magnitude=0;dot_value=0;cross_value=1;end
                4: begin code_denominator=(57'd1<<56);code_magnitude=code_denominator-1;phase_denominator=(29'd1<<28);phase_magnitude=phase_denominator-1;end
                default: begin end
            endcase
            if(n%4==0) begin code_magnitude=code_denominator;phase_magnitude=phase_denominator;end
            dividend={code_magnitude,16'd0};integer_code=code_denominator==0 ? 0 : dividend/code_denominator;
            integer_phase=phase_denominator==0 ? 0 : ({phase_magnitude,16'd0}/phase_denominator);
            start=1;@(negedge clk);start=0;cycles=0;
            while(!done && cycles<20) begin @(negedge clk);cycles=cycles+1;end
            if(cycles!=16 || code_ratio!==reference_code || phase_ratio!==reference_phase ||
                code_ratio!==integer_code || phase_ratio!==integer_phase || angle!==reference_angle)
                $fatal(1,"normalize mismatch n=%0d cycles=%0d code=%h/%h/%h phase=%h/%h/%h angle=%h/%h",
                    n,cycles,code_ratio,reference_code,integer_code,phase_ratio,reference_phase,integer_phase,angle,reference_angle);
        end
        // Reset and re-start in the middle of a pending transaction.
        start=1;@(negedge clk);start=0;repeat(5) @(negedge clk);
        reset_n=0;@(negedge clk);reset_n=1;repeat(20) @(negedge clk);
        if(done || dut.running) $fatal(1,"stale operation survived reset");
        $display("NORMALIZE_ITERATIVE_PASS vectors=20016 latency=16 reset_cancel=1");$finish;
    end
endmodule
