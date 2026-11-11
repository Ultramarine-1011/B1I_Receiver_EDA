`timescale 1ns/1ps
// Small-error DLL + Costas PI loop. All feedback is derived from E/P/L only.
// Existing NCO/PRN/mixer/frontend arithmetic remains the 2026-09-28 baseline.
module tracking_channel_minimal #(
    parameter integer ENABLE_FLL=0,ENABLE_CARRIER_AID=0
) (
    input logic clk, reset_n, init_valid,
    input logic [5:0] init_prn,
    input logic [42:0] init_code_phase_q,
    input logic [31:0] init_code_period_count, init_carrier_phase_word,
    input logic signed [31:0] init_doppler_word,
    input logic sample_valid,
    output logic sample_ready,
    input logic signed [2:0] sample_data,
    input logic [63:0] sample_ref,
    output logic [42:0] code_phase_q,
    output logic [31:0] code_period_count, carrier_phase_word,
    output logic [32:0] code_step_q,
    output logic [31:0] carrier_step_word,
    output logic signed [27:0] ie,qe,ip,qp,il,ql,
    output logic window_done,
    output logic [63:0] window_ref,
    output logic [42:0] window_code_phase_q,
    output logic [31:0] window_code_period_count, window_carrier_phase_word,
    output logic [42:0] window_end_code_phase_q,
    output logic [31:0] window_end_code_period_count,
    output logic [32:0] window_end_code_step_q,
    output logic [31:0] window_end_carrier_phase_word,
    output logic [41:0] window_energy,
    output logic feedback_valid, usable, locked,
    output logic fll_active,
    output logic signed [31:0] fll_error_q16,
    output logic signed [31:0] dll_error_q16, pll_error_q16,
    output logic signed [31:0] code_correction_q16, carrier_correction_q16,
    output logic [63:0] feedback_ref
);
    localparam logic signed [63:0] CODE_LIMIT=64'sd1638400; // 25 chip/s Q16
    localparam logic signed [63:0] CARRIER_LIMIT=64'sd655360000; // 10 kHz Q16
    logic code_valid, accepted, enabled;
    logic signed [31:0] base_doppler, code_integral, carrier_integral;
    logic [5:0] good_windows;
    logic [2:0] bad_windows;
    logic [4:0] invalid_run;
    logic [127:0] validity_history;
    logic [7:0] population, seen;
    logic [8:0] population_next;
    logic signed [31:0] code_mean_q16, frequency_mean_q16, previous_phase_q16;
    logic [31:0] phase_mean_square_q32;
    logic previous_phase_valid;
    logic previous_prompt_valid;
    logic signed [27:0] previous_ip,previous_qp;
    logic [63:0] previous_prompt_ref;
    logic signed [63:0] fll_dot,fll_cross,fll_frequency,fll_adjustment;
    logic signed [55:0] ie2,qe2,ip2,qp2,il2,ql2;
    logic [63:0] pe,pp,pl,den_code,abs_i,abs_q;
    logic signed [79:0] code_numerator, phase_numerator;
    logic signed [63:0] dcode, dphase, ci_next, pi_next, code_command, carrier_command;
    logic signed [63:0] code_delta_word, carrier_delta_word;
    logic valid_energy, good_error;
    logic signed [63:0] phase_square, phase_mean_next, code_mean_next, frequency_mean_next;
    function automatic logic signed [63:0] clamp(input logic signed [63:0] value,input logic signed [63:0] limit);
        if(value>limit) clamp=limit;
        else if(value < -limit) clamp=-limit;
        else clamp=value;
    endfunction
    // Vectoring CORDIC, turns Q32 -> Q16. Fold BPSK sign using dot's sign.
    function automatic logic signed [31:0] atan_turn_q16(input logic signed [63:0] dot_value,cross_value);
        logic signed [63:0] x,y,nx,ny,z;
        logic signed [63:0] angle;
        begin
            x=dot_value<0 ? -dot_value : dot_value;y=dot_value<0 ? -cross_value : cross_value;z=0;
            for(integer k=0;k<16;k=k+1) begin
                case(k)
                    0:angle=64'sd536870912;1:angle=64'sd316933406;2:angle=64'sd167458907;
                    3:angle=64'sd85004756;4:angle=64'sd42667331;5:angle=64'sd21354465;
                    6:angle=64'sd10679838;7:angle=64'sd5340245;8:angle=64'sd2670163;
                    9:angle=64'sd1335087;10:angle=64'sd667544;11:angle=64'sd333772;
                    12:angle=64'sd166886;13:angle=64'sd83443;14:angle=64'sd41722;default:angle=64'sd20861;
                endcase
                if(y>0) begin nx=x+(y >>> k);ny=y-(x >>> k);z=z+angle;end
                else if(y<0) begin nx=x-(y >>> k);ny=y+(x >>> k);z=z-angle;end
                else begin nx=x;ny=y;end
                x=nx;y=ny;
            end
            atan_turn_q16=32'(z >>> 16);
        end
    endfunction
    always_comb begin
        sample_ready=reset_n && enabled && code_valid && !init_valid;
        ie2=$signed(ie)*$signed(ie); qe2=$signed(qe)*$signed(qe);
        ip2=$signed(ip)*$signed(ip); qp2=$signed(qp)*$signed(qp);
        il2=$signed(il)*$signed(il); ql2=$signed(ql)*$signed(ql);
        pe={8'd0,ie2}+{8'd0,qe2}; pp={8'd0,ip2}+{8'd0,qp2}; pl={8'd0,il2}+{8'd0,ql2};
        den_code=pe+pl;
        abs_i=ip<0 ? 64'(-64'($signed(ip))) : 64'($signed(ip));
        abs_q=qp<0 ? 64'(-64'($signed(qp))) : 64'($signed(qp));
        code_numerator=(80'($signed(pe))-80'($signed(pl))) <<< 16;
        phase_numerator=80'($signed(qp)) <<< 16;
        if(ip<0) phase_numerator=-phase_numerator;
        dcode=!window_done || den_code==0 ? 64'sd0 : 64'(code_numerator / 80'($signed(den_code)));
        dcode=(dcode*11)/32; // (1-delta)/2, delta=5/16 chip in this wrapper
        dphase=!window_done || (abs_i+abs_q)==0 ? 64'sd0 : 64'(phase_numerator / 80'($signed(abs_i+abs_q)));
        dphase=(dphase*10430) >>> 16; // small-error Costas approximation, turn Q16
        valid_energy=pp > (64'(window_energy)*4) && den_code > (64'(window_energy)*8);
        ci_next=clamp(64'($signed(code_integral))+((dcode*932) >>> 16),CODE_LIMIT);
        fll_dot=64'($signed(previous_ip))*64'($signed(ip))+64'($signed(previous_qp))*64'($signed(qp));
        fll_cross=64'($signed(previous_ip))*64'($signed(qp))-64'($signed(previous_qp))*64'($signed(ip));
        fll_frequency=0;
        if(window_done && ENABLE_FLL!=0)
            fll_frequency=64'($signed(atan_turn_q16(fll_dot,fll_cross)))*1000;
        fll_active=ENABLE_FLL!=0 && seen<128;
        fll_adjustment=0;
        if(fll_active && previous_prompt_valid && valid_energy && window_ref==previous_prompt_ref+16368)
            fll_adjustment=(fll_frequency*3277) >>> 16; // 0.05, measured residual Hz Q16
        pi_next=clamp(64'($signed(carrier_integral))+((dphase*52429) >>> 16)+fll_adjustment,CARRIER_LIMIT);
        code_command=clamp(ci_next+((dcode*349525) >>> 16),CODE_LIMIT);
        carrier_command=clamp(pi_next+dphase*40,CARRIER_LIMIT);
        code_delta_word=(code_command*65536)/16368000;
        carrier_delta_word=(carrier_command*65536)/16368000;
        // Port the 9.28 LockEvidence/TrackingLoops policy: 128-window evidence,
        // smoothed measured errors, 32 good enter / 4 bad exit / 16 invalid exit.
        population_next={1'b0,population}+9'(valid_energy)-9'(validity_history[127]);
        phase_square=dphase*dphase;
        phase_mean_next=$signed({32'd0,phase_mean_square_q32})+(((phase_square-$signed({32'd0,phase_mean_square_q32}))*1311) >>> 16);
        code_mean_next=64'($signed(code_mean_q16))+(((dcode-64'($signed(code_mean_q16)))*1311) >>> 16);
        frequency_mean_next=64'($signed(frequency_mean_q16));
        if(previous_phase_valid)
            frequency_mean_next=frequency_mean_next+(((1000*(dphase-64'($signed(previous_phase_q16)))-frequency_mean_next)*3277) >>> 16);
        good_error=seen==128 && population>=64 && phase_mean_square_q32<32'd10737418
                   && code_mean_q16>-6554 && code_mean_q16<6554
                   && frequency_mean_q16>-655360 && frequency_mean_q16<655360;
    end
    tracking_frontend_spaced #(.EPL_HALF_SPACING_NUMERATOR(5),.EPL_HALF_SPACING_DENOMINATOR(16)) frontend (
        .clk(clk),.rst_n(reset_n),.init_valid(init_valid),.init_prn(init_prn),
        .init_code_phase_q(init_code_phase_q),.init_code_period_count(init_code_period_count),
        .init_carrier_phase_word(init_carrier_phase_word),.code_step_q(code_step_q),.carrier_step_word(carrier_step_word),
        .sample_valid(sample_valid && enabled),.sample_data(sample_data),.sample_ref(sample_ref),
        .sample_accepted(accepted),.code_valid(code_valid),.init_done(),.code_epoch(),
        .code_phase_q(code_phase_q),.code_period_count(code_period_count),.carrier_phase_word(carrier_phase_word),
        .ie(ie),.qe(qe),.ip(ip),.qp(qp),.il(il),.ql(ql),.window_done(window_done),
        .window_ref(window_ref),.window_energy(window_energy)
        ,.window_code_phase_q(window_code_phase_q),.window_code_period_count(window_code_period_count),
        .window_carrier_phase_word(window_carrier_phase_word)
        ,.window_end_code_phase_q(window_end_code_phase_q),
        .window_end_code_period_count(window_end_code_period_count),.window_end_code_step_q(window_end_code_step_q)
        ,.window_end_carrier_phase_word(window_end_carrier_phase_word)
    );
    // Keep the 9.28 source unchanged. At 8 samples/chip, delta=2.5 samples
    // centers the rectangular-code detector's discrete dead zone about zero.
    // The default legacy delta=2 samples has a [0,1)-sample zero-error zone,
    // which drives the PI loop to a biased +1-sample limit cycle from one side.
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            enabled<=0; base_doppler<=0; code_integral<=0; carrier_integral<=0;
            code_step_q<=33'h020000000; carrier_step_word<=32'h40000000;
            previous_prompt_valid<=0;previous_ip<=0;previous_qp<=0;previous_prompt_ref<=0;fll_error_q16<=0;
            feedback_valid<=0; usable<=0; locked<=0; good_windows<=0;
            bad_windows<=0; invalid_run<=0; validity_history<=0; population<=0; seen<=0;
            code_mean_q16<=0; frequency_mean_q16<=0; previous_phase_q16<=0;
            phase_mean_square_q32<=32'd268435456; previous_phase_valid<=0;
            dll_error_q16<=0; pll_error_q16<=0; code_correction_q16<=0;
            carrier_correction_q16<=0; feedback_ref<=0;
        end else if(init_valid) begin
            enabled<=1; base_doppler<=init_doppler_word;
            code_integral<=0; carrier_integral<=0;
            code_step_q<=33'(64'sh20000000+(ENABLE_CARRIER_AID ? 64'($signed(init_doppler_word))/763 : 64'sd0));
            carrier_step_word<=32'h40000000+init_doppler_word;
            previous_prompt_valid<=0;previous_ip<=0;previous_qp<=0;previous_prompt_ref<=0;fll_error_q16<=0;
            feedback_valid<=0; usable<=0; locked<=0; good_windows<=0;
            bad_windows<=0; invalid_run<=0; validity_history<=0; population<=0; seen<=0;
            code_mean_q16<=0; frequency_mean_q16<=0; previous_phase_q16<=0;
            phase_mean_square_q32<=32'd268435456; previous_phase_valid<=0;
            dll_error_q16<=0; pll_error_q16<=0; code_correction_q16<=0;
            carrier_correction_q16<=0; feedback_ref<=0;
        end else begin
            feedback_valid<=0;
            if(window_done) begin
                feedback_valid<=1; usable<=valid_energy;
                previous_prompt_valid<=valid_energy;previous_ip<=ip;previous_qp<=qp;previous_prompt_ref<=window_ref;
                fll_error_q16<=previous_prompt_valid ? fll_frequency[31:0] : 32'd0;
                feedback_ref<=sample_ref;
                dll_error_q16<=dcode[31:0]; pll_error_q16<=dphase[31:0];
                validity_history<={validity_history[126:0],valid_energy};
                population<=population_next[7:0];
                if(seen<128) seen<=seen+1'b1;
                previous_phase_valid<=valid_energy;
                if(valid_energy) invalid_run<=0;
                else if(invalid_run<16) invalid_run<=invalid_run+1'b1;
                if(valid_energy) begin
                    code_integral<=ci_next[31:0]; carrier_integral<=pi_next[31:0];
                    code_correction_q16<=code_command[31:0]; carrier_correction_q16<=carrier_command[31:0];
                    code_step_q<=33'(64'sh20000000+code_delta_word+
                        (ENABLE_CARRIER_AID ? (64'($signed(base_doppler))+carrier_delta_word)/763 : 64'sd0));
                    carrier_step_word<=32'(64'sh40000000+64'($signed(base_doppler))+carrier_delta_word);
                    code_mean_q16<=code_mean_next[31:0]; phase_mean_square_q32<=phase_mean_next[31:0];
                    frequency_mean_q16<=frequency_mean_next[31:0]; previous_phase_q16<=dphase[31:0];
                end
                if(good_error) begin
                    bad_windows<=0;
                    if(good_windows<32) good_windows<=good_windows+1'b1;
                    if(good_windows>=31) locked<=1;
                end else begin
                    good_windows<=0;
                    if(bad_windows<4) bad_windows<=bad_windows+1'b1;
                    if(bad_windows>=3) locked<=0;
                end
                if(!valid_energy && invalid_run>=15) begin locked<=0; good_windows<=0; end
            end
        end
    end
endmodule
