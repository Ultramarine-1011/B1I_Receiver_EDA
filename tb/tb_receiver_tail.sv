`timescale 1ns/1ps
// Short capture, exactly a capture window, and one trailing input word.
module tb_receiver_tail;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0,start=0;
    logic [31:0] stream_data=32'haaaaaaaa;
    logic stream_valid=0,stream_ready,stream_last=0;
    logic [63:0] sample_index=0;
    logic [255:0] record_data;
    logic record_valid,record_ready=1;
    integer total=0,ends=0,acqs=0,cycles=0;
    logic stalled=0;
    logic [255:0] saved=0;
    student_receiver_core #(.SEARCH_LAG_LAST(0),.SEARCH_DOPPLER_FIRST(0),
        .SEARCH_DOPPLER_LAST(0)) dut(.*);
    always @(negedge clk) begin cycles=cycles+1; record_ready=(cycles%41>=17); end
    always @(posedge clk) if(reset_n) begin
        if(stalled && (!record_valid || record_data!==saved)) $fatal(1,"tail record changed");
        stalled=record_valid && !record_ready; saved=record_data;
        if(record_valid && record_ready) begin
            case(record_data[7:0])
                5: begin
                    if(record_data[18]) $fatal(1,"constant IF falsely detected");
                    acqs=acqs+1;
                end
                6: begin
                    if(ends!=0 || record_data[95:32]!=64'(total) || record_data[19:18]!=0 || dut.processed_samples!=64'(total))
                        $fatal(1,"tail count/end");
                    ends=ends+1;
                end
                default: $fatal(1,"tail unexpected record");
            endcase
        end
    end
    initial begin
        for(integer c=0;c<3;c=c+1) begin
            @(negedge clk); reset_n=0;stream_valid=0;start=0;stalled=0;
            total=c==0 ? 48 : c==1 ? 16368 : 16384; ends=0;acqs=0;
            repeat(3) @(negedge clk);reset_n=1;start=1;
            @(negedge clk);start=0;
            for(integer n=0;n<total;n=n+16) begin
                sample_index=64'(n);stream_last=(n==total-16);stream_valid=1;
                do @(posedge clk); while(!stream_ready);
                @(negedge clk);stream_valid=0;
            end
            wait(ends==1);repeat(25) @(negedge clk);
            if(record_valid || stream_ready || acqs!=(c==0 ? 0 : 1)) $fatal(1,"tail drain/restart");
            $display("RECEIVER_TAIL_CASE_PASS total=%0d acquisition=%0d reset=1",total,acqs);
        end
        $display("RECEIVER_TAIL_PASS cases=3");$finish;
    end
    initial begin #10000000;$fatal(1,"tail timeout");end
endmodule
