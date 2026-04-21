#!/usr/bin/env bash
# Forge Deterministic Verification Script
# Runs concrete, file-based checks that do not depend on LLM judgment.
# Exit code 0 = all checks pass, 1 = at least one failure.

set -uo pipefail

FORGE_ROOT="${FORGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CHANGES_DIR="$FORGE_ROOT/.forge/changes"
PASS=0
FAIL=0
WARN=0

# ─── Helpers ────────────────────────────────────────────────────

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }
warn() { WARN=$((WARN + 1)); echo "  ⚠ $1"; }
section() { echo ""; echo "── $1 ──"; }

# ─── 1. Change Artifact Completeness ───────────────────────────

section "Change Artifact Completeness"

if [ ! -d "$CHANGES_DIR" ] || [ -z "$(ls -A "$CHANGES_DIR" 2>/dev/null)" ]; then
  warn "No active changes in .forge/changes/"
else
  for change_dir in "$CHANGES_DIR"/*/; do
    [ -d "$change_dir" ] || continue
    change_name="$(basename "$change_dir")"
    forge_yaml="$change_dir/.forge.yaml"

    if [ ! -f "$forge_yaml" ]; then
      fail "$change_name: missing .forge.yaml"
      continue
    fi

    status=$(grep '^status:' "$forge_yaml" | head -1 | awk '{print $2}')
    pass "$change_name: .forge.yaml found (status: $status)"

    # Check artifacts exist based on status progression (cumulative)
    needs_proposal=false; needs_specs=false; needs_design=false; needs_tasks=false
    case "$status" in
      implemented|archived) needs_tasks=true; needs_design=true; needs_specs=true; needs_proposal=true ;;
      planned)              needs_design=true; needs_specs=true; needs_proposal=true ;;
      designed)             needs_specs=true; needs_proposal=true ;;
      specified)            needs_proposal=true ;;
    esac

    if $needs_proposal; then
      [ -f "$change_dir/proposal.md" ] && pass "$change_name: proposal.md exists" || fail "$change_name: missing proposal.md (required at status=$status)"
    fi
    if $needs_specs; then
      [ -f "$change_dir/specs.md" ] && pass "$change_name: specs.md exists" || fail "$change_name: missing specs.md (required at status=$status)"
    fi
    if $needs_design; then
      [ -f "$change_dir/design.md" ] && pass "$change_name: design.md exists" || fail "$change_name: missing design.md (required at status=$status)"
    fi
    if $needs_tasks; then
      [ -f "$change_dir/tasks.md" ] && pass "$change_name: tasks.md exists" || fail "$change_name: missing tasks.md (required at status=$status)"
    fi
  done
fi

# ─── 2. Flutter Checks ─────────────────────────────────────────

if [ -f "$FORGE_ROOT/pubspec.yaml" ]; then
  section "Flutter Checks"

  # Static analysis
  if command -v flutter &>/dev/null; then
    if flutter analyze --fatal-infos "$FORGE_ROOT" 2>/dev/null; then
      pass "flutter analyze: zero issues"
    else
      fail "flutter analyze: issues found"
    fi

    # Formatting
    if dart format --output=none --set-exit-if-changed "$FORGE_ROOT/lib" 2>/dev/null; then
      pass "dart format: all files formatted"
    else
      fail "dart format: unformatted files found"
    fi

    # Tests + coverage
    if flutter test --coverage "$FORGE_ROOT" 2>/dev/null; then
      pass "flutter test: all tests pass"

      # Coverage threshold
      if [ -f "$FORGE_ROOT/coverage/lcov.info" ]; then
        if command -v lcov &>/dev/null; then
          coverage=$(lcov --summary "$FORGE_ROOT/coverage/lcov.info" 2>&1 | grep 'lines' | grep -oP '\d+\.\d+(?=%)' || echo "0")
          if [ "$(echo "$coverage >= 80" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
            pass "Coverage: ${coverage}% (>= 80%)"
          else
            fail "Coverage: ${coverage}% (< 80% threshold)"
          fi
        else
          warn "lcov not installed, cannot check coverage threshold"
        fi
      fi
    else
      fail "flutter test: test failures"
    fi
  else
    warn "flutter CLI not found, skipping Flutter checks"
  fi

  # Layer boundary: domain must not import Flutter
  domain_flutter_imports=$(grep -rl "import 'package:flutter" "$FORGE_ROOT/lib/features"/*/domain/ 2>/dev/null | wc -l | tr -d ' ')
  if [ "$domain_flutter_imports" = "0" ]; then
    pass "Layer boundary: domain has zero Flutter imports"
  else
    fail "Layer boundary: $domain_flutter_imports domain files import Flutter"
  fi
fi

# ─── 3. Rust Checks ────────────────────────────────────────────

