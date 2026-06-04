#!/usr/bin/env bash
# Forge — B.8.13 rollback-runbook harness
# <!-- Audit: B.8.13 (b8-13-rollback-runbook) -->
#
# Verifies the 1.0.0 → 2.0.0 rollback runbook (docs/ROLLBACK.md):
#   - two scenarios (p99 → Kong route weights ; traceparent → OTel SDK overlay)
#     each with the five operational steps (Detect/Decide/Execute/Verify/Re-attempt)
#   - relative thresholds only (> 20 % / > 1 %), NO committed absolute latency
#   - last-resort full-tree --rollback ; explicit no-DBOS/CPU criterion (B8O)
#   - runbook ↔ forge-migrate-flagship.sh embedded criteria consistency
#   - record-only supersession: ARCHITECTURE-TARGET.md is sha256-PINNED (t4) and
#     MUST stay byte-frozen ; the Supersession note enumerates its stale refs
#   - MIGRATIONS.md forward-reference resolved ; CHANGELOG/CI ; coupling (b8-12,
#     b8-10, t4)
#
# All L1, hermetic (grep/diff/stat/shasum) — no cargo/flutter/docker/node.
# Performance budget : L1 ≤ a few seconds.

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

ROLLBACK_DOC="$FORGE_ROOT_REAL/docs/ROLLBACK.md"
ARCH_DOC="$FORGE_ROOT_REAL/docs/ARCHITECTURE-TARGET.md"
T4_SPECS="$FORGE_ROOT_REAL/.forge/changes/t4-adr-ratification/specs.md"
MIGRATIONS="$FORGE_ROOT_REAL/docs/MIGRATIONS.md"
MIGRATE_SH="$FORGE_ROOT_REAL/bin/forge-migrate-flagship.sh"
ORCH_YAML="$FORGE_ROOT_REAL/.forge/standards/orchestration.yaml"
CHANGELOG="$FORGE_ROOT_REAL/CHANGELOG.md"
FORGE_CI="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"
SNAP="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
SNAP_SHA="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
# L1 (18 tests) — all hermetic; ≤ a few seconds.
# MANIFEST: _test_b813_001_runbook_present          — FR-B813-001
# MANIFEST: _test_b813_002_two_scenarios            — FR-B813-002
# MANIFEST: _test_b813_003_five_steps               — FR-B813-003
# MANIFEST: _test_b813_004_scenario_a_p99           — FR-B813-010 / 012
# MANIFEST: _test_b813_005_scenario_a_methodology   — FR-B813-011
# MANIFEST: _test_b813_006_scenario_b_traceparent   — FR-B813-020 / 021
# MANIFEST: _test_b813_007_fulltree_rollback        — FR-B813-030
# MANIFEST: _test_b813_008_no_dbos_criterion        — FR-B813-031
# MANIFEST: _test_b813_009_runbook_script_consistency — FR-B813-032
# MANIFEST: _test_b813_010_archdoc_frozen           — FR-B813-040
# MANIFEST: _test_b813_011_supersession_note        — FR-B813-041
# MANIFEST: _test_b813_012_migrations_repoint       — FR-B813-050
# MANIFEST: _test_b813_013_no_committed_latency     — FR-B813-060
# MANIFEST: _test_b813_014_frozen_snapshot          — FR-B813-061
# MANIFEST: _test_b813_015_supersession_target_valid — FR-B813-062
# MANIFEST: _test_b813_016_changelog_anchor         — FR-B813-067
# MANIFEST: _test_b813_017_forgeci_registration     — FR-B813-066
# MANIFEST: _test_b813_018_coupling_guards          — FR-B813-068

# FR-B813-001 — runbook exists, titled, audit-stamped
_test_b813_001_runbook_present() {
  if [ ! -f "$ROLLBACK_DOC" ]; then
    echo "    docs/ROLLBACK.md missing: $ROLLBACK_DOC" >&2; return 1
  fi
  if ! grep -qiE "^#.*rollback runbook" "$ROLLBACK_DOC"; then
    echo "    runbook title (# … Rollback Runbook …) missing" >&2; return 1
  fi
  if ! grep -qF "Audit: B.8.13 (b8-13-rollback-runbook)" "$ROLLBACK_DOC"; then
    echo "    audit provenance comment missing" >&2; return 1
  fi
}

