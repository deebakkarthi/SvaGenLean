#!/usr/bin/env bash
# Run --emit-lean on every test file under tests/emit_lean_test/.
# A test passes if the command exits 0.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BIN="$REPO_DIR/.lake/build/bin/Main"
TEST_DIR="$REPO_DIR/tests/emit_lean_test"

VERBOSE=0
if [[ "${1:-}" == "-v" ]]; then
  VERBOSE=1
fi

cd "$REPO_DIR"
lake build 2>&1

pass=0
fail=0
failures=""

for f in "$TEST_DIR"/*.v; do
  [[ "$f" == *_tb.v ]] && continue
  name="$(basename "$f" .v)"
  output="$("$BIN" --emit-lean "$f" 2>&1)" && exit_ok=1 || exit_ok=0
  if [[ $exit_ok -eq 1 ]]; then
    pass=$((pass + 1))
    if [[ $VERBOSE -eq 1 ]]; then
      echo "=== $name ==="
      echo "$output"
      echo ""
    fi
  else
    fail=$((fail + 1))
    failures="${failures}FAIL  ${name}: $(echo "$output" | head -1)\n"
  fi
done

total=$((pass + fail))
echo ""
echo "emit-lean test results:"
printf "  %-8s %d/%d\n" "PASS" "$pass" "$total"
[[ $fail -eq 0 ]] || printf "  %-8s %d/%d\n" "FAIL" "$fail" "$total"

if [[ -n "$failures" ]]; then
  echo ""
  printf "%b" "$failures"
fi

[[ $fail -eq 0 ]]
