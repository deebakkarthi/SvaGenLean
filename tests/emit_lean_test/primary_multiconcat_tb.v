`timescale 1ns/1ps
module tb_primary_multiconcat;
  reg [3:0] a;
  wire [11:0] y;
  primary_multiconcat dut(.a(a), .y(y));
  initial begin
    a = 5;  #1; $display("%0d", y);
    a = 15; #1; $display("%0d", y);
    a = 0;  #1; $display("%0d", y);
    a = 10; #1; $display("%0d", y);
    a = 3;  #1; $display("%0d", y);
    $finish;
  end
endmodule
