`timescale 1ns/1ps
// Public interface stays fixed; four channels are the minimum teacher receiver.
module student_receiver_core #(
    parameter integer USE_PCPS=1, CHANNELS=4,
    parameter integer SEARCH_PRN=6,
    parameter integer SEARCH_LAG_FIRST=0, SEARCH_LAG_LAST=16364, SEARCH_LAG_STEP=4,
    parameter integer SEARCH_DOPPLER_FIRST=-2624000, SEARCH_DOPPLER_LAST=2624000,
    parameter integer SEARCH_DOPPLER_STEP=131200
) (
    input logic clk,reset_n,start,
    input logic [31:0] stream_data,
    input logic stream_valid,
    output logic stream_ready,
    input logic stream_last,
    input logic [63:0] sample_index,
    output logic [255:0] record_data,
    output logic record_valid,
    input logic record_ready
);
    generate if(USE_PCPS==0) begin: single
        receiver_single #(.USE_PCPS(USE_PCPS),.SEARCH_PRN(SEARCH_PRN),
            .SEARCH_LAG_FIRST(SEARCH_LAG_FIRST),.SEARCH_LAG_LAST(SEARCH_LAG_LAST),.SEARCH_LAG_STEP(SEARCH_LAG_STEP),
            .SEARCH_DOPPLER_FIRST(SEARCH_DOPPLER_FIRST),.SEARCH_DOPPLER_LAST(SEARCH_DOPPLER_LAST),
            .SEARCH_DOPPLER_STEP(SEARCH_DOPPLER_STEP)) receiver(.*);
    end else begin: multi
        receiver_multichannel #(.CHANNELS(CHANNELS)) receiver(.*);
    end endgenerate
    initial if(CHANNELS!=1 && CHANNELS!=2 && CHANNELS!=4 && CHANNELS!=12)
        $fatal(1,"Supported independent-channel configurations are 1/2/4/12");
endmodule
