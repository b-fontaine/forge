#!/usr/bin/env bash
# Forge — T.5.3 OTel Dartastic Realign Test Harness (t5-otel-dartastic-realign)
# <!-- Audit: T.5.3 (t5-otel-dartastic-realign) -->
#
# Validates the T5.3 deliverables — Workiva opentelemetry (web-only)
# → Dartastic ecosystem (all-platform) substitution :
#
#   - .forge/standards/flutter/opentelemetry.md v1.1.0 → v2.0.0
#     (breaking bump per ADR-T53-002 WAIVER for beta API).
#   - examples/forge-fsm-example/frontend/ — 5 .dart files + pubspec
#     rewritten on Dartastic + flutterrific.
#   - .forge/templates/archetypes/mobile-only/ — pubspec.yaml.tmpl
#     + otel_init.dart.tmpl rewritten ; cli/assets mirror.
#   - 3 .forge-update-notes forward-pointer files in archived changes
#     (Article V immutability preserved).
#   - REVIEW.md append-only ledger entry (Article XII).
#   - CHANGELOG.md [Unreleased] BREAKING entry.
#
# 13 L1 + 2 L2 = 15 tests.
# Performance budget : L1 ≤ 5 s ; L2 ≤ 120 s/leg (NFR-T53-002).
#
# ADR-T53-001 — flutterrific shim primary, SDK fallback documented.
# ADR-T53-002 — Beta API pin accepted via WAIVER (named upgrade trigger).
# ADR-T53-003 — .forge-update-notes file per archive + global graph.
# ADR-T53-004 — Sampling dual-stage preserved (Phase A + Phase B).
# ADR-T53-005 — Harness mirrors J.7 / I.5 / K.3 / T5.2 pattern.
# ADR-T53-006 — cli/assets mirror discipline asserted by L1 diff.

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

STD_FILE="$FORGE_ROOT_REAL/.forge/standards/flutter/opentelemetry.md"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
FSM_FRONTEND_DIR="$FORGE_ROOT_REAL/examples/forge-fsm-example/frontend"
FSM_PUBSPEC="$FSM_FRONTEND_DIR/pubspec.yaml"
MOBILE_ONLY_TMPL_DIR="$FORGE_ROOT_REAL/.forge/templates/archetypes/mobile-only"
MOBILE_ONLY_PUBSPEC_TMPL="$MOBILE_ONLY_TMPL_DIR/pubspec.yaml.tmpl"
MOBILE_ONLY_OTEL_TMPL="$MOBILE_ONLY_TMPL_DIR/lib/observability/otel_init.dart.tmpl"
CLI_ASSETS_MOBILE_ONLY="$FORGE_ROOT_REAL/cli/assets/.forge/templates/archetypes/mobile-only"
CLI_ASSETS_PUBSPEC_TMPL="$CLI_ASSETS_MOBILE_ONLY/pubspec.yaml.tmpl"
CLI_ASSETS_OTEL_TMPL="$CLI_ASSETS_MOBILE_ONLY/lib/observability/otel_init.dart.tmpl"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
FORGE_CI_YML="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

ARCHIVED_NOTES_B4="$FORGE_ROOT_REAL/.forge/changes/b4-mobile-only/.forge-update-notes"
ARCHIVED_NOTES_OTELAPP="$FORGE_ROOT_REAL/.forge/changes/t5-otel-app/.forge-update-notes"
ARCHIVED_NOTES_OTELREALIGN="$FORGE_ROOT_REAL/.forge/changes/t5-otel-dart-api-realign/.forge-update-notes"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (13 tests)
# MANIFEST: _test_t53_l1_001_std_version_2_0_0           — FR-T53-E-004 / FR-T53-A-002
# MANIFEST: _test_t53_l1_002_std_breaking_change         — FR-T53-E-005 / FR-T53-A-003
# MANIFEST: _test_t53_l1_003_std_dartastic_imports       — FR-T53-E-006 / FR-T53-A-010
# MANIFEST: _test_t53_l1_004_std_workiva_imports_absent  — FR-T53-E-007
# MANIFEST: _test_t53_l1_005_phantom_pkg_absent          — FR-T53-E-008 / FR-T53-B-009 / FR-T53-C-001
# MANIFEST: _test_t53_l1_006_std_3_axis_embedded         — FR-T53-E-009 / FR-T53-A-008 / FR-T53-G-003
# MANIFEST: _test_t53_l1_007_std_migration_h2            — FR-T53-E-010 / FR-T53-A-013
# MANIFEST: _test_t53_l1_008_review_ledger_entry         — FR-T53-E-011 / FR-T53-A-025
# MANIFEST: _test_t53_l1_009_fsm_pubspec_dartastic       — FR-T53-E-012 / FR-T53-B-001
# MANIFEST: _test_t53_l1_010_mobile_pubspec_tmpl_dartastic — FR-T53-E-013 / FR-T53-C-001
# MANIFEST: _test_t53_l1_011_cli_assets_mirror           — FR-T53-E-014 / FR-T53-C-003 / FR-T53-C-004
# MANIFEST: _test_t53_l1_012_forward_pointers            — FR-T53-E-015 / FR-T53-D-001..003
# MANIFEST: _test_t53_l1_013_article_iii4_xref           — FR-T53-E-016 / FR-T53-A-030 / NFR-T53-009
#
# L2 (2 tests, opt-in via FORGE_T53_LIVE=1)
# MANIFEST: _test_t53_l2_001_fsm_flutter_pubget_analyze  — FR-T53-E-017 / FR-T53-B-014 / -015
# MANIFEST: _test_t53_l2_002_mobile_only_fresh_scaffold  — FR-T53-E-018 / FR-T53-C-007 / -008

