// Primary: identifier [ expression ]  — bit select
module primary_bit_select (input [7:0] a, output y);
  assign y = a[3];
endmodule
