namespace Verilog

abbrev Ident := String

-- ---------------------------------------------------------------------------
-- Expressions
-- ---------------------------------------------------------------------------

inductive Expr : Type
  | number      (s : String)
  | string      (s : String)
  | ident       (i : Ident)
  | index       (e : Expr) (idx : Expr)
  | slice       (e : Expr) (hi lo : Expr)
  | concat      (es : List Expr)
  | multiconcat (rep : Expr) (es : List Expr)
  | call        (f : Ident) (args : List Expr)
  | syscall     (f : String) (args : List Expr)
  | unary       (op : String) (e : Expr)
  | binary      (op : String) (l r : Expr)
  | ternary     (cond thenE elseE : Expr)
  deriving Repr

abbrev ConstExpr := Expr

-- ---------------------------------------------------------------------------
-- Range, LValue, Delay
-- ---------------------------------------------------------------------------

structure Range : Type where
  hi : ConstExpr
  lo : ConstExpr
  deriving Repr

inductive LValue : Type
  | ident  (i : Ident)
  | index  (i : Ident) (e : Expr)
  | slice  (i : Ident) (hi lo : ConstExpr)
  | concat (lvals : List LValue)
  deriving Repr

inductive Delay : Type
  | number (s : String)
  | ident  (i : Ident)
  | mintyp (e1 : Expr) (e2 : Option Expr) (e3 : Option Expr)
  deriving Repr

structure DriveStrength : Type where
  s0 : String
  s1 : String
  deriving Repr

inductive ChargeStrength : Type | small | medium | large deriving Repr

inductive ExpandRange : Type
  | range    (r : Range)
  | scalared (r : Range)
  | vectored (r : Range)
  deriving Repr

-- ---------------------------------------------------------------------------
-- Event expressions, delay/event control
-- ---------------------------------------------------------------------------

inductive EventExpr : Type
  | expr    (e : Expr)
  | posedge (e : Expr)
  | negedge (e : Expr)
  | or      (l r : EventExpr)
  deriving Repr

inductive DelayOrEventControl : Type
  | delay  (d : Delay)
  | event  (ee : EventExpr)
  | repeat (e : Expr) (ee : EventExpr)
  deriving Repr

-- ---------------------------------------------------------------------------
-- Assignment, RegisterVar, BlockDecl  (defined before Stmt)
-- ---------------------------------------------------------------------------

structure Assignment : Type where
  lv : LValue
  e  : Expr
  deriving Repr

inductive RegisterVar : Type
  | scalar (name : Ident)
  | memory (name : Ident) (hi lo : ConstExpr)
  deriving Repr

inductive BlockDecl : Type
  | param    (assigns : List Assignment)
  | reg      (range : Option Range) (vars : List RegisterVar)
  | integer  (vars : List RegisterVar)
  | real     (vars : List Ident)
  | time     (vars : List RegisterVar)
  | event    (names : List Ident)
  deriving Repr

-- ---------------------------------------------------------------------------
-- Stmt and CaseItem (mutually recursive)
-- ---------------------------------------------------------------------------

mutual

inductive Stmt : Type
  | blocking     (lv : LValue) (ctrl : Option DelayOrEventControl) (e : Expr)
  | nonblocking  (lv : LValue) (ctrl : Option DelayOrEventControl) (e : Expr)
  | if_          (cond : Expr) (thenS : Stmt) (elseS : Option Stmt)
  | case         (kw : String) (e : Expr) (items : List CaseItem)
  | forever      (s : Stmt)
  | repeat       (e : Expr) (s : Stmt)
  | while        (e : Expr) (s : Stmt)
  | for          (init : Assignment) (cond : Expr) (step : Assignment) (s : Stmt)
  | delay        (ctrl : DelayOrEventControl) (s : Option Stmt)
  | wait         (e : Expr) (s : Option Stmt)
  | event_trigger (ev : Ident)
  | seq_block    (label : Option Ident) (decls : List BlockDecl) (stmts : List Stmt)
  | par_block    (label : Option Ident) (decls : List BlockDecl) (stmts : List Stmt)
  | task_enable  (name : Ident) (args : List Expr)
  | sys_enable   (name : String) (args : List Expr)
  | disable      (name : Ident)
  | assign       (a : Assignment)
  | deassign     (lv : LValue)
  | force        (a : Assignment)
  | release      (lv : LValue)
  | null

inductive CaseItem : Type
  | exprs   (es : List Expr) (s : Option Stmt)
  | default (s : Option Stmt)

end

