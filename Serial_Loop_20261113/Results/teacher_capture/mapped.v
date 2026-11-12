/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : O-2018.06-SP1
// Date      : Fri Nov 13 00:28:12 2026
/////////////////////////////////////////////////////////////


module bdi_capture_channel_6sat_DW01_inc_0 ( A, SUM );
  input [10:0] A;
  output [10:0] SUM;

  wire   [10:2] carry;

  ADDHX1 U1_1_9 ( .A(A[9]), .B(carry[9]), .CO(carry[10]), .S(SUM[9]) );
  ADDHX1 U1_1_4 ( .A(A[4]), .B(carry[4]), .CO(carry[5]), .S(SUM[4]) );
  ADDHX1 U1_1_3 ( .A(A[3]), .B(carry[3]), .CO(carry[4]), .S(SUM[3]) );
  ADDHX1 U1_1_5 ( .A(A[5]), .B(carry[5]), .CO(carry[6]), .S(SUM[5]) );
  ADDHX1 U1_1_2 ( .A(A[2]), .B(carry[2]), .CO(carry[3]), .S(SUM[2]) );
  ADDHX1 U1_1_8 ( .A(A[8]), .B(carry[8]), .CO(carry[9]), .S(SUM[8]) );
  ADDHX1 U1_1_7 ( .A(A[7]), .B(carry[7]), .CO(carry[8]), .S(SUM[7]) );
  ADDHX1 U1_1_6 ( .A(A[6]), .B(carry[6]), .CO(carry[7]), .S(SUM[6]) );
  ADDHX1 U1_1_1 ( .A(A[1]), .B(A[0]), .CO(carry[2]), .S(SUM[1]) );
  INVX2 U1 ( .A(A[0]), .Y(SUM[0]) );
  XOR2X1 U2 ( .A(carry[10]), .B(A[10]), .Y(SUM[10]) );
endmodule


module bdi_capture_channel_6sat_DW01_inc_1 ( A, SUM );
  input [10:0] A;
  output [10:0] SUM;

  wire   [10:2] carry;

  ADDHX1 U1_1_9 ( .A(A[9]), .B(carry[9]), .CO(carry[10]), .S(SUM[9]) );
  ADDHX1 U1_1_8 ( .A(A[8]), .B(carry[8]), .CO(carry[9]), .S(SUM[8]) );
  ADDHX1 U1_1_7 ( .A(A[7]), .B(carry[7]), .CO(carry[8]), .S(SUM[7]) );
  ADDHX1 U1_1_6 ( .A(A[6]), .B(carry[6]), .CO(carry[7]), .S(SUM[6]) );
  ADDHX1 U1_1_5 ( .A(A[5]), .B(carry[5]), .CO(carry[6]), .S(SUM[5]) );
  ADDHX1 U1_1_4 ( .A(A[4]), .B(carry[4]), .CO(carry[5]), .S(SUM[4]) );
  ADDHX1 U1_1_3 ( .A(A[3]), .B(carry[3]), .CO(carry[4]), .S(SUM[3]) );
  ADDHX1 U1_1_2 ( .A(A[2]), .B(carry[2]), .CO(carry[3]), .S(SUM[2]) );
  ADDHX1 U1_1_1 ( .A(A[1]), .B(A[0]), .CO(carry[2]), .S(SUM[1]) );
  INVX2 U1 ( .A(A[0]), .Y(SUM[0]) );
  XOR2X1 U2 ( .A(carry[10]), .B(A[10]), .Y(SUM[10]) );
endmodule


module bdi_capture_channel_6sat_DW01_inc_2 ( A, SUM );
  input [14:0] A;
  output [14:0] SUM;

  wire   [14:2] carry;

  ADDHX1 U1_1_13 ( .A(A[13]), .B(carry[13]), .CO(carry[14]), .S(SUM[13]) );
  ADDHX1 U1_1_4 ( .A(A[4]), .B(carry[4]), .CO(carry[5]), .S(SUM[4]) );
  ADDHX1 U1_1_12 ( .A(A[12]), .B(carry[12]), .CO(carry[13]), .S(SUM[12]) );
  ADDHX1 U1_1_11 ( .A(A[11]), .B(carry[11]), .CO(carry[12]), .S(SUM[11]) );
  ADDHX1 U1_1_10 ( .A(A[10]), .B(carry[10]), .CO(carry[11]), .S(SUM[10]) );
  ADDHX1 U1_1_9 ( .A(A[9]), .B(carry[9]), .CO(carry[10]), .S(SUM[9]) );
  ADDHX1 U1_1_8 ( .A(A[8]), .B(carry[8]), .CO(carry[9]), .S(SUM[8]) );
  ADDHX1 U1_1_7 ( .A(A[7]), .B(carry[7]), .CO(carry[8]), .S(SUM[7]) );
  ADDHX1 U1_1_6 ( .A(A[6]), .B(carry[6]), .CO(carry[7]), .S(SUM[6]) );
  ADDHX1 U1_1_5 ( .A(A[5]), .B(carry[5]), .CO(carry[6]), .S(SUM[5]) );
  ADDHX1 U1_1_3 ( .A(A[3]), .B(carry[3]), .CO(carry[4]), .S(SUM[3]) );
  ADDHX1 U1_1_2 ( .A(A[2]), .B(carry[2]), .CO(carry[3]), .S(SUM[2]) );
  ADDHX1 U1_1_1 ( .A(A[1]), .B(A[0]), .CO(carry[2]), .S(SUM[1]) );
  INVX2 U1 ( .A(A[0]), .Y(SUM[0]) );
  XOR2X1 U2 ( .A(carry[14]), .B(A[14]), .Y(SUM[14]) );
endmodule


module bdi_capture_channel_6sat_DW01_inc_3 ( A, SUM );
  input [15:0] A;
  output [15:0] SUM;

  wire   [15:2] carry;

  ADDHX1 U1_1_14 ( .A(A[14]), .B(carry[14]), .CO(carry[15]), .S(SUM[14]) );
  ADDHX1 U1_1_13 ( .A(A[13]), .B(carry[13]), .CO(carry[14]), .S(SUM[13]) );
  ADDHX1 U1_1_12 ( .A(A[12]), .B(carry[12]), .CO(carry[13]), .S(SUM[12]) );
  ADDHX1 U1_1_11 ( .A(A[11]), .B(carry[11]), .CO(carry[12]), .S(SUM[11]) );
  ADDHX1 U1_1_10 ( .A(A[10]), .B(carry[10]), .CO(carry[11]), .S(SUM[10]) );
  ADDHX1 U1_1_9 ( .A(A[9]), .B(carry[9]), .CO(carry[10]), .S(SUM[9]) );
  ADDHX1 U1_1_8 ( .A(A[8]), .B(carry[8]), .CO(carry[9]), .S(SUM[8]) );
  ADDHX1 U1_1_7 ( .A(A[7]), .B(carry[7]), .CO(carry[8]), .S(SUM[7]) );
  ADDHX1 U1_1_6 ( .A(A[6]), .B(carry[6]), .CO(carry[7]), .S(SUM[6]) );
  ADDHX1 U1_1_5 ( .A(A[5]), .B(carry[5]), .CO(carry[6]), .S(SUM[5]) );
  ADDHX1 U1_1_4 ( .A(A[4]), .B(carry[4]), .CO(carry[5]), .S(SUM[4]) );
  ADDHX1 U1_1_3 ( .A(A[3]), .B(carry[3]), .CO(carry[4]), .S(SUM[3]) );
  ADDHX1 U1_1_2 ( .A(A[2]), .B(carry[2]), .CO(carry[3]), .S(SUM[2]) );
  ADDHX1 U1_1_1 ( .A(A[1]), .B(A[0]), .CO(carry[2]), .S(SUM[1]) );
  XOR2X1 U1 ( .A(carry[15]), .B(A[15]), .Y(SUM[15]) );
endmodule


module bdi_capture_channel_6sat_DW01_inc_4 ( A, SUM );
  input [31:0] A;
  output [31:0] SUM;

  wire   [31:2] carry;

  ADDHX1 U1_1_30 ( .A(A[30]), .B(carry[30]), .CO(carry[31]), .S(SUM[30]) );
  ADDHX1 U1_1_29 ( .A(A[29]), .B(carry[29]), .CO(carry[30]), .S(SUM[29]) );
  ADDHX1 U1_1_28 ( .A(A[28]), .B(carry[28]), .CO(carry[29]), .S(SUM[28]) );
  ADDHX1 U1_1_27 ( .A(A[27]), .B(carry[27]), .CO(carry[28]), .S(SUM[27]) );
  ADDHX1 U1_1_26 ( .A(A[26]), .B(carry[26]), .CO(carry[27]), .S(SUM[26]) );
  ADDHX1 U1_1_25 ( .A(A[25]), .B(carry[25]), .CO(carry[26]), .S(SUM[25]) );
  ADDHX1 U1_1_24 ( .A(A[24]), .B(carry[24]), .CO(carry[25]), .S(SUM[24]) );
  ADDHX1 U1_1_23 ( .A(A[23]), .B(carry[23]), .CO(carry[24]), .S(SUM[23]) );
  ADDHX1 U1_1_22 ( .A(A[22]), .B(carry[22]), .CO(carry[23]), .S(SUM[22]) );
  ADDHX1 U1_1_21 ( .A(A[21]), .B(carry[21]), .CO(carry[22]), .S(SUM[21]) );
  ADDHX1 U1_1_20 ( .A(A[20]), .B(carry[20]), .CO(carry[21]), .S(SUM[20]) );
  ADDHX1 U1_1_19 ( .A(A[19]), .B(carry[19]), .CO(carry[20]), .S(SUM[19]) );
  ADDHX1 U1_1_18 ( .A(A[18]), .B(carry[18]), .CO(carry[19]), .S(SUM[18]) );
  ADDHX1 U1_1_17 ( .A(A[17]), .B(carry[17]), .CO(carry[18]), .S(SUM[17]) );
  ADDHX1 U1_1_16 ( .A(A[16]), .B(carry[16]), .CO(carry[17]), .S(SUM[16]) );
  ADDHX1 U1_1_15 ( .A(A[15]), .B(carry[15]), .CO(carry[16]), .S(SUM[15]) );
  ADDHX1 U1_1_14 ( .A(A[14]), .B(carry[14]), .CO(carry[15]), .S(SUM[14]) );
  ADDHX1 U1_1_13 ( .A(A[13]), .B(carry[13]), .CO(carry[14]), .S(SUM[13]) );
  ADDHX1 U1_1_12 ( .A(A[12]), .B(carry[12]), .CO(carry[13]), .S(SUM[12]) );
  ADDHX1 U1_1_11 ( .A(A[11]), .B(carry[11]), .CO(carry[12]), .S(SUM[11]) );
  ADDHX1 U1_1_10 ( .A(A[10]), .B(carry[10]), .CO(carry[11]), .S(SUM[10]) );
  ADDHX1 U1_1_9 ( .A(A[9]), .B(carry[9]), .CO(carry[10]), .S(SUM[9]) );
  ADDHX1 U1_1_8 ( .A(A[8]), .B(carry[8]), .CO(carry[9]), .S(SUM[8]) );
  ADDHX1 U1_1_7 ( .A(A[7]), .B(carry[7]), .CO(carry[8]), .S(SUM[7]) );
  ADDHX1 U1_1_6 ( .A(A[6]), .B(carry[6]), .CO(carry[7]), .S(SUM[6]) );
  ADDHX1 U1_1_5 ( .A(A[5]), .B(carry[5]), .CO(carry[6]), .S(SUM[5]) );
  ADDHX1 U1_1_4 ( .A(A[4]), .B(carry[4]), .CO(carry[5]), .S(SUM[4]) );
  ADDHX1 U1_1_3 ( .A(A[3]), .B(carry[3]), .CO(carry[4]), .S(SUM[3]) );
  ADDHX1 U1_1_2 ( .A(A[2]), .B(carry[2]), .CO(carry[3]), .S(SUM[2]) );
  ADDHX1 U1_1_1 ( .A(A[1]), .B(A[0]), .CO(carry[2]), .S(SUM[1]) );
  XOR2X1 U1 ( .A(carry[31]), .B(A[31]), .Y(SUM[31]) );
endmodule


module bdi_capture_channel_6sat_DW01_add_0 ( A, B, CI, SUM, CO );
  input [24:0] A;
  input [24:0] B;
  output [24:0] SUM;
  input CI;
  output CO;
  wire   n1;
  wire   [24:1] carry;

  ADDFX1 U1_1 ( .A(A[1]), .B(B[1]), .CI(n1), .CO(carry[2]), .S(SUM[1]) );
  ADDFX1 U1_22 ( .A(A[22]), .B(B[22]), .CI(carry[22]), .CO(carry[23]), .S(
        SUM[22]) );
  ADDFX1 U1_21 ( .A(A[21]), .B(B[21]), .CI(carry[21]), .CO(carry[22]), .S(
        SUM[21]) );
  ADDFX1 U1_20 ( .A(A[20]), .B(B[20]), .CI(carry[20]), .CO(carry[21]), .S(
        SUM[20]) );
  ADDFX1 U1_19 ( .A(A[19]), .B(B[19]), .CI(carry[19]), .CO(carry[20]), .S(
        SUM[19]) );
  ADDFX1 U1_18 ( .A(A[18]), .B(B[18]), .CI(carry[18]), .CO(carry[19]), .S(
        SUM[18]) );
  ADDFX1 U1_17 ( .A(A[17]), .B(B[17]), .CI(carry[17]), .CO(carry[18]), .S(
        SUM[17]) );
  ADDFX1 U1_16 ( .A(A[16]), .B(B[16]), .CI(carry[16]), .CO(carry[17]), .S(
        SUM[16]) );
  ADDFX1 U1_15 ( .A(A[15]), .B(B[15]), .CI(carry[15]), .CO(carry[16]), .S(
        SUM[15]) );
  ADDFX1 U1_14 ( .A(A[14]), .B(B[14]), .CI(carry[14]), .CO(carry[15]), .S(
        SUM[14]) );
  ADDFX1 U1_13 ( .A(A[13]), .B(B[13]), .CI(carry[13]), .CO(carry[14]), .S(
        SUM[13]) );
  ADDFX1 U1_12 ( .A(A[12]), .B(B[12]), .CI(carry[12]), .CO(carry[13]), .S(
        SUM[12]) );
  ADDFX1 U1_11 ( .A(A[11]), .B(B[11]), .CI(carry[11]), .CO(carry[12]), .S(
        SUM[11]) );
  ADDFX1 U1_10 ( .A(A[10]), .B(B[10]), .CI(carry[10]), .CO(carry[11]), .S(
        SUM[10]) );
  ADDFX1 U1_9 ( .A(A[9]), .B(B[9]), .CI(carry[9]), .CO(carry[10]), .S(SUM[9])
         );
  ADDFX1 U1_8 ( .A(A[8]), .B(B[8]), .CI(carry[8]), .CO(carry[9]), .S(SUM[8])
         );
  ADDFX1 U1_7 ( .A(A[7]), .B(B[7]), .CI(carry[7]), .CO(carry[8]), .S(SUM[7])
         );
  ADDFX1 U1_6 ( .A(A[6]), .B(B[6]), .CI(carry[6]), .CO(carry[7]), .S(SUM[6])
         );
  ADDFX1 U1_5 ( .A(A[5]), .B(B[5]), .CI(carry[5]), .CO(carry[6]), .S(SUM[5])
         );
  ADDFX1 U1_4 ( .A(A[4]), .B(B[4]), .CI(carry[4]), .CO(carry[5]), .S(SUM[4])
         );
  ADDFX1 U1_3 ( .A(A[3]), .B(B[3]), .CI(carry[3]), .CO(carry[4]), .S(SUM[3])
         );
  ADDFX1 U1_2 ( .A(A[2]), .B(B[2]), .CI(carry[2]), .CO(carry[3]), .S(SUM[2])
         );
  ADDFX1 U1_23 ( .A(A[23]), .B(B[23]), .CI(carry[23]), .CO(SUM[24]), .S(
        SUM[23]) );
  AND2X2 U1 ( .A(B[0]), .B(A[0]), .Y(n1) );
  XOR2X1 U2 ( .A(B[0]), .B(A[0]), .Y(SUM[0]) );
endmodule


module bdi_capture_channel_6sat_DW01_sub_0 ( A, B, CI, DIFF, CO );
  input [23:0] A;
  input [23:0] B;
  output [23:0] DIFF;
  input CI;
  output CO;
  wire   \B[0] , n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14,
         n15, n16, n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28,
         n29, n30, n31, n32, n33, n34, n35, n36, n37, n38, n39, n40, n41, n42,
         n43, n44, n45, n46, n47, n48, n49, n50, n51, n52, n53, n54, n55, n56,
         n57, n58, n59, n60, n61, n62, n63, n64, n65, n66, n67;
  assign DIFF[0] = \B[0] ;
  assign \B[0]  = B[0];

  INVX2 U1 ( .A(n1), .Y(n43) );
  INVX2 U2 ( .A(n2), .Y(n42) );
  INVX2 U3 ( .A(n3), .Y(n41) );
  INVX2 U4 ( .A(n4), .Y(n40) );
  INVX2 U5 ( .A(n5), .Y(n39) );
  INVX2 U6 ( .A(n6), .Y(n38) );
  INVX2 U7 ( .A(n7), .Y(n37) );
  INVX2 U8 ( .A(n8), .Y(n36) );
  INVX2 U9 ( .A(n9), .Y(n35) );
  INVX2 U10 ( .A(n10), .Y(n34) );
  INVX2 U11 ( .A(n11), .Y(n33) );
  INVX2 U12 ( .A(n12), .Y(n32) );
  INVX2 U13 ( .A(n13), .Y(n31) );
  INVX2 U14 ( .A(n14), .Y(n30) );
  INVX2 U15 ( .A(n15), .Y(n29) );
  INVX2 U16 ( .A(n16), .Y(n28) );
  INVX2 U17 ( .A(n17), .Y(n27) );
  INVX2 U18 ( .A(n18), .Y(n26) );
  INVX2 U19 ( .A(n19), .Y(n25) );
  INVX2 U20 ( .A(n20), .Y(n24) );
  INVX2 U21 ( .A(n21), .Y(n22) );
  XOR2X1 U22 ( .A(n66), .B(n67), .Y(DIFF[1]) );
  AND2X2 U23 ( .A(n66), .B(n67), .Y(n1) );
  AND2X2 U24 ( .A(n65), .B(n1), .Y(n2) );
  AND2X2 U25 ( .A(n64), .B(n2), .Y(n3) );
  AND2X2 U26 ( .A(n63), .B(n3), .Y(n4) );
  AND2X2 U27 ( .A(n62), .B(n4), .Y(n5) );
  AND2X2 U28 ( .A(n61), .B(n5), .Y(n6) );
  AND2X2 U29 ( .A(n60), .B(n6), .Y(n7) );
  AND2X2 U30 ( .A(n59), .B(n7), .Y(n8) );
  AND2X2 U31 ( .A(n58), .B(n8), .Y(n9) );
  AND2X2 U32 ( .A(n57), .B(n9), .Y(n10) );
  AND2X2 U33 ( .A(n56), .B(n10), .Y(n11) );
  AND2X2 U34 ( .A(n55), .B(n11), .Y(n12) );
  AND2X2 U35 ( .A(n54), .B(n12), .Y(n13) );
  AND2X2 U36 ( .A(n53), .B(n13), .Y(n14) );
  AND2X2 U37 ( .A(n52), .B(n14), .Y(n15) );
  AND2X2 U38 ( .A(n51), .B(n15), .Y(n16) );
  AND2X2 U39 ( .A(n50), .B(n16), .Y(n17) );
  AND2X2 U40 ( .A(n49), .B(n17), .Y(n18) );
  AND2X2 U41 ( .A(n48), .B(n18), .Y(n19) );
  AND2X2 U42 ( .A(n47), .B(n19), .Y(n20) );
  AND2X2 U43 ( .A(n46), .B(n20), .Y(n21) );
  NAND2X2 U44 ( .A(n45), .B(n21), .Y(n23) );
  XNOR2X1 U45 ( .A(n44), .B(n23), .Y(DIFF[23]) );
  XNOR2X1 U46 ( .A(n65), .B(n43), .Y(DIFF[2]) );
  XNOR2X1 U47 ( .A(n64), .B(n42), .Y(DIFF[3]) );
  XNOR2X1 U48 ( .A(n63), .B(n41), .Y(DIFF[4]) );
  XNOR2X1 U49 ( .A(n62), .B(n40), .Y(DIFF[5]) );
  XNOR2X1 U50 ( .A(n61), .B(n39), .Y(DIFF[6]) );
  XNOR2X1 U51 ( .A(n60), .B(n38), .Y(DIFF[7]) );
  XNOR2X1 U52 ( .A(n59), .B(n37), .Y(DIFF[8]) );
  XNOR2X1 U53 ( .A(n58), .B(n36), .Y(DIFF[9]) );
  XNOR2X1 U54 ( .A(n57), .B(n35), .Y(DIFF[10]) );
  XNOR2X1 U55 ( .A(n56), .B(n34), .Y(DIFF[11]) );
  XNOR2X1 U56 ( .A(n55), .B(n33), .Y(DIFF[12]) );
  XNOR2X1 U57 ( .A(n54), .B(n32), .Y(DIFF[13]) );
  XNOR2X1 U58 ( .A(n53), .B(n31), .Y(DIFF[14]) );
  XNOR2X1 U59 ( .A(n52), .B(n30), .Y(DIFF[15]) );
  XNOR2X1 U60 ( .A(n51), .B(n29), .Y(DIFF[16]) );
  XNOR2X1 U61 ( .A(n50), .B(n28), .Y(DIFF[17]) );
  XNOR2X1 U62 ( .A(n49), .B(n27), .Y(DIFF[18]) );
  XNOR2X1 U63 ( .A(n48), .B(n26), .Y(DIFF[19]) );
  XNOR2X1 U64 ( .A(n47), .B(n25), .Y(DIFF[20]) );
  XNOR2X1 U65 ( .A(n46), .B(n24), .Y(DIFF[21]) );
  XNOR2X1 U66 ( .A(n45), .B(n22), .Y(DIFF[22]) );
  INVX2 U67 ( .A(\B[0] ), .Y(n67) );
  INVX2 U68 ( .A(B[1]), .Y(n66) );
  INVX2 U69 ( .A(B[2]), .Y(n65) );
  INVX2 U70 ( .A(B[3]), .Y(n64) );
  INVX2 U71 ( .A(B[4]), .Y(n63) );
  INVX2 U72 ( .A(B[5]), .Y(n62) );
  INVX2 U73 ( .A(B[6]), .Y(n61) );
  INVX2 U74 ( .A(B[7]), .Y(n60) );
  INVX2 U75 ( .A(B[8]), .Y(n59) );
  INVX2 U76 ( .A(B[9]), .Y(n58) );
  INVX2 U77 ( .A(B[10]), .Y(n57) );
  INVX2 U78 ( .A(B[11]), .Y(n56) );
  INVX2 U79 ( .A(B[12]), .Y(n55) );
  INVX2 U80 ( .A(B[13]), .Y(n54) );
  INVX2 U81 ( .A(B[14]), .Y(n53) );
  INVX2 U82 ( .A(B[15]), .Y(n52) );
  INVX2 U83 ( .A(B[16]), .Y(n51) );
  INVX2 U84 ( .A(B[17]), .Y(n50) );
  INVX2 U85 ( .A(B[18]), .Y(n49) );
  INVX2 U86 ( .A(B[19]), .Y(n48) );
  INVX2 U87 ( .A(B[20]), .Y(n47) );
  INVX2 U88 ( .A(B[21]), .Y(n46) );
  INVX2 U89 ( .A(B[22]), .Y(n45) );
  INVX2 U90 ( .A(B[23]), .Y(n44) );
endmodule


