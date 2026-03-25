`timescale 1ns/1ps
module tb_binary_logor;
  reg a, b;
  wire y;
  binary_logor dut(.a(a), .b(b), .y(y));
  initial begin
    a = 0; b = 0; #1; $display("%0d", y);
    a = 0; b = 1; #1; $display("%0d", y);
    a = 1; b = 0; #1; $display("%0d", y);
    a = 1; b = 1; #1; $display("%0d", y);
    a = 1; b = 0; #1; $display("%0d", y);
    $finish;
  end
endmodule
