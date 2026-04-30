#!/usr/bin/env bash
# Forge — B.4 Mobile-Only Test Harness (b4-mobile-only)
# <!-- Audit: B.4 (b4-mobile-only) -->
#
# Validates :
#  - Phase A : Schema + wrapper + dispatch-table + Flutter/iOS/Android skeleton + snapshot (FR-MO-001..016, FR-MO-038, FR-MO-039)
#  - Phase B : OIDC + secure storage + biometric + attestation + observability + standard (FR-MO-017..029, FR-MO-036)
#  - Phase C : Fastlane + CI workflow + ARCHETYPES.md + framework-owned-paths.yml.tmpl (FR-MO-030..035)
#
# Manifest pattern : functions are prefixed `_test_b4_NNN`.
#
# Usage :
#   bash .forge/scripts/tests/b4.test.sh                     # L1 only (default)
#   bash .forge/scripts/tests/b4.test.sh --level 1,2         # L1 + L2 fixture-based
#   bash .forge/scripts/tests/b4.test.sh --level 1,2 --require-flutter  # L1 + L2 + L3 (Flutter SDK)

set -uo pipefail

LEVEL="1"
REQUIRE_FLUTTER=0
for arg in "$@"; do
  case "$arg" in
    --level) shift; ;;
    --level=*) LEVEL="${arg#*=}" ;;
    --require-flutter) REQUIRE_FLUTTER=1 ;;
    1|2|"1,2"|"1") LEVEL="$arg" ;;
    *) ;;
  esac
done
# Re-parse positional --level <value>
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  prev="$arg"
done

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

SCHEMA="$FORGE_ROOT_REAL/.forge/schemas/mobile-only/schema.yaml"
WRAPPER="$FORGE_ROOT_REAL/bin/forge-init-mobile-only.sh"
DISPATCH="$FORGE_ROOT_REAL/.forge/scaffolding/dispatch-table.yml"
TEMPLATES="$FORGE_ROOT_REAL/.forge/templates/archetypes/mobile-only"
SNAPSHOT="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/mobile-only/1.0.0.tar.gz"
ARCHETYPES_MD="$FORGE_ROOT_REAL/docs/ARCHETYPES.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
STD_FLUTTER_MOBILE="$FORGE_ROOT_REAL/.forge/standards/global/flutter-mobile.md"
CI_WORKFLOW="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# Phase A — Core scaffold structure
# MANIFEST: _test_b4_001  — FR-MO-001 schema.yaml exists + parses
# MANIFEST: _test_b4_002  — FR-MO-001 schema declares mobile-only + 1.0.0
# MANIFEST: _test_b4_003  — FR-MO-001 schema layers single 'app'
# MANIFEST: _test_b4_004  — FR-MO-004 wrapper exists + executable
# MANIFEST: _test_b4_005  — FR-MO-004 wrapper rejects missing --target
# MANIFEST: _test_b4_006  — FR-MO-004 wrapper rejects missing --project-name
# MANIFEST: _test_b4_007  — FR-MO-004 wrapper rejects missing --reverse-domain
# MANIFEST: _test_b4_008  — FR-MO-003 dispatch-table has mobile-only entry
# MANIFEST: _test_b4_009  — FR-MO-003 dispatch-table signals correct
# MANIFEST: _test_b4_010  — FR-MO-006 pubspec.yaml.tmpl has required deps
# MANIFEST: _test_b4_011  — FR-MO-007 analysis_options.yaml strict lints
# MANIFEST: _test_b4_012  — FR-MO-008 lib/ 4 layers present
# MANIFEST: _test_b4_013  — FR-MO-009 integration_test login.feature scaffolded
# MANIFEST: _test_b4_014  — FR-MO-011 ios Info.plist.tmpl iOS 15.0
# MANIFEST: _test_b4_015  — FR-MO-012 ios Podfile.tmpl pinned 15.0
# MANIFEST: _test_b4_016  — FR-MO-014 android build.gradle.kts.tmpl minSdk 26
# MANIFEST: _test_b4_017  — FR-MO-015 AndroidManifest USE_BIOMETRIC + FlutterFragmentActivity
# MANIFEST: _test_b4_018  — FR-MO-014 MainActivity.kt extends FlutterFragmentActivity
# MANIFEST: _test_b4_019  — FR-MO-005 snapshot tarball exists + size ≤ 2 MB
#
# Phase A L2 — fixture-based scaffolder
# MANIFEST: _test_b4_l2_001 — wrapper produces expected structure (L2)
# MANIFEST: _test_b4_l2_002 — wrapper substitutes project_name + reverse_domain (L2)
# MANIFEST: _test_b4_l2_003 — wrapper idempotent with --force (L2)
# MANIFEST: _test_b4_l2_004 — wrapper exits non-zero on non-empty target without --force (L2)
# MANIFEST: _test_b4_l2_005 — reverse_domain propagates to Info.plist + build.gradle (L2)