# FR-B813-002 — exactly two operational scenarios (A + B)
_test_b813_002_two_scenarios() {
  if ! grep -qE "^##+ +Scenario A" "$ROLLBACK_DOC"; then
    echo "    'Scenario A' heading missing" >&2; return 1
  fi
  if ! grep -qE "^##+ +Scenario B" "$ROLLBACK_DOC"; then
    echo "    'Scenario B' heading missing" >&2; return 1
  fi
  local n; n="$(grep -cE "^##+ +Scenario [AB]" "$ROLLBACK_DOC")"
  if [ "$n" -ne 2 ]; then
    echo "    expected exactly 2 scenario headings, found $n" >&2; return 1
  fi
}

# FR-B813-003 — five operational steps present (each ≥ 2×, one per scenario)
_test_b813_003_five_steps() {
  local step
  for step in Detect Decide Execute Verify Re-attempt; do
    local c; c="$(grep -cE "\*\*${step}\*\*" "$ROLLBACK_DOC")"
    if [ "$c" -lt 2 ]; then
      echo "    step '**${step}**' appears $c× (expected ≥2, one per scenario)" >&2
      return 1
    fi
  done
}

# FR-B813-010 / 012 — Scenario A: p99 > 20 % relative → reverse Kong route weights
_test_b813_004_scenario_a_p99() {
  grep -qF "p99" "$ROLLBACK_DOC" || { echo "    'p99' missing" >&2; return 1; }
  grep -qE "20 ?%" "$ROLLBACK_DOC" || { echo "    '20 %' threshold missing" >&2; return 1; }
  grep -qiF "route weight" "$ROLLBACK_DOC" || { echo "    'route weight' (Kong reversal) missing" >&2; return 1; }
  grep -qF "Kong" "$ROLLBACK_DOC" || { echo "    'Kong' missing" >&2; return 1; }
}

# FR-B813-011 — Scenario A Detect cites the B.8.12 measurement methodology
_test_b813_005_scenario_a_methodology() {
  grep -qF "B.8.12" "$ROLLBACK_DOC" || { echo "    B.8.12 methodology ref missing" >&2; return 1; }
  grep -qiE "methodolog|B8-BASELINE" "$ROLLBACK_DOC" || { echo "    measurement methodology ref missing" >&2; return 1; }
}

# FR-B813-020 / 021 — Scenario B: traceparent > 1 % → OTel SDK overlay only
_test_b813_006_scenario_b_traceparent() {
  grep -qF "traceparent" "$ROLLBACK_DOC" || { echo "    'traceparent' missing" >&2; return 1; }
  grep -qE "1 ?%" "$ROLLBACK_DOC" || { echo "    '1 %' threshold missing" >&2; return 1; }
  grep -qiF "OTel SDK overlay only" "$ROLLBACK_DOC" || { echo "    'OTel SDK overlay only' missing" >&2; return 1; }
}

# FR-B813-030 — last-resort full-tree rollback documented
_test_b813_007_fulltree_rollback() {
  grep -qF -- "--rollback" "$ROLLBACK_DOC" || { echo "    '--rollback' missing" >&2; return 1; }
  grep -qE "byte-frozen 1\.0\.0|1\.0\.0 snapshot" "$ROLLBACK_DOC" || { echo "    1.0.0 snapshot ref missing" >&2; return 1; }
  grep -qiE "mutually exclusive.*--phase|--phase.*mutually exclusive" "$ROLLBACK_DOC" || { echo "    --rollback/--phase mutual-exclusion note missing" >&2; return 1; }
}

# FR-B813-031 — explicit no-DBOS / no-CPU criterion statement
_test_b813_008_no_dbos_criterion() {
  if ! grep -qiE "no DBOS[- ].*criterion|no DBOS- or CPU" "$ROLLBACK_DOC"; then
    echo "    explicit 'no DBOS/CPU-based criterion' statement missing" >&2; return 1
  fi
}

