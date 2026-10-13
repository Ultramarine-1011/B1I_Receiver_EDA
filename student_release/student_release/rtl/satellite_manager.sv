`timescale 1ns/1ps
// Slot ownership decisions only. Candidate events carry a search task/window;
// control tests may inject them, but production events come from RTL acquisition.
module satellite_manager #(
    parameter integer CHANNELS=4,
    parameter logic [63:0] STARTUP_TIMEOUT_SAMPLES=64'd32736000
) (
    input logic clk,reset_n,enable,task_start,
    input logic [15:0] task_id,
    input logic [63:0] task_window_ref,current_sample,
    input logic sample_event,
    input logic [CHANNELS-1:0] slot_active,slot_locked,slot_available,
    input logic [5:0] slot_prn[0:CHANNELS-1],
    input logic [7:0] slot_generation[0:CHANNELS-1],
    input logic candidate_valid,candidate_detected,result_allow,
    input logic [5:0] candidate_prn,
    input logic [15:0] candidate_task_id,
    input logic [63:0] candidate_ref,
    output logic candidate_ready,assign_event,
    output logic [3:0] assign_slot,
    output logic duplicate,full,stale,
    output logic [CHANNELS-1:0] release_event,
    output logic [CHANNELS-1:0] ever_locked,
    output logic [31:0] assigned_total,released_total,rejected_total
);
    logic [15:0] expected_task;
    logic [63:0] window_floor,assigned_ref[0:CHANNELS-1],recovery_floor[0:63];
    logic [CHANNELS-1:0] previous_active;
    logic free_found;
    always_comb begin
        release_event='0;duplicate=0;free_found=0;assign_slot=0;
        for(integer c=0;c<CHANNELS;c++) begin
            if(enable && slot_active[c] &&
               ((ever_locked[c] && !slot_locked[c]) ||
                (!ever_locked[c] && current_sample>=assigned_ref[c] &&
                 current_sample-assigned_ref[c]>=STARTUP_TIMEOUT_SAMPLES))) release_event[c]=1;
            if(slot_active[c] && slot_prn[c]==candidate_prn) duplicate=1;
            // Schema3 Prompt has six generation bits. Retire instead of wrapping.
            if(!free_found && !slot_active[c] && slot_available[c] && slot_generation[c]<63) begin
                free_found=1;assign_slot=4'(c);
            end
        end
        full=!free_found;
        stale=task_start || candidate_task_id!=expected_task || candidate_ref<window_floor ||
              candidate_ref>current_sample || candidate_ref<recovery_floor[candidate_prn] ||
              candidate_prn<6 || candidate_prn>37;
        candidate_ready=enable && result_allow;
        assign_event=candidate_valid && candidate_ready && candidate_detected && !duplicate && !full && !stale && !(|release_event);
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            expected_task<=0;window_floor<=0;previous_active<=0;ever_locked<=0;
            assigned_total<=0;released_total<=0;rejected_total<=0;
            for(integer c=0;c<CHANNELS;c++) assigned_ref[c]<=0;
            for(integer p=0;p<64;p++) recovery_floor[p]<=0;
        end else begin
            previous_active<=slot_active;
            if(task_start) begin expected_task<=task_id;window_floor<=task_window_ref;end
            for(integer c=0;c<CHANNELS;c++) begin
                if(!slot_active[c] || !previous_active[c]) begin
                    ever_locked[c]<=0;assigned_ref[c]<=current_sample;
                end
                if(slot_active[c] && slot_locked[c]) ever_locked[c]<=1;
                if(release_event[c]) begin
                    ever_locked[c]<=0;recovery_floor[slot_prn[c]]<=current_sample;
                end
            end
            if(|release_event) released_total<=released_total+32'($countones(release_event));
            if(assign_event) begin assigned_ref[assign_slot]<=current_sample;assigned_total<=assigned_total+1'b1;end
            if(candidate_valid && candidate_ready && !assign_event) rejected_total<=rejected_total+1'b1;
        end
    end
endmodule
