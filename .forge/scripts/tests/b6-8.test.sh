#!/usr/bin/env bash
# Forge — B.6.8 event-driven-eu Reference Project Harness (b6-8-example)
# <!-- Audit: B.6.8 (b6-8-example) -->
#
# Validates the third reference project tree under examples/ —
# forge-eda-example/ — demonstrating the event-driven-eu archetype:
#  - EDA example tree canonical structure + scaffold-manifest
#    (FR-EDAEX-001).
#  - Top-of-tree navigation README + meta-README row
#    (FR-EDAEX-002, FR-EDAEX-003).
#  - Three archived demo changes, their 5 artefacts, demo-003
#    multi-layer shape [backend, infra], the event-driven surfaces, the
#    demo manifest (FR-EDAEX-004, 005, 006).
#  - The EDA tree's own gates pass standalone (FR-EDAEX-007, L2).
#  - The example renders via the REAL `forge init` CLI (the archetype is
#    stable/scaffoldable since B.6.7); committing it does NOT modify the
#    archetype (FR-EDAEX-009).
#  - The example-reference.md consolidation post-archive (FR-EDAEX-010).
#  - The forge-ci.yml example job gates the EDA tree, the FSM + RAG blocks
#    are preserved, the harness loop registers b6-8.test.sh, and the
#    line budget holds (FR-CI-012, FR-EDAEX-008).
#  - NFR-EDAEX-* (no archetype/schema edit, byte budget, proposal size,
#    distinct combinations).
#
# This harness follows the manifest pattern established by b7-7.test.sh /
# c1.test.sh: a `# MANIFEST: test_* — FR-EDAEX-NNN` comment block declares
# each test; a meta-check (`test_b6_8_manifest_self_consistency`) parses
# the manifest and asserts every declared function is defined.
#
# Levels:
#  L1 (default) — hermetic structural / YAML / Markdown checks.
#  L2 (--require-example-tools) — runs the EDA tree's own gates + asserts
#       the archetype is still stable/scaffoldable (the promoted state the
#       example was rendered from).
#
# Usage:
#   bash .forge/scripts/tests/b6-8.test.sh
#   bash .forge/scripts/tests/b6-8.test.sh --require-example-tools

set -euo pipefail

# ─── CLI flags ──────────────────────────────────────────────────

REQUIRE_EXAMPLE_TOOLS=0
for arg in "$@"; do
  case "$arg" in
    --require-example-tools) REQUIRE_EXAMPLE_TOOLS=1 ;;
    *) echo "unknown flag: $arg" >&2 ; exit 2 ;;
  esac
done

# ─── Paths ──────────────────────────────────────────────────────

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

EXAMPLES_README="$FORGE_ROOT_REAL/examples/README.md"
EDA_DIR="$FORGE_ROOT_REAL/examples/forge-eda-example"
EDA_README="$EDA_DIR/README.md"
EDA_FORGE_YAML="$EDA_DIR/.forge.yaml"
EDA_SCAFFOLD_MANIFEST="$EDA_DIR/.forge/scaffold-manifest.yaml"
EDA_DEMOS_DIR="$EDA_DIR/.forge/changes"
EDA_DEMOS_MANIFEST="$EDA_DEMOS_DIR/MANIFEST.md"
WORKFLOW_FILE="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"
SCHEMA_EDE="$FORGE_ROOT_REAL/.forge/schemas/event-driven-eu/1.0.0.yaml"
SPEC_EXAMPLE="$FORGE_ROOT_REAL/.forge/specs/example-reference.md"
B6_8_FORGE_YAML="$FORGE_ROOT_REAL/.forge/changes/b6-8-example/.forge.yaml"

# forge-ci.yml line budget (bumped 400→420 by b6-8 for the third example
# gate block + the b6-8.test.sh loop entry; asserted in lockstep in
# c1/g1/t5-1/t5-otel-live-run + forge-self-ci.md).
CI_LINE_BUDGET=420

