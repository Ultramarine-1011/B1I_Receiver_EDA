`timescale 1ns/1ps
module tb_conversion_equivalence;
    logic clk=0,reset_n=0;
    logic signed [31:0] raw_code,raw_carrier,base_doppler;
    logic [32:0] original_code,optimized_code;
    logic [31:0] original_carrier,optimized_carrier;
    logic signed [31:0] edges[0:8];
    logic [31:0] random_state=32'hc0de2026;
    integer checks=0;
    conversion_original reference_dut(.*,.code_step(original_code),.carrier_step(original_carrier));
    conversion_optimized optimized_dut(.*,.code_step(optimized_code),.carrier_step(optimized_carrier));
    function automatic logic [31:0] random_word();
        random_state=random_state^(random_state<<13);
        random_state=random_state^(random_state>>17);
        random_state=random_state^(random_state<<5);
        return random_state;
    endfunction
    initial begin
        raw_code=0;raw_carrier=0;base_doppler=0;
        #1;clk=1;#1;clk=0;reset_n=1;
        edges[0]=0;edges[1]=1;edges[2]=-1;
        edges[3]=32'sh80000000;edges[4]=32'sh7fffffff;
        edges[5]=1638400;edges[6]=-1638400;edges[7]=655360000;edges[8]=-655360000;
        for(integer n=0;n<20000;n=n+1) begin
            raw_code=n<81 ? edges[n%9] : 32'(random_word());
            raw_carrier=n<81 ? edges[(n/9)%9] : 32'(random_word());
            base_doppler=n<81 ? edges[(n+n/9)%9] : 32'(random_word());
            #1;clk=1;#1;clk=0;
            if(original_code!==optimized_code || original_carrier!==optimized_carrier)
                $fatal(1,"CONVERSION_MISMATCH n=%0d",n);
            checks=checks+1;
        end
        $display("CONVERSION_EQUIVALENCE_PASS checks=%0d",checks);
        $finish;
    end
endmodule
