// Mix of assign and combinational always — still fully combinational
module mixed_assign_always (input a, b, c, output y, output reg z);
  assign y = a & b;
  always @(b or c)
    z = b | c;
endmodule
