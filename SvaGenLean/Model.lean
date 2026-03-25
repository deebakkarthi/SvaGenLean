/-!
# Circuit Model (Combinational)

A purely combinational circuit is modelled as a function `Input → Output`
wrapped in a `Circuit Unit Input Output` so that future sequential extensions
share the same interface.
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

/-- Construct a `Circuit` from a pure combinational function.
    The state is trivially `Unit` and never changes. -/
def mkComb {Input Output : Type} (f : Input → Output) :
    Circuit Unit Input Output where
  init    := ()
  step    := fun _ _ => ()
  observe := fun _ i => f i

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
