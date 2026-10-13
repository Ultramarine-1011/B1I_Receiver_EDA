`timescale 1ns/1ps
// Replay measured RTL Prompt I, exported without source truth fields.
module tb_nh_actual_prompt;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,prompt_valid=0;
    logic signed [27:0] prompt_i=0;
    logic [63:0] prompt_ref=0;
    logic nh_locked,bit_valid,data_bit;
    logic [4:0] nh_phase;
    logic signed [33:0] bit_soft;
    logic [63:0] bit_ref;
    integer fd,count,scanned,bits_seen=0,value;
    logic polarity,polarity_seen=0;
    longint unsigned reference;
    nh20_sync dut(.*);
    always @(negedge clk) if(bit_valid) begin
        if(!polarity_seen) begin polarity=data_bit;polarity_seen=1;end
        if(data_bit!=polarity || nh_phase!=1) $fatal(1,"actual Prompt bit/NH mismatch");
        bits_seen=bits_seen+1;
    end
    initial begin
        fd=$fopen("../../tb/vectors/nh_d1/actual_tracking_prompt.vec","r");
        if(fd==0) $fatal(1,"No actual RTL Prompt vector");
        scanned=$fscanf(fd,"%d\n",count);
        if(scanned!=1 || count!=999) $fatal(1,"bad Prompt count");
        repeat(3) @(negedge clk);reset_n=1;
        for(integer n=0;n<count;n=n+1) begin
            scanned=$fscanf(fd,"%d %d\n",value,reference);
            if(scanned!=2) $fatal(1,"bad Prompt vector row");
            prompt_i=28'(value);prompt_ref=reference;prompt_valid=1;
            @(negedge clk);
        end
        prompt_valid=0;repeat(4) @(negedge clk);$fclose(fd);
        if(!nh_locked || nh_phase!=1 || bits_seen!=29) $fatal(1,"actual Prompt sync/count failure bits=%0d phase=%0d",bits_seen,nh_phase);
        $display("NH_ACTUAL_RTL_PROMPT_PASS windows=999 phase=%0d bits=%0d constant_data_polarity=%0d",nh_phase,bits_seen,polarity);
        $finish;
    end
    initial begin #1000000;$fatal(1,"NH_ACTUAL_PROMPT_TIMEOUT");end
endmodule
