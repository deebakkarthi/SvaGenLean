import SvaGenLean.Lexer
import SvaGenLean.Ast

namespace Verilog

-- ---------------------------------------------------------------------------
-- Parser monad
-- ---------------------------------------------------------------------------

structure ParseState where
  tokens : Array Token
  pos    : Nat

abbrev ParseM := StateT ParseState (Except String)

def peek : ParseM Token := do
  let st ← get
  if st.pos < st.tokens.size then return st.tokens[st.pos]!
  return .EOF

def advance : ParseM Token := do
  let tok ← peek
  modify fun st => { st with pos := st.pos + 1 }
  return tok

def expect (tok : Token) : ParseM Unit := do
  let t ← advance
  if t != tok then throw s!"expected {repr tok}, got {repr t}"

def expectIdent : ParseM String := do
  let t ← advance
  match t with
  | .IDENTIFIER s => return s
  | other         => throw s!"expected IDENTIFIER, got {repr other}"

def eat (tok : Token) : ParseM Bool := do
  if (← peek) == tok then let _ ← advance; return true
  return false

def check (tok : Token) : ParseM Bool := do
  return (← peek) == tok

-- Save/restore position for backtracking
def tryP (p : ParseM α) : ParseM (Option α) := do
  let saved ← get
  match ← (StateT.run p saved |>.map some |>.tryCatch (fun _ => return none)) with
  | some (a, st') => set st'; return some a
  | none          => set saved; return none

def sepBy1 (p : ParseM α) (sep : Token) : ParseM (List α) := do
  let first ← p
  let mut rest : List α := []
  while (← eat sep) do
    rest := rest ++ [← p]
  return first :: rest

-- ---------------------------------------------------------------------------
-- Operator tables (must precede mutual block)
-- ---------------------------------------------------------------------------

def unopStr : Token → Option String
  | .PLUS        => some "+"   | .MINUS       => some "-"
  | .BANG        => some "!"   | .TILDE       => some "~"
  | .AMP         => some "&"   | .TILDE_AMP   => some "~&"
  | .PIPE        => some "|"   | .TILDE_PIPE  => some "~|"
  | .CARET       => some "^"   | .TILDE_CARET => some "~^"
  | _            => none

def binopBP : Token → Option (Nat × Nat)
  | .PIPE_PIPE                                    => some (10, 11)
  | .AMP_AMP                                      => some (20, 21)
  | .PIPE                                         => some (30, 31)
  | .CARET | .TILDE_CARET | .CARET_TILDE          => some (40, 41)
  | .AMP                                          => some (50, 51)
  | .EQ_EQ | .BANG_EQ | .EQ_EQ_EQ | .BANG_EQ_EQ  => some (60, 61)
  | .LT | .LT_EQ | .GT | .GT_EQ                  => some (70, 71)
  | .LT_LT | .GT_GT | .GT_GT_GT                   => some (80, 81)
  | .PLUS | .MINUS                                => some (90, 91)
  | .STAR | .SLASH | .PERCENT                     => some (100, 101)
  | _                                             => none

def binopStr : Token → String
  | .PLUS => "+" | .MINUS => "-" | .STAR => "*" | .SLASH => "/"
  | .PERCENT => "%" | .EQ_EQ => "==" | .BANG_EQ => "!="
  | .EQ_EQ_EQ => "===" | .BANG_EQ_EQ => "!=="
  | .AMP_AMP => "&&" | .PIPE_PIPE => "||"
  | .LT => "<" | .LT_EQ => "<=" | .GT => ">" | .GT_EQ => ">="
  | .AMP => "&" | .PIPE => "|" | .CARET => "^"
  | .TILDE_CARET => "~^" | .CARET_TILDE => "^~"
  | .LT_LT => "<<" | .GT_GT => ">>" | .GT_GT_GT => ">>>"
  | t => toString (repr t)

-- Skip optional signed/unsigned qualifier
def eatSignQual : ParseM Unit := do
  let t ← peek
  if t == .SIGNED || t == .UNSIGNED then let _ ← advance

-- Skip optional net/reg/integer/real/time type qualifier (for ANSI-style decls)
def eatTypeQual : ParseM Unit := do
  let t ← peek
  match t with
  | .WIRE | .REG | .TRI | .TRI0 | .TRI1 | .TRIAND | .TRIOR | .TRIREG
  | .SUPPLY0 | .SUPPLY1 | .WAND | .WOR | .INTEGER | .TIME | .REAL => let _ ← advance
  | _ => return ()

-- ---------------------------------------------------------------------------
-- All parser functions (mutual block for cross-references)
-- ---------------------------------------------------------------------------

mutual

partial def parseIdent : ParseM Ident := do
  let first ← expectIdent
  let mut result := first
  let mut cont := true
  while cont do
    if (← peek) == .DOT then
      let _ ← advance
      let t ← peek
      match t with
      | .IDENTIFIER _ =>
        let next ← expectIdent
        result := result ++ "." ++ next
      | _ => cont := false
    else cont := false
  return result

partial def parseRange : ParseM Range := do
  expect .LBRACKET
  let hi ← parseExpr
  expect .COLON
  let lo ← parseExpr
  expect .RBRACKET
  return { hi, lo }

partial def parseDelay : ParseM Delay := do
  expect .HASH
  let t ← peek
  match t with
  | .UNSIGNED_NUMBER s => let _ ← advance; return .number s
  | .IDENTIFIER _      => return .ident (← parseIdent)
  | .LPAREN =>
    let _ ← advance
    let e1 ← parseExpr
    if (← eat .COMMA) then
      let e2 ← parseExpr
      if (← eat .COMMA) then
        let e3 ← parseExpr; expect .RPAREN
        return .mintyp e1 (some e2) (some e3)
      expect .RPAREN; return .mintyp e1 (some e2) none
    expect .RPAREN; return .mintyp e1 none none
  | other => throw s!"expected delay, got {repr other}"

partial def parseDriveStrength : ParseM DriveStrength := do
  expect .LPAREN
  let t0 ← advance
  let s0s1 ← match isS0 t0 with
    | some s0 =>
      expect .COMMA
      let t1 ← advance
      pure (s0, (isS1 t1).getD "strong1")
    | none =>
      let s1 := (isS1 t0).getD "strong1"
      expect .COMMA
      let t1 ← advance
      pure ((isS0 t1).getD "strong0", s1)
  expect .RPAREN
  return { s0 := s0s1.1, s1 := s0s1.2 }
where
  isS0 : Token → Option String
    | .SUPPLY0 => some "supply0" | .IDENTIFIER "strong0" => some "strong0"
    | .IDENTIFIER "pull0" => some "pull0" | .IDENTIFIER "weak0" => some "weak0"
    | .IDENTIFIER "highz0" => some "highz0" | _ => none
  isS1 : Token → Option String
    | .SUPPLY1 => some "supply1" | .IDENTIFIER "strong1" => some "strong1"
    | .IDENTIFIER "pull1" => some "pull1" | .IDENTIFIER "weak1" => some "weak1"
    | .IDENTIFIER "highz1" => some "highz1" | _ => none

partial def parseChargeStrength : ParseM ChargeStrength := do
  expect .LPAREN
  let t ← advance
  let cs ← match t with
    | .SMALL  => pure ChargeStrength.small
    | .MEDIUM => pure ChargeStrength.medium
    | .LARGE  => pure ChargeStrength.large
    | other   => throw s!"expected charge strength, got {repr other}"
  expect .RPAREN; return cs

partial def parseExpandRange : ParseM ExpandRange := do
  let t ← peek
  match t with
  | .SCALARED => let _ ← advance; return .scalared (← parseRange)
  | .VECTORED => let _ ← advance; return .vectored (← parseRange)
  | .LBRACKET => return .range (← parseRange)
  | other => throw s!"expected expandrange, got {repr other}"

-- ---- Expressions -----------------------------------------------------------

partial def parseExpr : ParseM Expr := parseExprBP 0

partial def parseExprBP (minBP : Nat) : ParseM Expr := do
  let t ← peek
  let lhs ← match unopStr t with
    | some op => let _ ← advance; return Expr.unary op (← parseExprBP 200)
    | none    => parsePrimary
  parseInfix lhs minBP

partial def parseInfix (lhs : Expr) (minBP : Nat) : ParseM Expr := do
  let t ← peek
  if t == .QUESTION then
    if minBP > 5 then return lhs
    let _ ← advance
    let thenE ← parseExprBP 0
    expect .COLON
    let elseE ← parseExprBP 5
    parseInfix (Expr.ternary lhs thenE elseE) minBP
  else
    match binopBP t with
    | none => return lhs
    | some (lBP, rBP) =>
      if lBP < minBP then return lhs
      let _ ← advance
      let rhs ← parseExprBP rBP
      parseInfix (Expr.binary (binopStr t) lhs rhs) minBP

partial def parsePrimary : ParseM Expr := do
  let t ← peek
  match t with
  | .UNSIGNED_NUMBER s => let _ ← advance; return .number s
  | .STRING s          => let _ ← advance; return .string s
  | .LPAREN =>
    let _ ← advance
    let e ← parseExpr
    if (← eat .COLON) then
      let e2 ← parseExpr; expect .COLON; let e3 ← parseExpr; expect .RPAREN
      return .ternary e e2 e3
    expect .RPAREN; return e
  | .LBRACE =>
    let _ ← advance
    let first ← parseExpr
    if (← check .LBRACE) then
      let _ ← advance
      let es ← sepBy1 parseExpr .COMMA
      expect .RBRACE; expect .RBRACE
      return .multiconcat first es
    else if (← eat .COMMA) then
      let rest ← sepBy1 parseExpr .COMMA
      expect .RBRACE
      return .concat (first :: rest)
    else
      expect .RBRACE; return .concat [first]
  | .SYSTEM_IDENTIFIER name =>
    let _ ← advance
    if (← eat .LPAREN) then
      let args ← parseSysArgs; expect .RPAREN
      return .syscall name args
    return .syscall name []
  | .IDENTIFIER _ =>
    let name ← parseIdent
    let t2 ← peek
    match t2 with
    | .LPAREN =>
      let _ ← advance
      let args ← sepBy1 parseExpr .COMMA; expect .RPAREN
      return .call name args
    | .LBRACKET =>
      let _ ← advance; let idx ← parseExpr
      let t3 ← peek
      if t3 == .COLON then
        let _ ← advance; let lo ← parseExpr; expect .RBRACKET
        return .slice (.ident name) idx lo
      else if t3 == .PLUS_COLON || t3 == .MINUS_COLON then
        let _ ← advance; let width ← parseExpr; expect .RBRACKET
        return .slice (.ident name) idx width
      else
        expect .RBRACKET; return .index (.ident name) idx
    | _ => return .ident name
  | other => throw s!"unexpected token in expression: {repr other}"

-- ---- LValue ----------------------------------------------------------------

partial def parseLValue : ParseM LValue := do
  let t ← peek
  if t == .LBRACE then
    let _ ← advance
    let lv ← parseLValue
    let mut rest := [lv]
    while (← eat .COMMA) do rest := rest ++ [← parseLValue]
    expect .RBRACE; return .concat rest
  let name ← expectIdent
  let t2 ← peek
  match t2 with
  | .LBRACKET =>
    let _ ← advance; let e ← parseExpr
    let t3 ← peek
    if t3 == .COLON then
      let _ ← advance; let lo ← parseExpr; expect .RBRACKET; return .slice name e lo
    else if t3 == .PLUS_COLON || t3 == .MINUS_COLON then
      let _ ← advance; let width ← parseExpr; expect .RBRACKET; return .slice name e width
    else
      expect .RBRACKET; return .index name e
  | _ => return .ident name

-- ---- Event expression ------------------------------------------------------

partial def parseEventExpr : ParseM EventExpr := do
  let lhs ← parseEventTerm
  if (← peek) == .OR then let _ ← advance; return .or lhs (← parseEventExpr)
  return lhs

partial def parseEventTerm : ParseM EventExpr := do
  let t ← peek
  match t with
  | .POSEDGE => let _ ← advance; return .posedge (← parseExpr)
  | .NEGEDGE => let _ ← advance; return .negedge (← parseExpr)
  | _        => return .expr (← parseExpr)

-- ---- System task argument list (handles empty ,, slots) -------------------

partial def parseSysArgs : ParseM (List Expr) := do
  if (← check .RPAREN) then return []
  let mut args : List Expr := []
  let mut cont := true
  while cont do
    let t ← peek
    if t == .RPAREN || t == .SEMI || t == .EOF then
      cont := false
    else if t == .COMMA then
      let _ ← advance  -- skip empty slot
    else
      args := args ++ [← parseExpr]
      if not (← eat .COMMA) then cont := false
  return args

-- ---- Delay or event control ------------------------------------------------

partial def parseDelayOrEventControl : ParseM DelayOrEventControl := do
  let t ← peek
  match t with
  | .HASH => return .delay (← parseDelay)
  | .AT   =>
    let _ ← advance
    if (← eat .LPAREN) then
      let ee ← parseEventExpr; expect .RPAREN; return .event ee
    return .event (.expr (.ident (← parseIdent)))
  | .REPEAT =>
    let _ ← advance; expect .LPAREN
    let e ← parseExpr; expect .RPAREN
    let _ ← advance  -- @
    expect .LPAREN; let ee ← parseEventExpr; expect .RPAREN
    return .repeat e ee
  | other => throw s!"expected delay/event control, got {repr other}"

-- ---- Assignment ------------------------------------------------------------

partial def parseAssignment : ParseM Assignment := do
  let lv ← parseLValue; expect .EQ; let e ← parseExpr
  return { lv, e }

-- ---- Statements ------------------------------------------------------------

partial def parseStmtOrNull : ParseM (Option Stmt) := do
  if (← eat .SEMI) then return none
  return some (← parseStmt)

partial def parseStmt : ParseM Stmt := do
  let t ← peek
  match t with
  | .BEGIN =>
    let _ ← advance
    let label ← if (← eat .COLON) then some <$> expectIdent else pure none
    let decls ← parseBlockDecls
    let stmts ← parseStmtList [.END]
    expect .END
    return .seq_block label decls stmts
  | .FORK =>
    let _ ← advance
    let label ← if (← eat .COLON) then some <$> expectIdent else pure none
    let decls ← parseBlockDecls
    let stmts ← parseStmtList [.JOIN]
    expect .JOIN
    return .par_block label decls stmts
  | .IF =>
    let _ ← advance; expect .LPAREN; let cond ← parseExpr; expect .RPAREN
    let thenS ← parseStmt
    let elseS ← if (← eat .ELSE) then some <$> parseStmt else pure none
    return .if_ cond thenS elseS
  | .CASE | .CASEZ | .CASEX =>
    let kw := if t == .CASE then "case" else if t == .CASEZ then "casez" else "casex"
    let _ ← advance; expect .LPAREN; let e ← parseExpr; expect .RPAREN
    let items ← parseCaseItems
    expect .ENDCASE
    return .case kw e items
  | .FOREVER => let _ ← advance; return .forever (← parseStmt)
  | .REPEAT  =>
    let _ ← advance; expect .LPAREN; let e ← parseExpr; expect .RPAREN
    return .repeat e (← parseStmt)
  | .WHILE =>
    let _ ← advance; expect .LPAREN; let e ← parseExpr; expect .RPAREN
    return .while e (← parseStmt)
  | .FOR =>
    let _ ← advance; expect .LPAREN
    let init ← parseAssignment; expect .SEMI
    let cond ← parseExpr; expect .SEMI
    let step ← parseAssignment; expect .RPAREN
    return .for init cond step (← parseStmt)
  | .WAIT =>
    let _ ← advance; expect .LPAREN; let e ← parseExpr; expect .RPAREN
    return .wait e (← parseStmtOrNull)
  | .HASH | .AT =>
    return .delay (← parseDelayOrEventControl) (← parseStmtOrNull)
  | .DISABLE =>
    let _ ← advance; let name ← parseIdent; expect .SEMI; return .disable name
  | .ASSIGN =>
    let _ ← advance; let a ← parseAssignment; expect .SEMI; return .assign a
  | .DEASSIGN =>
    let _ ← advance; let lv ← parseLValue; expect .SEMI; return .deassign lv
  | .FORCE =>
    let _ ← advance; let a ← parseAssignment; expect .SEMI; return .force a
  | .RELEASE =>
    let _ ← advance; let lv ← parseLValue; expect .SEMI; return .release lv
  | .ARROW =>
    let _ ← advance; let name ← expectIdent; expect .SEMI; return .event_trigger name
  | .SYSTEM_IDENTIFIER name =>
    let _ ← advance
    if (← eat .LPAREN) then
      let args ← parseSysArgs; expect .RPAREN; expect .SEMI
      return .sys_enable name args
    expect .SEMI; return .sys_enable name []
  | .SEMI => let _ ← advance; return .null
  | _ =>
    let lv ← parseLValue
    let t2 ← peek
    match t2 with
    | .EQ =>
      let _ ← advance
      let t3 ← peek
      if t3 == .HASH || t3 == .AT then
        let ctrl ← parseDelayOrEventControl
        let e ← parseExpr; expect .SEMI
        return .blocking lv (some ctrl) e
      let e ← parseExpr; expect .SEMI
      return .blocking lv none e
    | .LT_EQ =>
      let _ ← advance
      let t3 ← peek
      if t3 == .HASH || t3 == .AT then
        let ctrl ← parseDelayOrEventControl
        let e ← parseExpr; expect .SEMI
        return .nonblocking lv (some ctrl) e
      let e ← parseExpr; expect .SEMI
      return .nonblocking lv none e
    | .LPAREN =>
      let name := match lv with | .ident i => i | _ => ""
      let _ ← advance
      let args ← sepBy1 parseExpr .COMMA; expect .RPAREN; expect .SEMI
      return .task_enable name args
    | .SEMI =>
      let _ ← advance
      let name := match lv with | .ident i => i | _ => ""
      return .task_enable name []
    | other => throw s!"unexpected token after lvalue: {repr other}"

partial def parseStmtList (stopAt : List Token) : ParseM (List Stmt) := do
  let mut stmts : List Stmt := []
  let mut cont := true
  while cont do
    let t ← peek
    if stopAt.contains t || t == .EOF then cont := false
    else stmts := stmts ++ [← parseStmt]
  return stmts

partial def parseCaseItems : ParseM (List CaseItem) := do
  let mut items : List CaseItem := []
  let mut cont := true
  while cont do
    let t ← peek
    match t with
    | .ENDCASE | .EOF => cont := false
    | .DEFAULT =>
      let _ ← advance; let _ ← eat .COLON
      items := items ++ [.default (← parseStmtOrNull)]
    | _ =>
      let es ← sepBy1 parseExpr .COMMA; expect .COLON
      items := items ++ [.exprs es (← parseStmtOrNull)]
  return items

-- ---- Block declarations ----------------------------------------------------

partial def parseBlockDecls : ParseM (List BlockDecl) := do
  let mut decls : List BlockDecl := []
  let mut cont := true
  while cont do
    let t ← peek
    match t with
    | .PARAMETER | .LOCALPARAM =>
      let _ ← advance; let a ← parseParamAssigns; expect .SEMI
      decls := decls ++ [.param a]
    | .REG =>
      let _ ← advance
      eatSignQual
      let r ← tryP parseRange
      let vs ← parseRegisterVars; expect .SEMI
      decls := decls ++ [.reg r vs]
    | .INTEGER =>
      let _ ← advance; let vs ← parseRegisterVars; expect .SEMI
      decls := decls ++ [.integer vs]
    | .REAL =>
      let _ ← advance; let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
      decls := decls ++ [.real vs]
    | .TIME =>
      let _ ← advance; let vs ← parseRegisterVars; expect .SEMI
      decls := decls ++ [.time vs]
    | .EVENT =>
      let _ ← advance; let ns ← sepBy1 expectIdent .COMMA; expect .SEMI
      decls := decls ++ [.event ns]
    | _ => cont := false
  return decls

-- ---- Helper parsers --------------------------------------------------------

partial def parseParamAssigns : ParseM (List Assignment) :=
  sepBy1 parseAssignment .COMMA

partial def parseRegisterVars : ParseM (List RegisterVar) :=
  sepBy1 parseOneRegVar .COMMA
where
  parseOneRegVar : ParseM RegisterVar := do
    let name ← expectIdent
    if (← eat .LBRACKET) then
      let hi ← parseExpr; expect .COLON; let lo ← parseExpr; expect .RBRACKET
      if (← eat .EQ) then let _ ← parseExpr  -- discard inline init
      return .memory name hi lo
    if (← eat .EQ) then let _ ← parseExpr  -- discard inline init (reg x = 0)
    return .scalar name

-- ---- TF declarations -------------------------------------------------------

partial def parseTfDecls : ParseM (List TfDecl) := do
  let mut ds : List TfDecl := []
  let mut cont := true
  while cont do
    let t ← peek
    match t with
    | .PARAMETER =>
      let _ ← advance; let a ← parseParamAssigns; expect .SEMI
      ds := ds ++ [.param a]
    | .INPUT =>
      let _ ← advance; eatTypeQual; eatSignQual
      let r ← tryP parseRange
      let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
      ds := ds ++ [.input r vs]
    | .OUTPUT =>
      let _ ← advance; eatTypeQual; eatSignQual
      let r ← tryP parseRange
      let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
      ds := ds ++ [.output r vs]
    | .INOUT =>
      let _ ← advance; eatTypeQual; eatSignQual
      let r ← tryP parseRange
      let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
      ds := ds ++ [.inout r vs]
    | .REG =>
      let _ ← advance; eatSignQual
      let r ← tryP parseRange
      let vs ← parseRegisterVars; expect .SEMI
      ds := ds ++ [.reg r vs]
    | .INTEGER =>
      let _ ← advance; let vs ← parseRegisterVars; expect .SEMI
      ds := ds ++ [.integer vs]
    | .REAL =>
      let _ ← advance; let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
      ds := ds ++ [.real vs]
    | .TIME =>
      let _ ← advance; let vs ← parseRegisterVars; expect .SEMI
      ds := ds ++ [.time vs]
    | _ => cont := false
  return ds

-- ---- Instances -------------------------------------------------------------

partial def parseGateInstance : ParseM GateInstance := do
  -- optional name+range before '('
  let nr ← tryP (do
    let n ← expectIdent; let r ← tryP parseRange; return (n, r))
  let (name, range) := match nr with
    | some (n, r) => (some n, r)
    | none        => (none, none)
  expect .LPAREN
  let ports ← sepBy1 parseExpr .COMMA
  expect .RPAREN
  return { name, range, ports }

partial def parseModConns : ParseM ModConns := do
  let t ← peek
  match t with
  | .RPAREN => return .positional []
  | .DOT    =>
    let cs ← sepBy1 parseNamedConn .COMMA
    return .named cs
  | _ =>
    let es ← sepBy1 parseOptExpr .COMMA
    return .positional es
where
  parseNamedConn : ParseM (Ident × Expr) := do
    expect .DOT; let name ← expectIdent; expect .LPAREN
    let e ← parseExpr; expect .RPAREN
    return (name, e)
  parseOptExpr : ParseM (Option Expr) := do
    if (← check .COMMA) || (← check .RPAREN) then return none
    return some (← parseExpr)

partial def parseModuleInstance : ParseM ModInstance := do
  let name ← expectIdent
  let range ← tryP parseRange
  expect .LPAREN
  let conns ← parseModConns
  expect .RPAREN
  return { name, range, conns }

-- ---- ANSI-style port/tf parsers --------------------------------------------

-- Parse one port in an ANSI-style port list: [dir] [type] [signed] [range] name
partial def parseAnsiPort : ParseM Port := do
  let t ← peek
  if t == .INPUT || t == .OUTPUT || t == .INOUT then let _ ← advance
  eatTypeQual
  eatSignQual
  let _ ← tryP parseRange
  let name ← expectIdent
  return .anon (some (.ref name none))

-- Parse ANSI-style function/task port list (inside parentheses)
partial def parseAnsiTfPortList : ParseM (List TfDecl) := do
  if (← check .RPAREN) then return []
  let mut decls : List TfDecl := []
  let mut cont := true
  while cont do
    let dir ← peek
    if dir == .INPUT || dir == .OUTPUT || dir == .INOUT then let _ ← advance
    eatTypeQual; eatSignQual
    let r ← tryP parseRange
    let name ← expectIdent
    let decl : TfDecl := match dir with
      | .OUTPUT => .output r [name]
      | .INOUT  => .inout r [name]
      | _       => .input r [name]
    decls := decls ++ [decl]
    if not (← eat .COMMA) then cont := false
  return decls

-- ---- Port list -------------------------------------------------------------

partial def parsePortRef : ParseM (Ident × Option PortSel) := do
  let name ← expectIdent
  let sel ← if (← eat .LBRACKET) then do
    let e ← parseExpr
    if (← eat .COLON) then
      let lo ← parseExpr; expect .RBRACKET; pure (some (PortSel.slice e lo))
    else
      expect .RBRACKET; pure (some (PortSel.index e))
  else pure none
  return (name, sel)

partial def parsePortExpr : ParseM PortExpr := do
  if (← eat .LBRACE) then
    let refs ← sepBy1 parsePortRef .COMMA; expect .RBRACE
    return .concat refs
  let (name, sel) ← parsePortRef
  return .ref name sel

partial def parsePort : ParseM Port := do
  if (← eat .DOT) then
    let name ← expectIdent; expect .LPAREN
    let e ← if (← check .RPAREN) then pure none else some <$> parsePortExpr
    expect .RPAREN; return .named name e
  let e ← if (← check .COMMA) || (← check .RPAREN) then pure none
           else some <$> parsePortExpr
  return .anon e

partial def parsePortList : ParseM (List Port) := do
  expect .LPAREN
  if (← check .RPAREN) then
    expect .RPAREN; return []
  let firstTok ← peek
  let ports ←
    if firstTok == .INPUT || firstTok == .OUTPUT || firstTok == .INOUT then
      sepBy1 parseAnsiPort .COMMA   -- ANSI-style port list
    else
      sepBy1 parsePort .COMMA       -- non-ANSI (Verilog-1995 style)
  expect .RPAREN; return ports

-- ---- Range or type ---------------------------------------------------------

partial def parseRangeOrType : ParseM RangeOrType := do
  let t ← peek
  match t with
  | .INTEGER  => let _ ← advance; return .integer
  | .REAL     => let _ ← advance; return .real
  | .LBRACKET => return .range (← parseRange)
  | other     => throw s!"expected range or type, got {repr other}"

-- ---- Specify items (mostly skipped) ----------------------------------------

partial def parseSpecifyItems : ParseM (List SpecifyItem) := do
  let mut items : List SpecifyItem := []
  let mut cont := true
  while cont do
    let t ← peek
    match t with
    | .ENDSPECIFY | .EOF => cont := false
    | .SPECPARAM =>
      let _ ← advance; let a ← parseParamAssigns; expect .SEMI
      items := items ++ [.specparam a]
    | _ =>
      let _ ← advance
      while (← peek) != .SEMI && (← peek) != .ENDSPECIFY && (← peek) != .EOF do
        let _ ← advance
      let _ ← eat .SEMI
      items := items ++ [.other]
  return items

-- ---- Net type helper -------------------------------------------------------

partial def tokenToNetType (t : Token) : Option NetType :=
  match t with
  | .WIRE    => some .wire    | .TRI     => some .tri
  | .TRI0    => some .tri0    | .TRI1    => some .tri1
  | .TRIAND  => some .triand  | .TRIOR   => some .trior
  | .SUPPLY0 => some .supply0 | .SUPPLY1 => some .supply1
  | .WAND    => some .wand    | .WOR     => some .wor
  | _        => none

-- ---- Module items ----------------------------------------------------------

partial def parseModuleItem : ParseM (Option ModuleItem) := do
  let t ← peek
  match t with
  | .ENDMODULE | .EOF => return none
  | .PARAMETER | .LOCALPARAM =>
    let _ ← advance; let a ← parseParamAssigns; expect .SEMI
    return some (.param_decl a)
  | .INPUT =>
    let _ ← advance; eatTypeQual; eatSignQual
    let r ← tryP parseRange
    let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
    return some (.input_decl r vs)
  | .OUTPUT =>
    let _ ← advance; eatTypeQual; eatSignQual
    let r ← tryP parseRange
    let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
    return some (.output_decl r vs)
  | .INOUT =>
    let _ ← advance; eatTypeQual; eatSignQual
    let r ← tryP parseRange
    let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
    return some (.inout_decl r vs)
  | .TRIREG =>
    let _ ← advance
    let cs ← tryP parseChargeStrength
    let er ← tryP parseExpandRange
    let d  ← tryP parseDelay
    let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
    return some (.trireg_decl cs er d vs)
  | _ =>
    match tokenToNetType t with
    | some nt =>
      let _ ← advance
      let ds ← tryP parseDriveStrength
      eatSignQual
      let er ← tryP parseExpandRange
      let d  ← tryP parseDelay
      let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
      return some (.net_decl nt ds er d vs)
    | none =>
      match t with
      | .REG =>
        let _ ← advance; eatSignQual
        let r ← tryP parseRange
        let vs ← parseRegisterVars; expect .SEMI
        return some (.reg_decl r vs)
      | .INTEGER =>
        let _ ← advance; let vs ← parseRegisterVars; expect .SEMI
        return some (.integer_decl vs)
      | .TIME =>
        let _ ← advance; let vs ← parseRegisterVars; expect .SEMI
        return some (.time_decl vs)
      | .REAL =>
        let _ ← advance; let vs ← sepBy1 expectIdent .COMMA; expect .SEMI
        return some (.real_decl vs)
      | .EVENT =>
        let _ ← advance; let ns ← sepBy1 expectIdent .COMMA; expect .SEMI
        return some (.event_decl ns)
      | .ASSIGN =>
        let _ ← advance
        let ds ← tryP parseDriveStrength
        let d  ← tryP parseDelay
        let as_ ← sepBy1 parseAssignment .COMMA; expect .SEMI
        return some (.cont_assign ds d as_)
      | .DEFPARAM =>
        let _ ← advance; let a ← parseParamAssigns; expect .SEMI
        return some (.param_override a)
      | .SPECIFY =>
        let _ ← advance
        let items ← parseSpecifyItems; expect .ENDSPECIFY
        return some (.specify_block items)
      | .INITIAL =>
        let _ ← advance; return some (.initial_stmt (← parseStmt))
      | .ALWAYS =>
        let _ ← advance; return some (.always_stmt (← parseStmt))
      | .TASK =>
        let _ ← advance; let name ← expectIdent; expect .SEMI
        let decls ← parseTfDecls
        let body ← parseStmtOrNull; expect .ENDTASK
        return some (.task_def name decls body)
      | .FUNCTION =>
        let _ ← advance
        let ret ← tryP parseRangeOrType
        let name ← expectIdent
        let decls ←
          if (← eat .LPAREN) then do
            let ds ← parseAnsiTfPortList
            expect .RPAREN; expect .SEMI
            parseTfDecls >>= fun ds2 => pure (ds ++ ds2)
          else do
            expect .SEMI; parseTfDecls
        let body ← parseStmt; expect .ENDFUNCTION
        return some (.func_def ret name decls body)
      | .IDENTIFIER _ =>
        let name ← parseIdent
        let gateTypes := ["and","nand","or","nor","xor","xnor","buf","bufif0","bufif1",
                          "not","notif0","notif1","pulldown","pullup","nmos","pmos","cmos",
                          "tran","tranif0","tranif1"]
        if gateTypes.contains name then
          let ds ← tryP parseDriveStrength
          let d  ← tryP parseDelay
          let insts ← sepBy1 parseGateInstance .COMMA; expect .SEMI
          return some (.gate_decl name ds d insts)
        else
          let params ← tryP (do
            expect .HASH; expect .LPAREN
            let es ← sepBy1 parseExpr .COMMA; expect .RPAREN; return es)
          let insts ← sepBy1 parseModuleInstance .COMMA; expect .SEMI
          return some (.mod_inst name (params.getD []) insts)
      | _ => let _ ← advance; return none  -- skip unknown

-- ---- Module ----------------------------------------------------------------

partial def parseModule : ParseM Module := do
  let t ← advance
  if t != .MODULE && t != .MACROMODULE then
    throw s!"expected 'module', got {repr t}"
  let name ← expectIdent
  let ports ← if (← check .LPAREN) then parsePortList else pure []
  expect .SEMI
  let mut items : List ModuleItem := []
  let mut cont := true
  while cont do
    let t ← peek
    if t == .ENDMODULE || t == .EOF then cont := false
    else
      match ← parseModuleItem with
      | some item => items := items ++ [item]
      | none      => pure ()  -- skip unknown item and continue
  expect .ENDMODULE
  return { name, ports, items }

-- ---- Source text -----------------------------------------------------------

partial def parseSourceText : ParseM SourceText := do
  let mut descs : List Description := []
  let mut cont := true
  while cont do
    let t ← peek
    match t with
    | .EOF => cont := false
    | .MODULE | .MACROMODULE =>
      descs := descs ++ [.module_ (← parseModule)]
    | _ => let _ ← advance  -- skip unknown top-level tokens

  return descs

end  -- mutual

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------

def parse (src : String) : Except String SourceText :=
  let tokens := tokenize src
  match parseSourceText.run { tokens, pos := 0 } with
  | .ok (ast, _) => .ok ast
  | .error e     => .error e

end Verilog
