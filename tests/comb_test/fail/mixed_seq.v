// Module with both combinational and sequential — must be rejected
module mixed_seq (input clk, a, b, output reg q, output y);
  assign y = a & b;
  always @(posedge clk)
    q <= a;
endmodule
