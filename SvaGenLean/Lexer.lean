namespace Verilog

-- ---------------------------------------------------------------------------
-- Token type  (names match the Verilog BNF document)
-- ---------------------------------------------------------------------------

inductive Token
  -- Literal classes from the BNF
  | IDENTIFIER         (s : String)
  | ESCAPED_IDENTIFIER (s : String)
  | SYSTEM_IDENTIFIER  (s : String)
  | UNSIGNED_NUMBER    (s : String)
  | STRING             (s : String)
  | COMPILER_DIRECTIVE (s : String)
  -- Keywords
  | MODULE | MACROMODULE | PRIMITIVE | ENDMODULE | ENDPRIMITIVE
  | INPUT | OUTPUT | INOUT
  | WIRE | TRI | TRI0 | TRI1 | TRIAND | TRIOR | TRIREG
  | SUPPLY0 | SUPPLY1 | WAND | WOR
  | REG | INTEGER | TIME | REAL | REALTIME | EVENT
  | AND | NAND | OR | NOR | XOR | XNOR
  | BUF | BUFIF0 | BUFIF1 | NOT | NOTIF0 | NOTIF1
  | PULLDOWN | PULLUP
  | NMOS | PMOS | CMOS
  | TRAN | TRANIF0 | TRANIF1
  | ALWAYS | INITIAL | TASK | FUNCTION | ENDTASK | ENDFUNCTION
  | BEGIN | END | FORK | JOIN
  | IF | ELSE | CASE | CASEZ | CASEX | ENDCASE
  | FOREVER | REPEAT | WHILE | FOR | WAIT
  | DISABLE | ASSIGN | DEASSIGN | FORCE | RELEASE
  | POSEDGE | NEGEDGE
  | DEFPARAM | PARAMETER | LOCALPARAM | SPECPARAM
  | SPECIFY | ENDSPECIFY
  | TABLE | ENDTABLE
  | DEFAULT | SMALL | MEDIUM | LARGE | SCALARED | VECTORED
  | SIGNED | UNSIGNED
  -- Punctuation
  | LPAREN | RPAREN | LBRACKET | RBRACKET | LBRACE | RBRACE
  | SEMI | COLON | COMMA | DOT | AT | HASH | QUESTION | DOLLAR
  -- Operators
  | PLUS | MINUS | STAR | SLASH | PERCENT
  | BANG | TILDE | AMP | PIPE | CARET
  | TILDE_AMP | TILDE_PIPE | TILDE_CARET | CARET_TILDE | CARET_PIPE
  | AMP_AMP | PIPE_PIPE
  | EQ_EQ | BANG_EQ | EQ_EQ_EQ | BANG_EQ_EQ
  | LT | LT_EQ | GT | GT_EQ
  | LT_LT | LT_LT_LT | GT_GT | GT_GT_GT
  | EQ | ARROW | STAR_STAR | STAR_GT
  | PLUS_COLON | MINUS_COLON
  | EOF
  deriving Repr, BEq, Inhabited

-- ---------------------------------------------------------------------------
-- Char stream
-- ---------------------------------------------------------------------------

abbrev Chars := List Char

-- ---------------------------------------------------------------------------
-- Char helpers
-- ---------------------------------------------------------------------------

def isAlphaNum   (c : Char) : Bool := c.isAlpha || c.isDigit
def isIdentStart (c : Char) : Bool := c.isAlpha || c == '_'
def isIdentChar  (c : Char) : Bool := isAlphaNum c || c == '_' || c == '$'
def isHexDigit   (c : Char) : Bool :=
  c.isDigit || ('a' ≤ c && c ≤ 'f') || ('A' ≤ c && c ≤ 'F')
def isOctDigit   (c : Char) : Bool := '0' ≤ c && c ≤ '7'
def isBinDigit   (c : Char) : Bool := c == '0' || c == '1'

-- ---------------------------------------------------------------------------
-- collectWhile
-- ---------------------------------------------------------------------------

def collectWhile (cs : Chars) (p : Char → Bool) : String × Chars :=
  go cs ""
where
  go : Chars → String → String × Chars
    | [],      acc => (acc, [])
    | c :: cs, acc => if p c then go cs (acc.push c) else (acc, c :: cs)

-- ---------------------------------------------------------------------------
-- Keyword table
-- ---------------------------------------------------------------------------

