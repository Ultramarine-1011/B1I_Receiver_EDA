`timescale 1ns/1ps

// Student work file and fixed public top-level module.
// Implement the receiver here; helper *.sv files may be added under rtl/ and
// optional $readmemh tables may be added under rom/. Do not change this
// module's port names, widths, or handshake meanings.

module student_receiver_core (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        start,

    // Sixteen consecutive 2-bit IF samples per accepted transfer.
    input  logic [31:0] stream_data,
    input  logic        stream_valid,
    output logic        stream_ready,
    input  logic        stream_last,
    input  logic [63:0] sample_index,

    // One 32-byte receiver record per accepted transfer.
    output logic [255:0] record_data,
    output logic         record_valid,
    input  logic         record_ready
);
    import receiver_contract_pkg::*;
    // A-stage transport baseline. No acquisition/lock/navigation claims.
    // A reset is required for a second run, as in the public file player.
    logic running, input_drained;
    logic sample_valid, sample_ready, sample_last;
    logic [1:0] sample_bits;
    logic signed [2:0] sample_data;
    logic [63:0] sample_ref;
    logic [63:0] accepted_samples, processed_samples, hardware_cycles;
    logic index_error;
    logic [1:0] drain_count;
    typedef enum logic [1:0] {WAIT_INPUT, DRAIN, SEND_END, DONE} state_t;
    state_t state;

    assign sample_ready = 1'b1;
    stream_unpacker unpacker (
        .clk(clk), .reset_n(reset_n), .enable(running),
        .stream_data(stream_data), .stream_valid(stream_valid),
        .stream_last(stream_last), .sample_index(sample_index),
        .stream_ready(stream_ready), .sample_valid(sample_valid),
        .sample_ready(sample_ready), .sample_bits(sample_bits),
        .sample_data(sample_data), .sample_ref(sample_ref),
        .sample_last(sample_last), .input_drained(input_drained)
    );

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            running <= 0;
            state <= WAIT_INPUT;
            accepted_samples <= 0;
            processed_samples <= 0;
            hardware_cycles <= 0;
            index_error <= 0;
            drain_count <= 0;
            record_data <= 0;
            record_valid <= 0;
        end else begin
            if (start && state == WAIT_INPUT) running <= 1;
            if (running) hardware_cycles <= hardware_cycles + 64'd1;
            if (stream_valid && stream_ready) begin
                accepted_samples <= accepted_samples + 64'(SAMPLES_PER_TRANSFER);
                if (sample_index != accepted_samples) index_error <= 1;
            end
            if (sample_valid && sample_ready)
                processed_samples <= processed_samples + 64'd1;
            case (state)
                WAIT_INPUT: if (input_drained) begin
                    state <= DRAIN;
                    drain_count <= 2;
                end
                DRAIN: if (drain_count != 0) drain_count <= drain_count - 1'b1;
                       else begin
                           // Only emit after every lane and in-flight stage drains.
                           record_data <= 0;
                           record_data[7:0] <= 8'd6;
                           record_data[95:32] <= processed_samples;
                           record_data[18] <= index_error;
                           record_data[19] <= processed_samples != accepted_samples;
                           record_data[159:96] <= hardware_cycles;
                           record_valid <= 1;
                           state <= SEND_END;
                       end
                SEND_END: if (record_valid && record_ready) begin
                    record_valid <= 0;
                    running <= 0;
                    state <= DONE;
                end
                DONE: begin end
                default: state <= DONE;
            endcase
        end
    end
endmodule
