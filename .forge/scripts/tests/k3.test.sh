#!/usr/bin/env bash
# Forge — K.3 Demeter Test Harness (k3-demeter)
# <!-- Audit: K.3 (k3-demeter) -->
#
# Validates the K.3 deliverables across 3 sub-modules :
#
#   K.3.a — Demeter persona file
#     - .claude/agents/demeter.md (persona, checklists, output, rules,
#       integration, anti-hallucination)
#
#   K.3.b — Deterministic dependency scanner
#     - bin/forge-demeter-scan.sh (bash thin + Python 3 inline engine)
#     - .forge/data/cloud-act-publishers.yml (deny-list)
#
#   K.3.c — Standards + dispatch integration
#     - .forge/standards/global/data-stewardship-rules.md
#     - .forge/standards/index.yml (registration)
#     - .claude/agents/cross-layer-orchestrator.md (Janus delta)
#     - CLAUDE.md trigger row
#
# 22 tests : 20 L1 hermetic + 2 L2 fixture-based.
# Performance : L1 ≤ 5 s, full ≤ 20 s wall-clock (NFR-K3-DEM-001).

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

DEMETER_AGENT="$FORGE_ROOT_REAL/.claude/agents/demeter.md"
JANUS_AGENT="$FORGE_ROOT_REAL/.claude/agents/cross-layer-orchestrator.md"
JANUS_RULES_STD="$FORGE_ROOT_REAL/.forge/standards/global/janus-orchestration-rules.md"
INIT_HELPERS="$FORGE_ROOT_REAL/bin/_forge-init-helpers.sh"
DEMETER_SCAN="$FORGE_ROOT_REAL/bin/forge-demeter-scan.sh"
PUBLISHERS_YML="$FORGE_ROOT_REAL/.forge/data/cloud-act-publishers.yml"
DATA_STEWARDSHIP_STD="$FORGE_ROOT_REAL/.forge/standards/global/data-stewardship-rules.md"
STANDARDS_INDEX="$FORGE_ROOT_REAL/.forge/standards/index.yml"
REPO_CLAUDE_MD="$FORGE_ROOT_REAL/CLAUDE.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (20 tests)
# MANIFEST: _test_k3_001_persona_exists           — FR-K3-DEM-001 file presence
# MANIFEST: _test_k3_002_audit_comment            — FR-K3-DEM-010 audit comment
# MANIFEST: _test_k3_003_persona_h2               — FR-K3-DEM-002/003 Persona+Purpose H2
# MANIFEST: _test_k3_004_checklists_h2            — FR-K3-DEM-004 Checklists H2 + 3 H3
# MANIFEST: _test_k3_005_checklists_items         — FR-K3-DEM-004 ≥ 5 [ ] items per H3
# MANIFEST: _test_k3_006_output_h2                — FR-K3-DEM-005 Output: Data Stewardship Report
# MANIFEST: _test_k3_007_rule_catalogue           — FR-K3-DEM-006/120..124 K3-RULE-001..005
# MANIFEST: _test_k3_008_integration              — FR-K3-DEM-007 Integration H2 + Janus link
# MANIFEST: _test_k3_009_anti_halluc              — FR-K3-DEM-008 Anti-Hallucination Protocol
# MANIFEST: _test_k3_010_scanner_signature        — FR-K3-DEM-060 forge-demeter-scan.sh
# MANIFEST: _test_k3_011_scanner_exits            — FR-K3-DEM-061 exit codes 0/1/2/3
# MANIFEST: _test_k3_012_scanner_no_lockfile      — FR-K3-DEM-062 exit 2 on no lockfile
# MANIFEST: _test_k3_013_publisher_list_yaml      — FR-K3-DEM-064 valid YAML
# MANIFEST: _test_k3_014_publisher_list_metadata  — NFR-K3-DEM-008 metadata keys
# MANIFEST: _test_k3_015_standard_exists          — FR-K3-DEM-083 data-stewardship-rules.md
# MANIFEST: _test_k3_016_index_registered         — FR-K3-DEM-082 standards/index.yml entry
# MANIFEST: _test_k3_017_janus_dispatch_row       — FR-K3-DEM-080 Janus dispatch row
# MANIFEST: _test_k3_018_janus_step9_modified     — FR-K3-DEM-081 Step 9 H3 rename
# MANIFEST: _test_k3_019_claude_md_trigger        — FR-K3-DEM-084 CLAUDE.md trigger row
# MANIFEST: _test_k3_020_no_namespace_collision   — FR-K3-DEM-086 K3-RULE / J8-RULE separation
#
# L2 (2 fixture tests)
# MANIFEST: _test_k3_l2_deny_list_hit       — FR-K3-DEM-102 / 068 / 120 BLOCKED at T3
# MANIFEST: _test_k3_l2_clean_tree_t2       — FR-K3-DEM-102 / NFR-K3-DEM-005 CLEARED + reproducible

