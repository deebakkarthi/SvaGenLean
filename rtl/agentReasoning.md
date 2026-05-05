# Analysis of `fifo2_wptr_increments_BUGGY` Proof Failure

## 1. What the Theorem Claims

The theorem states that on every valid write cycle — meaning `wr_en = true` at step `k` and the FIFO is not full (`cnt ≠ 2`) — the write pointer `wptr` increments by exactly 1 when treated as a natural number:

```
Bool.toNat (wptr at k+1) = Bool.toNat (wptr at k) + 1
```

`Bool.toNat` maps `false ↦ 0` and `true ↦ 1`.

The claim is that `wptr` behaves like a monotonically increasing counter. This is false. `wptr` is a single-bit Boolean that toggles on each write: `false → true → false → …`. It is not an incrementing counter; it is a 1-bit wrap-around pointer.

---

## 2. What the Proof Attempt Did

The proof calls `simp` followed by `omega`.

**`simp only [...]`** unfolds the circuit definitions (`runState`, `fifo2Circuit`, `mkSeq`) and uses the hypotheses `hwr : wr_en = true` and `hnotfull : cnt ≠ 2` to simplify the conditional expression for `wptr` at step `k+1`. After `simp`, the write condition `wr_en && cnt != 2` is known to be true, so the `ite` expression collapses: the next `wptr` is `!wptr_k` (the Boolean negation of the current pointer).

After simplification the goal becomes an arithmetic statement about natural numbers — specifically something of the form `(!wptr_k).toNat = wptr_k.toNat + 1` — which `omega` is then asked to prove over the integers/naturals.

**`omega`** is a decision procedure for linear arithmetic over integers and naturals. It has no way to reason about `Bool.toNat` applied to an unknown `Bool`. At this point `wptr_k` is still an arbitrary `Bool` whose value is unknown (it depends on the full history `inputs 0 .. inputs k`), so `omega` sees two opaque natural-number variables `a` and `b` with weak constraints and must try to derive a contradiction or a proof — which it cannot.

---

## 3. What the Counterexample Tells Us

After `simp`, the goal has been reduced to a purely arithmetic statement. `omega` names the key values:

- **`a`** = `(runState fifo2Circuit inputs k).wptr.toNat`  
  This is the natural-number representation of the current `wptr`: either 0 (`false`) or 1 (`true`).

- **`b`** = `(if ¬(cnt = 2) then !(wptr) else wptr).toNat`  
  Under the hypothesis `hnotfull`, the condition `¬(cnt = 2)` is true, so this simplifies to `(!wptr).toNat`, the natural-number representation of the *next* `wptr`.

The constraints `omega` reports are:

| Constraint | Meaning |
|---|---|
| `a ≥ 0` | `wptr_k.toNat` is a natural number (trivially true) |
| `b ≥ 0` | `(!wptr_k).toNat` is a natural number (trivially true) |
| `a - b ≥ 0` | `wptr_k.toNat ≥ (!wptr_k).toNat` |

These constraints are **satisfiable** (not contradictory). For example `a = 1, b = 0` satisfies all three, yet the goal `b = a + 1` becomes `0 = 2`, which is false. `omega` is reporting a witness to satisfiability of the *negation* of the goal — i.e., a point where the arithmetic statement fails — not a proof that the constraints are contradictory.

Crucially, `omega` knows nothing about the relationship between `a` (= `wptr.toNat`) and `b` (= `(!wptr).toNat`). It does not know they must sum to 1, or that exactly one is 0 and the other is 1, because that knowledge requires understanding `Bool` negation and `Bool.toNat`, neither of which are in the scope of `omega`. From `omega`'s perspective `a` and `b` are independent non-negative integers with no fixed bound. The goal `b = a + 1` is not provable from the given constraints alone, so `omega` gives up.

---

## 4. Why Omega Cannot Prove the Goal

There are two distinct reasons, and they compound:

### 4a. The Theorem Is False

The fundamental problem is that the theorem is **wrong**. `wptr` is a 1-bit toggle flip-flop. Its transition function on a valid write is:

```
wptr_{k+1} = !wptr_k
```

In `Bool.toNat` arithmetic:
- If `wptr_k = false` (value 0), then `wptr_{k+1} = true` (value 1), and `1 = 0 + 1` ✓
- If `wptr_k = true` (value 1), then `wptr_{k+1} = false` (value 0), and `0 ≠ 1 + 1 = 2` ✗

