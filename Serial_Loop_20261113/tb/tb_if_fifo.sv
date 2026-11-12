`timescale 1ns/1ps
// A throttled consumer isolates the queue's ordering and reset contract.
module bds_bb_6ch_engine #(
    parameter integer FIRST_DOPPLER=0,LAST_DOPPLER=0,DOPPLER_STEP=1,
    REFINE_LAG_RADIUS=0,REFINE_FREQUENCY_RADIUS=0,PULLIN_SAMPLES=1,REACQUIRE_RADIUS_SAMPLES=0
)(
    input logic clk,rst_n,input logic [1:0] IF,input logic if_valid,
    output logic if_ready,input logic cfg_valid,input logic [2:0] cfg_channel,
    input logic [5:0] cfg_prn,input logic cfg_enable,
    output logic [5:0] capture_ok,bit_sync_ok,nav_data,nav_valid
);
    assign if_ready=rst_n && cfg_enable;
    assign capture_ok=0;
    assign bit_sync_ok=0;
    assign nav_data=0;
    assign nav_valid=0;
endmodule
module tb_if_fifo;
    logic clk=0;
    always #5 clk=~clk;
    logic rst_n=0,if_valid=0,if_ready,cfg_valid=0,cfg_enable=0;
    logic [1:0] IF=0;
    logic [2:0] cfg_channel=0;
    logic [5:0] cfg_prn=6,capture_ok,bit_sync_ok,nav_data,nav_valid;
    integer sent=0,received=0,high_water=0,full_cycles=0;
    bds_bb_6ch_core dut(.*);
    function automatic logic [1:0] sample_value(input integer number);
        sample_value=2'(number ^ (number>>3));
    endfunction
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin sent=0;received=0;end
        else begin
            if(dut.dequeue) begin
                if(dut.samples[dut.read_pointer]!==sample_value(received))
                    $fatal(1,"FIFO data/order mismatch index=%0d",received);
                received=received+1;
            end
            if(if_valid && if_ready) sent=sent+1;
            if(dut.occupancy>high_water) high_water=dut.occupancy;
            if(dut.occupancy==64) begin
                full_cycles=full_cycles+1;
                if(if_ready) $fatal(1,"FIFO advertised free space while full");
            end
            if(received>sent || sent-received>64) $fatal(1,"FIFO occupancy bound");
        end
    end
    initial begin
        repeat(3) @(negedge clk);rst_n=1;
        for(integer n=0;n<10000;n=n+1) begin
            cfg_enable=n>=200 && ($random & 3)!=0;
            if_valid=n<200 || ($random & 3)!=0;IF=sample_value(sent);
            @(negedge clk);
        end
        if_valid=0;cfg_enable=1;repeat(80) @(negedge clk);
        if(sent!=received || dut.occupancy) $fatal(1,"FIFO failed to drain");
        // Refill, then reset with live queued samples.
        cfg_enable=0;if_valid=1;
        repeat(50) begin IF=sample_value(sent);@(negedge clk);end
        if(dut.occupancy!=50) $fatal(1,"reset test did not populate the queue");
        rst_n=0;if_valid=0;@(negedge clk);rst_n=1;cfg_enable=1;
        repeat(80) @(negedge clk);
        if(sent || received || dut.occupancy) $fatal(1,"stale FIFO samples after reset");
        if(high_water!=64 || full_cycles<100) $fatal(1,"missing FIFO full coverage");
        $display("IF_FIFO_PASS randomized_cycles=10000 high_water=%0d reset_nonempty=1",high_water);$finish;
    end
endmodule
