#!/usr/bin/env bash
# Forge — I.3 T3-Forbidden Linter Test Harness (i3-t3-forbidden-linter)
# <!-- Audit: I.3 (i3-t3-forbidden-linter) -->
#
# Validates the I.3 deliverables :
#
#   - .forge/scripts/constitution-linter.sh ADR-I3-001 section
#     (T3-Forbidden Components — generic forbidden discovery).
#   - .forge/standards/global/forbidden-components-rules.md v1.0.0
#     (≥ 6 H2 sections, T3-RULE-001..007 catalogue, severity matrix).
#   - .forge/standards/index.yml entry (id global/forbidden-components-rules).
#   - .forge/standards/REVIEW.md append-only birth entry 2026-05-12.
#   - .forge/standards/global/compliance-tiers.md frontmatter flip
#     (enforcement: review → ci) + Status note delta.
#   - docs/LINTING.md ADR-I3-001 H2 section.
#
# 14 L1 + 4 L2 = 18 tests. Performance : L1 ≤ 3 s, L1+L2 ≤ 15 s.

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

LINTER_SH="$FORGE_ROOT_REAL/.forge/scripts/constitution-linter.sh"
STD_FILE="$FORGE_ROOT_REAL/.forge/standards/global/forbidden-components-rules.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
COMPLIANCE_STD="$FORGE_ROOT_REAL/.forge/standards/global/compliance-tiers.md"
LINTING_DOC="$FORGE_ROOT_REAL/docs/LINTING.md"
IDENTITY_STD="$FORGE_ROOT_REAL/.forge/standards/identity.yaml"
ORCH_STD="$FORGE_ROOT_REAL/.forge/standards/orchestration.yaml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (14 tests)
# MANIFEST: _test_i3_001_linter_section_anchor    — FR-I3-T3F-001
# MANIFEST: _test_i3_002_linter_section_echo      — FR-I3-T3F-001
# MANIFEST: _test_i3_003_opt_out_env_var          — FR-I3-T3F-002 / NFR-I3-T3F-004
# MANIFEST: _test_i3_004_tier_discovery_ledger    — FR-I3-T3F-003
# MANIFEST: _test_i3_005_tier_discovery_na        — FR-I3-T3F-003 / 126
# MANIFEST: _test_i3_006_standards_discovery      — FR-I3-T3F-004
# MANIFEST: _test_i3_007_violation_format         — FR-I3-T3F-007 / 120
# MANIFEST: _test_i3_008_standard_exists          — FR-I3-T3F-040 / 041
# MANIFEST: _test_i3_009_standard_h2_sections     — FR-I3-T3F-042
# MANIFEST: _test_i3_010_rule_catalogue_anchors   — FR-I3-T3F-043 / 120..126
# MANIFEST: _test_i3_011_index_entry              — FR-I3-T3F-044
# MANIFEST: _test_i3_012_review_entry             — FR-I3-T3F-045
# MANIFEST: _test_i3_013_compliance_tiers_flip    — FR-I3-T3F-046
# MANIFEST: _test_i3_014_linting_md_section       — FR-I3-T3F-080
#
# L2 (4 tests)
# MANIFEST: _test_i3_l2_t3_pubspec                — FR-I3-T3F-062 / 120 / scenario 1
# MANIFEST: _test_i3_l2_t3_cargo                  — FR-I3-T3F-062 / 122 / scenario 1
# MANIFEST: _test_i3_l2_t1_warn_only              — FR-I3-T3F-062 / 006 / scenario 2
# MANIFEST: _test_i3_l2_no_tier_na                — FR-I3-T3F-062 / 126 / scenario 3

# ─── L1 tests ────────────────────────────────────────────────────

# FR-I3-T3F-001 — section anchor comment
_test_i3_001_linter_section_anchor() {
  if [ ! -f "$LINTER_SH" ]; then
    echo "    constitution-linter.sh missing: $LINTER_SH" >&2; return 1
  fi
  if ! grep -Fq "ADR-I3-001: T3-Forbidden Components" "$LINTER_SH"; then
    echo "    ADR-I3-001 section anchor missing in $LINTER_SH" >&2; return 1
  fi
}