# ─── L1 tests ────────────────────────────────────────────────────

_test_t53_l1_001_std_version_2_0_0() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    [FR-T53-A-002] standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -E "^version: *2\.0\.0( |$)" "$STD_FILE" >/dev/null; then
    echo "    [FR-T53-A-002] frontmatter 'version: 2.0.0' missing from $STD_FILE" >&2
    return 1
  fi
}

_test_t53_l1_002_std_breaking_change() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    [FR-T53-A-003] standard file missing (pre-requisite)" >&2; return 1
  fi
  if ! grep -E "^breaking_change: *true( |$)" "$STD_FILE" >/dev/null; then
    echo "    [FR-T53-A-003] frontmatter 'breaking_change: true' missing from $STD_FILE" >&2
    return 1
  fi
}

_test_t53_l1_003_std_dartastic_imports() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    [FR-T53-A-010] standard file missing (pre-requisite)" >&2; return 1
  fi
  local missing=()
  if ! grep -Fq "package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart" "$STD_FILE"; then
    missing+=("dartastic_opentelemetry_api")
  fi
  if ! grep -Fq "package:dartastic_opentelemetry/dartastic_opentelemetry.dart" "$STD_FILE"; then
    missing+=("dartastic_opentelemetry")
  fi
  if ! grep -Fq "package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart" "$STD_FILE"; then
    missing+=("flutterrific_opentelemetry")
  fi
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    [FR-T53-A-010] missing canonical Dartastic imports: ${missing[*]}" >&2
    return 1
  fi
}

_test_t53_l1_004_std_workiva_imports_absent() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    [FR-T53-A-027] standard file missing (pre-requisite)" >&2; return 1
  fi
  # The Migration H2 may document the OLD imports in a code block — exclude those.
  # We look for fenced code blocks containing the old import strings ; if they
  # appear ONLY inside the Migration H2 (post "Migration from v1.1.0" marker),
  # accept. Else FAIL.
  local raw_hits
  raw_hits=$(grep -Fn "package:opentelemetry/api.dart" "$STD_FILE" 2>/dev/null || true)
  if [ -n "$raw_hits" ]; then
    # All hits must be after the Migration H2 anchor.
    local migration_line
    migration_line=$(grep -nE "^## Migration from v1\.1\.0" "$STD_FILE" 2>/dev/null | head -1 | cut -d: -f1 || echo "")
    if [ -z "$migration_line" ]; then
      echo "    [FR-T53-A-027] Workiva import 'package:opentelemetry/api.dart' present but no 'Migration from v1.1.0' H2 to scope it" >&2
      return 1
    fi
    # Reject any hit at a line <= migration_line
    while IFS=: read -r ln _; do
      if [ "$ln" -le "$migration_line" ]; then
        echo "    [FR-T53-A-027] Workiva import 'package:opentelemetry/api.dart' present outside the Migration H2 (line $ln vs migration H2 at line $migration_line)" >&2
        return 1
      fi
    done <<< "$raw_hits"
  fi
}

