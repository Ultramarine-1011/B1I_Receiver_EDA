`timescale 1ns/1ps
module tb_period_reduce;
    logic [63:0] value=0,state=64'hb1a1202611122046;
    logic [31:0] quotient,reference_quotient;
    logic [42:0] remainder,reference_remainder;
    integer checked=0;
    integer digit0,digit1,digit2,digit3;
    logic [63:0] folded_case;
    localparam logic [63:0] PERIOD=64'h7fe00000000;
    b1i_period_reduce dut(.*);
    b1i_period_reference reference(.value(value),.quotient(reference_quotient),.remainder(reference_remainder));
    task automatic check(input logic [63:0] candidate);
        value=candidate;#1;
        if(quotient!==reference_quotient || remainder!==reference_remainder ||
           remainder>=PERIOD || 64'(quotient)*PERIOD+64'(remainder)!==value)
            $fatal(1,"period mismatch value=%h quotient=%h/%h remainder=%h/%h",value,quotient,reference_quotient,remainder,reference_remainder);
        checked++;
    endtask
    initial begin
        check(0);check(1);check(PERIOD-1);check(PERIOD);check(PERIOD+1);check('1);
        for(integer bit_number=0;bit_number<64;bit_number++) begin
            check(64'd1<<bit_number);check((64'd1<<bit_number)-1);check(~(64'd1<<bit_number));
        end
        for(integer digit_sum=0;digit_sum<=3070;digit_sum++) begin
            digit0=digit_sum>1023 ? 1023 : digit_sum;
            digit1=digit_sum-digit0>1023 ? 1023 : digit_sum-digit0;
            digit2=digit_sum-digit0-digit1>1023 ? 1023 : digit_sum-digit0-digit1;
            digit3=digit_sum-digit0-digit1-digit2;
            folded_case=(64'(digit0)|(64'(digit1)<<10)|(64'(digit2)<<20)|(64'(digit3)<<30))<<33;
            check(folded_case);check(folded_case|64'h1ffffffff);
        end
        for(integer n=0;n<200000;n++) begin
            state=state^(state<<13);state=state^(state>>7);state=state^(state<<17);
            check(state);
        end
        $display("PERIOD_REDUCE_PASS cases=%0d unsigned64 quotient32 remainder43 wrap=2046x2pow32",checked);
        $finish;
    end
endmodule
