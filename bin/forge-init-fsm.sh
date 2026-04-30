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
exec bash "$INIT_SH" "$PROJECT_NAME" \
  --org "$REVERSE_DOMAIN" \
  --target-dir "$TARGET" \
  ${FORCE:+$FORCE}
