#!/usr/bin/env bash
# Forge — I.6 Compliance Artefacts Bundle Test Harness (i6-compliance-artefacts)
# <!-- Audit: I.6 (i6-compliance-artefacts) -->
#
# Validates the I.6 deliverables :
#
#   - .forge/scripts/compliance/bundle.sh — bundle generator
#     (CycloneDX SBOM + tier matrix + DPA template + audit ledger
#     snapshot, deterministic .tgz output per ADR-I6-CA-001).
#   - .forge/templates/compliance/forge-dpa-declared.template —
#     canonical DPA declaration template (FR-I6-CA-030..035).
#   - .forge/standards/global/compliance-artefacts-bundle.md v1.0.0
#     (≥ 6 H2 sections, ≥ 3 RFC-2119 MUST NOT clauses,
#     frontmatter pinned per FR-I6-CA-044).
#   - .forge/standards/index.yml entry (id global/compliance-artefacts-bundle,
#     10+ triggers, scope all, priority high).
#   - .forge/standards/REVIEW.md append-only birth entry dated 2026-05-12.
#   - docs/COMPLIANCE.md fourth H2 (## Auditor hand-off bundle).
#   - CHANGELOG.md [Unreleased] entry.
#
# 14 L1 + 2 L2 = 16 tests.
# Performance budget : L1 ≤ 5 s wall-clock (NFR-I6-CA-001).

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

BUNDLE_SCRIPT="$FORGE_ROOT_REAL/.forge/scripts/compliance/bundle.sh"
DPA_TEMPLATE="$FORGE_ROOT_REAL/.forge/templates/compliance/forge-dpa-declared.template"
STD_FILE="$FORGE_ROOT_REAL/.forge/standards/global/compliance-artefacts-bundle.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
COMPLIANCE_DOC="$FORGE_ROOT_REAL/docs/COMPLIANCE.md"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
SBOM_SCRIPT="$FORGE_ROOT_REAL/bin/forge-sbom.sh"
TIER_MATRIX_STD="$FORGE_ROOT_REAL/.forge/standards/global/compliance-tiers.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (14 tests)
# MANIFEST: _test_i6_001_script_presence            — FR-I6-CA-001
# MANIFEST: _test_i6_002_script_help_exit_zero      — FR-I6-CA-004
# MANIFEST: _test_i6_003_script_audit_comment       — FR-I6-CA-002
# MANIFEST: _test_i6_004_script_bogus_arg_exit_2    — FR-I6-CA-005
# MANIFEST: _test_i6_010_template_presence          — FR-I6-CA-030 / FR-I6-CA-031
# MANIFEST: _test_i6_011_template_example           — FR-I6-CA-032..035
# MANIFEST: _test_i6_020_standard_presence          — FR-I6-CA-040 / FR-I6-CA-043
# MANIFEST: _test_i6_021_standard_frontmatter       — FR-I6-CA-044
# MANIFEST: _test_i6_022_standard_h2_sections       — FR-I6-CA-045 / FR-I6-CA-046..049
# MANIFEST: _test_i6_023_standard_must_not          — FR-I6-CA-050 / FR-I6-CA-051
# MANIFEST: _test_i6_030_index_entry                — FR-I6-CA-060..064
# MANIFEST: _test_i6_031_review_entry               — FR-I6-CA-070 / FR-I6-CA-071
# MANIFEST: _test_i6_040_compliance_doc_h2          — FR-I6-CA-080..082
# MANIFEST: _test_i6_041_changelog_entry            — FR-I6-CA-092
#
# L2 (2 tests)
# MANIFEST: _test_i6_l2_bundle_good                 — FR-I6-CA-008..020 / FR-I6-CA-103
# MANIFEST: _test_i6_l2_bundle_determinism          — NFR-I6-CA-005

# ─── L1 tests ────────────────────────────────────────────────────

_not_implemented() {
  echo "    not implemented yet (RED witness)" >&2
  return 1
}

# FR-I6-CA-001 — script exists + executable
_test_i6_001_script_presence() {
  if [ ! -f "$BUNDLE_SCRIPT" ]; then
    echo "    bundle script missing: $BUNDLE_SCRIPT" >&2; return 1
  fi
  if [ ! -x "$BUNDLE_SCRIPT" ]; then
    echo "    bundle script not executable: $BUNDLE_SCRIPT" >&2; return 1
  fi
}

