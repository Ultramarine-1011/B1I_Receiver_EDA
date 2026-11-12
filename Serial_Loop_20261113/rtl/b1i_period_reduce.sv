`timescale 1ns/1ps
// Exact unsigned quotient/remainder for the B1I code period 2046 * 2^32.
module b1i_period_reduce (
    input logic [63:0] value,
    output logic [31:0] quotient,
    output logic [42:0] remainder
);
    logic [30:0] high_word_half;
    logic [11:0] digit_sum,folded_remainder;
    logic [1:0] quotient_correction;
    assign high_word_half=value[63:33];
    // 1024 == 1 (mod 1023). The sum is at most 3*1023+1.
    assign digit_sum={2'b0,high_word_half[9:0]}+{2'b0,high_word_half[19:10]}+
                     {2'b0,high_word_half[29:20]}+{11'b0,high_word_half[30]};
    always_comb begin
        if(digit_sum>=12'd3069) begin
            quotient_correction=2'd3;
            folded_remainder=digit_sum-12'd3069;
        end else if(digit_sum>=12'd2046) begin
            quotient_correction=2'd2;
            folded_remainder=digit_sum-12'd2046;
        end else if(digit_sum>=12'd1023) begin
            quotient_correction=2'd1;
            folded_remainder=digit_sum-12'd1023;
        end else begin
            quotient_correction=2'd0;
            folded_remainder=digit_sum;
        end
        // x = digit_sum + 1023*(digit1 + 1025*digit2 + 1049601*digit3).
        quotient=32'(high_word_half[19:10])+(32'(high_word_half[29:20])<<10)+
                 32'(high_word_half[29:20])+
                 (high_word_half[30] ? 32'd1049601 : 32'd0)+32'(quotient_correction);
        remainder={folded_remainder[9:0],value[32:0]};
    end
endmodule

module b1i_period_reference (
    input logic [63:0] value,
    output logic [31:0] quotient,
    output logic [42:0] remainder
);
    assign quotient=32'(value/64'h7fe00000000);
    assign remainder=43'(value%64'h7fe00000000);
endmodule
