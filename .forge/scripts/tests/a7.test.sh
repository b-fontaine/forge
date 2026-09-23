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

OWNED_YML="$FORGE_ROOT_REAL/.forge/framework-owned-paths.yml"
UPGRADE_SH="$FORGE_ROOT_REAL/bin/forge-upgrade.sh"
SNAPSHOT_SH="$FORGE_ROOT_REAL/bin/forge-snapshot.sh"
STD_UPGRADE="$FORGE_ROOT_REAL/.forge/standards/global/upgrade-policy.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
GITIGNORE="$FORGE_ROOT_REAL/.gitignore"
FEATURE_FILE="$FORGE_ROOT_REAL/.forge/changes/a7-forge-upgrade/features/upgrade.feature"
SNAPSHOT_TARBALL="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
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
# Archetype merge surface (t8-upgrade-archetype-surface)
# MANIFEST: test_archetype_mode_detection                  — FR-T8UAS-006
# MANIFEST: test_project_owned_paths_are_the_merge_surface — FR-T8UAS-002
# MANIFEST: test_framework_paths_excluded_from_archetype_surface — FR-T8UAS-005
# MANIFEST: test_archetype_render_produces_declared_paths  — FR-T8UAS-003/007
# MANIFEST: test_archetype_upgrade_clean_on_untouched_render — FR-T8UAS-001 (LIVE)
#
# Flagship no-op (t8-upgrade-flagship-noop)
# MANIFEST: test_copied_framework_declaration_is_not_archetype_mode — FR-T8UFN-001
# MANIFEST: test_archetype_plan_selection_is_versioned     — FR-T8UFN-001 / FR-T8UFN-006
# MANIFEST: test_archetype_render_relocates_path_placeholders — FR-T8UFN-003
# MANIFEST: test_every_plan_placeholder_path_is_relocated  — FR-T8UFN-003
# MANIFEST: test_kotlin_relocation_gates_reverse_domain    — FR-T8UFN-003
# MANIFEST: test_archetype_unproducible_path_is_reported   — FR-T8UFN-004
# MANIFEST: test_unreadable_plan_is_reported               — FR-T8UFN-001
# MANIFEST: test_malformed_version_is_refused              — FR-T8UFN-006
# MANIFEST: test_invalid_archetype_never_reaches_a_snapshot — FR-T8UFN-007
# MANIFEST: test_conflicted_run_does_not_stamp_manifest    — FR-T8UFN-008 (FR-UP-007)
# MANIFEST: test_upgrade_leaves_no_temp_dirs               — FR-T8UFN-009
# MANIFEST: test_flagship_upgrade_is_not_a_silent_noop     — FR-T8UFN-002 (LIVE)
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
  if ! grep -q 'gzip compressed' < <(file "$SNAPSHOT_TARBALL"); then
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

# ─── Phase 2 — merge logic (library-style fixture tests) ──────
#
# forge-upgrade.sh is sourced — the script's main() guards on
# `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` so sourcing exposes the
# library functions without invoking main. Each test exercises
# one or two functions on a tmpdir fixture.

# Source forge-upgrade.sh for library access. Disable script-side
# `set -e` propagation by sourcing in a subshell-friendly way.
# shellcheck source=/dev/null
source "$UPGRADE_SH"

_a7_make_repo() {
  # Build a minimal Git repo at $1 with one initial commit.
  local d="$1"
  ( cd "$d" \
    && git init -q \
    && git config user.email "a7@test.local" \
    && git config user.name "a7" \
    && git add -A \
    && git commit -q -m "initial" )
}

# FR-UP-003 — exhaustive truth table for the 4-cell merge matrix
# plus the BASE-unavailable degraded 2-way fallback.
test_merge_truth_table_exhaustive() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-truth)
  trap "rm -rf '$tmp'" RETURN
  local errs=""

  # Cell 1 — same/same
  printf "X\n" > "$tmp/base1"; printf "X\n" > "$tmp/left1"; printf "X\n" > "$tmp/right1"
  if ! _a7_classify "$tmp/left1" "$tmp/base1" "$tmp/right1" | grep -q "^unchanged$"; then
    errs+=" same/same→!unchanged"
  fi

  # Cell 2 — same/changed → upgraded
  printf "X\n" > "$tmp/base2"; printf "X\n" > "$tmp/left2"; printf "Y\n" > "$tmp/right2"
  if ! _a7_classify "$tmp/left2" "$tmp/base2" "$tmp/right2" | grep -q "^upgraded$"; then
    errs+=" same/changed→!upgraded"
  fi

  # Cell 3 — changed/same → preserved
  printf "X\n" > "$tmp/base3"; printf "Y\n" > "$tmp/left3"; printf "X\n" > "$tmp/right3"
  if ! _a7_classify "$tmp/left3" "$tmp/base3" "$tmp/right3" | grep -q "^preserved$"; then
    errs+=" changed/same→!preserved"
  fi

  # Cell 4 — changed/changed → conflicted (3-way merge candidate)
  printf "X\n" > "$tmp/base4"; printf "Y\n" > "$tmp/left4"; printf "Z\n" > "$tmp/right4"
  if ! _a7_classify "$tmp/left4" "$tmp/base4" "$tmp/right4" | grep -q "^merge_candidate$"; then
    errs+=" changed/changed→!merge_candidate"
  fi

  # Cell 5 — BASE unavailable → 2-way fallback
  printf "X\n" > "$tmp/left5"; printf "X\n" > "$tmp/right5"
  if ! _a7_classify "$tmp/left5" "" "$tmp/right5" | grep -q "^unchanged$"; then
    errs+=" 2way-same→!unchanged"
  fi
  printf "X\n" > "$tmp/left6"; printf "Y\n" > "$tmp/right6"
  if ! _a7_classify "$tmp/left6" "" "$tmp/right6" | grep -q "^conflict_2way$"; then
    errs+=" 2way-diff→!conflict_2way"
  fi

  if [ -n "$errs" ]; then
    echo "    truth-table mismatches:$errs" >&2
    return 1
  fi
}

# FR-UP-004 — git merge-file --diff3 produces standard markers.
test_conflict_markers_written() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-markers)
  trap "rm -rf '$tmp'" RETURN
  printf "line1\ncommon\nline3\n" > "$tmp/base"
  printf "line1\nLEFT_EDIT\nline3\n" > "$tmp/left"
  printf "line1\nRIGHT_EDIT\nline3\n" > "$tmp/right"
  # Invoke library merge function ; expects in-place markers in LEFT.
  _a7_three_way_merge "$tmp/left" "$tmp/base" "$tmp/right" >/dev/null 2>&1 || true
  for needle in '<<<<<<<' '|||||||' '=======' '>>>>>>>'; do
    if ! grep -q "$needle" "$tmp/left"; then
      echo "    missing marker '$needle' in LEFT" >&2
      return 1
    fi
  done
}

# FR-UP-004 — .merge-conflicts file lists conflicted paths.
test_merge_conflicts_listing() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-listing)
  trap "rm -rf '$tmp'" RETURN
  printf "X\n" > "$tmp/conflict.md"
  : > "$tmp/.merge-conflicts"
  _a7_record_conflict "$tmp" "conflict.md"
  if ! grep -qF '[CONFLICT] conflict.md' "$tmp/.merge-conflicts"; then
    echo "    .merge-conflicts does not list conflict.md with [CONFLICT] prefix" >&2
    return 1
  fi
}

