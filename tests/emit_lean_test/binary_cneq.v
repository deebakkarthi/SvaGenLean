// Binary !==  (case inequality)
module binary_cneq (input [7:0] a, input [7:0] b, output y);
  assign y = (a !== b);
endmodule
