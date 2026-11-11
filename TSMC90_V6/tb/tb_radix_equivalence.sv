`timescale 1ns/1ps
module tb_radix_equivalence;
    logic clk=0, reset_n=1;
    logic [56:0] magnitude,denominator;
    logic [28:0] phase_magnitude,phase_denominator;
    wire [16:0] old_code,r4_code,r16_code,nr_code,old_phase,r4_phase,r16_phase,nr_phase;
    logic [72:0] expected;
    logic [44:0] expected_phase;
    logic [63:0] random_state=64'hb1d1_2026_1110_7654;
    integer checks=0;
    norm_v4_57 a(.*,.result(),.combinational_result(old_code));
    norm_r4_57 b(.*,.result(),.combinational_result(r4_code));
    norm_r16_57 c(.*,.result(),.combinational_result(r16_code));
    norm_nr_57 g(.*,.result(),.combinational_result(nr_code));
    norm_v4_29 d(.*,.magnitude(phase_magnitude),.denominator(phase_denominator),
                 .result(),.combinational_result(old_phase));
    norm_r4_29 e(.*,.magnitude(phase_magnitude),.denominator(phase_denominator),
                 .result(),.combinational_result(r4_phase));
    norm_r16_29 f(.*,.magnitude(phase_magnitude),.denominator(phase_denominator),
                  .result(),.combinational_result(r16_phase));
    norm_nr_29 h(.*,.magnitude(phase_magnitude),.denominator(phase_denominator),
                 .result(),.combinational_result(nr_phase));
    function automatic logic [63:0] random_word();
        random_state=random_state^(random_state<<13);
        random_state=random_state^(random_state>>7);
        random_state=random_state^(random_state<<17);
        return random_state;
    endfunction
    task automatic check_result;
        expected=denominator==0 ? 0 : (73'(magnitude)<<16)/73'(denominator);
        expected_phase=phase_denominator==0 ? 0 :
            (45'(phase_magnitude)<<16)/45'(phase_denominator);
        #1;
        if(old_code!==expected[16:0] || r4_code!==old_code || r16_code!==old_code || nr_code!==old_code ||
           old_phase!==expected_phase[16:0] || r4_phase!==old_phase || r16_phase!==old_phase || nr_phase!==old_phase)
            $fatal(1,"RADIX_MISMATCH check=%0d m=%h d=%h code=%h/%h/%h expected=%h phase=%h/%h/%h expected=%h",
                checks,magnitude,denominator,old_code,r4_code,r16_code,expected,
                old_phase,r4_phase,r16_phase,expected_phase);
        checks=checks+1;
    endtask
    initial begin
        magnitude=0;denominator=0;phase_magnitude=0;phase_denominator=0;
        check_result();
        for(integer den=1;den<=511;den=den+1)
            for(integer mag=0;mag<=den;mag=mag+1) begin
                magnitude=57'(mag);denominator=57'(den);
                phase_magnitude=29'(mag);phase_denominator=29'(den);
                check_result();
            end
        for(integer bit_index=0;bit_index<57;bit_index=bit_index+1) begin
            denominator=57'd1<<bit_index;
            phase_denominator=29'd1<<(bit_index%29);
            for(integer delta=-1;delta<=1;delta=delta+1) begin
                if(delta==0) begin magnitude=denominator;phase_magnitude=phase_denominator;end
                else if(delta<0) begin magnitude=denominator-1;phase_magnitude=phase_denominator-1;end
                else begin magnitude=0;phase_magnitude=0;end
                check_result();
            end
        end
        for(integer n=0;n<200000;n=n+1) begin
            denominator=57'(random_word());
            if(denominator==0) denominator=1;
            magnitude=57'(random_word())%denominator;
            phase_denominator=29'(random_word());
            if(phase_denominator==0) phase_denominator=1;
            phase_magnitude=29'(random_word())%phase_denominator;
            if(n%17==0) begin magnitude=denominator;phase_magnitude=phase_denominator;end
            if(n%31==0) begin magnitude=0;phase_magnitude=0;end
            check_result();
        end
        $display("RADIX_EQUIVALENCE_PASS checks=%0d widths=57,29 variants=v4,r4,r16,nr",checks);
        $finish;
    end
endmodule