# FR-I6-CA-004 — --help exits 0 + emits usage
_test_i6_002_script_help_exit_zero() {
  if [ ! -x "$BUNDLE_SCRIPT" ]; then
    echo "    bundle script not executable: $BUNDLE_SCRIPT" >&2; return 1
  fi
  local out rc
  out="$(bash "$BUNDLE_SCRIPT" --help 2>&1)"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    --help expected exit 0, got $rc" >&2; return 1
  fi
  if ! printf '%s' "$out" | grep -Fq "Usage:"; then
    echo "    --help output missing 'Usage:' block" >&2; return 1
  fi
}

# FR-I6-CA-002 — audit comment in first 10 lines
_test_i6_003_script_audit_comment() {
  if [ ! -f "$BUNDLE_SCRIPT" ]; then
    echo "    bundle script missing: $BUNDLE_SCRIPT" >&2; return 1
  fi
  if ! head -10 "$BUNDLE_SCRIPT" | grep -Fq "Audit: I.6 (i6-compliance-artefacts)"; then
    echo "    audit comment missing in first 10 lines of $BUNDLE_SCRIPT" >&2; return 1
  fi
}

# FR-I6-CA-005 — bogus arg exits 2
_test_i6_004_script_bogus_arg_exit_2() {
  if [ ! -x "$BUNDLE_SCRIPT" ]; then
    echo "    bundle script not executable: $BUNDLE_SCRIPT" >&2; return 1
  fi
  bash "$BUNDLE_SCRIPT" --bogus-arg-that-does-not-exist >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -ne 2 ]; then
    echo "    bogus arg expected exit 2, got $rc" >&2; return 1
  fi
}

# FR-I6-CA-030 / FR-I6-CA-031 — template presence + audit comment
_test_i6_010_template_presence() {
  if [ ! -f "$DPA_TEMPLATE" ]; then
    echo "    DPA template missing: $DPA_TEMPLATE" >&2; return 1
  fi
  if ! head -5 "$DPA_TEMPLATE" | grep -Fq "Audit: I.6 (i6-compliance-artefacts)"; then
    echo "    audit comment missing in first 5 lines of $DPA_TEMPLATE" >&2; return 1
  fi
}

# FR-I6-CA-032..035 — template canonical example + ADR-K3-002 / K3-RULE-002 / staleness
_test_i6_011_template_example() {
  if [ ! -f "$DPA_TEMPLATE" ]; then
    echo "    DPA template missing: $DPA_TEMPLATE" >&2; return 1
  fi
  if ! grep -Fq "T1: 2026-04-15 LegalOps-Confluence-DPA-2026-Q2" "$DPA_TEMPLATE"; then
    echo "    canonical example line missing" >&2; return 1
  fi
  if ! grep -Fq "ADR-K3-002" "$DPA_TEMPLATE"; then
    echo "    ADR-K3-002 cross-reference missing" >&2; return 1
  fi
  if ! grep -Fq "K3-RULE-002" "$DPA_TEMPLATE"; then
    echo "    K3-RULE-002 citation missing" >&2; return 1
  fi
  if ! grep -Eq "13[- ]month" "$DPA_TEMPLATE"; then
    echo "    13-month staleness window mention missing" >&2; return 1
  fi
}

# FR-I6-CA-040 / FR-I6-CA-043 — standard presence + H1 anchor
_test_i6_020_standard_presence() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -q "^# Standard — Compliance Artefacts Bundle" "$STD_FILE"; then
    echo "    H1 anchor missing: '# Standard — Compliance Artefacts Bundle'" >&2; return 1
  fi
  if ! head -5 "$STD_FILE" | grep -Fq "Audit: I.6 (i6-compliance-artefacts)"; then
    echo "    audit comment missing in first 5 lines of $STD_FILE" >&2; return 1
  fi
}