# FR-I3-T3F-001 — section echo line
_test_i3_002_linter_section_echo() {
  if [ ! -f "$LINTER_SH" ]; then
    echo "    constitution-linter.sh missing: $LINTER_SH" >&2; return 1
  fi
  if ! grep -Fq "T3-Forbidden Components (I.3" "$LINTER_SH"; then
    echo "    T3-Forbidden Components echo line missing in $LINTER_SH" >&2; return 1
  fi
}

# FR-I3-T3F-002 — opt-out env var honoured
_test_i3_003_opt_out_env_var() {
  if [ ! -f "$LINTER_SH" ]; then
    echo "    constitution-linter.sh missing: $LINTER_SH" >&2; return 1
  fi
  if ! grep -Fq "FORGE_LINTER_SKIP_T3_FORBIDDEN" "$LINTER_SH"; then
    echo "    FORGE_LINTER_SKIP_T3_FORBIDDEN keyword missing in $LINTER_SH" >&2; return 1
  fi
  # Black-box : invoke linter with opt-out ; expect "skipped via" line in
  # the T3-Forbidden block.
  local output
  output="$(FORGE_LINTER_SKIP_T3_FORBIDDEN=1 \
             bash "$LINTER_SH" 2>&1 || true)"
  if ! printf '%s' "$output" | grep -Fq "skipped via FORGE_LINTER_SKIP_T3_FORBIDDEN"; then
    echo "    opt-out branch did not emit 'skipped via FORGE_LINTER_SKIP_T3_FORBIDDEN'" >&2
    return 1
  fi
}

# FR-I3-T3F-003 — tier discovery via .forge/.forge-tier ledger
_test_i3_004_tier_discovery_ledger() {
  if ! grep -Fq ".forge/.forge-tier" "$LINTER_SH"; then
    echo "    .forge/.forge-tier reference missing in $LINTER_SH" >&2; return 1
  fi
}

# FR-I3-T3F-003 / 126 — N/A when no tier declared
_test_i3_005_tier_discovery_na() {
  # On the Forge framework repo, no .forge/.forge-tier is set and
  # FORGE_EU_TIER is unset, so the T3-Forbidden section MUST emit N/A.
  if [ ! -f "$LINTER_SH" ]; then
    echo "    constitution-linter.sh missing: $LINTER_SH" >&2; return 1
  fi
  local output
  output="$(unset FORGE_EU_TIER; bash "$LINTER_SH" 2>&1 || true)"
  # Expect N/A line under the T3-Forbidden Components header
  if ! printf '%s' "$output" | grep -Fq "no compliance tier declared"; then
    echo "    'no compliance tier declared' N/A line missing" >&2
    echo "    output preview:" >&2
    printf '%s' "$output" | grep -A 1 "T3-Forbidden" >&2 || true
    return 1
  fi
}

# FR-I3-T3F-004 — standards discovery (Python walk anchor)
_test_i3_006_standards_discovery() {
  if ! grep -Fq ".forge/standards" "$LINTER_SH"; then
    echo "    .forge/standards walk missing in $LINTER_SH" >&2; return 1
  fi
  if ! grep -Eq "(forbidden:|FORBIDDEN_BLOCK|discover.*forbidden)" "$LINTER_SH"; then
    echo "    forbidden: discovery logic missing in $LINTER_SH" >&2; return 1
  fi
}

# FR-I3-T3F-007 / 120 — [REFUSAL: T3-RULE-NNN: ...] format anchor
_test_i3_007_violation_format() {
  if ! grep -Fq "T3-RULE-" "$LINTER_SH"; then
    echo "    T3-RULE- format anchor missing in $LINTER_SH" >&2; return 1
  fi
  if ! grep -Fq "REFUSAL:" "$LINTER_SH"; then
    echo "    REFUSAL: emission anchor missing in $LINTER_SH" >&2; return 1
  fi
}

# FR-I3-T3F-040 / 041 — standard file exists + frontmatter
_test_i3_008_standard_exists() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -Fq "linter_rule: t3-forbidden-components" "$STD_FILE"; then
    echo "    'linter_rule: t3-forbidden-components' frontmatter missing" >&2; return 1
  fi
  if ! grep -Fq "enforcement: ci" "$STD_FILE"; then
    echo "    'enforcement: ci' frontmatter missing" >&2; return 1
  fi
  if ! grep -Fq "version: 1.0.0" "$STD_FILE"; then
    echo "    'version: 1.0.0' frontmatter missing" >&2; return 1
  fi
}

