import SvaGenLean

open Verilog

-- Reduction XOR: fold XOR over all bits (parity)
private def bvXorReduce {n : Nat} (v : BitVec n) : Bool :=
  (List.finRange n).foldl (fun b i => b != v.getLsb i) false

-- Module: half_adder

structure Half_adder_Input where
  a : Bool
  b : Bool

structure Half_adder_Output where
  sum : Bool
  carry : Bool

def half_adderCircuit : Circuit Unit Half_adder_Input Half_adder_Output :=
  mkComb fun _inp =>
  {
    sum := (Bool.xor _inp.a _inp.b)
    carry := (_inp.a && _inp.b)
  }

