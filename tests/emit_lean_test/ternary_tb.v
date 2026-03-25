`timescale 1ns/1ps
module tb_ternary;
  reg sel;
  reg [7:0] a, b;
  wire [7:0] y;
  ternary dut(.sel(sel), .a(a), .b(b), .y(y));
  initial begin
    sel = 0; a = 10;  b = 20;  #1; $display("%0d", y);
    sel = 1; a = 10;  b = 20;  #1; $display("%0d", y);
    sel = 0; a = 170; b = 85;  #1; $display("%0d", y);
    sel = 1; a = 170; b = 85;  #1; $display("%0d", y);
    sel = 0; a = 0;   b = 255; #1; $display("%0d", y);
    $finish;
  end
endmodule
