module counter_testbench();
  wire [3:0] out_test;
  reg clock_test;
  reg clear_test;

  counter counter_instance(
    .out(out_test),
    .clear(clear_test),
    .clock(clock_test)
  );

  initial begin
    clock_test = 1'b0;
    forever #10 clock_test = ~clock_test;
  end

  initial begin
    clear_test = 1'b0;
    #3 clear_test = 1'b1;
    #30 clear_test = 1'b0;
    #351 clear_test = 1'b1;
    #30 clear_test = 1'b0;
  end

  initial begin
    $dumpfile("counter.vcd");
    $dumpvars(0, counter_instance);
  end

  initial #500 $finish;
endmodule

