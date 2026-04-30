#!/usr/bin/env bash
# Forge Workflow Test Harness (b1-workflow)
# <!-- Audit: B.1.6 + B.1.7 + B.1.8 (b1-workflow) -->
#
# Three-level test strategy (design ADR-008) mirroring
# scaffolder.test.sh :
#
#   L1 — structural : Janus agent sections, multi-layer-workflow
#                     standard sections, index entry, per-layer
#                     templates. ZERO external tool deps.
#   L2 — fixture    : multi-layer metadata validation (4 scenarios),
#                     NFR-010 backwards-compat regression. ZERO
#                     external deps.
#   L3 — end-to-end : scaffold a project (re-uses scaffolder init.sh),
#                     run multi-root verify.sh, assert `[<layer>] ...`
#                     prefixed output. Requires flutter + cargo + buf.
#                     Opt-in.
#
# Usage :
#   bash .forge/scripts/tests/workflow.test.sh
#   bash .forge/scripts/tests/workflow.test.sh --level 1
#   bash .forge/scripts/tests/workflow.test.sh --require-external-tools

set -euo pipefail

# ─── Paths ──────────────────────────────────────────────────────

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"
JANUS_AGENT="$FORGE_ROOT_REAL/.claude/agents/cross-layer-orchestrator.md"
STANDARD_ML="$FORGE_ROOT_REAL/.forge/standards/global/multi-layer-workflow.md"
DESIGN_PER_LAYER_TMPL="$FORGE_ROOT_REAL/.forge/templates/design-per-layer.md"
TASKS_PER_LAYER_TMPL="$FORGE_ROOT_REAL/.forge/templates/tasks-per-layer.md"
CHANGE_YAML_TMPL="$FORGE_ROOT_REAL/.forge/templates/change.yaml"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
VALIDATOR="$SCRIPTS_DIR/validate-foundations.sh"
VERIFY_SH="$SCRIPTS_DIR/verify.sh"
LINTER_SH="$SCRIPTS_DIR/constitution-linter.sh"
INIT_SH="$SCRIPTS_DIR/scaffolder/init.sh"

# ─── Shared helpers ─────────────────────────────────────────────
# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"

# ─── Flags ──────────────────────────────────────────────────────

LEVEL=""
REQUIRE_TOOLS=false

while [ $# -gt 0 ]; do
  case "$1" in
    --level)      LEVEL="${2:-}"; shift 2 ;;
    --level=*)    LEVEL="${1#*=}"; shift ;;
    --require-external-tools) REQUIRE_TOOLS=true; shift ;;
    --help|-h)
      sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "workflow.test.sh: unknown flag '$1'" >&2
      exit 2
      ;;
  esac
done

have_external_tools() {
  command -v flutter >/dev/null 2>&1 \
    && command -v cargo >/dev/null 2>&1 \
    && command -v buf >/dev/null 2>&1
}

decide_levels() {
  if [ -n "$LEVEL" ]; then
    echo "$LEVEL"; return
  fi
  if [ "$REQUIRE_TOOLS" = "true" ] || have_external_tools; then
    echo "1,2,3"
  else
    echo "1,2"
  fi
}

# ─── L1 tests : structural invariants (no external deps) ───────

test_janus_agent_file_has_required_sections() {
  [ -f "$JANUS_AGENT" ] || { echo "    cross-layer-orchestrator.md missing" >&2; return 1; }
  local missing=()
  for h in '## Persona' '## Dispatch Table' '## 12-Step Workflow' '## Quality Gates' '## Routing Rules'; do
    grep -qFx "$h" "$JANUS_AGENT" || missing+=("$h")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "    missing headings: ${missing[*]}" >&2
    return 1
  fi
  # Invariant check (ADR-001).
  grep -q 'NEVER writes' "$JANUS_AGENT" || {
    echo "    'NEVER writes' invariant missing from Persona" >&2; return 1;
  }
  # Step 8 must delegate to Hermes-API (ADR-003).
  grep -q 'Hermes-API' "$JANUS_AGENT" || {
    echo "    Hermes-API delegation missing" >&2; return 1;
  }
}

