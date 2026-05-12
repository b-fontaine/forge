#!/usr/bin/env bash
# Forge — I.2 Compliance Tiers Standard Test Harness (i2-compliance-tiers)
# <!-- Audit: I.2 (i2-compliance-tiers) -->
#
# Validates the I.2 deliverables :
#
#   - .forge/standards/global/compliance-tiers.md v1.0.0 (7 H2
#     sections, verbatim citation of compliance-tier.schema.json
#     x-tier-descriptions, 15-row matrix mirroring §10.2,
#     ≥ 3 RFC-2119 MUST NOT clauses).
#   - .forge/standards/index.yml entry (id global/compliance-tiers,
#     9 triggers, scope all, priority high).
#   - .forge/standards/REVIEW.md append-only birth entry.
#   - docs/COMPLIANCE.md adopter intro (3 H2 sections).
#   - CHANGELOG.md [Unreleased] entry.
#
# 14 tests : 14 L1 hermetic grep-based assertions.
# Performance : L1 ≤ 3 s wall-clock (NFR-I2-CT-001).

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

STD_FILE="$FORGE_ROOT_REAL/.forge/standards/global/compliance-tiers.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
COMPLIANCE_DOC="$FORGE_ROOT_REAL/docs/COMPLIANCE.md"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
SCHEMA_FILE="$FORGE_ROOT_REAL/.forge/schemas/compliance-tier.schema.json"
DEMETER_AGENT="$FORGE_ROOT_REAL/.claude/agents/demeter.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (14 tests)
# MANIFEST: _test_i2_001_standard_exists           — FR-I2-CT-001 file presence
# MANIFEST: _test_i2_002_audit_comment             — FR-I2-CT-002 audit comment
# MANIFEST: _test_i2_003_trigger_comment           — FR-I2-CT-003 trigger comment
# MANIFEST: _test_i2_004_h1_anchor                 — FR-I2-CT-004 H1 anchor
# MANIFEST: _test_i2_005_frontmatter_version       — FR-I2-CT-005/006/007 frontmatter dates
# MANIFEST: _test_i2_006_h2_sections               — FR-I2-CT-020 ≥ 6 H2 sections
# MANIFEST: _test_i2_007_tier_definitions_verbatim — FR-I2-CT-022/NFR-I2-CT-004 schema verbatim
# MANIFEST: _test_i2_008_matrix_rows               — FR-I2-CT-023/NFR-I2-CT-005 ≥ 15 matrix rows
# MANIFEST: _test_i2_009_demeter_crosslink         — FR-I2-CT-024 Demeter cross-link
# MANIFEST: _test_i2_010_interdictions             — FR-I2-CT-027 ≥ 3 MUST NOT clauses
# MANIFEST: _test_i2_011_index_entry               — FR-I2-CT-040 standards/index.yml entry
# MANIFEST: _test_i2_012_review_entry              — FR-I2-CT-050 REVIEW.md entry
# MANIFEST: _test_i2_013_compliance_doc            — FR-I2-CT-090..092 docs/COMPLIANCE.md
# MANIFEST: _test_i2_014_changelog_entry           — FR-I2-CT-080 CHANGELOG.md entry

# ─── L1 tests ────────────────────────────────────────────────────

# FR-I2-CT-001 — standard file exists
_test_i2_001_standard_exists() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
}

# FR-I2-CT-002 — audit comment in first 5 lines
_test_i2_002_audit_comment() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! head -5 "$STD_FILE" | grep -q "<!-- Audit: I.2 (i2-compliance-tiers) -->"; then
    echo "    audit comment missing in first 5 lines of $STD_FILE" >&2; return 1
  fi
}

# FR-I2-CT-003 — trigger comment with ≥ 9 keywords in first 5 lines
_test_i2_003_trigger_comment() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  local header
  header="$(head -5 "$STD_FILE")"
  if ! printf '%s' "$header" | grep -q "<!-- Trigger:"; then
    echo "    trigger comment missing in first 5 lines" >&2; return 1
  fi
  local kw
  for kw in compliance t1 t2 t3 eu-tier dpa schrems cloud-act tier-classification; do
    if ! printf '%s' "$header" | grep -Fq "$kw"; then
      echo "    trigger keyword missing: $kw" >&2; return 1
    fi
  done
}

