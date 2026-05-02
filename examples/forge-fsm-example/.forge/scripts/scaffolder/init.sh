#!/usr/bin/env bash
# Forge — `/forge:init --archetype full-stack-monorepo` driver
# <!-- Audit: B.1.2 (part of b1-scaffolder, init orchestrator) -->
#
# End-to-end orchestrator for scaffolding a new `full-stack-monorepo`
# project. Sequence (non-negotiable per audit rule B.5.6):
#
#   1. Validate args, tools, target-dir collision.
#   2. Copy Forge framework assets (.forge/, .claude/, .mcp.json) from
#      the source Forge repo into the target, EXCLUDING runtime state
#      (.forge/changes, _memory, specs, product) and private Claude
#      config (.claude/settings.local.json).
#   3. Run `flutter create` (official scaffolder, non-negotiable).
#   4. Invoke overlay.sh — renders every archetype template incl.
#      backend/Cargo.toml which cargo new will then detect.
#   5. Run `cargo new` for each of the 5 workspace crates.
#   6. `buf lint` the seed proto (WARN-skip if buf absent — already
#      enforced by step 1).
#   7. Run validate-foundations.sh against the scaffolded target.
#      FAIL aborts with the scaffolded tree preserved for debugging.
#
# Exit codes :
#   0 — success
#   1 — unexpected error
#   2 — missing or malformed argument
#   3 — regex validation failure (delegated to overlay.sh)
#   4 — target file collision without --force
#   5 — missing or below-min external tool (flutter / cargo / buf)
#   6 — target directory already exists without --force
#   7 — scaffold validation failed (validate-foundations.sh exited non-zero)
#
# Usage :
#   init.sh <project-name> --org <reverse-domain> [--target-dir <path>] \
#           [--force] [--dry-run]

set -euo pipefail

# ─── Minimum tool versions (design ADR-006) ────────────────────

FLUTTER_MIN="3.24.0"
CARGO_MIN="1.80.0"
BUF_MIN="1.30.0"

# ─── Argument parsing ──────────────────────────────────────────

PROJECT_NAME=""
REVERSE_DOMAIN=""
TARGET_DIR=""
FORCE="false"
DRY_RUN="false"

POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --org)         REVERSE_DOMAIN="${2:-}"; shift 2 ;;
    --org=*)       REVERSE_DOMAIN="${1#*=}"; shift ;;
    --target-dir)     TARGET_DIR="${2:-}"; shift 2 ;;
    --target-dir=*)   TARGET_DIR="${1#*=}"; shift ;;
    --force)       FORCE="true"; shift ;;
    --dry-run)     DRY_RUN="true"; shift ;;
    --help|-h)
      sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --*)
      echo "init.sh: unknown flag '$1'" >&2
      exit 2
      ;;
    *)
      POSITIONAL+=("$1"); shift
      ;;
  esac
done

if [ "${#POSITIONAL[@]}" -ne 1 ]; then
  echo "init.sh: expected exactly one positional arg <project-name>, got ${#POSITIONAL[@]}" >&2
  exit 2
fi
PROJECT_NAME="${POSITIONAL[0]}"

[ -n "$REVERSE_DOMAIN" ] || { echo "init.sh: --org <reverse-domain> is required" >&2; exit 2; }

# Default --target-dir is ./<project-name>.
if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR="./$PROJECT_NAME"
fi

# Derive snake_case project name for Flutter's --project-name (Dart
# identifiers forbid hyphens).
PROJECT_NAME_SNAKE="${PROJECT_NAME//-/_}"

# ─── Tool version helpers ──────────────────────────────────────

version_ge() {
  # Returns 0 iff $1 >= $2, comparing first three dot-separated components.
  awk -v v="$1" -v min="$2" 'BEGIN {
    split(v,   a, ".");
    split(min, b, ".");
    for (i=1; i<=3; i++) {
      if ((a[i]+0) < (b[i]+0)) exit 1;
      if ((a[i]+0) > (b[i]+0)) exit 0;
    }
    exit 0;
  }'
}

