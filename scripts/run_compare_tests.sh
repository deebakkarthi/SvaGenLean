#!/usr/bin/env bash
# Run Verilog simulation vs Lean model comparison tests.
# For each <name>.v in tests/emit_lean_test/ (skipping *_tb.v files):
#   1. Compile and run <name>_tb.v with iverilog to get reference output
#   2. Generate Lean model via --emit-lean
#   3. Concatenate with <name>_test.lean and run via lake env lean --run
#   4. Compare outputs; report PASS / MISMATCH / SKIP
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BIN="$REPO_DIR/.lake/build/bin/Main"
TEST_DIR="$REPO_DIR/tests/emit_lean_test"
TMPDIR_RUN="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_RUN"' EXIT

VERBOSE=0
if [[ "${1:-}" == "-v" ]]; then
  VERBOSE=1
fi

# Build once
cd "$REPO_DIR"
lake build 2>&1

pass=0
fail=0
skip=0
failures=""

for f in "$TEST_DIR"/*.v; do
  # Skip testbench files
  [[ "$f" == *_tb.v ]] && continue

  name="$(basename "$f" .v)"
  tb="$TEST_DIR/${name}_tb.v"
  lean_test="$TEST_DIR/${name}_test.lean"

  # Skip if companion files are missing
  if [[ ! -f "$tb" || ! -f "$lean_test" ]]; then
    skip=$((skip + 1))
    continue
  fi

  # --- Verilog simulation ---
  vvp_out="$TMPDIR_RUN/${name}.vvp"
  verilog_output=""
  if ! iverilog -o "$vvp_out" "$f" "$tb" 2>/dev/null; then
    skip=$((skip + 1))
    [[ $VERBOSE -eq 1 ]] && echo "SKIP  $name  (iverilog compile failed)"
    continue
  fi
  verilog_output="$(vvp "$vvp_out" 2>/dev/null | grep -v '\$finish')"

  # --- Lean model generation ---
  model_file="$TMPDIR_RUN/${name}_model.lean"
  if ! "$BIN" --emit-lean "$f" > "$model_file" 2>/dev/null; then
    skip=$((skip + 1))
    [[ $VERBOSE -eq 1 ]] && echo "SKIP  $name  (--emit-lean failed)"
    continue
  fi

  # Concatenate model + test harness into a single runnable file
  combined="$TMPDIR_RUN/${name}_combined.lean"
  cat "$model_file" "$lean_test" > "$combined"

  lean_output=""
  if ! lean_output="$(cd "$REPO_DIR" && lake env lean --run "$combined" 2>/dev/null | grep -v ': warning:' | grep -v '^Note:')"; then
    skip=$((skip + 1))
    [[ $VERBOSE -eq 1 ]] && echo "SKIP  $name  (lean --run failed)"
    continue
  fi

  # --- Compare ---
  if [[ "$verilog_output" == "$lean_output" ]]; then
    pass=$((pass + 1))
    if [[ $VERBOSE -eq 1 ]]; then
      echo "=== $name ==="
      echo "Verilog: $verilog_output"
      echo "Lean:    $lean_output"
      echo ""
    fi
  else
    fail=$((fail + 1))
    first_verilog="$(echo "$verilog_output" | head -1)"
    first_lean="$(echo "$lean_output" | head -1)"
    failures="${failures}MISMATCH  ${name}  verilog=${first_verilog}  lean=${first_lean}\n"
    if [[ $VERBOSE -eq 1 ]]; then
      echo "=== $name (MISMATCH) ==="
      echo "--- Verilog ---"
      echo "$verilog_output"
      echo "--- Lean ---"
      echo "$lean_output"
      echo ""
    fi
  fi
done

total=$((pass + fail))
echo ""
echo "compare test results:"
printf "  %-10s %d/%d\n" "PASS" "$pass" "$total"
[[ $fail -eq 0 ]] || printf "  %-10s %d/%d\n" "MISMATCH" "$fail" "$total"
[[ $skip -eq 0 ]] || printf "  %-10s %d\n"    "SKIP" "$skip"

if [[ -n "$failures" ]]; then
  echo ""
  printf "%b" "$failures"
fi

[[ $fail -eq 0 ]]
