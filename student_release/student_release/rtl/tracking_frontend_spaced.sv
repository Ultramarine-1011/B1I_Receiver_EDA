`timescale 1ns/1ps

// Single-channel sample datapath, without DLL/FLL/PLL or satellite management.
// During PRN priming no input is accepted. After priming both NCOs consume
// exactly the same samples. Codes travel through the mixer's one-cycle stage.
module tracking_frontend_spaced #(
  parameter integer CODE_FRAC = 32,
  parameter integer EPL_HALF_SPACING_NUMERATOR = 1,
  parameter integer EPL_HALF_SPACING_DENOMINATOR = 4,
  parameter integer CARRIER_PHASE_WIDTH = 32,
  parameter integer INPUT_WIDTH = 3,
  parameter integer SAMPLE_REF_WIDTH = 64,
  parameter integer PERIOD_COUNT_WIDTH = 32,
  parameter integer WINDOW_SAMPLES = 16368,
  parameter integer ALIGN_FIRST_WINDOW = 1,
  parameter integer IQ_WIDTH = INPUT_WIDTH + 11,
  parameter integer ACC_WIDTH = IQ_WIDTH + $clog2(WINDOW_SAMPLES+1),
  parameter integer ENERGY_WIDTH = 2*IQ_WIDTH + $clog2(WINDOW_SAMPLES+1)
) (
  input logic clk, rst_n, init_valid,
  input logic [5:0] init_prn,
  input logic [10+CODE_FRAC:0] init_code_phase_q,
  input logic [PERIOD_COUNT_WIDTH-1:0] init_code_period_count,
  input logic [CARRIER_PHASE_WIDTH-1:0] init_carrier_phase_word,
  input logic [CODE_FRAC:0] code_step_q,
  input logic [CARRIER_PHASE_WIDTH-1:0] carrier_step_word,
  input logic sample_valid,
  input logic signed [INPUT_WIDTH-1:0] sample_data,
  input logic [SAMPLE_REF_WIDTH-1:0] sample_ref,

  output logic sample_accepted, code_valid, init_done, code_epoch,
  output logic [10+CODE_FRAC:0] code_phase_q,
  output logic [PERIOD_COUNT_WIDTH-1:0] code_period_count,
  output logic [CARRIER_PHASE_WIDTH-1:0] carrier_phase_word,
  output logic signed [ACC_WIDTH-1:0] ie, qe, ip, qp, il, ql,
  output logic window_done,
  output logic [SAMPLE_REF_WIDTH-1:0] window_ref,
  output logic [ENERGY_WIDTH-1:0] window_energy
);
  localparam logic [10+CODE_FRAC:0] CODE_MODULUS_Q = {11'd2046,{CODE_FRAC{1'b0}}};
  localparam integer COUNT_WIDTH = WINDOW_SAMPLES <= 1 ? 1 : $clog2(WINDOW_SAMPLES);
  logic early_code, prompt_code, late_code;
  logic early_delayed, prompt_delayed, late_delayed;
  logic integration_started, integrate_delayed;
  logic carrier_valid, carrier_accepted, iq_valid;
  logic signed [IQ_WIDTH-1:0] i_sample, q_sample;
  logic [SAMPLE_REF_WIDTH-1:0] iq_ref;
  logic correlator_valid;
  logic [2*IQ_WIDTH-1:0] i_square, q_square;
  logic [2*IQ_WIDTH:0] sample_energy;
  logic [ENERGY_WIDTH-1:0] energy_acc, energy_sum;
  logic [COUNT_WIDTH-1:0] energy_count;

  code_nco #(.PHASE_FRAC(CODE_FRAC), .PERIOD_COUNT_WIDTH(PERIOD_COUNT_WIDTH),
             .EPL_HALF_SPACING_NUMERATOR(EPL_HALF_SPACING_NUMERATOR),
             .EPL_HALF_SPACING_DENOMINATOR(EPL_HALF_SPACING_DENOMINATOR)) code_source (
    .clk(clk), .rst_n(rst_n), .init_valid(init_valid), .init_prn(init_prn),
    .init_code_phase_q(init_code_phase_q), .init_code_period_count(init_code_period_count),
    .sample_valid(sample_valid), .code_step_q(code_step_q), .code_valid(code_valid),
    .init_done(init_done), .sample_accepted(sample_accepted), .code_epoch(code_epoch),
    .early_code(early_code), .prompt_code(prompt_code), .late_code(late_code),
    .code_phase_q(code_phase_q), .code_period_count(code_period_count)
  );

  carrier_nco_mixer #(.PHASE_WIDTH(CARRIER_PHASE_WIDTH), .INPUT_WIDTH(INPUT_WIDTH),
                     .SAMPLE_REF_WIDTH(SAMPLE_REF_WIDTH)) carrier (
    .clk(clk), .rst_n(rst_n), .init_valid(init_valid), .init_phase_word(init_carrier_phase_word),
    .carrier_step_word(carrier_step_word), .sample_valid(sample_accepted),
    .sample_data(sample_data), .sample_ref(sample_ref), .carrier_valid(carrier_valid),
    .sample_accepted(carrier_accepted), .carrier_phase_word(carrier_phase_word),
    .iq_valid(iq_valid), .i_sample(i_sample), .q_sample(q_sample), .iq_ref(iq_ref)
  );

  always_comb begin
    correlator_valid = iq_valid && integrate_delayed;
    i_square = $signed(i_sample) * $signed(i_sample);
    q_square = $signed(q_sample) * $signed(q_sample);
    sample_energy = {1'b0,i_square} + {1'b0,q_square};
    energy_sum = energy_acc + sample_energy;
  end

  epl_correlator #(.IQ_WIDTH(IQ_WIDTH), .WINDOW_SAMPLES(WINDOW_SAMPLES),
                  .SAMPLE_REF_WIDTH(SAMPLE_REF_WIDTH), .ACC_WIDTH(ACC_WIDTH)) correlator (
    .clk(clk), .rst_n(rst_n), .init_valid(init_valid), .sample_valid(correlator_valid),
    .i_sample(i_sample), .q_sample(q_sample), .sample_ref(iq_ref),
    .early_code(early_delayed), .prompt_code(prompt_delayed), .late_code(late_delayed),
    .ie(ie), .qe(qe), .ip(ip), .qp(qp), .il(il), .ql(ql),
    .window_done(window_done), .window_ref(window_ref)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      early_delayed <= 0;
      prompt_delayed <= 0;
      late_delayed <= 0;
      integrate_delayed <= 0;
      integration_started <= 0;
      energy_acc <= 0;
      energy_count <= 0;
      window_energy <= 0;
    end else if (init_valid) begin
      early_delayed <= 0;
      prompt_delayed <= 0;
      late_delayed <= 0;
      integrate_delayed <= 0;
      integration_started <= !ALIGN_FIRST_WINDOW || init_code_phase_q == 0
                            || init_code_phase_q == CODE_MODULUS_Q;
      energy_acc <= 0;
      energy_count <= 0;
      window_energy <= 0;
    end else begin
      if (code_epoch)
        integration_started <= 1'b1;
      integrate_delayed <= sample_accepted && (integration_started || code_epoch);
      if (sample_accepted) begin
        early_delayed <= early_code;
        prompt_delayed <= prompt_code;
        late_delayed <= late_code;
      end
      if (correlator_valid) begin
        if (energy_count == WINDOW_SAMPLES-1) begin
          window_energy <= energy_sum;
          energy_acc <= 0;
          energy_count <= 0;
        end else begin
          energy_acc <= energy_sum;
          energy_count <= energy_count + 1'b1;
        end
      end
    end
  end

  initial begin
    if (IQ_WIDTH != INPUT_WIDTH+11 || ENERGY_WIDTH < 2*IQ_WIDTH+$clog2(WINDOW_SAMPLES+1))
      $fatal(1, "Invalid frontend width override");
  end
endmodule

