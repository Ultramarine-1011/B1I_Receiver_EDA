/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : K-2015.06
// Date      : Fri Oct 30 13:49:30 2026
/////////////////////////////////////////////////////////////


module d1_word_sync_DW01_sub_0 ( A, B, CI, DIFF, CO );
  input [63:0] A;
  input [63:0] B;
  output [63:0] DIFF;
  input CI;
  output CO;
  wire   \A[0] , n1, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15,
         n16, n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29,
         n30, n31, n32, n33, n34, n35, n36, n37, n38, n39, n40, n41, n42, n43,
         n44, n45, n46, n47, n48, n49, n50, n51, n52, n53, n54, n55, n56, n57,
         n58, n59, n60, n61, n62, n63, n64, n65, n66, n67, n68, n69, n70, n71,
         n72, n73, n74, n75, n76, n77, n78, n79, n80, n81, n82, n83, n84, n85,
         n86, n87, n88, n89, n90, n91, n92, n93, n94, n95;
  wire   [64:0] carry;
  assign DIFF[6] = A[6];
  assign DIFF[5] = A[5];
  assign DIFF[4] = A[4];
  assign DIFF[3] = A[3];
  assign DIFF[2] = A[2];
  assign DIFF[1] = A[1];
  assign DIFF[0] = \A[0] ;
  assign \A[0]  = A[0];

  FADDX1 U2_20 ( .A(A[20]), .B(n95), .CI(carry[20]), .CO(carry[21]), .S(
        DIFF[20]) );
  FADDX1 U2_15 ( .A(A[15]), .B(n95), .CI(carry[15]), .CO(carry[16]), .S(
        DIFF[15]) );
  FADDX1 U2_9 ( .A(A[9]), .B(n95), .CI(carry[9]), .CO(carry[10]), .S(DIFF[9])
         );
  FADDX1 U2_21 ( .A(A[21]), .B(n95), .CI(carry[21]), .CO(carry[22]), .S(
        DIFF[21]) );
  FADDX1 U2_16 ( .A(A[16]), .B(n95), .CI(carry[16]), .CO(carry[17]), .S(
        DIFF[16]) );
  FADDX1 U2_13 ( .A(A[13]), .B(n95), .CI(carry[13]), .CO(carry[14]), .S(
        DIFF[13]) );
  FADDX1 U2_12 ( .A(A[12]), .B(n95), .CI(carry[12]), .CO(carry[13]), .S(
        DIFF[12]) );
  FADDX1 U2_14 ( .A(A[14]), .B(n95), .CI(carry[14]), .CO(carry[15]), .S(
        DIFF[14]) );
  FADDX1 U2_8 ( .A(A[8]), .B(n95), .CI(carry[8]), .CO(carry[9]), .S(DIFF[8])
         );
  XOR2X1 U1 ( .IN1(n1), .IN2(carry[63]), .Q(DIFF[63]) );
  INVX1 U2 ( .INP(A[63]), .ZN(n1) );
  OR2X1 U3 ( .IN1(carry[52]), .IN2(A[52]), .Q(carry[53]) );
  AND2X1 U4 ( .IN1(n50), .IN2(n51), .Q(n3) );
  AND2X1 U5 ( .IN1(n37), .IN2(n38), .Q(n4) );
  AND2X1 U6 ( .IN1(n66), .IN2(n67), .Q(n5) );
  AND2X1 U7 ( .IN1(n10), .IN2(n28), .Q(n6) );
  AND2X1 U8 ( .IN1(n34), .IN2(n35), .Q(n7) );
  AND2X1 U9 ( .IN1(n5), .IN2(n68), .Q(n8) );
  AND2X1 U10 ( .IN1(n41), .IN2(n42), .Q(n9) );
  AND2X1 U11 ( .IN1(n24), .IN2(n25), .Q(n10) );
  AND2X1 U12 ( .IN1(n8), .IN2(n69), .Q(n11) );
  AND2X1 U13 ( .IN1(n11), .IN2(n70), .Q(n12) );
  AND2X1 U14 ( .IN1(n17), .IN2(n74), .Q(n13) );
  INVX0 U15 ( .INP(A[11]), .ZN(n14) );
  OR2X1 U16 ( .IN1(carry[10]), .IN2(n15), .Q(carry[12]) );
  NAND2X0 U17 ( .IN1(n54), .IN2(n14), .QN(n15) );
  AND2X1 U18 ( .IN1(n12), .IN2(n71), .Q(n16) );
  AND2X1 U19 ( .IN1(n21), .IN2(n73), .Q(n17) );
  AND2X1 U20 ( .IN1(n26), .IN2(n27), .Q(n18) );
  NAND2X0 U21 ( .IN1(n18), .IN2(n19), .QN(carry[20]) );
  AND2X1 U22 ( .IN1(n20), .IN2(n40), .Q(n19) );
  INVX0 U23 ( .INP(A[19]), .ZN(n20) );
  NAND2X0 U24 ( .IN1(n53), .IN2(n54), .QN(carry[11]) );
  NAND2X0 U25 ( .IN1(n48), .IN2(n49), .QN(carry[29]) );
  NAND2X0 U26 ( .IN1(n46), .IN2(n47), .QN(carry[32]) );
  NAND2X0 U27 ( .IN1(n24), .IN2(n25), .QN(carry[33]) );
  NAND2X0 U28 ( .IN1(n10), .IN2(n28), .QN(carry[34]) );
  NAND2X0 U29 ( .IN1(n50), .IN2(n51), .QN(carry[27]) );
  NAND2X0 U30 ( .IN1(n6), .IN2(n45), .QN(carry[35]) );
  NAND2X0 U31 ( .IN1(n26), .IN2(n27), .QN(carry[18]) );
  NAND2X0 U32 ( .IN1(n37), .IN2(n38), .QN(carry[36]) );
  NAND2X0 U33 ( .IN1(n4), .IN2(n36), .QN(carry[37]) );
  NAND2X0 U34 ( .IN1(n43), .IN2(n44), .QN(carry[38]) );
  NAND2X0 U35 ( .IN1(n76), .IN2(n77), .QN(carry[39]) );
  NAND2X0 U36 ( .IN1(n34), .IN2(n35), .QN(carry[25]) );
  NAND2X0 U37 ( .IN1(n41), .IN2(n42), .QN(carry[23]) );
  NAND2X0 U38 ( .IN1(n12), .IN2(n71), .QN(carry[58]) );
  AND2X1 U39 ( .IN1(n16), .IN2(n72), .Q(n21) );
  AND2X1 U40 ( .IN1(n30), .IN2(n31), .Q(n22) );
  AND2X1 U41 ( .IN1(n13), .IN2(n75), .Q(n23) );
  NAND2X0 U42 ( .IN1(n18), .IN2(n40), .QN(carry[19]) );
  INVX0 U43 ( .INP(carry[10]), .ZN(n53) );
  NAND2X1 U44 ( .IN1(n22), .IN2(n29), .QN(carry[31]) );
  INVX0 U45 ( .INP(carry[28]), .ZN(n48) );
  NAND2X0 U46 ( .IN1(n30), .IN2(n31), .QN(carry[30]) );
  INVX0 U47 ( .INP(carry[29]), .ZN(n30) );
  INVX0 U48 ( .INP(carry[31]), .ZN(n46) );
  NAND2X1 U49 ( .IN1(n3), .IN2(n39), .QN(carry[28]) );
  INVX0 U50 ( .INP(carry[32]), .ZN(n24) );
  INVX0 U51 ( .INP(carry[26]), .ZN(n50) );
  INVX0 U52 ( .INP(carry[17]), .ZN(n26) );
  NAND2X1 U53 ( .IN1(n7), .IN2(n33), .QN(carry[26]) );
  INVX0 U54 ( .INP(carry[24]), .ZN(n34) );
  NAND2X1 U55 ( .IN1(n9), .IN2(n52), .QN(carry[24]) );
  INVX0 U56 ( .INP(carry[22]), .ZN(n41) );
  NAND2X0 U57 ( .IN1(n16), .IN2(n72), .QN(carry[59]) );
  NAND2X0 U58 ( .IN1(n21), .IN2(n73), .QN(carry[60]) );
  NAND2X0 U59 ( .IN1(n17), .IN2(n74), .QN(carry[61]) );
  NAND2X0 U60 ( .IN1(n13), .IN2(n75), .QN(carry[62]) );
  INVX0 U61 ( .INP(carry[35]), .ZN(n37) );
  INVX0 U62 ( .INP(carry[37]), .ZN(n43) );
  INVX0 U63 ( .INP(carry[38]), .ZN(n76) );
  NAND2X0 U64 ( .IN1(n78), .IN2(n79), .QN(carry[40]) );
  INVX0 U65 ( .INP(carry[39]), .ZN(n78) );
  NAND2X0 U66 ( .IN1(n80), .IN2(n81), .QN(carry[41]) );
  INVX0 U67 ( .INP(carry[40]), .ZN(n80) );
  NAND2X0 U68 ( .IN1(n82), .IN2(n83), .QN(carry[42]) );
  INVX0 U69 ( .INP(carry[41]), .ZN(n82) );
  NAND2X0 U70 ( .IN1(n84), .IN2(n85), .QN(carry[43]) );
  INVX0 U71 ( .INP(carry[42]), .ZN(n84) );
  NAND2X0 U72 ( .IN1(n86), .IN2(n87), .QN(carry[44]) );
  INVX0 U73 ( .INP(carry[43]), .ZN(n86) );
  NAND2X0 U74 ( .IN1(n88), .IN2(n89), .QN(carry[45]) );
  INVX0 U75 ( .INP(carry[44]), .ZN(n88) );
  NAND2X0 U76 ( .IN1(n92), .IN2(n93), .QN(carry[46]) );
  INVX0 U77 ( .INP(carry[45]), .ZN(n92) );
  NAND2X0 U78 ( .IN1(n90), .IN2(n91), .QN(carry[47]) );
  INVX0 U79 ( .INP(carry[46]), .ZN(n90) );
  NAND2X0 U80 ( .IN1(n55), .IN2(n56), .QN(carry[48]) );
  INVX0 U81 ( .INP(carry[47]), .ZN(n55) );
  NAND2X0 U82 ( .IN1(n57), .IN2(n58), .QN(carry[49]) );
  INVX0 U83 ( .INP(carry[48]), .ZN(n57) );
  NAND2X0 U84 ( .IN1(n59), .IN2(n60), .QN(carry[50]) );
  INVX0 U85 ( .INP(carry[49]), .ZN(n59) );
  NAND2X0 U86 ( .IN1(n61), .IN2(n62), .QN(carry[51]) );
  INVX0 U87 ( .INP(carry[50]), .ZN(n61) );
  NAND2X0 U88 ( .IN1(n63), .IN2(n64), .QN(carry[52]) );
  INVX0 U89 ( .INP(carry[51]), .ZN(n63) );
  NAND2X0 U90 ( .IN1(n66), .IN2(n67), .QN(carry[54]) );
  INVX0 U91 ( .INP(carry[53]), .ZN(n66) );
  NAND2X0 U92 ( .IN1(n5), .IN2(n68), .QN(carry[55]) );
  NAND2X0 U93 ( .IN1(n8), .IN2(n69), .QN(carry[56]) );
  NAND2X0 U94 ( .IN1(n11), .IN2(n70), .QN(carry[57]) );
  NAND2X0 U95 ( .IN1(B[21]), .IN2(n94), .QN(carry[8]) );
  INVX0 U96 ( .INP(A[7]), .ZN(n94) );
  INVX0 U97 ( .INP(A[10]), .ZN(n54) );
  NAND2X0 U98 ( .IN1(n23), .IN2(n32), .QN(carry[63]) );
  INVX0 U99 ( .INP(A[17]), .ZN(n27) );
  INVX0 U100 ( .INP(A[18]), .ZN(n40) );
  INVX0 U101 ( .INP(A[24]), .ZN(n35) );
  INVX0 U102 ( .INP(A[23]), .ZN(n52) );
  INVX0 U103 ( .INP(A[25]), .ZN(n33) );
  INVX0 U104 ( .INP(A[22]), .ZN(n42) );
  INVX0 U105 ( .INP(A[26]), .ZN(n51) );
  INVX0 U106 ( .INP(A[27]), .ZN(n39) );
  INVX0 U107 ( .INP(A[28]), .ZN(n49) );
  INVX0 U108 ( .INP(A[30]), .ZN(n29) );
  INVX0 U109 ( .INP(A[29]), .ZN(n31) );
  INVX0 U110 ( .INP(A[31]), .ZN(n47) );
  INVX0 U111 ( .INP(A[32]), .ZN(n25) );
  INVX0 U112 ( .INP(A[33]), .ZN(n28) );
  INVX0 U113 ( .INP(A[34]), .ZN(n45) );
  INVX0 U114 ( .INP(A[35]), .ZN(n38) );
  INVX0 U115 ( .INP(A[36]), .ZN(n36) );
  INVX0 U116 ( .INP(A[37]), .ZN(n44) );
  INVX0 U117 ( .INP(A[38]), .ZN(n77) );
  INVX0 U118 ( .INP(A[39]), .ZN(n79) );
  INVX0 U119 ( .INP(A[40]), .ZN(n81) );
  INVX0 U120 ( .INP(A[41]), .ZN(n83) );
  INVX0 U121 ( .INP(A[42]), .ZN(n85) );
  INVX0 U122 ( .INP(A[43]), .ZN(n87) );
  INVX0 U123 ( .INP(A[44]), .ZN(n89) );
  INVX0 U124 ( .INP(A[45]), .ZN(n93) );
  INVX0 U125 ( .INP(A[46]), .ZN(n91) );
  INVX0 U126 ( .INP(A[47]), .ZN(n56) );
  INVX0 U127 ( .INP(A[48]), .ZN(n58) );
  INVX0 U128 ( .INP(A[49]), .ZN(n60) );
  INVX0 U129 ( .INP(A[50]), .ZN(n62) );
  INVX0 U130 ( .INP(A[51]), .ZN(n64) );
  INVX0 U131 ( .INP(A[52]), .ZN(n65) );
  INVX0 U132 ( .INP(A[53]), .ZN(n67) );
  INVX0 U133 ( .INP(A[54]), .ZN(n68) );
  INVX0 U134 ( .INP(A[55]), .ZN(n69) );
  INVX0 U135 ( .INP(A[56]), .ZN(n70) );
  INVX0 U136 ( .INP(A[57]), .ZN(n71) );
  INVX0 U137 ( .INP(A[58]), .ZN(n72) );
  INVX0 U138 ( .INP(A[59]), .ZN(n73) );
  INVX0 U139 ( .INP(A[60]), .ZN(n74) );
  INVX0 U140 ( .INP(A[61]), .ZN(n75) );
  INVX0 U141 ( .INP(A[62]), .ZN(n32) );
  XOR2X1 U142 ( .IN1(n25), .IN2(carry[32]), .Q(DIFF[32]) );
  XOR2X1 U143 ( .IN1(n27), .IN2(carry[17]), .Q(DIFF[17]) );
  XOR2X1 U144 ( .IN1(n28), .IN2(carry[33]), .Q(DIFF[33]) );
  XOR2X1 U145 ( .IN1(n29), .IN2(carry[30]), .Q(DIFF[30]) );
  XOR2X1 U146 ( .IN1(n31), .IN2(carry[29]), .Q(DIFF[29]) );
  XOR2X1 U147 ( .IN1(n20), .IN2(carry[19]), .Q(DIFF[19]) );
  XOR2X1 U148 ( .IN1(n14), .IN2(carry[11]), .Q(DIFF[11]) );
  XOR2X1 U149 ( .IN1(n32), .IN2(carry[62]), .Q(DIFF[62]) );
  XOR2X1 U150 ( .IN1(n33), .IN2(carry[25]), .Q(DIFF[25]) );
  XOR2X1 U151 ( .IN1(n35), .IN2(carry[24]), .Q(DIFF[24]) );
  XOR2X1 U152 ( .IN1(n36), .IN2(carry[36]), .Q(DIFF[36]) );
  XOR2X1 U153 ( .IN1(n38), .IN2(carry[35]), .Q(DIFF[35]) );
  XOR2X1 U154 ( .IN1(n39), .IN2(carry[27]), .Q(DIFF[27]) );
  XOR2X1 U155 ( .IN1(n40), .IN2(carry[18]), .Q(DIFF[18]) );
  XOR2X1 U156 ( .IN1(n42), .IN2(carry[22]), .Q(DIFF[22]) );
  XOR2X1 U157 ( .IN1(n44), .IN2(carry[37]), .Q(DIFF[37]) );
  XOR2X1 U158 ( .IN1(n45), .IN2(carry[34]), .Q(DIFF[34]) );
  XOR2X1 U159 ( .IN1(n47), .IN2(carry[31]), .Q(DIFF[31]) );
  XOR2X1 U160 ( .IN1(n49), .IN2(carry[28]), .Q(DIFF[28]) );
  XOR2X1 U161 ( .IN1(n51), .IN2(carry[26]), .Q(DIFF[26]) );
  XOR2X1 U162 ( .IN1(n52), .IN2(carry[23]), .Q(DIFF[23]) );
  XOR2X1 U163 ( .IN1(n54), .IN2(carry[10]), .Q(DIFF[10]) );
  XOR2X1 U164 ( .IN1(n56), .IN2(carry[47]), .Q(DIFF[47]) );
  XOR2X1 U165 ( .IN1(n58), .IN2(carry[48]), .Q(DIFF[48]) );
  XOR2X1 U166 ( .IN1(n60), .IN2(carry[49]), .Q(DIFF[49]) );
  XOR2X1 U167 ( .IN1(n62), .IN2(carry[50]), .Q(DIFF[50]) );
  XOR2X1 U168 ( .IN1(n64), .IN2(carry[51]), .Q(DIFF[51]) );
  XOR2X1 U169 ( .IN1(n65), .IN2(carry[52]), .Q(DIFF[52]) );
  XOR2X1 U170 ( .IN1(n67), .IN2(carry[53]), .Q(DIFF[53]) );
  XOR2X1 U171 ( .IN1(n68), .IN2(carry[54]), .Q(DIFF[54]) );
  XOR2X1 U172 ( .IN1(n69), .IN2(carry[55]), .Q(DIFF[55]) );
  XOR2X1 U173 ( .IN1(n70), .IN2(carry[56]), .Q(DIFF[56]) );
  XOR2X1 U174 ( .IN1(n71), .IN2(carry[57]), .Q(DIFF[57]) );
  XOR2X1 U175 ( .IN1(n72), .IN2(carry[58]), .Q(DIFF[58]) );
  XOR2X1 U176 ( .IN1(n73), .IN2(carry[59]), .Q(DIFF[59]) );
  XOR2X1 U177 ( .IN1(n74), .IN2(carry[60]), .Q(DIFF[60]) );
  XOR2X1 U178 ( .IN1(n75), .IN2(carry[61]), .Q(DIFF[61]) );
  XOR2X1 U179 ( .IN1(n77), .IN2(carry[38]), .Q(DIFF[38]) );
  XOR2X1 U180 ( .IN1(n79), .IN2(carry[39]), .Q(DIFF[39]) );
  XOR2X1 U181 ( .IN1(n81), .IN2(carry[40]), .Q(DIFF[40]) );
  XOR2X1 U182 ( .IN1(n83), .IN2(carry[41]), .Q(DIFF[41]) );
  XOR2X1 U183 ( .IN1(n85), .IN2(carry[42]), .Q(DIFF[42]) );
  XOR2X1 U184 ( .IN1(n87), .IN2(carry[43]), .Q(DIFF[43]) );
  XOR2X1 U185 ( .IN1(n89), .IN2(carry[44]), .Q(DIFF[44]) );
  XOR2X1 U186 ( .IN1(n91), .IN2(carry[46]), .Q(DIFF[46]) );
  XOR2X1 U187 ( .IN1(n93), .IN2(carry[45]), .Q(DIFF[45]) );
  XOR2X1 U188 ( .IN1(n94), .IN2(n95), .Q(DIFF[7]) );
  INVX1 U189 ( .INP(B[9]), .ZN(n95) );
