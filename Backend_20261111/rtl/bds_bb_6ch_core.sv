`timescale 1ns/1ps
// Six fixed, independently configured slots. Reuses the F bank's channel,
// PCPS and exact-period refinement; no truth/phase initialization ports.
module bds_bb_6ch_core #(
    parameter integer FIRST_DOPPLER=-2624000,LAST_DOPPLER=2624000,DOPPLER_STEP=131200,
    parameter integer REFINE_LAG_RADIUS=16,REFINE_FREQUENCY_RADIUS=5,
    parameter integer PULLIN_SAMPLES=32736000,
    parameter integer REACQUIRE_RADIUS_SAMPLES=16
) (
    input logic clk,rst_n,
    input logic [1:0] IF,
    input logic if_valid,
    output logic if_ready,
    input logic cfg_valid,
    input logic [2:0] cfg_channel,
    input logic [5:0] cfg_prn,
    input logic cfg_enable,
    output logic [5:0] capture_ok,bit_sync_ok,nav_data,nav_valid
);
    typedef enum logic [2:0] {SELECT,REQUEST,COARSE,FINE_REQUEST,FINE,ADVANCE} state_t;
    state_t state;
    logic [2:0] search_slot;
    logic [5:0] enabled,active,ready,locked,ever_locked,release_slot,assign_slot;
    logic [5:0] prns[0:5];
    logic [63:0] assigned_ref[0:5];
    logic [5:0] history_valid;
    logic [42:0] channel_phase[0:5],history_phase[0:5];
    logic [32:0] channel_step[0:5],history_step[0:5];
    logic [63:0] history_ref[0:5];
    logic [63:0] predicted_phase,phase_distance;
    logic candidate_consistent;
    logic [63:0] sample_count,effective_ref,code_advance,carrier_advance;
    logic [42:0] initial_code_phase;
    logic [31:0] initial_code_epoch;
    logic [5:0] sync_valid,bit_valid,bit_data;
    logic [5:0] record_valid,drained,overflow;
    logic [255:0] records[0:5];
    logic signed [2:0] sample_data,replay_data;
    logic sample_event,search_reset_n,search_reconfigured;
    logic coarse_ready,coarse_valid,coarse_detected,coarse_finished;
    logic [5:0] coarse_prn;
    logic [13:0] coarse_lag,fine_lag;
    logic signed [31:0] coarse_doppler,fine_doppler;
    logic [63:0] coarse_ref;
    logic fine_valid,fine_detected;
    logic [15:0] replay_address;
    logic [63:0] predicted_phase_input,phase_distance_input;
    logic [42:0] predicted_phase_remainder,phase_distance_remainder;
    b1i_period_reduce initial_period(.value(code_advance),.quotient(initial_code_epoch),.remainder(initial_code_phase));
    b1i_period_reduce predicted_period(.value(predicted_phase_input),.quotient(),.remainder(predicted_phase_remainder));
    b1i_period_reduce distance_period(.value(phase_distance_input),.quotient(),.remainder(phase_distance_remainder));
    always_comb begin
        if_ready=rst_n && (&ready);
        sample_event=if_valid && if_ready;
        case(IF)
            2'b00: sample_data=-3'sd3;
            2'b01: sample_data=-3'sd1;
            2'b10: sample_data=3'sd1;
            default: sample_data=3'sd3;
        endcase
        // Aborting the selected slot resets both search engines, rejecting all
        // in-flight candidates from the previous configuration.
        search_reconfigured=cfg_valid && cfg_channel==search_slot;
        search_reset_n=rst_n && !search_reconfigured;
        effective_ref=sample_count+64'd4096;
        code_advance=(64'((16368-int'(fine_lag))%16368)<<29)+(effective_ref-coarse_ref)*
            64'(64'sh20000000+64'($signed(fine_doppler))/763);
        carrier_advance=(effective_ref-coarse_ref)*64'(32'h40000000+fine_doppler);
        // Fast reacquisition uses our own last locked NCO, never signal truth.
        // A recent lock excludes distant cross-correlation ghosts during RF loss.
        predicted_phase_input=64'(history_phase[search_slot])+
            (effective_ref-history_ref[search_slot])*64'(history_step[search_slot]);
        predicted_phase=64'(predicted_phase_remainder);
        phase_distance_input=64'(initial_code_phase)+64'h7fe00000000-predicted_phase;
        phase_distance=64'(phase_distance_remainder);
        if(phase_distance>64'h3ff00000000) phase_distance=64'h7fe00000000-phase_distance;
        candidate_consistent=!history_valid[search_slot] ||
            sample_count-history_ref[search_slot]>=64'(PULLIN_SAMPLES) ||
            phase_distance<=(64'(REACQUIRE_RADIUS_SAMPLES)<<29);
        for(integer c=0;c<6;c++) begin
            release_slot[c]=(cfg_valid && cfg_channel==3'(c)) ||
                (active[c] && ((ever_locked[c] && !locked[c]) ||
                (!ever_locked[c] && sample_count>=assigned_ref[c]+64'(PULLIN_SAMPLES))));
            assign_slot[c]=state==FINE && fine_valid && fine_detected && search_slot==3'(c) &&
                enabled[c] && !active[c] && !search_reconfigured && drained[c] && candidate_consistent;
            bit_sync_ok[c]=capture_ok[c] && locked[c] && sync_valid[c] && !release_slot[c];
            nav_valid[c]=bit_sync_ok[c] && bit_valid[c];
            nav_data[c]=bit_data[c];
        end
    end
    acquisition_pcps #(.CONFIGURED_PRN(1),.FIRST_DOPPLER(FIRST_DOPPLER),
        .LAST_DOPPLER(LAST_DOPPLER),.DOPPLER_STEP(DOPPLER_STEP)) acquisition(
        .clk(clk),.reset_n(search_reset_n),.request(state==REQUEST),.cancel(1'b0),
        .request_prn(prns[search_slot]),.sample_ready(coarse_ready),
        .sample_valid(sample_event && coarse_ready),.sample_data(sample_data),.sample_ref(sample_count),
        .result_valid(coarse_valid),.result_ready(state==ADVANCE),.detected(coarse_detected),
        .finished(coarse_finished),.result_prn(coarse_prn),.result_lag(coarse_lag),
        .result_doppler(coarse_doppler),.result_ref(coarse_ref),.peak_power(),.mean_power(),
        .search_cycles(),.replay_address(replay_address),.replay_data(replay_data));
    acquisition_refine #(.LAG_RADIUS(REFINE_LAG_RADIUS),.FREQUENCY_RADIUS(REFINE_FREQUENCY_RADIUS)) refine(
        .clk(clk),.reset_n(search_reset_n),.request(state==FINE_REQUEST),.prn(coarse_prn),
        .coarse_lag(coarse_lag),.coarse_doppler(coarse_doppler),.reference_sample(coarse_ref),
        .replay_address(replay_address),.replay_data(replay_data),.result_valid(fine_valid),
        .result_ready(state==FINE),.detected(fine_detected),.result_lag(fine_lag),
        .result_doppler(fine_doppler),.peak_power(),.search_cycles());
    for(genvar c=0;c<6;c++) begin: channels
        receiver_channel #(.CHANNEL_ID(c),.EXPORT_RECORDS(0)) slot(.clk(clk),.reset_n(rst_n),
            .assign_valid(assign_slot[c]),.release_valid(release_slot[c]),.assign_prn(prns[c]),
            .assign_code_phase(initial_code_phase),.assign_code_epoch(initial_code_epoch),
            .assign_carrier_phase(carrier_advance[31:0]),.assign_doppler(fine_doppler),
            .assign_effective_ref(effective_ref),.sample_valid(sample_event),.sample_ready(ready[c]),
            .sample_data(sample_data),.sample_ref(sample_count),.epoch_event(1'b0),.epoch_id(32'd0),
            .record_valid(record_valid[c]),.record_ready(1'b1),.record_data(records[c]),
            .drained(drained[c]),.overflow(overflow[c]),.active(active[c]),.locked(locked[c]),
            .nh_valid(),.frame_valid(),.time_valid(),.prn_saved(),.generation(),
            .bit_sync_valid(sync_valid[c]),.nav_bit_valid(bit_valid[c]),.nav_bit(bit_data[c]),
            .tracking_code_phase(channel_phase[c]),.tracking_code_step(channel_step[c]));
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sample_count<=0;search_slot<=0;state<=SELECT;enabled<='1;capture_ok<=0;ever_locked<=0;history_valid<=0;
            for(integer c=0;c<6;c++) begin
                prns[c]<=6'(6+c);assigned_ref[c]<=0;history_ref[c]<=0;history_phase[c]<=0;history_step[c]<=0;
            end
        end else begin
            if(sample_event) sample_count<=sample_count+1'b1;
            for(integer c=0;c<6;c++) begin
                if(active[c] && locked[c]) ever_locked[c]<=1;
                if(sample_event && active[c] && locked[c] && !release_slot[c]) begin
                    history_valid[c]<=1;history_phase[c]<=channel_phase[c];
                    history_step[c]<=channel_step[c];history_ref[c]<=sample_count;
                end
                if(assign_slot[c]) begin
                    capture_ok[c]<=1;ever_locked[c]<=0;assigned_ref[c]<=effective_ref;
                end
                if(release_slot[c]) begin capture_ok[c]<=0;ever_locked[c]<=0;end
            end
            if(cfg_valid && cfg_channel<6) begin
                prns[cfg_channel]<=cfg_prn;enabled[cfg_channel]<=cfg_enable;
                history_valid[cfg_channel]<=0;
            end
            if(search_reconfigured) state<=ADVANCE;
            else case(state)
                SELECT: if(enabled[search_slot] && !active[search_slot] && drained[search_slot]) state<=REQUEST;
                        else state<=ADVANCE;
                REQUEST: state<=COARSE;
                COARSE: if(coarse_valid) state<=coarse_detected ? FINE_REQUEST : ADVANCE;
                FINE_REQUEST: state<=FINE;
                FINE: if(fine_valid) state<=ADVANCE;
                ADVANCE: begin search_slot<=search_slot==5 ? 3'd0 : search_slot+1'b1;state<=SELECT;end
                default: state<=SELECT;
            endcase
        end
    end
`ifndef SYNTHESIS
    always @(posedge clk) if(rst_n && cfg_valid &&
        (cfg_channel>=6 || (cfg_enable && (cfg_prn<6 || cfg_prn>37))))
        $fatal(1,"Invalid six-channel configuration");
    initial if(FIRST_DOPPLER>LAST_DOPPLER || DOPPLER_STEP<=0 || PULLIN_SAMPLES<=0 || REACQUIRE_RADIUS_SAMPLES<0)
        $fatal(1,"Invalid six-channel search parameters");
`endif
endmodule
