def main : IO Unit := do
  IO.println (binary_shrCircuit.observe () { a := 10,  amt := 1 }).y.toNat
  IO.println (binary_shrCircuit.observe () { a := 170, amt := 2 }).y.toNat
  IO.println (binary_shrCircuit.observe () { a := 255, amt := 0 }).y.toNat
  IO.println (binary_shrCircuit.observe () { a := 128, amt := 3 }).y.toNat
  IO.println (binary_shrCircuit.observe () { a := 1,   amt := 7 }).y.toNat
