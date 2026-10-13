`timescale 1ns/1ps

// Simulation-only integration template.
//
// This template contains two pieces of reusable infrastructure:
//   1. if2_file_player: reads input/scenario.if2 and drives the public stream;
//   2. record writer: saves the student's 256-bit output records as
//      output/receiver_records.bin.
//
// The DUT instance and all file I/O are already connected. The student only
// implements rtl/student_receiver_core.sv (and optional helper RTL/ROM files).
// The DUT must use the public receiver_records_32byte_le_v1 record format
// described in submission/RECORD_FORMAT.md.

module receiver_tb_template;
    localparam realtime HALF_PERIOD_NS = 30.547410;

    logic clk = 1'b0;
    always #(HALF_PERIOD_NS) clk = ~clk;

    logic reset_n = 1'b0;
    logic start = 1'b0;
    logic [31:0] stream_data;
    logic stream_valid;
    logic stream_ready;
    logic stream_last;
    logic [63:0] sample_index;
    logic player_busy, player_done, player_error;

    logic [255:0] record_data;
    logic record_valid;
    logic record_ready = 1'b1;
    integer output_fd;
    string output_path;
    integer record_count;
    integer end_wait_cycles;
    logic end_seen;

    localparam integer END_TIMEOUT_CYCLES = 10_000_000;

    if2_file_player #(
        .DEFAULT_INPUT("input/scenario.if2")
    ) player (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .stream_data(stream_data),
        .stream_valid(stream_valid),
        .stream_ready(stream_ready),
        .stream_last(stream_last),
        .sample_index(sample_index),
        .busy(player_busy),
        .done(player_done),
        .error(player_error)
    );

    // The student only edits rtl/student_receiver_core.sv. The input side must
    // use stream_valid && stream_ready as the transfer condition. The output
    // side must produce one 256-bit record per transfer.
    student_receiver_core dut (
        .clk          (clk),
        .reset_n      (reset_n),
        .start        (start),
        .stream_data  (stream_data),
        .stream_valid (stream_valid),
        .stream_ready  (stream_ready),
        .stream_last  (stream_last),
        .sample_index (sample_index),
        .record_data  (record_data),
        .record_valid (record_valid),
        .record_ready (record_ready)
    );

    task automatic write_record(input logic [255:0] value);
        integer byte_number;
        begin
            for (byte_number = 0; byte_number < 32; byte_number = byte_number + 1)
                $fwrite(output_fd, "%c", value[byte_number*8 +: 8]);
            record_count = record_count + 1;
        end
    endtask

    always @(posedge clk) begin
        if (record_valid && record_ready) begin
            if (end_seen)
                $fatal(1, "record appeared after the end record");
            write_record(record_data);
            if (record_data[7:0] == 8'd6) begin
                end_seen = 1'b1;
                $display("END record sample_index=%0d", record_data[95:32]);
            end
        end
    end

    initial begin
        output_path = "output/receiver_records.bin";
        void'($value$plusargs("OUTPUT=%s", output_path));
        record_count = 0;
        end_seen = 1'b0;
        output_fd = $fopen(output_path, "wb");
        if (output_fd == 0)
            $fatal(1, "Cannot open output file: %s", output_path);

        repeat (8) @(negedge clk);
        reset_n = 1'b1;
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        // player_done only means that the final transfer has entered the DUT.
        // The receiver may still have buffered samples and pending records, so
        // finish only after the DUT explicitly emits its type-6 end record.
        wait (player_done);
        end_wait_cycles = 0;
        while (!end_seen && end_wait_cycles < END_TIMEOUT_CYCLES) begin
            @(negedge clk);
            end_wait_cycles = end_wait_cycles + 1;
        end
        if (!end_seen)
            $fatal(1, "student receiver did not produce a type-6 end record after consuming the final input transfer");
        repeat (20) @(negedge clk);
        $fclose(output_fd);
        $display("PASS receiver_records.bin records=%0d", record_count);
        $finish;
    end
endmodule
