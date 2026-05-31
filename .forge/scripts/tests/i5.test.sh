#!/usr/bin/env bash
# Forge — I.5 Reusable Compliance Workflow Test Harness (i5-compliance-workflow)
# <!-- Audit: I.5 (i5-compliance-workflow) -->
#
# Validates the I.5 deliverables :
#
#   - .github/workflows/forge-compliance.yml — reusable workflow
#     (on: workflow_call:) orchestrating Demeter + linter + SBOM +
#     bundle per FR-I5-CW-001..060.
#   - .forge/standards/global/forge-compliance-workflow.md v1.0.0
#     (≥ 7 H2 sections, ≥ 3 RFC-2119 MUST NOT clauses,
#     frontmatter pinned per FR-I5-CW-074).
#   - .forge/standards/index.yml entry (id global/forge-compliance-workflow,
#     ≥ 8 triggers, scope all, priority high).
#   - .forge/standards/REVIEW.md append-only birth entry 2026-05-12.
#   - docs/COMPLIANCE.md H2 (## Reusable compliance workflow).
#   - CHANGELOG.md [Unreleased] entry.
#
# 16 L1 + 1 L2 = 17 tests.
# Performance budget : L1 ≤ 5 s wall-clock (NFR-I5-CW-001).

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

WORKFLOW_YML="$FORGE_ROOT_REAL/.github/workflows/forge-compliance.yml"
STD_FILE="$FORGE_ROOT_REAL/.forge/standards/global/forge-compliance-workflow.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
COMPLIANCE_DOC="$FORGE_ROOT_REAL/docs/COMPLIANCE.md"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
FORGE_CI_YML="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (16 tests)
# MANIFEST: _test_i5_001_workflow_presence       — FR-I5-CW-001
# MANIFEST: _test_i5_002_workflow_yaml_parses    — FR-I5-CW-003
# MANIFEST: _test_i5_003_workflow_audit_comment  — FR-I5-CW-002
# MANIFEST: _test_i5_004_on_workflow_call        — FR-I5-CW-005
# MANIFEST: _test_i5_005_inputs_schema           — FR-I5-CW-010 / 011 / 012
# MANIFEST: _test_i5_006_outputs_schema          — FR-I5-CW-020
# MANIFEST: _test_i5_007_step_invocations        — FR-I5-CW-040 / 041 / 042 / 043 / 045
# MANIFEST: _test_i5_008_action_pins             — FR-I5-CW-033 / 034 / 045 / NFR-I5-CW-005
# MANIFEST: _test_i5_009_standard_presence       — FR-I5-CW-070 / 073
# MANIFEST: _test_i5_010_standard_frontmatter    — FR-I5-CW-074
# MANIFEST: _test_i5_011_standard_h2_sections    — FR-I5-CW-075
# MANIFEST: _test_i5_012_standard_must_not       — FR-I5-CW-080
# MANIFEST: _test_i5_013_index_entry             — FR-I5-CW-090..094
# MANIFEST: _test_i5_014_review_entry            — FR-I5-CW-100
# MANIFEST: _test_i5_015_compliance_doc_h2       — FR-I5-CW-110..112
# MANIFEST: _test_i5_016_changelog_entry         — FR-I5-CW-142
#
# L2 (1 test, opt-in via FORGE_I5_ACT=1 ; skip-pass otherwise)
# MANIFEST: _test_i5_l2_act_workflow_call        — FR-I5-CW-117 / NFR-I5-CW-009 / ADR-I5-CW-003

# ─── L1 tests ────────────────────────────────────────────────────

_not_implemented() {
  echo "    not implemented yet (RED witness)" >&2
  return 1
}

# FR-I5-CW-001 — workflow file presence
_test_i5_001_workflow_presence() {
  if [ ! -f "$WORKFLOW_YML" ]; then
    echo "    workflow file missing: $WORKFLOW_YML" >&2; return 1
  fi
}

# FR-I5-CW-003 — workflow YAML well-formed
_test_i5_002_workflow_yaml_parses() {
  if [ ! -f "$WORKFLOW_YML" ]; then
    echo "    workflow file missing: $WORKFLOW_YML" >&2; return 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "    python3 not available — cannot verify YAML well-formedness" >&2; return 1
  fi
  if ! python3 -c "import sys, yaml; yaml.safe_load(open(sys.argv[1]).read())" "$WORKFLOW_YML" 2>/dev/null; then
    echo "    workflow YAML failed to parse: $WORKFLOW_YML" >&2; return 1
  fi
}

# FR-I5-CW-002 — audit comment in first 10 lines
_test_i5_003_workflow_audit_comment() {
  if [ ! -f "$WORKFLOW_YML" ]; then
    echo "    workflow file missing: $WORKFLOW_YML" >&2; return 1
  fi
  if ! head -10 "$WORKFLOW_YML" | grep -Fq "Audit: I.5 (i5-compliance-workflow)"; then
    echo "    audit comment missing in first 10 lines of $WORKFLOW_YML" >&2; return 1
  fi
}