_test_t53_l1_005_phantom_pkg_absent() {
  # The phantom `opentelemetry_sdk` package must not appear as an
  # **active dependency or import** anywhere in template or FSM trees.
  # Two grep patterns matter (historical comments mentioning the name
  # for documentation purposes are OK and excluded) :
  #   - `^[[:space:]]*opentelemetry_sdk:` — yaml dependency declaration
  #   - `package:opentelemetry_sdk/` — Dart import path
  # Scope : mobile-only template (source + cli/assets mirror) + FSM
  # frontend lib/.
  local hits=0
  local pat1='^[[:space:]]*opentelemetry_sdk:'
  local pat2='package:opentelemetry_sdk/'
  for dir in "$MOBILE_ONLY_TMPL_DIR" "$CLI_ASSETS_MOBILE_ONLY"; do
    if [ -d "$dir" ]; then
      if grep -rqE "$pat1" "$dir" 2>/dev/null || grep -rqF "$pat2" "$dir" 2>/dev/null; then
        echo "    [FR-T53-C-001] phantom 'opentelemetry_sdk' active dep/import still present in $dir" >&2
        { grep -rnE "$pat1" "$dir" 2>/dev/null; grep -rnF "$pat2" "$dir" 2>/dev/null; } | head -3 | sed 's/^/      /' >&2
        hits=1
      fi
    fi
  done
  if [ -d "$FSM_FRONTEND_DIR/lib" ]; then
    if grep -rqE "$pat1" "$FSM_FRONTEND_DIR/lib" 2>/dev/null || grep -rqF "$pat2" "$FSM_FRONTEND_DIR/lib" 2>/dev/null; then
      echo "    [FR-T53-B-009] phantom 'opentelemetry_sdk' active dep/import still present in FSM frontend lib/" >&2
      hits=1
    fi
  fi
  if [ "$hits" -eq 1 ]; then return 1; fi
}

_test_t53_l1_006_std_3_axis_embedded() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    [FR-T53-A-008] standard file missing (pre-requisite)" >&2; return 1
  fi
  if ! grep -Fq "Source Documents — 3-axis verification" "$STD_FILE" \
     && ! grep -Fq "Source Documents - 3-axis verification" "$STD_FILE"; then
    echo "    [FR-T53-A-008] '## Source Documents — 3-axis verification' H2 missing from $STD_FILE" >&2
    return 1
  fi
  local missing=()
  if ! grep -Fq "Existence" "$STD_FILE"; then missing+=("Existence"); fi
  if ! grep -Fq "API surface" "$STD_FILE"; then missing+=("API surface"); fi
  if ! grep -Fq "Platform compatibility" "$STD_FILE"; then missing+=("Platform compatibility"); fi
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    [FR-T53-G-003] missing 3-axis labels in standard: ${missing[*]}" >&2
    return 1
  fi
}

_test_t53_l1_007_std_migration_h2() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    [FR-T53-A-013] standard file missing (pre-requisite)" >&2; return 1
  fi
  if ! grep -Eq "^## Migration from v1\.1\.0" "$STD_FILE"; then
    echo "    [FR-T53-A-013] '## Migration from v1.1.0' H2 missing from $STD_FILE" >&2
    return 1
  fi
}

_test_t53_l1_008_review_ledger_entry() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    [FR-T53-A-025] REVIEW.md missing: $REVIEW_MD" >&2; return 1
  fi
  if ! grep -E "^## 20[0-9]{2}-[0-9]{2}-[0-9]{2} — Updated flutter/opentelemetry\.md to v2\.0\.0 \(t5-otel-dartastic-realign\)$" "$REVIEW_MD" >/dev/null; then
    echo "    [FR-T53-A-025] REVIEW.md ledger entry pattern missing — expected '## YYYY-MM-DD — Updated flutter/opentelemetry.md to v2.0.0 (t5-otel-dartastic-realign)'" >&2
    return 1
  fi
}

_test_t53_l1_009_fsm_pubspec_dartastic() {
  if [ ! -f "$FSM_PUBSPEC" ]; then
    echo "    [FR-T53-B-001] FSM pubspec missing: $FSM_PUBSPEC" >&2; return 1
  fi
  if ! grep -Eq "^[[:space:]]*dartastic_opentelemetry:" "$FSM_PUBSPEC"; then
    echo "    [FR-T53-B-001] 'dartastic_opentelemetry:' missing from $FSM_PUBSPEC" >&2
    return 1
  fi
  if ! grep -Eq "^[[:space:]]*flutterrific_opentelemetry:" "$FSM_PUBSPEC"; then
    echo "    [FR-T53-B-001] 'flutterrific_opentelemetry:' missing from $FSM_PUBSPEC" >&2
    return 1
  fi
  # Negative : no Workiva ^0.18 pin
  if grep -Eq "^[[:space:]]*opentelemetry:[[:space:]]*\^?0\.18" "$FSM_PUBSPEC"; then
    echo "    [FR-T53-B-001] Workiva 'opentelemetry: ^0.18' still pinned in $FSM_PUBSPEC" >&2
    return 1
  fi
}

