`timescale 1ns/1ps
// Minimum four-slot receiver. Ascending all-PRN search, no scenario identities.
module receiver_multichannel (
    input logic clk,reset_n,start,
    input logic [31:0] stream_data,
    input logic stream_valid,
    output logic stream_ready,
    input logic stream_last,
    input logic [63:0] sample_index,
    output logic [255:0] record_data,
    output logic record_valid,
    input logic record_ready
);
    typedef enum logic [3:0] {WAIT_START,REQUEST,CAPTURE,SEARCH,REFINE_REQUEST,REFINE,ALLOCATE,
                             PRIME,RUN,DISCARD,FLUSH,END_PENDING,DONE} state_t;
    state_t state;
    logic running,last_transfer_seen,input_drained,index_error;
    logic sample_valid,sample_ready,sample_last;
    logic [1:0] sample_bits;
    logic signed [2:0] sample_data;
    logic [63:0] sample_ref,accepted_samples,processed_samples,hardware_cycles;
    logic coarse_valid,coarse_detected,coarse_finished,coarse_ready,coarse_sample_ready;
    logic [5:0] coarse_prn;
    logic [13:0] coarse_lag,fine_lag;
    logic signed [31:0] coarse_doppler,fine_doppler;
    logic [63:0] coarse_ref,coarse_power,fine_power;
    logic [31:0] coarse_cycles,fine_cycles;
    logic [15:0] replay_address;
    logic signed [2:0] replay_data;
    logic fine_valid,fine_detected;
    logic [2:0] allocated_count,drain_count;
    logic [3:0] active,slot_ready,slot_valid,slot_take,slot_drained,slot_overflow;
    logic [255:0] slot_data[0:3];
    logic [63:0] code_advance,carrier_advance;
    logic [42:0] initial_code_phase;
    logic [31:0] initial_code_epoch;
    logic acq_pending,record_slot,epoch_event,selected_valid;
    logic [255:0] acquisition_payload;
    logic [31:0] epoch_id;
    logic [1:0] round_robin,selected_slot,probe_slot;
    always_comb begin
        record_slot=!record_valid || record_ready;
        sample_ready=0;
        if(state==CAPTURE) sample_ready=coarse_sample_ready;
        if(state==RUN) sample_ready=&slot_ready;
        if(state==DISCARD) sample_ready=1;
        coarse_ready=(state==SEARCH && !coarse_detected) || state==ALLOCATE ||
                     (state==REFINE && fine_valid && !fine_detected && !acq_pending);
        code_advance=(64'((16368-int'(fine_lag))%16368)<<29)+(processed_samples-coarse_ref)*
            64'(64'sh20000000+64'($signed(fine_doppler))/763);
        initial_code_phase=43'(code_advance%64'h7fe00000000);
        initial_code_epoch=32'(code_advance/64'h7fe00000000);
        carrier_advance=(processed_samples-coarse_ref)*64'(32'h40000000+fine_doppler);
        epoch_id=32'(sample_ref/64'd16368000);
        epoch_event=state==RUN && sample_valid && sample_ready && sample_ref!=0 && sample_ref%64'd16368000==0;
        selected_valid=0;selected_slot=round_robin;probe_slot=0;
        for(integer k=0;k<4;k=k+1) begin
            probe_slot=round_robin+2'(k);
            if(!selected_valid && slot_valid[probe_slot]) begin selected_valid=1;selected_slot=probe_slot;end
        end
        slot_take=0;
        if(record_slot && !acq_pending && selected_valid && state!=END_PENDING && state!=DONE)
            slot_take[selected_slot]=1;
    end
    stream_unpacker unpacker(.clk(clk),.reset_n(reset_n),.enable(running),.stream_data(stream_data),
        .stream_valid(stream_valid),.stream_ready(stream_ready),.stream_last(stream_last),.sample_index(sample_index),
        .sample_valid(sample_valid),.sample_ready(sample_ready),.sample_bits(sample_bits),.sample_data(sample_data),
        .sample_ref(sample_ref),.sample_last(sample_last),.input_drained(input_drained));
    acquisition_pcps acquisition(.clk(clk),.reset_n(reset_n),.request(state==REQUEST),
        .cancel(state==PRIME || state==FLUSH),.sample_ready(coarse_sample_ready),
        .sample_valid(sample_valid && state==CAPTURE),.sample_data(sample_data),.sample_ref(sample_ref),
        .result_valid(coarse_valid),.result_ready(coarse_ready),.detected(coarse_detected),.finished(coarse_finished),
        .result_prn(coarse_prn),.result_lag(coarse_lag),.result_doppler(coarse_doppler),.result_ref(coarse_ref),
        .peak_power(coarse_power),.mean_power(),.search_cycles(coarse_cycles),.replay_address(replay_address),.replay_data(replay_data));
    acquisition_refine refine(.clk(clk),.reset_n(reset_n),.request(state==REFINE_REQUEST),.prn(coarse_prn),
        .coarse_lag(coarse_lag),.coarse_doppler(coarse_doppler),.reference_sample(coarse_ref),
        .replay_address(replay_address),.replay_data(replay_data),.result_valid(fine_valid),
        .result_ready(state==REFINE && !acq_pending),.detected(fine_detected),.result_lag(fine_lag),
        .result_doppler(fine_doppler),.peak_power(fine_power),.search_cycles(fine_cycles));
    for(genvar c=0;c<4;c=c+1) begin: channels
        receiver_channel #(.CHANNEL_ID(c)) slot(.clk(clk),.reset_n(reset_n),
            .assign_valid(state==ALLOCATE && allocated_count==3'(c)),.assign_prn(coarse_prn),
            .assign_code_phase(initial_code_phase),.assign_code_epoch(initial_code_epoch),
            .assign_carrier_phase(carrier_advance[31:0]),.assign_doppler(fine_doppler),
            .sample_valid(state==RUN && sample_valid && sample_ready),.sample_ready(slot_ready[c]),
            .sample_data(sample_data),.sample_ref(sample_ref),.epoch_event(epoch_event),.epoch_id(epoch_id),
            .record_valid(slot_valid[c]),.record_ready(slot_take[c]),.record_data(slot_data[c]),
            .drained(slot_drained[c]),.overflow(slot_overflow[c]),.active(active[c]),
            .locked(),.nh_valid(),.frame_valid(),.time_valid(),.prn_saved(),.generation());
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state<=WAIT_START;running<=0;last_transfer_seen<=0;index_error<=0;
            accepted_samples<=0;processed_samples<=0;hardware_cycles<=0;allocated_count<=0;
            drain_count<=0;round_robin<=0;acq_pending<=0;acquisition_payload<=0;record_valid<=0;record_data<=0;
        end else begin
            if(running) hardware_cycles<=hardware_cycles+1'b1;
            if(stream_valid && stream_ready) begin
                accepted_samples<=accepted_samples+16;
                if(stream_last) last_transfer_seen<=1;
                if(sample_index!=accepted_samples) index_error<=1;
            end
            if(sample_valid && sample_ready) begin
                processed_samples<=processed_samples+1'b1;
                if(sample_ref!=processed_samples) index_error<=1;
            end
            if(record_slot && state!=END_PENDING && state!=DONE) begin
                record_valid<=0;
                if(acq_pending) begin record_data<=acquisition_payload;record_valid<=1;acq_pending<=0;end
                else if(selected_valid) begin
                    record_data<=slot_data[selected_slot];record_valid<=1;round_robin<=selected_slot+1'b1;
                end
            end
            case(state)
                WAIT_START: if(start) begin running<=1;state<=REQUEST;end
                REQUEST: state<=CAPTURE;
                CAPTURE: if(sample_valid && sample_ready) begin
                    if(processed_samples==65471) state<=SEARCH;
                    else if(sample_last) begin state<=FLUSH;drain_count<=0;end
                end
                SEARCH: begin
                    if(coarse_valid && coarse_detected) state<=REFINE_REQUEST;
                    else if(coarse_finished) begin
                        if(allocated_count!=0) state<=PRIME;
                        else if(last_transfer_seen && accepted_samples==processed_samples) begin state<=FLUSH;drain_count<=0;end
                        else state<=DISCARD;
                    end
                end
                REFINE_REQUEST: state<=REFINE;
                REFINE: if(fine_valid && !acq_pending) begin
                    acquisition_payload<=0;acquisition_payload[7:0]<=8'd5;
                    acquisition_payload[13:8]<=coarse_prn;acquisition_payload[17:14]<=4'(allocated_count);
                    acquisition_payload[18]<=fine_detected;acquisition_payload[95:32]<=coarse_ref;
                    acquisition_payload[109:96]<=fine_lag;acquisition_payload[159:128]<=fine_doppler;
                    acquisition_payload[223:160]<=fine_power;acquisition_payload[255:224]<=hardware_cycles[31:0];
                    acq_pending<=1;state<=fine_detected ? ALLOCATE : SEARCH;
                end
                ALLOCATE: begin
                    allocated_count<=allocated_count+1'b1;
                    state<=allocated_count==3 ? PRIME : SEARCH;
                end
                PRIME: if(&slot_ready) begin
                    if(last_transfer_seen && accepted_samples==processed_samples) begin state<=FLUSH;drain_count<=0;end
                    else state<=RUN;
                end
                RUN,DISCARD: if(sample_valid && sample_ready && sample_last) begin state<=FLUSH;drain_count<=0;end
                FLUSH: begin
                    if(drain_count<4) drain_count<=drain_count+1'b1;
                    else if(&slot_drained && !acq_pending && !record_valid) begin
                        record_data<=0;record_data[7:0]<=8'd6;record_data[95:32]<=processed_samples;
                        record_data[18]<=index_error;record_data[19]<=|slot_overflow || processed_samples!=accepted_samples;
                        record_data[159:96]<=hardware_cycles;record_valid<=1;state<=END_PENDING;
                    end
                end
                END_PENDING: if(record_valid && record_ready) begin record_valid<=0;running<=0;state<=DONE;end
                DONE: begin end
                default: state<=DONE;
            endcase
        end
    end
endmodule
