#!/usr/bin/env bash
# Forge — B.7.9 / J.8.c Janus LLM-Provider Rules Test Harness (b7-9-janus-ai)
# <!-- Audit: B.7.9 + J.8.c (b7-9-janus-ai) -->
#
# Validates the J.8.c deliverables — Janus refusal rules for the
# `ai-native-rag` archetype's LLM providers :
#
#   J.8.c.1 — new H3 sub-section + J8-RULE-004..006 in the Janus agent
#     - .claude/agents/cross-layer-orchestrator.md "LLM-provider rules"
#     - .forge/scaffolding/dispatch-table.yml `forbidden_combinations:` list
#
#   J.8.c.3 — combination-refusal helper + wrapper
#     - bin/_forge-init-helpers.sh `_refuse_if_forbidden_combination`
#     - bin/forge-init-ai-native-rag.sh sources + invokes it
#
#   J.8.c.4 — standards updates
#     - global/janus-orchestration-rules.md catalogue rows
#     - global/compliance-tiers.md::forbidden: tokens (Q-003 in-brick)
#     - constitution-linter.sh::ADR-I3-001 REMEDIATION map (Q-003 in-brick)
#
# 11 L1 hermetic + 2 L2 fixture = 13 tests.
# Performance : L1 ≤ 5 s (pure grep), full --level 1,2 ≤ 15 s (NFR-B7-9-002).

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

JANUS_AGENT="$FORGE_ROOT_REAL/.claude/agents/cross-layer-orchestrator.md"
DISPATCH_TABLE="$FORGE_ROOT_REAL/.forge/scaffolding/dispatch-table.yml"
INIT_HELPERS="$FORGE_ROOT_REAL/bin/_forge-init-helpers.sh"
AINR_WRAPPER="$FORGE_ROOT_REAL/bin/forge-init-ai-native-rag.sh"
JANUS_RULES_STD="$FORGE_ROOT_REAL/.forge/standards/global/janus-orchestration-rules.md"
COMPLIANCE_STD="$FORGE_ROOT_REAL/.forge/standards/global/compliance-tiers.md"
LINTER_SH="$FORGE_ROOT_REAL/.forge/scripts/constitution-linter.sh"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (11 tests)
# MANIFEST: _test_b7_9_001_agent_h3_section       — FR-B7-9-001/006 H3 + audit anchor
# MANIFEST: _test_b7_9_002_rule_004               — FR-B7-9-002 J8-RULE-004 anchor
# MANIFEST: _test_b7_9_003_rule_005               — FR-B7-9-003 J8-RULE-005 anchor
# MANIFEST: _test_b7_9_004_rule_006               — FR-B7-9-004 J8-RULE-006 anchor
# MANIFEST: _test_b7_9_005_rule_004_is_next_free  — NFR-B7-9-003 numbering invariant
# MANIFEST: _test_b7_9_020_combinations_key       — FR-B7-9-020 forbidden_combinations key
# MANIFEST: _test_b7_9_021_entry_shape            — FR-B7-9-021 7-key entry shape
# MANIFEST: _test_b7_9_022_seed_entries           — FR-B7-9-022 three seed rule_ids
# MANIFEST: _test_b7_9_040_helper_fn              — FR-B7-9-040 helper fn + old fn intact
# MANIFEST: _test_b7_9_043_refusal_format         — FR-B7-9-043 [REFUSAL: format in helper
# MANIFEST: _test_b7_9_045_wrapper_invokes        — FR-B7-9-045 wrapper sources + invokes
# MANIFEST: _test_b7_9_060_std_rows               — FR-B7-9-060 three catalogue rows
# MANIFEST: _test_b7_9_062_tokens                 — FR-B7-9-062/063 tokens + REMEDIATION (Q-003)
#
# L2 (2 fixture tests)
# MANIFEST: _test_b7_9_l2_refuse_t3        — FR-B7-9-082 T3 + us-managed-inference ⇒ exit 3 + J8-RULE-006
# MANIFEST: _test_b7_9_l2_t1_no_refuse     — FR-B7-9-082 T1 + openai-via-eu-gateway ⇒ exit 0, no refusal

# ─── RED witness ─────────────────────────────────────────────────

