// Combinational always with if/else
module always_level_if (input a, b, sel, output reg y);
  always @(a or b or sel)
    if (sel)
      y = a;
    else
      y = b;
endmodule
