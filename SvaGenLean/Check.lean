import SvaGenLean.Ast

namespace Verilog

-- ---------------------------------------------------------------------------
-- Combinational-logic checker
-- ---------------------------------------------------------------------------

private def edgeFree : EventExpr → Bool
  | .posedge _ => false
  | .negedge _ => false
  | .expr _    => true
  | .or l r    => edgeFree l && edgeFree r

private def levelSensitive : Stmt → Bool
  | .delay (.event ee) _ => edgeFree ee
  | _                    => false

private def findModule (src : SourceText) (name : Ident) : Option Module :=
  src.findSome? fun | .module_ m => if m.name == name then some m else none

-- Mutually recursive: a module is combinational iff all its items are, and
-- module instantiations are OK when the instantiated module is also
-- combinational (looked up in the same source text).
mutual

private partial def isCombModule (src : SourceText) (visited : List Ident)
    (m : Module) : Bool :=
  m.items.all (isCombItem src visited)

private partial def isCombItem (src : SourceText) (visited : List Ident)
    (item : ModuleItem) : Bool :=
  match item with
  | .always_stmt s  => levelSensitive s
  | .initial_stmt _ => false
  | .mod_inst name _ _ =>
    if visited.contains name then
      true  -- cycle guard (not reachable in valid Verilog)
    else
      match findModule src name with
      | some m => isCombModule src (name :: visited) m
      | none   => false  -- instantiated module not in source; cannot verify
  | _ => true  -- declarations, cont_assign, gate_decl, task_def, func_def …

end

def checkCombinational (src : SourceText) : Option String :=
  let nonComb := src.filterMap fun d =>
    match d with
    | .module_ m => if isCombModule src [] m then none else some m.name
  if nonComb.isEmpty then none
  else some "Only Combinational Circuits supported now"

end Verilog
