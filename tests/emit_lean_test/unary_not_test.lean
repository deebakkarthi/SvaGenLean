private def boolToNat (b : Bool) : Nat := if b then 1 else 0

def main : IO Unit := do
  IO.println (boolToNat (unary_notCircuit.observe () { a := false }).y)
  IO.println (boolToNat (unary_notCircuit.observe () { a := true  }).y)
  IO.println (boolToNat (unary_notCircuit.observe () { a := false }).y)
  IO.println (boolToNat (unary_notCircuit.observe () { a := true  }).y)
  IO.println (boolToNat (unary_notCircuit.observe () { a := false }).y)
