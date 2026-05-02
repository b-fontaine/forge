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
    1|2|"1,2") LEVEL="$arg" ;;
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

# ─── Phase B — runtime + standards ───────────────────────────────
#
# MANIFEST: _test_b4_020 — FR-MO-017 oidc_config TODO_REPLACE + 4 providers in comments
# MANIFEST: _test_b4_021 — FR-MO-019 auth_repository.dart interface 4 methods
# MANIFEST: _test_b4_022 — FR-MO-019 auth_repository_impl uses FlutterAppAuth + no token logging
# MANIFEST: _test_b4_023 — FR-MO-018 auth_bloc has states + events
# MANIFEST: _test_b4_024 — FR-MO-020 secure_storage_adapter Keychain + EncryptedSharedPreferences
# MANIFEST: _test_b4_025 — FR-MO-022 biometric_service wraps LocalAuthentication
# MANIFEST: _test_b4_026 — FR-MO-023 biometric_lock_widget uses WidgetsBindingObserver
# MANIFEST: _test_b4_027 — FR-MO-025 device_attestor interface 2 methods
# MANIFEST: _test_b4_028 — FR-MO-026,027 3 attestor impls (ios, android, fake)
# MANIFEST: _test_b4_029 — FR-MO-013 AppAttestService.swift with DCAppAttestService
# MANIFEST: _test_b4_030 — FR-MO-016 PlayIntegrityService.kt with IntegrityManager
# MANIFEST: _test_b4_031 — FR-MO-028 otel_init.dart with OtlpExporter
# MANIFEST: _test_b4_032 — FR-MO-029 auth_repository_impl instrumented with span
# MANIFEST: _test_b4_033 — FR-MO-036 flutter-mobile.md 7 H2 + 3 Interdictions
# MANIFEST: _test_b4_034 — FR-MO-036 index.yml has flutter-mobile entry

_test_b4_020() {
  local f="$TEMPLATES/lib/infrastructure/auth/oidc_config.dart.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF 'TODO_REPLACE_' "$f" || { echo "    missing TODO_REPLACE_ placeholder" >&2; return 1; }
  for provider in Auth0 Keycloak Okta Cognito; do
    grep -qiF "$provider" "$f" || { echo "    missing reference to $provider" >&2; return 1; }
  done
}

_test_b4_021() {
  local f="$TEMPLATES/lib/domain/auth/auth_repository.dart.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  for sig in 'login' 'refresh' 'logout' 'getCurrentToken'; do
    grep -qE "$sig" "$f" || { echo "    missing method: $sig" >&2; return 1; }
  done
  grep -qE 'abstract class|abstract interface class' "$f" \
    || { echo "    not an abstract class/interface" >&2; return 1; }
}

_test_b4_022() {
  local f="$TEMPLATES/lib/data/auth/auth_repository_impl.dart.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF 'FlutterAppAuth' "$f" || { echo "    missing FlutterAppAuth" >&2; return 1; }
  # No token logging (FR-MO-019).
  if grep -qE 'print\(.*token|debugPrint\(.*token' "$f"; then
    echo "    forbidden: print/debugPrint of token detected" >&2; return 1
  fi
}

_test_b4_023() {
  local f="$TEMPLATES/lib/presentation/auth/auth_bloc.dart.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  for state in AuthInitial AuthLoading AuthAuthenticated AuthUnauthenticated AuthError; do
    grep -qF "$state" "$f" || { echo "    missing state: $state" >&2; return 1; }
  done
  for ev in AuthLoginRequested AuthLogoutRequested AuthTokenRefreshRequested; do
    grep -qF "$ev" "$f" || { echo "    missing event: $ev" >&2; return 1; }
  done
}

_test_b4_024() {
  local f="$TEMPLATES/lib/infrastructure/storage/secure_storage_adapter.dart.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF 'FlutterSecureStorage' "$f" || { echo "    missing FlutterSecureStorage" >&2; return 1; }
  grep -qiF 'first_unlock_this_device' "$f" \
    || { echo "    missing iOS Keychain accessibility config" >&2; return 1; }
  grep -qF 'EncryptedSharedPreferences' "$f" \
    || { echo "    missing Android EncryptedSharedPreferences" >&2; return 1; }
}

