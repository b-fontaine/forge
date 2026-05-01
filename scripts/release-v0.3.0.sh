#!/usr/bin/env bash
# Forge — release v0.3.0 helper script
#
# Run AFTER the PR `optim → main` is merged. Performs the post-merge steps
# documented in GOVERNANCE.md § Release Process :
#   3. Tag git v0.3.0 on main
#   4. Push tag
#   5. Build + publish npm package from cli/
#   6. Create GitHub release (manual fallback if gh not installed)
#
# Usage :
#   bash scripts/release-v0.3.0.sh                # full run with prompts
#   bash scripts/release-v0.3.0.sh --dry-run      # preview without side effects
#   bash scripts/release-v0.3.0.sh --skip-npm     # skip npm publish step
#   bash scripts/release-v0.3.0.sh --skip-gh      # skip GitHub release step
#
# Exit codes :
#   0  — success (or dry-run preview)
#   1  — pre-flight check failed
#   2  — usage error
#   3  — operational failure (tag conflict, npm error, etc.)

set -euo pipefail

# ─── Args ────────────────────────────────────────────────────────

DRY_RUN=0
SKIP_NPM=0
SKIP_GH=0
TAG="v0.3.0"
EXPECTED_VERSION="0.3.0"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --skip-npm) SKIP_NPM=1; shift ;;
    --skip-gh) SKIP_GH=1; shift ;;
    -h|--help)
      sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "release-v0.3.0: unknown flag: $1" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

step() { echo "" ; echo "▶ $1"; }
ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
fatal() { echo "  ✗ $1" >&2; exit 3; }

run() {
  if [ "$DRY_RUN" = "1" ]; then
    echo "    [dry-run] $*"
  else
    eval "$@"
  fi
}

# ─── Pre-flight ──────────────────────────────────────────────────

step "Pre-flight checks"

# 1. On main branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main" ]; then
  fatal "must run on main branch (currently on '$current_branch'). \`git checkout main && git pull\`."
fi
ok "on branch main"

# 2. Clean working tree
if ! git diff --quiet || ! git diff --staged --quiet; then
  fatal "working tree has uncommitted changes. Stash or commit first."
fi
ok "working tree clean"

# 3. Up-to-date with origin
git fetch origin main >/dev/null 2>&1
local_sha=$(git rev-parse HEAD)
remote_sha=$(git rev-parse origin/main)
if [ "$local_sha" != "$remote_sha" ]; then
  fatal "local main ($local_sha) diverges from origin/main ($remote_sha). \`git pull\` first."
fi
ok "in sync with origin/main"

# 4. VERSION file matches expected
version=$(cat VERSION | tr -d ' \n')
if [ "$version" != "$EXPECTED_VERSION" ]; then
  fatal "VERSION file is '$version', expected '$EXPECTED_VERSION'. The release commit must be on main."
fi
ok "VERSION = $version"

