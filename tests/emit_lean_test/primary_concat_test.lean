def main : IO Unit := do
  IO.println (primary_concatCircuit.observe () { a := 15, b := 0,  c := false }).y.toNat
  IO.println (primary_concatCircuit.observe () { a := 0,  b := 15, c := true  }).y.toNat
  IO.println (primary_concatCircuit.observe () { a := 5,  b := 10, c := false }).y.toNat
  IO.println (primary_concatCircuit.observe () { a := 15, b := 15, c := true  }).y.toNat
  IO.println (primary_concatCircuit.observe () { a := 8,  b := 7,  c := false }).y.toNat
