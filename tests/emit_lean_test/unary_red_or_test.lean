private def boolToNat (b : Bool) : Nat := if b then 1 else 0

def main : IO Unit := do
  IO.println (boolToNat (unary_red_orCircuit.observe () { a := 0   }).y)
  IO.println (boolToNat (unary_red_orCircuit.observe () { a := 255 }).y)
  IO.println (boolToNat (unary_red_orCircuit.observe () { a := 85  }).y)
  IO.println (boolToNat (unary_red_orCircuit.observe () { a := 170 }).y)
  IO.println (boolToNat (unary_red_orCircuit.observe () { a := 127 }).y)
