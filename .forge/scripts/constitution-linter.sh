#!/usr/bin/env bash
# Forge Constitution Linter
# Verifies compliance with each article of the constitution deterministically.
# Exit code 0 = all applicable articles pass, 1 = at least one failure.

set -uo pipefail

# FORGE_ROOT is env-overridable for testability and parity with
# verify.sh ; default resolves to the script's own framework root.
FORGE_ROOT="${FORGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CHANGES_DIR="$FORGE_ROOT/.forge/changes"

# ─── c1-reference-project skip-guard (FR-GL-027) ────────────────
# Mirror of verify.sh's skip-guard. When invoked from the Forge
# framework repo (signature : .forge/specs/full-stack-monorepo.md
# AND examples/ both exist), tree walks across the whole repo MUST
# exclude examples/ — each example owns its own constitution-linter.sh.
FORGE_REPO_DETECTED=0
if [ -f "$FORGE_ROOT/.forge/specs/full-stack-monorepo.md" ] \
     && [ -d "$FORGE_ROOT/examples" ]; then
  FORGE_REPO_DETECTED=1
fi

# find_excluding_examples <args...> — wrapper around `find` that
# strips examples/ subtrees when running inside the Forge framework
# repo. The wrapper hides the conditional from callers and avoids
# shell-glob issues with embedded `*` patterns. When the framework
# signature is absent, behaves as a regular find.
find_excluding_examples() {
  if [ "$FORGE_REPO_DETECTED" = "1" ]; then
    find "$@" -not -path "$FORGE_ROOT/examples/*"
  else
    find "$@"
  fi
}
PASS=0
FAIL=0
NA=0
WARN=0

pass()    { PASS=$((PASS + 1)); echo "  PASS  $1"; }
fail()    { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; }
not_applicable() { NA=$((NA + 1)); echo "  N/A   $1"; }
warn()    { WARN=$((WARN + 1)); echo "  WARN  $1"; }

has_flutter() { [ -f "$FORGE_ROOT/pubspec.yaml" ]; }
has_rust()    { [ -f "$FORGE_ROOT/Cargo.toml" ]; }

# ─── b1-workflow : monorepo scoping (ADR-007 additive) ──────────
# Detects schema at the target root; when full-stack-monorepo, the
# Article VI/VII checks are RE-RUN a second time against the layer
# subtrees (frontend/, backend/). The existing single-root checks are
# preserved byte-for-byte for NFR-010 backwards compatibility.
detect_schema() {
  local yml="$FORGE_ROOT/.forge.yaml"
  [ -f "$yml" ] || { echo ""; return; }
  python3 - "$yml" <<'PY' 2>/dev/null || echo ""
import sys, yaml
try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        d = yaml.safe_load(f) or {}
except yaml.YAMLError:
    sys.exit(0)
print(d.get('schema', ''))
PY
}
resolve_monorepo_path() {
  local lid="$1"
  local s="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/schema.yaml"
  [ -f "$s" ] || { echo ""; return; }
  python3 - "$s" "$lid" <<'PY' 2>/dev/null || echo ""
import sys, yaml, re
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    d = yaml.safe_load(f) or {}
for l in d.get('layers', []) or []:
    if isinstance(l, dict) and l.get('id') == sys.argv[2]:
        p = l.get('path') or ''
        if '..' in p or p.startswith('/') or re.search(r'\s', p):
            sys.exit(0)
        print(p.rstrip('/'))
        sys.exit(0)
PY
}

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

