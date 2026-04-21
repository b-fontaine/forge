#!/usr/bin/env bash
# Forge framework installer — idempotent bootstrap into a target project.
#
# Usage:
#   Local  : bash bin/forge-install.sh [--force] [--target <dir>] [--source <dir>]
#   Remote : curl -fsSL https://raw.githubusercontent.com/bfontaine/forge/main/bin/forge-install.sh \
#              | bash -s -- [--force] [--target <dir>] [--ref <tag-or-branch>]
#
# Behavior:
#   - Copies `.forge/`, `.claude/`, `.mcp.json`, `CLAUDE.md`, `VERSION` into <target>.
#   - Excludes runtime/per-project state: `.forge/_memory/`, `.forge/changes/*`,
#     `.forge/specs/*`, `.claude/settings.local.json`.
#   - Scaffolds `.forge/product/{mission,roadmap,tech-stack}.md` from
#     `.forge/templates/product/*.md` (A3.0) — NEVER copies the source repo's
#     own `.forge/product/` content.
#   - Idempotent: files that already exist in <target> are kept unless
#     `--force` is set. `.forge/product/*` are NEVER overwritten even with
#     `--force` (they are user content).
#   - Refuses to run if <target> is not a directory.
#
# Exit codes:
#   0  success
#   1  generic failure
#   2  bad invocation / missing dependency
#   3  target directory invalid

set -euo pipefail

# ─── Config ────────────────────────────────────────────────────

REPO_SLUG="bfontaine/forge"
DEFAULT_REF="main"
TMP_PREFIX="forge-install"

TARGET_DIR="$PWD"
SOURCE_DIR=""
REF="$DEFAULT_REF"
FORCE=0
VERBOSE=0

# ─── Helpers ───────────────────────────────────────────────────

log()  { printf '%s\n' "$*" >&2; }
info() { log "→ $*"; }
ok()   { log "  ✓ $*"; }
skip() { log "  • $*"; }
warn() { log "  ⚠ $*"; }
die()  { log "✗ $*"; exit "${2:-1}"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1" 2
}

