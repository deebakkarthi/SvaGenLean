// Instantiates a sequential module — must be rejected
module dff (input clk, d, output reg q);
  always @(posedge clk) q <= d;
endmodule

module inst_seq (input clk, d, output q);
  dff u0 (.clk(clk), .d(d), .q(q));
endmodule
