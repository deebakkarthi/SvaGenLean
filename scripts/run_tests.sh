#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BIN="$REPO_DIR/.lake/build/bin/Main"
TEST_DIR="$REPO_DIR/tests/parser_test"

# Build first
cd "$REPO_DIR"
lake build 2>&1

# Check iverilog is available
if ! command -v iverilog &>/dev/null; then
  echo "WARNING: iverilog not found; running in parse-only mode (no oracle)"
  HAVE_IVERILOG=0
else
  HAVE_IVERILOG=1
fi

# iverilog exit codes:
#   0 → success (syntax + elaboration OK)
#   1 → elaboration error (syntax is valid, semantics are not)
#   2 → syntax/parse error ("I give up")
iv_syntax_ok() {
  local exit_code
  iverilog -tnull "$1" >/dev/null 2>&1
  exit_code=$?
  # exit 2 means "syntax error / I give up" — the file is not syntactically valid.
  # Any other exit code (0=OK, 1/7=elaboration error) means syntax parsed fine.
  [[ $exit_code -ne 2 ]]
}

both_pass=0      # both accept (correct)
parser_miss=0    # oracle accepts, we reject  ← real bugs
both_reject=0    # both reject (consistent)
extra_accept=0   # we accept, oracle rejects  (we are more permissive; OK)

bugs=""

for f in "$TEST_DIR"/*.v; do
  name="$(basename "$f" .v)"

  parser_ok=0
  "$BIN" "$f" >/dev/null 2>&1 && parser_ok=1

  if [[ $HAVE_IVERILOG -eq 1 ]]; then
    oracle_ok=0
    iv_syntax_ok "$f" && oracle_ok=1

    if   [[ $oracle_ok -eq 1 && $parser_ok -eq 1 ]]; then
      both_pass=$((both_pass + 1))
    elif [[ $oracle_ok -eq 1 && $parser_ok -eq 0 ]]; then
      parser_miss=$((parser_miss + 1))
      msg="$("$BIN" "$f" 2>&1 | head -1)" || true
      bugs="${bugs}MISS  ${name}: ${msg}\n"
    elif [[ $oracle_ok -eq 0 && $parser_ok -eq 0 ]]; then
      both_reject=$((both_reject + 1))
    else
      extra_accept=$((extra_accept + 1))
    fi
  else
    if [[ $parser_ok -eq 1 ]]; then
      both_pass=$((both_pass + 1))
    else
      parser_miss=$((parser_miss + 1))
      msg="$("$BIN" "$f" 2>&1 | head -1)" || true
      bugs="${bugs}FAIL  ${name}: ${msg}\n"
    fi
  fi
done

echo ""
if [[ $HAVE_IVERILOG -eq 1 ]]; then
  total=$((both_pass + parser_miss + both_reject + extra_accept))
  echo "Oracle: iverilog syntax check (exit 0=OK, 1=semantic error, 2=syntax error)"
  echo ""
  printf "  %-12s %d/%d\n" "PASS"         "$both_pass"    "$total"
  printf "  %-12s %d/%d  ← bugs\n" "MISS" "$parser_miss"  "$total"
  printf "  %-12s %d/%d  (both reject syntax-invalid files)\n" "BOTH_REJECT" "$both_reject" "$total"
  printf "  %-12s %d/%d  (we accept semantically-invalid but syntactically-valid files)\n" "EXTRA_ACCEPT" "$extra_accept" "$total"
else
  echo "Results (no oracle, parse-only):"
  echo "  PASS: $both_pass  FAIL: $parser_miss"
fi

if [[ -n "$bugs" ]]; then
  echo ""
  printf "%b" "$bugs"
fi

[[ $parser_miss -eq 0 ]]