# FR-I6-CA-044 — frontmatter version + lifecycle dates + linter_rule
_test_i6_021_standard_frontmatter() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -q "version: 1.0.0" "$STD_FILE"; then
    echo "    'version: 1.0.0' missing" >&2; return 1
  fi
  if ! grep -q "last_reviewed: 2026-05-12" "$STD_FILE"; then
    echo "    'last_reviewed: 2026-05-12' missing" >&2; return 1
  fi
  if ! grep -q "expires_at: 2027-05-12" "$STD_FILE"; then
    echo "    'expires_at: 2027-05-12' missing" >&2; return 1
  fi
  if ! grep -q "linter_rule: null" "$STD_FILE"; then
    echo "    'linter_rule: null' missing" >&2; return 1
  fi
}

# FR-I6-CA-045..049 — ≥ 6 H2 sections + key headers present
_test_i6_022_standard_h2_sections() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  local count
  count="$(grep -c "^## " "$STD_FILE")"
  if [ "$count" -lt 6 ]; then
    echo "    H2 section count $count < 6 minimum" >&2; return 1
  fi
  local section
  local missing=()
  for section in \
    "## Purpose & EU compliance rationale" \
    "## Bundle content schema" \
    "## Determinism guarantee" \
    "## Consumption protocol" \
    "## Regeneration cadence" \
    "## Interdictions"; do
    if ! grep -Fq "$section" "$STD_FILE"; then
      missing+=("$section")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    missing H2 section(s): ${missing[*]}" >&2; return 1
  fi
  # Determinism guarantee MUST cite SOURCE_DATE_EPOCH (FR-I6-CA-047).
  if ! grep -Fq "SOURCE_DATE_EPOCH" "$STD_FILE"; then
    echo "    SOURCE_DATE_EPOCH citation missing" >&2; return 1
  fi
}

# FR-I6-CA-050 / FR-I6-CA-051 — ≥ 3 MUST NOT clauses
_test_i6_023_standard_must_not() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  local count
  count="$(grep -c "MUST NOT" "$STD_FILE")"
  if [ "$count" -lt 3 ]; then
    echo "    MUST NOT count $count < 3 minimum" >&2; return 1
  fi
}

# FR-I6-CA-060..064 — standards/index.yml entry
_test_i6_030_index_entry() {
  if [ ! -f "$INDEX_YML" ]; then
    echo "    index.yml missing: $INDEX_YML" >&2; return 1
  fi
  if ! grep -Fq "id: global/compliance-artefacts-bundle" "$INDEX_YML"; then
    echo "    'id: global/compliance-artefacts-bundle' missing in index.yml" >&2; return 1
  fi
  if ! grep -Fq "path: standards/global/compliance-artefacts-bundle.md" "$INDEX_YML"; then
    echo "    'path: standards/global/compliance-artefacts-bundle.md' missing in index.yml" >&2; return 1
  fi
  local trigger
  for trigger in bundle auditor audit-ledger regulatory-handoff nis2 dora cra ai-act; do
    if ! grep -Fq "$trigger" "$INDEX_YML"; then
      echo "    index trigger '$trigger' missing" >&2; return 1
    fi
  done
}

# FR-I6-CA-070 / FR-I6-CA-071 — REVIEW.md append-only birth entry
_test_i6_031_review_entry() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing: $REVIEW_MD" >&2; return 1
  fi
  if ! grep -Fq "## 2026-05-12 — Initial ratification (i6-compliance-artefacts)" "$REVIEW_MD"; then
    echo "    REVIEW.md birth entry H2 missing" >&2; return 1
  fi
  if ! grep -Fq "global/compliance-artefacts-bundle.md" "$REVIEW_MD"; then
    echo "    global/compliance-artefacts-bundle.md reference missing in REVIEW.md" >&2; return 1
  fi
}

