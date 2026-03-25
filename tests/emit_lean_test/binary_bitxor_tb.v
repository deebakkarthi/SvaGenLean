`timescale 1ns/1ps
module tb_binary_bitxor;
  reg [7:0] a, b;
  wire [7:0] y;
  binary_bitxor dut(.a(a), .b(b), .y(y));
  initial begin
    a = 10;  b = 20;  #1; $display("%0d", y);
    a = 255; b = 0;   #1; $display("%0d", y);
    a = 170; b = 85;  #1; $display("%0d", y);
    a = 128; b = 64;  #1; $display("%0d", y);
    a = 255; b = 255; #1; $display("%0d", y);
    $finish;
  end
endmodule
