#!/usr/bin/env bash
# Forge — B.8.11 NSMA linter activation test harness (b8-11-nsma-linter)
# <!-- Audit: B.8.11 (b8-11-nsma-linter) -->
#
# Validates the B.8.11 deliverables — a PURE GOVERNANCE/DATA flip activating
# the already-existing no-state-management-alternatives (NSMA / ADR-006) rule
# in constitution-linter.sh by setting state-management.yaml
# enforcement.ci_blocking: false → true. NO new bash is added to the linter.
#
#   - .forge/standards/state-management.yaml v1.1.0 :
#       ci_blocking: true, version "1.1.0", activated_by field (replaces
#       activation_planned), pre_commit_hook stays false, structural-exception
#       pair (expires_at: never + exception_constitutional: true) intact,
#       forbidden list still 8 pkgs + flutter_bloc standard.
#   - .forge/standards/REVIEW.md — KEEP-WITH-CHANGES row for v1.1.0.
#   - .forge/standards/global/linting-rules.md — NSMA section + opt-out row.
#   - CHANGELOG.md — b8-11-nsma-linter anchor (whole-file grep).
#   - .github/workflows/forge-ci.yml — b8-11.test.sh registered.
#   - constitution-linter.sh — NO non-comment additions (data flip only).
#   - Coupling guards: b8-3 (schema) + i3 (I.3 interlock) exit 0.
#   - Live-tree backward-compat: zero scannable forbidden pubspec.yaml.
#
# 16 L1 + 2 L2 = 18 tests. Performance : L1 ≤ 2 s (grep/stat/exit-code only,
# no live-linter invocation at L1 except the fast coupling guards).

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

SM_YAML="$FORGE_ROOT_REAL/.forge/standards/state-management.yaml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
RULES_MD="$FORGE_ROOT_REAL/.forge/standards/global/linting-rules.md"
CHANGELOG="$FORGE_ROOT_REAL/CHANGELOG.md"
FORGE_CI="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"
LINTER_SH="$FORGE_ROOT_REAL/.forge/scripts/constitution-linter.sh"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (15 tests)
# MANIFEST: _test_b811_001_ci_blocking_true          — FR-B811-001
# MANIFEST: _test_b811_002_version_1_1_0             — FR-B811-010
# MANIFEST: _test_b811_003_activation_planned_gone   — FR-B811-002
# MANIFEST: _test_b811_004_activated_by_audit_trail  — FR-B811-002 / 011
# MANIFEST: _test_b811_005_structural_exception_pair — FR-B811-004 / NFR-B811-005
# MANIFEST: _test_b811_006_pre_commit_hook_false     — FR-B811-005
# MANIFEST: _test_b811_007_forbidden_list_intact     — FR-B811-003
# MANIFEST: _test_b811_008_review_md_row             — FR-B811-012
# MANIFEST: _test_b811_009_linting_rules_nsma_section— FR-B811-020 / 022 / 023
# MANIFEST: _test_b811_010_skip_nsma_opt_out_row     — FR-B811-021
# MANIFEST: _test_b811_011_changelog_anchor          — FR-B811-056
# MANIFEST: _test_b811_012_forge_ci_registration     — FR-B811-055
# MANIFEST: _test_b811_013_no_new_bash_in_linter     — FR-B811-043 / NFR-B811-003
# MANIFEST: _test_b811_014_coupling_b8_3             — FR-B811-053 / 013
# MANIFEST: _test_b811_015_coupling_i3               — FR-B811-053 / 042
# MANIFEST: _test_b811_016_live_tree_backward_compat — FR-B811-057 (LOW-3, dedicated id)
#
# L2 (2 tests)
# MANIFEST: _test_b811_l2_forbidden_pubspec          — FR-B811-040 / 054
# MANIFEST: _test_b811_l2_clean_pubspec              — FR-B811-041 / 054

# ─── L1 tests ────────────────────────────────────────────────────

