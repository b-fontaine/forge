#!/usr/bin/env bash
# Forge — A.7 Forge Upgrade Test Harness (a7-forge-upgrade)
# <!-- Audit: A.7 (a7-forge-upgrade) -->
#
# Validates :
#  - framework-owned-paths.yml shape + every owned glob resolves to an
#    actual file in the framework (FR-UP-002)
#  - 3-way merge truth table (FR-UP-003)
#  - conflict markers + .merge-conflicts companion (FR-UP-004)
#  - --force Git cleanliness gate (FR-UP-005)
#  - major-version migration abort (FR-UP-006)
#  - upgrade_history append-only with immutable identity fields (FR-UP-007)
#  - BASE recovery via committed snapshot tarballs (FR-UP-008)
#  - bin/forge-upgrade.sh shape + shellcheck-clean (FR-UP-009)
#  - standard global/upgrade-policy.md sections (FR-UP-010)
#  - index entry (FR-UP-011)
#  - .gitignore covers .merge-conflicts (FR-UP-012)
#  - features/upgrade.feature scenarios (FR-UP-013)
#  - manifest self-consistency (FR-UP-014 — meta)
#  - upgrade-spec consolidation post-archive (FR-UP-015)
#  - NFRs (idempotence, snapshot size, legacy compat, determinism)
#
# Manifest pattern : a `# MANIFEST: test_* — FR-UP-NNN` comment block
# below is parsed by `test_a7_manifest_self_consistency` to enforce
# parity with defined functions (consistent with delivery.test.sh,
# g1.test.sh, c1.test.sh).
#
# Levels :
#  L1 (default) — hermetic structural / static / YAML checks.
#  L2 (--require-external-tools is NOT needed) — fixture-based merge
#     truth-table tests using tmpdirs + git merge-file. Bash + git
#     are sufficient.
#  L3 (--require-external-tools) — end-to-end against
#     examples/forge-fsm-example/.
#
# Usage :
#   bash .forge/scripts/tests/a7.test.sh
#   bash .forge/scripts/tests/a7.test.sh --require-external-tools

set -euo pipefail

REQUIRE_EXTERNAL_TOOLS=0
for arg in "$@"; do
  case "$arg" in
    --require-external-tools) REQUIRE_EXTERNAL_TOOLS=1 ;;
    *) echo "unknown flag: $arg" >&2 ; exit 2 ;;
  esac
done

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

OWNED_YML="$FORGE_ROOT_REAL/cli/assets/framework-owned-paths.yml"
UPGRADE_SH="$FORGE_ROOT_REAL/bin/forge-upgrade.sh"
SNAPSHOT_SH="$FORGE_ROOT_REAL/bin/forge-snapshot.sh"
STD_UPGRADE="$FORGE_ROOT_REAL/.forge/standards/global/upgrade-policy.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
GITIGNORE="$FORGE_ROOT_REAL/.gitignore"
FEATURE_FILE="$FORGE_ROOT_REAL/.forge/changes/a7-forge-upgrade/features/upgrade.feature"
SNAPSHOT_TARBALL="$FORGE_ROOT_REAL/cli/assets/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
UPGRADE_TS="$FORGE_ROOT_REAL/cli/src/commands/upgrade.ts"
SPEC_UPGRADE="$FORGE_ROOT_REAL/.forge/specs/upgrade.md"
A7_FORGE_YAML="$FORGE_ROOT_REAL/.forge/changes/a7-forge-upgrade/.forge.yaml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"

PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# Phase 1 — scaffolding
# MANIFEST: test_framework_owned_paths_yml_shape           — FR-UP-002
# MANIFEST: test_owned_paths_exist_in_framework            — FR-UP-002
# MANIFEST: test_forge_upgrade_sh_exists_executable        — FR-UP-009
# MANIFEST: test_forge_upgrade_sh_uses_find_excluding_examples — FR-UP-009
# MANIFEST: test_standard_upgrade_policy_has_required_sections — FR-UP-010
# MANIFEST: test_index_has_upgrade_policy_entry            — FR-UP-011
# MANIFEST: test_gitignore_covers_merge_conflicts          — FR-UP-012
# MANIFEST: test_features_upgrade_feature_present          — FR-UP-013
# MANIFEST: test_snapshot_tarball_present_and_extractable  — FR-UP-008
# MANIFEST: test_snapshot_size_under_budget                — NFR-UP-003
#
# Phase 2 — merge logic
# MANIFEST: test_merge_truth_table_exhaustive              — FR-UP-003
# MANIFEST: test_conflict_markers_written                  — FR-UP-004
# MANIFEST: test_merge_conflicts_listing                   — FR-UP-004
# MANIFEST: test_force_requires_clean_git                  — FR-UP-005
# MANIFEST: test_force_succeeds_when_clean                 — FR-UP-005
# MANIFEST: test_force_aborts_on_non_git                   — FR-UP-005
# MANIFEST: test_major_version_aborts                      — FR-UP-006
# MANIFEST: test_minor_patch_bumps_proceed                 — FR-UP-006
# MANIFEST: test_upgrade_history_appended_after_run        — FR-UP-007
# MANIFEST: test_upgrade_history_append_only               — FR-UP-007
# MANIFEST: test_identity_fields_immutable                 — FR-UP-007
# MANIFEST: test_upgrade_idempotent_when_no_change         — NFR-UP-001
# MANIFEST: test_legacy_manifest_without_upgrade_history_parses — NFR-UP-005
# MANIFEST: test_merge_output_deterministic                — NFR-UP-006
# MANIFEST: test_base_recovery_via_snapshot                — FR-UP-008
#
# Phase 3 — TS layer
# MANIFEST: test_upgrade_cli_flags_parse                   — FR-UP-001
# MANIFEST: test_l3_end_to_end_against_example             — FR-UP-014 (L3)
#
# Archive-gated
# MANIFEST: test_upgrade_spec_present_post_archive         — FR-UP-015
#
# Meta
# MANIFEST: test_a7_manifest_self_consistency              — meta (FR-UP-014)
#
# ────────────────────────────────────────────────────────────────

test_a7_manifest_self_consistency() {
  local self="${BASH_SOURCE[0]}"
  local declared
  declared=$(grep -E '^# MANIFEST: (test_[a-z0-9_]+)' "$self" | awk '{print $3}' | sort -u)
  if [ -z "$declared" ]; then
    echo "    no MANIFEST entries found" >&2; return 1
  fi
  local missing=""
  local entry
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    if ! grep -qE "^${entry}\(\)" "$self"; then
      missing+=" $entry"
    fi
  done <<< "$declared"
  if [ -n "$missing" ]; then
    echo "    manifest declares functions not defined:${missing}" >&2
    return 1
  fi
}

# ─── Phase 1 — scaffolding cluster ─────────────────────────────

