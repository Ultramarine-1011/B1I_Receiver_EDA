`timescale 1ns/1ps
module tb_mapped_nco;
    reg clk=0,rst_n=0,init_valid=0,sample_valid=0;
    reg [5:0] init_prn=6;
    reg [42:0] init_code_phase_q=0;
    reg [31:0] init_code_period_count=0;
    reg [32:0] code_step_q=33'h020000000;
    reg [31:0] random_state=32'hb1a12026;
    integer checks=0;
    always #5 clk=~clk;
    function automatic reg [31:0] random_word;
        random_state=random_state^(random_state<<13);
        random_state=random_state^(random_state>>17);
        random_state=random_state^(random_state<<5);
        return random_state;
    endfunction
wire code_valid_old,init_done_old,sample_accepted_old,code_epoch_old,early_code_old,prompt_code_old,late_code_old;
wire [42:0] code_phase_q_old; wire [31:0] code_period_count_old;
code_nco_PHASE_FRAC32_PERIOD_COUNT_WIDTH32_EPL_HALF_SPACING_NUMERATOR5_EPL_HALF_SPACING_DENOMINATOR16_old dut_old(
.clk(clk),
.rst_n(rst_n),
.init_valid(init_valid),
.init_prn(init_prn),
.init_code_phase_q(init_code_phase_q),
.init_code_period_count(init_code_period_count),
.sample_valid(sample_valid),
.code_step_q(code_step_q),
.code_valid(code_valid_old),
.init_done(init_done_old),
.sample_accepted(sample_accepted_old),
.code_epoch(code_epoch_old),
.early_code(early_code_old),
.prompt_code(prompt_code_old),
.late_code(late_code_old),
.code_phase_q(code_phase_q_old),
.code_period_count(code_period_count_old));

wire code_valid_new,init_done_new,sample_accepted_new,code_epoch_new,early_code_new,prompt_code_new,late_code_new;
wire [42:0] code_phase_q_new; wire [31:0] code_period_count_new;
code_nco_PHASE_FRAC32_PERIOD_COUNT_WIDTH32_EPL_HALF_SPACING_NUMERATOR5_EPL_HALF_SPACING_DENOMINATOR16_new dut_new(
.clk(clk),
.rst_n(rst_n),
.init_valid(init_valid),
.init_prn(init_prn),
.init_code_phase_q(init_code_phase_q),
.init_code_period_count(init_code_period_count),
.sample_valid(sample_valid),
.code_step_q(code_step_q),
.code_valid(code_valid_new),
.init_done(init_done_new),
.sample_accepted(sample_accepted_new),
.code_epoch(code_epoch_new),
.early_code(early_code_new),
.prompt_code(prompt_code_new),
.late_code(late_code_new),
.code_phase_q(code_phase_q_new),
.code_period_count(code_period_count_new));

    initial begin
        repeat(3) @(negedge clk);
        for(integer cycle=0;cycle<200000;cycle=cycle+1) begin
            rst_n=cycle%37001!=0;
            init_valid=cycle%5000==1;
            init_prn=6+random_word()%32;
            if(init_valid) begin
                init_code_phase_q=43'({random_word(),random_word()});
                init_code_period_count=random_word();
            end
            sample_valid=(random_word()%7)!=0;
            case(cycle%5)
                0: code_step_q=33'h020000000;
                1: code_step_q=33'h0ffffffff;
                2: code_step_q=33'd1;
                default: code_step_q=33'(random_word());
            endcase
            @(posedge clk);#0.1;
            if((^{code_valid_old,init_done_old,sample_accepted_old,code_epoch_old,early_code_old,prompt_code_old,late_code_old,code_phase_q_old,code_period_count_old})===1'bx) $fatal(1,"MAPPED_NCO_UNKNOWN cycle=%0d",cycle);
            if({code_valid_old,init_done_old,sample_accepted_old,code_epoch_old,early_code_old,prompt_code_old,late_code_old,code_phase_q_old,code_period_count_old} !== {code_valid_new,init_done_new,sample_accepted_new,code_epoch_new,early_code_new,prompt_code_new,late_code_new,code_phase_q_new,code_period_count_new}) $fatal(1,"MAPPED_NCO_CYCLE_MISMATCH cycle=%0d",cycle);
            checks=checks+1;
            @(negedge clk);#0.01;
        end
        $display("MAPPED_NCO_EQUIVALENCE_PASS cycles=%0d seed=b1a12026",checks);
        $finish;
    end
endmodule