test_standard_multi_layer_workflow_sections() {
  [ -f "$STANDARD_ML" ] || { echo "    standard file missing" >&2; return 1; }
  local missing=()
  for h in \
    '## Routing Policy' \
    '## .forge.yaml Multi-Layer Schema' \
    '## Per-Layer Design Convention' \
    '## Per-Layer Tasks Convention' \
    '## Cross-Layer Contract Alignment' \
    '## Interdictions'
  do
    grep -qFx "$h" "$STANDARD_ML" || missing+=("$h")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "    missing headings: ${missing[*]}" >&2
    return 1
  fi
}

test_design_per_layer_template_sections() {
  [ -f "$DESIGN_PER_LAYER_TMPL" ] || { echo "    design-per-layer.md missing" >&2; return 1; }
  # FR-GL-020: first content section MUST be Cross-Layer References.
  grep -qFx '## Cross-Layer References' "$DESIGN_PER_LAYER_TMPL" || {
    echo "    '## Cross-Layer References' missing" >&2; return 1;
  }
  # <!-- Layer: ... --> header required.
  head -3 "$DESIGN_PER_LAYER_TMPL" | grep -q '<!-- Layer:' || {
    echo "    '<!-- Layer: ... -->' header missing" >&2; return 1;
  }
}

test_tasks_per_layer_template_phase_prefix() {
  [ -f "$TASKS_PER_LAYER_TMPL" ] || { echo "    tasks-per-layer.md missing" >&2; return 1; }
  # ADR-010: phase heading uses `<Layer> Phase N` convention.
  grep -qE '^## <Layer> Phase [0-9]+' "$TASKS_PER_LAYER_TMPL" || {
    echo "    '<Layer> Phase N' heading pattern missing" >&2; return 1;
  }
  grep -qFx '## Cross-Layer References' "$TASKS_PER_LAYER_TMPL" || {
    echo "    '## Cross-Layer References' missing" >&2; return 1;
  }
}

test_change_yaml_template_has_optional_layers_fields() {
  [ -f "$CHANGE_YAML_TMPL" ] || { echo "    change.yaml template missing" >&2; return 1; }
  # Each of the 3 optional fields must be documented in the comment block.
  for kw in 'layers:' 'designs_per_layer:' 'tasks_per_layer:'; do
    grep -q "$kw" "$CHANGE_YAML_TMPL" || {
      echo "    '$kw' documentation missing" >&2; return 1;
    }
  done
  # Activation rule mentions the threshold.
  grep -qE '>= 2|≥ 2|two or more' "$CHANGE_YAML_TMPL" || {
    echo "    '>= 2 layers' activation rule missing" >&2; return 1;
  }
}

# ─── L2 tests : fixture-based validator (no external deps) ──────

# Helper to build a fixture FORGE_ROOT containing just enough for
# validate-foundations.sh to locate the archetype schema + one or
# more fixture changes. Returns the root path.
mk_workflow_fixture() {
  local root; root=$(mk_tmpdir_with_trap forge-workflow)
  # Minimal Forge tree that satisfies foundations checks
  mkdir -p "$root/.forge/standards/global" \
           "$root/.forge/standards/infra" \
           "$root/.forge/schemas/full-stack-monorepo" \
           "$root/.forge/changes" \
           "$root/.forge/scripts" \
           "$root/docs"
  # Copy the real archetype schema so the enum for layer ids resolves.
  cp "$FORGE_ROOT_REAL/.forge/schemas/full-stack-monorepo/schema.yaml" \
     "$root/.forge/schemas/full-stack-monorepo/schema.yaml"
  # Copy index.yml + standards referenced by foundations checks.
  cp "$FORGE_ROOT_REAL/.forge/standards/index.yml" \
     "$root/.forge/standards/index.yml"
  cp "$FORGE_ROOT_REAL/.forge/standards/global/monorepo-layout.md" \
     "$root/.forge/standards/global/monorepo-layout.md"
  cp "$FORGE_ROOT_REAL/.forge/standards/global/proto-contracts.md" \
     "$root/.forge/standards/global/proto-contracts.md"
  cp "$FORGE_ROOT_REAL/.forge/standards/infra/docker-compose.md" \
     "$root/.forge/standards/infra/docker-compose.md"
  cp "$FORGE_ROOT_REAL/.forge/standards/global/git-workflow.md" \
     "$root/.forge/standards/global/git-workflow.md"
  cp "$FORGE_ROOT_REAL/.forge/standards/global/multi-layer-workflow.md" \
     "$root/.forge/standards/global/multi-layer-workflow.md"
  cp "$FORGE_ROOT_REAL/docs/VERSIONING.md" "$root/docs/VERSIONING.md"
  # Root .forge.yaml declaring the monorepo schema (so multi-layer
  # validation activates).
  printf 'schema: full-stack-monorepo\n' > "$root/.forge.yaml"
  echo "$root"
}