# FR-UP-005 — --force on dirty Git tree aborts (exit 7).
test_force_requires_clean_git() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-dirty)
  trap "rm -rf '$tmp'" RETURN
  printf "init\n" > "$tmp/file.md"
  _a7_make_repo "$tmp"
  # Modify file without committing → dirty tree.
  printf "dirty\n" >> "$tmp/file.md"
  local rc=0
  _a7_check_force_clean_git "$tmp" || rc=$?
  if [ "$rc" != "7" ]; then
    echo "    expected exit 7 on dirty tree, got $rc" >&2
    return 1
  fi
}

# FR-UP-005 — --force on clean Git tree proceeds.
test_force_succeeds_when_clean() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-clean)
  trap "rm -rf '$tmp'" RETURN
  printf "init\n" > "$tmp/file.md"
  _a7_make_repo "$tmp"
  local rc=0
  _a7_check_force_clean_git "$tmp" || rc=$?
  if [ "$rc" != "0" ]; then
    echo "    expected exit 0 on clean tree, got $rc" >&2
    return 1
  fi
}

# FR-UP-005 — --force on non-Git target aborts (exit 7).
test_force_aborts_on_non_git() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-nongit)
  trap "rm -rf '$tmp'" RETURN
  local rc=0
  _a7_check_force_clean_git "$tmp" || rc=$?
  if [ "$rc" != "7" ]; then
    echo "    expected exit 7 on non-Git target, got $rc" >&2
    return 1
  fi
}

# FR-UP-006 — major-version diff aborts.
test_major_version_aborts() {
  local out
  out=$(_a7_check_version_compat "1.5.2" "2.0.0" 2>&1) && {
    echo "    expected non-zero exit on major bump" >&2; return 1
  }
  if ! grep -q '\[NEEDS MIGRATION: from 1.5.2 to 2.0.0\]' <<<"$out"; then
    echo "    output missing [NEEDS MIGRATION:] marker" >&2
    return 1
  fi
}

# FR-UP-006 — minor / patch bumps proceed.
test_minor_patch_bumps_proceed() {
  local rc=0
  _a7_check_version_compat "1.0.0" "1.1.0" >/dev/null 2>&1 || rc=$?
  [ "$rc" = "0" ] || { echo "    1.0.0 → 1.1.0 should proceed (rc=$rc)" >&2; return 1; }
  rc=0
  _a7_check_version_compat "1.0.0" "1.0.1" >/dev/null 2>&1 || rc=$?
  [ "$rc" = "0" ] || { echo "    1.0.0 → 1.0.1 should proceed (rc=$rc)" >&2; return 1; }
}

# FR-UP-007 — upgrade_history entry appended after run.
test_upgrade_history_appended_after_run() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-hist1)
  trap "rm -rf '$tmp'" RETURN
  cat > "$tmp/scaffold-manifest.yaml" <<EOF
archetype: full-stack-monorepo
archetype_version: "1.0.0"
project_name: test
reverse_domain: io.test
root_module: test_root
scaffold_date: "2026-01-01T00:00:00+00:00"
scaffold_plan_sha: deadbeef
template_set_sha: cafef00d
EOF
  _a7_append_upgrade_history "$tmp/scaffold-manifest.yaml" \
    "1.0.0" "1.1.0" "deadbeef" "feedface" "1" "2" "3" "4" "5" "0.3.0"
  local entries
  entries=$(python3 -c "
import yaml
d = yaml.safe_load(open('$tmp/scaffold-manifest.yaml'))
print(len(d.get('upgrade_history', [])))
")
  [ "$entries" = "1" ] || { echo "    expected 1 history entry, got $entries" >&2; return 1; }
  python3 - "$tmp/scaffold-manifest.yaml" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1]))
e = d['upgrade_history'][0]
errs = []
for k in ('date','from_version','to_version','from_template_set_sha',
         'to_template_set_sha','counts','cli_version'):
    if k not in e: errs.append(f"missing key {k}")
if e.get('to_version') != '1.1.0': errs.append(f"to_version mismatch: {e.get('to_version')}")
counts = e.get('counts') or {}
for k in ('unchanged','upgraded','preserved','conflicted','skipped'):
    if k not in counts: errs.append(f"counts missing {k}")
if errs:
    for x in errs: print(f"    {x}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-UP-007 — history is append-only (existing entries preserved).
test_upgrade_history_append_only() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-hist2)
  trap "rm -rf '$tmp'" RETURN
  cat > "$tmp/m.yaml" <<EOF
archetype: full-stack-monorepo
archetype_version: "1.0.0"
project_name: test
reverse_domain: io.test
root_module: test_root
scaffold_date: "2026-01-01T00:00:00+00:00"
scaffold_plan_sha: deadbeef
template_set_sha: cafef00d
upgrade_history:
  - date: "2026-02-01T00:00:00+00:00"
    from_version: "0.9.0"
    to_version: "1.0.0"
    from_template_set_sha: aaaa
    to_template_set_sha: bbbb
    counts: { unchanged: 10, upgraded: 0, preserved: 0, conflicted: 0, skipped: 0 }
    cli_version: "0.2.0"
EOF
  _a7_append_upgrade_history "$tmp/m.yaml" \
    "1.0.0" "1.1.0" "bbbb" "cccc" "1" "2" "3" "4" "5" "0.3.0"
  local entries
  entries=$(python3 -c "
import yaml
print(len(yaml.safe_load(open('$tmp/m.yaml'))['upgrade_history']))
")
  [ "$entries" = "2" ] || { echo "    expected 2 entries, got $entries" >&2; return 1; }
  # Confirm the original entry is preserved byte-equivalent.
  local first_to
  first_to=$(python3 -c "
import yaml
print(yaml.safe_load(open('$tmp/m.yaml'))['upgrade_history'][0]['to_version'])
")
  [ "$first_to" = "1.0.0" ] || { echo "    first entry mutated: to_version=$first_to" >&2; return 1; }
}

# FR-UP-007 — identity fields immutable across upgrades.
test_identity_fields_immutable() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-immut)
  trap "rm -rf '$tmp'" RETURN
  cat > "$tmp/m.yaml" <<EOF
archetype: full-stack-monorepo
archetype_version: "1.0.0"
project_name: original-name
reverse_domain: io.original
root_module: original_root
scaffold_date: "2026-01-01T00:00:00+00:00"
scaffold_plan_sha: deadbeef
template_set_sha: cafef00d
EOF
  _a7_append_upgrade_history "$tmp/m.yaml" \
    "1.0.0" "1.1.0" "cafef00d" "feedface" "1" "2" "3" "4" "5" "0.3.0"
  local pn rd rm_field
  pn=$(python3 -c "import yaml; print(yaml.safe_load(open('$tmp/m.yaml'))['project_name'])")
  rd=$(python3 -c "import yaml; print(yaml.safe_load(open('$tmp/m.yaml'))['reverse_domain'])")
  rm_field=$(python3 -c "import yaml; print(yaml.safe_load(open('$tmp/m.yaml'))['root_module'])")
  [ "$pn" = "original-name" ] || { echo "    project_name mutated: $pn" >&2; return 1; }
  [ "$rd" = "io.original" ] || { echo "    reverse_domain mutated: $rd" >&2; return 1; }
  [ "$rm_field" = "original_root" ] || { echo "    root_module mutated: $rm_field" >&2; return 1; }
}

