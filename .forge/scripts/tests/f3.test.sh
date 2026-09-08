#!/usr/bin/env bash
# Forge — F.3 Release Script Fix Test Harness (f3-release-script-fix)
# <!-- Audit: F.3 (f3-release-script-fix) -->
#
# Validates the F.3 deliverables :
#
#   - scripts/release.sh — generic release helper (renamed from
#     scripts/release-v0.3.0.sh) with --version + --otp plumbing,
#     subshell isolation, and OTP non-disclosure.
#   - scripts/release-v0.3.0.sh — MUST be removed (no symlink ;
#     ADR-F3-001).
#   - GOVERNANCE.md § Release Process updated to document the new
#     invocation form.
#   - CHANGELOG.md [Unreleased] entry citing f3-release-script-fix.
#
# 12 L1 + 1 L2 = 13 tests.
# (10 + 1 at F.3 archive time ; FR-F3-140/141 added 2026-09-08 — see the
#  ADDENDUM in .forge/changes/f3-release-script-fix/specs.md.)
# Performance budget : L1 ≤ 3 s wall-clock (NFR-F3-001).

set -uo pipefail

LEVEL="1"
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  case "$arg" in --level=*) LEVEL="${arg#*=}" ;; esac
  prev="$arg"
done

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

RELEASE_SCRIPT="$FORGE_ROOT_REAL/scripts/release.sh"
OLD_RELEASE_SCRIPT="$FORGE_ROOT_REAL/scripts/release-v0.3.0.sh"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
GOVERNANCE_MD="$FORGE_ROOT_REAL/GOVERNANCE.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (12 tests)
# MANIFEST: _test_f3_001_script_presence            — FR-F3-001
# MANIFEST: _test_f3_002_old_script_removed         — FR-F3-004
# MANIFEST: _test_f3_003_audit_comment              — FR-F3-002
# MANIFEST: _test_f3_004_strict_mode                — FR-F3-003
# MANIFEST: _test_f3_005_version_flag_handling      — FR-F3-020 / FR-F3-021 / FR-F3-022 / FR-F3-023
# MANIFEST: _test_f3_006_otp_flag_handling          — FR-F3-040 / FR-F3-041 / FR-F3-042 / FR-F3-043
# MANIFEST: _test_f3_007_no_eval_cd                 — FR-F3-063
# MANIFEST: _test_f3_008_top_level_cd_count         — FR-F3-061 / FR-F3-062
# MANIFEST: _test_f3_009_npm_publish_otp_forward    — FR-F3-044
# MANIFEST: _test_f3_010_changelog_entry            — FR-F3-120
# MANIFEST: _test_f3_011_cli_tests_in_preflight     — FR-F3-140
# MANIFEST: _test_f3_012_cli_tests_precede_tag      — FR-F3-141
#
# L2 (1 test, opt-in via FORGE_F3_LIVE=1 ; skip-pass otherwise)
# MANIFEST: _test_f3_l2_dry_run_otp_forward         — FR-F3-044 / FR-F3-047 / ADR-F3-004

# ─── L1 tests ────────────────────────────────────────────────────

_not_implemented() {
  echo "    not implemented yet (RED witness)" >&2
  return 1
}

# FR-F3-001 — new script exists + executable
_test_f3_001_script_presence() {
  if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "    release script missing: $RELEASE_SCRIPT" >&2; return 1
  fi
  if [ ! -x "$RELEASE_SCRIPT" ]; then
    echo "    release script not executable: $RELEASE_SCRIPT" >&2; return 1
  fi
}

# FR-F3-004 — old script removed (no symlink ; ADR-F3-001)
_test_f3_002_old_script_removed() {
  # -e catches both regular files and symlinks. The old name must
  # not exist at all.
  if [ -e "$OLD_RELEASE_SCRIPT" ] || [ -L "$OLD_RELEASE_SCRIPT" ]; then
    echo "    old script unexpectedly present: $OLD_RELEASE_SCRIPT" >&2
    echo "    ADR-F3-001 requires deletion, no symlink" >&2
    return 1
  fi
}

