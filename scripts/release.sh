#!/usr/bin/env bash
# Forge — generic release helper script
# <!-- Audit: F.3 (f3-release-script-fix) -->
#
# Run AFTER the PR that closes the release scope is merged into main
# (per GOVERNANCE.md § Release Process). Performs the post-merge
# release steps :
#   3. Tag git vX.Y.Z on main
#   4. Push tag
#   5. Build + publish npm package from cli/ (with 2FA OTP)
#   6. Create GitHub release (manual fallback if gh not installed)
#
# Usage :
#   bash scripts/release.sh --version X.Y.Z [options]
#
# Required flag :
#   --version <X.Y.Z>   release semver to tag and publish ; MUST match
#                       VERSION file, cli/package.json, and a sealed
#                       `## [X.Y.Z]` heading in CHANGELOG.md.
#
# Optional flags :
#   --otp <6-digits>    Legacy npm 2FA TOTP code (kept for backwards
#                       compatibility). Fallback chain (ADR-F3-004) :
#                       --otp flag → interactive TTY prompt → $NPM_OTP
#                       env var. **Optional** since 2026-05-18 — when
#                       no OTP is provided, the script assumes the npm
#                       account uses WebAuthn 2FA and `npm publish`
#                       triggers the browser flow directly (npm v11+).
#   --dry-run           preview every step without side effects.
#   --skip-npm          skip npm publish step (and OTP collection).
#   --skip-gh           skip GitHub release step.
#   --skip-login        skip the `npm login` auto-trigger (assumes a
#                       valid session token already cached).
#   -h, --help          print this header and exit 0.
#
# npm 2FA modes supported :
#   - **WebAuthn (default for modern accounts)** : `npm login` opens a
#     browser ; the user approves with their authenticator (Touch ID /
#     Yubikey / Dashlane). `npm publish` then triggers a fresh browser
#     challenge for each publish. Pass NO `--otp`.
#   - **TOTP (legacy)** : pass `--otp <6-digits>` (or `$NPM_OTP`) and
#     the script forwards it to `npm publish --otp=...`.
#
# Exit codes :
#   0  — success (or dry-run preview)
#   1  — pre-flight check failed
#   2  — usage error (bad flag, bad value)
#   3  — operational failure (tag conflict, npm error, etc.)
#
# Bug-class fixes (F.3) vs the original release-v0.3.0.sh :
#   - `cd` is isolated inside subshells `( cd cli && ... )` so the
#     parent shell's pwd is invariant across the run.
#   - `npm publish --otp=<value>` is forwarded properly ; the OTP
#     value is never logged or echoed.
#
# WebAuthn support (2026-05-18) :
#   - `_resolve_otp` no longer fatals when no OTP is provided ;
#     the publish step omits `--otp` from the `npm publish` command
#     line so the npm CLI triggers the WebAuthn browser flow.
#   - A new `npm login` auto-trigger runs before publish when the
#     account is not currently logged in (skippable via --skip-login).

set -euo pipefail

# ─── Args ────────────────────────────────────────────────────────

DRY_RUN=0
SKIP_NPM=0
SKIP_GH=0
SKIP_LOGIN=0
VERSION=""
OTP=""

# Print the header comment block as user-facing help.
_print_help() {
  sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --skip-npm) SKIP_NPM=1; shift ;;
    --skip-gh) SKIP_GH=1; shift ;;
    --skip-login) SKIP_LOGIN=1; shift ;;
    --version)
      if [ $# -lt 2 ]; then
        echo "release: --version requires a value (e.g., --version 0.3.1)" >&2
        exit 2
      fi
      VERSION="$2"; shift 2 ;;
    --version=*) VERSION="${1#*=}"; shift ;;
    --otp)
      if [ $# -lt 2 ]; then
        echo "release: --otp requires a value (e.g., --otp 123456)" >&2
        exit 2
      fi
      OTP="$2"; shift 2 ;;
    --otp=*) OTP="${1#*=}"; shift ;;
    -h|--help)
      _print_help
      exit 0
      ;;
    *) echo "release: unknown flag: $1" >&2; exit 2 ;;
  esac
done

# ─── --version validation ────────────────────────────────────────

if [ -z "$VERSION" ]; then
  echo "release: --version <X.Y.Z> is required (see --help)" >&2
  exit 2