# NFR-UP-001 — same input twice produces zero file mutation on
# second run (truth-table classification gives all `unchanged`).
test_upgrade_idempotent_when_no_change() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-idemp)
  trap "rm -rf '$tmp'" RETURN
  printf "X\n" > "$tmp/file"
  # First "run" — file is at LEFT == BASE == RIGHT (clean state).
  local cls
  cls=$(_a7_classify "$tmp/file" "$tmp/file" "$tmp/file")
  [ "$cls" = "unchanged" ] || { echo "    expected unchanged, got $cls" >&2; return 1; }
  # SHA-256 unchanged after a no-op classification.
  local sha_before sha_after
  sha_before=$(_a7_sha256 "$tmp/file")
  sha_after=$(_a7_sha256 "$tmp/file")
  [ "$sha_before" = "$sha_after" ] || { echo "    sha changed across reads (impossible)" >&2; return 1; }
}

# NFR-UP-005 — manifest without upgrade_history parses as [].
test_legacy_manifest_without_upgrade_history_parses() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-legacy)
  trap "rm -rf '$tmp'" RETURN
  cat > "$tmp/m.yaml" <<EOF
archetype: full-stack-monorepo
archetype_version: "1.0.0"
project_name: legacy
reverse_domain: io.legacy
root_module: legacy_root
scaffold_date: "2026-01-01T00:00:00+00:00"
scaffold_plan_sha: deadbeef
template_set_sha: cafef00d
EOF
  # Function tolerates missing upgrade_history key.
  _a7_append_upgrade_history "$tmp/m.yaml" \
    "1.0.0" "1.1.0" "cafef00d" "feedface" "1" "0" "0" "0" "0" "0.3.0" \
    || { echo "    append failed on legacy manifest" >&2; return 1; }
  local has
  has=$(python3 -c "
import yaml
d = yaml.safe_load(open('$tmp/m.yaml'))
print(len(d.get('upgrade_history', [])))
")
  [ "$has" = "1" ] || { echo "    legacy manifest didn't gain history entry" >&2; return 1; }
}

# NFR-UP-006 — git merge-file output is deterministic across two
# invocations on the same triple. Use identical filenames in two
# separate tmpdirs so the markers don't include path-specific
# noise.
test_merge_output_deterministic() {
  local tmp1 tmp2
  tmp1=$(mk_tmpdir_with_trap a7-determ-1)
  tmp2=$(mk_tmpdir_with_trap a7-determ-2)
  trap "rm -rf '$tmp1' '$tmp2'" RETURN
  for d in "$tmp1" "$tmp2"; do
    printf "a\ncommon\nb\n" > "$d/base"
    printf "a\nLEFT\nb\n" > "$d/left"
    printf "a\nRIGHT\nb\n" > "$d/right"
    ( cd "$d" && _a7_three_way_merge "left" "base" "right" >/dev/null 2>&1 || true )
  done
  if ! diff -q "$tmp1/left" "$tmp2/left" >/dev/null 2>&1; then
    echo "    deterministic merge produced different output across runs" >&2
    diff "$tmp1/left" "$tmp2/left" | head -10 >&2
    return 1
  fi
}

# FR-UP-008 — BASE recovery via snapshot extracts cleanly. The
# snapshot contains framework-owned paths only (cli/ assets are
# not in `owned:` since they are CLI bundle resources, not project
# files).
test_base_recovery_via_snapshot() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-base)
  trap "rm -rf '$tmp'" RETURN
  if ! bash "$SNAPSHOT_SH" extract full-stack-monorepo 1.0.0 "$tmp" >/dev/null 2>&1; then
    echo "    snapshot extract failed" >&2
    return 1
  fi
  for f in .forge/constitution.md .forge/standards/global/tdd-rules.md \
           CLAUDE.md LICENSE NOTICE bin/forge-install.sh; do
    if [ ! -f "$tmp/$f" ]; then
      echo "    extracted tree missing expected owned file: $f" >&2
      return 1
    fi
  done
}

# ─── Phase 3 — TS CLI layer ────────────────────────────────────

# FR-UP-001 — upgrade.ts declares the canonical option set and
# wires through to the shell driver. Static text-grep on the source.
test_upgrade_cli_flags_parse() {
  if [ ! -f "$UPGRADE_TS" ]; then
    echo "    missing: $UPGRADE_TS" >&2; return 1
  fi
  local needle
  for needle in 'targetDir' 'dryRun' 'force' 'verbose' \
                'shellDriverPath' 'readManifest' 'resolveFrameworkVersion'; do
    if ! grep -q "$needle" "$UPGRADE_TS"; then
      echo "    upgrade.ts missing required identifier: $needle" >&2
      return 1
    fi
  done
  # cli.ts wires the upgrade subcommand
  local cli_ts="$FORGE_ROOT_REAL/cli/src/cli.ts"
  if ! grep -q '\.command("upgrade")' "$cli_ts"; then
    echo "    cli.ts does not register the upgrade subcommand" >&2
    return 1
  fi
  if ! grep -q 'upgradeCommand' "$cli_ts"; then
    echo "    cli.ts does not import upgradeCommand" >&2
    return 1
  fi
}
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

# ─── t8-upgrade-archetype-surface — the archetype merge surface (Q-007) ──────
#
# A.7 was designed against `default`, the one archetype that is a file-copy of the
# framework asset tree. Every RENDERED archetype was outside its model: the driver
# resolved owned paths from the FRAMEWORK manifest and took RIGHT from the framework
# tree, so `forge upgrade` on an untouched mobile-pwa-first render reported 49
# conflicts and exit 8, while the two paths that project declares were never opened.

# Build a synthetic archetype project: a manifest naming a planned archetype plus its
# own owned-paths declaration. Cheap enough for L1 — no render.
_a7t_mk_archetype_project() {
  local dir="$1" archetype="${2:-mobile-pwa-first}" version="${3:-2.0.0}"
  mkdir -p "$dir/.forge"
  cat > "$dir/.forge/scaffold-manifest.yaml" <<YAML
archetype: $archetype
archetype_version: $version
project_name: q7probe
reverse_domain: io.forge.q7
root_module: q7probe
YAML
  cat > "$dir/.forge/framework-owned-paths.yml" <<'YAML'
owned:
  - "pubspec.yaml"
  - "web-pwa/package.json"
excluded:
  - "web-pwa/.env"
YAML
  printf 'name: q7probe
' > "$dir/pubspec.yaml"
  mkdir -p "$dir/web-pwa"; printf '{}
' > "$dir/web-pwa/package.json"
}