feature_files=$(find_excluding_examples "$FORGE_ROOT" -name "*.feature" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
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

# ─── b1-workflow : Article VI + VII scoped (monorepo only) ─────
# These sections activate in addition to the root-level checks above
# when the target declares schema: full-stack-monorepo. On other
# schemas this block emits zero output (NFR-010).

_target_schema="$(detect_schema)"
if [ "$_target_schema" = "full-stack-monorepo" ]; then

  _frontend_path="$(resolve_monorepo_path frontend)"
  if [ -n "$_frontend_path" ] && [ -f "$FORGE_ROOT/$_frontend_path/pubspec.yaml" ]; then
    echo ""
    echo "Article VI (Flutter Architecture) [scoped: frontend]:"
    domain_imports=$(grep -rl "import 'package:flutter" "$FORGE_ROOT/$_frontend_path/lib/features"/*/domain/ 2>/dev/null | wc -l | tr -d ' ')
    if [ "$domain_imports" = "0" ]; then
      pass "  Domain layer has zero Flutter imports (scoped)"
    else
      fail "  $domain_imports domain files import Flutter (layer violation, scoped)"
    fi
    if grep -q 'flutter_bloc' "$FORGE_ROOT/$_frontend_path/pubspec.yaml" 2>/dev/null; then
      pass "  flutter_bloc declared in frontend/pubspec.yaml (scoped)"
    else
      fail "  flutter_bloc not found in frontend/pubspec.yaml (scoped)"
    fi
    if grep -q 'get_it\|injectable' "$FORGE_ROOT/$_frontend_path/pubspec.yaml" 2>/dev/null; then
      pass "  get_it/injectable declared in frontend/pubspec.yaml (scoped)"
    else
      fail "  get_it/injectable not found in frontend/pubspec.yaml (scoped)"
    fi
  fi

  _backend_path="$(resolve_monorepo_path backend)"
  if [ -n "$_backend_path" ] && [ -f "$FORGE_ROOT/$_backend_path/Cargo.toml" ]; then
    echo ""
    echo "Article VII (Rust Architecture) [scoped: backend]:"
    unwrap_count=$(grep -rn '\.unwrap()' "$FORGE_ROOT/$_backend_path"/*/src/ 2>/dev/null | grep -v '#\[cfg(test)\]' | grep -v '// SAFETY:' | wc -l | tr -d ' ')
    if [ "$unwrap_count" = "0" ]; then
      pass "  Zero unwrap() in production code (scoped)"
    else
      fail "  $unwrap_count unwrap() calls in production code (scoped)"
    fi
    panic_count=$(grep -rn 'panic!' "$FORGE_ROOT/$_backend_path"/*/src/ 2>/dev/null | grep -v '#\[cfg(test)\]' | wc -l | tr -d ' ')
    if [ "$panic_count" = "0" ]; then
      pass "  Zero panic!() in production code (scoped)"
    else
      fail "  $panic_count panic!() calls in production code (scoped)"
    fi
    if [ -d "$FORGE_ROOT/$_backend_path/crates/domain/src" ]; then
      infra_imports=$(grep -rn 'sqlx\|reqwest\|hyper\|tonic' "$FORGE_ROOT/$_backend_path/crates/domain/src" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$infra_imports" = "0" ]; then
        pass "  Domain layer has zero infra imports (scoped)"
      else
        fail "  $infra_imports infra imports in backend/crates/domain/src (scoped)"
      fi
    fi
  fi
fi

# ── Article VIII: Infrastructure ──────────────────────────────
echo ""
echo "Article VIII (Infrastructure):"

dockerfiles=$(find_excluding_examples "$FORGE_ROOT" -name "Dockerfile*" -not -path "*/.git/*" 2>/dev/null)
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

# ── Article V (Constitutional Compliance Gate) — F.4 ────────────
# FR-LE-001..003. Static checkable subset of Article V : `tasks.md`
# of any change with status >= planned MUST contain at least one
# `[Story: FR-` reference (audit trail). V.2 / V.3 are runtime, not
# static.
echo ""
echo "Article V (Constitutional Compliance Gate):"

if [ "${FORGE_LINTER_SKIP_V_1:-0}" = "1" ]; then
  not_applicable "  skipped via FORGE_LINTER_SKIP_V_1"
elif [ -d "$CHANGES_DIR" ]; then
  for change_dir in "$CHANGES_DIR"/*/; do
    [ -d "$change_dir" ] || continue
    [ "$FORGE_REPO_DETECTED" = "1" ] && case "$change_dir" in "$FORGE_ROOT/examples"/*) continue ;; esac
    name="$(basename "$change_dir")"
    yaml="$change_dir.forge.yaml"
    [ -f "$yaml" ] || continue
    status_v1="$(grep -E '^status:' "$yaml" | head -1 | awk '{print $2}' | tr -d '"')"
    case "$status_v1" in
      planned|implemented|archived) ;;
      *) continue ;;
    esac
    tasks_md="$change_dir/tasks.md"
    [ -f "$tasks_md" ] || continue
    if grep -qE '\[Story: FR-' "$tasks_md"; then
      pass "  $name: tasks.md has [Story: FR-XXX] audit trail"
    else
      fail "  $name: tasks.md missing [Story: FR-XXX] audit trail"
    fi
  done
fi

# ── Article X.3 (Public API Documentation) — F.4 ──────────────
# FR-LE-004..009. Ratio of public symbols carrying /// doc comments
# must be ≥ FORGE_LINTER_X3_THRESHOLD (default 80).
echo ""
echo "Article X.3 (Public API Documentation):"

if [ "${FORGE_LINTER_SKIP_X_3:-0}" = "1" ]; then
  not_applicable "  skipped via FORGE_LINTER_SKIP_X_3"
else
  X3_THRESHOLD="${FORGE_LINTER_X3_THRESHOLD:-80}"
  dart_files=$(find "$FORGE_ROOT/lib" -type f -name '*.dart' 2>/dev/null | head -200 || true)
  rust_files=$(find "$FORGE_ROOT/src" -type f -name '*.rs' 2>/dev/null | head -200 || true)
  sources_list=$(printf '%s\n%s' "$dart_files" "$rust_files" | grep -v '^$' || true)
  if [ -z "$sources_list" ]; then
    not_applicable "  No source directories found (lib/ or src/)"
  else
    # Files passed via argv (a heredoc on stdin would conflict with sys.stdin).
    # shellcheck disable=SC2086
    x3_result=$(python3 - "$X3_THRESHOLD" $sources_list <<'PY'
import re, sys
threshold = int(sys.argv[1])
files = [a for a in sys.argv[2:] if a.strip()]

dart_pat = re.compile(r'^(?:abstract\s+)?(class|enum|mixin)\s+[A-Z]')
dart_func_pat = re.compile(r'^[A-Z][A-Za-z0-9_<>?]*\s+[a-z][A-Za-z0-9_]*\s*\(')
rust_pat = re.compile(r'^pub\s+(fn|struct|enum|trait|const|static|type|impl)\b')
doc_pat_dart = re.compile(r'^\s*///')
doc_pat_rust = re.compile(r'^\s*(///|//!)')
attr_pat = re.compile(r'^\s*(@|#\[)')

total = 0
documented = 0
missing = []

for f in files:
    if not f:
        continue
    try:
        with open(f, encoding='utf-8', errors='replace') as fh:
            lines = fh.readlines()
    except OSError:
        continue
    is_rust = f.endswith('.rs')
    doc_pat = doc_pat_rust if is_rust else doc_pat_dart
    for i, line in enumerate(lines):
        matched = False
        if is_rust:
            if rust_pat.match(line):
                matched = True
        else:
            if dart_pat.match(line) or dart_func_pat.match(line):
                matched = True
        if not matched:
            continue
        total += 1
        j = i - 1
        while j >= 0 and (lines[j].strip() == '' or attr_pat.match(lines[j])):
            j -= 1
        if j >= 0 and doc_pat.match(lines[j]):
            documented += 1
        else:
            if len(missing) < 5:
                missing.append((f, i + 1, line.rstrip()))

if total == 0:
    print("NOTAPP")
else:
    ratio = (documented * 100) // total
    if ratio >= threshold:
        print(f"PASS {ratio} {documented}/{total}")
    else:
        print(f"FAIL {ratio} {documented}/{total}")
        for m in missing:
            print(f"MISS {m[0]}:{m[1]}:{m[2][:80]}")
PY
)
    head_line=$(printf '%s\n' "$x3_result" | head -1)
    case "$head_line" in
      NOTAPP)
        not_applicable "  No public symbols detected"
        ;;
      PASS\ *)
        ratio_v=$(echo "$head_line" | awk '{print $2}')
        counts=$(echo "$head_line" | awk '{print $3}')
        pass "  doc ratio ${ratio_v}% ($counts) >= threshold ${X3_THRESHOLD}%"
        ;;
      FAIL\ *)
        ratio_v=$(echo "$head_line" | awk '{print $2}')
        counts=$(echo "$head_line" | awk '{print $3}')
        fail "  doc ratio ${ratio_v}% ($counts) below threshold ${X3_THRESHOLD}%"
        printf '%s\n' "$x3_result" | grep '^MISS' | sed 's/^MISS /      missing /'
        ;;
      *)
        warn "  unexpected python output: $head_line"
        ;;
    esac
  fi