# FR-I2-CT-004 — H1 anchor `# Standard — Compliance Tiers`
_test_i2_004_h1_anchor() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -q "^# Standard — Compliance Tiers" "$STD_FILE"; then
    echo "    H1 anchor missing: '# Standard — Compliance Tiers ...'" >&2; return 1
  fi
}

# FR-I2-CT-005/006/007 — frontmatter version + lifecycle dates
_test_i2_005_frontmatter_version() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -q "version: 1.0.0" "$STD_FILE"; then
    echo "    'version: 1.0.0' missing" >&2; return 1
  fi
  if ! grep -q "last_reviewed: 2026-05-11" "$STD_FILE"; then
    echo "    'last_reviewed: 2026-05-11' missing" >&2; return 1
  fi
  if ! grep -q "expires_at: 2027-05-11" "$STD_FILE"; then
    echo "    'expires_at: 2027-05-11' missing" >&2; return 1
  fi
  if ! grep -q "linter_rule: t3-forbidden-components" "$STD_FILE"; then
    echo "    'linter_rule: t3-forbidden-components' forward-pointer missing" >&2; return 1
  fi
}

# FR-I2-CT-020 — ≥ 6 H2 sections
_test_i2_006_h2_sections() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  local count
  count="$(grep -c "^## " "$STD_FILE")"
  if [ "$count" -lt 6 ]; then
    echo "    H2 section count $count < 6 minimum" >&2; return 1
  fi
}

# FR-I2-CT-022 / NFR-I2-CT-004 — tier descriptions verbatim from schema
_test_i2_007_tier_definitions_verbatim() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -Fq "RGPD-compliant via DPA — SaaS hors EU acceptable si DPA + SCC + protections complémentaires (chiffrement, BYOK), assume risque résiduel CLOUD Act." "$STD_FILE"; then
    echo "    T1 verbatim description missing" >&2; return 1
  fi
  if ! grep -Fq "Self-hostable — déployable sur n'importe quel K8s EU, contrôle technique mais pas qualification sovereign." "$STD_FILE"; then
    echo "    T2 verbatim description missing" >&2; return 1
  fi
  if ! grep -Fq "Hébergement EU strict — SecNumCloud / HDS / EUCS High, 100% EU jurisdiction, immune CLOUD Act." "$STD_FILE"; then
    echo "    T3 verbatim description missing" >&2; return 1
  fi
}

# FR-I2-CT-023 / NFR-I2-CT-005 — ≥ 15 matrix rows
_test_i2_008_matrix_rows() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  # Component anchor strings from §10.2. We count lines mentioning
  # the canonical component names to confirm all 15 rows appear.
  local row
  local missing=()
  for row in \
    "Flutter / Qwik" \
    "Rust + tonic + axum" \
    "Envoy Gateway" \
    "Postgres 17 + pgvector" \
    "DBOS (embedded library)" \
    "Zitadel" \
    "SigNoz" \
    "Coroot" \
    "OTel Collector / OBI" \
    "OVHcloud / Scaleway / Outscale" \
    "AWS / GCP / Azure" \
    "Firebase" \
    "Temporal Cloud" \
    "LLM Gateway" \
    "NATS JetStream"; do
    if ! grep -Fq "$row" "$STD_FILE"; then
      missing+=("$row")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    matrix row(s) missing: ${missing[*]}" >&2; return 1
  fi
}

# FR-I2-CT-024 — Demeter cross-link + FR-K3-DEM-068 citation
_test_i2_009_demeter_crosslink() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -Fq "demeter.md" "$STD_FILE"; then
    echo "    Demeter persona cross-link missing" >&2; return 1
  fi
  if ! grep -Fq "FR-K3-DEM-068" "$STD_FILE"; then
    echo "    FR-K3-DEM-068 citation (tier scaling) missing" >&2; return 1
  fi
  if ! grep -Fq "data-stewardship-rules.md" "$STD_FILE"; then
    echo "    sibling standard cross-link missing" >&2; return 1
  fi
}

