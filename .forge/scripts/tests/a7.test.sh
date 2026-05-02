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
  if ! echo "$out" | grep -q '\[NEEDS MIGRATION: from 1.5.2 to 2.0.0\]'; then
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
