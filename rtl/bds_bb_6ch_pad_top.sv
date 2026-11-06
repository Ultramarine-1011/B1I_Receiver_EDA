`timescale 1ns/1ps
// Functional pad ring for bds_bb_6ch_core.
// Cells are TPHN28HPCPGV18, 8 mA, horizontal, non-Schmitt. Drive strength is an
// M2 candidate, not a signoff IO specification.
//
// From tphn28hpcpgv18_pwr.v and tphn28hpcpgv18tt0p9v1p8v25c.lib:
//   OEN active-low: bufif0 enables the driver when OEN=0.
//   REN active-low: the receiver pull is enabled when REN=0
//     (pull_down_function "!REN" on PDDW, pull_up_function "!REN" on PDUW).
//   Input pads use OEN=1, REN=0. Output pads use OEN=0, REN=1.
//   primitive_poc drives POC=0 when VDD=1, VSS=0 and VDDPST=1 (normal run).
//   POC=1 only with core VDD off and IO supply on, which forces the driver to Z
//   because HZ = ~VDD & VDDPST & POC.
// rst_n uses the pull-up cell. Every other functional pad uses the pull-down cell.
module bds_bb_pad_bit #(
    parameter integer OUTPUT_MODE = 0,
    parameter integer PULL_UP = 0
) (
    input logic I,
    output logic C,
    inout PAD,
    inout POC,
    inout VDD,
    inout VSS,
    inout VDDPST,
    inout VSSPST
);
    wire data_i = OUTPUT_MODE != 0 ? I : 1'b0;
    wire oen = OUTPUT_MODE != 0 ? 1'b0 : 1'b1;
    wire ren = OUTPUT_MODE != 0 ? 1'b1 : 1'b0;
    generate
        if (PULL_UP != 0) begin : g_pu
            PDUW08DGZ_H_G u (
                .I(data_i), .OEN(oen), .REN(ren), .PAD(PAD), .C(C),
                .POC(POC), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST)
            );
        end else begin : g_pd
            PDDW08DGZ_H_G u (
                .I(data_i), .OEN(oen), .REN(ren), .PAD(PAD), .C(C),
                .POC(POC), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST)
            );
        end
    endgenerate
endmodule

module bds_bb_6ch_pad_top (
    inout pad_clk,
    inout pad_rst_n,
    inout [1:0] pad_IF,
    inout pad_if_valid,
    inout pad_cfg_valid,
    inout [2:0] pad_cfg_channel,
    inout [5:0] pad_cfg_prn,
    inout pad_cfg_enable,
    inout pad_if_ready,
    inout [5:0] pad_capture_ok,
    inout [5:0] pad_bit_sync_ok,
    inout [5:0] pad_nav_data,
    inout [5:0] pad_nav_valid,
    inout VDD,
    inout VSS,
    inout VDDPST,
    inout VSSPST
);
    wire poc;
    wire clk, rst_n, if_valid, cfg_valid, cfg_enable, if_ready;
    wire [1:0] IF;
    wire [2:0] cfg_channel;
    wire [5:0] cfg_prn, capture_ok, bit_sync_ok, nav_data, nav_valid;

    PVDD1DGZ_H_G u_vdd (
        .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    PVSS1DGZ_H_G u_vss (
        .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    PVDD2POC_H_G u_poc (
        .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));

    bds_bb_pad_bit u_clk (
        .I(1'b0), .C(clk), .PAD(pad_clk),
        .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    bds_bb_pad_bit #(.PULL_UP(1)) u_rst_n (
        .I(1'b0), .C(rst_n), .PAD(pad_rst_n),
        .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    bds_bb_pad_bit u_if_valid (
        .I(1'b0), .C(if_valid), .PAD(pad_if_valid),
        .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    bds_bb_pad_bit u_cfg_valid (
        .I(1'b0), .C(cfg_valid), .PAD(pad_cfg_valid),
        .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    bds_bb_pad_bit u_cfg_enable (
        .I(1'b0), .C(cfg_enable), .PAD(pad_cfg_enable),
        .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    for (genvar i = 0; i < 2; i = i + 1) begin : g_if
        bds_bb_pad_bit u (
            .I(1'b0), .C(IF[i]), .PAD(pad_IF[i]),
            .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    end
    for (genvar i = 0; i < 3; i = i + 1) begin : g_cfg_channel
        bds_bb_pad_bit u (
            .I(1'b0), .C(cfg_channel[i]), .PAD(pad_cfg_channel[i]),
            .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    end
    for (genvar i = 0; i < 6; i = i + 1) begin : g_cfg_prn
        bds_bb_pad_bit u (
            .I(1'b0), .C(cfg_prn[i]), .PAD(pad_cfg_prn[i]),
            .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    end

    bds_bb_pad_bit #(.OUTPUT_MODE(1)) u_if_ready (
        .I(if_ready), .C(), .PAD(pad_if_ready),
        .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    for (genvar i = 0; i < 6; i = i + 1) begin : g_capture_ok
        bds_bb_pad_bit #(.OUTPUT_MODE(1)) u (
            .I(capture_ok[i]), .C(), .PAD(pad_capture_ok[i]),
            .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    end
    for (genvar i = 0; i < 6; i = i + 1) begin : g_bit_sync_ok
        bds_bb_pad_bit #(.OUTPUT_MODE(1)) u (
            .I(bit_sync_ok[i]), .C(), .PAD(pad_bit_sync_ok[i]),
            .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    end
    for (genvar i = 0; i < 6; i = i + 1) begin : g_nav_data
        bds_bb_pad_bit #(.OUTPUT_MODE(1)) u (
            .I(nav_data[i]), .C(), .PAD(pad_nav_data[i]),
            .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    end
    for (genvar i = 0; i < 6; i = i + 1) begin : g_nav_valid
        bds_bb_pad_bit #(.OUTPUT_MODE(1)) u (
            .I(nav_valid[i]), .C(), .PAD(pad_nav_valid[i]),
            .POC(poc), .VDD(VDD), .VSS(VSS), .VDDPST(VDDPST), .VSSPST(VSSPST));
    end

    bds_bb_6ch_core core (
        .clk(clk), .rst_n(rst_n), .IF(IF), .if_valid(if_valid), .if_ready(if_ready),
        .cfg_valid(cfg_valid), .cfg_channel(cfg_channel), .cfg_prn(cfg_prn),
        .cfg_enable(cfg_enable), .capture_ok(capture_ok), .bit_sync_ok(bit_sync_ok),
        .nav_data(nav_data), .nav_valid(nav_valid)
    );
endmodule
