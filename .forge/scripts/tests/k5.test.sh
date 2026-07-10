#!/usr/bin/env bash
# Forge — K.5 Themis Test Harness (k5-themis)
# <!-- Audit: K.5 (k5-themis) -->
#
# Validates the K.5 deliverables across 3 sub-modules :
#
#   K.5.a — Themis persona file
#     - .claude/agents/themis.md (persona, boundary-vs-Demeter,
#       checklists, output, rules, integration, anti-hallucination)
#
#   K.5.b — forge review-standards CLI
#     - bin/forge-review-standards.sh (bash thin + Python 3 inline)
#
#   K.5.c — Standards + workflow + dispatch integration
#     - .forge/standards/global/standards-review-rules.md
#     - .forge/standards/index.yml (registration)
#     - .forge/standards/global/standards-lifecycle.md (Themis delta)
#     - .github/workflows/forge-standards-review.yml (sibling workflow)
#     - CLAUDE.md + docs/GUIDE.md + docs/COMPLIANCE.md rows/sections
#
# 25 L1 hermetic + 2 L2 fixture-based = 27 tests.
# Performance : L1 ≤ 5 s, full ≤ 20 s wall-clock (NFR-K5-THE-001).

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

THEMIS_AGENT="$FORGE_ROOT_REAL/.claude/agents/themis.md"
DEMETER_AGENT="$FORGE_ROOT_REAL/.claude/agents/demeter.md"
REVIEW_CLI="$FORGE_ROOT_REAL/bin/forge-review-standards.sh"
DEMETER_SCAN="$FORGE_ROOT_REAL/bin/forge-demeter-scan.sh"
STANDARDS_REVIEW_STD="$FORGE_ROOT_REAL/.forge/standards/global/standards-review-rules.md"
DATA_STEWARDSHIP_STD="$FORGE_ROOT_REAL/.forge/standards/global/data-stewardship-rules.md"
LIFECYCLE_STD="$FORGE_ROOT_REAL/.forge/standards/global/standards-lifecycle.md"
STANDARDS_INDEX="$FORGE_ROOT_REAL/.forge/standards/index.yml"
WORKFLOW_YML="$FORGE_ROOT_REAL/.github/workflows/forge-standards-review.yml"
REPO_CLAUDE_MD="$FORGE_ROOT_REAL/CLAUDE.md"
GUIDE_MD="$FORGE_ROOT_REAL/docs/GUIDE.md"
COMPLIANCE_DOC="$FORGE_ROOT_REAL/docs/COMPLIANCE.md"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (25 tests)
# MANIFEST: _test_k5_001_persona_exists            — FR-K5-THE-001 file presence
# MANIFEST: _test_k5_002_audit_comment             — FR-K5-THE-010 audit comment
# MANIFEST: _test_k5_003_persona_h2                — FR-K5-THE-002/003 Persona+Purpose
# MANIFEST: _test_k5_004_boundary_h2               — FR-K5-THE-004 Boundary vs Demeter
# MANIFEST: _test_k5_005_checklists_h2             — FR-K5-THE-005 Checklists + 3 H3
# MANIFEST: _test_k5_006_checklists_items          — FR-K5-THE-005 ≥ 5 [ ] per H3
# MANIFEST: _test_k5_007_output_h2                 — FR-K5-THE-006 Output report + table
# MANIFEST: _test_k5_008_rule_catalogue            — FR-K5-THE-007/070..074 K5-RULE-001..005
# MANIFEST: _test_k5_009_integration               — FR-K5-THE-008 Integration H2
# MANIFEST: _test_k5_010_anti_halluc               — FR-K5-THE-009 Anti-Hallucination
# MANIFEST: _test_k5_011_cli_signature             — FR-K5-THE-020 CLI signature
# MANIFEST: _test_k5_012_cli_help_exit0            — FR-K5-THE-035 --help exit 0
# MANIFEST: _test_k5_013_cli_bogus_exit2           — FR-K5-THE-035 bogus arg exit 2
# MANIFEST: _test_k5_014_cli_empty_tree_exit2      — FR-K5-THE-036 no standards → exit 2
# MANIFEST: _test_k5_015_cli_regulatory_verbatim   — FR-K5-THE-027 verbatim dates
# MANIFEST: _test_k5_016_standard_exists           — FR-K5-THE-050 standards-review-rules.md
# MANIFEST: _test_k5_017_index_registered          — FR-K5-THE-051 index entry
# MANIFEST: _test_k5_018_lifecycle_updated         — FR-K5-THE-052 lifecycle Themis delta
# MANIFEST: _test_k5_019_workflow_presence         — FR-K5-THE-060/061/063 workflow
# MANIFEST: _test_k5_020_workflow_invocation       — FR-K5-THE-062 workflow invokes CLI
# MANIFEST: _test_k5_021_claude_md_trigger         — FR-K5-THE-053 CLAUDE.md row
# MANIFEST: _test_k5_022_guide_row                 — FR-K5-THE-054 GUIDE.md row
# MANIFEST: _test_k5_023_compliance_doc_h2         — FR-K5-THE-055 COMPLIANCE.md H2
# MANIFEST: _test_k5_024_no_namespace_collision    — FR-K5-THE-086 K5-RULE / K3-RULE
# MANIFEST: _test_k5_025_changelog_entry           — FR-K5-THE-111 CHANGELOG entry
#
# L2 (2 fixture tests)
# MANIFEST: _test_k5_l2_expired               — FR-K5-THE-102 REVIEW-DUE on expired
# MANIFEST: _test_k5_l2_clean_deterministic   — FR-K5-THE-102 / NFR-K5-THE-005 CLEARED + reproducible