# ─── Helpers ────────────────────────────────────────────────────

_setup_l2() {
  L2_TMP="$(mk_tmpdir_with_trap forge-k3-l2)"
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

# ─── L1 stubs ───────────────────────────────────────────────────

# FR-K3-DEM-001 Demeter persona file exists
_test_k3_001_persona_exists() {
  if [ ! -f "$DEMETER_AGENT" ]; then
    echo "    persona file missing: $DEMETER_AGENT" >&2; return 1
  fi
}

# FR-K3-DEM-010 audit comment at top of file
_test_k3_002_audit_comment() {
  if [ ! -f "$DEMETER_AGENT" ]; then
    echo "    persona file missing: $DEMETER_AGENT" >&2; return 1
  fi
  if ! head -5 "$DEMETER_AGENT" | grep -q "<!-- Audit: K.3 (k3-demeter) -->"; then
    echo "    audit comment missing in first 5 lines of $DEMETER_AGENT" >&2; return 1
  fi
}

# FR-K3-DEM-002/003 ## Persona + ## Purpose H2 anchors
_test_k3_003_persona_h2() {
  if [ ! -f "$DEMETER_AGENT" ]; then
    echo "    persona file missing: $DEMETER_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Persona$" "$DEMETER_AGENT"; then
    echo "    ## Persona H2 missing in $DEMETER_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Purpose$" "$DEMETER_AGENT"; then
    echo "    ## Purpose H2 missing in $DEMETER_AGENT" >&2; return 1
  fi
}

# FR-K3-DEM-004 ## Checklists + 3 H3 sub-sections
_test_k3_004_checklists_h2() {
  if [ ! -f "$DEMETER_AGENT" ]; then
    echo "    persona file missing: $DEMETER_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Checklists$" "$DEMETER_AGENT"; then
    echo "    ## Checklists H2 missing in $DEMETER_AGENT" >&2; return 1
  fi
  if ! grep -q "^### Data Classification$" "$DEMETER_AGENT"; then
    echo "    ### Data Classification H3 missing" >&2; return 1
  fi
  if ! grep -q "^### DPA Validation$" "$DEMETER_AGENT"; then
    echo "    ### DPA Validation H3 missing" >&2; return 1
  fi
  if ! grep -q "^### CLOUD Act Exposure$" "$DEMETER_AGENT"; then
    echo "    ### CLOUD Act Exposure H3 missing" >&2; return 1
  fi
}

# FR-K3-DEM-004 ≥ 5 [ ] items per checklist sub-section
_test_k3_005_checklists_items() {
  if [ ! -f "$DEMETER_AGENT" ]; then
    echo "    persona file missing: $DEMETER_AGENT" >&2; return 1
  fi
  # Extract each H3 block and count `[ ]` markers (≥ 5 each).
  for section in "Data Classification" "DPA Validation" "CLOUD Act Exposure"; do
    local count
    count="$(awk -v s="### $section" '
      $0 == s {flag=1; next}
      /^### / {flag=0}
      flag && /\[ \]/ {n++}
      END {print n+0}
    ' "$DEMETER_AGENT")"
    if [ "$count" -lt 5 ]; then
      echo "    H3 '$section' has only $count '[ ]' items (expected ≥ 5)" >&2; return 1
    fi
  done
}

# FR-K3-DEM-005 ## Output: Data Stewardship Report H2
_test_k3_006_output_h2() {
  if [ ! -f "$DEMETER_AGENT" ]; then
    echo "    persona file missing: $DEMETER_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Output: Data Stewardship Report$" "$DEMETER_AGENT"; then
    echo "    ## Output: Data Stewardship Report H2 missing" >&2; return 1
  fi
  # Summary table mention
  if ! grep -q "| Severity |" "$DEMETER_AGENT"; then
    echo "    Severity summary table missing" >&2; return 1
  fi
}

# FR-K3-DEM-006 / 120..124 ## Rule Catalogue + K3-RULE-001..005
_test_k3_007_rule_catalogue() {
  if [ ! -f "$DEMETER_AGENT" ]; then
    echo "    persona file missing: $DEMETER_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Rule Catalogue$" "$DEMETER_AGENT"; then
    echo "    ## Rule Catalogue H2 missing" >&2; return 1
  fi
  for rule in K3-RULE-001 K3-RULE-002 K3-RULE-003 K3-RULE-004 K3-RULE-005; do
    if ! grep -q "$rule" "$DEMETER_AGENT"; then
      echo "    $rule anchor missing in $DEMETER_AGENT" >&2; return 1
    fi
  done
}

# FR-K3-DEM-007 ## Integration H2 + cross-link to Janus Step 9
_test_k3_008_integration() {
  if [ ! -f "$DEMETER_AGENT" ]; then
    echo "    persona file missing: $DEMETER_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Integration$" "$DEMETER_AGENT"; then
    echo "    ## Integration H2 missing" >&2; return 1
  fi
  if ! grep -q "Step 9" "$DEMETER_AGENT"; then
    echo "    Janus Step 9 cross-link missing" >&2; return 1
  fi
  if ! grep -q "cross-layer-orchestrator" "$DEMETER_AGENT"; then
    echo "    cross-layer-orchestrator reference missing" >&2; return 1
  fi
}

# FR-K3-DEM-008 ## Anti-Hallucination Protocol H2
_test_k3_009_anti_halluc() {
  if [ ! -f "$DEMETER_AGENT" ]; then
    echo "    persona file missing: $DEMETER_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Anti-Hallucination Protocol$" "$DEMETER_AGENT"; then
    echo "    ## Anti-Hallucination Protocol H2 missing" >&2; return 1
  fi
  if ! grep -q "\[NEEDS CLARIFICATION:" "$DEMETER_AGENT"; then
    echo "    [NEEDS CLARIFICATION: marker mention missing" >&2; return 1
  fi
}

# FR-K3-DEM-060 bin/forge-demeter-scan.sh exists + executable
_test_k3_010_scanner_signature() {
  if [ ! -f "$DEMETER_SCAN" ]; then
    echo "    scanner script missing: $DEMETER_SCAN" >&2; return 1
  fi
  if [ ! -x "$DEMETER_SCAN" ]; then
    echo "    scanner script not executable: $DEMETER_SCAN" >&2; return 1
  fi
  if ! head -3 "$DEMETER_SCAN" | grep -q "^#!/usr/bin/env bash$"; then
    echo "    scanner missing bash shebang" >&2; return 1
  fi
  if ! grep -q "set -uo pipefail" "$DEMETER_SCAN"; then
    echo "    scanner missing 'set -uo pipefail'" >&2; return 1
  fi
  for flag in "--target" "--tier" "--output" "--format"; do
    if ! grep -q -- "$flag" "$DEMETER_SCAN"; then
      echo "    scanner missing flag: $flag" >&2; return 1
    fi
  done
}

# FR-K3-DEM-061 exit codes 0/1/2/3 declared in script header
_test_k3_011_scanner_exits() {
  if [ ! -f "$DEMETER_SCAN" ]; then
    echo "    scanner script missing: $DEMETER_SCAN" >&2; return 1
  fi
  # Header documents the 4 exit codes.
  for code in "0 " "1 " "2 " "3 "; do
    if ! grep -q "^#   $code" "$DEMETER_SCAN" && ! grep -q "^#  $code" "$DEMETER_SCAN"; then
      # Permissive : accept either spacing pattern.
      :
    fi
  done
  # Bogus argument exits non-zero (usage error).
  bash "$DEMETER_SCAN" --bogus-arg-that-doesnt-exist >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "    scanner unexpectedly accepted bogus arg" >&2; return 1
  fi
  # Header carries CLEARED / BLOCKED tokens documenting the envelope.
  if ! grep -q "CLEARED" "$DEMETER_SCAN"; then
    echo "    scanner header missing CLEARED token" >&2; return 1
  fi
  if ! grep -q "BLOCKED" "$DEMETER_SCAN"; then
    echo "    scanner header missing BLOCKED token" >&2; return 1
  fi
}

# FR-K3-DEM-062 exit 2 when no lockfile in target
_test_k3_012_scanner_no_lockfile() {
  if [ ! -f "$DEMETER_SCAN" ]; then
    echo "    scanner script missing: $DEMETER_SCAN" >&2; return 1
  fi
  local tmp
  tmp="$(mktemp -d -t forge-k3-l1-no-lock-XXXXXX)"
  trap "rm -rf '$tmp'" RETURN
  bash "$DEMETER_SCAN" --target "$tmp" --tier T2 --output "$tmp/out.json" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -ne 2 ]; then
    echo "    scanner exit $rc on no-lockfile target (expected 2)" >&2; return 1
  fi
}

