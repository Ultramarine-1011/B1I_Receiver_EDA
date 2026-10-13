`timescale 1ns/1ps
module tb_tracking_minimal;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,init_valid=0;
    logic [5:0] init_prn=6;
    logic [42:0] init_code_phase_q=0;
    logic signed [31:0] init_doppler_word=0;
    logic sample_valid=0,sample_ready;
    logic signed [2:0] sample_data=0;
    logic [63:0] sample_ref=0;
    logic [42:0] code_phase_q;
    logic [31:0] code_period_count,carrier_phase_word;
    logic [32:0] code_step_q;
    logic [31:0] carrier_step_word;
    logic signed [27:0] ie,qe,ip,qp,il,ql;
    logic window_done;
    logic [63:0] window_ref,feedback_ref;
    logic [41:0] window_energy;
    logic feedback_valid,usable,locked;
    logic signed [31:0] dll_error_q16,pll_error_q16,code_correction_q16,carrier_correction_q16;
    logic prn[0:2045];
    real true_phase=0.04,true_hz=5.0;
    real code_error,phase_error,hz_error,code_sq=0,phase_sq=0,hz_sq=0;
    integer case_number=0,tail_count=0,tail_locked=0,windows=0,feedbacks=0,fd;
    logic [32:0] previous_code_step;
    logic [31:0] previous_carrier_step;
    integer changed=0;
    tracking_channel_minimal dut(.*);
    function automatic real fold(input real value,input real period);
        fold=value-period*$floor(value/period+0.5);
    endfunction
    always @(negedge clk) if(feedback_valid) begin
        feedbacks=feedbacks+1;
        if(code_step_q!=previous_code_step || carrier_step_word!=previous_carrier_step) changed=changed+1;
        previous_code_step=code_step_q; previous_carrier_step=carrier_step_word;
        $fwrite(fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",case_number,window_ref,feedback_ref,ip,qp,ie,qe,il,ql,dll_error_q16,pll_error_q16,code_step_q,carrier_step_word,code_correction_q16,carrier_correction_q16,locked,code_phase_q,carrier_phase_word,code_period_count,window_energy);
    end
    // Score pre-consumption NCO state; truth never enters the DUT controller.
    always @(posedge clk) if(reset_n && sample_valid && sample_ready) begin
        if(sample_ref>=64'd13094400) begin // final 0.2 s of a 1 s run
            code_error=fold(real'(code_phase_q)/4294967296.0-real'(sample_ref)/8.0,2046.0);
            phase_error=fold(true_phase+(4092000.0+true_hz)*real'(sample_ref)/16368000.0-real'(carrier_phase_word)/4294967296.0,0.5);
            hz_error=(real'(carrier_step_word)-1073741824.0)*16368000.0/4294967296.0-true_hz;
            code_sq=code_sq+code_error*code_error;
            phase_sq=phase_sq+phase_error*phase_error;
            hz_sq=hz_sq+hz_error*hz_error;
            tail_count=tail_count+1; if(locked) tail_locked=tail_locked+1;
        end
        if(window_done) windows=windows+1;
    end
    task automatic run_case(input integer number,input real phase,input real hz,input logic [42:0] initial_code);
        real analog;
        integer sign_code,nh_sign,n,waits;
        begin
            case_number=number; true_phase=phase; true_hz=hz;
            code_sq=0;phase_sq=0;hz_sq=0;tail_count=0;tail_locked=0;windows=0;feedbacks=0;changed=0;
            @(negedge clk); sample_valid=0; init_valid=1; init_code_phase_q=initial_code;
            @(negedge clk); init_valid=0;
            waits=0;
            while(!sample_ready && waits<2055) begin @(negedge clk); waits=waits+1; end
            if(!sample_ready) $fatal(1,"prime timeout");
            previous_code_step=code_step_q;previous_carrier_step=carrier_step_word;
            for(n=0;n<16368000;n=n+1) begin
                sign_code=prn[(n/8)%2046] ? -1 : 1;
                // Explicit NH20 pattern below is used only by the signal generator.
                nh_sign=(((20'b00000100110101001110 >> (19-((n/16368)%20))) & 1)!=0) ? -1 : 1;
                analog=2.0*real'(sign_code*nh_sign)*$cos(6.283185307179586*(phase+(4092000.0+hz)*real'(n)/16368000.0));
                sample_data=analog < -1 ? -3 : analog < 0 ? -1 : analog < 1 ? 1 : 3;
                sample_ref=64'(n); sample_valid=1;
                @(negedge clk);
            end
            sample_valid=0; repeat(5) @(negedge clk);
            if(tail_count!=3273600 || feedbacks<995 || changed<50) $fatal(1,"missing feedback/sample coverage");
            $display("TRACKING_CASE_METRIC case=%0d code_rms=%f phase_rms_turn=%f frequency_rms_hz=%f tail_lock=%f windows=%0d feedbacks=%0d changes=%0d",number,$sqrt(code_sq/tail_count),$sqrt(phase_sq/tail_count),$sqrt(hz_sq/tail_count),real'(tail_locked)/real'(tail_count),windows,feedbacks,changed);
            if($sqrt(code_sq/tail_count)>0.10 || $sqrt(phase_sq/tail_count)>0.02 || $sqrt(hz_sq/tail_count)>1.0 || real'(tail_locked)/real'(tail_count)<0.95)
                $fatal(1,"TRACKING_CASE_FAIL case=%0d",number);
            $display("TRACKING_CASE_PASS case=%0d",number);
        end
    endtask
    initial begin
        $readmemh("../../tb/vectors/b1i_prn_06.mem",prn);
        fd=$fopen("../../reports/local/tracking_loop.csv","w");
        if(fd==0) $fatal(1,"CSV open failure");
        $fwrite(fd,"case,window_ref,feedback_ref,ip,qp,ie,qe,il,ql,dll_error_q16,pll_error_q16,code_step,carrier_step,code_correction_q16,carrier_correction_q16,locked,code_phase_q,carrier_phase_word,code_period_count,window_energy\n");
        repeat(4) @(negedge clk); reset_n=1;
        run_case(0,0.04,5.0,43'h040000000); // local code +0.25 chip
        run_case(1,-0.04,-5.0,(43'd2046<<32)-43'h040000000); // -0.25 chip modulo period
        $fclose(fd);
        $display("TRACKING_MINIMAL_PASS cases=2 seconds_per_case=1 NH20_flips=1");
        $finish;
    end
    initial begin #400000000; $fatal(1,"TRACKING_REGRESSION_TIMEOUT"); end
endmodule
