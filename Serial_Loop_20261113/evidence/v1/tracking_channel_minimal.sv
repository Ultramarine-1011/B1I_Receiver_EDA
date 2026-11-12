`timescale 1ns/1ps
// Iterative exact feedback. Accepted-sample behavior matches the preserved V6.
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
    logic signed [56:0] fll_dot,fll_cross; // each magnitude <= 2^55 for all 28-bit Prompt values
    logic signed [25:0] fll_frequency; // signed 16-bit turn error times 1000
    logic signed [21:0] fll_adjustment; // signed 26-bit frequency times 3277, arithmetic >> 16
    logic signed [55:0] ie2,qe2,ip2,qp2,il2,ql2;
    logic [63:0] pe,pp,pl,den_code,abs_i,abs_q;
    logic [56:0] code_magnitude;
    logic [28:0] phase_denominator;
    logic [16:0] code_ratio, phase_ratio;
    logic signed [17:0] code_ratio_signed, phase_ratio_signed;
    logic signed [15:0] dcode; // |dcode| <= 65536*11/32 = 22528
    logic signed [14:0] dphase; // -10430 <= floor(raw*10430/65536) <= 10430
    logic signed [21:0] ci_next, code_command; // clamp guarantees +/-1638400
    logic signed [30:0] pi_next, carrier_command; // clamp guarantees +/-655360000
    logic signed [13:0] code_delta_word; // maximum magnitude 6560
    logic signed [22:0] carrier_delta_word; // maximum magnitude 2624002
    logic signed [23:0] initial_aid_word, feedback_aid_word;
    logic valid_energy, good_error;
    logic signed [63:0] phase_square, phase_mean_next, code_mean_next, frequency_mean_next;
    logic [16:0] normalized_code_raw,normalized_phase_raw;
    logic signed [15:0] atan_raw;
    logic signed [23:0] code_delta_full,carrier_delta_full;
    function automatic logic signed [63:0] clamp(input logic signed [63:0] value,input logic signed [63:0] limit);
        if(value>limit) clamp=limit;
        else if(value < -limit) clamp=-limit;
        else clamp=value;
    endfunction
    // Exact signed ceil-reciprocal multiplication, with one negative-result rounding increment.
    // Full-domain bounds and odd-reciprocal proof are in evidence/reciprocal_bounds.json.

    // The same construction covers every signed 33-bit carrier-aid input.


    // Exact floor(2^16 * magnitude / denominator), with 0 <= magnitude <= denominator.
    // This bound follows from |pe-pl| <= pe+pl and |Q| <= |I|+|Q| for ALL 28-bit I/Q.
    // One integer bit and 16 fractional bits suffice, including the exact ratio 1.
    // The loop is combinational and keeps the existing feedback cycle unchanged.

    // Prompt denominator is at most 2^28, so this instance needs only 29-bit remainders.

    // For 16 rotations, max(|x|,|y|) <= 2^55*product(1+2^-k)+80 < 2^58.
    // Sum of all positive angle constants is < 2^31, so z is exact in 32 bits.
    // Vectoring CORDIC, turns Q32 -> Q16. Fold BPSK sign using dot's sign.

    typedef enum logic [2:0] {WAIT_WINDOW, NORMALIZE, CONVERT_CODE,
        CONVERT_CARRIER, CONVERT_AID, COMMIT} feedback_state_t;
    feedback_state_t feedback_state;
    logic math_done;
    logic feedback_commit;
    logic signed [39:0] conversion_input;
    logic signed [23:0] conversion_result, aid_result;
    logic [63:0] pending_feedback_ref;
    assign feedback_commit=feedback_state==COMMIT;
    tracking_normalize_iterative #(.ENABLE_FLL(ENABLE_FLL)) normalize(
        .clk(clk),.reset_n(reset_n && !init_valid),
        .start(window_done && feedback_state==WAIT_WINDOW),
        .code_magnitude(code_magnitude),.code_denominator(den_code[56:0]),
        .phase_magnitude(abs_q[28:0]),.phase_denominator(phase_denominator),
        .dot_value(fll_dot),.cross_value(fll_cross),
        .code_ratio(normalized_code_raw),.phase_ratio(normalized_phase_raw),
        .angle(atan_raw),.done(math_done));
    // One exact conversion multiplier serves both loop commands on separate clocks.
    assign conversion_input=feedback_state==CONVERT_CODE ?
        40'(64'($signed(code_command))*512) : 40'(64'($signed(carrier_command))*512);
    tracking_divide_step conversion(.value(conversion_input),.result(conversion_result));
    // Initialization and feedback never need this conversion simultaneously.
    tracking_divide_aid aid(.value(init_valid ? 33'($signed(init_doppler_word)) :
        33'(64'($signed(base_doppler))+carrier_delta_word)),.result(aid_result));
    assign initial_aid_word=aid_result;
    assign code_delta_word=14'(code_delta_full);
    assign carrier_delta_word=23'(carrier_delta_full);
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            feedback_state<=WAIT_WINDOW;
            code_delta_full<=0;carrier_delta_full<=0;feedback_aid_word<=0;
            pending_feedback_ref<=0;
        end else if(init_valid) begin
            feedback_state<=WAIT_WINDOW;
            code_delta_full<=0;carrier_delta_full<=0;feedback_aid_word<=0;
            pending_feedback_ref<=0;
        end else case(feedback_state)
            WAIT_WINDOW: if(window_done) begin
                pending_feedback_ref<=sample_ref;
                feedback_state<=NORMALIZE;
            end
            NORMALIZE: if(math_done) feedback_state<=CONVERT_CODE;
            CONVERT_CODE: begin code_delta_full<=conversion_result;feedback_state<=CONVERT_CARRIER;end
            CONVERT_CARRIER: begin carrier_delta_full<=conversion_result;feedback_state<=CONVERT_AID;end
            CONVERT_AID: begin feedback_aid_word<=aid_result;feedback_state<=COMMIT;end
            COMMIT: feedback_state<=WAIT_WINDOW;
            default: feedback_state<=WAIT_WINDOW;
        endcase
    end
    always_comb begin
        sample_ready=reset_n && enabled && code_valid && !init_valid &&
            feedback_state==WAIT_WINDOW && !window_done;
        ie2=$signed(ie)*$signed(ie); qe2=$signed(qe)*$signed(qe);
        ip2=$signed(ip)*$signed(ip); qp2=$signed(qp)*$signed(qp);
        il2=$signed(il)*$signed(il); ql2=$signed(ql)*$signed(ql);
        pe={8'd0,ie2}+{8'd0,qe2}; pp={8'd0,ip2}+{8'd0,qp2}; pl={8'd0,il2}+{8'd0,ql2};
        den_code=pe+pl;
        abs_i=ip<0 ? 64'(-64'($signed(ip))) : 64'($signed(ip));
        abs_q=qp<0 ? 64'(-64'($signed(qp))) : 64'($signed(qp));
        // A square is at most 2^54. Each power is at most 2^55 and their sum 2^56.
        code_magnitude=pe>=pl ? pe[56:0]-pl[56:0] : pl[56:0]-pe[56:0];
        phase_denominator=29'(abs_i+abs_q); // <= 2^28, including -2^27 inputs
    end
    always_comb begin
        code_ratio=0;
        phase_ratio=0;
        if(feedback_state!=WAIT_WINDOW) begin
            code_ratio=normalized_code_raw;
            phase_ratio=normalized_phase_raw;
        end
        code_ratio_signed=feedback_state==WAIT_WINDOW ? 18'sd0 : (pe<pl ? -$signed({1'b0,code_ratio}) : $signed({1'b0,code_ratio}));
        dcode=16'((64'($signed(code_ratio_signed))*11)/32); // (1-delta)/2, delta=5/16 chip in this wrapper
        phase_ratio_signed=feedback_state==WAIT_WINDOW ? 18'sd0 : ((qp<0) != (ip<0) ? -$signed({1'b0,phase_ratio}) : $signed({1'b0,phase_ratio}));
        dphase=15'((64'($signed(phase_ratio_signed))*10430) >>> 16); // small-error Costas approximation, turn Q16
        valid_energy=pp > (64'(window_energy)*4) && den_code > (64'(window_energy)*8);
        ci_next=clamp(64'($signed(code_integral))+((dcode*932) >>> 16),CODE_LIMIT);
        fll_dot=64'($signed(previous_ip))*64'($signed(ip))+64'($signed(previous_qp))*64'($signed(qp));
        fll_cross=64'($signed(previous_ip))*64'($signed(qp))-64'($signed(previous_qp))*64'($signed(ip));
    end
    always_comb begin
        fll_frequency=0;
        if(feedback_state!=WAIT_WINDOW && ENABLE_FLL!=0)
            fll_frequency=64'($signed(atan_raw))*1000;
        fll_active=ENABLE_FLL!=0 && seen<128;
        fll_adjustment=0;
        if(fll_active && previous_prompt_valid && valid_energy && window_ref==previous_prompt_ref+16368)
            fll_adjustment=(64'($signed(fll_frequency))*3277) >>> 16; // 0.05, measured residual Hz Q16
        pi_next=clamp(64'($signed(carrier_integral))+((dphase*52429) >>> 16)+fll_adjustment,CARRIER_LIMIT);
        code_command=clamp(ci_next+((dcode*349525) >>> 16),CODE_LIMIT);
        carrier_command=clamp(pi_next+dphase*40,CARRIER_LIMIT);
        // Cancel 2^7 exactly: 65536/16368000 = 512/127875 before the single truncation.
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
        .sample_valid(sample_valid && sample_ready),.sample_data(sample_data),.sample_ref(sample_ref),
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
            code_step_q<=33'(64'sh20000000+(ENABLE_CARRIER_AID ? 64'($signed(initial_aid_word)) : 64'sd0));
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
            if(feedback_commit) begin
                feedback_valid<=1; usable<=valid_energy;
                previous_prompt_valid<=valid_energy;previous_ip<=ip;previous_qp<=qp;previous_prompt_ref<=window_ref;
                fll_error_q16<=previous_prompt_valid ? 32'($signed(fll_frequency)) : 32'd0;
                feedback_ref<=pending_feedback_ref;
                dll_error_q16<=32'($signed(dcode)); pll_error_q16<=32'($signed(dphase));
                validity_history<={validity_history[126:0],valid_energy};
                population<=population_next[7:0];
                if(seen<128) seen<=seen+1'b1;
                previous_phase_valid<=valid_energy;
                if(valid_energy) invalid_run<=0;
                else if(invalid_run<16) invalid_run<=invalid_run+1'b1;
                if(valid_energy) begin
                    code_integral<=32'($signed(ci_next)); carrier_integral<=32'($signed(pi_next));
                    code_correction_q16<=32'($signed(code_command)); carrier_correction_q16<=32'($signed(carrier_command));
                    code_step_q<=33'(64'sh20000000+code_delta_word+
                        (ENABLE_CARRIER_AID ? 64'($signed(feedback_aid_word)) : 64'sd0));
                    carrier_step_word<=32'(64'sh40000000+64'($signed(base_doppler))+carrier_delta_word);
                    code_mean_q16<=code_mean_next[31:0]; phase_mean_square_q32<=phase_mean_next[31:0];
                    frequency_mean_q16<=frequency_mean_next[31:0]; previous_phase_q16<=32'($signed(dphase));
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

`timescale 1ns/1ps
// Sixteen radix-2 fractional division steps and sixteen CORDIC rotations.
// Inputs obey the existing discriminator bounds, magnitude <= denominator.
module tracking_normalize_iterative #(
    parameter integer ENABLE_FLL=1
) (
    input logic clk,reset_n,start,
    input logic [56:0] code_magnitude,code_denominator,
    input logic [28:0] phase_magnitude,phase_denominator,
    input logic signed [56:0] dot_value,cross_value,
    output logic [16:0] code_ratio,phase_ratio,
    output logic signed [15:0] angle,
    output logic done
);
    logic running;
    logic [3:0] iteration;
    logic [56:0] code_remainder,code_divisor;
    logic [28:0] phase_remainder,phase_divisor;
    logic [16:0] code_quotient,phase_quotient;
    logic signed [58:0] code_trial;
    logic signed [30:0] phase_trial;
    logic signed [58:0] x,y,next_x,next_y;
    logic signed [31:0] z,next_z,rotation_angle;
    logic code_bit,phase_bit;
    always_comb begin
        code_trial=$signed({1'b0,code_remainder,1'b0})-$signed({2'b0,code_divisor});
        phase_trial=$signed({1'b0,phase_remainder,1'b0})-$signed({2'b0,phase_divisor});
        code_bit=!code_trial[58] && code_divisor!=0;
        phase_bit=!phase_trial[30] && phase_divisor!=0;
        case(iteration)
            0:rotation_angle=536870912;1:rotation_angle=316933406;2:rotation_angle=167458907;
            3:rotation_angle=85004756;4:rotation_angle=42667331;5:rotation_angle=21354465;
            6:rotation_angle=10679838;7:rotation_angle=5340245;8:rotation_angle=2670163;
            9:rotation_angle=1335087;10:rotation_angle=667544;11:rotation_angle=333772;
            12:rotation_angle=166886;13:rotation_angle=83443;14:rotation_angle=41722;
            default:rotation_angle=20861;
        endcase
        next_x=x;next_y=y;next_z=z;
        if(ENABLE_FLL && y>0) begin
            next_x=x+(y >>> iteration);next_y=y-(x >>> iteration);next_z=z+rotation_angle;
        end else if(ENABLE_FLL && y<0) begin
            next_x=x-(y >>> iteration);next_y=y+(x >>> iteration);next_z=z-rotation_angle;
        end
    end
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            running<=0;iteration<=0;done<=0;
            code_remainder<=0;code_divisor<=0;phase_remainder<=0;phase_divisor<=0;
            code_quotient<=0;phase_quotient<=0;code_ratio<=0;phase_ratio<=0;
            x<=0;y<=0;z<=0;angle<=0;
        end else begin
            done<=0;
            if(start && !running) begin
                running<=1;iteration<=0;
                code_divisor<=code_denominator;phase_divisor<=phase_denominator;
                code_remainder<=code_magnitude==code_denominator ? 57'd0 : code_magnitude;
                phase_remainder<=phase_magnitude==phase_denominator ? 29'd0 : phase_magnitude;
                code_quotient<=17'(code_denominator!=0 && code_magnitude==code_denominator);
                phase_quotient<=17'(phase_denominator!=0 && phase_magnitude==phase_denominator);
                x<=ENABLE_FLL ? (dot_value<0 ? -59'($signed(dot_value)) : 59'($signed(dot_value))) : 59'sd0;
                y<=ENABLE_FLL ? (dot_value<0 ? -59'($signed(cross_value)) : 59'($signed(cross_value))) : 59'sd0;
                z<=0;
            end else if(running) begin
                code_remainder<=code_bit ? code_trial[56:0] : (code_remainder << 1);
                phase_remainder<=phase_bit ? phase_trial[28:0] : (phase_remainder << 1);
                code_quotient<={code_quotient[15:0],code_bit};
                phase_quotient<={phase_quotient[15:0],phase_bit};
                x<=next_x;y<=next_y;z<=next_z;
                if(iteration==15) begin
                    running<=0;done<=1;
                    code_ratio<={code_quotient[15:0],code_bit};
                    phase_ratio<={phase_quotient[15:0],phase_bit};
                    angle<=16'(next_z >>> 16);
                end else iteration<=iteration+1'b1;
            end
        end
    end
endmodule

module tracking_divide_step(input logic signed [39:0] value,output logic signed [23:0] result);
    function automatic logic signed [23:0] divide_step_127875(input logic signed [39:0] value);
        logic signed [80:0] product;
        logic signed [23:0] floor_quotient;
        begin
            product=value*41'sd563500246631;
            floor_quotient=24'(product >>> 56);
            divide_step_127875=floor_quotient+24'(value[39]);
        end
    endfunction
    assign result=divide_step_127875(value);
endmodule

module tracking_divide_aid(input logic signed [32:0] value,output logic signed [23:0] result);
    function automatic logic signed [23:0] divide_aid_763(input logic signed [32:0] value);
        logic signed [66:0] product;
        logic signed [23:0] floor_quotient;
        begin
            product=value*34'sd5764150081;
            floor_quotient=24'(product >>> 42);
            divide_aid_763=floor_quotient+24'(value[32]);
        end
    endfunction
    assign result=divide_aid_763(value);
endmodule
