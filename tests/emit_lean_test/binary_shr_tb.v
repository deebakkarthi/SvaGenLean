`timescale 1ns/1ps
module tb_binary_shr;
  reg [7:0] a;
  reg [2:0] amt;
  wire [7:0] y;
  binary_shr dut(.a(a), .amt(amt), .y(y));
  initial begin
    a = 10;  amt = 1; #1; $display("%0d", y);
    a = 170; amt = 2; #1; $display("%0d", y);
    a = 255; amt = 0; #1; $display("%0d", y);
    a = 128; amt = 3; #1; $display("%0d", y);
    a = 1;   amt = 7; #1; $display("%0d", y);
    $finish;
  end
endmodule
