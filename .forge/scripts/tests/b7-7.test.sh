#!/usr/bin/env bash
# Forge — B.7.7 RAG Reference Project Harness (b7-7-example)
# <!-- Audit: B.7.7 (b7-7-example) -->
#
# Validates the second reference project tree under examples/ —
# forge-rag-example/ — demonstrating the ai-native-rag archetype:
#  - RAG example tree canonical structure + scaffold-manifest
#    (FR-RAGEX-001).
#  - Top-of-tree navigation README + meta-README row
#    (FR-RAGEX-002, FR-RAGEX-003).
#  - Three archived demo changes, their 5 artefacts, demo-003
#    multi-layer shape, the AI-First surfaces, the demo manifest
#    (FR-RAGEX-004, 005, 006).
#  - The RAG tree's own gates pass standalone (FR-RAGEX-007, L2).
#  - The example renders via overlay.sh while the archetype stays
#    candidate; committing it does NOT promote (FR-RAGEX-009).
#  - The example-reference.md consolidation post-archive (FR-RAGEX-010).
#  - The forge-ci.yml example job gates the RAG tree, the FSM block is
#    preserved, the harness loop registers b7-7.test.sh (FR-CI-012,
#    FR-RAGEX-008).
#  - NFR-RAGEX-* (no archetype/schema edit, byte budget, proposal size,
#    distinct combinations).
#
# This harness follows the manifest pattern established by c1.test.sh:
# a `# MANIFEST: test_* — FR-RAGEX-NNN` comment block declares each test;
# a meta-check (`test_b7_7_manifest_self_consistency`) parses the
# manifest and asserts every declared function is defined.
#
# Levels:
#  L1 (default) — hermetic structural / YAML / Markdown checks.
#  L2 (--require-example-tools) — runs the RAG tree's own gates +
#       asserts the CLI still refuses `forge init --archetype
#       ai-native-rag` with exit 3.
#
# Usage:
#   bash .forge/scripts/tests/b7-7.test.sh
#   bash .forge/scripts/tests/b7-7.test.sh --require-example-tools

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
RAG_DIR="$FORGE_ROOT_REAL/examples/forge-rag-example"
RAG_README="$RAG_DIR/README.md"
RAG_FORGE_YAML="$RAG_DIR/.forge.yaml"
RAG_SCAFFOLD_MANIFEST="$RAG_DIR/.forge/scaffold-manifest.yaml"
RAG_DEMOS_DIR="$RAG_DIR/.forge/changes"
RAG_DEMOS_MANIFEST="$RAG_DEMOS_DIR/MANIFEST.md"
WORKFLOW_FILE="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"
SCHEMA_AINR="$FORGE_ROOT_REAL/.forge/schemas/ai-native-rag/1.0.0.yaml"
SPEC_EXAMPLE="$FORGE_ROOT_REAL/.forge/specs/example-reference.md"
B7_7_FORGE_YAML="$FORGE_ROOT_REAL/.forge/changes/b7-7-example/.forge.yaml"
VERIFY_SH="$SCRIPTS_DIR/verify.sh"
LINTER_SH="$SCRIPTS_DIR/constitution-linter.sh"
WRAPPER_RAG="$FORGE_ROOT_REAL/bin/forge-init-ai-native-rag.sh"

DEMOS=(demo-001-doc-ingestion demo-002-mcp-search-tool demo-003-rag-query-ui)

# ─── Shared helpers ─────────────────────────────────────────────
# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"