# FR-B811-001 — ci_blocking flipped to true; old false value gone
_test_b811_001_ci_blocking_true() {
  if [ ! -f "$SM_YAML" ]; then
    echo "    state-management.yaml missing: $SM_YAML" >&2; return 1
  fi
  if ! grep -qE '^[[:space:]]+ci_blocking:[[:space:]]+true' "$SM_YAML"; then
    echo "    ci_blocking: true not present in $SM_YAML" >&2; return 1
  fi
  if grep -qE '^[[:space:]]+ci_blocking:[[:space:]]+false' "$SM_YAML"; then
    echo "    old ci_blocking: false still present in $SM_YAML" >&2; return 1
  fi
}

# FR-B811-010 — version bumped to 1.1.0; old 1.0.0 gone
_test_b811_002_version_1_1_0() {
  if ! grep -qF 'version: "1.1.0"' "$SM_YAML"; then
    echo "    version: \"1.1.0\" not present in $SM_YAML" >&2; return 1
  fi
  if grep -qF 'version: "1.0.0"' "$SM_YAML"; then
    echo "    old version: \"1.0.0\" still present in $SM_YAML" >&2; return 1
  fi
}

# FR-B811-002 — activation_planned marker removed
_test_b811_003_activation_planned_gone() {
  if grep -q "activation_planned" "$SM_YAML"; then
    echo "    activation_planned still present in $SM_YAML (must be replaced)" >&2; return 1
  fi
}

# FR-B811-002 / 011 — b8-11 / B.8.11 audit trail present (activated_by + version history)
_test_b811_004_activated_by_audit_trail() {
  if ! grep -qE 'b8-11|B\.8\.11' "$SM_YAML"; then
    echo "    no b8-11 / B.8.11 audit trail in $SM_YAML" >&2; return 1
  fi
}

# FR-B811-004 / NFR-B811-005 — structural-exception pair intact
_test_b811_005_structural_exception_pair() {
  if ! grep -qF "expires_at: never" "$SM_YAML"; then
    echo "    expires_at: never missing in $SM_YAML" >&2; return 1
  fi
  if ! grep -qE "^exception_constitutional:[[:space:]]+true" "$SM_YAML"; then
    echo "    exception_constitutional: true missing in $SM_YAML" >&2; return 1
  fi
}

# FR-B811-005 — pre_commit_hook NOT true (no phantom gate)
_test_b811_006_pre_commit_hook_false() {
  if grep -qF "pre_commit_hook: true" "$SM_YAML"; then
    echo "    pre_commit_hook: true present (no runner ships — must stay false)" >&2; return 1
  fi
}

# FR-B811-003 — forbidden list still 8 pkgs + flutter_bloc standard byte-stable
_test_b811_007_forbidden_list_intact() {
  local pkg
  for pkg in flutter_riverpod riverpod provider get getx mobx flutter_mobx states_rebuilder; do
    if ! grep -qE "^[[:space:]]+-[[:space:]]+${pkg}\$" "$SM_YAML"; then
      echo "    forbidden pkg '${pkg}' missing from $SM_YAML" >&2; return 1
    fi
  done
  if ! grep -qF "standard: flutter_bloc" "$SM_YAML"; then
    echo "    flutter: standard: flutter_bloc missing from $SM_YAML" >&2; return 1
  fi
  if ! grep -qF "linter_rule: no-state-management-alternatives" "$SM_YAML"; then
    echo "    linter_rule: no-state-management-alternatives missing from $SM_YAML" >&2; return 1
  fi
}

