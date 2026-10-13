`timescale 1ns/1ps
module tb_carrier_nco_mixer;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  logic rst_n, init_valid, sample_valid;
  logic [31:0] init_phase_word, carrier_step_word;
  logic signed [2:0] sample_data;
  logic [63:0] sample_ref;
  logic carrier_valid, sample_accepted, iq_valid;
  logic [31:0] carrier_phase_word;
  logic signed [13:0] i_sample, q_sample;
  logic [63:0] iq_ref;

  carrier_nco_mixer dut(.*);
  integer errors = 0;
  integer fd, count, scanned, event_index, accepted_count;
  integer v_rst, v_init, v_valid, v_x;
  reg [31:0] v_phase, v_step;
  reg [63:0] v_ref;
  integer e_accepted, e_configured, e_valid, e_i, e_q;
  reg [31:0] e_phase;
  reg [63:0] e_ref;

  task automatic check(input logic condition, input [8*100-1:0] message);
    if (condition !== 1'b1) begin
      errors = errors + 1;
      if (errors < 20)
        $display("ERROR carrier event=%0d: %0s", event_index, message);
    end
  endtask

  initial begin
    #2000000;
    $fatal(1, "CARRIER_REGRESSION_TIMEOUT");
  end

  initial begin
    rst_n = 0;
    init_valid = 0;
    sample_valid = 0;
    init_phase_word = 0;
    carrier_step_word = 0;
    sample_data = 0;
    sample_ref = 0;
    accepted_count = 0;
    fd = $fopen("../../tb/vectors/carrier/carrier.vec", "r");
    if (!fd) $fatal(1, "Missing carrier vectors");
    scanned = $fscanf(fd, "%d\n", count);
    if (scanned != 1 || count <= 0) $fatal(1, "Invalid vector header");
    for (event_index = 0; event_index < count; event_index = event_index + 1) begin
      scanned = $fscanf(fd, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
          v_rst, v_init, v_phase, v_valid, v_x, v_ref, v_step,
          e_accepted, e_phase, e_configured, e_valid, e_i, e_q, e_ref);
      if (scanned != 14) $fatal(1, "Invalid carrier vector row %0d", event_index);
      @(negedge clk);
      rst_n = v_rst[0];
      init_valid = v_init[0];
      init_phase_word = v_phase;
      sample_valid = v_valid[0];
      sample_data = v_x;
      sample_ref = v_ref;
      carrier_step_word = v_step;
      #1;
      check(sample_accepted === e_accepted[0], "acceptance/reset/init priority");
      @(posedge clk);
      #1;
      check(carrier_phase_word === e_phase, "post-event phase");
      check(carrier_valid === e_configured[0], "configured state");
      check(iq_valid === e_valid[0], "registered iq_valid");
      check($signed(i_sample) === e_i, "I product");
      check($signed(q_sample) === e_q, "Q product/sign");
      check(iq_ref === e_ref, "sample reference alignment/hold");
      accepted_count = accepted_count + e_accepted;
    end
    $fclose(fd);
    if (errors != 0) $fatal(1, "CARRIER_REGRESSION_FAIL errors=%0d", errors);
    $display("CARRIER_REGRESSION_PASS events=%0d accepted=%0d", count, accepted_count);
    $finish;
  end
endmodule
