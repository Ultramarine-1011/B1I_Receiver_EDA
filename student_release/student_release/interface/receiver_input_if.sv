// Public simulation-only input contract.
// The signal player transfers sixteen consecutive 2-bit samples per handshake
// (four file bytes packed into the 32-bit bus).
// stream_data[1:0] is the earliest sample and stream_data[31:30] is the latest.
// sample_index is the index of the earliest sample in the current transfer and
// advances by 16 after each accepted transfer.
// No SRAM address, SRAM read latency, satellite truth, position, or Doppler truth
// is exposed to the student receiver.

interface receiver_input_if(input logic clk);
    logic        reset_n;
    logic        start;
    logic [31:0] stream_data;
    logic        stream_valid;
    logic        stream_ready;
    logic        stream_last;
    logic [63:0] sample_index;

    modport source (
        input  clk,
        output reset_n, start, stream_data, stream_valid, stream_last, sample_index,
        input  stream_ready
    );

    modport sink (
        input  clk, reset_n, start, stream_data, stream_valid, stream_last, sample_index,
        output stream_ready
    );
endinterface
