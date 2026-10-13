`timescale 1ns/1ps
// One reusable assigned channel; all accepted samples are from the common stream.
module receiver_channel #(
    parameter integer CHANNEL_ID=0
) (
    input logic clk,reset_n,assign_valid,
    input logic [5:0] assign_prn,
    input logic [42:0] assign_code_phase,
    input logic [31:0] assign_code_epoch,assign_carrier_phase,
    input logic signed [31:0] assign_doppler,
    input logic sample_valid,
    output logic sample_ready,
    input logic signed [2:0] sample_data,
    input logic [63:0] sample_ref,
    input logic epoch_event,
    input logic [31:0] epoch_id,
    output logic record_valid,
    input logic record_ready,
    output logic [255:0] record_data,
    output logic drained,overflow,
    output logic active,locked,nh_valid,frame_valid,time_valid,
    output logic [5:0] prn_saved,
    output logic [7:0] generation
);
    logic tracker_ready,window_done,feedback_valid,bch_valid,nav_valid,nav_ready;
    logic [42:0] code_phase_q,window_code_phase_q,window_end_code_phase_q;
    logic [31:0] code_period_count,carrier_phase_word,carrier_step_word;
    logic [31:0] window_code_period_count,window_carrier_phase_word,window_end_code_period_count;
    logic [31:0] window_end_carrier_phase_word;
    logic [32:0] window_end_code_step_q;
    logic [63:0] window_ref;
    logic signed [27:0] ip,qp;
    logic [255:0] nav_data,prompt_payload,observation_payload;
    logic [255:0] framed_prompt;
    logic prompt_pending,observation_pending,record_slot;
    logic [19:0] navigation_sow;
    logic [31:0] assigned_epoch,assigned_carrier_phase;
    logic [42:0] assigned_code_phase;
    logic signed [31:0] assigned_doppler;
    assign record_slot=!record_valid || record_ready;
    assign nav_ready=record_slot && !prompt_pending;
    assign sample_ready=!active || (tracker_ready && !prompt_pending && !observation_pending &&
                                    !record_valid && !nav_valid && !window_done);
    assign drained=!window_done && !prompt_pending && !observation_pending && !record_valid && !nav_valid;
    tracking_channel_minimal #(.ENABLE_FLL(1),.ENABLE_CARRIER_AID(1)) tracking(
        .clk(clk),.reset_n(reset_n),.init_valid(assign_valid),
        .init_prn(assign_valid ? assign_prn : prn_saved),
        .init_code_phase_q(assign_valid ? assign_code_phase : assigned_code_phase),
        .init_code_period_count(assign_valid ? assign_code_epoch : assigned_epoch),
        .init_carrier_phase_word(assign_valid ? assign_carrier_phase : assigned_carrier_phase),
        .init_doppler_word(assign_valid ? assign_doppler : assigned_doppler),
        .sample_valid(sample_valid && active),.sample_ready(tracker_ready),.sample_data(sample_data),.sample_ref(sample_ref),
        .code_phase_q(code_phase_q),.code_period_count(code_period_count),.carrier_phase_word(carrier_phase_word),
        .code_step_q(),.carrier_step_word(carrier_step_word),.ie(),.qe(),.ip(ip),.qp(qp),.il(),.ql(),
        .window_done(window_done),.window_ref(window_ref),.window_code_phase_q(window_code_phase_q),
        .window_code_period_count(window_code_period_count),.window_carrier_phase_word(window_carrier_phase_word),
        .window_end_code_phase_q(window_end_code_phase_q),.window_end_code_period_count(window_end_code_period_count),
        .window_end_code_step_q(window_end_code_step_q),.window_energy(),.feedback_valid(feedback_valid),
        .window_end_carrier_phase_word(window_end_carrier_phase_word),
        .usable(),.locked(locked),.fll_active(),.fll_error_q16(),.dll_error_q16(),.pll_error_q16(),
        .code_correction_q16(),.carrier_correction_q16(),.feedback_ref());
    navigation_d1 navigation(.clk(clk),.reset_n(reset_n),.locked(locked),.prompt_valid(window_done),
        .prompt_i(ip),.prompt_ref(window_ref),.prompt_end_ref(window_ref+64'd16368),
        .end_code_phase_q(window_end_code_phase_q),.end_code_period_count(window_end_code_period_count),
        .end_code_step_q(window_end_code_step_q),.prn(prn_saved),.channel(4'(CHANNEL_ID)),.generation(generation),
        .nh_valid(nh_valid),.frame_valid(frame_valid),.time_valid(time_valid),.bch_valid(bch_valid),.nh_phase(),
        .record_valid(nav_valid),.record_ready(nav_ready),.record_data(nav_data));
    tracking_record_framer framer(.event_valid(window_done),.prn(prn_saved),.channel(4'(CHANNEL_ID)),
        .generation(generation),.locked(locked),.nh_valid(nh_valid),.frame_valid(frame_valid),.time_valid(time_valid),
        .ip(ip),.qp(qp),.end_ref(window_ref+64'd16368),.end_code_phase(window_end_code_phase_q),
        .end_code_epoch(window_end_code_period_count),.end_carrier_phase(window_end_carrier_phase_word),
        .carrier_step(carrier_step_word),.end_code_step(window_end_code_step_q),.record_data(framed_prompt));
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            active<=0;prn_saved<=0;generation<=0;assigned_epoch<=0;assigned_carrier_phase<=0;
            assigned_code_phase<=0;assigned_doppler<=0;record_valid<=0;record_data<=0;
            prompt_pending<=0;observation_pending<=0;prompt_payload<=0;observation_payload<=0;
            navigation_sow<=0;overflow<=0;
        end else begin
            if(assign_valid) begin
                active<=1;prn_saved<=assign_prn;generation<=generation+1'b1;
                assigned_epoch<=assign_code_epoch;assigned_carrier_phase<=assign_carrier_phase;
                assigned_code_phase<=assign_code_phase;assigned_doppler<=assign_doppler;
            end
            if(record_slot) begin
                record_valid<=0;
                if(prompt_pending) begin record_data<=prompt_payload;record_valid<=1;prompt_pending<=0;end
                else if(nav_valid) begin
                    record_data<=nav_data;record_valid<=1;navigation_sow<=nav_data[178:159];
                end else if(observation_pending) begin
                    record_data<=observation_payload;record_valid<=1;observation_pending<=0;
                end
            end
            if(window_done) begin
                if(prompt_pending && !(record_slot && prompt_pending)) overflow<=1;
                prompt_payload<=framed_prompt;
                prompt_pending<=1;
            end
            if(epoch_event && active) begin
                if(observation_pending && !(record_slot && !prompt_pending && !nav_valid)) overflow<=1;
                observation_payload<=0;observation_payload[7:0]<=8'd4;observation_payload[13:8]<=prn_saved;
                observation_payload[17:14]<=4'(CHANNEL_ID);observation_payload[18]<=locked;
                observation_payload[19]<=nh_valid;observation_payload[20]<=frame_valid;
                observation_payload[21]<=time_valid;observation_payload[22]<=locked&&nh_valid&&frame_valid&&time_valid&&bch_valid;
                observation_payload[23]<=active;observation_payload[31:24]<=8'd1;
                observation_payload[95:32]<=sample_ref;observation_payload[127:96]<=epoch_id;
                observation_payload[143:128]<={8'd0,generation};observation_payload[159:144]<=code_period_count[15:0];
                observation_payload[170:160]<=code_phase_q[42:32];observation_payload[202:171]<=code_phase_q[31:0];
                observation_payload[234:203]<=carrier_step_word-32'h40000000;
                observation_payload[254:235]<=navigation_sow;observation_payload[255]<=bch_valid;
                observation_pending<=1;
            end
        end
    end
endmodule