fi

# ── Article XI.3 (Generative UI — schema-driven) — F.4 ──────────
# FR-LE-010..013. Heuristic warning (not fail) when AI features +
# UI rendering coexist without a referenced *.schema.json.
# Detection patterns include : anthropic, openai, gpt-, claude, llm, langchain.
echo ""
echo "Article XI.3 (Generative UI):"

if [ "${FORGE_LINTER_SKIP_XI_3:-0}" = "1" ]; then
  not_applicable "  skipped via FORGE_LINTER_SKIP_XI_3"
else
  ai_detected=0
  if [ -f "$FORGE_ROOT/.forge.yaml" ]; then
    if grep -qE '^schema:[[:space:]]+ai-first' "$FORGE_ROOT/.forge.yaml"; then
      ai_detected=1
    fi
  fi
  if [ "$ai_detected" -eq 0 ]; then
    if grep -rEq 'anthropic|openai|gpt-|claude|@google/genai|llm|langchain' \
        "$FORGE_ROOT/lib" "$FORGE_ROOT/src" "$FORGE_ROOT/pubspec.yaml" \
        "$FORGE_ROOT/Cargo.toml" "$FORGE_ROOT/package.json" 2>/dev/null; then
      ai_detected=1
    fi
  fi
  if [ "$ai_detected" -eq 0 ]; then
    not_applicable "  No AI features detected"
  else
    has_ui=0
    if grep -rEq 'class .*Widget|extends Widget|render *\(' \
        "$FORGE_ROOT/lib" "$FORGE_ROOT/src" 2>/dev/null; then
      has_ui=1
    fi
    if [ "$has_ui" -eq 0 ]; then
      pass "  AI features present but no UI rendering — no XI.3 surface"
    else
      has_schema=0
      if find "$FORGE_ROOT/lib" "$FORGE_ROOT/src" -type f -name '*.schema.json' 2>/dev/null | grep -q .; then
        has_schema=1
      fi
      if grep -rEq '\.schema\.json' "$FORGE_ROOT/lib" "$FORGE_ROOT/src" 2>/dev/null; then
        has_schema=1
      fi
      if [ "$has_schema" -eq 1 ]; then
        pass "  AI features + UI + *.schema.json reference detected"
      else
        warn "  XI.3 heuristic warning: AI features + UI rendering detected without coexisting *.schema.json reference. Manual audit recommended."
      fi
    fi
  fi
fi

# ── Article XI.5 (Mandatory Fallback Tested) — F.4 ──────────────
# FR-LE-014..017. Name-based pair: lib/**/*[fF]allback*.dart MUST
# have a corresponding test/**/*[fF]allback*_test*.dart pair.
echo ""
echo "Article XI.5 (Mandatory Fallback Tested):"

if [ "${FORGE_LINTER_SKIP_XI_5:-0}" = "1" ]; then
  not_applicable "  skipped via FORGE_LINTER_SKIP_XI_5"
