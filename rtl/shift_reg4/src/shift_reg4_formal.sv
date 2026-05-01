// 4-stage shift register with formal assertions
//
// Assertions correspond to the three Lean LTL theorems in
// shift_reg4_props.lean.  Each Lean `G (φ <-> X^n ψ)` becomes an
// equality check `signal == $past(other, n)`.
//
// f_past_valid[n] goes high after n+1 posedge events, gating assertions
// that require n+1 cycles of history — the standard SymbiYosys idiom.
//
// Verified with: sby -f shift_reg4.sby

module shift_reg4_formal (
    input logic clk,
    input logic sin
);

  logic q0, q1, q2, q3;

  // Design
  always @(posedge clk) begin
    q0 <= sin;
    q1 <= q0;
    q2 <= q1;
    q3 <= q2;
  end

`ifdef FORMAL

  // f_past_valid[n] = 1 after n+1 posedge events (n+1 cycles of history).
  reg [3:0] f_past_valid;
  initial f_past_valid = 4'h0;
  always @(posedge clk)
    f_past_valid <= {f_past_valid[2:0], 1'b1};

  // sr_sin_q0 : G (sin <-> X q0)
  // q0 at t+1 equals sin at t exactly.
  always @(posedge clk)
    if (f_past_valid[0])
      a1: assert(q0 == $past(sin));

  // sr_q0_to_q3 : G (q0 <-> X^3 q3)
  // q3 at t+3 equals q0 at t exactly — the full 3-stage chain.
  always @(posedge clk)
    if (f_past_valid[2])
      a2: assert(q3 == $past(q0, 3));

  // sr_sin_to_q3 : G (sin <-> X^4 q3)
  // q3 at t+4 equals sin at t exactly — end-to-end delay of 4 cycles.
  always @(posedge clk)
    if (f_past_valid[3])
      a3: assert(q3 == $past(sin, 4));

`endif

endmodule
