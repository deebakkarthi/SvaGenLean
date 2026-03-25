private def boolToNat (b : Bool) : Nat := if b then 1 else 0

def main : IO Unit := do
  IO.println (boolToNat (binary_logandCircuit.observe () { a := false, b := false }).y)
  IO.println (boolToNat (binary_logandCircuit.observe () { a := false, b := true  }).y)
  IO.println (boolToNat (binary_logandCircuit.observe () { a := true,  b := false }).y)
  IO.println (boolToNat (binary_logandCircuit.observe () { a := true,  b := true  }).y)
  IO.println (boolToNat (binary_logandCircuit.observe () { a := true,  b := false }).y)
