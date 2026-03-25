// Unary |  (reduction OR — true iff any bit is 1)
module unary_red_or (input [7:0] a, output y);
  assign y = |a;
endmodule
