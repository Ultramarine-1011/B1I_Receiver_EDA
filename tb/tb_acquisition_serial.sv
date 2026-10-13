`timescale 1ns/1ps
module tb_acquisition_serial;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,request_valid=0,request_ready;
    logic [5:0] request_prn=6;
    logic [13:0] lag_first=0,lag_last=0,lag_step=8;
    logic signed [31:0] doppler_first=0,doppler_last=0,doppler_step=0;
    logic sample_valid=0,sample_ready;
    logic signed [2:0] sample_data=0;
    logic [63:0] sample_ref=0;
    logic result_valid,result_ready=0,detected;
    logic [5:0] result_prn;
    logic [13:0] result_lag;
    logic signed [31:0] result_doppler;
    logic [63:0] result_ref,peak_power;
    logic [31:0] search_cycles;
    logic cell_valid;
    logic [13:0] cell_lag;
    logic signed [31:0] cell_doppler;
    logic [63:0] cell_power,cell_energy;
    logic [1:0] stimulus[0:16367];
    integer cells=0,total_cells=0,cases=0,fd;
    acquisition_serial dut(.*);
    function automatic logic signed [31:0] word_hz(input integer hz);
        word_hz=32'($rtoi(real'(hz)*4294967296.0/16368000.0 + (hz>=0 ? 0.5 : -0.5)));
    endfunction
    always @(posedge clk) if(cell_valid) begin
        cells=cells+1; total_cells=total_cells+1;
        $fwrite(fd,"%0d,%0d,%0d,%0d,%0d\n",cases,cell_lag,$signed(cell_doppler),cell_power,cell_energy);
    end
    task automatic run_case(input string name,input integer prn,input integer maxlag,
                            input integer minhz,input integer maxhz,input integer expected_lag,
                            input integer expected_hz,input integer expected_detected,input integer expected_cells);
        logic [143:0] saved;
        integer waits;
        begin
            $readmemh({"../../tb/vectors/acquisition/",name,".mem"},stimulus);
            @(negedge clk);
            request_prn=6'(prn); lag_last=14'(maxlag);
            doppler_first=word_hz(minhz); doppler_last=word_hz(maxhz); doppler_step=word_hz(1000);
            request_valid=1; cells=0;
            @(negedge clk); request_valid=0;
            for(integer n=0;n<16368;n=n+1) begin
                if(n%4096==0) begin sample_valid=0; repeat(2) @(negedge clk); end
                sample_valid=1;
                sample_ref=64'd100000+64'(n);
                case(stimulus[n])
                    0:sample_data=-3; 1:sample_data=-1; 2:sample_data=1; 3:sample_data=3;
                endcase
                if(!sample_ready) $fatal(1,"capture not ready");
                @(negedge clk);
            end
            sample_valid=0;
            waits=0;
            while(!result_valid && waits<400000) begin @(negedge clk); waits=waits+1; end
            if(!result_valid) $fatal(1,"acquisition timeout %s",name);
            @(negedge clk); // passive monitor observes the final published cell
            if(detected != 1'(expected_detected) || result_prn!=6'(prn) || result_ref!=100000 || cells!=expected_cells)
                $fatal(1,"bad detection/id/ref/cells %s detected=%0d cells=%0d",name,detected,cells);
            if(expected_detected && (result_lag!=14'(expected_lag) || result_doppler!=word_hz(expected_hz)))
                $fatal(1,"wrong winner %s lag=%0d doppler=%0d",name,result_lag,$signed(result_doppler));
            saved={detected,result_lag,result_doppler,peak_power,search_cycles,1'b0};
            repeat(5) begin
                @(negedge clk);
                if(!result_valid || {detected,result_lag,result_doppler,peak_power,search_cycles,1'b0}!==saved)
                    $fatal(1,"result changed during backpressure");
            end
            $display("ACQUISITION_CASE_PASS name=%s detected=%0d lag=%0d doppler_word=%0d cells=%0d peak=%0d cycles=%0d",name,detected,result_lag,$signed(result_doppler),cells,peak_power,search_cycles);
            result_ready=1; @(negedge clk); result_ready=0;
            cases=cases+1;
        end
    endtask
    initial begin
        fd=$fopen("../../reports/local/acquisition_cells.csv","w");
        if(fd==0) $fatal(1,"CSV open failure");
        $fwrite(fd,"case,lag_samples,doppler_word,power,energy\n");
        repeat(4) @(negedge clk); reset_n=1;
        run_case("aligned",6,16,0,0,0,0,1,3);
        run_case("positive",6,32,-1000,1000,16,1000,1,15);
        run_case("negative",12,24,-1000,1000,8,-1000,1,12);
        run_case("wrong_prn",12,0,0,0,0,0,0,1);
        $fclose(fd);
        if(cases!=4 || total_cells!=31) $fatal(1,"missing cases");
        $display("ACQUISITION_SERIAL_PASS cases=%0d cells=%0d",cases,total_cells);
        $finish;
    end
    initial begin #20000000; $fatal(1,"ACQUISITION_REGRESSION_TIMEOUT"); end
endmodule
