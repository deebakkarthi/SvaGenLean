// Unary ~&  (reduction NAND — true iff not all bits are 1)
module unary_red_nand (input [7:0] a, output y);
  assign y = ~&a;
endmodule
