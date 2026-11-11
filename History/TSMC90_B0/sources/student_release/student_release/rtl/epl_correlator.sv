`timescale 1ns/1ps

// Fixed accepted-sample-window E/P/L correlator.
// Code bit mapping: 0 -> +1, 1 -> -1.
module epl_correlator #(
  parameter integer IQ_WIDTH = 3,
  parameter integer WINDOW_SAMPLES = 16368,
  parameter integer SAMPLE_REF_WIDTH = 64,
  parameter integer ACC_GUARD_BITS = 0,
  parameter integer ACC_WIDTH =
      IQ_WIDTH + $clog2(WINDOW_SAMPLES + 1) + ACC_GUARD_BITS
) (
  input  logic                              clk,
  input  logic                              rst_n,
  input  logic                              init_valid,
  input  logic                              sample_valid,
  input  logic signed [IQ_WIDTH-1:0]        i_sample,
  input  logic signed [IQ_WIDTH-1:0]        q_sample,
  input  logic                              early_code,
  input  logic                              prompt_code,
  input  logic                              late_code,
  input  logic [SAMPLE_REF_WIDTH-1:0]       sample_ref,

  output logic signed [ACC_WIDTH-1:0]       ie,
  output logic signed [ACC_WIDTH-1:0]       qe,
  output logic signed [ACC_WIDTH-1:0]       ip,
  output logic signed [ACC_WIDTH-1:0]       qp,
  output logic signed [ACC_WIDTH-1:0]       il,
  output logic signed [ACC_WIDTH-1:0]       ql,
  output logic                              window_done,
  output logic [SAMPLE_REF_WIDTH-1:0]       window_ref
);

  localparam integer MIN_ACC_WIDTH = IQ_WIDTH + $clog2(WINDOW_SAMPLES + 1);
  localparam integer WINDOW_COUNT_WIDTH =
      (WINDOW_SAMPLES <= 1) ? 1 : $clog2(WINDOW_SAMPLES);

  logic signed [ACC_WIDTH-1:0] ie_acc;
  logic signed [ACC_WIDTH-1:0] qe_acc;
  logic signed [ACC_WIDTH-1:0] ip_acc;
  logic signed [ACC_WIDTH-1:0] qp_acc;
  logic signed [ACC_WIDTH-1:0] il_acc;
  logic signed [ACC_WIDTH-1:0] ql_acc;
  logic [WINDOW_COUNT_WIDTH-1:0] window_sample_count;
  logic [SAMPLE_REF_WIDTH-1:0] window_start_ref;

  logic signed [ACC_WIDTH-1:0] i_extended;
  logic signed [ACC_WIDTH-1:0] q_extended;
  logic signed [ACC_WIDTH-1:0] i_early_product;
  logic signed [ACC_WIDTH-1:0] q_early_product;
  logic signed [ACC_WIDTH-1:0] i_prompt_product;
  logic signed [ACC_WIDTH-1:0] q_prompt_product;
  logic signed [ACC_WIDTH-1:0] i_late_product;
  logic signed [ACC_WIDTH-1:0] q_late_product;
  logic signed [ACC_WIDTH-1:0] ie_sum;
  logic signed [ACC_WIDTH-1:0] qe_sum;
  logic signed [ACC_WIDTH-1:0] ip_sum;
  logic signed [ACC_WIDTH-1:0] qp_sum;
  logic signed [ACC_WIDTH-1:0] il_sum;
  logic signed [ACC_WIDTH-1:0] ql_sum;

  always_comb begin
    i_extended = {{(ACC_WIDTH-IQ_WIDTH){i_sample[IQ_WIDTH-1]}}, i_sample};
    q_extended = {{(ACC_WIDTH-IQ_WIDTH){q_sample[IQ_WIDTH-1]}}, q_sample};

    i_early_product  = early_code  ? -i_extended : i_extended;
    q_early_product  = early_code  ? -q_extended : q_extended;
    i_prompt_product = prompt_code ? -i_extended : i_extended;
    q_prompt_product = prompt_code ? -q_extended : q_extended;
    i_late_product   = late_code   ? -i_extended : i_extended;
    q_late_product   = late_code   ? -q_extended : q_extended;

    ie_sum = ie_acc + i_early_product;
    qe_sum = qe_acc + q_early_product;
    ip_sum = ip_acc + i_prompt_product;
    qp_sum = qp_acc + q_prompt_product;
    il_sum = il_acc + i_late_product;
    ql_sum = ql_acc + q_late_product;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ie_acc <= '0;
      qe_acc <= '0;
      ip_acc <= '0;
      qp_acc <= '0;
      il_acc <= '0;
      ql_acc <= '0;
      ie <= '0;
      qe <= '0;
      ip <= '0;
      qp <= '0;
      il <= '0;
      ql <= '0;
      window_sample_count <= '0;
      window_start_ref <= '0;
      window_ref <= '0;
      window_done <= 1'b0;
    end else begin
      window_done <= 1'b0;

      if (init_valid) begin
        ie_acc <= '0;
        qe_acc <= '0;
        ip_acc <= '0;
        qp_acc <= '0;
        il_acc <= '0;
        ql_acc <= '0;
        ie <= '0;
        qe <= '0;
        ip <= '0;
        qp <= '0;
        il <= '0;
        ql <= '0;
        window_sample_count <= '0;
        window_start_ref <= '0;
        window_ref <= '0;
      end else if (sample_valid) begin
        if (window_sample_count == 0)
          window_start_ref <= sample_ref;

        if (window_sample_count == WINDOW_SAMPLES - 1) begin
          ie <= ie_sum;
          qe <= qe_sum;
          ip <= ip_sum;
          qp <= qp_sum;
          il <= il_sum;
          ql <= ql_sum;
          window_ref <= (window_sample_count == 0) ? sample_ref : window_start_ref;
          window_done <= 1'b1;

          ie_acc <= '0;
          qe_acc <= '0;
          ip_acc <= '0;
          qp_acc <= '0;
          il_acc <= '0;
          ql_acc <= '0;
          window_sample_count <= '0;
        end else begin
          ie_acc <= ie_sum;
          qe_acc <= qe_sum;
          ip_acc <= ip_sum;
          qp_acc <= qp_sum;
          il_acc <= il_sum;
          ql_acc <= ql_sum;
          window_sample_count <= window_sample_count + 1'b1;
        end
      end
    end
  end

  initial begin
    if (WINDOW_SAMPLES <= 0)
      $fatal(1, "WINDOW_SAMPLES must be positive");
    if (ACC_WIDTH < MIN_ACC_WIDTH)
      $fatal(1, "ACC_WIDTH is too small for the configured input and window");
  end

endmodule