_not_implemented() {
  echo "    not implemented (RED witness — pending implementation tasks)" >&2
  return 1
}

# ─── L1 stubs ────────────────────────────────────────────────────

# FR-B7-9-001/006 — new H3 "LLM-provider rules" + B.7.9 audit anchor.
# The H3 lands INSIDE the existing "Forbidden archetypes & combinations"
# H2 (collision discipline ADR-B7-9-004 — never the Dispatch Table H2).
_test_b7_9_001_agent_h3_section() {
  if ! grep -qF "### LLM-provider rules (\`ai-native-rag\`)" "$JANUS_AGENT"; then
    echo "    H3 'LLM-provider rules (ai-native-rag)' missing in $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -qF "<!-- Audit: B.7.9 + J.8.c (b7-9-janus-ai) -->" "$JANUS_AGENT"; then
    echo "    B.7.9 audit anchor missing in $JANUS_AGENT" >&2; return 1
  fi
}

# FR-B7-9-002 — J8-RULE-004 anchor in agent file
_test_b7_9_002_rule_004() {
  if ! grep -qF "J8-RULE-004" "$JANUS_AGENT"; then
    echo "    J8-RULE-004 anchor missing in $JANUS_AGENT" >&2; return 1
  fi
}

# FR-B7-9-003 — J8-RULE-005 anchor in agent file
_test_b7_9_003_rule_005() {
  if ! grep -qF "J8-RULE-005" "$JANUS_AGENT"; then
    echo "    J8-RULE-005 anchor missing in $JANUS_AGENT" >&2; return 1
  fi
}

# FR-B7-9-004 — J8-RULE-006 anchor in agent file
_test_b7_9_004_rule_006() {
  if ! grep -qF "J8-RULE-006" "$JANUS_AGENT"; then
    echo "    J8-RULE-006 anchor missing in $JANUS_AGENT" >&2; return 1
  fi
}

# NFR-B7-9-003 — J8-RULE-004 is the next free ID : the live catalogue must
# never define a J8-RULE-007+ before 004..006 land (guards against a
# concurrently-landed J.8 rule grabbing 004). We assert 004/005/006 exist
# AND that no higher-numbered J8-RULE collides (no 007 yet allocated).
_test_b7_9_005_rule_004_is_next_free() {
  local rid
  for rid in J8-RULE-004 J8-RULE-005 J8-RULE-006; do
    if ! grep -qrF "$rid" "$JANUS_AGENT" "$DISPATCH_TABLE"; then
      echo "    expected $rid allocated (next free block) but missing" >&2; return 1
    fi
  done
  if grep -qrhoE "J8-RULE-0(0[7-9]|[1-9][0-9])" "$JANUS_AGENT" "$DISPATCH_TABLE"; then
    echo "    a J8-RULE-007+ ID exists — 004..006 are NOT the next free block (collision)" >&2; return 1
  fi
}

# FR-B7-9-020 — forbidden_combinations: top-level key in dispatch-table
_test_b7_9_020_combinations_key() {
  if ! grep -qE "^forbidden_combinations:" "$DISPATCH_TABLE"; then
    echo "    forbidden_combinations top-level key missing in $DISPATCH_TABLE" >&2; return 1
  fi
}

# FR-B7-9-021 — entry has the 7 keys (archetype/provider/tier/reason/since/
# alternative/rule_id) within the forbidden_combinations: block.
_test_b7_9_021_entry_shape() {
  local needles=("archetype:" "provider:" "tier:" "reason:" "since:" "alternative:" "rule_id:")
  local n
  for n in "${needles[@]}"; do
    if ! awk '/^forbidden_combinations:/{flag=1; next} flag && /^[A-Za-z]/{flag=0} flag' "$DISPATCH_TABLE" | grep -qF "$n"; then
      echo "    forbidden_combinations entry missing key: $n" >&2; return 1
    fi
  done
}

# FR-B7-9-022 — three seed rule_ids J8-RULE-004/005/006 present in the block
_test_b7_9_022_seed_entries() {
  local block
  block="$(awk '/^forbidden_combinations:/{flag=1; next} flag && /^[A-Za-z]/{flag=0} flag' "$DISPATCH_TABLE")"
  local rid
  for rid in J8-RULE-004 J8-RULE-005 J8-RULE-006; do
    if ! printf '%s' "$block" | grep -qF "rule_id: $rid"; then
      echo "    seed entry rule_id: $rid missing in forbidden_combinations" >&2; return 1
    fi
  done
}

