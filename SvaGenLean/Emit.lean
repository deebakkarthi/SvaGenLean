import SvaGenLean.Ast
import SvaGenLean.Width

/-!
# Lean Model Emitter

Generates Lean 4 source for combinational and sequential Verilog modules.

Combinational modules become `Circuit Unit Input Output` via `mkComb`.
Sequential modules (single posedge clock, non-blocking assignments only)
become `Circuit State Input Output` via `mkSeq`.

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

private def defaultInit (w : Width) : String :=
  if w == 1 then "false" else s!"(0 : BitVec {w})"

-- ---------------------------------------------------------------------------
-- Expression translation
-- ---------------------------------------------------------------------------

/-- Translate a Verilog number literal to a Lean literal. -/
private def translateNumber (s : String) : Option String :=
  if !s.contains '\'' then
    some s
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
        else none
      | 'd' :: digits | 'D' :: digits =>
        let ds := String.ofList digits
        if !is1 then some s!"({ds} : BitVec {size})"
        else match ds with
          | "0" => some "false" | "1" => some "true" | _ => none
      | _ => none
    | _ => none

private def translateUnary (op : String) (opW : Width) (e : String) : Option String :=
  match op with
  | "+"  => some e
  | "-"  => some s!"(-{e})"
  | "!"  => some s!"(!{e})"
  | "~"  => if opW == 1 then some s!"(!{e})" else some s!"(~~~{e})"
  | "&"  => some s!"(~~~{e} == 0)"
  | "~&" => some s!"(~~~{e} != 0)"
  | "|"  => some s!"({e} != 0)"
  | "~|" => some s!"({e} == 0)"
  | "^|" => some s!"({e} == 0)"
  | "^"  => some s!"(bvXorReduce {e})"
  | "~^" => some s!"(!bvXorReduce {e})"
  | _    => none

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
    Identifiers in `regs` are read from `_s`; all others from `inp`. -/
private def translateExpr (env : WidthEnv) (inp : String) (state : String)
    (regs : List String) : Expr → Option String
  | .ident i    =>
      if regs.contains i then some s!"{state}.{i}" else some s!"{inp}.{i}"
  | .number s   => translateNumber s
  | .unary op e => do
      let e' ← translateExpr env inp state regs e
      let w  := inferWidth env e |>.getD 0
      translateUnary op w e'
  | .binary op l r => do
      let l' ← translateExpr env inp state regs l
      let r' ← translateExpr env inp state regs r
      let w  := inferWidth env l |>.getD 0
      translateBinary op w l' r'
  | .ternary cond t f => do
      let c' ← translateExpr env inp state regs cond
      let t' ← translateExpr env inp state regs t
      let f' ← translateExpr env inp state regs f
      some s!"(if {c'} then {t'} else {f'})"
  | .index e (.number idx) => do
      guard (!idx.contains '\'')
      let e' ← translateExpr env inp state regs e
      some s!"({e'}.getLsb {idx})"
  | .slice e hi lo => do
      let hiN ← match hi with
        | .number s => if s.contains '\'' then none else some s
        | _ => none
      let loN ← match lo with
        | .number s => if s.contains '\'' then none else some s
        | _ => none
      let e' ← translateExpr env inp state regs e
      some s!"({e'}.extractLsb {hiN} {loN})"
  | .concat parts => do
      let ps ← parts.mapM fun p => do
        let s ← translateExpr env inp state regs p
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
        let s ← translateExpr env inp state regs p
        if inferWidth env p == some 1 then some s!"(BitVec.ofBool {s})"
        else some s
      let base ← match ps with
        | []      => none
        | [x]     => some x
        | x :: xs => some (xs.foldl (fun acc p => s!"({acc} ++ {p})") x)
      some s!"(BitVec.replicate {n} {base})"
  | _ => none

-- ---------------------------------------------------------------------------
-- Shared collection helpers
-- ---------------------------------------------------------------------------

private def collectPorts (items : List ModuleItem) :
    List String × List String :=
  items.foldl (fun (ins, outs) item =>
    match item with
    | .input_decl  _ names => (ins ++ names, outs)
    | .output_decl _ names => (ins, outs ++ names)
    | _ => (ins, outs)) ([], [])