# ─── Helpers locaux ──────────────────────────────────────────────

_run_wrapper_clean() {
  # _run_wrapper_clean <target> <project-name> <reverse-domain> [--force]
  # Run the wrapper and capture exit code (set -e disabled per-call).
  local rc=0
  bash "$WRAPPER" --target "$1" --project-name "$2" --reverse-domain "$3" "${@:4}" >/dev/null 2>&1 || rc=$?
  echo "$rc"
}

# ─── Phase A — L1 tests ──────────────────────────────────────────

_test_b4_001() {
  [ -f "$SCHEMA" ] || { echo "    expected: $SCHEMA" >&2; return 1; }
  python3 -c "import yaml,sys; yaml.safe_load(open('$SCHEMA'))" \
    || { echo "    schema.yaml not parseable" >&2; return 1; }
}

_test_b4_002() {
  [ -f "$SCHEMA" ] || { echo "    schema missing" >&2; return 1; }
  grep -qE '^archetype:[[:space:]]+mobile-only' "$SCHEMA" \
    || { echo "    archetype: mobile-only missing" >&2; return 1; }
  grep -qE '^schema_version:[[:space:]]+"?1\.0\.0"?' "$SCHEMA" \
    || { echo "    schema_version: 1.0.0 missing" >&2; return 1; }
}

_test_b4_003() {
  [ -f "$SCHEMA" ] || { echo "    schema missing" >&2; return 1; }
  local n
  n=$(python3 -c "import yaml; print(len((yaml.safe_load(open('$SCHEMA')) or {}).get('layers', [])))")
  if [ "$n" != "1" ]; then echo "    expected 1 layer, got $n" >&2; return 1; fi
  python3 -c "import yaml,sys; d=yaml.safe_load(open('$SCHEMA')); sys.exit(0 if d['layers'][0]['id']=='app' else 1)" \
    || { echo "    layer id != 'app'" >&2; return 1; }
}

_test_b4_004() {
  [ -f "$WRAPPER" ] || { echo "    expected: $WRAPPER" >&2; return 1; }
  [ -x "$WRAPPER" ] || { echo "    wrapper not executable" >&2; return 1; }
}

_test_b4_005() {
  [ -x "$WRAPPER" ] || { echo "    wrapper missing" >&2; return 1; }
  local rc=0
  bash "$WRAPPER" --project-name foo --reverse-domain com.example.foo >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then echo "    wrapper accepted missing --target" >&2; return 1; fi
}

_test_b4_006() {
  [ -x "$WRAPPER" ] || { echo "    wrapper missing" >&2; return 1; }
  local rc=0
  bash "$WRAPPER" --target /tmp/foo --reverse-domain com.example.foo >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then echo "    wrapper accepted missing --project-name" >&2; return 1; fi
}

_test_b4_007() {
  [ -x "$WRAPPER" ] || { echo "    wrapper missing" >&2; return 1; }
  local rc=0
  bash "$WRAPPER" --target /tmp/foo --project-name foo >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then echo "    wrapper accepted missing --reverse-domain" >&2; return 1; fi
}

_test_b4_008() {
  [ -f "$DISPATCH" ] || { echo "    dispatch-table missing" >&2; return 1; }
  python3 -c "import yaml,sys; d=yaml.safe_load(open('$DISPATCH')); sys.exit(0 if 'mobile-only' in d.get('archetypes', {}) else 1)" \
    || { echo "    mobile-only not registered in dispatch-table" >&2; return 1; }
}

_test_b4_009() {
  [ -f "$DISPATCH" ] || { echo "    dispatch-table missing" >&2; return 1; }
  python3 - "$DISPATCH" <<'PY' || return 1
import yaml, sys
d = yaml.safe_load(open(sys.argv[1])) or {}
mo = d.get('archetypes', {}).get('mobile-only', {})
if not mo:
    print("    mobile-only entry empty", file=sys.stderr); sys.exit(1)
if mo.get('scaffolder') != 'bin/forge-init-mobile-only.sh':
    print(f"    bad scaffolder: {mo.get('scaffolder')}", file=sys.stderr); sys.exit(1)
sigs = mo.get('signals', [])
if 'pubspec.yaml' not in sigs:
    print("    missing signal pubspec.yaml", file=sys.stderr); sys.exit(1)
PY
}

_test_b4_010() {
  local f="$TEMPLATES/pubspec.yaml.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  for dep in flutter_bloc flutter_appauth flutter_secure_storage local_auth opentelemetry_api; do
    grep -qE "^[[:space:]]+$dep:" "$f" || { echo "    missing dep: $dep" >&2; return 1; }
  done
}