# FR-I3-T3F-042 — ≥ 6 H2 sections
_test_i3_009_standard_h2_sections() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  local count
  count="$(grep -c "^## " "$STD_FILE")"
  if [ "$count" -lt 6 ]; then
    echo "    H2 section count $count < 6 minimum" >&2; return 1
  fi
}

# FR-I3-T3F-043 / 120..126 — rule catalogue T3-RULE-001..007 anchors
_test_i3_010_rule_catalogue_anchors() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  local rid
  for rid in T3-RULE-001 T3-RULE-002 T3-RULE-003 T3-RULE-004 \
             T3-RULE-005 T3-RULE-006 T3-RULE-007; do
    if ! grep -Fq "$rid" "$STD_FILE"; then
      echo "    rule anchor missing: $rid" >&2; return 1
    fi
  done
}

# FR-I3-T3F-044 — standards/index.yml entry
_test_i3_011_index_entry() {
  if [ ! -f "$INDEX_YML" ]; then
    echo "    index.yml missing: $INDEX_YML" >&2; return 1
  fi
  if ! grep -Fq "id: global/forbidden-components-rules" "$INDEX_YML"; then
    echo "    'id: global/forbidden-components-rules' entry missing in index.yml" >&2; return 1
  fi
  if ! grep -Fq "path: standards/global/forbidden-components-rules.md" "$INDEX_YML"; then
    echo "    'path: standards/global/forbidden-components-rules.md' missing" >&2; return 1
  fi
  if ! grep -Fq "t3-forbidden" "$INDEX_YML"; then
    echo "    't3-forbidden' trigger missing in index.yml" >&2; return 1
  fi
}

# FR-I3-T3F-045 — REVIEW.md birth entry
_test_i3_012_review_entry() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing: $REVIEW_MD" >&2; return 1
  fi
  if ! grep -Fq "Initial ratification (i3-t3-forbidden-linter)" "$REVIEW_MD"; then
    echo "    'Initial ratification (i3-t3-forbidden-linter)' entry missing in REVIEW.md" >&2; return 1
  fi
  if ! grep -Fq "forbidden-components-rules.md" "$REVIEW_MD"; then
    echo "    'forbidden-components-rules.md' reference missing in REVIEW.md" >&2; return 1
  fi
}

# FR-I3-T3F-046 — compliance-tiers.md frontmatter flip
_test_i3_013_compliance_tiers_flip() {
  if [ ! -f "$COMPLIANCE_STD" ]; then
    echo "    compliance-tiers.md missing: $COMPLIANCE_STD" >&2; return 1
  fi
  if ! grep -Fq "enforcement: ci" "$COMPLIANCE_STD"; then
    echo "    'enforcement: ci' missing in compliance-tiers.md (flip not applied)" >&2; return 1
  fi
  if ! grep -Fq "i3-t3-forbidden-linter" "$COMPLIANCE_STD"; then
    echo "    'i3-t3-forbidden-linter' delta marker missing in compliance-tiers.md Status note" >&2; return 1
  fi
}

# FR-I3-T3F-080 — docs/LINTING.md H2 section
_test_i3_014_linting_md_section() {
  if [ ! -f "$LINTING_DOC" ]; then
    echo "    docs/LINTING.md missing: $LINTING_DOC" >&2; return 1
  fi
  if ! grep -Fq "ADR-I3-001 — T3-Forbidden Components" "$LINTING_DOC"; then
    echo "    'ADR-I3-001 — T3-Forbidden Components' H2 missing in docs/LINTING.md" >&2; return 1
  fi
  if ! grep -Fq "FORGE_LINTER_SKIP_T3_FORBIDDEN" "$LINTING_DOC"; then
    echo "    FORGE_LINTER_SKIP_T3_FORBIDDEN env var missing in docs/LINTING.md" >&2; return 1
  fi
}

# ─── L2 fixtures ─────────────────────────────────────────────────

# Synthetic fixture builder : create a tmpdir with a copy of the
# linter + the relevant standards, plus the manifest under test.
# The fixture overrides FORGE_ROOT so the linter walks the synthetic
# tree instead of the framework repo.

