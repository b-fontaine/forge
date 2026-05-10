#!/usr/bin/env bash
# Forge — J.8 Janus Rules Test Harness (j8-janus-rules)
# <!-- Audit: J.8 (j8-janus-rules) -->
#
# Validates the J.8 deliverables across 3 sub-modules :
#
#   J.8.a — Janus refusal rules
#     - cross-layer-orchestrator.md "Forbidden archetypes" section
#     - dispatch-table.yml `forbidden_archetypes:` list
#     - bin/_forge-init-helpers.sh `_refuse_if_forbidden`
#     - cli/src/commands/init-archetype.ts dispatcher refusal
#     - global/janus-orchestration-rules.md standard
#
#   J.8.b — `--eu-tier` flag + T3 enforcement + ledger
#     - cli/src/commands/init.ts `--eu-tier <tier>` flag
#     - bin/forge-init-fsm.sh T3 enforcement
#     - .forge/.forge-tier ledger
#
#   J.8.d — SBOM CycloneDX
#     - bin/forge-sbom.sh handcraft Python inline
#     - global/sbom-policy.md standard
#
# 20 tests : 18 L1 hermetic + 2 L2 fixture-based.
# Performance : L1 ≤ 5 s, full ≤ 15 s wall-clock (NFR-J8-001).

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
INIT_FSM="$FORGE_ROOT_REAL/bin/forge-init-fsm.sh"
INIT_TS="$FORGE_ROOT_REAL/cli/src/commands/init.ts"
INIT_ARCHETYPE_TS="$FORGE_ROOT_REAL/cli/src/commands/init-archetype.ts"
JANUS_RULES_STD="$FORGE_ROOT_REAL/.forge/standards/global/janus-orchestration-rules.md"
SBOM_SCRIPT="$FORGE_ROOT_REAL/bin/forge-sbom.sh"
SBOM_POLICY_STD="$FORGE_ROOT_REAL/.forge/standards/global/sbom-policy.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (18 tests)
# MANIFEST: _test_j8_001_janus_section          — FR-J8-001/005 H2 + audit comment
# MANIFEST: _test_j8_002_janus_rule_001         — FR-J8-002 J8-RULE-001 anchor
# MANIFEST: _test_j8_003_janus_rule_002_003     — FR-J8-002 J8-RULE-002+003 anchors
# MANIFEST: _test_j8_010_dispatch_forbidden     — FR-J8-010 forbidden_archetypes key
# MANIFEST: _test_j8_011_entry_shape            — FR-J8-011 entry has 5 keys
# MANIFEST: _test_j8_012_seed_flutter_firebase  — FR-J8-012 seed entry shape
# MANIFEST: _test_j8_020_helper_exists          — FR-J8-022 helper file + function
# MANIFEST: _test_j8_021_wrapper_sources_helper — FR-J8-022 wrapper sources helper
# MANIFEST: _test_j8_022_dispatcher_check       — FR-J8-020 TS dispatcher check
# MANIFEST: _test_j8_023_refusal_format         — FR-J8-021 [REFUSAL: ...] format
# MANIFEST: _test_j8_030_standard_exists        — FR-J8-030 janus-orchestration-rules.md
# MANIFEST: _test_j8_040_eu_tier_flag           — FR-J8-040 init.ts declares --eu-tier
# MANIFEST: _test_j8_041_eu_tier_validation     — FR-J8-041 schema enum validation
# MANIFEST: _test_j8_042_no_default             — FR-J8-042 no default behaviour
# MANIFEST: _test_j8_050_t3_self_host_zitadel   — FR-J8-051 T3 zitadel guard
# MANIFEST: _test_j8_060_tier_ledger            — FR-J8-060 .forge/.forge-tier
# MANIFEST: _test_j8_070_sbom_signature         — FR-J8-070 forge-sbom.sh signature
# MANIFEST: _test_j8_080_sbom_policy_standard   — FR-J8-080 sbom-policy.md
#
# L2 (2 fixture tests)
# MANIFEST: _test_j8_l2_sbom_good          — FR-J8-102/072 valid CycloneDX 1.5 JSON
# MANIFEST: _test_j8_l2_sbom_determinism   — FR-J8-075 SOURCE_DATE_EPOCH byte-identical

# ─── Helpers ────────────────────────────────────────────────────

_setup_l1_fixture() {
  L1_TMP="$(mktemp -d -t forge-j8-l1-XXXXXX)"
}

_teardown_l1_fixture() {
  if [ -n "${L1_TMP:-}" ] && [ -d "$L1_TMP" ]; then
    rm -rf "$L1_TMP"
  fi
}