# FR-T8UAS-006 / ADR-T8UAS-001 — archetype mode is entered only for a project whose
# manifest names an archetype that HAS a scaffold plan. `default` has no template dir
# at all; `mobile-only` has one but no plan, and renders no manifest, so neither may
# be pulled into the rendered path.
test_archetype_mode_detection() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-archdetect)
  trap "rm -rf '$tmp'" RETURN
  _a7t_mk_archetype_project "$tmp/planned" mobile-pwa-first 2.0.0
  local got
  got=$(_a7_project_archetype "$tmp/planned")
  [ "$got" = "mobile-pwa-first" ] || { echo "    planned archetype not detected (got '''$got''')" >&2; return 1; }

  _a7t_mk_archetype_project "$tmp/plainer" default 1.0.0
  got=$(_a7_project_archetype "$tmp/plainer")
  [ -z "$got" ] || { echo "    'default' must NOT enter archetype mode (got '''$got''')" >&2; return 1; }

  _a7t_mk_archetype_project "$tmp/noplan" mobile-only 1.0.0
  got=$(_a7_project_archetype "$tmp/noplan")
  [ -z "$got" ] || { echo "    an archetype without a scaffold plan must NOT enter archetype mode (got '''$got''')" >&2; return 1; }
}

# FR-T8UAS-002 — the owned set comes from the PROJECT'''s declaration.
test_project_owned_paths_are_the_merge_surface() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-ownedsurface)
  trap "rm -rf '$tmp'" RETURN
  _a7t_mk_archetype_project "$tmp/p"
  local owned; owned=$(_a7_project_owned_paths "$tmp/p")
  grep -qx 'pubspec.yaml' <<<"$owned"     || { echo "    the project declares pubspec.yaml and it is not in the merge surface" >&2; return 1; }
  grep -qx 'web-pwa/package.json' <<<"$owned"     || { echo "    the project declares web-pwa/package.json and it is not in the merge surface" >&2; return 1; }
  grep -qx 'web-pwa/.env' <<<"$owned"     && { echo "    an 'excluded:' entry leaked into the merge surface" >&2; return 1; }
  # Anti-vacuity: an empty surface would make every assertion above trivially safe
  # in the negative direction, so require the count to be the declaration'''s.
  local n; n=$(grep -c . <<<"$owned")
  [ "$n" = "2" ] || { echo "    expected exactly the 2 declared paths, got $n" >&2; return 1; }
}

# FR-T8UAS-005 — Forge'''s own tree is not merged into a rendered project. This is the
# assertion that would have caught the 49 phantom conflicts.
test_framework_paths_excluded_from_archetype_surface() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-noframework)
  trap "rm -rf '$tmp'" RETURN
  _a7t_mk_archetype_project "$tmp/p"
  local owned; owned=$(_a7_project_owned_paths "$tmp/p")
  # Anti-vacuity FIRST. An empty surface contains no framework path either, so without
  # this the assertion below passes while the function does not exist at all — which is
  # exactly what it did on its first run.
  [ "$(grep -c . <<<"$owned")" -gt 0 ] \
    || { echo "    the merge surface is EMPTY — nothing was measured" >&2; return 1; }
  if grep -qE '^\.claude/|^\.forge/templates/|^bin/|^docs/' <<<"$owned"; then
    echo "    framework-shaped paths leaked into a rendered project'''s merge surface:" >&2
    grep -E '^\.claude/|^\.forge/templates/|^bin/|^docs/' <<<"$owned" | head -3 | sed 's/^/      /' >&2
    return 1
  fi
}

# FR-T8UAS-003/007 — RIGHT is a RENDER of the archetype, and the render's own manifest
# never enters the merge. Hermetic: overlay.sh needs only python3.
test_archetype_render_produces_declared_paths() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP: python3 absent" >&2; return 0; }
  local tmp; tmp=$(mk_tmpdir_with_trap a7-render)
  trap "rm -rf '$tmp'" RETURN
  _a7t_mk_archetype_project "$tmp/p"
  local out
  out=$(_a7_render_archetype mobile-pwa-first "$tmp/p/.forge/scaffold-manifest.yaml" "$FORGE_ROOT_REAL") \
    || { echo "    render of mobile-pwa-first failed against the repo templates" >&2; return 1; }
  [ -n "$out" ] && [ -d "$out" ] || { echo "    render produced no directory" >&2; return 1; }
  local rc=0
  for want in pubspec.yaml web-pwa/package.json; do
    [ -f "$out/$want" ] || { echo "    rendered tree is missing $want" >&2; rc=1; }
  done
  # No raw template may reach a target (the b8-10b defect: 36 .tmpl files shipped).
  # Process substitution, not a pipe: `find … | grep -q` lets grep exit on the first
  # match and SIGPIPE the find, so the branch can be missed (foundations.test.sh's own
  # rule, and the pipefail race this repository has paid for repeatedly).
  if grep -q . < <(find "$out" -name '*.tmpl' -type f); then
    echo "    raw .tmpl files survived the render" >&2; rc=1
  fi
  # The render writes its own manifest; it must be discarded (FR-T8UAS-007).
  [ -f "$out/.forge/scaffold-manifest.yaml" ] \
    && { echo "    the rendered scaffold-manifest.yaml was NOT discarded — merging it destroys the adopter's upgrade_history" >&2; rc=1; }
  # A placeholder left unsubstituted means the render did not actually run.
  if grep -rlq '<project-name>' "$out" 2>/dev/null; then
    echo "    unsubstituted <project-name> in the rendered tree" >&2; rc=1
  fi
  rm -rf "$out"
  return $rc
}

# FR-T8UAS-001/003/004 — the end-to-end claim: an untouched render upgrades with zero
# conflicts. Opt-in (FORGE_A7_LIVE=1): it renders a real archetype, which costs far
# more than this harness''' L1 budget.
test_archetype_upgrade_clean_on_untouched_render() {
  [ "${FORGE_A7_LIVE:-0}" = "1" ] || { echo "    SKIP: set FORGE_A7_LIVE=1 to render a real project and upgrade it" >&2; return 0; }
  command -v git >/dev/null 2>&1 || { echo "    SKIP: git absent" >&2; return 0; }
  local tmp; tmp=$(mk_tmpdir_with_trap a7-live)
  trap "rm -rf '$tmp'" RETURN
  bash "$FORGE_ROOT_REAL/bin/forge-init-mobile-pwa-first.sh" --target "$tmp/proj" \
      --project-name q7probe --reverse-domain io.forge.q7 >/dev/null 2>&1 \
    || { echo "    FAIL: render failed" >&2; return 1; }
  # FR-T8UFN-003 — the declared Kotlin file must exist in the project, or `skipped: 0`
  # below would hold without it ever being compared.
  [ -f "$tmp/proj/android/app/src/main/kotlin/io/forge/q7/PlayIntegrityService.kt" ] \
    || { echo "    precondition: the render has no PlayIntegrityService.kt — nothing measured" >&2; return 1; }
  ( cd "$tmp/proj" && git init -q && git add -A && \
    git -c user.email=t@t -c user.name=t commit -qm init ) >/dev/null 2>&1
  local out; out=$(bash "$FORGE_ROOT_REAL/bin/forge-upgrade.sh" --target "$tmp/proj" \
      --to-version 2.0.1 --dry-run 2>&1); local rc=$?
  local conflicts; conflicts=$(sed -nE 's/.*files conflicted:[[:space:]]*([0-9]+).*/\1/p' <<<"$out" | tail -1)
  # FR-T8UFN-003 — zero conflicts is not enough: `files skipped: 1` passed here while
  # PlayIntegrityService.kt, declared framework-owned, was absent from RIGHT on every run.
  local skipped; skipped=$(sed -nE 's/.*files skipped:[[:space:]]*([0-9]+).*/\1/p' <<<"$out" | tail -1)
  if [ "$rc" != "0" ] || [ "${conflicts:-x}" != "0" ] || [ "${skipped:-x}" != "0" ]; then
    echo "    FAIL: an untouched render must upgrade cleanly — rc=$rc conflicts=${conflicts:-?} skipped=${skipped:-?}" >&2
    printf '%s\n' "$out" | tail -8 | sed 's/^/      /' >&2
    return 1
  fi
}

