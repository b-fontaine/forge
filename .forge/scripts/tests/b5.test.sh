#!/usr/bin/env bash
# Forge — B.5.1 Init Wizard Test Harness (b5-1-init-wizard)
# <!-- Audit: B.5.1 (b5-1-init-wizard) -->
#
# Validates :
#  - Dispatch table shape + scaffolder paths exist (FR-IW-002)
#  - bin/forge-init-fsm.sh ABI translation (FR-IW-004)
#  - Standard global/scaffolding.md sections (FR-IW-008)
#  - Index entry (FR-IW-010)
#  - docs/ARCHETYPES.md decision matrix (FR-IW-009)
#  - features/init-wizard.feature scenarios (FR-IW-013 / AC-IW-*)
#  - reverse-domain regex (FR-IW-007)
#  - No new third-party deps (NFR-IW-002)
#  - CLI flag parsing (FR-IW-001)
#  - Default dispatcher idempotence (NFR-IW-001)
#  - Wizard skips when non-TTY (NFR-IW-003 / ADR-007)
#  - Auto-detection ambiguous aborts (FR-IW-005)
#  - L3 end-to-end full-stack-monorepo (MODIFIED FR-GL-011, opt-in)
#
# Manifest pattern : a `# MANIFEST: test_* — FR-IW-NNN` comment
# block below is parsed by `test_b5_manifest_self_consistency`.
#
# Usage :
#   bash .forge/scripts/tests/b5.test.sh
#   bash .forge/scripts/tests/b5.test.sh --require-external-tools

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

DISPATCH_TABLE="$FORGE_ROOT_REAL/.forge/scaffolding/dispatch-table.yml"
FSM_WRAPPER="$FORGE_ROOT_REAL/bin/forge-init-fsm.sh"
STD_SCAFFOLDING="$FORGE_ROOT_REAL/.forge/standards/global/scaffolding.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
ARCHETYPES_MD="$FORGE_ROOT_REAL/docs/ARCHETYPES.md"
FEATURE_FILE="$FORGE_ROOT_REAL/.forge/changes/b5-1-init-wizard/features/init-wizard.feature"
INIT_TS="$FORGE_ROOT_REAL/cli/src/commands/init.ts"
CLI_TS="$FORGE_ROOT_REAL/cli/src/cli.ts"
B5_FORGE_YAML="$FORGE_ROOT_REAL/.forge/changes/b5-1-init-wizard/.forge.yaml"
SPEC_INIT_WIZARD="$FORGE_ROOT_REAL/.forge/specs/init-wizard.md"
PACKAGE_JSON="$FORGE_ROOT_REAL/cli/package.json"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# Phase 1 — scaffolding cluster
# MANIFEST: test_dispatch_table_shape                    — FR-IW-002
# MANIFEST: test_dispatch_scaffolders_exist              — FR-IW-002
# MANIFEST: test_forge_init_fsm_sh_exists_executable     — FR-IW-004
# MANIFEST: test_forge_init_fsm_sh_translates_abi        — FR-IW-004
# MANIFEST: test_standard_scaffolding_has_required_sections — FR-IW-008
# MANIFEST: test_index_has_scaffolding_entry             — FR-IW-010
# MANIFEST: test_archetypes_decision_matrix_present      — FR-IW-009
# MANIFEST: test_features_init_wizard_feature_present    — FR-IW-013
# MANIFEST: test_reverse_domain_regex                    — FR-IW-007
# MANIFEST: test_no_new_third_party_deps                 — NFR-IW-002
#
# Phase 2 — dispatcher + domain + wizard
# MANIFEST: test_init_cli_flags_parse                    — FR-IW-001
# MANIFEST: test_default_dispatcher_idempotent           — NFR-IW-001
# MANIFEST: test_wizard_skips_when_non_tty               — NFR-IW-003
# MANIFEST: test_auto_detection_ambiguous_aborts         — FR-IW-005
#
# Phase 3 — L3 (opt-in)
# MANIFEST: test_l3_end_to_end_full_stack_monorepo       — MODIFIED FR-GL-011
#
# Archive-gated
# MANIFEST: test_init_wizard_spec_present_post_archive   — FR-IW-012
#
# Meta
# MANIFEST: test_b5_manifest_self_consistency            — meta (FR-IW-011)
#
# ────────────────────────────────────────────────────────────────

