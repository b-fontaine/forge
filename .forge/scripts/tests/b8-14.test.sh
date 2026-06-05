#!/usr/bin/env bash
# Forge — B.8.14 promotion-prep harness (prepare-only governance brick)
# <!-- Audit: B.8.14 (b8-14-promotion-prep) -->
#
# B.8.14 is the point of no return (amend §VIII.1 Kong→Envoy + promote 2.0.0 +
# remove Kong/REST). The amendment is process-gated by a ≥7-day public window
# (Article XII + GOVERNANCE.md), so this brick is PREPARE-ONLY: it applies
# NOTHING breaking and ships staged artifacts.
#
# The load-bearing tests are NEGATIVE held-state guards — they prove the flip was
# NOT applied (so a premature flip cannot merge green). Positive tests check the
# staged artifacts exist + are well-formed + the removal targets are real.
#
# All L1, hermetic (grep/diff/stat/shasum). ≤ a few seconds.

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

CHANGE_DIR="$FORGE_ROOT_REAL/.forge/changes/b8-14-promotion-prep"
AMENDMENT="$CHANGE_DIR/amendment-viii-1.md"
MANIFEST="$CHANGE_DIR/removal-manifest.yaml"
RUNBOOK="$CHANGE_DIR/flip-runbook.md"
CONSTITUTION="$FORGE_ROOT_REAL/.forge/constitution.md"
SCHEMA_20="$FORGE_ROOT_REAL/.forge/schemas/full-stack-monorepo/2.0.0.yaml"
KONG_STD="$FORGE_ROOT_REAL/.forge/standards/infra/kong.md"
B="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo"
COMPOSE="$B/docker-compose.dev.yml.tmpl"
KONG_TMPL="$B/infra/kong/kong.yml.example.tmpl"
ENV_TMPL="$B/.env.example.tmpl"
SCAFFOLD_PLAN="$B/scaffold-plan.yaml"
SNAP="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
SNAP_SHA="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256"
CHANGELOG="$FORGE_ROOT_REAL/CHANGELOG.md"
FORGE_CI="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
# L1 (15 tests) — negative held-guards + positive staged-artifact checks.
# MANIFEST: _test_b814_001_constitution_held        — FR-B814-003/030
# MANIFEST: _test_b814_002_no_amendment_applied      — FR-B814-003
# MANIFEST: _test_b814_003_schema_not_promoted       — FR-B814-030
# MANIFEST: _test_b814_004_kong_targets_intact       — FR-B814-011/032
# MANIFEST: _test_b814_005_no_forbidden_mutation     — FR-B814-031/032
# MANIFEST: _test_b814_006_amendment_present          — FR-B814-001
# MANIFEST: _test_b814_007_amendment_cites_process    — FR-B814-002
# MANIFEST: _test_b814_008_amendment_has_row          — FR-B814-001
# MANIFEST: _test_b814_009_manifest_targets_real      — FR-B814-010
# MANIFEST: _test_b814_010_manifest_distinguishes     — FR-B814-010
# MANIFEST: _test_b814_011_runbook_present            — FR-B814-020
# MANIFEST: _test_b814_012_deprecation_draft          — FR-B814-021
# MANIFEST: _test_b814_013_changelog_anchor           — FR-B814-041
# MANIFEST: _test_b814_014_forgeci_registration       — FR-B814-040
# MANIFEST: _test_b814_015_coupling_guards            — FR-B814-042

# ── Negative held-state guards (prove the flip was NOT applied) ──

# FR-B814-003/030 — constitution byte-held: v1.1.0 + §VIII.1 still Kong SHALL
_test_b814_001_constitution_held() {
  [ -f "$CONSTITUTION" ] || { echo "    constitution.md missing" >&2; return 1; }
  # Post-flip (b8-14-promotion-flip): constitution ratified to v2.0.0 + §VIII.1 Envoy.
  grep -qE '^\*\*Version\*\*: *v2\.0\.0' "$CONSTITUTION" || { echo "    constitution Version is not v2.0.0 (amendment not ratified?)" >&2; return 1; }
  grep -qiF "Envoy Gateway SHALL be used as the API gateway" "$CONSTITUTION" || { echo "    §VIII.1 'Envoy Gateway SHALL' missing (amendment not applied?)" >&2; return 1; }
}

# FR-B814-003 — no gateway/Envoy amendment ratified (Amendments table clean)
_test_b814_002_no_amendment_applied() {
  # Post-flip: the §VIII.1 amendment IS applied — the constitution now names Envoy
  # and the Amendments table carries row #2.
  grep -qiF "envoy" "$CONSTITUTION" || { echo "    constitution does not mention Envoy (amendment not applied)" >&2; return 1; }
  grep -qE '^\| 2 \| 20[0-9]{2}-[0-9]{2}-[0-9]{2} \|' "$CONSTITUTION" || { echo "    Amendments row #2 (§VIII.1) missing" >&2; return 1; }
}

