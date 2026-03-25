`timescale 1ns/1ps
module tb_binary_div;
  reg [7:0] a, b;
  wire [7:0] y;
  binary_div dut(.a(a), .b(b), .y(y));
  initial begin
    a = 20;  b = 5;   #1; $display("%0d", y);
    a = 100; b = 10;  #1; $display("%0d", y);
    a = 255; b = 3;   #1; $display("%0d", y);
    a = 200; b = 8;   #1; $display("%0d", y);
    a = 7;   b = 2;   #1; $display("%0d", y);
    $finish;
  end
endmodule
