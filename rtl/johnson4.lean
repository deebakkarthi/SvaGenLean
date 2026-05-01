import SvaGenLean

open Verilog

-- Reduction XOR: fold XOR over all bits (parity)
private def bvXorReduce {n : Nat} (v : BitVec n) : Bool :=
  (List.finRange n).foldl (fun b i => b != v.getLsb i) false

-- Module: johnson4

structure Johnson4_Input where

structure Johnson4_State where
  q0 : Bool
  q1 : Bool
  q2 : Bool
  q3 : Bool

structure Johnson4_Output where
  q0 : Bool
  q1 : Bool
  q2 : Bool
  q3 : Bool

def johnson4Circuit : Circuit Johnson4_State Johnson4_Input Johnson4_Output :=
  mkSeq { q0 := false, q1 := false, q2 := false, q3 := false }
    (fun _s _inp =>
    {
    q0 := (!_s.q3)
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