# FR-I6-CA-080..082 — docs/COMPLIANCE.md Auditor hand-off H2
_test_i6_040_compliance_doc_h2() {
  if [ ! -f "$COMPLIANCE_DOC" ]; then
    echo "    docs/COMPLIANCE.md missing: $COMPLIANCE_DOC" >&2; return 1
  fi
  if ! grep -q "^## Auditor hand-off bundle" "$COMPLIANCE_DOC"; then
    echo "    '## Auditor hand-off bundle' H2 missing in docs/COMPLIANCE.md" >&2; return 1
  fi
  if ! grep -Fq ".forge/scripts/compliance/bundle.sh" "$COMPLIANCE_DOC"; then
    echo "    bundle script cross-link missing" >&2; return 1
  fi
  if ! grep -Fq "compliance-artefacts-bundle.md" "$COMPLIANCE_DOC"; then
    echo "    standard cross-link missing" >&2; return 1
  fi
  if ! grep -Fq "SOURCE_DATE_EPOCH" "$COMPLIANCE_DOC"; then
    echo "    SOURCE_DATE_EPOCH mention missing" >&2; return 1
  fi
}

# FR-I6-CA-092 — CHANGELOG.md entry
_test_i6_041_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing: $CHANGELOG_MD" >&2; return 1
  fi
  if ! grep -Fq "i6-compliance-artefacts" "$CHANGELOG_MD"; then
    echo "    'i6-compliance-artefacts' reference missing in CHANGELOG.md" >&2; return 1
  fi
  if ! grep -Fq "compliance artefacts bundle" "$CHANGELOG_MD"; then
    echo "    'compliance artefacts bundle' phrase missing in CHANGELOG.md" >&2; return 1
  fi
}

# ─── L2 helpers ──────────────────────────────────────────────────

L2_TMP=""

_setup_l2() {
  # Create a tmpdir with the minimum source tree for the bundle.
  # We stage real artefacts copied from FORGE_ROOT_REAL so the bundle
  # script encounters the same paths it expects in production.
  L2_TMP="$(mk_tmpdir_with_trap forge-i6-l2)"

  mkdir -p \
    "$L2_TMP/.forge/standards/global" \
    "$L2_TMP/.forge/templates/compliance" \
    "$L2_TMP/.forge/changes/sample-archived" \
    "$L2_TMP/.forge/changes/sample-archived-2" \
    "$L2_TMP/bin"

  # Tier matrix standard (real copy).
  if [ -f "$TIER_MATRIX_STD" ]; then
    cp "$TIER_MATRIX_STD" "$L2_TMP/.forge/standards/global/compliance-tiers.md"
  else
    echo "# Standard — Compliance Tiers" > "$L2_TMP/.forge/standards/global/compliance-tiers.md"
  fi

  # DPA template (real copy if present, otherwise a stub of the same name).
  if [ -f "$DPA_TEMPLATE" ]; then
    cp "$DPA_TEMPLATE" "$L2_TMP/.forge/templates/compliance/forge-dpa-declared.template"
  else
    cat > "$L2_TMP/.forge/templates/compliance/forge-dpa-declared.template" <<'TPL'
# <!-- Audit: I.6 (i6-compliance-artefacts) -->
# Example: T1: 2026-04-15 LegalOps-Confluence-DPA-2026-Q2
TPL
  fi

  # Minimal REVIEW.md.
  cat > "$L2_TMP/.forge/standards/REVIEW.md" <<'REV'
# Forge Standards Review Ledger

## 2026-05-12 — Initial ratification (sample)

- **Reviewer**: @testfixture
- **Decision**: KEEP
REV

  # Two archived change stubs.
  cat > "$L2_TMP/.forge/changes/sample-archived/.forge.yaml" <<'CHG'
name: sample-archived
status: archived
created: 2026-05-01
parent_audit_items:
  - SAMPLE.1
timeline:
  archived: 2026-05-10
CHG

  cat > "$L2_TMP/.forge/changes/sample-archived-2/.forge.yaml" <<'CHG'
name: sample-archived-2
status: archived
created: 2026-05-02
parent_audit_items:
  - SAMPLE.2
timeline:
  archived: 2026-05-11
CHG

  # SBOM script — invoke the real one with --target $L2_TMP. The real
  # script handles "no lockfiles found" by exiting 1 which the bundle
  # treats as non-fatal (FR-I6-CA-019). Provide it under $L2_TMP/bin
  # only if real script available.
  if [ -f "$SBOM_SCRIPT" ]; then
    cp "$SBOM_SCRIPT" "$L2_TMP/bin/forge-sbom.sh"
    chmod +x "$L2_TMP/bin/forge-sbom.sh"
  fi

  # Project VERSION file so audit ledger can populate framework_version.
  echo "0.0.0-test" > "$L2_TMP/VERSION"
}

