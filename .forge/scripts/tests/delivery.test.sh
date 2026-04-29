#!/usr/bin/env bash
# Forge Delivery Test Harness (b1-delivery)
# <!-- Audit: B.1.9 + B.1.12 + B.1.14 (b1-delivery) -->
#
# Validates the third and final B.1 deliverable family — reference CI
# workflows, Kustomize overlays, and the local OTel + SigNoz
# observability stack — that close the full-stack-monorepo archetype
# contract and drive the schema promotion candidate / 1.0.0-rc.1 →
# stable / 1.0.0.
#
# Three-level test strategy (design ADR-010, mirroring workflow.test.sh) :
#
#   L1 — structural : YAML shape of the four reference workflows,
#                     standards' canonical sections, scaffold-plan
#                     entries, .env.dev OTel defaults. ZERO external
#                     deps beyond `python3 + PyYAML` (already required
#                     by previous harnesses).
#
#   L2 — fixture    : `kustomize build` × 3 overlays (dev/staging/prod)
#                     piped through `kubeconform --strict`,
#                     `docker compose config` shape assertions,
#                     overlay diff size budget (NFR-017),
#                     no-`:latest` enforcement (NFR-018), workflow
#                     file size budget (NFR-016), schema promotion
#                     gate (FR-GL-024 — gated on change status).
#                     Requires `kustomize` + `kubeconform` + Docker
#                     Compose v2 ≥ 2.1.0.
#
#   L3 — long-mode  : `time docker compose up -d --wait` against a
#                     fixture (NFR-015 stack startup ≤ 90s),
#                     `act --dry-run` per workflow (NFR-013 runtime
#                     budget). Opt-in via `--long-tests` or
#                     `LONG_TESTS=1`. Skipped cleanly when tools
#                     absent.
#
# Usage :
#   bash .forge/scripts/tests/delivery.test.sh
#   bash .forge/scripts/tests/delivery.test.sh --level 1
#   bash .forge/scripts/tests/delivery.test.sh --long-tests
#
# RED baseline note (Phase 1.1) : on first creation the harness ships
# with zero implemented tests beyond `test_manifest_self_consistency`
# and a deliberate `test_phase_1_red_baseline` placeholder that always
# fails. This is the b1-delivery RED of RED — until the manifest is
# wired and at least one phase-2 test is implemented, the harness MUST
# exit non-zero. Each subsequent task in tasks.md flips one
# manifest-listed test from missing to PASS.

set -euo pipefail

# ─── Paths ──────────────────────────────────────────────────────

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

# Archetype overlay tree (where every .tmpl produced by this change lives)
ARCHETYPE_DIR="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo"
WORKFLOWS_DIR="$ARCHETYPE_DIR/.github/workflows"
INFRA_DIR="$ARCHETYPE_DIR/infra"
K8S_DIR="$INFRA_DIR/k8s"
OBS_DIR="$INFRA_DIR/observability"
COMPOSE_TMPL="$ARCHETYPE_DIR/docker-compose.dev.yml.tmpl"
TASKFILE_TMPL="$ARCHETYPE_DIR/Taskfile.yml.tmpl"
SCAFFOLD_PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"

# Standards
STD_CI="$FORGE_ROOT_REAL/.forge/standards/infra/ci-workflows.md"
STD_K8S="$FORGE_ROOT_REAL/.forge/standards/infra/k8s-overlays.md"
STD_OBS="$FORGE_ROOT_REAL/.forge/standards/infra/observability-local.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"

# Schema (mutated at archive — FR-GL-024)
SCHEMA_YAML="$FORGE_ROOT_REAL/.forge/schemas/full-stack-monorepo/schema.yaml"

# Change metadata (source of truth for the gated promotion test)
CHANGE_YAML="$FORGE_ROOT_REAL/.forge/changes/b1-delivery/.forge.yaml"

# Forge gates that the workflows invoke
VERIFY_SH="$SCRIPTS_DIR/verify.sh"
LINTER_SH="$SCRIPTS_DIR/constitution-linter.sh"

# ─── Shared helpers ─────────────────────────────────────────────
# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"

# ─── Flags ──────────────────────────────────────────────────────

LEVEL=""
LONG_TESTS="${LONG_TESTS:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --level)        LEVEL="${2:-}"; shift 2 ;;
    --level=*)      LEVEL="${1#*=}"; shift ;;
    --long-tests)   LONG_TESTS=1; shift ;;
    --help|-h)
      sed -n '2,38p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "delivery.test.sh: unknown flag '$1'" >&2
      exit 2
      ;;
  esac
done

have_kustomize() { command -v kustomize >/dev/null 2>&1; }
have_kubeconform() { command -v kubeconform >/dev/null 2>&1; }
have_compose() { command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; }
have_act() { command -v act >/dev/null 2>&1; }
have_l2_tools() { have_kustomize && have_kubeconform && have_compose; }

decide_levels() {
  if [ -n "$LEVEL" ]; then
    echo "$LEVEL"; return
  fi
  if [ -n "$LONG_TESTS" ]; then
    echo "1,2,3"
  elif have_l2_tools; then
    echo "1,2"
  else
    echo "1"
  fi
}