# ─── Helpers ────────────────────────────────────────────────────

_setup_l2() {
  L2_TMP="$(mk_tmpdir_with_trap forge-k5-l2)"
}

_teardown_l2() {
  if [ -n "${L2_TMP:-}" ] && [ -d "$L2_TMP" ]; then
    rm -rf "$L2_TMP"
  fi
}

_not_implemented() {
  echo "    not implemented (RED witness — pending implementation tasks)" >&2
  return 1
}

# ─── L1 tests ───────────────────────────────────────────────────

# FR-K5-THE-001 Themis persona file exists
_test_k5_001_persona_exists() {
  if [ ! -f "$THEMIS_AGENT" ]; then
    echo "    persona file missing: $THEMIS_AGENT" >&2; return 1
  fi
}

# FR-K5-THE-010 audit comment at top of file
_test_k5_002_audit_comment() {
  if [ ! -f "$THEMIS_AGENT" ]; then
    echo "    persona file missing: $THEMIS_AGENT" >&2; return 1
  fi
  if ! head -5 "$THEMIS_AGENT" | grep -q "<!-- Audit: K.5 (k5-themis) -->"; then
    echo "    audit comment missing in first 5 lines of $THEMIS_AGENT" >&2; return 1
  fi
}

# FR-K5-THE-002/003 ## Persona + ## Purpose H2 anchors
_test_k5_003_persona_h2() {
  if [ ! -f "$THEMIS_AGENT" ]; then
    echo "    persona file missing: $THEMIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Persona$" "$THEMIS_AGENT"; then
    echo "    ## Persona H2 missing" >&2; return 1
  fi
  if ! grep -q "^## Purpose$" "$THEMIS_AGENT"; then
    echo "    ## Purpose H2 missing" >&2; return 1
  fi
}

# FR-K5-THE-004 ## Boundary — Themis vs Demeter (load-bearing)
_test_k5_004_boundary_h2() {
  if [ ! -f "$THEMIS_AGENT" ]; then
    echo "    persona file missing: $THEMIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Boundary — Themis vs Demeter$" "$THEMIS_AGENT"; then
    echo "    ## Boundary — Themis vs Demeter H2 missing" >&2; return 1
  fi
  if ! grep -q "scaffold-time" "$THEMIS_AGENT"; then
    echo "    'scaffold-time' boundary term missing" >&2; return 1
  fi
  if ! grep -q "repo-lifecycle-time" "$THEMIS_AGENT"; then
    echo "    'repo-lifecycle-time' boundary term missing" >&2; return 1
  fi
}

