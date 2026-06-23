#!/usr/bin/env bash
# Forge — B.7.2 ai-native-rag scaffolder backbone harness (SKELETON, Phase 0)
# <!-- Audit: B.7.2 (b7-2-scaffolder) — templates + backbone + verify-then-pin -->
#
# TDD contract for the ai-native-rag/1.0.0 scaffold backbone. The full backbone
# (templates + backend + frontend/infra + gated wrapper) has landed GREEN across
# Phases 1-4; this harness is REGISTERED in .github/workflows/forge-ci.yml
# (`b7-2.test.sh --level 1`, after b7-3 — Phase 5). L1 is the CI level (matching
# b7-3); the CI harness job ships python+node but no rust toolchain, so the L2
# cargo-check leg would only skip there — L2 stays a local/opt-in level and the
# comprehensive promotion suite is b7-6's job.
#
#   L1 (hermetic, grep/structure):
#     T-001  template layer-root tree exists (FR-B7-2-001)                 [GREEN P1]
#     T-002  scaffold-plan exists + references only existing tree files     [GREEN P1]
#     T-003  verify-then-pin research file records all 4 pins (FR-B7-2-040) [GREEN P0]
#     T-004  pins live only in Cargo.toml.tmpl, none in standards (FR-...041)[GREEN]
#     T-005  scaffolder wrapper exists + executable (FR-B7-2-050)           [GREEN]
#     T-006  wrapper refuses exit 3 + zero writes while candidate (FR-...051)[GREEN P4]
#     T-007  standards-conformance grep: rag/llm_gateway/mcp markers (FR-...060)[GREEN review]
#   L2 (toolchain-gated, skip when absent):
#     T-L2-001 render plan via overlay.sh → no .tmpl / no {{placeholder}}   (FR-B7-2-003)
#     T-L2-002 cargo check rendered backend workspace (default features)    (FR-B7-2-010)
#     T-L2-003 wrapper render path works end-to-end (gated override)        (FR-B7-2-050)
#
# Comprehensive ≥35-test promotion suite + snapshot tarball: b7-6-harness.

set -uo pipefail

LEVEL="1"
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  case "$arg" in --level=*) LEVEL="${arg#*=}" ;; esac
  prev="$arg"
done

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT="$(cd "$SCRIPTS_DIR/../.." && pwd)"

ARCHETYPE_DIR="$FORGE_ROOT/.forge/templates/archetypes/ai-native-rag"
TPL_DIR="$ARCHETYPE_DIR/1.0.0"
PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"
OVERLAY_SH="$FORGE_ROOT/.forge/scripts/scaffolder/overlay.sh"
WRAPPER="$FORGE_ROOT/bin/forge-init-ai-native-rag.sh"
SCHEMA_AINR="$FORGE_ROOT/.forge/schemas/ai-native-rag/1.0.0.yaml"
RESEARCH="$FORGE_ROOT/.forge/research/b7-2-verify-then-pin.md"
STD_DIR="$FORGE_ROOT/.forge/standards/global"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

