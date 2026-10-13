`timescale 1ns/1ps

// Full IF+offset NCO: unsigned PHASE_WIDTH-bit fraction of one turn.
// Mix with CURRENT phase, then advance by carrier_step_word on acceptance.
// The symmetric integer oscillator scale is 2047, NOT an implicit /2048.
// I = sample*cos(theta), Q = -sample*sin(theta), full integer products.
module carrier_nco_mixer #(
  parameter integer PHASE_WIDTH = 32,
  parameter integer INPUT_WIDTH = 3,
  parameter integer SAMPLE_REF_WIDTH = 64
) (
  input logic clk,
  input logic rst_n,
  input logic init_valid,
  input logic [PHASE_WIDTH-1:0] init_phase_word,
  input logic [PHASE_WIDTH-1:0] carrier_step_word,
  input logic sample_valid,
  input logic signed [INPUT_WIDTH-1:0] sample_data,
  input logic [SAMPLE_REF_WIDTH-1:0] sample_ref,

  output logic carrier_valid,
  output logic sample_accepted,
  output logic [PHASE_WIDTH-1:0] carrier_phase_word,
  output logic iq_valid,
  output logic signed [INPUT_WIDTH+10:0] i_sample,
  output logic signed [INPUT_WIDTH+10:0] q_sample,
  output logic [SAMPLE_REF_WIDTH-1:0] iq_ref
);
  localparam integer ADDRESS_BITS = 10;
  localparam integer AMPLITUDE_BITS = 12;
  localparam integer IQ_WIDTH = INPUT_WIDTH + AMPLITUDE_BITS - 1;
  localparam logic [PHASE_WIDTH-1:0] ROUND_BIAS =
      {{(PHASE_WIDTH-1){1'b0}}, 1'b1} << (PHASE_WIDTH-ADDRESS_BITS-1);

  logic [PHASE_WIDTH-1:0] rounded_phase;
  logic [ADDRESS_BITS-1:0] sine_address;
  logic [ADDRESS_BITS-1:0] cosine_address;
  logic signed [AMPLITUDE_BITS-1:0] sine_value;
  logic signed [AMPLITUDE_BITS-1:0] cosine_value;
  logic signed [INPUT_WIDTH+AMPLITUDE_BITS-1:0] i_product;
  logic signed [INPUT_WIDTH+AMPLITUDE_BITS-1:0] q_product;

  `include "carrier_quarter_lut.svh"

  function automatic logic signed [11:0] sine_lookup(input logic [9:0] address);
    logic [8:0] quarter_index;
    logic signed [11:0] magnitude;
    begin
      quarter_index = address[8] ? (9'd256 - {1'b0,address[7:0]})
                                 : {1'b0,address[7:0]};
      magnitude = quarter_sine(quarter_index);
      sine_lookup = address[9] ? -magnitude : magnitude;
    end
  endfunction

  always_comb begin
    sample_accepted = rst_n && !init_valid && carrier_valid && sample_valid;
    rounded_phase = carrier_phase_word + ROUND_BIAS;
    sine_address = rounded_phase >> (PHASE_WIDTH-ADDRESS_BITS);
    cosine_address = sine_address + 10'd256;
    sine_value = sine_lookup(sine_address);
    cosine_value = sine_lookup(cosine_address);
    i_product = $signed(sample_data) * $signed(cosine_value);
    q_product = -($signed(sample_data) * $signed(sine_value));
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      carrier_phase_word <= '0;
      carrier_valid <= 1'b0;
      iq_valid <= 1'b0;
      i_sample <= '0;
      q_sample <= '0;
      iq_ref <= '0;
    end else if (init_valid) begin
      carrier_phase_word <= init_phase_word;
      carrier_valid <= 1'b1;
      iq_valid <= 1'b0;
      i_sample <= '0;
      q_sample <= '0;
      iq_ref <= '0;
    end else begin
      iq_valid <= sample_accepted;
      if (sample_accepted) begin
        carrier_phase_word <= carrier_phase_word + carrier_step_word;
        // |product| <= 2^(INPUT_WIDTH-1)*2047 < 2^(IQ_WIDTH-1).
        // Only a redundant sign bit is removed; no numerical rounding.
        i_sample <= i_product[IQ_WIDTH-1:0];
        q_sample <= q_product[IQ_WIDTH-1:0];
        iq_ref <= sample_ref;
      end
    end
  end

  initial begin
    if (PHASE_WIDTH <= ADDRESS_BITS || INPUT_WIDTH < 2 || SAMPLE_REF_WIDTH < 1)
      $fatal(1, "Invalid carrier NCO/mixer parameters");
  end
endmodule
