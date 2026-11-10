`timescale 1ns/1ps
// M2 synthesis experiment only. The DC file list analyzes this empty module
// instead of student_release/.../acquisition_pcps.sv, so the 2,293,056 bit
// PCPS/FFT storage is not elaborated. Functional simulation keeps the real module.
// Do not add this file to a functional compile.
module acquisition_pcps #(
    parameter integer FIRST_PRN=6, LAST_PRN=37,
    parameter integer FIRST_DOPPLER=-2624000,LAST_DOPPLER=2624000,DOPPLER_STEP=131200,
    parameter integer DETECTION_RATIO=8,
    parameter integer CONFIGURED_PRN=0
) (
    input logic clk,reset_n,request,cancel,
    input logic [5:0] request_prn,
    output logic sample_ready,
    input logic sample_valid,
    input logic signed [2:0] sample_data,
    input logic [63:0] sample_ref,
    output logic result_valid,
    input logic result_ready,
    output logic detected,finished,
    output logic [5:0] result_prn,
    output logic [13:0] result_lag,
    output logic signed [31:0] result_doppler,
    output logic [63:0] result_ref,peak_power,mean_power,
    output logic [31:0] search_cycles,
    input logic [15:0] replay_address,
    output logic signed [2:0] replay_data
);
endmodule