# FR-F3-002 — audit comment in first 10 lines
_test_f3_003_audit_comment() {
  if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "    release script missing: $RELEASE_SCRIPT" >&2; return 1
  fi
  if ! head -10 "$RELEASE_SCRIPT" | grep -Fq "Audit: F.3 (f3-release-script-fix)"; then
    echo "    audit comment missing in first 10 lines of $RELEASE_SCRIPT" >&2
    return 1
  fi
}

# FR-F3-003 — strict mode `set -euo pipefail` in first 50 lines
_test_f3_004_strict_mode() {
  if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "    release script missing: $RELEASE_SCRIPT" >&2; return 1
  fi
  if ! head -50 "$RELEASE_SCRIPT" | grep -Eq "^set -euo pipefail"; then
    echo "    'set -euo pipefail' missing in first 50 lines" >&2
    return 1
  fi
}

# FR-F3-020..023 — --version flag handling (validation + required)
_test_f3_005_version_flag_handling() {
  if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "    release script missing: $RELEASE_SCRIPT" >&2; return 1
  fi
  # The script must parse `--version` and validate via the X.Y.Z regex.
  if ! grep -Eq "[-]{2}version" "$RELEASE_SCRIPT"; then
    echo "    '--version' flag not present in $RELEASE_SCRIPT" >&2
    return 1
  fi
  # Validation regex literal must appear (semver triple-dot core). The
  # X.Y.Z prefix is required ; what follows may be the strict `$` end-anchor
  # (legacy form) OR an optional prerelease group `(-...)?$` (SemVer 2 form
  # added 2026-05-19 to support `0.4.0-rc.1` releases). Grep the prefix
  # without `$` so both encodings satisfy the assertion.
  if ! grep -Fq '^[0-9]+\.[0-9]+\.[0-9]+' "$RELEASE_SCRIPT"; then
    echo "    semver validation regex missing for --version" >&2
    return 1
  fi
  # TAG = v$VERSION derivation.
  if ! grep -Eq 'TAG=\"?v\$\{?VERSION\}?\"?' "$RELEASE_SCRIPT"; then
    echo "    'TAG=\"v\$VERSION\"' derivation missing" >&2
    return 1
  fi
}

# FR-F3-040..043 — --otp flag + NPM_OTP env fallback
_test_f3_006_otp_flag_handling() {
  if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "    release script missing: $RELEASE_SCRIPT" >&2; return 1
  fi
  # --otp flag present.
  if ! grep -Eq "[-]{2}otp" "$RELEASE_SCRIPT"; then
    echo "    '--otp' flag not present in $RELEASE_SCRIPT" >&2
    return 1
  fi
  # 6-digit OTP validation.
  if ! grep -Fq '^[0-9]{6}$' "$RELEASE_SCRIPT"; then
    echo "    '^[0-9]{6}\$' OTP validation regex missing" >&2
    return 1
  fi
  # NPM_OTP env var fallback referenced.
  if ! grep -Fq "NPM_OTP" "$RELEASE_SCRIPT"; then
    echo "    NPM_OTP env-var fallback missing" >&2
    return 1
  fi
  # Interactive read for OTP (read -rsp or read -sp).
  if ! grep -Eq "read [-]r?sp?" "$RELEASE_SCRIPT" \
     && ! grep -Eq "read[[:space:]]+[-][a-z]*s" "$RELEASE_SCRIPT"; then
    echo "    interactive 'read -rsp' / 'read -sp' OTP prompt missing" >&2
    return 1
  fi
}

# FR-F3-063 — no bare `eval cd ...` anywhere
_test_f3_007_no_eval_cd() {
  if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "    release script missing: $RELEASE_SCRIPT" >&2; return 1
  fi
  # Forbid the eval-then-cd pattern. We grep for several variants
  # because shell expansion makes the literal form depend on the
  # author's quoting.
  if grep -Eq 'eval[[:space:]]+["'"'"']?cd[[:space:]]' "$RELEASE_SCRIPT"; then
    echo "    forbidden 'eval cd ...' pattern found" >&2
    return 1
  fi
  if grep -Eq 'eval[[:space:]]+[\"'"'"']cd[[:space:]]' "$RELEASE_SCRIPT"; then
    echo "    forbidden quoted 'eval \"cd ...\"' pattern found" >&2
    return 1
  fi
}

