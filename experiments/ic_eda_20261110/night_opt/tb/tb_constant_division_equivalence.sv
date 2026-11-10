`timescale 1ns/1ps
module tb_constant_division_equivalence;
    logic signed [39:0] step_value;
    logic signed [32:0] aid_value;
    logic signed [23:0] step_result,aid_result;
    logic signed [39:0] step_edges[0:12];
    logic signed [32:0] aid_edges[0:12];
    logic [31:0] random_state=32'hc0de7631,random_low,random_high;
    longint signed expected_step,expected_aid,boundary;
    integer checks=0;
    constant_division_probe dut(.*);
    function automatic logic [31:0] random_word();
        random_state=random_state^(random_state<<13);
        random_state=random_state^(random_state>>17);
        random_state=random_state^(random_state<<5);
        return random_state;
    endfunction
    task automatic check_result;
        #1;
        expected_step=64'($signed(step_value))/64'sd127875;
        expected_aid=64'($signed(aid_value))/64'sd763;
        if(64'($signed(step_result))!==expected_step || 64'($signed(aid_result))!==expected_aid)
            $fatal(1,"CONSTANT_DIVISION_MISMATCH check=%0d step=%0d aid=%0d expected=%0d/%0d actual=%0d/%0d",
                checks,step_value,aid_value,expected_step,expected_aid,step_result,aid_result);
        checks=checks+1;
    endtask
    initial begin
        step_edges[0]=0;step_edges[1]=1;step_edges[2]=-1;
        step_edges[3]=40'sh8000000000;step_edges[4]=40'sh7fffffffff;
        step_edges[5]=127875;step_edges[6]=-127875;
        step_edges[7]=127874;step_edges[8]=-127874;
        step_edges[9]=127876;step_edges[10]=-127876;
        step_edges[11]=40'sd335544320000;step_edges[12]=-40'sd335544320000;
        aid_edges[0]=0;aid_edges[1]=1;aid_edges[2]=-1;
        aid_edges[3]=33'sh100000000;aid_edges[4]=33'sh0ffffffff;
        aid_edges[5]=763;aid_edges[6]=-763;
        aid_edges[7]=762;aid_edges[8]=-762;
        aid_edges[9]=764;aid_edges[10]=-764;
        aid_edges[11]=33'sd2147483648;aid_edges[12]=-33'sd2147483648;
        for(integer a=0;a<13;a=a+1)
            for(integer b=0;b<13;b=b+1) begin
                step_value=step_edges[a];aid_value=aid_edges[b];check_result();
            end
        for(integer n=0;n<200000;n=n+1) begin
            random_low=random_word();random_high=random_word();step_value={random_low,random_high[7:0]};
            random_low=random_word();random_high=random_word();aid_value={random_high[0],random_low};
            check_result();
        end
        // Exercise both correction branches immediately below, on and above integer boundaries.
        for(integer n=0;n<10000;n=n+1) begin
            boundary=64'(random_word()&32'h003fffff)*127875;
            step_value=40'((n%2==0 ? boundary : -boundary)+(n%3)-1);
            boundary=64'(random_word()&32'h003fffff)*763;
            aid_value=33'((n%2==0 ? boundary : -boundary)+(n%3)-1);
            check_result();
        end
        $display("CONSTANT_DIVISION_EQUIVALENCE_PASS checks=%0d seed=c0de7631",checks);
        $finish;
    end
endmodule
