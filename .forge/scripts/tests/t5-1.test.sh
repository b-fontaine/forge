#!/usr/bin/env bash
# Forge — T5.1 CLI Trust Harness Test Harness (cli-trust-harness)
# <!-- Audit: T5.1 (cli-trust-harness) -->
#
# Validates the T5.1 deliverables :
#
#   - Layer T5.1.0 : Taskfile.yml.tmpl single-quote sweep
#     (`.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl:67`
#     + any sibling unquoted `: ` in `cmds:` lists across templates).
#   - Layer T5.1.A : golden snapshot of CLI flags
#     (`cli/test/e2e/help-snapshots.test.ts` + 5 `.snap.txt` files
#     under `cli/test/e2e/__snapshots__/help/` + dispatch-table
#     cross-reference).
#   - Layer T5.1.B : smoke test per archetype
#     (`cli/test/e2e/archetypes-smoke.test.ts` + YAML fixtures under
#     `cli/test/e2e/archetype-fixtures/<name>.yml` + mini-YAML parser
#     at `cli/test/e2e/helpers/load-fixture.ts`).
#   - Layer T5.1.C : pre-publish tarball gate
#     (`cli/scripts/prepublish-smoke.mjs` wired into
#     `cli/package.json::prepublishOnly` ; `FORGE_SKIP_PREPUBLISH=1`
#     emergency override per ADR-T51-005).
#   - GOVERNANCE.md § Release Process updated to document the new gate.
#   - CHANGELOG.md [Unreleased] entry citing cli-trust-harness.
#   - Layer D (forge upgrade matrix) deferred to B.8.15.
#
# 17 L1 + 2 L2 = 19 tests.
# Performance budget : L1 ≤ 5 s wall-clock (NFR-T51-002).

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

TASKFILE_TMPL="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl"
HELP_TEST="$FORGE_ROOT_REAL/cli/test/e2e/help-snapshots.test.ts"
SMOKE_TEST="$FORGE_ROOT_REAL/cli/test/e2e/archetypes-smoke.test.ts"
SNAPSHOTS_DIR="$FORGE_ROOT_REAL/cli/test/e2e/__snapshots__/help"
FIXTURES_DIR="$FORGE_ROOT_REAL/cli/test/e2e/archetype-fixtures"
LOAD_FIXTURE_HELPER="$FORGE_ROOT_REAL/cli/test/e2e/helpers/load-fixture.ts"
PREPUBLISH_SCRIPT="$FORGE_ROOT_REAL/cli/scripts/prepublish-smoke.mjs"
CLI_PACKAGE_JSON="$FORGE_ROOT_REAL/cli/package.json"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
GOVERNANCE_MD="$FORGE_ROOT_REAL/GOVERNANCE.md"
CI_WORKFLOW="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"
DISPATCH_TABLE="$FORGE_ROOT_REAL/.forge/scaffolding/dispatch-table.yml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (17 tests)
# MANIFEST: _test_t51_l1_001_taskfile_line67_quoted   — FR-T51-001
# MANIFEST: _test_t51_l1_002_no_unquoted_colon_space  — FR-T51-002 / FR-T51-003
# MANIFEST: _test_t51_l1_003_help_snapshots_file      — FR-T51-020 / FR-T51-021
# MANIFEST: _test_t51_l1_004_snapshots_dir_5files     — FR-T51-022 / FR-T51-023
# MANIFEST: _test_t51_l1_005_smoke_file               — FR-T51-040
# MANIFEST: _test_t51_l1_006_fixture_fsm              — FR-T51-046 / FR-T51-053
# MANIFEST: _test_t51_l1_007_fixture_mobile_only      — FR-T51-046 / FR-T51-054
# MANIFEST: _test_t51_l1_008_load_fixture_helper      — FR-T51-047 / ADR-T51-002
# MANIFEST: _test_t51_l1_009_prepublish_script        — FR-T51-090
# MANIFEST: _test_t51_l1_010_prepublish_wired         — FR-T51-097 / MR-T51-001
# MANIFEST: _test_t51_l1_011_skip_prepublish_env      — FR-T51-098 / ADR-T51-005
# MANIFEST: _test_t51_l1_012_toolchains_env           — FR-T51-050 / FR-T51-051 / ADR-T51-001
# MANIFEST: _test_t51_l1_013_changelog_entry          — FR-T51-150
# MANIFEST: _test_t51_l1_014_governance_gate_doc      — FR-T51-099 / MR-T51-004
# MANIFEST: _test_t51_l1_015_ci_registration          — FR-T51-126
# MANIFEST: _test_t51_l1_016_dispatch_xref            — FR-T51-055
# MANIFEST: _test_t51_l1_017_ci_line_budget           — FR-T51-127 / NFR-T51-005
#
# L2 (2 tests, opt-in via env-var ; skip-pass otherwise)
# MANIFEST: _test_t51_l2_smoke_one_archetype          — FR-T51-125 / FORGE_T51_LIVE=1
# MANIFEST: _test_t51_l2_pack_isolation               — FR-T51-125 / FORGE_T51_PACK=1