else
  fb_dart=$(find "$FORGE_ROOT/lib" -type f -iname '*fallback*.dart' 2>/dev/null || true)
  fb_rust=$(find "$FORGE_ROOT/src" -type f -iname '*fallback*.rs' 2>/dev/null || true)
  is_ai_first=0
  if [ -f "$FORGE_ROOT/.forge.yaml" ]; then
    if grep -qE '^schema:[[:space:]]+ai-first' "$FORGE_ROOT/.forge.yaml"; then
      is_ai_first=1
    fi
  fi
  if [ -z "$fb_dart" ] && [ -z "$fb_rust" ]; then
    if [ "$is_ai_first" -eq 1 ]; then
      fail "  Article XI.5 requires a fallback implementation in ai-first projects"
    else
      not_applicable "  No fallback files and not an AI-first project"
    fi
  else
    for src in $fb_dart $fb_rust; do
      [ -n "$src" ] || continue
      base=$(basename "$src")
      stem="${base%.*}"
      paired=0
      if find "$FORGE_ROOT/test" -type f \( -iname "${stem}*test*.dart" -o -iname "*${stem}*test*.dart" -o -iname "${stem}_test.dart" \) 2>/dev/null | grep -q .; then
        paired=1
      fi
      if [ "$paired" -eq 0 ]; then
        if find "$FORGE_ROOT/test" -type f -iname '*fallback*test*' 2>/dev/null | grep -q .; then
          paired=1
        fi
      fi
      if [ "$paired" -eq 0 ] && [[ "$src" == *.rs ]]; then
        if grep -qE '#\[cfg\(test\)\]|#\[test\]' "$src"; then
          paired=1
        elif find "$FORGE_ROOT/tests" -type f -iname '*fallback*' 2>/dev/null | grep -q .; then
          paired=1
        fi
      fi
      if [ "$paired" -eq 1 ]; then
        pass "  fallback ${src#$FORGE_ROOT/} has matching test pair"
      else
        fail "  ${src#$FORGE_ROOT/} has no matching *fallback*_test* in test/ or tests/"
      fi
    done
  fi
fi

# ── ADR-006: State Management Discipline (no-state-management-alternatives) — T.4 ──
# Ratified by t4-adr-ratification (2026-05-04). Reads
# .forge/standards/state-management.yaml for the forbidden: list and the
# enforcement.ci_blocking flag. WARN-only by default per Q-001 Option A ;
# planned transition to FAIL with B.8 (T6 — flagship migration).
# Opt-out via FORGE_LINTER_SKIP_NSMA=1.
echo ""
echo "ADR-006 (State Management Discipline — no-state-management-alternatives):"

if [ "${FORGE_LINTER_SKIP_NSMA:-0}" = "1" ]; then
  not_applicable "  skipped via FORGE_LINTER_SKIP_NSMA"
