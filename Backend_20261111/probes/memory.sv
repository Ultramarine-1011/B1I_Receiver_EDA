// Small copies of the relevant port structures. No macro or inference directive.
module memory_async #(parameter DEPTH=16, WIDTH=16, AW=$clog2(DEPTH)) (
    input logic clk, write_enable,
    input logic [AW-1:0] a,b,read_address,
    input logic [WIDTH-1:0] da,db,
    output logic [WIDTH-1:0] qa,qb,qread
);
    logic [WIDTH-1:0] storage[0:DEPTH-1];
    assign qa=storage[a];
    assign qb=storage[b];
    assign qread=storage[read_address];
    always @(posedge clk) if(write_enable) begin
        storage[a]<=da;
        storage[b]<=db;
    end
endmodule

module memory_sync #(parameter DEPTH=16, WIDTH=16, AW=$clog2(DEPTH)) (
    input logic clk, write_enable,
    input logic [AW-1:0] write_address,read_address,
    input logic [WIDTH-1:0] data,
    output logic [WIDTH-1:0] result
);
    logic [WIDTH-1:0] storage[0:DEPTH-1];
    always @(posedge clk) begin
        if(write_enable) storage[write_address]<=data;
        result<=storage[read_address];
    end
endmodule