# ─── t8-upgrade-flagship-noop — the flagship fell into archetype mode ────────
#
# init.sh:208 copies the framework's `.forge/` (minus its runtime state) into every
# flagship render, ROOT `framework-owned-paths.yml` included. The flagship has a plan and
# that file, which is all ADR-T8UAS-001 asked for, so it was sent into archetype mode:
# RIGHT rendered from the template carried none of the framework's paths, 548 of 549 were
# skipped, and a real upgrade exited 0 and stamped the new version over a surface it never
# compared. The review of this brick then found the snapshot path, the version field and
# the manifest stamp open to the same class of defect; those cells follow.

# Build a render-shaped tree holding the placeholder directory the wrapper relocates.
_a7t_mk_kotlin_placeholder() {
  mkdir -p "$1/android/app/src/main/kotlin/{{reverse_domain_path}}"
  printf 'package x\n' > "$1/android/app/src/main/kotlin/{{reverse_domain_path}}/PlayIntegrityService.kt"
}

# FR-T8UFN-001 / ADR-T8UFN-001 — a declaration is an archetype declaration only when the
# archetype's plan RENDERS it. A byte copy of the root file is not the only shape a
# flagship project can hold: a copy rendered by an older framework, or one the adopter
# edited, differs — and a detector that compared content (the alternative ADR-T8UFN-001
# rejects) would send exactly those projects back into archetype mode.
test_copied_framework_declaration_is_not_archetype_mode() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-fsmcopy)
  trap "rm -rf '$tmp'" RETURN
  # Positive control first: a detector broken outright would make every negative
  # assertion below pass for the wrong reason.
  _a7t_mk_archetype_project "$tmp/control" mobile-pwa-first 2.0.0
  [ "$(_a7_project_archetype "$tmp/control")" = "mobile-pwa-first" ] \
    || { echo "    positive control: mobile-pwa-first is no longer detected — nothing below is measured" >&2; return 1; }
  local v shape p got rc=0
  for v in 2.0.0 1.0.0; do
    for shape in copy edited synthetic; do
      p="$tmp/fsm-$v-$shape"
      _a7t_mk_archetype_project "$p" full-stack-monorepo "$v"
      case "$shape" in
        copy)   cp "$OWNED_YML" "$p/.forge/framework-owned-paths.yml" ;;
        edited) cp "$OWNED_YML" "$p/.forge/framework-owned-paths.yml"
                printf '  - "adopter/extra.txt"\n' >> "$p/.forge/framework-owned-paths.yml" ;;
        synthetic) : ;;  # the fixture's own two-path declaration
      esac
      got=$(_a7_project_archetype "$p" 2>/dev/null)
      [ -z "$got" ] || { echo "    flagship $v with a $shape declaration entered archetype mode (got '$got')" >&2; rc=1; }
    done
  done
  return $rc
}

# FR-T8UFN-001 / FR-T8UFN-006 — detection and rendering read the plan through ONE rule
# (the plan named for archetype_version, else the bare plan), and that rule never lets a
# version taken from the target's manifest walk out of the archetype directory.
test_archetype_plan_selection_is_versioned() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-plansel)
  trap "rm -rf '$tmp'" RETURN
  local d="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo" got rc=0
  [ -f "$d/scaffold-plan-2.0.0.yaml" ] && [ -f "$d/scaffold-plan.yaml" ] \
    || { echo "    precondition: the flagship no longer has both a versioned and a bare plan" >&2; return 1; }
  _a7t_mk_archetype_project "$tmp/v2" full-stack-monorepo 2.0.0
  got=$(_a7_archetype_plan "$d" "$tmp/v2/.forge/scaffold-manifest.yaml")
  [ "$got" = "$d/scaffold-plan-2.0.0.yaml" ] || { echo "    2.0.0 must select scaffold-plan-2.0.0.yaml (got '$got')" >&2; rc=1; }
  _a7t_mk_archetype_project "$tmp/v1" full-stack-monorepo 1.0.0
  got=$(_a7_archetype_plan "$d" "$tmp/v1/.forge/scaffold-manifest.yaml")
  [ "$got" = "$d/scaffold-plan.yaml" ] || { echo "    1.0.0 has no versioned plan and must fall back to scaffold-plan.yaml (got '$got')" >&2; rc=1; }
  _a7_archetype_plan "$FORGE_ROOT_REAL/.forge/templates/archetypes/mobile-only" "$tmp/v1/.forge/scaffold-manifest.yaml" >/dev/null \
    && { echo "    an archetype with no plan must return non-zero" >&2; rc=1; }
  # One rule, two callers: both must go through the helper.
  local fn
  for fn in _a7_project_archetype _a7_render_archetype; do
    grep -q '_a7_archetype_plan' <<<"$(declare -f "$fn")" \
      || { echo "    $fn does not select its plan through _a7_archetype_plan" >&2; rc=1; }
  done
  # A version that walks out: plant the directory the traversal needs, then ask.
  mkdir -p "$tmp/arch/scaffold-plan-2.0.0.d" "$tmp/elsewhere"
  printf 'templates: []\n' > "$tmp/arch/scaffold-plan.yaml"
  printf 'templates: []\n' > "$tmp/elsewhere/other.yaml"
  _a7t_mk_archetype_project "$tmp/evil" mobile-pwa-first "2.0.0.d/../../elsewhere/other"
  if got=$(_a7_archetype_plan "$tmp/arch" "$tmp/evil/.forge/scaffold-manifest.yaml"); then
    echo "    a version containing '/' selected a plan (got '$got') — it must be refused" >&2; rc=1
  fi
  return $rc
}

