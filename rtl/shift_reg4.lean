import SvaGenLean

open Verilog

-- Reduction XOR: fold XOR over all bits (parity)
private def bvXorReduce {n : Nat} (v : BitVec n) : Bool :=
  (List.finRange n).foldl (fun b i => b != v.getLsb i) false

-- Module: shift_reg4

structure Shift_reg4_Input where
  sin : Bool

structure Shift_reg4_State where
  q0 : Bool
  q1 : Bool
  q2 : Bool
  q3 : Bool

structure Shift_reg4_Output where
  q0 : Bool
  q1 : Bool
  q2 : Bool
  q3 : Bool

def shift_reg4Circuit : Circuit Shift_reg4_State Shift_reg4_Input Shift_reg4_Output :=
  mkSeq { q0 := false, q1 := false, q2 := false, q3 := false }
    (fun _s _inp =>
    {
    q0 := _inp.sin
    q1 := _s.q0
    q2 := _s.q1
    q3 := _s.q2
    })
    (fun _s _inp =>
    {
    q0 := _s.q0
    q1 := _s.q1
    q2 := _s.q2
    q3 := _s.q3
    })