# ─── L1 tests ────────────────────────────────────────────────────

_not_implemented() {
  echo "    not implemented yet (RED witness)" >&2
  return 1
}

# FR-T51-001 — Taskfile.yml.tmpl line 67 single-quoted
_test_t51_l1_001_taskfile_line67_quoted() {
  if [ ! -f "$TASKFILE_TMPL" ]; then
    echo "    Taskfile template missing: $TASKFILE_TMPL" >&2; return 1
  fi
  # The single-quoted form is what go-task / strict YAML parses as a string.
  if ! grep -Fq -- "- 'echo \"infra tests: delegated to b1-delivery workflows\"'" "$TASKFILE_TMPL"; then
    echo "    Taskfile.yml.tmpl missing single-quoted form of the infra-tests command" >&2
    return 1
  fi
  # The buggy plain-scalar form MUST be absent.
  if grep -Eq '^[[:space:]]*-[[:space:]]+echo "infra tests:' "$TASKFILE_TMPL"; then
    echo "    Taskfile.yml.tmpl still contains unquoted 'echo \"infra tests: ...\"'" >&2
    return 1
  fi
}

# FR-T51-002 / FR-T51-003 — no unquoted ': ' in cmds: lists across templates
_test_t51_l1_002_no_unquoted_colon_space() {
  # Recipe verbatim from design.md § "Sweep recipe for FR-T51-002".
  local matches
  matches=$(grep -rn -E '^[[:space:]]*-[[:space:]]+echo[[:space:]]+"[^"]*:[[:space:]]' \
    "$FORGE_ROOT_REAL/.forge/templates/" \
    "$FORGE_ROOT_REAL/examples/" \
    "$FORGE_ROOT_REAL/cli/assets/" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "    found unquoted ': '-bearing echo commands in templates/examples/assets:" >&2
    printf '%s\n' "$matches" | head -10 | sed 's/^/      /' >&2
    return 1
  fi
}

# FR-T51-020 / FR-T51-021 — help-snapshots.test.ts exists + audit comment
_test_t51_l1_003_help_snapshots_file() {
  if [ ! -f "$HELP_TEST" ]; then
    echo "    help-snapshots.test.ts missing: $HELP_TEST" >&2; return 1
  fi
  if ! head -10 "$HELP_TEST" | grep -Fq "Audit: T5.1 (cli-trust-harness)"; then
    echo "    help-snapshots.test.ts missing audit comment in first 10 lines" >&2
    return 1
  fi
}

# FR-T51-022 / FR-T51-023 — __snapshots__/help/ contains 5 .snap.txt files
_test_t51_l1_004_snapshots_dir_5files() {
  if [ ! -d "$SNAPSHOTS_DIR" ]; then
    echo "    snapshots dir missing: $SNAPSHOTS_DIR" >&2; return 1
  fi
  local count
  count=$(find "$SNAPSHOTS_DIR" -maxdepth 1 -name "*.snap.txt" -type f | wc -l | tr -d ' ')
  if [ "$count" -ne 5 ]; then
    echo "    expected 5 .snap.txt files under $SNAPSHOTS_DIR, found $count" >&2
    return 1
  fi
  # Sanity-check each canonical name is present.
  # `local snap` is required — bash dynamic scoping would otherwise leak this
  # loop variable into run_test's caller frame (where `name` is the test
  # function's identifier) and the post-call `echo "  ✓ ${name}"` would print
  # the leaked loop value instead of the test name.
  local snap
  for snap in root init upgrade verify version; do
    if [ ! -f "$SNAPSHOTS_DIR/${snap}.snap.txt" ]; then
      echo "    snapshot file missing: ${snap}.snap.txt" >&2; return 1
    fi
  done
}

# FR-T51-040 — archetypes-smoke.test.ts exists + audit comment
_test_t51_l1_005_smoke_file() {
  if [ ! -f "$SMOKE_TEST" ]; then
    echo "    archetypes-smoke.test.ts missing: $SMOKE_TEST" >&2; return 1
  fi
  if ! head -10 "$SMOKE_TEST" | grep -Fq "Audit: T5.1 (cli-trust-harness)"; then
    echo "    archetypes-smoke.test.ts missing audit comment in first 10 lines" >&2
    return 1
  fi
}

# FR-T51-046 / FR-T51-053 — full-stack-monorepo.yml fixture exists + audit
_test_t51_l1_006_fixture_fsm() {
  local f="$FIXTURES_DIR/full-stack-monorepo.yml"
  if [ ! -f "$f" ]; then
    echo "    fixture missing: $f" >&2; return 1
  fi
  if ! head -10 "$f" | grep -Fq "Audit: T5.1 (cli-trust-harness)"; then
    echo "    full-stack-monorepo.yml missing audit comment" >&2; return 1
  fi
  for required in "archetype: full-stack-monorepo" "required_paths:" "forbidden_paths:"; do
    if ! grep -Fq -- "$required" "$f"; then
      echo "    fixture missing required key: $required" >&2; return 1
    fi
  done
}

# FR-T51-046 / FR-T51-054 — mobile-only.yml fixture exists + audit
_test_t51_l1_007_fixture_mobile_only() {
  local f="$FIXTURES_DIR/mobile-only.yml"
  if [ ! -f "$f" ]; then
    echo "    fixture missing: $f" >&2; return 1
  fi
  if ! head -10 "$f" | grep -Fq "Audit: T5.1 (cli-trust-harness)"; then
    echo "    mobile-only.yml missing audit comment" >&2; return 1
  fi
  for required in "archetype: mobile-only" "required_paths:" "forbidden_paths:"; do
    if ! grep -Fq -- "$required" "$f"; then
      echo "    fixture missing required key: $required" >&2; return 1
    fi
  done
}

# FR-T51-047 / ADR-T51-002 — load-fixture.ts helper exists + audit
_test_t51_l1_008_load_fixture_helper() {
  if [ ! -f "$LOAD_FIXTURE_HELPER" ]; then
    echo "    load-fixture.ts missing: $LOAD_FIXTURE_HELPER" >&2; return 1
  fi
  if ! head -10 "$LOAD_FIXTURE_HELPER" | grep -Fq "Audit: T5.1 (cli-trust-harness)"; then
    echo "    load-fixture.ts missing audit comment" >&2; return 1
  fi
  # Sanity-check the exported types are present.
  for sym in "ArchetypeFixture" "parseFixture" "loadFixture"; do
    if ! grep -Fq -- "$sym" "$LOAD_FIXTURE_HELPER"; then
      echo "    load-fixture.ts missing exported symbol: $sym" >&2; return 1
    fi
  done
}

# FR-T51-090 — prepublish-smoke.mjs exists + audit comment
_test_t51_l1_009_prepublish_script() {
  if [ ! -f "$PREPUBLISH_SCRIPT" ]; then
    echo "    prepublish-smoke.mjs missing: $PREPUBLISH_SCRIPT" >&2; return 1
  fi
  if ! head -10 "$PREPUBLISH_SCRIPT" | grep -Fq "Audit: T5.1 (cli-trust-harness)"; then
    echo "    prepublish-smoke.mjs missing audit comment in first 10 lines" >&2
    return 1
  fi
}

# FR-T51-097 / MR-T51-001 — package.json prepublishOnly wired to smoke script
_test_t51_l1_010_prepublish_wired() {
  if [ ! -f "$CLI_PACKAGE_JSON" ]; then
    echo "    cli/package.json missing: $CLI_PACKAGE_JSON" >&2; return 1
  fi
  # The prepublishOnly script must chain through prepublish-smoke.mjs.
  if ! grep -Fq "prepublish-smoke.mjs" "$CLI_PACKAGE_JSON"; then
    echo "    cli/package.json::prepublishOnly does not reference prepublish-smoke.mjs" >&2
    return 1
  fi
}

# FR-T51-098 / ADR-T51-005 — FORGE_SKIP_PREPUBLISH referenced in smoke script
_test_t51_l1_011_skip_prepublish_env() {
  if [ ! -f "$PREPUBLISH_SCRIPT" ]; then
    echo "    prepublish-smoke.mjs missing: $PREPUBLISH_SCRIPT" >&2; return 1
  fi
  if ! grep -Fq "FORGE_SKIP_PREPUBLISH" "$PREPUBLISH_SCRIPT"; then
    echo "    prepublish-smoke.mjs does not honor FORGE_SKIP_PREPUBLISH (ADR-T51-005)" >&2
    return 1
  fi
  if ! grep -Fq "BYPASS" "$PREPUBLISH_SCRIPT"; then
    echo "    prepublish-smoke.mjs missing BYPASS keyword in override warning (NFR-T51-004)" >&2
    return 1
  fi
}

# FR-T51-050 / FR-T51-051 / ADR-T51-001 — FORGE_E2E_TOOLCHAINS referenced
_test_t51_l1_012_toolchains_env() {
  if [ ! -f "$SMOKE_TEST" ]; then
    echo "    smoke test file missing: $SMOKE_TEST" >&2; return 1
  fi
  if ! grep -Fq "FORGE_E2E_TOOLCHAINS" "$SMOKE_TEST"; then
    echo "    smoke test does not reference FORGE_E2E_TOOLCHAINS env-var (ADR-T51-001)" >&2
    return 1
  fi
}

# FR-T51-150 — CHANGELOG entry for cli-trust-harness
# Semantics : before release, the change must appear under [Unreleased].
# Once archived AND released, the entry migrates to a versioned section
# (Keep-a-Changelog 1.1.0) ; in that case any released section suffices.
_test_t51_l1_013_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing: $CHANGELOG_MD" >&2; return 1
  fi
  local change_yaml="$FORGE_ROOT_REAL/.forge/changes/cli-trust-harness/.forge.yaml"
  local archived=0
  if [ -f "$change_yaml" ] && grep -Eq '^status:[[:space:]]*archived' "$change_yaml"; then
    archived=1
  fi
  if [ "$archived" -eq 1 ]; then
    # Accept any mention in the file (released section is fine).
    if ! grep -Fq "cli-trust-harness" "$CHANGELOG_MD"; then
      echo "    CHANGELOG.md does not mention cli-trust-harness anywhere (archived change)" >&2
      return 1
    fi
    return 0
  fi
  # Pre-archive : must live under [Unreleased].
  local section
  section=$(awk '/^## \[Unreleased\]/{flag=1; next} /^## \[/{flag=0} flag' "$CHANGELOG_MD")
  if ! printf '%s' "$section" | grep -Fq "cli-trust-harness"; then
    echo "    CHANGELOG.md [Unreleased] does not mention cli-trust-harness" >&2
    return 1
  fi
}