_teardown_l2() {
  if [ -n "${L2_TMP:-}" ] && [ -d "$L2_TMP" ]; then
    rm -rf "$L2_TMP"
  fi
  L2_TMP=""
}

# FR-I6-CA-008..020 / FR-I6-CA-103 — bundle good fixture
_test_i6_l2_bundle_good() {
  _setup_l2
  trap '_teardown_l2' RETURN
  local out="$L2_TMP/bundle.tgz"
  bash "$BUNDLE_SCRIPT" --target "$L2_TMP" --output "$out" >/dev/null 2>&1
  local rc=$?
  assert_eq "0" "$rc" "bundle exit code (good fixture)" || return 1
  if [ ! -f "$out" ]; then
    echo "    bundle output not produced: $out" >&2; return 1
  fi
  # Six members expected.
  local listing
  listing="$(tar -tzf "$out" 2>/dev/null | sort)"
  local member
  for member in MANIFEST \
    "tier-matrix/compliance-tiers.md" \
    "templates/forge-dpa-declared.template" \
    "audit/audit-ledger.json" \
    "audit/audit-ledger.md" \
    "sbom/sbom.cdx.json"; do
    if ! printf '%s\n' "$listing" | grep -Fxq "$member"; then
      echo "    expected bundle member missing: $member" >&2
      echo "    listing was:" >&2
      printf '%s\n' "$listing" | sed 's/^/      /' >&2
      return 1
    fi
  done
  # MANIFEST must list 5 non-MANIFEST members (sorted, sha256 + size + path).
  local manifest_body
  manifest_body="$(tar -xOzf "$out" MANIFEST 2>/dev/null)"
  local manifest_lines
  manifest_lines="$(printf '%s' "$manifest_body" | grep -c '^[0-9a-f]\{64\}')"
  if [ "$manifest_lines" -lt 5 ]; then
    echo "    MANIFEST expected ≥ 5 sha256-line entries, got $manifest_lines" >&2
    return 1
  fi
}

# NFR-I6-CA-005 — determinism : SOURCE_DATE_EPOCH=0 × 2 → byte-identical
_test_i6_l2_bundle_determinism() {
  _setup_l2
  trap '_teardown_l2' RETURN
  local b1="$L2_TMP/bundle1.tgz"
  local b2="$L2_TMP/bundle2.tgz"
  SOURCE_DATE_EPOCH=0 bash "$BUNDLE_SCRIPT" --target "$L2_TMP" --output "$b1" >/dev/null 2>&1
  local rc1=$?
  SOURCE_DATE_EPOCH=0 bash "$BUNDLE_SCRIPT" --target "$L2_TMP" --output "$b2" >/dev/null 2>&1
  local rc2=$?
  assert_eq "0" "$rc1" "first run exit" || return 1
  assert_eq "0" "$rc2" "second run exit" || return 1
  if ! diff -q "$b1" "$b2" >/dev/null 2>&1; then
    echo "    bundles NOT byte-identical (NFR-I6-CA-005 violation)" >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── I.6 — i6-compliance-artefacts — level $LEVEL ──"

  # L1 always runs.
  run_test _test_i6_001_script_presence
  run_test _test_i6_002_script_help_exit_zero
  run_test _test_i6_003_script_audit_comment
  run_test _test_i6_004_script_bogus_arg_exit_2
  run_test _test_i6_010_template_presence
  run_test _test_i6_011_template_example
  run_test _test_i6_020_standard_presence
  run_test _test_i6_021_standard_frontmatter
  run_test _test_i6_022_standard_h2_sections
  run_test _test_i6_023_standard_must_not
  run_test _test_i6_030_index_entry
  run_test _test_i6_031_review_entry
  run_test _test_i6_040_compliance_doc_h2
  run_test _test_i6_041_changelog_entry

  # L2 runs when --level includes 2 or "all".
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based bundle determinism"
    run_test _test_i6_l2_bundle_good
    run_test _test_i6_l2_bundle_determinism
  fi

  print_summary
}

main "$@"
