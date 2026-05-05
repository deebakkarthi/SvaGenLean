import SvaGenLean

open Verilog

-- Reduction XOR: fold XOR over all bits (parity)
private def bvXorReduce {n : Nat} (v : BitVec n) : Bool :=
  (List.finRange n).foldl (fun b i => b != v.getLsb i) false

-- Module: fifo4

structure Fifo4_Input where
  wr_en : Bool
  rd_en : Bool
  din : BitVec 8

structure Fifo4_State where
  d0 : BitVec 8
  d1 : BitVec 8
  d2 : BitVec 8
  d3 : BitVec 8
  wptr : BitVec 2
  rptr : BitVec 2
  cnt : BitVec 3

structure Fifo4_Output where
  dout : BitVec 8
  full : Bool
  empty : Bool

def fifo4Circuit : Circuit Fifo4_State Fifo4_Input Fifo4_Output :=
  mkSeq { d0 := (0 : BitVec 8), d1 := (0 : BitVec 8), d2 := (0 : BitVec 8), d3 := (0 : BitVec 8), wptr := (0 : BitVec 2), rptr := (0 : BitVec 2), cnt := (0 : BitVec 3) }
    (fun _s _inp =>
    {
    d0 := (if ((_inp.wr_en && (_s.cnt != (4 : BitVec 3))) && (_s.wptr == (0 : BitVec 2))) then _inp.din else _s.d0)
    d1 := (if ((_inp.wr_en && (_s.cnt != (4 : BitVec 3))) && (_s.wptr == (1 : BitVec 2))) then _inp.din else _s.d1)
    d2 := (if ((_inp.wr_en && (_s.cnt != (4 : BitVec 3))) && (_s.wptr == (2 : BitVec 2))) then _inp.din else _s.d2)
    d3 := (if ((_inp.wr_en && (_s.cnt != (4 : BitVec 3))) && (_s.wptr == (3 : BitVec 2))) then _inp.din else _s.d3)
    wptr := (if (_inp.wr_en && (_s.cnt != (4 : BitVec 3))) then (_s.wptr + (1 : BitVec 2)) else _s.wptr)
    rptr := (if (_inp.rd_en && (_s.cnt != (0 : BitVec 3))) then (_s.rptr + (1 : BitVec 2)) else _s.rptr)
    cnt := ((_s.cnt + (if (_inp.wr_en && (_s.cnt != (4 : BitVec 3))) then (1 : BitVec 3) else (0 : BitVec 3))) - (if (_inp.rd_en && (_s.cnt != (0 : BitVec 3))) then (1 : BitVec 3) else (0 : BitVec 3)))
    })
    (fun _s _inp =>
    {
    dout := (if (_s.rptr == (0 : BitVec 2)) then _s.d0 else (if (_s.rptr == (1 : BitVec 2)) then _s.d1 else (if (_s.rptr == (2 : BitVec 2)) then _s.d2 else _s.d3)))
    full := (_s.cnt == (4 : BitVec 3))
    empty := (_s.cnt == (0 : BitVec 3))
    })

