// Primary: identifier [ constant_expression : constant_expression ]  — part select
module primary_part_select (input [7:0] a, output [3:0] hi, output [3:0] lo);
  assign hi = a[7:4];
  assign lo = a[3:0];
endmodule
