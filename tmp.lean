-- Equality of records reduces to equality of fields
@[ext] structure Pair where
  fst : Nat
  snd : Nat

example (p q : Pair) (h1 : p.fst = q.fst) (h2 : p.snd = q.snd) : p = q := by
  ext
  · exact h1
  · exact h2
