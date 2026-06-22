#!/usr/bin/env bash
# Forge — `forge init --archetype ai-native-rag` wrapper
# <!-- Audit: B.7.2 (b7-2-scaffolder, Phase 4) — gated real scaffolder body -->
#
# GATED REAL BODY (ADR-B7-2-007). The ai-native-rag archetype is declared
# (`.forge/scaffolding/dispatch-table.yml`) and its 1.0.0 schema is currently
# `stage: candidate` / `scaffoldable: false` (`.forge/schemas/ai-native-rag/
# 1.0.0.yaml`, B.7.1). The CLI versioned-schema layer (resolveScaffolder) refuses
# `forge init --archetype ai-native-rag` with exit 3 BEFORE this wrapper is ever
# invoked while the schema is a candidate.
#
# This wrapper is the wrapper-side scaffolder. It is a *gated* real body:
#   - It reads the schema's `stage`/`scaffoldable` itself (the scaffoldability
#     gate below). While candidate/scaffoldable:false it REFUSES — exit 3,
#     structured `[REFUSAL ...]` stderr, ZERO filesystem writes (defense in depth
#     mirroring the CLI guard; FR-B7-2-051 at the wrapper layer).
#   - The moment the schema is promoted to `stable` / `scaffoldable: true`
#     (B.7.6, gated on a green b7-6 harness — ADR-B7-2-001), the gate opens and
#     this same body renders the scaffold with NO further edits to this file.
#
# Render mechanism (ADR-B7-2-007): the scaffold is rendered via
# `.forge/scripts/scaffolder/overlay.sh` (the pure-python renderer), NOT via
# `init.sh`. `init.sh` is hardcoded to the full-stack-monorepo archetype (it runs
# `flutter create`, five fixed `cargo new`s, `buf lint`, and validate-foundations)
# and cannot render a second archetype's plan. `overlay.sh` likewise hardcodes its
# own ARCHETYPE_DIR, so this wrapper absolutizes the plan's relative `source:`
# paths against the ai-native-rag archetype dir into a throwaway temp plan before
# calling overlay.sh — the committed plan stays portable. This is the same trick
# the L2 harness `_b72_render_plan` helper uses.
#
# Stable per-archetype ABI (FR-B7-2-050 / B.5.1):
#   forge-init-ai-native-rag.sh \
#       --target <dir> \
#       --project-name <slug> \
#       --reverse-domain <fqdn> \
#       [--force]
#
# Exit codes:
#   0 — success (render complete; only reachable once scaffoldable)
#   2 — missing/unknown argument
#   3 — refusal (candidate / not-yet-scaffoldable, or J.8 forbidden archetype)
#   1 — unexpected render error (propagated from overlay.sh)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ARCHETYPE="ai-native-rag"
ARCHETYPE_DIR="$FORGE_ROOT/.forge/templates/archetypes/$ARCHETYPE"
SCHEMA="$FORGE_ROOT/.forge/schemas/$ARCHETYPE/1.0.0.yaml"
OVERLAY_SH="$FORGE_ROOT/.forge/scripts/scaffolder/overlay.sh"
PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"

err() { echo "forge-init-ai-native-rag: $*" >&2; }