_test_b4_011() {
  local f="$TEMPLATES/analysis_options.yaml"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF 'flutter_lints' "$f" || { echo "    flutter_lints not extended" >&2; return 1; }
  local strict_count=0
  for lint in prefer_const_constructors unawaited_futures avoid_print prefer_final_locals unnecessary_lambdas; do
    grep -qF "$lint" "$f" && strict_count=$((strict_count+1))
  done
  if [ "$strict_count" -lt 5 ]; then echo "    only $strict_count strict lints (need ≥ 5)" >&2; return 1; fi
}

_test_b4_012() {
  for layer in domain data presentation infrastructure; do
    [ -d "$TEMPLATES/lib/$layer" ] || { echo "    missing lib/$layer/" >&2; return 1; }
  done
}

_test_b4_013() {
  local f="$TEMPLATES/integration_test/features/login.feature.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qE '^Feature:' "$f" || { echo "    missing Feature: keyword" >&2; return 1; }
  grep -qE '^[[:space:]]*Scenario:' "$f" || { echo "    missing Scenario: keyword" >&2; return 1; }
}

_test_b4_014() {
  local f="$TEMPLATES/ios/Runner/Info.plist.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF '{{reverse_domain}}' "$f" || { echo "    missing {{reverse_domain}} placeholder" >&2; return 1; }
  grep -qF 'MinimumOSVersion' "$f" || { echo "    missing MinimumOSVersion key" >&2; return 1; }
  grep -qE '<string>15\.0</string>' "$f" || { echo "    MinimumOSVersion != 15.0" >&2; return 1; }
  grep -qF 'NSFaceIDUsageDescription' "$f" || { echo "    missing NSFaceIDUsageDescription" >&2; return 1; }
}

_test_b4_015() {
  local f="$TEMPLATES/ios/Podfile.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qE "platform :ios, '15\.0'" "$f" \
    || { echo "    Podfile not pinned to iOS 15.0" >&2; return 1; }
  if grep -qE '^[^#]*/Users/' "$f"; then
    echo "    Podfile contains absolute /Users/ path" >&2; return 1
  fi
}

_test_b4_016() {
  local f="$TEMPLATES/android/app/build.gradle.kts.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qE 'minSdk[[:space:]]*=[[:space:]]*26' "$f" \
    || { echo "    minSdk != 26" >&2; return 1; }
  grep -qE 'targetSdk[[:space:]]*=[[:space:]]*[0-9]+' "$f" \
    || { echo "    missing targetSdk" >&2; return 1; }
  grep -qF '{{reverse_domain}}' "$f" \
    || { echo "    missing {{reverse_domain}} placeholder" >&2; return 1; }
}

_test_b4_017() {
  local f="$TEMPLATES/android/app/src/main/AndroidManifest.xml.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF 'android.permission.USE_BIOMETRIC' "$f" \
    || { echo "    missing USE_BIOMETRIC permission" >&2; return 1; }
  grep -qF 'android.permission.INTERNET' "$f" \
    || { echo "    missing INTERNET permission" >&2; return 1; }
  grep -qF 'FlutterFragmentActivity' "$f" \
    || { echo "    MainActivity does not extend FlutterFragmentActivity" >&2; return 1; }
}

_test_b4_018() {
  # MainActivity.kt is under android/app/src/main/kotlin/{{reverse_domain_path}}/MainActivity.kt.tmpl
  local match
  match=$(find "$TEMPLATES/android/app/src/main/kotlin" -name 'MainActivity.kt.tmpl' 2>/dev/null | head -1)
  if [ -z "$match" ]; then echo "    MainActivity.kt.tmpl not found under kotlin/" >&2; return 1; fi
  grep -qF 'FlutterFragmentActivity' "$match" \
    || { echo "    MainActivity.kt does not extend FlutterFragmentActivity" >&2; return 1; }
}

_test_b4_019() {
  [ -f "$SNAPSHOT" ] || { echo "    expected: $SNAPSHOT" >&2; return 1; }
  local size_bytes
  size_bytes=$(wc -c < "$SNAPSHOT" | tr -d ' ')
  local budget=$((2 * 1024 * 1024))
  if [ "$size_bytes" -gt "$budget" ]; then
    echo "    snapshot too large: ${size_bytes} bytes (budget ${budget})" >&2; return 1
  fi
  file -b "$SNAPSHOT" | grep -qiE 'gzip|tar' \
    || { echo "    not a gzip/tar archive" >&2; return 1; }
}

# ─── Phase A — L2 tests (fixture-based) ──────────────────────────

