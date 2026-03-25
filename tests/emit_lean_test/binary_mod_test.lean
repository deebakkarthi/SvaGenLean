def main : IO Unit := do
  IO.println (binary_modCircuit.observe () { a := 10,  b := 3  }).y.toNat
  IO.println (binary_modCircuit.observe () { a := 255, b := 10 }).y.toNat
  IO.println (binary_modCircuit.observe () { a := 100, b := 7  }).y.toNat
  IO.println (binary_modCircuit.observe () { a := 128, b := 16 }).y.toNat
  IO.println (binary_modCircuit.observe () { a := 7,   b := 2  }).y.toNat