FLUTTER_VERSION=""
CARGO_VERSION=""
BUF_VERSION=""

check_tools() {
  if ! command -v flutter >/dev/null 2>&1; then
    echo "init.sh: flutter not found on PATH (minimum $FLUTTER_MIN)" >&2
    exit 5
  fi
  FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')
  if ! version_ge "$FLUTTER_VERSION" "$FLUTTER_MIN"; then
    echo "init.sh: flutter $FLUTTER_VERSION < $FLUTTER_MIN" >&2
    exit 5
  fi

  if ! command -v cargo >/dev/null 2>&1; then
    echo "init.sh: cargo not found on PATH (minimum $CARGO_MIN)" >&2
    exit 5
  fi
  CARGO_VERSION=$(cargo --version 2>/dev/null | awk '{print $2}')
  if ! version_ge "$CARGO_VERSION" "$CARGO_MIN"; then
    echo "init.sh: cargo $CARGO_VERSION < $CARGO_MIN" >&2
    exit 5
  fi

  if ! command -v buf >/dev/null 2>&1; then
    echo "init.sh: buf not found on PATH (minimum $BUF_MIN)" >&2
    exit 5
  fi
  BUF_VERSION=$(buf --version 2>/dev/null | head -1)
  if ! version_ge "$BUF_VERSION" "$BUF_MIN"; then
    echo "init.sh: buf $BUF_VERSION < $BUF_MIN" >&2
    exit 5
  fi
}

# ─── Locate Forge source repo ──────────────────────────────────

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT_SRC="$(cd "$HERE/../../.." && pwd)"
ARCHETYPE_DIR="$FORGE_ROOT_SRC/.forge/templates/archetypes/full-stack-monorepo"
OVERLAY_SH="$FORGE_ROOT_SRC/.forge/scripts/scaffolder/overlay.sh"

# ─── Main ──────────────────────────────────────────────────────

