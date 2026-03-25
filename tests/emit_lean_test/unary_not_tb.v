`timescale 1ns/1ps
module tb_unary_not;
  reg a;
  wire y;
  unary_not dut(.a(a), .y(y));
  initial begin
    a = 0; #1; $display("%0d", y);
    a = 1; #1; $display("%0d", y);
    a = 0; #1; $display("%0d", y);
    a = 1; #1; $display("%0d", y);
    a = 0; #1; $display("%0d", y);
    $finish;
  end
endmodule
