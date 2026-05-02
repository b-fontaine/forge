#!/usr/bin/env bash
# Forge — F.1 Open Questions Tracking Test Harness (f1-open-questions)
# <!-- Audit: F.1 (f1-open-questions) -->
#
# Validates :
#  - Standard global/open-questions.md (sections + Interdictions) (FR-OQ-001)
#  - Index entry (FR-OQ-002)
#  - Template open-questions.md.tmpl (FR-OQ-008)
#  - bin/forge-questions.sh exists, executable, supports filters (FR-OQ-015..017)
#  - verify.sh Open Questions Gate (FR-OQ-009..012) [L2]
#  - constitution-linter.sh NEEDS CLARIFICATION rule (FR-OQ-013..014) [L2]
#  - Skill modified OR fallback documented (FR-OQ-018)
#  - Docs reference (FR-OQ-019)
#  - Backward compatibility (FR-OQ-007 / NFR-OQ-003) [L2]
#  - No backfill of pre-F.1 archived changes (FR-OQ-022)
#  - CI registration (FR-OQ-020)

set -uo pipefail

LEVEL="1"
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  case "$arg" in
    --level=*) LEVEL="${arg#*=}" ;;
  esac
  prev="$arg"
done

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

STD_OQ="$FORGE_ROOT_REAL/.forge/standards/global/open-questions.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
TMPL_OQ="$FORGE_ROOT_REAL/.forge/templates/open-questions.md.tmpl"
QUESTIONS_SH="$FORGE_ROOT_REAL/bin/forge-questions.sh"
VERIFY_SH="$FORGE_ROOT_REAL/.forge/scripts/verify.sh"
LINTER_SH="$FORGE_ROOT_REAL/.forge/scripts/constitution-linter.sh"
CI_WORKFLOW="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"
DOCS_GUIDE="$FORGE_ROOT_REAL/docs/GUIDE.md"
DOCS_OQ="$FORGE_ROOT_REAL/docs/OPEN_QUESTIONS.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# MANIFEST: _test_f1_001 — FR-OQ-001 standard 8 H2 sections + 3 Interdictions
# MANIFEST: _test_f1_002 — FR-OQ-002 index.yml entry
# MANIFEST: _test_f1_003 — FR-OQ-008 template stub
# MANIFEST: _test_f1_004 — FR-OQ-015 forge-questions.sh exists + executable
# MANIFEST: _test_f1_005 — FR-OQ-017 forge-questions.sh --change flag
# MANIFEST: _test_f1_006 — FR-OQ-017 forge-questions.sh --status flag
# MANIFEST: _test_f1_007 — FR-OQ-009 verify.sh Open Questions section
# MANIFEST: _test_f1_008 — FR-OQ-013 constitution-linter NEEDS CLARIFICATION rule
# MANIFEST: _test_f1_009 — FR-OQ-018 skill scaffold OR fallback doc
# MANIFEST: _test_f1_010 — FR-OQ-019 docs reference
# MANIFEST: _test_f1_011 — FR-OQ-020 CI workflow registers f1.test.sh
# MANIFEST: _test_f1_012 — FR-OQ-022 no backfill of pre-F.1 archived
#
# L2 fixture-based
# MANIFEST: _test_f1_l2_001 — verify.sh FAIL on archived + open question
# MANIFEST: _test_f1_l2_002 — verify.sh PASS on archived + answered question
# MANIFEST: _test_f1_l2_003 — verify.sh PASS on archived + no open-questions.md (rétrocompat)
# MANIFEST: _test_f1_l2_004 — constitution-linter FAIL on implemented + NEEDS CLARIFICATION inline
# MANIFEST: _test_f1_l2_005 — forge-questions.sh aggregates + filters

# ─── L1 tests ────────────────────────────────────────────────────

_test_f1_001() {
  [ -f "$STD_OQ" ] || { echo "    expected: $STD_OQ" >&2; return 1; }
  local sections=("Purpose" "File Location and Lifecycle" "Question Schema" \
                  "Status Enum" "Resolution Block" "Verify Gate" \
                  "Linter Rule" "Discovery")
  local missing=()
  for s in "${sections[@]}"; do
    grep -qE "^## ${s}\$" "$STD_OQ" || missing+=("$s")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    missing H2 sections: ${missing[*]}" >&2; return 1
  fi
  local n
  n=$(grep -ciE 'interdiction' "$STD_OQ")
  if [ "$n" -lt 3 ]; then
    echo "    only $n Interdictions (need ≥ 3)" >&2; return 1
  fi
}

_test_f1_002() {
  [ -f "$INDEX_YML" ] || { echo "    index.yml missing" >&2; return 1; }
  grep -qF 'open-questions' "$INDEX_YML" \
    || { echo "    open-questions entry missing in index.yml" >&2; return 1; }
}

_test_f1_003() {
  [ -f "$TMPL_OQ" ] || { echo "    expected: $TMPL_OQ" >&2; return 1; }
  grep -qE '^# Open Questions' "$TMPL_OQ" \
    || { echo "    template missing '# Open Questions' header" >&2; return 1; }
}