_mk_fixture_tree() {
  # _mk_fixture_tree <tier> <manifest_path> <manifest_content>
  local tier="$1"
  local manifest_path="$2"
  local manifest_content="$3"
  local tmpdir
  tmpdir="$(mk_tmpdir_with_trap forge-i3-fixture)"
  mkdir -p "$tmpdir/.forge/standards/global"
  mkdir -p "$tmpdir/.forge/scripts"
  # Tier ledger.
  if [ -n "$tier" ]; then
    printf '%s\n' "$tier" > "$tmpdir/.forge/.forge-tier"
  fi
  # Copy the live identity.yaml + orchestration.yaml + the new
  # standard so the linter can discover forbidden: blocks.
  cp "$IDENTITY_STD" "$tmpdir/.forge/standards/identity.yaml"
  cp "$ORCH_STD" "$tmpdir/.forge/standards/orchestration.yaml"
  # We do NOT need the linter script copy ; we invoke the live one
  # with FORGE_ROOT pointing at the tmpdir.
  # Manifest.
  if [ -n "$manifest_path" ]; then
    mkdir -p "$tmpdir/$(dirname "$manifest_path")"
    printf '%s\n' "$manifest_content" > "$tmpdir/$manifest_path"
  fi
  echo "$tmpdir"
}

_run_linter_in_fixture() {
  # _run_linter_in_fixture <tmpdir>
  local tmpdir="$1"
  # Skip every other linter section to isolate the T3-Forbidden one.
  FORGE_ROOT="$tmpdir" \
  FORGE_LINTER_SKIP_V_1=1 \
  FORGE_LINTER_SKIP_X_3=1 \
  FORGE_LINTER_SKIP_XI_3=1 \
  FORGE_LINTER_SKIP_XI_5=1 \
  FORGE_LINTER_SKIP_NSMA=1 \
  FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1 \
  bash "$LINTER_SH" 2>&1
}

# FR-I3-T3F-062 — scenario 1 : T3 + firebase_auth in pubspec → FAIL
# Section-scoped : asserts the T3-Forbidden section emits FAIL with the
# T3-RULE-001 refusal line. The overall linter exit-code is not asserted
# (the synthetic fixture's unrelated Article-VI/IX checks are out of
# scope for this L2 test).
_test_i3_l2_t3_pubspec() {
  local tmpdir
  tmpdir="$(_mk_fixture_tree T3 "pubspec.yaml" \
    "name: forge_l2
dependencies:
  firebase_auth: ^1.0.0")"
  trap "rm -rf '$tmpdir'" RETURN
  local output section_body
  output="$(_run_linter_in_fixture "$tmpdir")"
  section_body="$(printf '%s' "$output" | awk '
      /^T3-Forbidden Components/ { in_block=1; next }
      in_block && /^[A-Z]/ { in_block=0 }
      in_block { print }
    ')"
  if ! printf '%s' "$section_body" | grep -Eq "FAIL.*T3-RULE-001.*firebase-auth.*forbidden at T3"; then
    echo "    expected T3-RULE-001 FAIL refusal line missing in section body" >&2
    echo "    section body:" >&2
    printf '%s\n' "$section_body" >&2
    return 1
  fi
}

# FR-I3-T3F-062 — scenario 1 bis : T3 + inngest in Cargo.toml → FAIL
_test_i3_l2_t3_cargo() {
  local tmpdir
  tmpdir="$(_mk_fixture_tree T3 "Cargo.toml" \
    "[package]
name = \"forge-l2\"
[dependencies]
inngest = \"0.1\"
")"
  trap "rm -rf '$tmpdir'" RETURN
  local output section_body
  output="$(_run_linter_in_fixture "$tmpdir")"
  section_body="$(printf '%s' "$output" | awk '
      /^T3-Forbidden Components/ { in_block=1; next }
      in_block && /^[A-Z]/ { in_block=0 }
      in_block { print }
    ')"
  if ! printf '%s' "$section_body" | grep -Eq "FAIL.*T3-RULE-003.*inngest.*forbidden at T3"; then
    echo "    expected T3-RULE-003 FAIL refusal line missing in section body" >&2
    echo "    section body:" >&2
    printf '%s\n' "$section_body" >&2
    return 1
  fi
}

