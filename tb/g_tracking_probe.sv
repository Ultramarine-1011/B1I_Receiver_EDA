`timescale 1ns/1ps
// Loop-only diagnostic. Initial estimates are test configuration, no truth feedback.
module g_tracking_probe(
    input logic clk,reset_n,init_valid,sample_valid,
    input logic signed [2:0] sample_data,
    input logic [63:0] sample_ref,
    input logic signed [31:0] init_doppler_word,
    output logic sample_ready,window_done,locked,usable,
    output logic [63:0] window_ref,
    output logic [42:0] window_end_code_phase_q,
    output logic [31:0] window_end_code_period_count,carrier_step_word,
    output logic signed [27:0] ip,qp
);
    tracking_channel_minimal #(.ENABLE_FLL(1),.ENABLE_CARRIER_AID(1)) dut(
        .clk,.reset_n,.init_valid,.init_prn(6'd6),.init_code_phase_q(43'd0),
        .init_code_period_count(32'd0),.init_carrier_phase_word(32'd0),.init_doppler_word,
        .sample_valid,.sample_ready,.sample_data,.sample_ref,
        .window_done,.window_ref,.window_end_code_phase_q,.window_end_code_period_count,
        .carrier_step_word,.locked,.usable,.ip,.qp,.ie(),.qe(),.il(),.ql(),
        .code_phase_q(),.code_period_count(),.carrier_phase_word(),.code_step_q(),
        .window_code_phase_q(),.window_code_period_count(),.window_carrier_phase_word(),
        .window_end_carrier_phase_word(),.window_end_code_step_q(),.window_energy(),.feedback_valid(),
        .fll_active(),.fll_error_q16(),.dll_error_q16(),.pll_error_q16(),.code_correction_q16(),
        .carrier_correction_q16(),.feedback_ref()
    );
endmodule
