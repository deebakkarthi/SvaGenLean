#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$REPO_DIR/tests/comb_test"

if ! command -v iverilog &>/dev/null; then
  echo "ERROR: iverilog not found" >&2
  exit 1
fi

pass=0
fail=0
errors=""

for f in "$TEST_DIR"/**/*.v; do
  name="${f#"$REPO_DIR"/}"
  if result="$(iverilog -g1995 -tnull "$f" 2>&1)"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    errors="${errors}FAIL ${name}:\n${result}\n\n"
  fi
done

echo "Verilog-1995 compatibility (iverilog -g1995):"
echo "  PASS: $pass  FAIL: $fail"

if [[ -n "$errors" ]]; then
  echo ""
  printf "%b" "$errors"
fi

[[ $fail -eq 0 ]]
