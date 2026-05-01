// 4-stage Johnson counter (twisted ring counter).
// Stage 0 is fed the complement of stage 3; all other stages
// shift right.  No external data input.
//
// Sequence from 0000:
//   0000 -> 1000 -> 1100 -> 1110 -> 1111
//        -> 0111 -> 0011 -> 0001 -> 0000 ...  (period 8)

module johnson4 (clk, q0, q1, q2, q3);
  input  clk;
  output q0, q1, q2, q3;
  reg    q0, q1, q2, q3;

  always @(posedge clk) begin
    q0 <= ~q3;
    q1 <= q0;
    q2 <= q1;
    q3 <= q2;
  end
endmodule
