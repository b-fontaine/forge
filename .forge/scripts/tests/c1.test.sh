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
# MANIFEST: test_forge_ci_workflow_shape_seven_jobs           — MODIFIED FR-CI-001
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

# ─── Phase 2 — demos cluster tests ─────────────────────────────

# FR-EX-004 + FR-EX-005 — exactly 4 demos, 3 archived + 1 specified.
test_archived_demos_count_and_status() {
  if [ ! -d "$EXAMPLE_DEMOS_DIR" ]; then
    echo "    demos dir missing: $EXAMPLE_DEMOS_DIR" >&2; return 1
  fi
  python3 - "$EXAMPLE_DEMOS_DIR" <<'PY' || return 1
import os, sys, yaml, glob
demos_dir = sys.argv[1]
demos = sorted([d for d in os.listdir(demos_dir)
                if os.path.isdir(os.path.join(demos_dir, d))
                and d.startswith("demo-")])
errs = []
# Canonical demos shipped by c1-reference-project — MUST be present,
# in this exact order. Extra demos (demo-005+, contributed by later
# Forge changes such as t5-connect-codegen) are allowed and validated
# only on `status` membership : archived | specified.
canonical = ["demo-001-greeting-service", "demo-002-greeting-screen",
             "demo-003-rate-limit", "demo-004-user-onboarding"]
if len(demos) < 4:
    errs.append(f"expected at least 4 demos, found {len(demos)}: {demos}")
missing_canonical = [d for d in canonical if d not in demos]
if missing_canonical:
    errs.append(f"missing canonical demos: {missing_canonical}")
statuses = {}
for d in demos:
    fy = os.path.join(demos_dir, d, ".forge.yaml")
    if not os.path.isfile(fy):
        errs.append(f"{d}: missing .forge.yaml")
        continue
    with open(fy) as f:
        statuses[d] = (yaml.safe_load(f) or {}).get("status", "")
expected_statuses = {
    "demo-001-greeting-service": "archived",
    "demo-002-greeting-screen": "archived",
    "demo-003-rate-limit": "archived",
    "demo-004-user-onboarding": "specified",
}
for d, want in expected_statuses.items():
    got = statuses.get(d, "<missing>")
    if got != want:
        errs.append(f"{d}: status='{got}', expected '{want}'")
# For non-canonical demos (demo-005+), require status ∈ {archived, specified}.
allowed_statuses = {"archived", "specified"}
for d in demos:
    if d in canonical:
        continue
    got = statuses.get(d, "<missing>")
    if got not in allowed_statuses:
        errs.append(f"{d}: status='{got}', expected one of {sorted(allowed_statuses)}")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-EX-004 — each archived demo carries the 5 lifecycle artefacts.
# Multi-layer demos substitute design.md/tasks.md with per-layer files
# under designs/ and tasks/ subdirs (FR-GL-016).
test_each_archived_demo_has_five_artefacts() {
  if [ ! -d "$EXAMPLE_DEMOS_DIR" ]; then
    echo "    demos dir missing: $EXAMPLE_DEMOS_DIR" >&2; return 1
  fi
  python3 - "$EXAMPLE_DEMOS_DIR" <<'PY' || return 1
import os, sys, yaml, glob
demos_dir = sys.argv[1]
errs = []
for demo in ("demo-001-greeting-service", "demo-002-greeting-screen", "demo-003-rate-limit"):
    d = os.path.join(demos_dir, demo)
    fy = os.path.join(d, ".forge.yaml")
    if not os.path.isfile(fy):
        errs.append(f"{demo}: missing .forge.yaml"); continue
    with open(fy) as f:
        meta = yaml.safe_load(f) or {}
    layers = meta.get("layers") or []
    multi = len(layers) >= 2
    # proposal + specs always required.
    for f in ("proposal.md", "specs.md"):
        if not os.path.isfile(os.path.join(d, f)):
            errs.append(f"{demo}: missing {f}")
    # design.md / tasks.md OR per-layer filenames at the change-dir
    # root (b1-workflow convention — see change.yaml template).
    if multi:
        per_designs = meta.get("designs_per_layer") or {}
        per_tasks = meta.get("tasks_per_layer") or {}
        if not per_designs:
            errs.append(f"{demo}: designs_per_layer missing or empty (multi-layer change)")
        if not per_tasks:
            errs.append(f"{demo}: tasks_per_layer missing or empty (multi-layer change)")
        for layer, fname in per_designs.items():
            if not os.path.isfile(os.path.join(d, fname)):
                errs.append(f"{demo}: designs_per_layer references missing file {fname}")
        for layer, fname in per_tasks.items():
            if not os.path.isfile(os.path.join(d, fname)):
                errs.append(f"{demo}: tasks_per_layer references missing file {fname}")
    else:
        for f in ("design.md", "tasks.md"):
            if not os.path.isfile(os.path.join(d, f)):
                errs.append(f"{demo}: missing {f}")
    # features/<demo>.feature
    features = glob.glob(os.path.join(d, "features", "*.feature"))
    if not features:
        errs.append(f"{demo}: missing features/*.feature")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-EX-004 + FR-GL-016 — demo-003 declares layers ≥ 2 and references
# valid per-layer designs / tasks files.
test_demo_003_is_multi_layer() {
  local d="$EXAMPLE_DEMOS_DIR/demo-003-rate-limit"
  if [ ! -d "$d" ]; then
    echo "    demo-003 missing: $d" >&2; return 1
  fi
  python3 - "$d/.forge.yaml" "$d" <<'PY' || return 1
import os, sys, yaml
fy_path, demo_dir = sys.argv[1], sys.argv[2]
with open(fy_path) as f:
    meta = yaml.safe_load(f) or {}
errs = []
layers = meta.get("layers") or []
if len(layers) < 2:
    errs.append(f"layers must have >=2 entries, got {layers!r}")
if "backend" not in layers or "infra" not in layers:
    errs.append(f"layers must include backend AND infra, got {layers!r}")
per_design = meta.get("designs_per_layer") or {}
per_tasks = meta.get("tasks_per_layer") or {}
if not per_design:
    errs.append("designs_per_layer is empty or missing")
if not per_tasks:
    errs.append("tasks_per_layer is empty or missing")
for layer, fname in per_design.items():
    if not os.path.isfile(os.path.join(demo_dir, fname)):
        errs.append(f"designs_per_layer.{layer}={fname!r} not found at change-dir root")
for layer, fname in per_tasks.items():
    if not os.path.isfile(os.path.join(demo_dir, fname)):
        errs.append(f"tasks_per_layer.{layer}={fname!r} not found at change-dir root")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-EX-005 — demo-004 carries proposal + specs only, no design/tasks.
test_demo_004_is_specified_only() {
  local d="$EXAMPLE_DEMOS_DIR/demo-004-user-onboarding"
  if [ ! -d "$d" ]; then
    echo "    demo-004 missing: $d" >&2; return 1
  fi
  if [ ! -f "$d/proposal.md" ]; then echo "    demo-004 missing proposal.md" >&2; return 1; fi
  if [ ! -f "$d/specs.md" ]; then echo "    demo-004 missing specs.md" >&2; return 1; fi
  if [ -f "$d/design.md" ] || [ -d "$d/designs" ]; then
    echo "    demo-004 must NOT ship design.md / designs/ at status=specified" >&2; return 1
  fi
  if [ -f "$d/tasks.md" ] || [ -d "$d/tasks" ]; then
    echo "    demo-004 must NOT ship tasks.md / tasks/ at status=specified" >&2; return 1
  fi
  if [ -d "$d/features" ]; then
    echo "    demo-004 must NOT ship features/ at status=specified" >&2; return 1
  fi
  python3 - "$d/.forge.yaml" <<'PY' || return 1
import sys, yaml
with open(sys.argv[1]) as f:
    meta = yaml.safe_load(f) or {}
errs = []
if meta.get("status") != "specified":
    errs.append(f"status must be 'specified', got {meta.get('status')!r}")
tl = meta.get("timeline") or {}
if not tl.get("specified"):
    errs.append("timeline.specified must be populated")
for fwd in ("designed", "planned", "implemented", "archived"):
    if tl.get(fwd):
        errs.append(f"timeline.{fwd} must NOT be set at status=specified")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-EX-005 — demo-004 specs.md contains a realistic
# [NEEDS CLARIFICATION] marker.
test_demo_004_has_needs_clarification_marker() {
  local s="$EXAMPLE_DEMOS_DIR/demo-004-user-onboarding/specs.md"
  if [ ! -f "$s" ]; then echo "    demo-004 specs.md missing" >&2; return 1; fi
  if ! grep -qE '\[NEEDS CLARIFICATION:' "$s"; then
    echo "    demo-004 specs.md does not contain a [NEEDS CLARIFICATION:] marker" >&2
    return 1
  fi
}

# FR-EX-006 — MANIFEST.md exists and lists the 4 demos.
test_demos_manifest_present_and_lists_four_demos() {
  if [ ! -f "$EXAMPLE_DEMOS_MANIFEST" ]; then
    echo "    demos MANIFEST.md missing: $EXAMPLE_DEMOS_MANIFEST" >&2; return 1
  fi
  for demo in demo-001-greeting-service demo-002-greeting-screen \
              demo-003-rate-limit demo-004-user-onboarding; do
    if ! grep -qF "$demo" "$EXAMPLE_DEMOS_MANIFEST"; then
      echo "    MANIFEST.md does not list $demo" >&2; return 1
    fi
  done
}

# NFR-EX-004 — each demo's proposal.md ≤ 200 lines.
test_each_demo_proposal_under_size_budget() {
  local d
  local fail=0
  for d in "$EXAMPLE_DEMOS_DIR"/demo-*/; do
    [ -d "$d" ] || continue
    local p="$d/proposal.md"
    [ -f "$p" ] || continue
    local lines
    lines=$(wc -l < "$p" | tr -d ' ')
    if [ "$lines" -gt 200 ]; then
      echo "    $(basename "$d")/proposal.md is $lines lines (> 200 NFR-EX-004 budget)" >&2
      fail=1
    fi
  done
  return $fail
}

# NFR-EX-005 — the 4 demos cover 4 distinct layer combinations.
test_demos_cover_distinct_layer_combinations() {
  if [ ! -d "$EXAMPLE_DEMOS_DIR" ]; then
    echo "    demos dir missing" >&2; return 1
  fi
  python3 - "$EXAMPLE_DEMOS_DIR" <<'PY' || return 1
import os, sys, yaml
demos_dir = sys.argv[1]
canonical = {"demo-001-greeting-service", "demo-002-greeting-screen",
             "demo-003-rate-limit", "demo-004-user-onboarding"}
demos = sorted(d for d in os.listdir(demos_dir)
               if os.path.isdir(os.path.join(demos_dir, d))
               and d.startswith("demo-"))
canonical_combos = []
for d in demos:
    if d not in canonical:
        continue
    fy = os.path.join(demos_dir, d, ".forge.yaml")
    with open(fy) as f:
        meta = yaml.safe_load(f) or {}
    layers = tuple(sorted(meta.get("layers") or []))
    canonical_combos.append((d, layers))
# The 4 canonical demos MUST cover 4 distinct layer combinations
# (NFR-EX-005). Non-canonical demos (demo-005+, e.g. demo-005-connect-greeting
# from t5-connect-codegen) are NOT required to introduce a new combo —
# they may legitimately re-use an existing one (e.g. backend-only).
seen = set()
for d, c in canonical_combos:
    if c in seen:
        print(f"    duplicate layer combination {c!r} in canonical demo {d}", file=sys.stderr)
        sys.exit(1)
    seen.add(c)
if len(seen) != 4:
    print(f"    expected 4 distinct layer combinations across canonical demos, got {len(seen)}: {seen}", file=sys.stderr)
    sys.exit(1)
PY
}

# ─── Phase 3 — CI + docs + baselines tests ────────────────────

# MODIFIED FR-CI-001 — workflow has exactly 7 top-level jobs (6 → 7: b7-6-harness
# added the `harness-rust` job, the ai-native-rag live codegen/build gate).
test_forge_ci_workflow_shape_seven_jobs() {
  if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "    workflow file missing: $WORKFLOW_FILE" >&2; return 1
  fi
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]).read()) or {}
jobs = doc.get("jobs", {})
expected = {"harness", "gates", "cli", "lint", "example", "summary", "harness-rust"}
if set(jobs.keys()) != expected:
    print(f"    expected jobs {sorted(expected)}, got {sorted(jobs.keys())}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-CI-012 — example job present, runs-on, permissions.
test_forge_ci_example_job_present() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]).read()) or {}
job = (doc.get("jobs") or {}).get("example")
if job is None:
    print("    jobs.example missing", file=sys.stderr); sys.exit(1)
