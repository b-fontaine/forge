#!/usr/bin/env bash
# Forge — T.5 Phase B Flutter OTel Dart API Realign Harness
# <!-- Audit: T.5 (t5-otel-dart-api-realign) — Q-004 follow-up to t5-otel-app -->
#
# Validates the `.forge/standards/flutter/opentelemetry.md` v1.0.0 -> v1.1.0
# realign : frontmatter pins + verified `opentelemetry: 0.18.11` (Workiva)
# API surface present + every legacy v1.0.0 fabricated identifier absent +
# REVIEW.md ledger entry appended + CI workflow registration.
#
# 12 L1 hermetic tests. No L2 lane — the Dart compile lane lives in
# t5-otel-app.test.sh (`_test_ota_l2_002_flutter_analyze`) and flips
# from xfail to GREEN in a separate follow-up commit on the t5-otel-app
# branch AFTER this change merges.
#
# Performance budget : L1 ≤ 3 s wall-clock (NFR-FOT-DA-005).

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

STD_FOT="$FORGE_ROOT_REAL/.forge/standards/flutter/opentelemetry.md"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
WORKFLOW="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (12 tests) — all hermetic, no toolchain, no network
# MANIFEST: _test_fda_001_frontmatter_block         — FR-FOT-DA-001
# MANIFEST: _test_fda_002_frontmatter_version_110   — FR-FOT-DA-002
# MANIFEST: _test_fda_003_frontmatter_last_reviewed — FR-FOT-DA-003
# MANIFEST: _test_fda_004_frontmatter_pkg_metadata  — FR-FOT-DA-004
# MANIFEST: _test_fda_011_setup_collector_exporter  — FR-FOT-DA-011
# MANIFEST: _test_fda_014_setup_tracer_provider     — FR-FOT-DA-014 / FR-FOT-DA-030
# MANIFEST: _test_fda_023_interceptor_status_ok     — FR-FOT-DA-023 / FR-FOT-DA-040
# MANIFEST: _test_fda_041_no_legacy_with_span_method — FR-FOT-DA-041 / FR-FOT-DA-022
# MANIFEST: _test_fda_050_no_legacy_identifiers     — FR-FOT-DA-050..FR-FOT-DA-055
# MANIFEST: _test_fda_060_workiva_status_callout    — FR-FOT-DA-060 / FR-FOT-DA-061
# MANIFEST: _test_fda_080_review_entry_present      — FR-FOT-DA-080..FR-FOT-DA-082
# MANIFEST: _test_fda_100_workflow_registers_harness — FR-FOT-DA-100

# ─── L1 tests ───────────────────────────────────────────────────

# FR-FOT-DA-001 — Standard carries a YAML frontmatter block
_test_fda_001_frontmatter_block() {
  if [ ! -f "$STD_FOT" ]; then
    echo "    standard missing: $STD_FOT" >&2; return 1
  fi
  # Frontmatter MUST be the very first non-empty content : line 1 == '---'.
  local first
  first="$(head -n 1 "$STD_FOT")"
  if [ "$first" != "---" ]; then
    echo "    line 1 is not '---' frontmatter delimiter (got: '$first')" >&2; return 1
  fi
  # There MUST be a closing '---' delimiter within the first 20 lines.
  if ! head -n 20 "$STD_FOT" | tail -n +2 | grep -q "^---$"; then
    echo "    closing '---' delimiter missing within first 20 lines" >&2; return 1
  fi
}

# FR-FOT-DA-002 — version: 1.1.0 in the frontmatter
_test_fda_002_frontmatter_version_110() {
  if ! head -n 20 "$STD_FOT" | grep -q "^version: 1.1.0$"; then
    echo "    'version: 1.1.0' not found in frontmatter (first 20 lines)" >&2; return 1
  fi
}

# FR-FOT-DA-003 — last_reviewed: 2026-05-11 in the frontmatter
_test_fda_003_frontmatter_last_reviewed() {
  if ! head -n 20 "$STD_FOT" | grep -q "^last_reviewed: 2026-05-11$"; then
    echo "    'last_reviewed: 2026-05-11' not found in frontmatter" >&2; return 1
  fi
}

# FR-FOT-DA-004 — pkg metadata pins in the frontmatter
_test_fda_004_frontmatter_pkg_metadata() {
  local fm
  fm="$(head -n 20 "$STD_FOT")"
  for needle in "pkg: opentelemetry" "pkg_version: 0.18.11" "pkg_maintainer: Workiva"; do
    if ! printf '%s' "$fm" | grep -q "^${needle}$"; then
      echo "    frontmatter pkg metadata missing: '$needle'" >&2; return 1
    fi
  done
  if ! printf '%s' "$fm" | grep -q "pub.dev/packages/opentelemetry"; then
    echo "    pkg_source URL not found in frontmatter" >&2; return 1
  fi
}

# FR-FOT-DA-011 — Setup uses CollectorExporter(Uri.parse(...))
_test_fda_011_setup_collector_exporter() {
  if ! grep -q "CollectorExporter(Uri\.parse(" "$STD_FOT"; then
    echo "    'CollectorExporter(Uri.parse(' not found in $STD_FOT" >&2; return 1
  fi
}

# FR-FOT-DA-014 + FR-FOT-DA-030 — TracerProviderBase + ParentBasedSampler(AlwaysOnSampler())
_test_fda_014_setup_tracer_provider() {
  if ! grep -q "TracerProviderBase(" "$STD_FOT"; then
    echo "    'TracerProviderBase(' not found in $STD_FOT" >&2; return 1
  fi
  if ! grep -q "ParentBasedSampler(AlwaysOnSampler())" "$STD_FOT"; then
    echo "    'ParentBasedSampler(AlwaysOnSampler())' not found in $STD_FOT" >&2; return 1
  fi
}

