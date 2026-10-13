module counter(out, clock, clear);
  output [3:0] out;
  input clock, clear;
  reg [3:0] out;

  always @(posedge clock) begin
    if (clear)
      out <= 4'd0;
    else
      out <= out + 1'b1;
  end
endmodule