# FR-T51-099 / MR-T51-004 — GOVERNANCE.md Release Process mentions gate
_test_t51_l1_014_governance_gate_doc() {
  if [ ! -f "$GOVERNANCE_MD" ]; then
    echo "    GOVERNANCE.md missing: $GOVERNANCE_MD" >&2; return 1
  fi
  if ! grep -Fq "prepublishOnly" "$GOVERNANCE_MD"; then
    echo "    GOVERNANCE.md does not document the prepublishOnly gate (FR-T51-099)" >&2
    return 1
  fi
  if ! grep -Fq "FORGE_SKIP_PREPUBLISH" "$GOVERNANCE_MD"; then
    echo "    GOVERNANCE.md does not document FORGE_SKIP_PREPUBLISH override (ADR-T51-005)" >&2
    return 1
  fi
}

# FR-T51-126 — t5-1.test.sh registered in forge-ci.yml harness matrix
_test_t51_l1_015_ci_registration() {
  if [ ! -f "$CI_WORKFLOW" ]; then
    echo "    forge-ci.yml missing: $CI_WORKFLOW" >&2; return 1
  fi
  if ! grep -Fq "t5-1.test.sh" "$CI_WORKFLOW"; then
    echo "    forge-ci.yml does not reference t5-1.test.sh" >&2; return 1
  fi
}