_test_b4_025() {
  local f="$TEMPLATES/lib/infrastructure/biometric/biometric_service.dart.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF 'LocalAuthentication' "$f" || { echo "    missing LocalAuthentication" >&2; return 1; }
  grep -qF 'biometricOnly' "$f" || { echo "    missing biometricOnly option" >&2; return 1; }
  grep -qF 'stickyAuth' "$f" || { echo "    missing stickyAuth option" >&2; return 1; }
}

_test_b4_026() {
  local f="$TEMPLATES/lib/presentation/biometric/biometric_lock_widget.dart.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF 'WidgetsBindingObserver' "$f" \
    || { echo "    missing WidgetsBindingObserver" >&2; return 1; }
  grep -qF 'AppLifecycleState' "$f" \
    || { echo "    missing AppLifecycleState reference" >&2; return 1; }
}

_test_b4_027() {
  local f="$TEMPLATES/lib/domain/attestation/device_attestor.dart.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qE 'requestAttestationToken' "$f" \
    || { echo "    missing requestAttestationToken" >&2; return 1; }
  grep -qE 'isSupported' "$f" \
    || { echo "    missing isSupported" >&2; return 1; }
}

_test_b4_028() {
  for impl in ios_app_attest_attestor android_play_integrity_attestor fake_attestor; do
    local f="$TEMPLATES/lib/infrastructure/attestation/${impl}.dart.tmpl"
    [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  done
  # MethodChannel names match Dart side
  grep -qF 'forge.attestation/app_attest' \
    "$TEMPLATES/lib/infrastructure/attestation/ios_app_attest_attestor.dart.tmpl" \
    || { echo "    iOS impl missing MethodChannel name" >&2; return 1; }
  grep -qF 'forge.attestation/play_integrity' \
    "$TEMPLATES/lib/infrastructure/attestation/android_play_integrity_attestor.dart.tmpl" \
    || { echo "    Android impl missing MethodChannel name" >&2; return 1; }
}

_test_b4_029() {
  local f="$TEMPLATES/ios/Runner/AppAttestService.swift.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF 'DCAppAttestService' "$f" \
    || { echo "    missing DCAppAttestService reference" >&2; return 1; }
  grep -qF 'forge.attestation/app_attest' "$f" \
    || { echo "    missing MethodChannel name" >&2; return 1; }
}

_test_b4_030() {
  local match
  match=$(find "$TEMPLATES/android/app/src/main/kotlin" -name 'PlayIntegrityService.kt.tmpl' 2>/dev/null | head -1)
  if [ -z "$match" ]; then echo "    PlayIntegrityService.kt.tmpl not found" >&2; return 1; fi
  grep -qF 'IntegrityManager' "$match" \
    || { echo "    missing IntegrityManager reference" >&2; return 1; }
  grep -qF 'forge.attestation/play_integrity' "$match" \
    || { echo "    missing MethodChannel name" >&2; return 1; }
}

_test_b4_031() {
  local f="$TEMPLATES/lib/observability/otel_init.dart.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qiE 'otlp|exporter' "$f" \
    || { echo "    missing OTLP exporter" >&2; return 1; }
  grep -qF '4318' "$f" \
    || { echo "    missing default endpoint port 4318" >&2; return 1; }
}

_test_b4_032() {
  local f="$TEMPLATES/lib/data/auth/auth_repository_impl.dart.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qE 'startSpan|tracer\.' "$f" \
    || { echo "    missing tracer.startSpan instrumentation" >&2; return 1; }
}

_test_b4_033() {
  [ -f "$STD_FLUTTER_MOBILE" ] || { echo "    expected: $STD_FLUTTER_MOBILE" >&2; return 1; }
  local sections=("Lifecycle and Backgrounding" "Permissions" "OIDC and Token Storage" "Biometric Lock" "Device Attestation" "Native Configuration" "CI / Fastlane")
  local missing=()
  for s in "${sections[@]}"; do
    grep -qE "^## ${s}\$" "$STD_FLUTTER_MOBILE" || missing+=("$s")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    missing H2 sections: ${missing[*]}" >&2; return 1
  fi
  local n
  n=$(grep -ciE 'interdiction' "$STD_FLUTTER_MOBILE")
  if [ "$n" -lt 3 ]; then
    echo "    only $n Interdictions (need ≥ 3)" >&2; return 1
  fi
}

_test_b4_034() {
  [ -f "$INDEX_YML" ] || { echo "    expected: $INDEX_YML" >&2; return 1; }
  grep -qF 'flutter-mobile' "$INDEX_YML" \
    || { echo "    flutter-mobile entry missing in index.yml" >&2; return 1; }
}

# ─── Phase C — Fastlane + CI + integrations ──────────────────────
#
# MANIFEST: _test_b4_035 — FR-MO-030,031 Fastlane structure + lanes per platform
# MANIFEST: _test_b4_036 — FR-MO-032 Fastlane secrets via ENV (no hardcoded password)
# MANIFEST: _test_b4_037 — FR-MO-033 mobile-ci.yml.tmpl ios + android jobs
# MANIFEST: _test_b4_038 — FR-MO-034,035 coverage threshold + cache
# MANIFEST: _test_b4_039 — FR-MO-039 ARCHETYPES.md mobile-only row
# MANIFEST: _test_b4_040 — FR-MO-038 framework-owned-paths.yml.tmpl in archetype
# MANIFEST: _test_b4_041 — FR-MO-037 b4.test.sh registered in forge-ci.yml
# MANIFEST: _test_b4_042 — FR-MO-040 negative scope: no cli/src/ touched

_test_b4_035() {
  for platform in ios android; do
    for f in Fastfile Appfile; do
      local p="$TEMPLATES/$platform/fastlane/${f}.tmpl"
      [ -f "$p" ] || { echo "    expected: $p" >&2; return 1; }
    done
  done
  # Matchfile only for iOS
  [ -f "$TEMPLATES/ios/fastlane/Matchfile.tmpl" ] \
    || { echo "    iOS Matchfile.tmpl missing" >&2; return 1; }
  # Lanes
  for lane in 'lane :beta' 'lane :release' 'lane :screenshots'; do
    grep -qF "$lane" "$TEMPLATES/ios/fastlane/Fastfile.tmpl" \
      || { echo "    iOS Fastfile missing $lane" >&2; return 1; }
    grep -qF "$lane" "$TEMPLATES/android/fastlane/Fastfile.tmpl" \
      || { echo "    Android Fastfile missing $lane" >&2; return 1; }
  done
}

_test_b4_036() {
  for f in "$TEMPLATES/ios/fastlane/Fastfile.tmpl" "$TEMPLATES/android/fastlane/Fastfile.tmpl"; do
    grep -qE 'ENV\[' "$f" \
      || { echo "    no ENV[...] reference in $f" >&2; return 1; }
    # Detect hardcoded password literals (basic heuristic).
    if grep -E 'password.*=\s*"[A-Za-z0-9]{6,}"' "$f" >/dev/null 2>&1; then
      echo "    suspicious hardcoded password in $f" >&2; return 1
    fi
  done
  # .envrc.example documents required ENV vars.
  local envrc="$TEMPLATES/.envrc.example"
  [ -f "$envrc" ] || { echo "    .envrc.example missing" >&2; return 1; }
  for var in MATCH_PASSWORD APP_STORE_CONNECT_API_KEY_PATH PLAY_STORE_JSON_KEY KEYSTORE_PASSWORD; do
    grep -qF "$var" "$envrc" || { echo "    $var missing in .envrc.example" >&2; return 1; }
  done
}

_test_b4_037() {
  local f="$TEMPLATES/.github/workflows/mobile-ci.yml.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF 'macos-latest' "$f" || { echo "    iOS job not on macos-latest" >&2; return 1; }
  grep -qF 'ubuntu-latest' "$f" || { echo "    Android job not on ubuntu-latest" >&2; return 1; }
  # ≥ 3 named jobs
  local n
  n=$(grep -cE '^[[:space:]]+(ios|android|summary|e2e-android):' "$f")
  if [ "$n" -lt 3 ]; then echo "    only $n named jobs (need ≥ 3)" >&2; return 1; fi
}

_test_b4_038() {
  local f="$TEMPLATES/.github/workflows/mobile-ci.yml.tmpl"
  [ -f "$f" ] || { echo "    mobile-ci missing" >&2; return 1; }
  grep -qF -- '--coverage' "$f" \
    || { echo "    coverage flag missing" >&2; return 1; }
  grep -qE '70|THRESHOLD' "$f" \
    || { echo "    coverage threshold (70 or THRESHOLD) missing" >&2; return 1; }
  grep -qE 'actions/cache' "$f" \
    || { echo "    actions/cache missing" >&2; return 1; }
  grep -qF 'pub-cache' "$f" \
    || { echo "    pub-cache reference missing" >&2; return 1; }
}

_test_b4_039() {
  [ -f "$ARCHETYPES_MD" ] || { echo "    docs/ARCHETYPES.md missing" >&2; return 1; }
  grep -qF 'mobile-only' "$ARCHETYPES_MD" \
    || { echo "    mobile-only row missing in ARCHETYPES.md" >&2; return 1; }
}

_test_b4_040() {
  local f="$TEMPLATES/.forge/framework-owned-paths.yml.tmpl"
  [ -f "$f" ] || { echo "    expected: $f" >&2; return 1; }
  grep -qF 'owned:' "$f" || { echo "    'owned:' section missing" >&2; return 1; }
}

_test_b4_041() {
  [ -f "$CI_WORKFLOW" ] || { echo "    forge-ci.yml missing" >&2; return 1; }
  grep -qF 'b4.test.sh' "$CI_WORKFLOW" \
    || { echo "    b4.test.sh not registered in forge-ci.yml" >&2; return 1; }
}

_test_b4_042() {
  # Audit FR-MO-040 negative scope: B.4 commits MUST NOT touch cli/src/.
  # Baseline = parent of the first commit that introduced .forge/changes/b4-mobile-only/.
  # If b4 has no commits yet (pre-Phase-A run), or git history is shallow, skip.
  local first_b4_commit
  first_b4_commit=$(git -C "$FORGE_ROOT_REAL" log --reverse --format='%H' \
    -- .forge/changes/b4-mobile-only/ 2>/dev/null | head -1)
  if [ -z "$first_b4_commit" ]; then
    echo "    skipped (no b4 commit in history)" >&2; return 0
  fi
  local baseline
  baseline=$(git -C "$FORGE_ROOT_REAL" rev-parse "${first_b4_commit}^" 2>/dev/null) || {
    echo "    skipped (cannot resolve baseline parent of $first_b4_commit)" >&2; return 0
  }
  local violators
  violators=$(git -C "$FORGE_ROOT_REAL" diff --name-only "$baseline"...HEAD 2>/dev/null \
    | grep -E '^cli/src/' | head -1)
  if [ -n "$violators" ]; then
    echo "    FR-MO-040 violation: cli/src/ touched since $baseline: $violators" >&2; return 1
  fi
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

  echo ""
  echo "── Phase B : runtime + standards ──"
  run_test _test_b4_020
  run_test _test_b4_021
  run_test _test_b4_022
  run_test _test_b4_023
  run_test _test_b4_024
  run_test _test_b4_025
  run_test _test_b4_026
  run_test _test_b4_027
  run_test _test_b4_028
  run_test _test_b4_029
  run_test _test_b4_030
  run_test _test_b4_031
  run_test _test_b4_032
  run_test _test_b4_033
  run_test _test_b4_034

  echo ""
  echo "── Phase C : Fastlane + CI + integrations ──"
  run_test _test_b4_035
  run_test _test_b4_036
  run_test _test_b4_037
  run_test _test_b4_038
  run_test _test_b4_039
  run_test _test_b4_040
  run_test _test_b4_041
  run_test _test_b4_042

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
