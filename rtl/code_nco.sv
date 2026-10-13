`timescale 1ns/1ps

// B1I code NCO plus Early/Prompt/Late PRN generation.
//
// code_phase_q uses unsigned Q11.PHASE_FRAC chips over [0, CODE_LENGTH).
// code_step_q uses unsigned Q1.PHASE_FRAC chips per accepted sample and must
// remain in (0, 1) chip/sample.  EPL spacing is the half-spacing delta:
// Early = q + delta, Prompt = q, Late = q - delta.
module code_nco #(
  parameter integer PHASE_FRAC = 32,
  parameter integer CODE_LENGTH = 2046,
  parameter integer PERIOD_COUNT_WIDTH = 32,
  parameter integer EPL_HALF_SPACING_NUMERATOR = 1,
  parameter integer EPL_HALF_SPACING_DENOMINATOR = 4
) (
  input  logic                          clk,
  input  logic                          rst_n,

  input  logic                          init_valid,
  input  logic [5:0]                    init_prn,
  input  logic [10+PHASE_FRAC:0]        init_code_phase_q,
  input  logic [PERIOD_COUNT_WIDTH-1:0] init_code_period_count,

  input  logic                          sample_valid,
  input  logic [PHASE_FRAC:0]           code_step_q,

  output logic                          code_valid,
  output logic                          init_done,
  output logic                          sample_accepted,
  output logic                          code_epoch,

  output logic                          early_code,
  output logic                          prompt_code,
  output logic                          late_code,

  output logic [10+PHASE_FRAC:0]        code_phase_q,
  output logic [PERIOD_COUNT_WIDTH-1:0] code_period_count
);

  localparam integer PHASE_WIDTH = 11 + PHASE_FRAC;
  localparam logic [PHASE_WIDTH-1:0] ONE_CHIP_Q =
      {{(PHASE_WIDTH-1){1'b0}}, 1'b1} << PHASE_FRAC;
  localparam logic [PHASE_WIDTH-1:0] CODE_MODULUS_Q = CODE_LENGTH * ONE_CHIP_Q;
  localparam logic [PHASE_WIDTH-1:0] EPL_HALF_SPACING_Q =
      (ONE_CHIP_Q * EPL_HALF_SPACING_NUMERATOR) / EPL_HALF_SPACING_DENOMINATOR;

  logic [PHASE_WIDTH-1:0] phase_acc;
  logic [PHASE_WIDTH:0] phase_sum;
  logic [PHASE_WIDTH-1:0] phase_next;
  logic phase_wrap;

  logic [PHASE_WIDTH-1:0] early_phase;
  logic [PHASE_WIDTH-1:0] late_phase;
  logic [PHASE_WIDTH-1:0] early_phase_next;
  logic [PHASE_WIDTH-1:0] late_phase_next;
  logic [PHASE_WIDTH-1:0] init_phase_normalized;
  logic [PHASE_WIDTH-1:0] init_early_phase;
  logic [PHASE_WIDTH-1:0] init_late_phase;

  logic [10:0] prompt_index_now;
  logic [10:0] early_index_now;
  logic [10:0] late_index_now;
  logic [10:0] prompt_index_next;
  logic [10:0] early_index_next;
  logic [10:0] late_index_next;
  logic [10:0] init_prompt_index;
  logic [10:0] init_early_index;
  logic [10:0] init_late_index;

  logic [10:0] prompt_generator_index;
  logic [10:0] early_generator_index;
  logic [10:0] late_generator_index;
  logic [10:0] target_prompt_index;
  logic [10:0] target_early_index;
  logic [10:0] target_late_index;

  logic prompt_configured;
  logic early_configured;
  logic late_configured;
  logic prompt_generator_epoch;
  logic early_generator_epoch;
  logic late_generator_epoch;
  logic init_busy;
  logic init_prn_supported;
  logic prompt_generator_enable;
  logic early_generator_enable;
  logic late_generator_enable;

  function automatic logic [PHASE_WIDTH-1:0] add_spacing(
    input logic [PHASE_WIDTH-1:0] phase
  );
    logic [PHASE_WIDTH:0] sum;
    begin
      sum = {1'b0, phase} + {1'b0, EPL_HALF_SPACING_Q};
      if (sum >= {1'b0, CODE_MODULUS_Q})
        add_spacing = sum - {1'b0, CODE_MODULUS_Q};
      else
        add_spacing = sum[PHASE_WIDTH-1:0];
    end
  endfunction

  function automatic logic [PHASE_WIDTH-1:0] subtract_spacing(
    input logic [PHASE_WIDTH-1:0] phase
  );
    begin
      if (phase >= EPL_HALF_SPACING_Q)
        subtract_spacing = phase - EPL_HALF_SPACING_Q;
      else
        subtract_spacing = CODE_MODULUS_Q - (EPL_HALF_SPACING_Q - phase);
    end
  endfunction

  always_comb begin
    phase_sum = {1'b0, phase_acc}
              + {{(PHASE_WIDTH-PHASE_FRAC){1'b0}}, code_step_q};
    if (phase_sum >= {1'b0, CODE_MODULUS_Q}) begin
      phase_next = phase_sum - {1'b0, CODE_MODULUS_Q};
      phase_wrap = 1'b1;
    end else begin
      phase_next = phase_sum[PHASE_WIDTH-1:0];
      phase_wrap = 1'b0;
    end

    early_phase = add_spacing(phase_acc);
    late_phase = subtract_spacing(phase_acc);
    early_phase_next = add_spacing(phase_next);
    late_phase_next = subtract_spacing(phase_next);

    prompt_index_now = phase_acc >> PHASE_FRAC;
    early_index_now = early_phase >> PHASE_FRAC;
    late_index_now = late_phase >> PHASE_FRAC;
    prompt_index_next = phase_next >> PHASE_FRAC;
    early_index_next = early_phase_next >> PHASE_FRAC;
    late_index_next = late_phase_next >> PHASE_FRAC;

    if (init_code_phase_q >= CODE_MODULUS_Q)
      init_phase_normalized = init_code_phase_q - CODE_MODULUS_Q;
    else
      init_phase_normalized = init_code_phase_q;
    init_early_phase = add_spacing(init_phase_normalized);
    init_late_phase = subtract_spacing(init_phase_normalized);
    init_prompt_index = init_phase_normalized >> PHASE_FRAC;
    init_early_index = init_early_phase >> PHASE_FRAC;
    init_late_index = init_late_phase >> PHASE_FRAC;

    init_prn_supported = (init_prn >= 6) && (init_prn <= 37);
    // Reset/reload cancels the current sample, including the acceptance flag.
    sample_accepted = rst_n && !init_valid && sample_valid && code_valid;

    prompt_generator_enable =
        (init_busy && (prompt_generator_index != target_prompt_index))
      || (sample_accepted && (prompt_index_next != prompt_index_now));
    early_generator_enable =
        (init_busy && (early_generator_index != target_early_index))
      || (sample_accepted && (early_index_next != early_index_now));
    late_generator_enable =
        (init_busy && (late_generator_index != target_late_index))
      || (sample_accepted && (late_index_next != late_index_now));

    code_phase_q = phase_acc;
  end

  b1i_prn_gen prompt_prn (
    .clk(clk),
    .rst_n(rst_n),
    .load(init_valid),
    .chip_enable(prompt_generator_enable),
    .prn_select(init_prn),
    .chip(prompt_code),
    .chip_index(prompt_generator_index),
    .configured(prompt_configured),
    .epoch(prompt_generator_epoch)
  );

  b1i_prn_gen early_prn (
    .clk(clk),
    .rst_n(rst_n),
    .load(init_valid),
    .chip_enable(early_generator_enable),
    .prn_select(init_prn),
    .chip(early_code),
    .chip_index(early_generator_index),
    .configured(early_configured),
    .epoch(early_generator_epoch)
  );

  b1i_prn_gen late_prn (
    .clk(clk),
    .rst_n(rst_n),
    .load(init_valid),
    .chip_enable(late_generator_enable),
    .prn_select(init_prn),
    .chip(late_code),
    .chip_index(late_generator_index),
    .configured(late_configured),
    .epoch(late_generator_epoch)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      phase_acc           <= {PHASE_WIDTH{1'b0}};
      code_period_count   <= {PERIOD_COUNT_WIDTH{1'b0}};
      target_prompt_index <= 11'd0;
      target_early_index  <= 11'd0;
      target_late_index   <= 11'd0;
      init_busy           <= 1'b0;
      code_valid          <= 1'b0;
      init_done           <= 1'b0;
      code_epoch          <= 1'b0;
    end else begin
      init_done  <= 1'b0;
      code_epoch <= 1'b0;

      if (init_valid) begin
        phase_acc           <= init_phase_normalized;
        code_period_count   <= init_code_period_count;
        target_prompt_index <= init_prompt_index;
        target_early_index  <= init_early_index;
        target_late_index   <= init_late_index;
        init_busy           <= init_prn_supported;
        code_valid          <= 1'b0;
      end else if (init_busy) begin
        if (prompt_configured && early_configured && late_configured
            && (prompt_generator_index == target_prompt_index)
            && (early_generator_index == target_early_index)
            && (late_generator_index == target_late_index)) begin
          init_busy  <= 1'b0;
          code_valid <= 1'b1;
          init_done  <= 1'b1;
        end
      end else if (sample_accepted) begin
        phase_acc <= phase_next;
        if (phase_wrap) begin
          code_period_count <= code_period_count + 1'b1;
          code_epoch <= 1'b1;
        end
      end
    end
  end

  initial begin
    if (PHASE_FRAC < 3)
      $fatal(1, "PHASE_FRAC must be at least 3 for nominal 1/8 chip/sample");
    if (EPL_HALF_SPACING_DENOMINATOR <= 0)
      $fatal(1, "EPL spacing denominator must be positive");
  end

endmodule