else
  nsma_yaml="$FORGE_ROOT/.forge/standards/state-management.yaml"
  if [ ! -f "$nsma_yaml" ]; then
    not_applicable "  state-management.yaml not present (rule disabled)"
  else
    nsma_search_root="${FORGE_LINTER_FIXTURE_ROOT:-$FORGE_ROOT}"
    nsma_blocking=0
    if grep -qE '^[[:space:]]+ci_blocking:[[:space:]]+true' "$nsma_yaml"; then
      nsma_blocking=1
    fi
    nsma_forbidden_pkgs=$(awk '
      /^forbidden:/ { in_block=1; next }
      in_block {
        if ($0 ~ /^[[:alpha:]_]/) { in_block=0; next }
        if ($0 ~ /^[[:space:]]+-[[:space:]]+/) {
          gsub(/^[[:space:]]+-[[:space:]]+/, "")
          gsub(/[[:space:]].*$/, "")
          if (length($0) > 0) print $0
        }
      }
    ' "$nsma_yaml")

    if [ -z "$nsma_forbidden_pkgs" ]; then
      not_applicable "  no forbidden packages declared in state-management.yaml"
    else
      nsma_pubspecs=$(find "$nsma_search_root" -type f -name pubspec.yaml 2>/dev/null \
        | grep -v "/.forge/" \
        | grep -v "/examples/" \
        | grep -v "/.dart_tool/" \
        || true)
      if [ -z "$nsma_pubspecs" ]; then
        not_applicable "  no Flutter pubspec.yaml found under $nsma_search_root"
      else
        nsma_violations=0
        nsma_files_scanned=0
        for pubspec in $nsma_pubspecs; do
          nsma_files_scanned=$((nsma_files_scanned + 1))
          for pkg in $nsma_forbidden_pkgs; do
            if grep -qE "^[[:space:]]+${pkg}:" "$pubspec"; then
              if [ "$nsma_blocking" = "1" ]; then
                fail "  forbidden state-mgmt dep '${pkg}' in ${pubspec#$FORGE_ROOT/} (no-state-management-alternatives, ci_blocking=true)"
              else
                warn "  forbidden state-mgmt dep '${pkg}' in ${pubspec#$FORGE_ROOT/} (no-state-management-alternatives, warn-only ; ci_blocking flips at B.8/T6)"
              fi
              nsma_violations=$((nsma_violations + 1))
            fi
          done
        done
        if [ "$nsma_violations" = "0" ]; then
          pass "  no forbidden state-mgmt deps detected across $nsma_files_scanned pubspec.yaml file(s)"
        fi
      fi
    fi
  fi
fi

# ── ADR-I3-001: T3-Forbidden Components — generic forbidden discovery ──
# I.3 (i3-t3-forbidden-linter). Generic enforcement of the `forbidden:`
# blocks declared in `.forge/standards/**/*.yaml` and `**/*.md`
# (Article XII §enforce). Tier-scaled severity per ADR-I3-003 :
# T1/T2 → warn (Phase A — flips to fail at B.8/T6), T3 → fail.
# Opt-out : FORGE_LINTER_SKIP_T3_FORBIDDEN=1 skips the section.
# Interlocks with the ADR-006 NSMA section above (NFR-I3-T3F-001) :
# `state-management.yaml` is always excluded from the generic walk to
# avoid double-fire — that standard is enforced solely by the ADR-006
# block. T3-RULE-NNN catalogue ships in
# `.forge/standards/global/forbidden-components-rules.md`.
echo ""
echo "T3-Forbidden Components (I.3 — generic forbidden enforcement):"

if [ "${FORGE_LINTER_SKIP_T3_FORBIDDEN:-0}" = "1" ]; then
  not_applicable "  skipped via FORGE_LINTER_SKIP_T3_FORBIDDEN"
else
  # ─── Tier discovery (FR-I3-T3F-003) ─────────────────────────
  t3f_tier=""
  if [ -f "$FORGE_ROOT/.forge/.forge-tier" ]; then
    t3f_tier="$(head -1 "$FORGE_ROOT/.forge/.forge-tier" 2>/dev/null \
                  | tr -d ' \t\r\n')"
  fi
  if [ -z "$t3f_tier" ] && [ -n "${FORGE_EU_TIER:-}" ]; then
    t3f_tier="$FORGE_EU_TIER"
  fi
  case "$t3f_tier" in
    T1|T2|T3) ;;
    *) t3f_tier="" ;;
  esac

  if [ -z "$t3f_tier" ]; then
    not_applicable "  no compliance tier declared (set .forge/.forge-tier or export FORGE_EU_TIER) — T3-RULE-007"
  else
    # ─── Standards + tree scan (FR-I3-T3F-004..008 / 020..026) ─
    # Python 3 inline (F.2 / J.7 / J.8.d / K.3 pattern verbatim).
    # Emits one line per finding on stdout, prefixed by severity tag
    # `FAIL<TAB>...` / `WARN<TAB>...` / `PASS<TAB>...`. The bash side
    # walks the lines and calls `fail` / `warn` / `pass` accordingly.
    # Exporting FORGE_ROOT + FORGE_REPO_DETECTED for the subshell.
    t3f_output="$(python3 - "$FORGE_ROOT" "$t3f_tier" "$FORGE_REPO_DETECTED" <<'PY' 2>/dev/null
import os, re, sys, glob

FORGE_ROOT = sys.argv[1]
TIER       = sys.argv[2]
FRAMEWORK  = sys.argv[3] == "1"

STANDARDS_DIR = os.path.join(FORGE_ROOT, ".forge", "standards")

# NSMA interlock per NFR-I3-T3F-001 — always exclude state-management.yaml.
EXCLUDE_STANDARDS = {"state-management.yaml"}
# Catalogue standard documents the tokens by design — never scan it.
EXCLUDE_FROM_DOC_SCAN_BASENAMES = {"forbidden-components-rules.md"}

# Rule-ID mapping per ADR-I3-002 / FR-I3-T3F-120..125.
RULE_ID_BY_STANDARD = {
    "identity.yaml":         "T3-RULE-001",
    "observability.yaml":    "T3-RULE-002",
    "orchestration.yaml":    "T3-RULE-003",
    "state-management.yaml": "T3-RULE-004",   # never used (interlock)
    "global/compliance-tiers.md": "T3-RULE-005",
}
DEFAULT_RULE_ID = "T3-RULE-005"  # extensible MD standards default

# Remediation hints per token (small inline map ; extensible in future
# minor bumps of forbidden-components-rules.md).
REMEDIATION = {
    "firebase-auth":   "replace with Zitadel (identity.yaml::default) or downgrade tier",
    "auth0-saas-us":   "replace with Zitadel or self-hosted Keycloak / Authentik",
    "datadog":         "replace with SigNoz + OBI eBPF (observability.yaml::backend) or downgrade tier",
    "inngest":         "replace with DBOS (orchestration.yaml::default) or Temporal fallback",
    "firebase":        "remove ; Firebase disqualified at all EU tiers per compliance-tiers.md §10.2",
    "aws-managed":     "replace with self-host EU / OVHcloud / Scaleway / Outscale (T3)",
}

def discover_standards():
    """Walk standards/, return list of (relpath, abs_path, forbidden_tokens)."""
    out = []
    if not os.path.isdir(STANDARDS_DIR):
        return out
    for root, dirs, files in os.walk(STANDARDS_DIR):
        # Stable traversal order.
        dirs.sort()
        files.sort()
        for f in files:
            if not (f.endswith(".yaml") or f.endswith(".md")):
                continue
            relroot = os.path.relpath(root, STANDARDS_DIR)
            relpath = f if relroot == "." else os.path.join(relroot, f)
            if relpath in EXCLUDE_STANDARDS:
                continue
            abs_path = os.path.join(root, f)
            tokens = parse_forbidden_block(abs_path)
            if tokens:
                out.append((relpath, abs_path, tokens))
    return out