# FR-B7-9-040 — _refuse_if_forbidden_combination defined ; the existing
# _refuse_if_forbidden (J.8.a contract) MUST still be present (additive only).
_test_b7_9_040_helper_fn() {
  if [ ! -f "$INIT_HELPERS" ]; then
    echo "    helper file missing: $INIT_HELPERS" >&2; return 1
  fi
  if ! grep -qE "^_refuse_if_forbidden_combination\(\)" "$INIT_HELPERS"; then
    echo "    _refuse_if_forbidden_combination() definition missing in $INIT_HELPERS" >&2; return 1
  fi
  if ! grep -qE "^_refuse_if_forbidden\(\)" "$INIT_HELPERS"; then
    echo "    existing _refuse_if_forbidden() must remain present (NFR-B7-9-001)" >&2; return 1
  fi
}

# FR-B7-9-043 — [REFUSAL: format used by the combination helper, carrying
# the @<tier> provider-aware shape.
_test_b7_9_043_refusal_format() {
  if ! grep -qF '[REFUSAL:' "$INIT_HELPERS"; then
    echo "    [REFUSAL: format missing in $INIT_HELPERS" >&2; return 1
  fi
  if ! grep -qF '@' "$INIT_HELPERS"; then
    echo "    provider-aware @<tier> shape missing in $INIT_HELPERS refusal" >&2; return 1
  fi
}

# FR-B7-9-045 — wrapper sources helper + invokes _refuse_if_forbidden_combination
_test_b7_9_045_wrapper_invokes() {
  if ! grep -qF "_forge-init-helpers.sh" "$AINR_WRAPPER"; then
    echo "    wrapper does not source _forge-init-helpers.sh" >&2; return 1
  fi
  if ! grep -qF "_refuse_if_forbidden_combination" "$AINR_WRAPPER"; then
    echo "    wrapper does not invoke _refuse_if_forbidden_combination" >&2; return 1
  fi
}

# FR-B7-9-060 — three new rows (J8-RULE-004/005/006) in the
# janus-orchestration-rules.md rule-catalogue.
_test_b7_9_060_std_rows() {
  local rid
  for rid in J8-RULE-004 J8-RULE-005 J8-RULE-006; do
    if ! grep -qF "$rid" "$JANUS_RULES_STD"; then
      echo "    catalogue row $rid missing in $JANUS_RULES_STD" >&2; return 1
    fi
  done
}

# FR-B7-9-062/063 — vertex-ai + bedrock in compliance-tiers.md::forbidden:
# + matching REMEDIATION entries in the linter (Q-003 in-brick).
_test_b7_9_062_tokens() {
  # forbidden: block in compliance-tiers.md now lists the two tokens.
  if ! grep -qF "vertex-ai" "$COMPLIANCE_STD"; then
    echo "    vertex-ai token missing in $COMPLIANCE_STD forbidden:" >&2; return 1
  fi
  if ! grep -qF "bedrock" "$COMPLIANCE_STD"; then
    echo "    bedrock token missing in $COMPLIANCE_STD forbidden:" >&2; return 1
  fi
  # REMEDIATION map in the linter carries both tokens.
  if ! grep -qF '"vertex-ai"' "$LINTER_SH"; then
    echo "    vertex-ai REMEDIATION entry missing in $LINTER_SH" >&2; return 1
  fi
  if ! grep -qF '"bedrock"' "$LINTER_SH"; then
    echo "    bedrock REMEDIATION entry missing in $LINTER_SH" >&2; return 1
  fi
}

# ─── L2 stubs ────────────────────────────────────────────────────

# Build a synthetic forge-root tree carrying the live dispatch-table +
# a .forge/.forge-tier ledger, so the helper resolves the tier + parses
# forbidden_combinations against the real registry. FORGE_ROOT points the
# helper at the fixture. Echoes the tmpdir path.
_mk_combo_fixture() {
  # _mk_combo_fixture <tier-or-empty>
  local tier="$1"
  local tmpdir
  tmpdir="$(mk_tmpdir_with_trap forge-b7-9-l2)"
  mkdir -p "$tmpdir/.forge/scaffolding"
  cp "$DISPATCH_TABLE" "$tmpdir/.forge/scaffolding/dispatch-table.yml"
  if [ -n "$tier" ]; then
    printf '%s\n' "$tier" > "$tmpdir/.forge/.forge-tier"
  fi
  echo "$tmpdir"
}

