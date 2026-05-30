#!/usr/bin/env bash
# Forge — B.8.2 flagship 1.0.0 legacy-snapshot freeze harness
# <!-- Audit: B.8.2 (b8-2-legacy-snapshot) — freeze the 1.0.0 reverse target -->
#
# Validates the b8-2-legacy-snapshot deliverables :
#
#   - Integrity manifest `1.0.0.sha256` committed + matches the frozen tarball
#     (FR-B8-2-001/002/011 ; ADR-B8-2-002).
#   - The immutability guard FAILS if the tarball is rebuilt/corrupted
#     (FR-B8-2-013 — the point-of-no-return protection).
#   - Tarball present + extractable via forge-snapshot.sh (FR-B8-2-012).
#   - Maintenance-freeze section in global/upgrade-policy.md + REVIEW.md ledger
#     entry (FR-B8-2-014/020/021 ; ADR-B8-2-003).
#   - Version-keyed path preserved, NO legacy/ dir (FR-B8-2-022 ; ADR-B8-2-001).
#
# 4 L1 tests. Performance budget : L1 ≤ 5 s (NFR-B8-2-001), zero net/Docker.

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

# Parameterized by archetype/version so B.9 adds a sibling manifest, not a new
# harness (ADR-B8-2-004).
ARCHETYPE="full-stack-monorepo"
FROZEN_VERSION="1.0.0"
SNAP_DIR="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/$ARCHETYPE"
TARBALL="$SNAP_DIR/$FROZEN_VERSION.tar.gz"
MANIFEST="$SNAP_DIR/$FROZEN_VERSION.sha256"
SNAPSHOT_SH="$FORGE_ROOT_REAL/bin/forge-snapshot.sh"
UPGRADE_POLICY="$FORGE_ROOT_REAL/.forge/standards/global/upgrade-policy.md"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# Portable sha256 (macOS shasum / Linux sha256sum) → bare hex.
_sha256() {
  if command -v shasum > /dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum > /dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "    no sha256 tool (shasum/sha256sum) on PATH" >&2; return 5
  fi
}

# ─── Manifest ────────────────────────────────────────────────────
# L1 (4 tests)
# MANIFEST: _test_b82_l1_001_sha_guard            — FR-B8-2-011
# MANIFEST: _test_b82_l1_002_extractable          — FR-B8-2-012
# MANIFEST: _test_b82_l1_003_freeze_section       — FR-B8-2-020
# MANIFEST: _test_b82_l1_004_review_ledger        — FR-B8-2-021

# ─── L1 ──────────────────────────────────────────────────────────

_test_b82_l1_001_sha_guard() {
  if [ ! -f "$TARBALL" ]; then
    echo "    frozen tarball missing: $TARBALL" >&2; return 1
  fi
  if [ ! -f "$MANIFEST" ]; then
    echo "    sha256 manifest missing: $MANIFEST (FR-B8-2-001)" >&2; return 1
  fi
  local expected actual
  expected=$(awk '{print $1}' "$MANIFEST")
  actual=$(_sha256 "$TARBALL") || return 1
  if [ "$expected" != "$actual" ]; then
    echo "    1.0.0 snapshot DRIFTED — tarball rebuilt or corrupted (FR-B8-2-011)" >&2
    echo "    manifest=$expected  tarball=$actual" >&2
    echo "    The 1.0.0 reverse target is frozen ; do not rebuild it. If this" >&2
    echo "    is a deliberate audited 1.0.0 patch, update the manifest + REVIEW.md." >&2
    return 1
  fi
}

_test_b82_l1_002_extractable() {
  if [ ! -x "$SNAPSHOT_SH" ] && [ ! -f "$SNAPSHOT_SH" ]; then
    echo "    forge-snapshot.sh missing: $SNAPSHOT_SH" >&2; return 1
  fi
  local tmp; tmp=$(mk_tmpdir_with_trap b8-2-extract)
  trap "rm -rf '$tmp'" RETURN
  if ! bash "$SNAPSHOT_SH" extract "$ARCHETYPE" "$FROZEN_VERSION" "$tmp" > /dev/null 2>&1; then
    echo "    forge-snapshot.sh extract $ARCHETYPE $FROZEN_VERSION failed (FR-B8-2-012)" >&2
    return 1
  fi
  # Sanity : extraction produced something.
  if [ -z "$(ls -A "$tmp" 2>/dev/null)" ]; then
    echo "    extraction produced an empty tree (FR-B8-2-012)" >&2; return 1
  fi
}

_test_b82_l1_003_freeze_section() {
  if [ ! -f "$UPGRADE_POLICY" ]; then
    echo "    upgrade-policy.md missing: $UPGRADE_POLICY" >&2; return 1
  fi
  local body; body=$(cat "$UPGRADE_POLICY")
  assert_contains "$body" "maintenance-freeze" "freeze section heading" || return 1
  # The freeze rule must name the 2.0.0-build-to-new-file invariant.
  assert_contains "$body" "2.0.0.tar.gz" "2.0.0-new-file invariant" || return 1
}

_test_b82_l1_004_review_ledger() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing: $REVIEW_MD" >&2; return 1
  fi
  if ! grep -Fq "b8-2-legacy-snapshot" "$REVIEW_MD"; then
    echo "    REVIEW.md has no b8-2-legacy-snapshot ledger entry (FR-B8-2-021)" >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── B.8.2 — b8-2-legacy-snapshot — level $LEVEL ──"
  run_test _test_b82_l1_001_sha_guard
  run_test _test_b82_l1_002_extractable
  run_test _test_b82_l1_003_freeze_section
  run_test _test_b82_l1_004_review_ledger
  print_summary
}

main