# FR-K5-THE-005 ## Checklists + 3 H3 sub-sections
_test_k5_005_checklists_h2() {
  if [ ! -f "$THEMIS_AGENT" ]; then
    echo "    persona file missing: $THEMIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Checklists$" "$THEMIS_AGENT"; then
    echo "    ## Checklists H2 missing" >&2; return 1
  fi
  if ! grep -q "^### Standards Review Cadence$" "$THEMIS_AGENT"; then
    echo "    ### Standards Review Cadence H3 missing" >&2; return 1
  fi
  if ! grep -q "^### Regulatory Deadlines$" "$THEMIS_AGENT"; then
    echo "    ### Regulatory Deadlines H3 missing" >&2; return 1
  fi
  if ! grep -q "^### Compliance Bundle Automation$" "$THEMIS_AGENT"; then
    echo "    ### Compliance Bundle Automation H3 missing" >&2; return 1
  fi
}

# FR-K5-THE-005 ≥ 5 [ ] items per checklist sub-section
_test_k5_006_checklists_items() {
  if [ ! -f "$THEMIS_AGENT" ]; then
    echo "    persona file missing: $THEMIS_AGENT" >&2; return 1
  fi
  for section in "Standards Review Cadence" "Regulatory Deadlines" "Compliance Bundle Automation"; do
    local count
    count="$(awk -v s="### $section" '
      $0 == s {flag=1; next}
      /^### / {flag=0}
      /^## / {flag=0}
      flag && /\[ \]/ {n++}
      END {print n+0}
    ' "$THEMIS_AGENT")"
    if [ "$count" -lt 5 ]; then
      echo "    H3 '$section' has only $count '[ ]' items (expected ≥ 5)" >&2; return 1
    fi
  done
}

# FR-K5-THE-006 ## Output: Standards Review Report + Summary table
_test_k5_007_output_h2() {
  if [ ! -f "$THEMIS_AGENT" ]; then
    echo "    persona file missing: $THEMIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Output: Standards Review Report$" "$THEMIS_AGENT"; then
    echo "    ## Output: Standards Review Report H2 missing" >&2; return 1
  fi
  if ! grep -q "| Severity |" "$THEMIS_AGENT"; then
    echo "    Severity summary table missing" >&2; return 1
  fi
}

# FR-K5-THE-007 / 070..074 ## Rule Catalogue + K5-RULE-001..005
_test_k5_008_rule_catalogue() {
  if [ ! -f "$THEMIS_AGENT" ]; then
    echo "    persona file missing: $THEMIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Rule Catalogue$" "$THEMIS_AGENT"; then
    echo "    ## Rule Catalogue H2 missing" >&2; return 1
  fi
  for rule in K5-RULE-001 K5-RULE-002 K5-RULE-003 K5-RULE-004 K5-RULE-005; do
    if ! grep -q "$rule" "$THEMIS_AGENT"; then
      echo "    $rule anchor missing" >&2; return 1
    fi
  done
}

# FR-K5-THE-008 ## Integration + forge review-standards + bundle drive
_test_k5_009_integration() {
  if [ ! -f "$THEMIS_AGENT" ]; then
    echo "    persona file missing: $THEMIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Integration$" "$THEMIS_AGENT"; then
    echo "    ## Integration H2 missing" >&2; return 1
  fi
  if ! grep -q "forge review-standards" "$THEMIS_AGENT"; then
    echo "    forge review-standards reference missing" >&2; return 1
  fi
  if ! grep -q "bundle.sh" "$THEMIS_AGENT"; then
    echo "    I.6 bundle.sh drive reference missing" >&2; return 1
  fi
}

# FR-K5-THE-009 ## Anti-Hallucination Protocol
_test_k5_010_anti_halluc() {
  if [ ! -f "$THEMIS_AGENT" ]; then
    echo "    persona file missing: $THEMIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Anti-Hallucination Protocol$" "$THEMIS_AGENT"; then
    echo "    ## Anti-Hallucination Protocol H2 missing" >&2; return 1
  fi
  if ! grep -q "\[NEEDS CLARIFICATION:" "$THEMIS_AGENT"; then
    echo "    [NEEDS CLARIFICATION: marker mention missing" >&2; return 1
  fi
}

