private def boolToNat (b : Bool) : Nat := if b then 1 else 0

def main : IO Unit := do
  let out := num_binaryCircuit.observe () {}
  IO.println out.y.toNat
  IO.println (boolToNat out.z)