def keywordMap : List (String × Token) := [
  ("module",       .MODULE),      ("macromodule",  .MACROMODULE),
  ("primitive",    .PRIMITIVE),   ("endmodule",    .ENDMODULE),
  ("endprimitive", .ENDPRIMITIVE),
  ("input",        .INPUT),       ("output",       .OUTPUT),
  ("inout",        .INOUT),
  ("wire",         .WIRE),        ("tri",          .TRI),
  ("tri0",         .TRI0),        ("tri1",         .TRI1),
  ("triand",       .TRIAND),      ("trior",        .TRIOR),
  ("trireg",       .TRIREG),      ("supply0",      .SUPPLY0),
  ("supply1",      .SUPPLY1),     ("wand",         .WAND),
  ("wor",          .WOR),
  ("reg",          .REG),         ("integer",      .INTEGER),
  ("time",         .TIME),        ("real",         .REAL),
  ("realtime",     .REALTIME),    ("event",        .EVENT),
  ("and",          .AND),         ("nand",         .NAND),
  ("or",           .OR),          ("nor",          .NOR),
  ("xor",          .XOR),         ("xnor",         .XNOR),
  ("buf",          .BUF),         ("bufif0",       .BUFIF0),
  ("bufif1",       .BUFIF1),      ("not",          .NOT),
  ("notif0",       .NOTIF0),      ("notif1",       .NOTIF1),
  ("pulldown",     .PULLDOWN),    ("pullup",       .PULLUP),
  ("nmos",         .NMOS),        ("pmos",         .PMOS),
  ("cmos",         .CMOS),
  ("tran",         .TRAN),        ("tranif0",      .TRANIF0),
  ("tranif1",      .TRANIF1),
  ("always",       .ALWAYS),      ("initial",      .INITIAL),
  ("task",         .TASK),        ("function",     .FUNCTION),
  ("endtask",      .ENDTASK),     ("endfunction",  .ENDFUNCTION),
  ("begin",        .BEGIN),       ("end",          .END),
  ("fork",         .FORK),        ("join",         .JOIN),
  ("if",           .IF),          ("else",         .ELSE),
  ("case",         .CASE),        ("casez",        .CASEZ),
  ("casex",        .CASEX),       ("endcase",      .ENDCASE),
  ("forever",      .FOREVER),     ("repeat",       .REPEAT),
  ("while",        .WHILE),       ("for",          .FOR),
  ("wait",         .WAIT),        ("disable",      .DISABLE),
  ("assign",       .ASSIGN),      ("deassign",     .DEASSIGN),
  ("force",        .FORCE),       ("release",      .RELEASE),
  ("posedge",      .POSEDGE),     ("negedge",      .NEGEDGE),
  ("defparam",     .DEFPARAM),    ("parameter",    .PARAMETER),
  ("localparam",   .LOCALPARAM),  ("specparam",    .SPECPARAM),
  ("specify",      .SPECIFY),     ("endspecify",   .ENDSPECIFY),
  ("table",        .TABLE),       ("endtable",     .ENDTABLE),
  ("default",      .DEFAULT),     ("small",        .SMALL),
  ("medium",       .MEDIUM),      ("large",        .LARGE),
  ("scalared",     .SCALARED),    ("vectored",     .VECTORED),
  ("signed",       .SIGNED),      ("unsigned",     .UNSIGNED),
]

def lookupKeyword (s : String) : Token :=
  match keywordMap.find? (fun (k, _) => k == s) with
  | some (_, tok) => tok
  | none          => .IDENTIFIER s

-- ---------------------------------------------------------------------------
-- Skip whitespace and comments
-- ---------------------------------------------------------------------------