# FR-UP-002 — framework-owned-paths.yml has the required shape.
test_framework_owned_paths_yml_shape() {
  if [ ! -f "$OWNED_YML" ]; then
    echo "    missing: $OWNED_YML" >&2; return 1
  fi
  python3 - "$OWNED_YML" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
errs = []
for k in ("owned", "excluded"):
    if k not in d:
        errs.append(f"missing top-level key: {k}")
        continue
    v = d[k]
    if not isinstance(v, list) or not v:
        errs.append(f"{k} must be a non-empty list, got {type(v).__name__}")
        continue
    for item in v:
        if not isinstance(item, str) or not item.strip():
            errs.append(f"{k} contains non-string or empty entry: {item!r}")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-UP-002 — every glob under owned: resolves to at least one file.
test_owned_paths_exist_in_framework() {
  python3 - "$OWNED_YML" "$FORGE_ROOT_REAL" <<'PY' || return 1
import sys, os, glob, yaml
yml, root = sys.argv[1], sys.argv[2]
data = yaml.safe_load(open(yml)) or {}
missing = []
for pattern in data.get("owned") or []:
    abs_pat = os.path.join(root, pattern)
    matches = [m for m in glob.glob(abs_pat, recursive=True) if os.path.isfile(m)]
    if not matches:
        missing.append(pattern)
if missing:
    for m in missing: print(f"    owned glob has no matches: {m}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-UP-009 — bin/forge-upgrade.sh exists, executable, bash.
test_forge_upgrade_sh_exists_executable() {
  if [ ! -f "$UPGRADE_SH" ]; then
    echo "    missing: $UPGRADE_SH" >&2; return 1
  fi
  if [ ! -x "$UPGRADE_SH" ]; then
    echo "    not executable: $UPGRADE_SH" >&2; return 1
  fi
  if ! head -1 "$UPGRADE_SH" | grep -qE '^#!.*bash'; then
    echo "    shebang is not bash on $UPGRADE_SH" >&2; return 1
  fi
}

# FR-UP-009 — script implements or sources the find_excluding_examples
# pattern (skip-guard discipline from FR-GL-027).
test_forge_upgrade_sh_uses_find_excluding_examples() {
  if ! grep -q 'find_excluding_examples' "$UPGRADE_SH"; then
    echo "    forge-upgrade.sh does not reference find_excluding_examples helper" >&2
    return 1
  fi
}

# FR-UP-010 — standard has the 6 H2 sections.
test_standard_upgrade_policy_has_required_sections() {
  if [ ! -f "$STD_UPGRADE" ]; then
    echo "    missing: $STD_UPGRADE" >&2; return 1
  fi
  local section
  for section in '## Framework-owned paths' \
                 '## Three-way merge policy' \
                 '## Conflict resolution discipline' \
                 '## Schema-version migration boundary' \
                 '## Upgrade history audit trail' \
                 '## Interdictions'; do
    if ! grep -qF "$section" "$STD_UPGRADE"; then
      echo "    missing H2 section: $section" >&2
      return 1
    fi
  done
}

# FR-UP-011 — index entry present.
test_index_has_upgrade_policy_entry() {
  python3 - "$INDEX_YML" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
entries = d.get("standards") or []
hit = next((e for e in entries if e.get("id") == "global/upgrade-policy"), None)
errs = []
if hit is None:
    errs.append("no entry with id 'global/upgrade-policy'")
else:
    if hit.get("scope") != "all":
        errs.append(f"scope should be 'all', got {hit.get('scope')!r}")
    if hit.get("priority") != "high":
        errs.append(f"priority should be 'high', got {hit.get('priority')!r}")
    triggers = hit.get("triggers") or []
    for needle in ("upgrade", "forge upgrade", "merge", "framework-owned"):
        if needle not in triggers:
            errs.append(f"missing trigger: {needle!r}")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-UP-012 — .gitignore covers .merge-conflicts.
test_gitignore_covers_merge_conflicts() {
  if ! grep -qE '^\.merge-conflicts$' "$GITIGNORE"; then
    echo "    .gitignore does not include '.merge-conflicts' line" >&2
    return 1
  fi
}

# FR-UP-013 — features/upgrade.feature has at least 5 scenarios.
test_features_upgrade_feature_present() {
  if [ ! -f "$FEATURE_FILE" ]; then
    echo "    missing: $FEATURE_FILE" >&2; return 1
  fi
  local count
  count=$(grep -cE '^[[:space:]]*Scenario:' "$FEATURE_FILE")
  if [ "$count" -lt 5 ]; then
    echo "    expected >= 5 Scenario blocks, got $count" >&2; return 1
  fi
  if ! grep -q 'Feature: Forge upgrade' "$FEATURE_FILE"; then
    echo "    feature file missing 'Feature: Forge upgrade' header" >&2; return 1
  fi
}

# FR-UP-008 — snapshot tarball is present, gzipped, and extractable.
test_snapshot_tarball_present_and_extractable() {
  if [ ! -f "$SNAPSHOT_TARBALL" ]; then
    echo "    missing: $SNAPSHOT_TARBALL" >&2; return 1
  fi
  if ! file "$SNAPSHOT_TARBALL" | grep -q 'gzip compressed'; then
    echo "    tarball is not gzip-compressed" >&2; return 1
  fi
  local tmp; tmp=$(mk_tmpdir_with_trap a7-tarball-extract)
  trap "rm -rf '$tmp'" RETURN
  if ! tar -xzf "$SNAPSHOT_TARBALL" -C "$tmp"; then
    echo "    tarball extraction failed" >&2; return 1
  fi
  # Snapshot must include a .forge/ subtree (proof of correctness).
  if [ ! -d "$tmp/.forge" ]; then
    echo "    extracted tree missing .forge/ subtree" >&2; return 1
  fi
}

# NFR-UP-003 — gzipped (on-disk) snapshot ≤ 1 MB. The compressed
# size is what affects the CLI bundle weight ; uncompressed
# expansion is a transient cost paid at upgrade time only.
test_snapshot_size_under_budget() {
  if [ ! -f "$SNAPSHOT_TARBALL" ]; then
    echo "    snapshot missing — cannot measure" >&2; return 1
  fi
  local compressed
  compressed=$(wc -c < "$SNAPSHOT_TARBALL" | tr -d ' ')
  local budget=$((1 * 1024 * 1024))
  if [ "$compressed" -gt "$budget" ]; then
    local mb
    mb=$(awk -v b="$compressed" 'BEGIN { printf "%.2f", b/1024/1024 }')
    echo "    snapshot gzipped is ${mb} MB (> 1 MB NFR-UP-003 budget)" >&2
    return 1
  fi
}

# ─── Phase 2 placeholders ──────────────────────────────────────

test_merge_truth_table_exhaustive()          { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_conflict_markers_written()              { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_merge_conflicts_listing()               { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_force_requires_clean_git()              { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_force_succeeds_when_clean()             { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_force_aborts_on_non_git()               { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_major_version_aborts()                  { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_minor_patch_bumps_proceed()             { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_upgrade_history_appended_after_run()    { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_upgrade_history_append_only()           { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_identity_fields_immutable()             { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_upgrade_idempotent_when_no_change()     { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_legacy_manifest_without_upgrade_history_parses() { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_merge_output_deterministic()            { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }
test_base_recovery_via_snapshot()            { echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1; }

# ─── Phase 3 placeholders ──────────────────────────────────────

test_upgrade_cli_flags_parse()               { echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1; }
test_l3_end_to_end_against_example() {
  if [ "$REQUIRE_EXTERNAL_TOOLS" != "1" ]; then
    echo "    skipped (set --require-external-tools to enable)" >&2; return 0
  fi
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}

# ─── Archive-gated ─────────────────────────────────────────────

test_upgrade_spec_present_post_archive() {
  if [ -f "$A7_FORGE_YAML" ]; then
    local status
    status=$(python3 - "$A7_FORGE_YAML" <<'PY' 2>/dev/null
import sys, yaml
print((yaml.safe_load(open(sys.argv[1])) or {}).get("status", ""))
PY
)
    if [ "$status" != "archived" ]; then
      echo "    skipped (a7 status='$status', not 'archived')" >&2
      return 0
    fi
  fi
  if [ ! -f "$SPEC_UPGRADE" ]; then
    echo "    expected spec file: $SPEC_UPGRADE" >&2; return 1
  fi
}

# ─── Main ───────────────────────────────────────────────────────

main() {
  echo "Forge — a7-forge-upgrade Test Harness"
  echo "FORGE_ROOT_REAL=$FORGE_ROOT_REAL"
  echo "REQUIRE_EXTERNAL_TOOLS=$REQUIRE_EXTERNAL_TOOLS"
  echo ""
  echo "── Phase 1 : scaffolding cluster ──"
  run_test test_framework_owned_paths_yml_shape
  run_test test_owned_paths_exist_in_framework
  run_test test_forge_upgrade_sh_exists_executable
  run_test test_forge_upgrade_sh_uses_find_excluding_examples
  run_test test_standard_upgrade_policy_has_required_sections
  run_test test_index_has_upgrade_policy_entry
  run_test test_gitignore_covers_merge_conflicts
  run_test test_features_upgrade_feature_present
  run_test test_snapshot_tarball_present_and_extractable
  run_test test_snapshot_size_under_budget
  echo ""
  echo "── Phase 2 : merge logic cluster ──"
  run_test test_merge_truth_table_exhaustive
  run_test test_conflict_markers_written
  run_test test_merge_conflicts_listing
  run_test test_force_requires_clean_git
  run_test test_force_succeeds_when_clean
  run_test test_force_aborts_on_non_git
  run_test test_major_version_aborts
  run_test test_minor_patch_bumps_proceed
  run_test test_upgrade_history_appended_after_run
  run_test test_upgrade_history_append_only
  run_test test_identity_fields_immutable
  run_test test_upgrade_idempotent_when_no_change
  run_test test_legacy_manifest_without_upgrade_history_parses
  run_test test_merge_output_deterministic
  run_test test_base_recovery_via_snapshot
  echo ""
  echo "── Phase 3 : CLI TS layer cluster ──"
  run_test test_upgrade_cli_flags_parse
  run_test test_l3_end_to_end_against_example
  echo ""
  echo "── Archive-gated ──"
  run_test test_upgrade_spec_present_post_archive
  echo ""
  echo "── Meta ──"
  run_test test_a7_manifest_self_consistency
  print_summary
}

main "$@"
