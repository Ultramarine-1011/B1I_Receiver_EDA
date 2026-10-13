`timescale 1ns/1ps
module tb_tracking_frontend;
  logic clk = 0;
  always #5 clk = ~clk;
  logic rst_n, init_valid, sample_valid;
  logic [5:0] init_prn;
  logic [42:0] init_code_phase_q, code_phase_q;
  logic [31:0] init_code_period_count, code_period_count;
  logic [31:0] init_carrier_phase_word, carrier_step_word, carrier_phase_word;
  logic [32:0] code_step_q;
  logic signed [2:0] sample_data;
  logic [63:0] sample_ref, window_ref;
  logic sample_accepted, code_valid, init_done, code_epoch, window_done;
  logic signed [27:0] ie, qe, ip, qp, il, ql;
  logic [41:0] window_energy;
  tracking_frontend dut(.*);

  integer errors = 0;
  integer total_events = 0;
  integer total_windows = 0;
  integer current_event = 0;
  task automatic check(input logic condition, input [8*100-1:0] message);
    if (condition !== 1'b1) begin
      errors = errors + 1;
      if (errors < 20) $display("FRONTEND ERROR event=%0d: %0s", current_event, message);
    end
  endtask

  task automatic run_case(input [8*160-1:0] path);
    integer fd, scanned, events, prn, wait_cycles, v_valid, v_x;
    reg [42:0] phase, e_phase;
    reg [31:0] period, carrier_phase, e_period, e_carrier, step;
    reg [32:0] code_step;
    reg [63:0] ref_value, e_ref, e_energy;
    integer e_epoch, e_done, e_ie, e_qe, e_ip, e_qp, e_il, e_ql;
    begin
      fd = $fopen(path, "r");
      if (!fd) $fatal(1, "Missing frontend vector %0s", path);
      scanned = $fscanf(fd, "%d %d %d %d %d %d\n",
          prn, phase, period, carrier_phase, code_step, events);
      if (scanned != 6) $fatal(1, "Invalid frontend header");
      @(negedge clk);
      sample_valid = 1;
      init_valid = 1;
      init_prn = prn;
      init_code_phase_q = phase;
      init_code_period_count = period;
      init_carrier_phase_word = carrier_phase;
      code_step_q = code_step;
      #1;
      check(sample_accepted === 1'b0, "reload cancels current sample");
      @(posedge clk);
      #1;
      check(window_done === 1'b0 && window_energy === 0, "reload clears result and energy");
      @(negedge clk);
      init_valid = 0;
      sample_valid = 0;
      wait_cycles = 0;
      while (!code_valid && wait_cycles < 2055) begin
        @(posedge clk);
        #1;
        check(carrier_phase_word === carrier_phase, "carrier must hold during code prime");
        wait_cycles = wait_cycles + 1;
      end
      check(code_valid === 1'b1, "PRN prime timeout");
      for (current_event = 0; current_event < events; current_event = current_event + 1) begin
        scanned = $fscanf(fd, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
            v_valid, v_x, ref_value, step, e_phase, e_period, e_carrier, e_epoch, e_done,
            e_ie, e_qe, e_ip, e_qp, e_il, e_ql, e_ref, e_energy);
        if (scanned != 17) $fatal(1, "Invalid frontend row %0d", current_event);
        @(negedge clk);
        sample_valid = v_valid[0];
        sample_data = v_x;
        sample_ref = ref_value;
        carrier_step_word = step;
        #1;
        check(sample_accepted === v_valid[0], "input acceptance");
        @(posedge clk);
        #1;
        check(code_phase_q === e_phase, "Code NCO phase");
        check(code_period_count === e_period, "code period");
        check(carrier_phase_word === e_carrier, "Carrier NCO phase");
        check(code_epoch === e_epoch[0], "code epoch");
        check(window_done === e_done[0], "window completion and pipeline latency");
        check($signed(ie) === e_ie && $signed(qe) === e_qe, "Early sums");
        check($signed(ip) === e_ip && $signed(qp) === e_qp, "Prompt sums");
        check($signed(il) === e_il && $signed(ql) === e_ql, "Late sums");
        check(window_ref === e_ref, "first accepted window reference");
        check(window_energy === e_energy, "window energy and last sample");
        total_events = total_events + 1;
        total_windows = total_windows + e_done;
      end
      $fclose(fd);
    end
  endtask

  task automatic check_reload_and_reset;
    integer waits;
    integer prior_errors;
    begin
      prior_errors = errors;
      // Populate the registered mixer stage immediately before cancellation.
      repeat (3) begin
        @(negedge clk);
        sample_valid = 1;
        sample_data = -4;
        sample_ref = 64'd999000;
      end
      @(negedge clk);
      init_valid = 1;
      init_prn = 37;
      init_code_phase_q = 0;
      init_carrier_phase_word = 0;
      #1;
      check(sample_accepted === 0, "reload cancels input with occupied pipeline");
      @(posedge clk);
      #1;
      check({ie,qe,ip,qp,il,ql} === 0 && window_energy === 0 && window_ref === 0,
            "reload discards old pipeline and partial window");
      check(window_done === 0 && carrier_phase_word === 0 && code_phase_q === 0,
            "reload must not publish old result or advance NCO");
      @(negedge clk);
      init_valid = 0; // leave valid asserted throughout PRN prime
      waits = 0;
      while (!code_valid && waits < 2055) begin
        check(sample_accepted === 0, "prime does not accept waiting samples");
        @(posedge clk);
        #1;
        check(carrier_phase_word === 0 && code_phase_q === 0, "prime holds both phases");
        waits = waits + 1;
      end
      check(code_valid === 1, "re-prime completion");
      // Consume one sample and then reset while its I/Q is in flight.
      @(posedge clk);
      #1;
      rst_n = 0;
      #1;
      check(sample_accepted === 0 && code_valid === 0 && window_done === 0,
            "async reset masks input and output events");
      check({ie,qe,ip,qp,il,ql} === 0 && window_energy === 0,
            "async reset discards in-flight sample");
      @(negedge clk);
      sample_valid = 0;
      rst_n = 1;
      if (errors == prior_errors) $display("FRONTEND_RELOAD_RESET_PASS");
    end
  endtask

  initial begin
    #2000000;
    $fatal(1, "FRONTEND_REGRESSION_TIMEOUT");
  end

  initial begin
    rst_n = 0; init_valid = 0; sample_valid = 0;
    init_prn = 6; init_code_phase_q = 0; init_code_period_count = 0;
    init_carrier_phase_word = 0; code_step_q = 0; carrier_step_word = 0;
    sample_data = 0; sample_ref = 0;
    repeat (4) @(negedge clk);
    rst_n = 1;
    run_case("../../tb/vectors/frontend/aligned.vec");
    run_case("../../tb/vectors/frontend/wrap.vec");
    run_case("../../tb/vectors/frontend/negative.vec");
    check_reload_and_reset();
    check(total_windows == 4, "expected four complete windows");
    if (errors) $fatal(1, "FRONTEND_REGRESSION_FAIL errors=%0d", errors);
    $display("FRONTEND_REGRESSION_PASS events=%0d windows=%0d", total_events, total_windows);
    $finish;
  end
endmodule
