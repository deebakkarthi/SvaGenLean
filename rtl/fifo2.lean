import SvaGenLean

open Verilog

-- Reduction XOR: fold XOR over all bits (parity)
private def bvXorReduce {n : Nat} (v : BitVec n) : Bool :=
  (List.finRange n).foldl (fun b i => b != v.getLsb i) false

-- Module: fifo2

structure Fifo2_Input where
  wr_en : Bool
  rd_en : Bool
  din : Bool

structure Fifo2_State where
  d0 : Bool
  d1 : Bool
  wptr : Bool
  rptr : Bool
  cnt : BitVec 2

structure Fifo2_Output where
  dout : Bool
  full : Bool
  empty : Bool

def fifo2Circuit : Circuit Fifo2_State Fifo2_Input Fifo2_Output :=
  mkSeq { d0 := false, d1 := false, wptr := false, rptr := false, cnt := (0 : BitVec 2) }
    (fun _s _inp =>
    {
    d0 := (if ((_inp.wr_en && (_s.cnt != (2 : BitVec 2))) && (!_s.wptr)) then _inp.din else _s.d0)
    d1 := (if ((_inp.wr_en && (_s.cnt != (2 : BitVec 2))) && _s.wptr) then _inp.din else _s.d1)
    wptr := (if (_inp.wr_en && (_s.cnt != (2 : BitVec 2))) then (!_s.wptr) else _s.wptr)
    rptr := (if (_inp.rd_en && (_s.cnt != (0 : BitVec 2))) then (!_s.rptr) else _s.rptr)
    cnt := ((_s.cnt + (if (_inp.wr_en && (_s.cnt != (2 : BitVec 2))) then (1 : BitVec 2) else (0 : BitVec 2))) - (if (_inp.rd_en && (_s.cnt != (0 : BitVec 2))) then (1 : BitVec 2) else (0 : BitVec 2)))
    })
    (fun _s _inp =>
    {
    dout := (if _s.rptr then _s.d1 else _s.d0)
    full := (_s.cnt == (2 : BitVec 2))
    empty := (_s.cnt == (0 : BitVec 2))
    })

