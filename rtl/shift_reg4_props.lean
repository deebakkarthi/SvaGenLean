import SvaGenLean

open Verilog LTL

-- ---------------------------------------------------------------------------
-- Circuit (copy of generated output from shift_reg4.v)
-- ---------------------------------------------------------------------------

private def bvXorReduce {n : Nat} (v : BitVec n) : Bool :=
  (List.finRange n).foldl (fun b i => b != v.getLsb i) false

structure Shift_reg4_Input where
  sin : Bool

structure Shift_reg4_State where
  q0 : Bool
  q1 : Bool
  q2 : Bool
  q3 : Bool

structure Shift_reg4_Output where
  q0 : Bool
  q1 : Bool
  q2 : Bool
  q3 : Bool

def shift_reg4Circuit : Circuit Shift_reg4_State Shift_reg4_Input Shift_reg4_Output :=
  mkSeq { q0 := false, q1 := false, q2 := false, q3 := false }
    (fun _s _inp => { q0 := _inp.sin, q1 := _s.q0, q2 := _s.q1, q3 := _s.q2 })
    (fun _s _inp => { q0 := _s.q0,   q1 := _s.q1, q2 := _s.q2, q3 := _s.q3 })

-- ---------------------------------------------------------------------------
-- Helper: abbreviation for the output trace
-- ---------------------------------------------------------------------------

private abbrev π (inputs : Nat → Shift_reg4_Input) (t : Nat) :=
  (inputs t, shift_reg4Circuit.observe (runState shift_reg4Circuit inputs t) (inputs t))

-- ---------------------------------------------------------------------------
-- Assertion 1: sin appears at q0 after exactly 1 cycle
--
-- The shift register's first stage is simply a DFF: whatever sin is at
-- time t, q0 will carry that value at t+1 — and conversely, q0 at t+1
-- tells you exactly what sin was at t.  The biconditional is stronger than
-- a one-way implication and rules out implementations where q0 could be
-- driven by anything other than the serial input.
-- ---------------------------------------------------------------------------

theorem sr_sin_q0 :
    shift_reg4Circuit.satisfies
      (G (iff (atom fun io => io.1.sin)
              (X (atom fun io => io.2.q0)))) := by
  intro inputs k
  simp [LTL.iff, X, atom, runState, shift_reg4Circuit, mkSeq]

-- ---------------------------------------------------------------------------
-- Assertion 2: q0 reaches q3 in exactly 3 cycles
--
-- The value at stage 0 propagates one stage per cycle.  After 3 more
-- cycles it must appear at stage 3 — no sooner, no later.  The
-- biconditional says q3 at t+3 is determined *solely* by q0 at t,
-- regardless of what sin does in the intervening cycles.  This rules out
-- bugs where a register is accidentally connected to the wrong stage.
-- ---------------------------------------------------------------------------

theorem sr_q0_to_q3 :
    shift_reg4Circuit.satisfies
      (G (iff (atom fun io => io.2.q0)
              (X (X (X (atom fun io => io.2.q3)))))) := by
  intro inputs k
  simp [LTL.iff, X, atom, runState, shift_reg4Circuit, mkSeq]

-- ---------------------------------------------------------------------------
-- Assertion 3: sin propagates to q3 in exactly 4 cycles
--
-- The full end-to-end delay is 4 cycles.  Combined with sr_sin_q0 and
-- sr_q0_to_q3, this closes the loop: it is not enough that sin reaches q0
-- and q0 reaches q3 separately — the composition must also hold, and the
-- delay must be exactly 4, not 3 or 5.
-- ---------------------------------------------------------------------------

theorem sr_sin_to_q3 :
    shift_reg4Circuit.satisfies
      (G (iff (atom fun io => io.1.sin)
              (X (X (X (X (atom fun io => io.2.q3))))))) := by
  intro inputs k
  simp [LTL.iff, X, atom, runState, shift_reg4Circuit, mkSeq]
