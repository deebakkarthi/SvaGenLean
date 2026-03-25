// Sequential: negedge clock — must be rejected
module always_negedge (input clk, d, output reg q);
  always @(negedge clk)
    q <= d;
endmodule
