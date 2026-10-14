`timescale 1ns/1ps
module tb_g_acquisition;
    logic clk=0,reset_n=0,request=0,cancel=0,sample_valid=0,sample_ready;
    logic signed [2:0] sample_data=0,replay_data;
    logic [63:0] sample_ref=0,coarse_ref,coarse_peak,coarse_mean,fine_peak;
    logic coarse_valid,coarse_ready=0,coarse_detected,finished;
    logic [5:0] prn;logic [13:0] coarse_lag,fine_lag;
    logic signed [31:0] coarse_doppler,fine_doppler;
    logic [31:0] coarse_cycles,fine_cycles;logic [15:0] replay_address;
    logic fine_request=0,fine_valid,fine_detected,fine_ready=0;
    logic [2:0] stimulus[0:65471];
    integer cycles=0,n=0,case_id,fd,accepted_cycle,coarse_cycle,refine_cycle,results=0;
    always #5 clk=~clk;
    acquisition_pcps #(.FIRST_PRN(6),.LAST_PRN(7)) coarse(
        .clk,.reset_n,.request,.cancel,.sample_ready,.sample_valid,.sample_data,.sample_ref,
        .result_valid(coarse_valid),.result_ready(coarse_ready),.detected(coarse_detected),.finished,
        .result_prn(prn),.result_lag(coarse_lag),.result_doppler(coarse_doppler),.result_ref(coarse_ref),
        .peak_power(coarse_peak),.mean_power(coarse_mean),.search_cycles(coarse_cycles),.replay_address,.replay_data);
    acquisition_refine refine(.clk,.reset_n,.request(fine_request),.prn,.coarse_lag,.coarse_doppler,
        .reference_sample(coarse_ref),.replay_address,.replay_data,.result_valid(fine_valid),.result_ready(fine_ready),
        .detected(fine_detected),.result_lag(fine_lag),.result_doppler(fine_doppler),.peak_power(fine_peak),.search_cycles(fine_cycles));
    always @(posedge clk) if(reset_n) begin
        cycles++;if(cycles>100000000) $fatal(1,"G acquisition structural timeout");
        if(request) accepted_cycle=cycles;
        if(sample_valid&&sample_ready) n++;
    end
    initial begin
        fd=$fopen("acquisition_results.jsonl","w");if(!fd)$fatal(1,"cannot open score trace");
        for(case_id=0;case_id<8;case_id++) begin
            @(negedge clk);reset_n=0;sample_valid=0;coarse_ready=0;fine_ready=0;n=0;cycles=0;
            $readmemh($sformatf("case%0d.mem",case_id),stimulus);
            repeat(3) @(negedge clk);reset_n=1;request=1;
            @(negedge clk);request=0;
            while(n<65472) begin sample_ref=64'(n);sample_valid=sample_ready;sample_data=$signed(stimulus[n]);@(negedge clk);end
            sample_valid=0;
            for(integer candidate=0;candidate<2;candidate++) begin
                while(!coarse_valid)@(negedge clk);
                coarse_cycle=cycles;refine_cycle=0;
                if(prn!=6'(6+candidate))$fatal(1,"wrong PRN order");
                if(coarse_detected) begin
                    fine_request=1;refine_cycle=cycles;@(negedge clk);fine_request=0;
                    while(!fine_valid)@(negedge clk);
                end
                $fwrite(fd,"{\"case_index\":%0d,\"prn\":%0d,\"coarse_detected\":%0d,\"fine_run\":%0d,\"detected\":%0d,\"lag_samples\":%0d,\"doppler_word\":%0d,\"accepted_cycle\":%0d,\"coarse_cycle\":%0d,\"refine_cycle\":%0d,\"verified_cycle\":%0d}\n",
                    case_id,prn,coarse_detected,coarse_detected,coarse_detected&&fine_detected,coarse_detected ? fine_lag : coarse_lag,
                    coarse_detected ? fine_doppler : coarse_doppler,accepted_cycle,coarse_cycle,refine_cycle,cycles);
                results++;fine_ready=1;coarse_ready=1;@(negedge clk);fine_ready=0;coarse_ready=0;
            end
            while(!finished)@(negedge clk);
            $display("G_ACQUISITION_CASE_COMPLETE index=%0d cycles=%0d observed_samples=%0d",case_id,cycles,n);
        end
        $fclose(fd);if(results!=16)$fatal(1,"missing candidate results");
        $display("G_ACQUISITION_TRACE_PASS cases=8 candidates=16 signal_duration_each_s=0.004 not_formal_statistics=1");$finish;
    end
endmodule