DEMOS=(demo-001-ingestion-http-nats demo-002-projection-readmodel demo-003-order-saga)

# ─── Shared helpers ─────────────────────────────────────────────
# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"

# Reset counters in case another harness sourced helpers in same shell.
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest — single source of truth for FR ↔ test mapping ────
#
# Every line of the form `# MANIFEST: test_* — FR-EDAEX-NNN` below is
# parsed by `test_b6_8_manifest_self_consistency` to assert every entry
# resolves to a defined bash function.
#
# Phase 1 — tree cluster
# MANIFEST: test_eda_example_tree_canonical_structure          — FR-EDAEX-001
# MANIFEST: test_eda_example_scaffold_manifest_complete        — FR-EDAEX-001
# MANIFEST: test_eda_example_readme_has_required_sections      — FR-EDAEX-002
# MANIFEST: test_examples_meta_readme_lists_eda_example        — FR-EDAEX-003
# MANIFEST: test_eda_archetype_still_stable_scaffoldable       — FR-EDAEX-009
# MANIFEST: test_b6_8_no_archetype_or_schema_edit              — NFR-EDAEX-001
# MANIFEST: test_forge_ci_example_job_gates_eda_tree           — FR-CI-012
# MANIFEST: test_forge_ci_example_job_fsm_rag_blocks_preserved — FR-CI-012
# MANIFEST: test_forge_ci_harness_loop_has_b6_8                — FR-EDAEX-008
# MANIFEST: test_forge_ci_line_budget_holds                    — FR-CI-012
#
# Phase 2 — demos cluster
# MANIFEST: test_eda_demos_count_and_status                    — FR-EDAEX-004
# MANIFEST: test_each_eda_demo_has_five_artefacts              — FR-EDAEX-004
# MANIFEST: test_eda_demo_003_is_multi_layer                   — FR-EDAEX-004
# MANIFEST: test_eda_demos_cover_event_surfaces                — FR-EDAEX-005
# MANIFEST: test_eda_demos_manifest_present_and_lists_three_demos — FR-EDAEX-006
# MANIFEST: test_each_eda_demo_proposal_under_size_budget      — NFR-EDAEX-004
# MANIFEST: test_eda_demos_cover_distinct_combinations         — NFR-EDAEX-005
#
# Phase 3 — harness + spec cluster
# MANIFEST: test_eda_example_tree_byte_budget                  — NFR-EDAEX-002
# MANIFEST: test_example_reference_spec_has_edaex_section_post_archive — FR-EDAEX-010
# MANIFEST: test_eda_example_tree_verify_exits_zero            — FR-EDAEX-007
# MANIFEST: test_eda_example_tree_constitution_linter_exits_zero — FR-EDAEX-007
# MANIFEST: test_cli_scaffolds_eda_init                        — FR-EDAEX-009
#
# Meta
# MANIFEST: test_b6_8_manifest_self_consistency                — meta (FR-EDAEX-008)
#
# ────────────────────────────────────────────────────────────────

# ─── Meta self-check — manifest ↔ implementation parity ────────