test_b5_manifest_self_consistency() {
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

# FR-IW-002 — dispatch table has the required shape.
test_dispatch_table_shape() {
  if [ ! -f "$DISPATCH_TABLE" ]; then
    echo "    missing: $DISPATCH_TABLE" >&2; return 1
  fi
  python3 - "$DISPATCH_TABLE" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
errs = []
arch = d.get("archetypes")
if not isinstance(arch, dict) or not arch:
    errs.append("missing or empty top-level 'archetypes' map")
else:
    for required in ("default", "full-stack-monorepo"):
        if required not in arch:
            errs.append(f"missing archetype '{required}'")
            continue
        entry = arch[required]
        for field in ("name", "scaffolder"):
            if field not in entry:
                errs.append(f"{required}: missing required field '{field}'")
        if entry.get("name") != required:
            errs.append(f"{required}: name field {entry.get('name')!r} != map key")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-IW-002 — every scaffolder value resolves to a file or "<built-in>".
test_dispatch_scaffolders_exist() {
  python3 - "$DISPATCH_TABLE" "$FORGE_ROOT_REAL" <<'PY' || return 1
import sys, os, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
root = sys.argv[2]
errs = []
for name, entry in (d.get("archetypes") or {}).items():
    s = entry.get("scaffolder", "")
    # Skip built-in (no on-disk script) and entries explicitly removed
    # from the roadmap (annotated by t4-adr-ratification per ADR-007 ;
    # the slot is preserved for forge upgrade history but the scaffolder
    # path is intentionally "<removed>").
    if s in ("<built-in>", "<removed>"):
        continue
    if entry.get("status") == "removed_from_roadmap":
        continue
    p = os.path.join(root, s)
    if not os.path.isfile(p):
        errs.append(f"{name}: scaffolder path does not exist: {s}")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-IW-004 — bin/forge-init-fsm.sh exists, executable, bash.
test_forge_init_fsm_sh_exists_executable() {
  if [ ! -f "$FSM_WRAPPER" ]; then
    echo "    missing: $FSM_WRAPPER" >&2; return 1
  fi
  if [ ! -x "$FSM_WRAPPER" ]; then
    echo "    not executable: $FSM_WRAPPER" >&2; return 1
  fi
  if ! head -1 "$FSM_WRAPPER" | grep -qE '^#!.*bash'; then
    echo "    shebang is not bash" >&2; return 1
  fi
}

# FR-IW-004 — wrapper translates the stable ABI to init.sh's
# legacy ABI. Mock init.sh via a shim that captures argv.
test_forge_init_fsm_sh_translates_abi() {
  local tmp; tmp=$(mk_tmpdir_with_trap a7-fsm-abi)
  trap "rm -rf '$tmp'" RETURN
  # Build a fake FORGE_ROOT with a stub init.sh that echoes its argv.
  mkdir -p "$tmp/.forge/scripts/scaffolder" "$tmp/bin"
  cp "$FSM_WRAPPER" "$tmp/bin/"
  cat > "$tmp/.forge/scripts/scaffolder/init.sh" <<'SHIM'
#!/usr/bin/env bash
echo "argv: $*"
SHIM
  chmod +x "$tmp/.forge/scripts/scaffolder/init.sh"
  local out
  out=$(bash "$tmp/bin/forge-init-fsm.sh" \
    --target /some/dir --project-name foo --reverse-domain io.test.foo 2>&1)
  if ! echo "$out" | grep -q 'argv: foo --org io.test.foo --target-dir /some/dir'; then
    echo "    wrapper ABI translation mismatch. Got: $out" >&2
    return 1
  fi
}

# FR-IW-008 — standard has the 6 H2 sections.
test_standard_scaffolding_has_required_sections() {
  if [ ! -f "$STD_SCAFFOLDING" ]; then
    echo "    missing: $STD_SCAFFOLDING" >&2; return 1
  fi
  local section
  for section in '## Dispatch table contract' \
                 '## Per-archetype scaffolder ABI' \
                 '## Auto-detection heuristic' \
                 '## Interactive wizard mode' \
                 '## Adding a new archetype' \
                 '## Interdictions'; do
    if ! grep -qF "$section" "$STD_SCAFFOLDING"; then
      echo "    missing H2: $section" >&2; return 1
    fi
  done
}

# FR-IW-010 — index entry present.
test_index_has_scaffolding_entry() {
  python3 - "$INDEX_YML" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
entries = d.get("standards") or []
hit = next((e for e in entries if e.get("id") == "global/scaffolding"), None)
errs = []
if hit is None:
    errs.append("no entry with id 'global/scaffolding'")
else:
    if hit.get("scope") != "all":
        errs.append(f"scope should be 'all', got {hit.get('scope')!r}")
    if hit.get("priority") != "high":
        errs.append(f"priority should be 'high', got {hit.get('priority')!r}")
    triggers = hit.get("triggers") or []
    for needle in ("init", "forge init", "wizard", "archetype", "dispatch-table"):
        if needle not in triggers:
            errs.append(f"missing trigger: {needle!r}")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-IW-009 — docs/ARCHETYPES.md decision matrix.
test_archetypes_decision_matrix_present() {
  if [ ! -f "$ARCHETYPES_MD" ]; then
    echo "    missing: $ARCHETYPES_MD" >&2; return 1
  fi
  if ! grep -qE '^# Forge Archetypes' "$ARCHETYPES_MD"; then
    echo "    H1 title 'Forge Archetypes' missing" >&2; return 1
  fi
  for archetype in default full-stack-monorepo flutter-firebase mobile-only rust-cli-tui; do
    if ! grep -qE "\`$archetype\`" "$ARCHETYPES_MD"; then
      echo "    matrix missing archetype: $archetype" >&2; return 1
    fi
  done
}

# FR-IW-013 — feature file has 5+ scenarios mapped to AC-IW-*.
test_features_init_wizard_feature_present() {
  if [ ! -f "$FEATURE_FILE" ]; then
    echo "    missing: $FEATURE_FILE" >&2; return 1
  fi
  local count
  count=$(grep -cE '^[[:space:]]*Scenario:' "$FEATURE_FILE")
  if [ "$count" -lt 5 ]; then
    echo "    expected >= 5 Scenario blocks, got $count" >&2; return 1
  fi
}

# FR-IW-007 — reverse-domain regex valid + invalid cases.
test_reverse_domain_regex() {
  python3 - <<'PY' || return 1
import re, sys
pattern = re.compile(r'^[a-z][a-z0-9.-]+\.[a-z][a-z0-9.-]+$')
valid = ['io.acme.app', 'co.uk.example', 'org.example.foo']
invalid = ['', 'Acme.io', '123.acme.io', 'acme', '.acme.io', '-bad.com']
errs = []
for v in valid:
    if not pattern.match(v):
        errs.append(f"valid input rejected: {v!r}")
for v in invalid:
    if pattern.match(v):
        errs.append(f"invalid input accepted: {v!r}")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# NFR-IW-002 — no new third-party deps in cli/package.json
# vs the b5.1-baseline (snapshot the prior keys here).
# Baseline (post-a7-forge-upgrade) :
#   dependencies: [commander]
#   devDependencies: [@types/node, @vitest/coverage-v8, esbuild,
#                     eslint, prettier, typescript, vitest]
test_no_new_third_party_deps() {
  python3 - "$PACKAGE_JSON" <<'PY' || return 1
import json, sys
d = json.load(open(sys.argv[1]))
deps = sorted((d.get("dependencies") or {}).keys())
dev = sorted((d.get("devDependencies") or {}).keys())
allowed_deps = {"commander"}
allowed_dev = {"@types/node", "@vitest/coverage-v8", "esbuild",
               "eslint", "prettier", "typescript", "vitest"}
extras_deps = set(deps) - allowed_deps
extras_dev = set(dev) - allowed_dev
errs = []
if extras_deps:
    errs.append(f"new runtime deps: {sorted(extras_deps)}")
if extras_dev:
    errs.append(f"new dev deps: {sorted(extras_dev)}")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# ─── Phase 2 — dispatcher + domain + wizard ───────────────────

# FR-IW-001 — cli.ts registers --archetype, --auto, --wizard, --org.
test_init_cli_flags_parse() {
  if [ ! -f "$CLI_TS" ]; then
    echo "    cli.ts missing: $CLI_TS" >&2; return 1
  fi
  local needle
  for needle in '--archetype <name>' '--auto' '--wizard' '--org <reverse-domain>'; do
    if ! grep -qF -- "$needle" "$CLI_TS"; then
      echo "    cli.ts missing option declaration: $needle" >&2
      return 1
    fi
  done
  if ! grep -q 'parseDispatchTable' "$CLI_TS"; then
    echo "    cli.ts does not import parseDispatchTable" >&2
    return 1
  fi
}

# NFR-IW-001 — running default dispatch twice produces the same outcome.
test_default_dispatcher_idempotent() {
  local tmp_target tmp_source
  tmp_target=$(mk_tmpdir_with_trap b5-idemp-target)
  tmp_source=$(mk_tmpdir_with_trap b5-idemp-source)
  trap "rm -rf '$tmp_target' '$tmp_source'" RETURN
  printf "# minimal\n" > "$tmp_source/CLAUDE.md"
  local cli_dist="$FORGE_ROOT_REAL/cli/dist/index.js"
  if [ ! -f "$cli_dist" ]; then
    echo "    CLI not built — run: cd cli && npm run build" >&2
    return 1
  fi
  local rc1 rc2
  node "$cli_dist" init --archetype default --source "$tmp_source" --target "$tmp_target" >/dev/null 2>&1 && rc1=0 || rc1=$?
  node "$cli_dist" init --archetype default --source "$tmp_source" --target "$tmp_target" >/dev/null 2>&1 && rc2=0 || rc2=$?
  if [ "$rc1" != "0" ] || [ "$rc2" != "0" ]; then
    echo "    unexpected exit codes: first=$rc1 second=$rc2" >&2
    return 1
  fi
}

# NFR-IW-003 — non-TTY without flags routes to silent default.
test_wizard_skips_when_non_tty() {
  local tmp_target tmp_source
  tmp_target=$(mk_tmpdir_with_trap b5-non-tty-target)
  tmp_source=$(mk_tmpdir_with_trap b5-non-tty-source)
  trap "rm -rf '$tmp_target' '$tmp_source'" RETURN
  printf "# minimal\n" > "$tmp_source/CLAUDE.md"
  local cli_dist="$FORGE_ROOT_REAL/cli/dist/index.js"
  [ -f "$cli_dist" ] || { echo "    CLI not built" >&2; return 1; }
  local out
  out=$(node "$cli_dist" init --source "$tmp_source" --target "$tmp_target" </dev/null 2>&1)
  if echo "$out" | grep -q 'Pick an archetype'; then
    echo "    wizard prompt appeared on non-TTY stdin" >&2
    return 1
  fi
  if ! echo "$out" | grep -q 'forge init: copied'; then
    echo "    silent default did not produce the legacy summary line" >&2
    echo "    output: $out" >&2
    return 1
  fi
}

# FR-IW-005 — --auto on ambiguous target dir aborts with [NEEDS DECISION:].
test_auto_detection_ambiguous_aborts() {
  local tmp_target tmp_source
  tmp_target=$(mk_tmpdir_with_trap b5-auto-amb)
  tmp_source=$(mk_tmpdir_with_trap b5-auto-amb-src)
  trap "rm -rf '$tmp_target' '$tmp_source'" RETURN
  printf "# pubspec\n" > "$tmp_target/pubspec.yaml"
  local cli_dist="$FORGE_ROOT_REAL/cli/dist/index.js"
  [ -f "$cli_dist" ] || { echo "    CLI not built" >&2; return 1; }
  local out rc
  out=$(node "$cli_dist" init --auto --source "$tmp_source" --target "$tmp_target" 2>&1) && rc=0 || rc=$?
  if [ "$rc" != "2" ]; then
    echo "    expected exit 2 on ambiguous --auto, got $rc" >&2
    echo "    output: $out" >&2
    return 1
  fi
  if ! echo "$out" | grep -q '\[NEEDS DECISION:'; then
    echo "    expected '[NEEDS DECISION:' marker in output" >&2
    echo "    output: $out" >&2
    return 1
  fi
}

# ─── Phase 3 placeholders ──────────────────────────────────────

test_l3_end_to_end_full_stack_monorepo() {
  if [ "$REQUIRE_EXTERNAL_TOOLS" != "1" ]; then
    echo "    skipped (set --require-external-tools to enable)" >&2; return 0
  fi
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}

# ─── Archive-gated ─────────────────────────────────────────────

test_init_wizard_spec_present_post_archive() {
  if [ -f "$B5_FORGE_YAML" ]; then
    local status
    status=$(python3 - "$B5_FORGE_YAML" <<'PY' 2>/dev/null
import sys, yaml
print((yaml.safe_load(open(sys.argv[1])) or {}).get("status", ""))
PY
)
    if [ "$status" != "archived" ]; then
      echo "    skipped (b5.1 status='$status', not 'archived')" >&2; return 0
    fi
  fi
  if [ ! -f "$SPEC_INIT_WIZARD" ]; then
    echo "    expected spec file: $SPEC_INIT_WIZARD" >&2; return 1
  fi
}

# ─── Main ───────────────────────────────────────────────────────

main() {
  echo "Forge — b5-1-init-wizard Test Harness"
  echo "FORGE_ROOT_REAL=$FORGE_ROOT_REAL"
  echo "REQUIRE_EXTERNAL_TOOLS=$REQUIRE_EXTERNAL_TOOLS"
  echo ""
  echo "── Phase 1 : scaffolding cluster ──"
  run_test test_dispatch_table_shape
  run_test test_dispatch_scaffolders_exist
  run_test test_forge_init_fsm_sh_exists_executable
  run_test test_forge_init_fsm_sh_translates_abi
  run_test test_standard_scaffolding_has_required_sections
  run_test test_index_has_scaffolding_entry
  run_test test_archetypes_decision_matrix_present
  run_test test_features_init_wizard_feature_present
  run_test test_reverse_domain_regex
  run_test test_no_new_third_party_deps
  echo ""
  echo "── Phase 2 : dispatcher + domain + wizard ──"
  run_test test_init_cli_flags_parse
  run_test test_default_dispatcher_idempotent
  run_test test_wizard_skips_when_non_tty
  run_test test_auto_detection_ambiguous_aborts
  echo ""
  echo "── Phase 3 : L3 (opt-in) ──"
  run_test test_l3_end_to_end_full_stack_monorepo
  echo ""
  echo "── Archive-gated ──"
  run_test test_init_wizard_spec_present_post_archive
  echo ""
  echo "── Meta ──"
  run_test test_b5_manifest_self_consistency
  print_summary
}

main "$@"
