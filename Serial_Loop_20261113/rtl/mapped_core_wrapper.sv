`timescale 1ns/1ps
// A short common IF queue absorbs the exact iterative feedback service bursts.
module bds_bb_6ch_core #(
    parameter integer FIRST_DOPPLER=-2624000,LAST_DOPPLER=2624000,DOPPLER_STEP=131200,
    parameter integer REFINE_LAG_RADIUS=16,REFINE_FREQUENCY_RADIUS=5,
    parameter integer PULLIN_SAMPLES=32736000,
    parameter integer REACQUIRE_RADIUS_SAMPLES=16
) (
    input logic clk,rst_n,
    input logic [1:0] IF,
    input logic if_valid,
    output logic if_ready,
    input logic cfg_valid,
    input logic [2:0] cfg_channel,
    input logic [5:0] cfg_prn,
    input logic cfg_enable,
    output logic [5:0] capture_ok,bit_sync_ok,nav_data,nav_valid
);
    logic [1:0] samples[0:63];
    logic [5:0] read_pointer,write_pointer;
    logic [6:0] occupancy;
    logic engine_ready,enqueue,dequeue;
    assign if_ready=rst_n && occupancy<64;
    assign enqueue=if_valid && if_ready;
    assign dequeue=occupancy!=0 && engine_ready;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            read_pointer<=0;write_pointer<=0;occupancy<=0;
        end else begin
            if(enqueue) begin
                samples[write_pointer]<=IF;
                write_pointer<=write_pointer+1'b1;
            end
            if(dequeue) read_pointer<=read_pointer+1'b1;
            case({enqueue,dequeue})
                2'b10: occupancy<=occupancy+1'b1;
                2'b01: occupancy<=occupancy-1'b1;
                default: begin end
            endcase
        end
    end
    bds_bb_6ch_engine engine(
        .clk(clk),.rst_n(rst_n),.IF(samples[read_pointer]),.if_valid(occupancy!=0),
        .if_ready(engine_ready),.cfg_valid(cfg_valid),.cfg_channel(cfg_channel),
        .cfg_prn(cfg_prn),.cfg_enable(cfg_enable),.capture_ok(capture_ok),
        .bit_sync_ok(bit_sync_ok),.nav_data(nav_data),.nav_valid(nav_valid));
endmodule