_setup_l2() {
  L2_TMP="$(mk_tmpdir_with_trap forge-j8-l2)"
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

# FR-J8-001/005 Janus agent gains H2 section + audit comment
_test_j8_001_janus_section() {
  if ! grep -q "^## Forbidden archetypes & combinations$" "$JANUS_AGENT"; then
    echo "    H2 'Forbidden archetypes & combinations' missing in $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -q "<!-- Audit: J.8 (j8-janus-rules) -->" "$JANUS_AGENT"; then
    echo "    audit comment missing in $JANUS_AGENT" >&2; return 1
  fi
}

# FR-J8-002 Janus rule J8-RULE-001 anchor
_test_j8_002_janus_rule_001() {
  if ! grep -q "J8-RULE-001" "$JANUS_AGENT"; then
    echo "    J8-RULE-001 anchor missing in $JANUS_AGENT" >&2; return 1
  fi
}

# FR-J8-002 Janus rules J8-RULE-002 + J8-RULE-003 anchors
_test_j8_003_janus_rule_002_003() {
  if ! grep -q "J8-RULE-002" "$JANUS_AGENT"; then
    echo "    J8-RULE-002 anchor missing in $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -q "J8-RULE-003" "$JANUS_AGENT"; then
    echo "    J8-RULE-003 anchor missing in $JANUS_AGENT" >&2; return 1
  fi
}

# FR-J8-010 dispatch-table top-level forbidden_archetypes key
_test_j8_010_dispatch_forbidden() {
  if ! grep -qE "^forbidden_archetypes:" "$DISPATCH_TABLE"; then
    echo "    forbidden_archetypes top-level key missing in $DISPATCH_TABLE" >&2; return 1
  fi
}

# FR-J8-011 entry has 5 keys (name, reason, since, alternative, rule_id)
_test_j8_011_entry_shape() {
  local needles=("name:" "reason:" "since:" "alternative:" "rule_id:")
  for n in "${needles[@]}"; do
    if ! awk '/^forbidden_archetypes:/{flag=1; next} flag && /^[A-Za-z]/{flag=0} flag' "$DISPATCH_TABLE" | grep -q "$n"; then
      echo "    forbidden_archetypes entry missing key: $n" >&2; return 1
    fi
  done
}

# FR-J8-012 seed entry shape (flutter-firebase + J8-RULE-001)
_test_j8_012_seed_flutter_firebase() {
  if ! awk '/^forbidden_archetypes:/{flag=1; next} flag && /^[A-Za-z]/{flag=0} flag' "$DISPATCH_TABLE" | grep -q "name: flutter-firebase"; then
    echo "    seed entry name=flutter-firebase missing" >&2; return 1
  fi
  if ! awk '/^forbidden_archetypes:/{flag=1; next} flag && /^[A-Za-z]/{flag=0} flag' "$DISPATCH_TABLE" | grep -q "rule_id: J8-RULE-001"; then
    echo "    seed entry rule_id=J8-RULE-001 missing" >&2; return 1
  fi
}

# FR-J8-022 helper file + _refuse_if_forbidden function
_test_j8_020_helper_exists() {
  if [ ! -f "$INIT_HELPERS" ]; then
    echo "    helper file missing: $INIT_HELPERS" >&2; return 1
  fi
  if ! grep -q "^_refuse_if_forbidden()" "$INIT_HELPERS"; then
    echo "    _refuse_if_forbidden() function definition missing in $INIT_HELPERS" >&2; return 1
  fi
}

# FR-J8-022 wrapper sources helper
_test_j8_021_wrapper_sources_helper() {
  if ! grep -q "_forge-init-helpers.sh" "$INIT_FSM"; then
    echo "    forge-init-fsm.sh does not source _forge-init-helpers.sh" >&2; return 1
  fi
  if ! grep -q "_refuse_if_forbidden" "$INIT_FSM"; then
    echo "    forge-init-fsm.sh does not invoke _refuse_if_forbidden" >&2; return 1
  fi
}

# FR-J8-020 TS dispatcher checks forbidden_archetypes
_test_j8_022_dispatcher_check() {
  if [ ! -f "$INIT_ARCHETYPE_TS" ]; then
    echo "    init-archetype.ts not found" >&2; return 1
  fi
  if ! grep -q "forbidden_archetypes" "$INIT_ARCHETYPE_TS"; then
    echo "    init-archetype.ts does not consult forbidden_archetypes" >&2; return 1
  fi
}

# FR-J8-021 [REFUSAL: ...] format used by helper + dispatcher
_test_j8_023_refusal_format() {
  if ! grep -q '\[REFUSAL:' "$INIT_HELPERS"; then
    echo "    [REFUSAL: format missing in $INIT_HELPERS" >&2; return 1
  fi
  if ! grep -q '\[REFUSAL:' "$INIT_ARCHETYPE_TS"; then
    echo "    [REFUSAL: format missing in $INIT_ARCHETYPE_TS" >&2; return 1
  fi
}

# FR-J8-030 janus-orchestration-rules.md standard exists with ≥ 5 H2 sections
_test_j8_030_standard_exists() {
  if [ ! -f "$JANUS_RULES_STD" ]; then
    echo "    standard missing: $JANUS_RULES_STD" >&2; return 1
  fi
  local h2_count
  h2_count="$(grep -cE '^## ' "$JANUS_RULES_STD")"
  if [ "$h2_count" -lt 5 ]; then
    echo "    expected ≥ 5 H2 sections in $JANUS_RULES_STD, got $h2_count" >&2; return 1
  fi
}
# FR-J8-040 init.ts declares --eu-tier (euTier?: in InitOptions)
_test_j8_040_eu_tier_flag() {
  if ! grep -q "euTier?:" "$INIT_TS"; then
    echo "    euTier?: optional field missing in $INIT_TS InitOptions" >&2; return 1
  fi
}

# FR-J8-041 enum validation [T1, T2, T3] with schema reference
_test_j8_041_eu_tier_validation() {
  if ! grep -qE 'EU_TIER_ENUM.*=.*\["T1"' "$INIT_TS"; then
    echo "    EU_TIER_ENUM with [T1, T2, T3] missing in $INIT_TS" >&2; return 1
  fi
  if ! grep -q "compliance-tier.schema.json" "$INIT_TS"; then
    echo "    schema reference missing in $INIT_TS validation" >&2; return 1
  fi
}

# FR-J8-042 no default — euTier remains optional, absence preserved
_test_j8_042_no_default() {
  # Optional shape : `euTier?:` (with `?:`).
  if ! grep -q "euTier?:" "$INIT_TS"; then
    echo "    euTier?: not declared as optional in $INIT_TS" >&2; return 1
  fi
  # `if (options.euTier !== undefined)` — gated path means absence = no behavior.
  if ! grep -q "options.euTier !== undefined" "$INIT_TS"; then
    echo "    options.euTier !== undefined gate missing in $INIT_TS" >&2; return 1
  fi
}

# FR-J8-051 wrapper has T3 self-host Zitadel guard
_test_j8_050_t3_self_host_zitadel() {
  if ! grep -qE 'FORGE_EU_TIER.*T3|case.*T3' "$INIT_FSM"; then
    echo "    T3 case-block missing in $INIT_FSM" >&2; return 1
  fi
  if ! grep -q "J8-RULE-002" "$INIT_FSM"; then
    echo "    J8-RULE-002 (zitadel) refusal missing in $INIT_FSM" >&2; return 1
  fi
  if ! grep -q "J8-RULE-003" "$INIT_FSM"; then
    echo "    J8-RULE-003 (signoz / datadog) refusal missing in $INIT_FSM" >&2; return 1
  fi
}

# FR-J8-060 .forge-tier ledger written by wrapper
_test_j8_060_tier_ledger() {
  if ! grep -q "\.forge-tier" "$INIT_FSM"; then
    echo "    .forge-tier ledger write missing in $INIT_FSM" >&2; return 1
  fi
  if ! grep -q "FORGE_EU_TIER" "$INIT_FSM"; then
    echo "    FORGE_EU_TIER consumption missing in $INIT_FSM" >&2; return 1
  fi
}

# FR-J8-070 forge-sbom.sh signature
_test_j8_070_sbom_signature() {
  if [ ! -f "$SBOM_SCRIPT" ]; then
    echo "    sbom script missing: $SBOM_SCRIPT" >&2; return 1
  fi
  if [ ! -x "$SBOM_SCRIPT" ]; then
    echo "    sbom script not executable: $SBOM_SCRIPT" >&2; return 1
  fi
  # Exit 2 on no args provided + unknown lockfiles ; we test via --help-like
  # invocation : run with no target dir + bogus arg → exit non-zero.
  bash "$SBOM_SCRIPT" --bogus-arg-that-doesnt-exist >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "    sbom script unexpectedly accepted bogus arg" >&2; return 1
  fi
}

# FR-J8-080 sbom-policy.md standard exists with ≥ 4 H2 sections
_test_j8_080_sbom_policy_standard() {
  if [ ! -f "$SBOM_POLICY_STD" ]; then
    echo "    sbom-policy standard missing: $SBOM_POLICY_STD" >&2; return 1
  fi
  local h2_count
  h2_count="$(grep -cE '^## ' "$SBOM_POLICY_STD")"
  if [ "$h2_count" -lt 4 ]; then
    echo "    expected ≥ 4 H2 sections in $SBOM_POLICY_STD, got $h2_count" >&2; return 1
  fi
}

# ─── L2 stubs ───────────────────────────────────────────────────

# FR-J8-102 / FR-J8-072 — happy-path SBOM with synthetic lockfiles.
_test_j8_l2_sbom_good() {
  _setup_l2
  trap '_teardown_l2' RETURN
  # Synthetic Cargo.lock (TOML, 2 packages).
  cat > "$L2_TMP/Cargo.lock" <<'TOML'
version = 4

[[package]]
name = "foo"
version = "1.0.0"

[[package]]
name = "bar"
version = "2.3.4"
TOML
  # Synthetic package-lock.json (npm v3, 1 package).
  cat > "$L2_TMP/package-lock.json" <<'JSON'
{
  "name": "fixture",
  "version": "0.0.1",
  "lockfileVersion": 3,
  "packages": {
    "": {"name": "fixture", "version": "0.0.1"},
    "node_modules/baz": {"name": "baz", "version": "9.9.9"}
  }
}
JSON
  bash "$SBOM_SCRIPT" --target "$L2_TMP" --output "$L2_TMP/sbom.cdx.json" >/dev/null 2>&1
  local rc=$?
  assert_eq "0" "$rc" "sbom exit code (good fixture, expected 0)" || return 1
  if [ ! -f "$L2_TMP/sbom.cdx.json" ]; then
    echo "    sbom.cdx.json not produced" >&2; return 1
  fi
  local content; content="$(cat "$L2_TMP/sbom.cdx.json")"
  assert_contains "$content" '"bomFormat": "CycloneDX"' || return 1
  assert_contains "$content" '"specVersion": "1.5"' || return 1
  assert_contains "$content" 'pkg:cargo/foo@1.0.0' || return 1
  assert_contains "$content" 'pkg:cargo/bar@2.3.4' || return 1
  assert_contains "$content" 'pkg:npm/baz@9.9.9' || return 1
}

# FR-J8-075 — byte-identical output with SOURCE_DATE_EPOCH=0.
_test_j8_l2_sbom_determinism() {
  _setup_l2
  trap '_teardown_l2' RETURN
  cat > "$L2_TMP/Cargo.lock" <<'TOML'
version = 4

[[package]]
name = "alpha"
version = "0.1.0"

[[package]]
name = "beta"
version = "0.2.0"
TOML
  SOURCE_DATE_EPOCH=0 bash "$SBOM_SCRIPT" \
    --target "$L2_TMP" --output "$L2_TMP/sbom1.json" >/dev/null 2>&1
  local rc1=$?
  SOURCE_DATE_EPOCH=0 bash "$SBOM_SCRIPT" \
    --target "$L2_TMP" --output "$L2_TMP/sbom2.json" >/dev/null 2>&1
  local rc2=$?
  assert_eq "0" "$rc1" "first run exit" || return 1
  assert_eq "0" "$rc2" "second run exit" || return 1
  if ! diff -q "$L2_TMP/sbom1.json" "$L2_TMP/sbom2.json" >/dev/null 2>&1; then
    echo "    SBOM not byte-identical between runs (NFR-J8-001 / FR-J8-075)" >&2
    diff "$L2_TMP/sbom1.json" "$L2_TMP/sbom2.json" | head -10 >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── J.8 — j8-janus-rules harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — Janus rules + eu-tier flag + SBOM script"
  run_test _test_j8_001_janus_section
  run_test _test_j8_002_janus_rule_001
  run_test _test_j8_003_janus_rule_002_003
  run_test _test_j8_010_dispatch_forbidden
  run_test _test_j8_011_entry_shape
  run_test _test_j8_012_seed_flutter_firebase
  run_test _test_j8_020_helper_exists
  run_test _test_j8_021_wrapper_sources_helper
  run_test _test_j8_022_dispatcher_check
  run_test _test_j8_023_refusal_format
  run_test _test_j8_030_standard_exists
  run_test _test_j8_040_eu_tier_flag
  run_test _test_j8_041_eu_tier_validation
  run_test _test_j8_042_no_default
  run_test _test_j8_050_t3_self_host_zitadel
  run_test _test_j8_060_tier_ledger
  run_test _test_j8_070_sbom_signature
  run_test _test_j8_080_sbom_policy_standard

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based SBOM"
    run_test _test_j8_l2_sbom_good
    run_test _test_j8_l2_sbom_determinism
  fi

  print_summary
}

main "$@"
