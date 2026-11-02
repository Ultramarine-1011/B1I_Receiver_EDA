`timescale 1ns/1ps
// Verification-only passive probes; none are configuration/truth inputs.
module six_receiver_probe #(
    parameter integer FIRST_DOPPLER=0,LAST_DOPPLER=0,DOPPLER_STEP=131200,
    parameter integer REFINE_LAG_RADIUS=4,REFINE_FREQUENCY_RADIUS=0
)(
    input logic clk,rst_n,
    input logic [1:0] IF,
    input logic if_valid,
    output logic if_ready,
    input logic cfg_valid,
    input logic [2:0] cfg_channel,
    input logic [5:0] cfg_prn,
    input logic cfg_enable,
    output logic [5:0] capture_ok,bit_sync_ok,nav_data,nav_valid,
    output logic [5:0] locked,active,overflow,
    output logic [63:0] processed
);
    bds_bb_6ch_core #(.FIRST_DOPPLER(FIRST_DOPPLER),.LAST_DOPPLER(LAST_DOPPLER),
        .DOPPLER_STEP(DOPPLER_STEP),.REFINE_LAG_RADIUS(REFINE_LAG_RADIUS),
        .REFINE_FREQUENCY_RADIUS(REFINE_FREQUENCY_RADIUS)) dut(
        .clk(clk),.rst_n(rst_n),.IF(IF),.if_valid(if_valid),.if_ready(if_ready),
        .cfg_valid(cfg_valid),.cfg_channel(cfg_channel),.cfg_prn(cfg_prn),.cfg_enable(cfg_enable),
        .capture_ok(capture_ok),.bit_sync_ok(bit_sync_ok),.nav_data(nav_data),.nav_valid(nav_valid));
    assign locked=dut.locked;
    assign active=dut.active;
    assign overflow=dut.overflow;
    assign processed=dut.sample_count;
    always @(posedge clk) if(rst_n && dut.state==3'd4 && dut.fine_valid && dut.fine_detected && !dut.candidate_consistent)
        $display("SIX_REJECT_HISTORY ch=%0d sample=%0d distance_q32=%0d lag=%0d",dut.search_slot,
            processed,dut.phase_distance,dut.fine_lag);
    for(genvar c=0;c<6;c++) begin: check
        always @(posedge clk) if(rst_n && dut.assign_slot[c])
            $display("SIX_ASSIGN ch=%0d sample=%0d capture_ref=%0d coarse_lag=%0d lag=%0d doppler=%0d",c,
                processed,dut.coarse_ref,dut.coarse_lag,dut.fine_lag,dut.fine_doppler);
        always @(posedge clk) if(rst_n && dut.sample_event && active[c] &&
            processed>=dut.assigned_ref[c] && !dut.release_slot[c] &&
            !dut.channels[c].slot.tracking.frontend.sample_accepted)
            $fatal(1,"Shared IF sample skipped channel=%0d sample=%0d",c,processed);
    end
endmodule
