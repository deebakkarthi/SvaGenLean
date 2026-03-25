`timescale 1ns/1ps
module tb_num_hex;
  wire [15:0] y;
  wire z;
  num_hex dut(.y(y), .z(z));
  initial begin
    #1;
    $display("%0d", y);
    $display("%0d", z);
    $finish;
  end
endmodule
