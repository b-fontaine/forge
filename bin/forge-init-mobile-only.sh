#!/usr/bin/env bash
# Forge — `forge init --archetype mobile-only` wrapper
# <!-- Audit: B.4 (b4-mobile-only, FR-MO-004) -->
#
# Stable per-archetype ABI (B.5.1 contract). Scaffolds a Flutter
# iOS + Android app from `.forge/templates/archetypes/mobile-only/`
# into <target>, substituting `{{project_name}}` and
# `{{reverse_domain}}` placeholders.
#
# Stable ABI :
#   forge-init-mobile-only.sh \
#       --target <dir> \
#       --project-name <slug> \
#       --reverse-domain <fqdn> \
#       [--force]
#
# Behavior :
#   1. Validate flags + format (project-name = [a-z][a-z0-9_]+ ;
#      reverse-domain = ^[a-z][a-z0-9.-]+\.[a-z][a-z0-9.-]+$).
#   2. Create <target> if missing ; refuse if non-empty unless --force.
#   3. rsync templates -> <target>.
#   4. For each *.tmpl, sed-substitute placeholders and rename
#      (drop the .tmpl suffix).
#   5. Move kotlin source from
#      android/app/src/main/kotlin/{{reverse_domain_path}}/
#      to android/app/src/main/kotlin/<slash-separated-domain>/.
#
# Exit codes :
#   0  — success
#   2  — argument error / format mismatch
#   3  — target collision (non-empty, no --force)
#   4  — template tree missing or unreadable

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$FORGE_ROOT/.forge/templates/archetypes/mobile-only"

# J.8 j8-janus-rules — defense-in-depth refusal (FR-J8-022 / ADR-J8-005).
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_forge-init-helpers.sh"
_refuse_if_forbidden "mobile-only"

err() { echo "forge-init-mobile-only: $*" >&2; }

usage() {
  sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# ─── Parse args ──────────────────────────────────────────────────

TARGET=""
PROJECT_NAME=""
REVERSE_DOMAIN=""
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --target=*) TARGET="${1#*=}"; shift ;;
    --project-name) PROJECT_NAME="${2:-}"; shift 2 ;;
    --project-name=*) PROJECT_NAME="${1#*=}"; shift ;;
    --reverse-domain) REVERSE_DOMAIN="${2:-}"; shift 2 ;;
    --reverse-domain=*) REVERSE_DOMAIN="${1#*=}"; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown flag: $1"; usage >&2; exit 2 ;;
  esac
done

[ -n "$TARGET" ] || { err "missing --target"; exit 2; }
[ -n "$PROJECT_NAME" ] || { err "missing --project-name"; exit 2; }
[ -n "$REVERSE_DOMAIN" ] || { err "missing --reverse-domain"; exit 2; }

# Validate formats
if ! [[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9_]+$ ]]; then
  err "invalid --project-name '$PROJECT_NAME' (expected: [a-z][a-z0-9_]+)"
  exit 2
fi
if ! [[ "$REVERSE_DOMAIN" =~ ^[a-z][a-z0-9.-]+\.[a-z][a-z0-9.-]+$ ]]; then
  err "invalid --reverse-domain '$REVERSE_DOMAIN' (expected: reverse FQDN)"
  exit 2
fi

# Compute the slash-separated path for kotlin sources.
REVERSE_DOMAIN_PATH="${REVERSE_DOMAIN//./\/}"

# ─── Validate template tree ──────────────────────────────────────

if [ ! -d "$TEMPLATES_DIR" ]; then
  err "templates directory missing: $TEMPLATES_DIR"
  exit 4
fi

# ─── Validate target ─────────────────────────────────────────────

if [ ! -d "$TARGET" ]; then
  mkdir -p "$TARGET"
elif [ "$FORCE" -ne 1 ]; then
  if [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
    err "target '$TARGET' is not empty (use --force to overwrite)"
    exit 3
  fi
fi

# ─── Copy templates ──────────────────────────────────────────────

# Copy verbatim (rsync handles dotfiles, preserves modes).
rsync -a --delete-excluded "$TEMPLATES_DIR/" "$TARGET/"

# ─── Substitute placeholders + rename .tmpl files ────────────────

# Find every *.tmpl file under target, substitute, write to the
# non-.tmpl name, remove the .tmpl original.
while IFS= read -r tmpl_file; do
  out_file="${tmpl_file%.tmpl}"
  # BSD sed compatible : -i ''
  sed \
    -e "s|{{project_name}}|$PROJECT_NAME|g" \
    -e "s|{{reverse_domain_path}}|$REVERSE_DOMAIN_PATH|g" \
    -e "s|{{reverse_domain}}|$REVERSE_DOMAIN|g" \
    "$tmpl_file" > "$out_file"
  rm -f "$tmpl_file"
done < <(find "$TARGET" -type f -name '*.tmpl')

# ─── Relocate kotlin sources to the correct package path ─────────

# After substitution, the literal directory name
# `{{reverse_domain_path}}` may still exist if rsync copied it
# before sed processed the file. Move it now to the substituted
# path.
KOTLIN_BASE="$TARGET/android/app/src/main/kotlin"
if [ -d "$KOTLIN_BASE/{{reverse_domain_path}}" ]; then
  mkdir -p "$KOTLIN_BASE/$REVERSE_DOMAIN_PATH"
  # Move contents (handle nested case where the placeholder exists
  # alongside the substituted dir if --force re-runs).
  rsync -a "$KOTLIN_BASE/{{reverse_domain_path}}/" "$KOTLIN_BASE/$REVERSE_DOMAIN_PATH/"
  rm -rf "$KOTLIN_BASE/{{reverse_domain_path}}"
fi

# ─── Done ────────────────────────────────────────────────────────

echo "Scaffolded mobile-only project at: $TARGET"
echo "  project-name:    $PROJECT_NAME"
echo "  reverse-domain:  $REVERSE_DOMAIN"
echo ""
echo "Next steps:"
echo "  1. cd $TARGET"
echo "  2. flutter pub get"
echo "  3. Edit lib/infrastructure/auth/oidc_config.dart with your OIDC provider details"
echo "  4. Edit ios/fastlane/Appfile and android/fastlane/Appfile with your team/app metadata"
echo "  5. Configure secrets via .envrc (copy from .envrc.example)"
exit 0
