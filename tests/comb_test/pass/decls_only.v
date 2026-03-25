// Declarations with combinational assign — wire/reg decls are neutral
module decls_only (input [7:0] a, b, output [7:0] y);
  wire [7:0] tmp;
  assign tmp = a + b;
  assign y   = tmp;
endmodule
