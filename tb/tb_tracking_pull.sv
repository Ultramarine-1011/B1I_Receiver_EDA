`timescale 1ns/1ps
module tb_tracking_pull;
    tb_tracking_minimal #(.FLL_TEST(1),.OUTPUT_CSV("../../reports/e_stage/tracking_pull.csv")) scenario();
endmodule
