// Primary: multiple concatenation  { const { expr, ... } }
module primary_multiconcat (input [3:0] a, output [11:0] y);
  assign y = {3{a}};
endmodule
