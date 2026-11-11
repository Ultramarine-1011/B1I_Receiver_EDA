/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : O-2018.06-SP1
// Date      : Tue Nov 10 18:00:35 2026
/////////////////////////////////////////////////////////////


module b1i_prn_gen_DW01_inc_0 ( A, SUM );
  input [10:0] A;
  output [10:0] SUM;

  wire   [10:2] carry;

  ADDHX1 U1_1_9 ( .A(A[9]), .B(carry[9]), .CO(carry[10]), .S(SUM[9]) );
  ADDHX1 U1_1_8 ( .A(A[8]), .B(carry[8]), .CO(carry[9]), .S(SUM[8]) );
  ADDHX1 U1_1_4 ( .A(A[4]), .B(carry[4]), .CO(carry[5]), .S(SUM[4]) );
  ADDHX1 U1_1_3 ( .A(A[3]), .B(carry[3]), .CO(carry[4]), .S(SUM[3]) );
  ADDHX1 U1_1_2 ( .A(A[2]), .B(carry[2]), .CO(carry[3]), .S(SUM[2]) );
  ADDHX1 U1_1_7 ( .A(A[7]), .B(carry[7]), .CO(carry[8]), .S(SUM[7]) );
  ADDHX1 U1_1_6 ( .A(A[6]), .B(carry[6]), .CO(carry[7]), .S(SUM[6]) );
  ADDHX1 U1_1_5 ( .A(A[5]), .B(carry[5]), .CO(carry[6]), .S(SUM[5]) );
  ADDHX1 U1_1_1 ( .A(A[1]), .B(A[0]), .CO(carry[2]), .S(SUM[1]) );
  INVX2 U1 ( .A(A[0]), .Y(SUM[0]) );
  XOR2X1 U2 ( .A(carry[10]), .B(A[10]), .Y(SUM[10]) );
endmodule


