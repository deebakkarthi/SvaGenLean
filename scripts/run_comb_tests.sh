#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BIN="$REPO_DIR/.lake/build/bin/Main"
PASS_DIR="$REPO_DIR/tests/comb_test/pass"
FAIL_DIR="$REPO_DIR/tests/comb_test/fail"

cd "$REPO_DIR"
lake build 2>&1

pass=0
fail=0
errors=""

# Files in pass/ must produce no "Only Combinational" message (exit 0, no warning)
for f in "$PASS_DIR"/*.v; do
  name="$(basename "$f" .v)"
  output="$("$BIN" "$f" 2>&1)"
  if echo "$output" | grep -q "Only Combinational Circuits supported now"; then
    fail=$((fail + 1))
    errors="${errors}FAIL [pass/${name}]: got rejection but expected acceptance\n"
  elif echo "$output" | grep -q "^Error:"; then
    fail=$((fail + 1))
    msg="$(echo "$output" | grep "^Error:" | head -1)"
    errors="${errors}FAIL [pass/${name}]: parse error: ${msg}\n"
  else
    pass=$((pass + 1))
  fi
done

# Files in fail/ must produce the "Only Combinational" message
for f in "$FAIL_DIR"/*.v; do
  name="$(basename "$f" .v)"
  output="$("$BIN" "$f" 2>&1)"
  if echo "$output" | grep -q "Only Combinational Circuits supported now"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    msg="$(echo "$output" | head -1)"
    errors="${errors}FAIL [fail/${name}]: expected rejection, got: ${msg}\n"
  fi
done

echo ""
echo "Combinational-logic check tests:"
echo "  PASS: $pass  FAIL: $fail"

if [[ -n "$errors" ]]; then
  echo ""
  printf "%b" "$errors"
fi

[[ $fail -eq 0 ]]
