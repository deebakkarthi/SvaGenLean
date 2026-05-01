/-!
# Circuit Model

Circuits are modelled as Moore machines: `Circuit State Input Output`.
Combinational circuits use `Unit` as the state; sequential circuits carry
their register values in `State`.
-/

namespace Verilog

-- ---------------------------------------------------------------------------
-- Core structure
-- ---------------------------------------------------------------------------

/-- A hardware circuit as a Moore-machine transition system.

- `State`  : type of internal state; use `Unit` for combinational circuits.
- `Input`  : bundle of all input-port values (a generated `structure`).
- `Output` : bundle of all output-port values (a generated `structure`).
-/
structure Circuit (State Input Output : Type) where
  /-- Initial state.  For combinational circuits this is `()`. -/
  init    : State
  /-- State-transition function.  For combinational circuits this is `fun _ _ => ()`. -/
  step    : State → Input → State
  /-- Output function.  For combinational circuits this ignores the state. -/
  observe : State → Input → Output

/-- Construct a `Circuit` from a pure combinational function. -/
def mkComb {Input Output : Type} (f : Input → Output) :
    Circuit Unit Input Output where
  init    := ()
  step    := fun _ _ => ()
  observe := fun _ i => f i

/-- Construct a sequential `Circuit` from explicit init/step/observe components. -/
def mkSeq {State Input Output : Type}
    (s0  : State)
    (nxt : State → Input → State)
    (obs : State → Input → Output) :
    Circuit State Input Output where
  init    := s0
  step    := nxt
  observe := obs

-- ---------------------------------------------------------------------------
-- Trace semantics
-- ---------------------------------------------------------------------------

/-- State at time `t` given an infinite input stream. -/
def runState {State Input Output : Type}
    (c : Circuit State Input Output) (inputs : Nat → Input) (t : Nat) : State :=
  match t with
  | Nat.zero   => c.init
  | Nat.succ n => c.step (runState c inputs n) (inputs n)

-- ---------------------------------------------------------------------------
-- Lemmas: combinational circuits
-- ---------------------------------------------------------------------------

/-- The state of a combinational circuit is always `()`. -/
@[simp]
theorem comb_runState_unit {Input Output : Type}
    (f : Input → Output) (s : Unit) (i : Input) :
    (mkComb f).step s i = () := by
  simp [mkComb]

/-- The output of a combinational circuit depends only on the current input. -/
@[simp]
theorem comb_observe {Input Output : Type}
    (f : Input → Output) (i : Input) :
    (mkComb f).observe () i = f i := by
  simp [mkComb]

end Verilog