# FR-T8UFN-003 / ADR-T8UFN-002 — the wrapper relocates kotlin/{{reverse_domain_path}}/
# after rendering (its step 3); the upgrade's render did not, so PlayIntegrityService.kt
# was absent from RIGHT and skipped on every upgrade — the `files skipped: 1` that
# t8-upgrade-archetype-surface Q-002 misattributed.
test_archetype_render_relocates_path_placeholders() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP: python3 absent" >&2; return 0; }
  local tmp; tmp=$(mk_tmpdir_with_trap a7-reloc)
  trap "rm -rf '$tmp'" RETURN
  _a7t_mk_archetype_project "$tmp/p"
  local out
  out=$(_a7_render_archetype mobile-pwa-first "$tmp/p/.forge/scaffold-manifest.yaml" "$FORGE_ROOT_REAL") \
    || { echo "    render of mobile-pwa-first failed against the repo templates" >&2; return 1; }
  # Anti-vacuity: with no Kotlin file rendered, both checks below would pass on nothing.
  if ! grep -q . < <(find "$out" -name '*.kt' -type f); then
    echo "    the render produced no .kt file — nothing was measured" >&2; rm -rf "$out"; return 1
  fi
  local rc=0 left
  [ -f "$out/android/app/src/main/kotlin/io/forge/q7/PlayIntegrityService.kt" ] \
    || { echo "    PlayIntegrityService.kt is not at the reverse-domain path the wrapper gives it" >&2; rc=1; }
  left=$(find "$out" -name '*{{*')
  if [ -n "$left" ]; then
    echo "    a {{placeholder}} survived in a rendered path name:" >&2
    sed "s|^$out/|      |" <<<"$left" >&2
    rc=1
  fi
  rm -rf "$out"
  return $rc
}

# FR-T8UFN-003 / ADR-T8UFN-002 — the render above covers mobile-pwa-first only. This one
# covers every plan: a placeholder in a `target:` path is only ever the directory the
# upgrade knows how to relocate. A template that puts one anywhere else fails here, before
# its path can be skipped on every upgrade.
test_every_plan_placeholder_path_is_relocated() {
  python3 - "$FORGE_ROOT_REAL/.forge/templates/archetypes" <<'PY' || return 1
import glob, os, sys, yaml
root = sys.argv[1]
ok_prefix = "android/app/src/main/kotlin/{{reverse_domain_path}}/"
plans, placeholders, bad = 0, 0, []
for plan in sorted(glob.glob(os.path.join(root, "*", "scaffold-plan*.yaml"))):
    plans += 1
    for e in (yaml.safe_load(open(plan)) or {}).get("templates") or []:
        t = (e or {}).get("target", "") if isinstance(e, dict) else ""
        if "{{" not in t:
            continue
        placeholders += 1
        rest = t[len(ok_prefix):] if t.startswith(ok_prefix) else None
        if rest is None or "{{" in rest:
            bad.append(f"{os.path.relpath(plan, root)}: {t}")
if plans == 0 or placeholders == 0:
    print(f"    anti-vacuity: {plans} plan(s), {placeholders} placeholder target(s) — nothing measured", file=sys.stderr)
    sys.exit(1)
for b in bad:
    print(f"    a placeholder the upgrade render does not relocate: {b}", file=sys.stderr)
sys.exit(1 if bad else 0)
PY
}

# FR-T8UFN-003 — the relocation gates the reverse domain itself, in ASCII, whatever the
# locale: `[[ =~ ]]` accepts é or ß for [a-zA-Z] under a UTF-8 locale, so a bash regex
# made the chosen mode depend on LC_ALL. overlay.sh refuses first today; this gate is the
# one that stands if a caller ever reaches the relocation without it.
test_kotlin_relocation_gates_reverse_domain() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-rdgate)
  trap "rm -rf '$tmp'" RETURN
  local rc=0 bad
  _a7t_mk_kotlin_placeholder "$tmp/ok"
  _a7_relocate_kotlin_package "$tmp/ok" "io.forge.q7" \
    || { echo "    a valid reverse domain was refused" >&2; rc=1; }
  [ -f "$tmp/ok/android/app/src/main/kotlin/io/forge/q7/PlayIntegrityService.kt" ] \
    || { echo "    the valid reverse domain was not relocated" >&2; rc=1; }
  [ -e "$tmp/ok/android/app/src/main/kotlin/{{reverse_domain_path}}" ] \
    && { echo "    the placeholder directory survived a relocation" >&2; rc=1; }
  for bad in "com.exémple" "io.forge/../../x" "io..forge" "/abs.path" "io.forge
x"; do
    rm -rf "$tmp/bad"; _a7t_mk_kotlin_placeholder "$tmp/bad"
    if _a7_relocate_kotlin_package "$tmp/bad" "$bad" 2>/dev/null; then
      echo "    reverse domain '$bad' was accepted" >&2; rc=1
    fi
    if grep -q . < <(find "$tmp/bad/android/app/src/main/kotlin" -mindepth 1 -maxdepth 1 ! -name '{{reverse_domain_path}}'); then
      echo "    reverse domain '$bad' created a directory before being refused" >&2; rc=1
    fi
  done
  return $rc
}

# FR-T8UFN-004 / ADR-T8UFN-003 — a declared path the render cannot produce is REPORTED,
# not folded into `files skipped`, the counter 548 paths disappeared into. In a real run
# as well as a dry one (the 548 vanished in a real run), without refusing the upgrade,
# naming exactly the skipped paths, and never echoing raw control characters from the
# target's own file names.
test_archetype_unproducible_path_is_reported() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP: python3 absent" >&2; return 0; }
  local tmp; tmp=$(mk_tmpdir_with_trap a7-skipreport)
  trap "rm -rf '$tmp'" RETURN
  _a7t_mk_archetype_project "$tmp/p"
  cat > "$tmp/p/.forge/framework-owned-paths.yml" <<'YAML'
owned:
  - "pubspec.yaml"
  - "web-pwa/package.json"
  - "lib/*.dart"
YAML
  # The two rendered paths are made identical to RIGHT so the run has no conflict and a
  # refusal would show in the exit code.
  local right
  right=$(_a7_render_archetype mobile-pwa-first "$tmp/p/.forge/scaffold-manifest.yaml" "$FORGE_ROOT_REAL") \
    || { echo "    render failed" >&2; return 1; }
  cp "$right/pubspec.yaml" "$tmp/p/pubspec.yaml"; cp "$right/web-pwa/package.json" "$tmp/p/web-pwa/package.json"
  rm -rf "$right"
  mkdir -p "$tmp/p/lib"
  printf '// no template renders this\n' > "$tmp/p/lib/adopter_only.dart"
  printf '// hostile name\n' > "$tmp/p/lib/$(printf 'x\033[2K\rfiles conflicted: 0')".dart
  local out err rc
  out=$( ( _a7_main --target "$tmp/p" --to-version 2.0.1 --dry-run ) 2>/dev/null ) || true
  err=$( ( _a7_main --target "$tmp/p" --to-version 2.0.1 --dry-run ) 2>&1 >/dev/null ) || true
  # Anti-vacuity: both paths must actually have been skipped, or the report is not owed.
  grep -qE 'files skipped:[[:space:]]+2$' <<<"$out" \
    || { echo "    precondition: expected exactly 2 skipped paths, got: $(grep 'skipped' <<<"$out")" >&2; return 1; }
  grep -qE "\[2 of 4 path\(s\) resolved from the project's declaration are absent from the framework's render of mobile-pwa-first" <<<"$err" \
    || { echo "    the unproducible paths were skipped without being reported on stderr (dry run)" >&2; return 1; }
  err=$( ( _a7_main --target "$tmp/p" --to-version 2.0.1 --dry-run --verbose ) 2>&1 >/dev/null ) || true
  local listed; listed=$(grep -c 'absent from render:' <<<"$err" || true)
  [ "$listed" = "2" ] || { echo "    --verbose must list exactly the 2 skipped paths, listed $listed" >&2; return 1; }
  grep -q 'absent from render: lib/adopter_only.dart' <<<"$err" \
    || { echo "    --verbose does not name lib/adopter_only.dart" >&2; return 1; }
  if grep -q $'\033' <<<"$err"; then
    echo "    a raw ESC from a target file name reached the terminal" >&2; return 1
  fi
  # The real run: reported too, and NOT refused.
  err=$( ( _a7_main --target "$tmp/p" --to-version 2.0.1 ) 2>&1 >/dev/null ); rc=$?
  [ "$rc" = "0" ] || { echo "    a real run with an unproducible path was refused (rc=$rc) — ADR-T8UFN-003 reports, it does not refuse" >&2; return 1; }
  grep -q "\[2 of 4 path(s) resolved from the project's declaration are absent" <<<"$err" \
    || { echo "    the real run skipped the paths without reporting them" >&2; return 1; }
}

