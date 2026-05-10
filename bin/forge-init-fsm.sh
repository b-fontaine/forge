#!/usr/bin/env bash
# Forge — `forge init --archetype full-stack-monorepo` wrapper
# <!-- Audit: B.5.1 (b5-1-init-wizard, FR-IW-004) -->
#
# Stable per-archetype ABI (FR-IW-004 + ADR-005). Translates the
# CLI's canonical flags into the legacy ABI of
# `.forge/scripts/scaffolder/init.sh` (delivered by b1-scaffolder).
# The CLI never invokes `init.sh` directly — it always goes
# through this wrapper. Decouples the CLI's argv shape from each
# scaffolder's native flags.
#
# Stable ABI :
#   forge-init-fsm.sh \
#       --target <dir> \
#       --project-name <slug> \
#       --reverse-domain <fqdn> \
#       [--force]
#
# Translation to init.sh's native ABI :
#   --target <dir>          → --target-dir <dir>
#   --project-name <slug>   → positional first argument
#   --reverse-domain <fqdn> → --org <fqdn>
#   --force                 → --force
#
# Exit codes : propagates init.sh's exit code unchanged.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INIT_SH="$FORGE_ROOT/.forge/scripts/scaffolder/init.sh"

# J.8 j8-janus-rules — defense-in-depth refusal (FR-J8-022 / ADR-J8-005).
# Source the helper only if it's alongside the wrapper. Sibling
# absence is tolerated for fixture-test contexts (b5 harness copies
# the wrapper to a tmpdir without the helper) — the TS dispatcher
# remains the canonical refusal point.
if [ -f "$SCRIPT_DIR/_forge-init-helpers.sh" ]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/_forge-init-helpers.sh"
  _refuse_if_forbidden "full-stack-monorepo"
fi

err() { echo "forge-init-fsm: $*" >&2; }

usage() {
  sed -n '2,28p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# Parse stable ABI flags
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

[ -n "$TARGET" ] || { err "--target is required"; exit 2; }
[ -n "$PROJECT_NAME" ] || { err "--project-name is required"; exit 2; }
[ -n "$REVERSE_DOMAIN" ] || { err "--reverse-domain is required"; exit 2; }

[ -f "$INIT_SH" ] || { err "init.sh not found at $INIT_SH"; exit 5; }

# Translate to init.sh's native ABI
bash "$INIT_SH" "$PROJECT_NAME" \
  --org "$REVERSE_DOMAIN" \
  --target-dir "$TARGET" \
  ${FORCE:+$FORCE}
RC=$?
if [ "$RC" -ne 0 ]; then
  exit "$RC"
fi

# ─── J.8 j8-janus-rules — EU compliance tier post-scaffold ──────
# (FR-J8-050..060 / ADR-J8-002 / ADR-J8-006).
# When FORGE_EU_TIER is set, apply tier-specific enforcement and
# write the .forge-tier ledger. Absence preserves backward compat.

if [ -n "${FORGE_EU_TIER:-}" ]; then
  case "$FORGE_EU_TIER" in
    T3)
      # FR-J8-053 — refuse Datadog in rendered observability config.
      OTEL_CFG="$TARGET/infra/observability/otel-collector-config.yaml"
      if [ -f "$OTEL_CFG" ] && grep -qi "datadog" "$OTEL_CFG"; then
        echo "[REFUSAL: full-stack-monorepo: J8-RULE-003: Datadog exporter detected with --eu-tier T3 (CLOUD Act forbidden) ; alternative: stay on the local-dev SigNoz config and self-host SigNoz at deploy time]" >&2
        exit 3
      fi
      # FR-J8-052 — refuse SigNoz Cloud SaaS endpoints (signoz.io).
      if [ -f "$OTEL_CFG" ] && grep -qE "signoz\.io" "$OTEL_CFG"; then
        echo "[REFUSAL: full-stack-monorepo: J8-RULE-003: SigNoz Cloud SaaS endpoint detected with --eu-tier T3 ; alternative: self-host SigNoz on EU-jurisdiction infrastructure]" >&2
        exit 3
      fi
      # FR-J8-051 — refuse non-self-host Zitadel (Auth0 / Keycloak-cloud).
      # Identity is currently a documentation-only standard ; this is a
      # forward-looking guard that fires when adopters bring their own
      # identity config files.
      ID_CFG="$TARGET/infra/identity"
      if [ -d "$ID_CFG" ] && grep -rqiE "auth0\.com|okta\.com|keycloak.*cloud" "$ID_CFG" 2>/dev/null; then
        echo "[REFUSAL: full-stack-monorepo: J8-RULE-002: cloud-managed identity provider detected with --eu-tier T3 ; alternative: self-host Zitadel on EU-jurisdiction infrastructure]" >&2
        exit 3
      fi
      ;;
    T1|T2)
      # FR-J8-054 — informational only, no refusal.
      echo "[INFO: ${FORGE_EU_TIER}: tier recorded ; no refusal at this tier ; recommended posture per docs/ARCHITECTURE-TARGET.md §10.]"
      ;;
    *)
      err "unknown FORGE_EU_TIER value: $FORGE_EU_TIER (expected T1|T2|T3)"
      exit 2
      ;;
  esac

  # FR-J8-060 / ADR-J8-006 — write the .forge-tier ledger
  # (plain text, exactly one line, trailing newline mandatory).
  mkdir -p "$TARGET/.forge"
  printf '%s\n' "$FORGE_EU_TIER" > "$TARGET/.forge/.forge-tier"
fi

exit 0
