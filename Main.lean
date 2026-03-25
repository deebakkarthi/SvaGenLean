import SvaGenLean

def usage : String :=
  "Usage: sva_gen_lean [OPTIONS] [FILE]\n" ++
  "\n" ++
  "Parse a Verilog-1995 file and emit its AST (default) or a Lean model.\n" ++
  "If FILE is omitted, input is read from stdin.\n" ++
  "\n" ++
  "Options:\n" ++
  "  --emit-lean   Emit a Lean 4 Circuit model (combinational designs only)\n" ++
  "  -h, --help    Show this message and exit"

def main (args : List String) : IO Unit := do
  if args.contains "-h" || args.contains "--help" then
    println! "{usage}"
    return
  let (flags, rest) := args.partition (·.startsWith "--")
  let src ← match rest with
    | [path] => IO.FS.readFile path
    | _      => IO.getStdin >>= (·.readToEnd)
  match Verilog.parse src with
  | .error e => println! "Error: {e}"; IO.Process.exit 1
  | .ok ast  =>
    if flags.contains "--emit-lean" then
      match Verilog.checkCombinational ast with
      | some msg => println! "Error: {msg}"; IO.Process.exit 1
      | none     => println! "{Verilog.emitLean ast}"
    else
      println! "{repr ast}"
