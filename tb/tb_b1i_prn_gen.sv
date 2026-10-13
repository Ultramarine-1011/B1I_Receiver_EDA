`timescale 1ns/1ps

module tb_b1i_prn_gen;
  logic        clk;
  logic        rst_n;
  logic        load;
  logic        chip_enable;
  logic [5:0]  prn_select;
  logic        chip;
  logic [10:0] chip_index;
  logic        configured;
  logic        epoch;

  reg golden_06 [0:2045];
  reg golden_12 [0:2045];
  reg golden_23 [0:2045];
  reg golden_37 [0:2045];
  reg golden_all [0:65471];

  integer errors;
  integer i;
  integer pair_differences [0:5];
  integer prn_loop;

  b1i_prn_gen dut (
    .clk(clk),
    .rst_n(rst_n),
    .load(load),
    .chip_enable(chip_enable),
    .prn_select(prn_select),
    .chip(chip),
    .chip_index(chip_index),
    .configured(configured),
    .epoch(epoch)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic check_condition(input condition, input [8*96-1:0] message);
    begin
      if (!condition) begin
        $display("ERROR: %0s at time %0t", message, $time);
        errors = errors + 1;
      end
    end
  endtask

  task automatic load_prn(input [5:0] prn);
    begin
      @(negedge clk);
      prn_select = prn;
      load = 1'b1;
      chip_enable = 1'b0;
      @(posedge clk);
      #1;
      load = 1'b0;
      check_condition(configured === 1'b1, "supported PRN must configure generator");
      check_condition(chip_index === 11'd0, "load must restore chip index zero");
      check_condition(epoch === 1'b0, "load must not assert epoch");
    end
  endtask

  task automatic verify_prn(input [5:0] prn);
    reg expected;
    begin
      load_prn(prn);
      chip_enable = 1'b1;

      for (i = 0; i < 2046; i = i + 1) begin
        expected = golden_all[((prn - 6) * 2046) + i];

        check_condition(chip_index === i[10:0], "chip index mismatch before advance");
        check_condition(chip === expected, "RTL chip differs from golden model");

        @(posedge clk);
        #1;
        if (i == 2045) begin
          check_condition(epoch === 1'b1, "epoch must pulse after chip 2045");
          check_condition(chip_index === 11'd0, "period wrap must return to chip zero");
          expected = golden_all[(prn - 6) * 2046];
          check_condition(chip === expected, "first chip after wrap must repeat");
        end else begin
          check_condition(epoch === 1'b0, "epoch asserted before period boundary");
          check_condition(chip_index === (i + 1), "chip index did not advance");
        end
      end

      @(posedge clk);
      #1;
      check_condition(epoch === 1'b0, "epoch must be a one-cycle pulse");
      chip_enable = 1'b0;
      $display("PRN %0d: 2046 chips and wrap verified", prn);
    end
  endtask

  initial begin
    $readmemb("../../tb/vectors/b1i_prn_06.mem", golden_06);
    $readmemb("../../tb/vectors/b1i_prn_12.mem", golden_12);
    $readmemb("../../tb/vectors/b1i_prn_23.mem", golden_23);
    $readmemb("../../tb/vectors/b1i_prn_37.mem", golden_37);
    $readmemb("../../tb/vectors/b1i_prn_06_37.mem", golden_all);

    errors = 0;
    rst_n = 1'b0;
    load = 1'b0;
    chip_enable = 1'b0;
    prn_select = 6'd6;

    repeat (3) @(posedge clk);
    #1;
    check_condition(configured === 1'b0, "reset must clear configured");
    check_condition(chip_index === 11'd0, "reset must initialize chip index");
    check_condition(chip === 1'b0, "chip must be zero while unconfigured");
    check_condition(epoch === 1'b0, "reset must clear epoch");

    @(negedge clk);
    rst_n = 1'b1;

    // Invalid PRNs must not silently select a code.
    @(negedge clk);
    prn_select = 6'd5;
    load = 1'b1;
    @(posedge clk);
    #1;
    load = 1'b0;
    check_condition(configured === 1'b0, "unsupported PRN must be rejected");

    for (prn_loop = 6; prn_loop <= 37; prn_loop = prn_loop + 1)
      verify_prn(prn_loop);

    for (i = 0; i < 6; i = i + 1)
      pair_differences[i] = 0;

    for (i = 0; i < 2046; i = i + 1) begin
      if (golden_06[i] != golden_12[i]) pair_differences[0] = pair_differences[0] + 1;
      if (golden_06[i] != golden_23[i]) pair_differences[1] = pair_differences[1] + 1;
      if (golden_06[i] != golden_37[i]) pair_differences[2] = pair_differences[2] + 1;
      if (golden_12[i] != golden_23[i]) pair_differences[3] = pair_differences[3] + 1;
      if (golden_12[i] != golden_37[i]) pair_differences[4] = pair_differences[4] + 1;
      if (golden_23[i] != golden_37[i]) pair_differences[5] = pair_differences[5] + 1;
    end

    for (i = 0; i < 6; i = i + 1)
      check_condition(pair_differences[i] > 0, "representative PRN sequences must differ");

    if (errors == 0) begin
      $display("B1I_PRN_REGRESSION_PASS");
      $finish;
    end else begin
      $fatal(1, "B1I_PRN_REGRESSION_FAIL: %0d errors", errors);
    end
  end

endmodule