if [ -f "$FORGE_ROOT/Cargo.toml" ]; then
  section "Rust Checks"

  if command -v cargo &>/dev/null; then
    # Clippy
    if cargo clippy --all-features --manifest-path "$FORGE_ROOT/Cargo.toml" -- -D warnings 2>/dev/null; then
      pass "cargo clippy: zero warnings"
    else
      fail "cargo clippy: warnings found"
    fi

    # Formatting
    if cargo fmt --all --manifest-path "$FORGE_ROOT/Cargo.toml" --check 2>/dev/null; then
      pass "cargo fmt: all files formatted"
    else
      fail "cargo fmt: unformatted files found"
    fi

    # Tests
    if cargo test --all-features --manifest-path "$FORGE_ROOT/Cargo.toml" 2>/dev/null; then
      pass "cargo test: all tests pass"
    else
      fail "cargo test: test failures"
    fi

    # unwrap/panic in production code
    unwrap_count=$(grep -rn '\.unwrap()' "$FORGE_ROOT/src/" 2>/dev/null | grep -v '#\[cfg(test)\]' | grep -v '// SAFETY:' | wc -l | tr -d ' ')
    if [ "$unwrap_count" = "0" ]; then
      pass "No unwrap() in production code"
    else
      fail "$unwrap_count unwrap() calls in production code (src/)"
    fi

    panic_count=$(grep -rn 'panic!' "$FORGE_ROOT/src/" 2>/dev/null | grep -v '#\[cfg(test)\]' | wc -l | tr -d ' ')
    if [ "$panic_count" = "0" ]; then
      pass "No panic!() in production code"
    else
      fail "$panic_count panic!() calls in production code (src/)"
    fi
  else
    warn "cargo CLI not found, skipping Rust checks"
  fi

  # Domain purity: domain must not import infra crates directly
  domain_infra=$(grep -rn 'sqlx\|reqwest\|hyper\|tonic' "$FORGE_ROOT/src/domain/" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$domain_infra" = "0" ]; then
    pass "Domain purity: no infrastructure imports in domain/"
  else
    fail "Domain purity: $domain_infra infrastructure imports in domain/"
  fi
fi

# ─── 4. Constitution Compliance (Cross-Language) ────────────────

section "Constitution Compliance"

# No untracked TODOs/FIXMEs
todo_dirs=""
[ -d "$FORGE_ROOT/lib" ] && todo_dirs="$todo_dirs $FORGE_ROOT/lib/"
[ -d "$FORGE_ROOT/src" ] && todo_dirs="$todo_dirs $FORGE_ROOT/src/"
if [ -n "$todo_dirs" ]; then
  untracked_todos=$(grep -rn 'TODO\|FIXME' $todo_dirs 2>/dev/null | grep -v 'ISSUE-\|ISSUE:\|#[0-9]' | wc -l | tr -d ' ')
  if [ "$untracked_todos" = "0" ]; then
    pass "No untracked TODO/FIXME (Article X.4)"
  else
    fail "$untracked_todos untracked TODO/FIXME without issue reference (Article X.4)"
  fi
else
  warn "No lib/ or src/ directories found, skipping TODO check"
fi

# Root .forge.yaml exists
if [ -f "$FORGE_ROOT/.forge.yaml" ]; then
  pass "Root .forge.yaml exists"
else
  fail "Root .forge.yaml missing"
fi

# Constitution exists
if [ -f "$FORGE_ROOT/.forge/constitution.md" ]; then
  pass "Constitution exists"
else
  fail "Constitution missing"
fi

# Standards index exists
if [ -f "$FORGE_ROOT/.forge/standards/index.yml" ]; then
  pass "Standards index exists"
else
  fail "Standards index missing"
fi

# ─── 5. Monorepo Foundations (conditional) ─────────────────────

# This section activates only for projects that have adopted the
# full-stack-monorepo archetype (b1-foundations, audit module B.1).
# Non-monorepo projects are unaffected: the validator is skipped.

if [ -d "$FORGE_ROOT/.forge/schemas/full-stack-monorepo" ]; then
  section "Monorepo Foundations"
  foundations_script="$FORGE_ROOT/.forge/scripts/validate-foundations.sh"
  if [ -x "$foundations_script" ] || [ -f "$foundations_script" ]; then
    # Run the validator, capture its PASS/FAIL lines, and aggregate
    # counters into the enclosing verify.sh totals.
    while IFS= read -r line; do
      case "$line" in
        "PASS: "*) pass "${line#PASS: }" ;;
        "FAIL: "*) fail "${line#FAIL: }" ;;
        *) [ -n "$line" ] && echo "  $line" ;;
      esac
    done < <(FORGE_ROOT="$FORGE_ROOT" bash "$foundations_script" || true)
  else
    warn "validate-foundations.sh missing or not executable — skipping"
  fi
else
  # Intentionally emit an informational message so non-monorepo users
  # see explicit confirmation that the conditional check was skipped.
  echo ""
  echo "── Monorepo Foundations ──"
  echo "  (validate-foundations skipped — not a monorepo)"
fi

# ─── 6. Scaffolder (conditional) ───────────────────────────────

# Activates only when the archetype template tree exists (b1-scaffolder).
# Always runs L1 (plan-shape) and L2 (overlay-rendering) — both are
# hermetic and need no external tools. L3 (end-to-end) is NOT invoked
# from verify.sh because it requires flutter + cargo + buf and takes
# several seconds; run `bash .forge/scripts/tests/scaffolder.test.sh
# --require-external-tools` explicitly on a tooled CI runner.

if [ -d "$FORGE_ROOT/.forge/templates/archetypes/full-stack-monorepo" ]; then
  section "Scaffolder (L1 + L2)"
  scaffolder_harness="$FORGE_ROOT/.forge/scripts/tests/scaffolder.test.sh"
  if [ -x "$scaffolder_harness" ] || [ -f "$scaffolder_harness" ]; then
    while IFS= read -r line; do
      case "$line" in
        "  ✓ "*) pass "${line#  ✓ }" ;;
        "  ✗ "*) fail "${line#  ✗ }" ;;
        # Swallow everything else (harness banner, summary, etc.) so
        # verify.sh owns the output format.
      esac
    done < <(bash "$scaffolder_harness" --level 2 2>&1 || true)
  else
    warn "scaffolder.test.sh missing or not executable — skipping"
  fi
else
  echo ""
  echo "── Scaffolder ──"
  echo "  (scaffolder tests skipped — no archetype template tree)"
fi

# ─── Summary ───────────────────────────────────────────────────

section "Summary"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Warnings: $WARN"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "RESULT: FAIL ($FAIL failures)"
  exit 1
else
  echo ""
  echo "RESULT: PASS"
  exit 0
fi