# FR-K5-THE-020 bin/forge-review-standards.sh exists + signature
_test_k5_011_cli_signature() {
  if [ ! -f "$REVIEW_CLI" ]; then
    echo "    CLI missing: $REVIEW_CLI" >&2; return 1
  fi
  if [ ! -x "$REVIEW_CLI" ]; then
    echo "    CLI not executable: $REVIEW_CLI" >&2; return 1
  fi
  if ! head -3 "$REVIEW_CLI" | grep -q "^#!/usr/bin/env bash$"; then
    echo "    CLI missing bash shebang" >&2; return 1
  fi
  if ! grep -q "set -uo pipefail" "$REVIEW_CLI"; then
    echo "    CLI missing 'set -uo pipefail'" >&2; return 1
  fi
  for flag in "--target" "--window" "--output" "--format" "--bundle" "--strict"; do
    if ! grep -q -- "$flag" "$REVIEW_CLI"; then
      echo "    CLI missing flag: $flag" >&2; return 1
    fi
  done
}

# FR-K5-THE-035 --help exits 0 + Usage:
_test_k5_012_cli_help_exit0() {
  if [ ! -x "$REVIEW_CLI" ]; then
    echo "    CLI not executable: $REVIEW_CLI" >&2; return 1
  fi
  local out rc
  out="$(bash "$REVIEW_CLI" --help 2>&1)"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    --help expected exit 0, got $rc" >&2; return 1
  fi
  if ! printf '%s' "$out" | grep -Fq "Usage:"; then
    echo "    --help output missing 'Usage:'" >&2; return 1
  fi
}

# FR-K5-THE-035 bogus arg exits 2
_test_k5_013_cli_bogus_exit2() {
  if [ ! -x "$REVIEW_CLI" ]; then
    echo "    CLI not executable: $REVIEW_CLI" >&2; return 1
  fi
  bash "$REVIEW_CLI" --bogus-arg-that-does-not-exist >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -ne 2 ]; then
    echo "    bogus arg expected exit 2, got $rc" >&2; return 1
  fi
}

# FR-K5-THE-036 no .forge/standards/ in target → exit 2
_test_k5_014_cli_empty_tree_exit2() {
  if [ ! -x "$REVIEW_CLI" ]; then
    echo "    CLI not executable: $REVIEW_CLI" >&2; return 1
  fi
  local tmp
  tmp="$(mktemp -d -t forge-k5-l1-empty-XXXXXX)"
  trap "rm -rf '$tmp'" RETURN
  bash "$REVIEW_CLI" --target "$tmp" --output "$tmp/out.json" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -ne 2 ]; then
    echo "    empty-tree target expected exit 2, got $rc" >&2; return 1
  fi
}

# FR-K5-THE-027 CLI carries the verbatim regulatory calendar
_test_k5_015_cli_regulatory_verbatim() {
  if [ ! -f "$REVIEW_CLI" ]; then
    echo "    CLI missing: $REVIEW_CLI" >&2; return 1
  fi
  for needle in "24h/72h" "30 avr 2026" "11 sept 2026" "11 déc 2027"; do
    if ! grep -Fq "$needle" "$REVIEW_CLI"; then
      echo "    verbatim regulatory token missing: $needle" >&2; return 1
    fi
  done
}

# FR-K5-THE-050 standard exists with ≥ 5 H2 sections
_test_k5_016_standard_exists() {
  if [ ! -f "$STANDARDS_REVIEW_STD" ]; then
    echo "    standard missing: $STANDARDS_REVIEW_STD" >&2; return 1
  fi
  local h2_count
  h2_count="$(grep -cE '^## ' "$STANDARDS_REVIEW_STD")"
  if [ "$h2_count" -lt 5 ]; then
    echo "    expected ≥ 5 H2 in $STANDARDS_REVIEW_STD, got $h2_count" >&2; return 1
  fi
}

# FR-K5-THE-051 standards/index.yml registers standards-review-rules
_test_k5_017_index_registered() {
  if [ ! -f "$STANDARDS_INDEX" ]; then
    echo "    standards index missing: $STANDARDS_INDEX" >&2; return 1
  fi
  if ! grep -q "id: global/standards-review-rules" "$STANDARDS_INDEX"; then
    echo "    standards-review-rules entry missing" >&2; return 1
  fi
  for trig in "themis" "review-standards" "nis2" "dora" "cra" "ai-act" "k5-rule"; do
    if ! grep -A 6 "id: global/standards-review-rules" "$STANDARDS_INDEX" | grep -q "$trig"; then
      echo "    trigger '$trig' missing on standards-review-rules entry" >&2; return 1
    fi
  done
}