# FR-B811-012 — REVIEW.md row: state-management.yaml + 1.1.0 + b8-11-nsma-linter
_test_b811_008_review_md_row() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing: $REVIEW_MD" >&2; return 1
  fi
  if ! grep -qF "state-management.yaml" "$REVIEW_MD"; then
    echo "    state-management.yaml reference missing in REVIEW.md" >&2; return 1
  fi
  if ! grep -qF "b8-11-nsma-linter" "$REVIEW_MD"; then
    echo "    b8-11-nsma-linter reference missing in REVIEW.md" >&2; return 1
  fi
  # The v1.1.0 row must carry both basename and version as adjacent table cells
  # (J.7 FR-J7-023 regex shape : | state-management.yaml | 1.1.0 | ...).
  if ! grep -qE "\|[[:space:]]*state-management\.yaml[[:space:]]*\|[[:space:]]*1\.1\.0[[:space:]]*\|" "$REVIEW_MD"; then
    echo "    KEEP-WITH-CHANGES row | state-management.yaml | 1.1.0 | missing in REVIEW.md" >&2; return 1
  fi
}

# FR-B811-020 / 022 / 023 — linting-rules.md NSMA section + ADR-006 + VI.3
_test_b811_009_linting_rules_nsma_section() {
  if [ ! -f "$RULES_MD" ]; then
    echo "    linting-rules.md missing: $RULES_MD" >&2; return 1
  fi
  if ! grep -qF "no-state-management-alternatives" "$RULES_MD"; then
    echo "    no-state-management-alternatives section missing in linting-rules.md" >&2; return 1
  fi
  if ! grep -qF "ADR-006" "$RULES_MD"; then
    echo "    ADR-006 citation missing in linting-rules.md" >&2; return 1
  fi
  if ! grep -qE "VI\.3|Article VI" "$RULES_MD"; then
    echo "    VI.3 / Article VI citation missing in linting-rules.md" >&2; return 1
  fi
}

# FR-B811-021 — FORGE_LINTER_SKIP_NSMA opt-out row
_test_b811_010_skip_nsma_opt_out_row() {
  if ! grep -qF "FORGE_LINTER_SKIP_NSMA" "$RULES_MD"; then
    echo "    FORGE_LINTER_SKIP_NSMA opt-out row missing in linting-rules.md" >&2; return 1
  fi
}

# FR-B811-056 — CHANGELOG whole-file anchor (NOT [Unreleased]-section-scoped)
_test_b811_011_changelog_anchor() {
  if [ ! -f "$CHANGELOG" ]; then
    echo "    CHANGELOG.md missing: $CHANGELOG" >&2; return 1
  fi
  if ! grep -qF "b8-11-nsma-linter" "$CHANGELOG"; then
    echo "    b8-11-nsma-linter anchor missing in CHANGELOG.md" >&2; return 1
  fi
}

# FR-B811-055 — forge-ci.yml registration
_test_b811_012_forge_ci_registration() {
  if [ ! -f "$FORGE_CI" ]; then
    echo "    forge-ci.yml missing: $FORGE_CI" >&2; return 1
  fi
  if ! grep -qF "b8-11.test.sh" "$FORGE_CI"; then
    echo "    b8-11.test.sh not registered in forge-ci.yml" >&2; return 1
  fi
}

# FR-B811-043 / NFR-B811-003 — NO new (non-comment) bash in constitution-linter.sh
_test_b811_013_no_new_bash_in_linter() {
  local additions
  additions="$(git -C "$FORGE_ROOT_REAL" diff HEAD -- \
    .forge/scripts/constitution-linter.sh \
    | grep '^+' | grep -v '^+++' | grep -v '^+[[:space:]]*#' || true)"
  if [ -n "$additions" ]; then
    echo "    non-comment additions found in constitution-linter.sh (B.8.11 adds no bash):" >&2
    printf '%s\n' "$additions" >&2
    return 1
  fi
}

# FR-B811-053 / 013 — coupling guard: b8-3 schema harness exits 0
_test_b811_014_coupling_b8_3() {
  if [ ! -f "$HARNESS_DIR/b8-3.test.sh" ]; then
    echo "    b8-3.test.sh missing: $HARNESS_DIR/b8-3.test.sh" >&2; return 1
  fi
  if ! bash "$HARNESS_DIR/b8-3.test.sh" --level 1 >/dev/null 2>&1; then
    echo "    b8-3.test.sh --level 1 exited non-zero (schema invariants broken)" >&2; return 1
  fi
}