-- Repr instances (manual since mutual blocks can't derive Repr directly)
instance : Repr Stmt where
  reprPrec _ n := reprPrec (toString "Stmt") n

instance : Repr CaseItem where
  reprPrec _ n := reprPrec (toString "CaseItem") n

-- ---------------------------------------------------------------------------
-- Net type
-- ---------------------------------------------------------------------------

inductive NetType : Type
  | wire | tri | tri1 | supply0 | wand | triand | tri0 | supply1 | wor | trior | trireg
  deriving Repr

-- ---------------------------------------------------------------------------
-- Structures used in ModuleItem
-- ---------------------------------------------------------------------------

inductive ModConns : Type
  | positional (es : List (Option Expr))
  | named      (cs : List (Ident × Option Expr))
  deriving Repr

structure GateInstance : Type where
  name  : Option Ident
  range : Option Range
  ports : List Expr
  deriving Repr

structure UdpInstance : Type where
  name  : Option Ident
  range : Option Range
  ports : List Expr
  deriving Repr

structure ModInstance : Type where
  name  : Ident
  range : Option Range
  conns : ModConns
  deriving Repr

inductive SpecifyItem : Type
  | specparam (assigns : List Assignment)
  | other
  deriving Repr

inductive RangeOrType : Type
  | range   (r : Range)
  | integer
  | real
  deriving Repr

inductive TfDecl : Type
  | param    (assigns : List Assignment)
  | input    (range : Option Range) (vars : List Ident)
  | output   (range : Option Range) (vars : List Ident)
  | inout    (range : Option Range) (vars : List Ident)
  | reg      (range : Option Range) (vars : List RegisterVar)
  | time     (vars : List RegisterVar)
  | integer  (vars : List RegisterVar)
  | real     (vars : List Ident)
  deriving Repr

-- ---------------------------------------------------------------------------
-- ModuleItem
-- ---------------------------------------------------------------------------

inductive ModuleItem : Type
  | param_decl    (assigns : List Assignment)
  | input_decl    (range : Option Range) (vars : List Ident)
  | output_decl   (range : Option Range) (vars : List Ident)
  | inout_decl    (range : Option Range) (vars : List Ident)
  | net_decl      (nt : NetType) (strength : Option DriveStrength)
                  (expand : Option ExpandRange) (delay : Option Delay) (vars : List Ident)
  | trireg_decl   (strength : Option ChargeStrength)
                  (expand : Option ExpandRange) (delay : Option Delay) (vars : List Ident)
  | reg_decl      (range : Option Range) (vars : List RegisterVar)
  | time_decl     (vars : List RegisterVar)
  | integer_decl  (vars : List RegisterVar)
  | real_decl     (vars : List Ident)
  | event_decl    (names : List Ident)
  | cont_assign   (strength : Option DriveStrength) (delay : Option Delay)
                  (assigns : List Assignment)
  | param_override (assigns : List Assignment)
  | gate_decl     (gtype : String) (strength : Option DriveStrength) (delay : Option Delay)
                  (instances : List GateInstance)
  | udp_inst      (udp : Ident) (strength : Option DriveStrength) (delay : Option Delay)
                  (instances : List UdpInstance)
  | mod_inst      (mod : Ident) (params : List Expr) (instances : List ModInstance)
  | specify_block (items : List SpecifyItem)
  | initial_stmt  (s : Stmt)
  | always_stmt   (s : Stmt)
  | task_def      (name : Ident) (decls : List TfDecl) (body : Option Stmt)
  | func_def      (ret : Option RangeOrType) (name : Ident)
                  (decls : List TfDecl) (body : Stmt)
  deriving Repr

-- ---------------------------------------------------------------------------
-- Port
-- ---------------------------------------------------------------------------

inductive PortSel : Type
  | index (e : ConstExpr)
  | slice (hi lo : ConstExpr)
  deriving Repr

inductive PortExpr : Type
  | ref    (name : Ident) (sel : Option PortSel)
  | concat (refs : List (Ident × Option PortSel))
  deriving Repr

inductive Port : Type
  | anon  (e : Option PortExpr)
  | named (name : Ident) (e : Option PortExpr)
  deriving Repr

-- ---------------------------------------------------------------------------
-- Module, Description, SourceText
-- ---------------------------------------------------------------------------

structure Module : Type where
  name  : Ident
  ports : List Port
  items : List ModuleItem
  deriving Repr

inductive Description : Type
  | module_ (m : Module)
  deriving Repr

abbrev SourceText := List Description

end Verilog
