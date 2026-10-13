`timescale 1ns/1ps
module tb_stream_unpacker;
    logic clk=0;
    always #5 clk=~clk;
    logic reset_n=0, enable=0;
    logic [31:0] stream_data=0;
    logic stream_valid=0, stream_last=0, stream_ready;
    logic [63:0] sample_index=0;
    logic sample_valid, sample_ready=0, sample_last, input_drained;
    logic [1:0] sample_bits;
    logic signed [2:0] sample_data;
    logic [63:0] sample_ref;
    integer received=0, transfers=0, drains=0, cycles=0;
    logic held=0;
    logic [68:0] held_payload;
    stream_unpacker dut (.*);

    function automatic integer pattern(input integer index);
        pattern=(index*3+index/5)%4;
    endfunction
    always @(negedge clk) begin
        cycles=cycles+1;
        sample_ready=(cycles%5 != 0 && cycles%5 != 1);
    end
    always @(posedge clk) if (reset_n) begin
        if (stream_valid && stream_ready) begin
            if (sample_index != 64'(transfers*16)) $fatal(1,"transfer index not +16");
            transfers=transfers+1;
        end
        if (held && (!sample_valid || {sample_ref,sample_data,sample_bits} !== held_payload))
            $fatal(1,"sample payload changed under backpressure");
        held=sample_valid && !sample_ready;
        if (held) held_payload={sample_ref,sample_data,sample_bits};
        if (sample_valid && sample_ready) begin
            if (sample_ref != 64'(received) || sample_bits != 2'(pattern(received)))
                $fatal(1,"sample order/ref mismatch n=%0d bits=%0d ref=%0d",received,sample_bits,sample_ref);
            if (int'($signed(sample_data)) != 2*pattern(received)-3) $fatal(1,"quantization mismatch");
            if (sample_last != (received==47)) $fatal(1,"last lane mismatch");
            received=received+1;
        end
        if (input_drained) begin
            if (received!=48) $fatal(1,"drain before last sample");
            drains=drains+1;
        end
    end
    task automatic send(input integer word_number);
        integer lane;
        begin
            repeat (word_number+1) @(negedge clk);
            for (lane=0; lane<16; lane=lane+1)
                stream_data[2*lane +: 2]=2'(pattern(word_number*16+lane));
            sample_index=64'(word_number*16);
            stream_last=(word_number==2);
            stream_valid=1;
            do @(posedge clk); while (!stream_ready);
            @(negedge clk);
            stream_valid=0;
            stream_last=0;
        end
    endtask
    initial begin
        repeat(3) @(negedge clk);
        reset_n=1; enable=1;
        send(0); send(1); send(2);
        wait(input_drained);
        repeat(8) @(negedge clk);
        if (received!=48 || transfers!=3 || drains!=1 || stream_ready)
            $fatal(1,"counts/drain mismatch");
        $display("STREAM_UNPACKER_PASS transfers=%0d samples=%0d drains=%0d",transfers,received,drains);
        $finish;
    end
    initial begin #100000; $fatal(1,"STREAM_UNPACKER_TIMEOUT"); end
endmodule
