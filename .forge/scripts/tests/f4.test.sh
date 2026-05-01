#!/usr/bin/env bash
# Forge — F.4 Linter Extension Test Harness (f4-linter-extension)
# <!-- Audit: F.4 (f4-linter-extension) -->
#
# Validates 4 new constitution-linter.sh rules :
#   - Article V.1   — Task ↔ FR linkage      (FR-LE-001..003)
#   - Article X.3   — Public API doc ratio   (FR-LE-004..009)
#   - Article XI.3  — GenUI schema warning   (FR-LE-010..013)
#   - Article XI.5  — Fallback test pair     (FR-LE-014..017)
# Plus the standard / index entry / doc / CI registration.

set -uo pipefail

LEVEL="1"
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  case "$arg" in --level=*) LEVEL="${arg#*=}" ;; esac
  prev="$arg"
done

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

LINTER="$FORGE_ROOT_REAL/.forge/scripts/constitution-linter.sh"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
STD_LE="$FORGE_ROOT_REAL/.forge/standards/global/linting-rules.md"
CI_WORKFLOW="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"
DOCS_LINT="$FORGE_ROOT_REAL/docs/LINTING.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# MANIFEST: _test_f4_001 — FR-LE-001 V section in linter
# MANIFEST: _test_f4_002 — FR-LE-003 V skip env var documented
# MANIFEST: _test_f4_003 — FR-LE-004 X.3 section in linter
# MANIFEST: _test_f4_004 — FR-LE-005 X.3 Dart symbols heuristic mentioned
# MANIFEST: _test_f4_005 — FR-LE-006 X.3 Rust symbols heuristic mentioned
# MANIFEST: _test_f4_006 — FR-LE-007 X.3 ratio threshold default 80
# MANIFEST: _test_f4_007 — FR-LE-009 X.3 threshold env var documented
# MANIFEST: _test_f4_008 — FR-LE-010 XI.3 section in linter
# MANIFEST: _test_f4_009 — FR-LE-011 XI.3 AI imports detection mentioned
# MANIFEST: _test_f4_010 — FR-LE-014 XI.5 section in linter
# MANIFEST: _test_f4_011 — FR-LE-015 XI.5 fallback name pattern mentioned
# MANIFEST: _test_f4_012 — FR-LE-018 standard linting-rules.md exists with 6 H2
# MANIFEST: _test_f4_013 — FR-LE-019 index.yml entry
# MANIFEST: _test_f4_014 — FR-LE-020 docs/LINTING.md exists
# MANIFEST: _test_f4_015 — FR-LE-020 docs lists all 4 env vars
# MANIFEST: _test_f4_016 — FR-LE-021 CI workflow registers f4.test.sh
#
# L2 fixture-based
# MANIFEST: _test_f4_l2_v1_fail   — FR-LE-002 tasks.md without FR-link → FAIL
# MANIFEST: _test_f4_l2_v1_pass   — FR-LE-002 tasks.md with FR-link → PASS
# MANIFEST: _test_f4_l2_x3_fail   — FR-LE-007 ratio < 80 → FAIL
# MANIFEST: _test_f4_l2_x3_envthr — FR-LE-009 threshold env var override
# MANIFEST: _test_f4_l2_xi3_warn  — FR-LE-012 AI + Widget no schema → WARN (not FAIL)
# MANIFEST: _test_f4_l2_xi5_fail  — FR-LE-016 fallback no test pair → FAIL
# MANIFEST: _test_f4_l2_optout    — FR-LE-003 SKIP_X_3 env var skips rule

# ─── L1 tests ────────────────────────────────────────────────────

_test_f4_001() {
  [ -f "$LINTER" ] || { echo "    linter missing" >&2; return 1; }
  grep -qE 'Article V \(Constitutional Compliance Gate' "$LINTER" \
    || { echo "    Article V section header missing in linter" >&2; return 1; }
}

_test_f4_002() {
  grep -qF 'FORGE_LINTER_SKIP_V_1' "$LINTER" \
    || { echo "    FORGE_LINTER_SKIP_V_1 env var not handled" >&2; return 1; }
}

_test_f4_003() {
  grep -qE 'Article X\.3 \(Public API Documentation' "$LINTER" \
    || { echo "    Article X.3 section header missing" >&2; return 1; }
}

