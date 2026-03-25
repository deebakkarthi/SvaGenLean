// Unary ^  (reduction XOR — parity: true iff odd number of 1 bits)
module unary_red_xor (input [7:0] a, output y);
  assign y = ^a;
endmodule