# FR-K5-THE-052 standards-lifecycle.md Themis section updated to shipped
_test_k5_018_lifecycle_updated() {
  if [ ! -f "$LIFECYCLE_STD" ]; then
    echo "    standards-lifecycle.md missing: $LIFECYCLE_STD" >&2; return 1
  fi
  # Themis section now references the shipped CLI.
  if ! grep -q "forge-review-standards.sh" "$LIFECYCLE_STD"; then
    echo "    lifecycle Themis section not updated (forge-review-standards.sh reference missing)" >&2; return 1
  fi
  # Structural-exception table MUST remain intact (t4.test.sh::_test_t4_025).
  if ! grep -qF "transport.yaml" "$LIFECYCLE_STD"; then
    echo "    structural-exception table broken: transport.yaml missing" >&2; return 1
  fi
  if ! grep -qF "state-management.yaml" "$LIFECYCLE_STD"; then
    echo "    structural-exception table broken: state-management.yaml missing" >&2; return 1
  fi
}

# FR-K5-THE-060/061/063 sibling workflow presence + triggers + permissions
_test_k5_019_workflow_presence() {
  if [ ! -f "$WORKFLOW_YML" ]; then
    echo "    workflow missing: $WORKFLOW_YML" >&2; return 1
  fi
  if ! python3 -c "import yaml,sys; yaml.safe_load(open('$WORKFLOW_YML'))" 2>/dev/null; then
    echo "    workflow is not valid YAML" >&2; return 1
  fi
  if ! grep -q "schedule:" "$WORKFLOW_YML"; then
    echo "    workflow missing schedule: trigger" >&2; return 1
  fi
  if ! grep -q "workflow_call:" "$WORKFLOW_YML"; then
    echo "    workflow missing workflow_call: trigger" >&2; return 1
  fi
  if ! grep -q "contents: read" "$WORKFLOW_YML"; then
    echo "    workflow missing 'contents: read' permission" >&2; return 1
  fi
}

# FR-K5-THE-062 workflow invokes the CLI
_test_k5_020_workflow_invocation() {
  if [ ! -f "$WORKFLOW_YML" ]; then
    echo "    workflow missing: $WORKFLOW_YML" >&2; return 1
  fi
  if ! grep -q "forge-review-standards.sh" "$WORKFLOW_YML"; then
    echo "    workflow does not invoke forge-review-standards.sh" >&2; return 1
  fi
}

# FR-K5-THE-053 repo CLAUDE.md trigger row contains Themis
_test_k5_021_claude_md_trigger() {
  if [ ! -f "$REPO_CLAUDE_MD" ]; then
    echo "    repo CLAUDE.md missing" >&2; return 1
  fi
  if ! grep -q "| Regulatory compliance | \*\*Themis\*\* | Compliance Officer EU |" "$REPO_CLAUDE_MD"; then
    echo "    Themis trigger row missing in CLAUDE.md" >&2; return 1
  fi
}

# FR-K5-THE-054 docs/GUIDE.md transversal agents table contains Themis
_test_k5_022_guide_row() {
  if [ ! -f "$GUIDE_MD" ]; then
    echo "    docs/GUIDE.md missing" >&2; return 1
  fi
  if ! grep -q "Themis" "$GUIDE_MD"; then
    echo "    Themis row missing in docs/GUIDE.md" >&2; return 1
  fi
  if ! grep -q "Compliance Officer EU" "$GUIDE_MD"; then
    echo "    'Compliance Officer EU' role missing in docs/GUIDE.md" >&2; return 1
  fi
}

# FR-K5-THE-055 docs/COMPLIANCE.md Themis H2
_test_k5_023_compliance_doc_h2() {
  if [ ! -f "$COMPLIANCE_DOC" ]; then
    echo "    docs/COMPLIANCE.md missing" >&2; return 1
  fi
  if ! grep -q "^## Standards review cadence (Themis)$" "$COMPLIANCE_DOC"; then
    echo "    '## Standards review cadence (Themis)' H2 missing" >&2; return 1
  fi
  if ! grep -q "forge review-standards" "$COMPLIANCE_DOC"; then
    echo "    forge review-standards reference missing in COMPLIANCE.md" >&2; return 1
  fi
}

