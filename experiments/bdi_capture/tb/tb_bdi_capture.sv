`timescale 1ns/1ps
module tb_bdi_capture;
    localparam int N = 16368;
    logic clk = 1'b0, rst_n = 1'b0;
    // Compressed clock, exactly as permitted by the teacher: 1 ns half period.
    // Counted samples, rather than the displayed ns axis, define physical time.
    always #1 clk = ~clk;
    string scenario = "main";
    string wave_path;
    bit trace_enabled;
    bit ref6 [0:2045];
    logic source_enable = 1'b0;
    logic signed [1:0] source10_sample, source3_sample;
    logic source10_valid, source3_valid;
    logic source10_code, source3_code;
    logic source10_nh, source10_nav, source3_nh, source3_nav;
    logic [10:0] source10_index, source3_index;
    logic [4:0] source10_nh_idx, source3_nh_idx;
    logic [5:0] source10_nav_idx, source3_nav_idx;
    logic source10_code_aligned, source3_code_aligned;
    logic source10_nh_aligned, source3_nh_aligned;
    logic source10_nav_aligned, source3_nav_aligned;
    logic [10:0] source10_index_aligned, source3_index_aligned;
    logic signed [1:0] injected_sample = 2'sd0;
    logic injected_valid = 1'b0, injected_code = 1'b0;
    logic signed [1:0] if_sample;
    logic if_valid, rx_code_aligned;
    logic ready, local_code;
    logic [10:0] local_code_index, candidate_phase, result_phase, captured_phase;
    logic [1:0] carrier_phase;
    logic signed [3:0] local_cos, local_sin;
    logic signed [5:0] i_product, q_product;
    logic signed [23:0] i_acc, q_acc, i_result, q_result;
    logic [25:0] energy;
    logic [25:0] threshold = 26'd8192;
    logic [13:0] sample_in_window;
    logic dump, hit, acquired;

    bdi_signal_source source10 (
        .clk_16m368(clk), .rst_n(rst_n), .enable(source_enable),
        .if_sample(source10_sample), .if_valid(source10_valid),
        .dbg_prn_bit(source10_code), .dbg_prn_phase(source10_index),
        .dbg_nh_bit(source10_nh), .dbg_nav_bit(source10_nav),
        .dbg_nh_idx(source10_nh_idx), .dbg_nav_idx(source10_nav_idx)
    );
    // A different teacher-source phase proves acquisition is not fixed to 10.
    bdi_signal_source #(.PRN_PHASE_OFFSET(3)) source3 (
        .clk_16m368(clk), .rst_n(rst_n), .enable(source_enable),
        .if_sample(source3_sample), .if_valid(source3_valid),
        .dbg_prn_bit(source3_code), .dbg_prn_phase(source3_index),
        .dbg_nh_bit(source3_nh), .dbg_nav_bit(source3_nav),
        .dbg_nh_idx(source3_nh_idx), .dbg_nav_idx(source3_nav_idx)
    );

    // The teacher's debug code is combinational but IF output is registered.
    // These observation-only registers align debug to the IF consumed by DUT.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            source10_code_aligned <= 1'b0; source3_code_aligned <= 1'b0;
            source10_index_aligned <= 11'd0; source3_index_aligned <= 11'd0;
            source10_nh_aligned <= 1'b0; source3_nh_aligned <= 1'b0;
            source10_nav_aligned <= 1'b0; source3_nav_aligned <= 1'b0;
        end else begin
            source10_code_aligned <= source10_code;
            source3_code_aligned <= source3_code;
            source10_index_aligned <= source10_index;
            source3_index_aligned <= source3_index;
            source10_nh_aligned <= source10_nh;
            source3_nh_aligned <= source3_nh;
            source10_nav_aligned <= source10_nav;
            source3_nav_aligned <= source3_nav;
        end
    end

    always_comb begin
        if_sample = source10_sample;
        if_valid = source10_valid;
        rx_code_aligned = source10_code_aligned;
        if (scenario == "phase3") begin
            if_sample = source3_sample; if_valid = source3_valid;
            rx_code_aligned = source3_code_aligned;
        end else if (scenario == "zero" || scenario == "terminal") begin
            if_sample = injected_sample; if_valid = injected_valid;
            rx_code_aligned = injected_code;
        end
    end

    bdi_sliding_capture dut (
        .clk(clk), .rst_n(rst_n), .if_sample(if_sample), .if_valid(if_valid),
        .ready(ready), .local_code(local_code), .local_code_index(local_code_index),
        .carrier_phase(carrier_phase), .local_cos(local_cos), .local_sin(local_sin),
        .i_product(i_product), .q_product(q_product), .i_acc(i_acc), .q_acc(q_acc),
        .i_result(i_result), .q_result(q_result), .energy(energy), .dump(dump),
        .sample_in_window(sample_in_window), .candidate_phase(candidate_phase),
        .result_phase(result_phase), .captured_phase(captured_phase),
        .hit(hit), .acquired(acquired)
    );

    // Driver and passive reference have separate state; neither changes DUT.
    int sent_samples = 0;
    int driver_clocks = 0;
    logic [19:0] nh_bits = 20'b00000100110101001110;
    logic [10:0] head_bits = 11'b11100010010;
    always @(posedge clk) begin
        if (!rst_n) sent_samples = 0;
        else if (ready && if_valid) sent_samples = sent_samples + 1;
    end
    always @(negedge clk) begin
        driver_clocks = driver_clocks + 1;
        source_enable = rst_n && ready;
        // Includes stalls inside chips, and before/after the terminal sample.
        if (scenario == "gaps" &&
            ((driver_clocks % 97 < 4) || (sent_samples % N == N-1 && driver_clocks % 3 != 0)))
            source_enable = 1'b0;
        injected_valid = rst_n && ready;
        injected_sample = 2'sd0;
        injected_code = 1'b0;
        if (scenario == "terminal") begin
            // A nonzero LAST product is essential: the teacher's last IF
            // sample is zero and alone cannot expose an off-by-one sum bug.
            if (sent_samples % N == 0)
                injected_sample = (sent_samples / N == 0) ? 2'sb10 : 2'sd1;
            else if (sent_samples % N == N-1)
                injected_sample = (sent_samples / N == 0) ? 2'sd1 : 2'sb10;
        end
    end

    int n = 0, win = 0, expected_candidate = 0;
    int sum_i = 0, sum_q = 0, saved_i = 0, saved_q = 0, saved_energy = 0;
    int saved_phase = 0, saved_capture = 0;
    int accepted = 0, clock_count = 0, invalid_clocks = 0;
    int last_dump_clock = 0, gaps_at_dump = 0, hit_count = 0;
    int aligned_samples = 0, mismatch_samples = 0;
    int verified_aligned_samples = 0;
    int target_phase = 10, goal_windows = 13, reset_epoch = 0;
    bit expected_acquired = 0, table_checked = 0, done = 0;
    bit e_dump, e_hit, code_bit;
    int exp_index, exp_carrier, exp_cos, exp_sin, exp_ip, exp_qp;
    int expected_rx_index, rx_value, source_sign;
    int energy_before_last;
    int windows_file, samples_file;
    // Generated independently from the CURRENT cyclic table. The teacher's
    // illustrative low-value table differs slightly; see reference.json.
    int unsigned reference_energy [0:12];
    // Transaction snapshots used in waveforms: all refer to the SAME sample
    // just accepted at this edge, alongside updated accumulators/result/dump.
    logic consumed_valid, consumed_rx_code, consumed_local_code;
    logic signed [1:0] consumed_if;
    logic signed [3:0] consumed_cos, consumed_sin;
    logic signed [5:0] consumed_i_product, consumed_q_product;
    logic [10:0] consumed_phase, consumed_local_index;
    logic [13:0] consumed_sample_index;

    function automatic int abs_int(input int value);
        return value < 0 ? -value : value;
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            n = 0; win = 0; expected_candidate = 0;
            sum_i = 0; sum_q = 0; saved_i = 0; saved_q = 0; saved_energy = 0;
            saved_phase = 0; saved_capture = 0; accepted = 0;
            clock_count = 0; invalid_clocks = 0; last_dump_clock = 0;
            gaps_at_dump = 0; hit_count = 0; aligned_samples = 0;
            mismatch_samples = 0; expected_acquired = 0; table_checked = 0; done = 0;
            consumed_valid = 0; consumed_rx_code = 0; consumed_local_code = 0;
            consumed_if = 0; consumed_cos = 0; consumed_sin = 0;
            consumed_i_product = 0; consumed_q_product = 0;
            consumed_phase = 0; consumed_local_index = 0; consumed_sample_index = 0;
            #0.001;
            if (ready || dump || hit || acquired || energy != 0 ||
                candidate_phase != 0 || captured_phase != 0 || sample_in_window != 0 ||
                i_acc != 0 || q_acc != 0 || i_result != 0 || q_result != 0)
                $fatal(1, "reset did not clear acquisition state");
        end else begin
            clock_count = clock_count + 1;
            e_dump = 0; e_hit = 0;
            consumed_valid = ready && if_valid;
            if (ready) begin
                if (!table_checked) begin
                    for (int k=0; k<2046; k=k+1)
                        if (dut.code_table[k] !== ref6[k])
                            $fatal(1, "reused PRN table mismatch chip %0d", k);
                    table_checked = 1;
                end
                if (if_valid) begin
                    exp_index = (expected_candidate + n/8) % 2046;
                    code_bit = ref6[exp_index];
                    exp_carrier = (accepted+1) % 4;
                    case (exp_carrier)
                        0: begin exp_cos = 7; exp_sin = 0; end
                        1: begin exp_cos = 0; exp_sin = 7; end
                        2: begin exp_cos = -7; exp_sin = 0; end
                        default: begin exp_cos = 0; exp_sin = -7; end
                    endcase
                    if (int'(local_code_index) != exp_index || local_code !== code_bit ||
                        int'(carrier_phase) != exp_carrier || int'($signed(local_cos)) != exp_cos || int'($signed(local_sin)) != exp_sin)
                        $fatal(1, "local code/carrier mismatch win=%0d sample=%0d", win+1, n);
                    if (scenario == "main" || scenario == "gaps" ||
                        scenario == "restart" || scenario == "phase3") begin
                        expected_rx_index = (target_phase + (accepted % N)/8) % 2046;
                        if (rx_code_aligned !== ref6[expected_rx_index])
                            $fatal(1, "observation pipeline mismatch sample=%0d", accepted);
                        source_sign = int'(ref6[expected_rx_index]) ^ int'(nh_bits[19-(accepted/N)%20]) ^
                            (((accepted/N)/20 < 11) ? int'(head_bits[10-(accepted/N)/20]) : 1);
                        case (accepted % 4)
                            0: rx_value = (source_sign != 0) ? -1 : 1;
                            2: rx_value = (source_sign != 0) ? 1 : -1;
                            default: rx_value = 0;
                        endcase
                        if (int'($signed(if_sample)) != rx_value)
                            $fatal(1, "teacher IF/reference mismatch sample=%0d", accepted);
                        if (expected_candidate == target_phase) begin
                            if (rx_code_aligned !== local_code)
                                $fatal(1, "aligned phase contains code mismatch");
                            aligned_samples = aligned_samples + 1;
                        end else if (rx_code_aligned !== local_code)
                            mismatch_samples = mismatch_samples + 1;
                    end
                    exp_ip = int'($signed(if_sample)) * exp_cos * (code_bit ? -1 : 1);
                    exp_qp = int'($signed(if_sample)) * exp_sin * (code_bit ? -1 : 1);
                    if (int'($signed(i_product)) != exp_ip || int'($signed(q_product)) != exp_qp)
                        $fatal(1, "signed correlation product mismatch sample=%0d", accepted);
                    consumed_if = if_sample; consumed_rx_code = rx_code_aligned;
                    consumed_local_code = local_code; consumed_cos = local_cos; consumed_sin = local_sin;
                    consumed_i_product = i_product; consumed_q_product = q_product;
                    consumed_phase = candidate_phase; consumed_local_index = local_code_index;
                    consumed_sample_index = 14'(n);
                    energy_before_last = abs_int(sum_i)+abs_int(sum_q);
                    sum_i = sum_i + exp_ip; sum_q = sum_q + exp_qp;
                    accepted = accepted + 1;
                    n = n + 1;
                    if (n == N) begin
                        e_dump = 1;
                        saved_i = sum_i; saved_q = sum_q;
                        saved_energy = abs_int(sum_i)+abs_int(sum_q);
                        saved_phase = expected_candidate;
                        e_hit = !expected_acquired && saved_energy >= 8192;
                        if (e_hit) begin
                            expected_acquired = 1; saved_capture = expected_candidate;
                            hit_count = hit_count + 1;
                        end else if (!expected_acquired)
                            expected_candidate = (expected_candidate+1) % 2046;
                        if (last_dump_clock != 0 &&
                            clock_count-last_dump_clock != N+invalid_clocks-gaps_at_dump)
                            $fatal(1, "dump interval not N valid samples");
                        last_dump_clock = clock_count; gaps_at_dump = invalid_clocks;
                        if ((scenario == "main" || scenario == "restart" || scenario == "gaps") &&
                            saved_energy != reference_energy[win])
                            $fatal(1, "independent reference energy mismatch win=%0d got=%0d", win+1, saved_energy);
                        if (scenario == "terminal" &&
                            (exp_ip == 0 || saved_energy == energy_before_last))
                            $fatal(1, "terminal directed vector must expose last-sample omission");
                        if ((scenario == "zero" || scenario == "terminal") && expected_acquired)
                            $fatal(1, "negative control false hit");
                        n = 0; sum_i = 0; sum_q = 0; win = win+1;
                    end
                end else invalid_clocks = invalid_clocks+1;
            end
            #0.001; // Observe DUT only AFTER nonblocking assignments commit.
            if (dump !== e_dump || hit !== e_hit || acquired !== expected_acquired ||
                int'(energy) != saved_energy || int'(result_phase) != saved_phase ||
                int'(captured_phase) != saved_capture || int'(candidate_phase) != expected_candidate ||
                int'(sample_in_window) != n || int'($signed(i_acc)) != sum_i || int'($signed(q_acc)) != sum_q ||
                int'($signed(i_result)) != saved_i || int'($signed(q_result)) != saved_q)
                $fatal(1, "post-edge state mismatch case=%s win=%0d n=%0d dump=%b/%b hit=%b/%b E=%0d/%0d",
                       scenario, win, n, dump,e_dump,hit,e_hit,energy,saved_energy);
            if (dump) begin
                $fdisplay(windows_file, "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                          reset_epoch,win,clock_count,accepted,result_phase,candidate_phase,
                          $signed(i_result),$signed(q_result),energy,hit,acquired,captured_phase);
                $display("WINDOW case=%s epoch=%0d win=%0d phase=%0d I=%0d Q=%0d energy=%0d hit=%0d samples=%0d",
                         scenario,reset_epoch,win,result_phase,$signed(i_result),$signed(q_result),energy,hit,accepted);
            end
            if (samples_file != 0 && ready)
                $fdisplay(samples_file, "%0.3f,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                    $realtime,consumed_valid,accepted,consumed_phase,consumed_sample_index,
                    $signed(consumed_if),consumed_rx_code,consumed_local_code,
                    $signed(consumed_cos),$signed(consumed_sin),
                    $signed(consumed_i_product),$signed(consumed_q_product),
                    $signed(i_acc),$signed(q_acc),$signed(i_result),$signed(q_result),
                    energy,dump,candidate_phase,result_phase,hit,acquired);
            if (win == goal_windows) done = 1;
        end
    end

    task automatic check_completion;
        begin
            if (scenario == "zero" || scenario == "terminal") begin
                if (hit_count != 0 || acquired) $fatal(1, "negative control hit");
            end else begin
                if (hit_count != 1 || int'(captured_phase) != target_phase ||
                    aligned_samples != 3*N || mismatch_samples == 0)
                    $fatal(1, "incomplete acquisition/code-alignment coverage");
            end
            if (accepted != goal_windows*N || !table_checked)
                $fatal(1, "incomplete sample/window/table coverage");
            if (scenario == "gaps" && invalid_clocks < 1000)
                $fatal(1, "gaps were not exercised");
            verified_aligned_samples = aligned_samples;
        end
    endtask

    initial begin
        if ($value$plusargs("CASE=%s", scenario)) begin end
        if (scenario != "main" && scenario != "gaps" && scenario != "phase3" &&
            scenario != "zero" && scenario != "terminal" && scenario != "restart")
            $fatal(1, "unknown CASE=%s", scenario);
        if (scenario == "phase3") begin target_phase = 3; goal_windows = 6; end
        if (scenario == "terminal") goal_windows = 2;
        $readmemb("prn6.mem",ref6);
        $readmemh("energy.mem",reference_energy);
        trace_enabled = $value$plusargs("TRACE=%s",wave_path);
        if (trace_enabled) begin $dumpfile(wave_path); $dumpvars(0,tb_bdi_capture); end
        windows_file = $fopen("windows.csv","w");
        if (windows_file == 0) $fatal(1, "cannot open windows CSV");
        $fdisplay(windows_file,"epoch,window,clock,accepted,result_phase,candidate_phase,i_result,q_result,energy,hit,acquired,captured_phase");
        samples_file = 0;
        if (trace_enabled) begin
            samples_file = $fopen("samples.csv","w");
            if (samples_file == 0) $fatal(1, "cannot open samples CSV");
            $fdisplay(samples_file,"time_ns,valid,accepted,consumed_phase,sample_index,if_sample,rx_code,local_code,cos,sin,i_product,q_product,i_acc,q_acc,i_result,q_result,energy,dump,candidate_phase,result_phase,hit,acquired");
        end
        repeat (5) @(negedge clk);
        rst_n = 1'b1;
        wait(done);
        @(negedge clk); check_completion();
        if (scenario == "restart") begin
            // Reset after historical hit and during a new, partial window.
            repeat (37) @(negedge clk);
            if (sample_in_window == 0 || !acquired) $fatal(1,"mid-window reset precondition missing");
            rst_n = 1'b0; reset_epoch = 1;
            repeat (5) @(negedge clk);
            rst_n = 1'b1;
            wait(done);
            @(negedge clk); check_completion();
        end
        // Observe an invalid cycle after the last dump to check pulse clearing.
        @(negedge clk);
        if (dump || hit) $fatal(1,"dump/hit wider than one clock");
        $fclose(windows_file);
        if (samples_file != 0) $fclose(samples_file);
        $display("BDI_CAPTURE_PASS case=%s windows=%0d integrated_samples=%0d hits=%0d verified_aligned_samples=%0d mismatched_samples=%0d invalid_clocks=%0d epoch=%0d trailing_samples=%0d",
                 scenario,win,goal_windows*N,hit_count,verified_aligned_samples,mismatch_samples,invalid_clocks,reset_epoch,accepted-goal_windows*N);
        $finish;
    end
    initial begin
        repeat (600000) @(posedge clk);
        $fatal(1,"watchdog timeout CASE=%s",scenario);
    end
endmodule
