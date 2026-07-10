#!/usr/bin/env bash
# Forge — B.6.10 Janus Event-Broker Rules Test Harness (b6-10-janus-rule)
# <!-- Audit: B.6.10 (b6-10-janus-rule) -->
#
# Validates the B.6.10 deliverables — Janus refusal rules for the
# `event-driven-eu` archetype's event broker :
#
#   B.6.10.1 — new H3 sub-section + J8-RULE-007..008 in the Janus agent
#     - .claude/agents/cross-layer-orchestrator.md "Event-broker rules"
#     - .forge/scaffolding/dispatch-table.yml forbidden_combinations: entries
#
#   B.6.10.3 — wrapper invokes the (reused) combination helper
#     - bin/forge-init-event-driven-eu.sh sources + invokes
#       _refuse_if_forbidden_combination (helper REUSED from b7-9-janus-ai)
#
#   B.6.10.4 — standards updates
#     - global/janus-orchestration-rules.md catalogue rows
#     - global/compliance-tiers.md::forbidden: confluent-cloud token
#     - constitution-linter.sh::ADR-I3-001 REMEDIATION map
#
# 9 L1 hermetic + 3 L2 fixture = 12 tests.
# Performance : L1 ≤ 5 s (pure grep), full --level 1,2 ≤ 15 s (NFR-B6-JR-002).

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
EDE_WRAPPER="$FORGE_ROOT_REAL/bin/forge-init-event-driven-eu.sh"
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
# L1 (9 tests)
# MANIFEST: _test_b6_10_001_agent_h3_section       — FR-B6-JR-001/005 H3 + audit anchor
# MANIFEST: _test_b6_10_002_rule_007               — FR-B6-JR-002 J8-RULE-007 anchor
# MANIFEST: _test_b6_10_003_rule_008               — FR-B6-JR-003 J8-RULE-008 anchor
# MANIFEST: _test_b6_10_004_rule_007_is_next_free  — NFR-B6-JR-003 numbering invariant
# MANIFEST: _test_b6_10_020_combinations_entries   — FR-B6-JR-020 event-driven-eu broker entries
# MANIFEST: _test_b6_10_021_seed_rule_ids          — FR-B6-JR-021 two seed rule_ids
# MANIFEST: _test_b6_10_041_wrapper_invokes        — FR-B6-JR-041 wrapper sources + invokes
# MANIFEST: _test_b6_10_060_std_rows               — FR-B6-JR-060 two catalogue rows
# MANIFEST: _test_b6_10_062_token                  — FR-B6-JR-062/063 confluent-cloud token + REMEDIATION
#
# L2 (3 fixture tests)
# MANIFEST: _test_b6_10_l2_refuse_confluent   — FR-B6-JR-082 confluent-cloud (any tier) ⇒ exit 3 + J8-RULE-007
# MANIFEST: _test_b6_10_l2_refuse_t3_kafka    — FR-B6-JR-082 T3 + us-managed-kafka ⇒ exit 3 + J8-RULE-008
# MANIFEST: _test_b6_10_l2_nats_no_refuse     — FR-B6-JR-082 T3 + nats-jetstream ⇒ exit 0, no refusal

# ─── L1 ──────────────────────────────────────────────────────────

# FR-B6-JR-001/005 — new H3 "Event-broker rules" + B.6.10 audit anchor.
# The H3 lands INSIDE the existing "Forbidden archetypes & combinations" H2.
_test_b6_10_001_agent_h3_section() {
  if ! grep -qF "### Event-broker rules (\`event-driven-eu\`)" "$JANUS_AGENT"; then
    echo "    H3 'Event-broker rules (event-driven-eu)' missing in $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -qF "<!-- Audit: B.6.10 (b6-10-janus-rule) -->" "$JANUS_AGENT"; then
    echo "    B.6.10 audit anchor missing in $JANUS_AGENT" >&2; return 1
  fi
}

# FR-B6-JR-002 — J8-RULE-007 anchor in agent file
_test_b6_10_002_rule_007() {
  if ! grep -qF "J8-RULE-007" "$JANUS_AGENT"; then
    echo "    J8-RULE-007 anchor missing in $JANUS_AGENT" >&2; return 1
  fi
}

# FR-B6-JR-003 — J8-RULE-008 anchor in agent file
_test_b6_10_003_rule_008() {
  if ! grep -qF "J8-RULE-008" "$JANUS_AGENT"; then
    echo "    J8-RULE-008 anchor missing in $JANUS_AGENT" >&2; return 1
  fi
}

