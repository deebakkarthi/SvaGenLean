module shift_reg4 (clk, sin, q0, q1, q2, q3);
  input  clk;
  input  sin;
  output q0, q1, q2, q3;
  reg    q0, q1, q2, q3;

  always @(posedge clk) begin
    q0 <= sin;
    q1 <= q0;
    q2 <= q1;
    q3 <= q2;
  end
endmodule
