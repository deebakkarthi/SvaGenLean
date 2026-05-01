import SvaGenLean.Model

/-!
# Minimal LTL for circuit assertions

Formulas are predicates on (infinite path, start index).
The alphabet is `Input × Output` so assertions can reference both.

Operators provided: `atom`, `X` (next), `G` (globally), `imp`.
-/

namespace LTL

/-- An LTL formula over observations of type `α`. -/
def Formula (α : Type) := (Nat → α) → Nat → Prop

def atom (p : α → Prop)               : Formula α := fun π t => p (π t)
def X    (φ : Formula α)              : Formula α := fun π t => φ π (t + 1)
def G    (φ : Formula α)              : Formula α := fun π t => ∀ k, φ π (t + k)
def imp  (φ ψ : Formula α)            : Formula α := fun π t => φ π t → ψ π t
def neg  (φ : Formula α)              : Formula α := fun π t => ¬ φ π t
def iff  (φ ψ : Formula α)            : Formula α := fun π t => φ π t ↔ ψ π t

end LTL

namespace Verilog

/-- A circuit satisfies an LTL property when it holds from time 0
    for every possible input stream. -/
def Circuit.satisfies {State Input Output : Type}
    (c : Circuit State Input Output)
    (φ : LTL.Formula (Input × Output)) : Prop :=
  ∀ inputs : Nat → Input,
    φ (fun t => (inputs t, c.observe (runState c inputs t) (inputs t))) 0

end Verilog