_test_b72_l1_001_tree_roots() {
  local ok=1
  for d in "backend" "frontend/web-public" "infra" "shared/protos"; do
    [ -d "$TPL_DIR/$d" ] || { echo "    FAIL T-001: missing template layer root $TPL_DIR/$d (FR-B7-2-001)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b72_l1_002_plan_coverage() {
  [ -f "$PLAN" ] || { echo "    FAIL T-002: scaffold-plan missing: $PLAN (FR-B7-2-002)" >&2; return 1; }
  # Every .tmpl in the tree must be referenced by the plan (no orphan); and the
  # plan must not reference a file absent from the tree (no dangling).
  local ok=1
  while IFS= read -r f; do
    rel="${f#"$TPL_DIR/"}"
    grep -qF "$rel" "$PLAN" || { echo "    FAIL T-002: tree file not in plan: $rel (FR-B7-2-002)" >&2; ok=0; }
  done < <(find "$TPL_DIR" -type f -name '*.tmpl' 2>/dev/null)
  [ "$ok" = "1" ]
}

_test_b72_l1_003_verify_then_pin_recorded() {
  [ -f "$RESEARCH" ] || { echo "    FAIL T-003: verify-then-pin research file missing: $RESEARCH (FR-B7-2-040)" >&2; return 1; }
  local ok=1
  for crate in "rmcp" "pgvector" "async-openai" "fastembed"; do
    grep -qE "\`?${crate}[\`]? *= *\"[0-9]" "$RESEARCH" || { echo "    FAIL T-003: research file missing LIVE pin for '$crate' (FR-B7-2-040)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b72_l1_004_pins_only_in_cargo() {
  local ok=1
  # No version pin inside the B.7.3 standards (mirrors b7-3 T-007; FR-B7-2-041).
  for f in "$STD_DIR/rag-patterns.md" "$STD_DIR/llm-gateway.md" "$STD_DIR/mcp-servers.md"; do
    [ -f "$f" ] || continue
    hits=$(grep -nE '(rmcp|pgvector|async-openai|fastembed)[[:space:]]*=[[:space:]]*"[0-9]' "$f" 2>/dev/null || true)
    [ -z "$hits" ] || { echo "    FAIL T-004: $(basename "$f") inlines a pin (FR-B7-2-041): $hits" >&2; ok=0; }
  done
  # Once the tree exists, pins MUST appear in a Cargo.toml.tmpl (asserted from P2 on).
  if [ -d "$TPL_DIR/backend" ]; then
    grep -rqE '(rmcp|pgvector|async-openai|fastembed)[[:space:]]*=' "$TPL_DIR/backend" \
      || { echo "    FAIL T-004: no crate pin found in backend Cargo.toml.tmpl (FR-B7-2-041)" >&2; ok=0; }
  fi
  [ "$ok" = "1" ]
}

_test_b72_l1_005_wrapper_present() {
  [ -f "$WRAPPER" ] || { echo "    FAIL T-005: scaffolder wrapper missing: $WRAPPER (FR-B7-2-050)" >&2; return 1; }
  [ -x "$WRAPPER" ] || { echo "    FAIL T-005: wrapper not executable (FR-B7-2-050)" >&2; return 1; }
  head -1 "$WRAPPER" | grep -qE '^#!.*(bash|sh)' || { echo "    FAIL T-005: wrapper missing shebang (FR-B7-2-050)" >&2; return 1; }
}

# T-006 — POST-PROMOTION (B.7.6 flip). The 1.0.0 schema is now stage:stable /
# scaffoldable:true, so the wrapper's scaffoldability gate (is_scaffoldable, reading
# the schema) is OPEN and the wrapper NO LONGER refuses. This test (inverted from
# the pre-flip exit-3 refusal contract by b7-6-harness; FR-B7-2-051 → promoted)
# positively requires the promoted state: the schema is no longer candidate, and the
# wrapper given valid ABI args does NOT exit 3 (the candidate refusal). A bad-args
# probe (no flags) still exits 2 (arg error), never the candidate exit-3.
_test_b72_l1_006_wrapper_refuses_while_candidate() {
  [ -f "$WRAPPER" ] || { echo "    FAIL T-006: wrapper missing (FR-B7-2-051)" >&2; return 1; }
  local ok=1
  # Promoted-state precondition: schema is stable + scaffoldable:true.
  grep -qE '^\s*stage:\s*stable' "$SCHEMA_AINR" 2>/dev/null \
    || { echo "    FAIL T-006: schema stage != stable (expected promoted by B.7.6) (FR-B7-2-051)" >&2; ok=0; }
  grep -qE '^\s*scaffoldable:\s*true' "$SCHEMA_AINR" 2>/dev/null \
    || { echo "    FAIL T-006: schema scaffoldable != true (expected promoted by B.7.6) (FR-B7-2-051)" >&2; ok=0; }
  # The wrapper no longer refuses (exit 3) on the candidate gate. A no-args probe
  # now reaches arg-parsing and exits 2 (missing --target), NOT the candidate 3.
  local rc=0
  bash "$WRAPPER" >/dev/null 2>&1 || rc=$?
  [ "$rc" != "3" ] || { echo "    FAIL T-006: wrapper still exits 3 (candidate refusal) AFTER the B.7.6 promotion (FR-B7-2-051)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-007 — standards-conformance grep (FR-B7-2-060, specs.md §Harness). POSITIVE
# assertion (complements the negative no-inline-pin guard T-004) that the
# scaffolded backend templates carry the markers proving conformance to the three
# B.7.3 pattern standards. Hermetic — greps the `.tmpl` tree, no toolchain:
#   rag-patterns.md   → rag/ : RRF + coarse→exact rerank + HNSW vector_cosine_ops
#   llm-gateway.md    → llm_gateway/ : prompt-audit span + PII redaction + non-AI fallback
#   mcp-servers.md    → mcp/ : tool_router + schemars input validation + StreamableHttp + rmcp auth
_test_b72_l1_007_standards_conformance() {
  local be="$TPL_DIR/backend"
  [ -d "$be" ] || { echo "    FAIL T-007: backend template tree missing (FR-B7-2-060)" >&2; return 1; }
  local ok=1
  # marker <regex> <dir> <standard> <human-label>
  _conf() {
    grep -rqE "$1" "$2" 2>/dev/null || { echo "    FAIL T-007: $4 marker absent under ${2#"$TPL_DIR/"} ($3)" >&2; ok=0; }
  }
  # rag-patterns.md
  _conf 'reciprocal_rank_fusion|\bRRF\b' "$be/rag" "rag-patterns.md" "hybrid-retrieval RRF"
  _conf 'rerank_exact|coarse.+exact|exact re-?rank' "$be/rag" "rag-patterns.md" "coarse→exact rerank"
  _conf 'vector_cosine_ops' "$be/rag" "rag-patterns.md" "pgvector HNSW vector_cosine_ops"
  # llm-gateway.md
  _conf 'prompt.?audit|PromptAudit' "$be/llm_gateway" "llm-gateway.md" "prompt-audit span (IX.6)"
  _conf 'redact_pii' "$be/llm_gateway" "llm-gateway.md" "PII redaction (XI.6)"
  _conf 'non_ai_fallback|FallbackReason' "$be/llm_gateway" "llm-gateway.md" "non-AI fallback (XI.5)"
  # mcp-servers.md
  _conf 'tool_router' "$be/mcp" "mcp-servers.md" "rmcp tool_router"
  _conf 'schemars|JsonSchema' "$be/mcp" "mcp-servers.md" "schemars input validation"
  _conf 'StreamableHttp' "$be/mcp" "mcp-servers.md" "streamable-HTTP transport"
  # OAuth 2.1 conformance is documented in the mcp transport; the enabling `auth`
  # rmcp feature lives in the workspace pin-ledger (ADR-B7-2-003), not the crate.
  _conf 'OAuth|auth' "$be/mcp" "mcp-servers.md" "OAuth 2.1 / rmcp auth (mcp transport)"
  _conf 'rmcp.*auth' "$be/Cargo.toml.tmpl" "mcp-servers.md" "rmcp auth feature (workspace pin)"
  [ "$ok" = "1" ]
}

# ── L2 (toolchain-gated) ──────────────────────────────────────────
#
# Rendering goes through overlay.sh — the pure-python renderer that init.sh
# delegates the actual .tmpl-stripping + placeholder substitution to. This is
# the repo-wide convention for hermetic L2 render tests (cf. b8-14-flip.test.sh
# `_test_b814f_004_overlay_renders_kongless`, scaffolder.test.sh L2). init.sh is
# NOT usable here: it is hardcoded to the full-stack-monorepo archetype (it runs
# `flutter create`, five fixed `cargo new`s, `buf lint`, and validate-foundations)
# and so cannot render a second archetype's plan. overlay.sh hardcodes its
# ARCHETYPE_DIR to full-stack-monorepo too, so the harness absolutizes the
# plan's relative `source:` paths (rooted at the ai-native-rag archetype dir)
# into a throwaway temp plan — the committed plan stays portable. No toolchain
# (flutter/cargo/buf) is required for the render itself.

# Render the committed scaffold-plan into $1 via overlay.sh, absolutizing the
# plan's relative `source:` paths first. Shared by T-L2-001 (render-clean) and
# T-L2-002 (cargo check). Returns non-zero on render failure.
_b72_render_plan() {
  local out_dir="$1"
  local absplan; absplan="$(mktemp)"
  ARCHETYPE_DIR="$ARCHETYPE_DIR" PLAN="$PLAN" ABSPLAN="$absplan" python3 - <<'PY' || { rm -f "$absplan"; return 1; }
import os, yaml
arch = os.environ['ARCHETYPE_DIR']
with open(os.environ['PLAN']) as f:
    plan = yaml.safe_load(f)
for e in plan.get('templates', []):
    s = e.get('source', '')
    if s and not os.path.isabs(s):
        e['source'] = os.path.join(arch, s)
with open(os.environ['ABSPLAN'], 'w') as f:
    yaml.safe_dump(plan, f, sort_keys=False)
PY
  SOURCE_DATE_EPOCH=0 bash "$OVERLAY_SH" --target "$out_dir" --project-name probe \
    --reverse-domain example.com --plan "$absplan" --force >/dev/null 2>&1
  local rc=$?
  rm -f "$absplan"
  return $rc
}

# T-L2-001 — render the scaffold-plan and assert the produced tree carries no
# `.tmpl` suffix and no unsubstituted {{placeholder}} (FR-B7-2-003), then
# re-render and byte-diff for determinism (NFR-B7-2-004).
_test_b72_l2_001_render_clean() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-001: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-L2-001: python3 PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-L2-001: plan not yet authored (Phase 1)" >&2; return 0; }
  [ -f "$OVERLAY_SH" ] || { echo "    SKIP T-L2-001: overlay.sh absent" >&2; return 0; }

  local work; work="$(mktemp -d)"
  local out1="$work/render1"
  local out2="$work/render2"

  _b72_render_plan "$out1" || {
    echo "    FAIL T-L2-001: overlay.sh render failed (FR-B7-2-003)" >&2; rm -rf "$work"; return 1; }

  local ok=1
  [ -z "$(find "$out1" -name '*.tmpl' 2>/dev/null)" ] || { echo "    FAIL T-L2-001: .tmpl suffix survived render (FR-B7-2-003)" >&2; ok=0; }
  ! grep -rqE '\{\{[a-zA-Z_]+\}\}' "$out1" 2>/dev/null || { echo "    FAIL T-L2-001: unsubstituted {{placeholder}} (FR-B7-2-003)" >&2; ok=0; }

  # Determinism (NFR-B7-2-004): re-render into a fresh target and byte-diff.
  # `_b72_render_plan` pins SOURCE_DATE_EPOCH=0 so the manifest timestamp (the
  # only volatile field) is neutralised; the rendered file tree must otherwise
  # be identical between the two renders.
  _b72_render_plan "$out2" || { echo "    FAIL T-L2-001: second render failed (NFR-B7-2-004)" >&2; rm -rf "$work"; return 1; }
  if ! diff -r "$out1" "$out2" >/dev/null 2>&1; then
    echo "    FAIL T-L2-001: re-render not byte-stable (NFR-B7-2-004)" >&2; ok=0
  fi

  rm -rf "$work"
  [ "$ok" = "1" ]
}

# T-L2-002 — render the plan, then `cargo check` the rendered backend workspace
# with DEFAULT features (FR-B7-2-010). Default features are deliberately
# hermetic: the heavy `local-embeddings` (fastembed → ONNX Runtime) path is
# OFF by default, so this needs only the crates.io registry, no system ONNX.
# Skips gracefully when cargo / python3 / network-fetched deps are unavailable.
_test_b72_l2_002_cargo_check() {
  command -v cargo >/dev/null 2>&1 || { echo "    SKIP T-L2-002: cargo absent" >&2; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-002: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-L2-002: python3 PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-L2-002: plan not yet authored" >&2; return 0; }
  [ -d "$TPL_DIR/backend" ] || { echo "    SKIP T-L2-002: backend tree not yet built" >&2; return 0; }
  [ -f "$OVERLAY_SH" ] || { echo "    SKIP T-L2-002: overlay.sh absent" >&2; return 0; }

  local work; work="$(mktemp -d)"
  local out="$work/render"
  _b72_render_plan "$out" || { echo "    FAIL T-L2-002: render failed (FR-B7-2-010)" >&2; rm -rf "$work"; return 1; }

  # `cargo check` (default features) on the rendered backend workspace. Allow an
  # offline/registry-unavailable environment to skip rather than fail (the
  # render itself already passed; this leg specifically asserts the rendered
  # Rust compiles given dependency access).
  local log="$work/cargo.log"
  if ! ( cd "$out/backend" && cargo check --workspace ) >"$log" 2>&1; then
    if grep -qiE 'failed to (download|get|fetch|load source)|no matching package|could not (connect|resolve)|network|offline' "$log"; then
      echo "    SKIP T-L2-002: cargo check skipped — crate registry unavailable (offline)" >&2
      rm -rf "$work"; return 0
    fi
    echo "    FAIL T-L2-002: cargo check failed on rendered backend (FR-B7-2-010)" >&2
    tail -20 "$log" >&2
    rm -rf "$work"; return 1
  fi
  rm -rf "$work"
  return 0
}

# T-L2-003 — the wrapper's REAL render path works end-to-end. The default
# canonical state is refuse (T-006); this gated test sets the harness-only
# override (FORGE_AINR_FORCE_SCAFFOLD=1) to open the scaffoldability gate and
# asserts the wrapper renders a clean tree via overlay.sh (FR-B7-2-050) — proving
# the body that auto-activates at b7-6 promotion is correct, without flipping the
# schema. No toolchain needed (pure overlay render).
_test_b72_l2_003_wrapper_render_path() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-003: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-L2-003: python3 PyYAML absent" >&2; return 0; }
  [ -f "$WRAPPER" ] || { echo "    SKIP T-L2-003: wrapper absent" >&2; return 0; }
  [ -f "$OVERLAY_SH" ] || { echo "    SKIP T-L2-003: overlay.sh absent" >&2; return 0; }

  local out; out="$(mktemp -d)"; local tgt="$out/proj"
  local rc=0
  FORGE_AINR_FORCE_SCAFFOLD=1 bash "$WRAPPER" \
    --target "$tgt" --project-name probe --reverse-domain example.com --force \
    >/dev/null 2>"$out/err" || rc=$?
  local ok=1
  [ "$rc" = "0" ] || { echo "    FAIL T-L2-003: wrapper render exit $rc, expected 0 (FR-B7-2-050)" >&2; tail -5 "$out/err" >&2; ok=0; }
  [ -d "$tgt/backend" ] && [ -d "$tgt/frontend/web-public" ] && [ -d "$tgt/infra" ] \
    || { echo "    FAIL T-L2-003: wrapper render missing layer roots (FR-B7-2-050)" >&2; ok=0; }
  [ -z "$(find "$tgt" -name '*.tmpl' 2>/dev/null)" ] || { echo "    FAIL T-L2-003: .tmpl survived wrapper render" >&2; ok=0; }
  ! grep -rqE '\{\{[a-zA-Z_]+\}\}' "$tgt" 2>/dev/null || { echo "    FAIL T-L2-003: unsubstituted {{placeholder}} after wrapper render" >&2; ok=0; }
  rm -rf "$out"
  [ "$ok" = "1" ]
}

main() {
  echo "── B.7.2 — b7-2-scaffolder — level $LEVEL ──"
  run_test _test_b72_l1_001_tree_roots
  run_test _test_b72_l1_002_plan_coverage
  run_test _test_b72_l1_003_verify_then_pin_recorded
  run_test _test_b72_l1_004_pins_only_in_cargo
  run_test _test_b72_l1_005_wrapper_present
  run_test _test_b72_l1_006_wrapper_refuses_while_candidate
  run_test _test_b72_l1_007_standards_conformance
  case "$LEVEL" in
    *2*)
      run_test _test_b72_l2_001_render_clean
      run_test _test_b72_l2_002_cargo_check
      run_test _test_b72_l2_003_wrapper_render_path
      ;;
  esac
  print_summary
}

main