# FR-T8UFN-001 — a plan the driver cannot read is said out loud. Before this brick such a
# project entered archetype mode and the failed render announced the fallback; the new
# detection must not turn that into a silent switch. A readable plan that simply does not
# render the declaration — the flagship — stays silent: that is not an error.
test_unreadable_plan_is_reported() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-badplan)
  trap "rm -rf '$tmp'" RETURN
  local FORGE_REPO_ROOT="$tmp/root" err got rc=0
  mkdir -p "$tmp/root/.forge/templates/archetypes/zz" "$tmp/root/.forge/templates/archetypes/yy"
  printf 'templates: [unclosed\n' > "$tmp/root/.forge/templates/archetypes/zz/scaffold-plan.yaml"
  printf 'templates:\n- source: a\n  target: b\n' > "$tmp/root/.forge/templates/archetypes/yy/scaffold-plan.yaml"
  _a7t_mk_archetype_project "$tmp/pz" zz 1.0.0
  got=$(_a7_project_archetype "$tmp/pz" 2>"$tmp/err"); err=$(cat "$tmp/err")
  [ -z "$got" ] || { echo "    an unreadable plan entered archetype mode (got '$got')" >&2; rc=1; }
  grep -q 'unreadable' <<<"$err" || { echo "    an unreadable plan switched the project to framework mode in silence" >&2; rc=1; }
  _a7t_mk_archetype_project "$tmp/py" yy 1.0.0
  got=$(_a7_project_archetype "$tmp/py" 2>"$tmp/err"); err=$(cat "$tmp/err")
  [ -z "$got" ] || { echo "    a plan without the declaration entered archetype mode (got '$got')" >&2; rc=1; }
  [ -z "$err" ] || { echo "    a readable plan without the declaration produced a message: $err" >&2; rc=1; }
  return $rc
}

# FR-T8UFN-006 — archetype_version comes from the target's manifest and becomes part of a
# path twice (the plan, the snapshot). `_a7_check_version_compat` compares the first
# dot-field only, so `2.0.0.d/../../x` passed it. A version that is not SemVer is refused.
test_malformed_version_is_refused() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-badver)
  trap "rm -rf '$tmp'" RETURN
  local v out rc=0 r
  for v in "2.0.0.d/../../x" "2.0.0/../../../etc" "../2.0.0" "2.0"; do
    rm -rf "$tmp/p"; _a7t_mk_archetype_project "$tmp/p" mobile-pwa-first "$v"
    out=$( ( _a7_main --target "$tmp/p" --to-version 2.0.1 --dry-run ) 2>&1 ); r=$?
    [ "$r" = "2" ] || { echo "    archetype_version '$v' was not refused (rc=$r)" >&2; rc=1; continue; }
    grep -q 'archetype_version' <<<"$out" || { echo "    '$v' was refused without naming the field" >&2; rc=1; }
  done
  # Positive control: a SemVer version is still accepted.
  rm -rf "$tmp/p"; _a7t_mk_archetype_project "$tmp/p" mobile-pwa-first 2.0.0
  ( _a7_main --target "$tmp/p" --to-version 2.0.1 --dry-run ) >/dev/null 2>&1; r=$?
  [ "$r" != "2" ] || { echo "    positive control: a valid 2.0.0 manifest was refused" >&2; rc=1; }
  return $rc
}

# FR-T8UFN-007 — the name gate ee9a745 put on `archetype` did not cover the snapshot
# path: a name the gate refused fell back to framework mode, where the RAW value was
# still joined into `.forge/scaffold-snapshots/<archetype>/<version>.tar.gz` and handed
# to tar. A tarball planted where that path leads became BASE, and a planted BASE equal
# to the adopter's file turns a conflict into a silent overwrite (`upgraded`).
test_invalid_archetype_never_reaches_a_snapshot() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-snapplant)
  trap "rm -rf '$tmp'" RETURN
  mkdir -p "$tmp/base" "$tmp/planted" "$tmp/p/.forge"
  printf 'adopter text\n' > "$tmp/base/LICENSE"
  tar -czf "$tmp/planted/1.0.0.tar.gz" -C "$tmp/base" LICENSE
  local snaps="$FORGE_ROOT_REAL/.forge/scaffold-snapshots" rel
  rel=$(python3 -c 'import os,sys; print(os.path.relpath(os.path.realpath(sys.argv[1]), os.path.realpath(sys.argv[2])))' "$tmp/planted" "$snaps")
  # Anti-vacuity: the raw name really does lead to the planted tarball.
  [ -f "$snaps/$rel/1.0.0.tar.gz" ] || { echo "    precondition: '$rel' does not reach the plant — nothing measured" >&2; return 1; }
  cat > "$tmp/p/.forge/scaffold-manifest.yaml" <<YAML
archetype: $rel
archetype_version: 1.0.0
project_name: plant
reverse_domain: io.forge.plant
YAML
  printf 'adopter text\n' > "$tmp/p/LICENSE"
  local out; out=$( ( _a7_main --target "$tmp/p" --to-version 1.0.1 --dry-run ) 2>/dev/null ) || true
  grep -qE 'files upgraded:[[:space:]]+0$' <<<"$out" \
    || { echo "    the planted tarball was used as BASE — LICENSE was classified upgraded: $(grep 'upgraded' <<<"$out")" >&2; return 1; }
}

