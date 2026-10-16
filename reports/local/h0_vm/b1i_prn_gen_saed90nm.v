/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : K-2015.06
// Date      : Fri Oct 16 15:16:41 2026
/////////////////////////////////////////////////////////////


module b1i_prn_gen_DW01_inc_0 ( A, SUM );
  input [10:0] A;
  output [10:0] SUM;

  wire   [10:2] carry;

  HADDX1 U1_1_9 ( .A0(A[9]), .B0(carry[9]), .C1(carry[10]), .SO(SUM[9]) );
  HADDX1 U1_1_8 ( .A0(A[8]), .B0(carry[8]), .C1(carry[9]), .SO(SUM[8]) );
  HADDX1 U1_1_7 ( .A0(A[7]), .B0(carry[7]), .C1(carry[8]), .SO(SUM[7]) );
  HADDX1 U1_1_6 ( .A0(A[6]), .B0(carry[6]), .C1(carry[7]), .SO(SUM[6]) );
  HADDX1 U1_1_5 ( .A0(A[5]), .B0(carry[5]), .C1(carry[6]), .SO(SUM[5]) );
  HADDX1 U1_1_4 ( .A0(A[4]), .B0(carry[4]), .C1(carry[5]), .SO(SUM[4]) );
  HADDX1 U1_1_3 ( .A0(A[3]), .B0(carry[3]), .C1(carry[4]), .SO(SUM[3]) );
  HADDX1 U1_1_2 ( .A0(A[2]), .B0(carry[2]), .C1(carry[3]), .SO(SUM[2]) );
  HADDX1 U1_1_1 ( .A0(A[1]), .B0(A[0]), .C1(carry[2]), .SO(SUM[1]) );
  INVX0 U1 ( .INP(A[0]), .ZN(SUM[0]) );
  XOR2X1 U2 ( .IN1(carry[10]), .IN2(A[10]), .Q(SUM[10]) );
endmodule