_test_t53_l1_010_mobile_pubspec_tmpl_dartastic() {
  if [ ! -f "$MOBILE_ONLY_PUBSPEC_TMPL" ]; then
    echo "    [FR-T53-C-001] mobile-only pubspec.yaml.tmpl missing: $MOBILE_ONLY_PUBSPEC_TMPL" >&2; return 1
  fi
  if ! grep -Eq "dartastic_opentelemetry:" "$MOBILE_ONLY_PUBSPEC_TMPL"; then
    echo "    [FR-T53-C-001] 'dartastic_opentelemetry:' missing from $MOBILE_ONLY_PUBSPEC_TMPL" >&2
    return 1
  fi
  if ! grep -Eq "flutterrific_opentelemetry:" "$MOBILE_ONLY_PUBSPEC_TMPL"; then
    echo "    [FR-T53-C-001] 'flutterrific_opentelemetry:' missing from $MOBILE_ONLY_PUBSPEC_TMPL" >&2
    return 1
  fi
  if grep -Eq "^[[:space:]]*opentelemetry:[[:space:]]*\^?0\.18" "$MOBILE_ONLY_PUBSPEC_TMPL"; then
    echo "    [FR-T53-C-001] Workiva 'opentelemetry: ^0.18' still pinned in $MOBILE_ONLY_PUBSPEC_TMPL" >&2
    return 1
  fi
}

_test_t53_l1_011_cli_assets_mirror() {
  if [ ! -f "$CLI_ASSETS_PUBSPEC_TMPL" ]; then
    echo "    [FR-T53-C-003] cli/assets pubspec.yaml.tmpl missing: $CLI_ASSETS_PUBSPEC_TMPL" >&2; return 1
  fi
  if ! diff -q "$MOBILE_ONLY_PUBSPEC_TMPL" "$CLI_ASSETS_PUBSPEC_TMPL" >/dev/null 2>&1; then
    echo "    [FR-T53-C-003] cli/assets pubspec.yaml.tmpl differs from source — diff -q failed" >&2
    return 1
  fi
  if [ -f "$MOBILE_ONLY_OTEL_TMPL" ] && [ -f "$CLI_ASSETS_OTEL_TMPL" ]; then
    if ! diff -q "$MOBILE_ONLY_OTEL_TMPL" "$CLI_ASSETS_OTEL_TMPL" >/dev/null 2>&1; then
      echo "    [FR-T53-C-004] cli/assets otel_init.dart.tmpl differs from source — diff -q failed" >&2
      return 1
    fi
  elif [ -f "$MOBILE_ONLY_OTEL_TMPL" ] && [ ! -f "$CLI_ASSETS_OTEL_TMPL" ]; then
    echo "    [FR-T53-C-004] cli/assets otel_init.dart.tmpl missing while source exists" >&2
    return 1
  fi
}

_test_t53_l1_012_forward_pointers() {
  local missing=()
  for f in "$ARCHIVED_NOTES_B4" "$ARCHIVED_NOTES_OTELAPP" "$ARCHIVED_NOTES_OTELREALIGN"; do
    if [ ! -f "$f" ]; then missing+=("$(basename "$(dirname "$f")")"); continue; fi
    if ! grep -Fq "## Superseded standard pin" "$f"; then
      echo "    [FR-T53-D-001..003] '## Superseded standard pin' H2 missing from $f" >&2
      return 1
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    [FR-T53-D-001..003] .forge-update-notes missing in archive(s): ${missing[*]}" >&2
    return 1
  fi
}

_test_t53_l1_013_article_iii4_xref() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    [FR-T53-A-030] standard file missing (pre-requisite)" >&2; return 1
  fi
  if ! grep -Fq "Article III.4" "$STD_FILE"; then
    echo "    [FR-T53-A-030] 'Article III.4' (Ambiguity Protocol) cross-reference missing from $STD_FILE" >&2
    return 1
  fi
}

# ─── L2 tests (opt-in flutter pub get + analyze per ADR-T53-005) ─