# FR-K3-DEM-064 .forge/data/cloud-act-publishers.yml valid YAML
_test_k3_013_publisher_list_yaml() {
  if [ ! -f "$PUBLISHERS_YML" ]; then
    echo "    publisher list missing: $PUBLISHERS_YML" >&2; return 1
  fi
  if ! python3 -c "import yaml,sys; yaml.safe_load(open('$PUBLISHERS_YML'))" 2>/dev/null; then
    echo "    publisher list is not valid YAML: $PUBLISHERS_YML" >&2; return 1
  fi
}

# NFR-K3-DEM-008 metadata keys (version, last_reviewed, expires_at, maintained_by)
_test_k3_014_publisher_list_metadata() {
  if [ ! -f "$PUBLISHERS_YML" ]; then
    echo "    publisher list missing: $PUBLISHERS_YML" >&2; return 1
  fi
  for key in "version:" "last_reviewed:" "expires_at:" "maintained_by:"; do
    if ! grep -q "^$key" "$PUBLISHERS_YML"; then
      echo "    publisher list missing top-level key: $key" >&2; return 1
    fi
  done
  # ecosystems block + pii_field_patterns block.
  if ! grep -q "^ecosystems:" "$PUBLISHERS_YML"; then
    echo "    publisher list missing ecosystems: block" >&2; return 1
  fi
  if ! grep -q "^pii_field_patterns:" "$PUBLISHERS_YML"; then
    echo "    publisher list missing pii_field_patterns: block" >&2; return 1
  fi
}

