`timescale 1ns/1ps

// Independent teaching experiment. Input is SIGNED two's complement, not IF2.
// Reuses the frozen PRN RTL unchanged to build one cyclic 2046-chip local table.
// The acquisition path has no source/debug/expected-phase inputs.
module bdi_sliding_capture #(
    parameter logic [25:0] THRESHOLD = 26'd8192
) (
    input  logic clk,
    input  logic rst_n,
    input  logic signed [1:0] if_sample,
    input  logic if_valid,
    output logic ready,
    output logic local_code,
    output logic [10:0] local_code_index,
    output logic [1:0] carrier_phase,
    output logic signed [3:0] local_cos, local_sin,
    output logic signed [5:0] i_product, q_product,
    output logic signed [23:0] i_acc, q_acc,
    output logic signed [23:0] i_result, q_result,
    output logic [25:0] energy,
    output logic dump,
    output logic [13:0] sample_in_window,
    output logic [10:0] candidate_phase, result_phase, captured_phase,
    output logic hit,
    output logic acquired
);
    localparam logic [13:0] LAST_SAMPLE = 14'd16367;
    logic [2045:0] code_table;
    logic prn_chip, prn_configured, unused_prn_epoch;
    logic [10:0] prn_index, next_candidate;
    logic signed [5:0] i_mix, q_mix;
    logic signed [23:0] i_next, q_next;
    logic [24:0] i_magnitude, q_magnitude;
    logic [25:0] metric_next;

    b1i_prn_gen local_prn (
        .clk(clk), .rst_n(rst_n), .load(!prn_configured),
        .chip_enable(prn_configured && !ready), .prn_select(6'd6),
        .chip(prn_chip), .chip_index(prn_index),
        .configured(prn_configured), .epoch(unused_prn_epoch)
    );

    // Extend before negating, including the most-negative 24-bit input.
    function automatic logic [24:0] magnitude(input logic signed [23:0] value);
        logic signed [24:0] extended;
        begin
            extended = {value[23], value};
            magnitude = value[23] ? $unsigned(-extended) : $unsigned(extended);
        end
    endfunction

    always_comb begin
        local_code = ready ? code_table[local_code_index] : 1'b0;
        // Four-phase Fs/4 oscillator, amplitude 7. Initial phase is +pi/2;
        // phase is advanced only AFTER the current accepted input is mixed.
        case (carrier_phase)
            2'd0: begin local_cos =  4'sd7; local_sin =  4'sd0; end
            2'd1: begin local_cos =  4'sd0; local_sin =  4'sd7; end
            2'd2: begin local_cos = -4'sd7; local_sin =  4'sd0; end
            default: begin local_cos = 4'sd0; local_sin = -4'sd7; end
        endcase
        i_mix = $signed(if_sample) * $signed(local_cos);
        q_mix = $signed(if_sample) * $signed(local_sin);
        i_product = 6'sd0;
        q_product = 6'sd0;
        if (ready && if_valid) begin
            i_product = local_code ? -i_mix : i_mix;
            q_product = local_code ? -q_mix : q_mix;
        end
        i_next = i_acc + {{18{i_product[5]}}, i_product};
        q_next = q_acc + {{18{q_product[5]}}, q_product};
        i_magnitude = magnitude(i_next);
        q_magnitude = magnitude(q_next);
        metric_next = {1'b0, i_magnitude} + {1'b0, q_magnitude};
        next_candidate = (candidate_phase == 11'd2045) ? 11'd0
                                                            : candidate_phase + 11'd1;
    end

    // Initialization is complete BEFORE ready asserts. No input sample is
    // consumed during table construction; the TB starts the source on ready.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready <= 1'b0;
        end else if (!ready && prn_configured) begin
            code_table[prn_index] <= prn_chip;
            if (prn_index == 11'd2045) ready <= 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carrier_phase <= 2'd1;
            local_code_index <= 11'd0;
            sample_in_window <= 14'd0;
            candidate_phase <= 11'd0;
            result_phase <= 11'd0;
            captured_phase <= 11'd0;
            i_acc <= 24'sd0;
            q_acc <= 24'sd0;
            i_result <= 24'sd0;
            q_result <= 24'sd0;
            energy <= 26'd0;
            dump <= 1'b0;
            hit <= 1'b0;
            acquired <= 1'b0;
        end else begin
            dump <= 1'b0;
            hit <= 1'b0;
            if (ready && if_valid) begin
                carrier_phase <= carrier_phase + 2'd1;
                if (sample_in_window == LAST_SAMPLE) begin
                    // The same full-window values feed result, energy and
                    // decision. In particular the current final product is IN.
                    i_result <= i_next;
                    q_result <= q_next;
                    energy <= metric_next;
                    result_phase <= candidate_phase;
                    dump <= 1'b1;
                    sample_in_window <= 14'd0;
                    i_acc <= 24'sd0;
                    q_acc <= 24'sd0;
                    if (!acquired && metric_next >= THRESHOLD) begin
                        hit <= 1'b1;
                        acquired <= 1'b1;
                        captured_phase <= candidate_phase;
                        local_code_index <= candidate_phase;
                    end else if (!acquired) begin
                        candidate_phase <= next_candidate;
                        local_code_index <= next_candidate;
                    end else begin
                        // Historical capture is sticky; keep integrating this
                        // phase for independent post-hit peak verification.
                        local_code_index <= candidate_phase;
                    end
                end else begin
                    i_acc <= i_next;
                    q_acc <= q_next;
                    sample_in_window <= sample_in_window + 14'd1;
                    if (sample_in_window[2:0] == 3'd7)
                        local_code_index <= (local_code_index == 11'd2045)
                                            ? 11'd0 : local_code_index + 11'd1;
                end
            end
        end
    end
endmodule
