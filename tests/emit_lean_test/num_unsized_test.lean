def main : IO Unit := do
  IO.println (num_unsizedCircuit.observe () {}).y.toNat
