`timescale 1ns/1ps
// Minimal single-PRN search over a captured 1 ms window. No truth inputs.
// lag is an IF-sample delay: local code[n] = PRN[(n-lag) mod 16368].
module acquisition_serial #(
    parameter integer DETECTION_FACTOR = 16
) (
    input logic clk, reset_n,
    input logic request_valid,
    output logic request_ready,
    input logic [5:0] request_prn,
    input logic [13:0] lag_first, lag_last, lag_step,
    input logic signed [31:0] doppler_first, doppler_last, doppler_step,
    input logic sample_valid,
    output logic sample_ready,
    input logic signed [2:0] sample_data,
    input logic [63:0] sample_ref,
    output logic result_valid,
    input logic result_ready,
    output logic detected,
    output logic [5:0] result_prn,
    output logic [13:0] result_lag,
    output logic signed [31:0] result_doppler,
    output logic [63:0] result_ref, peak_power,
    output logic [31:0] search_cycles,
    output logic cell_valid,
    output logic [13:0] cell_lag,
    output logic signed [31:0] cell_doppler,
    output logic [63:0] cell_power, cell_energy
);
    localparam integer N=16368;
    typedef enum logic [2:0] {IDLE,CAPTURE,INIT,PRIME,REPLAY,EVALUATE,RESULT} state_t;
    state_t state;
    logic signed [2:0] buffer [0:N-1];
    logic [13:0] count, replay_count, current_lag, first_lag, final_lag, delta_lag;
    logic signed [31:0] current_doppler, final_doppler, delta_doppler;
    logic [63:0] window_reference, best_energy;
    logic [31:0] cycles;
    logic first_cell, accepted, code_valid, window_done;
    logic [42:0] initial_code_phase;
    logic signed [27:0] ip,qp;
    logic [41:0] energy;
    logic signed [55:0] ip_square, qp_square;
    logic [63:0] power_now;
    logic [14:0] next_lag;
    logic signed [32:0] next_doppler;
    logic replace_peak, final_cell;

    always_comb begin
        request_ready=reset_n && state==IDLE;
        sample_ready=reset_n && state==CAPTURE;
        initial_code_phase=current_lag==0 ? 43'd0 : (43'(N-int'(current_lag)) << 29);
        ip_square=$signed(ip)*$signed(ip);
        qp_square=$signed(qp)*$signed(qp);
        power_now={8'd0,ip_square}+{8'd0,qp_square};
        next_lag={1'b0,current_lag}+{1'b0,delta_lag};
        next_doppler={current_doppler[31],current_doppler}+{delta_doppler[31],delta_doppler};
        replace_peak=first_cell || power_now>peak_power;
        final_cell=(next_lag>{1'b0,final_lag}) && (next_doppler>{final_doppler[31],final_doppler});
    end
    tracking_frontend #(.ALIGN_FIRST_WINDOW(0)) correlator (
        .clk(clk),.rst_n(reset_n),.init_valid(state==INIT),.init_prn(result_prn),
        .init_code_phase_q(initial_code_phase),.init_code_period_count(32'd0),
        .init_carrier_phase_word(32'd0),.code_step_q(33'h020000000),
        .carrier_step_word(32'h40000000+current_doppler),
        .sample_valid(state==REPLAY),.sample_data(buffer[replay_count]),
        .sample_ref(window_reference+{50'd0,replay_count}),
        .sample_accepted(accepted),.code_valid(code_valid),.init_done(),.code_epoch(),
        .code_phase_q(),.code_period_count(),.carrier_phase_word(),
        .ie(),.qe(),.ip(ip),.qp(qp),.il(),.ql(),.window_done(window_done),
        .window_ref(),.window_energy(energy)
    );
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state<=IDLE; count<=0; replay_count<=0;
            current_lag<=0; first_lag<=0; final_lag<=0; delta_lag<=0;
            current_doppler<=0; final_doppler<=0; delta_doppler<=0;
            window_reference<=0; best_energy<=0; cycles<=0; first_cell<=1;
            result_valid<=0; detected<=0; result_prn<=0; result_lag<=0;
            result_doppler<=0; result_ref<=0; peak_power<=0; search_cycles<=0;
            cell_valid<=0; cell_lag<=0; cell_doppler<=0; cell_power<=0; cell_energy<=0;
        end else begin
            cell_valid<=0;
            if(state!=IDLE && state!=RESULT) cycles<=cycles+1'b1;
            case(state)
                IDLE: if(request_valid && request_ready) begin
                    // Legal search configuration is the caller's contract.
                    result_prn<=request_prn;
                    first_lag<=lag_first; current_lag<=lag_first; final_lag<=lag_last; delta_lag<=lag_step;
                    current_doppler<=doppler_first; final_doppler<=doppler_last; delta_doppler<=doppler_step;
                    count<=0; cycles<=0; first_cell<=1; peak_power<=0; detected<=0;
                    state<=CAPTURE;
                end
                CAPTURE: if(sample_valid && sample_ready) begin
                    buffer[count]<=sample_data;
                    if(count==0) begin window_reference<=sample_ref; result_ref<=sample_ref; end
                    if(count==14'd16367) begin replay_count<=0; state<=INIT; end
                    else count<=count+1'b1;
                end
                INIT: state<=PRIME;
                PRIME: if(code_valid) state<=REPLAY;
                REPLAY: if(accepted) begin
                    if(replay_count==14'd16367) state<=EVALUATE;
                    else replay_count<=replay_count+1'b1;
                end
                EVALUATE: if(window_done) begin
                    cell_valid<=1; cell_lag<=current_lag; cell_doppler<=current_doppler;
                    cell_power<=power_now; cell_energy<={22'd0,energy};
                    if(replace_peak) begin
                        peak_power<=power_now; best_energy<={22'd0,energy};
                        result_lag<=current_lag; result_doppler<=current_doppler;
                    end
                    first_cell<=0;
                    if(final_cell) begin
                        detected<=replace_peak ? power_now>64'(DETECTION_FACTOR)*64'(energy)
                                              : peak_power>64'(DETECTION_FACTOR)*best_energy;
                        search_cycles<=cycles+1'b1; result_valid<=1; state<=RESULT;
                    end else begin
                        if(next_lag>{1'b0,final_lag}) begin
                            current_lag<=first_lag; current_doppler<=next_doppler[31:0];
                        end else current_lag<=next_lag[13:0];
                        replay_count<=0; state<=INIT;
                    end
                end
                RESULT: if(result_valid && result_ready) begin result_valid<=0; state<=IDLE; end
                default: state<=IDLE;
            endcase
        end
    end
endmodule