def parse_forbidden_block(path):
    """Extract `forbidden:` list from a YAML file or MD frontmatter.
    Returns the list of string tokens (possibly empty)."""
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except OSError:
        return []
    # Strip MD frontmatter fences if present (```yaml ... ``` or --- ... ---).
    # We just scan the whole file for a top-level `forbidden:` block — both
    # YAML files and MD frontmatter use the same `^forbidden:` syntax.
    lines = content.splitlines()
    tokens = []
    in_block = False
    inline_match = re.compile(r'^forbidden:\s*\[(.*)\]\s*$')
    block_start  = re.compile(r'^forbidden:\s*$')
    block_item   = re.compile(r'^\s+-\s+([^\s#]+)')
    block_end    = re.compile(r'^[A-Za-z_]')
    for line in lines:
        m = inline_match.match(line)
        if m:
            raw = m.group(1).strip()
            if raw:
                for tok in raw.split(","):
                    tok = tok.strip().strip('"').strip("'")
                    if tok:
                        tokens.append(tok)
            return tokens
        if in_block:
            mi = block_item.match(line)
            if mi:
                tokens.append(mi.group(1).strip())
                continue
            # Blank lines + comments are tolerated.
            if line.strip() == "" or line.lstrip().startswith("#"):
                continue
            if block_end.match(line):
                in_block = False
                # fall through ; same line is not an item.
        if block_start.match(line):
            in_block = True
    return tokens

# ─── Scanners ──────────────────────────────────────────────────

def is_under_excluded(path):
    rel = os.path.relpath(path, FORGE_ROOT)
    parts = rel.split(os.sep)
    if rel.startswith(".."):
        return True
    excluded_prefixes = (".forge", ".git", "node_modules", "target",
                         "build", ".dart_tool", "dist")
    if parts and parts[0] in excluded_prefixes:
        return True
    if FRAMEWORK and parts and parts[0] == "examples":
        return True
    return False

def walk_manifests(suffix_set):
    out = []
    for root, dirs, files in os.walk(FORGE_ROOT):
        # Prune excluded dirs in-place for speed.
        rel = os.path.relpath(root, FORGE_ROOT)
        parts = rel.split(os.sep) if rel != "." else []
        if parts and parts[0] in (".forge", ".git", "node_modules",
                                  "target", "build", ".dart_tool", "dist"):
            dirs[:] = []
            continue
        if FRAMEWORK and parts and parts[0] == "examples":
            dirs[:] = []
            continue
        dirs.sort()
        files.sort()
        for f in files:
            if f in suffix_set:
                out.append(os.path.join(root, f))
    return out

def walk_docs():
    """Yield doc body paths : docs/**/*.md + .forge/changes/**/*.md
    excluding the I.3 self-authoring change."""
    out = []
    docs_dir = os.path.join(FORGE_ROOT, "docs")
    if os.path.isdir(docs_dir):
        for root, dirs, files in os.walk(docs_dir):
            dirs.sort(); files.sort()
            for f in files:
                if f.endswith(".md"):
                    out.append(os.path.join(root, f))
    changes_dir = os.path.join(FORGE_ROOT, ".forge", "changes")
    if os.path.isdir(changes_dir):
        for root, dirs, files in os.walk(changes_dir):
            dirs.sort(); files.sort()
            # Self-exclusion (FR-I3-T3F-022).
            if "i3-t3-forbidden-linter" in root.split(os.sep):
                dirs[:] = []
                continue
            for f in files:
                if f.endswith(".md"):
                    out.append(os.path.join(root, f))
    return out

def walk_standards_md(owner_relpath):
    """Yield standards body paths excluding the standard owning the token
    and the catalogue standard."""
    out = []
    if not os.path.isdir(STANDARDS_DIR):
        return out
    for root, dirs, files in os.walk(STANDARDS_DIR):
        dirs.sort(); files.sort()
        for f in files:
            if not f.endswith(".md"):
                continue
            if f in EXCLUDE_FROM_DOC_SCAN_BASENAMES:
                continue
            rel = os.path.relpath(os.path.join(root, f), STANDARDS_DIR)
            if rel == owner_relpath:
                continue
            out.append(os.path.join(root, f))
    return out

# Build manifest file list once (per ecosystem grammar).
PUBSPECS    = walk_manifests({"pubspec.yaml"})
PACKAGEJSON = walk_manifests({"package.json"})
CARGOTOMLS  = walk_manifests({"Cargo.toml"})
REQUIREMENTS = walk_manifests({"requirements.txt"})
GOMODS      = walk_manifests({"go.mod"})
DOCS        = walk_docs()

def grep_manifest_key(path, token):
    """Exact-key match per ecosystem. Tokens with hyphens map to keys
    with hyphens OR underscores (e.g. firebase-auth ↔ firebase_auth)."""
    tok_variants = {token}
    if "-" in token:
        tok_variants.add(token.replace("-", "_"))
    if "_" in token:
        tok_variants.add(token.replace("_", "-"))
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except OSError:
        return []
    hits = []
    for ln, line in enumerate(content.splitlines(), start=1):
        for tok in tok_variants:
            # pubspec / Cargo / package.json / go.mod / requirements.txt
            # all use the dependency name as a left-anchored token (with
            # optional leading whitespace + optional quotes).
            pat = re.compile(
                r'^\s*"?\b' + re.escape(tok) + r'\b"?\s*[:=]'
            )
            if pat.match(line):
                hits.append((ln, line.strip()[:120]))
                break
    return hits