# FR-F3-061 / FR-F3-062 — top-level `cd` count = 1 (anchor only)
_test_f3_008_top_level_cd_count() {
  if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "    release script missing: $RELEASE_SCRIPT" >&2; return 1
  fi
  # Count lines that start (after optional whitespace) with `cd `
  # and whose first non-whitespace token is the unqualified `cd`
  # command. Lines inside a subshell still match this regex by
  # design — we accept that as a soft constraint and rely on
  # subshell parens being structurally visible in the diff. The
  # canonical check is that the line `cd "$REPO_ROOT"` exists
  # exactly once at top level.
  local anchor_count
  anchor_count="$(grep -Ec '^cd[[:space:]]+\"\$REPO_ROOT\"' "$RELEASE_SCRIPT" || true)"
  if [ "$anchor_count" -ne 1 ]; then
    echo "    top-level anchor 'cd \"\$REPO_ROOT\"' count = $anchor_count, expected 1" >&2
    return 1
  fi
  # Any other top-level cd line (not under a `(` and not indented
  # inside a function or block) would be a regression. We assert
  # there is exactly one top-level `cd` *to a fixed directory other
  # than `$REPO_ROOT`* (none allowed). The pattern
  # `^cd[[:space:]]+[^(]` (cd not followed by a `(`) caught from
  # the start of a line is what we want.
  local stray_top_cd
  stray_top_cd="$(grep -Ec '^cd[[:space:]]+' "$RELEASE_SCRIPT" || true)"
  if [ "$stray_top_cd" -gt 1 ]; then
    echo "    stray top-level 'cd ...' lines detected (count=$stray_top_cd, anchor=1 expected)" >&2
    return 1
  fi
}

# FR-F3-044 — npm publish carries --otp forwarding
_test_f3_009_npm_publish_otp_forward() {
  if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "    release script missing: $RELEASE_SCRIPT" >&2; return 1
  fi
  # The publish invocation must include `--otp` forwarding. We
  # accept several forms : `--otp="$OTP"`, `--otp "$OTP"`,
  # `--otp=$OTP`. The redacted dry-run line `--otp=<redacted>` is
  # ALSO acceptable because it proves the flag is plumbed.
  if ! grep -Eq 'npm[[:space:]]+publish[[:space:]].*--otp' "$RELEASE_SCRIPT" \
     && ! grep -Eq 'npm publish.*--otp' "$RELEASE_SCRIPT"; then
    echo "    'npm publish ... --otp' forwarding missing" >&2
    return 1
  fi
}

# FR-F3-120 — CHANGELOG.md entry
_test_f3_010_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing: $CHANGELOG_MD" >&2; return 1
  fi
  if ! grep -Fq "f3-release-script-fix" "$CHANGELOG_MD"; then
    echo "    'f3-release-script-fix' reference missing in CHANGELOG.md" >&2
    return 1
  fi
  if ! grep -Fq "scripts/release.sh" "$CHANGELOG_MD"; then
    echo "    'scripts/release.sh' phrase missing in CHANGELOG.md" >&2
    return 1
  fi
}

# Line number of the first EXECUTABLE occurrence of a pattern in
# release.sh, or 0. Two exclusions matter and both cost a real bug if
# dropped: `^[^#]*` drops comment lines, and the `fatal|echo|warn` filter
# drops lines where the pattern only appears inside a user-facing message.
# Without the second one, `fatal "... re-run \`cd cli && npm test\` ..."`
# satisfied an ordering assertion about the command it merely names — the
# same substring-satisfaction trap that killed three b9-3 rows.
_release_line() {
  grep -nE "^[^#]*$1" "$RELEASE_SCRIPT" 2>/dev/null \
    | grep -vE ':[[:space:]]*(fatal|echo|warn|ok)[[:space:]]' \
    | head -1 | cut -d: -f1 || echo 0
}