# Write a fixture change directory with the provided .forge.yaml body.
# Returns nothing; caller knows the path is $root/.forge/changes/<name>.
add_fixture_change() {
  local root="$1" name="$2" yaml="$3"
  mkdir -p "$root/.forge/changes/$name"
  printf '%s\n' "$yaml" > "$root/.forge/changes/$name/.forge.yaml"
  # Every non-empty-stub change needs proposal.md / specs.md for the
  # existing change-artifact completeness check (status: specified).
  touch "$root/.forge/changes/$name/proposal.md"
  touch "$root/.forge/changes/$name/specs.md"
}

test_multi_layer_metadata_valid_single_layer() {
  local root; root=$(mk_workflow_fixture)
  trap "rm -rf '$root'" RETURN
  add_fixture_change "$root" valid-single "$(cat <<'Y'
name: valid-single
status: specified
created: 2026-04-22
schema: default
constitution_version: "1.0.0"
layers:
  - backend
timeline:
  proposed: 2026-04-22
  specified: 2026-04-22
Y
)"
  local out; out=$(FORGE_ROOT="$root" bash "$VALIDATOR" 2>&1 || true)
  assert_contains "$out" "PASS: FR-GL-017" "single-layer change must PASS"
}

test_multi_layer_metadata_valid_multi_complete() {
  local root; root=$(mk_workflow_fixture)
  trap "rm -rf '$root'" RETURN
  add_fixture_change "$root" valid-multi "$(cat <<'Y'
name: valid-multi
status: specified
created: 2026-04-22
schema: default
constitution_version: "1.0.0"
layers:
  - backend
  - frontend
designs_per_layer:
  backend: design-backend.md
  frontend: design-frontend.md
tasks_per_layer:
  backend: tasks-backend.md
  frontend: tasks-frontend.md
timeline:
  proposed: 2026-04-22
  specified: 2026-04-22
Y
)"
  # Create the referenced per-layer files (even as stubs).
  for f in design-backend.md design-frontend.md tasks-backend.md tasks-frontend.md; do
    touch "$root/.forge/changes/valid-multi/$f"
  done
  local out; out=$(FORGE_ROOT="$root" bash "$VALIDATOR" 2>&1 || true)
  assert_contains "$out" "PASS: FR-GL-017" "multi-layer complete must PASS"
}

test_multi_layer_metadata_missing_per_layer_fails() {
  local root; root=$(mk_workflow_fixture)
  trap "rm -rf '$root'" RETURN
  add_fixture_change "$root" missing-per-layer "$(cat <<'Y'
name: missing-per-layer
status: specified
created: 2026-04-22
schema: default
constitution_version: "1.0.0"
layers:
  - backend
  - frontend
timeline:
  proposed: 2026-04-22
  specified: 2026-04-22
Y
)"
  local out; out=$(FORGE_ROOT="$root" bash "$VALIDATOR" 2>&1 || true)
  assert_contains "$out" "FAIL: FR-GL-017" "missing designs_per_layer must FAIL"
  assert_contains "$out" "designs_per_layer" "failure message cites designs_per_layer"
}