# FR-B811-053 / 042 — coupling guard: i3 interlock harness exits 0
_test_b811_015_coupling_i3() {
  if [ ! -f "$HARNESS_DIR/i3.test.sh" ]; then
    echo "    i3.test.sh missing: $HARNESS_DIR/i3.test.sh" >&2; return 1
  fi
  if ! bash "$HARNESS_DIR/i3.test.sh" --level 1 >/dev/null 2>&1; then
    echo "    i3.test.sh --level 1 exited non-zero (I.3 interlock broken)" >&2; return 1
  fi
}

# FR-B811-057 (LOW-3 — dedicated id) — live-tree backward-compat:
# zero SCANNABLE pubspec.yaml (excl /.forge/ + /examples/ + /.dart_tool/)
# declares a forbidden state-mgmt pkg, so ci_blocking: true keeps the live
# tree OVERALL PASS. SEPARATE from the no-new-bash guard (T-013).
_test_b811_016_live_tree_backward_compat() {
  local found
  found="$(find "$FORGE_ROOT_REAL" -type f -name pubspec.yaml \
    | grep -v "/.forge/" | grep -v "/examples/" | grep -v "/.dart_tool/" \
    | xargs grep -lE \
      'flutter_riverpod|^[[:space:]]+riverpod:|^[[:space:]]+provider:|^[[:space:]]+get:|^[[:space:]]+getx:|^[[:space:]]+mobx:|^[[:space:]]+flutter_mobx:|^[[:space:]]+states_rebuilder:' \
      2>/dev/null || true)"
  if [ -n "$found" ]; then
    echo "    scannable pubspec.yaml declaring a forbidden state-mgmt dep found (live-tree violation):" >&2
    printf '%s\n' "$found" >&2
    return 1
  fi
}

# ─── L2 fixtures (opt-in, gated on FORGE_LINTER_FIXTURE_ROOT) ─────