_test_f1_004() {
  [ -f "$QUESTIONS_SH" ] || { echo "    expected: $QUESTIONS_SH" >&2; return 1; }
  [ -x "$QUESTIONS_SH" ] || { echo "    forge-questions.sh not executable" >&2; return 1; }
}

_test_f1_005() {
  [ -x "$QUESTIONS_SH" ] || { echo "    forge-questions.sh missing" >&2; return 1; }
  grep -qE -- '--change' "$QUESTIONS_SH" \
    || { echo "    --change flag not implemented" >&2; return 1; }
}

_test_f1_006() {
  [ -x "$QUESTIONS_SH" ] || { echo "    forge-questions.sh missing" >&2; return 1; }
  grep -qE -- '--status' "$QUESTIONS_SH" \
    || { echo "    --status flag not implemented" >&2; return 1; }
}

_test_f1_007() {
  [ -f "$VERIFY_SH" ] || { echo "    verify.sh missing" >&2; return 1; }
  grep -qiE 'Open Questions' "$VERIFY_SH" \
    || { echo "    Open Questions section missing in verify.sh" >&2; return 1; }
}

_test_f1_008() {
  [ -f "$LINTER_SH" ] || { echo "    constitution-linter.sh missing" >&2; return 1; }
  grep -qF 'NEEDS CLARIFICATION' "$LINTER_SH" \
    || { echo "    NEEDS CLARIFICATION rule missing in constitution-linter.sh" >&2; return 1; }
}

_test_f1_009() {
  # Skill scaffold OR fallback doc (FR-OQ-018, ADR-009).
  # Accept either: a skill file mentions open-questions.md, OR the standard
  # documents the manual creation step.
  local skill_match=0
  if find "$FORGE_ROOT_REAL/.claude" -name '*.md' -type f -print0 2>/dev/null \
       | xargs -0 grep -lF 'open-questions.md' 2>/dev/null | head -1 | grep -q .; then
    skill_match=1
  fi
  local doc_match=0
  if [ -f "$STD_OQ" ] && grep -qiE 'manual|fallback|create.*open-questions' "$STD_OQ"; then
    doc_match=1
  fi
  if [ "$skill_match" -eq 0 ] && [ "$doc_match" -eq 0 ]; then
    echo "    neither skill modified nor fallback doc present" >&2; return 1
  fi
}

_test_f1_010() {
  if [ -f "$DOCS_OQ" ]; then
    grep -qiE 'open questions' "$DOCS_OQ" \
      || { echo "    docs/OPEN_QUESTIONS.md does not mention 'Open Questions'" >&2; return 1; }
  elif [ -f "$DOCS_GUIDE" ]; then
    grep -qiE 'open questions' "$DOCS_GUIDE" \
      || { echo "    docs/GUIDE.md missing Open Questions section" >&2; return 1; }
  else
    echo "    neither docs/OPEN_QUESTIONS.md nor docs/GUIDE.md exists" >&2; return 1
  fi
}

_test_f1_011() {
  [ -f "$CI_WORKFLOW" ] || { echo "    forge-ci.yml missing" >&2; return 1; }
  grep -qF 'f1.test.sh' "$CI_WORKFLOW" \
    || { echo "    f1.test.sh not registered in forge-ci.yml" >&2; return 1; }
}

_test_f1_012() {
  # FR-OQ-022 — no backfill of pre-F.1 archived changes.
  local backfilled=()
  for ch in b1-foundations b1-scaffolder b1-workflow b1-delivery g1-forge-ci \
            c1-reference-project a7-forge-upgrade b5-1-init-wizard \
            d5-governance b4-mobile-only; do
    if [ -f "$FORGE_ROOT_REAL/.forge/changes/$ch/open-questions.md" ]; then
      backfilled+=("$ch")
    fi
  done
  if [ "${#backfilled[@]}" -gt 0 ]; then
    echo "    pre-F.1 changes wrongly backfilled: ${backfilled[*]}" >&2; return 1
  fi
}

# ─── L2 fixture-based tests ──────────────────────────────────────

_make_fixture_change() {
  # _make_fixture_change <root> <name> <status> [open|answered]
  local root="$1" name="$2" status="$3" qstatus="${4:-}"
  mkdir -p "$root/.forge/changes/$name"
  cat > "$root/.forge/changes/$name/.forge.yaml" <<EOF
name: $name
status: $status
created: 2026-04-30
schema: default
constitution_version: "1.1.0"
timeline:
  proposed: 2026-04-30
EOF
  if [ -n "$qstatus" ]; then
    cat > "$root/.forge/changes/$name/open-questions.md" <<EOF
# Open Questions — $name

## Q-001: Sample question

- **Status**: $qstatus
- **Raised in**: specs.md
- **Raised on**: 2026-04-30
- **Raised by**: tester

### Question

Test question for fixture.
EOF
  fi
}