module bdi_capture_channel_6sat_DW01_add_1 ( A, B, CI, SUM, CO );
  input [23:0] A;
  input [23:0] B;
  output [23:0] SUM;
  input CI;
  output CO;
  wire   n1;
  wire   [23:1] carry;

  ADDFX1 U1_1 ( .A(A[1]), .B(B[1]), .CI(n1), .CO(carry[2]), .S(SUM[1]) );
  ADDFX1 U1_22 ( .A(A[22]), .B(B[22]), .CI(carry[22]), .CO(carry[23]), .S(
        SUM[22]) );
  ADDFX1 U1_21 ( .A(A[21]), .B(B[21]), .CI(carry[21]), .CO(carry[22]), .S(
        SUM[21]) );
  ADDFX1 U1_20 ( .A(A[20]), .B(B[20]), .CI(carry[20]), .CO(carry[21]), .S(
        SUM[20]) );
  ADDFX1 U1_19 ( .A(A[19]), .B(B[19]), .CI(carry[19]), .CO(carry[20]), .S(
        SUM[19]) );
  ADDFX1 U1_18 ( .A(A[18]), .B(B[18]), .CI(carry[18]), .CO(carry[19]), .S(
        SUM[18]) );
  ADDFX1 U1_17 ( .A(A[17]), .B(B[17]), .CI(carry[17]), .CO(carry[18]), .S(
        SUM[17]) );
  ADDFX1 U1_16 ( .A(A[16]), .B(B[16]), .CI(carry[16]), .CO(carry[17]), .S(
        SUM[16]) );
  ADDFX1 U1_15 ( .A(A[15]), .B(B[15]), .CI(carry[15]), .CO(carry[16]), .S(
        SUM[15]) );
  ADDFX1 U1_14 ( .A(A[14]), .B(B[14]), .CI(carry[14]), .CO(carry[15]), .S(
        SUM[14]) );
  ADDFX1 U1_13 ( .A(A[13]), .B(B[13]), .CI(carry[13]), .CO(carry[14]), .S(
        SUM[13]) );
  ADDFX1 U1_12 ( .A(A[12]), .B(B[12]), .CI(carry[12]), .CO(carry[13]), .S(
        SUM[12]) );
  ADDFX1 U1_11 ( .A(A[11]), .B(B[11]), .CI(carry[11]), .CO(carry[12]), .S(
        SUM[11]) );
  ADDFX1 U1_10 ( .A(A[10]), .B(B[10]), .CI(carry[10]), .CO(carry[11]), .S(
        SUM[10]) );
  ADDFX1 U1_9 ( .A(A[9]), .B(B[9]), .CI(carry[9]), .CO(carry[10]), .S(SUM[9])
         );
  ADDFX1 U1_8 ( .A(A[8]), .B(B[8]), .CI(carry[8]), .CO(carry[9]), .S(SUM[8])
         );
  ADDFX1 U1_7 ( .A(A[7]), .B(B[7]), .CI(carry[7]), .CO(carry[8]), .S(SUM[7])
         );
  ADDFX1 U1_6 ( .A(A[6]), .B(B[6]), .CI(carry[6]), .CO(carry[7]), .S(SUM[6])
         );
  ADDFX1 U1_5 ( .A(A[5]), .B(B[5]), .CI(carry[5]), .CO(carry[6]), .S(SUM[5])
         );
  ADDFX1 U1_4 ( .A(A[4]), .B(B[4]), .CI(carry[4]), .CO(carry[5]), .S(SUM[4])
         );
  ADDFX1 U1_3 ( .A(A[3]), .B(B[3]), .CI(carry[3]), .CO(carry[4]), .S(SUM[3])
         );
  ADDFX1 U1_2 ( .A(A[2]), .B(B[2]), .CI(carry[2]), .CO(carry[3]), .S(SUM[2])
         );
  XOR3XL U1_23 ( .A(A[23]), .B(B[23]), .C(carry[23]), .Y(SUM[23]) );
  AND2X2 U1 ( .A(B[0]), .B(A[0]), .Y(n1) );
  XOR2X1 U2 ( .A(B[0]), .B(A[0]), .Y(SUM[0]) );
endmodule


module bdi_capture_channel_6sat_DW01_sub_2 ( A, B, CI, DIFF, CO );
  input [23:0] A;
  input [23:0] B;
  output [23:0] DIFF;
  input CI;
  output CO;
  wire   \B[0] , n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14,
         n15, n16, n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28,
         n29, n30, n31, n32, n33, n34, n35, n36, n37, n38, n39, n40, n41, n42,
         n43, n44, n45;
  assign DIFF[0] = \B[0] ;
  assign \B[0]  = B[0];

  AND2X2 U1 ( .A(n23), .B(n22), .Y(n1) );
  XOR2X1 U2 ( .A(n44), .B(n45), .Y(DIFF[1]) );
  XOR2X1 U3 ( .A(n43), .B(n2), .Y(DIFF[2]) );
  XOR2X1 U4 ( .A(n42), .B(n3), .Y(DIFF[3]) );
  XOR2X1 U5 ( .A(n41), .B(n4), .Y(DIFF[4]) );
  XOR2X1 U6 ( .A(n40), .B(n5), .Y(DIFF[5]) );
  XOR2X1 U7 ( .A(n39), .B(n6), .Y(DIFF[6]) );
  XOR2X1 U8 ( .A(n38), .B(n7), .Y(DIFF[7]) );
  XOR2X1 U9 ( .A(n37), .B(n8), .Y(DIFF[8]) );
  XOR2X1 U10 ( .A(n36), .B(n9), .Y(DIFF[9]) );
  XOR2X1 U11 ( .A(n35), .B(n10), .Y(DIFF[10]) );
  XOR2X1 U12 ( .A(n34), .B(n11), .Y(DIFF[11]) );
  XOR2X1 U13 ( .A(n33), .B(n12), .Y(DIFF[12]) );
  XOR2X1 U14 ( .A(n32), .B(n13), .Y(DIFF[13]) );
  XOR2X1 U15 ( .A(n31), .B(n14), .Y(DIFF[14]) );
  XOR2X1 U16 ( .A(n30), .B(n15), .Y(DIFF[15]) );
  XOR2X1 U17 ( .A(n29), .B(n16), .Y(DIFF[16]) );
  XOR2X1 U18 ( .A(n28), .B(n17), .Y(DIFF[17]) );
  XOR2X1 U19 ( .A(n27), .B(n18), .Y(DIFF[18]) );
  XOR2X1 U20 ( .A(n26), .B(n19), .Y(DIFF[19]) );
  XOR2X1 U21 ( .A(n25), .B(n20), .Y(DIFF[20]) );
  XOR2X1 U22 ( .A(n24), .B(n21), .Y(DIFF[21]) );
  XOR2X1 U23 ( .A(n23), .B(n22), .Y(DIFF[22]) );
  AND2X2 U24 ( .A(n44), .B(n45), .Y(n2) );
  AND2X2 U25 ( .A(n43), .B(n2), .Y(n3) );
  AND2X2 U26 ( .A(n42), .B(n3), .Y(n4) );
  AND2X2 U27 ( .A(n41), .B(n4), .Y(n5) );
  AND2X2 U28 ( .A(n40), .B(n5), .Y(n6) );
  AND2X2 U29 ( .A(n39), .B(n6), .Y(n7) );
  AND2X2 U30 ( .A(n38), .B(n7), .Y(n8) );
  AND2X2 U31 ( .A(n37), .B(n8), .Y(n9) );
  AND2X2 U32 ( .A(n36), .B(n9), .Y(n10) );
  AND2X2 U33 ( .A(n35), .B(n10), .Y(n11) );
  AND2X2 U34 ( .A(n34), .B(n11), .Y(n12) );
  AND2X2 U35 ( .A(n33), .B(n12), .Y(n13) );
  AND2X2 U36 ( .A(n32), .B(n13), .Y(n14) );
  AND2X2 U37 ( .A(n31), .B(n14), .Y(n15) );
  AND2X2 U38 ( .A(n30), .B(n15), .Y(n16) );
  AND2X2 U39 ( .A(n29), .B(n16), .Y(n17) );
  AND2X2 U40 ( .A(n28), .B(n17), .Y(n18) );
  AND2X2 U41 ( .A(n27), .B(n18), .Y(n19) );
  AND2X2 U42 ( .A(n26), .B(n19), .Y(n20) );
  AND2X2 U43 ( .A(n25), .B(n20), .Y(n21) );
  AND2X2 U44 ( .A(n24), .B(n21), .Y(n22) );
  XNOR2X1 U45 ( .A(B[23]), .B(n1), .Y(DIFF[23]) );
  INVX2 U46 ( .A(\B[0] ), .Y(n45) );
  INVX2 U47 ( .A(B[1]), .Y(n44) );
  INVX2 U48 ( .A(B[2]), .Y(n43) );
  INVX2 U49 ( .A(B[3]), .Y(n42) );
  INVX2 U50 ( .A(B[4]), .Y(n41) );
  INVX2 U51 ( .A(B[5]), .Y(n40) );
  INVX2 U52 ( .A(B[6]), .Y(n39) );
  INVX2 U53 ( .A(B[7]), .Y(n38) );
  INVX2 U54 ( .A(B[8]), .Y(n37) );
  INVX2 U55 ( .A(B[9]), .Y(n36) );
  INVX2 U56 ( .A(B[10]), .Y(n35) );
  INVX2 U57 ( .A(B[11]), .Y(n34) );
  INVX2 U58 ( .A(B[12]), .Y(n33) );
  INVX2 U59 ( .A(B[13]), .Y(n32) );
  INVX2 U60 ( .A(B[14]), .Y(n31) );
  INVX2 U61 ( .A(B[15]), .Y(n30) );
  INVX2 U62 ( .A(B[16]), .Y(n29) );
  INVX2 U63 ( .A(B[17]), .Y(n28) );
  INVX2 U64 ( .A(B[18]), .Y(n27) );
  INVX2 U65 ( .A(B[19]), .Y(n26) );
  INVX2 U66 ( .A(B[20]), .Y(n25) );
  INVX2 U67 ( .A(B[21]), .Y(n24) );
  INVX2 U68 ( .A(B[22]), .Y(n23) );
endmodule


module bdi_capture_channel_6sat_DW01_add_2 ( A, B, CI, SUM, CO );
  input [23:0] A;
  input [23:0] B;
  output [23:0] SUM;
  input CI;
  output CO;
  wire   n1;
  wire   [23:1] carry;

  ADDFX1 U1_1 ( .A(A[1]), .B(B[1]), .CI(n1), .CO(carry[2]), .S(SUM[1]) );
  ADDFX1 U1_22 ( .A(A[22]), .B(B[22]), .CI(carry[22]), .CO(carry[23]), .S(
        SUM[22]) );
  ADDFX1 U1_21 ( .A(A[21]), .B(B[21]), .CI(carry[21]), .CO(carry[22]), .S(
        SUM[21]) );
  ADDFX1 U1_20 ( .A(A[20]), .B(B[20]), .CI(carry[20]), .CO(carry[21]), .S(
        SUM[20]) );
  ADDFX1 U1_19 ( .A(A[19]), .B(B[19]), .CI(carry[19]), .CO(carry[20]), .S(
        SUM[19]) );
  ADDFX1 U1_18 ( .A(A[18]), .B(B[18]), .CI(carry[18]), .CO(carry[19]), .S(
        SUM[18]) );
  ADDFX1 U1_17 ( .A(A[17]), .B(B[17]), .CI(carry[17]), .CO(carry[18]), .S(
        SUM[17]) );
  ADDFX1 U1_16 ( .A(A[16]), .B(B[16]), .CI(carry[16]), .CO(carry[17]), .S(
        SUM[16]) );
  ADDFX1 U1_15 ( .A(A[15]), .B(B[15]), .CI(carry[15]), .CO(carry[16]), .S(
        SUM[15]) );
  ADDFX1 U1_14 ( .A(A[14]), .B(B[14]), .CI(carry[14]), .CO(carry[15]), .S(
        SUM[14]) );
  ADDFX1 U1_13 ( .A(A[13]), .B(B[13]), .CI(carry[13]), .CO(carry[14]), .S(
        SUM[13]) );
  ADDFX1 U1_12 ( .A(A[12]), .B(B[12]), .CI(carry[12]), .CO(carry[13]), .S(
        SUM[12]) );
  ADDFX1 U1_11 ( .A(A[11]), .B(B[11]), .CI(carry[11]), .CO(carry[12]), .S(
        SUM[11]) );
  ADDFX1 U1_10 ( .A(A[10]), .B(B[10]), .CI(carry[10]), .CO(carry[11]), .S(
        SUM[10]) );
  ADDFX1 U1_9 ( .A(A[9]), .B(B[9]), .CI(carry[9]), .CO(carry[10]), .S(SUM[9])
         );
  ADDFX1 U1_8 ( .A(A[8]), .B(B[8]), .CI(carry[8]), .CO(carry[9]), .S(SUM[8])
         );
  ADDFX1 U1_7 ( .A(A[7]), .B(B[7]), .CI(carry[7]), .CO(carry[8]), .S(SUM[7])
         );
  ADDFX1 U1_6 ( .A(A[6]), .B(B[6]), .CI(carry[6]), .CO(carry[7]), .S(SUM[6])
         );
  ADDFX1 U1_5 ( .A(A[5]), .B(B[5]), .CI(carry[5]), .CO(carry[6]), .S(SUM[5])
         );
  ADDFX1 U1_4 ( .A(A[4]), .B(B[4]), .CI(carry[4]), .CO(carry[5]), .S(SUM[4])
         );
  ADDFX1 U1_3 ( .A(A[3]), .B(B[3]), .CI(carry[3]), .CO(carry[4]), .S(SUM[3])
         );
  ADDFX1 U1_2 ( .A(A[2]), .B(B[2]), .CI(carry[2]), .CO(carry[3]), .S(SUM[2])
         );
  XOR3XL U1_23 ( .A(A[23]), .B(B[23]), .C(carry[23]), .Y(SUM[23]) );
  AND2X2 U1 ( .A(B[0]), .B(A[0]), .Y(n1) );
  XOR2X1 U2 ( .A(B[0]), .B(A[0]), .Y(SUM[0]) );
endmodule


module bdi_capture_channel_6sat_DW01_add_3 ( A, B, CI, SUM, CO );
  input [11:0] A;
  input [11:0] B;
  output [11:0] SUM;
  input CI;
  output CO;
  wire   n1, n2;
  wire   [11:1] carry;

  ADDFX1 U1_1 ( .A(A[1]), .B(B[1]), .CI(n1), .CO(carry[2]), .S(SUM[1]) );
  ADDFX1 U1_9 ( .A(A[9]), .B(B[9]), .CI(carry[9]), .CO(carry[10]), .S(SUM[9])
         );
  ADDFX1 U1_7 ( .A(A[7]), .B(B[7]), .CI(carry[7]), .CO(carry[8]), .S(SUM[7])
         );
  ADDFX1 U1_8 ( .A(A[8]), .B(B[8]), .CI(carry[8]), .CO(carry[9]), .S(SUM[8])
         );
  ADDFX1 U1_2 ( .A(A[2]), .B(B[2]), .CI(carry[2]), .CO(carry[3]), .S(SUM[2])
         );
  ADDFX1 U1_3 ( .A(A[3]), .B(B[3]), .CI(carry[3]), .CO(carry[4]), .S(SUM[3])
         );
  ADDFX1 U1_6 ( .A(A[6]), .B(B[6]), .CI(carry[6]), .CO(carry[7]), .S(SUM[6])
         );
  ADDFX1 U1_5 ( .A(A[5]), .B(B[5]), .CI(carry[5]), .CO(carry[6]), .S(SUM[5])
         );
  ADDFX1 U1_4 ( .A(A[4]), .B(B[4]), .CI(carry[4]), .CO(carry[5]), .S(SUM[4])
         );
  ADDFX1 U1_10 ( .A(A[10]), .B(B[10]), .CI(carry[10]), .CO(SUM[11]), .S(
        SUM[10]) );
  AND2X2 U1 ( .A(B[0]), .B(A[0]), .Y(n1) );
  XNOR2X1 U2 ( .A(B[0]), .B(n2), .Y(SUM[0]) );
  INVX2 U3 ( .A(A[0]), .Y(n2) );
endmodule


module bdi_capture_channel_6sat_DW_mult_tc_1 ( a, b, product );
  input [3:0] a;
  input [3:0] b;
  output [7:0] product;
  wire   n1, n2, n3, n4, n5, n6, n7, n9, n10, n11, n12, n13, n14, n15, n17,
         n18, n20, n21, n22, n69, n70, n71, n72, n73, n74, n75, n76, n77, n78,
         n79, n80, n81, n82, n83, n84, n85;

  ADDFX1 U2 ( .A(n15), .B(n7), .CI(n2), .CO(n1), .S(product[6]) );
  ADDFX1 U3 ( .A(n9), .B(n69), .CI(n3), .CO(n2), .S(product[5]) );
  ADDFX1 U4 ( .A(n10), .B(n11), .CI(n4), .CO(n3), .S(product[4]) );
  ADDFX1 U5 ( .A(n12), .B(n13), .CI(n5), .CO(n4), .S(product[3]) );
  ADDFX1 U6 ( .A(n21), .B(n18), .CI(n6), .CO(n5), .S(product[2]) );
  ADDHX1 U7 ( .A(n14), .B(n22), .CO(n6), .S(product[1]) );
  ADDHX1 U11 ( .A(n20), .B(n17), .CO(n11), .S(n12) );
  INVX2 U51 ( .A(n7), .Y(n69) );
  INVX2 U52 ( .A(n1), .Y(product[7]) );
  INVX2 U53 ( .A(a[0]), .Y(n71) );
  INVX2 U54 ( .A(a[3]), .Y(n70) );
  INVX2 U55 ( .A(b[0]), .Y(n72) );
  NOR2X1 U56 ( .A(n71), .B(n72), .Y(product[0]) );
  NAND2BX1 U57 ( .AN(n73), .B(n74), .Y(n9) );
  OAI2B2X1 U58 ( .A1N(n75), .A0(n76), .B0(n77), .B1(n78), .Y(n7) );
  OAI22X1 U59 ( .A0(b[0]), .A1(n79), .B0(n80), .B1(n71), .Y(n22) );
  OAI22X1 U60 ( .A0(n80), .A1(n79), .B0(n81), .B1(n71), .Y(n21) );
  XNOR2X1 U61 ( .A(b[1]), .B(a[1]), .Y(n80) );
  OAI22X1 U62 ( .A0(n81), .A1(n79), .B0(n82), .B1(n71), .Y(n20) );
  XNOR2X1 U63 ( .A(b[2]), .B(a[1]), .Y(n81) );
  NOR2X1 U64 ( .A(n76), .B(n72), .Y(n18) );
  OAI22X1 U65 ( .A0(n83), .A1(n78), .B0(n76), .B1(n84), .Y(n17) );
  XNOR2X1 U66 ( .A(a[3]), .B(b[0]), .Y(n83) );
  OAI2BB1X1 U67 ( .A0N(n78), .A1N(n76), .B0(n75), .Y(n15) );
  XNOR2X1 U68 ( .A(b[3]), .B(n70), .Y(n75) );
  OAI2BB1X1 U69 ( .A0N(n72), .A1N(a[1]), .B0(n79), .Y(n14) );
  OAI32XL U70 ( .A0(n70), .A1(b[0]), .A2(n76), .B0(n70), .B1(n78), .Y(n13) );
  XOR2X1 U71 ( .A(n73), .B(n74), .Y(n10) );
  AOI21X1 U72 ( .A0(n71), .A1(n79), .B0(n82), .Y(n74) );
  XNOR2X1 U73 ( .A(b[3]), .B(a[1]), .Y(n82) );
  CLKNAND2X2 U74 ( .A(a[1]), .B(n71), .Y(n79) );
  OAI22X1 U75 ( .A0(n84), .A1(n78), .B0(n76), .B1(n77), .Y(n73) );
  XNOR2X1 U76 ( .A(b[2]), .B(a[3]), .Y(n77) );
  CLKNAND2X2 U77 ( .A(n76), .B(n85), .Y(n78) );
  XNOR2X1 U78 ( .A(n70), .B(a[2]), .Y(n85) );
  XNOR2X1 U79 ( .A(a[2]), .B(a[1]), .Y(n76) );
  XNOR2X1 U80 ( .A(b[1]), .B(a[3]), .Y(n84) );
endmodule


module bdi_capture_channel_6sat_DW_mult_tc_0 ( a, b, product );
  input [3:0] a;
  input [3:0] b;
  output [7:0] product;
  wire   n1, n2, n3, n4, n5, n6, n7, n9, n10, n11, n12, n13, n14, n15, n17,
         n18, n20, n21, n22, n69, n70, n71, n72, n73, n74, n75, n76, n77, n78,
         n79, n80, n81, n82, n83, n84, n85;

  ADDFX1 U2 ( .A(n15), .B(n7), .CI(n2), .CO(n1), .S(product[6]) );
  ADDFX1 U3 ( .A(n9), .B(n69), .CI(n3), .CO(n2), .S(product[5]) );
  ADDFX1 U4 ( .A(n10), .B(n11), .CI(n4), .CO(n3), .S(product[4]) );
  ADDFX1 U5 ( .A(n12), .B(n13), .CI(n5), .CO(n4), .S(product[3]) );
  ADDFX1 U6 ( .A(n21), .B(n18), .CI(n6), .CO(n5), .S(product[2]) );
  ADDHX1 U7 ( .A(n14), .B(n22), .CO(n6), .S(product[1]) );
  ADDHX1 U11 ( .A(n20), .B(n17), .CO(n11), .S(n12) );
  INVX2 U51 ( .A(n7), .Y(n69) );
  INVX2 U52 ( .A(n1), .Y(product[7]) );
  INVX2 U53 ( .A(a[0]), .Y(n71) );
  INVX2 U54 ( .A(a[3]), .Y(n70) );
  INVX2 U55 ( .A(b[0]), .Y(n72) );
  NOR2X1 U56 ( .A(n71), .B(n72), .Y(product[0]) );
  NAND2BX1 U57 ( .AN(n73), .B(n74), .Y(n9) );
  OAI2B2X1 U58 ( .A1N(n75), .A0(n76), .B0(n77), .B1(n78), .Y(n7) );
  OAI22X1 U59 ( .A0(b[0]), .A1(n79), .B0(n80), .B1(n71), .Y(n22) );
  OAI22X1 U60 ( .A0(n80), .A1(n79), .B0(n81), .B1(n71), .Y(n21) );
  XNOR2X1 U61 ( .A(b[1]), .B(a[1]), .Y(n80) );
  OAI22X1 U62 ( .A0(n81), .A1(n79), .B0(n82), .B1(n71), .Y(n20) );
  XNOR2X1 U63 ( .A(b[2]), .B(a[1]), .Y(n81) );
  NOR2X1 U64 ( .A(n76), .B(n72), .Y(n18) );
  OAI22X1 U65 ( .A0(n83), .A1(n78), .B0(n76), .B1(n84), .Y(n17) );
  XNOR2X1 U66 ( .A(a[3]), .B(b[0]), .Y(n83) );
  OAI2BB1X1 U67 ( .A0N(n78), .A1N(n76), .B0(n75), .Y(n15) );
  XNOR2X1 U68 ( .A(b[3]), .B(n70), .Y(n75) );
  OAI2BB1X1 U69 ( .A0N(n72), .A1N(a[1]), .B0(n79), .Y(n14) );
  OAI32XL U70 ( .A0(n70), .A1(b[0]), .A2(n76), .B0(n70), .B1(n78), .Y(n13) );
  XOR2X1 U71 ( .A(n73), .B(n74), .Y(n10) );
  AOI21X1 U72 ( .A0(n71), .A1(n79), .B0(n82), .Y(n74) );
  XNOR2X1 U73 ( .A(b[3]), .B(a[1]), .Y(n82) );
  CLKNAND2X2 U74 ( .A(a[1]), .B(n71), .Y(n79) );
  OAI22X1 U75 ( .A0(n84), .A1(n78), .B0(n76), .B1(n77), .Y(n73) );
  XNOR2X1 U76 ( .A(b[2]), .B(a[3]), .Y(n77) );
  CLKNAND2X2 U77 ( .A(n76), .B(n85), .Y(n78) );
  XNOR2X1 U78 ( .A(n70), .B(a[2]), .Y(n85) );
  XNOR2X1 U79 ( .A(a[2]), .B(a[1]), .Y(n76) );
  XNOR2X1 U80 ( .A(b[1]), .B(a[3]), .Y(n84) );
