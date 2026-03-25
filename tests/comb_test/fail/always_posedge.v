// Sequential: posedge clock — must be rejected
module always_posedge (input clk, d, output reg q);
  always @(posedge clk)
    q <= d;
endmodule
