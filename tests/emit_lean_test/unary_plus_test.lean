def main : IO Unit := do
  IO.println (unary_plusCircuit.observe () { a := 0   }).y.toNat
  IO.println (unary_plusCircuit.observe () { a := 1   }).y.toNat
  IO.println (unary_plusCircuit.observe () { a := 85  }).y.toNat
  IO.println (unary_plusCircuit.observe () { a := 170 }).y.toNat
  IO.println (unary_plusCircuit.observe () { a := 255 }).y.toNat