# FR-F3-140 — the cli/ vitest suite runs inside the pre-flight block
_test_f3_011_cli_tests_in_preflight() {
  if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "    release script missing: $RELEASE_SCRIPT" >&2; return 1
  fi
  # `^[^#]*` keeps comment lines out of the match : the header documents
  # the same command text, and matching it would let a comment satisfy a
  # test about executable order.
  local l_test l_pre l_tag
  l_test=$(_release_line 'cd cli && npm test([^A-Za-z0-9_-]|$)')
  l_pre=$(grep -nF 'step "Pre-flight checks"' "$RELEASE_SCRIPT" | head -1 | cut -d: -f1 || echo 0)
  l_tag=$(_release_line 'git tag -a')
  if [ "${l_test:-0}" -eq 0 ]; then
    echo "    'cd cli && npm test' absent from release.sh (FR-F3-140)" >&2; return 1
  fi
  if [ "${l_pre:-0}" -eq 0 ] || [ "${l_tag:-0}" -eq 0 ]; then
    echo "    anchors not found (preflight=$l_pre, tag=$l_tag) (FR-F3-140)" >&2; return 1
  fi
  if [ "$l_test" -le "$l_pre" ] || [ "$l_test" -ge "$l_tag" ]; then
    echo "    'cd cli && npm test' (line $l_test) MUST sit inside the pre-flight block, between 'step \"Pre-flight checks\"' (line $l_pre) and the tag step (line $l_tag) (FR-F3-140)" >&2
    return 1
  fi
}

# FR-F3-141 — a red CLI suite MUST be able to stop the tag
_test_f3_012_cli_tests_precede_tag() {
  if [ ! -f "$RELEASE_SCRIPT" ]; then
    echo "    release script missing: $RELEASE_SCRIPT" >&2; return 1
  fi
  # Regression witness : v0.5.0 was tagged and pushed with T5.1.A red,
  # because `cd cli && npm test` sat at line 362 while `git tag -a` was at
  # 328 and `git push origin` at 334. The tag had to be moved by hand.
  # Static line-order inspection — the script pushes real tags, so it is
  # never executed here (NFR-F3-001 also caps L1 at 3 s).
  local l_test l_tag l_push
  l_test=$(_release_line 'cd cli && npm test([^A-Za-z0-9_-]|$)')
  l_tag=$(_release_line 'git tag -a')
  l_push=$(_release_line 'git push origin')
  if [ "${l_test:-0}" -eq 0 ]; then
    echo "    'cd cli && npm test' absent from release.sh (FR-F3-141)" >&2; return 1
  fi
  if [ "${l_tag:-0}" -eq 0 ] || [ "${l_push:-0}" -eq 0 ]; then
    echo "    'git tag -a' / 'git push origin' anchors not found (tag=$l_tag, push=$l_push) (FR-F3-141)" >&2; return 1
  fi
  if [ "$l_test" -ge "$l_tag" ] || [ "$l_test" -ge "$l_push" ]; then
    echo "    'cd cli && npm test' (line $l_test) MUST precede 'git tag -a' (line $l_tag) and 'git push origin' (line $l_push) — otherwise a red CLI test cannot stop the tag (FR-F3-141)" >&2
    return 1
  fi
}

# ─── L2 tests (opt-in via FORGE_F3_LIVE=1 ; skip-pass otherwise) ─