# FR-B814-030 — 2.0.0 schema promoted (post-C2). Func name retained for manifest
# stability (cf. _001/_002 post-C1); the body now asserts the FLIPPED state.
_test_b814_003_schema_not_promoted() {
  [ -f "$SCHEMA_20" ] || { echo "    2.0.0.yaml missing" >&2; return 1; }
  grep -qE '^stage: *stable' "$SCHEMA_20" || { echo "    2.0.0.yaml stage != stable (promotion not applied?)" >&2; return 1; }
  grep -qE '^scaffoldable: *true' "$SCHEMA_20" || { echo "    2.0.0.yaml scaffoldable != true (flip not applied?)" >&2; return 1; }
}

# FR-B814-011/032 — Kong/REST removal NOT executed (targets + snapshot intact)
_test_b814_004_kong_targets_intact() {
  grep -qE '^  fsm-kong:' "$COMPOSE" || { echo "    fsm-kong removed from 1.0.0 compose (removal executed?)" >&2; return 1; }
  [ -f "$KONG_TMPL" ] || { echo "    infra/kong/kong.yml.example.tmpl removed" >&2; return 1; }
  [ -f "$KONG_STD" ] || { echo "    .forge/standards/infra/kong.md removed" >&2; return 1; }
  local actual expected
  actual="$(shasum -a 256 "$SNAP" | awk '{print $1}')"
  expected="$(grep -oE '[a-f0-9]{64}' "$SNAP_SHA" | head -1 || true)"
  if [ "$actual" != "$expected" ]; then
    echo "    frozen 1.0.0 snapshot drifted (expected=$expected actual=$actual)" >&2; return 1
  fi
}

# FR-B814-031/032 — no forbidden file mutated vs HEAD (constitution/schema/standards/templates)
_test_b814_005_no_forbidden_mutation() {
  # RETIRED post-flip (b8-14-promotion-flip): this guard existed only to prove the
  # PREPARE brick applied nothing breaking. The flip legitimately amends the
  # constitution + promotes 2.0.0, so the prepare-only no-mutation invariant no
  # longer holds. The flipped state is asserted by b8-14-flip.test.sh + the
  # inverted _001/_002 above. Kept as a passing no-op for manifest stability.
  return 0
}

# ── Positive staged-artifact checks ──

# FR-B814-001 — amendment draft present + Envoy SHALL + target v2.0.0
_test_b814_006_amendment_present() {
  [ -f "$AMENDMENT" ] || { echo "    amendment-viii-1.md missing" >&2; return 1; }
  grep -qF "Audit: B.8.14 (b8-14-promotion-prep)" "$AMENDMENT" || { echo "    audit comment missing" >&2; return 1; }
  grep -qiF "VIII.1" "$AMENDMENT" || { echo "    §VIII.1 reference missing" >&2; return 1; }
  grep -qiE "Envoy.*SHALL|SHALL.*Envoy" "$AMENDMENT" || { echo "    proposed 'Envoy … SHALL' text missing" >&2; return 1; }
  grep -qE "v?2\.0\.0" "$AMENDMENT" || { echo "    target Constitution version v2.0.0 missing" >&2; return 1; }
}

# FR-B814-002 — amendment cites the real process + sources (anti-fabrication)
_test_b814_007_amendment_cites_process() {
  grep -qiF "Amendment Process" "$AMENDMENT" || { echo "    'Amendment Process' citation missing" >&2; return 1; }
  grep -qiE "7[- ](day|jour)" "$AMENDMENT" || { echo "    7-day public window citation missing" >&2; return 1; }
  grep -qF "d5-governance" "$AMENDMENT" || { echo "    d5-governance precedent missing" >&2; return 1; }
  grep -qF "VERSIONING" "$AMENDMENT" || { echo "    VERSIONING citation missing" >&2; return 1; }
  grep -qF "GOVERNANCE" "$AMENDMENT" || { echo "    GOVERNANCE citation missing" >&2; return 1; }
}

# FR-B814-001 — amendment includes the proposed Amendments-table row
_test_b814_008_amendment_has_row() {
  grep -qiF "Amendments" "$AMENDMENT" || { echo "    Amendments-table reference missing" >&2; return 1; }
  # a markdown table row mentioning the gateway amendment
  grep -qE '^\| *2 *\|' "$AMENDMENT" || { echo "    proposed Amendment #2 row missing" >&2; return 1; }
}

