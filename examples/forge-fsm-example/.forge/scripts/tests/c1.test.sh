#!/usr/bin/env bash
# Forge — C.1 Reference Project Harness (c1-reference-project)
# <!-- Audit: C.1 (c1-reference-project) -->
#
# Validates :
#  - Skip-guards in verify.sh / constitution-linter.sh for the
#    examples/ tree (FR-GL-026..027).
#  - Forge repo .gitignore covers example build artefacts (FR-GL-028).
#  - Example tree at examples/forge-fsm-example/ has the canonical
#    structure (FR-EX-001..003).
#  - Demo changes shape and lifecycle (FR-EX-004..006).
#  - Forge-ci.yml example job + summary aggregation (FR-CI-012..013,
#    MODIFIED FR-CI-001 + FR-CI-006).
#  - NFR baselines recorded in target standards (FR-EX-008,
#    MODIFIED NFR-013/014/015/017).
#  - Spec consolidation post-archive (FR-EX-010).
#  - NFR-EX-* (byte budget, layer combinations distinct, etc.).
#
# This harness follows the manifest pattern established by
# delivery.test.sh and g1.test.sh : a `# MANIFEST: test_* — FR-XX-NNN`
# comment block declares each test ; a meta-check
# (`test_c1_manifest_self_consistency`) parses the manifest and asserts
# every declared function is defined.
#
# Levels :
#  L1 (default) — hermetic structural / YAML / Markdown checks.
#  L2 (--require-example-tools) — runs the example tree's own gates.
#  L3 (--require-external-tools) — reproducibility check (re-runs the
#       scaffolder against a tmpdir and diffs).
#
# Usage :
#   bash .forge/scripts/tests/c1.test.sh
#   bash .forge/scripts/tests/c1.test.sh --require-example-tools
#   bash .forge/scripts/tests/c1.test.sh --require-external-tools

set -euo pipefail

# ─── CLI flags ──────────────────────────────────────────────────

REQUIRE_EXAMPLE_TOOLS=0
REQUIRE_EXTERNAL_TOOLS=0
for arg in "$@"; do
  case "$arg" in
    --require-example-tools)  REQUIRE_EXAMPLE_TOOLS=1 ;;
    --require-external-tools) REQUIRE_EXTERNAL_TOOLS=1 ;;
    *) echo "unknown flag: $arg" >&2 ; exit 2 ;;
  esac
done

# ─── Paths ──────────────────────────────────────────────────────

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

VERIFY_SH="$SCRIPTS_DIR/verify.sh"
LINTER_SH="$SCRIPTS_DIR/constitution-linter.sh"
GITIGNORE="$FORGE_ROOT_REAL/.gitignore"
EXAMPLE_DIR="$FORGE_ROOT_REAL/examples/forge-fsm-example"
EXAMPLES_README="$FORGE_ROOT_REAL/examples/README.md"
EXAMPLE_README="$EXAMPLE_DIR/README.md"
EXAMPLE_SCAFFOLD_MANIFEST="$EXAMPLE_DIR/.forge/scaffold-manifest.yaml"
EXAMPLE_DEMOS_DIR="$EXAMPLE_DIR/.forge/changes"
EXAMPLE_DEMOS_MANIFEST="$EXAMPLE_DEMOS_DIR/MANIFEST.md"
WORKFLOW_FILE="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"
SPEC_FSM="$FORGE_ROOT_REAL/.forge/specs/full-stack-monorepo.md"
SPEC_EXAMPLE="$FORGE_ROOT_REAL/.forge/specs/example-reference.md"
STD_CI_WORKFLOWS="$FORGE_ROOT_REAL/.forge/standards/infra/ci-workflows.md"
STD_OBS_LOCAL="$FORGE_ROOT_REAL/.forge/standards/infra/observability-local.md"
STD_K8S_OVERLAYS="$FORGE_ROOT_REAL/.forge/standards/infra/k8s-overlays.md"
C1_FORGE_YAML="$FORGE_ROOT_REAL/.forge/changes/c1-reference-project/.forge.yaml"

# ─── Shared helpers ─────────────────────────────────────────────
# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"

