`timescale 1ns/1ps

// Public stream is already LSB-first in time. No byte/pair reversal here.
module stream_unpacker (
    input logic clk, reset_n, enable,
    input logic [31:0] stream_data,
    input logic stream_valid, stream_last,
    input logic [63:0] sample_index,
    output logic stream_ready,
    output logic sample_valid,
    input logic sample_ready,
    output logic [1:0] sample_bits,
    output logic signed [2:0] sample_data,
    output logic [63:0] sample_ref,
    output logic sample_last, input_drained
);
    logic [31:0] word_data;
    logic [63:0] word_ref;
    logic [3:0] lane;
    logic occupied, word_last, last_seen;

    always_comb begin
        stream_ready = reset_n && enable && !occupied && !last_seen;
        sample_valid = reset_n && enable && occupied;
        sample_bits = word_data[2*lane +: 2];
        sample_ref = word_ref + {60'd0, lane};
        sample_last = word_last && lane == 4'd15;
        case (sample_bits)
            2'b00: sample_data = -3'sd3;
            2'b01: sample_data = -3'sd1;
            2'b10: sample_data = 3'sd1;
            2'b11: sample_data = 3'sd3;
            default: sample_data = 3'sd0;
        endcase
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            word_data <= 0;
            word_ref <= 0;
            lane <= 0;
            occupied <= 0;
            word_last <= 0;
            last_seen <= 0;
            input_drained <= 0;
        end else begin
            input_drained <= 0;
            if (stream_valid && stream_ready) begin
                word_data <= stream_data;
                word_ref <= sample_index;
                word_last <= stream_last;
                last_seen <= stream_last;
                lane <= 0;
                occupied <= 1;
            end
            if (sample_valid && sample_ready) begin
                if (lane == 4'd15) begin
                    occupied <= 0;
                    input_drained <= word_last;
                end else lane <= lane + 1'b1;
            end
        end
    end
endmodule
