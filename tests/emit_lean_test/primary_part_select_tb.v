`timescale 1ns/1ps
module tb_primary_part_select;
  reg [7:0] a;
  wire [3:0] hi, lo;
  primary_part_select dut(.a(a), .hi(hi), .lo(lo));
  initial begin
    a = 171; #1; $display("%0d", hi); $display("%0d", lo);
    a = 255; #1; $display("%0d", hi); $display("%0d", lo);
    a = 0;   #1; $display("%0d", hi); $display("%0d", lo);
    a = 18;  #1; $display("%0d", hi); $display("%0d", lo);
    a = 90;  #1; $display("%0d", hi); $display("%0d", lo);
    $finish;
  end
endmodule
