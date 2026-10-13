`timescale 1ns/1ps

module tb_code_nco_epl;
  localparam integer PHASE_FRAC = 32;
  localparam integer PHASE_WIDTH = 11 + PHASE_FRAC;
  localparam integer IQ_WIDTH = 3;
  localparam integer WINDOW_SAMPLES = 16368;
  localparam integer ACC_WIDTH = IQ_WIDTH + $clog2(WINDOW_SAMPLES + 1);

  logic clk;
  logic rst_n;

  logic nco_init_valid;
  logic [5:0] init_prn;
  logic [PHASE_WIDTH-1:0] init_code_phase_q;
  logic [31:0] init_code_period_count;
  logic sample_valid;
  logic [PHASE_FRAC:0] code_step_q;
  logic code_valid;
  logic init_done;
  logic sample_accepted;
  logic code_epoch;
  logic early_code;
  logic prompt_code;
  logic late_code;
  logic [PHASE_WIDTH-1:0] code_phase_q;
  logic [31:0] code_period_count;

  logic signed [IQ_WIDTH-1:0] i_sample;
  logic signed [IQ_WIDTH-1:0] q_sample;
  logic [63:0] sample_ref;
  logic signed [ACC_WIDTH-1:0] ie;
  logic signed [ACC_WIDTH-1:0] qe;
  logic signed [ACC_WIDTH-1:0] ip;
  logic signed [ACC_WIDTH-1:0] qp;
  logic signed [ACC_WIDTH-1:0] il;
  logic signed [ACC_WIDTH-1:0] ql;
  logic window_done;
  logic [63:0] window_ref;

  logic ext_init_valid;
  logic ext_sample_valid;
  logic signed [IQ_WIDTH-1:0] ext_i_sample;
  logic signed [IQ_WIDTH-1:0] ext_q_sample;
  logic ext_early_code;
  logic ext_prompt_code;
  logic ext_late_code;
  logic [63:0] ext_sample_ref;
  logic signed [ACC_WIDTH-1:0] ext_ie;
  logic signed [ACC_WIDTH-1:0] ext_qe;
  logic signed [ACC_WIDTH-1:0] ext_ip;
  logic signed [ACC_WIDTH-1:0] ext_qp;
  logic signed [ACC_WIDTH-1:0] ext_il;
  logic signed [ACC_WIDTH-1:0] ext_ql;
  logic ext_window_done;
  logic [63:0] ext_window_ref;

  integer errors;
  integer total_vector_events;
  integer total_window_results;

  code_nco #(
    .PHASE_FRAC(PHASE_FRAC),
    .CODE_LENGTH(2046),
    .PERIOD_COUNT_WIDTH(32),
    .EPL_HALF_SPACING_NUMERATOR(1),
    .EPL_HALF_SPACING_DENOMINATOR(4)
  ) dut_nco (
    .clk(clk),
    .rst_n(rst_n),
    .init_valid(nco_init_valid),
    .init_prn(init_prn),
    .init_code_phase_q(init_code_phase_q),
    .init_code_period_count(init_code_period_count),
    .sample_valid(sample_valid),
    .code_step_q(code_step_q),
    .code_valid(code_valid),
    .init_done(init_done),
    .sample_accepted(sample_accepted),
    .code_epoch(code_epoch),
    .early_code(early_code),
    .prompt_code(prompt_code),
    .late_code(late_code),
    .code_phase_q(code_phase_q),
    .code_period_count(code_period_count)
  );

  epl_correlator #(
    .IQ_WIDTH(IQ_WIDTH),
    .WINDOW_SAMPLES(WINDOW_SAMPLES),
    .SAMPLE_REF_WIDTH(64),
    .ACC_GUARD_BITS(0)
  ) dut_correlator (
    .clk(clk),
    .rst_n(rst_n),
    .init_valid(nco_init_valid),
    .sample_valid(sample_accepted),
    .i_sample(i_sample),
    .q_sample(q_sample),
    .early_code(early_code),
    .prompt_code(prompt_code),
    .late_code(late_code),
    .sample_ref(sample_ref),
    .ie(ie),
    .qe(qe),
    .ip(ip),
    .qp(qp),
    .il(il),
    .ql(ql),
    .window_done(window_done),
    .window_ref(window_ref)
  );

  epl_correlator #(
    .IQ_WIDTH(IQ_WIDTH),
    .WINDOW_SAMPLES(WINDOW_SAMPLES),
    .SAMPLE_REF_WIDTH(64),
    .ACC_GUARD_BITS(0)
  ) extreme_correlator (
    .clk(clk),
    .rst_n(rst_n),
    .init_valid(ext_init_valid),
    .sample_valid(ext_sample_valid),
    .i_sample(ext_i_sample),
    .q_sample(ext_q_sample),
    .early_code(ext_early_code),
    .prompt_code(ext_prompt_code),
    .late_code(ext_late_code),
    .sample_ref(ext_sample_ref),
    .ie(ext_ie),
    .qe(ext_qe),
    .ip(ext_ip),
    .qp(ext_qp),
    .il(ext_il),
    .ql(ext_ql),
    .window_done(ext_window_done),
    .window_ref(ext_window_ref)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic check_condition(input condition, input [8*120-1:0] message);
    begin
      if (!condition) begin
        $display("ERROR: %0s at time %0t", message, $time);
        errors = errors + 1;
      end
    end
  endtask

  task automatic run_vector_case(input [8*160-1:0] filename);
    integer fd;
    integer scan_count;
    integer header_prn;
    reg [PHASE_WIDTH-1:0] header_phase;
    integer header_period;
    reg [PHASE_FRAC:0] header_step;
    integer header_events;
    integer event_index;
    integer vec_valid;
    integer vec_i;
    integer vec_q;
    integer vec_ref;
    reg [PHASE_WIDTH-1:0] exp_pre_phase;
    integer exp_pre_period;
    integer exp_early;
    integer exp_prompt;
    integer exp_late;
    reg [PHASE_WIDTH-1:0] exp_post_phase;
    integer exp_post_period;
    integer exp_epoch;
    integer exp_done;
    integer exp_ie;
    integer exp_qe;
    integer exp_ip;
    integer exp_qp;
    integer exp_il;
    integer exp_ql;
    integer exp_window_ref;
    integer init_wait_cycles;
    begin
      fd = $fopen(filename, "r");
      check_condition(fd != 0, "failed to open golden vector file");
      if (fd == 0)
        $fatal(1, "cannot continue without golden vectors");

      scan_count = $fscanf(fd, "%d %h %d %h %d\n",
          header_prn, header_phase, header_period, header_step, header_events);
      check_condition(scan_count == 5, "invalid golden vector header");

      @(negedge clk);
      sample_valid = 1'b0;
      nco_init_valid = 1'b1;
      init_prn = header_prn[5:0];
      init_code_phase_q = header_phase;
      init_code_period_count = header_period;
      code_step_q = header_step;
      @(posedge clk);
      #1;
      nco_init_valid = 1'b0;

      init_wait_cycles = 0;
      while (!code_valid && init_wait_cycles < 2055) begin
        @(posedge clk);
        #1;
        init_wait_cycles = init_wait_cycles + 1;
      end
      check_condition(code_valid === 1'b1, "Code NCO initialization timed out");
      check_condition(code_phase_q === header_phase, "init phase was not held during PRN alignment");
      check_condition(code_period_count === header_period, "init period count mismatch");

      for (event_index = 0; event_index < header_events; event_index = event_index + 1) begin
        scan_count = $fscanf(fd,
          "%d %d %d %d %h %d %d %d %d %h %d %d %d %d %d %d %d %d %d %d\n",
          vec_valid, vec_i, vec_q, vec_ref,
          exp_pre_phase, exp_pre_period, exp_early, exp_prompt, exp_late,
          exp_post_phase, exp_post_period, exp_epoch, exp_done,
          exp_ie, exp_qe, exp_ip, exp_qp, exp_il, exp_ql, exp_window_ref);
        check_condition(scan_count == 20, "invalid golden vector event row");

        @(negedge clk);
        sample_valid = vec_valid[0];
        i_sample = vec_i;
        q_sample = vec_q;
        sample_ref = vec_ref;
        #1;

        check_condition(code_phase_q === exp_pre_phase, "pre-sample code phase mismatch");
        check_condition(code_period_count === exp_pre_period, "pre-sample period count mismatch");
        check_condition(early_code === exp_early[0], "Early code mismatch");
        check_condition(prompt_code === exp_prompt[0], "Prompt code mismatch");
        check_condition(late_code === exp_late[0], "Late code mismatch");
        check_condition(sample_accepted === vec_valid[0], "sample acceptance mismatch");

        @(posedge clk);
        #1;
        check_condition(code_phase_q === exp_post_phase, "post-sample code phase mismatch");
        check_condition(code_period_count === exp_post_period, "post-sample period count mismatch");
        check_condition(code_epoch === exp_epoch[0], "code epoch mismatch");
        check_condition(window_done === exp_done[0], "window_done mismatch");
        check_condition($signed(ie) === exp_ie, "IE mismatch");
        check_condition($signed(qe) === exp_qe, "QE mismatch");
        check_condition($signed(ip) === exp_ip, "IP mismatch");
        check_condition($signed(qp) === exp_qp, "QP mismatch");
        check_condition($signed(il) === exp_il, "IL mismatch");
        check_condition($signed(ql) === exp_ql, "QL mismatch");
        check_condition(window_ref === exp_window_ref, "window reference mismatch");

        total_vector_events = total_vector_events + 1;
        if (exp_done)
          total_window_results = total_window_results + 1;
      end

      @(negedge clk);
      sample_valid = 1'b0;
      $fclose(fd);
      $display("VECTOR CASE PASS: %0s (%0d events, init wait %0d cycles)",
          filename, header_events, init_wait_cycles);
    end
  endtask

  task automatic run_extreme_window_test;
    integer sample_index;
    begin
      @(negedge clk);
      ext_init_valid = 1'b1;
      ext_sample_valid = 1'b0;
      @(posedge clk);
      #1;
      ext_init_valid = 1'b0;

      for (sample_index = 0; sample_index < WINDOW_SAMPLES; sample_index = sample_index + 1) begin
        @(negedge clk);
        ext_sample_valid = 1'b1;
        ext_i_sample = -4;
        ext_q_sample = -4;
        ext_early_code = 1'b1;
        ext_prompt_code = 1'b0;
        ext_late_code = 1'b1;
        ext_sample_ref = 64'd500000 + sample_index;
        @(posedge clk);
        #1;
        if (sample_index < WINDOW_SAMPLES - 1)
          check_condition(ext_window_done === 1'b0, "extreme window ended early");
      end
      check_condition(ext_window_done === 1'b1, "extreme positive window missing done");
      check_condition($signed(ext_ie) === 65472, "positive IE extreme mismatch");
      check_condition($signed(ext_qe) === 65472, "positive QE extreme mismatch");
      check_condition($signed(ext_ip) === -65472, "negative IP extreme mismatch");
      check_condition($signed(ext_qp) === -65472, "negative QP extreme mismatch");
      check_condition($signed(ext_il) === 65472, "positive IL extreme mismatch");
      check_condition($signed(ext_ql) === 65472, "positive QL extreme mismatch");
      check_condition(ext_window_ref === 64'd500000, "extreme window reference mismatch");

      // Start the next window immediately on the following accepted sample.
      for (sample_index = 0; sample_index < WINDOW_SAMPLES; sample_index = sample_index + 1) begin
        @(negedge clk);
        ext_early_code = 1'b0;
        ext_prompt_code = 1'b1;
        ext_late_code = 1'b0;
        ext_sample_ref = 64'd600000 + sample_index;
        @(posedge clk);
        #1;
      end
      check_condition(ext_window_done === 1'b1, "second extreme window missing done");
      check_condition($signed(ext_ie) === -65472, "negative IE extreme mismatch");
      check_condition($signed(ext_qe) === -65472, "negative QE extreme mismatch");
      check_condition($signed(ext_ip) === 65472, "positive IP extreme mismatch");
      check_condition($signed(ext_qp) === 65472, "positive QP extreme mismatch");
      check_condition($signed(ext_il) === -65472, "negative IL extreme mismatch");
      check_condition($signed(ext_ql) === -65472, "negative QL extreme mismatch");
      check_condition(ext_window_ref === 64'd600000, "second window reference mismatch");

      @(negedge clk);
      ext_sample_valid = 1'b0;
      $display("ACCUMULATOR EXTREME PASS: +/-65472 in %0d signed bits", ACC_WIDTH);
    end
  endtask

  task automatic run_reload_collision_test;
    integer wait_cycles;
    reg [PHASE_WIDTH-1:0] reload_phase;
    begin
      // A live channel has a partial window from the previous vector case.
      check_condition(code_valid === 1'b1, "collision test requires live channel");
      reload_phase = 43'h100000000; // exactly one chip, E/P/L need at most 2 clocks
      @(negedge clk);
      sample_valid = 1'b1;
      i_sample = -4;
      q_sample = 3;
      nco_init_valid = 1'b1;
      init_prn = 6'd6;
      init_code_phase_q = reload_phase;
      init_code_period_count = 32'd123;
      #1;
      check_condition(sample_accepted === 1'b0, "reload must mask sample acceptance before edge");
      @(posedge clk);
      #1;
      check_condition(code_phase_q === reload_phase, "reload must win over phase advance");
      check_condition(code_period_count === 32'd123, "reload period must win");
      check_condition(window_done === 1'b0, "reload must not publish partial window");
      check_condition(dut_correlator.window_sample_count === 0, "reload must discard partial window");
      check_condition({ie,qe,ip,qp,il,ql} === 0, "reload must clear old results");
      @(negedge clk);
      nco_init_valid = 1'b0;
      wait_cycles = 0;
      while (!code_valid && wait_cycles < 2055) begin
        check_condition(sample_accepted === 1'b0, "busy PRN alignment must not consume samples");
        @(posedge clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      check_condition(code_valid === 1'b1, "reload did not finish");
      check_condition(code_phase_q === reload_phase, "busy sample_valid must not advance phase");
      @(negedge clk);
      sample_valid = 1'b0;
      // Reset while old code_valid is high must mask combinational acceptance too.
      sample_valid = 1'b1;
      rst_n = 1'b0;
      #1;
      check_condition(sample_accepted === 1'b0, "reset must cancel acceptance");
      check_condition(code_valid === 1'b0, "reset must clear availability");
      @(negedge clk);
      sample_valid = 1'b0;
      rst_n = 1'b1;
      $display("RELOAD_COLLISION_PASS: init priority, busy sample and asynchronous reset");
    end
  endtask

  initial begin
    errors = 0;
    total_vector_events = 0;
    total_window_results = 0;
    rst_n = 1'b0;
    nco_init_valid = 1'b0;
    init_prn = 6'd6;
    init_code_phase_q = '0;
    init_code_period_count = '0;
    sample_valid = 1'b0;
    code_step_q = '0;
    i_sample = '0;
    q_sample = '0;
    sample_ref = '0;
    ext_init_valid = 1'b0;
    ext_sample_valid = 1'b0;
    ext_i_sample = '0;
    ext_q_sample = '0;
    ext_early_code = 1'b0;
    ext_prompt_code = 1'b0;
    ext_late_code = 1'b0;
    ext_sample_ref = '0;

    repeat (4) @(posedge clk);
    #1;
    check_condition(code_valid === 1'b0, "reset must clear code_valid");
    check_condition(code_phase_q === 0, "reset must clear code phase");
    check_condition(code_period_count === 0, "reset must clear code period count");
    check_condition(window_done === 1'b0, "reset must clear window_done");

    @(negedge clk);
    rst_n = 1'b1;

    run_vector_case("../../tb/vectors/code_nco_epl/nco_epl_nominal.vec");
    run_vector_case("../../tb/vectors/code_nco_epl/nco_epl_positive_adjust.vec");
    run_vector_case("../../tb/vectors/code_nco_epl/nco_epl_negative_adjust.vec");
    run_vector_case("../../tb/vectors/code_nco_epl/nco_epl_midstream_reload.vec");
    run_extreme_window_test();
    run_reload_collision_test();

    check_condition(total_window_results == 2, "golden regression must contain two full windows");

    if (errors == 0) begin
      $display("CODE_NCO_EPL_REGRESSION_PASS events=%0d windows=%0d",
          total_vector_events, total_window_results + 2);
      $finish;
    end else begin
      $fatal(1, "CODE_NCO_EPL_REGRESSION_FAIL: %0d errors", errors);
    end
  end

endmodule
