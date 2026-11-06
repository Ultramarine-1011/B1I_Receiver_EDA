`timescale 1ns/1ps
// Constant addresses of the real Q30 twiddle functions.
// Expected mem values: cos 40000000, 3ffffb11, c0000000, 3ffffb11
// and sin 00000000, 001921fb, 00000000, ffe6de05.
module twiddle_probe (
    output signed [31:0] c0,
    output signed [31:0] c1,
    output signed [31:0] c2048,
    output signed [31:0] c4095,
    output signed [31:0] s0,
    output signed [31:0] s1,
    output signed [31:0] s2048,
    output signed [31:0] s4095
);
    `include "fft_twiddle_rom.svh"
    assign c0 = fft_twiddle_cos(12'h000);
    assign c1 = fft_twiddle_cos(12'h001);
    assign c2048 = fft_twiddle_cos(12'h800);
    assign c4095 = fft_twiddle_cos(12'hFFF);
    assign s0 = fft_twiddle_sin(12'h000);
    assign s1 = fft_twiddle_sin(12'h001);
    assign s2048 = fft_twiddle_sin(12'h800);
    assign s4095 = fft_twiddle_sin(12'hFFF);
endmodule
