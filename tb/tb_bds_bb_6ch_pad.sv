`timescale 1ns/1ps
// Light connectivity check for bds_bb_6ch_pad_top. Compile with the power-aware
// TPHN28 model tphn28hpcpgv18_pwr.v. This does not run acquisition or tracking.
module tb_bds_bb_6ch_pad;
    reg clk_drv, rst_drv, if_valid_drv, cfg_valid_drv, cfg_enable_drv;
    reg [1:0] if_drv;
    reg [2:0] cfg_channel_drv;
    reg [5:0] cfg_prn_drv;
    integer errors, i;

    `define CHECK(cond, msg) \
        if (!(cond)) begin \
            errors = errors + 1; \
            $display("PAD_CHECK_FAIL %s", msg); \
        end

    wire pad_clk, pad_rst_n, pad_if_valid, pad_cfg_valid, pad_cfg_enable, pad_if_ready;
    wire [1:0] pad_IF;
    wire [2:0] pad_cfg_channel;
    wire [5:0] pad_cfg_prn, pad_capture_ok, pad_bit_sync_ok, pad_nav_data, pad_nav_valid;
    wire VDD, VSS, VDDPST, VSSPST;

    assign VDD = 1'b1;
    assign VSS = 1'b0;
    assign VDDPST = 1'b1;
    assign VSSPST = 1'b0;
    assign pad_clk = clk_drv;
    assign pad_rst_n = rst_drv;
    assign pad_IF = if_drv;
    assign pad_if_valid = if_valid_drv;
    assign pad_cfg_valid = cfg_valid_drv;
    assign pad_cfg_channel = cfg_channel_drv;
    assign pad_cfg_prn = cfg_prn_drv;
    assign pad_cfg_enable = cfg_enable_drv;

    bds_bb_6ch_pad_top dut (
        .pad_clk(pad_clk), .pad_rst_n(pad_rst_n), .pad_IF(pad_IF),
        .pad_if_valid(pad_if_valid), .pad_cfg_valid(pad_cfg_valid),
        .pad_cfg_channel(pad_cfg_channel), .pad_cfg_prn(pad_cfg_prn),
        .pad_cfg_enable(pad_cfg_enable), .pad_if_ready(pad_if_ready),
        .pad_capture_ok(pad_capture_ok), .pad_bit_sync_ok(pad_bit_sync_ok),
        .pad_nav_data(pad_nav_data), .pad_nav_valid(pad_nav_valid),
        .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST)
    );

    initial begin
        errors = 0;
        clk_drv = 0;
        rst_drv = 0;
        if_drv = 2'b00;
        if_valid_drv = 0;
        cfg_valid_drv = 0;
        cfg_channel_drv = 3'b000;
        cfg_prn_drv = 6'b000000;
        cfg_enable_drv = 0;
        #1;
        `CHECK(dut.poc === 1'b0, "POC is 0 while core and IO supplies are in the normal state")
        `CHECK(dut.core.clk === 1'b0, "clock pad reaches core clk at 0")
        `CHECK(dut.core.rst_n === 1'b0, "reset pad reaches core rst_n at 0")
        `CHECK(dut.u_rst_n.g_pu.u.OEN === 1'b1, "reset pad OEN is disabled")
        `CHECK(dut.u_rst_n.g_pu.u.REN === 1'b0, "reset pad receiver is enabled")
        `CHECK(dut.u_clk.g_pd.u.OEN === 1'b1, "clock pad is an input")
        `CHECK(dut.u_if_ready.g_pd.u.OEN === 1'b0, "if_ready pad driver is enabled")
        `CHECK(dut.u_if_ready.g_pd.u.REN === 1'b1, "if_ready receiver pull is off")

        clk_drv = 1;
        rst_drv = 1;
        if_drv = 2'b10;
        if_valid_drv = 1;
        cfg_valid_drv = 1;
        cfg_channel_drv = 3'b101;
        cfg_prn_drv = 6'b100101;
        cfg_enable_drv = 1;
        #1;
        `CHECK(dut.core.clk === 1'b1, "clock pad follows 1")
        `CHECK(dut.core.rst_n === 1'b1, "reset pad follows 1")
        `CHECK(dut.core.IF === 2'b10, "IF bit order is preserved")
        `CHECK(dut.core.if_valid === 1'b1, "if_valid reaches the core")
        `CHECK(dut.core.cfg_valid === 1'b1, "cfg_valid reaches the core")
        `CHECK(dut.core.cfg_channel === 3'b101, "cfg_channel bit order is preserved")
        `CHECK(dut.core.cfg_prn === 6'b100101, "cfg_prn bit order is preserved")
        `CHECK(dut.core.cfg_enable === 1'b1, "cfg_enable reaches the core")
        for (i = 0; i < 2; i = i + 1)
            `CHECK(dut.core.IF[i] === if_drv[i], "IF bit matches the driven pad")
        for (i = 0; i < 3; i = i + 1)
            `CHECK(dut.core.cfg_channel[i] === cfg_channel_drv[i], "cfg_channel bit matches")
        for (i = 0; i < 6; i = i + 1)
            `CHECK(dut.core.cfg_prn[i] === cfg_prn_drv[i], "cfg_prn bit matches")

        force dut.core.if_ready = 1'b1;
        force dut.core.capture_ok = 6'b100101;
        force dut.core.bit_sync_ok = 6'b011010;
        force dut.core.nav_data = 6'b111000;
        force dut.core.nav_valid = 6'b000111;
        #1;
        `CHECK(pad_if_ready === 1'b1, "if_ready pad follows the core")
        `CHECK(pad_capture_ok === 6'b100101, "capture_ok pad preserves slot order")
        `CHECK(pad_bit_sync_ok === 6'b011010, "bit_sync_ok pad preserves slot order")
        `CHECK(pad_nav_data === 6'b111000, "nav_data pad preserves slot order")
        `CHECK(pad_nav_valid === 6'b000111, "nav_valid pad preserves slot order")
        `CHECK(dut.g_capture_ok[0].u.g_pd.u.I === dut.core.capture_ok[0], "capture pad 0")
        `CHECK(dut.g_capture_ok[1].u.g_pd.u.I === dut.core.capture_ok[1], "capture pad 1")
        `CHECK(dut.g_capture_ok[2].u.g_pd.u.I === dut.core.capture_ok[2], "capture pad 2")
        `CHECK(dut.g_capture_ok[3].u.g_pd.u.I === dut.core.capture_ok[3], "capture pad 3")
        `CHECK(dut.g_capture_ok[4].u.g_pd.u.I === dut.core.capture_ok[4], "capture pad 4")
        `CHECK(dut.g_capture_ok[5].u.g_pd.u.I === dut.core.capture_ok[5], "capture pad 5")
        `CHECK(dut.g_bit_sync_ok[5].u.g_pd.u.I === 1'b0, "bit_sync slot 5 is the MSB and is 0")
        `CHECK(dut.g_bit_sync_ok[0].u.g_pd.u.I === 1'b0, "bit_sync slot 0 is 0")
        `CHECK(dut.g_bit_sync_ok[1].u.g_pd.u.I === 1'b1, "bit_sync slot 1 is 1")
        `CHECK(dut.g_nav_data[5].u.g_pd.u.I === 1'b1, "nav_data slot 5 is 1")
        `CHECK(dut.g_nav_data[0].u.g_pd.u.I === 1'b0, "nav_data slot 0 is 0")
        `CHECK(dut.g_nav_valid[0].u.g_pd.u.I === 1'b1, "nav_valid slot 0 is 1")
        `CHECK(dut.g_nav_valid[5].u.g_pd.u.I === 1'b0, "nav_valid slot 5 is 0")
        release dut.core.if_ready;
        release dut.core.capture_ok;
        release dut.core.bit_sync_ok;
        release dut.core.nav_data;
        release dut.core.nav_valid;

        if (errors == 0) begin
            $display("M2_PAD_CONNECT_PASS");
            $finish(0);
        end else begin
            $display("M2_PAD_CONNECT_FAIL errors=%0d", errors);
            $finish(1);
        end
    end
endmodule