The theorem is only true in one of the two cases. The proof fails because no valid proof exists.

### 4b. The Strategy Cannot Bridge the Bool–Nat Gap

Even setting aside falsity, the proof strategy is insufficient. After `simp` reduces the goal, the statement involves `Bool.toNat` applied to `!wptr_k` and `wptr_k`. `omega` operates in the theory of linear integer/natural arithmetic and has no axioms about `Bool`, `Bool.not`, or `Bool.toNat`. It cannot derive `Bool.toNat (!b) = 1 - Bool.toNat b` on its own. Even if the theorem *were* true (which it is not), this step would require a dedicated lemma about `Bool.toNat` and `Bool.not` before `omega` could close the goal.

---

## 5. The Concrete Counterexample

Take a sequence of two consecutive write operations starting from the initial state:

```
inputs : Nat → Fifo2_Input
inputs 0 = { wr_en := true, rd_en := false, din := false }
inputs 1 = { wr_en := true, rd_en := false, din := false }
k = 1
```

**Trace:**

| Step | `wptr` | `cnt` | `wr_en` |
|---|---|---|---|
| 0 (init) | `false` (0) | `0#2` | — |
| 1 (after step 0) | `true` (1) | `1#2` | `true` |
| 2 (after step 1) | `false` (0) | `2#2` | `true` |

At `k = 1`:
- Hypothesis `hwr`: `(inputs 1).wr_en = true` ✓
- Hypothesis `hnotfull`: `(runState … 1).cnt = 1#2 ≠ 2#2` ✓

Goal requires: `Bool.toNat (wptr at 2) = Bool.toNat (wptr at 1) + 1`

Substituting: `Bool.toNat false = Bool.toNat true + 1`, i.e., `0 = 1 + 1 = 2`. This is false.

This is exactly the wrap-around case. After the first write toggles `wptr` from 0 to 1, the second write toggles it back from 1 to 0. The theorem's claim that the natural-number value always increases by 1 is refuted.

---

## 6. Helpfulness and Clarity of the Error Message

The error message is **moderately informative to an expert but quite opaque to a non-expert**. Here is a breakdown:

### What the message gets right

- It clearly states which tactic failed (`omega`) and at which line (`166:2`).
- It provides the counterexample constraints (`b ≥ 0`, `a ≥ 0`, `a - b ≥ 0`), which together allow `a = 1, b = 0`, a concrete witness to the goal's failure.
- It gives the full term for `a` and `b`, so a careful reader can reconstruct what each represents.

### What makes it hard to read

- The terms for `a` and `b` are **fully unfolded** — the circuit's `step` and `observe` functions are inlined in their entirety, spanning ~50 lines. A reader must mentally refold this back into `(runState fifo2Circuit inputs k).wptr` and `(!wptr).toNat` to understand the structure.
- The phrase "a possible counterexample *may* satisfy the constraints" is cautious to the point of being misleading. `omega` is reporting that the constraints are satisfiable in a way that falsifies the goal, which is strong evidence the *theorem itself* is false — but the message does not say this plainly.
- The constraints (`b ≥ 0`, `a ≥ 0`, `a - b ≥ 0`) look almost trivial at first glance. A non-expert sees three non-negativity conditions and does not immediately see how they witness the falsity of `b = a + 1`. The key insight — that `a = 1, b = 0` satisfies all three but makes `b = a + 1` false — requires arithmetic reasoning that the message leaves entirely to the reader.
- The message gives no hint about **why** omega could not prove the goal. It does not distinguish between "omega lacks a needed lemma about Bool.toNat" and "the theorem is false." Both result in the same error. To determine which is the cause, the reader must understand the domain.

### Summary

For someone who already understands that `wptr` is a Boolean toggle and that `Bool.toNat` maps `true → 1, false → 0`, the error message is enough: `a - b ≥ 0` with `a = Bool.toNat (wptr_k)` and `b = Bool.toNat (!wptr_k)` immediately suggests the `wptr_k = true` case where `b = 0` and `a = 1`, giving `a - b = 1 ≥ 0` but `b ≠ a + 1`. For someone who does not already know the theorem is false, the message is hard to interpret: the unfolded terms are intimidating, the constraints look trivial, and there is no explicit signal that the theorem statement itself is the problem rather than the proof strategy.
