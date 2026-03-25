`timescale 1ns/1ps
module tb_unary_red_or;
  reg [7:0] a;
  wire y;
  unary_red_or dut(.a(a), .y(y));
  initial begin
    a = 0;   #1; $display("%0d", y);
    a = 255; #1; $display("%0d", y);
    a = 85;  #1; $display("%0d", y);
    a = 170; #1; $display("%0d", y);
    a = 127; #1; $display("%0d", y);
    $finish;
  end
endmodule
