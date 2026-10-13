`timescale 1ns/1ps
module tb_student_transport;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,start=0;
    logic [31:0] stream_data=0;
    logic stream_valid=0,stream_ready,stream_last=0;
    logic [63:0] sample_index=0;
    logic [255:0] record_data;
    logic record_valid,record_ready=0;
    integer transfers=0,samples=0,ends=0;
    logic [255:0] saved_record;
    student_receiver_core #(.USE_PCPS(0)) dut (.*);
    always @(posedge clk) if(reset_n) begin
        if(stream_valid && stream_ready) begin
            if(sample_index!=64'(transfers*16)) $fatal(1,"input index not +16");
            transfers=transfers+1;
        end
        if(dut.single.receiver.sample_valid && dut.single.receiver.sample_ready) begin
            if(dut.single.receiver.sample_ref!=64'(samples)) $fatal(1,"lost sample reference");
            if(dut.single.receiver.sample_bits!=2'(samples%4)) $fatal(1,"wrong lane order");
            samples=samples+1;
        end
        if(record_valid) begin
            if(samples!=48 || transfers!=3) $fatal(1,"end before drain");
            if(record_data[7:0]!=6 || record_data[95:32]!=48 || record_data[19:18]!=0)
                $fatal(1,"invalid end record");
            if(record_ready) ends=ends+1;
        end
    end
    initial begin
        repeat(3) @(negedge clk);
        reset_n=1; start=1;
        @(negedge clk); start=0;
        for(integer word_number=0; word_number<3; word_number=word_number+1) begin
            repeat(word_number+1) @(negedge clk);
            for(integer lane=0;lane<16;lane=lane+1) stream_data[2*lane+:2]=2'(lane%4);
            sample_index=64'(word_number*16);
            stream_last=(word_number==2); stream_valid=1;
            do @(posedge clk); while(!stream_ready);
            @(negedge clk); stream_valid=0; stream_last=0;
        end
        wait(record_valid);
        @(negedge clk); saved_record=record_data;
        repeat(6) begin
            @(negedge clk);
            if(!record_valid || record_data!==saved_record) $fatal(1,"record changed while stalled");
        end
        record_ready=1;
        repeat(10) @(negedge clk);
        if(ends!=1 || record_valid || stream_ready) $fatal(1,"end duplication/continued input");
        $display("STUDENT_TRANSPORT_PASS transfers=%0d samples=%0d ends=%0d record_stall=6",transfers,samples,ends);
        $finish;
    end
    initial begin #100000; $fatal(1,"STUDENT_TRANSPORT_TIMEOUT"); end
endmodule
