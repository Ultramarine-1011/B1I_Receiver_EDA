/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : K-2015.06
// Date      : Mon Sep 21 17:02:01 2026
/////////////////////////////////////////////////////////////


module counter ( out, clock, clear );
  output [3:0] out;
  input clock, clear;
  wire   n19, n20, n21, n22, N7, N8, N9, N10, n3, n4, n5, n6, n7, n8, n9, n10,
         n11, n13, n15, n17;

  DFFX1 \out_reg[0]  ( .D(N7), .CLK(clock), .Q(n22), .QN(n17) );
  DFFX1 \out_reg[1]  ( .D(N8), .CLK(clock), .Q(n21), .QN(n13) );
  DFFX1 \out_reg[2]  ( .D(N9), .CLK(clock), .Q(n20), .QN(n15) );
  DFFX1 \out_reg[3]  ( .D(N10), .CLK(clock), .Q(n19), .QN(n11) );
  XNOR2X1 U12 ( .IN1(n22), .IN2(n21), .Q(n7) );
  AND2X1 U14 ( .IN1(n6), .IN2(n3), .Q(n4) );
  AND2X1 U17 ( .IN1(n21), .IN2(n22), .Q(n6) );
  NAND3X0 U18 ( .IN1(n10), .IN2(n3), .IN3(n19), .QN(n8) );
  NAND3X0 U19 ( .IN1(n20), .IN2(n11), .IN3(n4), .QN(n9) );
  AO22X1 U20 ( .IN1(n4), .IN2(n15), .IN3(n5), .IN4(n20), .Q(N9) );
  INVX0 U21 ( .INP(n11), .ZN(out[3]) );
  INVX0 U22 ( .INP(n13), .ZN(out[1]) );
  INVX0 U23 ( .INP(n15), .ZN(out[2]) );
  INVX0 U24 ( .INP(n17), .ZN(out[0]) );
  NAND2X1 U25 ( .IN1(n8), .IN2(n9), .QN(N10) );
  NAND2X0 U26 ( .IN1(n6), .IN2(n20), .QN(n10) );
  INVX0 U27 ( .INP(clear), .ZN(n3) );
  NOR2X0 U28 ( .IN1(clear), .IN2(n7), .QN(N8) );
  NOR2X0 U29 ( .IN1(clear), .IN2(n6), .QN(n5) );
  NOR2X0 U30 ( .IN1(n22), .IN2(clear), .QN(N7) );
endmodule