# Reset counters in case another harness sourced helpers in same shell.
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest — single source of truth for FR ↔ test mapping ────
#
# Every line of the form `# MANIFEST: test_* — FR-XX-NNN` below is
# parsed by `test_c1_manifest_self_consistency` to assert every
# entry resolves to a defined bash function.
#
# Phase 1 — scaffold cluster
# MANIFEST: test_verify_skip_guard_block_present              — FR-GL-026
# MANIFEST: test_verify_no_skip_when_no_examples_dir          — NFR-EX-006
# MANIFEST: test_constitution_linter_skips_examples_features  — FR-GL-027
# MANIFEST: test_gitignore_covers_example_artefacts           — FR-GL-028
# MANIFEST: test_example_tree_canonical_structure             — FR-EX-001
# MANIFEST: test_example_scaffold_manifest_complete           — FR-EX-001
# MANIFEST: test_example_readme_has_required_sections         — FR-EX-002
# MANIFEST: test_examples_meta_readme_present                 — FR-EX-003
#
# Phase 2 — demos cluster
# MANIFEST: test_archived_demos_count_and_status              — FR-EX-004 + FR-EX-005
# MANIFEST: test_each_archived_demo_has_five_artefacts        — FR-EX-004
# MANIFEST: test_demo_003_is_multi_layer                      — FR-EX-004 + FR-GL-016
# MANIFEST: test_demo_004_is_specified_only                   — FR-EX-005
# MANIFEST: test_demo_004_has_needs_clarification_marker      — FR-EX-005
# MANIFEST: test_demos_manifest_present_and_lists_four_demos  — FR-EX-006
# MANIFEST: test_each_demo_proposal_under_size_budget         — NFR-EX-004
# MANIFEST: test_demos_cover_distinct_layer_combinations      — NFR-EX-005
#
# Phase 3 — CI + docs + baselines cluster
# MANIFEST: test_forge_ci_workflow_shape_six_jobs             — MODIFIED FR-CI-001
# MANIFEST: test_forge_ci_example_job_present                 — FR-CI-012
# MANIFEST: test_forge_ci_example_job_paths_filter            — FR-CI-012
# MANIFEST: test_forge_ci_example_job_steps                   — FR-CI-012
# MANIFEST: test_forge_ci_summary_aggregates_five_needs       — MODIFIED FR-CI-006
# MANIFEST: test_forge_ci_summary_treats_example_skip_as_success — MODIFIED FR-CI-006
# MANIFEST: test_forge_ci_under_size_budget                   — NFR-CI-002 + FR-CI-013
# MANIFEST: test_nfr_013_baseline_recorded                    — FR-EX-008
# MANIFEST: test_nfr_014_baseline_recorded                    — FR-EX-008
# MANIFEST: test_nfr_015_baseline_recorded                    — FR-EX-008
# MANIFEST: test_nfr_017_baseline_recorded                    — FR-EX-008
# MANIFEST: test_example_reference_spec_present_post_archive  — FR-EX-010
# MANIFEST: test_example_tree_byte_budget                     — NFR-EX-002
#
# Meta
# MANIFEST: test_c1_manifest_self_consistency                 — meta (FR-EX-009)
#
# ────────────────────────────────────────────────────────────────

# ─── Meta self-check — manifest ↔ implementation parity ────────

