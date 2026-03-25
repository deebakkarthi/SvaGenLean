// Unary &  (reduction AND — true iff all bits are 1)
module unary_red_and (input [7:0] a, output y);
  assign y = &a;
endmodule