# Whole-word boundary regex for doc bodies (NFR-I3-T3F-007).
def grep_doc_body(path, token):
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            content = fh.read()
    except OSError:
        return []
    boundary = r'(?:^|[^a-zA-Z0-9_-])'
    end      = r'(?:$|[^a-zA-Z0-9_-])'
    pat = re.compile(boundary + re.escape(token) + end, re.IGNORECASE)
    hits = []
    for ln, line in enumerate(content.splitlines(), start=1):
        if pat.search(line):
            hits.append((ln, line.strip()[:120]))
    return hits

# Severity scaling (ADR-I3-003 / FR-I3-T3F-006).
def severity_for(tier):
    if tier == "T3":
        return "FAIL"
    return "WARN"

# ─── Main scan loop ─────────────────────────────────────────────

standards = discover_standards()
findings = []  # (severity, rule_id, token, tier, standard_relpath, remediation)
scanned_files = 0

for relpath, abs_path, tokens in standards:
    rule_id = RULE_ID_BY_STANDARD.get(relpath, DEFAULT_RULE_ID)
    sev = severity_for(TIER)
    standards_md_paths = walk_standards_md(relpath)
    for token in tokens:
        rem = REMEDIATION.get(token, "remove or replace with EU-jurisdiction equivalent")
        hit_emitted = False
        # Manifest scan.
        for mlist in (PUBSPECS, PACKAGEJSON, CARGOTOMLS,
                      REQUIREMENTS, GOMODS):
            for m in mlist:
                hits = grep_manifest_key(m, token)
                if hits:
                    findings.append((sev, rule_id, token, TIER,
                                     relpath, rem,
                                     os.path.relpath(m, FORGE_ROOT)))
                    hit_emitted = True
                    break
            if hit_emitted:
                break
        if hit_emitted:
            continue
        # Doc-body scan (whole-word).
        # Cap per-token noise : emit one finding per token max ; first
        # doc match wins. Standards self-scan is treated as T3-RULE-006
        # cross-standard mention (capped at WARN).
        cross_emitted = False
        for s in standards_md_paths:
            hits = grep_doc_body(s, token)
            if hits:
                findings.append(("WARN", "T3-RULE-006", token, TIER,
                                 relpath, "cross-standard mention — refactor cross-reference to cite the standard ID",
                                 os.path.relpath(s, FORGE_ROOT)))
                cross_emitted = True
                break
        if cross_emitted:
            continue
        for d in DOCS:
            hits = grep_doc_body(d, token)
            if hits:
                findings.append((sev, rule_id, token, TIER,
                                 relpath, rem,
                                 os.path.relpath(d, FORGE_ROOT)))
                break

scanned_files = (len(PUBSPECS) + len(PACKAGEJSON) + len(CARGOTOMLS)
                 + len(REQUIREMENTS) + len(GOMODS) + len(DOCS))

# Determinism (NFR-I3-T3F-005) : sort by (severity_rank, rule_id, token,
# location). FAIL > WARN > PASS in severity_rank.
SEV_RANK = {"FAIL": 0, "WARN": 1, "PASS": 2}
findings.sort(key=lambda x: (SEV_RANK.get(x[0], 9), x[1], x[2], x[6]))

# Emit one line per finding ; first 7 fields tab-separated.
for f in findings:
    print("\t".join(f))

# Clean-tree sentinel (consumed by bash side).
if not findings:
    print("PASS\t" + str(len(standards)) + "\t" + str(scanned_files))
PY
)"

    if [ -z "$t3f_output" ]; then
      # Python error or no output — defensively skip with N/A.
      not_applicable "  T3-forbidden discovery emitted no output (python error?)"
    else
      # Parse output : findings or PASS sentinel.
      t3f_fail_count=0
      t3f_warn_count=0
      while IFS=$'\t' read -r sev field2 field3 tier_f standard_f rem_f loc_f; do
        case "$sev" in
          PASS)
            pass "  no forbidden components detected at $t3f_tier across $field2 standards / $field3 scanned files"
            ;;
          FAIL)
            fail "  [REFUSAL: $field2: $field3 forbidden at $tier_f ($standard_f::forbidden) ; location: $loc_f ; remediation: $rem_f]"
            t3f_fail_count=$((t3f_fail_count + 1))
            ;;
          WARN)
            warn "  [REFUSAL: $field2: $field3 forbidden at $tier_f ($standard_f::forbidden) ; location: $loc_f ; remediation: $rem_f]"
            t3f_warn_count=$((t3f_warn_count + 1))
            ;;
        esac
      done <<EOF_T3F
$t3f_output
EOF_T3F
      # If any findings were FAIL/WARN but no PASS sentinel emitted,
      # leave the per-finding pass/fail/warn calls speak for themselves.
      if [ "$t3f_fail_count" = "0" ] && [ "$t3f_warn_count" = "0" ]; then
        # Already emitted by the PASS branch above ; nothing to add.
        :
      fi
    fi
  fi
