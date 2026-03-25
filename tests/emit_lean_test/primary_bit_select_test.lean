private def boolToNat (b : Bool) : Nat := if b then 1 else 0

def main : IO Unit := do
  IO.println (boolToNat (primary_bit_selectCircuit.observe () { a := 8   }).y)
  IO.println (boolToNat (primary_bit_selectCircuit.observe () { a := 247 }).y)
  IO.println (boolToNat (primary_bit_selectCircuit.observe () { a := 0   }).y)
  IO.println (boolToNat (primary_bit_selectCircuit.observe () { a := 255 }).y)
  IO.println (boolToNat (primary_bit_selectCircuit.observe () { a := 170 }).y)
