`timescale 1ns/1ps

// One-phase-parallel sliding correlator for the simplified BDI/B1I source.
// Input samples are the signed 4-bit composite IF samples from the six-star
// teaching source.  The local PRN is selected by SV_ID.
// The local carrier is 4-bit signed and the local PRN chip is exposed as `code`.
module bdi_capture_channel_6sat #(
    parameter int SV_ID = 6,
    parameter int CAPTURE_THRESHOLD = 24'd8192,
    parameter int CAPTURE_SEARCH_START = 0,
    parameter int CAPTURE_SEARCH_STEPS = 2046
) (
    input  logic              clk_16m368,
    input  logic              rst_n,
    input  logic              enable,
    input  logic              if_valid,
    input  logic signed [3:0] if_sample,
    output logic              code,
    output logic              dump,
    output logic              capture,
    output logic              capture_event,
    output logic              capture_rise,
    output logic              handoff_valid,
    output logic [10:0]       handoff_code_phase,
    output logic [31:0]       accepted_sample_count,
    output logic [31:0]       handoff_sample_epoch,
    output logic [15:0]       handoff_ms_count,
    output logic signed [3:0] local_sin,
    output logic signed [3:0] local_cos,
    output logic [10:0]       search_phase,
    output logic [23:0]       metric_debug
);

    import bdi_b1i_prn_pkg::*;

    localparam int CODE_LEN = 2046;
    localparam int SAMPLES_PER_MS = 16368;

    logic [14:0] sample_cnt;
    logic [2:0]  chip_sample_cnt;
    logic [10:0] chip_idx;
    logic [1:0]  carrier_phase;
    logic signed [23:0] i_acc, q_acc;
    logic sample_accept;
    logic [15:0] completed_ms_count;

    logic [11:0] code_index_sum;
    logic [10:0] local_code_index;
    logic signed [3:0] sig4;
    logic signed [7:0] mix_i, mix_q;
    logic signed [23:0] i_next, q_next;
    logic [23:0] abs_i, abs_q;
    logic [24:0] metric_next;

    always_comb begin
        // `if_valid` belongs to the registered source sample.  Only this
        // combined strobe is allowed to advance the integration state.
        sample_accept = enable && if_valid;

        // Search phase is the candidate table start index.  The local code
        // advances through the same 2046-chip cyclic table as the source.
        code_index_sum = search_phase + chip_idx;
        if (code_index_sum >= CODE_LEN)
            local_code_index = code_index_sum - CODE_LEN;
        else
            local_code_index = code_index_sum[10:0];
        code = b1i_code_bit(SV_ID, local_code_index);
        sig4 = if_sample;

        case (carrier_phase)
            2'd0: begin local_cos = 4'sd7;  local_sin = 4'sd0;  end
            2'd1: begin local_cos = 4'sd0;  local_sin = 4'sd7;  end
            2'd2: begin local_cos = -4'sd7; local_sin = 4'sd0;  end
            default: begin local_cos = 4'sd0; local_sin = -4'sd7; end
        endcase

        mix_i = sig4 * local_cos;
        mix_q = sig4 * local_sin;
        if (code) begin
            mix_i = -mix_i;
            mix_q = -mix_q;
        end

        i_next = i_acc + {{16{mix_i[7]}}, mix_i};
        q_next = q_acc + {{16{mix_q[7]}}, mix_q};
        abs_i = i_next[23] ? -i_next : i_next;
        abs_q = q_next[23] ? -q_next : q_next;
        metric_next = abs_i + abs_q;
    end

    initial begin
        if (CAPTURE_THRESHOLD <= 0 || CAPTURE_THRESHOLD >= 24'd1000000)
            $fatal(1, "CAPTURE_THRESHOLD is outside the reference model range");
    end

    always_ff @(posedge clk_16m368 or negedge rst_n) begin
        if (!rst_n) begin
            sample_cnt <= 15'd0;
            chip_sample_cnt <= 3'd0;
            chip_idx <= 11'd0;
            search_phase <= CAPTURE_SEARCH_START[10:0];
            carrier_phase <= 2'd0;
            i_acc <= 24'sd0;
            q_acc <= 24'sd0;
            dump <= 1'b0;
            capture <= 1'b0;
            capture_event <= 1'b0;
            capture_rise <= 1'b0;
            handoff_valid <= 1'b0;
            handoff_code_phase <= 11'd0;
            accepted_sample_count <= 32'd0;
            handoff_sample_epoch <= 32'd0;
            handoff_ms_count <= 16'd0;
            completed_ms_count <= 16'd0;
            metric_debug <= 24'd0;
        end else if (!sample_accept) begin
            dump <= 1'b0;
            capture_event <= 1'b0;
            capture_rise <= 1'b0;
        end else begin
            dump <= 1'b0;
            capture_event <= 1'b0;
            capture_rise <= 1'b0;
            accepted_sample_count <= accepted_sample_count + 32'd1;
            carrier_phase <= carrier_phase + 2'd1;

            if (sample_cnt != SAMPLES_PER_MS-1) begin
                sample_cnt <= sample_cnt + 15'd1;
                i_acc <= i_next;
                q_acc <= q_next;
                if (chip_sample_cnt != 3'd7) begin
                    chip_sample_cnt <= chip_sample_cnt + 3'd1;
                end else begin
                    chip_sample_cnt <= 3'd0;
                    if (chip_idx != CODE_LEN-1) begin
                        chip_idx <= chip_idx + 11'd1;
                    end
                end
            end else begin
                // Include the current sample in the final correlation result.
                sample_cnt <= 15'd0;
                chip_sample_cnt <= 3'd0;
                chip_idx <= 11'd0;
                i_acc <= 24'sd0;
                q_acc <= 24'sd0;
                dump <= 1'b1;
                capture_event <= 1'b1;
                completed_ms_count <= completed_ms_count + 16'd1;
                metric_debug <= metric_next[23:0];

                if (metric_next >= CAPTURE_THRESHOLD) begin
                    capture <= 1'b1;
                    if (!capture) begin
                        capture_rise <= 1'b1;
                        handoff_valid <= 1'b1;
                        handoff_code_phase <= search_phase;
                        handoff_sample_epoch <= accepted_sample_count + 32'd1;
                        handoff_ms_count <= completed_ms_count + 16'd1;
                    end
                end else if (!capture) begin
                    capture <= 1'b0;
                    if (search_phase == CAPTURE_SEARCH_START + CAPTURE_SEARCH_STEPS - 1) begin
                        search_phase <= CAPTURE_SEARCH_START[10:0];
                    end else begin
                        search_phase <= search_phase + 11'd1;
                    end
                end
            end
        end
    end
endmodule
