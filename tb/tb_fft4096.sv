`timescale 1ns/1ps
module tb_fft4096;
    logic clk=0;always #5 clk=~clk;
    logic reset_n=0,load_valid=0,load_ready,start=0,inverse=0,busy,done;
    logic [11:0] load_address=0,read_address=0;
    logic signed [31:0] load_real=0,load_imag=0,read_real,read_imag;
    logic signed [31:0] inr[0:4095],ini[0:4095],outr[0:4095],outi[0:4095];
    integer cycles=0,events=0;
    fft4096_serial #(.COS_FILE("../../student_release/student_release/rom/fft_cos_q30.mem"),
                    .SIN_FILE("../../student_release/student_release/rom/fft_sin_q30.mem")) dut(.*);
    initial begin
        repeat(3) @(negedge clk);reset_n=1;
        for(integer c=0;c<3;c=c+1) begin
            $readmemh($sformatf("in%0d_r.mem",c),inr);$readmemh($sformatf("in%0d_i.mem",c),ini);
            $readmemh($sformatf("out%0d_r.mem",c),outr);$readmemh($sformatf("out%0d_i.mem",c),outi);
            for(integer k=0;k<4096;k=k+1) begin
                @(negedge clk);load_address=12'(k);load_real=inr[k];load_imag=ini[k];load_valid=1;
                if(!load_ready) $fatal(1,"FFT load not ready");
            end
            @(negedge clk);load_valid=0;start=1;inverse=(c==2);
            @(negedge clk);start=0;cycles=0;
            while(!done && cycles<24580) begin @(negedge clk);cycles=cycles+1;end
            if(!done || cycles!=24576 || busy) $fatal(1,"FFT latency/done mismatch %0d",cycles);
            for(integer k=0;k<4096;k=k+1) begin
                read_address=12'(k);#1;
                if(read_real!==outr[k] || read_imag!==outi[k])
                    $fatal(1,"FFT case=%0d k=%0d got=%0d,%0d expected=%0d,%0d",c,k,read_real,read_imag,outr[k],outi[k]);
                events=events+1;
            end
            $display("FFT_CASE_PASS case=%0d cycles=%0d",c,cycles);
        end
        $display("FFT4096_PASS outputs=%0d bit_exact=1",events);$finish;
    end
    initial begin #2000000;$fatal(1,"FFT timeout");end
endmodule