# FR-B814-010 — removal manifest enumerates real targets (anti-fabrication)
_test_b814_009_manifest_targets_real() {
  [ -f "$MANIFEST" ] || { echo "    removal-manifest.yaml missing" >&2; return 1; }
  # enumerated anchors present in the manifest …
  local anchor
  for anchor in "infra/kong" "fsm-kong" "FSM_KONG_ADMIN_PORT" "standards/infra/kong.md"; do
    grep -qF "$anchor" "$MANIFEST" || { echo "    manifest omits target '$anchor'" >&2; return 1; }
  done
  # … and each target actually exists in the live tree (not fabricated)
  [ -d "$B/infra/kong" ] || { echo "    target infra/kong/ does not exist" >&2; return 1; }
  grep -qE '^  fsm-kong:' "$COMPOSE" || { echo "    target fsm-kong does not exist in compose" >&2; return 1; }
  grep -qF "FSM_KONG_ADMIN_PORT" "$ENV_TMPL" || { echo "    target FSM_KONG_ADMIN_PORT not in .env" >&2; return 1; }
  [ -f "$KONG_STD" ] || { echo "    target kong.md standard does not exist" >&2; return 1; }
  grep -qF "infra/kong" "$SCAFFOLD_PLAN" || { echo "    target kong entry not in scaffold-plan" >&2; return 1; }
}

# FR-B814-010 — manifest distinguishes scaffold-composition vs framework-standard targets
_test_b814_010_manifest_distinguishes() {
  grep -qiE "scaffold.composition|scaffold_composition|composition" "$MANIFEST" || { echo "    manifest lacks scaffold-composition category" >&2; return 1; }
  grep -qiE "framework.standard|framework_standard|standard" "$MANIFEST" || { echo "    manifest lacks framework-standard category" >&2; return 1; }
}

# FR-B814-020 — flip runbook present, ordered, with the key gates
_test_b814_011_runbook_present() {
  [ -f "$RUNBOOK" ] || { echo "    flip-runbook.md missing" >&2; return 1; }
  grep -qiF "ratif" "$RUNBOOK" || { echo "    runbook missing ratification step" >&2; return 1; }
  grep -qF "scaffoldable: true" "$RUNBOOK" || { echo "    runbook missing scaffoldable:true flip step" >&2; return 1; }
  grep -qiF "removal" "$RUNBOOK" || { echo "    runbook missing removal step" >&2; return 1; }
  grep -qiF "t4" "$RUNBOOK" || { echo "    runbook missing t4 material-path note" >&2; return 1; }
  grep -qiE "70-73|pre-GA|BREAKING" "$RUNBOOK" || { echo "    runbook missing framework-version pin (VERSIONING:70-73 pre-GA)" >&2; return 1; }
}

# FR-B814-021 — 1.0.0 deprecation announcement drafted (T+6mo)
_test_b814_012_deprecation_draft() {
  grep -qiF "deprecat" "$RUNBOOK" || { echo "    deprecation draft missing" >&2; return 1; }
  grep -qiE "6[- ](month|mois)|T\+6" "$RUNBOOK" || { echo "    T+6-month deprecation window missing" >&2; return 1; }
}

# FR-B814-041 — CHANGELOG anchor (prepare-only)
_test_b814_013_changelog_anchor() {
  [ -f "$CHANGELOG" ] || { echo "    CHANGELOG.md missing" >&2; return 1; }
  grep -qF "b8-14" "$CHANGELOG" || { echo "    b8-14 anchor missing in CHANGELOG" >&2; return 1; }
}

# FR-B814-040 — forge-ci registration
_test_b814_014_forgeci_registration() {
  [ -f "$FORGE_CI" ] || { echo "    forge-ci.yml missing" >&2; return 1; }
  grep -qF "b8-14.test.sh" "$FORGE_CI" || { echo "    b8-14.test.sh not registered in forge-ci.yml" >&2; return 1; }
}

# FR-B814-042 — coupling guards: b8-13 + t4 + b8-3 green by exit code
_test_b814_015_coupling_guards() {
  local sib out
  for sib in b8-13 t4 b8-3; do
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
  echo "── B.8.14 — b8-14-promotion-prep — level $LEVEL ──"
  echo ""
  echo "L1 — negative held-state guards (flip NOT applied)"
  run_test _test_b814_001_constitution_held
  run_test _test_b814_002_no_amendment_applied
  run_test _test_b814_003_schema_not_promoted
  run_test _test_b814_004_kong_targets_intact
  run_test _test_b814_005_no_forbidden_mutation

  echo ""
  echo "L1 — staged amendment draft"
  run_test _test_b814_006_amendment_present
  run_test _test_b814_007_amendment_cites_process
  run_test _test_b814_008_amendment_has_row

  echo ""
  echo "L1 — staged removal manifest"
  run_test _test_b814_009_manifest_targets_real
  run_test _test_b814_010_manifest_distinguishes

  echo ""
  echo "L1 — flip runbook + deprecation draft"
  run_test _test_b814_011_runbook_present
  run_test _test_b814_012_deprecation_draft

  echo ""
  echo "L1 — CHANGELOG/CI + coupling"
  run_test _test_b814_013_changelog_anchor
  run_test _test_b814_014_forgeci_registration
  run_test _test_b814_015_coupling_guards

  print_summary
}

main "$@"
