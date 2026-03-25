// Primary: concatenation  { expr, expr, ... }
module primary_concat (
  input [3:0] a,
  input [3:0] b,
  input       c,
  output [8:0] y
);
  assign y = {a, b, c};
endmodule
