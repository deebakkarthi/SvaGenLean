import SvaGenLean.Ast

/-!
# Width Inference

Infers the bit-width of every signal and expression in a Verilog module.

Width 1  →  `Bool` in generated Lean code
Width n  →  `BitVec n` in generated Lean code

The pass produces a `WidthEnv` (a name → width map) from the module's
port and wire/reg declarations.  Expression widths are inferred bottom-up
from that environment.
-/

namespace Verilog

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------

/-- Bit-width of a signal or expression. -/
abbrev Width := Nat

/-- Width environment: ordered association list from identifiers to widths.
    Earlier entries shadow later ones (insert prepends). -/
abbrev WidthEnv := List (String × Width)

def WidthEnv.lookup (env : WidthEnv) (name : String) : Option Width :=
  (env.find? fun (k, _) => k == name) |>.map (·.2)

def WidthEnv.insert (env : WidthEnv) (name : String) (w : Width) : WidthEnv :=
  (name, w) :: env.filter fun (k, _) => k != name

-- ---------------------------------------------------------------------------
-- Constant expression evaluator (for range bounds)
-- ---------------------------------------------------------------------------

/-- Try to reduce an expression to a concrete `Nat`.
    Only handles plain decimal literals since range bounds in Verilog-1995
    are almost always simple integer constants. -/
private def evalConst : Expr → Option Nat
  | .number s =>
    -- Reject based literals (they contain a single-quote, e.g. "8'hFF")
    if s.contains '\'' then none else s.toNat?
  | _ => none

-- ---------------------------------------------------------------------------
-- Range helpers
-- ---------------------------------------------------------------------------

/-- Width of a `[hi : lo]` range annotation. -/
def rangeWidth (r : Range) : Option Width := do
  let hi ← evalConst r.hi
  let lo ← evalConst r.lo
  guard (hi >= lo)
  return hi - lo + 1

/-- Width of an optional range annotation; `none` means the signal is 1-bit. -/
def optRangeWidth (r : Option Range) : Option Width :=
  match r with
  | none   => some 1
  | some r => rangeWidth r

-- ---------------------------------------------------------------------------
-- Expression width inference
-- ---------------------------------------------------------------------------

/-- Infer the bit-width of an expression given a width environment.
    Returns `none` when width cannot be determined statically. -/
partial def inferWidth (env : WidthEnv) : Expr → Option Width
  | .number s =>
    if s.contains '\'' then
      -- Based literal: the size prefix is the width, e.g. "8'hFF" → 8
      (s.splitOn "'" |>.head?).bind (fun pfx => pfx.trimAscii.toString.toNat?)
    else
      -- Plain decimal: Verilog context-determines width; use 32 as default
      some 32
  | .string _  => some 8   -- one character / byte
  | .ident  i  => env.lookup i
  | .unary op e =>
    match op with
    | "&" | "~&" | "|" | "~|" | "^" | "~^" => some 1  -- reduction operators
    | _ => inferWidth env e
  | .binary op l r =>
    match op with
    -- Relational / logical ops always produce a 1-bit result
    | "==" | "!=" | "===" | "!==" | "<" | "<=" | ">" | ">="
    | "&&" | "||" => some 1
    -- Bitwise / arithmetic: result is as wide as the wider operand
    | _ =>
      match inferWidth env l, inferWidth env r with
      | some wl, some wr => some (max wl wr)
      | some wl, none    => some wl
      | none,    some wr => some wr
      | none,    none    => none
  | .ternary _ t f =>
    -- Width is that of the selected branch (both should match; take whichever
    -- is known, preferring the then-branch)
    match inferWidth env t with
    | some w => some w
    | none   => inferWidth env f
  | .index _ _ => some 1        -- single-bit select
  | .slice _ hi lo =>
    match evalConst hi, evalConst lo with
    | some h, some l => if h >= l then some (h - l + 1) else none
    | _, _           => none
  | .concat parts =>
    -- Concatenation: sum of part widths
    parts.foldlM (fun acc e => (inferWidth env e).map (· + acc)) 0
  | .multiconcat rep parts =>
    let partW := parts.foldlM (fun acc e => (inferWidth env e).map (· + acc)) 0
    match evalConst rep, partW with
    | some r, some w => some (r * w)
    | _, _           => none
  | .call _ _ | .syscall _ _ => none  -- cannot determine without more context

-- ---------------------------------------------------------------------------
-- Build a WidthEnv from module-item declarations
-- ---------------------------------------------------------------------------

private def addNames (env : WidthEnv) (w : Width) (names : List String) :
    WidthEnv :=
  names.foldl (fun e n => e.insert n w) env

private def addRegVars (env : WidthEnv) (w : Width) (vars : List RegisterVar) :
    WidthEnv :=
  vars.foldl (fun e v =>
    match v with
    | .scalar name      => e.insert name w
    | .memory name _ _  => e.insert name w) env

/-- Build a `WidthEnv` from the declaration items of a module.
    Only port, wire, and register declarations contribute widths; behavioral
    items (`always`, `assign`, etc.) are ignored here. -/
def buildWidthEnv (items : List ModuleItem) : WidthEnv :=
  items.foldl step []
where
  step (env : WidthEnv) : ModuleItem → WidthEnv
    | .input_decl  r names => addNames env (optRangeWidth r |>.getD 1) names
    | .output_decl r names => addNames env (optRangeWidth r |>.getD 1) names
    | .inout_decl  r names => addNames env (optRangeWidth r |>.getD 1) names
    | .net_decl _ _ er _ names =>
        let w := match er with
          | some (.range r) => rangeWidth r |>.getD 1
          | some (.scalared r) => rangeWidth r |>.getD 1
          | some (.vectored r) => rangeWidth r |>.getD 1
          | none => 1
        addNames env w names
    | .reg_decl r vars =>
        addRegVars env (optRangeWidth r |>.getD 1) vars
    | .integer_decl vars => addRegVars env 32 vars
    | .time_decl    vars => addRegVars env 64 vars
    | .real_decl   names => addNames  env 64 names
    | .param_decl assigns | .param_override assigns =>
        assigns.foldl (fun e a =>
          match a.lv with
          | .ident n =>
            let w := inferWidth e a.e |>.getD 32
            e.insert n w
          | _ => e) env
    | _ => env

end Verilog
