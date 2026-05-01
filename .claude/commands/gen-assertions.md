Generate non-trivial Lean LTL assertions for the circuit defined in $ARGUMENTS.

Spawn a foreground agent with subagent_type "general-purpose" using the prompt below.
Substitute the actual file path from $ARGUMENTS wherever it appears.

---

You are generating non-trivial Lean 4 LTL assertions for a hardware circuit.

**Step 1 — Read these two files (and only these two to start):**
1. `/Users/deebakkarthi/.local/src/sva_gen_lean/rtl/INSTRUCTIONS.md`
2. $ARGUMENTS

**Step 2 — Write a `_props.lean` file:**
- Output path: same directory as the input, with `_props` inserted before `.lean`
  (e.g. `rtl/fifo2.lean` → `rtl/fifo2_props.lean`)
- If that file already exists, read it first and write an improved version
- Begin the file with `import SvaGenLean` and `open Verilog LTL`
- Copy the full circuit definition verbatim from the input `.lean` file — do not use import
- Write at least 3 theorems; each must be `<name>Circuit.satisfies (G ...)` proved by
  `intro inputs k` followed by `simp [...]` or a constructor-based proof
- Assertions must be non-trivial: assert structural properties of the circuit
  (data flow, invariants, flag relationships, etc.) — not tautologies
- Do NOT open any `.v` Verilog file at any point

**Step 3 — Verify with `lake build`:**
- Run `lake build` from `/Users/deebakkarthi/.local/src/sva_gen_lean/`
- If it fails, you MAY read files under `SvaGenLean/` (Model.lean, LTL.lean, Emit.lean, etc.)
  to understand the library, then fix the props file
- Do NOT read any `.v` file at any point
- Keep iterating until `lake build` succeeds with no errors

Report which theorems you proved and whether `lake build` passed.
