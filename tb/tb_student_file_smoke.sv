`timescale 1ns/1ps
// Wrap the unmodified public TB; independently compare every unpacked sample
// with file MSB-first order. The file contains only IF2, never signal truth.
module tb_student_file_smoke;
    receiver_tb_template public_tb();
    integer input_fd, expected_byte, expected_bits;
    integer samples=0, transfers=0, ends=0;
    string input_path;
    initial begin
        input_path="input/scenario.if2";
        void'($value$plusargs("INPUT=%s",input_path));
        input_fd=$fopen(input_path,"rb");
        if(input_fd==0) $fatal(1,"Cannot open independent IF2 reader");
    end
    always @(posedge public_tb.clk) if(public_tb.reset_n) begin
        if(public_tb.stream_valid && public_tb.stream_ready) begin
            if(public_tb.sample_index!=64'(transfers*16)) $fatal(1,"stream index not +16");
            if(public_tb.stream_last != (transfers==10229)) $fatal(1,"unexpected stream_last");
            transfers=transfers+1;
        end
        if(public_tb.dut.multi.receiver.sample_valid && public_tb.dut.multi.receiver.sample_ready) begin
            if(samples%4==0) expected_byte=$fgetc(input_fd);
            if(expected_byte<0) $fatal(1,"early independent EOF");
            expected_bits=(expected_byte >> (6-2*(samples%4))) & 3;
            if(public_tb.dut.multi.receiver.sample_ref != 64'(samples)
               || public_tb.dut.multi.receiver.sample_bits != 2'(expected_bits)
               || int'($signed(public_tb.dut.multi.receiver.sample_data)) != 2*expected_bits-3)
                $fatal(1,"file sample mismatch at %0d",samples);
            if(public_tb.dut.multi.receiver.sample_last != (samples==163679)) $fatal(1,"last lane incorrect");
            samples=samples+1;
        end
        if(public_tb.record_valid && public_tb.record_ready && public_tb.record_data[7:0]==6) begin
            if(public_tb.record_data[7:0]!=6 || public_tb.record_data[95:32]!=163680
               || public_tb.record_data[19:18]!=0 || samples!=163680 || transfers!=10230 || ends!=0)
                $fatal(1,"bad end/count/drain");
            ends=ends+1;
            $fclose(input_fd);
            $display("STUDENT_FILE_SMOKE_PASS seconds=0.01 transfers=%0d samples=%0d ends=%0d file_order=MSB_first bus_order=LSB_first",transfers,samples,ends);
        end
    end
    initial begin #200000000; $fatal(1,"STUDENT_FILE_SMOKE_TIMEOUT"); end
endmodule