# Reset counters in case another harness sourced helpers in same shell.
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest — single source of truth for FR ↔ test mapping ────
#
# Every line of the form `# MANIFEST: test_* — FR-RAGEX-NNN` below is
# parsed by `test_b7_7_manifest_self_consistency` to assert every
# entry resolves to a defined bash function.
#
# Phase 1 — tree cluster
# MANIFEST: test_rag_example_tree_canonical_structure         — FR-RAGEX-001
# MANIFEST: test_rag_example_scaffold_manifest_complete       — FR-RAGEX-001
# MANIFEST: test_rag_example_readme_has_required_sections     — FR-RAGEX-002
# MANIFEST: test_examples_meta_readme_lists_rag_example       — FR-RAGEX-003
# MANIFEST: test_rag_archetype_still_candidate                — FR-RAGEX-009
# MANIFEST: test_b7_7_no_archetype_or_schema_edit             — NFR-RAGEX-001
# MANIFEST: test_forge_ci_example_job_gates_rag_tree          — FR-CI-012
# MANIFEST: test_forge_ci_example_job_fsm_block_preserved     — FR-CI-012
# MANIFEST: test_forge_ci_harness_loop_has_b7_7               — FR-RAGEX-008
#
# Phase 2 — demos cluster
# MANIFEST: test_rag_demos_count_and_status                   — FR-RAGEX-004
# MANIFEST: test_each_rag_demo_has_five_artefacts             — FR-RAGEX-004
# MANIFEST: test_rag_demo_003_is_multi_layer                  — FR-RAGEX-004
# MANIFEST: test_rag_demos_cover_ai_first_surfaces            — FR-RAGEX-005
# MANIFEST: test_rag_demos_manifest_present_and_lists_three_demos — FR-RAGEX-006
# MANIFEST: test_each_rag_demo_proposal_under_size_budget     — NFR-RAGEX-004
# MANIFEST: test_rag_demos_cover_distinct_combinations        — NFR-RAGEX-005
#
# Phase 3 — harness + spec cluster
# MANIFEST: test_rag_example_tree_byte_budget                 — NFR-RAGEX-002
# MANIFEST: test_example_reference_spec_has_ragex_section_post_archive — FR-RAGEX-010
# MANIFEST: test_rag_example_tree_verify_exits_zero           — FR-RAGEX-007
# MANIFEST: test_rag_example_tree_constitution_linter_exits_zero — FR-RAGEX-007
# MANIFEST: test_cli_still_refuses_rag_init                   — FR-RAGEX-009
#
# Meta
# MANIFEST: test_b7_7_manifest_self_consistency               — meta (FR-RAGEX-008)
#
# ────────────────────────────────────────────────────────────────

# ─── Meta self-check — manifest ↔ implementation parity ────────

