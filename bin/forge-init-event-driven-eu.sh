#!/usr/bin/env bash
# Forge — `forge init --archetype event-driven-eu` wrapper
# <!-- Audit: B.6.2 (b6-2-scaffolder) — gated real scaffolder body -->
#
# GATED REAL BODY (mirrors the ai-native-rag B.7.2 wrapper). The event-driven-eu
# archetype is declared (`.forge/scaffolding/dispatch-table.yml`) and its 1.0.0
# schema is currently `stage: candidate` / `scaffoldable: false`
# (`.forge/schemas/event-driven-eu/1.0.0.yaml`, B.6.1). The CLI versioned-schema
# layer refuses `forge init --archetype event-driven-eu` with exit 3 BEFORE this
# wrapper is invoked while the schema is a candidate.
#
# This wrapper is the wrapper-side scaffolder. It is a *gated* real body:
#   - It reads the schema's `stage`/`scaffoldable` (the scaffoldability gate below).
#     While candidate/scaffoldable:false it REFUSES — exit 3, structured
#     `[REFUSAL ...]` stderr, ZERO filesystem writes (defense in depth mirroring the
#     CLI guard).
#   - The moment the schema is promoted to `stable` / `scaffoldable: true` (B.6.7,
#     gated on a green b6 harness), the gate opens and this same body renders the
#     scaffold with NO further edits to this file.
#
# Render mechanism: the scaffold renders via
# `.forge/scripts/scaffolder/overlay.sh` (the pure-python renderer), NOT via
# `init.sh`. `init.sh` is hardcoded to the full-stack-monorepo archetype and cannot
# render a second archetype's plan. overlay.sh likewise hardcodes its own
# ARCHETYPE_DIR, so this wrapper absolutizes the plan's relative `source:` paths
# against the event-driven-eu archetype dir into a throwaway temp plan before
# calling overlay.sh — the committed plan stays portable. This is the same trick
# the ai-native-rag wrapper + the b6-2 L2 harness use.
#
# Stable per-archetype ABI:
#   forge-init-event-driven-eu.sh \
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
ARCHETYPE="event-driven-eu"
ARCHETYPE_DIR="$FORGE_ROOT/.forge/templates/archetypes/$ARCHETYPE"
SCHEMA="$FORGE_ROOT/.forge/schemas/$ARCHETYPE/1.0.0.yaml"
OVERLAY_SH="$FORGE_ROOT/.forge/scripts/scaffolder/overlay.sh"
PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"

err() { echo "forge-init-event-driven-eu: $*" >&2; }

usage() {
  sed -n '2,46p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# ── J.8 j8-janus-rules — defense-in-depth refusal ──
# event-driven-eu is NOT on the forbidden list (it is a registered candidate), so
# this is a no-op for it today; retained for parity + future-proofing.
if [ -f "$SCRIPT_DIR/_forge-init-helpers.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/_forge-init-helpers.sh"
  _refuse_if_forbidden "$ARCHETYPE"
fi

# ── Scaffoldability gate ─────────────────────────────────────────────────────
# Read the schema's stage + scaffoldable. While the archetype is a candidate
# (scaffoldable:false) REFUSE — exit 3, structured stderr, ZERO writes. This runs
# BEFORE ABI-flag parsing so the candidate refusal is UNCONDITIONAL w.r.t. args.
# The gate auto-opens when B.6.7 promotes the schema to stable/scaffoldable:true;
# no edit to this wrapper is needed at promotion. FORGE_EDE_FORCE_SCAFFOLD=1
# overrides the gate FOR HARNESS USE ONLY (the gated end-to-end render test).
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

if [ "${FORGE_EDE_FORCE_SCAFFOLD:-0}" != "1" ] && ! is_scaffoldable; then
  echo "[REFUSAL: event-driven-eu: not-yet-scaffoldable: the event-driven-eu schema is a candidate (scaffoldable:false) — the scaffold backbone (templates + wrapper) has landed (B.6.2) but promotion to stable is gated on a green b6 harness (B.6.7) ; alternative: use --archetype full-stack-monorepo, or 'default' then add the NATS/Temporal components manually]" >&2
  exit 3
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

# Absolutize the plan's relative `source:` paths against the event-driven-eu
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

# ── Post-render codegen + dep-fetch (deferred to B.6.7 harness) ───────────────
# Best-effort post-steps the rendered project needs before its first build:
#   - `buf generate` (shared/protos → Connect/gRPC stubs) needs the buf CLI + BSR.
#   - `cargo fetch` needs cargo + the crates.io registry.
# When a tool or the network is absent we SKIP and tell the adopter to run the
# corresponding task; we never fail the scaffold on a codegen miss (the wrapper's
# exit-0 success contract is the RENDER).
if command -v buf >/dev/null 2>&1; then
  ( cd "$TARGET/shared/protos" && buf generate ) >/dev/null 2>&1 \
    && echo "✓ proto stubs generated (buf generate)" \
    || echo "  note: buf generate did not complete (BSR/plugins unavailable) — run 'task proto' after connecting" >&2
else
  echo "  note: buf not found — run 'task proto' to generate Connect/gRPC stubs" >&2
fi
if command -v cargo >/dev/null 2>&1; then
  ( cd "$TARGET/backend" && cargo fetch ) >/dev/null 2>&1 \
    && echo "✓ backend dependencies pre-fetched (cargo fetch)" \
    || echo "  note: cargo fetch did not complete (registry unavailable) — run 'cargo fetch' after connecting" >&2
fi
