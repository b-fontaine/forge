# Forge — Shared Test Helpers
# <!-- Audit: B.1 (b1-scaffolder — extracted from b1-foundations foundations.test.sh) -->
#
# Shared helpers sourced by every Forge test harness under
# .forge/scripts/tests/. Exposes assertion functions, a uniform
# test-runner, and PASS/FAIL counters that each harness aggregates
# into its own totals.
#
# Usage:
#   # Inside foundations.test.sh or scaffolder.test.sh:
#   source "$(dirname "${BASH_SOURCE[0]}")/_helpers.sh"
#   run_test some_test_fn
#
# Counters `PASS`, `FAIL`, `FAIL_NAMES` are initialised on first
# `source`. A harness SHOULD reset them to 0 / () before its own
# main() to avoid cross-harness pollution if two harnesses are sourced
# in the same shell (rare).

# Idempotent initialisation — a harness sourcing this file twice must
# not double-init counters.
: "${PASS:=0}"
: "${FAIL:=0}"
if ! declare -p FAIL_NAMES >/dev/null 2>&1; then
  FAIL_NAMES=()
fi

# ─── Assertion helpers ──────────────────────────────────────────

assert_eq() {
  # assert_eq <expected> <actual> [message]
  local expected="$1"
  local actual="$2"
  local msg="${3:-assert_eq}"
  if [ "$expected" != "$actual" ]; then
    echo "    ${msg}: expected='${expected}' actual='${actual}'" >&2
    return 1
  fi
}

assert_contains() {
  # assert_contains <haystack> <needle> [message]
  local haystack="$1"
  local needle="$2"
  local msg="${3:-assert_contains}"
  if ! printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    echo "    ${msg}: needle='${needle}' not in haystack" >&2
    echo "    haystack preview: $(printf '%s' "$haystack" | head -5)" >&2
    return 1
  fi
}

assert_not_contains() {
  # assert_not_contains <haystack> <needle> [message]
  local haystack="$1"
  local needle="$2"
  local msg="${3:-assert_not_contains}"
  if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    echo "    ${msg}: needle='${needle}' unexpectedly found" >&2
    return 1
  fi
}

# ─── Generic tmpdir + trap ──────────────────────────────────────

mk_tmpdir_with_trap() {
  # mk_tmpdir_with_trap <template-prefix>
  # Creates a tmpdir with the given prefix and echoes the path.
  # The caller remains responsible for setting:
  #   trap "rm -rf '<path>'" RETURN
  # immediately after capturing the echo (consistent with the existing
  # pattern in foundations.test.sh). A future refactor may centralise
  # the trap here if bash EXIT traps prove safer to share.
  local prefix="${1:-forge-tmp}"
  mktemp -d -t "${prefix}-XXXXXX"
}

# ─── Test runner ────────────────────────────────────────────────

run_test() {
  # run_test <function_name> — invoke the named test, print ✓/✗,
  # increment PASS/FAIL. Fail reason is whatever the test function
  # emitted to stderr before returning non-zero.
  local name="$1"
  if "$name"; then
    PASS=$((PASS + 1))
    echo "  ✓ ${name}"
  else
    FAIL=$((FAIL + 1))
    FAIL_NAMES+=("$name")
    echo "  ✗ ${name}"
  fi
}

# ─── Summary printer ────────────────────────────────────────────

print_summary() {
  # print_summary — prints the aggregated PASS/FAIL summary and
  # returns 0 if FAIL == 0, else 1. Harnesses call this at the end of
  # main().
  echo ""
  echo "── Summary ──"
  echo "  Passed:  $PASS"
  echo "  Failed:  $FAIL"
  if [ "$FAIL" -gt 0 ]; then
    echo "  Failures:"
    for n in "${FAIL_NAMES[@]}"; do echo "    - $n"; done
    return 1
  fi
  return 0
}
