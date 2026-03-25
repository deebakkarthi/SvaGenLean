// Binary >>  (right shift)
module binary_shr (input [7:0] a, input [2:0] amt, output [7:0] y);
  assign y = a >> amt;
endmodule
