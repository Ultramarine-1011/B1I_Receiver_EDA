`timescale 1ns/1ps
// Exact signed33 / 763, truncated toward zero, two quotient bits per cycle.
module tracking_aid_iterative(
    input logic clk,reset_n,start,
    input logic signed [32:0] value,
    output logic signed [23:0] result,
    output logic done
);
    logic running,negative;
    logic [4:0] iteration;
    logic [33:0] dividend;
    logic [9:0] remainder_value;
    logic [11:0] trial,next_remainder;
    logic [1:0] digit;
    logic [23:0] quotient,next_quotient;
    always_comb begin
        trial={remainder_value,dividend[33:32]};
        digit=0;next_remainder=trial;
        if(trial>=12'd2289) begin digit=3;next_remainder=trial-12'd2289;end
        else if(trial>=12'd1526) begin digit=2;next_remainder=trial-12'd1526;end
        else if(trial>=12'd763) begin digit=1;next_remainder=trial-12'd763;end
        next_quotient={quotient[21:0],digit};
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            running<=0;negative<=0;iteration<=0;dividend<=0;remainder_value<=0;
            quotient<=0;result<=0;done<=0;
        end else begin
            done<=0;
            if(start) begin
                running<=1;negative<=value[32];iteration<=0;
                dividend<=value[32] ? -34'($signed(value)) : 34'($signed(value));
                remainder_value<=0;quotient<=0;
            end else if(running) begin
                dividend<={dividend[31:0],2'b00};
                remainder_value<=next_remainder[9:0];quotient<=next_quotient;
                if(iteration==16) begin
                    running<=0;done<=1;
                    result<=negative ? -$signed(next_quotient) : $signed(next_quotient);
                end else iteration<=iteration+1'b1;
            end
        end
    end
endmodule