partial def skipWsAndComments : Chars → Chars
  | []      => []
  | c :: cs =>
    if c.isWhitespace then
      skipWsAndComments cs
    else if c == '/' then
      match cs with
      | '/' :: rest => skipWsAndComments (skipLine rest)
      | '*' :: rest => skipWsAndComments (skipBlock rest)
      | _           => c :: cs
    else if c == '`' then
      -- Only skip if this looks like a standalone directive line
      -- (previous non-whitespace was a newline, i.e. we're at column 0 of meaning).
      -- Heuristic: skip the line only if the backtick identifier is a known
      -- directive keyword; otherwise let lexOne handle it as a COMPILER_DIRECTIVE token.
      let (name, rest) := collectWhile cs isIdentChar
      let directives := ["ifdef", "ifndef", "else", "elsif", "endif",
                         "include", "define", "undef", "line",
                         "celldefine", "endcelldefine",
                         "default_nettype", "resetall", "timescale",
                         "unconnected_drive", "nounconnected_drive",
                         "begin_keywords", "end_keywords"]
      if directives.contains name then
        skipWsAndComments (skipLine rest)
      else
        -- Macro use like `CLK — return the chars so lexOne can tokenize it
        c :: cs
    else c :: cs
where
  skipLine : Chars → Chars
    | []         => []
    | '\n' :: cs => cs
    | _ :: cs    => skipLine cs
  skipBlock : Chars → Chars
    | []                 => []
    | '*' :: '/' :: cs   => cs
    | _ :: cs            => skipBlock cs

-- ---------------------------------------------------------------------------
-- Number lexing
-- ---------------------------------------------------------------------------

def basedDigitPred (base : Char) : Char → Bool :=
  let xz    (c : Char) := c == 'x' || c == 'X' || c == 'z' || c == 'Z'
  let under (c : Char) := c == '_'
  match base with
  | 'b' | 'B' => fun c => isBinDigit c || xz c || under c
  | 'o' | 'O' => fun c => isOctDigit c || xz c || under c
  | 'd' | 'D' => fun c => c.isDigit    || xz c || under c
  | 'h' | 'H' => fun c => isHexDigit c || xz c || under c
  | _         => fun _ => false

-- Verilog allows whitespace between the base specifier and the digit string.
private def skipBlanks : Chars → Chars
  | c :: cs => if c == ' ' || c == '\t' then skipBlanks cs else c :: cs
  | []      => []

def lexBasedTail (pfx : String) : Chars → String × Chars
  | []        => (pfx ++ "'", [])
  | 's' :: b :: rest =>
    let (digits, cs) := collectWhile (skipBlanks rest) (basedDigitPred b)
    (pfx ++ "'s" ++ b.toString ++ digits, cs)
  | 'S' :: b :: rest =>
    let (digits, cs) := collectWhile (skipBlanks rest) (basedDigitPred b)
    (pfx ++ "'S" ++ b.toString ++ digits, cs)
  | b :: rest =>
    let (digits, cs) := collectWhile (skipBlanks rest) (basedDigitPred b)
    (pfx ++ "'" ++ b.toString ++ digits, cs)

def lexNumber (cs : Chars) : Token × Chars :=
  let (digits, cs) := collectWhile cs (fun c => c.isDigit || c == '_')
  match cs with
  | '\'' :: rest =>
    let (s, cs) := lexBasedTail digits rest
    (.UNSIGNED_NUMBER s, cs)
  | '.' :: rest =>
    let (frac, cs) := collectWhile rest (fun c => c.isDigit || c == '_')
    let base := digits ++ "." ++ frac
    match cs with
    | 'e' :: rest | 'E' :: rest =>
      let (sign, cs) :=
        match rest with
        | '+' :: rs => ("+", rs)
        | '-' :: rs => ("-", rs)
        | rs        => ("",  rs)
      let (exp, cs) := collectWhile cs (fun c => c.isDigit || c == '_')
      (.UNSIGNED_NUMBER (base ++ "e" ++ sign ++ exp), cs)
    | _ => (.UNSIGNED_NUMBER base, cs)
  | _ => (.UNSIGNED_NUMBER digits, cs)

-- ---------------------------------------------------------------------------
-- String literal
-- ---------------------------------------------------------------------------

def lexStringLit : Chars → Token × Chars
  | []              => (.STRING "", [])
  | '"'  :: cs      => (.STRING "", cs)
  | '\\' :: c :: cs =>
    let (tok, cs) := lexStringLit cs
    match tok with
    | .STRING s => (.STRING ("\\" ++ c.toString ++ s), cs)
    | other     => (other, cs)
  | c :: cs =>
    let (tok, cs) := lexStringLit cs
    match tok with
    | .STRING s => (.STRING (c.toString ++ s), cs)
    | other     => (other, cs)

-- ---------------------------------------------------------------------------
-- Lex one token
-- ---------------------------------------------------------------------------

def lexOne : Chars → Token × Chars
  | [] => (.EOF, [])
  | c :: cs =>
    if isIdentStart c then
      let (rest, cs) := collectWhile cs isIdentChar
      (lookupKeyword (c.toString ++ rest), cs)
    else if c == '\\' then
      let (name, cs) := collectWhile cs (fun ch => !ch.isWhitespace)
      (.ESCAPED_IDENTIFIER name, cs)
    else if c == '$' then
      let (name, cs) := collectWhile cs isIdentChar
      if name.isEmpty then (.DOLLAR, cs) else (.SYSTEM_IDENTIFIER name, cs)
    else if c == '`' then
      let (name, cs) := collectWhile cs isIdentChar
      (.COMPILER_DIRECTIVE name, cs)
    else if c.isDigit then
      lexNumber (c :: cs)
    else if c == '\'' then
      let (s, cs) := lexBasedTail "" cs
      (.UNSIGNED_NUMBER s, cs)
    else if c == '"' then
      lexStringLit cs
    else
      match c, cs with
      | '<', '<' :: '<' :: cs  => (.LT_LT_LT,   cs)
      | '<', '<' :: cs         => (.LT_LT,      cs)
      | '<', '=' :: cs         => (.LT_EQ,      cs)
      | '<', _                 => (.LT,          cs)
      | '>', '>' :: '>' :: cs  => (.GT_GT_GT,   cs)
      | '>', '>' :: cs         => (.GT_GT,      cs)
      | '>', '=' :: cs         => (.GT_EQ,      cs)
      | '>', _                 => (.GT,          cs)
      | '=', '>' :: cs         => (.ARROW,      cs)
      | '=', '=' :: '=' :: cs  => (.EQ_EQ_EQ,   cs)
      | '=', '=' :: cs         => (.EQ_EQ,      cs)
      | '=', _                 => (.EQ,          cs)
      | '!', '=' :: '=' :: cs  => (.BANG_EQ_EQ, cs)
      | '!', '=' :: cs         => (.BANG_EQ,    cs)
      | '!', _                 => (.BANG,        cs)
      | '&', '&' :: cs         => (.AMP_AMP,    cs)
      | '&', _                 => (.AMP,         cs)
      | '|', '|' :: cs         => (.PIPE_PIPE,  cs)
      | '|', _                 => (.PIPE,        cs)
      | '~', '&' :: cs         => (.TILDE_AMP,  cs)
      | '~', '|' :: cs         => (.TILDE_PIPE, cs)
      | '~', '^' :: cs         => (.TILDE_CARET,cs)
      | '~', _                 => (.TILDE,       cs)
      | '^', '~' :: cs         => (.CARET_TILDE,cs)
      | '^', '|' :: cs         => (.CARET_PIPE,  cs)
      | '^', _                 => (.CARET,       cs)
      | '*', '*' :: cs         => (.STAR_STAR,   cs)
      | '*', '>' :: cs         => (.STAR_GT,    cs)
      | '*', _                 => (.STAR,        cs)
      | '+', ':' :: cs         => (.PLUS_COLON, cs)
      | '+', _                 => (.PLUS,        cs)
      | '-', ':' :: cs         => (.MINUS_COLON,cs)
      | '-', _                 => (.MINUS,       cs)
      | '(', _                 => (.LPAREN,      cs)
      | ')', _                 => (.RPAREN,      cs)
      | '[', _                 => (.LBRACKET,    cs)
      | ']', _                 => (.RBRACKET,    cs)
      | '{', _                 => (.LBRACE,      cs)
      | '}', _                 => (.RBRACE,      cs)
      | ';', _                 => (.SEMI,        cs)
      | ':', _                 => (.COLON,       cs)
      | ',', _                 => (.COMMA,       cs)
      | '.', _                 => (.DOT,         cs)
      | '@', _                 => (.AT,          cs)
      | '#', _                 => (.HASH,        cs)
      | '?', _                 => (.QUESTION,    cs)
      | '/', _                 => (.SLASH,       cs)
      | '%', _                 => (.PERCENT,     cs)
      | _,   _                 => lexOne cs

-- ---------------------------------------------------------------------------
-- Tokenize entire string
-- ---------------------------------------------------------------------------

partial def tokenize (src : String) : Array Token :=
  go src.toList #[]
where
  go : Chars → Array Token → Array Token
    | cs, acc =>
      let cs := skipWsAndComments cs
      match cs with
      | [] => acc.push .EOF
      | _  =>
        let (tok, cs) := lexOne cs
        go cs (acc.push tok)

end Verilog