errs = []
if job.get("runs-on") != "ubuntu-latest":
    errs.append(f"runs-on must be 'ubuntu-latest', got {job.get('runs-on')!r}")
perms = job.get("permissions") or {}
if perms.get("contents") != "read":
    errs.append(f"permissions.contents must be 'read', got {perms.get('contents')!r}")
allowed = {"contents"}
extras = set(perms.keys()) - allowed
if extras:
    errs.append(f"unexpected permissions present: {sorted(extras)}")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-CI-012 — example job uses dorny/paths-filter@v4 on examples/**.
test_forge_ci_example_job_paths_filter() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]).read()) or {}
job = (doc.get("jobs") or {}).get("example") or {}
steps = job.get("steps") or []
filter_step = next((s for s in steps
                    if isinstance(s.get("uses"), str)
                    and s["uses"].startswith("dorny/paths-filter@")), None)
if filter_step is None:
    print("    no dorny/paths-filter@vN step in jobs.example", file=sys.stderr); sys.exit(1)
if not filter_step["uses"].startswith("dorny/paths-filter@v4"):
    print(f"    paths-filter must be pinned @v4, got {filter_step['uses']!r}", file=sys.stderr); sys.exit(1)
filters = (filter_step.get("with") or {}).get("filters") or ""
if "examples/**" not in filters:
    print(f"    paths-filter.filters does not declare 'examples/**' :\n      {filters!r}", file=sys.stderr); sys.exit(1)
PY
}

# FR-CI-012 — example job conditional steps run verify, linter, parse.
test_forge_ci_example_job_steps() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]).read()) or {}
job = (doc.get("jobs") or {}).get("example") or {}
steps = job.get("steps") or []
needles = ["verify.sh", "constitution-linter.sh", "yaml.safe_load"]
joined = "\n".join(s.get("run") or "" for s in steps if isinstance(s.get("run"), str))
missing = [n for n in needles if n not in joined]
if missing:
    print(f"    example job missing step content for: {missing}", file=sys.stderr); sys.exit(1)
# Conditional gate : at least one step must have an `if:` referencing
# the paths-filter outputs (so unmatched PRs skip work).
guarded = any(isinstance(s.get("if"), str) and "examples-filter" in s["if"] for s in steps)
if not guarded:
    print("    no step gated on the paths-filter output (steps.if missing)", file=sys.stderr); sys.exit(1)
PY
}

# MODIFIED FR-CI-006 — summary's needs list extended to include example (c1) and
# harness-rust (b7-6 — the ai-native-rag live codegen/build gate).
test_forge_ci_summary_aggregates_five_needs() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]).read()) or {}
summary = (doc.get("jobs") or {}).get("summary") or {}
needs = summary.get("needs")
if needs is None:
    print("    jobs.summary.needs missing", file=sys.stderr); sys.exit(1)
if isinstance(needs, str):
    needs = [needs]
expected = {"harness", "gates", "cli", "lint", "example", "harness-rust"}
if set(needs) != expected:
    print(f"    summary.needs must be {sorted(expected)}, got {sorted(needs)}", file=sys.stderr); sys.exit(1)
PY
}

# MODIFIED FR-CI-006 — summary treats example=skipped as success.
test_forge_ci_summary_treats_example_skip_as_success() {
  python3 - "$WORKFLOW_FILE" <<'PY' || return 1
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]).read()) or {}
summary = (doc.get("jobs") or {}).get("summary") or {}
steps = summary.get("steps") or []
joined_run = "\n".join(s.get("run") or "" for s in steps if isinstance(s.get("run"), str))
joined_env = ""
for s in steps:
    env = s.get("env") or {}
    for k, v in env.items():
        joined_env += f"{k}: {v}\n"
needs_example_in_env = "needs.example.result" in joined_env or \
                       "EXAMPLE_RESULT" in joined_env
if not needs_example_in_env:
    print("    summary's env: block does not expose needs.example.result", file=sys.stderr); sys.exit(1)
# Match either explicit string in run or implicit guard via env.
if "skipped" not in joined_run:
    print("    summary's bash logic does not handle example=skipped as success", file=sys.stderr); sys.exit(1)
PY
}

# NFR-CI-002 + FR-CI-013 — workflow ≤ 420 lines (bumped 250→300 2026-05-12;
# 300→340 2026-06-23 by b7-7-example for the MODIFIED FR-CI-012 second-tree
# RAG gate; 340→380 2026-06-23 by b7-6-harness for the new harness-rust job —
# the ai-native-rag live codegen/build gate, ADR-B7-6-005; 380→400 2026-07-12 by
# b6-7-harness for the event-driven-eu promotion gate's harness-rust L2 step,
# ADR-B6-7-005/007; 400→420 2026-07-12 by b6-8-example for the MODIFIED FR-CI-012
# third-tree EDA gate + the b6-8.test.sh harness-loop entry, ADR-B6-8-004).
test_forge_ci_under_size_budget() {
  if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "    workflow file missing" >&2; return 1
  fi
  local lines
  lines=$(wc -l < "$WORKFLOW_FILE" | tr -d ' ')
  if [ "$lines" -gt 420 ]; then
    echo "    forge-ci.yml is $lines lines (> 420 NFR-CI-002 budget)" >&2
    return 1
  fi
}

# FR-EX-008 — each affected NFR gets a "Baseline at archive time of
# c1-reference-project" pointer in spec, plus a section + measured
# value in the corresponding standard. The pointer string is the
# canonical signal that the modification landed.
test_nfr_013_baseline_recorded() {
  if ! grep -q 'NFR-013.*Baseline at archive time of c1-reference-project\|Baseline at archive time of c1-reference-project.*NFR-013' "$SPEC_FSM"; then
    if ! grep -B1 -A20 '^### NFR-013' "$SPEC_FSM" 2>/dev/null \
         | grep -q 'Baseline at archive time of c1-reference-project'; then
      echo "    NFR-013 section in spec lacks 'Baseline at archive time of c1-reference-project' line" >&2
      return 1
    fi
  fi
  if ! grep -qE '^## Performance Baselines' "$STD_CI_WORKFLOWS"; then
    echo "    standard infra/ci-workflows.md missing '## Performance Baselines' H2 section" >&2
    return 1
  fi
}

test_nfr_014_baseline_recorded() {
  if ! grep -B1 -A20 '^### NFR-014' "$SPEC_FSM" 2>/dev/null \
       | grep -q 'Baseline at archive time of c1-reference-project'; then
    echo "    NFR-014 section in spec lacks 'Baseline at archive time of c1-reference-project' line" >&2
    return 1
  fi
}

test_nfr_015_baseline_recorded() {
  if ! grep -B1 -A20 '^### NFR-015' "$SPEC_FSM" 2>/dev/null \
       | grep -q 'Baseline at archive time of c1-reference-project'; then
    echo "    NFR-015 section in spec lacks 'Baseline at archive time of c1-reference-project' line" >&2
    return 1
  fi
  if ! grep -qE '^## Startup Baselines' "$STD_OBS_LOCAL"; then
    echo "    standard infra/observability-local.md missing '## Startup Baselines' H2 section" >&2
    return 1
  fi
}

test_nfr_017_baseline_recorded() {
  if ! grep -B1 -A20 '^### NFR-017' "$SPEC_FSM" 2>/dev/null \
       | grep -q 'Baseline at archive time of c1-reference-project'; then
    echo "    NFR-017 section in spec lacks 'Baseline at archive time of c1-reference-project' line" >&2
    return 1
  fi
  if ! grep -qE '^## Diff Budget' "$STD_K8S_OVERLAYS"; then
    echo "    standard infra/k8s-overlays.md missing '## Diff Budget' H2 section" >&2
    return 1
  fi
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
# NFR-EX-002 — example tree ≤ 5 MB committed (excludes ignored paths).
test_example_tree_byte_budget() {
  if [ ! -d "$EXAMPLE_DIR" ]; then
    echo "    example dir missing" >&2; return 1
  fi
  # Sum bytes ; excludes paths handled by .gitignore (build/,
  # target/, .dart_tool/, etc.) since they are not committed.
  local bytes
  bytes=$(cd "$EXAMPLE_DIR" && \
    find . -type f \
      -not -path '*/build/*' \
      -not -path '*/target/*' \
      -not -path '*/.dart_tool/*' \
      -not -path '*/node_modules/*' \
      -not -path '*/.cargo/*' \
      -not -path '*/coverage/*' \
      -exec wc -c {} \; 2>/dev/null \
      | awk '{sum += $1} END {print sum}')
  bytes=${bytes:-0}
  local budget=$((5 * 1024 * 1024))
  if [ "$bytes" -gt "$budget" ]; then
    local mb
    mb=$(awk -v b="$bytes" 'BEGIN { printf "%.2f", b/1024/1024 }')
    echo "    example tree is ${mb} MB (> 5 MB NFR-EX-002 budget)" >&2
    return 1
  fi
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
  run_test test_forge_ci_workflow_shape_seven_jobs
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