# FR-K5-THE-086 K5-RULE / K3-RULE namespace non-collision
# Caveat (mirrors k3.test.sh::_test_k3_020) : a standard doc MAY cite a
# sibling rule namespace as a bounded cross-reference (the ADR-J8-004
# <MODULE>-RULE-NNN family is deliberately documented together). Rule-body
# / code leakage into the other module's SCRIPT is the real bleed the
# guard blocks ; a handful of sibling cross-references in the standard
# prose is permitted (k3.test.sh allows ≤ 2 K3-RULE in the J.8 standard).
_test_k5_024_no_namespace_collision() {
  # K5-RULE must NOT bleed into Demeter's scanner (real code bleed).
  if [ -f "$DEMETER_SCAN" ] && grep -q "K5-RULE" "$DEMETER_SCAN" 2>/dev/null; then
    echo "    K5-RULE leaked into $DEMETER_SCAN" >&2; return 1
  fi
  # K5-RULE must NOT bleed into Demeter's standard rule catalogue.
  if [ -f "$DATA_STEWARDSHIP_STD" ] && grep -q "K5-RULE" "$DATA_STEWARDSHIP_STD" 2>/dev/null; then
    echo "    K5-RULE leaked into $DATA_STEWARDSHIP_STD" >&2; return 1
  fi
  # K3-RULE must NOT appear in the Themis CLI (real code bleed).
  if [ -f "$REVIEW_CLI" ] && grep -q "K3-RULE" "$REVIEW_CLI" 2>/dev/null; then
    echo "    K3-RULE leaked into $REVIEW_CLI" >&2; return 1
  fi
  # The Themis standard MAY cite K3-RULE as a bounded sibling
  # cross-reference (namespace-disjointness prose) ; assert ≤ 2.
  if [ -f "$STANDARDS_REVIEW_STD" ]; then
    local n
    n="$(grep -c "K3-RULE" "$STANDARDS_REVIEW_STD" 2>/dev/null || echo 0)"
    if [ "$n" -gt 2 ]; then
      echo "    K3-RULE over-cited in $STANDARDS_REVIEW_STD ($n hits, expected ≤ 2 sibling cross-references)" >&2; return 1
    fi
  fi
}

# FR-K5-THE-111 CHANGELOG entry
_test_k5_025_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing" >&2; return 1
  fi
  if ! grep -Fq "k5-themis" "$CHANGELOG_MD"; then
    echo "    'k5-themis' reference missing in CHANGELOG.md" >&2; return 1
  fi
  if ! grep -Fq "review-standards" "$CHANGELOG_MD"; then
    echo "    'review-standards' phrase missing in CHANGELOG.md" >&2; return 1
  fi
}

# ─── L2 fixture tests ────────────────────────────────────────────

# FR-K5-THE-102 — expired standard → REVIEW-DUE + K5-RULE-001 Medium
_test_k5_l2_expired() {
  _setup_l2
  trap '_teardown_l2' RETURN
  mkdir -p "$L2_TMP/.forge/standards/global"
  # Expired MD standard (fenced yaml frontmatter, long past).
  cat > "$L2_TMP/.forge/standards/global/stale-standard.md" <<'MD'
# Standard — Stale Fixture

```yaml
version: 1.0.0
last_reviewed: 2020-01-01
expires_at: 2021-01-01
exception_constitutional: false
```

Body.
MD
  # Fresh YAML standard (far future).
  cat > "$L2_TMP/.forge/standards/fresh.yaml" <<'YML'
version: 1.0.0
last_reviewed: 2026-01-01
expires_at: 2099-01-01
exception_constitutional: false
YML
  # Structural exception (never / constitutional).
  cat > "$L2_TMP/.forge/standards/structural.yaml" <<'YML'
version: 1.0.0
last_reviewed: 2026-01-01
expires_at: never
exception_constitutional: true
YML
  bash "$REVIEW_CLI" --target "$L2_TMP" --format json \
    --output "$L2_TMP/report.json" >/dev/null 2>&1
  local rc=$?
  assert_eq "1" "$rc" "expired fixture expected exit 1 (REVIEW-DUE)" || return 1
  if [ ! -f "$L2_TMP/report.json" ]; then
    echo "    report.json not produced" >&2; return 1
  fi
  local content; content="$(cat "$L2_TMP/report.json")"
  assert_contains "$content" '"overall_status": "REVIEW-DUE"' || return 1
  assert_contains "$content" '"rule_id": "K5-RULE-001"' || return 1
  assert_contains "$content" '"severity": "Medium"' || return 1
  assert_contains "$content" 'stale-standard.md' || return 1
  # Structural exception must NOT be flagged.
  if printf '%s' "$content" | grep -q 'structural.yaml.*EXPIRED'; then
    echo "    structural exception wrongly flagged EXPIRED" >&2; return 1
  fi
}