usage() {
  cat <<'EOF'
Forge installer

Usage:
  forge-install.sh [--force] [--target <dir>] [--source <dir>] [--ref <tag>]

Flags:
  --target <dir>   Target project directory (default: current directory).
  --source <dir>   Local Forge checkout to copy from. Skips download.
  --ref <tag>      Git ref to download when no --source is provided
                   (branch or tag; default: main).
  --force          Overwrite existing framework files. Never touches
                   .forge/product/*, .forge/changes/*, .forge/specs/*.
  -h, --help       Show this help and exit.

Environment:
  FORGE_INSTALL_DEBUG=1   Print every copy operation.
EOF
}

# ─── Argument parsing ──────────────────────────────────────────

while [ $# -gt 0 ]; do
  case "$1" in
    --target)  TARGET_DIR="${2:?--target requires a value}"; shift 2 ;;
    --source)  SOURCE_DIR="${2:?--source requires a value}"; shift 2 ;;
    --ref)     REF="${2:?--ref requires a value}"; shift 2 ;;
    --force)   FORCE=1; shift ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1 (see --help)" 2 ;;
  esac
done

[ "${FORGE_INSTALL_DEBUG:-0}" = "1" ] && VERBOSE=1

# ─── Resolve source directory ──────────────────────────────────

resolve_source() {
  if [ -n "$SOURCE_DIR" ]; then
    [ -d "$SOURCE_DIR" ] || die "source directory does not exist: $SOURCE_DIR" 2
    SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
    info "Using local source: $SOURCE_DIR"
    return
  fi

  # If this script lives inside a Forge checkout, prefer that.
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local maybe_root="$(dirname "$script_dir")"
  if [ -f "$maybe_root/.forge/constitution.md" ] && [ -f "$maybe_root/VERSION" ]; then
    SOURCE_DIR="$maybe_root"
    info "Using local source (detected checkout): $SOURCE_DIR"
    return
  fi

  # Otherwise, download a tarball at the requested ref.
  require_cmd curl
  require_cmd tar
  local tmp
  tmp="$(mktemp -d -t "${TMP_PREFIX}.XXXXXX")"
  trap 'rm -rf "$tmp"' EXIT
  local tarball="https://codeload.github.com/${REPO_SLUG}/tar.gz/${REF}"
  info "Downloading Forge @ ${REF} from ${tarball}"
  curl -fsSL "$tarball" | tar -xz -C "$tmp"
  SOURCE_DIR="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
  [ -d "$SOURCE_DIR/.forge" ] || die "downloaded tarball has no .forge/ at root" 1
}

# ─── Copy with overwrite policy ────────────────────────────────

copy_file() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ "$FORCE" -ne 1 ]; then
    skip "keep existing $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  [ "$VERBOSE" -eq 1 ] && ok "copy $dst" || :
}

copy_tree() {
  # copy_tree <src-dir> <dst-dir>
  # Honors FORCE on a per-file basis and never copies forbidden paths.
  local src="$1" dst="$2"
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  (cd "$src" && find . -type f -print0) | while IFS= read -r -d '' rel; do
    local s="$src/${rel#./}"
    local d="$dst/${rel#./}"
    copy_file "$s" "$d"
  done
}

# ─── Scaffold product/ from templates ──────────────────────────

scaffold_product() {
  local tpl_dir="$SOURCE_DIR/.forge/templates/product"
  local out_dir="$TARGET_DIR/.forge/product"
  [ -d "$tpl_dir" ] || die "missing $tpl_dir — source repo layout invalid" 1
  mkdir -p "$out_dir"
  info "Scaffolding .forge/product/ from templates (A3.0)"
  for f in mission.md roadmap.md tech-stack.md; do
    local s="$tpl_dir/$f"
    local d="$out_dir/$f"
    if [ ! -f "$s" ]; then
      warn "template missing: .forge/templates/product/$f — skipping"
      continue
    fi
    if [ -e "$d" ]; then
      skip "keep existing .forge/product/$f (user content — never overwritten)"
      continue
    fi
    cp "$s" "$d"
    ok "scaffold .forge/product/$f"
  done
}

# ─── Install framework files ───────────────────────────────────

install_framework() {
  info "Installing Forge framework into $TARGET_DIR"

  # Root files
  for f in .mcp.json CLAUDE.md VERSION; do
    if [ -f "$SOURCE_DIR/$f" ]; then
      copy_file "$SOURCE_DIR/$f" "$TARGET_DIR/$f"
    fi
  done

  # .claude/ — everything except settings.local.json
  if [ -d "$SOURCE_DIR/.claude" ]; then
    (cd "$SOURCE_DIR/.claude" && find . -type f ! -name 'settings.local.json' -print0) \
      | while IFS= read -r -d '' rel; do
          copy_file "$SOURCE_DIR/.claude/${rel#./}" "$TARGET_DIR/.claude/${rel#./}"
        done
  fi

  # .forge/ — everything except _memory, product, changes, specs
  for sub in constitution.md schemas scripts standards templates; do
    if [ -e "$SOURCE_DIR/.forge/$sub" ]; then
      if [ -d "$SOURCE_DIR/.forge/$sub" ]; then
        copy_tree "$SOURCE_DIR/.forge/$sub" "$TARGET_DIR/.forge/$sub"
      else
        copy_file "$SOURCE_DIR/.forge/$sub" "$TARGET_DIR/.forge/$sub"
      fi
    fi
  done

  # Empty runtime dirs (don't create if they already exist — `mkdir -p` is safe)
  mkdir -p "$TARGET_DIR/.forge/changes" "$TARGET_DIR/.forge/specs" "$TARGET_DIR/.forge/_memory"

  # Root .forge.yaml — use template if no target file exists
  if [ -f "$SOURCE_DIR/.forge/templates/change.yaml" ]; then
    :  # per-change template, not a root installer concern
  fi

  # Product (A3.0 — scaffold, never copy source repo's product/)
  scaffold_product
}

# ─── Post-install summary ──────────────────────────────────────

summary() {
  local version="unknown"
  [ -f "$TARGET_DIR/VERSION" ] && version="$(cat "$TARGET_DIR/VERSION")"
  cat >&2 <<EOF

✓ Forge ${version} installed in ${TARGET_DIR}

Next steps:
  1. Open Claude Code in this directory.
  2. Run /forge to auto-detect state and start the guided flow.
  3. Edit .forge/product/mission.md and roadmap.md to describe YOUR product.
  4. Review .forge/constitution.md — every article applies.

Upgrade later:
  forge-install.sh --force --target ${TARGET_DIR}   # overwrites framework,
                                                    # preserves your product/
                                                    # and .forge/changes/.
EOF
}

# ─── Main ──────────────────────────────────────────────────────

[ -d "$TARGET_DIR" ] || die "target is not a directory: $TARGET_DIR" 3
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

resolve_source
install_framework
summary