private def collectAssigns (env : WidthEnv) (state : String) (regs : List String)
    (items : List ModuleItem) : List (String × String) :=
  items.foldl (fun acc item =>
    match item with
    | .cont_assign _ _ assigns =>
      assigns.foldl (fun a asgn =>
        match asgn.lv with
        | .ident name =>
          match translateExpr env "_inp" state regs asgn.e with
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

-- ---------------------------------------------------------------------------
-- Combinational module emitter
-- ---------------------------------------------------------------------------

private def emitCombModule (m : Module) : String :=
  let (inputs, outputs) := collectPorts m.items
  let env      := buildWidthEnv m.items
  let assigns  := collectAssigns env "" [] m.items
  let inStruct := emitStruct (capitalize m.name ++ "_Input")  env inputs
  let outStruct:= emitStruct (capitalize m.name ++ "_Output") env outputs
  let fields := outputs.map fun n =>
    let rhs := (assigns.find? fun (k, _) => k == n).map (·.2) |>.getD "sorry"
    s!"    {n} := {rhs}"
  let body    := String.intercalate "\n" fields
  let inTy    := capitalize m.name ++ "_Input"
  let outTy   := capitalize m.name ++ "_Output"
  let circuit :=
    s!"def {m.name}Circuit : Circuit Unit {inTy} {outTy} :=\n" ++
    s!"  mkComb fun _inp =>\n  \{\n{body}\n  }"
  [s!"-- Module: {m.name}", inStruct, outStruct, circuit]
    |> String.intercalate "\n\n"

-- ---------------------------------------------------------------------------
-- Sequential module emitter
-- ---------------------------------------------------------------------------

private def collectRegs (items : List ModuleItem) : List String :=
  items.foldl (fun acc item =>
    match item with
    | .reg_decl _ vars => acc ++ vars.filterMap fun
      | .scalar n => some n
      | _         => none
    | _ => acc) []

private partial def collectNBAs : Stmt → List (String × Expr)
  | .nonblocking (.ident name) _ e => [(name, e)]
  | .seq_block _ _ stmts           => stmts.flatMap collectNBAs
  | _                              => []

private def collectSeqAssigns (clock : String) (items : List ModuleItem) :
    List (String × Expr) :=
  items.foldl (fun acc item =>
    match item with
    | .always_stmt (.delay (.event (.posedge (.ident clk))) (some body)) =>
      if clk == clock then acc ++ collectNBAs body else acc
    | _ => acc) []

private def emitSeqModule (m : Module) (clock : String) : String :=
  let (inputs, outputs) := collectPorts m.items
  let inputs      := inputs.filter (· != clock)
  let env         := buildWidthEnv m.items
  let regs        := collectRegs m.items
  let nbas        := collectSeqAssigns clock m.items
  let contAssigns := collectAssigns env "_s" regs m.items

  let inTy    := capitalize m.name ++ "_Input"
  let stateTy := capitalize m.name ++ "_State"
  let outTy   := capitalize m.name ++ "_Output"

  let inStruct    := emitStruct inTy    env inputs
  let stateStruct := emitStruct stateTy env regs
  let outStruct   := emitStruct outTy   env outputs

  -- init: all registers default to false / 0
  let initFields := regs.map fun r =>
    let w := env.lookup r |>.getD 1
    s!"{r} := {defaultInit w}"
  let initBody := "{ " ++ String.intercalate ", " initFields ++ " }"

  -- step: non-blocking assignment RHS; unassigned registers hold their value
  let stepFields := regs.map fun r =>
    let rhs := (nbas.find? fun (k, _) => k == r)
      |>.bind  (fun (_, e) => translateExpr env "_inp" "_s" regs e)
      |>.getD  s!"_s.{r}"
    s!"    {r} := {rhs}"
  let stepBody := String.intercalate "\n" stepFields

  -- observe: registers come from state; combinational outputs from cont_assign
  let obsFields := outputs.map fun n =>
    let rhs :=
      if regs.contains n then s!"_s.{n}"
      else (contAssigns.find? fun (k, _) => k == n) |>.map (·.2) |>.getD "sorry"
    s!"    {n} := {rhs}"
  let obsBody := String.intercalate "\n" obsFields

  let circuit :=
    s!"def {m.name}Circuit : Circuit {stateTy} {inTy} {outTy} :=\n" ++
    s!"  mkSeq {initBody}\n" ++
    s!"    (fun _s _inp =>\n    \{\n{stepBody}\n    })\n" ++
    s!"    (fun _s _inp =>\n    \{\n{obsBody}\n    })"

  [s!"-- Module: {m.name}", inStruct, stateStruct, outStruct, circuit]
    |> String.intercalate "\n\n"

-- ---------------------------------------------------------------------------
-- Module dispatcher: detect combinational vs sequential
-- ---------------------------------------------------------------------------

private def posEdgeClock : Stmt → Option String
  | .delay (.event (.posedge (.ident clk))) _ => some clk
  | _                                          => none

private def emitModule (m : Module) : String :=
  let clocks :=
    (m.items.filterMap fun | .always_stmt s => posEdgeClock s | _ => none)
    |>.foldl (fun acc c => if acc.contains c then acc else acc ++ [c]) []
  match clocks with
  | []    => emitCombModule m
  | [clk] => emitSeqModule m clk
  | _     => s!"-- Unsupported module '{m.name}': multiple clock domains\n"

-- ---------------------------------------------------------------------------
-- Top-level entry point
-- ---------------------------------------------------------------------------

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
