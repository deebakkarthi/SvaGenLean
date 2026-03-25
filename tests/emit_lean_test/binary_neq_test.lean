private def boolToNat (b : Bool) : Nat := if b then 1 else 0

def main : IO Unit := do
  IO.println (boolToNat (binary_neqCircuit.observe () { a := 10,  b := 20  }).y)
  IO.println (boolToNat (binary_neqCircuit.observe () { a := 10,  b := 10  }).y)
  IO.println (boolToNat (binary_neqCircuit.observe () { a := 0,   b := 0   }).y)
  IO.println (boolToNat (binary_neqCircuit.observe () { a := 170, b := 85  }).y)
  IO.println (boolToNat (binary_neqCircuit.observe () { a := 255, b := 255 }).y)