# NFR-B6-JR-003 — J8-RULE-007/008 are the next free block after 006 : assert
# 007/008 exist AND no higher-numbered J8-RULE (009+) collides.
_test_b6_10_004_rule_007_is_next_free() {
  local rid
  for rid in J8-RULE-007 J8-RULE-008; do
    if ! grep -qrF "$rid" "$JANUS_AGENT" "$DISPATCH_TABLE"; then
      echo "    expected $rid allocated (next free block) but missing" >&2; return 1
    fi
  done
  if grep -qrhoE "J8-RULE-0(09|[1-9][0-9])" "$JANUS_AGENT" "$DISPATCH_TABLE"; then
    echo "    a J8-RULE-009+ ID exists — 007..008 are NOT the next free block (collision)" >&2; return 1
  fi
}

# FR-B6-JR-020 — event-driven-eu broker entries in the forbidden_combinations:
# block (confluent-cloud + us-managed-kafka providers + the archetype key).
_test_b6_10_020_combinations_entries() {
  local block
  block="$(awk '/^forbidden_combinations:/{flag=1; next} flag && /^[A-Za-z]/{flag=0} flag' "$DISPATCH_TABLE")"
  local n
  for n in "event-driven-eu" "confluent-cloud" "us-managed-kafka"; do
    if ! printf '%s' "$block" | grep -qF "$n"; then
      echo "    forbidden_combinations block missing token: $n" >&2; return 1
    fi
  done
}

# FR-B6-JR-021 — two seed rule_ids J8-RULE-007/008 present in the block
_test_b6_10_021_seed_rule_ids() {
  local block
  block="$(awk '/^forbidden_combinations:/{flag=1; next} flag && /^[A-Za-z]/{flag=0} flag' "$DISPATCH_TABLE")"
  local rid
  for rid in J8-RULE-007 J8-RULE-008; do
    if ! printf '%s' "$block" | grep -qF "rule_id: $rid"; then
      echo "    seed entry rule_id: $rid missing in forbidden_combinations" >&2; return 1
    fi
  done
}

# FR-B6-JR-041 — wrapper sources helper + invokes _refuse_if_forbidden_combination
# for the event-driven-eu archetype (helper REUSED from b7-9, not duplicated).
_test_b6_10_041_wrapper_invokes() {
  if ! grep -qF "_forge-init-helpers.sh" "$EDE_WRAPPER"; then
    echo "    wrapper does not source _forge-init-helpers.sh" >&2; return 1
  fi
  if ! grep -qF "_refuse_if_forbidden_combination" "$EDE_WRAPPER"; then
    echo "    wrapper does not invoke _refuse_if_forbidden_combination" >&2; return 1
  fi
  # The combination call must target event-driven-eu — either the literal
  # string or the $ARCHETYPE var (which the wrapper sets to "event-driven-eu",
  # the DRY pattern shared with the ai-native-rag sibling wrapper).
  if ! grep -qE "_refuse_if_forbidden_combination[[:space:]]+\"(\\\$ARCHETYPE|event-driven-eu)\"" "$EDE_WRAPPER"; then
    echo "    wrapper does not invoke _refuse_if_forbidden_combination for event-driven-eu" >&2; return 1
  fi
  if ! grep -qE "^ARCHETYPE=\"event-driven-eu\"" "$EDE_WRAPPER"; then
    echo "    wrapper ARCHETYPE var is not \"event-driven-eu\"" >&2; return 1
  fi
}

# FR-B6-JR-060 — two new rows (J8-RULE-007/008) in the
# janus-orchestration-rules.md rule-catalogue.
_test_b6_10_060_std_rows() {
  local rid
  for rid in J8-RULE-007 J8-RULE-008; do
    if ! grep -qF "$rid" "$JANUS_RULES_STD"; then
      echo "    catalogue row $rid missing in $JANUS_RULES_STD" >&2; return 1
    fi
  done
}

# FR-B6-JR-062/063 — confluent-cloud in compliance-tiers.md::forbidden:
# + matching REMEDIATION entry in the linter.
_test_b6_10_062_token() {
  if ! grep -qF "confluent-cloud" "$COMPLIANCE_STD"; then
    echo "    confluent-cloud token missing in $COMPLIANCE_STD forbidden:" >&2; return 1
  fi
  if ! grep -qF '"confluent-cloud"' "$LINTER_SH"; then
    echo "    confluent-cloud REMEDIATION entry missing in $LINTER_SH" >&2; return 1
  fi
}