# FR-T51-055 — every non-removed_from_roadmap archetype has a fixture
_test_t51_l1_016_dispatch_xref() {
  if [ ! -f "$DISPATCH_TABLE" ]; then
    echo "    dispatch-table.yml missing: $DISPATCH_TABLE" >&2; return 1
  fi
  if [ ! -d "$FIXTURES_DIR" ]; then
    echo "    fixtures dir missing: $FIXTURES_DIR" >&2; return 1
  fi
  # Parse archetype names from dispatch-table top-level entries (2-space
  # indent under `archetypes:`). Filter out `default` (covered by
  # cli.test.ts), entries flagged removed_from_roadmap (detected via the
  # `<removed>` scaffolder sentinel or an explicit `status:` field), and
  # `status: candidate` entries — B.7.2a registered-but-not-yet-scaffoldable
  # archetypes (e.g. ai-native-rag) have no scaffold fixture; their refusal
  # is covered by b7-2a.test.sh + archetypes-smoke.test.ts. They rejoin this
  # fixture cross-reference when promoted to stable/scaffoldable (B.7.2-full).
  local in_archetypes=0
  local current=""
  local current_status=""
  local current_scaffolder=""
  local missing=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^archetypes:[[:space:]]*$ ]]; then
      in_archetypes=1; continue
    fi
    if [[ "$line" =~ ^[a-zA-Z_]+:[[:space:]]*$ ]] && [ "$in_archetypes" = "1" ]; then
      # New top-level key (not an archetype) — leave the archetypes block.
      in_archetypes=0
    fi
    if [ "$in_archetypes" = "1" ]; then
      if [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z][a-zA-Z0-9_-]*):[[:space:]]*$ ]]; then
        # Flush the previous archetype if any.
        if [ -n "$current" ] && [ "$current" != "default" ] \
           && [ "$current_status" != "removed_from_roadmap" ] \
           && [ "$current_status" != "candidate" ] \
           && [ "$current_scaffolder" != "<removed>" ]; then
          if [ ! -f "$FIXTURES_DIR/$current.yml" ]; then
            missing+="$current "
          fi
        fi
        current="${BASH_REMATCH[1]}"
        current_status=""
        current_scaffolder=""
        continue
      fi
      if [[ "$line" =~ ^[[:space:]]{4}status:[[:space:]]+(.+)$ ]]; then
        current_status="${BASH_REMATCH[1]}"
        current_status="${current_status%\"}"; current_status="${current_status#\"}"
      fi
      if [[ "$line" =~ ^[[:space:]]{4}scaffolder:[[:space:]]+\"?([^\"]+)\"?[[:space:]]*$ ]]; then
        current_scaffolder="${BASH_REMATCH[1]}"
      fi
    fi
  done < "$DISPATCH_TABLE"
  # Flush the last entry.
  if [ -n "$current" ] && [ "$current" != "default" ] \
     && [ "$current_status" != "removed_from_roadmap" ] \
     && [ "$current_status" != "candidate" ] \
     && [ "$current_scaffolder" != "<removed>" ]; then
    if [ ! -f "$FIXTURES_DIR/$current.yml" ]; then
      missing+="$current "
    fi
  fi
  if [ -n "$missing" ]; then
    echo "    missing fixtures for active archetypes: $missing" >&2
    return 1
  fi
}

# FR-T51-127 / NFR-T51-005 — forge-ci.yml ≤ 340 lines (bumped 300→340 2026-06-23
# by b7-7-example's MODIFIED FR-CI-012 second-tree RAG gate; kept in sync with the
# sibling NFR-CI-002 assertions in c1.test.sh / g1.test.sh / t5-otel-live-run.test.sh).
_test_t51_l1_017_ci_line_budget() {
  if [ ! -f "$CI_WORKFLOW" ]; then
    echo "    forge-ci.yml missing: $CI_WORKFLOW" >&2; return 1
  fi
  local lines
  lines=$(wc -l < "$CI_WORKFLOW" | tr -d ' ')
  if [ "$lines" -gt 340 ]; then
    echo "    forge-ci.yml is $lines lines, exceeds NFR-CI-002 / NFR-T51-005 budget of 340" >&2
    return 1
  fi
}

# ─── L2 tests (opt-in) ───────────────────────────────────────────

# FR-T51-125 — full smoke against one archetype (FORGE_T51_LIVE=1)
_test_t51_l2_smoke_one_archetype() {
  if [ "${FORGE_T51_LIVE:-0}" != "1" ]; then
    echo "    skipped (FORGE_T51_LIVE unset — opt-in per ADR-T51-001)" >&2
    return 0
  fi
  _not_implemented
}

# FR-T51-125 — pack isolation round-trip (FORGE_T51_PACK=1)
_test_t51_l2_pack_isolation() {
  if [ "${FORGE_T51_PACK:-0}" != "1" ]; then
    echo "    skipped (FORGE_T51_PACK unset — opt-in per ADR-T51-005)" >&2
    return 0
  fi
  _not_implemented
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T5.1 — cli-trust-harness — level $LEVEL ──"

  # L1 always runs.
  run_test _test_t51_l1_001_taskfile_line67_quoted
  run_test _test_t51_l1_002_no_unquoted_colon_space
  run_test _test_t51_l1_003_help_snapshots_file
  run_test _test_t51_l1_004_snapshots_dir_5files
  run_test _test_t51_l1_005_smoke_file
  run_test _test_t51_l1_006_fixture_fsm
  run_test _test_t51_l1_007_fixture_mobile_only
  run_test _test_t51_l1_008_load_fixture_helper
  run_test _test_t51_l1_009_prepublish_script
  run_test _test_t51_l1_010_prepublish_wired
  run_test _test_t51_l1_011_skip_prepublish_env
  run_test _test_t51_l1_012_toolchains_env
  run_test _test_t51_l1_013_changelog_entry
  run_test _test_t51_l1_014_governance_gate_doc
  run_test _test_t51_l1_015_ci_registration
  run_test _test_t51_l1_016_dispatch_xref
  run_test _test_t51_l1_017_ci_line_budget

  # L2 runs when --level includes 2 or "all".
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — opt-in fixtures (FORGE_T51_LIVE / FORGE_T51_PACK)"
    run_test _test_t51_l2_smoke_one_archetype
    run_test _test_t51_l2_pack_isolation
  fi

  print_summary
}

main "$@"
