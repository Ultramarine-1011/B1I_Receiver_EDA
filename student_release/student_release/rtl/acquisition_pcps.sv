`timescale 1ns/1ps
// Four real 1ms IF windows. Quarter-IF wipe, /4, padded FFT correlation.
// Outputs candidates from every PRN. Caller must refine padded lag and prove lock.
module acquisition_pcps #(
    parameter integer FIRST_PRN=6, LAST_PRN=37,
    parameter integer FIRST_DOPPLER=-2624000,LAST_DOPPLER=2624000,DOPPLER_STEP=131200,
    parameter integer DETECTION_RATIO=8
) (
    input logic clk,reset_n,request,cancel,
    output logic sample_ready,
    input logic sample_valid,
    input logic signed [2:0] sample_data,
    input logic [63:0] sample_ref,
    output logic result_valid,
    input logic result_ready,
    output logic detected,finished,
    output logic [5:0] result_prn,
    output logic [13:0] result_lag,
    output logic signed [31:0] result_doppler,
    output logic [63:0] result_ref,peak_power,mean_power,
    output logic [31:0] search_cycles,
    // Read-only access to first original IF window for exact-period refinement.
    input logic [15:0] replay_address,
    output logic signed [2:0] replay_data
);
    typedef enum logic [4:0] {IDLE,CAPTURE,CODE_INIT,CODE_PRIME,LOAD_CODE,FFT_CODE,
        WAIT_CODE,STORE_CODE,LOAD_SIGNAL,FFT_SIGNAL,WAIT_SIGNAL,STORE_SIGNAL,
        LOAD_PRODUCT,IFFT_START,IFFT_WAIT,EVALUATE,DECIDE,RESULT,FINISHED} state_t;
    state_t state;
    logic signed [2:0] raw[0:65471];
    logic signed [15:0] base_r[0:16367],base_i[0:16367];
    logic signed [15:0] quarter_r,quarter_i;
    logic [15:0] capture_count;
    logic [12:0] address;
    logic [1:0] window_number;
    logic signed [31:0] code_r[0:4095],code_i[0:4095],signal_r[0:4095],signal_i[0:4095];
    logic signed [31:0] cosine[0:4095],sine[0:4095];
    logic [63:0] accumulated_power[0:4095];
    logic [5:0] prn;
    logic signed [31:0] doppler,best_doppler;
    logic [31:0] mixer_phase,cycles;
    logic [63:0] reference_sample,frequency_peak,frequency_sum,best_peak,best_sum;
    logic [11:0] frequency_lag,best_lag;
    logic code_chip,prn_configured;
    logic load_valid,load_ready,fft_busy,fft_done,fft_start,fft_inverse;
    logic signed [31:0] load_r,load_i,fft_r,fft_i;
    logic signed [63:0] rr,ii,ri,ir,mixed_r,mixed_i;
    logic signed [63:0] square_r,square_i;
    logic [63:0] power_now,total_power;
    logic [13:0] buffer_address;
    logic [11:0] twiddle_address;
    logic signed [31:0] lag_signed;
    assign replay_data=raw[replay_address];
    always_comb begin
        sample_ready=reset_n && state==CAPTURE;
        load_valid=state==LOAD_CODE || state==LOAD_SIGNAL || state==LOAD_PRODUCT;
        fft_start=state==FFT_CODE || state==FFT_SIGNAL || state==IFFT_START;
        fft_inverse=state==IFFT_START;
        buffer_address=14'(int'(window_number)*4092+int'(address));
        twiddle_address=mixer_phase[31:20];
        rr=64'($signed(base_r[buffer_address]))*64'($signed(cosine[twiddle_address]));
        ii=64'($signed(base_i[buffer_address]))*64'($signed(sine[twiddle_address]));
        ri=64'($signed(base_r[buffer_address]))*64'($signed(sine[twiddle_address]));
        ir=64'($signed(base_i[buffer_address]))*64'($signed(cosine[twiddle_address]));
        // Four extra fractional bits prevent /4096 FFT noise-bin truncation.
        mixed_r=((rr+ii)*2048) >>> 30;mixed_i=((ir-ri)*2048) >>> 30;
        load_r=0;load_i=0;
        if(state==LOAD_CODE && address<4092) load_r=code_chip ? -32'sd65536 : 32'sd65536;
        if(state==LOAD_SIGNAL && address<4092) begin load_r=32'(mixed_r);load_i=32'(mixed_i);end
        if(state==LOAD_PRODUCT) begin
            load_r=32'(64'($signed(signal_r[address[11:0]]))*64'($signed(code_r[address[11:0]]))+
                       64'($signed(signal_i[address[11:0]]))*64'($signed(code_i[address[11:0]])));
            load_i=32'(64'($signed(signal_i[address[11:0]]))*64'($signed(code_r[address[11:0]]))-
                       64'($signed(signal_r[address[11:0]]))*64'($signed(code_i[address[11:0]])));
        end
        square_r=$signed(fft_r)*$signed(fft_r);square_i=$signed(fft_i)*$signed(fft_i);
        power_now=64'(square_r)+64'(square_i);
        total_power=window_number==0 ? power_now : accumulated_power[address[11:0]]+power_now;
        lag_signed=best_lag<2048 ? 32'(best_lag)*4 : (32'(best_lag)-4096)*4;
    end
    b1i_prn_gen code_source(.clk(clk),.rst_n(reset_n && !cancel),.load(state==CODE_INIT),
        .chip_enable(state==LOAD_CODE && address<4092 && address[0]),.prn_select(prn),
        .chip(code_chip),.chip_index(),.configured(prn_configured),.epoch());
    fft4096_serial engine(.clk(clk),.reset_n(reset_n && !cancel),.load_valid(load_valid),
        .load_ready(load_ready),.load_address(address[11:0]),.load_real(load_r),.load_imag(load_i),
        .start(fft_start),.inverse(fft_inverse),.busy(fft_busy),.done(fft_done),
        .read_address(address[11:0]),.read_real(fft_r),.read_imag(fft_i));
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state<=IDLE;capture_count<=0;quarter_r<=0;quarter_i<=0;address<=0;window_number<=0;
            prn<=6;doppler<=0;best_doppler<=0;mixer_phase<=0;cycles<=0;reference_sample<=0;
            frequency_peak<=0;frequency_sum<=0;best_peak<=0;best_sum<=0;frequency_lag<=0;best_lag<=0;
            result_valid<=0;detected<=0;finished<=0;result_prn<=0;result_lag<=0;result_doppler<=0;
            result_ref<=0;peak_power<=0;mean_power<=0;search_cycles<=0;
        end else if(cancel) begin state<=FINISHED;result_valid<=0;finished<=1;end
        else begin
            if(state!=IDLE && state!=FINISHED && state!=RESULT) cycles<=cycles+1'b1;
            case(state)
                IDLE: if(request) begin capture_count<=0;cycles<=0;finished<=0;prn<=6'(FIRST_PRN);state<=CAPTURE;end
                CAPTURE: if(sample_valid && sample_ready) begin
                    if(capture_count==0) begin reference_sample<=sample_ref;result_ref<=sample_ref;end
                    raw[capture_count]<=sample_data;
                    case(capture_count[1:0])
                        0: begin quarter_r<=16'($signed(sample_data));quarter_i<=0;end
                        1: quarter_i<=-16'($signed(sample_data));
                        2: quarter_r<=quarter_r-16'($signed(sample_data));
                        3: begin
                            base_r[capture_count[15:2]]<=quarter_r;
                            base_i[capture_count[15:2]]<=quarter_i+16'($signed(sample_data));
                        end
                    endcase
                    if(capture_count==65471) state<=CODE_INIT;
                    else capture_count<=capture_count+1'b1;
                end
                CODE_INIT: begin state<=CODE_PRIME;address<=0;best_peak<=0;best_sum<=0;end
                CODE_PRIME: if(prn_configured) state<=LOAD_CODE;
                LOAD_CODE: if(load_ready) begin
                    if(address==4095) begin address<=0;state<=FFT_CODE;end else address<=address+1'b1;
                end
                FFT_CODE: state<=WAIT_CODE;
                WAIT_CODE: if(fft_done) begin state<=STORE_CODE;address<=0;end
                STORE_CODE: begin
                    code_r[address[11:0]]<=fft_r;code_i[address[11:0]]<=fft_i;
                    if(address==4095) begin
                        state<=LOAD_SIGNAL;address<=0;doppler<=32'(FIRST_DOPPLER);window_number<=0;mixer_phase<=0;
                        frequency_peak<=0;frequency_sum<=0;
                    end else address<=address+1'b1;
                end
                LOAD_SIGNAL: if(load_ready) begin
                    mixer_phase<=mixer_phase+32'(doppler*4);
                    if(address==4095) begin state<=FFT_SIGNAL;address<=0;end else address<=address+1'b1;
                end
                FFT_SIGNAL: state<=WAIT_SIGNAL;
                WAIT_SIGNAL: if(fft_done) begin state<=STORE_SIGNAL;address<=0;end
                STORE_SIGNAL: begin
                    signal_r[address[11:0]]<=fft_r;signal_i[address[11:0]]<=fft_i;
                    if(address==4095) begin state<=LOAD_PRODUCT;address<=0;end else address<=address+1'b1;
                end
                LOAD_PRODUCT: if(load_ready) begin
                    if(address==4095) begin state<=IFFT_START;address<=0;end else address<=address+1'b1;
                end
                IFFT_START: state<=IFFT_WAIT;
                IFFT_WAIT: if(fft_done) begin state<=EVALUATE;address<=0;end
                EVALUATE: begin
                    accumulated_power[address[11:0]]<=total_power;
                    if(window_number==3) begin
                        frequency_sum<=frequency_sum+total_power;
                        if(total_power>frequency_peak) begin frequency_peak<=total_power;frequency_lag<=address[11:0];end
                    end
                    if(address==4095) begin
                        address<=0;mixer_phase<=0;
                        if(window_number==3) state<=DECIDE;
                        else begin window_number<=window_number+1'b1;state<=LOAD_SIGNAL;end
                    end else address<=address+1'b1;
                end
                DECIDE: begin
                    if(frequency_peak>best_peak) begin
                        best_peak<=frequency_peak;best_sum<=frequency_sum;best_lag<=frequency_lag;best_doppler<=doppler;
                    end
                    if(doppler+32'(DOPPLER_STEP)>32'(LAST_DOPPLER)) begin state<=RESULT;result_valid<=0;end
                    else begin
                        doppler<=doppler+32'(DOPPLER_STEP);window_number<=0;address<=0;
                        frequency_peak<=0;frequency_sum<=0;state<=LOAD_SIGNAL;
                    end
                end
                RESULT: if(!result_valid) begin
                    result_valid<=1;result_prn<=prn;result_doppler<=best_doppler;
                    result_lag<=14'(lag_signed<0 ? lag_signed+16368 : lag_signed);
                    peak_power<=best_peak;mean_power<=best_sum>>12;
                    detected<=(best_peak<<12)>best_sum*64'(DETECTION_RATIO);search_cycles<=cycles;
                end else if(result_ready) begin
                    result_valid<=0;
                    if(prn==6'(LAST_PRN)) begin state<=FINISHED;finished<=1;end
                    else begin prn<=prn+1'b1;state<=CODE_INIT;end
                end
                FINISHED: begin end
                default: state<=IDLE;
            endcase
        end
    end
    initial begin $readmemh("rom/fft_cos_q30.mem",cosine);$readmemh("rom/fft_sin_q30.mem",sine);end
endmodule
