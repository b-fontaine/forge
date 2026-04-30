#!/usr/bin/env bash
# Forge — `forge upgrade` driver (Phase 1 stub — Phase 2 ships logic).
# <!-- Audit: A.7 (a7-forge-upgrade, FR-UP-009) -->
#
# Non-destructive merge of framework updates into a scaffolded
# project. Invoked by cli/src/commands/upgrade.ts via spawn.
#
# Phase 1 ships a stub honoring the invocation contract ; Phase 2
# replaces the stub with the actual merge logic per FR-UP-003..007.
#
# Invocation contract :
#   forge-upgrade.sh --target <dir> --to-version <X.Y.Z> \
#                    [--dry-run] [--force] [--verbose]
#
# Exit codes :
#   0  — success
#   2  — argument error
#   5  — missing required tool (git / python3 / tar)
#   7  — upgrade aborted (major-version migration / dirty git tree /
#        non-Git target with --force)
#   8  — conflicts produced (without --force)

set -euo pipefail

# c1-reference-project skip-guard discipline (FR-GL-027) :
# this script's recursive walks (none yet, but placeholder helper
# kept for parity with the other Forge scripts) MUST exclude
# examples/ when running inside the Forge framework repo's own
# dog-food upgrade scenario.
find_excluding_examples() {
  if [ -d "${FORGE_REPO_ROOT:-}/examples" ] \
     && [ -f "${FORGE_REPO_ROOT:-}/.forge/specs/full-stack-monorepo.md" ]; then
    find "$@" -not -path "${FORGE_REPO_ROOT}/examples/*"
  else
    find "$@"
  fi
}

# Defaults
TARGET=""
TO_VERSION=""
DRY_RUN=0
FORCE=0
VERBOSE=0

usage() {
  sed -n '2,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

err() { echo "forge-upgrade: $*" >&2; }

# Argument parsing
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --target=*) TARGET="${1#*=}"; shift ;;
    --to-version) TO_VERSION="${2:-}"; shift 2 ;;
    --to-version=*) TO_VERSION="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    --verbose) VERBOSE=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) err "unknown argument: $1"; exit 2 ;;
  esac
done

[ -n "$TARGET" ] || { err "--target is required"; exit 2; }
[ -n "$TO_VERSION" ] || { err "--to-version is required"; exit 2; }
[ -d "$TARGET" ] || { err "target dir not found: $TARGET"; exit 2; }

# Phase 1 : honour the invocation contract but produce no side
# effects yet. Phase 2 replaces this body with the actual merge.
echo "forge-upgrade: stub (Phase 1) — target=$TARGET to=$TO_VERSION dry_run=$DRY_RUN force=$FORCE verbose=$VERBOSE"
echo "forge-upgrade: TBD : Phase 2 GREEN ships the merge logic per FR-UP-003..007"
exit 0
