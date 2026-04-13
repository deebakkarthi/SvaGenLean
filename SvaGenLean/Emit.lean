import SvaGenLean.Ast
import SvaGenLean.Width

/-!
# Lean Model Emitter

Generates Lean 4 source representing a purely-combinational Verilog module
as a `Circuit Unit Input Output` (see `Model.lean`).

For each module:
  - `structure <ModName>_Input`  — one field per input port
  - `structure <ModName>_Output` — one field per output port
  - `def <modName>Circuit`       — `mkComb`-wrapped circuit with translated body

## Expression coverage (Verilog-1995 BNF)

Primary:
  ✓ number literal         ✓ identifier
  ✓ identifier[const]      ✓ identifier[const:const]  (constant indices only)
  ✓ concatenation          ✓ multiple concatenation
  ✗ function_call          (emits `sorry`)

Unary operators (+  -  !  ~  &  ~&  |  ^|  ^  ~^):
  ✓ +  -  !  ~
  ✓ &  ~&  |  ^|           (reduction AND/NAND/OR/NOR via BitVec equality)
  ✓ ^  ~^                  (reduction XOR/XNOR via emitted `bvXorReduce` helper)

Binary operators:
  ✓ +  -  *  /  %
  ✓ &  |  ^  ^~
  ✓ &&  ||
  ✓ ==  !=  ===  !==
  ✓ <  <=  >  >=
  ✓ <<  >>
-/

namespace Verilog

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

private def leanType (w : Width) : String :=
  if w == 1 then "Bool" else s!"BitVec {w}"

private def capitalize (s : String) : String :=
  match s.toList with
  | []      => s
  | c :: cs => String.ofList (c.toUpper :: cs)

-- ---------------------------------------------------------------------------
-- Expression translation
-- ---------------------------------------------------------------------------

/-- Translate a Verilog number literal to a Lean literal.
    1-bit binary/hex/decimal values map to `true`/`false`.
    Multi-bit based literals become `(value : BitVec n)`.
    Plain decimals are emitted as-is and rely on Lean's type inference. -/
private def translateNumber (s : String) : Option String :=
  if !s.contains '\'' then
    some s  -- plain decimal; Lean infers the type
  else
    match s.splitOn "'" with
    | [sizeStr, rest] =>
      let size := sizeStr.trimAscii.toString
      let size := if size.isEmpty then "_" else size
      let is1  := size == "1"
      match rest.toList with
      | 'b' :: digits | 'B' :: digits =>
        let ds := String.ofList digits
        if !is1 then some s!"(0b{ds} : BitVec {size})"
        else match ds with
          | "0" => some "false" | "1" => some "true" | _ => none
      | 'h' :: digits | 'H' :: digits =>
        let ds := String.ofList digits
        if !is1 then some s!"(0x{ds} : BitVec {size})"
        else match ds.toLower with
          | "0" => some "false" | "1" => some "true" | _ => none
      | 'o' :: digits | 'O' :: digits =>
        let ds := String.ofList digits
        if !is1 then some s!"(0o{ds} : BitVec {size})"
        else none  -- 1-bit octal is unusual; skip
      | 'd' :: digits | 'D' :: digits =>
        let ds := String.ofList digits
        if !is1 then some s!"({ds} : BitVec {size})"
        else match ds with
          | "0" => some "false" | "1" => some "true" | _ => none
      | _ => none
    | _ => none

/-- Map a Verilog unary operator to its Lean equivalent.
    `opW` is the bit-width of the operand (1 = Bool, else BitVec).
    Reduction ops collapse all bits to a single Bool.
    Operator tokens as produced by the parser:
      &  → all bits 1     (~~~v == 0)
      ~& → not all 1      (~~~v != 0)
      |  → any bit 1      (v != 0)
      ^| → all bits 0     (v == 0)     [NOR — BNF token]
      ^  → parity         (bvXorReduce v)
      ~^ → even parity    (!bvXorReduce v) -/
