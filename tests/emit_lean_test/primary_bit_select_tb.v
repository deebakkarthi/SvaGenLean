`timescale 1ns/1ps
module tb_primary_bit_select;
  reg [7:0] a;
  wire y;
  primary_bit_select dut(.a(a), .y(y));
  initial begin
    a = 8;   #1; $display("%0d", y);
    a = 247; #1; $display("%0d", y);
    a = 0;   #1; $display("%0d", y);
    a = 255; #1; $display("%0d", y);
    a = 170; #1; $display("%0d", y);
    $finish;
  end
endmodule
