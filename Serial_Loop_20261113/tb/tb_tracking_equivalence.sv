`timescale 1ns/1ps
module tb_tracking_equivalence;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,init_valid=0,sample_valid=0;
    logic [5:0] init_prn=6;
    logic [42:0] init_code_phase_q=43'h040000000;
    logic [31:0] init_code_period_count=0,init_carrier_phase_word=0;
    logic signed [31:0] init_doppler_word=0;
    logic signed [2:0] sample_data=0;
    logic [63:0] sample_ref=0;
    logic u_sample_ready,v_sample_ready;
    logic [42:0] u_code_phase_q,v_code_phase_q;
    logic [31:0] u_code_period_count,v_code_period_count;
    logic [31:0] u_carrier_phase_word,v_carrier_phase_word;
    logic [32:0] u_code_step_q,v_code_step_q;
    logic [31:0] u_carrier_step_word,v_carrier_step_word;
    logic signed [27:0] u_ie,v_ie;
    logic signed [27:0] u_qe,v_qe;
    logic signed [27:0] u_ip,v_ip;
    logic signed [27:0] u_qp,v_qp;
    logic signed [27:0] u_il,v_il;
    logic signed [27:0] u_ql,v_ql;
    logic u_window_done,v_window_done;
    logic [63:0] u_window_ref,v_window_ref;
    logic [42:0] u_window_code_phase_q,v_window_code_phase_q;
    logic [31:0] u_window_code_period_count,v_window_code_period_count;
    logic [31:0] u_window_carrier_phase_word,v_window_carrier_phase_word;
    logic [42:0] u_window_end_code_phase_q,v_window_end_code_phase_q;
    logic [31:0] u_window_end_code_period_count,v_window_end_code_period_count;
    logic [32:0] u_window_end_code_step_q,v_window_end_code_step_q;
    logic [31:0] u_window_end_carrier_phase_word,v_window_end_carrier_phase_word;
    logic [41:0] u_window_energy,v_window_energy;
    logic u_feedback_valid,v_feedback_valid;
    logic u_usable,v_usable;
    logic u_locked,v_locked;
    logic u_fll_active,v_fll_active;
    logic signed [31:0] u_fll_error_q16,v_fll_error_q16;
    logic signed [31:0] u_dll_error_q16,v_dll_error_q16;
    logic signed [31:0] u_pll_error_q16,v_pll_error_q16;
    logic signed [31:0] u_code_correction_q16,v_code_correction_q16;
    logic signed [31:0] u_carrier_correction_q16,v_carrier_correction_q16;
    logic [63:0] u_feedback_ref,v_feedback_ref;
    tracking_channel_minimal #(.ENABLE_FLL(1),.ENABLE_CARRIER_AID(1)) dut(
        .clk(clk),
        .reset_n(reset_n),
        .init_valid(init_valid),
        .init_prn(init_prn),
        .init_code_phase_q(init_code_phase_q),
        .init_code_period_count(init_code_period_count),
        .init_carrier_phase_word(init_carrier_phase_word),
        .init_doppler_word(init_doppler_word),
        .sample_valid(sample_valid),
        .sample_data(sample_data),
        .sample_ref(sample_ref),
        .sample_ready(u_sample_ready),
        .code_phase_q(u_code_phase_q),
        .code_period_count(u_code_period_count),
        .carrier_phase_word(u_carrier_phase_word),
        .code_step_q(u_code_step_q),
        .carrier_step_word(u_carrier_step_word),
        .ie(u_ie),
        .qe(u_qe),
        .ip(u_ip),
        .qp(u_qp),
        .il(u_il),
        .ql(u_ql),
        .window_done(u_window_done),
        .window_ref(u_window_ref),
        .window_code_phase_q(u_window_code_phase_q),
        .window_code_period_count(u_window_code_period_count),
        .window_carrier_phase_word(u_window_carrier_phase_word),
        .window_end_code_phase_q(u_window_end_code_phase_q),
        .window_end_code_period_count(u_window_end_code_period_count),
        .window_end_code_step_q(u_window_end_code_step_q),
        .window_end_carrier_phase_word(u_window_end_carrier_phase_word),
        .window_energy(u_window_energy),
        .feedback_valid(u_feedback_valid),
        .usable(u_usable),
        .locked(u_locked),
        .fll_active(u_fll_active),
        .fll_error_q16(u_fll_error_q16),
        .dll_error_q16(u_dll_error_q16),
        .pll_error_q16(u_pll_error_q16),
        .code_correction_q16(u_code_correction_q16),
        .carrier_correction_q16(u_carrier_correction_q16),
        .feedback_ref(u_feedback_ref));
    reference_tracking_channel_minimal #(.ENABLE_FLL(1),.ENABLE_CARRIER_AID(1)) reference_dut(
        .clk(clk),
        .reset_n(reset_n),
        .init_valid(init_valid),
        .init_prn(init_prn),
        .init_code_phase_q(init_code_phase_q),
        .init_code_period_count(init_code_period_count),
        .init_carrier_phase_word(init_carrier_phase_word),
        .init_doppler_word(init_doppler_word),
        .sample_valid(sample_valid),
        .sample_data(sample_data),
        .sample_ref(sample_ref),
        .sample_ready(v_sample_ready),
        .code_phase_q(v_code_phase_q),
        .code_period_count(v_code_period_count),
        .carrier_phase_word(v_carrier_phase_word),
        .code_step_q(v_code_step_q),
        .carrier_step_word(v_carrier_step_word),
        .ie(v_ie),
        .qe(v_qe),
        .ip(v_ip),
        .qp(v_qp),
        .il(v_il),
        .ql(v_ql),
        .window_done(v_window_done),
        .window_ref(v_window_ref),
        .window_code_phase_q(v_window_code_phase_q),
        .window_code_period_count(v_window_code_period_count),
        .window_carrier_phase_word(v_window_carrier_phase_word),
        .window_end_code_phase_q(v_window_end_code_phase_q),
        .window_end_code_period_count(v_window_end_code_period_count),
        .window_end_code_step_q(v_window_end_code_step_q),
        .window_end_carrier_phase_word(v_window_end_carrier_phase_word),
        .window_energy(v_window_energy),
        .feedback_valid(v_feedback_valid),
        .usable(v_usable),
        .locked(v_locked),
        .fll_active(v_fll_active),
        .fll_error_q16(v_fll_error_q16),
        .dll_error_q16(v_dll_error_q16),
        .pll_error_q16(v_pll_error_q16),
        .code_correction_q16(v_code_correction_q16),
        .carrier_correction_q16(v_carrier_correction_q16),
        .feedback_ref(v_feedback_ref));
    logic prn[0:2045];
    integer n,scenario,stalls=0,feedbacks=0,accepted=0,max_stall=0,run_stall=0;
    real analog,hz,phase;
    integer sign_code,nh_sign;
    always @(negedge clk) if(reset_n && !init_valid) begin
        if(u_feedback_valid) begin
            feedbacks=feedbacks+1;
            if({u_usable,u_locked,u_dll_error_q16,u_pll_error_q16,u_code_correction_q16,u_carrier_correction_q16,u_fll_error_q16,u_feedback_ref} !== {v_usable,v_locked,v_dll_error_q16,v_pll_error_q16,v_code_correction_q16,v_carrier_correction_q16,v_fll_error_q16,v_feedback_ref})
                $fatal(1,"feedback mismatch sample=%0d dll=%0d/%0d pll=%0d/%0d code=%0d/%0d carrier=%0d/%0d ref=%0d/%0d",
                    sample_ref,u_dll_error_q16,v_dll_error_q16,u_pll_error_q16,v_pll_error_q16,
                    u_code_correction_q16,v_code_correction_q16,u_carrier_correction_q16,v_carrier_correction_q16,
                    u_feedback_ref,v_feedback_ref);
        end
    end
    always @(posedge clk) if(reset_n && sample_valid) begin
        if(!u_sample_ready || !v_sample_ready) $fatal(1,"testbench violated handshake");
        if({u_code_phase_q,u_code_period_count,u_carrier_phase_word,u_code_step_q,u_carrier_step_word,u_ie,u_qe,u_ip,u_qp,u_il,u_ql,u_window_ref,u_window_energy} !== {v_code_phase_q,v_code_period_count,v_carrier_phase_word,v_code_step_q,v_carrier_step_word,v_ie,v_qe,v_ip,v_qp,v_il,v_ql,v_window_ref,v_window_energy})
            $fatal(1,"accepted-sample state mismatch sample=%0d code=%h/%h carrier=%h/%h",
                sample_ref,u_code_step_q,v_code_step_q,u_carrier_step_word,v_carrier_step_word);
        accepted=accepted+1;
    end
    initial begin
        $readmemh("../tb/b1i_prn_06.mem",prn);
        repeat(4) @(negedge clk);reset_n=1;
        // Cover the full signed32 initialization domain before accepting samples.
        for(n=0;n<40;n=n+1) begin
            init_valid=1;
            init_doppler_word=n==0 ? 32'sh80000000 : n==1 ? 32'sh7fffffff : $random;
            @(negedge clk);init_valid=0;
            while(!u_sample_ready || !v_sample_ready) @(negedge clk);
            if(u_code_step_q!==v_code_step_q || u_carrier_step_word!==v_carrier_step_word)
                $fatal(1,"initial aid mismatch value=%0d",init_doppler_word);
        end
        for(scenario=0;scenario<2;scenario=scenario+1) begin
            @(negedge clk);sample_valid=0;init_valid=1;
            init_code_phase_q=scenario==0 ? 43'h040000000 : (43'd2046<<32)-43'h040000000;
            init_doppler_word=scenario==0 ? 32'sd32000 : -32'sd32000;
            hz=scenario==0 ? 125.0 : -125.0;phase=scenario==0 ? 0.13 : -0.13;
            @(negedge clk);init_valid=0;
            for(n=0;n<16368000;n=n+1) begin
                sample_valid=0;
                run_stall=0;
                while(!u_sample_ready || !v_sample_ready) begin
                    @(negedge clk);stalls=stalls+1;run_stall=run_stall+1;
                end
                if(n>0 && run_stall>max_stall) max_stall=run_stall;
                sign_code=prn[(n/8)%2046] ? -1 : 1;
                nh_sign=((20'b00000100110101001110 >> (19-((n/16368)%20))) & 1) ? -1 : 1;
                analog=2.0*real'(sign_code*nh_sign)*$cos(6.283185307179586*(phase+(4092000.0+hz)*real'(n)/16368000.0));
                sample_data=analog < -1 ? -3 : analog < 0 ? -1 : analog < 1 ? 1 : 3;
                sample_ref=64'(n);sample_valid=1;
                @(negedge clk);
            end
            sample_valid=0;repeat(64) @(negedge clk);
            if(!u_locked || !v_locked) $fatal(1,"loop failed to lock scenario=%0d",scenario);
        end
        $display("TRACKING_ITERATIVE_EQUIVALENCE_PASS accepted=%0d feedbacks=%0d stalls=%0d max_feedback_stall=%0d",accepted,feedbacks,stalls,max_stall);
        $finish;
    end
    initial begin #500000000; $fatal(1,"equivalence timeout");end
endmodule
