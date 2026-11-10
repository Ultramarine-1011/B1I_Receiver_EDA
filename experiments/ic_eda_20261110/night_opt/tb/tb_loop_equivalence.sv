`timescale 1ns/1ps
module tb_loop_equivalence;
    logic window_done=1,previous_prompt_valid=1,previous_phase_valid=1;
    logic signed [27:0] ie,qe,ip,qp,il,ql,previous_ip,previous_qp;
    logic signed [31:0] code_integral,carrier_integral,code_mean_q16,frequency_mean_q16,previous_phase_q16;
    logic signed [31:0] base_doppler,init_doppler_word;
    logic [7:0] seen,population;
    logic [127:0] validity_history;
    logic [31:0] phase_mean_square_q32;
    logic [41:0] window_energy;
    logic [63:0] window_ref,previous_prompt_ref;
    logic [1151:0] original_values,optimized_values;
    logic [31:0] random_state=32'h600dc0de;
    logic signed [31:0] state_edges[0:8];
    logic signed [27:0] prompt_edges[0:4];
    integer checks=0;
    loop_original reference_dut(.*,.observed_values(original_values));
    loop_optimized optimized_dut(.*,.observed_values(optimized_values));
    function automatic logic [31:0] random_word();
        random_state=random_state^(random_state<<13);
        random_state=random_state^(random_state>>17);
        random_state=random_state^(random_state<<5);
        return random_state;
    endfunction
    task automatic check_result;
        #1;
        if(original_values!==optimized_values)
            $fatal(1,"LOOP_ARITHMETIC_MISMATCH check=%0d old=%h new=%h",checks,original_values,optimized_values);
        checks=checks+1;
    endtask
    initial begin
        state_edges[0]=32'sh80000000;state_edges[1]=32'sh7fffffff;
        state_edges[2]=0;state_edges[3]=1;state_edges[4]=-1;
        state_edges[5]=1638400;state_edges[6]=-1638400;
        state_edges[7]=655360000;state_edges[8]=-655360000;
        prompt_edges[0]=0;prompt_edges[1]=1;prompt_edges[2]=-1;
        prompt_edges[3]=28'sh8000000;prompt_edges[4]=28'sh7ffffff;
        for(integer a=0;a<5;a=a+1)
            for(integer b=0;b<5;b=b+1)
                for(integer c=0;c<5;c=c+1)
                    for(integer d=0;d<5;d=d+1) begin
                        ip=prompt_edges[a];qp=prompt_edges[b];
                        previous_ip=prompt_edges[c];previous_qp=prompt_edges[d];
                        ie=28'sh8000000;qe=ie;il=0;ql=0;window_energy=0;window_done=1;
                        code_integral=state_edges[checks%9];carrier_integral=state_edges[(checks/9)%9];
                        base_doppler=state_edges[checks%9];init_doppler_word=state_edges[(checks/9)%9];
                        code_mean_q16=state_edges[(checks/3)%9];frequency_mean_q16=32'sh80000000;
                        previous_phase_q16=32'sh7fffffff;phase_mean_square_q32=32'hffffffff;
                        seen=0;population=128;validity_history=0;previous_phase_valid=1;previous_prompt_valid=1;
                        previous_prompt_ref=64'hffffffffffffc00f;window_ref=previous_prompt_ref+16368;
                        check_result();
                    end
        // Include arbitrary full-width state words, beyond normal closed-loop trajectories.
        for(integer n=0;n<100000;n=n+1) begin
            ie=28'(random_word());qe=28'(random_word());il=28'(random_word());ql=28'(random_word());
            ip=28'(random_word());qp=28'(random_word());previous_ip=28'(random_word());previous_qp=28'(random_word());
            code_integral=n<81 ? state_edges[n%9] : 32'(random_word());
            base_doppler=n<81 ? state_edges[n%9] : 32'(random_word());
            init_doppler_word=n<81 ? state_edges[(n/9)%9] : 32'(random_word());
            carrier_integral=n<81 ? state_edges[(n/9)%9] : 32'(random_word());
            code_mean_q16=32'(random_word());frequency_mean_q16=32'(random_word());previous_phase_q16=32'(random_word());
            phase_mean_square_q32=random_word();window_energy={10'd0,random_word()};
            seen=8'(n%129);population=8'(n%129);validity_history={random_word(),random_word(),random_word(),random_word()};
            previous_prompt_ref={32'd0,random_word()};window_ref=previous_prompt_ref+((n%3)==0 ? 16369 : 16368);
            previous_prompt_valid=n%5!=0;previous_phase_valid=n%7!=0;window_done=n%11!=0;
            if(n<81) begin
                ie=n%2==0 ? 28'sh8000000 : 0;qe=ie;il=n%2==0 ? 0 : 28'sh8000000;ql=il;
                ip=n%3==0 ? 0 : n%3==1 ? -1 : 28'sh8000000;qp=n%2==0 ? 28'sh8000000 : 28'sh7ffffff;
                window_energy=0;window_done=1;
            end
            check_result();
        end
        $display("LOOP_EQUIVALENCE_PASS checks=%0d fields=18 seed=600dc0de",checks);
        $finish;
    end
endmodule