private def translateUnary (op : String) (opW : Width) (e : String) : Option String :=
  match op with
  | "+"  => some e
  | "-"  => some s!"(-{e})"
  | "!"  => some s!"(!{e})"
  -- 1-bit (Bool) complement uses `!`; multi-bit uses `~~~`
  | "~"  => if opW == 1 then some s!"(!{e})" else some s!"(~~~{e})"
  | "&"  => some s!"(~~~{e} == 0)"
  | "~&" => some s!"(~~~{e} != 0)"
  | "|"  => some s!"({e} != 0)"
  | "~|" => some s!"({e} == 0)"
  | "^|" => some s!"({e} == 0)"
  | "^"  => some s!"(bvXorReduce {e})"
  | "~^" => some s!"(!bvXorReduce {e})"
  | _    => none

/-- Map a Verilog binary operator to its Lean equivalent.
    `opW` is the bit-width of the operands (1 = Bool, else BitVec).
    For 1-bit signals the bitwise operators map to their Bool equivalents
    (`Bool.xor`, `&&`, `||`) since `HXor`/`HAnd`/`HOr` have no `Bool` instance. -/
private def translateBinary (op : String) (opW : Width) (l r : String) : Option String :=
  match op with
  | "+"           => some s!"({l} + {r})"
  | "-"           => some s!"({l} - {r})"
  | "*"           => some s!"({l}.zeroExtend _ * {r}.zeroExtend _)"
  | "/"           => some s!"({l} / {r})"
  | "%"           => some s!"({l} % {r})"
  | "&"           => if opW == 1 then some s!"({l} && {r})"  else some s!"({l} &&& {r})"
  | "|"           => if opW == 1 then some s!"({l} || {r})"  else some s!"({l} ||| {r})"
  | "^"           => if opW == 1 then some s!"(Bool.xor {l} {r})" else some s!"({l} ^^^ {r})"
  | "^~" | "~^"   => if opW == 1 then some s!"(!Bool.xor {l} {r})" else some s!"(~~~({l} ^^^ {r}))"
  | "&&"          => some s!"({l} && {r})"
  | "||"          => some s!"({l} || {r})"
  | "==" | "==="  => some s!"({l} == {r})"
  | "!=" | "!=="  => some s!"({l} != {r})"
  | "<"           => some s!"({l} < {r})"
  | "<="          => some s!"({l} <= {r})"
  | ">"           => some s!"({l} > {r})"
  | ">="          => some s!"({l} >= {r})"
  | "<<"          => some s!"({l} <<< {r})"
  | ">>"          => some s!"({l} >>> {r})"
  | _             => none

/-- Translate a Verilog expression to a Lean expression string.
    `env` is used for width inference (e.g. to detect 1-bit signals in concat).
    `inp` names the input-bundle argument in the generated `mkComb` body.
    Returns `none` for unsupported forms; callers fall back to `sorry`. -/
private def translateExpr (env : WidthEnv) (inp : String) : Expr → Option String
  | .ident i    => some s!"{inp}.{i}"
  | .number s   => translateNumber s
  | .unary op e => do
      let e' ← translateExpr env inp e
      let w  := inferWidth env e |>.getD 0
      translateUnary op w e'
  | .binary op l r => do
      let l' ← translateExpr env inp l
      let r' ← translateExpr env inp r
      -- Use the left-operand width to choose Bool vs BitVec operators
      let w  := inferWidth env l |>.getD 0
      translateBinary op w l' r'
  | .ternary cond t f => do
      let c' ← translateExpr env inp cond
      let t' ← translateExpr env inp t
      let f' ← translateExpr env inp f
      some s!"(if {c'} then {t'} else {f'})"
  | .index e (.number idx) => do
      -- Variable indices are not yet supported
      guard (!idx.contains '\'')
      let e' ← translateExpr env inp e
      some s!"({e'}.getLsb {idx})"
  | .slice e hi lo => do
      -- Only constant (non-based) bounds are supported
      let hiN ← match hi with
        | .number s => if s.contains '\'' then none else some s
        | _ => none
      let loN ← match lo with
        | .number s => if s.contains '\'' then none else some s
        | _ => none
      let e' ← translateExpr env inp e
      some s!"({e'}.extractLsb {hiN} {loN})"
  | .concat parts => do
      -- 1-bit (Bool) parts must be lifted to BitVec 1 before concatenation
      let ps ← parts.mapM fun p => do
        let s ← translateExpr env inp p
        if inferWidth env p == some 1 then some s!"(BitVec.ofBool {s})"
        else some s
      match ps with
      | []      => none
      | [x]     => some x
      | x :: xs => some (xs.foldl (fun acc p => s!"({acc} ++ {p})") x)
  | .multiconcat rep parts => do
      let n ← match rep with
        | .number s => if s.contains '\'' then none else s.toNat?
        | _ => none
      let ps ← parts.mapM fun p => do
        let s ← translateExpr env inp p
        if inferWidth env p == some 1 then some s!"(BitVec.ofBool {s})"
        else some s
      let base ← match ps with
        | []      => none
        | [x]     => some x
        | x :: xs => some (xs.foldl (fun acc p => s!"({acc} ++ {p})") x)
      some s!"(BitVec.replicate {n} {base})"
  | _ => none