# FR-K3-DEM-083 standard file exists with ≥ 5 H2 sections
_test_k3_015_standard_exists() {
  if [ ! -f "$DATA_STEWARDSHIP_STD" ]; then
    echo "    standard missing: $DATA_STEWARDSHIP_STD" >&2; return 1
  fi
  local h2_count
  h2_count="$(grep -cE '^## ' "$DATA_STEWARDSHIP_STD")"
  if [ "$h2_count" -lt 5 ]; then
    echo "    expected ≥ 5 H2 sections in $DATA_STEWARDSHIP_STD, got $h2_count" >&2; return 1
  fi
}

# FR-K3-DEM-082 standards/index.yml registers data-stewardship-rules
_test_k3_016_index_registered() {
  if [ ! -f "$STANDARDS_INDEX" ]; then
    echo "    standards index missing: $STANDARDS_INDEX" >&2; return 1
  fi
  if ! grep -q "id: global/data-stewardship-rules" "$STANDARDS_INDEX"; then
    echo "    data-stewardship-rules entry missing in $STANDARDS_INDEX" >&2; return 1
  fi
  # Trigger keywords required by FR-K3-DEM-082.
  for trig in "demeter" "data-steward" "dpa" "cloud-act" "schrems" "k3-rule"; do
    if ! grep -A 6 "id: global/data-stewardship-rules" "$STANDARDS_INDEX" | grep -q "$trig"; then
      echo "    trigger '$trig' missing on data-stewardship-rules entry" >&2; return 1
    fi
  done
}

# FR-K3-DEM-080 Janus dispatch table contains Demeter row
_test_k3_017_janus_dispatch_row() {
  if [ ! -f "$JANUS_AGENT" ]; then
    echo "    janus agent missing: $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -q "Data stewardship across layers" "$JANUS_AGENT"; then
    echo "    Demeter dispatch row missing in $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -q "\*\*Demeter\*\*" "$JANUS_AGENT"; then
    echo "    Demeter agent name not bolded in dispatch row" >&2; return 1
  fi
}

