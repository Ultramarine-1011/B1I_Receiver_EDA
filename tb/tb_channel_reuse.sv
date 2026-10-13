`timescale 1ns/1ps
// Directly injected release validates channel cleanup and transport ownership.
module tb_channel_reuse;
    logic clk=0,reset_n=0,assign_valid=0,release_valid=0,sample_valid=0,sample_ready;
    logic [5:0] assign_prn=6,prn_saved;logic [42:0] assign_code_phase=0;
    logic [31:0] assign_code_epoch=0,assign_carrier_phase=0;
    logic signed [31:0] assign_doppler=0;logic [63:0] assign_effective_ref=0,sample_ref=0;
    logic signed [2:0] sample_data=3;
    logic epoch_event=0;logic [31:0] epoch_id=0;
    logic record_valid,record_ready=0,drained,overflow,active,locked,nh_valid,frame_valid,time_valid;
    logic [255:0] record_data,held_data;logic [7:0] generation;
    integer cycles=0,n=0,lost=0,old=0,new_records=0;
    receiver_channel dut(.*);
    always #5 clk=~clk;
    always @(posedge clk) if(reset_n) begin
        cycles++;if(cycles>200000) $fatal(1,"timeout");
        if(sample_valid&&sample_ready) n++;
        if(record_valid&&record_ready) begin
            if(record_data[7:0]==3) begin
                lost++;if(record_data[13:8]!=6 || record_data[31:24]!=1 || record_data[21:18]!=0) $fatal(1,"lost identity/validity");
            end else if(generation==1) old++;
            else begin
                new_records++;
                if(record_data[13:8]!=7 || (record_data[7:0]==1 ? record_data[29:24]!=2 : record_data[143:128]!=2))
                    $fatal(1,"old generation leaked after reuse");
                if(record_data[21:18]!=0 || record_data[7:0]==2) $fatal(1,"stale sync/time/nav");
            end
        end
    end
    task automatic feed(input integer count);
        while(n<count) begin
            @(negedge clk);sample_ref=64'(n);sample_valid=n<count && sample_ready;sample_data=n%4<2 ? 3 : -3;
        end
        @(negedge clk);sample_valid=0;
    endtask
    initial begin
        repeat(3) @(negedge clk);reset_n=1;assign_valid=1;
        @(negedge clk);assign_valid=0;
        feed(16368);
        while(!record_valid) @(negedge clk);
        held_data=record_data;release_valid=1;
        @(negedge clk);release_valid=0;
        repeat(5) begin @(negedge clk);if(!record_valid || record_data!==held_data) $fatal(1,"committed old record changed on release");end
        if(active || locked || nh_valid || frame_valid || time_valid) $fatal(1,"loss did not revoke validity");
        record_ready=1;
        while(!drained) @(negedge clk);
        if(lost!=1 || old!=1) $fatal(1,"release drain counts");
        assign_prn=7;assign_effective_ref=64'(n+16);assign_valid=1;
        @(negedge clk);assign_valid=0;
        feed(16368+16);
        if(dut.tracking.code_period_count!=0 || dut.tracking.code_phase_q!=0) $fatal(1,"NCO advanced before effective time");
        feed(16368*2+16);
        repeat(20) @(negedge clk);
        if(generation!=2 || new_records!=1 || overflow || !drained) $fatal(1,"reuse result counts");
        reset_n=0;
        @(negedge clk);reset_n=1;
        if(active || generation || record_valid || !drained) $fatal(1,"reset cleanup");
        $display("CHANNEL_REUSE_PASS control_only=1 held_record/lost/drain/reassignment/generation/effective_sample/reset");$finish;
    end
endmodule