# 5. cli/package.json version matches
cli_version=$(grep '"version"' cli/package.json | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
if [ "$cli_version" != "$EXPECTED_VERSION" ]; then
  fatal "cli/package.json version is '$cli_version', expected '$EXPECTED_VERSION'."
fi
ok "cli/package.json version = $cli_version"

# 6. Tag does not already exist
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  fatal "tag $TAG already exists locally. Delete with \`git tag -d $TAG\` if intentional."
fi
if git ls-remote --tags origin "refs/tags/$TAG" 2>/dev/null | grep -q "$TAG\$"; then
  fatal "tag $TAG already exists on origin. Aborting to avoid overwriting a published release."
fi
ok "tag $TAG available"

# 7. CHANGELOG has the [0.3.0] section sealed
if ! grep -qE "^## \[0\.3\.0\] — 2026-05-01" CHANGELOG.md; then
  fatal "CHANGELOG.md does not have a sealed '## [0.3.0] — 2026-05-01' header."
fi
ok "CHANGELOG.md sealed for $TAG"

# 8. Test surface (sanity check — quick)
step "Sanity tests (verify.sh + constitution-linter — quick gate)"
if [ "$DRY_RUN" = "0" ]; then
  if ! bash .forge/scripts/verify.sh >/dev/null 2>&1; then
    fatal "verify.sh failed. Aborting release."
  fi
  ok "verify.sh PASS"
  if ! bash .forge/scripts/constitution-linter.sh >/dev/null 2>&1; then
    fatal "constitution-linter.sh failed. Aborting release."
  fi
  ok "constitution-linter.sh OVERALL PASS"
else
  echo "    [dry-run] skipped sanity tests"
fi

# ─── Step 3 — Tag ────────────────────────────────────────────────

step "Step 3 — Create tag $TAG on main"
run "git tag -a '$TAG' -m 'release(0.3.0): T2 P1 + P2 + T3 robustness — 13 changes, Constitution v1.1.0'"
ok "tag $TAG created locally"

# ─── Step 4 — Push tag ───────────────────────────────────────────

step "Step 4 — Push tag to origin"
run "git push origin '$TAG'"
ok "tag $TAG pushed"

# ─── Step 5 — npm publish ────────────────────────────────────────

if [ "$SKIP_NPM" = "1" ]; then
  step "Step 5 — npm publish (skipped via --skip-npm)"
else
  step "Step 5 — Build + publish @sdd-forge/cli to npm"

  echo "  Logged in as: $(npm whoami 2>/dev/null || echo '(not logged in)')"
  if [ "$DRY_RUN" = "0" ] && ! npm whoami >/dev/null 2>&1; then
    fatal "not logged in to npm. Run \`npm login\` first or use --skip-npm."
  fi

  run "cd cli && npm install"
  ok "cli/ deps installed"
  run "cd cli && npm run bundle"
  ok "cli/ bundle built"
  run "cd cli && npm test"
  ok "cli/ tests passed"

  if [ "$DRY_RUN" = "1" ]; then
    echo "    [dry-run] would run: cd cli && npm publish --access public"
  else
    cd cli && npm publish --access public && cd "$REPO_ROOT"
    ok "@sdd-forge/cli@$EXPECTED_VERSION published to npm"
  fi
fi

# ─── Step 6 — GitHub release ─────────────────────────────────────

if [ "$SKIP_GH" = "1" ]; then
  step "Step 6 — GitHub release (skipped via --skip-gh)"
else
  step "Step 6 — Create GitHub release for $TAG"

  if command -v gh >/dev/null 2>&1; then
    # Extract the [0.3.0] section from CHANGELOG.md as release notes.
    notes_file=$(mktemp -t forge-release-notes-XXXXXX)
    awk '
      /^## \[0\.3\.0\]/ { capture=1; next }
      capture && /^## \[/ { exit }
      capture { print }
    ' CHANGELOG.md > "$notes_file"

    if [ "$DRY_RUN" = "1" ]; then
      echo "    [dry-run] would run: gh release create $TAG --title 'Forge $TAG' --notes-file <CHANGELOG section>"
      echo "    --- release notes preview (first 20 lines) ---"
      head -20 "$notes_file" | sed 's/^/    | /'
    else
      gh release create "$TAG" \
        --title "Forge $TAG" \
        --notes-file "$notes_file"
      ok "GitHub release created"
    fi
    rm -f "$notes_file"
  else
    warn "gh CLI not installed — open the release manually:"
    echo ""
    echo "    URL: https://github.com/b-fontaine/forge/releases/new?tag=$TAG"
    echo "    Title: Forge $TAG"
    echo "    Notes: copy the [0.3.0] section from CHANGELOG.md"
    echo ""
  fi
fi

# ─── Done ────────────────────────────────────────────────────────

step "Release v0.3.0 complete"
if [ "$DRY_RUN" = "1" ]; then
  echo "  (dry-run — no changes pushed)"
else
  echo "  Tag: $TAG"
  if [ "$SKIP_NPM" = "0" ]; then echo "  npm: @sdd-forge/cli@$EXPECTED_VERSION"; fi
  echo "  Next: announce in GitHub Discussions."
fi
exit 0