endmodule


module bdi_capture_channel_6sat ( clk_16m368, rst_n, enable, if_valid, 
        if_sample, code, dump, capture, capture_event, capture_rise, 
        handoff_valid, handoff_code_phase, accepted_sample_count, 
        handoff_sample_epoch, handoff_ms_count, local_sin, local_cos, 
        search_phase, metric_debug );
  input [3:0] if_sample;
  output [10:0] handoff_code_phase;
  output [31:0] accepted_sample_count;
  output [31:0] handoff_sample_epoch;
  output [15:0] handoff_ms_count;
  output [3:0] local_sin;
  output [3:0] local_cos;
  output [10:0] search_phase;
  output [23:0] metric_debug;
  input clk_16m368, rst_n, enable, if_valid;
  output code, dump, capture, capture_event, capture_rise, handoff_valid;
  wire   N17, N18, N19, N20, N21, N22, N23, N24, N25, N26, N27, n1001, N29,
         \carrier_phase[1] , N52, N53, N54, N55, N56, N57, N58, N60, N61, N62,
         N63, N64, N65, N66, N68, N69, N70, N71, N72, N73, N74, N75, N76, N77,
         N78, N79, N80, N81, N82, N83, N85, N86, N87, N88, N89, N90, N91, N92,
         N93, N94, N95, N96, N97, N98, N99, N100, N101, N102, N103, N104, N105,
         N106, N107, N108, N110, N111, N112, N113, N114, N115, N116, N117,
         N118, N119, N120, N121, N122, N123, N124, N125, N126, N127, N128,
         N129, N130, N131, N132, N133, N139, N140, N141, N142, N143, N144,
         N145, N146, N147, N148, N149, N150, N151, N152, N153, N154, N155,
         N156, N157, N158, N159, N160, N161, N162, N163, N164, N165, N166,
         N167, N168, N169, N174, N175, N176, N177, N178, N179, N180, N181,
         N182, N183, N184, N185, N186, N187, N188, N193, N194, N195, N196,
         N197, N198, N199, N200, N201, N202, N203, N210, N211, N212, N213,
         N214, N215, N216, N217, N218, N219, N220, N221, N222, N223, N224,
         N279, N280, N281, N282, N283, N284, N285, N286, N287, N288, N289,
         N394, n36, n69, n116, n117, n118, n120, n122, n166, n167, n168, n169,
         n170, n171, n172, n179, n181, n191, n192, n193, n194, n195, n198,
         n199, n200, n201, n202, n203, n204, n205, n206, n207, n208, n209,
         n210, n211, n212, n213, n214, n215, n216, n217, n218, n219, n220,
         n221, n222, n223, n224, n225, n226, n227, n228, n229, n230, n231,
         n232, n233, n234, n235, n236, n237, n238, n239, n240, n241, n242,
         n243, n244, n245, n246, n247, n248, n249, n250, n251, n252, n253,
         n254, n255, n256, n257, n258, n259, n260, n261, n262, n263, n264,
         n265, n266, n267, n268, n269, n270, n271, n272, n273, n274, n275,
         n276, n277, n278, n279, n280, n281, n282, n283, n284, n285, n286,
         n288, n289, n290, n291, n292, n293, n294, n295, n296, n297, n298,
         n299, n300, n301, n302, n303, n304, n305, n306, n307, n308, n310,
         n311, n312, n313, n314, n315, n316, n317, n318, n319, n320, n321,
         n322, n323, n324, n325, n326, n327, n328, n329, n330, n331, n332,
         n333, n334, n335, n336, n337, n338, n339, n340, n341, n342, n343,
         n344, n345, n346, n347, n348, n349, n350, n351, n352, n353, n354,
         n355, n356, n357, n358, n359, n360, n361, n362, n363, n364, n365,
         n366, n367, n368, n369, n370, n371, n372, n373, n374, n375, n376,
         n377, n378, n379, n380, n381, n382, n383, n384, n385, n386, n387,
         n388, n389, n390, n391, n392, n393, n394, n395, n396, n397, n398,
         n399, n400, n401, n402, n403, n404, n405, n406, n407, n408, n409,
         n410, n411, n412, n413, n414, n415, n416, n417, n418, n419, n420,
         n421, n422, n423, n424, n425, n426, n427, n428, n429, n430, n431,
         \local_code_index[9] , \local_code_index[8] , \local_code_index[7] ,
         \local_code_index[6] , \local_code_index[5] , \local_code_index[4] ,
         \local_code_index[3] , \local_code_index[2] , \local_code_index[1] ,
         \local_code_index[10] , n432, n433, n434, n435, n436, n437, n438,
         n439, n440, n441, n442, n443, n444, n445, n446, n447, n448, n449,
         n450, n451, n452, n453, n454, n455, n456, n457, n458, n459, n460,
         n461, n462, n463, n464, n465, n466, n467, n468, n469, n470, n471,
         n472, n473, n474, n475, n476, n477, n478, n479, n480, n481, n482,
         n483, n484, n485, n486, n487, n488, n489, n490, n491, n492, n493,
         n494, n495, n496, n497, n498, n499, n500, n501, n502, n503, n504,
         n505, n506, n507, n508, n509, n510, n511, n512, n513, n514, n515,
         n516, n517, n518, n519, n520, n521, n522, n523, n524, n525, n526,
         n527, n528, n529, n530, n531, n532, n533, n534, n535, n536, n537,
         n538, n539, n540, n541, n542, n543, n544, n545, n546, n547, n548,
         n549, n550, n551, n552, n553, n554, n555, n556, n557, n558, n559,
         n560, n561, n562, n563, n564, n565, n566, n567, n568, n569, n570,
         n571, n572, n573, n574, n575, n576, n577, n578, n579, n580, n581,
         n582, n583, n584, n585, n586, n587, n588, n589, n590, n591, n592,
         n593, n594, n595, n596, n597, n598, n599, n600, n601, n602, n603,
         n604, n605, n606, n607, n608, n609, n610, n611, n612, n613, n614,
         n615, n616, n617, n618, n619, n620, n621, n622, n623, n624, n625,
         n626, n627, n628, n629, n630, n631, n632, n633, n634, n635, n636,
         n637, n638, n639, n640, n641, n642, n643, n644, n645, n646, n647,
         n648, n649, n650, n651, n652, n653, n654, n655, n656, n657, n658,
         n659, n660, n661, n662, n663, n664, n665, n666, n667, n668, n669,
         n670, n671, n672, n673, n674, n675, n676, n677, n678, n679, n680,
         n681, n682, n683, n684, n685, n686, n687, n688, n689, n690, n691,
         n692, n693, n694, n695, n696, n697, n698, n699, n700, n701, n702,
         n703, n704, n705, n706, n707, n708, n709, n710, n711, n712, n713,
         n714, n715, n716, n717, n718, n719, n720, n721, n722, n723, n724,
         n725, n726, n727, n728, n729, n730, n731, n732, n733, n734, n735,
         n736, n737, n738, n739, n740, n741, n742, n743, n744, n745, n746,
         n747, n748, n749, n750, n751, n752, n753, n754, n755, n756, n757,
         n758, n759, n760, n761, n762, n763, n764, n765, n766, n767, n768,
         n769, n770, n771, n772, n773, n774, n775, n776, n777, n778, n779,
         n780, n781, n782, n783, n784, n785, n786, n787, n788, n789, n790,
         n791, n792, n793, n794, n795, n796, n797, n799, n800, n801, n802,
         n803, n804, n805, n806, n807, n808, n809, n810, n811, n812, n813,
         n814, n815, n816, n817, n818, n819, n820, n821, n822, n823, n824,
         n825, n826, n827, n828, n829, n830, n831, n832, n833, n834, n835,
         n836, n837, n838, n839, n840, n841, n842, n843, n844, n845, n846,
         n847, n848, n849, n850, n851, n852, n853, n854, n855, n856, n857,
         n858, n859, n860, n861, n862, n863, n864, n865, n866, n867, n868,
         n869, n870, n871, n872, n873, n874, n875, n876, n877, n878, n879,
         n880, n881, n882, n883, n884, n885, n886, n887, n888, n889, n890,
         n891, n892, n893, n894, n895, n896, n897, n898, n899, n900, n901,
         n902, n903, n904, n905, n906, n907, n908, n909, n910, n911, n912,
         n913, n914, n915, n916, n917, n918, n919, n920, n921, n922, n923,
         n924, n925, n926, n927, n928, n929, n930, n931, n932, n933, n934,
         n935, n936, n937, n938, n939, n940, n942, n943, n944, n945, n946,
         n947, n948, n949, n950, n951, n952, n953, n954, n955, n956, n957,
         n958, n959, n960, n961, n962, n963, n964, n965, n966, n967, n968,
         n969, n970, n971, n972, n973, n974, n975, n976, n977, n978, n979,
         n980, n981, n982, n983, n984, n985, n986, n987, n988, n989, n990,
         n991, n992, n993, n994, n995, n996, n997, n998, n999;
  wire   [10:0] chip_idx;
  wire   [11:0] code_index_sum;
  wire   [7:0] mix_i;
  wire   [7:0] mix_q;
  wire   [23:0] i_acc;
  wire   [23:0] i_next;
  wire   [23:0] q_acc;
  wire   [23:0] q_next;
  wire   [23:0] abs_i;
  wire   [23:0] abs_q;
  wire   [24:0] metric_next;
  wire   [14:0] sample_cnt;
  wire   [2:0] chip_sample_cnt;
  wire   [15:0] completed_ms_count;
  wire   [8:0] \sub_81/carry ;
  wire   [8:0] \sub_80/carry ;
  wire   [10:1] \add_0_root_sub_0_root_sub_55_C67_rn/carry ;
  wire   [11:0] \sub_1_root_sub_0_root_sub_55_C67_rn/carry ;
  wire   SYNOPSYS_UNCONNECTED__0, SYNOPSYS_UNCONNECTED__1;
  assign local_sin[1] = local_sin[2];
  assign local_cos[1] = local_cos[2];

  bdi_capture_channel_6sat_DW01_inc_0 add_165 ( .A(search_phase), .SUM({N289, 
        N288, N287, N286, N285, N284, N283, N282, N281, N280, N279}) );
  bdi_capture_channel_6sat_DW01_inc_1 add_136 ( .A(chip_idx), .SUM({N203, N202, 
        N201, N200, N199, N198, N197, N196, N195, N194, N193}) );
  bdi_capture_channel_6sat_DW01_inc_2 add_128 ( .A(sample_cnt), .SUM({N188, 
        N187, N186, N185, N184, N183, N182, N181, N180, N179, N178, N177, N176, 
        N175, N174}) );
  bdi_capture_channel_6sat_DW01_inc_3 r421 ( .A(completed_ms_count), .SUM({
        N224, N223, N222, N221, N220, N219, N218, N217, N216, N215, N214, N213, 
        N212, N211, N210, SYNOPSYS_UNCONNECTED__0}) );
  bdi_capture_channel_6sat_DW01_inc_4 r416 ( .A(accepted_sample_count), .SUM({
        N169, N168, N167, N166, N165, N164, N163, N162, N161, N160, N159, N158, 
        N157, N156, N155, N154, N153, N152, N151, N150, N149, N148, N147, N146, 
        N145, N144, N143, N142, N141, N140, N139, SYNOPSYS_UNCONNECTED__1}) );
  bdi_capture_channel_6sat_DW01_add_0 add_88 ( .A({1'b0, abs_i}), .B({1'b0, 
        abs_q}), .CI(1'b0), .SUM(metric_next) );
  bdi_capture_channel_6sat_DW01_sub_0 sub_87 ( .A({1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}), .B({n829, 
        q_next[22:0]}), .CI(1'b0), .DIFF({N133, N132, N131, N130, N129, N128, 
        N127, N126, N125, N124, N123, N122, N121, N120, N119, N118, N117, N116, 
        N115, N114, N113, N112, N111, N110}) );
  bdi_capture_channel_6sat_DW01_add_1 add_85 ( .A(q_acc), .B({n804, n805, n804, 
        n805, n804, n805, n804, n805, n804, n805, n804, n805, n804, n805, n804, 
        n805, n804, mix_q[6:0]}), .CI(1'b0), .SUM(q_next) );
  bdi_capture_channel_6sat_DW01_sub_2 sub_86 ( .A({1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}), .B({n831, 
        i_next[22:0]}), .CI(1'b0), .DIFF({N108, N107, N106, N105, N104, N103, 
        N102, N101, N100, N99, N98, N97, N96, N95, N94, N93, N92, N91, N90, 
        N89, N88, N87, N86, N85}) );
  bdi_capture_channel_6sat_DW01_add_2 add_84 ( .A(i_acc), .B({n802, n803, n802, 
        n803, n802, n803, n802, n803, n802, n803, n802, n803, n802, n803, n802, 
        n803, n802, mix_i[6:0]}), .CI(1'b0), .SUM(i_next) );
  bdi_capture_channel_6sat_DW01_add_3 add_62 ( .A({1'b0, search_phase}), .B({
        1'b0, chip_idx}), .CI(1'b0), .SUM({code_index_sum[11:2], 
        \local_code_index[1] , code_index_sum[0]}) );
  bdi_capture_channel_6sat_DW_mult_tc_1 mult_78 ( .a({n797, if_sample[2:1], 
        n796}), .b({local_sin[3:2], local_sin[2], local_sin[0]}), .product({
        N66, N65, N64, N63, N62, N61, N60, N76}) );
  bdi_capture_channel_6sat_DW_mult_tc_0 mult_77 ( .a({n797, if_sample[2:1], 
        n796}), .b({local_cos[3:2], local_cos[2], local_cos[0]}), .product({
        N58, N57, N56, N55, N54, N53, N52, N68}) );
  DFFRQX2 \completed_ms_count_reg[15]  ( .D(n311), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[15]) );
  DFFRQX2 \completed_ms_count_reg[5]  ( .D(n331), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[5]) );
  DFFRQX2 \completed_ms_count_reg[6]  ( .D(n329), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[6]) );
  DFFRQX2 \completed_ms_count_reg[7]  ( .D(n327), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[7]) );
  DFFRQX2 \completed_ms_count_reg[8]  ( .D(n325), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[8]) );
  DFFRQX2 \completed_ms_count_reg[9]  ( .D(n323), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[9]) );
  DFFRQX2 \completed_ms_count_reg[10]  ( .D(n321), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[10]) );
  DFFRQX2 \completed_ms_count_reg[11]  ( .D(n319), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[11]) );
  DFFRQX2 \completed_ms_count_reg[12]  ( .D(n317), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[12]) );
  DFFRQX2 \completed_ms_count_reg[13]  ( .D(n315), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[13]) );
  DFFRQX2 \completed_ms_count_reg[14]  ( .D(n313), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[14]) );
  DFFRQX2 \chip_sample_cnt_reg[2]  ( .D(n289), .CK(clk_16m368), .RN(rst_n), 
        .Q(chip_sample_cnt[2]) );
  DFFRQX2 \chip_sample_cnt_reg[1]  ( .D(n290), .CK(clk_16m368), .RN(rst_n), 
        .Q(chip_sample_cnt[1]) );
  DFFRQX2 \chip_sample_cnt_reg[0]  ( .D(n291), .CK(clk_16m368), .RN(rst_n), 
        .Q(chip_sample_cnt[0]) );
  DFFRQX2 \handoff_code_phase_reg[10]  ( .D(n384), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[10]) );
  DFFRQX2 \handoff_code_phase_reg[9]  ( .D(n383), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[9]) );
  DFFRQX2 \handoff_code_phase_reg[8]  ( .D(n382), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[8]) );
  DFFRQX2 \handoff_code_phase_reg[7]  ( .D(n381), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[7]) );
  DFFRQX2 \handoff_code_phase_reg[6]  ( .D(n380), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[6]) );
  DFFRQX2 \handoff_code_phase_reg[5]  ( .D(n379), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[5]) );
  DFFRQX2 \handoff_code_phase_reg[4]  ( .D(n378), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[4]) );
  DFFRQX2 \handoff_code_phase_reg[3]  ( .D(n377), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[3]) );
  DFFRQX2 \handoff_code_phase_reg[2]  ( .D(n376), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[2]) );
  DFFRQX2 \handoff_code_phase_reg[1]  ( .D(n375), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[1]) );
  DFFRQX2 \handoff_code_phase_reg[0]  ( .D(n374), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_code_phase[0]) );
  DFFRQX2 \handoff_sample_epoch_reg[31]  ( .D(n373), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[31]) );
  DFFRQX2 \handoff_sample_epoch_reg[30]  ( .D(n372), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[30]) );
  DFFRQX2 \handoff_sample_epoch_reg[29]  ( .D(n371), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[29]) );
  DFFRQX2 \handoff_sample_epoch_reg[28]  ( .D(n370), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[28]) );
  DFFRQX2 \handoff_sample_epoch_reg[27]  ( .D(n369), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[27]) );
  DFFRQX2 \handoff_sample_epoch_reg[26]  ( .D(n368), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[26]) );
  DFFRQX2 \handoff_sample_epoch_reg[25]  ( .D(n367), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[25]) );
  DFFRQX2 \handoff_sample_epoch_reg[24]  ( .D(n366), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[24]) );
  DFFRQX2 \handoff_sample_epoch_reg[23]  ( .D(n365), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[23]) );
  DFFRQX2 \handoff_sample_epoch_reg[22]  ( .D(n364), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[22]) );
  DFFRQX2 \handoff_sample_epoch_reg[21]  ( .D(n363), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[21]) );
  DFFRQX2 \handoff_sample_epoch_reg[20]  ( .D(n362), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[20]) );
  DFFRQX2 \handoff_sample_epoch_reg[19]  ( .D(n361), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[19]) );
  DFFRQX2 \handoff_sample_epoch_reg[18]  ( .D(n360), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[18]) );
  DFFRQX2 \handoff_sample_epoch_reg[17]  ( .D(n359), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[17]) );
  DFFRQX2 \handoff_sample_epoch_reg[16]  ( .D(n358), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[16]) );
  DFFRQX2 \handoff_sample_epoch_reg[15]  ( .D(n357), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[15]) );
  DFFRQX2 \handoff_sample_epoch_reg[14]  ( .D(n356), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[14]) );
  DFFRQX2 \handoff_sample_epoch_reg[13]  ( .D(n355), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[13]) );
  DFFRQX2 \handoff_sample_epoch_reg[12]  ( .D(n354), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[12]) );
  DFFRQX2 \handoff_sample_epoch_reg[11]  ( .D(n353), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[11]) );
  DFFRQX2 \handoff_sample_epoch_reg[10]  ( .D(n352), .CK(clk_16m368), .RN(
        rst_n), .Q(handoff_sample_epoch[10]) );
  DFFRQX2 \handoff_sample_epoch_reg[9]  ( .D(n351), .CK(clk_16m368), .RN(rst_n), .Q(handoff_sample_epoch[9]) );
  DFFRQX2 \handoff_sample_epoch_reg[8]  ( .D(n350), .CK(clk_16m368), .RN(rst_n), .Q(handoff_sample_epoch[8]) );
  DFFRQX2 \handoff_sample_epoch_reg[7]  ( .D(n349), .CK(clk_16m368), .RN(rst_n), .Q(handoff_sample_epoch[7]) );
  DFFRQX2 \handoff_sample_epoch_reg[6]  ( .D(n348), .CK(clk_16m368), .RN(rst_n), .Q(handoff_sample_epoch[6]) );
  DFFRQX2 \handoff_sample_epoch_reg[5]  ( .D(n347), .CK(clk_16m368), .RN(rst_n), .Q(handoff_sample_epoch[5]) );
  DFFRQX2 \handoff_sample_epoch_reg[4]  ( .D(n346), .CK(clk_16m368), .RN(rst_n), .Q(handoff_sample_epoch[4]) );
  DFFRQX2 \handoff_sample_epoch_reg[3]  ( .D(n345), .CK(clk_16m368), .RN(rst_n), .Q(handoff_sample_epoch[3]) );
  DFFRQX2 \handoff_sample_epoch_reg[2]  ( .D(n344), .CK(clk_16m368), .RN(rst_n), .Q(handoff_sample_epoch[2]) );
  DFFRQX2 \handoff_sample_epoch_reg[1]  ( .D(n343), .CK(clk_16m368), .RN(rst_n), .Q(handoff_sample_epoch[1]) );
  DFFRQX2 \handoff_sample_epoch_reg[0]  ( .D(n342), .CK(clk_16m368), .RN(rst_n), .Q(handoff_sample_epoch[0]) );
  DFFRQX2 \handoff_ms_count_reg[0]  ( .D(n340), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[0]) );
  DFFRQX2 \handoff_ms_count_reg[1]  ( .D(n338), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[1]) );
  DFFRQX2 \handoff_ms_count_reg[2]  ( .D(n336), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[2]) );
  DFFRQX2 \handoff_ms_count_reg[3]  ( .D(n334), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[3]) );
  DFFRQX2 \handoff_ms_count_reg[4]  ( .D(n332), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[4]) );
  DFFRQX2 \handoff_ms_count_reg[5]  ( .D(n330), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[5]) );
  DFFRQX2 \handoff_ms_count_reg[6]  ( .D(n328), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[6]) );
  DFFRQX2 \handoff_ms_count_reg[7]  ( .D(n326), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[7]) );
  DFFRQX2 \handoff_ms_count_reg[8]  ( .D(n324), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[8]) );
  DFFRQX2 \handoff_ms_count_reg[9]  ( .D(n322), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[9]) );
  DFFRQX2 \handoff_ms_count_reg[10]  ( .D(n320), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[10]) );
  DFFRQX2 \handoff_ms_count_reg[11]  ( .D(n318), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[11]) );
  DFFRQX2 \handoff_ms_count_reg[12]  ( .D(n316), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[12]) );
  DFFRQX2 \handoff_ms_count_reg[13]  ( .D(n314), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[13]) );
  DFFRQX2 \handoff_ms_count_reg[14]  ( .D(n312), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[14]) );
  DFFRQX2 \handoff_ms_count_reg[15]  ( .D(n310), .CK(clk_16m368), .RN(rst_n), 
        .Q(handoff_ms_count[15]) );
  DFFRQX2 \metric_debug_reg[16]  ( .D(n404), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[16]) );
  DFFRQX2 \metric_debug_reg[17]  ( .D(n403), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[17]) );
  DFFRQX2 \metric_debug_reg[18]  ( .D(n402), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[18]) );
  DFFRQX2 \metric_debug_reg[19]  ( .D(n401), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[19]) );
  DFFRQX2 \metric_debug_reg[20]  ( .D(n400), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[20]) );
  DFFRQX2 \metric_debug_reg[21]  ( .D(n399), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[21]) );
  DFFRQX2 \metric_debug_reg[0]  ( .D(n420), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[0]) );
  DFFRQX2 \metric_debug_reg[1]  ( .D(n419), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[1]) );
  DFFRQX2 \metric_debug_reg[2]  ( .D(n418), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[2]) );
  DFFRQX2 \metric_debug_reg[3]  ( .D(n417), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[3]) );
  DFFRQX2 \metric_debug_reg[4]  ( .D(n416), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[4]) );
  DFFRQX2 \metric_debug_reg[5]  ( .D(n415), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[5]) );
  DFFRQX2 \metric_debug_reg[6]  ( .D(n414), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[6]) );
  DFFRQX2 \metric_debug_reg[7]  ( .D(n413), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[7]) );
  DFFRQX2 \metric_debug_reg[8]  ( .D(n412), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[8]) );
  DFFRQX2 \metric_debug_reg[9]  ( .D(n411), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[9]) );
  DFFRQX2 \metric_debug_reg[10]  ( .D(n410), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[10]) );
  DFFRQX2 \metric_debug_reg[11]  ( .D(n409), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[11]) );
  DFFRQX2 \metric_debug_reg[12]  ( .D(n408), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[12]) );
  DFFRQX2 \metric_debug_reg[13]  ( .D(n407), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[13]) );
  DFFRQX2 \metric_debug_reg[14]  ( .D(n406), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[14]) );
  DFFRQX2 \metric_debug_reg[15]  ( .D(n405), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[15]) );
  DFFRQX2 \metric_debug_reg[22]  ( .D(n398), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[22]) );
  DFFRQX2 \metric_debug_reg[23]  ( .D(n397), .CK(clk_16m368), .RN(rst_n), .Q(
        metric_debug[23]) );
  DFFRQX2 \accepted_sample_count_reg[31]  ( .D(n206), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[31]) );
  DFFRQX2 handoff_valid_reg ( .D(n238), .CK(clk_16m368), .RN(rst_n), .Q(
        handoff_valid) );
  DFFRQX2 \sample_cnt_reg[14]  ( .D(n292), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[14]) );
  DFFRQX2 \completed_ms_count_reg[1]  ( .D(n339), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[1]) );
  DFFRQX2 \completed_ms_count_reg[2]  ( .D(n337), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[2]) );
  DFFRQX2 \completed_ms_count_reg[3]  ( .D(n335), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[3]) );
  DFFRQX2 \completed_ms_count_reg[4]  ( .D(n333), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[4]) );
  DFFRQX2 \completed_ms_count_reg[0]  ( .D(n341), .CK(clk_16m368), .RN(rst_n), 
        .Q(completed_ms_count[0]) );
  DFFRQX2 \accepted_sample_count_reg[1]  ( .D(n236), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[1]) );
  DFFRQX2 \accepted_sample_count_reg[2]  ( .D(n235), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[2]) );
  DFFRQX2 \accepted_sample_count_reg[3]  ( .D(n234), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[3]) );
  DFFRQX2 \accepted_sample_count_reg[4]  ( .D(n233), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[4]) );
  DFFRQX2 \accepted_sample_count_reg[5]  ( .D(n232), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[5]) );
  DFFRQX2 \accepted_sample_count_reg[6]  ( .D(n231), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[6]) );
  DFFRQX2 \accepted_sample_count_reg[7]  ( .D(n230), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[7]) );
  DFFRQX2 \accepted_sample_count_reg[8]  ( .D(n229), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[8]) );
  DFFRQX2 \accepted_sample_count_reg[9]  ( .D(n228), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[9]) );
  DFFRQX2 \accepted_sample_count_reg[10]  ( .D(n227), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[10]) );
  DFFRQX2 \accepted_sample_count_reg[11]  ( .D(n226), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[11]) );
  DFFRQX2 \accepted_sample_count_reg[12]  ( .D(n225), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[12]) );
  DFFRQX2 \accepted_sample_count_reg[13]  ( .D(n224), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[13]) );
  DFFRQX2 \accepted_sample_count_reg[14]  ( .D(n223), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[14]) );
  DFFRQX2 \accepted_sample_count_reg[15]  ( .D(n222), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[15]) );
  DFFRQX2 \accepted_sample_count_reg[16]  ( .D(n221), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[16]) );
  DFFRQX2 \accepted_sample_count_reg[17]  ( .D(n220), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[17]) );
  DFFRQX2 \accepted_sample_count_reg[18]  ( .D(n219), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[18]) );
  DFFRQX2 \accepted_sample_count_reg[19]  ( .D(n218), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[19]) );
  DFFRQX2 \accepted_sample_count_reg[20]  ( .D(n217), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[20]) );
  DFFRQX2 \accepted_sample_count_reg[21]  ( .D(n216), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[21]) );
  DFFRQX2 \accepted_sample_count_reg[22]  ( .D(n215), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[22]) );
  DFFRQX2 \accepted_sample_count_reg[23]  ( .D(n214), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[23]) );
  DFFRQX2 \accepted_sample_count_reg[24]  ( .D(n213), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[24]) );
  DFFRQX2 \accepted_sample_count_reg[25]  ( .D(n212), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[25]) );
  DFFRQX2 \accepted_sample_count_reg[26]  ( .D(n211), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[26]) );
  DFFRQX2 \accepted_sample_count_reg[27]  ( .D(n210), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[27]) );
  DFFRQX2 \accepted_sample_count_reg[28]  ( .D(n209), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[28]) );
  DFFRQX2 \accepted_sample_count_reg[29]  ( .D(n208), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[29]) );
  DFFRQX2 \accepted_sample_count_reg[30]  ( .D(n207), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[30]) );
  DFFRQX2 \accepted_sample_count_reg[0]  ( .D(n237), .CK(clk_16m368), .RN(
        rst_n), .Q(accepted_sample_count[0]) );
  DFFRQX2 capture_reg ( .D(n396), .CK(clk_16m368), .RN(rst_n), .Q(capture) );
  DFFRQX2 \sample_cnt_reg[4]  ( .D(n302), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[4]) );
  DFFRQX2 \sample_cnt_reg[1]  ( .D(n305), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[1]) );
  DFFRQX2 \sample_cnt_reg[2]  ( .D(n304), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[2]) );
  DFFRQX2 \sample_cnt_reg[3]  ( .D(n303), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[3]) );
  DFFRQX2 \sample_cnt_reg[5]  ( .D(n301), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[5]) );
  DFFRQX2 \sample_cnt_reg[6]  ( .D(n300), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[6]) );
  DFFRQX2 \sample_cnt_reg[7]  ( .D(n299), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[7]) );
  DFFRQX2 \sample_cnt_reg[8]  ( .D(n298), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[8]) );
  DFFRQX2 \sample_cnt_reg[9]  ( .D(n297), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[9]) );
  DFFRQX2 \sample_cnt_reg[10]  ( .D(n296), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[10]) );
  DFFRQX2 \sample_cnt_reg[11]  ( .D(n295), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[11]) );
  DFFRQX2 \sample_cnt_reg[12]  ( .D(n294), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[12]) );
  DFFRQX2 \sample_cnt_reg[13]  ( .D(n293), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[13]) );
  DFFRQX2 \sample_cnt_reg[0]  ( .D(n306), .CK(clk_16m368), .RN(rst_n), .Q(
        sample_cnt[0]) );
  DFFRQX2 \i_acc_reg[18]  ( .D(n268), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[18]) );
  DFFRQX2 \i_acc_reg[19]  ( .D(n267), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[19]) );
  DFFRQX2 \i_acc_reg[20]  ( .D(n266), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[20]) );
  DFFRQX2 \i_acc_reg[21]  ( .D(n265), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[21]) );
  DFFRQX2 \i_acc_reg[22]  ( .D(n264), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[22]) );
  DFFRQX2 \q_acc_reg[18]  ( .D(n244), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[18]) );
  DFFRQX2 \q_acc_reg[19]  ( .D(n243), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[19]) );
  DFFRQX2 \q_acc_reg[20]  ( .D(n242), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[20]) );
  DFFRQX2 \q_acc_reg[21]  ( .D(n241), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[21]) );
  DFFRQX2 \q_acc_reg[22]  ( .D(n240), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[22]) );
  DFFRQX2 \i_acc_reg[23]  ( .D(n263), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[23]) );
  DFFRQX2 \q_acc_reg[23]  ( .D(n239), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[23]) );
  DFFRQX2 \i_acc_reg[3]  ( .D(n283), .CK(clk_16m368), .RN(rst_n), .Q(i_acc[3])
         );
  DFFRQX2 \i_acc_reg[4]  ( .D(n282), .CK(clk_16m368), .RN(rst_n), .Q(i_acc[4])
         );
  DFFRQX2 \i_acc_reg[5]  ( .D(n281), .CK(clk_16m368), .RN(rst_n), .Q(i_acc[5])
         );
  DFFRQX2 \i_acc_reg[6]  ( .D(n280), .CK(clk_16m368), .RN(rst_n), .Q(i_acc[6])
         );
  DFFRQX2 \i_acc_reg[7]  ( .D(n279), .CK(clk_16m368), .RN(rst_n), .Q(i_acc[7])
         );
  DFFRQX2 \i_acc_reg[8]  ( .D(n278), .CK(clk_16m368), .RN(rst_n), .Q(i_acc[8])
         );
  DFFRQX2 \i_acc_reg[9]  ( .D(n277), .CK(clk_16m368), .RN(rst_n), .Q(i_acc[9])
         );
  DFFRQX2 \i_acc_reg[10]  ( .D(n276), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[10]) );
  DFFRQX2 \i_acc_reg[11]  ( .D(n275), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[11]) );
  DFFRQX2 \i_acc_reg[12]  ( .D(n274), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[12]) );
  DFFRQX2 \i_acc_reg[13]  ( .D(n273), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[13]) );
  DFFRQX2 \i_acc_reg[14]  ( .D(n272), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[14]) );
  DFFRQX2 \i_acc_reg[15]  ( .D(n271), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[15]) );
  DFFRQX2 \i_acc_reg[16]  ( .D(n270), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[16]) );
  DFFRQX2 \i_acc_reg[17]  ( .D(n269), .CK(clk_16m368), .RN(rst_n), .Q(
        i_acc[17]) );
  DFFRQX2 \q_acc_reg[3]  ( .D(n259), .CK(clk_16m368), .RN(rst_n), .Q(q_acc[3])
         );
  DFFRQX2 \q_acc_reg[4]  ( .D(n258), .CK(clk_16m368), .RN(rst_n), .Q(q_acc[4])
         );
  DFFRQX2 \q_acc_reg[5]  ( .D(n257), .CK(clk_16m368), .RN(rst_n), .Q(q_acc[5])
         );
  DFFRQX2 \q_acc_reg[6]  ( .D(n256), .CK(clk_16m368), .RN(rst_n), .Q(q_acc[6])
         );
  DFFRQX2 \q_acc_reg[7]  ( .D(n255), .CK(clk_16m368), .RN(rst_n), .Q(q_acc[7])
         );
  DFFRQX2 \q_acc_reg[8]  ( .D(n254), .CK(clk_16m368), .RN(rst_n), .Q(q_acc[8])
         );
  DFFRQX2 \q_acc_reg[9]  ( .D(n253), .CK(clk_16m368), .RN(rst_n), .Q(q_acc[9])
         );
  DFFRQX2 \q_acc_reg[10]  ( .D(n252), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[10]) );
  DFFRQX2 \q_acc_reg[11]  ( .D(n251), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[11]) );
  DFFRQX2 \q_acc_reg[12]  ( .D(n250), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[12]) );
  DFFRQX2 \q_acc_reg[13]  ( .D(n249), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[13]) );
  DFFRQX2 \q_acc_reg[14]  ( .D(n248), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[14]) );
  DFFRQX2 \q_acc_reg[15]  ( .D(n247), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[15]) );
  DFFRQX2 \q_acc_reg[16]  ( .D(n246), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[16]) );
  DFFRQX2 \q_acc_reg[17]  ( .D(n245), .CK(clk_16m368), .RN(rst_n), .Q(
        q_acc[17]) );
  DFFRQX2 \i_acc_reg[1]  ( .D(n285), .CK(clk_16m368), .RN(rst_n), .Q(i_acc[1])
         );
  DFFRQX2 \i_acc_reg[2]  ( .D(n284), .CK(clk_16m368), .RN(rst_n), .Q(i_acc[2])
         );
  DFFRQX2 \q_acc_reg[1]  ( .D(n261), .CK(clk_16m368), .RN(rst_n), .Q(q_acc[1])
         );
  DFFRQX2 \q_acc_reg[2]  ( .D(n260), .CK(clk_16m368), .RN(rst_n), .Q(q_acc[2])
         );
  DFFRQX2 \i_acc_reg[0]  ( .D(n286), .CK(clk_16m368), .RN(rst_n), .Q(i_acc[0])
         );
  DFFRQX2 \q_acc_reg[0]  ( .D(n262), .CK(clk_16m368), .RN(rst_n), .Q(q_acc[0])
         );
  DFFRQX2 \carrier_phase_reg[1]  ( .D(n913), .CK(clk_16m368), .RN(rst_n), .Q(
        \carrier_phase[1] ) );
  DFFRQX2 \carrier_phase_reg[0]  ( .D(n288), .CK(clk_16m368), .RN(rst_n), .Q(
        local_sin[0]) );
  DFFRQX2 \search_phase_reg[10]  ( .D(n385), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[10]) );
  DFFRQX2 \chip_idx_reg[10]  ( .D(n430), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[10]) );
  DFFRQX2 \chip_idx_reg[3]  ( .D(n427), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[3]) );
  DFFRQX2 \chip_idx_reg[4]  ( .D(n426), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[4]) );
  DFFRQX2 \chip_idx_reg[5]  ( .D(n425), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[5]) );
  DFFRQX2 \chip_idx_reg[6]  ( .D(n424), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[6]) );
  DFFRQX2 \chip_idx_reg[7]  ( .D(n423), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[7]) );
  DFFRQX2 \chip_idx_reg[8]  ( .D(n422), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[8]) );
  DFFRQX2 \search_phase_reg[4]  ( .D(n391), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[4]) );
  DFFRQX2 \search_phase_reg[3]  ( .D(n392), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[3]) );
  DFFRQX2 \search_phase_reg[9]  ( .D(n386), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[9]) );
  DFFRQX2 \search_phase_reg[2]  ( .D(n393), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[2]) );
  DFFRQX2 \search_phase_reg[5]  ( .D(n390), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[5]) );
  DFFRX1 \chip_idx_reg[1]  ( .D(n429), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[1]), .QN(n308) );
  DFFRQX2 \chip_idx_reg[9]  ( .D(n421), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[9]) );
  DFFRQX2 \chip_idx_reg[2]  ( .D(n428), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[2]) );
  DFFRQX2 \chip_idx_reg[0]  ( .D(n431), .CK(clk_16m368), .RN(rst_n), .Q(
        chip_idx[0]) );
  DFFRQX2 \search_phase_reg[0]  ( .D(n394), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[0]) );
  DFFRX1 \search_phase_reg[1]  ( .D(n395), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[1]), .QN(n943) );
  DFFRX1 \search_phase_reg[6]  ( .D(n389), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[6]), .QN(n949) );
  DFFRX1 \search_phase_reg[7]  ( .D(n388), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[7]), .QN(n950) );
  DFFRX1 \search_phase_reg[8]  ( .D(n387), .CK(clk_16m368), .RN(rst_n), .Q(
        search_phase[8]), .QN(n951) );
  DFFRQX2 dump_reg ( .D(n800), .CK(clk_16m368), .RN(rst_n), .Q(dump) );
  DFFRQX2 capture_event_reg ( .D(n801), .CK(clk_16m368), .RN(rst_n), .Q(
        capture_event) );
  DFFRQX2 capture_rise_reg ( .D(n821), .CK(clk_16m368), .RN(rst_n), .Q(
        capture_rise) );
  AO22X2 U479 ( .A0(code), .A1(N83), .B0(N66), .B1(n912), .Y(mix_q[7]) );
  AO22X2 U480 ( .A0(N75), .A1(code), .B0(N58), .B1(n912), .Y(mix_i[7]) );
  AO22X2 U481 ( .A0(metric_next[0]), .A1(n800), .B0(metric_debug[0]), .B1(n810), .Y(n420) );
  BUFX2 U482 ( .A(N29), .Y(n799) );
  INVX2 U483 ( .A(n830), .Y(n829) );
  INVX2 U484 ( .A(n832), .Y(n831) );
  INVX2 U485 ( .A(n694), .Y(n749) );
  INVX2 U486 ( .A(n501), .Y(n765) );
  INVX2 U487 ( .A(n593), .Y(n738) );
  INVX2 U488 ( .A(n474), .Y(n759) );
  INVX2 U489 ( .A(n627), .Y(n747) );
  INVX2 U490 ( .A(n607), .Y(n755) );
  INVX2 U491 ( .A(n471), .Y(n763) );
  INVX2 U492 ( .A(n651), .Y(n760) );
  INVX2 U493 ( .A(n631), .Y(n746) );
  INVX2 U494 ( .A(n515), .Y(n754) );
  INVX2 U495 ( .A(n657), .Y(n730) );
  INVX2 U496 ( .A(n585), .Y(n751) );
  INVX2 U497 ( .A(n568), .Y(n767) );
  INVX2 U498 ( .A(n646), .Y(n756) );
  INVX2 U499 ( .A(n677), .Y(n762) );
  INVX2 U500 ( .A(n634), .Y(n753) );
  INVX2 U501 ( .A(n660), .Y(n750) );
  INVX2 U502 ( .A(n602), .Y(n731) );
  INVX2 U503 ( .A(n555), .Y(n758) );
  INVX2 U504 ( .A(n566), .Y(n740) );
  INVX2 U505 ( .A(n670), .Y(n766) );
  INVX2 U506 ( .A(n553), .Y(n761) );
  INVX2 U507 ( .A(n559), .Y(n737) );
  INVX2 U508 ( .A(n644), .Y(n770) );
  INVX2 U509 ( .A(n551), .Y(n743) );
  INVX2 U510 ( .A(n661), .Y(n752) );
  INVX2 U511 ( .A(n655), .Y(n729) );
  INVX2 U512 ( .A(n626), .Y(n735) );
  INVX2 U513 ( .A(n519), .Y(n774) );
  INVX2 U514 ( .A(n664), .Y(n732) );
  INVX2 U515 ( .A(n610), .Y(n748) );
  INVX2 U516 ( .A(n652), .Y(n733) );
  INVX2 U517 ( .A(n571), .Y(n725) );
  INVX2 U518 ( .A(n584), .Y(n757) );
  INVX2 U519 ( .A(n680), .Y(n741) );
  BUFX2 U520 ( .A(mix_i[7]), .Y(n802) );
  BUFX2 U521 ( .A(mix_q[7]), .Y(n804) );
  INVX2 U522 ( .A(n676), .Y(n745) );
  INVX2 U523 ( .A(n603), .Y(n736) );
  BUFX2 U524 ( .A(mix_i[7]), .Y(n803) );
  BUFX2 U525 ( .A(mix_q[7]), .Y(n805) );
  INVX2 U526 ( .A(n659), .Y(n742) );
  INVX2 U527 ( .A(n460), .Y(n739) );
  INVX2 U528 ( .A(n598), .Y(n778) );
  INVX2 U529 ( .A(n718), .Y(n777) );
  INVX2 U530 ( .A(n516), .Y(n769) );
  INVX2 U531 ( .A(n781), .Y(n784) );
  INVX2 U532 ( .A(n786), .Y(n789) );
  BUFX2 U533 ( .A(n914), .Y(n809) );
  BUFX2 U534 ( .A(n914), .Y(n810) );
  INVX2 U535 ( .A(n498), .Y(n764) );
  XOR2X1 U536 ( .A(N58), .B(n432), .Y(N75) );
  NAND2X2 U537 ( .A(\sub_80/carry [6]), .B(n848), .Y(n432) );
  XOR2X1 U538 ( .A(N66), .B(n433), .Y(N83) );
  NAND2X2 U539 ( .A(\sub_81/carry [6]), .B(n855), .Y(n433) );
  INVX2 U540 ( .A(n642), .Y(n775) );
  INVX2 U541 ( .A(n687), .Y(n771) );
  INVX2 U542 ( .A(n681), .Y(n744) );
  AO22X2 U543 ( .A0(N68), .A1(code), .B0(N68), .B1(n912), .Y(mix_i[0]) );
  INVX2 U544 ( .A(n532), .Y(n728) );
  INVX2 U545 ( .A(n675), .Y(n726) );
  BUFX2 U546 ( .A(n434), .Y(n783) );
  BUFX2 U547 ( .A(n434), .Y(n782) );
  BUFX2 U548 ( .A(n434), .Y(n781) );
  BUFX2 U549 ( .A(n790), .Y(n786) );
  BUFX2 U550 ( .A(n790), .Y(n787) );
  BUFX2 U551 ( .A(n790), .Y(n788) );
  INVX2 U552 ( .A(N20), .Y(n727) );
  NAND3XL U553 ( .A(n861), .B(n860), .C(n862), .Y(n204) );
  INVX2 U554 ( .A(code), .Y(n912) );
  NAND2X2 U555 ( .A(n734), .B(n724), .Y(n575) );
  INVX2 U556 ( .A(N21), .Y(n734) );
  INVX2 U557 ( .A(n823), .Y(n822) );
  INVX2 U558 ( .A(n823), .Y(n821) );
  INVX2 U559 ( .A(n824), .Y(n820) );
  INVX2 U560 ( .A(N22), .Y(n768) );
  BUFX2 U561 ( .A(n434), .Y(n780) );
  INVX2 U562 ( .A(N24), .Y(n776) );
  INVX2 U563 ( .A(N23), .Y(n773) );
  INVX2 U564 ( .A(N26), .Y(n779) );
  INVX2 U565 ( .A(n792), .Y(n795) );
  INVX2 U566 ( .A(N68), .Y(n842) );
  INVX2 U567 ( .A(N56), .Y(n847) );
  INVX2 U568 ( .A(N64), .Y(n854) );
  INVX2 U569 ( .A(N55), .Y(n846) );
  INVX2 U570 ( .A(n818), .Y(n817) );
  INVX2 U571 ( .A(n307), .Y(n914) );
  BUFX2 U572 ( .A(n69), .Y(n812) );
  BUFX2 U573 ( .A(n69), .Y(n813) );
  BUFX2 U574 ( .A(n69), .Y(n814) );
  BUFX2 U575 ( .A(n69), .Y(n811) );
  BUFX2 U576 ( .A(n69), .Y(n815) );
  INVX2 U577 ( .A(n696), .Y(n772) );
  OR2X2 U578 ( .A(code_index_sum[0]), .B(n768), .Y(n434) );
  ADDFX1 U579 ( .A(\local_code_index[5] ), .B(n799), .CI(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [5]), .CO(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [6]), .S(N22) );
  ADDFX1 U580 ( .A(\local_code_index[4] ), .B(n799), .CI(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [4]), .CO(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [5]), .S(N21) );
  ADDFX1 U581 ( .A(\local_code_index[6] ), .B(n799), .CI(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [6]), .CO(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [7]), .S(N23) );
  AO22X2 U582 ( .A0(N76), .A1(code), .B0(N76), .B1(n912), .Y(mix_q[0]) );
  ADDFX1 U583 ( .A(\local_code_index[9] ), .B(n799), .CI(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [9]), .CO(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [10]), .S(N26) );
  INVX2 U584 ( .A(N18), .Y(n723) );
  NAND2X2 U585 ( .A(n202), .B(n203), .Y(n171) );
  NOR4X2 U586 ( .A(n205), .B(metric_next[13]), .C(metric_next[15]), .D(
        metric_next[14]), .Y(n202) );
  NOR4X2 U587 ( .A(n204), .B(metric_next[22]), .C(metric_next[24]), .D(
        metric_next[23]), .Y(n203) );
  NAND3XL U588 ( .A(n864), .B(n863), .C(n865), .Y(n205) );
  BUFX2 U589 ( .A(n828), .Y(n823) );
  BUFX2 U590 ( .A(n436), .Y(n794) );
  BUFX2 U591 ( .A(n436), .Y(n793) );
  BUFX2 U592 ( .A(n436), .Y(n792) );
  BUFX2 U593 ( .A(n828), .Y(n824) );
  BUFX2 U594 ( .A(n828), .Y(n825) );
  BUFX2 U595 ( .A(n828), .Y(n826) );
  BUFX2 U596 ( .A(n1001), .Y(code) );
  XOR3XL U597 ( .A(\local_code_index[10] ), .B(n799), .C(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [10]), .Y(N27) );
  ADDFX1 U598 ( .A(\local_code_index[8] ), .B(n799), .CI(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [8]), .CO(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [9]), .S(N25) );
  INVX2 U599 ( .A(n435), .Y(n785) );
  ADDFX1 U600 ( .A(\local_code_index[3] ), .B(n799), .CI(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [3]), .CO(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [4]), .S(N20) );
  ADDFX1 U601 ( .A(\local_code_index[7] ), .B(n799), .CI(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [7]), .CO(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [8]), .S(N24) );
  INVX2 U602 ( .A(N19), .Y(n724) );
  BUFX2 U603 ( .A(n700), .Y(n790) );
  BUFX2 U604 ( .A(n436), .Y(n791) );
  INVX2 U605 ( .A(metric_next[19]), .Y(n862) );
  INVX2 U606 ( .A(metric_next[16]), .Y(n865) );
  INVX2 U607 ( .A(metric_next[21]), .Y(n860) );
  INVX2 U608 ( .A(metric_next[18]), .Y(n863) );
  INVX2 U609 ( .A(metric_next[20]), .Y(n861) );
  INVX2 U610 ( .A(metric_next[17]), .Y(n864) );
  BUFX2 U611 ( .A(n828), .Y(n827) );
  INVX2 U612 ( .A(N76), .Y(n849) );
  INVX2 U613 ( .A(N57), .Y(n848) );
  INVX2 U614 ( .A(N65), .Y(n855) );
  INVX2 U615 ( .A(N54), .Y(n845) );
  INVX2 U616 ( .A(N53), .Y(n844) );
  INVX2 U617 ( .A(N61), .Y(n851) );
  INVX2 U618 ( .A(N63), .Y(n853) );
  NOR2X2 U619 ( .A(n120), .B(n816), .Y(n307) );
  NOR2X2 U620 ( .A(n120), .B(n816), .Y(n801) );
  NOR2X2 U621 ( .A(n120), .B(n816), .Y(n800) );
  NAND2X2 U622 ( .A(n819), .B(n120), .Y(n69) );
  INVX2 U623 ( .A(n816), .Y(n818) );
  INVX2 U624 ( .A(n817), .Y(n819) );
  OAI2BB2X2 U625 ( .B0(n831), .B1(n911), .A0N(N85), .A1N(n831), .Y(abs_i[0])
         );
  OAI2BB2X2 U626 ( .B0(n829), .B1(n888), .A0N(N110), .A1N(n829), .Y(abs_q[0])
         );
  OR2X2 U627 ( .A(n768), .B(N17), .Y(n435) );
  OR2X2 U628 ( .A(N17), .B(N22), .Y(n436) );
  OAI2B2X1 U629 ( .A1N(N288), .A0(n808), .B0(n807), .B1(n952), .Y(n386) );
  OAI2B2X1 U630 ( .A1N(N284), .A0(n808), .B0(n807), .B1(n948), .Y(n390) );
  OAI2B2X1 U631 ( .A1N(N283), .A0(n808), .B0(n807), .B1(n947), .Y(n391) );
  OAI2B2X1 U632 ( .A1N(N282), .A0(n808), .B0(n807), .B1(n946), .Y(n392) );
  OAI2B2X1 U633 ( .A1N(N281), .A0(n808), .B0(n807), .B1(n945), .Y(n393) );
  OAI2B2X1 U634 ( .A1N(N287), .A0(n808), .B0(n807), .B1(n951), .Y(n387) );
  OAI2B2X1 U635 ( .A1N(N286), .A0(n808), .B0(n807), .B1(n950), .Y(n388) );
  OAI2B2X1 U636 ( .A1N(N285), .A0(n808), .B0(n807), .B1(n949), .Y(n389) );
  OAI2B2X1 U637 ( .A1N(N280), .A0(n808), .B0(n807), .B1(n943), .Y(n395) );
  OAI21BX1 U638 ( .A0(n859), .A1(n858), .B0N(code_index_sum[11]), .Y(N29) );
  OA22X2 U639 ( .A0(n437), .A1(n678), .B0(n789), .B1(n679), .Y(n686) );
  OA21X1 U640 ( .A0(N17), .A1(n701), .B0(n793), .Y(n437) );
  AND2X2 U641 ( .A(N133), .B(n829), .Y(abs_q[23]) );
  AND2X2 U642 ( .A(N108), .B(n831), .Y(abs_i[23]) );
  ADDFX1 U643 ( .A(\local_code_index[2] ), .B(n799), .CI(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [2]), .CO(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [3]), .S(N19) );
  OAI2BB2X2 U644 ( .B0(n829), .B1(n886), .A0N(N112), .A1N(n829), .Y(abs_q[2])
         );
  OAI2BB2X2 U645 ( .B0(n831), .B1(n909), .A0N(N87), .A1N(n831), .Y(abs_i[2])
         );
  OAI2BB2X2 U646 ( .B0(n829), .B1(n885), .A0N(N113), .A1N(n829), .Y(abs_q[3])
         );
  OAI2BB2X2 U647 ( .B0(n831), .B1(n908), .A0N(N88), .A1N(n831), .Y(abs_i[3])
         );
  OAI2BB2X2 U648 ( .B0(n829), .B1(n884), .A0N(N114), .A1N(n829), .Y(abs_q[4])
         );
  OAI2BB2X2 U649 ( .B0(n831), .B1(n907), .A0N(N89), .A1N(n831), .Y(abs_i[4])
         );
  OAI2BB2X2 U650 ( .B0(n829), .B1(n883), .A0N(N115), .A1N(n829), .Y(abs_q[5])
         );
  OAI2BB2X2 U651 ( .B0(n831), .B1(n906), .A0N(N90), .A1N(n831), .Y(abs_i[5])
         );
  OAI2BB2X2 U652 ( .B0(n829), .B1(n882), .A0N(N116), .A1N(n829), .Y(abs_q[6])
         );
  OAI2BB2X2 U653 ( .B0(n831), .B1(n905), .A0N(N91), .A1N(n831), .Y(abs_i[6])
         );
  OAI2BB2X2 U654 ( .B0(n829), .B1(n881), .A0N(N117), .A1N(n829), .Y(abs_q[7])
         );
  OAI2BB2X2 U655 ( .B0(n831), .B1(n904), .A0N(N92), .A1N(n831), .Y(abs_i[7])
         );
  OAI2BB2X2 U656 ( .B0(n829), .B1(n880), .A0N(N118), .A1N(n829), .Y(abs_q[8])
         );
  OAI2BB2X2 U657 ( .B0(n831), .B1(n903), .A0N(N93), .A1N(n831), .Y(abs_i[8])
         );
  OAI2BB2X2 U658 ( .B0(n829), .B1(n879), .A0N(N119), .A1N(n829), .Y(abs_q[9])
         );
  OAI2BB2X2 U659 ( .B0(n831), .B1(n902), .A0N(N94), .A1N(n831), .Y(abs_i[9])
         );
  OAI2BB2X2 U660 ( .B0(n829), .B1(n878), .A0N(N120), .A1N(n829), .Y(abs_q[10])
         );
  OAI2BB2X2 U661 ( .B0(n831), .B1(n901), .A0N(N95), .A1N(n831), .Y(abs_i[10])
         );
  OAI2BB2X2 U662 ( .B0(n829), .B1(n877), .A0N(N121), .A1N(n829), .Y(abs_q[11])
         );
  OAI2BB2X2 U663 ( .B0(n831), .B1(n900), .A0N(N96), .A1N(n831), .Y(abs_i[11])
         );
  OAI2BB2X2 U664 ( .B0(n829), .B1(n876), .A0N(N122), .A1N(n829), .Y(abs_q[12])
         );
  OAI2BB2X2 U665 ( .B0(n831), .B1(n899), .A0N(N97), .A1N(n831), .Y(abs_i[12])
         );
  OAI2BB2X2 U666 ( .B0(n829), .B1(n875), .A0N(N123), .A1N(n829), .Y(abs_q[13])
         );
  OAI2BB2X2 U667 ( .B0(n831), .B1(n898), .A0N(N98), .A1N(n831), .Y(abs_i[13])
         );
  OAI2BB2X2 U668 ( .B0(n829), .B1(n874), .A0N(N124), .A1N(n829), .Y(abs_q[14])
         );
  OAI2BB2X2 U669 ( .B0(n831), .B1(n897), .A0N(N99), .A1N(n831), .Y(abs_i[14])
         );
  OAI2BB2X2 U670 ( .B0(n829), .B1(n873), .A0N(N125), .A1N(n829), .Y(abs_q[15])
         );
  OAI2BB2X2 U671 ( .B0(n831), .B1(n896), .A0N(N100), .A1N(n831), .Y(abs_i[15])
         );
  OAI2BB2X2 U672 ( .B0(n829), .B1(n872), .A0N(N126), .A1N(n829), .Y(abs_q[16])
         );
  OAI2BB2X2 U673 ( .B0(n831), .B1(n895), .A0N(N101), .A1N(n831), .Y(abs_i[16])
         );
  OAI2BB2X2 U674 ( .B0(n829), .B1(n871), .A0N(N127), .A1N(n829), .Y(abs_q[17])
         );
  OAI2BB2X2 U675 ( .B0(n831), .B1(n894), .A0N(N102), .A1N(n831), .Y(abs_i[17])
         );
  OAI2BB2X2 U676 ( .B0(n829), .B1(n870), .A0N(N128), .A1N(n829), .Y(abs_q[18])
         );
  OAI2BB2X2 U677 ( .B0(n831), .B1(n893), .A0N(N103), .A1N(n831), .Y(abs_i[18])
         );
  OAI2BB2X2 U678 ( .B0(n829), .B1(n869), .A0N(N129), .A1N(n829), .Y(abs_q[19])
         );
  OAI2BB2X2 U679 ( .B0(n831), .B1(n892), .A0N(N104), .A1N(n831), .Y(abs_i[19])
         );
  OAI2BB2X2 U680 ( .B0(n829), .B1(n868), .A0N(N130), .A1N(n829), .Y(abs_q[20])
         );
  OAI2BB2X2 U681 ( .B0(n831), .B1(n891), .A0N(N105), .A1N(n831), .Y(abs_i[20])
         );
  OAI2BB2X2 U682 ( .B0(n829), .B1(n867), .A0N(N131), .A1N(n829), .Y(abs_q[21])
         );
  OAI2BB2X2 U683 ( .B0(n831), .B1(n890), .A0N(N106), .A1N(n831), .Y(abs_i[21])
         );
  OAI2BB2X2 U684 ( .B0(n829), .B1(n866), .A0N(N132), .A1N(n829), .Y(abs_q[22])
         );
  OAI2BB2X2 U685 ( .B0(n831), .B1(n889), .A0N(N107), .A1N(n831), .Y(abs_i[22])
         );
  OAI2BB2X2 U686 ( .B0(n829), .B1(n887), .A0N(N111), .A1N(n829), .Y(abs_q[1])
         );
  OAI2BB2X2 U687 ( .B0(n831), .B1(n910), .A0N(N86), .A1N(n831), .Y(abs_i[1])
         );
  INVX2 U688 ( .A(\local_code_index[1] ), .Y(n833) );
  INVX2 U689 ( .A(code_index_sum[3]), .Y(n835) );
  INVX2 U690 ( .A(code_index_sum[2]), .Y(n834) );
  INVX2 U691 ( .A(code_index_sum[4]), .Y(n836) );
  INVX2 U692 ( .A(N394), .Y(n828) );
  XNOR2X1 U693 ( .A(code_index_sum[10]), .B(n438), .Y(\local_code_index[10] )
         );
  NOR2X2 U694 ( .A(n841), .B(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [9]), 
        .Y(n438) );
  INVX2 U695 ( .A(N52), .Y(n843) );
  INVX2 U696 ( .A(N60), .Y(n850) );
  INVX2 U697 ( .A(i_next[0]), .Y(n911) );
  INVX2 U698 ( .A(q_next[0]), .Y(n888) );
  INVX2 U699 ( .A(N62), .Y(n852) );
  INVX2 U700 ( .A(i_next[1]), .Y(n910) );
  INVX2 U701 ( .A(q_next[1]), .Y(n887) );
  INVX2 U702 ( .A(i_next[2]), .Y(n909) );
  INVX2 U703 ( .A(q_next[2]), .Y(n886) );
  INVX2 U704 ( .A(i_next[3]), .Y(n908) );
  INVX2 U705 ( .A(q_next[3]), .Y(n885) );
  INVX2 U706 ( .A(i_next[4]), .Y(n907) );
  INVX2 U707 ( .A(q_next[4]), .Y(n884) );
  INVX2 U708 ( .A(i_next[5]), .Y(n906) );
  INVX2 U709 ( .A(q_next[5]), .Y(n883) );
  INVX2 U710 ( .A(i_next[6]), .Y(n905) );
  INVX2 U711 ( .A(q_next[6]), .Y(n882) );
  INVX2 U712 ( .A(i_next[7]), .Y(n904) );
  INVX2 U713 ( .A(q_next[7]), .Y(n881) );
  INVX2 U714 ( .A(i_next[8]), .Y(n903) );
  INVX2 U715 ( .A(q_next[8]), .Y(n880) );
  INVX2 U716 ( .A(i_next[9]), .Y(n902) );
  INVX2 U717 ( .A(q_next[9]), .Y(n879) );
  INVX2 U718 ( .A(i_next[10]), .Y(n901) );
  INVX2 U719 ( .A(q_next[10]), .Y(n878) );
  INVX2 U720 ( .A(i_next[11]), .Y(n900) );
  INVX2 U721 ( .A(q_next[11]), .Y(n877) );
  INVX2 U722 ( .A(i_next[12]), .Y(n899) );
  INVX2 U723 ( .A(q_next[12]), .Y(n876) );
  INVX2 U724 ( .A(i_next[13]), .Y(n898) );
  INVX2 U725 ( .A(q_next[13]), .Y(n875) );
  INVX2 U726 ( .A(i_next[14]), .Y(n897) );
  INVX2 U727 ( .A(q_next[14]), .Y(n874) );
  INVX2 U728 ( .A(i_next[15]), .Y(n896) );
  INVX2 U729 ( .A(q_next[15]), .Y(n873) );
  INVX2 U730 ( .A(i_next[16]), .Y(n895) );
  INVX2 U731 ( .A(q_next[16]), .Y(n872) );
  INVX2 U732 ( .A(i_next[17]), .Y(n894) );
  INVX2 U733 ( .A(q_next[17]), .Y(n871) );
  INVX2 U734 ( .A(i_next[18]), .Y(n893) );
  INVX2 U735 ( .A(q_next[18]), .Y(n870) );
  INVX2 U736 ( .A(i_next[19]), .Y(n892) );
  INVX2 U737 ( .A(q_next[19]), .Y(n869) );
  INVX2 U738 ( .A(i_next[20]), .Y(n891) );
  INVX2 U739 ( .A(q_next[20]), .Y(n868) );
  INVX2 U740 ( .A(i_next[21]), .Y(n890) );
  INVX2 U741 ( .A(q_next[21]), .Y(n867) );
  INVX2 U742 ( .A(i_next[22]), .Y(n889) );
  INVX2 U743 ( .A(q_next[22]), .Y(n866) );
  INVX2 U744 ( .A(code_index_sum[8]), .Y(n840) );
  INVX2 U745 ( .A(code_index_sum[7]), .Y(n839) );
  INVX2 U746 ( .A(code_index_sum[6]), .Y(n838) );
  INVX2 U747 ( .A(code_index_sum[5]), .Y(n837) );
  INVX2 U748 ( .A(code_index_sum[9]), .Y(n841) );
  NOR2X2 U749 ( .A(local_cos[0]), .B(n942), .Y(local_sin[3]) );
  NAND4X2 U750 ( .A(n198), .B(n199), .C(n200), .D(n201), .Y(n120) );
  NOR3X1 U751 ( .A(n923), .B(n921), .C(n922), .Y(n198) );
  NOR4X2 U752 ( .A(n925), .B(n926), .C(n927), .D(n916), .Y(n200) );
  NOR4X2 U753 ( .A(n917), .B(n918), .C(n919), .D(n920), .Y(n199) );
  NAND2X2 U754 ( .A(n806), .B(n120), .Y(n179) );
  OAI2B2X1 U755 ( .A1N(N187), .A0(n812), .B0(n819), .B1(n927), .Y(n293) );
  OAI2B2X1 U756 ( .A1N(N175), .A0(n811), .B0(n819), .B1(n916), .Y(n305) );
  OAI2B2X1 U757 ( .A1N(N186), .A0(n812), .B0(n819), .B1(n926), .Y(n294) );
  OAI2B2X1 U758 ( .A1N(N185), .A0(n811), .B0(n819), .B1(n925), .Y(n295) );
  OAI2B2X1 U759 ( .A1N(N184), .A0(n812), .B0(n819), .B1(n924), .Y(n296) );
  OAI2B2X1 U760 ( .A1N(N183), .A0(n811), .B0(n819), .B1(n923), .Y(n297) );
  OAI2B2X1 U761 ( .A1N(N182), .A0(n811), .B0(n819), .B1(n922), .Y(n298) );
  OAI2B2X1 U762 ( .A1N(N181), .A0(n811), .B0(n819), .B1(n921), .Y(n299) );
  OAI2B2X1 U763 ( .A1N(N180), .A0(n811), .B0(n819), .B1(n920), .Y(n300) );
  OAI2B2X1 U764 ( .A1N(N179), .A0(n811), .B0(n819), .B1(n919), .Y(n301) );
  OAI2B2X1 U765 ( .A1N(N177), .A0(n811), .B0(n819), .B1(n918), .Y(n303) );
  OAI2B2X1 U766 ( .A1N(N176), .A0(n811), .B0(n819), .B1(n917), .Y(n304) );
  OAI2B2X1 U767 ( .A1N(N201), .A0(n179), .B0(n938), .B1(n806), .Y(n422) );
  OAI2B2X1 U768 ( .A1N(N200), .A0(n179), .B0(n937), .B1(n806), .Y(n423) );
  OAI2B2X1 U769 ( .A1N(N199), .A0(n179), .B0(n936), .B1(n806), .Y(n424) );
  OAI2B2X1 U770 ( .A1N(N198), .A0(n179), .B0(n935), .B1(n806), .Y(n425) );
  OAI2B2X1 U771 ( .A1N(N197), .A0(n179), .B0(n934), .B1(n806), .Y(n426) );
  OAI2B2X1 U772 ( .A1N(N196), .A0(n179), .B0(n933), .B1(n806), .Y(n427) );
  AOI21X1 U773 ( .A0(n928), .A1(n120), .B0(n36), .Y(n122) );
  BUFX2 U774 ( .A(n36), .Y(n816) );
  INVX2 U775 ( .A(N223), .Y(n986) );
  INVX2 U776 ( .A(N168), .Y(n955) );
  INVX2 U777 ( .A(N167), .Y(n956) );
  INVX2 U778 ( .A(N166), .Y(n957) );
  INVX2 U779 ( .A(N165), .Y(n958) );
  INVX2 U780 ( .A(N164), .Y(n959) );
  INVX2 U781 ( .A(N163), .Y(n960) );
  INVX2 U782 ( .A(N162), .Y(n961) );
  INVX2 U783 ( .A(N161), .Y(n962) );
  INVX2 U784 ( .A(N160), .Y(n963) );
  INVX2 U785 ( .A(N159), .Y(n964) );
  INVX2 U786 ( .A(N158), .Y(n965) );
  INVX2 U787 ( .A(N157), .Y(n966) );
  INVX2 U788 ( .A(N156), .Y(n967) );
  INVX2 U789 ( .A(N155), .Y(n968) );
  INVX2 U790 ( .A(N154), .Y(n969) );
  INVX2 U791 ( .A(N153), .Y(n970) );
  INVX2 U792 ( .A(N152), .Y(n971) );
  XOR2X1 U793 ( .A(local_cos[0]), .B(n36), .Y(n288) );
  NOR3X1 U794 ( .A(n938), .B(n936), .C(n937), .Y(n193) );
  INVX2 U795 ( .A(N222), .Y(n987) );
  INVX2 U796 ( .A(N221), .Y(n988) );
  INVX2 U797 ( .A(N220), .Y(n989) );
  INVX2 U798 ( .A(N219), .Y(n990) );
  INVX2 U799 ( .A(N218), .Y(n991) );
  INVX2 U800 ( .A(N217), .Y(n992) );
  INVX2 U801 ( .A(N216), .Y(n993) );
  INVX2 U802 ( .A(N215), .Y(n994) );
  INVX2 U803 ( .A(N214), .Y(n995) );
  INVX2 U804 ( .A(N213), .Y(n996) );
  INVX2 U805 ( .A(N212), .Y(n997) );
  INVX2 U806 ( .A(N211), .Y(n998) );
  INVX2 U807 ( .A(N210), .Y(n999) );
  INVX2 U808 ( .A(N151), .Y(n972) );
  INVX2 U809 ( .A(N150), .Y(n973) );
  INVX2 U810 ( .A(N149), .Y(n974) );
  INVX2 U811 ( .A(N148), .Y(n975) );
  INVX2 U812 ( .A(N147), .Y(n976) );
  INVX2 U813 ( .A(N146), .Y(n977) );
  INVX2 U814 ( .A(N145), .Y(n978) );
  INVX2 U815 ( .A(N144), .Y(n979) );
  INVX2 U816 ( .A(N143), .Y(n980) );
  INVX2 U817 ( .A(N142), .Y(n981) );
  INVX2 U818 ( .A(N141), .Y(n982) );
  INVX2 U819 ( .A(N140), .Y(n983) );
  INVX2 U820 ( .A(N139), .Y(n984) );
  OAI2B2X1 U821 ( .A1N(handoff_ms_count[15]), .A0(n822), .B0(n826), .B1(n985), 
        .Y(n310) );
  OAI2B2X1 U822 ( .A1N(handoff_sample_epoch[31]), .A0(n822), .B0(n954), .B1(
        n824), .Y(n373) );
  OAI2B2X1 U823 ( .A1N(handoff_ms_count[14]), .A0(n822), .B0(n827), .B1(n986), 
        .Y(n312) );
  OAI2B2X1 U824 ( .A1N(handoff_ms_count[13]), .A0(n822), .B0(n827), .B1(n987), 
        .Y(n314) );
  OAI2B2X1 U825 ( .A1N(handoff_ms_count[12]), .A0(n822), .B0(n827), .B1(n988), 
        .Y(n316) );
  OAI2B2X1 U826 ( .A1N(handoff_ms_count[11]), .A0(n822), .B0(n827), .B1(n989), 
        .Y(n318) );
  OAI2B2X1 U827 ( .A1N(handoff_ms_count[10]), .A0(n822), .B0(n827), .B1(n990), 
        .Y(n320) );
  OAI2B2X1 U828 ( .A1N(handoff_code_phase[10]), .A0(n821), .B0(n826), .B1(n953), .Y(n384) );
  OAI2B2X1 U829 ( .A1N(N289), .A0(n808), .B0(n807), .B1(n953), .Y(n385) );
  OAI2B2X1 U830 ( .A1N(handoff_code_phase[2]), .A0(n822), .B0(n826), .B1(n945), 
        .Y(n376) );
  OAI2B2X1 U831 ( .A1N(handoff_code_phase[3]), .A0(n821), .B0(n826), .B1(n946), 
        .Y(n377) );
  OAI2B2X1 U832 ( .A1N(handoff_code_phase[4]), .A0(n822), .B0(n826), .B1(n947), 
        .Y(n378) );
  OAI2B2X1 U833 ( .A1N(handoff_code_phase[5]), .A0(n821), .B0(n826), .B1(n948), 
        .Y(n379) );
  OAI2B2X1 U834 ( .A1N(handoff_code_phase[9]), .A0(n822), .B0(n826), .B1(n952), 
        .Y(n383) );
  OAI2B2X1 U835 ( .A1N(N279), .A0(n808), .B0(n807), .B1(n944), .Y(n394) );
  OAI2B2X1 U836 ( .A1N(handoff_ms_count[9]), .A0(n822), .B0(n826), .B1(n991), 
        .Y(n322) );
  OAI2B2X1 U837 ( .A1N(handoff_ms_count[8]), .A0(n822), .B0(n826), .B1(n992), 
        .Y(n324) );
  OAI2B2X1 U838 ( .A1N(handoff_ms_count[7]), .A0(n822), .B0(n826), .B1(n993), 
        .Y(n326) );
  OAI2B2X1 U839 ( .A1N(handoff_ms_count[6]), .A0(n822), .B0(n826), .B1(n994), 
        .Y(n328) );
  OAI2B2X1 U840 ( .A1N(handoff_ms_count[5]), .A0(n822), .B0(n826), .B1(n995), 
        .Y(n330) );
  OAI2B2X1 U841 ( .A1N(handoff_ms_count[4]), .A0(n822), .B0(n826), .B1(n996), 
        .Y(n332) );
  OAI2B2X1 U842 ( .A1N(handoff_ms_count[3]), .A0(n822), .B0(n826), .B1(n997), 
        .Y(n334) );
  OAI2B2X1 U843 ( .A1N(handoff_ms_count[2]), .A0(n822), .B0(n826), .B1(n998), 
        .Y(n336) );
  OAI2B2X1 U844 ( .A1N(handoff_ms_count[1]), .A0(n822), .B0(n826), .B1(n999), 
        .Y(n338) );
  OAI2B2X1 U845 ( .A1N(handoff_sample_epoch[1]), .A0(n821), .B0(n984), .B1(
        n825), .Y(n343) );
  OAI2B2X1 U846 ( .A1N(handoff_sample_epoch[2]), .A0(n821), .B0(n983), .B1(
        n824), .Y(n344) );
  OAI2B2X1 U847 ( .A1N(handoff_sample_epoch[3]), .A0(n821), .B0(n982), .B1(
        n825), .Y(n345) );
  OAI2B2X1 U848 ( .A1N(handoff_sample_epoch[4]), .A0(n821), .B0(n981), .B1(
        n825), .Y(n346) );
  OAI2B2X1 U849 ( .A1N(handoff_sample_epoch[5]), .A0(n821), .B0(n980), .B1(
        n823), .Y(n347) );
  OAI2B2X1 U850 ( .A1N(handoff_sample_epoch[6]), .A0(n821), .B0(n979), .B1(
        n824), .Y(n348) );
  OAI2B2X1 U851 ( .A1N(handoff_sample_epoch[7]), .A0(n821), .B0(n978), .B1(
        n825), .Y(n349) );
  OAI2B2X1 U852 ( .A1N(handoff_sample_epoch[8]), .A0(n821), .B0(n977), .B1(
        n824), .Y(n350) );
  OAI2B2X1 U853 ( .A1N(handoff_sample_epoch[9]), .A0(n821), .B0(n976), .B1(
        n825), .Y(n351) );
  OAI2B2X1 U854 ( .A1N(handoff_sample_epoch[10]), .A0(n821), .B0(n975), .B1(
        n825), .Y(n352) );
  OAI2B2X1 U855 ( .A1N(handoff_sample_epoch[11]), .A0(n821), .B0(n974), .B1(
        n825), .Y(n353) );
  OAI2B2X1 U856 ( .A1N(handoff_sample_epoch[12]), .A0(n821), .B0(n973), .B1(
        n825), .Y(n354) );
  OAI2B2X1 U857 ( .A1N(handoff_sample_epoch[13]), .A0(n820), .B0(n972), .B1(
        n825), .Y(n355) );
  OAI2B2X1 U858 ( .A1N(handoff_sample_epoch[14]), .A0(n820), .B0(n971), .B1(
        n825), .Y(n356) );
  OAI2B2X1 U859 ( .A1N(handoff_sample_epoch[15]), .A0(n820), .B0(n970), .B1(
        n825), .Y(n357) );
  OAI2B2X1 U860 ( .A1N(handoff_sample_epoch[16]), .A0(n820), .B0(n969), .B1(
        n825), .Y(n358) );
  OAI2B2X1 U861 ( .A1N(handoff_sample_epoch[17]), .A0(n820), .B0(n968), .B1(
        n825), .Y(n359) );
  OAI2B2X1 U862 ( .A1N(handoff_sample_epoch[18]), .A0(n820), .B0(n967), .B1(
        n825), .Y(n360) );
  OAI2B2X1 U863 ( .A1N(handoff_sample_epoch[19]), .A0(n820), .B0(n966), .B1(
        n825), .Y(n361) );
  OAI2B2X1 U864 ( .A1N(handoff_sample_epoch[20]), .A0(n820), .B0(n965), .B1(
        n825), .Y(n362) );
  OAI2B2X1 U865 ( .A1N(handoff_sample_epoch[21]), .A0(n820), .B0(n964), .B1(
        n825), .Y(n363) );
  OAI2B2X1 U866 ( .A1N(handoff_sample_epoch[22]), .A0(n820), .B0(n963), .B1(
        n825), .Y(n364) );
  OAI2B2X1 U867 ( .A1N(handoff_sample_epoch[23]), .A0(n820), .B0(n962), .B1(
        n825), .Y(n365) );
  OAI2B2X1 U868 ( .A1N(handoff_sample_epoch[24]), .A0(n820), .B0(n961), .B1(
        n825), .Y(n366) );
  OAI2B2X1 U869 ( .A1N(handoff_sample_epoch[25]), .A0(n820), .B0(n960), .B1(
        n826), .Y(n367) );
  OAI2B2X1 U870 ( .A1N(handoff_sample_epoch[26]), .A0(n820), .B0(n959), .B1(
        n825), .Y(n368) );
  OAI2B2X1 U871 ( .A1N(handoff_sample_epoch[27]), .A0(n820), .B0(n958), .B1(
        n824), .Y(n369) );
  OAI2B2X1 U872 ( .A1N(handoff_sample_epoch[28]), .A0(n821), .B0(n957), .B1(
        n824), .Y(n370) );
  OAI2B2X1 U873 ( .A1N(handoff_sample_epoch[29]), .A0(n822), .B0(n956), .B1(
        n824), .Y(n371) );
  OAI2B2X1 U874 ( .A1N(handoff_sample_epoch[30]), .A0(n821), .B0(n955), .B1(
        n824), .Y(n372) );
  OAI2B2X1 U875 ( .A1N(handoff_code_phase[0]), .A0(n821), .B0(n826), .B1(n944), 
        .Y(n374) );
  OAI2B2X1 U876 ( .A1N(handoff_ms_count[0]), .A0(n821), .B0(n826), .B1(
        completed_ms_count[0]), .Y(n340) );
  OAI2B2X1 U877 ( .A1N(handoff_code_phase[1]), .A0(n822), .B0(n826), .B1(n943), 
        .Y(n375) );
  OAI2B2X1 U878 ( .A1N(handoff_code_phase[6]), .A0(n821), .B0(n826), .B1(n949), 
        .Y(n380) );
  OAI2B2X1 U879 ( .A1N(handoff_sample_epoch[0]), .A0(n821), .B0(
        accepted_sample_count[0]), .B1(n825), .Y(n342) );
  OAI2B2X1 U880 ( .A1N(handoff_code_phase[7]), .A0(n822), .B0(n826), .B1(n950), 
        .Y(n381) );
  OAI2B2X1 U881 ( .A1N(handoff_code_phase[8]), .A0(n821), .B0(n826), .B1(n951), 
        .Y(n382) );
  NOR3BX1 U882 ( .AN(n171), .B(capture), .C(n809), .Y(N394) );
  INVX2 U883 ( .A(i_next[23]), .Y(n832) );
  INVX2 U884 ( .A(q_next[23]), .Y(n830) );
  OAI2BB2X2 U885 ( .B0(n809), .B1(n861), .A0N(metric_debug[20]), .A1N(n810), 
        .Y(n400) );
  OAI2BB2X2 U886 ( .B0(n809), .B1(n864), .A0N(metric_debug[17]), .A1N(n810), 
        .Y(n403) );
  OAI2BB2X2 U887 ( .B0(n809), .B1(n860), .A0N(metric_debug[21]), .A1N(n810), 
        .Y(n399) );
  OAI2BB2X2 U888 ( .B0(n809), .B1(n863), .A0N(metric_debug[18]), .A1N(n810), 
        .Y(n402) );
  OAI2BB2X2 U889 ( .B0(n809), .B1(n862), .A0N(metric_debug[19]), .A1N(n810), 
        .Y(n401) );
  BUFX2 U890 ( .A(n166), .Y(n808) );
  OAI31X1 U891 ( .A0(n168), .A1(n169), .A2(n170), .B0(n807), .Y(n166) );
  NAND3XL U892 ( .A(search_phase[4]), .B(search_phase[3]), .C(search_phase[5]), 
        .Y(n170) );
  NAND3XL U893 ( .A(search_phase[0]), .B(n943), .C(search_phase[2]), .Y(n169)
         );
  AO22X2 U894 ( .A0(N70), .A1(code), .B0(N53), .B1(n912), .Y(mix_i[2]) );
  AO22X2 U895 ( .A0(N71), .A1(code), .B0(N54), .B1(n912), .Y(mix_i[3]) );
  AO22X2 U896 ( .A0(N78), .A1(code), .B0(N61), .B1(n912), .Y(mix_q[2]) );
  AO22X2 U897 ( .A0(N72), .A1(code), .B0(N55), .B1(n912), .Y(mix_i[4]) );
  AO22X2 U898 ( .A0(N79), .A1(code), .B0(N62), .B1(n912), .Y(mix_q[3]) );
  AO22X2 U899 ( .A0(N73), .A1(code), .B0(N56), .B1(n912), .Y(mix_i[5]) );
  AO22X2 U900 ( .A0(N80), .A1(code), .B0(N63), .B1(n912), .Y(mix_q[4]) );
  AO22X2 U901 ( .A0(N74), .A1(code), .B0(N57), .B1(n912), .Y(mix_i[6]) );
  AO22X2 U902 ( .A0(N81), .A1(code), .B0(N64), .B1(n912), .Y(mix_q[5]) );
  AO22X2 U903 ( .A0(N82), .A1(code), .B0(N65), .B1(n912), .Y(mix_q[6]) );
  AO22X2 U904 ( .A0(N69), .A1(code), .B0(N52), .B1(n912), .Y(mix_i[1]) );
  AO22X2 U905 ( .A0(N77), .A1(code), .B0(N60), .B1(n912), .Y(mix_q[1]) );
  BUFX2 U906 ( .A(n167), .Y(n807) );
  NOR3X1 U907 ( .A(n809), .B(capture), .C(n171), .Y(n167) );
  AO22X2 U908 ( .A0(n801), .A1(metric_next[23]), .B0(metric_debug[23]), .B1(
        n810), .Y(n397) );
  AO22X2 U909 ( .A0(n307), .A1(metric_next[22]), .B0(metric_debug[22]), .B1(
        n810), .Y(n398) );
  AO21X2 U910 ( .A0(n171), .A1(n800), .B0(capture), .Y(n396) );
  OR2X2 U911 ( .A(handoff_valid), .B(n822), .Y(n238) );
  OAI2BB2X2 U912 ( .B0(n809), .B1(n865), .A0N(metric_debug[16]), .A1N(n810), 
        .Y(n404) );
  INVX2 U913 ( .A(code_index_sum[0]), .Y(N17) );
  AO22X2 U914 ( .A0(n800), .A1(metric_next[15]), .B0(metric_debug[15]), .B1(
        n810), .Y(n405) );
  AO22X2 U915 ( .A0(n801), .A1(metric_next[14]), .B0(metric_debug[14]), .B1(
        n810), .Y(n406) );
  AO22X2 U916 ( .A0(n307), .A1(metric_next[13]), .B0(metric_debug[13]), .B1(
        n810), .Y(n407) );
  AO22X2 U917 ( .A0(metric_next[12]), .A1(n801), .B0(metric_debug[12]), .B1(
        n810), .Y(n408) );
  AO22X2 U918 ( .A0(metric_next[11]), .A1(n800), .B0(metric_debug[11]), .B1(
        n810), .Y(n409) );
  AO22X2 U919 ( .A0(metric_next[10]), .A1(n801), .B0(metric_debug[10]), .B1(
        n810), .Y(n410) );
  AO22X2 U920 ( .A0(metric_next[9]), .A1(n800), .B0(metric_debug[9]), .B1(n810), .Y(n411) );
  AO22X2 U921 ( .A0(metric_next[8]), .A1(n801), .B0(metric_debug[8]), .B1(n810), .Y(n412) );
  AO22X2 U922 ( .A0(metric_next[7]), .A1(n800), .B0(metric_debug[7]), .B1(n810), .Y(n413) );
  AO22X2 U923 ( .A0(metric_next[6]), .A1(n801), .B0(metric_debug[6]), .B1(n810), .Y(n414) );
  AO22X2 U924 ( .A0(metric_next[5]), .A1(n800), .B0(metric_debug[5]), .B1(n810), .Y(n415) );
  AO22X2 U925 ( .A0(metric_next[4]), .A1(n801), .B0(metric_debug[4]), .B1(n810), .Y(n416) );
  AO22X2 U926 ( .A0(metric_next[3]), .A1(n800), .B0(metric_debug[3]), .B1(n810), .Y(n417) );
  AO22X2 U927 ( .A0(metric_next[2]), .A1(n801), .B0(metric_debug[2]), .B1(n810), .Y(n418) );
  BUFX2 U928 ( .A(if_sample[3]), .Y(n797) );
  BUFX2 U929 ( .A(if_sample[0]), .Y(n796) );
  NOR2X2 U930 ( .A(local_cos[0]), .B(\carrier_phase[1] ), .Y(local_sin[2]) );
  NOR2X2 U931 ( .A(local_sin[0]), .B(\carrier_phase[1] ), .Y(local_cos[2]) );
  NOR2X2 U932 ( .A(n942), .B(local_sin[0]), .Y(local_cos[3]) );
  INVX2 U933 ( .A(local_sin[0]), .Y(local_cos[0]) );
  OAI2BB2X2 U934 ( .B0(n812), .B1(n866), .A0N(q_acc[22]), .A1N(n817), .Y(n240)
         );
  OAI2BB2X2 U935 ( .B0(n812), .B1(n867), .A0N(q_acc[21]), .A1N(n36), .Y(n241)
         );
  OAI2BB2X2 U936 ( .B0(n812), .B1(n868), .A0N(q_acc[20]), .A1N(n36), .Y(n242)
         );
  OAI2BB2X2 U937 ( .B0(n812), .B1(n869), .A0N(q_acc[19]), .A1N(n36), .Y(n243)
         );
  OAI2BB2X2 U938 ( .B0(n812), .B1(n870), .A0N(q_acc[18]), .A1N(n36), .Y(n244)
         );
  OAI2BB2X2 U939 ( .B0(n812), .B1(n871), .A0N(q_acc[17]), .A1N(n36), .Y(n245)
         );
  OAI2BB2X2 U940 ( .B0(n812), .B1(n872), .A0N(q_acc[16]), .A1N(n36), .Y(n246)
         );
  OAI2BB2X2 U941 ( .B0(n812), .B1(n873), .A0N(q_acc[15]), .A1N(n36), .Y(n247)
         );
  OAI2BB2X2 U942 ( .B0(n812), .B1(n874), .A0N(q_acc[14]), .A1N(n36), .Y(n248)
         );
  OAI2BB2X2 U943 ( .B0(n812), .B1(n875), .A0N(q_acc[13]), .A1N(n36), .Y(n249)
         );
  OAI2BB2X2 U944 ( .B0(n813), .B1(n889), .A0N(i_acc[22]), .A1N(n817), .Y(n264)
         );
  OAI2BB2X2 U945 ( .B0(n813), .B1(n890), .A0N(i_acc[21]), .A1N(n817), .Y(n265)
         );
  OAI2BB2X2 U946 ( .B0(n814), .B1(n891), .A0N(i_acc[20]), .A1N(n817), .Y(n266)
         );
  OAI2BB2X2 U947 ( .B0(n814), .B1(n892), .A0N(i_acc[19]), .A1N(n817), .Y(n267)
         );
  OAI2BB2X2 U948 ( .B0(n814), .B1(n893), .A0N(i_acc[18]), .A1N(n817), .Y(n268)
         );
  OAI2BB2X2 U949 ( .B0(n814), .B1(n894), .A0N(i_acc[17]), .A1N(n817), .Y(n269)
         );
  OAI2BB2X2 U950 ( .B0(n814), .B1(n895), .A0N(i_acc[16]), .A1N(n817), .Y(n270)
         );
  OAI2BB2X2 U951 ( .B0(n814), .B1(n896), .A0N(i_acc[15]), .A1N(n817), .Y(n271)
         );
  OAI2BB2X2 U952 ( .B0(n814), .B1(n897), .A0N(i_acc[14]), .A1N(n817), .Y(n272)
         );
  OAI2BB2X2 U953 ( .B0(n814), .B1(n898), .A0N(i_acc[13]), .A1N(n817), .Y(n273)
         );
  INVX2 U954 ( .A(\carrier_phase[1] ), .Y(n942) );
  AO2B2X2 U955 ( .B0(q_acc[23]), .B1(n817), .A0(n829), .A1N(n815), .Y(n239) );
  AO2B2X2 U956 ( .B0(i_acc[23]), .B1(n817), .A0(n831), .A1N(n815), .Y(n263) );
  AO22X2 U957 ( .A0(metric_next[1]), .A1(n307), .B0(metric_debug[1]), .B1(n810), .Y(n419) );
  OAI2BB2X2 U958 ( .B0(n812), .B1(n876), .A0N(q_acc[12]), .A1N(n36), .Y(n250)
         );
  OAI2BB2X2 U959 ( .B0(n813), .B1(n877), .A0N(q_acc[11]), .A1N(n817), .Y(n251)
         );
  OAI2BB2X2 U960 ( .B0(n813), .B1(n878), .A0N(q_acc[10]), .A1N(n36), .Y(n252)
         );
  OAI2BB2X2 U961 ( .B0(n813), .B1(n879), .A0N(q_acc[9]), .A1N(n816), .Y(n253)
         );
  OAI2BB2X2 U962 ( .B0(n813), .B1(n880), .A0N(q_acc[8]), .A1N(n816), .Y(n254)
         );
  OAI2BB2X2 U963 ( .B0(n813), .B1(n881), .A0N(q_acc[7]), .A1N(n816), .Y(n255)
         );
  OAI2BB2X2 U964 ( .B0(n813), .B1(n882), .A0N(q_acc[6]), .A1N(n816), .Y(n256)
         );
  OAI2BB2X2 U965 ( .B0(n813), .B1(n883), .A0N(q_acc[5]), .A1N(n36), .Y(n257)
         );
  OAI2BB2X2 U966 ( .B0(n813), .B1(n884), .A0N(q_acc[4]), .A1N(n36), .Y(n258)
         );
  OAI2BB2X2 U967 ( .B0(n813), .B1(n885), .A0N(q_acc[3]), .A1N(n36), .Y(n259)
         );
  OAI2BB2X2 U968 ( .B0(n813), .B1(n886), .A0N(q_acc[2]), .A1N(n36), .Y(n260)
         );
  OAI2BB2X2 U969 ( .B0(n813), .B1(n887), .A0N(q_acc[1]), .A1N(n36), .Y(n261)
         );
  OAI2BB2X2 U970 ( .B0(n814), .B1(n899), .A0N(i_acc[12]), .A1N(n817), .Y(n274)
         );
  OAI2BB2X2 U971 ( .B0(n814), .B1(n900), .A0N(i_acc[11]), .A1N(n817), .Y(n275)
         );
  OAI2BB2X2 U972 ( .B0(n814), .B1(n901), .A0N(i_acc[10]), .A1N(n817), .Y(n276)
         );
  OAI2BB2X2 U973 ( .B0(n814), .B1(n902), .A0N(i_acc[9]), .A1N(n817), .Y(n277)
         );
  OAI2BB2X2 U974 ( .B0(n814), .B1(n903), .A0N(i_acc[8]), .A1N(n817), .Y(n278)
         );
  OAI2BB2X2 U975 ( .B0(n815), .B1(n904), .A0N(i_acc[7]), .A1N(n817), .Y(n279)
         );
  OAI2BB2X2 U976 ( .B0(n814), .B1(n905), .A0N(i_acc[6]), .A1N(n817), .Y(n280)
         );
  OAI2BB2X2 U977 ( .B0(n815), .B1(n906), .A0N(i_acc[5]), .A1N(n817), .Y(n281)
         );
  OAI2BB2X2 U978 ( .B0(n815), .B1(n907), .A0N(i_acc[4]), .A1N(n817), .Y(n282)
         );
  OAI2BB2X2 U979 ( .B0(n815), .B1(n908), .A0N(i_acc[3]), .A1N(n817), .Y(n283)
         );
  OAI2BB2X2 U980 ( .B0(n815), .B1(n909), .A0N(i_acc[2]), .A1N(n817), .Y(n284)
         );
  OAI2BB2X2 U981 ( .B0(n815), .B1(n910), .A0N(i_acc[1]), .A1N(n817), .Y(n285)
         );
  OAI2BB2X2 U982 ( .B0(n815), .B1(n911), .A0N(i_acc[0]), .A1N(n817), .Y(n286)
         );
  OAI2BB2X2 U983 ( .B0(n813), .B1(n888), .A0N(q_acc[0]), .A1N(n36), .Y(n262)
         );
  INVX2 U984 ( .A(N169), .Y(n954) );
  BUFX2 U985 ( .A(n181), .Y(n806) );
  OAI31X1 U986 ( .A0(n191), .A1(n929), .A2(n930), .B0(n809), .Y(n181) );
  NAND3XL U987 ( .A(n818), .B(n192), .C(chip_sample_cnt[0]), .Y(n191) );
  NAND4X2 U988 ( .A(n308), .B(chip_idx[9]), .C(n193), .D(n194), .Y(n192) );
  NOR4X2 U989 ( .A(sample_cnt[4]), .B(sample_cnt[14]), .C(n915), .D(n924), .Y(
        n201) );
  OAI32XL U990 ( .A0(n117), .A1(chip_sample_cnt[2]), .A2(n811), .B0(n118), 
        .B1(n930), .Y(n289) );
  NAND2X2 U991 ( .A(chip_sample_cnt[1]), .B(chip_sample_cnt[0]), .Y(n117) );
  AOI21BX2 U992 ( .A0(n120), .A1(n929), .B0N(n122), .Y(n118) );
  OAI32XL U993 ( .A0(n928), .A1(chip_sample_cnt[1]), .A2(n811), .B0(n122), 
        .B1(n929), .Y(n290) );
  OAI2B2X1 U994 ( .A1N(accepted_sample_count[31]), .A0(n819), .B0(n36), .B1(
        n954), .Y(n206) );
  OAI2B2X1 U995 ( .A1N(N203), .A0(n179), .B0(n940), .B1(n806), .Y(n430) );
  INVX2 U996 ( .A(chip_idx[10]), .Y(n940) );
  OAI2B2X1 U997 ( .A1N(N202), .A0(n179), .B0(n939), .B1(n806), .Y(n421) );
  INVX2 U998 ( .A(chip_idx[9]), .Y(n939) );
  OAI2B2X1 U999 ( .A1N(N195), .A0(n179), .B0(n932), .B1(n806), .Y(n428) );
  INVX2 U1000 ( .A(chip_idx[2]), .Y(n932) );
  OAI2B2X1 U1001 ( .A1N(N193), .A0(n179), .B0(n931), .B1(n806), .Y(n431) );
  INVX2 U1002 ( .A(chip_idx[0]), .Y(n931) );
  OAI2B2X1 U1003 ( .A1N(N174), .A0(n811), .B0(n819), .B1(n915), .Y(n306) );
  OAI2B2X1 U1004 ( .A1N(accepted_sample_count[30]), .A0(n819), .B0(n36), .B1(
        n955), .Y(n207) );
  OAI2B2X1 U1005 ( .A1N(accepted_sample_count[29]), .A0(n819), .B0(n36), .B1(
        n956), .Y(n208) );
  OAI2B2X1 U1006 ( .A1N(accepted_sample_count[28]), .A0(n819), .B0(n36), .B1(
        n957), .Y(n209) );
  OAI2B2X1 U1007 ( .A1N(accepted_sample_count[27]), .A0(n819), .B0(n36), .B1(
        n958), .Y(n210) );
  OAI2B2X1 U1008 ( .A1N(accepted_sample_count[26]), .A0(n819), .B0(n36), .B1(
        n959), .Y(n211) );
  OAI2B2X1 U1009 ( .A1N(accepted_sample_count[25]), .A0(n819), .B0(n36), .B1(
        n960), .Y(n212) );
  OAI2B2X1 U1010 ( .A1N(accepted_sample_count[24]), .A0(n819), .B0(n36), .B1(
        n961), .Y(n213) );
  OAI2B2X1 U1011 ( .A1N(accepted_sample_count[23]), .A0(n819), .B0(n36), .B1(
        n962), .Y(n214) );
  OAI2B2X1 U1012 ( .A1N(accepted_sample_count[22]), .A0(n819), .B0(n36), .B1(
        n963), .Y(n215) );
  OAI2B2X1 U1013 ( .A1N(accepted_sample_count[21]), .A0(n819), .B0(n36), .B1(
        n964), .Y(n216) );
  OAI2B2X1 U1014 ( .A1N(accepted_sample_count[20]), .A0(n819), .B0(n36), .B1(
        n965), .Y(n217) );
  OAI2B2X1 U1015 ( .A1N(accepted_sample_count[19]), .A0(n819), .B0(n36), .B1(
        n966), .Y(n218) );
  OAI2B2X1 U1016 ( .A1N(accepted_sample_count[18]), .A0(n819), .B0(n36), .B1(
        n967), .Y(n219) );
  OAI2B2X1 U1017 ( .A1N(accepted_sample_count[17]), .A0(n819), .B0(n36), .B1(
        n968), .Y(n220) );
  OAI2B2X1 U1018 ( .A1N(accepted_sample_count[16]), .A0(n819), .B0(n817), .B1(
        n969), .Y(n221) );
  OAI2B2X1 U1019 ( .A1N(accepted_sample_count[15]), .A0(n819), .B0(n36), .B1(
        n970), .Y(n222) );
  OAI2B2X1 U1020 ( .A1N(accepted_sample_count[14]), .A0(n819), .B0(n36), .B1(
        n971), .Y(n223) );
  OAI2B2X1 U1021 ( .A1N(accepted_sample_count[13]), .A0(n819), .B0(n36), .B1(
        n972), .Y(n224) );
  OAI2B2X1 U1022 ( .A1N(accepted_sample_count[12]), .A0(n819), .B0(n817), .B1(
        n973), .Y(n225) );
  OAI2B2X1 U1023 ( .A1N(accepted_sample_count[11]), .A0(n819), .B0(n36), .B1(
        n974), .Y(n226) );
  OAI2B2X1 U1024 ( .A1N(accepted_sample_count[10]), .A0(n819), .B0(n817), .B1(
        n975), .Y(n227) );
  OAI2B2X1 U1025 ( .A1N(accepted_sample_count[9]), .A0(n819), .B0(n817), .B1(
        n976), .Y(n228) );
  OAI2B2X1 U1026 ( .A1N(accepted_sample_count[8]), .A0(n819), .B0(n817), .B1(
        n977), .Y(n229) );
  OAI2B2X1 U1027 ( .A1N(accepted_sample_count[7]), .A0(n819), .B0(n817), .B1(
        n978), .Y(n230) );
  OAI2B2X1 U1028 ( .A1N(accepted_sample_count[6]), .A0(n819), .B0(n817), .B1(
        n979), .Y(n231) );
  OAI2B2X1 U1029 ( .A1N(accepted_sample_count[5]), .A0(n819), .B0(n817), .B1(
        n980), .Y(n232) );
  OAI2B2X1 U1030 ( .A1N(accepted_sample_count[4]), .A0(n819), .B0(n817), .B1(
        n981), .Y(n233) );
  OAI2B2X1 U1031 ( .A1N(accepted_sample_count[3]), .A0(n819), .B0(n817), .B1(
        n982), .Y(n234) );
  OAI2B2X1 U1032 ( .A1N(accepted_sample_count[2]), .A0(n819), .B0(n817), .B1(
        n983), .Y(n235) );
  OAI2B2X1 U1033 ( .A1N(accepted_sample_count[1]), .A0(n819), .B0(n817), .B1(
        n984), .Y(n236) );
  OAI2B2X1 U1034 ( .A1N(accepted_sample_count[0]), .A0(n819), .B0(n817), .B1(
        accepted_sample_count[0]), .Y(n237) );
  OAI22X1 U1035 ( .A0(n819), .A1(n928), .B0(chip_sample_cnt[0]), .B1(n811), 
        .Y(n291) );
  OAI2B2X1 U1036 ( .A1N(N194), .A0(n179), .B0(n308), .B1(n806), .Y(n429) );
  INVX2 U1037 ( .A(N224), .Y(n985) );
  OAI2BB2X2 U1038 ( .B0(n809), .B1(n985), .A0N(completed_ms_count[15]), .A1N(
        n810), .Y(n311) );
  OAI2BB2X2 U1039 ( .B0(n809), .B1(n986), .A0N(completed_ms_count[14]), .A1N(
        n810), .Y(n313) );
  OAI2BB2X2 U1040 ( .B0(n809), .B1(n987), .A0N(completed_ms_count[13]), .A1N(
        n810), .Y(n315) );
  OAI2BB2X2 U1041 ( .B0(n809), .B1(n988), .A0N(completed_ms_count[12]), .A1N(
        n810), .Y(n317) );
  OAI2BB2X2 U1042 ( .B0(n809), .B1(n989), .A0N(completed_ms_count[11]), .A1N(
        n810), .Y(n319) );
  OAI2BB2X2 U1043 ( .B0(n809), .B1(n990), .A0N(completed_ms_count[10]), .A1N(
        n810), .Y(n321) );
  OAI2BB2X2 U1044 ( .B0(n809), .B1(n991), .A0N(completed_ms_count[9]), .A1N(
        n810), .Y(n323) );
  OAI2BB2X2 U1045 ( .B0(n809), .B1(n992), .A0N(completed_ms_count[8]), .A1N(
        n810), .Y(n325) );
  OAI2BB2X2 U1046 ( .B0(n809), .B1(n993), .A0N(completed_ms_count[7]), .A1N(
        n810), .Y(n327) );
  OAI2BB2X2 U1047 ( .B0(n809), .B1(n994), .A0N(completed_ms_count[6]), .A1N(
        n810), .Y(n329) );
  OAI2BB2X2 U1048 ( .B0(n809), .B1(n995), .A0N(completed_ms_count[5]), .A1N(
        n810), .Y(n331) );
  OAI2BB2X2 U1049 ( .B0(n809), .B1(n996), .A0N(completed_ms_count[4]), .A1N(
        n810), .Y(n333) );
  OAI2BB2X2 U1050 ( .B0(n809), .B1(n997), .A0N(completed_ms_count[3]), .A1N(
        n810), .Y(n335) );
  OAI2BB2X2 U1051 ( .B0(n809), .B1(n998), .A0N(completed_ms_count[2]), .A1N(
        n810), .Y(n337) );
  OAI2BB2X2 U1052 ( .B0(n809), .B1(n999), .A0N(completed_ms_count[1]), .A1N(
        n810), .Y(n339) );
  OAI2BB2X2 U1053 ( .B0(n809), .B1(completed_ms_count[0]), .A0N(
        completed_ms_count[0]), .A1N(n810), .Y(n341) );
  NAND2X2 U1054 ( .A(if_valid), .B(enable), .Y(n36) );
  INVX2 U1055 ( .A(n116), .Y(n913) );
  AOI221XL U1056 ( .A0(n817), .A1(\carrier_phase[1] ), .B0(n819), .B1(
        local_sin[2]), .C0(local_cos[3]), .Y(n116) );
  AO2B2X2 U1057 ( .B0(n817), .B1(sample_cnt[14]), .A0(N188), .A1N(n815), .Y(
        n292) );
  AO2B2X2 U1058 ( .B0(n817), .B1(sample_cnt[4]), .A0(N178), .A1N(n815), .Y(
        n302) );
  INVX2 U1059 ( .A(sample_cnt[0]), .Y(n915) );
  INVX2 U1060 ( .A(sample_cnt[8]), .Y(n922) );
  INVX2 U1061 ( .A(sample_cnt[9]), .Y(n923) );
  INVX2 U1062 ( .A(sample_cnt[5]), .Y(n919) );
  INVX2 U1063 ( .A(sample_cnt[13]), .Y(n927) );
  INVX2 U1064 ( .A(sample_cnt[7]), .Y(n921) );
  INVX2 U1065 ( .A(sample_cnt[3]), .Y(n918) );
  INVX2 U1066 ( .A(sample_cnt[12]), .Y(n926) );
  INVX2 U1067 ( .A(sample_cnt[2]), .Y(n917) );
  INVX2 U1068 ( .A(sample_cnt[11]), .Y(n925) );
  INVX2 U1069 ( .A(sample_cnt[10]), .Y(n924) );
  INVX2 U1070 ( .A(sample_cnt[6]), .Y(n920) );
  INVX2 U1071 ( .A(sample_cnt[1]), .Y(n916) );
  NOR4X2 U1072 ( .A(n195), .B(n935), .C(n933), .D(n934), .Y(n194) );
  NAND3XL U1073 ( .A(chip_idx[10]), .B(chip_idx[0]), .C(chip_idx[2]), .Y(n195)
         );
  NAND3XL U1074 ( .A(search_phase[10]), .B(search_phase[9]), .C(n172), .Y(n168) );
  NOR3X1 U1075 ( .A(n951), .B(n949), .C(n950), .Y(n172) );
  INVX2 U1076 ( .A(search_phase[0]), .Y(n944) );
  INVX2 U1077 ( .A(chip_sample_cnt[0]), .Y(n928) );
  INVX2 U1078 ( .A(chip_idx[7]), .Y(n937) );
  INVX2 U1079 ( .A(chip_idx[8]), .Y(n938) );
  INVX2 U1080 ( .A(chip_idx[3]), .Y(n933) );
  INVX2 U1081 ( .A(chip_idx[6]), .Y(n936) );
  INVX2 U1082 ( .A(chip_idx[5]), .Y(n935) );
  INVX2 U1083 ( .A(chip_idx[4]), .Y(n934) );
  INVX2 U1084 ( .A(search_phase[5]), .Y(n948) );
  INVX2 U1085 ( .A(search_phase[2]), .Y(n945) );
  INVX2 U1086 ( .A(search_phase[9]), .Y(n952) );
  INVX2 U1087 ( .A(search_phase[3]), .Y(n946) );
  INVX2 U1088 ( .A(search_phase[4]), .Y(n947) );
  INVX2 U1089 ( .A(search_phase[10]), .Y(n953) );
  INVX2 U1090 ( .A(chip_sample_cnt[1]), .Y(n929) );
  INVX2 U1091 ( .A(chip_sample_cnt[2]), .Y(n930) );
  NOR2X1 U1092 ( .A(n773), .B(N18), .Y(n642) );
  NOR2X1 U1093 ( .A(n727), .B(n724), .Y(n655) );
  NOR2X1 U1094 ( .A(N21), .B(n724), .Y(n664) );
  NOR2X1 U1095 ( .A(n664), .B(N20), .Y(n525) );
  NOR2X1 U1096 ( .A(n655), .B(n525), .Y(n602) );
  NOR2X1 U1097 ( .A(n724), .B(N20), .Y(n571) );
  NOR2X1 U1098 ( .A(n727), .B(n734), .Y(n568) );
  NOR2X1 U1099 ( .A(n571), .B(n568), .Y(n670) );
  NOR2X1 U1100 ( .A(code_index_sum[0]), .B(N22), .Y(n700) );
  NOR2X1 U1101 ( .A(n734), .B(n724), .Y(n661) );
  NOR2X1 U1102 ( .A(n727), .B(n661), .Y(n585) );
  AOI222XL U1103 ( .A0(n731), .A1(n784), .B0(n766), .B1(n787), .C0(n785), .C1(
        n585), .Y(n445) );
  NOR2X1 U1104 ( .A(n664), .B(n585), .Y(n660) );
  NOR2X1 U1105 ( .A(n734), .B(N19), .Y(n681) );
  NOR2X1 U1106 ( .A(n723), .B(N23), .Y(n644) );
  AOI31X1 U1107 ( .A0(n785), .A1(n744), .A2(n751), .B0(n770), .Y(n440) );
  CLKNAND2X2 U1108 ( .A(n575), .B(n752), .Y(n553) );
  CLKNAND2X2 U1109 ( .A(N20), .B(n575), .Y(n460) );
  NOR2X1 U1110 ( .A(n761), .B(n739), .Y(n501) );
  NOR2X1 U1111 ( .A(n739), .B(n571), .Y(n574) );
  AOI2BB2X1 U1112 ( .B0(n765), .B1(n784), .A0N(n574), .A1N(n789), .Y(n439) );
  OAI211XL U1113 ( .A0(n750), .A1(n791), .B0(n440), .C0(n439), .Y(n444) );
  NOR2X1 U1114 ( .A(N20), .B(n752), .Y(n584) );
  CLKNAND2X2 U1115 ( .A(N20), .B(n664), .Y(n604) );
  AOI2BB1X1 U1116 ( .A0N(n604), .A1N(N17), .B0(n795), .Y(n442) );
  NOR2X1 U1117 ( .A(N18), .B(N23), .Y(n687) );
  NOR2X1 U1118 ( .A(n727), .B(n681), .Y(n551) );
  CLKNAND2X2 U1119 ( .A(n575), .B(n743), .Y(n679) );
  NOR2X1 U1120 ( .A(n727), .B(n664), .Y(n657) );
  NOR2X1 U1121 ( .A(n681), .B(n657), .Y(n659) );
  AOI22XL U1122 ( .A0(n679), .A1(n786), .B0(n742), .B1(n784), .Y(n441) );
  OAI211XL U1123 ( .A0(n584), .A1(n442), .B0(n687), .C0(n441), .Y(n443) );
  OAI211XL U1124 ( .A0(n775), .A1(n445), .B0(n444), .C0(n443), .Y(n449) );
  CLKNAND2X2 U1125 ( .A(n664), .B(n727), .Y(n682) );
  NOR3X1 U1126 ( .A(n792), .B(n682), .C(n775), .Y(n458) );
  OAI21X1 U1127 ( .A0(N17), .A1(n682), .B0(n793), .Y(n447) );
  NOR2X1 U1128 ( .A(n727), .B(n553), .Y(n651) );
  NOR2X1 U1129 ( .A(n661), .B(N20), .Y(n610) );
  CLKNAND2X2 U1130 ( .A(n743), .B(n748), .Y(n497) );
  OAI22X1 U1131 ( .A0(n497), .A1(n780), .B0(n765), .B1(n789), .Y(n446) );
  NOR2X1 U1132 ( .A(n773), .B(n723), .Y(n519) );
  AOI211X1 U1133 ( .A0(n447), .A1(n760), .B0(n446), .C0(n774), .Y(n448) );
  CLKNAND2X2 U1134 ( .A(N25), .B(N24), .Y(n718) );
  OAI31X1 U1135 ( .A0(n449), .A1(n458), .A2(n448), .B0(n777), .Y(n549) );
  CLKNAND2X2 U1136 ( .A(N25), .B(n776), .Y(n598) );
  NOR2X1 U1137 ( .A(n727), .B(n744), .Y(n631) );
  CLKNAND2X2 U1138 ( .A(n727), .B(n734), .Y(n524) );
  CLKNAND2X2 U1139 ( .A(n746), .B(n524), .Y(n627) );
  NOR2X1 U1140 ( .A(n727), .B(n752), .Y(n515) );
  CLKNAND2X2 U1141 ( .A(n754), .B(n524), .Y(n607) );
  AOI222XL U1142 ( .A0(n627), .A1(n784), .B0(n497), .B1(n786), .C0(n785), .C1(
        n755), .Y(n451) );
  NOR2X1 U1143 ( .A(n761), .B(N20), .Y(n533) );
  NOR2X1 U1144 ( .A(n568), .B(n533), .Y(n693) );
  NOR2X1 U1145 ( .A(n727), .B(N19), .Y(n532) );
  CLKNAND2X2 U1146 ( .A(n761), .B(n727), .Y(n565) );
  CLKNAND2X2 U1147 ( .A(n754), .B(n565), .Y(n498) );
  AOI222XL U1148 ( .A0(N22), .A1(n693), .B0(n532), .B1(n786), .C0(n498), .C1(
        n795), .Y(n450) );
  OAI22X1 U1149 ( .A0(n775), .A1(n451), .B0(n450), .B1(n770), .Y(n459) );
  NOR2X1 U1150 ( .A(n553), .B(n657), .Y(n474) );
  OAI2BB1X1 U1151 ( .A0N(n682), .A1N(n746), .B0(N22), .Y(n452) );
  OAI21X1 U1152 ( .A0(N22), .A1(n759), .B0(n452), .Y(n472) );
  NAND2BX1 U1153 ( .AN(n533), .B(n460), .Y(n561) );
  AOI32XL U1154 ( .A0(n743), .A1(n732), .A2(n795), .B0(n785), .B1(n561), .Y(
        n453) );
  OAI211XL U1155 ( .A0(n472), .A1(code_index_sum[0]), .B0(n687), .C0(n453), 
        .Y(n457) );
  CLKNAND2X2 U1156 ( .A(n730), .B(n565), .Y(n637) );
  NOR2X1 U1157 ( .A(n727), .B(n575), .Y(n594) );
  CLKNAND2X2 U1158 ( .A(n575), .B(n727), .Y(n559) );
  NOR2X1 U1159 ( .A(n594), .B(n737), .Y(n593) );
  CLKNAND2X2 U1160 ( .A(n760), .B(n524), .Y(n633) );
  AOI21X1 U1161 ( .A0(n743), .A1(n524), .B0(n789), .Y(n454) );
  AOI221XL U1162 ( .A0(n738), .A1(n785), .B0(n633), .B1(n795), .C0(n454), .Y(
        n455) );
  OAI211XL U1163 ( .A0(n637), .A1(n780), .B0(n519), .C0(n455), .Y(n456) );
  NAND4BBX1 U1164 ( .AN(n459), .BN(n458), .C(n457), .D(n456), .Y(n486) );
  NOR2X1 U1165 ( .A(N24), .B(N25), .Y(n713) );
  CLKNAND2X2 U1166 ( .A(n743), .B(n565), .Y(n471) );
  AOI32XL U1167 ( .A0(n460), .A1(n744), .A2(N22), .B0(n471), .B1(n768), .Y(
        n461) );
  OAI22X1 U1168 ( .A0(n460), .A1(n768), .B0(N22), .B1(n757), .Y(n663) );
  AOI21X1 U1169 ( .A0(n461), .A1(N17), .B0(n663), .Y(n470) );
  NOR2X1 U1170 ( .A(n734), .B(N20), .Y(n626) );
  NOR2X1 U1171 ( .A(n626), .B(n515), .Y(n608) );
  AOI221XL U1172 ( .A0(n784), .A1(n748), .B0(n737), .B1(n795), .C0(n770), .Y(
        n462) );
  OAI221X1 U1173 ( .A0(n789), .A1(n608), .B0(n498), .B1(n435), .C0(n462), .Y(
        n469) );
  NOR2X1 U1174 ( .A(n584), .B(n655), .Y(n646) );
  NOR2X1 U1175 ( .A(n575), .B(N20), .Y(n603) );
  NOR2X1 U1176 ( .A(n651), .B(n603), .Y(n529) );
  AOI2BB2X1 U1177 ( .B0(n788), .B1(n646), .A0N(n529), .A1N(n435), .Y(n467) );
  AOI21X1 U1178 ( .A0(n735), .A1(n604), .B0(n783), .Y(n463) );
  AOI211X1 U1179 ( .A0(n795), .A1(n575), .B0(n771), .C0(n463), .Y(n466) );
  CLKNAND2X2 U1180 ( .A(n735), .B(n728), .Y(n534) );
  AOI2BB2X1 U1181 ( .B0(n742), .B1(n785), .A0N(n789), .A1N(n534), .Y(n465) );
  AOI221XL U1182 ( .A0(n679), .A1(n784), .B0(n568), .B1(n795), .C0(n774), .Y(
        n464) );
  AOI22XL U1183 ( .A0(n467), .A1(n466), .B0(n465), .B1(n464), .Y(n468) );
  OAI211XL U1184 ( .A0(n775), .A1(n470), .B0(n469), .C0(n468), .Y(n485) );
  NOR2X1 U1185 ( .A(n776), .B(N25), .Y(n711) );
  AOI222XL U1186 ( .A0(N17), .A1(n472), .B0(n795), .B1(n763), .C0(n785), .C1(
        n734), .Y(n483) );
  OAI22X1 U1187 ( .A0(N20), .A1(n789), .B0(n534), .B1(n791), .Y(n473) );
  AOI221XL U1188 ( .A0(n785), .A1(n631), .B0(n784), .B1(n551), .C0(n473), .Y(
        n482) );
  NOR2X1 U1189 ( .A(n553), .B(n551), .Y(n555) );
  NOR2X1 U1190 ( .A(n585), .B(n737), .Y(n694) );
  AOI22XL U1191 ( .A0(n758), .A1(n784), .B0(N17), .B1(n694), .Y(n480) );
  NOR2X1 U1192 ( .A(n681), .B(N20), .Y(n680) );
  NOR2X1 U1193 ( .A(n739), .B(n680), .Y(n647) );
  AOI221XL U1194 ( .A0(n785), .A1(n647), .B0(n795), .B1(n474), .C0(n770), .Y(
        n479) );
  NOR2X1 U1195 ( .A(n631), .B(n680), .Y(n530) );
  NOR2X1 U1196 ( .A(N20), .B(n744), .Y(n676) );
  OAI22X1 U1197 ( .A0(n782), .A1(n530), .B0(n745), .B1(n791), .Y(n477) );
  AOI21X1 U1198 ( .A0(n760), .A1(n725), .B0(n435), .Y(n476) );
  NOR2X1 U1199 ( .A(n761), .B(n727), .Y(n677) );
  AOI21X1 U1200 ( .A0(n752), .A1(n762), .B0(n789), .Y(n475) );
  NOR4X1 U1201 ( .A(n477), .B(n476), .C(n771), .D(n475), .Y(n478) );
  AOI21X1 U1202 ( .A0(n480), .A1(n479), .B0(n478), .Y(n481) );
  OAI221X1 U1203 ( .A0(n775), .A1(n483), .B0(n774), .B1(n482), .C0(n481), .Y(
        n484) );
  AOI222XL U1204 ( .A0(n778), .A1(n486), .B0(n713), .B1(n485), .C0(n711), .C1(
        n484), .Y(n548) );
  CLKNAND2X2 U1205 ( .A(n725), .B(n754), .Y(n583) );
  AOI222XL U1206 ( .A0(n784), .A1(n739), .B0(n749), .B1(n795), .C0(n583), .C1(
        n785), .Y(n495) );
  AOI221XL U1207 ( .A0(n571), .A1(N17), .B0(n787), .B1(n657), .C0(n774), .Y(
        n494) );
  NOR2X1 U1208 ( .A(n727), .B(N21), .Y(n652) );
  NOR2X1 U1209 ( .A(n652), .B(n603), .Y(n552) );
  OAI2BB2X1 U1210 ( .B0(n792), .B1(n594), .A0N(n552), .A1N(n786), .Y(n487) );
  AOI221XL U1211 ( .A0(n785), .A1(n501), .B0(n745), .B1(n784), .C0(n487), .Y(
        n489) );
  CLKNAND2X2 U1212 ( .A(n729), .B(n741), .Y(n499) );
  OAI32XL U1213 ( .A0(n435), .A1(n610), .A2(n739), .B0(n789), .B1(n660), .Y(
        n669) );
  AOI221XL U1214 ( .A0(n499), .A1(n795), .B0(n784), .B1(N21), .C0(n669), .Y(
        n488) );
  OAI22X1 U1215 ( .A0(n771), .A1(n489), .B0(n775), .B1(n488), .Y(n493) );
  OAI21X1 U1216 ( .A0(n532), .A1(n525), .B0(n795), .Y(n490) );
  OAI211XL U1217 ( .A0(n746), .A1(n789), .B0(n490), .C0(n644), .Y(n491) );
  AOI221XL U1218 ( .A0(n735), .A1(n785), .B0(n784), .B1(n724), .C0(n491), .Y(
        n492) );
  AOI211X1 U1219 ( .A0(n495), .A1(n494), .B0(n493), .C0(n492), .Y(n546) );
  OAI21X1 U1220 ( .A0(n525), .A1(n651), .B0(n788), .Y(n496) );
  OAI211XL U1221 ( .A0(n551), .A1(n791), .B0(n496), .C0(n644), .Y(n504) );
  NOR2X1 U1222 ( .A(n651), .B(n584), .Y(n572) );
  OAI2B2X1 U1223 ( .A1N(n497), .A0(n781), .B0(n435), .B1(n572), .Y(n503) );
  OAI22X1 U1224 ( .A0(n499), .A1(n789), .B0(n752), .B1(n791), .Y(n500) );
  AOI221XL U1225 ( .A0(n785), .A1(n501), .B0(n784), .B1(n764), .C0(n500), .Y(
        n502) );
  OAI22X1 U1226 ( .A0(n504), .A1(n503), .B0(n774), .B1(n502), .Y(n510) );
  CLKNAND2X2 U1227 ( .A(n745), .B(n604), .Y(n628) );
  NOR2X1 U1228 ( .A(n655), .B(n533), .Y(n605) );
  CLKNAND2X2 U1229 ( .A(n785), .B(n575), .Y(n516) );
  OAI211XL U1230 ( .A0(n791), .A1(n729), .B0(n687), .C0(n516), .Y(n505) );
  AOI221XL U1231 ( .A0(n628), .A1(n787), .B0(n784), .B1(n605), .C0(n505), .Y(
        n509) );
  NOR2X1 U1232 ( .A(n652), .B(n525), .Y(n678) );
  OAI22X1 U1233 ( .A0(n789), .A1(n678), .B0(n735), .B1(n791), .Y(n507) );
  AOI21X1 U1234 ( .A0(n733), .A1(n559), .B0(n435), .Y(n506) );
  NOR2X1 U1235 ( .A(n754), .B(n780), .Y(n595) );
  NOR4X1 U1236 ( .A(n507), .B(n506), .C(n595), .D(n775), .Y(n508) );
  OAI31X1 U1237 ( .A0(n510), .A1(n509), .A2(n508), .B0(n778), .Y(n545) );
  CLKNAND2X2 U1238 ( .A(n729), .B(n748), .Y(n635) );
  OAI22X1 U1239 ( .A0(n635), .A1(n789), .B0(n749), .B1(n791), .Y(n511) );
  AOI221XL U1240 ( .A0(n785), .A1(n755), .B0(n784), .B1(n738), .C0(n511), .Y(
        n523) );
  CLKNAND2X2 U1241 ( .A(n751), .B(n741), .Y(n649) );
  OAI2B2X1 U1242 ( .A1N(n605), .A0(n781), .B0(N17), .B1(n745), .Y(n512) );
  AOI221XL U1243 ( .A0(n649), .A1(n787), .B0(n628), .B1(n785), .C0(n512), .Y(
        n522) );
  NOR2X1 U1244 ( .A(N19), .B(N20), .Y(n675) );
  AOI21X1 U1245 ( .A0(n743), .A1(n726), .B0(n782), .Y(n513) );
  AOI31X1 U1246 ( .A0(n752), .A1(n743), .A2(n788), .B0(n513), .Y(n514) );
  OAI221X1 U1247 ( .A0(n756), .A1(n791), .B0(n435), .B1(n678), .C0(n514), .Y(
        n520) );
  NOR2X1 U1248 ( .A(n610), .B(n515), .Y(n634) );
  AOI22XL U1249 ( .A0(n787), .A1(N21), .B0(n784), .B1(n634), .Y(n518) );
  CLKNAND2X2 U1250 ( .A(n733), .B(n741), .Y(n674) );
  AOI221XL U1251 ( .A0(n674), .A1(n795), .B0(n769), .B1(n751), .C0(n770), .Y(
        n517) );
  AOI22XL U1252 ( .A0(n520), .A1(n519), .B0(n518), .B1(n517), .Y(n521) );
  OAI221X1 U1253 ( .A0(n771), .A1(n523), .B0(n775), .B1(n522), .C0(n521), .Y(
        n543) );
  CLKNAND2X2 U1254 ( .A(n524), .B(n728), .Y(n697) );
  NOR2X1 U1255 ( .A(n739), .B(n525), .Y(n566) );
  OAI22X1 U1256 ( .A0(n697), .A1(n780), .B0(n793), .B1(n566), .Y(n527) );
  AOI21X1 U1257 ( .A0(n728), .A1(n559), .B0(n789), .Y(n526) );
  AOI211X1 U1258 ( .A0(n571), .A1(n785), .B0(n527), .C0(n526), .Y(n541) );
  OAI22X1 U1259 ( .A0(n674), .A1(n789), .B0(n765), .B1(n791), .Y(n528) );
  AOI221XL U1260 ( .A0(n742), .A1(n785), .B0(n784), .B1(n529), .C0(n528), .Y(
        n540) );
  AOI22XL U1261 ( .A0(n787), .A1(n530), .B0(n785), .B1(n593), .Y(n538) );
  AOI21X1 U1262 ( .A0(n733), .A1(n725), .B0(n794), .Y(n531) );
  AOI211X1 U1263 ( .A0(n532), .A1(n784), .B0(n770), .C0(n531), .Y(n537) );
  AOI22XL U1264 ( .A0(n749), .A1(n784), .B0(N17), .B1(n631), .Y(n536) );
  AOI221XL U1265 ( .A0(n534), .A1(n795), .B0(n785), .B1(n533), .C0(n775), .Y(
        n535) );
  AOI22XL U1266 ( .A0(n538), .A1(n537), .B0(n536), .B1(n535), .Y(n539) );
  OAI221X1 U1267 ( .A0(n771), .A1(n541), .B0(n774), .B1(n540), .C0(n539), .Y(
        n542) );
  AOI22XL U1268 ( .A0(n543), .A1(n713), .B0(n542), .B1(n711), .Y(n544) );
  OAI211XL U1269 ( .A0(n718), .A1(n546), .B0(n545), .C0(n544), .Y(n547) );
  AOI32XL U1270 ( .A0(N26), .A1(n549), .A2(n548), .B0(n547), .B1(n779), .Y(
        n722) );
  OAI2BB2X1 U1271 ( .B0(n435), .B1(n646), .A0N(n594), .A1N(n784), .Y(n550) );
  AOI221XL U1272 ( .A0(n795), .A1(n551), .B0(n766), .B1(n786), .C0(n550), .Y(
        n557) );
  OAI22X1 U1273 ( .A0(n553), .A1(n789), .B0(n794), .B1(n552), .Y(n554) );
  AOI221XL U1274 ( .A0(n627), .A1(n785), .B0(n784), .B1(n555), .C0(n554), .Y(
        n556) );
  OAI221X1 U1275 ( .A0(n771), .A1(n557), .B0(n775), .B1(n556), .C0(n711), .Y(
        n624) );
  NOR2X1 U1276 ( .A(n610), .B(n652), .Y(n558) );
  OAI22X1 U1277 ( .A0(n739), .A1(n435), .B0(n789), .B1(n558), .Y(n564) );
  NOR2X1 U1278 ( .A(n781), .B(n559), .Y(n695) );
  OAI21X1 U1279 ( .A0(n655), .A1(n676), .B0(n785), .Y(n560) );
  OAI211XL U1280 ( .A0(n628), .A1(n791), .B0(n560), .C0(n644), .Y(n563) );
  OAI22X1 U1281 ( .A0(n782), .A1(n634), .B0(n561), .B1(n789), .Y(n562) );
  OAI32XL U1282 ( .A0(n564), .A1(n695), .A2(n774), .B0(n563), .B1(n562), .Y(
        n623) );
  CLKNAND2X2 U1283 ( .A(n729), .B(n565), .Y(n672) );
  OAI22X1 U1284 ( .A0(code_index_sum[0]), .A1(n763), .B0(n631), .B1(n780), .Y(
        n567) );
  AOI221XL U1285 ( .A0(n672), .A1(n795), .B0(n740), .B1(n785), .C0(n567), .Y(
        n582) );
  CLKNAND2X2 U1286 ( .A(n741), .B(n767), .Y(n701) );
  OAI22X1 U1287 ( .A0(n759), .A1(code_index_sum[0]), .B0(n780), .B1(n694), .Y(
        n569) );
  AOI221XL U1288 ( .A0(n795), .A1(n634), .B0(n701), .B1(n785), .C0(n569), .Y(
        n570) );
  OA21X1 U1289 ( .A0(n775), .A1(n570), .B0(n713), .Y(n581) );
  OAI21X1 U1290 ( .A0(n677), .A1(n571), .B0(n788), .Y(n579) );
  OAI21X1 U1291 ( .A0(N17), .A1(n740), .B0(n792), .Y(n573) );
  AOI22XL U1292 ( .A0(n573), .A1(n572), .B0(n784), .B1(n755), .Y(n578) );
  AOI22XL U1293 ( .A0(n795), .A1(n574), .B0(n785), .B1(n727), .Y(n577) );
  CLKNAND2X2 U1294 ( .A(n575), .B(n762), .Y(n699) );
  AOI221XL U1295 ( .A0(n699), .A1(N17), .B0(n784), .B1(n682), .C0(n771), .Y(
        n576) );
  AOI32XL U1296 ( .A0(n579), .A1(n644), .A2(n578), .B0(n577), .B1(n576), .Y(
        n580) );
  OAI211XL U1297 ( .A0(n774), .A1(n582), .B0(n581), .C0(n580), .Y(n622) );
  AOI31X1 U1298 ( .A0(n760), .A1(n732), .A2(n788), .B0(n775), .Y(n591) );
  OAI21X1 U1299 ( .A0(n652), .A1(n584), .B0(n795), .Y(n590) );
  AOI2BB2X1 U1300 ( .B0(n784), .B1(n767), .A0N(n435), .A1N(n583), .Y(n589) );
  NOR2X1 U1301 ( .A(n435), .B(n727), .Y(n703) );
  OR3X1 U1302 ( .A(n769), .B(n703), .C(n774), .Y(n587) );
  OAI32XL U1303 ( .A0(n585), .A1(n761), .A2(n780), .B0(n789), .B1(n584), .Y(
        n586) );
  AOI211X1 U1304 ( .A0(n602), .A1(code_index_sum[0]), .B0(n587), .C0(n586), 
        .Y(n588) );
  AOI31X1 U1305 ( .A0(n591), .A1(n590), .A2(n589), .B0(n588), .Y(n620) );
  OAI21X1 U1306 ( .A0(n626), .A1(n739), .B0(n784), .Y(n630) );
  AOI22XL U1307 ( .A0(n742), .A1(n795), .B0(n788), .B1(n743), .Y(n592) );
  OAI211XL U1308 ( .A0(n435), .A1(n593), .B0(n630), .C0(n592), .Y(n600) );
  OAI22X1 U1309 ( .A0(n435), .A1(n594), .B0(n735), .B1(n789), .Y(n597) );
  NOR3X1 U1310 ( .A(n791), .B(n739), .C(n661), .Y(n596) );
  NOR4X1 U1311 ( .A(n597), .B(n596), .C(n595), .D(n771), .Y(n599) );
  AOI211X1 U1312 ( .A0(n600), .A1(n644), .B0(n599), .C0(n598), .Y(n619) );
  OA22X1 U1313 ( .A0(n435), .A1(n649), .B0(n780), .B1(n674), .Y(n617) );
  AOI21X1 U1314 ( .A0(n728), .A1(n736), .B0(n789), .Y(n601) );
  AOI211X1 U1315 ( .A0(n610), .A1(n795), .B0(n770), .C0(n601), .Y(n616) );
  AOI22XL U1316 ( .A0(n785), .A1(n626), .B0(n784), .B1(n602), .Y(n615) );
  AOI221XL U1317 ( .A0(n750), .A1(n787), .B0(n603), .B1(n795), .C0(n771), .Y(
        n614) );
  CLKNAND2X2 U1318 ( .A(n736), .B(n604), .Y(n671) );
  OAI22X1 U1319 ( .A0(n789), .A1(n605), .B0(n681), .B1(n791), .Y(n606) );
  AOI221XL U1320 ( .A0(n671), .A1(n785), .B0(n607), .B1(n784), .C0(n606), .Y(
        n612) );
  OAI2BB2X1 U1321 ( .B0(n435), .B1(n608), .A0N(n637), .A1N(n784), .Y(n609) );
  AOI221XL U1322 ( .A0(n610), .A1(n787), .B0(n795), .B1(n694), .C0(n609), .Y(
        n611) );
  OAI221X1 U1323 ( .A0(n775), .A1(n612), .B0(n774), .B1(n611), .C0(n777), .Y(
        n613) );
  AOI221XL U1324 ( .A0(n617), .A1(n616), .B0(n615), .B1(n614), .C0(n613), .Y(
        n618) );
  AOI21X1 U1325 ( .A0(n620), .A1(n619), .B0(n618), .Y(n621) );
  OAI211XL U1326 ( .A0(n624), .A1(n623), .B0(n622), .C0(n621), .Y(n720) );
  AOI22XL U1327 ( .A0(n637), .A1(n795), .B0(n788), .B1(n659), .Y(n625) );
  OAI211XL U1328 ( .A0(n435), .A1(n626), .B0(n630), .C0(n625), .Y(n645) );
  AOI22XL U1329 ( .A0(n628), .A1(n795), .B0(n756), .B1(n786), .Y(n629) );
  OAI211XL U1330 ( .A0(n435), .A1(n747), .B0(n630), .C0(n629), .Y(n643) );
  AOI21X1 U1331 ( .A0(n631), .A1(code_index_sum[0]), .B0(n795), .Y(n632) );
  OAI2B2X1 U1332 ( .A1N(n633), .A0(n632), .B0(n765), .B1(n780), .Y(n640) );
  AOI21X1 U1333 ( .A0(n757), .A1(n767), .B0(n789), .Y(n639) );
  OAI22X1 U1334 ( .A0(n635), .A1(n789), .B0(n735), .B1(n791), .Y(n636) );
  AOI221XL U1335 ( .A0(n753), .A1(n785), .B0(n784), .B1(n637), .C0(n636), .Y(
        n638) );
  OAI32XL U1336 ( .A0(n640), .A1(n771), .A2(n639), .B0(n774), .B1(n638), .Y(
        n641) );
  AOI221XL U1337 ( .A0(n645), .A1(n644), .B0(n643), .B1(n642), .C0(n641), .Y(
        n717) );
  OAI2B2X1 U1338 ( .A1N(n647), .A0(n794), .B0(n789), .B1(n646), .Y(n648) );
  AOI221XL U1339 ( .A0(n785), .A1(n744), .B0(n649), .B1(n784), .C0(n648), .Y(
        n654) );
  OAI22X1 U1340 ( .A0(N20), .A1(code_index_sum[0]), .B0(n735), .B1(n435), .Y(
        n650) );
  AOI221XL U1341 ( .A0(n652), .A1(n785), .B0(n795), .B1(n651), .C0(n650), .Y(
        n653) );
  OAI22X1 U1342 ( .A0(n771), .A1(n654), .B0(n774), .B1(n653), .Y(n668) );
  NOR2X1 U1343 ( .A(n675), .B(n655), .Y(n656) );
  OAI32XL U1344 ( .A0(n780), .A1(n657), .A2(n661), .B0(n435), .B1(n656), .Y(
        n658) );
  AOI221XL U1345 ( .A0(n795), .A1(n660), .B0(n787), .B1(n659), .C0(n658), .Y(
        n666) );
  OAI32XL U1346 ( .A0(n789), .A1(n739), .A2(n661), .B0(n744), .B1(n435), .Y(
        n662) );
  AOI221XL U1347 ( .A0(n784), .A1(n664), .B0(n663), .B1(code_index_sum[0]), 
        .C0(n662), .Y(n665) );
  OAI22X1 U1348 ( .A0(n775), .A1(n666), .B0(n770), .B1(n665), .Y(n667) );
  OAI21X1 U1349 ( .A0(n668), .A1(n667), .B0(n778), .Y(n716) );
  AOI221XL U1350 ( .A0(n795), .A1(n670), .B0(n784), .B1(n759), .C0(n669), .Y(
        n691) );
  AO22X1 U1351 ( .A0(n672), .A1(n785), .B0(n784), .B1(n671), .Y(n673) );
  AOI221XL U1352 ( .A0(n675), .A1(n787), .B0(n674), .B1(n795), .C0(n673), .Y(
        n690) );
  OAI21X1 U1353 ( .A0(n677), .A1(n676), .B0(n784), .Y(n688) );
  AOI222XL U1354 ( .A0(n785), .A1(n681), .B0(n680), .B1(n784), .C0(n697), .C1(
        n795), .Y(n685) );
  AOI21X1 U1355 ( .A0(n754), .A1(n682), .B0(n789), .Y(n683) );
  NOR3X1 U1356 ( .A(n683), .B(n703), .C(n775), .Y(n684) );
  AOI32XL U1357 ( .A0(n688), .A1(n687), .A2(n686), .B0(n685), .B1(n684), .Y(
        n689) );
  OAI221X1 U1358 ( .A0(n770), .A1(n691), .B0(n774), .B1(n690), .C0(n689), .Y(
        n714) );
  OAI22X1 U1359 ( .A0(n760), .A1(n789), .B0(n757), .B1(n791), .Y(n692) );
  AOI221XL U1360 ( .A0(n785), .A1(n694), .B0(n784), .B1(n693), .C0(n692), .Y(
        n710) );
  AOI211X1 U1361 ( .A0(N19), .A1(n795), .B0(n771), .C0(n695), .Y(n696) );
  OAI22X1 U1362 ( .A0(n758), .A1(n435), .B0(n697), .B1(n789), .Y(n709) );
  AOI22XL U1363 ( .A0(n738), .A1(n795), .B0(n788), .B1(n747), .Y(n707) );
  AOI21X1 U1364 ( .A0(n748), .A1(n730), .B0(n783), .Y(n698) );
  AOI211X1 U1365 ( .A0(n699), .A1(n785), .B0(n775), .C0(n698), .Y(n706) );
  AOI22XL U1366 ( .A0(n701), .A1(n795), .B0(n758), .B1(n786), .Y(n705) );
  AOI21X1 U1367 ( .A0(n730), .A1(n726), .B0(n783), .Y(n702) );
  AOI211X1 U1368 ( .A0(n703), .A1(n724), .B0(n774), .C0(n702), .Y(n704) );
  AOI22XL U1369 ( .A0(n707), .A1(n706), .B0(n705), .B1(n704), .Y(n708) );
  OAI221X1 U1370 ( .A0(n770), .A1(n710), .B0(n772), .B1(n709), .C0(n708), .Y(
        n712) );
  AOI22XL U1371 ( .A0(n714), .A1(n713), .B0(n712), .B1(n711), .Y(n715) );
  OAI211XL U1372 ( .A0(n718), .A1(n717), .B0(n716), .C0(n715), .Y(n719) );
  AOI22XL U1373 ( .A0(n720), .A1(n779), .B0(n719), .B1(N26), .Y(n721) );
  OAI2B2X1 U1374 ( .A1N(N27), .A0(n722), .B0(N27), .B1(n721), .Y(n1001) );
  XOR2X1 U1375 ( .A(n855), .B(\sub_81/carry [6]), .Y(N82) );
  AND2X1 U1376 ( .A(\sub_81/carry [5]), .B(n854), .Y(\sub_81/carry [6]) );
  XOR2X1 U1377 ( .A(n854), .B(\sub_81/carry [5]), .Y(N81) );
  AND2X1 U1378 ( .A(\sub_81/carry [4]), .B(n853), .Y(\sub_81/carry [5]) );
  XOR2X1 U1379 ( .A(n853), .B(\sub_81/carry [4]), .Y(N80) );
  AND2X1 U1380 ( .A(\sub_81/carry [3]), .B(n852), .Y(\sub_81/carry [4]) );
  XOR2X1 U1381 ( .A(n852), .B(\sub_81/carry [3]), .Y(N79) );
  AND2X1 U1382 ( .A(\sub_81/carry [2]), .B(n851), .Y(\sub_81/carry [3]) );
  XOR2X1 U1383 ( .A(n851), .B(\sub_81/carry [2]), .Y(N78) );
  AND2X1 U1384 ( .A(n849), .B(n850), .Y(\sub_81/carry [2]) );
  XOR2X1 U1385 ( .A(n850), .B(n849), .Y(N77) );
  AND2X1 U1386 ( .A(\local_code_index[1] ), .B(n799), .Y(
        \add_0_root_sub_0_root_sub_55_C67_rn/carry [2]) );
  XOR2X1 U1387 ( .A(n799), .B(\local_code_index[1] ), .Y(N18) );
  XNOR2X1 U1388 ( .A(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [9]), .B(n841), 
        .Y(\local_code_index[9] ) );
  OR2X1 U1389 ( .A(n840), .B(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [8]), 
        .Y(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [9]) );
  XNOR2X1 U1390 ( .A(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [8]), .B(n840), 
        .Y(\local_code_index[8] ) );
  OR2X1 U1391 ( .A(n839), .B(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [7]), 
        .Y(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [8]) );
  XNOR2X1 U1392 ( .A(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [7]), .B(n839), 
        .Y(\local_code_index[7] ) );
  OR2X1 U1393 ( .A(n838), .B(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [6]), 
        .Y(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [7]) );
  XNOR2X1 U1394 ( .A(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [6]), .B(n838), 
        .Y(\local_code_index[6] ) );
  OR2X1 U1395 ( .A(n837), .B(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [5]), 
        .Y(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [6]) );
  XNOR2X1 U1396 ( .A(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [5]), .B(n837), 
        .Y(\local_code_index[5] ) );
  OR2X1 U1397 ( .A(n836), .B(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [4]), 
        .Y(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [5]) );
  XNOR2X1 U1398 ( .A(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [4]), .B(n836), 
        .Y(\local_code_index[4] ) );
  OR2X1 U1399 ( .A(n835), .B(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [3]), 
        .Y(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [4]) );
  XNOR2X1 U1400 ( .A(\sub_1_root_sub_0_root_sub_55_C67_rn/carry [3]), .B(n835), 
        .Y(\local_code_index[3] ) );
  OR2X1 U1401 ( .A(n834), .B(n833), .Y(
        \sub_1_root_sub_0_root_sub_55_C67_rn/carry [3]) );
  XNOR2X1 U1402 ( .A(n833), .B(n834), .Y(\local_code_index[2] ) );
  XOR2X1 U1403 ( .A(n848), .B(\sub_80/carry [6]), .Y(N74) );
  AND2X1 U1404 ( .A(\sub_80/carry [5]), .B(n847), .Y(\sub_80/carry [6]) );
  XOR2X1 U1405 ( .A(n847), .B(\sub_80/carry [5]), .Y(N73) );
  AND2X1 U1406 ( .A(\sub_80/carry [4]), .B(n846), .Y(\sub_80/carry [5]) );
  XOR2X1 U1407 ( .A(n846), .B(\sub_80/carry [4]), .Y(N72) );
  AND2X1 U1408 ( .A(\sub_80/carry [3]), .B(n845), .Y(\sub_80/carry [4]) );
  XOR2X1 U1409 ( .A(n845), .B(\sub_80/carry [3]), .Y(N71) );
  AND2X1 U1410 ( .A(\sub_80/carry [2]), .B(n844), .Y(\sub_80/carry [3]) );
  XOR2X1 U1411 ( .A(n844), .B(\sub_80/carry [2]), .Y(N70) );
  AND2X1 U1412 ( .A(n842), .B(n843), .Y(\sub_80/carry [2]) );
  XOR2X1 U1413 ( .A(n843), .B(n842), .Y(N69) );
  AND3X1 U1414 ( .A(code_index_sum[9]), .B(code_index_sum[10]), .C(
        \local_code_index[1] ), .Y(n856) );
  NAND3XL U1415 ( .A(code_index_sum[3]), .B(code_index_sum[2]), .C(n856), .Y(
        n859) );
  AND3X1 U1416 ( .A(code_index_sum[5]), .B(code_index_sum[4]), .C(
        code_index_sum[6]), .Y(n857) );
  NAND3XL U1417 ( .A(code_index_sum[8]), .B(code_index_sum[7]), .C(n857), .Y(
        n858) );
endmodule