test_c1_manifest_self_consistency() {
  local self="${BASH_SOURCE[0]}"
  local declared
  declared=$(grep -E '^# MANIFEST: (test_[a-z0-9_]+)' "$self" | awk '{print $3}' | sort -u)
  if [ -z "$declared" ]; then
    echo "    no MANIFEST entries found — self-check would always pass" >&2
    return 1
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

# ─── Phase 1 — scaffold cluster tests ──────────────────────────

# FR-GL-026 — verify.sh declares the skip-guard detection block + the
# per-section prefix-check pattern. Static text-grep : the test does not
# require the guard to fire (no current walk hits examples/ from the
# Forge framework repo), only that the guard code is present and
# documented.
test_verify_skip_guard_block_present() {
  if [ ! -f "$VERIFY_SH" ]; then
    echo "    verify.sh missing: $VERIFY_SH" >&2; return 1
  fi
  if ! grep -q 'FORGE_REPO_DETECTED' "$VERIFY_SH"; then
    echo "    skip-guard detection variable FORGE_REPO_DETECTED not found in verify.sh" >&2
    return 1
  fi
  # The detection block must check both signatures :
  # - .forge/specs/full-stack-monorepo.md present (= we are in the
  #   Forge framework repo, since example trees do not have this file
  #   in their own .forge/specs/)
  # - examples/ directory present
  if ! grep -q 'full-stack-monorepo.md' "$VERIFY_SH"; then
    echo "    detection signature on .forge/specs/full-stack-monorepo.md missing" >&2
    return 1
  fi
  if ! grep -qE 'examples/?[^a-z]' "$VERIFY_SH"; then
    echo "    examples/ path reference missing in verify.sh" >&2
    return 1
  fi
}

# NFR-EX-006 — when no examples/ subdir exists, verify.sh emits
# byte-identical output to a baseline (no spurious skip lines).
test_verify_no_skip_when_no_examples_dir() {
  local tmp; tmp=$(mk_tmpdir_with_trap c1-noskip)
  trap "rm -rf '$tmp'" RETURN
  # Build a minimal Forge-signature fixture WITHOUT examples/.
  mkdir -p "$tmp/.forge/specs" "$tmp/.forge/changes" "$tmp/.forge/scripts"
  printf "schema: full-stack-monorepo\n" > "$tmp/.forge.yaml"
  : > "$tmp/.forge/specs/full-stack-monorepo.md"
  # Minimal change for the Change Artifact Completeness section.
  mkdir -p "$tmp/.forge/changes/sample-change"
  printf "name: sample-change\nstatus: proposed\n" > "$tmp/.forge/changes/sample-change/.forge.yaml"
  # Run verify.sh with FORGE_ROOT pointing at the fixture.
  local out
  out=$(FORGE_ROOT="$tmp" bash "$VERIFY_SH" 2>&1 || true)
  if printf '%s' "$out" | grep -q '\[skipped: examples\]'; then
    echo "    verify.sh emitted [skipped: examples] line when no examples/ dir exists" >&2
    return 1
  fi
}

# FR-GL-027 — constitution-linter.sh does NOT count .feature files
# located inside examples/ when invoked from the Forge framework repo.
# The linter's BDD section emits a line like
# "  ✓ <N> .feature files found for <M> files with ACs". We force
# ac_count >= 1 (so the count line is emitted), put one .feature
# outside examples/ and one inside, then assert the count is 1.
test_constitution_linter_skips_examples_features() {
  local tmp; tmp=$(mk_tmpdir_with_trap c1-linterskip)
  trap "rm -rf '$tmp'" RETURN
  mkdir -p "$tmp/.forge/specs" \
           "$tmp/.forge/changes/sample-change" \
           "$tmp/features-outside" \
           "$tmp/examples/forge-fsm-example/features-inside"
  printf "schema: full-stack-monorepo\n" > "$tmp/.forge.yaml"
  : > "$tmp/.forge/specs/full-stack-monorepo.md"
  # Force ac_count >= 1 by putting an AC marker in a change file.
  printf "name: sample-change\nstatus: proposed\n" > "$tmp/.forge/changes/sample-change/.forge.yaml"
  printf "AC-001: sample\n" > "$tmp/.forge/changes/sample-change/specs.md"
  cat > "$tmp/features-outside/outside.feature" <<'F'
Feature: outside
F
  cat > "$tmp/examples/forge-fsm-example/features-inside/inside.feature" <<'F'
Feature: inside
F
  local out
  out=$(FORGE_ROOT="$tmp" bash "$LINTER_SH" 2>&1 || true)
  # Look for the BDD-section count line. With skip-guard, count==1 ;
  # without skip-guard, count==2.
  if printf '%s' "$out" | grep -qE ' 2 \.feature files found'; then
    echo "    linter found 2 .feature files (recursed into examples/) — skip-guard not active" >&2
    return 1
  fi
  if ! printf '%s' "$out" | grep -qE ' 1 \.feature files found'; then
    echo "    linter did not report exactly 1 .feature file (output excerpt below)" >&2
    printf '%s' "$out" | grep -E '\.feature' | head -3 >&2 || true
    return 1
  fi
}

# FR-GL-028 — Forge repo .gitignore covers example build artefacts.
test_gitignore_covers_example_artefacts() {
  if [ ! -f "$GITIGNORE" ]; then
    echo "    .gitignore missing: $GITIGNORE" >&2; return 1
  fi
  local entry
  for entry in 'examples/*/build/' 'examples/*/target/' 'examples/*/.dart_tool/' 'examples/*/node_modules/'; do
    if ! grep -qF "$entry" "$GITIGNORE"; then
      echo "    .gitignore missing entry: $entry" >&2
      return 1
    fi
  done
}

# FR-EX-001 — examples/forge-fsm-example/ has the canonical structure.
test_example_tree_canonical_structure() {
  if [ ! -d "$EXAMPLE_DIR" ]; then
    echo "    example dir missing: $EXAMPLE_DIR" >&2; return 1
  fi
  local subdir
  for subdir in frontend backend infra shared/protos .forge .claude .github/workflows; do
    if [ ! -e "$EXAMPLE_DIR/$subdir" ]; then
      echo "    expected subdir/path missing: $EXAMPLE_DIR/$subdir" >&2
      return 1
    fi
  done
  local file
  for file in CLAUDE.md Taskfile.yml docker-compose.dev.yml .env.example .gitignore .forge.yaml .mcp.json; do
    if [ ! -f "$EXAMPLE_DIR/$file" ]; then
      echo "    expected root file missing: $EXAMPLE_DIR/$file" >&2
      return 1
    fi
  done
  # Schema declared in .forge.yaml.
  if ! grep -q 'schema: full-stack-monorepo' "$EXAMPLE_DIR/.forge.yaml"; then
    echo "    .forge.yaml does not declare schema: full-stack-monorepo" >&2
    return 1
  fi
}

# FR-EX-001 — scaffold-manifest.yaml records the audit trail.
test_example_scaffold_manifest_complete() {
  if [ ! -f "$EXAMPLE_SCAFFOLD_MANIFEST" ]; then
    echo "    scaffold-manifest missing: $EXAMPLE_SCAFFOLD_MANIFEST" >&2
    return 1
  fi
  python3 - "$EXAMPLE_SCAFFOLD_MANIFEST" <<'PY' || return 1
import sys, yaml
with open(sys.argv[1]) as f:
    d = yaml.safe_load(f) or {}
errs = []
top_level = [
    "archetype", "archetype_version", "scaffold_plan_sha",
    "template_set_sha", "scaffold_date", "project_name",
    "reverse_domain", "root_module", "tools",
]
for k in top_level:
    if k not in d:
        errs.append(f"missing top-level key: {k}")
if d.get("archetype") != "full-stack-monorepo":
    errs.append(f"archetype must be 'full-stack-monorepo', got {d.get('archetype')!r}")
if d.get("archetype_version") != "1.0.0":
    errs.append(f"archetype_version must be '1.0.0', got {d.get('archetype_version')!r}")
if d.get("project_name") != "forge-fsm-example":
    errs.append(f"project_name must be 'forge-fsm-example', got {d.get('project_name')!r}")
tools = d.get("tools") or {}
for tool in ("flutter", "cargo", "buf"):
    if tool not in tools or not tools[tool]:
        errs.append(f"tools.{tool} missing or empty in scaffold-manifest")
if errs:
    for e in errs:
        print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-EX-002 — example README has the 4 H2 sections.
test_example_readme_has_required_sections() {
  if [ ! -f "$EXAMPLE_README" ]; then
    echo "    README missing: $EXAMPLE_README" >&2; return 1
  fi
  local section
  for section in '## How this example was built' '## What.s in here' '## Demo changes' '## Reproducing this example'; do
    if ! grep -qE "$section" "$EXAMPLE_README"; then
      echo "    README missing H2 section matching: $section" >&2
      return 1
    fi
  done
}

# FR-EX-003 — examples/README.md exists with required content.
test_examples_meta_readme_present() {
  if [ ! -f "$EXAMPLES_README" ]; then
    echo "    meta README missing: $EXAMPLES_README" >&2; return 1
  fi
  if ! grep -q 'forge-fsm-example' "$EXAMPLES_README"; then
    echo "    meta README does not list forge-fsm-example" >&2
    return 1
  fi
  if ! grep -qiE '(skip|exclude)' "$EXAMPLES_README"; then
    echo "    meta README does not mention skip-guards / examples exclusion" >&2
    return 1
  fi
}

# ─── Phase 2 — demos cluster tests (skeleton) ─────────────────

test_archived_demos_count_and_status() {
  echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1
}
test_each_archived_demo_has_five_artefacts() {
  echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1
}
test_demo_003_is_multi_layer() {
  echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1
}
test_demo_004_is_specified_only() {
  echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1
}
test_demo_004_has_needs_clarification_marker() {
  echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1
}
test_demos_manifest_present_and_lists_four_demos() {
  echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1
}
test_each_demo_proposal_under_size_budget() {
  echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1
}
test_demos_cover_distinct_layer_combinations() {
  echo "    not yet implemented (Phase 2 GREEN)" >&2; return 1
}

# ─── Phase 3 — CI + docs + baselines tests (skeleton) ─────────

test_forge_ci_workflow_shape_six_jobs() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_forge_ci_example_job_present() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_forge_ci_example_job_paths_filter() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_forge_ci_example_job_steps() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_forge_ci_summary_aggregates_five_needs() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_forge_ci_summary_treats_example_skip_as_success() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_forge_ci_under_size_budget() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_nfr_013_baseline_recorded() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_nfr_014_baseline_recorded() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_nfr_015_baseline_recorded() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_nfr_017_baseline_recorded() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}
test_example_reference_spec_present_post_archive() {
  # Archive-gated. Skip when c1's own status is not yet 'archived'.
  if [ -f "$C1_FORGE_YAML" ]; then
    local status
    status=$(python3 - "$C1_FORGE_YAML" <<'PY' 2>/dev/null
import sys, yaml
print((yaml.safe_load(open(sys.argv[1])) or {}).get("status", ""))
PY
)
    if [ "$status" != "archived" ]; then
      echo "    skipped (c1 status='$status', not 'archived')" >&2
      return 0
    fi
  fi
  if [ ! -f "$SPEC_EXAMPLE" ]; then
    echo "    expected spec file: $SPEC_EXAMPLE" >&2; return 1
  fi
}
test_example_tree_byte_budget() {
  echo "    not yet implemented (Phase 3 GREEN)" >&2; return 1
}

# ─── Main ───────────────────────────────────────────────────────

main() {
  echo "Forge — c1-reference-project Test Harness"
  echo "FORGE_ROOT_REAL=$FORGE_ROOT_REAL"
  echo "REQUIRE_EXAMPLE_TOOLS=$REQUIRE_EXAMPLE_TOOLS"
  echo "REQUIRE_EXTERNAL_TOOLS=$REQUIRE_EXTERNAL_TOOLS"
  echo ""
  echo "── Phase 1 : scaffold cluster ──"
  run_test test_verify_skip_guard_block_present
  run_test test_verify_no_skip_when_no_examples_dir
  run_test test_constitution_linter_skips_examples_features
  run_test test_gitignore_covers_example_artefacts
  run_test test_example_tree_canonical_structure
  run_test test_example_scaffold_manifest_complete
  run_test test_example_readme_has_required_sections
  run_test test_examples_meta_readme_present
  echo ""
  echo "── Phase 2 : demos cluster ──"
  run_test test_archived_demos_count_and_status
  run_test test_each_archived_demo_has_five_artefacts
  run_test test_demo_003_is_multi_layer
  run_test test_demo_004_is_specified_only
  run_test test_demo_004_has_needs_clarification_marker
  run_test test_demos_manifest_present_and_lists_four_demos
  run_test test_each_demo_proposal_under_size_budget
  run_test test_demos_cover_distinct_layer_combinations
  echo ""
  echo "── Phase 3 : CI + docs + baselines cluster ──"
  run_test test_forge_ci_workflow_shape_six_jobs
  run_test test_forge_ci_example_job_present
  run_test test_forge_ci_example_job_paths_filter
  run_test test_forge_ci_example_job_steps
  run_test test_forge_ci_summary_aggregates_five_needs
  run_test test_forge_ci_summary_treats_example_skip_as_success
  run_test test_forge_ci_under_size_budget
  run_test test_nfr_013_baseline_recorded
  run_test test_nfr_014_baseline_recorded
  run_test test_nfr_015_baseline_recorded
  run_test test_nfr_017_baseline_recorded
  run_test test_example_reference_spec_present_post_archive
  run_test test_example_tree_byte_budget
  echo ""
  echo "── Meta ──"
  run_test test_c1_manifest_self_consistency
  print_summary
}

main "$@"