# ─── Manifest — single source of truth for FR ↔ test mapping ────
#
# Every line of the form `# MANIFEST: test_* — FR-XXX[, FR-YYY]`
# below is parsed by `test_manifest_self_consistency` to assert
# (a) that every FR/NFR listed Testable in specs.md has at least one
# entry here, and (b) that every entry resolves to a defined bash
# function. The manifest is the harness's contract with the spec.
#
# MANIFEST: test_phase_1_red_baseline                         — bootstrap
# MANIFEST: test_workflow_backend_paths_filter_and_steps      — FR-IN-002
# MANIFEST: test_workflow_frontend_paths_filter_and_steps     — FR-IN-003
# MANIFEST: test_workflow_infra_paths_filter_and_steps        — FR-IN-004
# MANIFEST: test_workflow_integration_triggers_and_lifecycle  — FR-IN-005
# MANIFEST: test_kustomize_base_renders                       — FR-IN-006
# MANIFEST: test_overlay_dev_renders_and_validates            — FR-IN-006
# MANIFEST: test_overlay_staging_renders_and_validates        — FR-IN-006
# MANIFEST: test_overlay_prod_renders_and_validates           — FR-IN-006
# MANIFEST: test_overlay_diff_size_under_4kb                  — NFR-017
# MANIFEST: test_compose_otel_service_shape                   — FR-IN-007
# MANIFEST: test_compose_signoz_services_shape                — FR-IN-008
# MANIFEST: test_taskfile_has_observe_target                  — FR-IN-008
# MANIFEST: test_env_dev_files_export_otel_defaults           — FR-IN-009
# MANIFEST: test_standard_ci_workflows_has_required_sections  — FR-IN-010
# MANIFEST: test_standard_k8s_overlays_has_required_sections  — FR-IN-011
# MANIFEST: test_standard_observability_local_has_required_sections — FR-IN-012
# MANIFEST: test_index_has_three_new_infra_standards          — FR-IN-010, FR-IN-011, FR-IN-012
# MANIFEST: test_scaffold_plan_lists_all_new_templates        — FR-IN-002..009
# MANIFEST: test_scaffold_fixture_renders_and_validates       — FR-IN-002..009
# MANIFEST: test_schema_header_post_archive                   — FR-GL-024
# MANIFEST: test_no_latest_tag_anywhere                       — NFR-018
# MANIFEST: test_workflow_files_under_size_budget             — NFR-016
# MANIFEST: test_no_secrets_in_templates                      — Aegis security
# MANIFEST: test_compose_stack_startup_under_90s              — NFR-015 (LONG_TESTS)
# MANIFEST: test_per_layer_workflow_runtime_warm_under_8min   — NFR-013 (LONG_TESTS)
# MANIFEST: test_manifest_self_consistency                    — meta (FR-GL-025)
#
# ────────────────────────────────────────────────────────────────

# ─── Tests ──────────────────────────────────────────────────────

test_phase_1_red_baseline() {
  # Deliberate RED placeholder. Removed in Phase 2 task 2.1 GREEN
  # (when the first real test_workflow_* lands and the harness has
  # something genuine to assert). Until then this fail confirms the
  # skeleton wires up `_helpers.sh` correctly.
  echo "    Phase 1 RED baseline — replaced by Phase 2.1 implementation" >&2
  return 1
}

test_manifest_self_consistency() {
  # Meta-test : every `# MANIFEST: test_*` line declares a bash
  # function that exists in this file. Catches typos and orphaned
  # manifest entries.
  local missing=()
  while IFS= read -r fn; do
    if ! declare -F "$fn" >/dev/null 2>&1; then
      missing+=("$fn")
    fi
  done < <(grep -oE '^# MANIFEST: test_[a-z0-9_]+' "${BASH_SOURCE[0]}" | awk '{print $3}')
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    manifest declares functions not defined: ${missing[*]}" >&2
    return 1
  fi
}

# ─── Main dispatcher ────────────────────────────────────────────

main() {
  echo "── Forge Delivery Test Harness ──"
  echo "  ARCHETYPE_DIR=$ARCHETYPE_DIR"
  local levels; levels="$(decide_levels)"
  echo "  LEVELS=$levels"
  echo ""

  if [[ "$levels" == *"1"* ]]; then
    echo "── L1 : structural invariants ──"
    run_test test_phase_1_red_baseline
    run_test test_manifest_self_consistency
  fi

  if [[ "$levels" == *"2"* ]]; then
    if ! have_l2_tools; then
      echo ""
      echo "── L2 : fixture-based — SKIPPED (kustomize/kubeconform/docker compose missing) ──"
    else
      echo ""
      echo "── L2 : fixture-based ──"
      # Filled in Phase 2-7 GREEN.
      :
    fi
  fi

  if [[ "$levels" == *"3"* ]]; then
    if [ -z "$LONG_TESTS" ]; then
      echo ""
      echo "── L3 : long-mode — SKIPPED (LONG_TESTS unset) ──"
    else
      echo ""
      echo "── L3 : long-mode ──"
      # Filled in Phase 8.1 GREEN.
      :
    fi
  fi

  print_summary
}

main "$@"
