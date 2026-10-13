`timescale 1ns/1ps
// Single-PRN end-to-end receiver. Search ranges are configuration, never IF truth.
module student_receiver_core #(
    parameter integer SEARCH_PRN=6,
    parameter integer SEARCH_LAG_FIRST=0, SEARCH_LAG_LAST=16364, SEARCH_LAG_STEP=4,
    parameter integer SEARCH_DOPPLER_FIRST=-2624000, SEARCH_DOPPLER_LAST=2624000,
    parameter integer SEARCH_DOPPLER_STEP=131200
) (
    input logic clk, reset_n, start,
    input logic [31:0] stream_data,
    input logic stream_valid,
    output logic stream_ready,
    input logic stream_last,
    input logic [63:0] sample_index,
    output logic [255:0] record_data,
    output logic record_valid,
    input logic record_ready
);
    logic running, input_drained, last_transfer_seen;
    logic sample_valid, sample_ready, sample_last;
    logic [1:0] sample_bits;
    logic signed [2:0] sample_data;
    logic [63:0] sample_ref, accepted_samples, processed_samples, hardware_cycles;
    logic index_error, output_error;
    typedef enum logic [3:0] {WAIT_START,REQUEST,CAPTURE,SEARCH,HANDOFF,PRIME,TRACK,
                             DISCARD,FLUSH,END_PENDING,DONE} state_t;
    state_t state;
    logic acq_ready, acq_sample_ready, acq_result_valid, acq_detected;
    logic [5:0] acq_prn;
    logic [13:0] acq_lag;
    logic signed [31:0] acq_doppler;
    logic [63:0] acq_ref, acq_power;
    logic [31:0] acq_cycles;
    logic track_ready, window_done, locked;
    logic signed [27:0] ip, qp;
    logic [63:0] window_ref;
    logic [42:0] window_code_phase_q;
    logic [31:0] window_code_period_count, window_carrier_phase_word, carrier_step_word;
    logic [63:0] phase_samples, advance_samples, carrier_advance;
    logic [42:0] initial_code_phase;
    logic [31:0] initial_code_period;
    logic [2:0] drain_count;
    logic [255:0] pending_data;
    logic pending_valid;
    logic record_slot;

    assign record_slot=!record_valid || record_ready;
    always_comb begin
        // Pause before new samples whenever either output slot is occupied.
        // Two slots cover the one-cycle mixer and one-cycle window publication.
        sample_ready=0;
        if(state==CAPTURE) sample_ready=acq_sample_ready;
        if(state==TRACK) sample_ready=track_ready && !pending_valid && !record_valid && !window_done;
        if(state==DISCARD) sample_ready=1;
        advance_samples=processed_samples-acq_ref;
        phase_samples=advance_samples+64'((16368-int'(acq_lag))%16368);
        initial_code_phase=43'(phase_samples%64'd16368) << 29;
        initial_code_period=32'(phase_samples/64'd16368);
        carrier_advance=advance_samples*64'(32'h40000000+acq_doppler);
    end
    stream_unpacker unpacker (
        .clk(clk),.reset_n(reset_n),.enable(running),.stream_data(stream_data),
        .stream_valid(stream_valid),.stream_last(stream_last),.sample_index(sample_index),
        .stream_ready(stream_ready),.sample_valid(sample_valid),.sample_ready(sample_ready),
        .sample_bits(sample_bits),.sample_data(sample_data),.sample_ref(sample_ref),
        .sample_last(sample_last),.input_drained(input_drained)
    );
    acquisition_serial acquisition (
        .clk(clk),.reset_n(reset_n),.request_valid(state==REQUEST),.request_ready(acq_ready),
        .request_prn(6'(SEARCH_PRN)),.lag_first(14'(SEARCH_LAG_FIRST)),
        .lag_last(14'(SEARCH_LAG_LAST)),.lag_step(14'(SEARCH_LAG_STEP)),
        .doppler_first(32'(SEARCH_DOPPLER_FIRST)),.doppler_last(32'(SEARCH_DOPPLER_LAST)),
        .doppler_step(32'(SEARCH_DOPPLER_STEP)),
        .sample_valid(sample_valid && state==CAPTURE),.sample_ready(acq_sample_ready),
        .sample_data(sample_data),.sample_ref(sample_ref),.result_valid(acq_result_valid),
        .result_ready(state==SEARCH && !pending_valid),.detected(acq_detected),
        .result_prn(acq_prn),.result_lag(acq_lag),.result_doppler(acq_doppler),
        .result_ref(acq_ref),.peak_power(acq_power),.search_cycles(acq_cycles),
        .cell_valid(),.cell_lag(),.cell_doppler(),.cell_power(),.cell_energy()
    );
    tracking_channel_minimal tracking (
        .clk(clk),.reset_n(reset_n),.init_valid(state==HANDOFF),.init_prn(acq_prn),
        .init_code_phase_q(initial_code_phase),.init_code_period_count(initial_code_period),
        .init_carrier_phase_word(carrier_advance[31:0]),.init_doppler_word(acq_doppler),
        .sample_valid(sample_valid && sample_ready && state==TRACK),.sample_ready(track_ready),
        .sample_data(sample_data),.sample_ref(sample_ref),.code_phase_q(),.code_period_count(),
        .carrier_phase_word(),.code_step_q(),.carrier_step_word(carrier_step_word),
        .ie(),.qe(),.ip(ip),.qp(qp),.il(),.ql(),.window_done(window_done),
        .window_ref(window_ref),.window_code_phase_q(window_code_phase_q),
        .window_code_period_count(window_code_period_count),
        .window_carrier_phase_word(window_carrier_phase_word),.window_energy(),
        .feedback_valid(),.usable(),.locked(locked),.dll_error_q16(),.pll_error_q16(),
        .code_correction_q16(),.carrier_correction_q16(),.feedback_ref()
    );
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state<=WAIT_START; running<=0; last_transfer_seen<=0; accepted_samples<=0; processed_samples<=0;
            hardware_cycles<=0; index_error<=0; output_error<=0; drain_count<=0;
            record_data<=0; record_valid<=0; pending_data<=0; pending_valid<=0;
        end else begin
            if(running) hardware_cycles<=hardware_cycles+1'b1;
            if(stream_valid && stream_ready) begin
                accepted_samples<=accepted_samples+64'd16;
                if(stream_last) last_transfer_seen<=1;
                if(sample_index!=accepted_samples) index_error<=1;
            end
            if(sample_valid && sample_ready) begin
                processed_samples<=processed_samples+1'b1;
                if(sample_ref!=processed_samples) index_error<=1;
            end
            if(record_slot) begin
                record_valid<=pending_valid;
                if(pending_valid) record_data<=pending_data;
                pending_valid<=0;
            end
            if(window_done) begin
                if(pending_valid && !record_slot) output_error<=1;
                pending_data<=0;
                pending_data[7:0]<=8'd1; pending_data[13:8]<=acq_prn;
                pending_data[18]<=locked;
                pending_data[23]<=1; pending_data[31:24]<=8'hc1; // schema3, generation1
                pending_data[95:32]<=window_ref;
                // Q28 -> Q24: arithmetic /16 (negative rounds toward -infinity).
                // Preserves dynamic range; decode values have 1/16 mixer-sum units.
                pending_data[119:96]<=24'($signed(ip) >>> 4);
                pending_data[143:120]<=24'($signed(qp) >>> 4);
                pending_data[175:144]<=carrier_step_word-32'h40000000;
                pending_data[207:176]<=window_carrier_phase_word;
                pending_data[231:208]<=window_code_phase_q[31:8];
                pending_data[242:232]<=window_code_phase_q[42:32];
                pending_data[255:243]<=window_code_period_count[12:0];
                pending_valid<=1;
            end
            case(state)
                WAIT_START: if(start) begin running<=1; state<=REQUEST; end
                REQUEST: if(acq_ready) state<=CAPTURE;
                CAPTURE: if(sample_valid && sample_ready) begin
                    if(processed_samples==64'd16367) state<=SEARCH;
                    else if(sample_last) begin state<=FLUSH; drain_count<=0; end
                end
                SEARCH: if(acq_result_valid && !pending_valid) begin
                    pending_data<=0; pending_data[7:0]<=8'd5;
                    pending_data[13:8]<=acq_prn; pending_data[18]<=acq_detected;
                    pending_data[95:32]<=acq_ref; pending_data[109:96]<=acq_lag;
                    pending_data[159:128]<=acq_doppler; pending_data[223:160]<=acq_power;
                    pending_data[255:224]<=acq_cycles; pending_valid<=1;
                    if(last_transfer_seen && processed_samples==accepted_samples)
                        begin state<=FLUSH; drain_count<=0; end
                    else state<=acq_detected ? HANDOFF : DISCARD;
                end
                HANDOFF: state<=PRIME;
                PRIME: if(track_ready) state<=TRACK;
                TRACK,DISCARD: if(sample_valid && sample_ready && sample_last) begin
                    state<=FLUSH; drain_count<=0;
                end
                FLUSH: begin
                    // No new sample can enter; mixer/correlator are two stages.
                    // Also wait for the event and both output slots to drain.
                    if(drain_count<4) drain_count<=drain_count+1'b1;
                    else if(!window_done && !pending_valid && !record_valid) begin
                        pending_data<=0; pending_data[7:0]<=8'd6;
                        pending_data[95:32]<=processed_samples;
                        pending_data[18]<=index_error;
                        pending_data[19]<=output_error || processed_samples!=accepted_samples;
                        pending_data[159:96]<=hardware_cycles;
                        pending_valid<=1; state<=END_PENDING;
                    end
                end
                END_PENDING: if(record_valid && record_ready && record_data[7:0]==8'd6) begin
                    running<=0; state<=DONE;
                end
                DONE: begin end
                default: state<=DONE;
            endcase
        end
    end
endmodule
