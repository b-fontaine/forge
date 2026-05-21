#!/usr/bin/env bash
# Forge — T5.3.3 vitest globalSetup bundle preflight harness
# <!-- Audit: T5.3.3 (t5-3-3-vitest-bundle-preflight) -->
#
# Validates the T5.3.3 deliverables :
#
#   - `cli/test/global-setup.ts` exists, with audit comment + spawn npm bundle.
#   - `cli/vitest.config.ts` wires `globalSetup: "./test/global-setup.ts"`.
#   - CHANGELOG.md references the change.
#
# 5 L1 tests. No L2 (the inverse proof — running vitest against a stale
# cli/assets/ — is intrinsically covered by the existing e2e suite).
# Performance budget : L1 ≤ 1 s wall-clock (NFR-T533 implicit, same as T5.3.1).

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

GLOBAL_SETUP="$FORGE_ROOT_REAL/cli/test/global-setup.ts"
VITEST_CONFIG="$FORGE_ROOT_REAL/cli/vitest.config.ts"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (5 tests)
# MANIFEST: _test_t533_l1_001_global_setup_exists        — FR-T533-001
# MANIFEST: _test_t533_l1_002_global_setup_audit_comment — FR-T533-005
# MANIFEST: _test_t533_l1_003_global_setup_spawns_bundle — FR-T533-003 / FR-T533-004
# MANIFEST: _test_t533_l1_004_vitest_config_wired        — FR-T533-020
# MANIFEST: _test_t533_l1_005_changelog_entry            — FR-T533-060

# ─── L1 tests ────────────────────────────────────────────────────

_test_t533_l1_001_global_setup_exists() {
  if [ ! -f "$GLOBAL_SETUP" ]; then
    echo "    cli/test/global-setup.ts missing (FR-T533-001)" >&2
    return 1
  fi
}

_test_t533_l1_002_global_setup_audit_comment() {
  if [ ! -f "$GLOBAL_SETUP" ]; then
    echo "    cli/test/global-setup.ts missing" >&2; return 1
  fi
  if ! grep -Fq 'T5.3.3 (t5-3-3-vitest-bundle-preflight)' "$GLOBAL_SETUP"; then
    echo "    audit comment missing in global-setup.ts (FR-T533-005)" >&2
    return 1
  fi
}

_test_t533_l1_003_global_setup_spawns_bundle() {
  if [ ! -f "$GLOBAL_SETUP" ]; then
    echo "    cli/test/global-setup.ts missing" >&2; return 1
  fi
  if ! grep -Eq 'spawnSync|spawn\(' "$GLOBAL_SETUP"; then
    echo "    global-setup.ts does not call spawnSync/spawn (FR-T533-003)" >&2
    return 1
  fi
  if ! grep -Fq 'bundle' "$GLOBAL_SETUP" || ! grep -Fq 'npm' "$GLOBAL_SETUP"; then
    echo "    global-setup.ts does not invoke 'npm ... bundle' (FR-T533-003)" >&2
    return 1
  fi
}

_test_t533_l1_004_vitest_config_wired() {
  if [ ! -f "$VITEST_CONFIG" ]; then
    echo "    cli/vitest.config.ts missing" >&2; return 1
  fi
  if ! grep -Fq 'globalSetup' "$VITEST_CONFIG"; then
    echo "    cli/vitest.config.ts missing globalSetup key (FR-T533-020)" >&2
    return 1
  fi
  if ! grep -Fq './test/global-setup.ts' "$VITEST_CONFIG" && \
     ! grep -Fq './test/global-setup' "$VITEST_CONFIG"; then
    echo "    cli/vitest.config.ts globalSetup does not reference ./test/global-setup.ts (FR-T533-020)" >&2
    return 1
  fi
}

_test_t533_l1_005_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing" >&2; return 1
  fi
  if ! grep -Fq "t5-3-3-vitest-bundle-preflight" "$CHANGELOG_MD"; then
    echo "    CHANGELOG.md missing t5-3-3-vitest-bundle-preflight entry (FR-T533-060)" >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T5.3.3 — t5-3-3-vitest-bundle-preflight — level $LEVEL ──"

  run_test _test_t533_l1_001_global_setup_exists
  run_test _test_t533_l1_002_global_setup_audit_comment
  run_test _test_t533_l1_003_global_setup_spawns_bundle
  run_test _test_t533_l1_004_vitest_config_wired
  run_test _test_t533_l1_005_changelog_entry

  print_summary
}

main "$@"