usage() {
  sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# ── J.8 j8-janus-rules — defense-in-depth refusal (FR-J8-022 / ADR-J8-005) ──
# Source the helper only if it's alongside the wrapper. Sibling absence is
# tolerated for fixture-test contexts — the TS dispatcher is the canonical
# refusal point. ai-native-rag is NOT on the forbidden list (it is a registered
# candidate), so this is a no-op for it today; retained for parity + future-proof.
if [ -f "$SCRIPT_DIR/_forge-init-helpers.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/_forge-init-helpers.sh"
  _refuse_if_forbidden "$ARCHETYPE"
fi

# ── Scaffoldability gate (FR-B7-2-051 / ADR-B7-2-001 / ADR-B7-2-007) ─────────
# Read the schema's stage + scaffoldable. While the archetype is a candidate
# (scaffoldable:false) REFUSE — exit 3, structured stderr, ZERO writes. This runs
# BEFORE ABI-flag parsing so the candidate refusal is UNCONDITIONAL w.r.t. args
# (a hard policy refusal must not depend on well-formed args — and this preserves
# the refusing-stub contract b7-2a T-003 encodes, which invokes the wrapper with
# the legacy `<name> --org <fqdn>` shape). The gate auto-opens when b7-6 promotes
# the schema to stable/scaffoldable:true; no edit to this wrapper is needed at
# promotion. FORGE_AINR_FORCE_SCAFFOLD=1 overrides the gate FOR HARNESS USE ONLY
# (the gated end-to-end render test), never in normal operation.
is_scaffoldable() {
  [ -f "$SCHEMA" ] || return 1
  STAGE_SCAFF="$(SCHEMA="$SCHEMA" python3 - <<'PY' 2>/dev/null
import os, yaml
try:
    with open(os.environ['SCHEMA']) as f:
        d = yaml.safe_load(f) or {}
except Exception:
    print("error false"); raise SystemExit(0)
print(d.get('stage', 'unknown'), str(bool(d.get('scaffoldable', False))).lower())
PY
)"
  local stage scaffoldable
  stage="${STAGE_SCAFF%% *}"
  scaffoldable="${STAGE_SCAFF##* }"
  [ "$stage" = "stable" ] && [ "$scaffoldable" = "true" ]
}

if [ "${FORGE_AINR_FORCE_SCAFFOLD:-0}" != "1" ] && ! is_scaffoldable; then
  echo "[REFUSAL: ai-native-rag: not-yet-scaffoldable: the ai-native-rag schema is a candidate (scaffoldable:false) — the scaffold backbone (templates + wrapper) has landed (B.7.2) but promotion to stable is gated on a green b7-6 harness (ADR-B7-2-001) ; alternative: use --archetype full-stack-monorepo, or 'default' then add the RAG components manually]" >&2
  exit 3
fi

# ── J.8.c b7-9-janus-ai — LLM-provider combination refusal (FR-B7-9-045) ──────
# Defense-in-depth scaffold-time refusal of a non-sovereign LLM provider (Vertex
# AI / Bedrock at any tier ; US-managed inference at T3) per J8-RULE-004..006.
# Positioned AFTER the scaffoldability gate so it only fires post-promotion (a
# candidate init never reaches here — the gate above refuses first, ADR-B7-2-001
# untouched). The configured provider comes from FORGE_AINR_LLM_PROVIDER ; the
# scaffold's sovereign default (Mistral-EU / vLLM, global/llm-gateway.md) does
# not refuse. The helper resolves the tier ($FORGE_EU_TIER → .forge/.forge-tier)
# and fail-opens when the dispatch-table is unreachable.
if declare -f _refuse_if_forbidden_combination >/dev/null 2>&1; then
  _refuse_if_forbidden_combination "$ARCHETYPE" "${FORGE_AINR_LLM_PROVIDER:-mistral-eu}"
fi

# ── Parse stable ABI flags (reached only once scaffoldable / under override) ──
TARGET=""
PROJECT_NAME=""
REVERSE_DOMAIN=""
FORCE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --target=*) TARGET="${1#*=}"; shift ;;
    --project-name) PROJECT_NAME="${2:-}"; shift 2 ;;
    --project-name=*) PROJECT_NAME="${1#*=}"; shift ;;
    --reverse-domain) REVERSE_DOMAIN="${2:-}"; shift 2 ;;
    --reverse-domain=*) REVERSE_DOMAIN="${1#*=}"; shift ;;
    --force) FORCE="--force"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) err "unknown argument: $1"; usage; exit 2 ;;
  esac
done

# ── Real render body (reachable only once scaffoldable, or under the harness
#     override) ────────────────────────────────────────────────────────────────
[ -n "$TARGET" ]         || { err "--target is required"; exit 2; }
[ -n "$PROJECT_NAME" ]   || { err "--project-name is required"; exit 2; }
[ -n "$REVERSE_DOMAIN" ] || { err "--reverse-domain is required"; exit 2; }
[ -f "$OVERLAY_SH" ]     || { err "overlay.sh not found at $OVERLAY_SH"; exit 1; }
[ -f "$PLAN" ]           || { err "scaffold-plan not found at $PLAN"; exit 1; }

# Absolutize the plan's relative `source:` paths against the ai-native-rag
# archetype dir (overlay.sh joins source against its own hardcoded ARCHETYPE_DIR,
# and an absolute right-hand side wins). The committed plan is left untouched.
ABS_PLAN="$(mktemp)"
trap 'rm -f "$ABS_PLAN"' EXIT
ARCHETYPE_DIR="$ARCHETYPE_DIR" PLAN="$PLAN" ABS_PLAN="$ABS_PLAN" python3 - <<'PY' || { err "failed to prepare scaffold plan"; exit 1; }
import os, yaml
arch = os.environ['ARCHETYPE_DIR']
with open(os.environ['PLAN']) as f:
    plan = yaml.safe_load(f)
for e in plan.get('templates', []):
    s = e.get('source', '')
    if s and not os.path.isabs(s):
        e['source'] = os.path.join(arch, s)
with open(os.environ['ABS_PLAN'], 'w') as f:
    yaml.safe_dump(plan, f, sort_keys=False)
PY

bash "$OVERLAY_SH" \
  --target "$TARGET" \
  --project-name "$PROJECT_NAME" \
  --reverse-domain "$REVERSE_DOMAIN" \
  --plan "$ABS_PLAN" \
  ${FORCE:+$FORCE}

# ── Post-render steps DEFERRED to b7-6 (need buf + network; ADR-B7-2-007) ──────
# These are intentionally NOT implemented here — they require `buf` and network
# access (the buf remote es/tonic plugins) + a populated cargo registry, which
# are out of this brick's hermetic scope. b7-6-harness wires + verifies them:
#   TODO(b7-6): cd "$TARGET/shared/protos" && buf generate
#     → materialises the Rust tonic/prost stubs + the TS Connect `rag_pb`
#       descriptor the Qwik web-public surface imports.
#   TODO(b7-6): cd "$TARGET/backend" && cargo fetch
#     → pre-populates the workspace dependency graph (the verify-then-pin ledger).
# Until then, the rendered project documents `task proto` as the first build step
# (see frontend/web-public/README.md + shared/protos/README.md).

echo "✓ ai-native-rag scaffold rendered into $TARGET"
echo "  next: cd $TARGET && task proto    # generate proto stubs (buf), then build"