-- ---------------------------------------------------------------------------
-- Per-module emission
-- ---------------------------------------------------------------------------

private def collectPorts (items : List ModuleItem) :
    List String × List String :=
  items.foldl (fun (ins, outs) item =>
    match item with
    | .input_decl  _ names => (ins ++ names, outs)
    | .output_decl _ names => (ins, outs ++ names)
    | _ => (ins, outs)) ([], [])

/-- Collect continuous assignments whose LValue is a plain identifier.
    Returns an association list mapping signal name → translated RHS. -/
private def collectAssigns (env : WidthEnv) (items : List ModuleItem) : List (String × String) :=
  items.foldl (fun acc item =>
    match item with
    | .cont_assign _ _ assigns =>
      assigns.foldl (fun a asgn =>
        match asgn.lv with
        | .ident name =>
          match translateExpr env "_inp" asgn.e with
          | some rhs => a ++ [(name, rhs)]
          | none     => a
        | _ => a) acc
    | _ => acc) []

private def emitStruct (structId : String) (env : WidthEnv)
    (ports : List String) : String :=
  let fields := ports.map fun name =>
    let w := env.lookup name |>.getD 1
    s!"  {name} : {leanType w}"
  (s!"structure {structId} where" :: fields) |> String.intercalate "\n"

private def emitCircuit (modName : String) (outputs : List String)
    (assigns : List (String × String)) : String :=
  let inTy  := capitalize modName ++ "_Input"
  let outTy := capitalize modName ++ "_Output"
  let fields := outputs.map fun n =>
    let rhs := (assigns.find? fun (k, _) => k == n).map (·.2) |>.getD "sorry"
    s!"    {n} := {rhs}"
  let body := String.intercalate "\n" fields
  s!"def {modName}Circuit : Circuit Unit {inTy} {outTy} :=\n" ++
  s!"  mkComb fun _inp =>\n  \{\n{body}\n  }"

private def emitModule (m : Module) : String :=
  let (inputs, outputs) := collectPorts m.items
  let env      := buildWidthEnv m.items
  let assigns  := collectAssigns env m.items
  let inStruct := emitStruct (capitalize m.name ++ "_Input")  env inputs
  let outStruct:= emitStruct (capitalize m.name ++ "_Output") env outputs
  let circuit  := emitCircuit m.name outputs assigns
  [ s!"-- Module: {m.name}", inStruct, outStruct, circuit ]
    |> String.intercalate "\n\n"

-- ---------------------------------------------------------------------------
-- Top-level entry point
-- ---------------------------------------------------------------------------

/-- Emit a complete Lean 4 source file modelling every module in `src`
    as a `Circuit Unit Input Output` via `mkComb`. -/
-- Helper emitted into every generated file for XOR/XNOR reduction.
private def bvXorReduceHelper : String :=
  "-- Reduction XOR: fold XOR over all bits (parity)\n" ++
  "private def bvXorReduce {n : Nat} (v : BitVec n) : Bool :=\n" ++
  "  (List.finRange n).foldl (fun b i => b != v.getLsb i) false"

def emitLean (src : SourceText) : String :=
  let header := "import SvaGenLean\n\nopen Verilog\n"
  let mods   := src.filterMap fun | .module_ m => some (emitModule m)
  header ++ "\n" ++ bvXorReduceHelper ++ "\n\n" ++
  String.intercalate "\n\n" mods ++ "\n"

end Verilog