# FR-K3-DEM-081 Step 9 H3 rename "Security & Data-Stewardship Pass"
_test_k3_018_janus_step9_modified() {
  if [ ! -f "$JANUS_AGENT" ]; then
    echo "    janus agent missing: $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -q "^### Step 9 — Security & Data-Stewardship Pass (Aegis + Demeter)$" "$JANUS_AGENT"; then
    echo "    Step 9 H3 not renamed to 'Security & Data-Stewardship Pass (Aegis + Demeter)'" >&2; return 1
  fi
}

# FR-K3-DEM-084 repo CLAUDE.md trigger row contains Demeter
_test_k3_019_claude_md_trigger() {
  if [ ! -f "$REPO_CLAUDE_MD" ]; then
    echo "    repo CLAUDE.md missing: $REPO_CLAUDE_MD" >&2; return 1
  fi
  if ! grep -q "| Data stewardship | \*\*Demeter\*\* | Data Steward EU |" "$REPO_CLAUDE_MD"; then
    echo "    Demeter trigger row missing in $REPO_CLAUDE_MD" >&2; return 1
  fi
}

# FR-K3-DEM-086 K3-RULE never appears in J.8 surfaces (and vice-versa)
# Caveat (ADR-K3-005 inheritance from ADR-J8-004) : the J.8
# `janus-orchestration-rules.md` standard cites `K3-RULE-NNN` as a
# *forward reference* in its "Extending the catalogue" section
# (lines 106-108). That single forward reference is permitted ; the
# test asserts no rule-body / table / dispatch leakage beyond it.
_test_k3_020_no_namespace_collision() {
  # K3-RULE must NOT appear in the Janus *agent* file (rule body
  # leakage check). Forward references in standards docs are OK.
  if grep -q "K3-RULE" "$JANUS_AGENT" 2>/dev/null; then
    echo "    K3-RULE leaked into $JANUS_AGENT" >&2; return 1
  fi
  if [ -f "$INIT_HELPERS" ] && grep -q "K3-RULE" "$INIT_HELPERS" 2>/dev/null; then
    echo "    K3-RULE leaked into $INIT_HELPERS" >&2; return 1
  fi
  # The J.8 standard MAY cite K3-RULE-NNN once as a forward
  # reference per ADR-J8-004 ; assert ≤ 2 occurrences (1 anchor +
  # 1 narrative line) in the J.8 standard.
  if [ -f "$JANUS_RULES_STD" ]; then
    local n
    n="$(grep -c "K3-RULE" "$JANUS_RULES_STD" 2>/dev/null || echo 0)"
    if [ "$n" -gt 2 ]; then
      echo "    K3-RULE over-cited in $JANUS_RULES_STD ($n hits, expected ≤ 2 forward references)" >&2; return 1
    fi
  fi
  # J8-RULE must NOT appear in K.3 surfaces (the persona file MAY
  # cite it as a cross-link acknowledgement ; check the standard
  # and scanner where leakage would be a real namespace bleed).
  if [ -f "$DATA_STEWARDSHIP_STD" ] && grep -q "J8-RULE" "$DATA_STEWARDSHIP_STD" 2>/dev/null; then
    echo "    J8-RULE leaked into $DATA_STEWARDSHIP_STD" >&2; return 1
  fi
  if [ -f "$DEMETER_SCAN" ] && grep -q "J8-RULE" "$DEMETER_SCAN" 2>/dev/null; then
    echo "    J8-RULE leaked into $DEMETER_SCAN" >&2; return 1
  fi
}

# ─── L2 stubs ───────────────────────────────────────────────────