# FR-B813-032 — runbook ↔ migrate-script embedded criteria consistency
_test_b813_009_runbook_script_consistency() {
  [ -f "$MIGRATE_SH" ] || { echo "    forge-migrate-flagship.sh missing" >&2; return 1; }
  # The script's embedded criteria (the stable anchor) must still be present …
  grep -qF "roll back Kong" "$MIGRATE_SH" || { echo "    script lost 'roll back Kong' criterion" >&2; return 1; }
  grep -qF "roll back OTel SDK only" "$MIGRATE_SH" || { echo "    script lost 'roll back OTel SDK only' criterion" >&2; return 1; }
  grep -qF "no CPU criterion" "$MIGRATE_SH" || { echo "    script lost 'no CPU criterion' note" >&2; return 1; }
  # … and the runbook must echo the same three anchors.
  grep -qF "roll back Kong" "$ROLLBACK_DOC" || { echo "    runbook missing 'roll back Kong'" >&2; return 1; }
  grep -qF "roll back OTel SDK only" "$ROLLBACK_DOC" || { echo "    runbook missing 'roll back OTel SDK only'" >&2; return 1; }
  grep -qF "no CPU criterion" "$ROLLBACK_DOC" || { echo "    runbook missing 'no CPU criterion'" >&2; return 1; }
}

# FR-B813-040 — ARCHITECTURE-TARGET.md left byte-frozen (t4 pin intact)
_test_b813_010_archdoc_frozen() {
  [ -f "$ARCH_DOC" ] || { echo "    ARCHITECTURE-TARGET.md missing" >&2; return 1; }
  [ -f "$T4_SPECS" ] || { echo "    t4-adr-ratification/specs.md missing" >&2; return 1; }
  local actual expected
  actual="$(shasum -a 256 "$ARCH_DOC" | awk '{print $1}')"
  expected="$(grep -oE '[a-f0-9]{64}' "$T4_SPECS" | head -1 || true)"
  if [ -z "$expected" ]; then
    echo "    pinned hash not found in t4 specs.md" >&2; return 1
  fi
  if [ "$actual" != "$expected" ]; then
    echo "    ARCHITECTURE-TARGET.md was edited — t4 pin would break (expected=$expected actual=$actual)" >&2
    return 1
  fi
}

# FR-B813-041 — Supersession note enumerates the 7 stale arch-doc refs
_test_b813_011_supersession_note() {
  grep -qiF "Supersession" "$ROLLBACK_DOC" || { echo "    'Supersession' note missing" >&2; return 1; }
  grep -qiE "obsolete per B8O|obsolete.*B8O" "$ROLLBACK_DOC" || { echo "    'obsolete per B8O' framing missing" >&2; return 1; }
  grep -qF "orchestration.yaml" "$ROLLBACK_DOC" || { echo "    authoritative-record pointer (orchestration.yaml) missing" >&2; return 1; }
  local ref
  for ref in "§11.1" "§11.2" "§11.3" "§11.4" "§12.1"; do
    grep -qF "$ref" "$ROLLBACK_DOC" || { echo "    stale-ref enumeration missing $ref" >&2; return 1; }
  done
}

# FR-B813-050 — MIGRATIONS.md forward-reference resolves to ROLLBACK.md
_test_b813_012_migrations_repoint() {
  [ -f "$MIGRATIONS" ] || { echo "    MIGRATIONS.md missing" >&2; return 1; }
  grep -qF "ROLLBACK.md" "$MIGRATIONS" || { echo "    MIGRATIONS.md does not link docs/ROLLBACK.md" >&2; return 1; }
}

# FR-B813-060 — no committed absolute latency figure in the runbook
_test_b813_013_no_committed_latency() {
  local hit
  # abbreviated units (5 ms / 120us / 3 µs / 9ns)
  hit="$(grep -nE '[0-9]+ *(ms|µs|us|ns)\b' "$ROLLBACK_DOC" || true)"
  if [ -n "$hit" ]; then
    echo "    committed absolute latency unit (abbrev) found in runbook:" >&2
    printf '%s\n' "$hit" | sed 's/^/      /' >&2
    return 1
  fi
  # spelled-out units (120 milliseconds / 9 microseconds / nanoseconds)
  hit="$(grep -niE '[0-9]+ *(milli|micro|nano)second' "$ROLLBACK_DOC" || true)"
  if [ -n "$hit" ]; then
    echo "    committed absolute latency unit (spelled) found in runbook:" >&2
    printf '%s\n' "$hit" | sed 's/^/      /' >&2
    return 1
  fi
  # an assigned p95/p99 value (p99 = 120 / p99 was 120 / p95: 80 / p99 reached 5)
  hit="$(grep -niE 'p9[59] *([=:]|( +(was|is|reached|hit|measured|of) +)) *[0-9]' "$ROLLBACK_DOC" || true)"
  if [ -n "$hit" ]; then
    echo "    committed p95/p99 value found in runbook:" >&2
    printf '%s\n' "$hit" | sed 's/^/      /' >&2
    return 1
  fi
}