endmodule


module d1_word_sync ( clk, reset_n, bit_valid, data_bit, bit_ref, word_valid, 
        bch_valid, polarity_inverted, raw_word, information, word_number, 
        corrected_bits, word_ref );
  input [63:0] bit_ref;
  output [29:0] raw_word;
  output [25:0] information;
  output [3:0] word_number;
  output [1:0] corrected_bits;
  output [63:0] word_ref;
  input clk, reset_n, bit_valid, data_bit;
  output word_valid, bch_valid, polarity_inverted;
  wire   aligned, fix_left, fix_right, N443, N444, N447, N448, N449, N450,
         N451, N470, N471, N472, N473, N474, N475, N476, N477, N478, N479,
         N480, N481, N482, N483, N484, N485, N486, N487, N488, N489, N490,
         N491, N492, N493, N494, N495, N496, N497, N498, N499, N500, N501,
         N502, N503, N504, N505, N506, N507, N508, N509, N510, N511, N512,
         N513, N514, N515, N516, N517, N518, N519, N520, N521, N522, N523,
         N524, N525, N526, N527, N528, N530, N531, N532, N533, N534, N573,
         N574, N575, N899, n23, n25, n29, n30, n33, n34, n35, n36, n37, n38,
         n39, n40, n41, n42, n43, n44, n45, n46, n47, n48, n49, n50, n51, n52,
         n53, n54, n55, n56, n57, n58, n59, n60, n61, n62, n63, n64, n65, n66,
         n67, n68, n69, n70, n71, n72, n73, n74, n75, n76, n77, n78, n79, n80,
         n81, n82, n83, n84, n85, n86, n87, n88, n89, n90, n91, n92, n93, n94,
         n95, n96, n97, n98, n99, n100, n101, n102, n103, n104, n105, n106,
         n107, n108, n109, n110, n111, n112, n113, n114, n115, n116, n117,
         n118, n119, n120, n121, n122, n123, n124, n125, n126, n127, n128,
         n129, n130, n131, n132, n133, n134, n135, n136, n137, n138, n139,
         n140, n141, n142, n143, n144, n145, n146, n147, n148, n149, n150,
         n151, n152, n153, n154, n155, n156, n157, n158, n159, n160, n161,
         n162, n163, n164, n165, n166, n167, n168, n169, n170, n171, n172,
         n173, n174, n175, n176, n177, n178, n179, n180, n181, n182, n183,
         n184, n185, n186, n187, n188, n189, n190, n191, n192, n193, n194,
         n195, n196, n197, n198, n199, n200, n201, n202, n203, n204, n205,
         n206, n207, n208, n209, n210, n211, n212, n213, n214, n215, n216,
         n217, n218, n219, n220, n221, n222, n223, n224, n225, n226, n227,
         n228, n229, n230, n231, n232, n233, n234, n235, n236, n237, n238,
         n239, n240, n241, n242, n243, n244, n245, n246, n247, n248, n249,
         n250, n251, n252, n253, n254, n255, n256, n257, n258, n259, n260,
         n261, n262, n263, n264, n265, n266, n267, n268, n269, n270, n271,
         n272, n273, n274, n275, n276, n277, n278, n279, n280, n281, n282,
         n283, n284, n285, n286, n287, n288, n289, n290, n291, n292, n293,
         n294, n295, n296, n297, n298, n299, n300, n301, n302, n303, n304,
         n305, n306, n307, n308, n309, n310, n311, n312, n313, n314, n315,
         n316, n317, n318, n319, n320, n321, n322, n323, n324, n325, n326,
         n327, n328, n329, n330, n331, n332, n333, n334, n335, n336, n337,
         n338, n339, n340, n341, n342, n343, n344, n345, n346, n347, n348,
         n349, n350, n351, n352, n353, n354, n355, n356, n357, n358, n359,
         n360, n361, n362, n363, n364, n365, n366, n367, n368, n369, n370,
         n371, n372, n373, n374, n375, n376, n377, n378, n379, n380, n381,
         n382, n383, n384, n385, n386, n387, n388, n389, n390, n391, n392,
         n393, n394, n395, n396, n397, n398, n399, n400, n401, n402, n403,
         n404, n405, n406, n407, n408, n409, n410, n411, n412, n413, n414,
         n415, n416, n417, n418, n419, n420, n421, n422, n423, n424, n425,
         n426, n427, n428, n429, n430, n431, n432, n433, n434, n435, n436,
         n437, n438, n439, n440, n441, n442, n443, n444, n445, n446, n447,
         n448, n449, n450, n451, n452, n453, n454, n455, n456, n457, n458,
         n459, n460, n461, n462, n463, n464, n465, n466, n467, n468, N904,
         \mult_add_84_aco/PROD_not[3] , n469, n470, n471, n472, n473, n474,
         n475, n476, n477, n478, n479, n480, n481, n482, n483, n484, n485,
         n486, n487, n488, n489, n490, n491, n492, n493, n494, n495, n496,
         n497, n498, n499, n500, n501, n502, n503, n504, n505, n506, n507,
         n508, n509, n510, n511, n512, n513, n514, n515, n516, n517, n518,
         n519, n520, n521, n522, n523, n524, n525, n526, n527, n528, n529,
         n530, n531, n532, n533, n534, n535, n536, n537, n538, n539, n540,
         n541, n542, n543, n544, n545, n546, n547, n548, n549, n550, n551,
         n552;
  wire   [10:1] scan_next;
  wire   [29:0] assembled;
  wire   [3:0] current_word;
  wire   [4:0] bit_count;
  wire   [63:0] start_ref;
  wire   [4:2] \add_85/carry ;

  DFFASX1 \current_word_reg[0]  ( .D(n468), .CLK(clk), .SETB(n531), .Q(
        current_word[0]), .QN(n30) );
  DFFARX1 \bit_count_reg[3]  ( .D(n453), .CLK(clk), .RSTB(n529), .Q(
        bit_count[3]) );
  DFFARX1 \current_word_reg[1]  ( .D(n451), .CLK(clk), .RSTB(n529), .Q(
        current_word[1]) );
  DFFARX1 \current_word_reg[3]  ( .D(n449), .CLK(clk), .RSTB(n529), .Q(
        current_word[3]) );
  DFFARX1 \start_ref_reg[63]  ( .D(n448), .CLK(clk), .RSTB(n529), .Q(
        start_ref[63]) );
  DFFARX1 \start_ref_reg[62]  ( .D(n446), .CLK(clk), .RSTB(n529), .Q(
        start_ref[62]) );
  DFFARX1 \word_ref_reg[62]  ( .D(n445), .CLK(clk), .RSTB(n529), .Q(
        word_ref[62]) );
  DFFARX1 \start_ref_reg[61]  ( .D(n444), .CLK(clk), .RSTB(n529), .Q(
        start_ref[61]) );
  DFFARX1 \start_ref_reg[60]  ( .D(n442), .CLK(clk), .RSTB(n528), .Q(
        start_ref[60]) );
  DFFARX1 \start_ref_reg[59]  ( .D(n440), .CLK(clk), .RSTB(n528), .Q(
        start_ref[59]) );
  DFFARX1 \start_ref_reg[58]  ( .D(n438), .CLK(clk), .RSTB(n528), .Q(
        start_ref[58]) );
  DFFARX1 \start_ref_reg[57]  ( .D(n436), .CLK(clk), .RSTB(n528), .Q(
        start_ref[57]) );
  DFFARX1 \start_ref_reg[56]  ( .D(n434), .CLK(clk), .RSTB(n528), .Q(
        start_ref[56]) );
  DFFARX1 \start_ref_reg[55]  ( .D(n432), .CLK(clk), .RSTB(n528), .Q(
        start_ref[55]) );
  DFFARX1 \word_ref_reg[55]  ( .D(n431), .CLK(clk), .RSTB(n528), .Q(
        word_ref[55]) );
  DFFARX1 \start_ref_reg[54]  ( .D(n430), .CLK(clk), .RSTB(n527), .Q(
        start_ref[54]) );
  DFFARX1 \start_ref_reg[53]  ( .D(n428), .CLK(clk), .RSTB(n527), .Q(
        start_ref[53]) );
  DFFARX1 \start_ref_reg[52]  ( .D(n426), .CLK(clk), .RSTB(n527), .Q(
        start_ref[52]) );
  DFFARX1 \start_ref_reg[51]  ( .D(n424), .CLK(clk), .RSTB(n527), .Q(
        start_ref[51]) );
  DFFARX1 \start_ref_reg[50]  ( .D(n422), .CLK(clk), .RSTB(n527), .Q(
        start_ref[50]) );
  DFFARX1 \start_ref_reg[49]  ( .D(n420), .CLK(clk), .RSTB(n527), .Q(
        start_ref[49]) );
  DFFARX1 \word_ref_reg[49]  ( .D(n419), .CLK(clk), .RSTB(n527), .Q(
        word_ref[49]) );
  DFFARX1 \start_ref_reg[48]  ( .D(n418), .CLK(clk), .RSTB(n526), .Q(
        start_ref[48]) );
  DFFARX1 \start_ref_reg[47]  ( .D(n416), .CLK(clk), .RSTB(n526), .Q(
        start_ref[47]) );
  DFFARX1 \word_ref_reg[47]  ( .D(n415), .CLK(clk), .RSTB(n526), .Q(
        word_ref[47]) );
  DFFARX1 \start_ref_reg[46]  ( .D(n414), .CLK(clk), .RSTB(n526), .Q(
        start_ref[46]) );
  DFFARX1 \start_ref_reg[45]  ( .D(n412), .CLK(clk), .RSTB(n526), .Q(
        start_ref[45]) );
  DFFARX1 \word_ref_reg[45]  ( .D(n411), .CLK(clk), .RSTB(n526), .Q(
        word_ref[45]) );
  DFFARX1 \start_ref_reg[44]  ( .D(n410), .CLK(clk), .RSTB(n526), .Q(
        start_ref[44]) );
  DFFARX1 \word_ref_reg[44]  ( .D(n409), .CLK(clk), .RSTB(n526), .Q(
        word_ref[44]) );
  DFFARX1 \start_ref_reg[43]  ( .D(n408), .CLK(clk), .RSTB(n526), .Q(
        start_ref[43]) );
  DFFARX1 \word_ref_reg[43]  ( .D(n407), .CLK(clk), .RSTB(n526), .Q(
        word_ref[43]) );
  DFFARX1 \start_ref_reg[42]  ( .D(n406), .CLK(clk), .RSTB(n525), .Q(
        start_ref[42]) );
  DFFARX1 \word_ref_reg[42]  ( .D(n405), .CLK(clk), .RSTB(n525), .Q(
        word_ref[42]) );
  DFFARX1 \start_ref_reg[41]  ( .D(n404), .CLK(clk), .RSTB(n525), .Q(
        start_ref[41]) );
  DFFARX1 \word_ref_reg[41]  ( .D(n403), .CLK(clk), .RSTB(n525), .Q(
        word_ref[41]) );
  DFFARX1 \start_ref_reg[40]  ( .D(n402), .CLK(clk), .RSTB(n525), .Q(
        start_ref[40]) );
  DFFARX1 \word_ref_reg[40]  ( .D(n401), .CLK(clk), .RSTB(n525), .Q(
        word_ref[40]) );
  DFFARX1 \start_ref_reg[39]  ( .D(n400), .CLK(clk), .RSTB(n525), .Q(
        start_ref[39]) );
  DFFARX1 \word_ref_reg[39]  ( .D(n399), .CLK(clk), .RSTB(n525), .Q(
        word_ref[39]) );
  DFFARX1 \start_ref_reg[38]  ( .D(n398), .CLK(clk), .RSTB(n525), .Q(
        start_ref[38]) );
  DFFARX1 \word_ref_reg[38]  ( .D(n397), .CLK(clk), .RSTB(n525), .Q(
        word_ref[38]) );
  DFFARX1 \start_ref_reg[37]  ( .D(n396), .CLK(clk), .RSTB(n525), .Q(
        start_ref[37]) );
  DFFARX1 \word_ref_reg[37]  ( .D(n395), .CLK(clk), .RSTB(n525), .Q(
        word_ref[37]) );
  DFFARX1 \start_ref_reg[36]  ( .D(n394), .CLK(clk), .RSTB(n524), .Q(
        start_ref[36]) );
  DFFARX1 \word_ref_reg[36]  ( .D(n393), .CLK(clk), .RSTB(n524), .Q(
        word_ref[36]) );
  DFFARX1 \start_ref_reg[35]  ( .D(n392), .CLK(clk), .RSTB(n524), .Q(
        start_ref[35]) );
  DFFARX1 \word_ref_reg[35]  ( .D(n391), .CLK(clk), .RSTB(n524), .Q(
        word_ref[35]) );
  DFFARX1 \start_ref_reg[34]  ( .D(n390), .CLK(clk), .RSTB(n524), .Q(
        start_ref[34]) );
  DFFARX1 \word_ref_reg[34]  ( .D(n389), .CLK(clk), .RSTB(n524), .Q(
        word_ref[34]) );
  DFFARX1 \start_ref_reg[33]  ( .D(n388), .CLK(clk), .RSTB(n524), .Q(
        start_ref[33]) );
  DFFARX1 \word_ref_reg[33]  ( .D(n387), .CLK(clk), .RSTB(n524), .Q(
        word_ref[33]) );
  DFFARX1 \start_ref_reg[32]  ( .D(n386), .CLK(clk), .RSTB(n524), .Q(
        start_ref[32]) );
  DFFARX1 \word_ref_reg[32]  ( .D(n385), .CLK(clk), .RSTB(n524), .Q(
        word_ref[32]) );
  DFFARX1 \start_ref_reg[31]  ( .D(n384), .CLK(clk), .RSTB(n524), .Q(
        start_ref[31]) );
  DFFARX1 \word_ref_reg[31]  ( .D(n383), .CLK(clk), .RSTB(n524), .Q(
        word_ref[31]) );
  DFFARX1 \start_ref_reg[30]  ( .D(n382), .CLK(clk), .RSTB(n523), .Q(
        start_ref[30]) );
  DFFARX1 \word_ref_reg[30]  ( .D(n381), .CLK(clk), .RSTB(n523), .Q(
        word_ref[30]) );
  DFFARX1 \start_ref_reg[29]  ( .D(n380), .CLK(clk), .RSTB(n523), .Q(
        start_ref[29]) );
  DFFARX1 \word_ref_reg[29]  ( .D(n379), .CLK(clk), .RSTB(n523), .Q(
        word_ref[29]) );
  DFFARX1 \start_ref_reg[28]  ( .D(n378), .CLK(clk), .RSTB(n523), .Q(
        start_ref[28]) );
  DFFARX1 \word_ref_reg[28]  ( .D(n377), .CLK(clk), .RSTB(n523), .Q(
        word_ref[28]) );
  DFFARX1 \start_ref_reg[27]  ( .D(n376), .CLK(clk), .RSTB(n523), .Q(
        start_ref[27]) );
  DFFARX1 \word_ref_reg[27]  ( .D(n375), .CLK(clk), .RSTB(n523), .Q(
        word_ref[27]) );
  DFFARX1 \start_ref_reg[26]  ( .D(n374), .CLK(clk), .RSTB(n523), .Q(
        start_ref[26]) );
  DFFARX1 \word_ref_reg[26]  ( .D(n373), .CLK(clk), .RSTB(n523), .Q(
        word_ref[26]) );
  DFFARX1 \start_ref_reg[25]  ( .D(n372), .CLK(clk), .RSTB(n523), .Q(
        start_ref[25]) );
  DFFARX1 \word_ref_reg[25]  ( .D(n371), .CLK(clk), .RSTB(n523), .Q(
        word_ref[25]) );
  DFFARX1 \start_ref_reg[24]  ( .D(n370), .CLK(clk), .RSTB(n522), .Q(
        start_ref[24]) );
  DFFARX1 \word_ref_reg[24]  ( .D(n369), .CLK(clk), .RSTB(n522), .Q(
        word_ref[24]) );
  DFFARX1 \start_ref_reg[23]  ( .D(n368), .CLK(clk), .RSTB(n522), .Q(
        start_ref[23]) );
  DFFARX1 \word_ref_reg[23]  ( .D(n367), .CLK(clk), .RSTB(n522), .Q(
        word_ref[23]) );
  DFFARX1 \start_ref_reg[22]  ( .D(n366), .CLK(clk), .RSTB(n522), .Q(
        start_ref[22]) );
  DFFARX1 \word_ref_reg[22]  ( .D(n365), .CLK(clk), .RSTB(n522), .Q(
        word_ref[22]) );
  DFFARX1 \start_ref_reg[21]  ( .D(n364), .CLK(clk), .RSTB(n522), .Q(
        start_ref[21]) );
  DFFARX1 \word_ref_reg[21]  ( .D(n363), .CLK(clk), .RSTB(n522), .Q(
        word_ref[21]) );
  DFFARX1 \start_ref_reg[20]  ( .D(n362), .CLK(clk), .RSTB(n522), .Q(
        start_ref[20]) );
  DFFARX1 \word_ref_reg[20]  ( .D(n361), .CLK(clk), .RSTB(n522), .Q(
        word_ref[20]) );
  DFFARX1 \start_ref_reg[19]  ( .D(n360), .CLK(clk), .RSTB(n522), .Q(
        start_ref[19]) );
  DFFARX1 \word_ref_reg[19]  ( .D(n359), .CLK(clk), .RSTB(n522), .Q(
        word_ref[19]) );
  DFFARX1 \start_ref_reg[18]  ( .D(n358), .CLK(clk), .RSTB(n521), .Q(
        start_ref[18]) );
  DFFARX1 \word_ref_reg[18]  ( .D(n357), .CLK(clk), .RSTB(n521), .Q(
        word_ref[18]) );
  DFFARX1 \start_ref_reg[17]  ( .D(n356), .CLK(clk), .RSTB(n521), .Q(
        start_ref[17]) );
  DFFARX1 \word_ref_reg[17]  ( .D(n355), .CLK(clk), .RSTB(n521), .Q(
        word_ref[17]) );
  DFFARX1 \start_ref_reg[16]  ( .D(n354), .CLK(clk), .RSTB(n521), .Q(
        start_ref[16]) );
  DFFARX1 \word_ref_reg[16]  ( .D(n353), .CLK(clk), .RSTB(n521), .Q(
        word_ref[16]) );
  DFFARX1 \start_ref_reg[15]  ( .D(n352), .CLK(clk), .RSTB(n521), .Q(
        start_ref[15]) );
  DFFARX1 \word_ref_reg[15]  ( .D(n351), .CLK(clk), .RSTB(n521), .Q(
        word_ref[15]) );
  DFFARX1 \start_ref_reg[14]  ( .D(n350), .CLK(clk), .RSTB(n521), .Q(
        start_ref[14]) );
  DFFARX1 \word_ref_reg[14]  ( .D(n349), .CLK(clk), .RSTB(n521), .Q(
        word_ref[14]) );
  DFFARX1 \start_ref_reg[13]  ( .D(n348), .CLK(clk), .RSTB(n521), .Q(
        start_ref[13]) );
  DFFARX1 \word_ref_reg[13]  ( .D(n347), .CLK(clk), .RSTB(n521), .Q(
        word_ref[13]) );
  DFFARX1 \start_ref_reg[12]  ( .D(n346), .CLK(clk), .RSTB(n520), .Q(
        start_ref[12]) );
  DFFARX1 \word_ref_reg[12]  ( .D(n345), .CLK(clk), .RSTB(n520), .Q(
        word_ref[12]) );
  DFFARX1 \start_ref_reg[11]  ( .D(n344), .CLK(clk), .RSTB(n520), .Q(
        start_ref[11]) );
  DFFARX1 \word_ref_reg[11]  ( .D(n343), .CLK(clk), .RSTB(n520), .Q(
        word_ref[11]) );
  DFFARX1 \start_ref_reg[10]  ( .D(n342), .CLK(clk), .RSTB(n520), .Q(
        start_ref[10]) );
  DFFARX1 \word_ref_reg[10]  ( .D(n341), .CLK(clk), .RSTB(n520), .Q(
        word_ref[10]) );
  DFFARX1 \start_ref_reg[9]  ( .D(n340), .CLK(clk), .RSTB(n520), .Q(
        start_ref[9]) );
  DFFARX1 \word_ref_reg[9]  ( .D(n339), .CLK(clk), .RSTB(n520), .Q(word_ref[9]) );
  DFFARX1 \start_ref_reg[8]  ( .D(n338), .CLK(clk), .RSTB(n520), .Q(
        start_ref[8]) );
  DFFARX1 \word_ref_reg[8]  ( .D(n337), .CLK(clk), .RSTB(n520), .Q(word_ref[8]) );
  DFFARX1 \start_ref_reg[7]  ( .D(n336), .CLK(clk), .RSTB(n520), .Q(
        start_ref[7]) );
  DFFARX1 \word_ref_reg[7]  ( .D(n335), .CLK(clk), .RSTB(n520), .Q(word_ref[7]) );
  DFFARX1 \start_ref_reg[6]  ( .D(n334), .CLK(clk), .RSTB(n519), .Q(
        start_ref[6]) );
  DFFARX1 \word_ref_reg[6]  ( .D(n333), .CLK(clk), .RSTB(n519), .Q(word_ref[6]) );
  DFFARX1 \start_ref_reg[5]  ( .D(n332), .CLK(clk), .RSTB(n519), .Q(
        start_ref[5]) );
  DFFARX1 \word_ref_reg[5]  ( .D(n331), .CLK(clk), .RSTB(n519), .Q(word_ref[5]) );
  DFFARX1 \start_ref_reg[4]  ( .D(n330), .CLK(clk), .RSTB(n519), .Q(
        start_ref[4]) );
  DFFARX1 \word_ref_reg[4]  ( .D(n329), .CLK(clk), .RSTB(n519), .Q(word_ref[4]) );
  DFFARX1 \start_ref_reg[3]  ( .D(n328), .CLK(clk), .RSTB(n519), .Q(
        start_ref[3]) );
  DFFARX1 \word_ref_reg[3]  ( .D(n327), .CLK(clk), .RSTB(n519), .Q(word_ref[3]) );
  DFFARX1 \start_ref_reg[2]  ( .D(n326), .CLK(clk), .RSTB(n519), .Q(
        start_ref[2]) );
  DFFARX1 \word_ref_reg[2]  ( .D(n325), .CLK(clk), .RSTB(n519), .Q(word_ref[2]) );
  DFFARX1 \start_ref_reg[1]  ( .D(n324), .CLK(clk), .RSTB(n519), .Q(
        start_ref[1]) );
  DFFARX1 \word_ref_reg[1]  ( .D(n323), .CLK(clk), .RSTB(n519), .Q(word_ref[1]) );
  DFFARX1 \start_ref_reg[0]  ( .D(n322), .CLK(clk), .RSTB(n518), .Q(
        start_ref[0]) );
  DFFARX1 \word_ref_reg[0]  ( .D(n321), .CLK(clk), .RSTB(n518), .Q(word_ref[0]) );
  DFFARX1 \shift_reg[1]  ( .D(n318), .CLK(clk), .RSTB(n518), .Q(assembled[2])
         );
  DFFARX1 \shift_reg[4]  ( .D(n315), .CLK(clk), .RSTB(n518), .Q(assembled[5])
         );
  DFFARX1 \shift_reg[8]  ( .D(n311), .CLK(clk), .RSTB(n517), .Q(assembled[9])
         );
  DFFARX1 \shift_reg[9]  ( .D(n310), .CLK(clk), .RSTB(n517), .Q(assembled[10])
         );
  DFFARX1 \shift_reg[10]  ( .D(n309), .CLK(clk), .RSTB(n517), .Q(assembled[11]) );
  DFFARX1 bch_valid_reg ( .D(n290), .CLK(clk), .RSTB(n516), .Q(bch_valid) );
  DFFARX1 \raw_word_reg[29]  ( .D(n289), .CLK(clk), .RSTB(n516), .Q(
        raw_word[29]) );
  DFFARX1 \raw_word_reg[28]  ( .D(n288), .CLK(clk), .RSTB(n516), .Q(
        raw_word[28]) );
  DFFARX1 \raw_word_reg[27]  ( .D(n287), .CLK(clk), .RSTB(n515), .Q(
        raw_word[27]) );
  DFFARX1 \raw_word_reg[26]  ( .D(n286), .CLK(clk), .RSTB(n515), .Q(
        raw_word[26]) );
  DFFARX1 \raw_word_reg[25]  ( .D(n285), .CLK(clk), .RSTB(n515), .Q(
        raw_word[25]) );
  DFFARX1 \raw_word_reg[24]  ( .D(n284), .CLK(clk), .RSTB(n515), .Q(
        raw_word[24]) );
  DFFARX1 \raw_word_reg[23]  ( .D(n283), .CLK(clk), .RSTB(n515), .Q(
        raw_word[23]) );
  DFFARX1 \raw_word_reg[22]  ( .D(n282), .CLK(clk), .RSTB(n515), .Q(
        raw_word[22]) );
  DFFARX1 \raw_word_reg[21]  ( .D(n281), .CLK(clk), .RSTB(n515), .Q(
        raw_word[21]) );
  DFFARX1 \raw_word_reg[20]  ( .D(n280), .CLK(clk), .RSTB(n515), .Q(
        raw_word[20]) );
  DFFARX1 \raw_word_reg[19]  ( .D(n279), .CLK(clk), .RSTB(n515), .Q(
        raw_word[19]) );
  DFFARX1 \raw_word_reg[18]  ( .D(n278), .CLK(clk), .RSTB(n515), .Q(
        raw_word[18]) );
  DFFARX1 \raw_word_reg[17]  ( .D(n277), .CLK(clk), .RSTB(n515), .Q(
        raw_word[17]) );
  DFFARX1 \raw_word_reg[16]  ( .D(n276), .CLK(clk), .RSTB(n515), .Q(
        raw_word[16]) );
  DFFARX1 \raw_word_reg[15]  ( .D(n275), .CLK(clk), .RSTB(n514), .Q(
        raw_word[15]) );
  DFFARX1 \raw_word_reg[14]  ( .D(n274), .CLK(clk), .RSTB(n514), .Q(
        raw_word[14]) );
  DFFARX1 \raw_word_reg[13]  ( .D(n273), .CLK(clk), .RSTB(n514), .Q(
        raw_word[13]) );
  DFFARX1 \raw_word_reg[12]  ( .D(n272), .CLK(clk), .RSTB(n514), .Q(
        raw_word[12]) );
  DFFARX1 \raw_word_reg[11]  ( .D(n271), .CLK(clk), .RSTB(n514), .Q(
        raw_word[11]) );
  DFFARX1 \raw_word_reg[6]  ( .D(n266), .CLK(clk), .RSTB(n514), .Q(raw_word[6]) );
  DFFARX1 \raw_word_reg[5]  ( .D(n265), .CLK(clk), .RSTB(n514), .Q(raw_word[5]) );
  DFFARX1 \raw_word_reg[4]  ( .D(n264), .CLK(clk), .RSTB(n514), .Q(raw_word[4]) );
  DFFARX1 \raw_word_reg[3]  ( .D(n263), .CLK(clk), .RSTB(n513), .Q(raw_word[3]) );
  DFFARX1 \raw_word_reg[2]  ( .D(n262), .CLK(clk), .RSTB(n513), .Q(raw_word[2]) );
  DFFARX1 \raw_word_reg[1]  ( .D(n261), .CLK(clk), .RSTB(n513), .Q(raw_word[1]) );
  DFFARX1 \information_reg[21]  ( .D(n255), .CLK(clk), .RSTB(n513), .Q(
        information[21]) );
  DFFARX1 \information_reg[20]  ( .D(n254), .CLK(clk), .RSTB(n513), .Q(
        information[20]) );
  DFFARX1 \information_reg[19]  ( .D(n253), .CLK(clk), .RSTB(n513), .Q(
        information[19]) );
  DFFARX1 \information_reg[18]  ( .D(n252), .CLK(clk), .RSTB(n513), .Q(
        information[18]) );
  DFFARX1 \information_reg[17]  ( .D(n251), .CLK(clk), .RSTB(n512), .Q(
        information[17]) );
  DFFARX1 \information_reg[16]  ( .D(n250), .CLK(clk), .RSTB(n512), .Q(
        information[16]) );
  DFFARX1 \information_reg[15]  ( .D(n249), .CLK(clk), .RSTB(n512), .Q(
        information[15]) );
  DFFARX1 \information_reg[14]  ( .D(n248), .CLK(clk), .RSTB(n512), .Q(
        information[14]) );
  DFFARX1 \information_reg[13]  ( .D(n247), .CLK(clk), .RSTB(n512), .Q(
        information[13]) );
  DFFARX1 \information_reg[12]  ( .D(n246), .CLK(clk), .RSTB(n512), .Q(
        information[12]) );
  DFFARX1 \information_reg[11]  ( .D(n245), .CLK(clk), .RSTB(n512), .Q(
        information[11]) );
  DFFARX1 \information_reg[10]  ( .D(n244), .CLK(clk), .RSTB(n512), .Q(
        information[10]) );
  DFFARX1 \information_reg[9]  ( .D(n243), .CLK(clk), .RSTB(n512), .Q(
        information[9]) );
  DFFARX1 \information_reg[8]  ( .D(n242), .CLK(clk), .RSTB(n512), .Q(
        information[8]) );
  DFFARX1 \information_reg[7]  ( .D(n241), .CLK(clk), .RSTB(n512), .Q(
        information[7]) );
  DFFARX1 \information_reg[6]  ( .D(n240), .CLK(clk), .RSTB(n512), .Q(
        information[6]) );
  DFFARX1 \information_reg[5]  ( .D(n239), .CLK(clk), .RSTB(n511), .Q(
        information[5]) );
  DFFARX1 \information_reg[4]  ( .D(n238), .CLK(clk), .RSTB(n511), .Q(
        information[4]) );
  DFFARX1 \information_reg[3]  ( .D(n237), .CLK(clk), .RSTB(n511), .Q(
        information[3]) );
  DFFARX1 \information_reg[2]  ( .D(n236), .CLK(clk), .RSTB(n511), .Q(
        information[2]) );
  DFFARX1 \information_reg[1]  ( .D(n235), .CLK(clk), .RSTB(n511), .Q(
        information[1]) );
  DFFARX1 \information_reg[0]  ( .D(n234), .CLK(clk), .RSTB(n511), .Q(
        information[0]) );
  DFFARX1 \corrected_bits_reg[1]  ( .D(n229), .CLK(clk), .RSTB(n511), .Q(
        corrected_bits[1]) );
  DFFARX1 \corrected_bits_reg[0]  ( .D(n228), .CLK(clk), .RSTB(n511), .Q(
        corrected_bits[0]) );
  AO22X1 U97 ( .IN1(N443), .IN2(n507), .IN3(corrected_bits[0]), .IN4(n498), 
        .Q(n228) );
  AO22X1 U98 ( .IN1(N444), .IN2(n508), .IN3(corrected_bits[1]), .IN4(n496), 
        .Q(n229) );
  AO22X1 U99 ( .IN1(current_word[0]), .IN2(n507), .IN3(word_number[0]), .IN4(
        n496), .Q(n230) );
  AO22X1 U100 ( .IN1(current_word[1]), .IN2(n503), .IN3(word_number[1]), .IN4(
        n496), .Q(n231) );
  AO22X1 U101 ( .IN1(current_word[2]), .IN2(n506), .IN3(word_number[2]), .IN4(
        n496), .Q(n232) );
  AO22X1 U102 ( .IN1(current_word[3]), .IN2(n507), .IN3(word_number[3]), .IN4(
        n496), .Q(n233) );
  AO22X1 U103 ( .IN1(information[0]), .IN2(n499), .IN3(n34), .IN4(n508), .Q(
        n234) );
  AO22X1 U104 ( .IN1(information[1]), .IN2(n499), .IN3(n35), .IN4(n503), .Q(
        n235) );
  AO22X1 U105 ( .IN1(information[2]), .IN2(n499), .IN3(n36), .IN4(n507), .Q(
        n236) );
  AO22X1 U106 ( .IN1(information[3]), .IN2(n499), .IN3(n37), .IN4(n503), .Q(
        n237) );
  AO22X1 U107 ( .IN1(information[4]), .IN2(n499), .IN3(n38), .IN4(n506), .Q(
        n238) );
  AO22X1 U108 ( .IN1(information[5]), .IN2(n499), .IN3(n39), .IN4(n503), .Q(
        n239) );
  AO22X1 U109 ( .IN1(information[6]), .IN2(n499), .IN3(n40), .IN4(n503), .Q(
        n240) );
  AO22X1 U110 ( .IN1(information[7]), .IN2(n499), .IN3(n41), .IN4(n503), .Q(
        n241) );
  AO22X1 U111 ( .IN1(information[8]), .IN2(n499), .IN3(n42), .IN4(n503), .Q(
        n242) );
  AO22X1 U112 ( .IN1(information[9]), .IN2(n499), .IN3(n43), .IN4(n503), .Q(
        n243) );
  AO22X1 U113 ( .IN1(information[10]), .IN2(n499), .IN3(n44), .IN4(n503), .Q(
        n244) );
  AO222X1 U114 ( .IN1(n534), .IN2(assembled[15]), .IN3(n45), .IN4(n46), .IN5(
        information[11]), .IN6(n496), .Q(n245) );
  AO222X1 U115 ( .IN1(n534), .IN2(assembled[16]), .IN3(n45), .IN4(n47), .IN5(
        information[12]), .IN6(n496), .Q(n246) );
  AO222X1 U116 ( .IN1(n534), .IN2(assembled[17]), .IN3(n45), .IN4(n48), .IN5(
        information[13]), .IN6(n496), .Q(n247) );
  AO222X1 U117 ( .IN1(n534), .IN2(assembled[18]), .IN3(n45), .IN4(n49), .IN5(
        information[14]), .IN6(n496), .Q(n248) );
  AO222X1 U118 ( .IN1(n534), .IN2(assembled[19]), .IN3(n45), .IN4(n50), .IN5(
        information[15]), .IN6(n496), .Q(n249) );
  AO222X1 U119 ( .IN1(n534), .IN2(assembled[20]), .IN3(n45), .IN4(n51), .IN5(
        information[16]), .IN6(n496), .Q(n250) );
  AO222X1 U120 ( .IN1(n534), .IN2(assembled[21]), .IN3(n45), .IN4(n52), .IN5(
        information[17]), .IN6(n496), .Q(n251) );
  AO222X1 U121 ( .IN1(n534), .IN2(assembled[22]), .IN3(n45), .IN4(n53), .IN5(
        information[18]), .IN6(n496), .Q(n252) );
  AO222X1 U122 ( .IN1(n534), .IN2(assembled[23]), .IN3(n45), .IN4(n54), .IN5(
        information[19]), .IN6(n496), .Q(n253) );
  AO222X1 U123 ( .IN1(n534), .IN2(assembled[24]), .IN3(n45), .IN4(n55), .IN5(
        information[20]), .IN6(n496), .Q(n254) );
  AO222X1 U124 ( .IN1(n534), .IN2(assembled[25]), .IN3(n45), .IN4(n56), .IN5(
        information[21]), .IN6(n496), .Q(n255) );
  AO22X1 U125 ( .IN1(information[22]), .IN2(n499), .IN3(n534), .IN4(
        assembled[26]), .Q(n256) );
  AO22X1 U126 ( .IN1(information[23]), .IN2(n499), .IN3(n534), .IN4(
        assembled[27]), .Q(n257) );
  AO22X1 U127 ( .IN1(information[24]), .IN2(n499), .IN3(n534), .IN4(
        assembled[28]), .Q(n258) );
  AO22X1 U128 ( .IN1(information[25]), .IN2(n499), .IN3(n534), .IN4(
        assembled[29]), .Q(n259) );
  AO22X1 U129 ( .IN1(raw_word[0]), .IN2(n499), .IN3(n509), .IN4(n59), .Q(n260)
         );
  AO22X1 U130 ( .IN1(assembled[1]), .IN2(n505), .IN3(raw_word[1]), .IN4(n496), 
        .Q(n261) );
  AO22X1 U131 ( .IN1(assembled[2]), .IN2(n504), .IN3(raw_word[2]), .IN4(n496), 
        .Q(n262) );
  AO22X1 U132 ( .IN1(assembled[3]), .IN2(n503), .IN3(raw_word[3]), .IN4(n496), 
        .Q(n263) );
  AO22X1 U133 ( .IN1(assembled[4]), .IN2(n503), .IN3(raw_word[4]), .IN4(n496), 
        .Q(n264) );
  AO22X1 U134 ( .IN1(assembled[5]), .IN2(n504), .IN3(raw_word[5]), .IN4(n496), 
        .Q(n265) );
  AO22X1 U135 ( .IN1(assembled[6]), .IN2(n504), .IN3(raw_word[6]), .IN4(n496), 
        .Q(n266) );
  AO22X1 U136 ( .IN1(assembled[7]), .IN2(n504), .IN3(raw_word[7]), .IN4(n496), 
        .Q(n267) );
  AO22X1 U137 ( .IN1(assembled[8]), .IN2(n504), .IN3(raw_word[8]), .IN4(n496), 
        .Q(n268) );
  AO22X1 U138 ( .IN1(assembled[9]), .IN2(n504), .IN3(raw_word[9]), .IN4(n496), 
        .Q(n269) );
  AO22X1 U139 ( .IN1(assembled[10]), .IN2(n504), .IN3(raw_word[10]), .IN4(n496), .Q(n270) );
  AO22X1 U140 ( .IN1(assembled[11]), .IN2(n504), .IN3(raw_word[11]), .IN4(n497), .Q(n271) );
  AO22X1 U141 ( .IN1(assembled[12]), .IN2(n504), .IN3(raw_word[12]), .IN4(n497), .Q(n272) );
  AO22X1 U142 ( .IN1(assembled[13]), .IN2(n504), .IN3(raw_word[13]), .IN4(n497), .Q(n273) );
  AO22X1 U143 ( .IN1(assembled[14]), .IN2(n505), .IN3(raw_word[14]), .IN4(n497), .Q(n274) );
  AO22X1 U144 ( .IN1(assembled[15]), .IN2(n505), .IN3(raw_word[15]), .IN4(n497), .Q(n275) );
  AO22X1 U145 ( .IN1(assembled[16]), .IN2(n505), .IN3(raw_word[16]), .IN4(n497), .Q(n276) );
  AO22X1 U146 ( .IN1(assembled[17]), .IN2(n505), .IN3(raw_word[17]), .IN4(n497), .Q(n277) );
  AO22X1 U147 ( .IN1(assembled[18]), .IN2(n505), .IN3(raw_word[18]), .IN4(n497), .Q(n278) );
  AO22X1 U148 ( .IN1(assembled[19]), .IN2(n505), .IN3(raw_word[19]), .IN4(n497), .Q(n279) );
  AO22X1 U149 ( .IN1(assembled[20]), .IN2(n505), .IN3(raw_word[20]), .IN4(n497), .Q(n280) );
  AO22X1 U150 ( .IN1(assembled[21]), .IN2(n505), .IN3(raw_word[21]), .IN4(n497), .Q(n281) );
  AO22X1 U151 ( .IN1(assembled[22]), .IN2(n505), .IN3(raw_word[22]), .IN4(n497), .Q(n282) );
  AO22X1 U152 ( .IN1(assembled[23]), .IN2(n506), .IN3(raw_word[23]), .IN4(n497), .Q(n283) );
  AO22X1 U153 ( .IN1(assembled[24]), .IN2(n506), .IN3(raw_word[24]), .IN4(n497), .Q(n284) );
  AO22X1 U154 ( .IN1(assembled[25]), .IN2(n506), .IN3(raw_word[25]), .IN4(n497), .Q(n285) );
  AO22X1 U155 ( .IN1(assembled[26]), .IN2(n506), .IN3(raw_word[26]), .IN4(n497), .Q(n286) );
  AO22X1 U156 ( .IN1(assembled[27]), .IN2(n506), .IN3(raw_word[27]), .IN4(n497), .Q(n287) );
  AO22X1 U157 ( .IN1(assembled[28]), .IN2(n506), .IN3(raw_word[28]), .IN4(n497), .Q(n288) );
  AO22X1 U158 ( .IN1(assembled[29]), .IN2(n506), .IN3(raw_word[29]), .IN4(n497), .Q(n289) );
  AO21X1 U159 ( .IN1(bch_valid), .IN2(n499), .IN3(n60), .Q(n290) );
  NOR4X0 U160 ( .IN1(n61), .IN2(n62), .IN3(n63), .IN4(n64), .QN(n60) );
  XOR3X1 U161 ( .IN1(n65), .IN2(n66), .IN3(n67), .Q(n64) );
  XOR3X1 U162 ( .IN1(n44), .IN2(n37), .IN3(n35), .Q(n67) );
  XOR2X1 U163 ( .IN1(n68), .IN2(n69), .Q(n44) );
  XOR3X1 U164 ( .IN1(n34), .IN2(n43), .IN3(n70), .Q(n63) );
  XOR3X1 U166 ( .IN1(n72), .IN2(n73), .IN3(n74), .Q(n65) );
  XOR2X1 U167 ( .IN1(n75), .IN2(n76), .Q(n43) );
  AO21X1 U168 ( .IN1(n58), .IN2(n77), .IN3(n78), .Q(n62) );
  XOR2X1 U169 ( .IN1(n79), .IN2(n80), .Q(n78) );
  XNOR3X1 U170 ( .IN1(n35), .IN2(n38), .IN3(n42), .Q(n80) );
  XNOR2X1 U171 ( .IN1(n81), .IN2(n82), .Q(n42) );
  XNOR2X1 U172 ( .IN1(n83), .IN2(n84), .Q(n35) );
  XNOR3X1 U173 ( .IN1(n85), .IN2(n86), .IN3(n71), .Q(n79) );
  XNOR3X1 U174 ( .IN1(n87), .IN2(n88), .IN3(n89), .Q(n71) );
  XNOR2X1 U176 ( .IN1(n90), .IN2(n91), .Q(n37) );
  NAND4X0 U177 ( .IN1(n92), .IN2(n505), .IN3(n93), .IN4(n94), .QN(n77) );
  XOR3X1 U178 ( .IN1(n97), .IN2(n98), .IN3(n99), .Q(n96) );
  XOR3X1 U179 ( .IN1(n52), .IN2(n56), .IN3(n100), .Q(n99) );
  XNOR2X1 U180 ( .IN1(n101), .IN2(assembled[29]), .Q(n56) );
  XOR3X1 U181 ( .IN1(n97), .IN2(n102), .IN3(n103), .Q(n95) );
  XOR3X1 U182 ( .IN1(n49), .IN2(n55), .IN3(n104), .Q(n103) );
  XNOR2X1 U183 ( .IN1(n105), .IN2(assembled[27]), .Q(n55) );
  XNOR3X1 U184 ( .IN1(assembled[5]), .IN2(n106), .IN3(n107), .Q(n97) );
  XNOR3X1 U185 ( .IN1(n102), .IN2(n107), .IN3(n108), .Q(n93) );
  XOR3X1 U186 ( .IN1(n52), .IN2(n53), .IN3(n109), .Q(n108) );
  XNOR2X1 U187 ( .IN1(n110), .IN2(assembled[23]), .Q(n53) );
  XNOR2X1 U188 ( .IN1(n111), .IN2(assembled[21]), .Q(n52) );
  XNOR2X1 U189 ( .IN1(n51), .IN2(n50), .Q(n107) );
  XNOR2X1 U190 ( .IN1(n112), .IN2(assembled[19]), .Q(n51) );
  XOR2X1 U191 ( .IN1(n46), .IN2(n48), .Q(n102) );
  XNOR2X1 U192 ( .IN1(n113), .IN2(assembled[9]), .Q(n46) );
  XOR2X1 U193 ( .IN1(n114), .IN2(n115), .Q(n92) );
  XOR3X1 U194 ( .IN1(n48), .IN2(n50), .IN3(n54), .Q(n115) );
  XNOR2X1 U195 ( .IN1(n116), .IN2(assembled[25]), .Q(n54) );
  XNOR2X1 U196 ( .IN1(n117), .IN2(assembled[17]), .Q(n50) );
  XNOR2X1 U197 ( .IN1(n118), .IN2(assembled[13]), .Q(n48) );
  XNOR3X1 U198 ( .IN1(n98), .IN2(n104), .IN3(n109), .Q(n114) );
  XNOR3X1 U199 ( .IN1(assembled[1]), .IN2(n119), .IN3(n100), .Q(n109) );
  XOR2X1 U200 ( .IN1(n120), .IN2(assembled[7]), .Q(n100) );
  XOR2X1 U201 ( .IN1(n121), .IN2(assembled[3]), .Q(n104) );
  XOR2X1 U202 ( .IN1(n47), .IN2(n49), .Q(n98) );
  XNOR2X1 U203 ( .IN1(n122), .IN2(assembled[15]), .Q(n49) );
  XNOR2X1 U204 ( .IN1(n123), .IN2(assembled[11]), .Q(n47) );
  XOR2X1 U205 ( .IN1(n124), .IN2(n125), .Q(n61) );
  XNOR3X1 U206 ( .IN1(n34), .IN2(n41), .IN3(n36), .Q(n125) );
  XNOR2X1 U207 ( .IN1(n126), .IN2(n127), .Q(n36) );
  XNOR2X1 U208 ( .IN1(n128), .IN2(n129), .Q(n41) );
  XOR2X1 U209 ( .IN1(n130), .IN2(n131), .Q(n34) );
  XNOR3X1 U210 ( .IN1(n74), .IN2(n85), .IN3(n66), .Q(n124) );
  XNOR2X1 U211 ( .IN1(n86), .IN2(n40), .Q(n66) );
  XNOR2X1 U212 ( .IN1(n132), .IN2(n133), .Q(n40) );
  XOR2X1 U213 ( .IN1(n134), .IN2(n135), .Q(n86) );
  XNOR2X1 U214 ( .IN1(n59), .IN2(n136), .Q(n85) );
  XOR2X1 U215 ( .IN1(n39), .IN2(n38), .Q(n74) );
  XOR2X1 U216 ( .IN1(n137), .IN2(n138), .Q(n38) );
  XNOR2X1 U217 ( .IN1(n139), .IN2(n140), .Q(n39) );
  AO22X1 U218 ( .IN1(n473), .IN2(assembled[29]), .IN3(n476), .IN4(
        assembled[28]), .Q(n291) );
  AO22X1 U219 ( .IN1(n473), .IN2(assembled[28]), .IN3(n476), .IN4(
        assembled[27]), .Q(n292) );
  AO22X1 U220 ( .IN1(n473), .IN2(assembled[27]), .IN3(n476), .IN4(
        assembled[26]), .Q(n293) );
  AO22X1 U221 ( .IN1(n473), .IN2(assembled[26]), .IN3(n476), .IN4(
        assembled[25]), .Q(n294) );
  AO22X1 U222 ( .IN1(n473), .IN2(assembled[25]), .IN3(n476), .IN4(
        assembled[24]), .Q(n295) );
  AO22X1 U223 ( .IN1(n473), .IN2(assembled[24]), .IN3(n476), .IN4(
        assembled[23]), .Q(n296) );
  AO22X1 U224 ( .IN1(n474), .IN2(assembled[23]), .IN3(n476), .IN4(
        assembled[22]), .Q(n297) );
  AO22X1 U225 ( .IN1(n474), .IN2(assembled[22]), .IN3(n476), .IN4(
        assembled[21]), .Q(n298) );
  AO22X1 U226 ( .IN1(n474), .IN2(assembled[21]), .IN3(n476), .IN4(
        assembled[20]), .Q(n299) );
  AO22X1 U227 ( .IN1(n474), .IN2(assembled[20]), .IN3(n476), .IN4(
        assembled[19]), .Q(n300) );
  AO22X1 U228 ( .IN1(n474), .IN2(assembled[19]), .IN3(n476), .IN4(
        assembled[18]), .Q(n301) );
  AO22X1 U229 ( .IN1(n474), .IN2(assembled[18]), .IN3(n476), .IN4(
        assembled[17]), .Q(n302) );
  AO22X1 U230 ( .IN1(n474), .IN2(assembled[17]), .IN3(n475), .IN4(
        assembled[16]), .Q(n303) );
  AO22X1 U231 ( .IN1(n474), .IN2(assembled[16]), .IN3(n475), .IN4(
        assembled[15]), .Q(n304) );
  AO22X1 U232 ( .IN1(n474), .IN2(assembled[15]), .IN3(n475), .IN4(
        assembled[14]), .Q(n305) );
  AO22X1 U233 ( .IN1(n474), .IN2(assembled[14]), .IN3(n475), .IN4(
        assembled[13]), .Q(n306) );
  AO22X1 U234 ( .IN1(n474), .IN2(assembled[13]), .IN3(n475), .IN4(
        assembled[12]), .Q(n307) );
  AO22X1 U235 ( .IN1(n474), .IN2(assembled[12]), .IN3(n475), .IN4(
        assembled[11]), .Q(n308) );
  AO221X1 U236 ( .IN1(n473), .IN2(assembled[11]), .IN3(assembled[10]), .IN4(
        n141), .IN5(n142), .Q(n309) );
  AO221X1 U237 ( .IN1(n473), .IN2(assembled[10]), .IN3(assembled[9]), .IN4(
        n141), .IN5(n142), .Q(n310) );
  AO221X1 U238 ( .IN1(n473), .IN2(assembled[9]), .IN3(assembled[8]), .IN4(n141), .IN5(n142), .Q(n311) );
  AO22X1 U239 ( .IN1(n474), .IN2(assembled[8]), .IN3(n475), .IN4(assembled[7]), 
        .Q(n312) );
  AO22X1 U240 ( .IN1(n474), .IN2(assembled[7]), .IN3(n475), .IN4(assembled[6]), 
        .Q(n313) );
  AO22X1 U241 ( .IN1(n474), .IN2(assembled[6]), .IN3(n475), .IN4(assembled[5]), 
        .Q(n314) );
  AO221X1 U242 ( .IN1(n473), .IN2(assembled[5]), .IN3(assembled[4]), .IN4(n141), .IN5(n142), .Q(n315) );
  AO22X1 U243 ( .IN1(n474), .IN2(assembled[4]), .IN3(n475), .IN4(assembled[3]), 
        .Q(n316) );
  AO22X1 U244 ( .IN1(n474), .IN2(assembled[3]), .IN3(n475), .IN4(assembled[2]), 
        .Q(n317) );
  AO221X1 U245 ( .IN1(n473), .IN2(assembled[2]), .IN3(assembled[1]), .IN4(n141), .IN5(n142), .Q(n318) );
  AO22X1 U246 ( .IN1(n474), .IN2(assembled[1]), .IN3(n475), .IN4(n59), .Q(n319) );
  AO22X1 U247 ( .IN1(polarity_inverted), .IN2(n144), .IN3(n547), .IN4(n145), 
        .Q(n320) );
  AO22X1 U248 ( .IN1(start_ref[0]), .IN2(n506), .IN3(word_ref[0]), .IN4(n497), 
        .Q(n321) );
  AO22X1 U249 ( .IN1(N470), .IN2(n486), .IN3(n487), .IN4(start_ref[0]), .Q(
        n322) );
  AO22X1 U250 ( .IN1(start_ref[1]), .IN2(n506), .IN3(word_ref[1]), .IN4(n497), 
        .Q(n323) );
  AO22X1 U251 ( .IN1(N471), .IN2(n486), .IN3(start_ref[1]), .IN4(n488), .Q(
        n324) );
  AO22X1 U252 ( .IN1(start_ref[2]), .IN2(n507), .IN3(word_ref[2]), .IN4(n497), 
        .Q(n325) );
  AO22X1 U253 ( .IN1(N472), .IN2(n486), .IN3(start_ref[2]), .IN4(n489), .Q(
        n326) );
  AO22X1 U254 ( .IN1(start_ref[3]), .IN2(n507), .IN3(word_ref[3]), .IN4(n497), 
        .Q(n327) );
  AO22X1 U255 ( .IN1(N473), .IN2(n486), .IN3(start_ref[3]), .IN4(n490), .Q(
        n328) );
  AO22X1 U256 ( .IN1(start_ref[4]), .IN2(n507), .IN3(word_ref[4]), .IN4(n497), 
        .Q(n329) );
  AO22X1 U257 ( .IN1(N474), .IN2(n486), .IN3(start_ref[4]), .IN4(n488), .Q(
        n330) );
  AO22X1 U258 ( .IN1(start_ref[5]), .IN2(n507), .IN3(word_ref[5]), .IN4(n497), 
        .Q(n331) );
  AO22X1 U259 ( .IN1(N475), .IN2(n486), .IN3(start_ref[5]), .IN4(n489), .Q(
        n332) );
  AO22X1 U260 ( .IN1(start_ref[6]), .IN2(n507), .IN3(word_ref[6]), .IN4(n497), 
        .Q(n333) );
  AO22X1 U261 ( .IN1(N476), .IN2(n486), .IN3(start_ref[6]), .IN4(n490), .Q(
        n334) );
  AO22X1 U262 ( .IN1(start_ref[7]), .IN2(n507), .IN3(word_ref[7]), .IN4(n497), 
        .Q(n335) );
  AO22X1 U263 ( .IN1(N477), .IN2(n486), .IN3(start_ref[7]), .IN4(n487), .Q(
        n336) );
  AO22X1 U264 ( .IN1(start_ref[8]), .IN2(n507), .IN3(word_ref[8]), .IN4(n497), 
        .Q(n337) );
  AO22X1 U265 ( .IN1(N478), .IN2(n485), .IN3(start_ref[8]), .IN4(n488), .Q(
        n338) );
  AO22X1 U266 ( .IN1(start_ref[9]), .IN2(n507), .IN3(word_ref[9]), .IN4(n497), 
        .Q(n339) );
  AO22X1 U267 ( .IN1(N479), .IN2(n485), .IN3(start_ref[9]), .IN4(n489), .Q(
        n340) );
  AO22X1 U268 ( .IN1(start_ref[10]), .IN2(n508), .IN3(word_ref[10]), .IN4(n497), .Q(n341) );
  AO22X1 U269 ( .IN1(N480), .IN2(n485), .IN3(start_ref[10]), .IN4(n490), .Q(
        n342) );
  AO22X1 U270 ( .IN1(start_ref[11]), .IN2(n508), .IN3(word_ref[11]), .IN4(n497), .Q(n343) );
  AO22X1 U271 ( .IN1(N481), .IN2(n485), .IN3(start_ref[11]), .IN4(n487), .Q(
        n344) );
  AO22X1 U272 ( .IN1(start_ref[12]), .IN2(n508), .IN3(word_ref[12]), .IN4(n497), .Q(n345) );
  AO22X1 U273 ( .IN1(N482), .IN2(n485), .IN3(start_ref[12]), .IN4(n490), .Q(
        n346) );
  AO22X1 U274 ( .IN1(start_ref[13]), .IN2(n508), .IN3(word_ref[13]), .IN4(n497), .Q(n347) );
  AO22X1 U275 ( .IN1(N483), .IN2(n485), .IN3(start_ref[13]), .IN4(n487), .Q(
        n348) );
  AO22X1 U276 ( .IN1(start_ref[14]), .IN2(n508), .IN3(word_ref[14]), .IN4(n497), .Q(n349) );
  AO22X1 U277 ( .IN1(N484), .IN2(n485), .IN3(start_ref[14]), .IN4(n488), .Q(
        n350) );
  AO22X1 U278 ( .IN1(start_ref[15]), .IN2(n508), .IN3(word_ref[15]), .IN4(n498), .Q(n351) );
  AO22X1 U279 ( .IN1(N485), .IN2(n484), .IN3(start_ref[15]), .IN4(n489), .Q(
        n352) );
  AO22X1 U280 ( .IN1(start_ref[16]), .IN2(n508), .IN3(word_ref[16]), .IN4(n498), .Q(n353) );
  AO22X1 U281 ( .IN1(N486), .IN2(n484), .IN3(start_ref[16]), .IN4(n490), .Q(
        n354) );
  AO22X1 U282 ( .IN1(start_ref[17]), .IN2(n508), .IN3(word_ref[17]), .IN4(n498), .Q(n355) );
  AO22X1 U283 ( .IN1(N487), .IN2(n484), .IN3(start_ref[17]), .IN4(n490), .Q(
        n356) );
  AO22X1 U284 ( .IN1(start_ref[18]), .IN2(n508), .IN3(word_ref[18]), .IN4(n498), .Q(n357) );
  AO22X1 U285 ( .IN1(N488), .IN2(n484), .IN3(start_ref[18]), .IN4(n490), .Q(
        n358) );
  AO22X1 U286 ( .IN1(start_ref[19]), .IN2(n506), .IN3(word_ref[19]), .IN4(n498), .Q(n359) );
  AO22X1 U287 ( .IN1(N489), .IN2(n484), .IN3(start_ref[19]), .IN4(n490), .Q(
        n360) );
  AO22X1 U288 ( .IN1(start_ref[20]), .IN2(n509), .IN3(word_ref[20]), .IN4(n498), .Q(n361) );
  AO22X1 U289 ( .IN1(N490), .IN2(n484), .IN3(start_ref[20]), .IN4(n490), .Q(
        n362) );
  AO22X1 U290 ( .IN1(start_ref[21]), .IN2(n508), .IN3(word_ref[21]), .IN4(n498), .Q(n363) );
  AO22X1 U291 ( .IN1(N491), .IN2(n484), .IN3(start_ref[21]), .IN4(n490), .Q(
        n364) );
  AO22X1 U292 ( .IN1(start_ref[22]), .IN2(n507), .IN3(word_ref[22]), .IN4(n498), .Q(n365) );
  AO22X1 U293 ( .IN1(N492), .IN2(n483), .IN3(start_ref[22]), .IN4(n490), .Q(
        n366) );
  AO22X1 U294 ( .IN1(start_ref[23]), .IN2(n506), .IN3(word_ref[23]), .IN4(n498), .Q(n367) );
  AO22X1 U295 ( .IN1(N493), .IN2(n483), .IN3(start_ref[23]), .IN4(n490), .Q(
        n368) );
  AO22X1 U296 ( .IN1(start_ref[24]), .IN2(n509), .IN3(word_ref[24]), .IN4(n498), .Q(n369) );
  AO22X1 U297 ( .IN1(N494), .IN2(n483), .IN3(start_ref[24]), .IN4(n490), .Q(
        n370) );
  AO22X1 U298 ( .IN1(start_ref[25]), .IN2(n508), .IN3(word_ref[25]), .IN4(n498), .Q(n371) );
  AO22X1 U299 ( .IN1(N495), .IN2(n483), .IN3(start_ref[25]), .IN4(n490), .Q(
        n372) );
  AO22X1 U300 ( .IN1(start_ref[26]), .IN2(n507), .IN3(word_ref[26]), .IN4(n498), .Q(n373) );
  AO22X1 U301 ( .IN1(N496), .IN2(n483), .IN3(start_ref[26]), .IN4(n490), .Q(
        n374) );
  AO22X1 U302 ( .IN1(start_ref[27]), .IN2(n509), .IN3(word_ref[27]), .IN4(n498), .Q(n375) );
  AO22X1 U303 ( .IN1(N497), .IN2(n483), .IN3(start_ref[27]), .IN4(n490), .Q(
        n376) );
  AO22X1 U304 ( .IN1(start_ref[28]), .IN2(n509), .IN3(word_ref[28]), .IN4(n498), .Q(n377) );
  AO22X1 U305 ( .IN1(N498), .IN2(n483), .IN3(start_ref[28]), .IN4(n489), .Q(
        n378) );
  AO22X1 U306 ( .IN1(start_ref[29]), .IN2(n509), .IN3(word_ref[29]), .IN4(n498), .Q(n379) );
  AO22X1 U307 ( .IN1(N499), .IN2(n482), .IN3(start_ref[29]), .IN4(n489), .Q(
        n380) );
  AO22X1 U308 ( .IN1(start_ref[30]), .IN2(n509), .IN3(word_ref[30]), .IN4(n498), .Q(n381) );
  AO22X1 U309 ( .IN1(N500), .IN2(n482), .IN3(start_ref[30]), .IN4(n489), .Q(
        n382) );
  AO22X1 U310 ( .IN1(start_ref[31]), .IN2(n509), .IN3(word_ref[31]), .IN4(n498), .Q(n383) );
  AO22X1 U311 ( .IN1(N501), .IN2(n482), .IN3(start_ref[31]), .IN4(n489), .Q(
        n384) );
  AO22X1 U312 ( .IN1(start_ref[32]), .IN2(n509), .IN3(word_ref[32]), .IN4(n498), .Q(n385) );
  AO22X1 U313 ( .IN1(N502), .IN2(n482), .IN3(start_ref[32]), .IN4(n489), .Q(
        n386) );
  AO22X1 U314 ( .IN1(start_ref[33]), .IN2(n509), .IN3(word_ref[33]), .IN4(n498), .Q(n387) );
  AO22X1 U315 ( .IN1(N503), .IN2(n482), .IN3(start_ref[33]), .IN4(n489), .Q(
        n388) );
  AO22X1 U316 ( .IN1(start_ref[34]), .IN2(n509), .IN3(word_ref[34]), .IN4(n497), .Q(n389) );
  AO22X1 U317 ( .IN1(N504), .IN2(n482), .IN3(start_ref[34]), .IN4(n489), .Q(
        n390) );
  AO22X1 U318 ( .IN1(start_ref[35]), .IN2(n509), .IN3(word_ref[35]), .IN4(n498), .Q(n391) );
  AO22X1 U319 ( .IN1(N505), .IN2(n482), .IN3(start_ref[35]), .IN4(n489), .Q(
        n392) );
  AO22X1 U320 ( .IN1(start_ref[36]), .IN2(n509), .IN3(word_ref[36]), .IN4(n498), .Q(n393) );
  AO22X1 U321 ( .IN1(N506), .IN2(n481), .IN3(start_ref[36]), .IN4(n489), .Q(
        n394) );
  AO22X1 U322 ( .IN1(start_ref[37]), .IN2(n508), .IN3(word_ref[37]), .IN4(n498), .Q(n395) );
  AO22X1 U323 ( .IN1(N507), .IN2(n481), .IN3(start_ref[37]), .IN4(n489), .Q(
        n396) );
  AO22X1 U324 ( .IN1(start_ref[38]), .IN2(n507), .IN3(word_ref[38]), .IN4(n498), .Q(n397) );
  AO22X1 U325 ( .IN1(N508), .IN2(n481), .IN3(start_ref[38]), .IN4(n489), .Q(
        n398) );
  AO22X1 U326 ( .IN1(start_ref[39]), .IN2(n509), .IN3(word_ref[39]), .IN4(n498), .Q(n399) );
  AO22X1 U327 ( .IN1(N509), .IN2(n481), .IN3(start_ref[39]), .IN4(n489), .Q(
        n400) );
  AO22X1 U328 ( .IN1(start_ref[40]), .IN2(n506), .IN3(word_ref[40]), .IN4(n498), .Q(n401) );
  AO22X1 U329 ( .IN1(N510), .IN2(n481), .IN3(start_ref[40]), .IN4(n488), .Q(
        n402) );
  AO22X1 U330 ( .IN1(start_ref[41]), .IN2(n508), .IN3(word_ref[41]), .IN4(n498), .Q(n403) );
  AO22X1 U331 ( .IN1(N511), .IN2(n481), .IN3(start_ref[41]), .IN4(n488), .Q(
        n404) );
  AO22X1 U332 ( .IN1(start_ref[42]), .IN2(n507), .IN3(word_ref[42]), .IN4(n498), .Q(n405) );
  AO22X1 U333 ( .IN1(N512), .IN2(n481), .IN3(start_ref[42]), .IN4(n488), .Q(
        n406) );
  AO22X1 U334 ( .IN1(start_ref[43]), .IN2(n509), .IN3(word_ref[43]), .IN4(n498), .Q(n407) );
  AO22X1 U335 ( .IN1(N513), .IN2(n480), .IN3(start_ref[43]), .IN4(n488), .Q(
        n408) );
  AO22X1 U336 ( .IN1(start_ref[44]), .IN2(n506), .IN3(word_ref[44]), .IN4(n498), .Q(n409) );
  AO22X1 U337 ( .IN1(N514), .IN2(n480), .IN3(start_ref[44]), .IN4(n488), .Q(
        n410) );
  AO22X1 U338 ( .IN1(start_ref[45]), .IN2(n509), .IN3(word_ref[45]), .IN4(n498), .Q(n411) );
  AO22X1 U339 ( .IN1(N515), .IN2(n480), .IN3(start_ref[45]), .IN4(n488), .Q(
        n412) );
  AO22X1 U340 ( .IN1(start_ref[46]), .IN2(n510), .IN3(word_ref[46]), .IN4(n499), .Q(n413) );
  AO22X1 U341 ( .IN1(N516), .IN2(n480), .IN3(start_ref[46]), .IN4(n488), .Q(
        n414) );
  AO22X1 U342 ( .IN1(start_ref[47]), .IN2(n510), .IN3(word_ref[47]), .IN4(n498), .Q(n415) );
  AO22X1 U343 ( .IN1(N517), .IN2(n480), .IN3(start_ref[47]), .IN4(n488), .Q(
        n416) );
  AO22X1 U344 ( .IN1(start_ref[48]), .IN2(n510), .IN3(word_ref[48]), .IN4(n499), .Q(n417) );
  AO22X1 U345 ( .IN1(N518), .IN2(n480), .IN3(start_ref[48]), .IN4(n488), .Q(
        n418) );
  AO22X1 U346 ( .IN1(start_ref[49]), .IN2(n510), .IN3(word_ref[49]), .IN4(n498), .Q(n419) );
  AO22X1 U347 ( .IN1(N519), .IN2(n480), .IN3(start_ref[49]), .IN4(n488), .Q(
        n420) );
  AO22X1 U348 ( .IN1(start_ref[50]), .IN2(n510), .IN3(word_ref[50]), .IN4(n499), .Q(n421) );
  AO22X1 U349 ( .IN1(N520), .IN2(n479), .IN3(start_ref[50]), .IN4(n488), .Q(
        n422) );
  AO22X1 U350 ( .IN1(start_ref[51]), .IN2(n510), .IN3(word_ref[51]), .IN4(n499), .Q(n423) );
  AO22X1 U351 ( .IN1(N521), .IN2(n479), .IN3(start_ref[51]), .IN4(n488), .Q(
        n424) );
  AO22X1 U352 ( .IN1(start_ref[52]), .IN2(n510), .IN3(word_ref[52]), .IN4(n499), .Q(n425) );
  AO22X1 U353 ( .IN1(N522), .IN2(n479), .IN3(start_ref[52]), .IN4(n487), .Q(
        n426) );
  AO22X1 U354 ( .IN1(start_ref[53]), .IN2(n510), .IN3(word_ref[53]), .IN4(n499), .Q(n427) );
  AO22X1 U355 ( .IN1(N523), .IN2(n479), .IN3(start_ref[53]), .IN4(n487), .Q(
        n428) );
  AO22X1 U356 ( .IN1(start_ref[54]), .IN2(n510), .IN3(word_ref[54]), .IN4(n499), .Q(n429) );
  AO22X1 U357 ( .IN1(N524), .IN2(n479), .IN3(start_ref[54]), .IN4(n487), .Q(
        n430) );
  AO22X1 U358 ( .IN1(start_ref[55]), .IN2(n505), .IN3(word_ref[55]), .IN4(n498), .Q(n431) );
  AO22X1 U359 ( .IN1(N525), .IN2(n479), .IN3(start_ref[55]), .IN4(n487), .Q(
        n432) );
  AO22X1 U360 ( .IN1(start_ref[56]), .IN2(n510), .IN3(word_ref[56]), .IN4(n499), .Q(n433) );
  AO22X1 U361 ( .IN1(N526), .IN2(n479), .IN3(start_ref[56]), .IN4(n487), .Q(
        n434) );
  AO22X1 U362 ( .IN1(start_ref[57]), .IN2(n506), .IN3(word_ref[57]), .IN4(n499), .Q(n435) );
  AO22X1 U363 ( .IN1(N527), .IN2(n478), .IN3(start_ref[57]), .IN4(n487), .Q(
        n436) );
  AO22X1 U364 ( .IN1(start_ref[58]), .IN2(n509), .IN3(word_ref[58]), .IN4(n499), .Q(n437) );
  AO22X1 U365 ( .IN1(N528), .IN2(n478), .IN3(start_ref[58]), .IN4(n487), .Q(
        n438) );
  AO22X1 U366 ( .IN1(start_ref[59]), .IN2(n508), .IN3(word_ref[59]), .IN4(n499), .Q(n439) );
  AO22X1 U367 ( .IN1(N530), .IN2(n478), .IN3(start_ref[59]), .IN4(n487), .Q(
        n440) );
  AO22X1 U368 ( .IN1(start_ref[60]), .IN2(n508), .IN3(word_ref[60]), .IN4(n499), .Q(n441) );
  AO22X1 U369 ( .IN1(N531), .IN2(n478), .IN3(start_ref[60]), .IN4(n487), .Q(
        n442) );
  AO22X1 U370 ( .IN1(start_ref[61]), .IN2(n507), .IN3(word_ref[61]), .IN4(n499), .Q(n443) );
  AO22X1 U371 ( .IN1(N532), .IN2(n478), .IN3(start_ref[61]), .IN4(n487), .Q(
        n444) );
  AO22X1 U372 ( .IN1(start_ref[62]), .IN2(n504), .IN3(word_ref[62]), .IN4(n498), .Q(n445) );
  AO22X1 U373 ( .IN1(N533), .IN2(n478), .IN3(start_ref[62]), .IN4(n487), .Q(
        n446) );
  AO22X1 U374 ( .IN1(start_ref[63]), .IN2(n506), .IN3(word_ref[63]), .IN4(n496), .Q(n447) );
  AO22X1 U375 ( .IN1(N534), .IN2(n478), .IN3(start_ref[63]), .IN4(n487), .Q(
        n448) );
  OR4X1 U376 ( .IN1(bit_count[3]), .IN2(bit_count[4]), .IN3(bit_count[2]), 
        .IN4(n148), .Q(n147) );
  NAND3X0 U377 ( .IN1(n149), .IN2(n25), .IN3(N447), .QN(n148) );
  AO22X1 U378 ( .IN1(N575), .IN2(n150), .IN3(n543), .IN4(current_word[3]), .Q(
        n449) );
  AO22X1 U379 ( .IN1(N574), .IN2(n150), .IN3(n543), .IN4(current_word[2]), .Q(
        n450) );
  AO22X1 U380 ( .IN1(N573), .IN2(n150), .IN3(n543), .IN4(current_word[1]), .Q(
        n451) );
  AO22X1 U381 ( .IN1(n474), .IN2(bit_count[4]), .IN3(n151), .IN4(N451), .Q(
        n452) );
  AO221X1 U382 ( .IN1(N450), .IN2(n152), .IN3(n473), .IN4(bit_count[3]), .IN5(
        n142), .Q(n453) );
  AO22X1 U383 ( .IN1(n473), .IN2(bit_count[2]), .IN3(n151), .IN4(N449), .Q(
        n454) );
  AO221X1 U384 ( .IN1(N448), .IN2(n152), .IN3(bit_count[1]), .IN4(n473), .IN5(
        n142), .Q(n455) );
  AO221X1 U385 ( .IN1(N447), .IN2(n152), .IN3(n473), .IN4(bit_count[0]), .IN5(
        n142), .Q(n456) );
  AO21X1 U386 ( .IN1(bit_valid), .IN2(n154), .IN3(n149), .Q(n141) );
  AO22X1 U387 ( .IN1(scan_next[10]), .IN2(n155), .IN3(n156), .IN4(scan_next[9]), .Q(n457) );
  AO22X1 U388 ( .IN1(scan_next[9]), .IN2(n155), .IN3(n156), .IN4(scan_next[8]), 
        .Q(n458) );
  AO22X1 U389 ( .IN1(scan_next[8]), .IN2(n155), .IN3(n156), .IN4(scan_next[7]), 
        .Q(n459) );
  AO22X1 U390 ( .IN1(scan_next[7]), .IN2(n155), .IN3(n156), .IN4(scan_next[6]), 
        .Q(n460) );
  AO22X1 U391 ( .IN1(scan_next[6]), .IN2(n155), .IN3(n156), .IN4(scan_next[5]), 
        .Q(n461) );
  AO22X1 U392 ( .IN1(scan_next[5]), .IN2(n155), .IN3(n156), .IN4(scan_next[4]), 
        .Q(n462) );
  AO22X1 U393 ( .IN1(scan_next[4]), .IN2(n155), .IN3(n156), .IN4(scan_next[3]), 
        .Q(n463) );
  AO22X1 U394 ( .IN1(scan_next[3]), .IN2(n155), .IN3(n156), .IN4(scan_next[2]), 
        .Q(n464) );
  AO22X1 U395 ( .IN1(scan_next[2]), .IN2(n155), .IN3(n156), .IN4(scan_next[1]), 
        .Q(n465) );
  AO22X1 U396 ( .IN1(scan_next[1]), .IN2(n155), .IN3(n156), .IN4(data_bit), 
        .Q(n466) );
  AO21X1 U397 ( .IN1(n157), .IN2(aligned), .IN3(n546), .Q(n155) );
  XOR2X1 U398 ( .IN1(n23), .IN2(n158), .Q(n467) );
  AO22X1 U399 ( .IN1(n549), .IN2(n150), .IN3(n543), .IN4(current_word[0]), .Q(
        n468) );
  NAND3X0 U400 ( .IN1(n154), .IN2(n23), .IN3(bit_valid), .QN(n144) );
  NAND4X0 U401 ( .IN1(scan_next[7]), .IN2(scan_next[6]), .IN3(n161), .IN4(n162), .QN(n160) );
  NOR4X0 U402 ( .IN1(n163), .IN2(scan_next[4]), .IN3(scan_next[9]), .IN4(
        scan_next[8]), .QN(n162) );
  OR3X1 U403 ( .IN1(scan_next[10]), .IN2(scan_next[1]), .IN3(n548), .Q(n163)
         );
  AND3X1 U404 ( .IN1(scan_next[3]), .IN2(scan_next[2]), .IN3(scan_next[5]), 
        .Q(n161) );
  NAND4X0 U405 ( .IN1(scan_next[9]), .IN2(scan_next[8]), .IN3(n164), .IN4(n165), .QN(n145) );
  NOR4X0 U406 ( .IN1(n166), .IN2(data_bit), .IN3(scan_next[3]), .IN4(
        scan_next[2]), .QN(n165) );
  OR3X1 U407 ( .IN1(scan_next[6]), .IN2(scan_next[7]), .IN3(scan_next[5]), .Q(
        n166) );
  AND3X1 U408 ( .IN1(scan_next[1]), .IN2(scan_next[10]), .IN3(scan_next[4]), 
        .Q(n164) );
  OR4X1 U409 ( .IN1(n167), .IN2(n168), .IN3(n169), .IN4(n170), .Q(fix_right)
         );
  NAND4X0 U410 ( .IN1(n90), .IN2(n126), .IN3(n83), .IN4(n130), .QN(n170) );
  NAND4X0 U411 ( .IN1(n134), .IN2(n72), .IN3(n87), .IN4(n136), .QN(n169) );
  NAND3X0 U412 ( .IN1(n75), .IN2(n82), .IN3(n68), .QN(n168) );
  NAND4X0 U413 ( .IN1(n129), .IN2(n132), .IN3(n139), .IN4(n137), .QN(n167) );
  XNOR3X1 U414 ( .IN1(n184), .IN2(n84), .IN3(n185), .Q(n183) );
  XOR3X1 U415 ( .IN1(n186), .IN2(n69), .IN3(n187), .Q(n185) );
  AOI22X1 U416 ( .IN1(assembled[28]), .IN2(n551), .IN3(assembled[14]), .IN4(
        n57), .QN(n69) );
  XOR2X1 U417 ( .IN1(n91), .IN2(n73), .Q(n184) );
  XNOR3X1 U418 ( .IN1(n128), .IN2(n186), .IN3(n189), .Q(n188) );
  XNOR2X1 U419 ( .IN1(n190), .IN2(n191), .Q(n189) );
  XOR2X1 U420 ( .IN1(n133), .IN2(n140), .Q(n186) );
  AO22X1 U421 ( .IN1(assembled[20]), .IN2(n551), .IN3(assembled[10]), .IN4(n57), .Q(n133) );
  AO22X1 U422 ( .IN1(assembled[22]), .IN2(n551), .IN3(assembled[11]), .IN4(n57), .Q(n128) );
  XOR3X1 U423 ( .IN1(n193), .IN2(n138), .IN3(n194), .Q(n192) );
  XNOR3X1 U424 ( .IN1(n195), .IN2(n73), .IN3(n191), .Q(n194) );
  XNOR2X1 U425 ( .IN1(n127), .IN2(n131), .Q(n191) );
  AOI22X1 U426 ( .IN1(assembled[8]), .IN2(n551), .IN3(assembled[4]), .IN4(n57), 
        .QN(n131) );
  AOI22X1 U427 ( .IN1(assembled[4]), .IN2(n551), .IN3(assembled[2]), .IN4(n57), 
        .QN(n73) );
  XOR2X1 U428 ( .IN1(n140), .IN2(n76), .Q(n193) );
  AOI22X1 U429 ( .IN1(assembled[26]), .IN2(n551), .IN3(assembled[13]), .IN4(
        n57), .QN(n76) );
  AO22X1 U430 ( .IN1(assembled[18]), .IN2(n551), .IN3(assembled[9]), .IN4(n57), 
        .Q(n140) );
  XOR3X1 U431 ( .IN1(n190), .IN2(n195), .IN3(n197), .Q(n196) );
  XOR3X1 U432 ( .IN1(n127), .IN2(n81), .IN3(n84), .Q(n197) );
  AO22X1 U433 ( .IN1(assembled[10]), .IN2(n551), .IN3(assembled[5]), .IN4(n57), 
        .Q(n84) );
  AO22X1 U434 ( .IN1(assembled[24]), .IN2(n551), .IN3(assembled[12]), .IN4(n57), .Q(n81) );
  AO22X1 U435 ( .IN1(assembled[12]), .IN2(n551), .IN3(assembled[6]), .IN4(n57), 
        .Q(n127) );
  XOR2X1 U436 ( .IN1(n88), .IN2(n91), .Q(n195) );
  AO22X1 U437 ( .IN1(assembled[14]), .IN2(n551), .IN3(assembled[7]), .IN4(n57), 
        .Q(n91) );
  AO22X1 U438 ( .IN1(assembled[2]), .IN2(n551), .IN3(assembled[1]), .IN4(n57), 
        .Q(n88) );
  XOR2X1 U440 ( .IN1(n135), .IN2(n138), .Q(n187) );
  AOI22X1 U441 ( .IN1(assembled[16]), .IN2(n551), .IN3(assembled[8]), .IN4(n57), .QN(n138) );
  AO22X1 U442 ( .IN1(assembled[6]), .IN2(n551), .IN3(assembled[3]), .IN4(n57), 
        .Q(n135) );
  XNOR2X1 U443 ( .IN1(polarity_inverted), .IN2(n548), .Q(n59) );
  OR4X1 U444 ( .IN1(n198), .IN2(n199), .IN3(n200), .IN4(n201), .Q(fix_left) );
  NAND4X0 U445 ( .IN1(n122), .IN2(n118), .IN3(n123), .IN4(n113), .QN(n201) );
  NAND4X0 U446 ( .IN1(n120), .IN2(n106), .IN3(n121), .IN4(n119), .QN(n200) );
  NAND3X0 U447 ( .IN1(n105), .IN2(n116), .IN3(n101), .QN(n199) );
  NAND4X0 U448 ( .IN1(n110), .IN2(n111), .IN3(n112), .IN4(n117), .QN(n198) );
  XOR3X1 U449 ( .IN1(n215), .IN2(n216), .IN3(n217), .Q(n214) );
  XOR3X1 U450 ( .IN1(assembled[5]), .IN2(assembled[29]), .IN3(assembled[15]), 
        .Q(n217) );
  XOR3X1 U451 ( .IN1(assembled[23]), .IN2(n219), .IN3(n220), .Q(n218) );
  XOR3X1 U452 ( .IN1(assembled[1]), .IN2(assembled[13]), .IN3(n215), .Q(n220)
         );
  XOR2X1 U453 ( .IN1(assembled[21]), .IN2(n221), .Q(n215) );
  XOR2X1 U454 ( .IN1(assembled[9]), .IN2(assembled[7]), .Q(n219) );
  XNOR3X1 U455 ( .IN1(n221), .IN2(n223), .IN3(n224), .Q(n222) );
  XOR3X1 U456 ( .IN1(assembled[9]), .IN2(assembled[5]), .IN3(assembled[27]), 
        .Q(n223) );
  XOR2X1 U457 ( .IN1(assembled[17]), .IN2(assembled[19]), .Q(n221) );
  XNOR3X1 U458 ( .IN1(n216), .IN2(n226), .IN3(n224), .Q(n225) );
  XNOR3X1 U459 ( .IN1(assembled[3]), .IN2(assembled[15]), .IN3(assembled[13]), 
        .Q(n224) );
  XOR3X1 U460 ( .IN1(assembled[25]), .IN2(assembled[1]), .IN3(assembled[17]), 
        .Q(n226) );
  XOR2X1 U461 ( .IN1(assembled[11]), .IN2(assembled[7]), .Q(n216) );
  NAND4X0 U462 ( .IN1(current_word[3]), .IN2(current_word[1]), .IN3(n30), 
        .IN4(n29), .QN(n159) );
  AND4X1 U464 ( .IN1(bit_count[4]), .IN2(bit_count[3]), .IN3(n227), .IN4(
        bit_count[2]), .Q(n153) );
  d1_word_sync_DW01_sub_0 sub_66_aco ( .A(bit_ref), .B({1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, n23, n23, 1'b0, 1'b0, 1'b0, n23, n23, n23, n23, n23, 1'b0, 
        1'b0, n23, n23, n23, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}), .CI(
        1'b0), .DIFF({N534, N533, N532, N531, N530, N528, N527, N526, N525, 
        N524, N523, N522, N521, N520, N519, N518, N517, N516, N515, N514, N513, 
        N512, N511, N510, N509, N508, N507, N506, N505, N504, N503, N502, N501, 
        N500, N499, N498, N497, N496, N495, N494, N493, N492, N491, N490, N489, 
        N488, N487, N486, N485, N484, N483, N482, N481, N480, N479, N478, N477, 
        N476, N475, N474, N473, N472, N471, N470}) );
  HADDX1 \add_85/U1_1_1  ( .A0(bit_count[1]), .B0(bit_count[0]), .C1(
        \add_85/carry [2]), .SO(N448) );
  HADDX1 \add_85/U1_1_2  ( .A0(bit_count[2]), .B0(\add_85/carry [2]), .C1(
        \add_85/carry [3]), .SO(N449) );
  HADDX1 \add_85/U1_1_3  ( .A0(bit_count[3]), .B0(\add_85/carry [3]), .C1(
        \add_85/carry [4]), .SO(N450) );
  DFFARX1 aligned_reg ( .D(n467), .CLK(clk), .RSTB(n531), .Q(aligned), .QN(n23) );
  DFFARX1 \bit_count_reg[0]  ( .D(n456), .CLK(clk), .RSTB(n530), .Q(
        bit_count[0]), .QN(N447) );
  DFFARX1 \bit_count_reg[1]  ( .D(n455), .CLK(clk), .RSTB(n529), .Q(
        bit_count[1]), .QN(n25) );
  DFFARX1 \current_word_reg[2]  ( .D(n450), .CLK(clk), .RSTB(n529), .Q(
        current_word[2]), .QN(n29) );
  DFFARX1 \scan_reg[9]  ( .D(n457), .CLK(clk), .RSTB(reset_n), .Q(
        scan_next[10]) );
  DFFARX1 \scan_reg[8]  ( .D(n458), .CLK(clk), .RSTB(n530), .Q(scan_next[9])
         );
  DFFARX1 \scan_reg[7]  ( .D(n459), .CLK(clk), .RSTB(n530), .Q(scan_next[8])
         );
  DFFARX1 \scan_reg[6]  ( .D(n460), .CLK(clk), .RSTB(n530), .Q(scan_next[7])
         );
  DFFARX1 \scan_reg[5]  ( .D(n461), .CLK(clk), .RSTB(n530), .Q(scan_next[6])
         );
  DFFARX1 \scan_reg[4]  ( .D(n462), .CLK(clk), .RSTB(n530), .Q(scan_next[5])
         );
  DFFARX1 \scan_reg[3]  ( .D(n463), .CLK(clk), .RSTB(n530), .Q(scan_next[4])
         );
  DFFARX1 \scan_reg[2]  ( .D(n464), .CLK(clk), .RSTB(n530), .Q(scan_next[3])
         );
  DFFARX1 \scan_reg[1]  ( .D(n465), .CLK(clk), .RSTB(n530), .Q(scan_next[2])
         );
  DFFARX1 \scan_reg[0]  ( .D(n466), .CLK(clk), .RSTB(n530), .Q(scan_next[1])
         );
  DFFARX1 word_valid_reg ( .D(n502), .CLK(clk), .RSTB(n518), .Q(word_valid) );
  DFFARX1 polarity_inverted_reg ( .D(n320), .CLK(clk), .RSTB(n518), .Q(
        polarity_inverted) );
  DFFARX1 \bit_count_reg[2]  ( .D(n454), .CLK(clk), .RSTB(n530), .Q(
        bit_count[2]) );
  DFFARX1 \bit_count_reg[4]  ( .D(n452), .CLK(clk), .RSTB(n529), .Q(
        bit_count[4]) );
  DFFARX1 \word_ref_reg[61]  ( .D(n443), .CLK(clk), .RSTB(n529), .Q(
        word_ref[61]) );
  DFFARX1 \word_ref_reg[60]  ( .D(n441), .CLK(clk), .RSTB(n528), .Q(
        word_ref[60]) );
  DFFARX1 \word_ref_reg[59]  ( .D(n439), .CLK(clk), .RSTB(n528), .Q(
        word_ref[59]) );
  DFFARX1 \word_ref_reg[58]  ( .D(n437), .CLK(clk), .RSTB(n528), .Q(
        word_ref[58]) );
  DFFARX1 \word_ref_reg[57]  ( .D(n435), .CLK(clk), .RSTB(n528), .Q(
        word_ref[57]) );
  DFFARX1 \word_ref_reg[56]  ( .D(n433), .CLK(clk), .RSTB(n528), .Q(
        word_ref[56]) );
  DFFARX1 \word_ref_reg[54]  ( .D(n429), .CLK(clk), .RSTB(n527), .Q(
        word_ref[54]) );
  DFFARX1 \word_ref_reg[53]  ( .D(n427), .CLK(clk), .RSTB(n527), .Q(
        word_ref[53]) );
  DFFARX1 \word_ref_reg[52]  ( .D(n425), .CLK(clk), .RSTB(n527), .Q(
        word_ref[52]) );
  DFFARX1 \word_ref_reg[51]  ( .D(n423), .CLK(clk), .RSTB(n527), .Q(
        word_ref[51]) );
  DFFARX1 \word_ref_reg[50]  ( .D(n421), .CLK(clk), .RSTB(n527), .Q(
        word_ref[50]) );
  DFFARX1 \word_ref_reg[48]  ( .D(n417), .CLK(clk), .RSTB(n526), .Q(
        word_ref[48]) );
  DFFARX1 \word_ref_reg[46]  ( .D(n413), .CLK(clk), .RSTB(n526), .Q(
        word_ref[46]) );
  DFFARX1 \shift_reg[27]  ( .D(n292), .CLK(clk), .RSTB(n516), .Q(assembled[28]) );
  DFFARX1 \shift_reg[25]  ( .D(n294), .CLK(clk), .RSTB(n516), .Q(assembled[26]) );
  DFFARX1 \shift_reg[15]  ( .D(n304), .CLK(clk), .RSTB(n517), .Q(assembled[16]) );
  DFFARX1 \shift_reg[7]  ( .D(n312), .CLK(clk), .RSTB(n518), .Q(assembled[8])
         );
  DFFARX1 \shift_reg[3]  ( .D(n316), .CLK(clk), .RSTB(n518), .Q(assembled[4])
         );
  DFFARX1 \shift_reg[23]  ( .D(n296), .CLK(clk), .RSTB(n516), .Q(assembled[24]) );
  DFFARX1 \shift_reg[21]  ( .D(n298), .CLK(clk), .RSTB(n516), .Q(assembled[22]) );
  DFFARX1 \shift_reg[19]  ( .D(n300), .CLK(clk), .RSTB(n517), .Q(assembled[20]) );
  DFFARX1 \shift_reg[17]  ( .D(n302), .CLK(clk), .RSTB(n517), .Q(assembled[18]) );
  DFFARX1 \shift_reg[13]  ( .D(n306), .CLK(clk), .RSTB(n517), .Q(assembled[14]) );
  DFFARX1 \shift_reg[11]  ( .D(n308), .CLK(clk), .RSTB(n517), .Q(assembled[12]) );
  DFFARX1 \shift_reg[5]  ( .D(n314), .CLK(clk), .RSTB(n518), .Q(assembled[6])
         );
  DFFARX1 \shift_reg[28]  ( .D(n291), .CLK(clk), .RSTB(n516), .Q(assembled[29]) );
  DFFARX1 \shift_reg[24]  ( .D(n295), .CLK(clk), .RSTB(n516), .Q(assembled[25]) );
  DFFARX1 \shift_reg[22]  ( .D(n297), .CLK(clk), .RSTB(n516), .Q(assembled[23]) );
  DFFARX1 \shift_reg[26]  ( .D(n293), .CLK(clk), .RSTB(n516), .Q(assembled[27]) );
  DFFARX1 \shift_reg[18]  ( .D(n301), .CLK(clk), .RSTB(n517), .Q(assembled[19]) );
  DFFARX1 \shift_reg[2]  ( .D(n317), .CLK(clk), .RSTB(n518), .Q(assembled[3])
         );
  DFFARX1 \shift_reg[20]  ( .D(n299), .CLK(clk), .RSTB(n516), .Q(assembled[21]) );
  DFFARX1 \shift_reg[12]  ( .D(n307), .CLK(clk), .RSTB(n517), .Q(assembled[13]) );
  DFFARX1 \shift_reg[0]  ( .D(n319), .CLK(clk), .RSTB(n518), .Q(assembled[1])
         );
  DFFARX1 \shift_reg[14]  ( .D(n305), .CLK(clk), .RSTB(n517), .Q(assembled[15]) );
  DFFARX1 \shift_reg[6]  ( .D(n313), .CLK(clk), .RSTB(n518), .Q(assembled[7])
         );
  DFFARX1 \shift_reg[16]  ( .D(n303), .CLK(clk), .RSTB(n517), .Q(assembled[17]) );
  DFFARX1 \raw_word_reg[0]  ( .D(n260), .CLK(clk), .RSTB(n513), .Q(raw_word[0]) );
  DFFARX1 \information_reg[25]  ( .D(n259), .CLK(clk), .RSTB(n513), .Q(
        information[25]) );
  DFFARX1 \information_reg[24]  ( .D(n258), .CLK(clk), .RSTB(n513), .Q(
        information[24]) );
  DFFARX1 \information_reg[23]  ( .D(n257), .CLK(clk), .RSTB(n513), .Q(
        information[23]) );
  DFFARX1 \information_reg[22]  ( .D(n256), .CLK(clk), .RSTB(n513), .Q(
        information[22]) );
  DFFARX1 \word_ref_reg[63]  ( .D(n447), .CLK(clk), .RSTB(n529), .Q(
        word_ref[63]) );
  DFFARX1 \word_number_reg[3]  ( .D(n233), .CLK(clk), .RSTB(n511), .Q(
        word_number[3]) );
  DFFARX1 \word_number_reg[2]  ( .D(n232), .CLK(clk), .RSTB(n511), .Q(
        word_number[2]) );
  DFFARX1 \word_number_reg[1]  ( .D(n231), .CLK(clk), .RSTB(n511), .Q(
        word_number[1]) );
  DFFARX1 \word_number_reg[0]  ( .D(n230), .CLK(clk), .RSTB(n511), .Q(
        word_number[0]) );
  DFFARX1 \raw_word_reg[10]  ( .D(n270), .CLK(clk), .RSTB(n514), .Q(
        raw_word[10]) );
  DFFARX1 \raw_word_reg[9]  ( .D(n269), .CLK(clk), .RSTB(n514), .Q(raw_word[9]) );
  DFFARX1 \raw_word_reg[8]  ( .D(n268), .CLK(clk), .RSTB(n514), .Q(raw_word[8]) );
  DFFARX1 \raw_word_reg[7]  ( .D(n267), .CLK(clk), .RSTB(n514), .Q(raw_word[7]) );
  NAND2X1 U465 ( .IN1(current_word[2]), .IN2(N899), .QN(n469) );
  INVX0 U466 ( .INP(n510), .ZN(n496) );
  INVX0 U467 ( .INP(n491), .ZN(n502) );
  INVX0 U468 ( .INP(n491), .ZN(n500) );
  INVX0 U469 ( .INP(n491), .ZN(n501) );
  NOR2X0 U470 ( .IN1(n536), .IN2(n535), .QN(n176) );
  NOR2X0 U471 ( .IN1(n538), .IN2(n537), .QN(n178) );
  NAND2X1 U472 ( .IN1(n178), .IN2(n174), .QN(n68) );
  NAND2X1 U473 ( .IN1(n177), .IN2(n175), .QN(n137) );
  NAND2X1 U474 ( .IN1(n176), .IN2(n171), .QN(n75) );
  NAND2X1 U475 ( .IN1(n171), .IN2(n172), .QN(n130) );
  NAND2X1 U476 ( .IN1(n177), .IN2(n173), .QN(n134) );
  NAND2X1 U477 ( .IN1(n176), .IN2(n173), .QN(n82) );
  NAND2X1 U478 ( .IN1(n173), .IN2(n172), .QN(n136) );
  NAND2X1 U479 ( .IN1(n176), .IN2(n175), .QN(n87) );
  NAND2X1 U480 ( .IN1(n178), .IN2(n172), .QN(n129) );
  NAND2X1 U481 ( .IN1(n174), .IN2(n171), .QN(n72) );
  NAND2X1 U482 ( .IN1(n178), .IN2(n177), .QN(n132) );
  NAND2X1 U483 ( .IN1(n173), .IN2(n174), .QN(n83) );
  NAND2X1 U484 ( .IN1(n177), .IN2(n171), .QN(n139) );
  NAND2X1 U485 ( .IN1(n175), .IN2(n172), .QN(n126) );
  NAND2X1 U486 ( .IN1(n175), .IN2(n174), .QN(n90) );
  INVX0 U487 ( .INP(n492), .ZN(n503) );
  INVX0 U488 ( .INP(n493), .ZN(n504) );
  INVX0 U489 ( .INP(n493), .ZN(n505) );
  INVX0 U490 ( .INP(n493), .ZN(n506) );
  INVX0 U491 ( .INP(n494), .ZN(n507) );
  INVX0 U492 ( .INP(n494), .ZN(n508) );
  INVX0 U493 ( .INP(n495), .ZN(n509) );
  INVX0 U494 ( .INP(n495), .ZN(n510) );
  NBUFFX2 U495 ( .INP(n33), .Z(n491) );
  NAND2X1 U496 ( .IN1(n208), .IN2(n206), .QN(n117) );
  NAND2X1 U497 ( .IN1(n208), .IN2(n202), .QN(n112) );
  NOR2X0 U498 ( .IN1(n182), .IN2(n538), .QN(n171) );
  NOR2X0 U499 ( .IN1(n181), .IN2(n535), .QN(n172) );
  NOR2X0 U500 ( .IN1(n179), .IN2(n536), .QN(n174) );
  NOR2X0 U501 ( .IN1(n179), .IN2(n181), .QN(n177) );
  NOR2X0 U502 ( .IN1(n180), .IN2(n537), .QN(n173) );
  NOR2X0 U503 ( .IN1(n180), .IN2(n182), .QN(n175) );
  NOR2X0 U504 ( .IN1(n542), .IN2(n541), .QN(n209) );
  NOR2X0 U505 ( .IN1(n540), .IN2(n539), .QN(n207) );
  NBUFFX2 U506 ( .INP(n33), .Z(n492) );
  INVX0 U507 ( .INP(n182), .ZN(n537) );
  INVX0 U508 ( .INP(n179), .ZN(n535) );
  INVX0 U509 ( .INP(n181), .ZN(n536) );
  INVX0 U510 ( .INP(n180), .ZN(n538) );
  INVX0 U511 ( .INP(n150), .ZN(n543) );
  NAND2X1 U512 ( .IN1(n207), .IN2(n206), .QN(n121) );
  NAND2X1 U513 ( .IN1(n208), .IN2(n204), .QN(n120) );
  NAND2X1 U514 ( .IN1(n204), .IN2(n203), .QN(n119) );
  NAND2X1 U515 ( .IN1(n205), .IN2(n202), .QN(n106) );
  NAND2X1 U516 ( .IN1(n207), .IN2(n204), .QN(n116) );
  NAND2X1 U517 ( .IN1(n209), .IN2(n205), .QN(n101) );
  NAND2X1 U518 ( .IN1(n207), .IN2(n202), .QN(n105) );
  NAND2X1 U519 ( .IN1(n209), .IN2(n208), .QN(n111) );
  NAND2X1 U520 ( .IN1(n204), .IN2(n205), .QN(n123) );
  NAND2X1 U521 ( .IN1(n202), .IN2(n203), .QN(n113) );
  NAND2X1 U522 ( .IN1(n206), .IN2(n203), .QN(n118) );
  NAND2X1 U523 ( .IN1(n206), .IN2(n205), .QN(n122) );
  NAND2X1 U524 ( .IN1(n209), .IN2(n203), .QN(n110) );
  XNOR2X1 U525 ( .IN1(n71), .IN2(n65), .Q(n70) );
  NBUFFX2 U526 ( .INP(n544), .Z(n473) );
  INVX0 U527 ( .INP(n58), .ZN(n534) );
  NBUFFX2 U528 ( .INP(n544), .Z(n474) );
  NBUFFX2 U529 ( .INP(n545), .Z(n476) );
  NBUFFX2 U530 ( .INP(n545), .Z(n475) );
  NBUFFX2 U531 ( .INP(n33), .Z(n493) );
  NBUFFX2 U532 ( .INP(n33), .Z(n494) );
  NBUFFX2 U533 ( .INP(n33), .Z(n495) );
  NOR2X0 U534 ( .IN1(n213), .IN2(n542), .QN(n202) );
  NOR2X0 U535 ( .IN1(n211), .IN2(n213), .QN(n206) );
  NOR2X0 U536 ( .IN1(n210), .IN2(n212), .QN(n208) );
  NAND2X1 U537 ( .IN1(n149), .IN2(n153), .QN(n33) );
  INVX0 U538 ( .INP(n211), .ZN(n542) );
  NOR2X0 U539 ( .IN1(n95), .IN2(n96), .QN(n94) );
  NOR2X0 U540 ( .IN1(n496), .IN2(n57), .QN(n45) );
  INVX0 U541 ( .INP(n57), .ZN(n551) );
  NOR2X0 U542 ( .IN1(n212), .IN2(n539), .QN(n203) );
  NOR2X0 U543 ( .IN1(n210), .IN2(n540), .QN(n205) );
  NOR2X0 U544 ( .IN1(n211), .IN2(n541), .QN(n204) );
  NAND2X1 U545 ( .IN1(n496), .IN2(n144), .QN(n150) );
  NAND2X1 U546 ( .IN1(n501), .IN2(n183), .QN(n179) );
  NAND2X1 U547 ( .IN1(n188), .IN2(n502), .QN(n181) );
  NAND2X1 U548 ( .IN1(n196), .IN2(n502), .QN(n180) );
  NAND2X1 U549 ( .IN1(n501), .IN2(n192), .QN(n182) );
  INVX0 U550 ( .INP(n213), .ZN(n541) );
  INVX0 U551 ( .INP(n212), .ZN(n540) );
  INVX0 U552 ( .INP(n210), .ZN(n539) );
  XNOR2X1 U553 ( .IN1(n59), .IN2(n187), .Q(n190) );
  XNOR2X1 U554 ( .IN1(n36), .IN2(n37), .Q(n89) );
  NBUFFX2 U555 ( .INP(n146), .Z(n486) );
  NBUFFX2 U556 ( .INP(n146), .Z(n485) );
  NBUFFX2 U557 ( .INP(n146), .Z(n484) );
  NBUFFX2 U558 ( .INP(n146), .Z(n483) );
  NBUFFX2 U559 ( .INP(n146), .Z(n482) );
  NBUFFX2 U560 ( .INP(n146), .Z(n481) );
  NBUFFX2 U561 ( .INP(n146), .Z(n480) );
  NBUFFX2 U562 ( .INP(n146), .Z(n479) );
  NBUFFX2 U563 ( .INP(n146), .Z(n478) );
  NBUFFX2 U564 ( .INP(n146), .Z(n477) );
  NOR2X0 U565 ( .IN1(n473), .IN2(n153), .QN(n152) );
  NAND2X1 U566 ( .IN1(n500), .IN2(n57), .QN(n58) );
  NOR2X0 U567 ( .IN1(n153), .IN2(n143), .QN(n151) );
  INVX0 U568 ( .INP(n141), .ZN(n544) );
  INVX0 U569 ( .INP(n143), .ZN(n545) );
  INVX0 U570 ( .INP(n159), .ZN(n550) );
  NAND2X1 U571 ( .IN1(n471), .IN2(n472), .QN(n552) );
  NBUFFX2 U572 ( .INP(n532), .Z(n520) );
  NBUFFX2 U573 ( .INP(n532), .Z(n521) );
  NBUFFX2 U574 ( .INP(n532), .Z(n522) );
  NBUFFX2 U575 ( .INP(n532), .Z(n523) );
  NBUFFX2 U576 ( .INP(n532), .Z(n524) );
  NBUFFX2 U577 ( .INP(n532), .Z(n525) );
  NBUFFX2 U578 ( .INP(n532), .Z(n526) );
  NBUFFX2 U579 ( .INP(n532), .Z(n527) );
  NBUFFX2 U580 ( .INP(n532), .Z(n528) );
  NBUFFX2 U581 ( .INP(n532), .Z(n529) );
  NBUFFX2 U582 ( .INP(n532), .Z(n530) );
  NBUFFX2 U583 ( .INP(n533), .Z(n511) );
  NBUFFX2 U584 ( .INP(n533), .Z(n512) );
  NBUFFX2 U585 ( .INP(n533), .Z(n513) );
  NBUFFX2 U586 ( .INP(n533), .Z(n514) );
  NBUFFX2 U587 ( .INP(n533), .Z(n515) );
  NBUFFX2 U588 ( .INP(n533), .Z(n516) );
  NBUFFX2 U589 ( .INP(n533), .Z(n517) );
  NBUFFX2 U590 ( .INP(n533), .Z(n518) );
  NBUFFX2 U591 ( .INP(n533), .Z(n519) );
  NBUFFX2 U592 ( .INP(n532), .Z(n531) );
  NOR2X0 U593 ( .IN1(n546), .IN2(n23), .QN(n149) );
  NAND2X1 U594 ( .IN1(n500), .IN2(n222), .QN(n213) );
  NAND2X1 U595 ( .IN1(n501), .IN2(n225), .QN(n211) );
  NAND2X1 U596 ( .IN1(n502), .IN2(n218), .QN(n212) );
  NAND2X1 U597 ( .IN1(n500), .IN2(n214), .QN(n210) );
  INVX0 U598 ( .INP(bit_valid), .ZN(n546) );
  NOR4X0 U599 ( .IN1(n30), .IN2(current_word[1]), .IN3(current_word[2]), .IN4(
        current_word[3]), .QN(n57) );
  NOR2X0 U600 ( .IN1(bit_count[1]), .IN2(N447), .QN(n227) );
  INVX0 U601 ( .INP(n472), .ZN(n549) );
  XOR2X1 U602 ( .IN1(\mult_add_84_aco/PROD_not[3] ), .IN2(n470), .Q(N575) );
  OR2X1 U603 ( .IN1(n552), .IN2(n469), .Q(n470) );
  INVX0 U604 ( .INP(data_bit), .ZN(n548) );
  NAND2X1 U605 ( .IN1(n145), .IN2(n160), .QN(n154) );
  NOR2X0 U606 ( .IN1(n473), .IN2(aligned), .QN(n142) );
  NAND2X1 U607 ( .IN1(n550), .IN2(n153), .QN(n157) );
  NOR2X0 U608 ( .IN1(n155), .IN2(aligned), .QN(n156) );
  NAND2X1 U609 ( .IN1(n144), .IN2(n147), .QN(n146) );
  NAND2X1 U610 ( .IN1(n141), .IN2(aligned), .QN(n143) );
  INVX0 U611 ( .INP(n144), .ZN(n547) );
  OA21X1 U612 ( .IN1(n496), .IN2(n159), .IN3(n144), .Q(n158) );
  AND2X1 U613 ( .IN1(current_word[1]), .IN2(N899), .Q(n471) );
  NOR2X0 U614 ( .IN1(n23), .IN2(n550), .QN(N899) );
  AND2X1 U615 ( .IN1(current_word[0]), .IN2(N899), .Q(n472) );
  NBUFFX2 U616 ( .INP(reset_n), .Z(n532) );
  NBUFFX2 U617 ( .INP(reset_n), .Z(n533) );
  INVX0 U618 ( .INP(n477), .ZN(n487) );
  INVX0 U619 ( .INP(n477), .ZN(n488) );
  INVX0 U620 ( .INP(n477), .ZN(n489) );
  INVX0 U621 ( .INP(n477), .ZN(n490) );
  INVX0 U622 ( .INP(n510), .ZN(n497) );
  INVX0 U623 ( .INP(n503), .ZN(n498) );
  INVX0 U624 ( .INP(n504), .ZN(n499) );
  NAND2X0 U625 ( .IN1(N899), .IN2(current_word[3]), .QN(
        \mult_add_84_aco/PROD_not[3] ) );
  XOR2X1 U626 ( .IN1(\add_85/carry [4]), .IN2(bit_count[4]), .Q(N451) );
  XOR2X1 U627 ( .IN1(n469), .IN2(n552), .Q(N574) );
  XOR2X1 U628 ( .IN1(n471), .IN2(n472), .Q(N573) );
  AND2X1 U629 ( .IN1(N904), .IN2(fix_right), .Q(N444) );
  XOR2X1 U630 ( .IN1(fix_right), .IN2(N904), .Q(N443) );
  AND2X1 U631 ( .IN1(n551), .IN2(fix_left), .Q(N904) );
endmodule

