import SvaGenLean

def main (args : List String) : IO Unit := do
  let src ← match args with
    | [path] => IO.FS.readFile path
    | _      => IO.getStdin >>= (·.readToEnd)
  match Verilog.parse src with
  | .error e => println! "Error: {e}"
  | .ok ast  => println! "{repr ast}"
