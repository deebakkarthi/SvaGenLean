`timescale 1ns/1ps
module tb_num_unsized;
  wire [7:0] y;
  num_unsized dut(.y(y));
  initial begin
    #1; $display("%0d", y);
    $finish;
  end
endmodule