fi

if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "release: --version must match X.Y.Z, got '$VERSION'" >&2
  exit 2
fi

TAG="v$VERSION"
EXPECTED_VERSION="$VERSION"

# ─── --otp validation (value present only ; resolution deferred) ─

if [ -n "$OTP" ]; then
  if ! printf '%s' "$OTP" | grep -Eq '^[0-9]{6}$'; then
    # Redact the rejected value ; never echo it.
    echo "release: --otp must be 6 digits, got '<redacted>'" >&2
    exit 2
  fi
fi

# ─── Anchor working directory ────────────────────────────────────
# This is the ONLY top-level `cd` in the script. Every subsequent
# directory change happens inside a subshell `( cd ... && ... )`
# so the parent shell's pwd is invariant (FR-F3-061 / FR-F3-062).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# ─── Helpers ─────────────────────────────────────────────────────

step() { echo "" ; echo "▶ $1"; }
ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
fatal() { echo "  ✗ $1" >&2; exit 3; }

# Subshell-isolated executor. Any `cd` inside the evaluated string
# is scoped to the subshell and cannot affect the caller's pwd.
# In dry-run mode, the OTP value (if set) is redacted from the trace.
run() {
  if [ "$DRY_RUN" = "1" ]; then
    local rendered="$*"
    if [ -n "$OTP" ]; then
      rendered="${rendered//$OTP/<redacted>}"
    fi
    echo "    [dry-run] $rendered"
  else
    ( eval "$@" )
  fi
}

