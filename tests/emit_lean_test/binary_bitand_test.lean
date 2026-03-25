def main : IO Unit := do
  IO.println (binary_bitandCircuit.observe () { a := 10,  b := 20  }).y.toNat
  IO.println (binary_bitandCircuit.observe () { a := 255, b := 0   }).y.toNat
  IO.println (binary_bitandCircuit.observe () { a := 170, b := 85  }).y.toNat
  IO.println (binary_bitandCircuit.observe () { a := 128, b := 64  }).y.toNat
  IO.println (binary_bitandCircuit.observe () { a := 255, b := 255 }).y.toNat
