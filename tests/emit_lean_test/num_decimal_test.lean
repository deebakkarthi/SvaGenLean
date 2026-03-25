def main : IO Unit := do
  IO.println (num_decimalCircuit.observe () {}).y.toNat