# ─── OTP resolution (only when publish will actually run) ────────
#
# Legacy TOTP fallback chain per ADR-F3-004 :
#   1. --otp flag (already in $OTP if passed).
#   2. Interactive TTY prompt (silent read ; OPTIONAL since 2026-05-18).
#   3. $NPM_OTP env var.
#
# **WebAuthn-friendly behaviour (2026-05-18)** : if no OTP is provided
# via flag / env / TTY-prompt, `_resolve_otp` returns 0 cleanly. The
# publish step omits `--otp` from the `npm publish` command line so
# the npm CLI itself triggers the WebAuthn browser flow (npm v11+).
#
# In --skip-npm or --dry-run mode we skip resolution entirely so a
# maintainer exploring with --dry-run or testing the script need
# not hold a fresh OTP.
_resolve_otp() {
  if [ "$SKIP_NPM" = "1" ] || [ "$DRY_RUN" = "1" ]; then
    return 0
  fi
  if [ -n "$OTP" ]; then
    return 0
  fi
  if [ -t 0 ]; then
    # Interactive TTY — prompt the user with a silent read. Empty
    # response is now valid : it means "use WebAuthn, no TOTP".
    local prompt_otp
    read -rsp "npm 2FA OTP (6 digits, or empty for WebAuthn) : " prompt_otp
    echo ""  # newline after the silent prompt
    if [ -z "$prompt_otp" ]; then
      echo "  → empty OTP : assuming WebAuthn 2FA (browser flow)" >&2
      return 0
    fi
    if ! printf '%s' "$prompt_otp" | grep -Eq '^[0-9]{6}$'; then
      echo "release: 2FA OTP must be 6 digits, got '<redacted>'" >&2
      exit 2
    fi
    OTP="$prompt_otp"
    return 0
  fi
  # Non-TTY — last chance is $NPM_OTP.
  if [ -n "${NPM_OTP:-}" ]; then
    if ! printf '%s' "$NPM_OTP" | grep -Eq '^[0-9]{6}$'; then
      echo "release: \$NPM_OTP must be 6 digits, got '<redacted>'" >&2
      exit 2
    fi
    OTP="$NPM_OTP"
    return 0
  fi
  # No OTP available — assume WebAuthn flow (browser challenge during
  # `npm publish`). This is the default for modern npm accounts.
  return 0
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
version_file=$(cat VERSION | tr -d ' \n')
if [ "$version_file" != "$EXPECTED_VERSION" ]; then
  fatal "VERSION file is '$version_file', expected '$EXPECTED_VERSION'. The release commit must be on main."
fi
ok "VERSION = $version_file"

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

# 7. CHANGELOG has the [X.Y.Z] section sealed.
# The version-only header (no date pin) is the canonical contract :
# the date is release-specific and would block the script for every
# subsequent version. Maintainers seal the date manually at archive
# time (Calliope writes the full `## [X.Y.Z] — YYYY-MM-DD` line ;
# the version-only grep here is satisfied by both pinned-date and
# date-pending forms).
escaped_version=$(printf '%s' "$EXPECTED_VERSION" | sed 's/\./\\./g')
if ! grep -qE "^## \\[${escaped_version}\\]" CHANGELOG.md; then
  fatal "CHANGELOG.md does not have a sealed '## [${EXPECTED_VERSION}]' header."
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

# ─── OTP resolution before publish ───────────────────────────────

if [ "$SKIP_NPM" = "0" ] && [ "$DRY_RUN" = "0" ]; then
  step "Resolve npm 2FA OTP"
  _resolve_otp
  ok "OTP resolved"
fi

# ─── Step 3 — Tag ────────────────────────────────────────────────

step "Step 3 — Create tag $TAG on main"
run "git tag -a '$TAG' -m 'release($EXPECTED_VERSION): see CHANGELOG.md'"
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

  current_user="$(npm whoami 2>/dev/null || echo '(not logged in)')"
  echo "  Logged in as: $current_user"
  if [ "$DRY_RUN" = "0" ] && ! npm whoami >/dev/null 2>&1; then
    if [ "$SKIP_LOGIN" = "1" ]; then
      fatal "not logged in to npm and --skip-login passed. Run \`npm login\` first or drop --skip-login."
    fi
    echo "  → triggering \`npm login\` (WebAuthn browser flow ; approve in your authenticator)"
    npm login
    if ! npm whoami >/dev/null 2>&1; then
      fatal "npm login did not produce a valid session. Aborting."
    fi
    ok "logged in as $(npm whoami)"
  fi

  run "cd cli && npm install"
  ok "cli/ deps installed"
  run "cd cli && npm run bundle"
  ok "cli/ bundle built"
  run "cd cli && npm test"
  ok "cli/ tests passed"

  # The publish step. Two modes :
  #   - WebAuthn (default, no OTP) : invoke `npm publish --access public`
  #     directly ; npm CLI triggers a browser challenge for the publish.
  #   - TOTP (legacy, $OTP set) : forward `--otp=$OTP` ; never echo the
  #     value (dry-run trace renders `<redacted>`).
  if [ "$DRY_RUN" = "1" ]; then
    if [ -n "$OTP" ]; then
      echo "    [dry-run] cd cli && npm publish --access public --otp=<redacted>"
    else
      echo "    [dry-run] cd cli && npm publish --access public  # WebAuthn flow"
    fi
  else
    if [ -n "$OTP" ]; then
      ( cd cli && npm publish --access public --otp="$OTP" )
    else
      echo "  → \`npm publish\` will trigger WebAuthn ; approve in your authenticator"
      ( cd cli && npm publish --access public )
    fi
    ok "@sdd-forge/cli@$EXPECTED_VERSION published to npm"
  fi
fi

# ─── Step 6 — GitHub release ─────────────────────────────────────

if [ "$SKIP_GH" = "1" ]; then
  step "Step 6 — GitHub release (skipped via --skip-gh)"
else
  step "Step 6 — Create GitHub release for $TAG"

  if command -v gh >/dev/null 2>&1; then
    # Extract the [X.Y.Z] section from CHANGELOG.md as release notes.
    notes_file=$(mktemp -t forge-release-notes-XXXXXX)
    awk -v ver="${EXPECTED_VERSION}" '
      $0 ~ "^## \\[" ver "\\]" { capture=1; next }
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
    echo "    Notes: copy the [${EXPECTED_VERSION}] section from CHANGELOG.md"
    echo ""
  fi
fi

# ─── Done ────────────────────────────────────────────────────────

step "Release $TAG complete"
if [ "$DRY_RUN" = "1" ]; then
  echo "  (dry-run — no changes pushed)"
else
  echo "  Tag: $TAG"
  if [ "$SKIP_NPM" = "0" ]; then echo "  npm: @sdd-forge/cli@$EXPECTED_VERSION"; fi
  echo "  Next: announce in GitHub Discussions."
fi
exit 0
