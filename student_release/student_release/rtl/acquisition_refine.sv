`timescale 1ns/1ps
// Exact 16368-point code correlation, four noncoherent windows, local grid.
// Initial candidate must come from the RTL PCPS detector, no host inputs.
module acquisition_refine (
    input logic clk,reset_n,request,
    input logic [5:0] prn,
    input logic [13:0] coarse_lag,
    input logic signed [31:0] coarse_doppler,
    input logic [63:0] reference_sample,
    output logic [15:0] replay_address,
    input logic signed [2:0] replay_data,
    output logic result_valid,
    input logic result_ready,
    output logic detected,
    output logic [13:0] result_lag,
    output logic signed [31:0] result_doppler,
    output logic [63:0] peak_power,
    output logic [31:0] search_cycles
);
    typedef enum logic [2:0] {IDLE,INIT,PRIME,REPLAY,EVALUATE,RESULT} state_t;
    state_t state;
    logic [5:0] lag_offset;
    logic [3:0] frequency_offset;
    logic [1:0] window_number;
    logic [15:0] sample_number;
    logic [13:0] current_lag;
    logic signed [31:0] current_doppler;
    logic signed [31:0] base_lag,base_doppler;
    logic [63:0] ref_sample,candidate_power,candidate_energy,best_energy;
    logic [31:0] cycles;
    logic [5:0] candidate_prn;
    logic accepted,code_valid,window_done;
    logic signed [27:0] ip,qp;
    logic [41:0] energy;
    logic signed [55:0] ip2,qp2;
    logic [63:0] power_now,power_sum,energy_sum;
    logic [42:0] initial_code_phase;
    always_comb begin
        current_lag=14'((base_lag+32'(lag_offset)+16368)%16368);
        current_doppler=base_doppler+32'(frequency_offset)*13120; // 50Hz FCW steps
        initial_code_phase=43'((16368-int'(current_lag))%16368)<<29;
        replay_address=sample_number;
        ip2=$signed(ip)*$signed(ip);qp2=$signed(qp)*$signed(qp);
        power_now={8'd0,ip2}+{8'd0,qp2};
        power_sum=candidate_power+power_now;energy_sum=candidate_energy+64'(energy);
    end
    tracking_frontend #(.ALIGN_FIRST_WINDOW(0)) correlator(
        .clk(clk),.rst_n(reset_n),.init_valid(state==INIT),.init_prn(candidate_prn),
        .init_code_phase_q(initial_code_phase),.init_code_period_count(32'd0),
        .init_carrier_phase_word(32'd0),.code_step_q(33'h020000000),
        .carrier_step_word(32'h40000000+current_doppler),
        .sample_valid(state==REPLAY),.sample_data(replay_data),.sample_ref(ref_sample+64'(sample_number)),
        .sample_accepted(accepted),.code_valid(code_valid),.init_done(),.code_epoch(),
        .code_phase_q(),.code_period_count(),.carrier_phase_word(),.ie(),.qe(),.ip(ip),.qp(qp),
        .il(),.ql(),.window_done(window_done),.window_ref(),.window_energy(energy));
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state<=IDLE;lag_offset<=0;frequency_offset<=0;window_number<=0;sample_number<=0;
            base_lag<=0;base_doppler<=0;ref_sample<=0;candidate_power<=0;candidate_energy<=0;
            best_energy<=0;cycles<=0;candidate_prn<=0;result_valid<=0;detected<=0;
            result_lag<=0;result_doppler<=0;peak_power<=0;search_cycles<=0;
        end else begin
            if(state!=IDLE && state!=RESULT) cycles<=cycles+1'b1;
            case(state)
                IDLE: if(request) begin
                    candidate_prn<=prn;base_lag<=32'(coarse_lag)-16;base_doppler<=coarse_doppler-65600;
                    ref_sample<=reference_sample;lag_offset<=0;frequency_offset<=0;window_number<=0;
                    sample_number<=0;candidate_power<=0;candidate_energy<=0;peak_power<=0;
                    best_energy<=0;cycles<=0;state<=INIT;
                end
                INIT: state<=PRIME;
                PRIME: if(code_valid) state<=REPLAY;
                REPLAY: if(accepted) begin
                    sample_number<=sample_number+1'b1;
                    if(sample_number==16'(int'(window_number)*16368+16367)) state<=EVALUATE;
                end
                EVALUATE: if(window_done) begin
                    if(window_number!=3) begin
                        candidate_power<=power_sum;candidate_energy<=energy_sum;
                        window_number<=window_number+1'b1;state<=REPLAY;
                    end else begin
                        if(power_sum>peak_power) begin
                            peak_power<=power_sum;best_energy<=energy_sum;
                            result_lag<=current_lag;result_doppler<=current_doppler;
                        end
                        if(lag_offset==32 && frequency_offset==10) begin
                            detected<=power_sum>peak_power ? power_sum>energy_sum*4 : peak_power>best_energy*4;
                            search_cycles<=cycles+1'b1;result_valid<=1;state<=RESULT;
                        end else begin
                            if(lag_offset==32) begin lag_offset<=0;frequency_offset<=frequency_offset+1'b1;end
                            else lag_offset<=lag_offset+1'b1;
                            sample_number<=0;window_number<=0;candidate_power<=0;candidate_energy<=0;state<=INIT;
                        end
                    end
                end
                RESULT: if(result_valid && result_ready) begin result_valid<=0;state<=IDLE;end
                default: state<=IDLE;
            endcase
        end
    end
endmodule