module b1i_prn_gen ( clk, rst_n, load, chip_enable, prn_select, chip, 
        chip_index, configured, epoch );
  input [5:0] prn_select;
  output [10:0] chip_index;
  input clk, rst_n, load, chip_enable;
  output chip, configured, epoch;
  wire   N289, N290, N291, N292, N293, N294, N295, N296, N297, N298, N299,
         N368, n9, n10, n11, n12, n13, n18, n20, n21, n102, n103, n104, n105,
         n106, n107, n108, n109, n110, n111, n112, n113, n114, n115, n116,
         n117, n118, n119, n120, n121, n122, n123, n124, n125, n126, n127,
         n128, n129, n130, n131, n132, n133, n134, n135, n136, n137, n138,
         n139, n140, n141, n142, n143, n144, n145, n146, n147, n148, n149,
         n150, n151, n152, n153, n154, n155, n156, n158, n159, n160, n161,
         n162, n163, n164, n165, n166, n167, n168, n169, n170, n171, n172,
         n173, n174, n175, n176, n177, n178, n179, n180, n181, n182, n183,
         n184, n185, n186, n187, n188, n189, n190, n201, n202, n203, n204,
         n205, n206, n207, n208, n209, n210, n211, n212, n213, n214, n215,
         n216, n217, n218, n219, n220, n221, n222, n223, n224, n225, n226,
         n227, n228, n229, n230, n231, n232, n233, n234, n235, n236, n237,
         n238, n239, n240, n241, n242, n243, n244, n245, n246, n247, n248,
         n249, n250, n251, n252, n253, n254, n255, n256, n257, n258, n259,
         n260, n261, n262, n263, n264, n265, n266, n267, n268, n269, n270,
         n271, n272, n273, n274, n275, n276, n277, n278, n279, n280, n281,
         n282, n283, n284, n285, n286, n287, n288, n289, n290, n291, n292,
         n293, n294, n295, n296, n297;

  DFFARX1 \chip_index_reg[10]  ( .D(n140), .CLK(clk), .RSTB(n152), .Q(
        chip_index[10]) );
  DFFARX1 \chip_index_reg[0]  ( .D(n117), .CLK(clk), .RSTB(n152), .Q(
        chip_index[0]), .QN(n20) );
  DFFARX1 \chip_index_reg[1]  ( .D(n116), .CLK(clk), .RSTB(n152), .Q(
        chip_index[1]), .QN(n292) );
  DFFARX1 \chip_index_reg[2]  ( .D(n115), .CLK(clk), .RSTB(n151), .Q(
        chip_index[2]), .QN(n293) );
  DFFARX1 \chip_index_reg[3]  ( .D(n114), .CLK(clk), .RSTB(n151), .Q(
        chip_index[3]), .QN(n294) );
  DFFARX1 \chip_index_reg[4]  ( .D(n113), .CLK(clk), .RSTB(n151), .Q(
        chip_index[4]) );
  DFFARX1 \chip_index_reg[5]  ( .D(n112), .CLK(clk), .RSTB(n151), .Q(
        chip_index[5]), .QN(n296) );
  DFFARX1 \chip_index_reg[6]  ( .D(n111), .CLK(clk), .RSTB(n151), .Q(
        chip_index[6]), .QN(n297) );
  DFFARX1 \chip_index_reg[7]  ( .D(n110), .CLK(clk), .RSTB(n151), .Q(
        chip_index[7]), .QN(n295) );
  DFFARX1 \chip_index_reg[8]  ( .D(n109), .CLK(clk), .RSTB(n151), .Q(
        chip_index[8]) );
  DFFARX1 \chip_index_reg[9]  ( .D(n108), .CLK(clk), .RSTB(n151), .Q(
        chip_index[9]) );
  b1i_prn_gen_DW01_inc_0 add_124 ( .A(chip_index), .SUM({N299, N298, N297, 
        N296, N295, N294, N293, N292, N291, N290, N289}) );
  DFFARX1 epoch_reg ( .D(N368), .CLK(clk), .RSTB(rst_n), .Q(epoch) );
  DFFARX1 configured_reg ( .D(n141), .CLK(clk), .RSTB(rst_n), .Q(configured), 
        .QN(n21) );
  DFFARX1 \active_prn_reg[0]  ( .D(n107), .CLK(clk), .RSTB(rst_n), .Q(n203), 
        .QN(n18) );
  DFFARX1 \active_prn_reg[1]  ( .D(n106), .CLK(clk), .RSTB(n152), .Q(n204), 
        .QN(n282) );
  DFFARX1 \active_prn_reg[5]  ( .D(n102), .CLK(clk), .RSTB(n151), .Q(n209), 
        .QN(n281) );
  DFFARX1 \active_prn_reg[4]  ( .D(n103), .CLK(clk), .RSTB(n151), .Q(n208), 
        .QN(n11) );
  DFFARX1 \active_prn_reg[3]  ( .D(n104), .CLK(clk), .RSTB(n152), .Q(n207), 
        .QN(n12) );
  DFFARX1 \active_prn_reg[2]  ( .D(n105), .CLK(clk), .RSTB(n152), .Q(n205), 
        .QN(n13) );
  DFFARX1 \g1_state_reg[8]  ( .D(n131), .CLK(clk), .RSTB(n150), .Q(n169) );
  DFFARX1 \g1_state_reg[6]  ( .D(n133), .CLK(clk), .RSTB(n150), .Q(n167) );
  DFFARX1 \g1_state_reg[4]  ( .D(n135), .CLK(clk), .RSTB(n150), .Q(n165), .QN(
        n276) );
  DFFARX1 \g1_state_reg[2]  ( .D(n137), .CLK(clk), .RSTB(n150), .Q(n162), .QN(
        n278) );
  DFFARX1 \g1_state_reg[0]  ( .D(n139), .CLK(clk), .RSTB(n150), .Q(n159), .QN(
        n280) );
  DFFARX1 \g2_state_reg[10]  ( .D(n118), .CLK(clk), .RSTB(n150), .Q(n185), 
        .QN(n289) );
  DFFARX1 \g2_state_reg[4]  ( .D(n124), .CLK(clk), .RSTB(n150), .Q(n179), .QN(
        n291) );
  DFFARX1 \g1_state_reg[10]  ( .D(n129), .CLK(clk), .RSTB(n150), .Q(n171), 
        .QN(n275) );
  DFFARX1 \g2_state_reg[0]  ( .D(n128), .CLK(clk), .RSTB(n150), .Q(n175), .QN(
        n10) );
  DFFARX1 \g2_state_reg[6]  ( .D(n122), .CLK(clk), .RSTB(n150), .Q(n181), .QN(
        n286) );
  DFFARX1 \g2_state_reg[8]  ( .D(n120), .CLK(clk), .RSTB(n150), .Q(n183), .QN(
        n287) );
  DFFARX1 \g2_state_reg[2]  ( .D(n126), .CLK(clk), .RSTB(n150), .Q(n177), .QN(
        n283) );
  DFFASX1 \g2_state_reg[9]  ( .D(n119), .CLK(clk), .SETB(rst_n), .Q(n184), 
        .QN(n290) );
  DFFASX1 \g1_state_reg[3]  ( .D(n136), .CLK(clk), .SETB(n152), .Q(n164), .QN(
        n277) );
  DFFASX1 \g1_state_reg[1]  ( .D(n138), .CLK(clk), .SETB(n152), .Q(n160), .QN(
        n279) );
  DFFASX1 \g1_state_reg[9]  ( .D(n130), .CLK(clk), .SETB(n152), .Q(n170) );
  DFFASX1 \g1_state_reg[7]  ( .D(n132), .CLK(clk), .SETB(rst_n), .Q(n168) );
  DFFASX1 \g1_state_reg[5]  ( .D(n134), .CLK(clk), .SETB(n152), .Q(n166) );
  DFFASX1 \g2_state_reg[3]  ( .D(n125), .CLK(clk), .SETB(n152), .Q(n178), .QN(
        n285) );
  DFFASX1 \g2_state_reg[7]  ( .D(n121), .CLK(clk), .SETB(n152), .Q(n182), .QN(
        n288) );
  DFFASX1 \g2_state_reg[5]  ( .D(n123), .CLK(clk), .SETB(n152), .Q(n180), .QN(
        n284) );
  DFFASX1 \g2_state_reg[1]  ( .D(n127), .CLK(clk), .SETB(n152), .Q(n176), .QN(
        n9) );
  INVX0 U133 ( .INP(n158), .ZN(n142) );
  NBUFFX2 U134 ( .INP(n156), .Z(n148) );
  NBUFFX2 U135 ( .INP(n156), .Z(n147) );
  AND2X1 U136 ( .IN1(n161), .IN2(n201), .Q(n158) );
  NBUFFX2 U137 ( .INP(n156), .Z(n149) );
  OR2X1 U138 ( .IN1(load), .IN2(N368), .Q(n163) );
  NBUFFX2 U139 ( .INP(rst_n), .Z(n152) );
  NBUFFX2 U140 ( .INP(rst_n), .Z(n150) );
  NBUFFX2 U141 ( .INP(rst_n), .Z(n151) );
  INVX0 U142 ( .INP(n142), .ZN(n143) );
  INVX0 U143 ( .INP(n142), .ZN(n144) );
  INVX0 U144 ( .INP(n142), .ZN(n145) );
  INVX0 U145 ( .INP(n142), .ZN(n146) );
  MUX21X1 U146 ( .IN1(configured), .IN2(n153), .S(load), .Q(n141) );
  XOR2X1 U147 ( .IN1(n154), .IN2(prn_select[5]), .Q(n153) );
  OR3X1 U148 ( .IN1(prn_select[3]), .IN2(prn_select[4]), .IN3(n155), .Q(n154)
         );
  AND2X1 U149 ( .IN1(prn_select[2]), .IN2(prn_select[1]), .Q(n155) );
  AO22X1 U150 ( .IN1(n148), .IN2(chip_index[10]), .IN3(N299), .IN4(n145), .Q(
        n140) );
  AO22X1 U151 ( .IN1(n149), .IN2(n159), .IN3(n146), .IN4(n160), .Q(n139) );
  AO221X1 U152 ( .IN1(n147), .IN2(n160), .IN3(n161), .IN4(n162), .IN5(n163), 
        .Q(n138) );
  AO22X1 U153 ( .IN1(n149), .IN2(n162), .IN3(n145), .IN4(n164), .Q(n137) );
  AO221X1 U154 ( .IN1(n147), .IN2(n164), .IN3(n161), .IN4(n165), .IN5(n163), 
        .Q(n136) );
  AO22X1 U155 ( .IN1(n149), .IN2(n165), .IN3(n144), .IN4(n166), .Q(n135) );
  AO221X1 U156 ( .IN1(n147), .IN2(n166), .IN3(n161), .IN4(n167), .IN5(n163), 
        .Q(n134) );
  AO22X1 U157 ( .IN1(n149), .IN2(n167), .IN3(n144), .IN4(n168), .Q(n133) );
  AO221X1 U158 ( .IN1(n147), .IN2(n168), .IN3(n161), .IN4(n169), .IN5(n163), 
        .Q(n132) );
  AO22X1 U159 ( .IN1(n149), .IN2(n169), .IN3(n143), .IN4(n170), .Q(n131) );
  AO221X1 U160 ( .IN1(n147), .IN2(n170), .IN3(n161), .IN4(n171), .IN5(n163), 
        .Q(n130) );
  AO22X1 U161 ( .IN1(n148), .IN2(n171), .IN3(n146), .IN4(n172), .Q(n129) );
  XOR2X1 U162 ( .IN1(n173), .IN2(n174), .Q(n172) );
  XOR3X1 U163 ( .IN1(n278), .IN2(n279), .IN3(n280), .Q(n174) );
  XOR3X1 U164 ( .IN1(n275), .IN2(n276), .IN3(n277), .Q(n173) );
  AO22X1 U165 ( .IN1(n148), .IN2(n175), .IN3(n145), .IN4(n176), .Q(n128) );
  AO221X1 U166 ( .IN1(n147), .IN2(n176), .IN3(n161), .IN4(n177), .IN5(n163), 
        .Q(n127) );
  AO22X1 U167 ( .IN1(n148), .IN2(n177), .IN3(n145), .IN4(n178), .Q(n126) );
  AO221X1 U168 ( .IN1(n147), .IN2(n178), .IN3(n161), .IN4(n179), .IN5(n163), 
        .Q(n125) );
  AO22X1 U169 ( .IN1(n148), .IN2(n179), .IN3(n143), .IN4(n180), .Q(n124) );
  AO221X1 U170 ( .IN1(n147), .IN2(n180), .IN3(n161), .IN4(n181), .IN5(n163), 
        .Q(n123) );
  AO22X1 U171 ( .IN1(n148), .IN2(n181), .IN3(n146), .IN4(n182), .Q(n122) );
  AO221X1 U172 ( .IN1(n147), .IN2(n182), .IN3(n161), .IN4(n183), .IN5(n163), 
        .Q(n121) );
  AO22X1 U173 ( .IN1(n148), .IN2(n183), .IN3(n143), .IN4(n184), .Q(n120) );
  AO221X1 U174 ( .IN1(n147), .IN2(n184), .IN3(n161), .IN4(n185), .IN5(n163), 
        .Q(n119) );
  AO22X1 U175 ( .IN1(n148), .IN2(n185), .IN3(n146), .IN4(n186), .Q(n118) );
  XOR3X1 U176 ( .IN1(n187), .IN2(n188), .IN3(n189), .Q(n186) );
  XNOR3X1 U177 ( .IN1(n286), .IN2(n184), .IN3(n190), .Q(n189) );
  AO22X1 U178 ( .IN1(n148), .IN2(chip_index[0]), .IN3(N289), .IN4(n146), .Q(
        n117) );
  AO22X1 U179 ( .IN1(n148), .IN2(chip_index[1]), .IN3(N290), .IN4(n145), .Q(
        n116) );
  AO22X1 U180 ( .IN1(n148), .IN2(chip_index[2]), .IN3(N291), .IN4(n144), .Q(
        n115) );
  AO22X1 U181 ( .IN1(n148), .IN2(chip_index[3]), .IN3(N292), .IN4(n143), .Q(
        n114) );
  AO22X1 U182 ( .IN1(n148), .IN2(chip_index[4]), .IN3(N293), .IN4(n146), .Q(
        n113) );
  AO22X1 U183 ( .IN1(n148), .IN2(chip_index[5]), .IN3(N294), .IN4(n145), .Q(
        n112) );
  AO22X1 U184 ( .IN1(n147), .IN2(chip_index[6]), .IN3(N295), .IN4(n144), .Q(
        n111) );
  AO22X1 U185 ( .IN1(n147), .IN2(chip_index[7]), .IN3(N296), .IN4(n143), .Q(
        n110) );
  AO22X1 U186 ( .IN1(n147), .IN2(chip_index[8]), .IN3(N297), .IN4(n144), .Q(
        n109) );
  AO22X1 U187 ( .IN1(n148), .IN2(chip_index[9]), .IN3(N298), .IN4(n143), .Q(
        n108) );
  NOR2X0 U188 ( .IN1(n161), .IN2(load), .QN(n156) );
  INVX0 U189 ( .INP(n202), .ZN(n161) );
  MUX21X1 U190 ( .IN1(n203), .IN2(prn_select[0]), .S(load), .Q(n107) );
  MUX21X1 U191 ( .IN1(n204), .IN2(prn_select[1]), .S(load), .Q(n106) );
  MUX21X1 U192 ( .IN1(prn_select[2]), .IN2(n205), .S(n206), .Q(n105) );
  MUX21X1 U193 ( .IN1(prn_select[3]), .IN2(n207), .S(n206), .Q(n104) );
  MUX21X1 U194 ( .IN1(prn_select[4]), .IN2(n208), .S(n206), .Q(n103) );
  MUX21X1 U195 ( .IN1(prn_select[5]), .IN2(n209), .S(n206), .Q(n102) );
  NOR2X0 U196 ( .IN1(n21), .IN2(n210), .QN(chip) );
  XOR2X1 U197 ( .IN1(n159), .IN2(n211), .Q(n210) );
  MUX21X1 U198 ( .IN1(n212), .IN2(n213), .S(n281), .Q(n211) );
  MUX41X1 U199 ( .IN1(n214), .IN3(n215), .IN2(n216), .IN4(n217), .S0(n207), 
        .S1(n208), .Q(n213) );
  MUX21X1 U200 ( .IN1(n218), .IN2(n219), .S(n205), .Q(n217) );
  OA221X1 U201 ( .IN1(n220), .IN2(n221), .IN3(n222), .IN4(n223), .IN5(n224), 
        .Q(n219) );
  OA22X1 U202 ( .IN1(n225), .IN2(n226), .IN3(n227), .IN4(n228), .Q(n224) );
  XOR2X1 U203 ( .IN1(n180), .IN2(n283), .Q(n227) );
  XNOR2X1 U204 ( .IN1(n285), .IN2(n284), .Q(n225) );
  XOR2X1 U205 ( .IN1(n180), .IN2(n9), .Q(n222) );
  XNOR2X1 U206 ( .IN1(n284), .IN2(n10), .Q(n220) );
  OA221X1 U207 ( .IN1(n229), .IN2(n221), .IN3(n230), .IN4(n223), .IN5(n231), 
        .Q(n218) );
  OA22X1 U208 ( .IN1(n232), .IN2(n226), .IN3(n233), .IN4(n228), .Q(n231) );
  XOR2X1 U209 ( .IN1(n181), .IN2(n283), .Q(n233) );
  XOR2X1 U210 ( .IN1(n178), .IN2(n286), .Q(n232) );
  XNOR2X1 U211 ( .IN1(n176), .IN2(n181), .Q(n230) );
  XOR2X1 U212 ( .IN1(n175), .IN2(n286), .Q(n229) );
  MUX21X1 U213 ( .IN1(n234), .IN2(n235), .S(n205), .Q(n216) );
  OA221X1 U214 ( .IN1(n236), .IN2(n221), .IN3(n237), .IN4(n223), .IN5(n238), 
        .Q(n235) );
  OA22X1 U215 ( .IN1(n239), .IN2(n226), .IN3(n240), .IN4(n228), .Q(n238) );
  XNOR2X1 U216 ( .IN1(n288), .IN2(n9), .Q(n240) );
  XNOR2X1 U217 ( .IN1(n288), .IN2(n283), .Q(n239) );
  XOR2X1 U218 ( .IN1(n288), .IN2(n175), .Q(n237) );
  XOR2X1 U219 ( .IN1(n180), .IN2(n286), .Q(n236) );
  OA221X1 U220 ( .IN1(n187), .IN2(n226), .IN3(n241), .IN4(n223), .IN5(n242), 
        .Q(n234) );
  OA22X1 U221 ( .IN1(n243), .IN2(n228), .IN3(n188), .IN4(n221), .Q(n242) );
  XNOR2X1 U222 ( .IN1(n285), .IN2(n288), .Q(n188) );
  XNOR2X1 U223 ( .IN1(n182), .IN2(n181), .Q(n243) );
  XOR2X1 U224 ( .IN1(n182), .IN2(n284), .Q(n241) );
  XNOR2X1 U225 ( .IN1(n287), .IN2(n10), .Q(n187) );
  MUX21X1 U226 ( .IN1(n244), .IN2(n245), .S(n13), .Q(n215) );
  OA221X1 U227 ( .IN1(n246), .IN2(n221), .IN3(n247), .IN4(n223), .IN5(n248), 
        .Q(n245) );
  OA22X1 U228 ( .IN1(n249), .IN2(n226), .IN3(n250), .IN4(n228), .Q(n248) );
  XNOR2X1 U229 ( .IN1(n291), .IN2(n290), .Q(n250) );
  XOR2X1 U230 ( .IN1(n185), .IN2(n10), .Q(n249) );
  XOR2X1 U231 ( .IN1(n182), .IN2(n287), .Q(n247) );
  XOR2X1 U232 ( .IN1(n183), .IN2(n286), .Q(n246) );
  OA221X1 U233 ( .IN1(n251), .IN2(n221), .IN3(n252), .IN4(n223), .IN5(n253), 
        .Q(n244) );
  OA22X1 U234 ( .IN1(n254), .IN2(n226), .IN3(n255), .IN4(n228), .Q(n253) );
  INVX0 U235 ( .INP(n256), .ZN(n228) );
  XOR2X1 U236 ( .IN1(n178), .IN2(n287), .Q(n255) );
  INVX0 U237 ( .INP(n257), .ZN(n226) );
  XOR2X1 U238 ( .IN1(n183), .IN2(n284), .Q(n254) );
  INVX0 U239 ( .INP(n258), .ZN(n223) );
  XOR2X1 U240 ( .IN1(n183), .IN2(n283), .Q(n252) );
  INVX0 U241 ( .INP(n259), .ZN(n221) );
  XNOR2X1 U242 ( .IN1(n287), .IN2(n9), .Q(n251) );
  NAND3X0 U243 ( .IN1(n205), .IN2(n204), .IN3(n260), .QN(n214) );
  MUX21X1 U244 ( .IN1(n261), .IN2(n190), .S(n18), .Q(n260) );
  XNOR2X1 U245 ( .IN1(n289), .IN2(n177), .Q(n190) );
  XOR2X1 U246 ( .IN1(n289), .IN2(n9), .Q(n261) );
  NAND3X0 U247 ( .IN1(n262), .IN2(n12), .IN3(n11), .QN(n212) );
  MUX21X1 U248 ( .IN1(n263), .IN2(n264), .S(n13), .Q(n262) );
  AO21X1 U249 ( .IN1(n259), .IN2(n265), .IN3(n266), .Q(n264) );
  MUX21X1 U250 ( .IN1(n267), .IN2(n268), .S(n285), .Q(n266) );
  AO222X1 U251 ( .IN1(n257), .IN2(n177), .IN3(n258), .IN4(n175), .IN5(n256), 
        .IN6(n176), .Q(n268) );
  AO222X1 U252 ( .IN1(n257), .IN2(n283), .IN3(n258), .IN4(n10), .IN5(n256), 
        .IN6(n9), .Q(n267) );
  NOR2X0 U253 ( .IN1(n204), .IN2(n18), .QN(n256) );
  NOR2X0 U254 ( .IN1(n203), .IN2(n282), .QN(n258) );
  NOR2X0 U255 ( .IN1(n204), .IN2(n203), .QN(n257) );
  XOR2X1 U256 ( .IN1(n177), .IN2(n176), .Q(n265) );
  NOR2X0 U257 ( .IN1(n282), .IN2(n18), .QN(n259) );
  NOR2X0 U258 ( .IN1(n204), .IN2(n269), .QN(n263) );
  MUX21X1 U259 ( .IN1(n270), .IN2(n271), .S(n203), .Q(n269) );
  XOR2X1 U260 ( .IN1(n10), .IN2(n176), .Q(n271) );
  XNOR2X1 U261 ( .IN1(n175), .IN2(n177), .Q(n270) );
  NOR2X0 U262 ( .IN1(n201), .IN2(n202), .QN(N368) );
  NAND3X0 U263 ( .IN1(n206), .IN2(configured), .IN3(chip_enable), .QN(n202) );
  INVX0 U264 ( .INP(load), .ZN(n206) );
  NAND4X0 U265 ( .IN1(n292), .IN2(chip_index[10]), .IN3(n272), .IN4(n273), 
        .QN(n201) );
  NOR4X0 U266 ( .IN1(n274), .IN2(n295), .IN3(n293), .IN4(n294), .QN(n273) );
  NAND3X0 U267 ( .IN1(chip_index[9]), .IN2(chip_index[8]), .IN3(chip_index[4]), 
        .QN(n274) );
  NOR3X0 U268 ( .IN1(n20), .IN2(n296), .IN3(n297), .QN(n272) );
endmodule

