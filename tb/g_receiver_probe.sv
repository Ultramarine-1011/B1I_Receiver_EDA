`timescale 1ns/1ps
// Passive verification wrapper. Teacher top ports and student RTL are unchanged.
module g_receiver_probe #(
    parameter integer CHANNELS=4,NARROW=0
)(
    input logic clk,reset_n,start,
    input logic [31:0] stream_data,
    input logic stream_valid,stream_last,
    input logic [63:0] sample_index,
    output logic stream_ready,
    output logic [255:0] record_data,
    output logic record_valid,
    input logic record_ready,
    output logic [3:0] probe_state,
    output logic [2:0] probe_bg,
    output logic probe_sample_accept,probe_task_start,probe_code_init,
    output logic [5:0] probe_search_prn,probe_result_prn,
    output logic [15:0] probe_task_id,probe_active,probe_locked,
    output logic probe_coarse_valid,probe_coarse_detected,probe_refine_start,
    output logic probe_fine_valid,probe_fine_detected,probe_assign,
    output logic [15:0] probe_release,
    output logic [63:0] probe_processed
);
    receiver_multichannel #(.CHANNELS(CHANNELS),
        .REFINE_LAG_RADIUS(NARROW ? 4 : 16),.REFINE_FREQUENCY_RADIUS(NARROW ? 0 : 5),
        .SEARCH_FIRST_PRN(6),.SEARCH_LAST_PRN(NARROW ? 7 : 37),
        .SEARCH_FIRST_DOPPLER(NARROW ? 0 : -2624000),.SEARCH_LAST_DOPPLER(NARROW ? 0 : 2624000)
    ) dut(.clk,.reset_n,.start,.stream_data,.stream_valid,.stream_ready,.stream_last,.sample_index,.record_data,.record_valid,.record_ready);
    assign probe_state=dut.state;
    assign probe_bg=dut.bg_state;
    assign probe_sample_accept=dut.sample_valid && dut.sample_ready;
    assign probe_task_start=dut.state==4'd1 || (dut.state==4'd8 && dut.bg_state==3'd1);
    assign probe_code_init=dut.acquisition.state==5'd2;
    assign probe_search_prn=dut.acquisition.prn;
    assign probe_result_prn=dut.coarse_prn;
    assign probe_task_id=dut.search_task;
    assign probe_active=16'(dut.active);
    assign probe_locked=16'(dut.slot_locked);
    assign probe_coarse_valid=dut.coarse_valid;
    assign probe_coarse_detected=dut.coarse_detected;
    assign probe_refine_start=dut.state==4'd4 || (dut.state==4'd8 && dut.bg_state==3'd4);
    assign probe_fine_valid=dut.fine_valid && dut.manager_ready;
    assign probe_fine_detected=dut.fine_detected;
    assign probe_assign=dut.assign_event;
    assign probe_release=16'(dut.release_event);
    assign probe_processed=dut.processed_samples;
endmodule
