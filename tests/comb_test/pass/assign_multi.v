// Multiple continuous assignments
module assign_multi (input a, b, c, output y, z);
  assign y = a | b;
  assign z = b ^ c;
endmodule
