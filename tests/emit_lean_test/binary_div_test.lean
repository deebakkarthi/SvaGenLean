def main : IO Unit := do
  IO.println (binary_divCircuit.observe () { a := 20,  b := 5  }).y.toNat
  IO.println (binary_divCircuit.observe () { a := 100, b := 10 }).y.toNat
  IO.println (binary_divCircuit.observe () { a := 255, b := 3  }).y.toNat
  IO.println (binary_divCircuit.observe () { a := 200, b := 8  }).y.toNat
  IO.println (binary_divCircuit.observe () { a := 7,   b := 2  }).y.toNat
