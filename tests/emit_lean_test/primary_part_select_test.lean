def main : IO Unit := do
  let run a := primary_part_selectCircuit.observe () { a }
  let p1 := run 171; IO.println p1.hi.toNat; IO.println p1.lo.toNat
  let p2 := run 255; IO.println p2.hi.toNat; IO.println p2.lo.toNat
  let p3 := run 0;   IO.println p3.hi.toNat; IO.println p3.lo.toNat
  let p4 := run 18;  IO.println p4.hi.toNat; IO.println p4.lo.toNat
  let p5 := run 90;  IO.println p5.hi.toNat; IO.println p5.lo.toNat