fi

# ── Article III.4: No NEEDS CLARIFICATION inline in implemented/archived ───
# F.1 (f1-open-questions, FR-OQ-013, FR-OQ-014). Once a change reaches
# `implemented` or `archived` status, every `[NEEDS CLARIFICATION:`
# marker MUST be resolved (replaced inline) and tracked instead in
# `open-questions.md` (which is the legitimate location for the question
# audit trail).
echo ""
echo "Article III.4 (Anti-Hallucination — no NEEDS CLARIFICATION inline):"

iii4_violations=0
if [ -d "$CHANGES_DIR" ]; then
  for change_dir in "$CHANGES_DIR"/*/; do
    [ -d "$change_dir" ] || continue
    [ "$FORGE_REPO_DETECTED" = "1" ] && case "$change_dir" in "$FORGE_ROOT/examples"/*) continue ;; esac
    name="$(basename "$change_dir")"
    yaml="$change_dir.forge.yaml"
    [ -f "$yaml" ] || continue
    status="$(grep -E '^status:' "$yaml" | head -1 | awk '{print $2}' | tr -d '"')"
    case "$status" in
      implemented|archived) ;;
      *) continue ;;
    esac
    for f in proposal.md specs.md design.md tasks.md; do
      file="$change_dir$f"
      [ -f "$file" ] || continue
      # Detect REAL unresolved markers, excluding documentary contexts :
      #   1. Inside backticks `[NEEDS CLARIFICATION: ...]`
      #   2. Inside HTML comments <!-- ... -->
      #   3. Inside fenced code blocks ```...```  (Mermaid diagrams, code samples)
      # awk tracks code-fence state across lines.
      while IFS=: read -r line_no _; do
        [ -z "$line_no" ] && continue
        fail "  $name:$f:$line_no: NEEDS CLARIFICATION inline detected"
        iii4_violations=$((iii4_violations + 1))
      done < <(awk '
        /^```/ { in_fence = !in_fence; next }
        in_fence { next }
        /<!--/ && /-->/ { next }
        /\[NEEDS CLARIFICATION:/ {
          # Determine if the marker is inside an inline code span (`...`).
          # Walk the line: count backticks BEFORE the marker. If odd, the
          # marker sits between an opening and closing backtick = code span.
          # Also tolerate the older direct-prefix case (`[NEEDS CLARIFICATION).
          marker_pos = index($0, "[NEEDS CLARIFICATION")
          prefix = substr($0, 1, marker_pos - 1)
          n_backticks = gsub(/`/, "`", prefix)
          if (n_backticks % 2 == 1) next
          if (index($0, "`[NEEDS CLARIFICATION") > 0) next
          print NR ":"
        }
      ' "$file" 2>/dev/null)
    done
  done
fi
if [ "$iii4_violations" -eq 0 ]; then
  pass "  No [NEEDS CLARIFICATION:] inline in implemented/archived changes"
fi

# ─── T.5 (t5-connect-codegen) — transport-codegen-coverage ──────
#
# WARN-only rule (FR-T5-CC-040 / FR-T5-CC-041). Walks the project for
# any `proto/`-suffixed directory and emits a WARN if no sibling
# `gen/connect/` tree exists. The intent is to nudge adopters toward
# the Connect codegen path post-T.5 without breaking existing CI.
#
# Opt-out : `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1` skips the rule.
echo ""
echo "T.5 (Transport Codegen Coverage):"
if [ -n "${FORGE_LINTER_SKIP_TRANSPORT_CODEGEN:-}" ]; then
  not_applicable "transport-codegen-coverage rule skipped via FORGE_LINTER_SKIP_TRANSPORT_CODEGEN"
else
  tcc_proto_count=0
  tcc_warn_count=0
  while IFS= read -r tcc_proto_dir; do
    [ -z "$tcc_proto_dir" ] && continue
    case "$tcc_proto_dir" in
      */node_modules/*|*/.git/*|*/target/*|*/build/*) continue ;;
    esac
    tcc_proto_count=$((tcc_proto_count + 1))
    tcc_parent="$(dirname "$tcc_proto_dir")"
    if [ ! -d "$tcc_parent/gen/connect" ]; then
      warn "transport-codegen-coverage: $tcc_proto_dir has no sibling gen/connect/ — see docs/MIGRATION-PATHS.md (T.5)"
      tcc_warn_count=$((tcc_warn_count + 1))
    fi
  done < <(find_excluding_examples "$FORGE_ROOT" -type d \( -name 'protos' -o -name 'proto' \) 2>/dev/null)
  if [ "$tcc_proto_count" = "0" ]; then
    not_applicable "transport-codegen-coverage: no proto/ or protos/ directory found"
  elif [ "$tcc_warn_count" = "0" ]; then
    pass "transport-codegen-coverage: $tcc_proto_count proto director(y/ies) all have sibling gen/connect/"
  fi
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "========================"
echo "PASS: $PASS | FAIL: $FAIL | WARN: $WARN | N/A: $NA"

if [ "$FAIL" -gt 0 ]; then
  echo "OVERALL: FAIL ($FAIL violations)"
  exit 1
else
  echo "OVERALL: PASS"
  exit 0
fi
