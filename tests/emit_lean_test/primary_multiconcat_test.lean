def main : IO Unit := do
  IO.println (primary_multiconcatCircuit.observe () { a := 5  }).y.toNat
  IO.println (primary_multiconcatCircuit.observe () { a := 15 }).y.toNat
  IO.println (primary_multiconcatCircuit.observe () { a := 0  }).y.toNat
  IO.println (primary_multiconcatCircuit.observe () { a := 10 }).y.toNat
  IO.println (primary_multiconcatCircuit.observe () { a := 3  }).y.toNat
