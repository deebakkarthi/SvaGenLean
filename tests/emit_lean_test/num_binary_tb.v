`timescale 1ns/1ps
module tb_num_binary;
  wire [7:0] y;
  wire z;
  num_binary dut(.y(y), .z(z));
  initial begin
    #1;
    $display("%0d", y);
    $display("%0d", z);
    $finish;
  end
endmodule