# FR-I5-CW-005 — on: workflow_call: trigger
_test_i5_004_on_workflow_call() {
  if [ ! -f "$WORKFLOW_YML" ]; then
    echo "    workflow file missing: $WORKFLOW_YML" >&2; return 1
  fi
  if ! grep -Eq "^  workflow_call:" "$WORKFLOW_YML"; then
    echo "    'workflow_call:' trigger missing under top-level on:" >&2; return 1
  fi
}

# FR-I5-CW-010 / 011 / 012 — three inputs declared
_test_i5_005_inputs_schema() {
  if [ ! -f "$WORKFLOW_YML" ]; then
    echo "    workflow file missing: $WORKFLOW_YML" >&2; return 1
  fi
  local input
  for input in eu-tier target-dir artefact-name; do
    if ! grep -Fq "${input}:" "$WORKFLOW_YML"; then
      echo "    input '${input}' missing in workflow YAML" >&2; return 1
    fi
  done
  if ! grep -Fq "required: true" "$WORKFLOW_YML"; then
    echo "    'required: true' missing (eu-tier should be required)" >&2; return 1
  fi
  if ! grep -Fq "forge-compliance-artefacts" "$WORKFLOW_YML"; then
    echo "    default 'forge-compliance-artefacts' missing for artefact-name" >&2; return 1
  fi
}

# FR-I5-CW-020 — output artefact-path declared
_test_i5_006_outputs_schema() {
  if [ ! -f "$WORKFLOW_YML" ]; then
    echo "    workflow file missing: $WORKFLOW_YML" >&2; return 1
  fi
  if ! grep -Fq "artefact-path:" "$WORKFLOW_YML"; then
    echo "    output 'artefact-path:' missing in workflow YAML" >&2; return 1
  fi
}

# FR-I5-CW-040..045 — four script invocations present
_test_i5_007_step_invocations() {
  if [ ! -f "$WORKFLOW_YML" ]; then
    echo "    workflow file missing: $WORKFLOW_YML" >&2; return 1
  fi
  local script
  for script in \
    "bin/forge-demeter-scan.sh" \
    ".forge/scripts/constitution-linter.sh" \
    "bin/forge-sbom.sh" \
    ".forge/scripts/compliance/bundle.sh"; do
    if ! grep -Fq "$script" "$WORKFLOW_YML"; then
      echo "    script invocation missing: $script" >&2; return 1
    fi
  done
}

# FR-I5-CW-033 / 034 / 045 — action pins
_test_i5_008_action_pins() {
  if [ ! -f "$WORKFLOW_YML" ]; then
    echo "    workflow file missing: $WORKFLOW_YML" >&2; return 1
  fi
  local action
  for action in \
    "actions/checkout@v6" \
    "actions/setup-python@v6" \
    "actions/upload-artifact@v7"; do
    if ! grep -Fq "$action" "$WORKFLOW_YML"; then
      echo "    action pin missing: $action" >&2; return 1
    fi
  done
}

# FR-I5-CW-070 / 073 — standard presence + H1 anchor
_test_i5_009_standard_presence() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -q "^# Standard — Forge Compliance Workflow" "$STD_FILE"; then
    echo "    H1 anchor missing: '# Standard — Forge Compliance Workflow'" >&2; return 1
  fi
  if ! head -5 "$STD_FILE" | grep -Fq "Audit: I.5 (i5-compliance-workflow)"; then
    echo "    audit comment missing in first 5 lines of $STD_FILE" >&2; return 1
  fi
}

# FR-I5-CW-074 — frontmatter version + lifecycle dates + linter_rule
_test_i5_010_standard_frontmatter() {
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

# FR-I5-CW-075 — ≥ 6 H2 sections (target 7) with key headers
_test_i5_011_standard_h2_sections() {
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
    "## Workflow inputs and outputs" \
    "## Step-by-step contract" \
    "## Tier-scaled severity aggregation" \
    "## Consumption protocol" \
    "## Interdictions"; do
    if ! grep -Fq "$section" "$STD_FILE"; then
      missing+=("$section")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    missing H2 section(s): ${missing[*]}" >&2; return 1
  fi
}

# FR-I5-CW-080 — ≥ 3 MUST NOT clauses
_test_i5_012_standard_must_not() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  local count
  count="$(grep -c "MUST NOT" "$STD_FILE")"
  if [ "$count" -lt 3 ]; then
    echo "    MUST NOT count $count < 3 minimum" >&2; return 1
  fi
}

# FR-I5-CW-090..094 — standards/index.yml entry
_test_i5_013_index_entry() {
  if [ ! -f "$INDEX_YML" ]; then
    echo "    index.yml missing: $INDEX_YML" >&2; return 1
  fi
  if ! grep -Fq "id: global/forge-compliance-workflow" "$INDEX_YML"; then
    echo "    'id: global/forge-compliance-workflow' missing in index.yml" >&2; return 1
  fi
  if ! grep -Fq "path: standards/global/forge-compliance-workflow.md" "$INDEX_YML"; then
    echo "    'path: standards/global/forge-compliance-workflow.md' missing in index.yml" >&2; return 1
  fi
  local trigger
  for trigger in compliance forge-compliance.yml reusable-workflow workflow_call eu-tier ci-enforcement regulatory-handoff github-actions; do
    if ! grep -Fq "$trigger" "$INDEX_YML"; then
      echo "    index trigger '$trigger' missing" >&2; return 1
    fi
  done
}

