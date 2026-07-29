#!/usr/bin/env bash
# Forge — `forge init --archetype mobile-pwa-first` wrapper
# <!-- Audit: B.9.2 (b9-2-web-pwa) — gated real scaffolder body -->
#
# GATED REAL BODY (ADR-B7-2-007 pattern, lifted from forge-init-ai-native-rag.sh).
# `mobile-pwa-first` is registered in `.forge/scaffolding/dispatch-table.yml` and its
# 2.0.0 schema is currently `stage: candidate` / `scaffoldable: false` (B.9.1). The CLI
# versioned-schema layer refuses `forge init --archetype mobile-pwa-first` with exit 3
# BEFORE this wrapper is ever invoked while the schema is a candidate; this wrapper
# repeats the refusal as defense in depth.
#
# The gate opens with NO edit to this file when B.9.11 promotes the schema.
#
# Render mechanism (ADR-B9-2-002): ONE `scaffold-plan.yaml` covers BOTH surfaces — the
# Flutter `app` surface at `.` (ported from mobile-only) and the Qwik `web-pwa/` PWA
# channel. Rendered via `.forge/scripts/scaffolder/overlay.sh`, never `init.sh` (which
# is hardcoded to full-stack-monorepo).
#
# TWO archetype-specific steps this wrapper owns, both because overlay.sh cannot:
#
#   1. PLAN ABSOLUTIZATION. overlay.sh:128 hardcodes
#      ARCHETYPE_DIR=.../archetypes/full-stack-monorepo, so a committed plan's relative
#      `source:` paths would resolve against the FLAGSHIP tree. We rewrite them against
#      this archetype's dir into a mktemp plan and pass that absolute path to --plan
#      (overlay.sh:135 honours an absolute plan). The committed plan stays portable.
#      Same trick as forge-init-ai-native-rag.sh:144-159.
#
#   2. KOTLIN PACKAGE RELOCATION. `android/app/src/main/kotlin/{{reverse_domain_path}}`
#      is a literal DIRECTORY name; overlay.sh substitutes only in file contents
#      (:187-189) and uses entry['target'] verbatim, so it cannot produce a
#      domain-derived directory. We relocate after the render, reproducing
#      bin/forge-init-mobile-only.sh:136-146. Restructuring the template to avoid the
#      placeholder directory was rejected: it would break the byte-equivalence contract
#      with the mobile-only render (FR-B9-2-004 / ADR-B9-2-006).
#
# overlay.sh is NOT modified by this brick (NFR-B9-2-001) — the hardcoding is worked
# around, not fixed; fixing it is shared-infra surgery for its own brick.
#
# Stable per-archetype ABI (FR-B7-2-050 / B.5.1):
#   forge-init-mobile-pwa-first.sh \
#       --target <dir> \
#       --project-name <slug> \
#       --reverse-domain <fqdn> \
#       [--force]
#
# Exit codes:
#   0 — success (render complete; only reachable once scaffoldable)
#   2 — missing/unknown argument
#   3 — refusal (candidate / not-yet-scaffoldable)
#   1 — unexpected render error (propagated from overlay.sh)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ARCHETYPE="mobile-pwa-first"
ARCHETYPE_DIR="$FORGE_ROOT/.forge/templates/archetypes/$ARCHETYPE"
SCHEMA="$FORGE_ROOT/.forge/schemas/$ARCHETYPE/2.0.0.yaml"
OVERLAY_SH="$FORGE_ROOT/.forge/scripts/scaffolder/overlay.sh"
PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"

err() { echo "forge-init-mobile-pwa-first: $*" >&2; }

usage() {
  sed -n '2,50p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# ── J.8 defense-in-depth refusal (parity with the sibling wrappers) ──────────
if [ -f "$SCRIPT_DIR/_forge-init-helpers.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/_forge-init-helpers.sh"
  _refuse_if_forbidden "$ARCHETYPE"
fi

# ── Scaffoldability gate (FR-B9-2-007) ───────────────────────────────────────
# Runs BEFORE ABI-flag parsing so the candidate refusal is UNCONDITIONAL w.r.t.
# arguments — a hard policy refusal must not depend on well-formed args.
# ZERO filesystem writes on this path.
# FORGE_MPF_FORCE_SCAFFOLD=1 overrides the gate FOR HARNESS USE ONLY (the gated
# end-to-end render test), never in normal operation.
is_scaffoldable() {
  [ -f "$SCHEMA" ] || return 1
  local stage scaffoldable
  stage=$(grep -E '^stage:' "$SCHEMA" | head -1 | sed 's/^stage:[[:space:]]*//' | tr -d '"' | awk '{print $1}')
  scaffoldable=$(grep -E '^scaffoldable:' "$SCHEMA" | head -1 | sed 's/^scaffoldable:[[:space:]]*//' | awk '{print $1}')
  [ "$stage" = "stable" ] && [ "$scaffoldable" = "true" ]
}

if [ "${FORGE_MPF_FORCE_SCAFFOLD:-0}" != "1" ] && ! is_scaffoldable; then
  echo "[REFUSAL: mobile-pwa-first: not-yet-scaffoldable: the mobile-pwa-first 2.0.0 schema is a candidate (scaffoldable:false) — the scaffold backbone (both surfaces + wrapper) has landed (B.9.2) but promotion to stable is gated on a green b9-11 harness (ADR-B9-1-002) ; alternative: use --archetype mobile-only for the native-only tree, or 'default' then add the PWA channel manually]" >&2
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

[ -n "$TARGET" ]         || { err "--target is required"; exit 2; }
[ -n "$PROJECT_NAME" ]   || { err "--project-name is required"; exit 2; }
[ -n "$REVERSE_DOMAIN" ] || { err "--reverse-domain is required"; exit 2; }
[ -f "$OVERLAY_SH" ]     || { err "overlay.sh not found at $OVERLAY_SH"; exit 1; }
[ -f "$PLAN" ]           || { err "scaffold-plan not found at $PLAN"; exit 1; }

# ── Step 1: absolutize the plan (see header) ─────────────────────────────────
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

# ── Step 2: render both surfaces ─────────────────────────────────────────────
# shellcheck disable=SC2086
bash "$OVERLAY_SH" \
  --target "$TARGET" \
  --project-name "$PROJECT_NAME" \
  --reverse-domain "$REVERSE_DOMAIN" \
  --plan "$ABS_PLAN" \
  $FORCE

# ── Step 3: relocate the Kotlin package directory (see header) ───────────────
REVERSE_DOMAIN_PATH="${REVERSE_DOMAIN//./\/}"
KOTLIN_BASE="$TARGET/android/app/src/main/kotlin"
if [ -d "$KOTLIN_BASE/{{reverse_domain_path}}" ]; then
  mkdir -p "$KOTLIN_BASE/$REVERSE_DOMAIN_PATH"
  rsync -a "$KOTLIN_BASE/{{reverse_domain_path}}/" "$KOTLIN_BASE/$REVERSE_DOMAIN_PATH/"
  rm -rf "$KOTLIN_BASE/{{reverse_domain_path}}"
fi

echo "Scaffolded mobile-pwa-first project at: $TARGET"
echo "  project-name:    $PROJECT_NAME"
echo "  reverse-domain:  $REVERSE_DOMAIN"
echo "  surfaces:        app (Flutter, .) + web-pwa (Qwik City)"
