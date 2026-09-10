#!/usr/bin/env bash
# Forge — `mobile-only / 1.0.0` → `mobile-pwa-first / 2.0.0` migration.
# <!-- Audit: B.9.9 (b9-9-migrate-mobile-pwa, FR-B99-001..009) -->
#
# Adds the Qwik PWA surface to an existing mobile-only install and touches nothing
# that is already there.
#
# ── WHY THIS IS SIMPLER THAN forge-migrate-flagship.sh ───────────────────────
#
# The flagship migration sources forge-upgrade.sh's _a7_* 3-way merge engine because
# it genuinely rewrites existing files. This one does not: rendering both archetypes
# from identical inputs and diffing gives 26 ADDITIONS and ZERO modifications —
# web-pwa/ (23 files), oidc-provider.json, .github/workflows/web-pwa-ci.yml, and the
# scaffold manifest. The Flutter surface is byte-identical between the two renders.
#
# That is a consequence of ADR-B9-1-004, not luck: mobile-only's single
# `- id: app / path: .` maps 1:1 onto mobile-pwa-first's `app` layer, same id, same
# path. So there is nothing to merge, and a merge engine here would be machinery for
# a case that cannot arise. On a target that HAS diverged — the adopter wrote their
# own web-pwa/ — merging framework templates into their work is worse than refusing
# (ADR-B99-001).
#
# ── RENDERED, NEVER COPIED ───────────────────────────────────────────────────
#
# b8-10b-migrate-render established this the expensive way: the flagship migration
# used to `cp` template files, so adopters received 36 raw `.tmpl` files with live
# `<project-name>` placeholders. Everything here goes through overlay.sh, so there is
# ONE implementation of the placeholder semantics and the output is the same bytes
# `forge init --archetype mobile-pwa-first` would produce.
#
# ── WHERE THE SUBSTITUTION VALUES COME FROM ──────────────────────────────────
#
# A mobile-only install has NO .forge/scaffold-manifest.yaml — only
# framework-owned-paths.yml — so b8-10b's "read them from the manifest" is
# unavailable. Both are derived from the project itself: pubspec.yaml's `name:` and
# android/app/build.gradle.kts's `namespace`. That is also more correct than a stored
# value: if you changed your applicationId after scaffolding, the Gradle file is what
# your build actually uses (ADR-B99-002).
#
# Usage:
#   forge-migrate-mobile-pwa.sh --target <dir> [--dry-run] [--force]
#
# Flags:
#   --target <dir>   Project directory to migrate (required).
#   --dry-run        Print what would be written; mutate nothing.
#   --force          Overwrite on collision instead of refusing.
#   --help, -h       Print this usage and exit 0.
#
# Exit codes: 0 success / 2 usage error / 5 missing tool / 7 precondition not met /
#             8 collision without --force.  (The sibling 0/2/5/7/8 envelope.)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_REPO_ROOT="${FORGE_REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

ARCHETYPE_DIR="$FORGE_REPO_ROOT/.forge/templates/archetypes/mobile-pwa-first"
PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"
OVERLAY_SH="$FORGE_REPO_ROOT/.forge/scripts/scaffolder/overlay.sh"

TARGET=""
DRY_RUN=0
FORCE=0

err() { echo "forge-migrate-mobile-pwa: $*" >&2; }

usage() { sed -n '2,52p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

require_tool() { command -v "$1" >/dev/null 2>&1 || { err "missing required tool: $1"; exit 5; }; }

while [ $# -gt 0 ]; do
  case "$1" in
    --target)   TARGET="${2:-}"; shift 2 ;;
    --target=*) TARGET="${1#*=}"; shift ;;
    --dry-run)  DRY_RUN=1; shift ;;
    --force)    FORCE=1; shift ;;
    --help|-h)  usage; exit 0 ;;
    *)          err "unknown argument: $1 (try --help)"; exit 2 ;;
  esac
done

[ -n "$TARGET" ] || { err "--target is required (try --help)"; exit 2; }
require_tool python3

[ -d "$TARGET" ] || { err "preflight: target-missing: $TARGET is not a directory"; exit 7; }
[ -f "$PLAN" ] || { err "preflight: plan-missing: $PLAN"; exit 7; }
[ -f "$OVERLAY_SH" ] || { err "preflight: overlay-missing: $OVERLAY_SH"; exit 7; }

# ── Phase 0: preflight (FR-B99-002) ──────────────────────────────────────────
PUBSPEC="$TARGET/pubspec.yaml"
GRADLE="$TARGET/android/app/build.gradle.kts"

if [ ! -f "$PUBSPEC" ]; then
  err "preflight: not-a-flutter-project: $PUBSPEC not found — this migrates a mobile-only install"
  exit 7
fi
if [ ! -f "$GRADLE" ]; then
  err "preflight: no-android-module: $GRADLE not found — the reverse domain is derived from its namespace"
  exit 7
fi
if [ -e "$TARGET/web-pwa" ]; then
  err "preflight: already-migrated: $TARGET/web-pwa already exists."
  err "  This migration is purely additive and will not merge into an existing surface."
  err "  Move or remove it first if you intend to re-render."
  exit 7
fi