test_multi_layer_metadata_unknown_layer_fails() {
  local root; root=$(mk_workflow_fixture)
  trap "rm -rf '$root'" RETURN
  add_fixture_change "$root" unknown-layer "$(cat <<'Y'
name: unknown-layer
status: specified
created: 2026-04-22
schema: default
constitution_version: "1.0.0"
layers:
  - backend
  - unicorn
designs_per_layer:
  backend: design-backend.md
  unicorn: design-unicorn.md
tasks_per_layer:
  backend: tasks-backend.md
  unicorn: tasks-unicorn.md
timeline:
  proposed: 2026-04-22
  specified: 2026-04-22
Y
)"
  for f in design-backend.md design-unicorn.md tasks-backend.md tasks-unicorn.md; do
    touch "$root/.forge/changes/unknown-layer/$f"
  done
  local out; out=$(FORGE_ROOT="$root" bash "$VALIDATOR" 2>&1 || true)
  assert_contains "$out" "FAIL: FR-GL-017" "unknown layer must FAIL"
  assert_contains "$out" "unicorn" "failure message cites unknown layer id"
}

test_multi_layer_standard_section_check_passes_on_real_repo() {
  # On the real Forge repo, the standard exists and has all sections.
  local out; out=$(bash "$VALIDATOR" 2>&1 || true)
  assert_contains "$out" "PASS: FR-GL-018" "multi-layer-workflow standard OK"
}

test_index_has_multi_layer_workflow_entry() {
  # This test expects the index entry to be present (Phase 3.3 GREEN).
  local result
  result=$(python3 - "$INDEX_YML" <<'PY'
import sys, yaml
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)
found = None
for e in data.get('standards', []):
    if isinstance(e, dict) and e.get('id') == 'global/multi-layer-workflow':
        found = e; break
if not found:
    print('KO: entry absent'); sys.exit(0)
if found.get('scope') != 'monorepo':
    print(f"KO: scope {found.get('scope')!r}, expected 'monorepo'"); sys.exit(0)
if found.get('priority') != 'high':
    print(f"KO: priority {found.get('priority')!r}, expected 'high'"); sys.exit(0)
triggers = found.get('triggers') or []
for t in ('multi-layer', 'janus', 'cross-layer'):
    if t not in triggers:
        print(f"KO: trigger '{t}' missing"); sys.exit(0)
print('OK')
PY
)
  assert_eq "OK" "$result" "multi-layer-workflow index entry"
}

# ─── L3 tests : multi-root end-to-end (requires flutter+cargo+buf) ──

# Helper to scaffold a demo project via init.sh. Echoes the target path.
# Caller owns the trap cleanup.
scaffold_demo() {
  local parent; parent=$(mk_tmpdir_with_trap forge-workflow-e2e)
  local tgt="$parent/demo-app"
  bash "$INIT_SH" demo-app --org com.example.workflow --target-dir "$tgt" >/dev/null 2>&1 || {
    echo "SCAFFOLD_FAILED:$parent"; return 1;
  }
  echo "$parent"
}

test_verify_backend_scoped_emits_prefixed_lines() {
  local parent; parent=$(scaffold_demo) || return 1
  trap "rm -rf '$parent'" RETURN
  local tgt="$parent/demo-app"
  local out; out=$(FORGE_ROOT="$tgt" bash "$VERIFY_SH" 2>&1 || true)
  assert_contains "$out" "── Backend (scoped) ──"          "section header" || return 1
  assert_contains "$out" "[backend]"                        "[backend] prefix" || return 1
}

test_verify_frontend_scoped_emits_prefixed_lines() {
  local parent; parent=$(scaffold_demo) || return 1
  trap "rm -rf '$parent'" RETURN
  local tgt="$parent/demo-app"
  local out; out=$(FORGE_ROOT="$tgt" bash "$VERIFY_SH" 2>&1 || true)
  assert_contains "$out" "── Frontend (scoped) ──" "section header" || return 1
  assert_contains "$out" "[frontend]"              "[frontend] prefix" || return 1
}

test_verify_protos_scoped_buf_lint() {
  local parent; parent=$(scaffold_demo) || return 1
  trap "rm -rf '$parent'" RETURN
  local tgt="$parent/demo-app"
  local out; out=$(FORGE_ROOT="$tgt" bash "$VERIFY_SH" 2>&1 || true)
  assert_contains "$out" "── Protos (scoped) ──" "protos section header" || return 1
  assert_contains "$out" "[protos] buf lint"     "[protos] buf lint line" || return 1
}