_test_t53_l2_001_fsm_flutter_pubget_analyze() {
  if [ "${FORGE_T53_LIVE:-0}" != "1" ]; then
    echo "    [INFO: L2 FSM flutter pub get gated by FORGE_T53_LIVE=1, skipping]" >&2
    return 0
  fi
  if ! command -v flutter >/dev/null 2>&1; then
    echo "    [SKIP: flutter not installed on PATH]" >&2
    return 0
  fi
  if [ ! -f "$FSM_PUBSPEC" ]; then
    echo "    [FR-T53-B-014] FSM pubspec missing (pre-requisite)" >&2; return 1
  fi
  local out rc
  out="$(timeout 120 bash -c "cd '$FSM_FRONTEND_DIR' && flutter pub get 2>&1")"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    [FR-T53-B-014] flutter pub get failed (rc=$rc) in FSM frontend ; first 20 lines :" >&2
    printf '%s\n' "$out" | head -20 | sed 's/^/      /' >&2
    return 1
  fi
  out="$(timeout 120 bash -c "cd '$FSM_FRONTEND_DIR' && flutter analyze 2>&1")"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    [FR-T53-B-015] flutter analyze failed (rc=$rc) in FSM frontend ; first 30 lines :" >&2
    printf '%s\n' "$out" | head -30 | sed 's/^/      /' >&2
    return 1
  fi
}

_test_t53_l2_002_mobile_only_fresh_scaffold() {
  if [ "${FORGE_T53_LIVE:-0}" != "1" ]; then
    echo "    [INFO: L2 mobile-only scaffold gated by FORGE_T53_LIVE=1, skipping]" >&2
    return 0
  fi
  if ! command -v flutter >/dev/null 2>&1; then
    echo "    [SKIP: flutter not installed on PATH]" >&2
    return 0
  fi
  local forge_bin="$FORGE_ROOT_REAL/cli/bin/forge"
  if [ ! -x "$forge_bin" ]; then
    echo "    [SKIP: forge CLI not built at $forge_bin]" >&2
    return 0
  fi

  local tmpdir
  tmpdir=$(mktemp -d -t t53-mobile-XXXXXX)
  trap "rm -rf '$tmpdir'" RETURN

  local out rc
  out="$(timeout 60 "$forge_bin" init "t53probe" --archetype mobile-only --org "dev.forge.test" --target "$tmpdir/probe" 2>&1)"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    [FR-T53-C-007] forge init mobile-only failed (rc=$rc) ; first 20 lines :" >&2
    printf '%s\n' "$out" | head -20 | sed 's/^/      /' >&2
    return 1
  fi

  out="$(timeout 120 bash -c "cd '$tmpdir/probe' && flutter pub get 2>&1")"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    [FR-T53-C-007] flutter pub get failed on fresh mobile-only scaffold (rc=$rc) ; first 20 lines :" >&2
    printf '%s\n' "$out" | head -20 | sed 's/^/      /' >&2
    return 1
  fi

  out="$(timeout 120 bash -c "cd '$tmpdir/probe' && flutter analyze 2>&1")"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    [FR-T53-C-008] flutter analyze failed on fresh mobile-only scaffold (rc=$rc) ; first 30 lines :" >&2
    printf '%s\n' "$out" | head -30 | sed 's/^/      /' >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T.5.3 — t5-otel-dartastic-realign — level $LEVEL ──"

  run_test _test_t53_l1_001_std_version_2_0_0
  run_test _test_t53_l1_002_std_breaking_change
  run_test _test_t53_l1_003_std_dartastic_imports
  run_test _test_t53_l1_004_std_workiva_imports_absent
  run_test _test_t53_l1_005_phantom_pkg_absent
  run_test _test_t53_l1_006_std_3_axis_embedded
  run_test _test_t53_l1_007_std_migration_h2
  run_test _test_t53_l1_008_review_ledger_entry
  run_test _test_t53_l1_009_fsm_pubspec_dartastic
  run_test _test_t53_l1_010_mobile_pubspec_tmpl_dartastic
  run_test _test_t53_l1_011_cli_assets_mirror
  run_test _test_t53_l1_012_forward_pointers
  run_test _test_t53_l1_013_article_iii4_xref

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — flutter pub get + analyze (opt-in FORGE_T53_LIVE=1)"
    run_test _test_t53_l2_001_fsm_flutter_pubget_analyze
    run_test _test_t53_l2_002_mobile_only_fresh_scaffold
  fi

  print_summary
}

main "$@"
