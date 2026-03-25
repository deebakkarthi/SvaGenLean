#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BIN="$REPO_DIR/.lake/build/bin/Main"
TEST_DIR="$REPO_DIR/tests/iverilog"

# Build first
cd "$REPO_DIR"
lake build

pass=0
fail=0
errors=""

for f in "$TEST_DIR"/*.v; do
  name="$(basename "$f" .v)"
  if result="$("$BIN" "$f" 2>&1)"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    msg="$(echo "$result" | head -1)"
    errors="${errors}FAIL ${name}: ${msg}\n"
  fi
done

echo "PASS: $pass  FAIL: $fail"
if [[ -n "$errors" ]]; then
  echo ""
  printf "%b" "$errors"
fi

[[ $fail -eq 0 ]]