module b1i_prn_gen ( clk, rst_n, load, chip_enable, prn_select, chip, 
        chip_index, configured, epoch );
  input [5:0] prn_select;
  output [10:0] chip_index;
  input clk, rst_n, load, chip_enable;
  output chip, configured, epoch;
  wire   N289, N290, N291, N292, N293, N294, N295, N296, N297, N298, N299,
         N368, n37, n40, n41, n42, n47, n131, n132, n133, n134, n135, n136,
         n137, n138, n139, n140, n141, n142, n143, n144, n145, n146, n147,
         n148, n149, n150, n151, n152, n153, n154, n155, n156, n157, n158,
         n159, n160, n161, n162, n163, n164, n165, n166, n167, n168, n169,
         n170, n171, n172, n173, n174, n175, n176, n177, n178, n179, n180,
         n181, n182, n183, n184, n185, n186, n187, n188, n189, n190, n191,
         n192, n193, n194, n195, n196, n197, n198, n199, n200, n201, n202,
         n203, n204, n205, n206, n207, n208, n209, n210, n211, n212, n213,
         n214, n215, n216, n217, n218, n219, n220, n221, n222, n223, n224,
         n225, n226, n227, n228, n229, n230, n231, n232, n233, n234, n235,
         n236, n237, n238, n239, n240, n241, n242, n243, n244, n245, n246,
         n247, n248, n249, n250, n251, n252, n253, n254, n255, n256, n257,
         n258, n259, n260, n261, n262, n263, n264, n265, n266, n267, n268,
         n269, n270, n271, n272, n273, n274, n275, n276, n277, n278, n279,
         n280, n281;
  wire   [10:0] g1_state;
  wire   [10:0] g2_state;
  wire   [5:0] active_prn;

  b1i_prn_gen_DW01_inc_0 add_124 ( .A(chip_index), .SUM({N299, N298, N297, 
        N296, N295, N294, N293, N292, N291, N290, N289}) );
  DFFRX1 \g1_state_reg[8]  ( .D(n139), .CK(clk), .RN(rst_n), .QN(n214) );
  DFFRX1 \g1_state_reg[6]  ( .D(n141), .CK(clk), .RN(rst_n), .QN(n212) );
  DFFSX2 \g1_state_reg[9]  ( .D(n138), .CK(clk), .SN(rst_n), .QN(n215) );
  DFFSX2 \g1_state_reg[7]  ( .D(n140), .CK(clk), .SN(rst_n), .QN(n213) );
  DFFSX2 \g1_state_reg[5]  ( .D(n142), .CK(clk), .SN(rst_n), .QN(n211) );
  DFFRX1 \g2_state_reg[4]  ( .D(n154), .CK(clk), .RN(rst_n), .Q(n281), .QN(
        n192) );
  DFFRX1 \chip_index_reg[10]  ( .D(n159), .CK(clk), .RN(rst_n), .Q(
        chip_index[10]), .QN(n37) );
  DFFRX1 \chip_index_reg[5]  ( .D(n164), .CK(clk), .RN(rst_n), .Q(
        chip_index[5]), .QN(n42) );
  DFFRX1 \chip_index_reg[6]  ( .D(n163), .CK(clk), .RN(rst_n), .Q(
        chip_index[6]), .QN(n41) );
  DFFRX1 \chip_index_reg[7]  ( .D(n162), .CK(clk), .RN(rst_n), .Q(
        chip_index[7]), .QN(n40) );
  DFFRX1 \chip_index_reg[0]  ( .D(n169), .CK(clk), .RN(rst_n), .Q(
        chip_index[0]), .QN(n47) );
  DFFSXL \g2_state_reg[9]  ( .D(n149), .CK(clk), .SN(rst_n), .Q(g2_state[9]), 
        .QN(n197) );
  DFFSXL \g2_state_reg[7]  ( .D(n151), .CK(clk), .SN(rst_n), .Q(g2_state[7]), 
        .QN(n195) );
  DFFSXL \g2_state_reg[5]  ( .D(n153), .CK(clk), .SN(rst_n), .Q(g2_state[5]), 
        .QN(n193) );
  DFFSXL \g2_state_reg[3]  ( .D(n155), .CK(clk), .SN(rst_n), .Q(g2_state[3]), 
        .QN(n191) );
  DFFSXL \g2_state_reg[1]  ( .D(n157), .CK(clk), .SN(rst_n), .Q(g2_state[1]), 
        .QN(n187) );
  DFFSXL \g1_state_reg[3]  ( .D(n144), .CK(clk), .SN(rst_n), .Q(g1_state[3]), 
        .QN(n209) );
  DFFSXL \g1_state_reg[1]  ( .D(n147), .CK(clk), .SN(rst_n), .Q(g1_state[1]), 
        .QN(n206) );
  DFFRXL \active_prn_reg[0]  ( .D(n136), .CK(clk), .RN(rst_n), .Q(
        active_prn[0]), .QN(n274) );
  DFFRXL configured_reg ( .D(n170), .CK(clk), .RN(rst_n), .Q(configured), .QN(
        n175) );
  DFFRXL \active_prn_reg[5]  ( .D(n135), .CK(clk), .RN(rst_n), .Q(
        active_prn[5]) );
  DFFRXL \active_prn_reg[4]  ( .D(n134), .CK(clk), .RN(rst_n), .Q(
        active_prn[4]) );
  DFFRXL \active_prn_reg[3]  ( .D(n133), .CK(clk), .RN(rst_n), .Q(
        active_prn[3]) );
  DFFRXL \active_prn_reg[2]  ( .D(n132), .CK(clk), .RN(rst_n), .Q(
        active_prn[2]), .QN(n277) );
  DFFRXL \active_prn_reg[1]  ( .D(n131), .CK(clk), .RN(rst_n), .Q(
        active_prn[1]) );
  DFFRXL epoch_reg ( .D(N368), .CK(clk), .RN(rst_n), .Q(epoch) );
  DFFRXL \chip_index_reg[1]  ( .D(n168), .CK(clk), .RN(rst_n), .Q(
        chip_index[1]), .QN(n180) );
  DFFRXL \chip_index_reg[8]  ( .D(n161), .CK(clk), .RN(rst_n), .Q(
        chip_index[8]), .QN(n184) );
  DFFRXL \chip_index_reg[3]  ( .D(n166), .CK(clk), .RN(rst_n), .Q(
        chip_index[3]), .QN(n182) );
  DFFRXL \chip_index_reg[2]  ( .D(n167), .CK(clk), .RN(rst_n), .Q(
        chip_index[2]), .QN(n181) );
  DFFRXL \chip_index_reg[4]  ( .D(n165), .CK(clk), .RN(rst_n), .Q(
        chip_index[4]), .QN(n183) );
  DFFRXL \chip_index_reg[9]  ( .D(n160), .CK(clk), .RN(rst_n), .Q(
        chip_index[9]), .QN(n185) );
  DFFRXL \g2_state_reg[8]  ( .D(n150), .CK(clk), .RN(rst_n), .Q(g2_state[8]), 
        .QN(n196) );
  DFFRXL \g1_state_reg[2]  ( .D(n145), .CK(clk), .RN(rst_n), .Q(g1_state[2]), 
        .QN(n207) );
  DFFRXL \g1_state_reg[0]  ( .D(n146), .CK(clk), .RN(rst_n), .Q(g1_state[0]), 
        .QN(n208) );
  DFFRXL \g1_state_reg[4]  ( .D(n143), .CK(clk), .RN(rst_n), .Q(g1_state[4]), 
        .QN(n210) );
  DFFRXL \g2_state_reg[2]  ( .D(n156), .CK(clk), .RN(rst_n), .Q(g2_state[2]), 
        .QN(n189) );
  DFFRXL \g2_state_reg[6]  ( .D(n152), .CK(clk), .RN(rst_n), .Q(g2_state[6]), 
        .QN(n194) );
  DFFRXL \g2_state_reg[0]  ( .D(n158), .CK(clk), .RN(rst_n), .Q(g2_state[0]), 
        .QN(n186) );
  DFFRXL \g2_state_reg[10]  ( .D(n148), .CK(clk), .RN(rst_n), .Q(g2_state[10]), 
        .QN(n198) );
  DFFRXL \g1_state_reg[10]  ( .D(n137), .CK(clk), .RN(rst_n), .Q(g1_state[10]), 
        .QN(n216) );
  BUFX2 U161 ( .A(n174), .Y(n172) );
  BUFX2 U162 ( .A(n174), .Y(n171) );
  BUFX2 U163 ( .A(n174), .Y(n173) );
  BUFX2 U164 ( .A(n179), .Y(n174) );
  NAND3XL U165 ( .A(configured), .B(n223), .C(chip_enable), .Y(n188) );
  NOR2X2 U166 ( .A(N368), .B(load), .Y(n190) );
  NOR2X2 U167 ( .A(n274), .B(active_prn[1]), .Y(n249) );
  NAND2BX2 U168 ( .AN(n188), .B(n218), .Y(n178) );
  MXI2X1 U169 ( .A(n175), .B(n176), .S0(load), .Y(n170) );
  XOR2X1 U170 ( .A(prn_select[5]), .B(n177), .Y(n176) );
  AOI211X1 U171 ( .A0(prn_select[2]), .A1(prn_select[1]), .B0(prn_select[4]), 
        .C0(prn_select[3]), .Y(n177) );
  OAI2B2X1 U172 ( .A1N(N289), .A0(n178), .B0(n47), .B1(n173), .Y(n169) );
  OAI2B2X1 U173 ( .A1N(N290), .A0(n178), .B0(n180), .B1(n173), .Y(n168) );
  OAI2B2X1 U174 ( .A1N(N291), .A0(n178), .B0(n181), .B1(n173), .Y(n167) );
  OAI2B2X1 U175 ( .A1N(N292), .A0(n178), .B0(n182), .B1(n173), .Y(n166) );
  OAI2B2X1 U176 ( .A1N(N293), .A0(n178), .B0(n183), .B1(n173), .Y(n165) );
  OAI2B2X1 U177 ( .A1N(N294), .A0(n178), .B0(n42), .B1(n173), .Y(n164) );
  OAI2B2X1 U178 ( .A1N(N295), .A0(n178), .B0(n41), .B1(n173), .Y(n163) );
  OAI2B2X1 U179 ( .A1N(N296), .A0(n178), .B0(n40), .B1(n172), .Y(n162) );
  OAI2B2X1 U180 ( .A1N(N297), .A0(n178), .B0(n184), .B1(n172), .Y(n161) );
  OAI2B2X1 U181 ( .A1N(N298), .A0(n178), .B0(n185), .B1(n172), .Y(n160) );
  OAI2B2X1 U182 ( .A1N(N299), .A0(n178), .B0(n37), .B1(n172), .Y(n159) );
  OAI22X1 U183 ( .A0(n171), .A1(n186), .B0(n178), .B1(n187), .Y(n158) );
  OAI221X1 U184 ( .A0(n172), .A1(n187), .B0(n188), .B1(n189), .C0(n190), .Y(
        n157) );
  OAI22X1 U185 ( .A0(n171), .A1(n189), .B0(n178), .B1(n191), .Y(n156) );
  OAI221X1 U186 ( .A0(n172), .A1(n191), .B0(n188), .B1(n192), .C0(n190), .Y(
        n155) );
  OAI22X1 U187 ( .A0(n171), .A1(n192), .B0(n178), .B1(n193), .Y(n154) );
  OAI221X1 U188 ( .A0(n172), .A1(n193), .B0(n188), .B1(n194), .C0(n190), .Y(
        n153) );
  OAI22X1 U189 ( .A0(n171), .A1(n194), .B0(n178), .B1(n195), .Y(n152) );
  OAI221X1 U190 ( .A0(n172), .A1(n195), .B0(n188), .B1(n196), .C0(n190), .Y(
        n151) );
  OAI22X1 U191 ( .A0(n171), .A1(n196), .B0(n178), .B1(n197), .Y(n150) );
  OAI221X1 U192 ( .A0(n172), .A1(n197), .B0(n188), .B1(n198), .C0(n190), .Y(
        n149) );
  OAI22X1 U193 ( .A0(n171), .A1(n198), .B0(n199), .B1(n178), .Y(n148) );
  XOR2X1 U194 ( .A(n200), .B(n201), .Y(n199) );
  XOR2X1 U195 ( .A(n202), .B(n203), .Y(n201) );
  XOR2X1 U196 ( .A(n204), .B(n205), .Y(n200) );
  XOR2X1 U197 ( .A(n197), .B(g2_state[6]), .Y(n204) );
  OAI221X1 U198 ( .A0(n172), .A1(n206), .B0(n188), .B1(n207), .C0(n190), .Y(
        n147) );
  OAI22X1 U199 ( .A0(n171), .A1(n208), .B0(n178), .B1(n206), .Y(n146) );
  OAI22X1 U200 ( .A0(n171), .A1(n207), .B0(n178), .B1(n209), .Y(n145) );
  OAI221X1 U201 ( .A0(n172), .A1(n209), .B0(n188), .B1(n210), .C0(n190), .Y(
        n144) );
  OAI22X1 U202 ( .A0(n171), .A1(n210), .B0(n178), .B1(n211), .Y(n143) );
  OAI221X1 U203 ( .A0(n172), .A1(n211), .B0(n188), .B1(n212), .C0(n190), .Y(
        n142) );
  OAI22X1 U204 ( .A0(n171), .A1(n212), .B0(n178), .B1(n213), .Y(n141) );
  OAI221X1 U205 ( .A0(n172), .A1(n213), .B0(n188), .B1(n214), .C0(n190), .Y(
        n140) );
  OAI22X1 U206 ( .A0(n171), .A1(n214), .B0(n178), .B1(n215), .Y(n139) );
  OAI221X1 U207 ( .A0(n172), .A1(n215), .B0(n188), .B1(n216), .C0(n190), .Y(
        n138) );
  OAI22X1 U208 ( .A0(n171), .A1(n216), .B0(n217), .B1(n178), .Y(n137) );
  XOR2X1 U209 ( .A(n219), .B(n220), .Y(n217) );
  XOR2X1 U210 ( .A(g1_state[2]), .B(n221), .Y(n220) );
  XOR2X1 U211 ( .A(g1_state[4]), .B(g1_state[3]), .Y(n221) );
  XOR2X1 U212 ( .A(n208), .B(n222), .Y(n219) );
  XOR2X1 U213 ( .A(g1_state[1]), .B(g1_state[10]), .Y(n222) );
  CLKNAND2X2 U214 ( .A(n223), .B(n188), .Y(n179) );
  MX2X1 U215 ( .A(active_prn[0]), .B(prn_select[0]), .S0(load), .Y(n136) );
  MX2X1 U216 ( .A(prn_select[5]), .B(active_prn[5]), .S0(n223), .Y(n135) );
  MX2X1 U217 ( .A(prn_select[4]), .B(active_prn[4]), .S0(n223), .Y(n134) );
  MX2X1 U218 ( .A(prn_select[3]), .B(active_prn[3]), .S0(n223), .Y(n133) );
  MX2X1 U219 ( .A(prn_select[2]), .B(active_prn[2]), .S0(n223), .Y(n132) );
  MX2X1 U220 ( .A(prn_select[1]), .B(active_prn[1]), .S0(n223), .Y(n131) );
  NOR2X1 U221 ( .A(n175), .B(n224), .Y(chip) );
  XOR2X1 U222 ( .A(g1_state[0]), .B(n225), .Y(n224) );
  MXI2X1 U223 ( .A(n226), .B(n227), .S0(active_prn[5]), .Y(n225) );
  NOR3X1 U224 ( .A(n228), .B(active_prn[4]), .C(active_prn[3]), .Y(n227) );
  MXI2X1 U225 ( .A(n229), .B(n230), .S0(active_prn[2]), .Y(n228) );
  MXI2X1 U226 ( .A(n231), .B(n232), .S0(g2_state[0]), .Y(n230) );
  CLKNAND2X2 U227 ( .A(n233), .B(n234), .Y(n229) );
  MXI2X1 U228 ( .A(n235), .B(n236), .S0(g2_state[2]), .Y(n234) );
  MXI2X1 U229 ( .A(n237), .B(n238), .S0(g2_state[3]), .Y(n233) );
  MX4XL U230 ( .A(n239), .B(n240), .C(n241), .D(n242), .S0(active_prn[4]), 
        .S1(active_prn[3]), .Y(n226) );
  BMXIX2 U231 ( .A(n243), .S(n244), .M1(g2_state[6]), .M0(g2_state[5]), .X2(
        active_prn[2]), .PPN(n242) );
  OAI221X1 U232 ( .A0(n186), .A1(n245), .B0(n187), .B1(n246), .C0(n247), .Y(
        n244) );
  AOI22XL U233 ( .A0(n248), .A1(g2_state[3]), .B0(n249), .B1(g2_state[2]), .Y(
        n247) );
  OAI221X1 U234 ( .A0(g2_state[0]), .A1(n245), .B0(g2_state[1]), .B1(n246), 
        .C0(n250), .Y(n243) );
  AOI22XL U235 ( .A0(n248), .A1(n191), .B0(n249), .B1(n189), .Y(n250) );
  MXI2X1 U236 ( .A(n251), .B(n252), .S0(active_prn[2]), .Y(n241) );
  MXI2X1 U237 ( .A(n253), .B(n254), .S0(g2_state[8]), .Y(n252) );
  OAI211XL U238 ( .A0(g2_state[5]), .A1(n255), .B0(n256), .C0(n257), .Y(n254)
         );
  AOI22XL U239 ( .A0(n249), .A1(n191), .B0(n258), .B1(n189), .Y(n257) );
  OAI211XL U240 ( .A0(n193), .A1(n255), .B0(n259), .C0(n260), .Y(n253) );
  AOI22XL U241 ( .A0(n249), .A1(g2_state[3]), .B0(n258), .B1(g2_state[2]), .Y(
        n260) );
  CLKINVX1 U242 ( .A(n248), .Y(n255) );
  AOI221XL U243 ( .A0(n248), .A1(n261), .B0(n249), .B1(n262), .C0(n263), .Y(
        n251) );
  MXI2X1 U244 ( .A(n264), .B(n265), .S0(g2_state[8]), .Y(n263) );
  AOI22XL U245 ( .A0(n266), .A1(n194), .B0(n258), .B1(n195), .Y(n265) );
  AOI22XL U246 ( .A0(n266), .A1(g2_state[6]), .B0(n258), .B1(g2_state[7]), .Y(
        n264) );
  XOR2X1 U247 ( .A(n281), .B(g2_state[9]), .Y(n262) );
  XOR2X1 U248 ( .A(g2_state[10]), .B(g2_state[0]), .Y(n261) );
  MXI2X1 U249 ( .A(n267), .B(n268), .S0(active_prn[2]), .Y(n240) );
  AOI21X1 U250 ( .A0(n266), .A1(n269), .B0(n270), .Y(n268) );
  MX2X1 U251 ( .A(n238), .B(n237), .S0(n195), .Y(n270) );
  OAI21X1 U252 ( .A0(n186), .A1(n246), .B0(n231), .Y(n237) );
  AOI22XL U253 ( .A0(g2_state[1]), .A1(n249), .B0(g2_state[2]), .B1(n248), .Y(
        n231) );
  OAI21X1 U254 ( .A0(g2_state[0]), .A1(n246), .B0(n232), .Y(n238) );
  AOI22XL U255 ( .A0(n187), .A1(n249), .B0(n189), .B1(n248), .Y(n232) );
  XOR2X1 U256 ( .A(g2_state[6]), .B(g2_state[5]), .Y(n269) );
  AOI221XL U257 ( .A0(n266), .A1(n205), .B0(n248), .B1(n203), .C0(n271), .Y(
        n267) );
  MXI2X1 U258 ( .A(n272), .B(n273), .S0(g2_state[7]), .Y(n271) );
  AOI22XL U259 ( .A0(n249), .A1(n194), .B0(n258), .B1(n193), .Y(n273) );
  AOI22XL U260 ( .A0(n249), .A1(g2_state[6]), .B0(n258), .B1(g2_state[5]), .Y(
        n272) );
  XOR2X1 U261 ( .A(g2_state[8]), .B(g2_state[0]), .Y(n203) );
  NOR2X1 U262 ( .A(active_prn[1]), .B(active_prn[0]), .Y(n248) );
  XOR2X1 U263 ( .A(g2_state[7]), .B(g2_state[3]), .Y(n205) );
  AOI21X1 U264 ( .A0(n275), .A1(n276), .B0(n277), .Y(n239) );
  CLKNAND2X2 U265 ( .A(n258), .B(n202), .Y(n276) );
  XOR2X1 U266 ( .A(g2_state[10]), .B(g2_state[2]), .Y(n202) );
  CLKINVX1 U267 ( .A(n246), .Y(n258) );
  CLKNAND2X2 U268 ( .A(active_prn[1]), .B(n274), .Y(n246) );
  MXI2X1 U269 ( .A(n235), .B(n236), .S0(g2_state[10]), .Y(n275) );
  CLKINVX1 U270 ( .A(n256), .Y(n236) );
  CLKNAND2X2 U271 ( .A(n266), .B(n187), .Y(n256) );
  CLKINVX1 U272 ( .A(n259), .Y(n235) );
  CLKNAND2X2 U273 ( .A(n266), .B(g2_state[1]), .Y(n259) );
  CLKINVX1 U274 ( .A(n245), .Y(n266) );
  CLKNAND2X2 U275 ( .A(active_prn[1]), .B(active_prn[0]), .Y(n245) );
  NOR2X1 U276 ( .A(n218), .B(n188), .Y(N368) );
  CLKINVX1 U277 ( .A(load), .Y(n223) );
  NAND4X1 U278 ( .A(chip_index[9]), .B(chip_index[8]), .C(n278), .D(n279), .Y(
        n218) );
  NOR4X1 U279 ( .A(n280), .B(chip_index[1]), .C(n40), .D(n37), .Y(n279) );
  OR3X1 U280 ( .A(n42), .B(n47), .C(n41), .Y(n280) );
  NOR3X1 U281 ( .A(n183), .B(n181), .C(n182), .Y(n278) );
endmodule