# ─── L2 ──────────────────────────────────────────────────────────

# Build a synthetic forge-root tree carrying the live dispatch-table +
# an optional .forge/.forge-tier ledger, so the reused helper resolves the
# tier + parses forbidden_combinations against the real registry.
_mk_combo_fixture() {
  # _mk_combo_fixture <tier-or-empty>
  local tier="$1"
  local tmpdir
  tmpdir="$(mk_tmpdir_with_trap forge-b6-10-l2)"
  mkdir -p "$tmpdir/.forge/scaffolding"
  cp "$DISPATCH_TABLE" "$tmpdir/.forge/scaffolding/dispatch-table.yml"
  if [ -n "$tier" ]; then
    printf '%s\n' "$tier" > "$tmpdir/.forge/.forge-tier"
  fi
  echo "$tmpdir"
}

# Invoke the reused combination helper in a child bash so its `exit 3`
# terminates only the child. Append an RC=<code> sentinel to the captured
# stream so callers can assert the code regardless of refusal / fail-open.
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

# FR-B6-JR-082 — confluent-cloud (tier unset) ⇒ exit 3 + [REFUSAL: J8-RULE-007
# (tier: any fires regardless of the declared tier).
_test_b6_10_l2_refuse_confluent() {
  local tmpdir output
  tmpdir="$(_mk_combo_fixture "")"
  trap "rm -rf '$tmpdir'" RETURN
  output="$(_run_combo_helper "$tmpdir" "" "event-driven-eu" "confluent-cloud")"
  if ! printf '%s' "$output" | grep -qF "RC=3"; then
    echo "    expected exit 3 from combination helper for confluent-cloud (any tier)" >&2
    printf '    output: %s\n' "$output" >&2
    return 1
  fi
  assert_contains "$output" "[REFUSAL:" "confluent-cloud refusal line" || return 1
  assert_contains "$output" "J8-RULE-007" "confluent-cloud refusal carries J8-RULE-007" || return 1
}

# FR-B6-JR-082 — T3 + us-managed-kafka ⇒ exit 3 + [REFUSAL: J8-RULE-008
_test_b6_10_l2_refuse_t3_kafka() {
  local tmpdir output
  tmpdir="$(_mk_combo_fixture T3)"
  trap "rm -rf '$tmpdir'" RETURN
  output="$(_run_combo_helper "$tmpdir" T3 "event-driven-eu" "us-managed-kafka")"
  if ! printf '%s' "$output" | grep -qF "RC=3"; then
    echo "    expected exit 3 from combination helper at T3 for us-managed-kafka" >&2
    printf '    output: %s\n' "$output" >&2
    return 1
  fi
  assert_contains "$output" "[REFUSAL:" "T3 kafka refusal line" || return 1
  assert_contains "$output" "J8-RULE-008" "T3 kafka refusal carries J8-RULE-008" || return 1
}

# FR-B6-JR-082 — T3 + nats-jetstream ⇒ exit 0, no [REFUSAL:
# The sovereign default matches no forbidden entry (negative control).
_test_b6_10_l2_nats_no_refuse() {
  local tmpdir output
  tmpdir="$(_mk_combo_fixture T3)"
  trap "rm -rf '$tmpdir'" RETURN
  output="$(_run_combo_helper "$tmpdir" T3 "event-driven-eu" "nats-jetstream")"
  if ! printf '%s' "$output" | grep -qF "RC=0"; then
    echo "    expected exit 0 (no refusal) at T3 for nats-jetstream (sovereign default)" >&2
    printf '    output: %s\n' "$output" >&2
    return 1
  fi
  assert_not_contains "$output" "[REFUSAL:" "T3 nats-jetstream must not refuse" || return 1
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── B.6.10 — b6-10-janus-rule harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — agent rules + registry + wrapper + standards"
  run_test _test_b6_10_001_agent_h3_section
  run_test _test_b6_10_002_rule_007
  run_test _test_b6_10_003_rule_008
  run_test _test_b6_10_004_rule_007_is_next_free
  run_test _test_b6_10_020_combinations_entries
  run_test _test_b6_10_021_seed_rule_ids
  run_test _test_b6_10_041_wrapper_invokes
  run_test _test_b6_10_060_std_rows
  run_test _test_b6_10_062_token

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based combination refusal (reused helper)"
    run_test _test_b6_10_l2_refuse_confluent
    run_test _test_b6_10_l2_refuse_t3_kafka
    run_test _test_b6_10_l2_nats_no_refuse
  fi

  print_summary
}

main "$@"