# FR-B811-040 / 054 — forbidden pubspec → NSMA section emits FAIL (ci_blocking=true)
_test_b811_l2_forbidden_pubspec() {
  if [ -z "${FORGE_LINTER_FIXTURE_ROOT:-}" ]; then
    echo "    SKIP: FORGE_LINTER_FIXTURE_ROOT not set"; return 0
  fi
  local tmpdir
  tmpdir="$(mk_tmpdir_with_trap forge-b811-l2-forbidden)"
  trap "rm -rf '$tmpdir'" RETURN
  cat > "$tmpdir/pubspec.yaml" <<'PUBSPEC'
name: b811_l2_forbidden
dependencies:
  riverpod: ^2.0.0
PUBSPEC
  local output section_body
  output="$(FORGE_LINTER_FIXTURE_ROOT="$tmpdir" \
            FORGE_LINTER_SKIP_V_1=1 \
            FORGE_LINTER_SKIP_X_3=1 \
            FORGE_LINTER_SKIP_XI_3=1 \
            FORGE_LINTER_SKIP_XI_5=1 \
            FORGE_LINTER_SKIP_T3_FORBIDDEN=1 \
            bash "$LINTER_SH" 2>&1 || true)"
  section_body="$(printf '%s' "$output" | awk '
      /^ADR-006 \(State Management Discipline/ { in_block=1; next }
      in_block && /^[A-Z]/ { in_block=0 }
      in_block { print }
    ')"
  if ! printf '%s' "$section_body" | grep -Eq "forbidden state-mgmt dep '?riverpod'?.*ci_blocking=true"; then
    echo "    expected NSMA FAIL line with riverpod + ci_blocking=true not found" >&2
    echo "    NSMA section body:" >&2
    printf '%s\n' "$section_body" >&2
    return 1
  fi
}

# FR-B811-041 / 054 — clean flutter_bloc-only pubspec → NSMA PASS, no FAIL
_test_b811_l2_clean_pubspec() {
  if [ -z "${FORGE_LINTER_FIXTURE_ROOT:-}" ]; then
    echo "    SKIP: FORGE_LINTER_FIXTURE_ROOT not set"; return 0
  fi
  local tmpdir
  tmpdir="$(mk_tmpdir_with_trap forge-b811-l2-clean)"
  trap "rm -rf '$tmpdir'" RETURN
  cat > "$tmpdir/pubspec.yaml" <<'PUBSPEC'
name: b811_l2_clean
dependencies:
  flutter_bloc: ^9.0.0
PUBSPEC
  local output section_body
  output="$(FORGE_LINTER_FIXTURE_ROOT="$tmpdir" \
            FORGE_LINTER_SKIP_V_1=1 \
            FORGE_LINTER_SKIP_X_3=1 \
            FORGE_LINTER_SKIP_XI_3=1 \
            FORGE_LINTER_SKIP_XI_5=1 \
            FORGE_LINTER_SKIP_T3_FORBIDDEN=1 \
            bash "$LINTER_SH" 2>&1 || true)"
  section_body="$(printf '%s' "$output" | awk '
      /^ADR-006 \(State Management Discipline/ { in_block=1; next }
      in_block && /^[A-Z]/ { in_block=0 }
      in_block { print }
    ')"
  if ! printf '%s' "$section_body" | grep -qF "no forbidden state-mgmt deps detected"; then
    echo "    expected NSMA PASS line 'no forbidden state-mgmt deps detected' not found" >&2
    echo "    NSMA section body:" >&2
    printf '%s\n' "$section_body" >&2
    return 1
  fi
  if printf '%s' "$section_body" | grep -Eq "forbidden state-mgmt dep.*ci_blocking=true"; then
    echo "    clean pubspec unexpectedly emitted a FAIL line" >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── B.8.11 — b8-11-nsma-linter — level $LEVEL ──"

  case "$LEVEL" in
    1)
      run_test _test_b811_001_ci_blocking_true
      run_test _test_b811_002_version_1_1_0
      run_test _test_b811_003_activation_planned_gone
      run_test _test_b811_004_activated_by_audit_trail
      run_test _test_b811_005_structural_exception_pair
      run_test _test_b811_006_pre_commit_hook_false
      run_test _test_b811_007_forbidden_list_intact
      run_test _test_b811_008_review_md_row
      run_test _test_b811_009_linting_rules_nsma_section
      run_test _test_b811_010_skip_nsma_opt_out_row
      run_test _test_b811_011_changelog_anchor
      run_test _test_b811_012_forge_ci_registration
      run_test _test_b811_013_no_new_bash_in_linter
      run_test _test_b811_014_coupling_b8_3
      run_test _test_b811_015_coupling_i3
      run_test _test_b811_016_live_tree_backward_compat
      ;;
    1,2|all)
      run_test _test_b811_001_ci_blocking_true
      run_test _test_b811_002_version_1_1_0
      run_test _test_b811_003_activation_planned_gone
      run_test _test_b811_004_activated_by_audit_trail
      run_test _test_b811_005_structural_exception_pair
      run_test _test_b811_006_pre_commit_hook_false
      run_test _test_b811_007_forbidden_list_intact
      run_test _test_b811_008_review_md_row
      run_test _test_b811_009_linting_rules_nsma_section
      run_test _test_b811_010_skip_nsma_opt_out_row
      run_test _test_b811_011_changelog_anchor
      run_test _test_b811_012_forge_ci_registration
      run_test _test_b811_013_no_new_bash_in_linter
      run_test _test_b811_014_coupling_b8_3
      run_test _test_b811_015_coupling_i3
      run_test _test_b811_016_live_tree_backward_compat
      run_test _test_b811_l2_forbidden_pubspec
      run_test _test_b811_l2_clean_pubspec
      ;;
    *)
      echo "unknown level: $LEVEL" >&2; exit 2
      ;;
  esac

  print_summary
}

main