_test_f1_l2_001() {
  # archived + open question → verify.sh FAIL.
  [ -x "$VERIFY_SH" ] || { echo "    verify.sh missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f1-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  mkdir -p "$tmp/.forge/scripts"
  cp -r "$FORGE_ROOT_REAL/.forge/scripts/." "$tmp/.forge/scripts/"
  # Minimal scaffold for verify.sh to scan changes (it only reads .forge/changes/).
  _make_fixture_change "$tmp" "test-archived-open" "archived" "open"
  local rc=0
  FORGE_ROOT="$tmp" bash "$tmp/.forge/scripts/verify.sh" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "    verify.sh should FAIL on archived+open, exit was $rc" >&2; return 1
  fi
}

_test_f1_l2_002() {
  # archived + answered question → verify.sh PASS on Open Questions Gate.
  [ -x "$VERIFY_SH" ] || { echo "    verify.sh missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f1-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  cp -r "$FORGE_ROOT_REAL/.forge/scripts" "$tmp/.forge/"
  _make_fixture_change "$tmp" "test-archived-answered" "archived" "answered"
  # Run verify.sh — gate should NOT fail on this change.
  local out
  out=$(FORGE_ROOT="$tmp" bash "$tmp/.forge/scripts/verify.sh" 2>&1 || true)
  if echo "$out" | grep -qE 'test-archived-answered.*open question'; then
    echo "    verify.sh wrongly fails on answered question" >&2; return 1
  fi
}

_test_f1_l2_003() {
  # archived + no open-questions.md → verify.sh PASS (rétrocompat).
  [ -x "$VERIFY_SH" ] || { echo "    verify.sh missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f1-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  cp -r "$FORGE_ROOT_REAL/.forge/scripts" "$tmp/.forge/"
  _make_fixture_change "$tmp" "test-archived-noFile" "archived"
  local out
  out=$(FORGE_ROOT="$tmp" bash "$tmp/.forge/scripts/verify.sh" 2>&1 || true)
  if echo "$out" | grep -qE 'test-archived-noFile.*open question'; then
    echo "    verify.sh wrongly fails on absent open-questions.md" >&2; return 1
  fi
}

_test_f1_l2_004() {
  # implemented + [NEEDS CLARIFICATION:] inline → constitution-linter FAIL.
  [ -x "$LINTER_SH" ] || { echo "    constitution-linter.sh missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f1-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  cp -r "$FORGE_ROOT_REAL/.forge/scripts" "$tmp/.forge/"
  cp -r "$FORGE_ROOT_REAL/.forge/constitution.md" "$tmp/.forge/"
  cp -r "$FORGE_ROOT_REAL/.forge/standards" "$tmp/.forge/"
  _make_fixture_change "$tmp" "test-impl-inline" "implemented"
  cat > "$tmp/.forge/changes/test-impl-inline/specs.md" <<'EOF'
# Specs

[NEEDS CLARIFICATION: which library?]
EOF
  local rc=0
  FORGE_ROOT="$tmp" bash "$tmp/.forge/scripts/constitution-linter.sh" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "    linter should FAIL on implemented+NEEDS CLARIFICATION, exit was $rc" >&2; return 1
  fi
}

_test_f1_l2_005() {
  # forge-questions.sh aggregates + filter --change works.
  [ -x "$QUESTIONS_SH" ] || { echo "    forge-questions.sh missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f1-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_change "$tmp" "alpha" "specified" "open"
  _make_fixture_change "$tmp" "beta" "designed" "open"
  _make_fixture_change "$tmp" "gamma" "implemented" "answered"
  local out
  out=$(FORGE_ROOT="$tmp" bash "$QUESTIONS_SH" 2>&1)
  if ! echo "$out" | grep -q 'alpha:Q-001'; then
    echo "    forge-questions.sh missed alpha" >&2; return 1
  fi
  if ! echo "$out" | grep -q 'beta:Q-001'; then
    echo "    forge-questions.sh missed beta" >&2; return 1
  fi
  if echo "$out" | grep -q 'gamma:Q-001'; then
    echo "    forge-questions.sh wrongly listed gamma (answered)" >&2; return 1
  fi
  # Filter --change
  out=$(FORGE_ROOT="$tmp" bash "$QUESTIONS_SH" --change alpha 2>&1)
  if echo "$out" | grep -q 'beta:Q-001'; then
    echo "    --change filter did not exclude beta" >&2; return 1
  fi
}

# ─── Main ───────────────────────────────────────────────────────

main() {
  echo "Forge — f1-open-questions Test Harness"
  echo "FORGE_ROOT_REAL=$FORGE_ROOT_REAL"
  echo "LEVEL=$LEVEL"
  echo ""
  echo "── L1 hermetic ──"
  run_test _test_f1_001
  run_test _test_f1_002
  run_test _test_f1_003
  run_test _test_f1_004
  run_test _test_f1_005
  run_test _test_f1_006
  run_test _test_f1_007
  run_test _test_f1_008
  run_test _test_f1_009
  run_test _test_f1_010
  run_test _test_f1_011
  run_test _test_f1_012

  case ",$LEVEL," in
    *,2,*)
      echo ""
      echo "── L2 fixture-based ──"
      run_test _test_f1_l2_001
      run_test _test_f1_l2_002
      run_test _test_f1_l2_003
      run_test _test_f1_l2_004
      run_test _test_f1_l2_005
      ;;
  esac

  print_summary
}

main "$@"
