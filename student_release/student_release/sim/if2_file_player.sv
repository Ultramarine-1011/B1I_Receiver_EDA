`timescale 1ns/1ps

// Simulation-only IF2 file player.
//
// It reads four bytes (sixteen 2-bit samples) from scenario.if2 and presents
// them as one 32-bit transfer. The player is intentionally not an SRAM model. It gives
// students a deterministic streaming input so their work stays focused on the
// receiver rather than file I/O or memory-controller logic.
//
// Transfer mapping:
//   stream_data[1:0]    = earliest sample in the transfer
//   stream_data[31:30]  = latest sample in the transfer
//
// The file format is MSB-first within each byte: file_byte[7:6] is the
// earliest sample in that byte. Therefore each byte is pair-reversed before
// it is placed on the stream, so the public stream remains LSB-first in time.
// A transfer is accepted on posedge clk when stream_valid && stream_ready.

module if2_file_player #(
    parameter integer BUFFER_BYTES = 65536,
    parameter string DEFAULT_INPUT = "input/scenario.if2"
) (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        start,
    output logic [31:0] stream_data,
    output logic        stream_valid,
    input  logic        stream_ready,
    output logic        stream_last,
    output logic [63:0] sample_index,
    output logic        busy,
    output logic        done,
    output logic        error
);
    string input_path;
    integer input_fd;
    integer bytes_read;
    integer request_bytes;
    integer buffer_index;
    longint bytes_sent;
    longint max_bytes;
    logic [7:0] file_buffer [0:BUFFER_BYTES-1];
    logic started;

    function automatic logic [7:0] reverse_sample_pairs(input logic [7:0] value);
        reverse_sample_pairs = {value[1:0], value[3:2], value[5:4], value[7:6]};
    endfunction

    initial begin
        input_path = DEFAULT_INPUT;
        void'($value$plusargs("INPUT=%s", input_path));
        stream_data = '0;
        stream_valid = 1'b0;
        stream_last = 1'b0;
        sample_index = '0;
        bytes_sent = 0;
        max_bytes = 0;
        void'($value$plusargs("MAX_BYTES=%d", max_bytes));
        busy = 1'b0;
        done = 1'b0;
        error = 1'b0;
        started = 1'b0;
    end

    task automatic send_word(input logic [31:0] word, input logic last_word);
        begin
            stream_data = word;
            stream_last = last_word;
            stream_valid = 1'b1;
            do @(posedge clk); while (!stream_ready);
            @(negedge clk);
            stream_valid = 1'b0;
            stream_last = 1'b0;
            // Four file bytes contain sixteen real samples.
            sample_index = sample_index + 64'd16;
        end
    endtask

    initial begin
        wait (reset_n === 1'b1);
        wait (start === 1'b1);
        if (started) $fatal(1, "if2_file_player start asserted more than once");
        started = 1'b1;
        busy = 1'b1;
        input_fd = $fopen(input_path, "rb");
        if (input_fd == 0) begin
            error = 1'b1;
            busy = 1'b0;
            $fatal(1, "Cannot open IF2 input: %s", input_path);
        end

        forever begin
            request_bytes = BUFFER_BYTES;
            if (max_bytes > 0 && bytes_sent + longint'(request_bytes) > max_bytes)
                request_bytes = integer'(max_bytes - bytes_sent);
            if (request_bytes <= 0) break;
            bytes_read = $fread(file_buffer, input_fd, 0, request_bytes);
            if (bytes_read == 0) break;
            if ((bytes_read % 4) != 0) begin
                error = 1'b1;
                $fatal(1, "IF2 file length must be divisible by four bytes");
            end
            for (buffer_index = 0; buffer_index < bytes_read; buffer_index = buffer_index + 4) begin
                send_word(
                    {
                        reverse_sample_pairs(file_buffer[buffer_index+3]),
                        reverse_sample_pairs(file_buffer[buffer_index+2]),
                        reverse_sample_pairs(file_buffer[buffer_index+1]),
                        reverse_sample_pairs(file_buffer[buffer_index])
                    },
                    (max_bytes > 0
                        ? (bytes_sent + longint'(buffer_index) + 4 >= max_bytes)
                        : (bytes_read < BUFFER_BYTES && buffer_index + 4 == bytes_read))
                );
            end
            bytes_sent = bytes_sent + longint'(bytes_read);
            if (max_bytes > 0 && bytes_sent >= max_bytes) break;
        end
        $fclose(input_fd);
        busy = 1'b0;
        done = 1'b1;
    end
endmodule