_test_f4_004() {
  grep -qiE 'lib/.*\.dart' "$LINTER" \
    || { echo "    Dart source path not referenced in linter" >&2; return 1; }
}

_test_f4_005() {
  # The Rust heuristic uses `pub\s+(fn|struct|enum|trait|...)\b` regex
  # embedded as a Python r-string. Confirm the linter has Rust pub-symbol
  # detection by checking for the regex's distinctive content.
  grep -qE 'pub.*fn.*struct.*enum.*trait' "$LINTER" \
    || grep -qE 'rust_pat.*pub' "$LINTER" \
    || { echo "    Rust pub-symbol heuristic missing" >&2; return 1; }
}

_test_f4_006() {
  grep -qE 'X3_THRESHOLD.*80|80.*X3_THRESHOLD' "$LINTER" \
    || { echo "    X.3 default threshold 80 not detected" >&2; return 1; }
}

_test_f4_007() {
  grep -qF 'FORGE_LINTER_SKIP_X_3' "$LINTER" \
    || { echo "    FORGE_LINTER_SKIP_X_3 env var not handled" >&2; return 1; }
  grep -qF 'FORGE_LINTER_X3_THRESHOLD' "$LINTER" \
    || { echo "    FORGE_LINTER_X3_THRESHOLD env var not handled" >&2; return 1; }
}

_test_f4_008() {
  grep -qE 'Article XI\.3 \(Generative UI' "$LINTER" \
    || { echo "    Article XI.3 section header missing" >&2; return 1; }
}

_test_f4_009() {
  # AI imports detection heuristic mentions at least 2 of the patterns.
  local count=0
  for pat in anthropic openai 'gpt-' claude llm langchain; do
    grep -qF "$pat" "$LINTER" && count=$((count+1))
  done
  if [ "$count" -lt 2 ]; then
    echo "    fewer than 2 AI patterns mentioned ($count)" >&2; return 1
  fi
}

_test_f4_010() {
  grep -qE 'Article XI\.5 \(Mandatory Fallback' "$LINTER" \
    || { echo "    Article XI.5 section header missing" >&2; return 1; }
}

_test_f4_011() {
  grep -qiE 'fallback' "$LINTER" \
    || { echo "    fallback heuristic missing" >&2; return 1; }
  grep -qF 'FORGE_LINTER_SKIP_XI_5' "$LINTER" \
    || { echo "    FORGE_LINTER_SKIP_XI_5 env var not handled" >&2; return 1; }
}

_test_f4_012() {
  [ -f "$STD_LE" ] || { echo "    expected: $STD_LE" >&2; return 1; }
  local sections=("Purpose" "Article V.1" "Article X.3" "Article XI.3" \
                  "Article XI.5" "Opt-Out Mechanism")
  local missing=()
  for s in "${sections[@]}"; do
    grep -qE "^## ${s}" "$STD_LE" || missing+=("$s")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    missing H2 sections: ${missing[*]}" >&2; return 1
  fi
}

_test_f4_013() {
  [ -f "$INDEX_YML" ] || { echo "    index.yml missing" >&2; return 1; }
  grep -qF 'linting-rules' "$INDEX_YML" \
    || { echo "    linting-rules entry missing in index.yml" >&2; return 1; }
}

_test_f4_014() {
  [ -f "$DOCS_LINT" ] || { echo "    expected: $DOCS_LINT" >&2; return 1; }
  local n
  n=$(wc -l < "$DOCS_LINT" | tr -d ' ')
  if [ "$n" -lt 30 ]; then
    echo "    docs/LINTING.md too short: $n lines (need ≥ 30)" >&2; return 1
  fi
}

_test_f4_015() {
  [ -f "$DOCS_LINT" ] || { echo "    docs missing" >&2; return 1; }
  for v in FORGE_LINTER_SKIP_V_1 FORGE_LINTER_SKIP_X_3 FORGE_LINTER_SKIP_XI_3 FORGE_LINTER_SKIP_XI_5; do
    grep -qF "$v" "$DOCS_LINT" || { echo "    docs/LINTING.md missing env var: $v" >&2; return 1; }
  done
}

_test_f4_016() {
  [ -f "$CI_WORKFLOW" ] || { echo "    forge-ci.yml missing" >&2; return 1; }
  grep -qF 'f4.test.sh' "$CI_WORKFLOW" \
    || { echo "    f4.test.sh not registered in forge-ci.yml" >&2; return 1; }
}