# FR-B813-061 — frozen 1.0.0 snapshot byte-identity (b8-2 invariant)
_test_b813_014_frozen_snapshot() {
  [ -f "$SNAP" ] || { echo "    1.0.0 snapshot missing: $SNAP" >&2; return 1; }
  [ -f "$SNAP_SHA" ] || { echo "    1.0.0 snapshot .sha256 missing: $SNAP_SHA" >&2; return 1; }
  local actual expected
  actual="$(shasum -a 256 "$SNAP" | awk '{print $1}')"
  expected="$(grep -oE '[a-f0-9]{64}' "$SNAP_SHA" | head -1 || true)"
  if [ "$actual" != "$expected" ]; then
    echo "    1.0.0 snapshot drifted (expected=$expected actual=$actual)" >&2; return 1
  fi
}

# FR-B813-062 — supersession-target valid (orchestration.yaml unchanged at v1.2.0)
_test_b813_015_supersession_target_valid() {
  [ -f "$ORCH_YAML" ] || { echo "    orchestration.yaml missing" >&2; return 1; }
  grep -qE "version: *['\"]?1\.2\.0" "$ORCH_YAML" || { echo "    orchestration.yaml not v1.2.0 (supersession pointer stale)" >&2; return 1; }
  grep -qE "rust: *temporal" "$ORCH_YAML" || { echo "    orchestration.yaml rust:temporal default missing" >&2; return 1; }
}

# FR-B813-067 — CHANGELOG anchor (whole-file)
_test_b813_016_changelog_anchor() {
  [ -f "$CHANGELOG" ] || { echo "    CHANGELOG.md missing" >&2; return 1; }
  grep -qF "b8-13" "$CHANGELOG" || { echo "    b8-13 anchor missing in CHANGELOG.md" >&2; return 1; }
}

# FR-B813-066 — forge-ci registration
_test_b813_017_forgeci_registration() {
  [ -f "$FORGE_CI" ] || { echo "    forge-ci.yml missing" >&2; return 1; }
  grep -qF "b8-13.test.sh" "$FORGE_CI" || { echo "    b8-13.test.sh not registered in forge-ci.yml" >&2; return 1; }
}

# FR-B813-068 — coupling guards: b8-12 + b8-10 + t4 green by exit code
_test_b813_018_coupling_guards() {
  local sib out
  for sib in b8-12 b8-10 t4; do
    if [ ! -f "$HARNESS_DIR/${sib}.test.sh" ]; then
      echo "    ${sib}.test.sh missing" >&2; return 1
    fi
    if ! out="$(bash "$HARNESS_DIR/${sib}.test.sh" --level 1 2>&1)"; then
      echo "    ${sib}.test.sh --level 1 exited non-zero (coupling break):" >&2
      printf '%s\n' "$out" | grep -E "✗|Failed:|Failures:|    -" | sed 's/^/      /' >&2
      return 1
    fi
  done
}

# ─── Main ────────────────────────────────────────────────────────
main() {
  echo "── B.8.13 — b8-13-rollback-runbook — level $LEVEL ──"
  echo ""
  echo "L1 — runbook structure"
  run_test _test_b813_001_runbook_present
  run_test _test_b813_002_two_scenarios
  run_test _test_b813_003_five_steps

  echo ""
  echo "L1 — scenarios + criteria"
  run_test _test_b813_004_scenario_a_p99
  run_test _test_b813_005_scenario_a_methodology
  run_test _test_b813_006_scenario_b_traceparent
  run_test _test_b813_007_fulltree_rollback
  run_test _test_b813_008_no_dbos_criterion
  run_test _test_b813_009_runbook_script_consistency

  echo ""
  echo "L1 — record-only supersession + frozen invariants"
  run_test _test_b813_010_archdoc_frozen
  run_test _test_b813_011_supersession_note
  run_test _test_b813_012_migrations_repoint
  run_test _test_b813_013_no_committed_latency
  run_test _test_b813_014_frozen_snapshot
  run_test _test_b813_015_supersession_target_valid

  echo ""
  echo "L1 — CHANGELOG/CI + coupling"
  run_test _test_b813_016_changelog_anchor
  run_test _test_b813_017_forgeci_registration
  run_test _test_b813_018_coupling_guards

  print_summary
}

main "$@"
