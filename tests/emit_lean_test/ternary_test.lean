def main : IO Unit := do
  IO.println (ternaryCircuit.observe () { sel := false, a := 10,  b := 20  }).y.toNat
  IO.println (ternaryCircuit.observe () { sel := true,  a := 10,  b := 20  }).y.toNat
  IO.println (ternaryCircuit.observe () { sel := false, a := 170, b := 85  }).y.toNat
  IO.println (ternaryCircuit.observe () { sel := true,  a := 170, b := 85  }).y.toNat
  IO.println (ternaryCircuit.observe () { sel := false, a := 0,   b := 255 }).y.toNat