# ─── L2 fixture-based tests ──────────────────────────────────────

_make_fixture_tree() {
  # _make_fixture_tree <root>
  # Builds a minimal .forge/ tree so the linter can run.
  local root="$1"
  mkdir -p "$root/.forge/scripts" "$root/.forge/changes" "$root/.forge/standards" "$root/.forge/specs"
  cp -r "$FORGE_ROOT_REAL/.forge/scripts/." "$root/.forge/scripts/" 2>/dev/null
  cp -r "$FORGE_ROOT_REAL/.forge/standards/." "$root/.forge/standards/" 2>/dev/null
  cp "$FORGE_ROOT_REAL/.forge/constitution.md" "$root/.forge/" 2>/dev/null
  cp "$FORGE_ROOT_REAL/.forge/schemas/change.schema.json" "$root/.forge/schemas/" 2>/dev/null || mkdir -p "$root/.forge/schemas"
}

_make_change_yaml() {
  # _make_change_yaml <root> <name> <status>
  local root="$1" name="$2" status="$3"
  mkdir -p "$root/.forge/changes/$name"
  cat > "$root/.forge/changes/$name/.forge.yaml" <<EOF
name: $name
status: $status
created: 2026-05-01
schema: default
constitution_version: "1.1.0"
timeline:
  proposed: 2026-05-01
EOF
}

