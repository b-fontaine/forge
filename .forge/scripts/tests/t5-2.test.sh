#!/usr/bin/env bash
# Forge — T.5.2 Anti-Hallucination Platform Verification Test Harness (t5-2-platform-verification)
# <!-- Audit: T.5.2 (t5-2-platform-verification) -->
#
# Validates the T5.2 deliverables :
#
#   - .claude/agents/document-specialist.md — Forge-local override
#     carrying the H2 "## Platform Verification Checklist (3-axis)"
#     (FR-T52-A-001..015 + ADR-T52-001 option A).
#   - .forge/standards/global/standards-lifecycle.md — additive bump
#     v1.0.0 → v1.1.0 with new H2 "## Platform compatibility
#     re-verification" (FR-T52-B-001..010 + ADR-T52-001 option B).
#   - .forge/standards/REVIEW.md — append-only ledger entry
#     "2026-MM-DD — standards-lifecycle.md v1.0.0 → v1.1.0"
#     (FR-T52-C-001..003 + Article XII).
#
# 8 L1 + 1 L2 = 9 tests.
# Performance budget : L1 ≤ 5 s wall-clock ; L1+L2 ≤ 15 s with
# FORGE_T52_LIVE=1 (NFR-T52-002).
#
# ADR-T52-001 — Forge-local override + standards-lifecycle embedding.
# ADR-T52-002 — L2 = pub.dev tooling smoke on flutter_bloc (opt-in).
# ADR-T52-003 — Verbatim H2 cross-referencing as drift guard.
# ADR-T52-004 — Harness structure mirrors J.7 / I.5 / K.3 pattern.

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

AGENT_FILE="$FORGE_ROOT_REAL/.claude/agents/document-specialist.md"
LIFECYCLE_STD="$FORGE_ROOT_REAL/.forge/standards/global/standards-lifecycle.md"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
CONTRIBUTING_MD="$FORGE_ROOT_REAL/docs/CONTRIBUTING.md"
LINTING_MD="$FORGE_ROOT_REAL/docs/LINTING.md"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
FORGE_CI_YML="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (8 tests)
# MANIFEST: _test_t52_l1_001_agent_file_present       — FR-T52-D-003 / FR-T52-A-001
# MANIFEST: _test_t52_l1_002_checklist_h2             — FR-T52-D-004 / FR-T52-A-003
# MANIFEST: _test_t52_l1_003_three_axes_named         — FR-T52-D-005 / FR-T52-A-004..006
# MANIFEST: _test_t52_l1_004_platform_mismatch_token  — FR-T52-D-006 / FR-T52-A-008
# MANIFEST: _test_t52_l1_005_lifecycle_v110           — FR-T52-D-007 / FR-T52-B-001
# MANIFEST: _test_t52_l1_006_re_verification_h2       — FR-T52-D-008 / FR-T52-B-005
# MANIFEST: _test_t52_l1_007_review_ledger_entry      — FR-T52-D-009 / FR-T52-C-001
# MANIFEST: _test_t52_l1_008_article_iii4_xref        — FR-T52-D-010 / FR-T52-A-012
#
# L2 (1 test, opt-in via FORGE_T52_LIVE=1 ; skip-pass otherwise)
# MANIFEST: _test_t52_l2_001_pubdev_tooling_smoke     — FR-T52-E-001..004 / ADR-T52-002

# ─── L1 tests ────────────────────────────────────────────────────

_not_implemented() {
  echo "    [FR-T52-D-???] not implemented yet (RED witness)" >&2
  return 1
}

# FR-T52-D-003 / FR-T52-A-001 — Forge-local agent file presence.
_test_t52_l1_001_agent_file_present() {
  if [ ! -f "$AGENT_FILE" ]; then
    echo "    [FR-T52-A-001] agent file missing: $AGENT_FILE" >&2; return 1
  fi
  if [ ! -s "$AGENT_FILE" ]; then
    echo "    [FR-T52-A-001] agent file empty: $AGENT_FILE" >&2; return 1
  fi
}

# FR-T52-D-004 / FR-T52-A-003 — verbatim H2 anchor.
_test_t52_l1_002_checklist_h2() {
  if [ ! -f "$AGENT_FILE" ]; then
    echo "    [FR-T52-A-003] agent file missing (pre-requisite)" >&2; return 1
  fi
  if ! grep -Fq "## Platform Verification Checklist (3-axis)" "$AGENT_FILE"; then
    echo "    [FR-T52-A-003] H2 anchor '## Platform Verification Checklist (3-axis)' missing from $AGENT_FILE" >&2
    return 1
  fi
}

# FR-T52-D-005 / FR-T52-A-004..006 — three axes named verbatim.
_test_t52_l1_003_three_axes_named() {
  if [ ! -f "$AGENT_FILE" ]; then
    echo "    [FR-T52-A-004..006] agent file missing (pre-requisite)" >&2; return 1
  fi
  if ! grep -Fq "Existence" "$AGENT_FILE"; then
    echo "    [FR-T52-A-004] axis 1 'Existence' missing from $AGENT_FILE" >&2; return 1
  fi
  if ! grep -Fq "API surface" "$AGENT_FILE"; then
    echo "    [FR-T52-A-005] axis 2 'API surface' missing from $AGENT_FILE" >&2; return 1
  fi
  if ! grep -Fq "Platform compatibility" "$AGENT_FILE"; then
    echo "    [FR-T52-A-006] axis 3 'Platform compatibility' missing from $AGENT_FILE" >&2; return 1
  fi
}