_test_b4_l2_001() {
  [ -x "$WRAPPER" ] || { echo "    wrapper missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t b4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  local rc=0
  bash "$WRAPPER" --target "$tmp" --project-name myapp --reverse-domain com.example.myapp --force >/dev/null 2>&1 || rc=$?
  if [ "$rc" -ne 0 ]; then echo "    wrapper exited $rc" >&2; return 1; fi
  for f in pubspec.yaml lib/main.dart ios/Runner/Info.plist android/app/build.gradle.kts; do
    [ -f "$tmp/$f" ] || { echo "    expected: $tmp/$f" >&2; return 1; }
  done
}

_test_b4_l2_002() {
  [ -x "$WRAPPER" ] || { echo "    wrapper missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t b4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  bash "$WRAPPER" --target "$tmp" --project-name myapp --reverse-domain com.example.myapp --force >/dev/null 2>&1 \
    || { echo "    scaffold failed" >&2; return 1; }
  if grep -rF '{{project_name}}' "$tmp" 2>/dev/null | grep -v '\.tmpl$' | head -1 | grep -q .; then
    echo "    {{project_name}} not substituted" >&2; return 1
  fi
  if grep -rF '{{reverse_domain}}' "$tmp" 2>/dev/null | grep -v '\.tmpl$' | head -1 | grep -q .; then
    echo "    {{reverse_domain}} not substituted" >&2; return 1
  fi
  grep -rF 'myapp' "$tmp/pubspec.yaml" >/dev/null || { echo "    project_name not in pubspec" >&2; return 1; }
}

_test_b4_l2_003() {
  [ -x "$WRAPPER" ] || { echo "    wrapper missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t b4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  bash "$WRAPPER" --target "$tmp" --project-name myapp --reverse-domain com.example.myapp --force >/dev/null 2>&1 \
    || { echo "    first scaffold failed" >&2; return 1; }
  local manifest1
  manifest1=$(cd "$tmp" && find . -type f -print0 | sort -z | xargs -0 shasum | shasum)
  bash "$WRAPPER" --target "$tmp" --project-name myapp --reverse-domain com.example.myapp --force >/dev/null 2>&1 \
    || { echo "    second scaffold failed" >&2; return 1; }
  local manifest2
  manifest2=$(cd "$tmp" && find . -type f -print0 | sort -z | xargs -0 shasum | shasum)
  if [ "$manifest1" != "$manifest2" ]; then
    echo "    not idempotent: $manifest1 vs $manifest2" >&2; return 1
  fi
}

_test_b4_l2_004() {
  [ -x "$WRAPPER" ] || { echo "    wrapper missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t b4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  echo "preexisting" > "$tmp/sentinel.txt"
  local rc=0
  bash "$WRAPPER" --target "$tmp" --project-name myapp --reverse-domain com.example.myapp >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "    wrapper should refuse non-empty dir without --force" >&2; return 1
  fi
}

_test_b4_l2_005() {
  [ -x "$WRAPPER" ] || { echo "    wrapper missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t b4-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  bash "$WRAPPER" --target "$tmp" --project-name myapp --reverse-domain com.example.myapp --force >/dev/null 2>&1 \
    || { echo "    scaffold failed" >&2; return 1; }
  grep -qF 'com.example.myapp' "$tmp/ios/Runner/Info.plist" \
    || { echo "    reverse_domain not in Info.plist" >&2; return 1; }
  grep -qF 'com.example.myapp' "$tmp/android/app/build.gradle.kts" \
    || { echo "    reverse_domain not in build.gradle.kts" >&2; return 1; }
}

# ─── Main ───────────────────────────────────────────────────────

main() {
  echo "Forge — b4-mobile-only Test Harness"
  echo "FORGE_ROOT_REAL=$FORGE_ROOT_REAL"
  echo "LEVEL=$LEVEL"
  echo ""
  echo "── Phase A : L1 hermetic ──"
  run_test _test_b4_001
  run_test _test_b4_002
  run_test _test_b4_003
  run_test _test_b4_004
  run_test _test_b4_005
  run_test _test_b4_006
  run_test _test_b4_007
  run_test _test_b4_008
  run_test _test_b4_009
  run_test _test_b4_010
  run_test _test_b4_011
  run_test _test_b4_012
  run_test _test_b4_013
  run_test _test_b4_014
  run_test _test_b4_015
  run_test _test_b4_016
  run_test _test_b4_017
  run_test _test_b4_018
  run_test _test_b4_019

  case ",$LEVEL," in
    *,2,*)
      echo ""
      echo "── Phase A : L2 fixture-based ──"
      run_test _test_b4_l2_001
      run_test _test_b4_l2_002
      run_test _test_b4_l2_003
      run_test _test_b4_l2_004
      run_test _test_b4_l2_005
      ;;
  esac

  print_summary
}

main "$@"