# FR-I3-T3F-062 — scenario 2 : T1 + firebase_auth → WARN only
# We assert the T3-Forbidden section emits WARN (and ONLY WARN) for the
# T1 case — the linter's overall exit code is not asserted here because
# the synthetic pubspec.yaml legitimately lacks unrelated Article-VI/IX
# Flutter deps that other sections check independently. Scoped assertion :
# the T3-Forbidden section MUST NOT emit a FAIL/REFUSAL line.
_test_i3_l2_t1_warn_only() {
  local tmpdir
  tmpdir="$(_mk_fixture_tree T1 "pubspec.yaml" \
    "name: forge_l2
dependencies:
  firebase_auth: ^1.0.0")"
  trap "rm -rf '$tmpdir'" RETURN
  local output
  output="$(_run_linter_in_fixture "$tmpdir")"
  # Expect WARN line in T3-Forbidden section.
  if ! printf '%s' "$output" | grep -Eq "WARN.*T3-RULE-001.*forbidden at T1"; then
    echo "    expected T1 WARN T3-RULE-001 line missing" >&2
    printf '%s' "$output" | grep -A 2 "T3-Forbidden" >&2 || true
    return 1
  fi
  # Assert no FAIL line under the T3-Forbidden section. We extract the
  # block between the section echo line and the next `^[A-Z]` header.
  if printf '%s' "$output" | awk '
        /^T3-Forbidden Components/ { in_block=1; next }
        in_block && /^[A-Z]/ { in_block=0 }
        in_block { print }
      ' | grep -Eq "^[[:space:]]+FAIL[[:space:]]+\["; then
    echo "    T1 fixture emitted FAIL line under T3-Forbidden ; expected WARN only" >&2
    return 1
  fi
}

# FR-I3-T3F-062 — scenario 3 : no tier → N/A
# Section-scoped : asserts the T3-Forbidden section emits the N/A line
# "no compliance tier declared" per FR-I3-T3F-126. The overall linter
# exit code is not asserted (unrelated sections may fire on the synthetic
# tree).
_test_i3_l2_no_tier_na() {
  local tmpdir
  tmpdir="$(_mk_fixture_tree "" "" "")"
  trap "rm -rf '$tmpdir'" RETURN
  local output section_body
  output="$(_run_linter_in_fixture "$tmpdir")"
  section_body="$(printf '%s' "$output" | awk '
      /^T3-Forbidden Components/ { in_block=1; next }
      in_block && /^[A-Z]/ { in_block=0 }
      in_block { print }
    ')"
  if ! printf '%s' "$section_body" | grep -Fq "no compliance tier declared"; then
    echo "    expected N/A 'no compliance tier declared' line missing in section body" >&2
    echo "    section body:" >&2
    printf '%s\n' "$section_body" >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── I.3 — i3-t3-forbidden-linter — level $LEVEL ──"

  case "$LEVEL" in
    1)
      run_test _test_i3_001_linter_section_anchor
      run_test _test_i3_002_linter_section_echo
      run_test _test_i3_003_opt_out_env_var
      run_test _test_i3_004_tier_discovery_ledger
      run_test _test_i3_005_tier_discovery_na
      run_test _test_i3_006_standards_discovery
      run_test _test_i3_007_violation_format
      run_test _test_i3_008_standard_exists
      run_test _test_i3_009_standard_h2_sections
      run_test _test_i3_010_rule_catalogue_anchors
      run_test _test_i3_011_index_entry
      run_test _test_i3_012_review_entry
      run_test _test_i3_013_compliance_tiers_flip
      run_test _test_i3_014_linting_md_section
      ;;
    1,2|all)
      run_test _test_i3_001_linter_section_anchor
      run_test _test_i3_002_linter_section_echo
      run_test _test_i3_003_opt_out_env_var
      run_test _test_i3_004_tier_discovery_ledger
      run_test _test_i3_005_tier_discovery_na
      run_test _test_i3_006_standards_discovery
      run_test _test_i3_007_violation_format
      run_test _test_i3_008_standard_exists
      run_test _test_i3_009_standard_h2_sections
      run_test _test_i3_010_rule_catalogue_anchors
      run_test _test_i3_011_index_entry
      run_test _test_i3_012_review_entry
      run_test _test_i3_013_compliance_tiers_flip
      run_test _test_i3_014_linting_md_section
      run_test _test_i3_l2_t3_pubspec
      run_test _test_i3_l2_t3_cargo
      run_test _test_i3_l2_t1_warn_only
      run_test _test_i3_l2_no_tier_na
      ;;
    *)
      echo "unknown level: $LEVEL" >&2; exit 2
      ;;
  esac

  print_summary
}

main