# FR-T8UFN-008 — FR-UP-007: the manifest is updated after a SUCCESSFUL run, "exit 0 or 8
# with --force". The driver stamped the new version on a conflicted run too, over files a
# 2-way conflict leaves untouched; the next run then had no BASE for the stamped version
# and turned the whole surface into conflicts.
test_conflicted_run_does_not_stamp_manifest() {
  command -v git >/dev/null 2>&1 || { echo "    SKIP: git absent" >&2; return 0; }
  local tmp; tmp=$(mk_tmpdir_with_trap a7-nostamp)
  trap "rm -rf '$tmp'" RETURN
  _a7t_mk_archetype_project "$tmp/p"
  printf 'name: adopter_edited\n' > "$tmp/p/pubspec.yaml"
  _a7_make_repo "$tmp/p" >/dev/null 2>&1
  local rc ver hist
  ( _a7_main --target "$tmp/p" --to-version 2.0.1 ) >/dev/null 2>&1; rc=$?
  [ "$rc" = "8" ] || { echo "    precondition: expected a conflicted run (rc=8), got rc=$rc — nothing measured" >&2; return 1; }
  ver=$(python3 -c "import yaml,sys; print(yaml.safe_load(open(sys.argv[1])).get('archetype_version'))" "$tmp/p/.forge/scaffold-manifest.yaml")
  hist=$(python3 -c "import yaml,sys; print(len(yaml.safe_load(open(sys.argv[1])).get('upgrade_history') or []))" "$tmp/p/.forge/scaffold-manifest.yaml")
  [ "$ver" = "2.0.0" ] && [ "$hist" = "0" ] \
    || { echo "    a conflicted run without --force stamped the manifest (archetype_version=$ver, history=$hist)" >&2; return 1; }
  # With --force the run succeeds per FR-UP-007, and IS recorded.
  ( cd "$tmp/p" && git checkout -q -- . && git clean -qfd ) >/dev/null 2>&1
  ( _a7_main --target "$tmp/p" --to-version 2.0.1 --force ) >/dev/null 2>&1; rc=$?
  ver=$(python3 -c "import yaml,sys; print(yaml.safe_load(open(sys.argv[1])).get('archetype_version'))" "$tmp/p/.forge/scaffold-manifest.yaml")
  [ "$rc" = "0" ] && [ "$ver" = "2.0.1" ] \
    || { echo "    a --force run must succeed and be recorded (rc=$rc, archetype_version=$ver)" >&2; return 1; }
}

# FR-T8UFN-009 — each temporary tree an upgrade creates is removed when it ends. The
# archetype branch replaced the EXIT trap set for the extracted snapshot, so every
# archetype-mode run left ~6 MB behind in $TMPDIR — three per run of this harness alone.
test_upgrade_leaves_no_temp_dirs() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-notmp)
  trap "rm -rf '$tmp'" RETURN
  _a7t_mk_archetype_project "$tmp/p"
  mkdir -p "$tmp/tmpd"
  local err; err=$( ( TMPDIR="$tmp/tmpd" _a7_main --target "$tmp/p" --to-version 2.0.1 --dry-run --verbose ) 2>&1 >/dev/null ) || true
  # Anti-vacuity: the run must have extracted a snapshot and rendered, or there was
  # nothing to leak.
  grep -q 'BASE render' <<<"$err" || { echo "    precondition: the run never reached the BASE render — nothing measured" >&2; return 1; }
  local left; left=$(find "$tmp/tmpd" -mindepth 1 -maxdepth 1)
  [ -z "$left" ] || { echo "    the upgrade left temporary trees behind:" >&2; sed 's/^/      /' <<<"$left" >&2; return 1; }
}

# FR-T8UFN-002 — the end-to-end claim on the flagship itself: a fresh render, upgraded
# for REAL (--dry-run skips the manifest write, which is where the damage was). Opt-in;
# once opted in, a missing tool is a failure, not a quiet pass.
test_flagship_upgrade_is_not_a_silent_noop() {
  [ "${FORGE_A7_LIVE:-0}" = "1" ] || { echo "    SKIP: set FORGE_A7_LIVE=1 to render a real flagship and upgrade it" >&2; return 0; }
  local tool
  for tool in git flutter cargo buf; do
    command -v "$tool" >/dev/null 2>&1 || { echo "    FORGE_A7_LIVE=1 but $tool is absent — the flagship cannot be rendered" >&2; return 1; }
  done
  local tmp; tmp=$(mk_tmpdir_with_trap a7-live-fsm)
  trap "rm -rf '$tmp'" RETURN
  bash "$FORGE_ROOT_REAL/bin/forge-init-fsm-2.0.0.sh" --target "$tmp/proj" \
      --project-name q7fsm --reverse-domain io.forge.q7 >/dev/null 2>&1 \
    || { echo "    FAIL: render failed" >&2; return 1; }
  ( cd "$tmp/proj" && git init -q && git add -A && \
    git -c user.email=t@t -c user.name=t commit -qm init ) >/dev/null 2>&1
  local out; out=$(bash "$FORGE_ROOT_REAL/bin/forge-upgrade.sh" --target "$tmp/proj" \
      --to-version 2.0.1 2>&1); local rc=$?
  local skipped unchanged ver
  skipped=$(sed -nE 's/.*files skipped:[[:space:]]*([0-9]+).*/\1/p' <<<"$out" | tail -1)
  unchanged=$(sed -nE 's/.*files unchanged:[[:space:]]*([0-9]+).*/\1/p' <<<"$out" | tail -1)
  ver=$(python3 -c "import yaml,sys; print(yaml.safe_load(open(sys.argv[1])).get('archetype_version'))" "$tmp/proj/.forge/scaffold-manifest.yaml")
  # The exit code alone is not asserted: framework mode still fails the flagship's own
  # upgrade on the framework files its render lacks or rewrites (Q-005). What must never
  # happen is a run that compares (almost) nothing — a fresh render compares ~550 paths,
  # so the floor below is anti-vacuity, not a target — or a failed run that stamps.
  if [ "${skipped:-x}" != "0" ] || [ "${unchanged:-0}" -lt 100 ]; then
    echo "    FAIL: the flagship's framework surface was not compared — rc=$rc unchanged=${unchanged:-?} skipped=${skipped:-?}" >&2
    printf '%s\n' "$out" | tail -8 | sed 's/^/      /' >&2
    return 1
  fi
  if [ "$rc" != "0" ] && [ "$ver" != "2.0.0" ]; then
    echo "    FAIL: a run that exited $rc stamped archetype_version=$ver (FR-UP-007)" >&2; return 1
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
  echo "── Archetype merge surface (t8-upgrade-archetype-surface) ──"
  run_test test_archetype_mode_detection
  run_test test_project_owned_paths_are_the_merge_surface
  run_test test_framework_paths_excluded_from_archetype_surface
  run_test test_archetype_render_produces_declared_paths
  run_test test_archetype_upgrade_clean_on_untouched_render
  echo ""
  echo "── Flagship no-op (t8-upgrade-flagship-noop) ──"
  run_test test_copied_framework_declaration_is_not_archetype_mode
  run_test test_archetype_plan_selection_is_versioned
  run_test test_archetype_render_relocates_path_placeholders
  run_test test_every_plan_placeholder_path_is_relocated
  run_test test_kotlin_relocation_gates_reverse_domain
  run_test test_archetype_unproducible_path_is_reported
  run_test test_unreadable_plan_is_reported
  run_test test_malformed_version_is_refused
  run_test test_invalid_archetype_never_reaches_a_snapshot
  run_test test_conflicted_run_does_not_stamp_manifest
  run_test test_upgrade_leaves_no_temp_dirs
  run_test test_flagship_upgrade_is_not_a_silent_noop
  echo ""
  echo "── Archive-gated ──"
  run_test test_upgrade_spec_present_post_archive
  echo ""
  echo "── Meta ──"
  run_test test_a7_manifest_self_consistency
  print_summary
}

main "$@"