# FR-K5-THE-102 / NFR-K5-THE-005 — clean tree → CLEARED + reproducible
_test_k5_l2_clean_deterministic() {
  _setup_l2
  trap '_teardown_l2' RETURN
  mkdir -p "$L2_TMP/.forge/standards/global"
  cat > "$L2_TMP/.forge/standards/fresh-a.yaml" <<'YML'
version: 1.0.0
last_reviewed: 2026-01-01
expires_at: 2099-01-01
exception_constitutional: false
YML
  cat > "$L2_TMP/.forge/standards/global/fresh-b.md" <<'MD'
# Standard — Fresh B

```yaml
version: 1.0.0
last_reviewed: 2026-01-01
expires_at: 2099-01-01
exception_constitutional: false
```
MD
  cat > "$L2_TMP/.forge/standards/structural.yaml" <<'YML'
version: 1.0.0
last_reviewed: 2026-01-01
expires_at: never
exception_constitutional: true
YML
  SOURCE_DATE_EPOCH=0 bash "$REVIEW_CLI" --target "$L2_TMP" --format json \
    --output "$L2_TMP/r1.json" >/dev/null 2>&1
  local rc1=$?
  SOURCE_DATE_EPOCH=0 bash "$REVIEW_CLI" --target "$L2_TMP" --format json \
    --output "$L2_TMP/r2.json" >/dev/null 2>&1
  local rc2=$?
  assert_eq "0" "$rc1" "clean run #1 expected exit 0 (CLEARED)" || return 1
  assert_eq "0" "$rc2" "clean run #2 expected exit 0 (CLEARED)" || return 1
  local content; content="$(cat "$L2_TMP/r1.json")"
  assert_contains "$content" '"overall_status": "CLEARED"' || return 1
  if ! diff -q "$L2_TMP/r1.json" "$L2_TMP/r2.json" >/dev/null 2>&1; then
    echo "    report not byte-identical between runs (NFR-K5-THE-005)" >&2
    diff "$L2_TMP/r1.json" "$L2_TMP/r2.json" | head -10 >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── K.5 — k5-themis harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — persona + CLI + standard + workflow + integration anchors"
  run_test _test_k5_001_persona_exists
  run_test _test_k5_002_audit_comment
  run_test _test_k5_003_persona_h2
  run_test _test_k5_004_boundary_h2
  run_test _test_k5_005_checklists_h2
  run_test _test_k5_006_checklists_items
  run_test _test_k5_007_output_h2
  run_test _test_k5_008_rule_catalogue
  run_test _test_k5_009_integration
  run_test _test_k5_010_anti_halluc
  run_test _test_k5_011_cli_signature
  run_test _test_k5_012_cli_help_exit0
  run_test _test_k5_013_cli_bogus_exit2
  run_test _test_k5_014_cli_empty_tree_exit2
  run_test _test_k5_015_cli_regulatory_verbatim
  run_test _test_k5_016_standard_exists
  run_test _test_k5_017_index_registered
  run_test _test_k5_018_lifecycle_updated
  run_test _test_k5_019_workflow_presence
  run_test _test_k5_020_workflow_invocation
  run_test _test_k5_021_claude_md_trigger
  run_test _test_k5_022_guide_row
  run_test _test_k5_023_compliance_doc_h2
  run_test _test_k5_024_no_namespace_collision
  run_test _test_k5_025_changelog_entry

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based CLI runs"
    run_test _test_k5_l2_expired
    run_test _test_k5_l2_clean_deterministic
  fi

  print_summary
}

main "$@"
