`timescale 1ns/1ps
module tb_mapped_arithmetic;
    logic [28:0] magnitude=0,denominator=0;
    logic [16:0] ratio;
    logic signed [39:0] step_value=0;
    logic signed [32:0] aid_value=0;
    logic signed [23:0] step_result,aid_result;
    logic [31:0] state=32'h112026b1;
    logic [44:0] numerator;
    logic [16:0] expected_ratio;
    logic signed [63:0] wide_step,wide_aid;
    logic signed [23:0] expected_step,expected_aid;
    integer checks=0;
    tracking_ratio_phase phase(.magnitude(magnitude),.denominator(denominator),.result(ratio));
    tracking_divide_step step(.value(step_value),.result(step_result));
    tracking_divide_aid aid(.value(aid_value),.result(aid_result));
    function automatic logic [31:0] random_word;
        state=state^(state<<13);
        state=state^(state>>17);
        state=state^(state<<5);
        return state;
    endfunction
    task automatic check;
        #1;
        numerator={magnitude,16'd0};
        expected_ratio=denominator==0 ? 17'd0 : 17'(numerator/denominator);
        wide_step=$signed(step_value);wide_aid=$signed(aid_value);
        expected_step=24'(wide_step/64'sd127875);
        expected_aid=24'(wide_aid/64'sd763);
        if(ratio!==expected_ratio || step_result!==expected_step || aid_result!==expected_aid)
            $fatal(1,"MAPPED_ARITHMETIC_MISMATCH check=%0d ratio=%h/%h step=%h/%h aid=%h/%h",checks,ratio,expected_ratio,step_result,expected_step,aid_result,expected_aid);
        checks=checks+1;
    endtask
    initial begin
        check();
        denominator=1;magnitude=1;step_value=1;aid_value=1;check();
        step_value=-1;aid_value=-1;check();
        denominator=29'd268435456;magnitude=denominator;
        step_value=40'sh8000000000;aid_value=33'sh100000000;check();
        magnitude=0;step_value=40'sh7fffffffff;aid_value=33'sh0ffffffff;check();
        step_value=127875;aid_value=763;check();
        step_value=-127875;aid_value=-763;check();
        for(integer i=0;i<20000;i=i+1) begin
            denominator=29'(random_word() & 32'h0fffffff);
            magnitude=denominator==0 ? 29'd0 : 29'(random_word()%(denominator+1));
            step_value=40'({random_word(),random_word()});
            aid_value=33'({random_word(),random_word()});
            check();
        end
        $display("MAPPED_ARITHMETIC_EQUIVALENCE_PASS checks=%0d seed=112026b1",checks);
        $finish;
    end
endmodule