# FR-T52-D-006 / FR-T52-A-008 — [PLATFORM MISMATCH:] escalation token.
_test_t52_l1_004_platform_mismatch_token() {
  if [ ! -f "$AGENT_FILE" ]; then
    echo "    [FR-T52-A-008] agent file missing (pre-requisite)" >&2; return 1
  fi
  if ! grep -Fq "[PLATFORM MISMATCH:" "$AGENT_FILE"; then
    echo "    [FR-T52-A-008] '[PLATFORM MISMATCH:' token missing from $AGENT_FILE" >&2
    return 1
  fi
}

# FR-T52-D-007 / FR-T52-B-001 — standards-lifecycle.md frontmatter version bump.
_test_t52_l1_005_lifecycle_v110() {
  if [ ! -f "$LIFECYCLE_STD" ]; then
    echo "    [FR-T52-B-001] standards-lifecycle.md missing: $LIFECYCLE_STD" >&2; return 1
  fi
  if ! grep -E "^version: *1\.1\.0( |$)" "$LIFECYCLE_STD" >/dev/null; then
    echo "    [FR-T52-B-001] frontmatter 'version: 1.1.0' missing from $LIFECYCLE_STD" >&2
    return 1
  fi
}

# FR-T52-D-008 / FR-T52-B-005 — verbatim re-verification H2.
_test_t52_l1_006_re_verification_h2() {
  if [ ! -f "$LIFECYCLE_STD" ]; then
    echo "    [FR-T52-B-005] standards-lifecycle.md missing (pre-requisite)" >&2; return 1
  fi
  if ! grep -Fq "## Platform compatibility re-verification" "$LIFECYCLE_STD"; then
    echo "    [FR-T52-B-005] H2 '## Platform compatibility re-verification' missing from $LIFECYCLE_STD" >&2
    return 1
  fi
}

# FR-T52-D-009 / FR-T52-C-001 — REVIEW.md append-only ledger entry.
_test_t52_l1_007_review_ledger_entry() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    [FR-T52-C-001] REVIEW.md missing: $REVIEW_MD" >&2; return 1
  fi
  if ! grep -E "^## 20[0-9]{2}-[0-9]{2}-[0-9]{2} — standards-lifecycle\.md v1\.0\.0 → v1\.1\.0$" "$REVIEW_MD" >/dev/null; then
    echo "    [FR-T52-C-001] REVIEW.md ledger entry pattern missing — expected '## YYYY-MM-DD — standards-lifecycle.md v1.0.0 → v1.1.0'" >&2
    return 1
  fi
}

# FR-T52-D-010 / FR-T52-A-012 — Article III.4 (Ambiguity Protocol / anti-hallucination) cross-reference.
# Corrective : the original spec drafted "Article VIII" by mistake. Article VIII is "Infrastructure"
# in the Forge constitution ; the anti-hallucination clause is Article III.4 (Ambiguity Protocol).
_test_t52_l1_008_article_iii4_xref() {
  if [ ! -f "$AGENT_FILE" ]; then
    echo "    [FR-T52-A-012] agent file missing (pre-requisite)" >&2; return 1
  fi
  if ! grep -Fq "Article III.4" "$AGENT_FILE"; then
    echo "    [FR-T52-A-012] 'Article III.4' (Ambiguity Protocol) cross-reference missing from $AGENT_FILE" >&2
    return 1
  fi
}

# ─── L2 tests (opt-in pub.dev tooling smoke per ADR-T52-002) ─────

# FR-T52-E-001..004 — pub.dev smoke on flutter_bloc, gated by FORGE_T52_LIVE=1.
_test_t52_l2_001_pubdev_tooling_smoke() {
  if [ "${FORGE_T52_LIVE:-0}" != "1" ]; then
    echo "    [INFO: L2 pub.dev smoke gated by FORGE_T52_LIVE=1, skipping]" >&2
    return 0
  fi
  if ! command -v curl >/dev/null 2>&1; then
    echo "    [SKIP: curl not installed on PATH]" >&2
    return 0
  fi

  local url="https://pub.dev/packages/flutter_bloc"
  local body
  if ! body="$(timeout 20 curl --max-time 10 --silent --fail --show-error -L "$url" 2>&1)"; then
    echo "    [SKIP: pub.dev unreachable — $body]" >&2
    return 0
  fi

  # pub.dev's chip label is "Platform" (singular) in the package
  # detail panel ; grep case-insensitive to cover both renderings.
  if ! printf '%s' "$body" | grep -iEq "[Pp]latform"; then
    echo "    [FR-T52-E-002] pub.dev page for flutter_bloc missing 'Platform' chip label — regression?" >&2
    return 1
  fi

  local found=0 plat
  for plat in Android iOS Linux macOS Web Windows; do
    if printf '%s' "$body" | grep -Fq "$plat"; then
      found=1; break
    fi
  done
  if [ "$found" -ne 1 ]; then
    echo "    [FR-T52-E-002] pub.dev page for flutter_bloc missing all platform tokens (Android/iOS/Linux/macOS/Web/Windows)" >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T.5.2 — t5-2-platform-verification — level $LEVEL ──"

  # L1 always runs.
  run_test _test_t52_l1_001_agent_file_present
  run_test _test_t52_l1_002_checklist_h2
  run_test _test_t52_l1_003_three_axes_named
  run_test _test_t52_l1_004_platform_mismatch_token
  run_test _test_t52_l1_005_lifecycle_v110
  run_test _test_t52_l1_006_re_verification_h2
  run_test _test_t52_l1_007_review_ledger_entry
  run_test _test_t52_l1_008_article_iii4_xref

  # L2 runs when --level includes 2 or "all".
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — pub.dev tooling smoke on flutter_bloc (opt-in FORGE_T52_LIVE=1)"
    run_test _test_t52_l2_001_pubdev_tooling_smoke
  fi

  print_summary
}

main "$@"
