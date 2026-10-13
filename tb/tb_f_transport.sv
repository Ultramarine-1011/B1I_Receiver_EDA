`timescale 1ns/1ps
module f_transport_case #(parameter integer CHANNELS=4,INDEX_GAP=0)(output logic done=0);
    logic clk=0,reset_n=0,start=0,stream_valid=0,stream_ready,stream_last=0,record_valid,record_ready=0;
    logic [31:0] stream_data=32'hE4E4E4E4;logic [63:0] sample_index=0;
    logic [255:0] record_data,held;logic stalled=0;
    integer cycles=0,words=0,ends=0;
    always #5 clk=~clk;
    student_receiver_core #(.CHANNELS(CHANNELS)) core(.*);
    always @(posedge clk) if(reset_n) begin
        cycles++;if(cycles>2000) $fatal(1,"transport timeout");
        if(stream_valid&&stream_ready) words++;
        if(stalled && (!record_valid || held!==record_data)) $fatal(1,"end payload changed under stall");
        stalled=record_valid&&!record_ready;held=record_data;
        if(record_valid&&record_ready) begin
            if(ends || record_data[7:0]!=6 || record_data[95:32]!=64 || record_data[19] || record_data[18]!=1'(INDEX_GAP))
                $fatal(1,"transport end count/flags/ordering channels=%0d gap=%0d",CHANNELS,INDEX_GAP);
            ends++;
        end
    end
    task automatic send_word(input integer index,input bit last_word);
        @(negedge clk);stream_valid=1;sample_index=64'(index);stream_last=last_word;
        do @(posedge clk);while(!stream_ready);
        @(negedge clk);stream_valid=0;stream_last=0;
    endtask
    initial begin
        repeat(3) @(negedge clk);reset_n=1;start=1;
        @(negedge clk);start=0;
        send_word(0,0);
        // Cancel a partially processed first word. No false end/lost survives.
        repeat(3) @(negedge clk);reset_n=0;words=0;stalled=0;
        @(negedge clk);reset_n=1;start=1;
        @(negedge clk);start=0;
        for(integer w=0;w<4;w++) begin send_word(w*16+(INDEX_GAP && w>=2 ? 16 : 0),w==3);repeat(3) @(negedge clk);end
        while(!record_valid) @(negedge clk);
        repeat(6) @(negedge clk);record_ready=1;
        while(!ends) @(negedge clk);
        repeat(20) @(negedge clk);
        if(words!=4 || ends!=1 || stream_ready) $fatal(1,"EOF still accepts input");
        done=1;$display("F_TRANSPORT_CASE_PASS channels=%0d gap=%0d reset/partial_EOF/end_backpressure",CHANNELS,INDEX_GAP);
    end
endmodule

module tb_f_transport;
    logic d1,d4,d12,dgap;
    f_transport_case #(.CHANNELS(1)) c1(d1);
    f_transport_case #(.CHANNELS(4)) c4(d4);
    f_transport_case #(.CHANNELS(12)) c12(d12);
    f_transport_case #(.CHANNELS(4),.INDEX_GAP(1)) gap(dgap);
    initial begin wait(d1&&d4&&d12&&dgap);$display("F_TRANSPORT_PASS 1/4/12 EOF/reset/input_gap/error_flags/stable_end/no_false_observation");$finish;end
endmodule
