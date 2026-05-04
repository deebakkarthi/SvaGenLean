-- Concepts borrowed from "Writing an Interpreter in Go - Thorsten Ball"
namespace Lexer

structure Lexer where
  input: List Char
  position: Nat
  ch: Option Char
  deriving Repr

inductive Token where
  | ILLEGAL
  | LEGAL
  | EOF
deriving Repr, DecidableEq

def init (input: String) : Lexer:=
  match input.isEmpty with
  | true => {input:=input.toList, position:=0, ch:=.none : Lexer}
  | false =>
  {input:=input.toList, position:=0, ch:=.some  (input.front) : Lexer}

def advance (l :Lexer) :Lexer :=
  if l.position >= l.input.length then {l with ch:=.none} else 
  {l with position:=l.position+1, ch:=l.input[l.position+1]? :Lexer}

partial def seek (l: Lexer) (condition: Option Char -> Bool) : Lexer :=
  if condition l.ch then seek (advance l) condition else l

def skipWhitespace (l: Lexer) : Lexer :=
   match l.ch with
   | .none => l
   | .some ch => seek l (fun (ch: Option Char) =>
     match ch with
     | .none => false
     | .some x => x.isWhitespace)


def nextToken (l: Lexer) : Lexer × (Option Token) :=
  let l := skipWhitespace l
  match l.ch with
  | .none => (l, .none)
  | .some x => 
    match x with
    | '+' => (advance l, .some .LEGAL)
    | _ => (advance l,  .some .ILLEGAL)

end Lexer
