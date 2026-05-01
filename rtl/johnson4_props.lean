import SvaGenLean

open Verilog LTL

-- ---------------------------------------------------------------------------
-- Circuit (copy of generated output from johnson4.v)
-- ---------------------------------------------------------------------------

private def bvXorReduce {n : Nat} (v : BitVec n) : Bool :=
  (List.finRange n).foldl (fun b i => b != v.getLsb i) false

structure Johnson4_Input where

structure Johnson4_State where
  q0 : Bool
  q1 : Bool
  q2 : Bool
  q3 : Bool

structure Johnson4_Output where
  q0 : Bool
  q1 : Bool
  q2 : Bool
  q3 : Bool

def johnson4Circuit : Circuit Johnson4_State Johnson4_Input Johnson4_Output :=
  mkSeq { q0 := false, q1 := false, q2 := false, q3 := false }
    (fun _s _inp =>
    {
    q0 := (!_s.q3)
    q1 := _s.q0
    q2 := _s.q1
    q3 := _s.q2
    })
    (fun _s _inp =>
    {
    q0 := _s.q0
    q1 := _s.q1
    q2 := _s.q2
    q3 := _s.q3
    })

-- ---------------------------------------------------------------------------
-- Assertion 1: The twist property — ¬q3 ↔ X q0
--
-- This is the defining characteristic of a Johnson (twisted-ring) counter.
-- In a plain ring counter, q0 ← q3; here, q0 ← ¬q3.  The biconditional
-- says the two are equivalent: knowing q3 now tells you exactly what q0
-- will be next cycle, and vice versa.  A plain ring counter would satisfy
-- G (q3 ↔ X q0) instead — the negation distinguishes the two designs.
-- ---------------------------------------------------------------------------

theorem johnson4_twist :
    johnson4Circuit.satisfies
      (G (iff (neg (atom fun io => io.2.q3))
              (X (atom fun io => io.2.q0)))) := by
  intro inputs k
  simp [LTL.iff, LTL.neg, X, atom, runState, johnson4Circuit, mkSeq]

-- ---------------------------------------------------------------------------
-- Assertion 2: The shift-chain property for stages 1–3
--
-- q1 at t+1 equals q0 at t, q2 at t+1 equals q1 at t, q3 at t+1 equals
-- q2 at t.  Together these three biconditionals say that stages 1, 2, and 3
-- are pure delay elements: each one faithfully copies its left neighbour with
-- a one-cycle delay and is driven by nothing else.  A bug that skips a stage
-- or cross-connects stages would violate at least one of these.
-- ---------------------------------------------------------------------------

theorem johnson4_shift_q0_q1 :
    johnson4Circuit.satisfies
      (G (iff (atom fun io => io.2.q0)
              (X (atom fun io => io.2.q1)))) := by
  intro inputs k
  simp [LTL.iff, X, atom, runState, johnson4Circuit, mkSeq]

theorem johnson4_shift_q1_q2 :
    johnson4Circuit.satisfies
      (G (iff (atom fun io => io.2.q1)
              (X (atom fun io => io.2.q2)))) := by
  intro inputs k
  simp [LTL.iff, X, atom, runState, johnson4Circuit, mkSeq]

theorem johnson4_shift_q2_q3 :
    johnson4Circuit.satisfies
      (G (iff (atom fun io => io.2.q2)
              (X (atom fun io => io.2.q3)))) := by
  intro inputs k
  simp [LTL.iff, X, atom, runState, johnson4Circuit, mkSeq]

-- ---------------------------------------------------------------------------
-- Assertion 3: After 4 cycles, q0 is complemented
--
-- This is the key period-8 / self-complementing property of a Johnson
-- counter.  After exactly 4 clock cycles, q0 holds the logical complement
-- of its current value.  After another 4 cycles it is restored.  No other
-- 4-stage shift topology (plain ring, LFSR, etc.) satisfies this exact
-- relationship.  The property also implies period divides 8, ruling out
-- stuck-at-constant faults where a register never changes.
-- ---------------------------------------------------------------------------

theorem johnson4_complement_after_4 :
    johnson4Circuit.satisfies
      (G (iff (atom fun io => io.2.q0)
              (X (X (X (X (neg (atom fun io => io.2.q0)))))))) := by
  intro inputs k
  simp [LTL.iff, LTL.neg, X, atom, runState, johnson4Circuit, mkSeq]
