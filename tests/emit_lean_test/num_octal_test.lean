def main : IO Unit := do
  IO.println (num_octalCircuit.observe () {}).y.toNat
