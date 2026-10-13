`timescale 1ns/1ps
// Unmodified teacher file player, all supported PRNs/full coarse frequency grid.
module tb_pcps_real;
    logic clk=0;always #5 clk=~clk;
    logic reset_n=0,start=0;
    logic [31:0] stream_data;
    logic stream_valid,stream_ready,stream_last;
    logic [63:0] sample_index;
    logic sample_valid,sample_ready,sample_last,input_drained;
    logic signed [2:0] sample_data;
    logic [63:0] sample_ref;
    logic result_valid,result_ready=1,detected,finished;
    logic [5:0] result_prn;
    logic [13:0] result_lag;
    logic [15:0] replay_address=0;
    logic signed [31:0] result_doppler;
    logic signed [2:0] replay_data;
    logic [63:0] result_ref,peak_power,mean_power;
    logic [31:0] search_cycles;
    integer fd,power_fd,count=0,detected_count=0,samples=0;
    if2_file_player player(.clk(clk),.reset_n(reset_n),.start(start),.stream_data(stream_data),
        .stream_valid(stream_valid),.stream_ready(stream_ready),.stream_last(stream_last),
        .sample_index(sample_index),.busy(),.done(),.error());
    stream_unpacker unpacker(.clk(clk),.reset_n(reset_n),.enable(1'b1),.stream_data(stream_data),
        .stream_valid(stream_valid),.stream_ready(stream_ready),.stream_last(stream_last),.sample_index(sample_index),
        .sample_valid(sample_valid),.sample_ready(sample_ready),.sample_bits(),.sample_data(sample_data),
        .sample_ref(sample_ref),.sample_last(sample_last),.input_drained(input_drained));
    acquisition_pcps dut(.clk(clk),.reset_n(reset_n),.request(start),.cancel(1'b0),.*);
    always @(posedge clk) if(reset_n) begin
        if(dut.state==dut.EVALUATE && dut.prn==6 && dut.doppler==-2624000 && dut.window_number==3)
            $fwrite(power_fd,"%0d,%0d\n",dut.address,dut.total_power);
        if(sample_valid && sample_ready) begin
            if(sample_ref!=64'(samples)) $fatal(1,"PCPS capture discontinuity");samples=samples+1;
        end
        if(result_valid && result_ready) begin
            if(result_prn!=6+count || result_ref!=0 || mean_power==0) $fatal(1,"PCPS result identity/time");
            $fwrite(fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",result_prn,result_lag,result_doppler,peak_power,mean_power,detected,search_cycles);
            $display("PCPS_REAL_CANDIDATE prn=%0d lag=%0d fcw=%0d ratio=%f detected=%0d cycles=%0d",result_prn,result_lag,result_doppler,real'(peak_power)/real'(mean_power),detected,search_cycles);
            count=count+1;if(detected) detected_count=detected_count+1;
        end
    end
    initial begin
        fd=$fopen("../../reports/e_stage/pcps_real_candidates.csv","w");
        power_fd=$fopen("../../reports/e_stage/pcps_first_grid.csv","w");
        $fwrite(power_fd,"index,power\n");
        $fwrite(fd,"prn,lag_samples,doppler_word,peak,mean,detected,cycles\n");
        repeat(4) @(negedge clk);reset_n=1;start=1;
        @(negedge clk);start=0;
        wait(finished);@(negedge clk);$fclose(fd);$fclose(power_fd);
        if(count!=32 || samples!=65472 || detected_count<1) $fatal(1,"PCPS incomplete search");
        $display("PCPS_REAL_SEARCH_PASS prns=%0d samples=%0d detected_candidates=%0d",count,samples,detected_count);$finish;
    end
    initial begin #4000000000;$fatal(1,"PCPS real search timeout");end
endmodule
