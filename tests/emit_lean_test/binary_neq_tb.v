`timescale 1ns/1ps
module tb_binary_neq;
  reg [7:0] a, b;
  wire y;
  binary_neq dut(.a(a), .b(b), .y(y));
  initial begin
    a = 10;  b = 20;  #1; $display("%0d", y);
    a = 10;  b = 10;  #1; $display("%0d", y);
    a = 0;   b = 0;   #1; $display("%0d", y);
    a = 170; b = 85;  #1; $display("%0d", y);
    a = 255; b = 255; #1; $display("%0d", y);
    $finish;
  end
endmodule
