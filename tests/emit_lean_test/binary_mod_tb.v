`timescale 1ns/1ps
module tb_binary_mod;
  reg [7:0] a, b;
  wire [7:0] y;
  binary_mod dut(.a(a), .b(b), .y(y));
  initial begin
    a = 10;  b = 3;   #1; $display("%0d", y);
    a = 255; b = 10;  #1; $display("%0d", y);
    a = 100; b = 7;   #1; $display("%0d", y);
    a = 128; b = 16;  #1; $display("%0d", y);
    a = 7;   b = 2;   #1; $display("%0d", y);
    $finish;
  end
endmodule
