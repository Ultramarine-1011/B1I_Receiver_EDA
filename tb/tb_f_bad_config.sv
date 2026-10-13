`timescale 1ns/1ps
module tb_f_bad_config;
    logic clk=0,reset_n=0,start=0,stream_valid=0,stream_ready,stream_last=0,record_valid,record_ready=1;
    logic [31:0] stream_data=0;logic [63:0] sample_index=0;logic [255:0] record_data;
    student_receiver_core #(.CHANNELS(3)) dut(.*);
    initial begin #100;$fatal(1,"configuration rejection missing");end
endmodule
