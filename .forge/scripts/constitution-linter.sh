#!/usr/bin/env bash
# Forge Constitution Linter
# Verifies compliance with each article of the constitution deterministically.
# Exit code 0 = all applicable articles pass, 1 = at least one failure.

set -uo pipefail

FORGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHANGES_DIR="$FORGE_ROOT/.forge/changes"
PASS=0
FAIL=0
NA=0

pass()    { PASS=$((PASS + 1)); echo "  PASS  $1"; }
fail()    { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; }
not_applicable() { NA=$((NA + 1)); echo "  N/A   $1"; }

has_flutter() { [ -f "$FORGE_ROOT/pubspec.yaml" ]; }
has_rust()    { [ -f "$FORGE_ROOT/Cargo.toml" ]; }

echo "CONSTITUTION LINT REPORT"
echo "========================"
echo ""

# ── Article I: TDD ─────────────────────────────────────────────
echo "Article I (TDD):"

if has_flutter; then
  dart_files=$(find "$FORGE_ROOT/lib" -name "*.dart" -not -path "*/generated/*" 2>/dev/null | wc -l | tr -d ' ')
  test_files=$(find "$FORGE_ROOT/test" -name "*_test.dart" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$dart_files" = "0" ]; then
    not_applicable "  No Dart source files found"
  elif [ "$test_files" = "0" ]; then
    fail "  $dart_files Dart source files but 0 test files"
  else
    ratio=$((test_files * 100 / dart_files))
    if [ "$ratio" -ge 50 ]; then
      pass "  Test-to-source ratio: ${test_files}/${dart_files} (${ratio}%)"
    else
      fail "  Low test-to-source ratio: ${test_files}/${dart_files} (${ratio}%) — expected >=50%"
    fi
  fi
elif has_rust; then
  rs_files=$(find "$FORGE_ROOT/src" -name "*.rs" 2>/dev/null | wc -l | tr -d ' ')
  cfg_test_count=$(grep -rl '#\[cfg(test)\]' "$FORGE_ROOT/src/" 2>/dev/null | wc -l | tr -d ' ')
  test_dir_files=$(find "$FORGE_ROOT/tests" -name "*.rs" 2>/dev/null | wc -l | tr -d ' ')
  total_test=$((cfg_test_count + test_dir_files))
  if [ "$rs_files" = "0" ]; then
    not_applicable "  No Rust source files found"
  elif [ "$total_test" = "0" ]; then
    fail "  $rs_files Rust source files but 0 test modules/files"
  else
    pass "  Rust test coverage: $cfg_test_count inline #[cfg(test)] + $test_dir_files test files"
  fi
else
  not_applicable "  No Flutter or Rust project detected"
fi

# ── Article II: BDD ────────────────────────────────────────────
echo ""
echo "Article II (BDD):"

feature_files=$(find "$FORGE_ROOT" -name "*.feature" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
if [ -d "$CHANGES_DIR" ]; then
  ac_count=$(grep -rl 'AC-[0-9]' "$CHANGES_DIR"/ 2>/dev/null | wc -l | tr -d ' ')
else
  ac_count=0
fi

if [ "$ac_count" = "0" ]; then
  not_applicable "  No acceptance criteria found in changes"
elif [ "$feature_files" = "0" ]; then
  fail "  $ac_count files with ACs but 0 .feature files found"
else
  pass "  $feature_files .feature files found for $ac_count files with ACs"
fi

# ── Article III: Specs Before Code ─────────────────────────────
echo ""
echo "Article III (Specs Before Code):"

if [ ! -d "$CHANGES_DIR" ] || [ -z "$(ls -A "$CHANGES_DIR" 2>/dev/null)" ]; then
  not_applicable "  No active changes"
else
  art3_ok=true
  for change_dir in "$CHANGES_DIR"/*/; do
    [ -d "$change_dir" ] || continue
    name="$(basename "$change_dir")"
    forge_yaml="$change_dir/.forge.yaml"
    if [ ! -f "$forge_yaml" ]; then
      fail "  $name: missing .forge.yaml"
      art3_ok=false
      continue
    fi
    status=$(grep '^status:' "$forge_yaml" | head -1 | awk '{print $2}')
    case "$status" in
      implemented|archived)
        if [ ! -f "$change_dir/specs.md" ]; then
          fail "  $name: implemented without specs.md"
          art3_ok=false
        fi
        ;;
    esac
  done
  if $art3_ok; then
    pass "  All changes have specs before implementation"
  fi
fi

# ── Article IV: Delta Format ──────────────────────────────────
echo ""
echo "Article IV (Delta-Based Changes):"

if [ ! -d "$CHANGES_DIR" ] || [ -z "$(ls -A "$CHANGES_DIR" 2>/dev/null)" ]; then
  not_applicable "  No active changes"
else
  art4_ok=true
  for change_dir in "$CHANGES_DIR"/*/; do
    [ -d "$change_dir" ] || continue
    name="$(basename "$change_dir")"
    specs="$change_dir/specs.md"
    if [ -f "$specs" ]; then
      has_delta=$(grep -c '## ADDED\|## MODIFIED\|## REMOVED' "$specs" 2>/dev/null || echo "0")
      if [ "$has_delta" = "0" ]; then
        # Check if it's just a template (comments only)
        real_content=$(grep -v '^<!--' "$specs" | grep -v '^$' | grep -v '^#' | wc -l | tr -d ' ')
        if [ "$real_content" -gt 2 ]; then
          fail "  $name: specs.md has content but no ADDED/MODIFIED/REMOVED sections"
          art4_ok=false
        fi
      fi
    fi
  done
  if $art4_ok; then
    pass "  All specs use delta format (ADDED/MODIFIED/REMOVED)"
  fi
fi

# ── Article VI: Flutter Architecture ──────────────────────────
echo ""
echo "Article VI (Flutter Architecture):"

if has_flutter; then
  # Domain must not import Flutter
  domain_imports=$(grep -rl "import 'package:flutter" "$FORGE_ROOT/lib/features"/*/domain/ 2>/dev/null | wc -l | tr -d ' ')
  if [ "$domain_imports" = "0" ]; then
    pass "  Domain layer has zero Flutter imports"
  else
    fail "  $domain_imports domain files import Flutter (layer violation)"
  fi

  # Check flutter_bloc in pubspec
  if grep -q 'flutter_bloc' "$FORGE_ROOT/pubspec.yaml" 2>/dev/null; then
    pass "  flutter_bloc declared in pubspec.yaml"
  else
    fail "  flutter_bloc not found in pubspec.yaml (required by Article VI.3)"
  fi

  # Check get_it/injectable in pubspec
  if grep -q 'get_it\|injectable' "$FORGE_ROOT/pubspec.yaml" 2>/dev/null; then
    pass "  get_it/injectable declared in pubspec.yaml"
  else
    fail "  get_it/injectable not found in pubspec.yaml (required by Article VI.4)"
  fi
else
  not_applicable "  No Flutter project detected"
fi

# ── Article VII: Rust Architecture ────────────────────────────
echo ""
echo "Article VII (Rust Architecture):"

if has_rust; then
  # No unwrap in production code
  unwrap_count=$(grep -rn '\.unwrap()' "$FORGE_ROOT/src/" 2>/dev/null | grep -v '#\[cfg(test)\]' | grep -v '// SAFETY:' | wc -l | tr -d ' ')
  if [ "$unwrap_count" = "0" ]; then
    pass "  Zero unwrap() in production code"
  else
    fail "  $unwrap_count unwrap() calls in production code"
  fi

  # No panic in production code
  panic_count=$(grep -rn 'panic!' "$FORGE_ROOT/src/" 2>/dev/null | grep -v '#\[cfg(test)\]' | wc -l | tr -d ' ')
  if [ "$panic_count" = "0" ]; then
    pass "  Zero panic!() in production code"
  else
    fail "  $panic_count panic!() calls in production code"
  fi

  # Undocumented unsafe
  unsafe_blocks=$(grep -rn 'unsafe' "$FORGE_ROOT/src/" 2>/dev/null | grep -v '#\[cfg(test)\]' | wc -l | tr -d ' ')
  safety_comments=$(grep -rn '// SAFETY:' "$FORGE_ROOT/src/" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$unsafe_blocks" = "0" ]; then
    pass "  Zero unsafe blocks"
  elif [ "$safety_comments" -ge "$unsafe_blocks" ]; then
    pass "  All unsafe blocks have SAFETY comments ($unsafe_blocks blocks, $safety_comments comments)"
  else
    fail "  $unsafe_blocks unsafe blocks but only $safety_comments SAFETY comments"
  fi

  # Domain purity
  if [ -d "$FORGE_ROOT/src/domain" ]; then
    infra_imports=$(grep -rn 'sqlx\|reqwest\|hyper\|tonic' "$FORGE_ROOT/src/domain/" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$infra_imports" = "0" ]; then
      pass "  Domain layer has zero infrastructure imports"
    else
      fail "  $infra_imports infrastructure imports in domain/"
    fi
  fi
else
  not_applicable "  No Rust project detected"
fi

# ── Article VIII: Infrastructure ──────────────────────────────
echo ""
echo "Article VIII (Infrastructure):"

dockerfiles=$(find "$FORGE_ROOT" -name "Dockerfile*" -not -path "*/.git/*" 2>/dev/null)
if [ -z "$dockerfiles" ]; then
  not_applicable "  No Dockerfiles found"
else
  art8_ok=true
  for df in $dockerfiles; do
    name=$(basename "$df")
    # Check multi-stage
    stages=$(grep -c '^FROM' "$df" 2>/dev/null || echo "0")
    if [ "$stages" -lt 2 ]; then
      fail "  $name: not multi-stage ($stages FROM directives, need >=2)"
      art8_ok=false
    fi
    # Check distroless in final stage
    last_from=$(grep '^FROM' "$df" | tail -1)
    if echo "$last_from" | grep -qi 'distroless\|alpine\|scratch'; then
      : # ok
    else
      fail "  $name: final stage is not distroless/alpine/scratch"
      art8_ok=false
    fi
  done
  if $art8_ok; then
    pass "  All Dockerfiles are multi-stage with minimal runtime images"
  fi
fi

# ── Article IX: Observability ─────────────────────────────────
echo ""
echo "Article IX (Observability):"

if has_flutter; then
  if grep -q 'opentelemetry_dart\|opentelemetry_api' "$FORGE_ROOT/pubspec.yaml" 2>/dev/null; then
    pass "  Flutter: OpenTelemetry SDK declared in pubspec.yaml"
  else
    fail "  Flutter: opentelemetry_dart not found in pubspec.yaml (required by Article IX.3)"
  fi
elif has_rust; then
  if grep -q 'tracing' "$FORGE_ROOT/Cargo.toml" 2>/dev/null; then
    pass "  Rust: tracing crate declared in Cargo.toml"
  else
    fail "  Rust: tracing crate not found in Cargo.toml (required by Article IX.4)"
  fi
  if grep -q 'tracing-opentelemetry\|opentelemetry' "$FORGE_ROOT/Cargo.toml" 2>/dev/null; then
    pass "  Rust: OpenTelemetry bridge declared in Cargo.toml"
  else
    fail "  Rust: tracing-opentelemetry not found in Cargo.toml (required by Article IX.4)"
  fi
else
  not_applicable "  No Flutter or Rust project detected"
fi

# ── Article X: Code Quality ──────────────────────────────────
echo ""
echo "Article X (Code Quality):"

# Untracked TODOs
todo_dirs=""
[ -d "$FORGE_ROOT/lib" ] && todo_dirs="$todo_dirs $FORGE_ROOT/lib/"
[ -d "$FORGE_ROOT/src" ] && todo_dirs="$todo_dirs $FORGE_ROOT/src/"
if [ -n "$todo_dirs" ]; then
  untracked=$(grep -rn 'TODO\|FIXME' $todo_dirs 2>/dev/null | grep -v 'ISSUE-\|ISSUE:\|#[0-9]' | wc -l | tr -d ' ')
  if [ "$untracked" = "0" ]; then
    pass "  Zero untracked TODO/FIXME"
  else
    fail "  $untracked untracked TODO/FIXME without issue reference"
  fi
else
  not_applicable "  No source directories found"
fi

# ── Article XI: AI-First ─────────────────────────────────────
echo ""
echo "Article XI (AI-First Design):"

schema="default"
if [ -f "$FORGE_ROOT/.forge.yaml" ]; then
  schema=$(grep '^schema:' "$FORGE_ROOT/.forge.yaml" | head -1 | awk '{print $2}')
fi

if [ "$schema" = "ai-first" ]; then
  # Check for fallback implementations
  fallback_count=$(grep -rl 'fallback\|Fallback\|FALLBACK' "$FORGE_ROOT/lib/" "$FORGE_ROOT/src/" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$fallback_count" -gt 0 ]; then
    pass "  $fallback_count files with fallback implementations found"
  else
    fail "  AI-first schema but no fallback implementations found (required by Article XI.5)"
  fi
else
  not_applicable "  Schema is '$schema', not ai-first"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "========================"
echo "PASS: $PASS | FAIL: $FAIL | N/A: $NA"

if [ "$FAIL" -gt 0 ]; then
  echo "OVERALL: FAIL ($FAIL violations)"
  exit 1
else
  echo "OVERALL: PASS"
  exit 0
fi
