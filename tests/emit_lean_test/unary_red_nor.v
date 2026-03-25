// Unary ~|  (reduction NOR — true iff all bits are 0; ^| is a BNF alias)
module unary_red_nor (input [7:0] a, output y);
  assign y = ~|a;
endmodule
