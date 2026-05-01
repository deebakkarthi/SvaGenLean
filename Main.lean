import SvaGenLean

def help: IO Unit := do
  IO.print "Usage: svagenlean [FILE|-h]
  Convert a verilog file into its lean representation
  FILE\ta verilog file. If not passed, input is read from stdin
  -h\tPrint out this help message\n"

def main(args: List String) : IO UInt32:= do
  match args with
  -- Read from stdin if no args are provided
  | [] => do
    let stdin <- IO.getStdin
    let file <- stdin.readToEnd
    lex file
    return 0
  | x::xs => 
    -- If we have multiple args
    if xs !=[] then help
    if x == "-h" then do
      help
      IO.Process.exit 0
    -- We know that x isn't -h and is something else
    -- Check if it starts with -. If it doesn' then interpret that as a file
    if x.startsWith "-" then do
      help
      IO.Process.exit 1
      -- Exit if the file is not found
    if !(<- System.FilePath.pathExists x)then do
      IO.println s!"svagenlean: {x}  not found"
      IO.Process.exit 1

    let file <- IO.FS.readFile x
    lex file
    return 0