# ── Derive the substitution values (FR-B99-003) ──────────────────────────────
PROJECT_NAME="$(sed -n 's/^name:[[:space:]]*\([A-Za-z0-9_]\{1,\}\).*/\1/p' "$PUBSPEC" | head -1)"
REVERSE_DOMAIN="$(sed -n 's/.*namespace[[:space:]]*=[[:space:]]*"\([^"]\{1,\}\)".*/\1/p' "$GRADLE" | head -1)"

if [ -z "$PROJECT_NAME" ]; then
  err "preflight: cannot derive project name from $PUBSPEC (no 'name:' line)"
  exit 7
fi
if [ -z "$REVERSE_DOMAIN" ]; then
  err "preflight: cannot derive reverse domain from $GRADLE (no 'namespace = \"...\"')"
  exit 7
fi

echo "[Phase 0] preflight: OK"
echo "  target:          $TARGET"
echo "  project-name:    $PROJECT_NAME    (derived from pubspec.yaml)"
echo "  reverse-domain:  $REVERSE_DOMAIN    (derived from android/app/build.gradle.kts)"
echo "  from:            mobile-only / 1.0.0"
echo "  to:              mobile-pwa-first / 2.0.0 (candidate; the schema gate is B.9.11)"

# ── Phase 1: build the additive plan (FR-B99-006) ────────────────────────────
#
# DERIVED from the archetype's own scaffold-plan, never a second hand-maintained
# list — that is what made b8-10b need a coverage guard. The predicate is the
# additive contract measured in b9-9's evidence: everything under web-pwa/, plus the
# two root files the mobile-only render has no counterpart for.
#
# Sources are absolutized in the same pass, because overlay.sh:128 hardcodes its
# ARCHETYPE_DIR to full-stack-monorepo and would otherwise resolve them against the
# flagship tree (the documented forge-init-mobile-pwa-first.sh trick).
ADD_PLAN="$(mktemp)"
trap 'rm -f "$ADD_PLAN"' EXIT

ARCHETYPE_DIR="$ARCHETYPE_DIR" PLAN="$PLAN" ADD_PLAN="$ADD_PLAN" python3 - <<'PY' || { err "failed to build the additive plan"; exit 1; }
import os, sys, yaml
arch = os.environ['ARCHETYPE_DIR']
with open(os.environ['PLAN']) as f:
    plan = yaml.safe_load(f) or {}

ROOT_ADDITIONS = {"oidc-provider.json", ".github/workflows/web-pwa-ci.yml"}

def additive(e):
    t = str(e.get("target", ""))
    return t.startswith("web-pwa/") or t in ROOT_ADDITIONS

kept = [e for e in (plan.get("templates") or []) if additive(e)]
if not kept:
    print("additive filter selected NOTHING", file=sys.stderr)
    raise SystemExit(1)

for e in kept:
    s = e.get("source", "")
    if s and not os.path.isabs(s):
        e["source"] = os.path.join(arch, s)

plan["templates"] = kept
# post_steps is kept: overlay.sh writes .forge/scaffold-manifest.yaml, which a
# mobile-only install does not have and a migrated project needs (FR-B99-008).
# Its scaffold_plan_sha will reflect THIS filtered plan rather than a fresh init's —
# correct, since it records what was actually rendered.
with open(os.environ['ADD_PLAN'], 'w') as f:
    yaml.safe_dump(plan, f, sort_keys=False)
print(f"[Phase 1] additive plan: {len(kept)} entries", file=sys.stderr)
PY

# ── Phase 2: render into a staging dir, then add (FR-B99-004/005/007) ────────
STAGE="$(mktemp -d -t forge-mpwa-XXXXXX)"
trap 'rm -f "$ADD_PLAN"; rm -rf "$STAGE"' EXIT

bash "$OVERLAY_SH" \
  --target "$STAGE" \
  --project-name "$PROJECT_NAME" \
  --reverse-domain "$REVERSE_DOMAIN" \
  --plan "$ADD_PLAN" >/dev/null 2>&1 \
  || { err "phase2: overlay render failed"; exit 1; }

# Collision check BEFORE writing anything: an additive migration that overwrites is
# not additive (FR-B99-007).
COLLISIONS=()
while IFS= read -r abs; do
  rel="${abs#"$STAGE"/}"
  [ -e "$TARGET/$rel" ] && COLLISIONS+=("$rel")
done < <(find "$STAGE" -type f | sort)

if [ "${#COLLISIONS[@]}" -gt 0 ] && [ "$FORCE" != "1" ]; then
  err "phase2: ${#COLLISIONS[@]} file(s) already exist in the target:"
  printf '  %s\n' "${COLLISIONS[@]}" >&2
  err "  Re-run with --force to overwrite, or move them aside."
  exit 8
fi

COUNT=0
while IFS= read -r abs; do
  rel="${abs#"$STAGE"/}"
  if [ "$DRY_RUN" = "1" ]; then
    echo "    [add] $rel"
  else
    mkdir -p "$(dirname "$TARGET/$rel")"
    cp "$abs" "$TARGET/$rel"
  fi
  COUNT=$((COUNT + 1))
done < <(find "$STAGE" -type f | sort)

if [ "$DRY_RUN" = "1" ]; then
  echo "[Phase 2] dry-run: $COUNT file(s) would be added, 0 modified"
  exit 0
fi

echo "[Phase 2] added $COUNT file(s); 0 modified"
echo ""
echo "Next steps :"
echo "  cd $TARGET/web-pwa && npm install && npm run build"
echo "  review oidc-provider.json — it declares the issuer for BOTH surfaces"
echo "  .github/workflows/web-pwa-ci.yml is a SECOND required check; configure branch protection"
