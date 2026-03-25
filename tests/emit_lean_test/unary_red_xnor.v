// Unary ~^  (reduction XNOR — true iff even number of 1 bits)
module unary_red_xnor (input [7:0] a, output y);
  assign y = ~^a;
endmodule