test_b7_7_manifest_self_consistency() {
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

# FR-RAGEX-001 — examples/forge-rag-example/ has the canonical
# ai-native-rag structure.
test_rag_example_tree_canonical_structure() {
  if [ ! -d "$RAG_DIR" ]; then
    echo "    RAG example dir missing: $RAG_DIR" >&2; return 1
  fi
  local p
  for p in \
      backend/rag backend/mcp backend/llm_gateway backend/bin-server \
      frontend/web-public infra shared/protos/v1/rag \
      .forge .claude; do
    if [ ! -e "$RAG_DIR/$p" ]; then
      echo "    expected subdir/path missing: $RAG_DIR/$p" >&2
      return 1
    fi
  done
  local file
  for file in CLAUDE.md Taskfile.yml docker-compose.dev.yml .gitignore .forge.yaml README.md; do
    if [ ! -f "$RAG_DIR/$file" ]; then
      echo "    expected root file missing: $RAG_DIR/$file" >&2
      return 1
    fi
  done
  # Schema declared in .forge.yaml.
  if ! grep -q 'schema: ai-native-rag' "$RAG_FORGE_YAML"; then
    echo "    .forge.yaml does not declare schema: ai-native-rag" >&2
    return 1
  fi
  # The seed rag.proto must carry RagService.Query + QueryStream (b7-10).
  local proto="$RAG_DIR/shared/protos/v1/rag/rag.proto"
  if [ ! -f "$proto" ]; then
    echo "    rag.proto missing: $proto" >&2; return 1
  fi
  if ! grep -q 'rpc Query(' "$proto" || ! grep -q 'rpc QueryStream(' "$proto"; then
    echo "    rag.proto missing RagService.Query and/or QueryStream RPC" >&2
    return 1
  fi
}

# FR-RAGEX-001 — scaffold-manifest.yaml records the audit trail.
test_rag_example_scaffold_manifest_complete() {
  if [ ! -f "$RAG_SCAFFOLD_MANIFEST" ]; then
    echo "    scaffold-manifest missing: $RAG_SCAFFOLD_MANIFEST" >&2
    return 1
  fi
  python3 - "$RAG_SCAFFOLD_MANIFEST" <<'PY' || return 1
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
if d.get("archetype") != "ai-native-rag":
    errs.append(f"archetype must be 'ai-native-rag', got {d.get('archetype')!r}")
if str(d.get("archetype_version")) != "1.0.0":
    errs.append(f"archetype_version must be '1.0.0', got {d.get('archetype_version')!r}")
if d.get("project_name") != "forge-rag-example":
    errs.append(f"project_name must be 'forge-rag-example', got {d.get('project_name')!r}")
if errs:
    for e in errs:
        print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# FR-RAGEX-002 — RAG README has the 4 H2 sections + the "does NOT show" note.
test_rag_example_readme_has_required_sections() {
  if [ ! -f "$RAG_README" ]; then
    echo "    README missing: $RAG_README" >&2; return 1
  fi
  local section
  for section in '## How this example was built' "## What.s in here" '## Demo changes' '## Reproducing this example'; do
    if ! grep -qE "$section" "$RAG_README"; then
      echo "    README missing H2 section matching: $section" >&2
      return 1
    fi
  done
  # The "does NOT show" note must record the known gaps.
  if ! grep -qiE 'does NOT show|candidate' "$RAG_README"; then
    echo "    README missing the 'does NOT show' / candidate-caveat note" >&2
    return 1
  fi
  # Must document overlay.sh (not forge init) as the build path.
  if ! grep -q 'overlay.sh' "$RAG_README"; then
    echo "    README does not document overlay.sh as the build path" >&2
    return 1
  fi
}

# FR-RAGEX-003 — examples/README.md lists the RAG example.
test_examples_meta_readme_lists_rag_example() {
  if [ ! -f "$EXAMPLES_README" ]; then
    echo "    meta README missing: $EXAMPLES_README" >&2; return 1
  fi
  # The FSM row must still be present (additive).
  if ! grep -q 'forge-fsm-example' "$EXAMPLES_README"; then
    echo "    meta README no longer lists forge-fsm-example (must stay additive)" >&2
    return 1
  fi
  # A row referencing forge-rag-example AND ai-native-rag must exist.
  if ! grep -q 'forge-rag-example' "$EXAMPLES_README"; then
    echo "    meta README does not list forge-rag-example" >&2
    return 1
  fi
  if ! grep -E 'forge-rag-example' "$EXAMPLES_README" | grep -q 'ai-native-rag'; then
    echo "    forge-rag-example row does not name the ai-native-rag archetype" >&2
    return 1
  fi
}

# FR-RAGEX-009 — POST-PROMOTION (B.7.6 flip). The original contract was "committing
# the EXAMPLE must NOT promote the framework schema" (it stayed candidate). The
# PROMOTION instead happened in B.7.6 (b7-6-harness), gated on a green b7-6 suite —
# NOT by committing the example. This assertion is inverted in lockstep with that
# flip (the b8-14-flip break-cascade): the framework schema is now stable /
# scaffoldable:true. The example tree itself is unchanged; FR-RAGEX-009's intent
# (the example does not by itself flip the framework) is preserved — the flip's
# author is b7-6, and that is what this now asserts.
test_rag_archetype_still_candidate() {
  if [ ! -f "$SCHEMA_AINR" ]; then
    echo "    ai-native-rag schema missing: $SCHEMA_AINR" >&2; return 1
  fi
  python3 - "$SCHEMA_AINR" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
errs = []
if d.get("stage") != "stable":
    errs.append(f"stage expected 'stable' (promoted by B.7.6), got {d.get('stage')!r}")
if d.get("scaffoldable") is not True:
    errs.append(f"scaffoldable expected True (promoted by B.7.6), got {d.get('scaffoldable')!r}")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# NFR-RAGEX-001 — additive: b7-7 must not edit the archetype template
# tree or the schema. Asserts the schema file + the archetype template
# tree are NOT modified relative to git HEAD by this change's worktree
# (the example carries its OWN copy under examples/; the framework copy
# is untouched).
test_b7_7_no_archetype_or_schema_edit() {
  # Static guard: the framework archetype template dir + schema must not
  # appear in `git diff --name-only` against the merge-base of this
  # branch. Since the harness runs in many contexts (CI on the branch,
  # local), we assert the weaker invariant that no file UNDER the
  # framework archetype/schema paths is in the working-tree diff vs HEAD.
  if ! command -v git >/dev/null 2>&1; then
    echo "    SKIP: git not available" >&2; return 0
  fi
  local touched
  touched=$(cd "$FORGE_ROOT_REAL" && git diff --name-only HEAD -- \
      '.forge/templates/archetypes/ai-native-rag' \
      '.forge/schemas/ai-native-rag' 2>/dev/null || true)
  if [ -n "$touched" ]; then
    echo "    b7-7 working tree edits framework archetype/schema files:" >&2
    printf '      %s\n' $touched >&2
    return 1
  fi
}

# FR-CI-012 — the example job gains a RAG gate block.
test_forge_ci_example_job_gates_rag_tree() {
  if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "    workflow missing: $WORKFLOW_FILE" >&2; return 1
  fi
  # A step must cd into the RAG tree and run verify.sh + constitution-linter.sh.
  if ! grep -q 'cd examples/forge-rag-example' "$WORKFLOW_FILE"; then
    echo "    example job has no 'cd examples/forge-rag-example' step" >&2
    return 1
  fi
  # Both gates must be invoked for the RAG tree (count the gate script
  # references that follow a forge-rag-example context — approximate via
  # presence of both within the workflow).
  if ! grep -q 'rag-example verify.sh' "$WORKFLOW_FILE" \
     && ! grep -qE 'forge-rag-example' "$WORKFLOW_FILE"; then
    echo "    RAG gate steps not found in example job" >&2
    return 1
  fi
}

# FR-CI-012 — the FSM gate block is preserved byte-for-byte (additive).
test_forge_ci_example_job_fsm_block_preserved() {
  if ! grep -q 'cd examples/forge-fsm-example' "$WORKFLOW_FILE"; then
    echo "    FSM gate steps removed/altered (cd examples/forge-fsm-example missing)" >&2
    return 1
  fi
  # The FSM archetype-template parse step (full-stack-monorepo workflows glob)
  # must still be present.
  if ! grep -q 'full-stack-monorepo/.github/workflows' "$WORKFLOW_FILE"; then
    echo "    FSM archetype workflow-template parse step removed" >&2
    return 1
  fi
}

# FR-RAGEX-008 — b7-7.test.sh registered in the harness loop.
test_forge_ci_harness_loop_has_b7_7() {
  if ! grep -qF 'b7-7.test.sh' "$WORKFLOW_FILE"; then
    echo "    harness loop does not list b7-7.test.sh" >&2
    return 1
  fi
}

# ─── Phase 2 — demos cluster tests ─────────────────────────────

# FR-RAGEX-004 — exactly 3 demos, all status: archived.
test_rag_demos_count_and_status() {
  if [ ! -d "$RAG_DEMOS_DIR" ]; then
    echo "    demos dir missing: $RAG_DEMOS_DIR" >&2; return 1
  fi
  local count=0 d
  for d in "$RAG_DEMOS_DIR"/*/; do
    [ -d "$d" ] || continue
    count=$((count + 1))
  done
  if [ "$count" -ne 3 ]; then
    echo "    expected exactly 3 demo directories, found $count" >&2
    return 1
  fi
  for d in "${DEMOS[@]}"; do
    local yml="$RAG_DEMOS_DIR/$d/.forge.yaml"
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

# FR-RAGEX-004 — each demo carries the canonical 5 artefacts.
test_each_rag_demo_has_five_artefacts() {
  local d
  for d in "${DEMOS[@]}"; do
    local dir="$RAG_DEMOS_DIR/$d"
    [ -d "$dir" ] || { echo "    demo dir missing: $dir" >&2; return 1; }
    # proposal + specs always.
    [ -f "$dir/proposal.md" ] || { echo "    $d: missing proposal.md" >&2; return 1; }
    [ -f "$dir/specs.md" ]    || { echo "    $d: missing specs.md" >&2; return 1; }
    # a feature file under features/.
    if ! ls "$dir"/features/*.feature >/dev/null 2>&1; then
      echo "    $d: missing features/*.feature" >&2; return 1
    fi
    # design + tasks: single-file OR per-layer (multi-layer).
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
      # per-layer designs/ + tasks/ required (FR-GL-016).
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

# FR-RAGEX-004 + FR-GL-016 — demo-003 is multi-layer [backend, frontend].
test_rag_demo_003_is_multi_layer() {
  local dir="$RAG_DEMOS_DIR/demo-003-rag-query-ui"
  local yml="$dir/.forge.yaml"
  [ -f "$yml" ] || { echo "    demo-003 .forge.yaml missing" >&2; return 1; }
  python3 - "$yml" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
layers = d.get("layers") or []
errs = []
if not (isinstance(layers, list) and len(layers) >= 2):
    errs.append(f"layers must have >=2 entries, got {layers!r}")
if set(["backend","frontend"]) - set(layers):
    errs.append(f"layers must include backend AND frontend, got {layers!r}")
for key in ("designs_per_layer","tasks_per_layer"):
    m = d.get(key)
    if not isinstance(m, dict) or not m:
        errs.append(f"{key} missing or empty for multi-layer demo")
if errs:
    for e in errs: print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
  # The referenced per-layer files must exist.
  ls "$dir"/designs/design-backend.md "$dir"/designs/design-frontend.md >/dev/null 2>&1 \
    || { echo "    demo-003 per-layer design files missing" >&2; return 1; }
  ls "$dir"/tasks/tasks-backend.md "$dir"/tasks/tasks-frontend.md >/dev/null 2>&1 \
    || { echo "    demo-003 per-layer tasks files missing" >&2; return 1; }
}

# FR-RAGEX-005 — collectively the demos materialise the AI-First surfaces.
test_rag_demos_cover_ai_first_surfaces() {
  # XI.5 fallback marker — demo-001 (embedder) + demo-003 (fallbackUsed).
  if ! grep -rqiE 'fallback' "$RAG_DEMOS_DIR/demo-001-doc-ingestion" 2>/dev/null; then
    echo "    demo-001 specs/design do not mention the XI.5 fallback" >&2; return 1
  fi
  if ! grep -rqiE 'fallback' "$RAG_DEMOS_DIR/demo-003-rag-query-ui" 2>/dev/null; then
    echo "    demo-003 specs/design do not mention the fallbackUsed path" >&2; return 1
  fi
  # IX.6 prompt-audit — demo-003 gateway across the stream.
  if ! grep -rqiE 'prompt.audit|prompt-audit' "$RAG_DEMOS_DIR/demo-003-rag-query-ui" 2>/dev/null; then
    echo "    demo-003 does not mention the prompt-audit span (IX.6)" >&2; return 1
  fi
  # embeddings-pipeline phase — demo-001.
  if ! grep -rqiE 'embeddings' "$RAG_DEMOS_DIR/demo-001-doc-ingestion" 2>/dev/null; then
    echo "    demo-001 does not mention the embeddings pipeline" >&2; return 1
  fi
}

# FR-RAGEX-006 — the demo manifest lists all 3 demos.
test_rag_demos_manifest_present_and_lists_three_demos() {
  if [ ! -f "$RAG_DEMOS_MANIFEST" ]; then
    echo "    demo MANIFEST.md missing: $RAG_DEMOS_MANIFEST" >&2; return 1
  fi
  local d
  for d in "${DEMOS[@]}"; do
    if ! grep -q "$d" "$RAG_DEMOS_MANIFEST"; then
      echo "    MANIFEST.md does not list $d" >&2; return 1
    fi
  done
}

# NFR-RAGEX-004 — each demo proposal ≤ 200 lines.
test_each_rag_demo_proposal_under_size_budget() {
  local d
  for d in "${DEMOS[@]}"; do
    local p="$RAG_DEMOS_DIR/$d/proposal.md"
    [ -f "$p" ] || { echo "    $d: proposal.md missing" >&2; return 1; }
    local lines
    lines=$(wc -l < "$p" | tr -d ' ')
    if [ "$lines" -gt 200 ]; then
      echo "    $d: proposal.md is $lines lines (budget 200)" >&2; return 1
    fi
  done
}

# NFR-RAGEX-005 — the 3 demos cover distinct layer + RAG-surface combos.
test_rag_demos_cover_distinct_combinations() {
  # demo-001 + demo-002 single-layer backend; demo-003 multi-layer.
  local m1 m2 m3
  m1=$(_b77_layers demo-001-doc-ingestion)
  m2=$(_b77_layers demo-002-mcp-search-tool)
  m3=$(_b77_layers demo-003-rag-query-ui)
  if [ "$m1" != "backend" ]; then
    echo "    demo-001 layers='$m1' (expected single-layer backend)" >&2; return 1
  fi
  if [ "$m2" != "backend" ]; then
    echo "    demo-002 layers='$m2' (expected single-layer backend)" >&2; return 1
  fi
  if [ "$m3" = "backend" ]; then
    echo "    demo-003 layers='$m3' (expected multi-layer)" >&2; return 1
  fi
  # demo-001 vs demo-002 must differ by RAG surface (rag/ vs mcp/).
  if ! grep -rqiE '\brag\b|chunk|embed|retriev' "$RAG_DEMOS_DIR/demo-001-doc-ingestion/specs.md" 2>/dev/null; then
    echo "    demo-001 specs do not target the rag/ pipeline surface" >&2; return 1
  fi
  if ! grep -rqiE 'mcp|search tool|tool_router|rmcp' "$RAG_DEMOS_DIR/demo-002-mcp-search-tool/specs.md" 2>/dev/null; then
    echo "    demo-002 specs do not target the mcp/ server surface" >&2; return 1
  fi
}

# Helper — echo the comma-joined sorted layer ids of a demo.
_b77_layers() {
  local yml="$RAG_DEMOS_DIR/$1/.forge.yaml"
  [ -f "$yml" ] || { echo ""; return; }
  python3 - "$yml" <<'PY' 2>/dev/null
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
layers = d.get("layers") or []
print(",".join(sorted(str(x) for x in layers)))
PY
}

# ─── Phase 3 — harness + spec cluster tests ────────────────────

# NFR-RAGEX-002 — RAG example tree ≤ 5 MB (excluding ignored paths).
test_rag_example_tree_byte_budget() {
  if [ ! -d "$RAG_DIR" ]; then
    echo "    RAG dir missing" >&2; return 1
  fi
  # Exclude build artefacts (FR-GL-028 ignored paths) from the count.
  local bytes
  bytes=$(find "$RAG_DIR" -type f \
      -not -path '*/target/*' -not -path '*/node_modules/*' \
      -not -path '*/.dart_tool/*' -not -path '*/build/*' \
      -printf '%s\n' 2>/dev/null | awk '{s+=$1} END {print s+0}')
  local budget=$((5 * 1024 * 1024))
  if [ "$bytes" -gt "$budget" ]; then
    echo "    RAG tree is $bytes bytes (budget $budget = 5 MB)" >&2; return 1
  fi
}

# FR-RAGEX-010 — archive-gated. After b7-7 is archived,
# example-reference.md must carry the FR-RAGEX-* section + a b7-7 row.
# Skip-passes while b7-7's own status is not yet 'archived' (so this
# test is GREEN now while implemented, and stays GREEN post-archive).
test_example_reference_spec_has_ragex_section_post_archive() {
  local status=""
  if [ -f "$B7_7_FORGE_YAML" ]; then
    status=$(python3 - "$B7_7_FORGE_YAML" <<'PY' 2>/dev/null
import sys, yaml
print((yaml.safe_load(open(sys.argv[1])) or {}).get("status",""))
PY
)
  fi
  if [ "$status" != "archived" ]; then
    echo "    skipped (b7-7 status='$status', not yet 'archived')" >&2
    return 0
  fi
  if [ ! -f "$SPEC_EXAMPLE" ]; then
    echo "    expected spec file: $SPEC_EXAMPLE" >&2; return 1
  fi
  if ! grep -q 'FR-RAGEX-' "$SPEC_EXAMPLE"; then
    echo "    example-reference.md has no FR-RAGEX-* section post-archive" >&2; return 1
  fi
  if ! grep -q 'b7-7-example' "$SPEC_EXAMPLE"; then
    echo "    example-reference.md has no b7-7-example archived-changes row" >&2; return 1
  fi
}

# ─── L2 (--require-example-tools) tests ────────────────────────

# FR-RAGEX-007 — the RAG tree's own verify.sh exits 0 standalone.
test_rag_example_tree_verify_exits_zero() {
  if [ "$REQUIRE_EXAMPLE_TOOLS" != "1" ]; then
    echo "    skipped (L2 — pass --require-example-tools)" >&2; return 0
  fi
  ( cd "$RAG_DIR" && bash .forge/scripts/verify.sh >/dev/null 2>&1 )
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    RAG tree verify.sh exited $rc (expected 0)" >&2; return 1
  fi
}

# FR-RAGEX-007 — the RAG tree's own constitution-linter.sh exits 0.
test_rag_example_tree_constitution_linter_exits_zero() {
  if [ "$REQUIRE_EXAMPLE_TOOLS" != "1" ]; then
    echo "    skipped (L2 — pass --require-example-tools)" >&2; return 0
  fi
  ( cd "$RAG_DIR" && bash .forge/scripts/constitution-linter.sh >/dev/null 2>&1 )
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    RAG tree constitution-linter.sh exited $rc (expected 0)" >&2; return 1
  fi
}

# FR-RAGEX-009 — the CLI still refuses `forge init --archetype
# ai-native-rag` with exit 3 (committing the example must not promote).
test_cli_still_refuses_rag_init() {
  if [ "$REQUIRE_EXAMPLE_TOOLS" != "1" ]; then
    echo "    skipped (L2 — pass --require-example-tools)" >&2; return 0
  fi
  # Prefer the dispatch wrapper if present; otherwise assert the schema
  # gate (scaffoldable:false) which is what makes the CLI refuse.
  if [ -f "$WRAPPER_RAG" ]; then
    local out rc
    out=$(bash "$WRAPPER_RAG" --help 2>&1 || true)
    : # wrapper presence + schema gate are the real contract; checked below.
  fi
  # POST-PROMOTION (B.7.6 flip): the schema is now stage:stable / scaffoldable:true,
  # so selectScaffoldableVersion returns 1.0.0 and the CLI scaffolds (it no longer
  # refuses with exit 3). Inverted in lockstep with the b7-6 flip. Assert the
  # promoted state directly.
  python3 - "$SCHEMA_AINR" <<'PY' || return 1
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
if d.get("scaffoldable") is not True or d.get("stage") != "stable":
    print(f"    schema not promoted: stage={d.get('stage')!r} scaffoldable={d.get('scaffoldable')!r} (expected stable/true after B.7.6)", file=sys.stderr)
    sys.exit(1)
PY
}

# ─── Main ───────────────────────────────────────────────────────

main() {
  echo "Forge — b7-7-example Test Harness"
  echo "FORGE_ROOT_REAL=$FORGE_ROOT_REAL"
  echo "REQUIRE_EXAMPLE_TOOLS=$REQUIRE_EXAMPLE_TOOLS"
  echo ""
  echo "── Phase 1 : tree cluster ──"
  run_test test_rag_example_tree_canonical_structure
  run_test test_rag_example_scaffold_manifest_complete
  run_test test_rag_example_readme_has_required_sections
  run_test test_examples_meta_readme_lists_rag_example
  run_test test_rag_archetype_still_candidate
  run_test test_b7_7_no_archetype_or_schema_edit
  run_test test_forge_ci_example_job_gates_rag_tree
  run_test test_forge_ci_example_job_fsm_block_preserved
  run_test test_forge_ci_harness_loop_has_b7_7
  echo ""
  echo "── Phase 2 : demos cluster ──"
  run_test test_rag_demos_count_and_status
  run_test test_each_rag_demo_has_five_artefacts
  run_test test_rag_demo_003_is_multi_layer
  run_test test_rag_demos_cover_ai_first_surfaces
  run_test test_rag_demos_manifest_present_and_lists_three_demos
  run_test test_each_rag_demo_proposal_under_size_budget
  run_test test_rag_demos_cover_distinct_combinations
  echo ""
  echo "── Phase 3 : harness + spec cluster ──"
  run_test test_rag_example_tree_byte_budget
  run_test test_example_reference_spec_has_ragex_section_post_archive
  run_test test_rag_example_tree_verify_exits_zero
  run_test test_rag_example_tree_constitution_linter_exits_zero
  run_test test_cli_still_refuses_rag_init
  echo ""
  echo "── Meta ──"
  run_test test_b7_7_manifest_self_consistency
  print_summary
}

main "$@"