# FR-I2-CT-027 — ≥ 3 MUST NOT clauses
_test_i2_010_interdictions() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  local count
  count="$(grep -c "MUST NOT" "$STD_FILE")"
  if [ "$count" -lt 3 ]; then
    echo "    MUST NOT count $count < 3 minimum" >&2; return 1
  fi
}

# FR-I2-CT-040 — standards/index.yml entry
_test_i2_011_index_entry() {
  if [ ! -f "$INDEX_YML" ]; then
    echo "    index.yml missing: $INDEX_YML" >&2; return 1
  fi
  if ! grep -Fq "id: global/compliance-tiers" "$INDEX_YML"; then
    echo "    'id: global/compliance-tiers' entry missing in index.yml" >&2; return 1
  fi
  if ! grep -Fq "path: standards/global/compliance-tiers.md" "$INDEX_YML"; then
    echo "    'path: standards/global/compliance-tiers.md' missing in index.yml" >&2; return 1
  fi
  if ! grep -Fq "eu-tier" "$INDEX_YML"; then
    echo "    'eu-tier' trigger missing in index.yml" >&2; return 1
  fi
}

# FR-I2-CT-050 — REVIEW.md append-only entry
_test_i2_012_review_entry() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing: $REVIEW_MD" >&2; return 1
  fi
  if ! grep -Fq "## 2026-05-11 — Initial ratification (i2-compliance-tiers)" "$REVIEW_MD"; then
    echo "    'Initial ratification (i2-compliance-tiers)' H2 missing in REVIEW.md" >&2; return 1
  fi
  if ! grep -Fq "global/compliance-tiers.md" "$REVIEW_MD"; then
    echo "    'global/compliance-tiers.md' reference missing in REVIEW.md" >&2; return 1
  fi
}

# FR-I2-CT-090..092 — docs/COMPLIANCE.md presence + H1 + 3 H2s
_test_i2_013_compliance_doc() {
  if [ ! -f "$COMPLIANCE_DOC" ]; then
    echo "    docs/COMPLIANCE.md missing: $COMPLIANCE_DOC" >&2; return 1
  fi
  if ! grep -q "^# Forge Compliance" "$COMPLIANCE_DOC"; then
    echo "    H1 anchor missing in $COMPLIANCE_DOC" >&2; return 1
  fi
  local h2_count
  h2_count="$(grep -c "^## " "$COMPLIANCE_DOC")"
  if [ "$h2_count" -lt 3 ]; then
    echo "    docs/COMPLIANCE.md H2 count $h2_count < 3 minimum" >&2; return 1
  fi
  if ! grep -Fq "compliance-tiers.md" "$COMPLIANCE_DOC"; then
    echo "    cross-link to compliance-tiers.md missing in $COMPLIANCE_DOC" >&2; return 1
  fi
}

# FR-I2-CT-080 — CHANGELOG entry
_test_i2_014_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing: $CHANGELOG_MD" >&2; return 1
  fi
  if ! grep -Fq "i2-compliance-tiers" "$CHANGELOG_MD"; then
    echo "    'i2-compliance-tiers' reference missing in CHANGELOG.md" >&2; return 1
  fi
  if ! grep -Fq "compliance-tiers standard" "$CHANGELOG_MD"; then
    echo "    'compliance-tiers standard' reference missing in CHANGELOG.md" >&2; return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── I.2 — i2-compliance-tiers — level $LEVEL ──"

  case "$LEVEL" in
    1|1,2|all)
      run_test _test_i2_001_standard_exists
      run_test _test_i2_002_audit_comment
      run_test _test_i2_003_trigger_comment
      run_test _test_i2_004_h1_anchor
      run_test _test_i2_005_frontmatter_version
      run_test _test_i2_006_h2_sections
      run_test _test_i2_007_tier_definitions_verbatim
      run_test _test_i2_008_matrix_rows
      run_test _test_i2_009_demeter_crosslink
      run_test _test_i2_010_interdictions
      run_test _test_i2_011_index_entry
      run_test _test_i2_012_review_entry
      run_test _test_i2_013_compliance_doc
      run_test _test_i2_014_changelog_entry
      ;;
    *)
      echo "unknown level: $LEVEL" >&2; exit 2
      ;;
  esac

  print_summary
}

main
