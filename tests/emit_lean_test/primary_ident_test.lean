def main : IO Unit := do
  IO.println (primary_identCircuit.observe () { a := 0   }).y.toNat
  IO.println (primary_identCircuit.observe () { a := 1   }).y.toNat
  IO.println (primary_identCircuit.observe () { a := 85  }).y.toNat
  IO.println (primary_identCircuit.observe () { a := 170 }).y.toNat
  IO.println (primary_identCircuit.observe () { a := 255 }).y.toNat
