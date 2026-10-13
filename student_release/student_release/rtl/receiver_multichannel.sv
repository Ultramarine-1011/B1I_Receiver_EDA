`timescale 1ns/1ps
// Parameterized independent slots. Ascending all-PRN search, no scenario identities.
module receiver_multichannel #(
    parameter integer CHANNELS=4,
    parameter integer ENABLE_BACKGROUND=1,REFINE_LAG_RADIUS=16,REFINE_FREQUENCY_RADIUS=5,
    parameter integer SEARCH_FIRST_PRN=6,SEARCH_LAST_PRN=37,
    parameter integer SEARCH_FIRST_DOPPLER=-2624000,SEARCH_LAST_DOPPLER=2624000,SEARCH_DOPPLER_STEP=131200
) (
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
    typedef enum logic [2:0] {BG_IDLE,BG_REQUEST,BG_CAPTURE,BG_SEARCH,BG_REFINE_REQUEST,BG_REFINE,BG_ADVANCE} bg_state_t;
    bg_state_t bg_state;
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
    localparam integer SLOT_WIDTH=CHANNELS>1 ? $clog2(CHANNELS) : 1;
    localparam integer COUNT_WIDTH=$clog2(CHANNELS+1);
    logic [COUNT_WIDTH-1:0] allocated_count;
    logic [2:0] drain_count;
    logic [CHANNELS-1:0] active,slot_ready,slot_valid,slot_take,slot_drained,slot_overflow;
    logic [255:0] slot_data[0:CHANNELS-1];
    logic [CHANNELS-1:0] slot_locked,slot_available,release_event;
    logic [5:0] slot_prn[0:CHANNELS-1];
    logic [7:0] slot_generation[0:CHANNELS-1];
    logic manager_ready,assign_event,duplicate,full,stale,refine_context;
    logic [3:0] assign_slot;
    logic [15:0] search_task;
    logic [15:0] background_capture_count;
    logic [63:0] handover_ref;
    logic [63:0] code_advance,carrier_advance;
    logic [42:0] initial_code_phase;
    logic [31:0] initial_code_epoch;
    logic acq_pending,record_slot,epoch_event,selected_valid;
    logic [255:0] acquisition_payload;
    logic [31:0] epoch_id;
    logic [SLOT_WIDTH-1:0] round_robin,selected_slot,probe_slot;
    always_comb begin
        record_slot=!record_valid || record_ready;
        sample_ready=0;
        if(state==CAPTURE) sample_ready=coarse_sample_ready;
        if(state==RUN) sample_ready=&slot_ready;
        if(state==DISCARD) sample_ready=1;
        coarse_ready=(state==SEARCH && !coarse_detected) || state==ALLOCATE ||
                     (state==REFINE && fine_valid && !fine_detected && !acq_pending) ||
                     (state==RUN && ((bg_state==BG_SEARCH && !coarse_detected) || bg_state==BG_ADVANCE ||
                       (bg_state==BG_REFINE && fine_valid && !fine_detected && !acq_pending)));
        refine_context=state==REFINE || (state==RUN && bg_state==BG_REFINE);
        handover_ref=state==RUN ? processed_samples+64'd4096 : processed_samples;
        code_advance=(64'((16368-int'(fine_lag))%16368)<<29)+(handover_ref-coarse_ref)*
            64'(64'sh20000000+64'($signed(fine_doppler))/763);
        initial_code_phase=43'(code_advance%64'h7fe00000000);
        initial_code_epoch=32'(code_advance/64'h7fe00000000);
        carrier_advance=(handover_ref-coarse_ref)*64'(32'h40000000+fine_doppler);
        epoch_id=32'(sample_ref/64'd16368000);
        epoch_event=state==RUN && sample_valid && sample_ready && sample_ref!=0 && sample_ref%64'd16368000==0;
        selected_valid=0;selected_slot=round_robin;probe_slot=0;
        for(integer k=0;k<CHANNELS;k=k+1) begin
            probe_slot=SLOT_WIDTH'((int'(round_robin)+k)%CHANNELS);
            if(!selected_valid && slot_valid[probe_slot]) begin selected_valid=1;selected_slot=probe_slot;end
        end
        slot_take=0;
        if(record_slot && !acq_pending && selected_valid && state!=END_PENDING && state!=DONE)
            slot_take[selected_slot]=1;
        for(integer c=0;c<CHANNELS;c++)
            slot_available[c]=slot_drained[c] && !(record_valid && record_data[17:14]==4'(c));
    end
    stream_unpacker unpacker(.clk(clk),.reset_n(reset_n),.enable(running),.stream_data(stream_data),
        .stream_valid(stream_valid),.stream_ready(stream_ready),.stream_last(stream_last),.sample_index(sample_index),
        .sample_valid(sample_valid),.sample_ready(sample_ready),.sample_bits(sample_bits),.sample_data(sample_data),
        .sample_ref(sample_ref),.sample_last(sample_last),.input_drained(input_drained));
    acquisition_pcps #(.FIRST_PRN(SEARCH_FIRST_PRN),.LAST_PRN(SEARCH_LAST_PRN),
        .FIRST_DOPPLER(SEARCH_FIRST_DOPPLER),.LAST_DOPPLER(SEARCH_LAST_DOPPLER),.DOPPLER_STEP(SEARCH_DOPPLER_STEP)) acquisition(
        .clk(clk),.reset_n(reset_n),.request(state==REQUEST || (state==RUN && bg_state==BG_REQUEST)),
        .cancel(state==PRIME || state==FLUSH),.sample_ready(coarse_sample_ready),
        .sample_valid(sample_valid && sample_ready && (state==CAPTURE || (state==RUN && bg_state==BG_CAPTURE))),.sample_data(sample_data),.sample_ref(sample_ref),
        .result_valid(coarse_valid),.result_ready(coarse_ready),.detected(coarse_detected),.finished(coarse_finished),
        .result_prn(coarse_prn),.result_lag(coarse_lag),.result_doppler(coarse_doppler),.result_ref(coarse_ref),
        .peak_power(coarse_power),.mean_power(),.search_cycles(coarse_cycles),.replay_address(replay_address),.replay_data(replay_data));
    acquisition_refine #(.LAG_RADIUS(REFINE_LAG_RADIUS),.FREQUENCY_RADIUS(REFINE_FREQUENCY_RADIUS)) refine(
        .clk(clk),.reset_n(reset_n),.request(state==REFINE_REQUEST || (state==RUN && bg_state==BG_REFINE_REQUEST)),.prn(coarse_prn),
        .coarse_lag(coarse_lag),.coarse_doppler(coarse_doppler),.reference_sample(coarse_ref),
        .replay_address(replay_address),.replay_data(replay_data),.result_valid(fine_valid),
        .result_ready(refine_context && manager_ready),.detected(fine_detected),.result_lag(fine_lag),
        .result_doppler(fine_doppler),.peak_power(fine_power),.search_cycles(fine_cycles));
    satellite_manager #(.CHANNELS(CHANNELS)) manager(.clk(clk),.reset_n(reset_n),
        .enable(running && !index_error && state!=FLUSH && state!=END_PENDING && state!=DONE),
        .task_start(state==REQUEST || (state==RUN && bg_state==BG_REQUEST)),
        .task_id(search_task),.task_window_ref(processed_samples),.current_sample(processed_samples),
        .sample_event(state==RUN && sample_valid && sample_ready),.slot_active(active),.slot_locked(slot_locked),
        .slot_available(slot_available),.slot_prn(slot_prn),.slot_generation(slot_generation),
        .candidate_valid(refine_context && fine_valid),.candidate_detected(fine_detected),.result_allow(!acq_pending),
        .candidate_prn(coarse_prn),.candidate_task_id(search_task),.candidate_ref(coarse_ref),
        .candidate_ready(manager_ready),.assign_event(assign_event),.assign_slot(assign_slot),
        .duplicate(duplicate),.full(full),.stale(stale),.release_event(release_event),.ever_locked(),
        .assigned_total(),.released_total(),.rejected_total());
    for(genvar c=0;c<CHANNELS;c=c+1) begin: channels
        receiver_channel #(.CHANNEL_ID(c)) slot(.clk(clk),.reset_n(reset_n),
            .assign_valid(assign_event && assign_slot==4'(c)),.release_valid(release_event[c] || index_error),
            .assign_prn(coarse_prn),.assign_effective_ref(handover_ref),
            .assign_code_phase(initial_code_phase),.assign_code_epoch(initial_code_epoch),
            .assign_carrier_phase(carrier_advance[31:0]),.assign_doppler(fine_doppler),
            .sample_valid(state==RUN && sample_valid && sample_ready),.sample_ready(slot_ready[c]),
            .sample_data(sample_data),.sample_ref(sample_valid ? sample_ref : processed_samples),.epoch_event(epoch_event),.epoch_id(epoch_id),
            .record_valid(slot_valid[c]),.record_ready(slot_take[c]),.record_data(slot_data[c]),
            .drained(slot_drained[c]),.overflow(slot_overflow[c]),.active(active[c]),
            .locked(slot_locked[c]),.nh_valid(),.frame_valid(),.time_valid(),.prn_saved(slot_prn[c]),.generation(slot_generation[c]));
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state<=WAIT_START;running<=0;last_transfer_seen<=0;index_error<=0;
            accepted_samples<=0;processed_samples<=0;hardware_cycles<=0;allocated_count<=0;
            drain_count<=0;round_robin<=0;acq_pending<=0;acquisition_payload<=0;record_valid<=0;record_data<=0;
            bg_state<=BG_IDLE;search_task<=1;background_capture_count<=0;
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
            if(assign_event && state!=RUN) allocated_count<=allocated_count+1'b1;
            if(record_slot && state!=END_PENDING && state!=DONE) begin
                record_valid<=0;
                if(acq_pending) begin record_data<=acquisition_payload;record_valid<=1;acq_pending<=0;end
                else if(selected_valid) begin
                    record_data<=slot_data[selected_slot];record_valid<=1;
                    round_robin<=selected_slot==SLOT_WIDTH'(CHANNELS-1) ? '0 : selected_slot+1'b1;
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
                        if(last_transfer_seen && accepted_samples==processed_samples) begin state<=FLUSH;drain_count<=0;end
                        else state<=PRIME;
                    end
                end
                REFINE_REQUEST: state<=REFINE;
                REFINE: if(fine_valid && manager_ready) begin
                    acquisition_payload<=0;acquisition_payload[7:0]<=8'd5;
                    acquisition_payload[13:8]<=coarse_prn;acquisition_payload[17:14]<=assign_slot;
                    acquisition_payload[18]<=assign_event;acquisition_payload[95:32]<=coarse_ref;
                    acquisition_payload[109:96]<=fine_lag;acquisition_payload[159:128]<=fine_doppler;
                    acquisition_payload[223:160]<=fine_power;acquisition_payload[255:224]<=hardware_cycles[31:0];
                    acq_pending<=1;state<=fine_detected ? ALLOCATE : SEARCH;
                end
                ALLOCATE: begin
                    state<=allocated_count==COUNT_WIDTH'(CHANNELS) ? PRIME : SEARCH;
                end
                PRIME: if(&slot_ready) begin
                    if(last_transfer_seen && accepted_samples==processed_samples) begin state<=FLUSH;drain_count<=0;end
                    else state<=RUN;
                end
                RUN,DISCARD: begin
                    if(sample_valid && sample_ready && sample_last) begin state<=FLUSH;drain_count<=0;end
                    if(state==RUN) case(bg_state)
                        BG_IDLE: if(ENABLE_BACKGROUND!=0 && !(&active) && !last_transfer_seen) begin
                            bg_state<=BG_REQUEST;search_task<=search_task+1'b1;
                        end
                        BG_REQUEST: begin bg_state<=BG_CAPTURE;background_capture_count<=0;end
                        BG_CAPTURE: if(sample_valid && sample_ready) begin
                            background_capture_count<=background_capture_count+1'b1;
                            if(background_capture_count==65471) bg_state<=BG_SEARCH;
                        end
                        BG_SEARCH: begin
                            if(coarse_valid && coarse_detected && !duplicate) bg_state<=BG_REFINE_REQUEST;
                            else if(coarse_valid && coarse_detected && duplicate) bg_state<=BG_ADVANCE;
                            else if(coarse_finished) bg_state<=BG_IDLE;
                        end
                        BG_REFINE_REQUEST: bg_state<=BG_REFINE;
                        BG_REFINE: if(fine_valid && manager_ready) begin
                            acquisition_payload<=0;acquisition_payload[7:0]<=8'd5;
                            acquisition_payload[13:8]<=coarse_prn;acquisition_payload[17:14]<=assign_slot;
                            acquisition_payload[18]<=assign_event;acquisition_payload[95:32]<=coarse_ref;
                            acquisition_payload[109:96]<=fine_lag;acquisition_payload[159:128]<=fine_doppler;
                            acquisition_payload[223:160]<=fine_power;acquisition_payload[255:224]<=hardware_cycles[31:0];
                            acq_pending<=1;bg_state<=BG_ADVANCE;
                        end
                        BG_ADVANCE: bg_state<=BG_SEARCH;
                        default: bg_state<=BG_IDLE;
                    endcase
                end
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
    initial begin
        if(CHANNELS!=1 && CHANNELS!=2 && CHANNELS!=4 && CHANNELS!=12) $fatal(1,"Invalid channel configuration");
        if(SEARCH_FIRST_PRN<6 || SEARCH_LAST_PRN>37 || SEARCH_FIRST_PRN>SEARCH_LAST_PRN ||
           SEARCH_DOPPLER_STEP<=0 || SEARCH_FIRST_DOPPLER>SEARCH_LAST_DOPPLER)
            $fatal(1,"Invalid acquisition configuration");
    end
endmodule