main() {
  echo "── forge init --archetype full-stack-monorepo ──"
  echo "  project-name:    $PROJECT_NAME"
  echo "  reverse-domain:  $REVERSE_DOMAIN"
  echo "  target-dir:      $TARGET_DIR"
  echo "  force:           $FORCE"
  echo "  dry-run:         $DRY_RUN"
  echo ""

  check_tools
  echo "  flutter: $FLUTTER_VERSION"
  echo "  cargo:   $CARGO_VERSION"
  echo "  buf:     $BUF_VERSION"
  echo ""

  # Target-dir collision check.
  if [ -e "$TARGET_DIR" ] && [ "$FORCE" != "true" ]; then
    echo "init.sh: target '$TARGET_DIR' already exists (use --force to overlay)" >&2
    exit 6
  fi

  if [ "$DRY_RUN" = "true" ]; then
    echo "── DRY RUN — no changes ──"
    echo "  would copy .forge/ + .claude/ + .mcp.json from $FORGE_ROOT_SRC"
    echo "  would run: flutter create ... --org $REVERSE_DOMAIN"
    echo "  would run: overlay.sh against $TARGET_DIR"
    echo "  would run: cargo new for 5 crates in $TARGET_DIR/backend/"
    echo "  would run: buf lint on shared/protos/"
    echo "  would run: validate-foundations.sh on the final target"
    exit 0
  fi

  mkdir -p "$TARGET_DIR"
  local target_abs; target_abs="$(cd "$TARGET_DIR" && pwd)"

  echo "── Step 1 : copy Forge framework assets ──"
  # .forge/ minus runtime state
  cp -R "$FORGE_ROOT_SRC/.forge" "$target_abs/.forge"
  rm -rf "$target_abs/.forge/changes" \
         "$target_abs/.forge/_memory" \
         "$target_abs/.forge/specs" \
         "$target_abs/.forge/product"
  # .claude/ minus private settings
  cp -R "$FORGE_ROOT_SRC/.claude" "$target_abs/.claude"
  rm -f  "$target_abs/.claude/settings.local.json"
  # .mcp.json (optional)
  [ -f "$FORGE_ROOT_SRC/.mcp.json" ] && cp "$FORGE_ROOT_SRC/.mcp.json" "$target_abs/.mcp.json"
  # docs/ — the scaffolded project inherits the Forge framework docs
  # (ARCHITECTURE, CONTRIBUTING, GUIDE, VERSIONING) as a starting
  # reference. The adopter replaces them with project-specific content
  # over time. Required for FR-GL-006 (docs/VERSIONING.md monorepo
  # section) to pass on the scaffolded target.
  if [ -d "$FORGE_ROOT_SRC/docs" ]; then
    cp -R "$FORGE_ROOT_SRC/docs" "$target_abs/docs"
  fi
  echo "  ✓ framework assets copied"

  echo "── Step 2 : flutter create frontend ──"
  (
    cd "$target_abs"
    flutter create frontend \
      --org "$REVERSE_DOMAIN" \
      --platforms android,ios,web \
      --project-name "${PROJECT_NAME_SNAKE}_frontend" >/dev/null 2>&1
  )
  echo "  ✓ flutter create done"

  echo "── Step 3 : overlay archetype templates ──"
  # Export tool versions so overlay.sh can embed them in scaffold-manifest.yaml.
  export OVERLAY_FLUTTER_VERSION="$FLUTTER_VERSION"
  export OVERLAY_CARGO_VERSION="$CARGO_VERSION"
  export OVERLAY_BUF_VERSION="$BUF_VERSION"
  bash "$OVERLAY_SH" \
    --target "$target_abs" \
    --project-name "$PROJECT_NAME" \
    --reverse-domain "$REVERSE_DOMAIN" \
    --force  # flutter create produced some files that overlap overlay paths (e.g. none currently, but defensive)
  echo "  ✓ overlay applied"

  echo "── Step 4 : cargo new for 5 crates ──"
  (
    cd "$target_abs/backend"
    mkdir -p crates
    cargo new --lib crates/domain         --vcs none --name domain          >/dev/null 2>&1
    cargo new --lib crates/application    --vcs none --name application     >/dev/null 2>&1
    cargo new --lib crates/grpc-api       --vcs none --name grpc-api        >/dev/null 2>&1
    cargo new --lib crates/infrastructure --vcs none --name infrastructure  >/dev/null 2>&1
    cargo new      bin-server             --vcs none --name bin-server      >/dev/null 2>&1
  )
  echo "  ✓ 5 crates created"

  echo "── Step 5 : buf lint seed protos ──"
  (
    cd "$target_abs/shared/protos"
    if buf lint >/dev/null 2>&1; then
      echo "  ✓ buf lint passed"
    else
      echo "  ⚠ buf lint reported issues (non-fatal on seed commit)"
    fi
  )

  echo "── Step 6 : validate-foundations on scaffolded target ──"
  local validator="$target_abs/.forge/scripts/validate-foundations.sh"
  if ! FORGE_ROOT="$target_abs" bash "$validator"; then
    echo "" >&2
    echo "[SCAFFOLD VALIDATION FAILED]" >&2
    echo "The scaffolded project at $target_abs did not pass" >&2
    echo "validate-foundations.sh. This is a bug in b1-scaffolder." >&2
    echo "The scaffolded tree is preserved for inspection." >&2
    exit 7
  fi

  echo ""
  echo "✓ Scaffold complete : $target_abs"
  echo ""
  echo "Next steps :"
  echo "  cd $TARGET_DIR"
  echo "  cp .env.example .env            # fill in real values"
  echo "  task dev:up                     # start local stack"
  echo "  cd frontend && flutter run      # run the app"
}

main "$@"