test_verify_infra_scoped_compose_syntax() {
  local parent; parent=$(scaffold_demo) || return 1
  trap "rm -rf '$parent'" RETURN
  local tgt="$parent/demo-app"
  local out; out=$(FORGE_ROOT="$tgt" bash "$VERIFY_SH" 2>&1 || true)
  assert_contains "$out" "── Infra (scoped) ──" "infra section header" || return 1
  assert_contains "$out" "[infra]"              "[infra] prefix" || return 1
}

test_verify_non_monorepo_no_scoped_output() {
  # NFR-010 : on a non-monorepo target (schema != full-stack-monorepo),
  # verify.sh MUST NOT emit any scoped section or [<layer>] line.
  local tmp; tmp=$(mk_tmpdir_with_trap forge-nonmono)
  trap "rm -rf '$tmp'" RETURN
  mkdir -p "$tmp/.forge/standards" "$tmp/.forge/changes"
  printf 'schema: default\n' > "$tmp/.forge.yaml"
  cp "$FORGE_ROOT_REAL/.forge/standards/index.yml" "$tmp/.forge/standards/index.yml"
  cp "$FORGE_ROOT_REAL/.forge/constitution.md"     "$tmp/.forge/constitution.md"
  local out; out=$(FORGE_ROOT="$tmp" bash "$VERIFY_SH" 2>&1 || true)
  assert_not_contains "$out" "── Backend (scoped) ──"  "no scoped Backend section" || return 1
  assert_not_contains "$out" "── Frontend (scoped) ──" "no scoped Frontend section" || return 1
  assert_not_contains "$out" "── Protos (scoped) ──"   "no scoped Protos section" || return 1
  assert_not_contains "$out" "── Infra (scoped) ──"    "no scoped Infra section" || return 1
  assert_not_contains "$out" "[backend]"               "no [backend] prefix" || return 1
  assert_not_contains "$out" "[frontend]"              "no [frontend] prefix" || return 1
}

# ─── Main dispatcher ────────────────────────────────────────────

main() {
  echo "── Forge Workflow Test Harness ──"
  echo "  JANUS_AGENT=$JANUS_AGENT"
  echo "  STANDARD_ML=$STANDARD_ML"
  local levels; levels="$(decide_levels)"
  echo "  LEVELS=$levels"
  echo ""

  if [[ "$levels" == *"1"* ]]; then
    echo "── L1 : structural invariants ──"
    run_test test_janus_agent_file_has_required_sections
    run_test test_standard_multi_layer_workflow_sections
    run_test test_design_per_layer_template_sections
    run_test test_tasks_per_layer_template_phase_prefix
    run_test test_change_yaml_template_has_optional_layers_fields
  fi

  if [[ "$levels" == *"2"* ]]; then
    echo ""
    echo "── L2 : fixture-based validator ──"
    run_test test_multi_layer_metadata_valid_single_layer
    run_test test_multi_layer_metadata_valid_multi_complete
    run_test test_multi_layer_metadata_missing_per_layer_fails
    run_test test_multi_layer_metadata_unknown_layer_fails
    run_test test_multi_layer_standard_section_check_passes_on_real_repo
    run_test test_index_has_multi_layer_workflow_entry
  fi

  if [[ "$levels" == *"3"* ]]; then
    if ! have_external_tools && [ "$REQUIRE_TOOLS" != "true" ]; then
      echo ""
      echo "── L3 : multi-root E2E — SKIPPED (flutter / cargo / buf not all on PATH) ──"
    else
      echo ""
      echo "── L3 : multi-root E2E ──"
      run_test test_verify_backend_scoped_emits_prefixed_lines
      run_test test_verify_frontend_scoped_emits_prefixed_lines
      run_test test_verify_protos_scoped_buf_lint
      run_test test_verify_infra_scoped_compose_syntax
      run_test test_verify_non_monorepo_no_scoped_output
    fi
  fi

  print_summary
}

main "$@"