# FR-FOT-DA-023 + FR-FOT-DA-040 — StatusCode.ok present AND SpanStatusCode absent
_test_fda_023_interceptor_status_ok() {
  if ! grep -q "StatusCode\.ok" "$STD_FOT"; then
    echo "    'StatusCode.ok' not found in $STD_FOT" >&2; return 1
  fi
  if grep -q "SpanStatusCode" "$STD_FOT"; then
    echo "    forbidden legacy 'SpanStatusCode' still present in $STD_FOT" >&2; return 1
  fi
}

# FR-FOT-DA-022 + FR-FOT-DA-041 — contextWithSpan present AND Context.current.withSpan absent
_test_fda_041_no_legacy_with_span_method() {
  if ! grep -q "contextWithSpan(" "$STD_FOT"; then
    echo "    'contextWithSpan(' not found in $STD_FOT" >&2; return 1
  fi
  if grep -q "Context\.current\.withSpan(" "$STD_FOT"; then
    echo "    forbidden legacy 'Context.current.withSpan(' still present in $STD_FOT" >&2; return 1
  fi
}

# FR-FOT-DA-050..FR-FOT-DA-055 — all 6 legacy fabricated identifiers absent
_test_fda_050_no_legacy_identifiers() {
  local forbidden=(
    "OtlpHttpSpanExporter"
    "OtlpHttpExporterConfig"
    "BatchSpanProcessorConfig"
    "TraceIdRatioBasedSampler"
    "exporter_otlp_http.dart"
    "exporter_otlp_grpc.dart"
  )
  for needle in "${forbidden[@]}"; do
    if grep -q "$needle" "$STD_FOT"; then
      echo "    forbidden legacy identifier still present: '$needle'" >&2; return 1
    fi
  done
}

# FR-FOT-DA-060 + FR-FOT-DA-061 — Workiva status callout block (Traces/Metrics/Logs scope)
_test_fda_060_workiva_status_callout() {
  # The callout MUST be in the top portion of the standard (within the first 80
  # lines after the frontmatter), and MUST mention the three status tokens.
  local top
  top="$(head -n 80 "$STD_FOT")"
  for needle in "Traces" "Beta" "Metrics" "Alpha" "Logs" "Unimplemented"; do
    if ! printf '%s' "$top" | grep -q "$needle"; then
      echo "    Workiva status callout missing token: '$needle' (within first 80 lines)" >&2; return 1
    fi
  done
  # Scope-to-traces statement
  if ! printf '%s' "$top" | grep -qi "traces"; then
    echo "    scope-to-traces statement missing in status callout" >&2; return 1
  fi
}

# FR-FOT-DA-080..FR-FOT-DA-082 — REVIEW.md ledger entry present
_test_fda_080_review_entry_present() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing: $REVIEW_MD" >&2; return 1
  fi
  if ! grep -q "^## 2026-05-11 — Updated flutter/opentelemetry\.md to v1\.1\.0 (t5-otel-dart-api-realign)$" "$REVIEW_MD"; then
    echo "    expected H2 entry not found in $REVIEW_MD" >&2; return 1
  fi
  # The entry MUST mention Q-004 (the open question this change resolves)
  # AND the canonical pkg/version.
  if ! grep -q "Q-004" "$REVIEW_MD"; then
    echo "    REVIEW.md entry must reference 'Q-004' (origin open question)" >&2; return 1
  fi
  if ! grep -q "opentelemetry: 0\.18\.11" "$REVIEW_MD" && ! grep -q "opentelemetry 0\.18\.11" "$REVIEW_MD"; then
    echo "    REVIEW.md entry must reference pkg pin 'opentelemetry 0.18.11'" >&2; return 1
  fi
  # The entry table row : v1.1.0 + KEEP-WITH-CHANGES decision
  if ! grep -qE '\| flutter/opentelemetry\.md +\| 1\.1\.0 +\| KEEP-WITH-CHANGES' "$REVIEW_MD"; then
    echo "    REVIEW.md table row 'flutter/opentelemetry.md | 1.1.0 | KEEP-WITH-CHANGES' missing" >&2; return 1
  fi
}

# FR-FOT-DA-100 — workflow registers the harness
_test_fda_100_workflow_registers_harness() {
  if [ ! -f "$WORKFLOW" ]; then
    echo "    workflow missing: $WORKFLOW" >&2; return 1
  fi
  if ! grep -q "t5-otel-dart-api-realign\.test\.sh" "$WORKFLOW"; then
    echo "    workflow does not register 't5-otel-dart-api-realign.test.sh'" >&2; return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T.5 — t5-otel-dart-api-realign harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — standard frontmatter + API surface + REVIEW + CI"
  run_test _test_fda_001_frontmatter_block
  run_test _test_fda_002_frontmatter_version_110
  run_test _test_fda_003_frontmatter_last_reviewed
  run_test _test_fda_004_frontmatter_pkg_metadata
  run_test _test_fda_011_setup_collector_exporter
  run_test _test_fda_014_setup_tracer_provider
  run_test _test_fda_023_interceptor_status_ok
  run_test _test_fda_041_no_legacy_with_span_method
  run_test _test_fda_050_no_legacy_identifiers
  run_test _test_fda_060_workiva_status_callout
  run_test _test_fda_080_review_entry_present
  run_test _test_fda_100_workflow_registers_harness

  print_summary
}

main "$@"