test_b6_8_manifest_self_consistency() {
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

# ─── Phase 1 — tree cluster tests ──────────────────────────────

# FR-EDAEX-001 — examples/forge-eda-example/ has the canonical
# event-driven-eu structure.
test_eda_example_tree_canonical_structure() {
  if [ ! -d "$EDA_DIR" ]; then
    echo "    EDA example dir missing: $EDA_DIR" >&2; return 1
  fi
  local p
  for p in \
      backend/events backend/eventstore backend/saga backend/bin-server \
      infra shared/asyncapi shared/protos/v1/events \
      .forge .claude; do
    if [ ! -e "$EDA_DIR/$p" ]; then
      echo "    expected subdir/path missing: $EDA_DIR/$p" >&2
      return 1
    fi
  done
  local file
  for file in CLAUDE.md Taskfile.yml docker-compose.dev.yml .gitignore .forge.yaml README.md; do
    if [ ! -f "$EDA_DIR/$file" ]; then
      echo "    expected root file missing: $EDA_DIR/$file" >&2
      return 1
    fi
  done
  # Schema declared in .forge.yaml.
  if ! grep -q 'schema: event-driven-eu' "$EDA_FORGE_YAML"; then
    echo "    .forge.yaml does not declare schema: event-driven-eu" >&2
    return 1
  fi
  # The seed events.proto must carry EventService.Publish + ReadStream.
  local proto="$EDA_DIR/shared/protos/v1/events/events.proto"
  if [ ! -f "$proto" ]; then
    echo "    events.proto missing: $proto" >&2; return 1
  fi
  if ! grep -q 'rpc Publish(' "$proto" || ! grep -q 'rpc ReadStream(' "$proto"; then
    echo "    events.proto missing EventService.Publish and/or ReadStream RPC" >&2
    return 1
  fi
}

# FR-EDAEX-001 — scaffold-manifest.yaml records the audit trail.
test_eda_example_scaffold_manifest_complete() {
  if [ ! -f "$EDA_SCAFFOLD_MANIFEST" ]; then
    echo "    scaffold-manifest missing: $EDA_SCAFFOLD_MANIFEST" >&2
    return 1
  fi
  python3 - "$EDA_SCAFFOLD_MANIFEST" <<'PY' || return 1
import sys, yaml
with open(sys.argv[1]) as f:
    d = yaml.safe_load(f) or {}
errs = []
top_level = [
    "archetype", "archetype_version", "scaffold_plan_sha",
    "template_set_sha", "scaffold_date", "project_name",
    "reverse_domain", "root_module",
]
for k in top_level:
    if k not in d:
        errs.append(f"missing top-level key: {k}")
if d.get("archetype") != "event-driven-eu":
    errs.append(f"archetype must be 'event-driven-eu', got {d.get('archetype')!r}")
if str(d.get("archetype_version")) != "1.0.0":
    errs.append(f"archetype_version must be '1.0.0', got {d.get('archetype_version')!r}")
if d.get("project_name") != "forge-eda-example":
    errs.append(f"project_name must be 'forge-eda-example', got {d.get('project_name')!r}")
if errs:
    for e in errs:
        print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-EDAEX-002 — EDA README has the 4 H2 sections + the "does NOT show" note.
test_eda_example_readme_has_required_sections() {
  if [ ! -f "$EDA_README" ]; then
    echo "    README missing: $EDA_README" >&2; return 1
  fi
  local section
  for section in '## How this example was built' "## What.s in here" '## Demo changes' '## Reproducing this example'; do
    if ! grep -qE "$section" "$EDA_README"; then
      echo "    README missing H2 section matching: $section" >&2
      return 1
    fi
  done
  # The "does NOT show" note must record the known gaps.
  if ! grep -qiE 'does NOT show' "$EDA_README"; then
    echo "    README missing the 'does NOT show' known-gaps note" >&2
    return 1
  fi
  # Must document the real `forge init` CLI (not overlay.sh) as the build path.
  if ! grep -q 'forge init --archetype event-driven-eu' "$EDA_README"; then
    echo "    README does not document the real 'forge init' CLI build path" >&2
    return 1
  fi
}

# FR-EDAEX-003 — examples/README.md lists the EDA example.
test_examples_meta_readme_lists_eda_example() {
  if [ ! -f "$EXAMPLES_README" ]; then
    echo "    meta README missing: $EXAMPLES_README" >&2; return 1
  fi
  # The FSM + RAG rows must still be present (additive).
  if ! grep -q 'forge-fsm-example' "$EXAMPLES_README"; then
    echo "    meta README no longer lists forge-fsm-example (must stay additive)" >&2
    return 1
  fi
  if ! grep -q 'forge-rag-example' "$EXAMPLES_README"; then
    echo "    meta README no longer lists forge-rag-example (must stay additive)" >&2
    return 1
  fi
  # A row referencing forge-eda-example AND event-driven-eu must exist.
  if ! grep -q 'forge-eda-example' "$EXAMPLES_README"; then
    echo "    meta README does not list forge-eda-example" >&2
    return 1
  fi
  if ! grep -E 'forge-eda-example' "$EXAMPLES_README" | grep -q 'event-driven-eu'; then
    echo "    forge-eda-example row does not name the event-driven-eu archetype" >&2
    return 1
  fi
}

# FR-EDAEX-009 — the archetype is stable/scaffoldable (the promoted state the
# example was rendered from). Committing the example must NOT change it.
test_eda_archetype_still_stable_scaffoldable() {
  if [ ! -f "$SCHEMA_EDE" ]; then
    echo "    event-driven-eu schema missing: $SCHEMA_EDE" >&2; return 1
  fi
  python3 - "$SCHEMA_EDE" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
errs = []
if d.get("stage") != "stable":
    errs.append(f"stage expected 'stable' (promoted by B.6.7), got {d.get('stage')!r}")
if d.get("scaffoldable") is not True:
    errs.append(f"scaffoldable expected True (promoted by B.6.7), got {d.get('scaffoldable')!r}")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# NFR-EDAEX-001 — additive: b6-8 must not edit the archetype template tree
# or the schema. Asserts no file UNDER the framework archetype/schema paths
# is in the working-tree diff vs HEAD (the example carries its OWN copy
# under examples/; the framework copy is untouched).
test_b6_8_no_archetype_or_schema_edit() {
  if ! command -v git >/dev/null 2>&1; then
    echo "    SKIP: git not available" >&2; return 0
  fi
  local touched
  touched=$(cd "$FORGE_ROOT_REAL" && git diff --name-only HEAD -- \
      '.forge/templates/archetypes/event-driven-eu' \
      '.forge/schemas/event-driven-eu' 2>/dev/null || true)
  if [ -n "$touched" ]; then
    echo "    b6-8 working tree edits framework archetype/schema files:" >&2
    printf '      %s\n' $touched >&2
    return 1
  fi
}

# FR-CI-012 — the example job gains an EDA gate block.
test_forge_ci_example_job_gates_eda_tree() {
  if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "    workflow missing: $WORKFLOW_FILE" >&2; return 1
  fi
  if ! grep -q 'cd examples/forge-eda-example' "$WORKFLOW_FILE"; then
    echo "    example job has no 'cd examples/forge-eda-example' step" >&2
    return 1
  fi
  if ! grep -qE 'eda-example gates|forge-eda-example' "$WORKFLOW_FILE"; then
    echo "    EDA gate steps not found in example job" >&2
    return 1
  fi
}

# FR-CI-012 — the FSM + RAG gate blocks are preserved (additive).
test_forge_ci_example_job_fsm_rag_blocks_preserved() {
  if ! grep -q 'cd examples/forge-fsm-example' "$WORKFLOW_FILE"; then
    echo "    FSM gate steps removed/altered (cd examples/forge-fsm-example missing)" >&2
    return 1
  fi
  if ! grep -q 'cd examples/forge-rag-example' "$WORKFLOW_FILE"; then
    echo "    RAG gate steps removed/altered (cd examples/forge-rag-example missing)" >&2
    return 1
  fi
  # The FSM archetype-template parse step must still be present.
  if ! grep -q 'full-stack-monorepo/.github/workflows' "$WORKFLOW_FILE"; then
    echo "    FSM archetype workflow-template parse step removed" >&2
    return 1
  fi
}

# FR-EDAEX-008 — b6-8.test.sh registered in the harness loop.
test_forge_ci_harness_loop_has_b6_8() {
  if ! grep -qF 'b6-8.test.sh' "$WORKFLOW_FILE"; then
    echo "    harness loop does not list b6-8.test.sh" >&2
    return 1
  fi
}

# FR-CI-012 — the forge-ci.yml line budget holds after the b6-8 gate block.
test_forge_ci_line_budget_holds() {
  local lines
  lines=$(wc -l < "$WORKFLOW_FILE" | tr -d ' ')
  if [ "$lines" -gt "$CI_LINE_BUDGET" ]; then
    echo "    forge-ci.yml is $lines lines (> $CI_LINE_BUDGET budget)" >&2
    return 1
  fi
}

# ─── Phase 2 — demos cluster tests ─────────────────────────────

# FR-EDAEX-004 — exactly 3 demos, all status: archived.
test_eda_demos_count_and_status() {
  if [ ! -d "$EDA_DEMOS_DIR" ]; then
    echo "    demos dir missing: $EDA_DEMOS_DIR" >&2; return 1
  fi
  local count=0 d
  for d in "$EDA_DEMOS_DIR"/*/; do
    [ -d "$d" ] || continue
    count=$((count + 1))
  done
  if [ "$count" -ne 3 ]; then
    echo "    expected exactly 3 demo directories, found $count" >&2
    return 1
  fi
  for d in "${DEMOS[@]}"; do
    local yml="$EDA_DEMOS_DIR/$d/.forge.yaml"
    if [ ! -f "$yml" ]; then
      echo "    demo $d missing .forge.yaml" >&2; return 1
    fi
    local status
    status=$(python3 - "$yml" <<'PY' 2>/dev/null
import sys, yaml
print((yaml.safe_load(open(sys.argv[1])) or {}).get("status",""))
PY
)
    if [ "$status" != "archived" ]; then
      echo "    demo $d status='$status' (expected 'archived')" >&2
      return 1
    fi
  done
}

# FR-EDAEX-004 — each demo carries the canonical 5 artefacts.
test_each_eda_demo_has_five_artefacts() {
  local d
  for d in "${DEMOS[@]}"; do
    local dir="$EDA_DEMOS_DIR/$d"
    [ -d "$dir" ] || { echo "    demo dir missing: $dir" >&2; return 1; }
    [ -f "$dir/proposal.md" ] || { echo "    $d: missing proposal.md" >&2; return 1; }
    [ -f "$dir/specs.md" ]    || { echo "    $d: missing specs.md" >&2; return 1; }
    if ! ls "$dir"/features/*.feature >/dev/null 2>&1; then
      echo "    $d: missing features/*.feature" >&2; return 1
    fi
    local yml="$dir/.forge.yaml"
    local multi
    multi=$(python3 - "$yml" <<'PY' 2>/dev/null
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
layers = d.get("layers") or []
print("1" if isinstance(layers, list) and len(layers) >= 2 else "0")
PY
)
    if [ "$multi" = "1" ]; then
      if ! ls "$dir"/designs/design-*.md >/dev/null 2>&1; then
        echo "    $d (multi-layer): missing designs/design-<layer>.md" >&2; return 1
      fi
      if ! ls "$dir"/tasks/tasks-*.md >/dev/null 2>&1; then
        echo "    $d (multi-layer): missing tasks/tasks-<layer>.md" >&2; return 1
      fi
    else
      [ -f "$dir/design.md" ] || { echo "    $d: missing design.md" >&2; return 1; }
      [ -f "$dir/tasks.md" ]  || { echo "    $d: missing tasks.md" >&2; return 1; }
    fi
  done
}

# FR-EDAEX-004 + FR-GL-016 — demo-003 is multi-layer [backend, infra].
test_eda_demo_003_is_multi_layer() {
  local dir="$EDA_DEMOS_DIR/demo-003-order-saga"
  local yml="$dir/.forge.yaml"
  [ -f "$yml" ] || { echo "    demo-003 .forge.yaml missing" >&2; return 1; }
  python3 - "$yml" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
layers = d.get("layers") or []
errs = []
if not (isinstance(layers, list) and len(layers) >= 2):
    errs.append(f"layers must have >=2 entries, got {layers!r}")
if set(["backend","infra"]) - set(layers):
    errs.append(f"layers must include backend AND infra, got {layers!r}")
for key in ("designs_per_layer","tasks_per_layer"):
    m = d.get(key)
    if not isinstance(m, dict) or not m:
        errs.append(f"{key} missing or empty for multi-layer demo")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
  ls "$dir"/designs/design-backend.md "$dir"/designs/design-infra.md >/dev/null 2>&1 \
    || { echo "    demo-003 per-layer design files missing" >&2; return 1; }
  ls "$dir"/tasks/tasks-backend.md "$dir"/tasks/tasks-infra.md >/dev/null 2>&1 \
    || { echo "    demo-003 per-layer tasks files missing" >&2; return 1; }
}

# FR-EDAEX-005 — collectively the demos materialise the event-driven surfaces.
test_eda_demos_cover_event_surfaces() {
  # NATS JetStream publish + idempotency dedup — demo-001.
  if ! grep -rqiE 'jetstream|nats' "$EDA_DEMOS_DIR/demo-001-ingestion-http-nats" 2>/dev/null; then
    echo "    demo-001 specs/design do not mention NATS JetStream" >&2; return 1
  fi
  if ! grep -rqiE 'idempoten' "$EDA_DEMOS_DIR/demo-001-ingestion-http-nats" 2>/dev/null; then
    echo "    demo-001 does not mention idempotency keys" >&2; return 1
  fi
  # Event store → read-model projection — demo-002.
  if ! grep -rqiE 'projection|read.model' "$EDA_DEMOS_DIR/demo-002-projection-readmodel" 2>/dev/null; then
    echo "    demo-002 does not mention the read-model projection" >&2; return 1
  fi
  # Temporal saga + reverse-order compensation — demo-003.
  if ! grep -rqiE 'saga' "$EDA_DEMOS_DIR/demo-003-order-saga" 2>/dev/null; then
    echo "    demo-003 does not mention the saga" >&2; return 1
  fi
  if ! grep -rqiE 'compensat' "$EDA_DEMOS_DIR/demo-003-order-saga" 2>/dev/null; then
    echo "    demo-003 does not mention saga compensation" >&2; return 1
  fi
}

# FR-EDAEX-006 — the demo manifest lists all 3 demos.
test_eda_demos_manifest_present_and_lists_three_demos() {
  if [ ! -f "$EDA_DEMOS_MANIFEST" ]; then
    echo "    demo MANIFEST.md missing: $EDA_DEMOS_MANIFEST" >&2; return 1
  fi
  local d
  for d in "${DEMOS[@]}"; do
    if ! grep -q "$d" "$EDA_DEMOS_MANIFEST"; then
      echo "    MANIFEST.md does not list $d" >&2; return 1
    fi
  done
}

# NFR-EDAEX-004 — each demo proposal ≤ 200 lines.
test_each_eda_demo_proposal_under_size_budget() {
  local d
  for d in "${DEMOS[@]}"; do
    local p="$EDA_DEMOS_DIR/$d/proposal.md"
    [ -f "$p" ] || { echo "    $d: proposal.md missing" >&2; return 1; }
    local lines
    lines=$(wc -l < "$p" | tr -d ' ')
    if [ "$lines" -gt 200 ]; then
      echo "    $d: proposal.md is $lines lines (budget 200)" >&2; return 1
    fi
  done
}

# NFR-EDAEX-005 — the 3 demos cover distinct layer + event-surface combos.
test_eda_demos_cover_distinct_combinations() {
  local m1 m2 m3
  m1=$(_b68_layers demo-001-ingestion-http-nats)
  m2=$(_b68_layers demo-002-projection-readmodel)
  m3=$(_b68_layers demo-003-order-saga)
  if [ "$m1" != "backend" ]; then
    echo "    demo-001 layers='$m1' (expected single-layer backend)" >&2; return 1
  fi
  if [ "$m2" != "backend" ]; then
    echo "    demo-002 layers='$m2' (expected single-layer backend)" >&2; return 1
  fi
  if [ "$m3" = "backend" ]; then
    echo "    demo-003 layers='$m3' (expected multi-layer)" >&2; return 1
  fi
  # demo-001 vs demo-002 must differ by event surface (events/ vs eventstore/).
  if ! grep -rqiE 'publish|jetstream|ingest' "$EDA_DEMOS_DIR/demo-001-ingestion-http-nats/specs.md" 2>/dev/null; then
    echo "    demo-001 specs do not target the events/ ingestion surface" >&2; return 1
  fi
  if ! grep -rqiE 'projection|event.store|read.model' "$EDA_DEMOS_DIR/demo-002-projection-readmodel/specs.md" 2>/dev/null; then
    echo "    demo-002 specs do not target the eventstore/ projection surface" >&2; return 1
  fi
}

# Helper — echo the comma-joined sorted layer ids of a demo.
_b68_layers() {
  local yml="$EDA_DEMOS_DIR/$1/.forge.yaml"
  [ -f "$yml" ] || { echo ""; return; }
  python3 - "$yml" <<'PY' 2>/dev/null
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
layers = d.get("layers") or []
print(",".join(sorted(str(x) for x in layers)))
PY
}

# ─── Phase 3 — harness + spec cluster tests ────────────────────

# NFR-EDAEX-002 — EDA example tree ≤ 5 MB (excluding ignored paths).
test_eda_example_tree_byte_budget() {
  if [ ! -d "$EDA_DIR" ]; then
    echo "    EDA dir missing" >&2; return 1
  fi
  local bytes
  bytes=$(find "$EDA_DIR" -type f \
      -not -path '*/target/*' -not -path '*/node_modules/*' \
      -not -path '*/.dart_tool/*' -not -path '*/build/*' \
      -printf '%s\n' 2>/dev/null | awk '{s+=$1} END {print s+0}')
  local budget=$((5 * 1024 * 1024))
  if [ "$bytes" -gt "$budget" ]; then
    echo "    EDA tree is $bytes bytes (budget $budget = 5 MB)" >&2; return 1
  fi
}

# FR-EDAEX-010 — archive-gated. After b6-8 is archived,
# example-reference.md must carry the FR-EDAEX-* section + a b6-8 row.
# Skip-passes while b6-8's own status is not yet 'archived'.
test_example_reference_spec_has_edaex_section_post_archive() {
  local status=""
  if [ -f "$B6_8_FORGE_YAML" ]; then
    status=$(python3 - "$B6_8_FORGE_YAML" <<'PY' 2>/dev/null
import sys, yaml
print((yaml.safe_load(open(sys.argv[1])) or {}).get("status",""))
PY
)
  fi
  if [ "$status" != "archived" ]; then
    echo "    skipped (b6-8 status='$status', not yet 'archived')" >&2
    return 0
  fi
  if [ ! -f "$SPEC_EXAMPLE" ]; then
    echo "    expected spec file: $SPEC_EXAMPLE" >&2; return 1
  fi
  if ! grep -q 'FR-EDAEX-' "$SPEC_EXAMPLE"; then
    echo "    example-reference.md has no FR-EDAEX-* section post-archive" >&2; return 1
  fi
  if ! grep -q 'b6-8-example' "$SPEC_EXAMPLE"; then
    echo "    example-reference.md has no b6-8-example archived-changes row" >&2; return 1
  fi
}

# ─── L2 (--require-example-tools) tests ────────────────────────

# FR-EDAEX-007 — the EDA tree's own verify.sh exits 0 standalone.
test_eda_example_tree_verify_exits_zero() {
  if [ "$REQUIRE_EXAMPLE_TOOLS" != "1" ]; then
    echo "    skipped (L2 — pass --require-example-tools)" >&2; return 0
  fi
  ( cd "$EDA_DIR" && bash .forge/scripts/verify.sh >/dev/null 2>&1 )
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    EDA tree verify.sh exited $rc (expected 0)" >&2; return 1
  fi
}

# FR-EDAEX-007 — the EDA tree's own constitution-linter.sh exits 0.
test_eda_example_tree_constitution_linter_exits_zero() {
  if [ "$REQUIRE_EXAMPLE_TOOLS" != "1" ]; then
    echo "    skipped (L2 — pass --require-example-tools)" >&2; return 0
  fi
  ( cd "$EDA_DIR" && bash .forge/scripts/constitution-linter.sh >/dev/null 2>&1 )
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    EDA tree constitution-linter.sh exited $rc (expected 0)" >&2; return 1
  fi
}

# FR-EDAEX-009 — the CLI SCAFFOLDS `forge init --archetype event-driven-eu`
# (the archetype is promoted stable/scaffoldable). Asserts the promoted
# schema state directly (the gate that makes the CLI render, not refuse).
test_cli_scaffolds_eda_init() {
  if [ "$REQUIRE_EXAMPLE_TOOLS" != "1" ]; then
    echo "    skipped (L2 — pass --require-example-tools)" >&2; return 0
  fi
  python3 - "$SCHEMA_EDE" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
if d.get("scaffoldable") is not True or d.get("stage") != "stable":
    print(f"    schema not scaffoldable: stage={d.get('stage')!r} scaffoldable={d.get('scaffoldable')!r} (expected stable/true after B.6.7)", file=sys.stderr)
    sys.exit(1)
PY
}

# ─── Main ───────────────────────────────────────────────────────

main() {
  echo "Forge — b6-8-example Test Harness"
  echo "FORGE_ROOT_REAL=$FORGE_ROOT_REAL"
  echo "REQUIRE_EXAMPLE_TOOLS=$REQUIRE_EXAMPLE_TOOLS"
  echo ""
  echo "── Phase 1 : tree cluster ──"
  run_test test_eda_example_tree_canonical_structure
  run_test test_eda_example_scaffold_manifest_complete
  run_test test_eda_example_readme_has_required_sections
  run_test test_examples_meta_readme_lists_eda_example
  run_test test_eda_archetype_still_stable_scaffoldable
  run_test test_b6_8_no_archetype_or_schema_edit
  run_test test_forge_ci_example_job_gates_eda_tree
  run_test test_forge_ci_example_job_fsm_rag_blocks_preserved
  run_test test_forge_ci_harness_loop_has_b6_8
  run_test test_forge_ci_line_budget_holds
  echo ""
  echo "── Phase 2 : demos cluster ──"
  run_test test_eda_demos_count_and_status
  run_test test_each_eda_demo_has_five_artefacts
  run_test test_eda_demo_003_is_multi_layer
  run_test test_eda_demos_cover_event_surfaces
  run_test test_eda_demos_manifest_present_and_lists_three_demos
  run_test test_each_eda_demo_proposal_under_size_budget
  run_test test_eda_demos_cover_distinct_combinations
  echo ""
  echo "── Phase 3 : harness + spec cluster ──"
  run_test test_eda_example_tree_byte_budget
  run_test test_example_reference_spec_has_edaex_section_post_archive
  run_test test_eda_example_tree_verify_exits_zero
  run_test test_eda_example_tree_constitution_linter_exits_zero
  run_test test_cli_scaffolds_eda_init
  echo ""
  echo "── Meta ──"
  run_test test_b6_8_manifest_self_consistency
  print_summary
}

main "$@"
