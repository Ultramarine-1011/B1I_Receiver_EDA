`timescale 1ns/1ps
// Real RTL timing trace on a reduced synthetic grid. Not formal P02 coverage.
module tb_p02_probe;
    logic clk=0,reset_n=0,request=0,cancel=0,sample_valid=0,sample_ready;
    logic signed [2:0] sample_data=0,replay_data;
    logic [63:0] sample_ref=0,coarse_ref,coarse_peak,coarse_mean,fine_peak;
    logic coarse_valid,coarse_ready=0,coarse_detected,finished;
    logic [5:0] prn;logic [13:0] coarse_lag,fine_lag;
    logic signed [31:0] coarse_doppler,fine_doppler;
    logic [31:0] coarse_cycles,fine_cycles;
    logic [15:0] replay_address;
    logic fine_request=0,fine_valid,fine_detected,fine_ready=0;
    logic code[0:2045];integer cycles=0,n=0,queued_cycle,accepted_cycle,verified_cycle,fd;
    always #5 clk=~clk;
    acquisition_pcps #(.FIRST_PRN(6),.LAST_PRN(6),.FIRST_DOPPLER(0),.LAST_DOPPLER(0)) coarse(
        .clk,.reset_n,.request,.cancel,.sample_ready,.sample_valid,.sample_data,.sample_ref,
        .result_valid(coarse_valid),.result_ready(coarse_ready),.detected(coarse_detected),.finished,
        .result_prn(prn),.result_lag(coarse_lag),.result_doppler(coarse_doppler),.result_ref(coarse_ref),
        .peak_power(coarse_peak),.mean_power(coarse_mean),.search_cycles(coarse_cycles),.replay_address,.replay_data);
    acquisition_refine #(.LAG_RADIUS(4),.FREQUENCY_RADIUS(0)) refine(
        .clk,.reset_n,.request(fine_request),.prn,.coarse_lag,.coarse_doppler,.reference_sample(coarse_ref),
        .replay_address,.replay_data,.result_valid(fine_valid),.result_ready(fine_ready),.detected(fine_detected),
        .result_lag(fine_lag),.result_doppler(fine_doppler),.peak_power(fine_peak),.search_cycles(fine_cycles));
    always @(posedge clk) if(reset_n) begin
        cycles++;if(cycles>2000000) $fatal(1,"timing probe timeout");
        if(request) accepted_cycle=cycles;
        if(sample_valid&&sample_ready) n++;
    end
    initial begin
        $readmemh("b1i_prn_06.mem",code);repeat(3) @(negedge clk);reset_n=1;queued_cycle=cycles;
        repeat(13) @(negedge clk);request=1;
        @(negedge clk);request=0;
        while(n<65472) begin
            sample_ref=64'(n);sample_valid=sample_ready && n<65472;
            // cos(IF*n+pi/4), 2-bit quantization of amplitude3 primary code.
            sample_data=(code[(n/8)%2046] ^ (n%4==1 || n%4==2)) ? -3 : 3;
            @(negedge clk);
        end
        sample_valid=0;
        while(!coarse_valid) @(negedge clk);
        if(!coarse_detected || prn!=6) $fatal(1,"coarse probe detection");
        fine_request=1;@(negedge clk);fine_request=0;
        while(!fine_valid) @(negedge clk);
        if(!fine_detected || fine_lag!=0 || fine_doppler!=0) $fatal(1,"independent probe verification lag=%0d freq=%0d",fine_lag,fine_doppler);
        verified_cycle=cycles;
        fd=$fopen("p02_probe.json","w");
        $fwrite(fd,"{\"scope\":\"self_generated_reduced_grid_not_formal_P02\",\"metric\":\"acquisition\",\"trials\":[{\"id\":\"rtl_probe\",\"seed\":0,\"target_present\":true,\"verified_success\":true,\"queued_cycle\":%0d,\"accepted_cycle\":%0d,\"verified_cycle\":%0d,\"signal_samples\":%0d}]}\n",queued_cycle,accepted_cycle,verified_cycle,n);
        $fclose(fd);fine_ready=1;coarse_ready=1;repeat(5) @(negedge clk);
        $display("P02_RTL_TIMING_PROBE_PASS reduced_grid=1 queue=%0d accepted=%0d verified=%0d samples=%0d",queued_cycle,accepted_cycle,verified_cycle,n);$finish;
    end
endmodule