# FR-F3-044 / FR-F3-047 / ADR-F3-004 — dry-run OTP forward + redaction
_test_f3_l2_dry_run_otp_forward() {
  if [ "${FORGE_F3_LIVE:-0}" != "1" ]; then
    echo "    [INFO: L2 dry-run gated by FORGE_F3_LIVE=1, skipping]" >&2
    return 0
  fi
  if [ ! -x "$RELEASE_SCRIPT" ]; then
    echo "    release script not executable: $RELEASE_SCRIPT" >&2
    return 1
  fi
  # Build a tmpdir fixture with the minimum surface the script
  # expects under its $REPO_ROOT (which is derived from its own
  # path's parent). We materialise a fake $REPO_ROOT, copy the
  # script in, and run it from there. The pre-flight checks 1-3
  # need a git repo on `main` ; we monkey-patch by exporting a
  # GIT_DIR that points at a tiny fixture repo we initialise.
  local fixture
  fixture="$(mk_tmpdir_with_trap forge-f3-l2)"
  # shellcheck disable=SC2064
  trap "rm -rf '$fixture'" RETURN

  # Stage the script under <fixture>/scripts/release.sh so that
  # the script's REPO_ROOT derivation (`dirname/..`) resolves to
  # <fixture>.
  mkdir -p "$fixture/scripts" "$fixture/cli" "$fixture/.git"
  cp "$RELEASE_SCRIPT" "$fixture/scripts/release.sh"
  chmod +x "$fixture/scripts/release.sh"

  # Minimal VERSION + cli/package.json + CHANGELOG.
  echo "0.0.1" > "$fixture/VERSION"
  cat > "$fixture/cli/package.json" <<'PKG'
{
  "name": "@sdd-forge/cli",
  "version": "0.0.1"
}
PKG
  cat > "$fixture/CHANGELOG.md" <<'LOG'
# Changelog

## [Unreleased]

## [0.0.1]

### Added

- fixture release.
LOG

  # Minimal git fixture : initialise, commit, set HEAD to main.
  ( cd "$fixture" \
    && git init -q -b main \
    && git config user.email "fix@test" \
    && git config user.name "fix" \
    && git add . \
    && git commit -q -m "init" \
    && git remote add origin "$fixture" \
    && git update-ref refs/remotes/origin/main HEAD ) >/dev/null 2>&1

  # Run the script in dry-run mode with --otp 654321 and capture
  # all output. We skip the gh release step since gh isn't part
  # of this assertion ; the publish step is the focus.
  local out
  out="$(cd "$fixture" && bash scripts/release.sh \
    --dry-run --version 0.0.1 --otp 654321 --skip-gh 2>&1 || true)"

  # Assertion 1 : the dry-run trace mentions `npm publish`.
  if ! printf '%s\n' "$out" | grep -Fq "npm publish"; then
    echo "    dry-run trace missing 'npm publish'" >&2
    printf '%s\n' "$out" | head -40 | sed 's/^/      /' >&2
    return 1
  fi

  # Assertion 2 : the dry-run trace shows the OTP flag forwarded.
  if ! printf '%s\n' "$out" | grep -Eq -- '--otp[= ]?(<redacted>|654321)'; then
    echo "    dry-run trace missing '--otp' forwarding" >&2
    printf '%s\n' "$out" | head -40 | sed 's/^/      /' >&2
    return 1
  fi

  # Assertion 3 : the OTP literal '654321' MUST be redacted ; it
  # MUST NOT appear in the trace.
  if printf '%s\n' "$out" | grep -Fq "654321"; then
    echo "    OTP literal '654321' leaked into dry-run trace (FR-F3-045 violation)" >&2
    printf '%s\n' "$out" | head -40 | sed 's/^/      /' >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── F.3 — f3-release-script-fix — level $LEVEL ──"

  # L1 always runs.
  run_test _test_f3_001_script_presence
  run_test _test_f3_002_old_script_removed
  run_test _test_f3_003_audit_comment
  run_test _test_f3_004_strict_mode
  run_test _test_f3_005_version_flag_handling
  run_test _test_f3_006_otp_flag_handling
  run_test _test_f3_007_no_eval_cd
  run_test _test_f3_008_top_level_cd_count
  run_test _test_f3_009_npm_publish_otp_forward
  run_test _test_f3_010_changelog_entry
  run_test _test_f3_011_cli_tests_in_preflight
  run_test _test_f3_012_cli_tests_precede_tag

  # L2 runs when --level includes 2 or "all".
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — dry-run OTP forward (opt-in FORGE_F3_LIVE=1)"
    run_test _test_f3_l2_dry_run_otp_forward
  fi

  print_summary
}

main "$@"