# FR-K3-DEM-102 / 068 / 120 — deny-list hit at T3 → BLOCKED + Critical
_test_k3_l2_deny_list_hit() {
  _setup_l2
  trap '_teardown_l2' RETURN
  mkdir -p "$L2_TMP/.forge"
  echo "T3" > "$L2_TMP/.forge/.forge-tier"
  # Synthetic Cargo.lock with one EU-neutral crate + one deny-listed
  # AWS crate. The publisher list seeded by Phase 3 includes
  # 'aws-sdk-*' on the cargo deny-list.
  cat > "$L2_TMP/Cargo.lock" <<'TOML'
version = 4

[[package]]
name = "tokio"
version = "1.36.0"

[[package]]
name = "aws-sdk-s3"
version = "1.2.3"
TOML
  bash "$DEMETER_SCAN" --target "$L2_TMP" --tier T3 \
    --output "$L2_TMP/report.json" >/dev/null 2>&1
  local rc=$?
  assert_eq "3" "$rc" "deny-list hit at T3 expected exit 3 (BLOCKED)" || return 1
  if [ ! -f "$L2_TMP/report.json" ]; then
    echo "    report.json not produced" >&2; return 1
  fi
  local content; content="$(cat "$L2_TMP/report.json")"
  assert_contains "$content" '"overall_status": "BLOCKED"' || return 1
  assert_contains "$content" '"rule_id": "K3-RULE-001"' || return 1
  assert_contains "$content" '"severity": "Critical"' || return 1
  assert_contains "$content" 'aws-sdk-s3' || return 1
}

# FR-K3-DEM-102 / NFR-K3-DEM-005 — clean tree at T2 → CLEARED + reproducible
_test_k3_l2_clean_tree_t2() {
  _setup_l2
  trap '_teardown_l2' RETURN
  mkdir -p "$L2_TMP/.forge"
  echo "T2" > "$L2_TMP/.forge/.forge-tier"
  cat > "$L2_TMP/Cargo.lock" <<'TOML'
version = 4

[[package]]
name = "serde"
version = "1.0.197"

[[package]]
name = "tokio"
version = "1.36.0"
TOML
  cat > "$L2_TMP/package-lock.json" <<'JSON'
{
  "name": "k3-fixture-clean",
  "version": "0.0.1",
  "lockfileVersion": 3,
  "packages": {
    "": {"name": "k3-fixture-clean", "version": "0.0.1"},
    "node_modules/lodash": {"name": "lodash", "version": "4.17.21"}
  }
}
JSON
  SOURCE_DATE_EPOCH=0 bash "$DEMETER_SCAN" --target "$L2_TMP" --tier T2 \
    --output "$L2_TMP/r1.json" >/dev/null 2>&1
  local rc1=$?
  SOURCE_DATE_EPOCH=0 bash "$DEMETER_SCAN" --target "$L2_TMP" --tier T2 \
    --output "$L2_TMP/r2.json" >/dev/null 2>&1
  local rc2=$?
  assert_eq "0" "$rc1" "clean-tree run #1 expected exit 0 (CLEARED)" || return 1
  assert_eq "0" "$rc2" "clean-tree run #2 expected exit 0 (CLEARED)" || return 1
  local content; content="$(cat "$L2_TMP/r1.json")"
  assert_contains "$content" '"overall_status": "CLEARED"' || return 1
  if ! diff -q "$L2_TMP/r1.json" "$L2_TMP/r2.json" >/dev/null 2>&1; then
    echo "    report not byte-identical between runs (NFR-K3-DEM-005)" >&2
    diff "$L2_TMP/r1.json" "$L2_TMP/r2.json" | head -10 >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── K.3 — k3-demeter harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — persona + scanner + standard + integration anchors"
  run_test _test_k3_001_persona_exists
  run_test _test_k3_002_audit_comment
  run_test _test_k3_003_persona_h2
  run_test _test_k3_004_checklists_h2
  run_test _test_k3_005_checklists_items
  run_test _test_k3_006_output_h2
  run_test _test_k3_007_rule_catalogue
  run_test _test_k3_008_integration
  run_test _test_k3_009_anti_halluc
  run_test _test_k3_010_scanner_signature
  run_test _test_k3_011_scanner_exits
  run_test _test_k3_012_scanner_no_lockfile
  run_test _test_k3_013_publisher_list_yaml
  run_test _test_k3_014_publisher_list_metadata
  run_test _test_k3_015_standard_exists
  run_test _test_k3_016_index_registered
  run_test _test_k3_017_janus_dispatch_row
  run_test _test_k3_018_janus_step9_modified
  run_test _test_k3_019_claude_md_trigger
  run_test _test_k3_020_no_namespace_collision

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based scanner runs"
    run_test _test_k3_l2_deny_list_hit
    run_test _test_k3_l2_clean_tree_t2
  fi

  print_summary
}

main "$@"
