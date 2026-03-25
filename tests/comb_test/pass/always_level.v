// always with level-sensitive (combinational) sensitivity list
module always_level (input a, b, output reg y);
  always @(a or b)
    y = a & b;
endmodule
