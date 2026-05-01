import SvaGenLean

open Verilog LTL

-- D flip-flop (no reset)
structure DFF_State  where q : Bool
structure DFF_Input  where d : Bool
structure DFF_Output where q : Bool

def dffCircuit : Circuit DFF_State DFF_Input DFF_Output :=
  mkSeq { q := false }
        (fun _s i => { q := i.d })
        (fun s  _ => { q := s.q })

-- "If d is high at time t, q is high at time t+1"
def dff_prop : Formula (DFF_Input × DFF_Output) :=
  G (imp (atom fun io => io.1.d)
         (X  (atom fun io => io.2.q)))

theorem dff_correct : dffCircuit.satisfies dff_prop := by
  intro inputs k hd
  simp only [X, atom, runState, dffCircuit, mkSeq]
  exact hd