_test_f4_l2_v1_fail() {
  [ -x "$LINTER" ] || { echo "    linter missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_tree "$tmp"
  _make_change_yaml "$tmp" "test-no-fr" "planned"
  cat > "$tmp/.forge/changes/test-no-fr/tasks.md" <<'EOF'
# Tasks

- [ ] Task A: do stuff
- [ ] Task B: more stuff
EOF
  local out rc=0
  out=$(FORGE_ROOT="$tmp" bash "$tmp/.forge/scripts/constitution-linter.sh" 2>&1) || rc=$?
  # FAIL line uses 'missing' keyword, PASS line uses 'has' keyword.
  if ! echo "$out" | grep -qE 'test-no-fr.*missing.*audit trail'; then
    echo "    expected V.1 fail message about test-no-fr ; got:" >&2
    echo "$out" | tail -10 >&2
    return 1
  fi
}

_test_f4_l2_v1_pass() {
  [ -x "$LINTER" ] || { echo "    linter missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_tree "$tmp"
  _make_change_yaml "$tmp" "test-with-fr" "planned"
  cat > "$tmp/.forge/changes/test-with-fr/tasks.md" <<'EOF'
# Tasks

- [ ] Task A: do stuff [Story: FR-001]
EOF
  local out
  out=$(FORGE_ROOT="$tmp" bash "$tmp/.forge/scripts/constitution-linter.sh" 2>&1)
  # FAIL message contains "missing"; PASS message contains "has".
  if echo "$out" | grep -qE 'test-with-fr.*missing.*audit trail'; then
    echo "    V.1 wrongly fails on change with [Story: FR-001]" >&2; return 1
  fi
}

_test_f4_l2_x3_fail() {
  [ -x "$LINTER" ] || { echo "    linter missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_tree "$tmp"
  mkdir -p "$tmp/lib"
  cat > "$tmp/lib/foo.dart" <<'EOF'
class Foo {
  void method() {}
}
class Bar {
  void thing() {}
}
class Baz {
  void other() {}
}
class Qux {
  void final_one() {}
}
class Quux {
  void final_two() {}
}
EOF
  # 5 classes, 0 documented = 0% < 80% → FAIL
  cat > "$tmp/pubspec.yaml" <<'EOF'
name: testapp
EOF
  local out rc=0
  out=$(FORGE_ROOT="$tmp" bash "$tmp/.forge/scripts/constitution-linter.sh" 2>&1) || rc=$?
  if ! echo "$out" | grep -qE 'X\.3.*ratio|below threshold'; then
    echo "    expected X.3 ratio fail message ; got:" >&2
    echo "$out" | tail -15 >&2
    return 1
  fi
}

_test_f4_l2_x3_envthr() {
  [ -x "$LINTER" ] || { echo "    linter missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_tree "$tmp"
  mkdir -p "$tmp/lib"
  # 1 class, 0 documented = 0% ; threshold 0 → PASS
  cat > "$tmp/lib/foo.dart" <<'EOF'
class Foo {
  void method() {}
}
EOF
  cat > "$tmp/pubspec.yaml" <<'EOF'
name: testapp
EOF
  local out
  out=$(FORGE_ROOT="$tmp" FORGE_LINTER_X3_THRESHOLD=0 bash "$tmp/.forge/scripts/constitution-linter.sh" 2>&1)
  if echo "$out" | grep -qE 'X\.3.*FAIL.*ratio'; then
    echo "    X.3 wrongly fails when threshold env var = 0" >&2; return 1
  fi
}

_test_f4_l2_xi3_warn() {
  [ -x "$LINTER" ] || { echo "    linter missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_tree "$tmp"
  mkdir -p "$tmp/lib"
  cat > "$tmp/lib/main.dart" <<'EOF'
import 'package:anthropic/anthropic.dart';
import 'package:flutter/widgets.dart';

class MyWidget extends Widget {
  void render() {}
}
EOF
  cat > "$tmp/pubspec.yaml" <<'EOF'
name: testapp
dependencies:
  anthropic: ^1.0.0
EOF
  local out
  out=$(FORGE_ROOT="$tmp" bash "$tmp/.forge/scripts/constitution-linter.sh" 2>&1)
  # XI.3 should emit a WARN, not a FAIL.
  if ! echo "$out" | grep -qiE 'XI\.3.*warn|warning'; then
    echo "    expected XI.3 warning ; got:" >&2
    echo "$out" | tail -15 >&2
    return 1
  fi
}

_test_f4_l2_xi5_fail() {
  [ -x "$LINTER" ] || { echo "    linter missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_tree "$tmp"
  mkdir -p "$tmp/lib"
  cat > "$tmp/lib/translation_fallback.dart" <<'EOF'
class TranslationFallback {
  String translate(String key) => key;
}
EOF
  cat > "$tmp/pubspec.yaml" <<'EOF'
name: testapp
EOF
  local out rc=0
  out=$(FORGE_ROOT="$tmp" bash "$tmp/.forge/scripts/constitution-linter.sh" 2>&1) || rc=$?
  if ! echo "$out" | grep -qE 'XI\.5.*fallback.*test|no matching.*fallback'; then
    echo "    expected XI.5 fail on missing fallback test pair ; got:" >&2
    echo "$out" | tail -15 >&2
    return 1
  fi
}

_test_f4_l2_optout() {
  [ -x "$LINTER" ] || { echo "    linter missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_tree "$tmp"
  mkdir -p "$tmp/lib"
  # Same fixture as x3_fail (5 classes, 0% doc).
  cat > "$tmp/lib/foo.dart" <<'EOF'
class Foo {
  void method() {}
}
class Bar {
  void thing() {}
}
EOF
  cat > "$tmp/pubspec.yaml" <<'EOF'
name: testapp
EOF
  local out
  out=$(FORGE_ROOT="$tmp" FORGE_LINTER_SKIP_X_3=1 bash "$tmp/.forge/scripts/constitution-linter.sh" 2>&1)
  # X.3 should be skipped, no FAIL emitted.
  if echo "$out" | grep -qE 'X\.3.*ratio.*FAIL|below threshold'; then
    echo "    X.3 ratio FAIL emitted despite SKIP env var" >&2; return 1
  fi
  echo "$out" | grep -qiF 'skipped via FORGE_LINTER_SKIP_X_3' \
    || { echo "    expected 'skipped via FORGE_LINTER_SKIP_X_3' message" >&2; return 1; }
}

# ─── Main ───────────────────────────────────────────────────────

main() {
  echo "Forge — f4-linter-extension Test Harness"
  echo "FORGE_ROOT_REAL=$FORGE_ROOT_REAL"
  echo "LEVEL=$LEVEL"
  echo ""
  echo "── L1 hermetic ──"
  for n in 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016; do
    run_test "_test_f4_$n"
  done

  case ",$LEVEL," in
    *,2,*)
      echo ""
      echo "── L2 fixture-based ──"
      run_test _test_f4_l2_v1_fail
      run_test _test_f4_l2_v1_pass
      run_test _test_f4_l2_x3_fail
      run_test _test_f4_l2_x3_envthr
      run_test _test_f4_l2_xi3_warn
      run_test _test_f4_l2_xi5_fail
      run_test _test_f4_l2_optout
      ;;
  esac

  print_summary
}

main "$@"