# Invoke the combination helper in a child bash so its `exit 3` terminates
# only the child (not the harness). The child's exit status IS the helper's
# refusal exit code ; we append an `RC=<code>` sentinel to the captured
# stream so callers can assert the code regardless of whether the helper
# exited (refusal) or returned (fail-open).
_run_combo_helper() {
  # _run_combo_helper <forge_root> <tier-or-empty> <archetype> <provider>
  local forge_root="$1" tier="$2" archetype="$3" provider="$4"
  local tier_env=""
  [ -n "$tier" ] && tier_env="FORGE_EU_TIER=$tier"
  local out rc
  out="$(env -u FORGE_EU_TIER $tier_env FORGE_ROOT="$forge_root" \
         INIT_HELPERS="$INIT_HELPERS" \
         bash -c '
           set +e
           # shellcheck source=/dev/null
           source "$INIT_HELPERS"
           _refuse_if_forbidden_combination "$1" "$2"
         ' _ "$archetype" "$provider" 2>&1)"
  rc=$?
  printf '%s\nRC=%s\n' "$out" "$rc"
}

# FR-B7-9-082 — T3 + us-managed-inference ⇒ exit 3 + [REFUSAL: with J8-RULE-006
_test_b7_9_l2_refuse_t3() {
  local tmpdir output
  tmpdir="$(_mk_combo_fixture T3)"
  trap "rm -rf '$tmpdir'" RETURN
  output="$(_run_combo_helper "$tmpdir" T3 "ai-native-rag" "us-managed-inference")"
  if ! printf '%s' "$output" | grep -qF "RC=3"; then
    echo "    expected exit 3 from combination helper at T3" >&2
    printf '    output: %s\n' "$output" >&2
    return 1
  fi
  assert_contains "$output" "[REFUSAL:" "T3 refusal line" || return 1
  assert_contains "$output" "J8-RULE-006" "T3 refusal carries J8-RULE-006" || return 1
}

# FR-B7-9-082 — T1 + openai-via-eu-gateway ⇒ exit 0, no [REFUSAL:
# Mirrors i3.test.sh::_test_i3_l2_t1_warn_only — the T3 rule does NOT fire at
# T1, and openai-via-eu-gateway matches no default-provider entry.
_test_b7_9_l2_t1_no_refuse() {
  local tmpdir output
  tmpdir="$(_mk_combo_fixture T1)"
  trap "rm -rf '$tmpdir'" RETURN
  output="$(_run_combo_helper "$tmpdir" T1 "ai-native-rag" "openai-via-eu-gateway")"
  if ! printf '%s' "$output" | grep -qF "RC=0"; then
    echo "    expected exit 0 (no refusal) at T1 for openai-via-eu-gateway" >&2
    printf '    output: %s\n' "$output" >&2
    return 1
  fi
  assert_not_contains "$output" "[REFUSAL:" "T1 openai-via-eu-gateway must not refuse" || return 1
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── B.7.9 / J.8.c — b7-9-janus-ai harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — agent rules + registry + helper + wrapper + standards"
  run_test _test_b7_9_001_agent_h3_section
  run_test _test_b7_9_002_rule_004
  run_test _test_b7_9_003_rule_005
  run_test _test_b7_9_004_rule_006
  run_test _test_b7_9_005_rule_004_is_next_free
  run_test _test_b7_9_020_combinations_key
  run_test _test_b7_9_021_entry_shape
  run_test _test_b7_9_022_seed_entries
  run_test _test_b7_9_040_helper_fn
  run_test _test_b7_9_043_refusal_format
  run_test _test_b7_9_045_wrapper_invokes
  run_test _test_b7_9_060_std_rows
  run_test _test_b7_9_062_tokens

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based combination refusal"
    run_test _test_b7_9_l2_refuse_t3
    run_test _test_b7_9_l2_t1_no_refuse
  fi

  print_summary
}

main "$@"
