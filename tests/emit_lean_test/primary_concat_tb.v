`timescale 1ns/1ps
module tb_primary_concat;
  reg [3:0] a, b;
  reg c;
  wire [8:0] y;
  primary_concat dut(.a(a), .b(b), .c(c), .y(y));
  initial begin
    a = 15; b = 0;  c = 0; #1; $display("%0d", y);
    a = 0;  b = 15; c = 1; #1; $display("%0d", y);
    a = 5;  b = 10; c = 0; #1; $display("%0d", y);
    a = 15; b = 15; c = 1; #1; $display("%0d", y);
    a = 8;  b = 7;  c = 0; #1; $display("%0d", y);
    $finish;
  end
endmodule