# FR-I5-CW-100 — REVIEW.md append-only birth entry
_test_i5_014_review_entry() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing: $REVIEW_MD" >&2; return 1
  fi
  if ! grep -Fq "## 2026-05-12 — Initial ratification (i5-compliance-workflow)" "$REVIEW_MD"; then
    echo "    REVIEW.md birth entry H2 missing" >&2; return 1
  fi
  if ! grep -Fq "global/forge-compliance-workflow.md" "$REVIEW_MD"; then
    echo "    global/forge-compliance-workflow.md reference missing in REVIEW.md" >&2; return 1
  fi
}

# FR-I5-CW-110..112 — docs/COMPLIANCE.md H2
_test_i5_015_compliance_doc_h2() {
  if [ ! -f "$COMPLIANCE_DOC" ]; then
    echo "    docs/COMPLIANCE.md missing: $COMPLIANCE_DOC" >&2; return 1
  fi
  if ! grep -q "^## Reusable compliance workflow" "$COMPLIANCE_DOC"; then
    echo "    '## Reusable compliance workflow' H2 missing in docs/COMPLIANCE.md" >&2; return 1
  fi
  if ! grep -Fq ".github/workflows/forge-compliance.yml" "$COMPLIANCE_DOC"; then
    echo "    workflow file cross-link missing in docs/COMPLIANCE.md" >&2; return 1
  fi
  if ! grep -Fq "forge-compliance-workflow.md" "$COMPLIANCE_DOC"; then
    echo "    standard cross-link missing in docs/COMPLIANCE.md" >&2; return 1
  fi
  if ! grep -Fq "uses:" "$COMPLIANCE_DOC"; then
    echo "    copy-pasteable 'uses:' YAML block missing in docs/COMPLIANCE.md" >&2; return 1
  fi
}

# FR-I5-CW-142 — CHANGELOG.md entry
_test_i5_016_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing: $CHANGELOG_MD" >&2; return 1
  fi
  if ! grep -Fq "i5-compliance-workflow" "$CHANGELOG_MD"; then
    echo "    'i5-compliance-workflow' reference missing in CHANGELOG.md" >&2; return 1
  fi
  if ! grep -Fq "forge-compliance.yml" "$CHANGELOG_MD"; then
    echo "    'forge-compliance.yml' phrase missing in CHANGELOG.md" >&2; return 1
  fi
}

# ─── L2 tests (opt-in act run, skip-when-absent per ADR-I5-CW-003) ─

# FR-I5-CW-117 / NFR-I5-CW-009 — gated act run, skip-pass otherwise
_test_i5_l2_act_workflow_call() {
  if [ "${FORGE_I5_ACT:-0}" != "1" ]; then
    echo "    [INFO: L2 act run gated by FORGE_I5_ACT=1, skipping]" >&2
    return 0
  fi
  if ! command -v act >/dev/null 2>&1; then
    echo "    [INFO: act not installed on PATH, skipping]" >&2
    return 0
  fi
  # Best-effort smoke : run act against the live workflow. We do NOT
  # assert deeply on output ; exit 0 is the contract.
  local out rc
  out="$(act workflow_call \
    -W "$WORKFLOW_YML" \
    --input eu-tier=T2 \
    --input target-dir=. \
    --input artefact-name=forge-compliance-artefacts \
    2>&1)"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    act invocation failed (rc=$rc) — first 20 lines :" >&2
    printf '%s\n' "$out" | head -20 | sed 's/^/      /' >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── I.5 — i5-compliance-workflow — level $LEVEL ──"

  # L1 always runs.
  run_test _test_i5_001_workflow_presence
  run_test _test_i5_002_workflow_yaml_parses
  run_test _test_i5_003_workflow_audit_comment
  run_test _test_i5_004_on_workflow_call
  run_test _test_i5_005_inputs_schema
  run_test _test_i5_006_outputs_schema
  run_test _test_i5_007_step_invocations
  run_test _test_i5_008_action_pins
  run_test _test_i5_009_standard_presence
  run_test _test_i5_010_standard_frontmatter
  run_test _test_i5_011_standard_h2_sections
  run_test _test_i5_012_standard_must_not
  run_test _test_i5_013_index_entry
  run_test _test_i5_014_review_entry
  run_test _test_i5_015_compliance_doc_h2
  run_test _test_i5_016_changelog_entry

  # L2 runs when --level includes 2 or "all".
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — act-runner workflow_call (opt-in FORGE_I5_ACT=1)"
    run_test _test_i5_l2_act_workflow_call
  fi

  print_summary
}

main "$@"
