#!/usr/bin/env bash
# Forge — T.5 Phase B OTel App SDK Harness (t5-otel-app)
# <!-- Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation -->
#
# Validates the additive app-side SDK instrumentation in
# examples/forge-fsm-example/ : Rust SDK init + middleware,
# Flutter SDK init + interceptor, demo-005 traceparent round trip,
# env config docs, CI registration.
#
# 16 L1 hermetic tests + 2 L2 smoke tests.
# Performance budget : L1 ≤ 8 s, L2 ≤ 90 s.

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

EXAMPLE="$FORGE_ROOT_REAL/examples/forge-fsm-example"
BACKEND="$EXAMPLE/backend"
FRONTEND="$EXAMPLE/frontend"
INFRA_CARGO="$BACKEND/Cargo.toml"
TELEMETRY_DIR="$BACKEND/crates/infrastructure/src/telemetry"
BIN_SERVER_MAIN="$BACKEND/bin-server/src/main.rs"
APP_CRATE_DIR="$BACKEND/crates/application/src"
PUBSPEC="$FRONTEND/pubspec.yaml"
LIB_TELEMETRY_DIR="$FRONTEND/lib/core/telemetry"
LIB_MAIN="$FRONTEND/lib/main.dart"
GREETING_REPO="$FRONTEND/lib/features/greeting/data/repository/greeting_repository_impl.dart"
ENV_DOC="$EXAMPLE/README.md"
DEMO_DOC="$EXAMPLE/docs/demo-005-connect-greeting.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (16 tests) — all hermetic, no network, no toolchain
# MANIFEST: _test_ota_001_rust_telemetry_module       — FR-T5-OTA-001
# MANIFEST: _test_ota_002_rust_cargo_otel_deps        — FR-T5-OTA-004 / FR-T5-OTA-025
# MANIFEST: _test_ota_003_rust_main_setup_telemetry   — FR-T5-OTA-008
# MANIFEST: _test_ota_004_rust_main_shutdown          — FR-T5-OTA-007
# MANIFEST: _test_ota_005_rust_axum_tracelayer        — FR-T5-OTA-020
# MANIFEST: _test_ota_006_rust_tonic_metadata_carrier — FR-T5-OTA-022
# MANIFEST: _test_ota_007_rust_propagation_helper     — FR-T5-OTA-023
# MANIFEST: _test_ota_010_dart_telemetry_setup        — FR-T5-OTA-040
# MANIFEST: _test_ota_011_dart_pubspec_otel           — FR-T5-OTA-042
# MANIFEST: _test_ota_012_dart_main_setup_telemetry   — FR-T5-OTA-047
# MANIFEST: _test_ota_013_dart_observers              — FR-T5-OTA-048 / FR-T5-OTA-049
# MANIFEST: _test_ota_014_dart_tracing_interceptor    — FR-T5-OTA-060
# MANIFEST: _test_ota_015_dart_repo_wires_interceptor — FR-T5-OTA-061
# MANIFEST: _test_ota_020_app_use_case_instrument     — FR-T5-OTA-009
# MANIFEST: _test_ota_021_demo_doc_signoz_section     — FR-T5-OTA-033
# MANIFEST: _test_ota_030_env_example_trio            — FR-T5-OTA-070
#
# L2 (2 tests) — gated by --level 2 ; uses cargo + flutter toolchains
# MANIFEST: _test_ota_l2_001_cargo_build_bin_server   — NFR-T5-OTA-002 / FR-T5-OTA-008
# MANIFEST: _test_ota_l2_002_flutter_analyze          — NFR-T5-OTA-002 / FR-T5-OTA-047

# ─── Helpers ────────────────────────────────────────────────────

_not_implemented() {
  echo "    not implemented (RED witness — pending implementation tasks)" >&2
  return 1
}

_skip_if_no_toolchain() {
  # _skip_if_no_toolchain <cmd> — return 0 (skip / pass) if cmd absent.
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "    skipping — '$cmd' not on PATH (toolchain absent)" >&2
    return 0
  fi
  return 1
}

# ─── L1 tests — Rust backend SDK init (FR-T5-OTA-001..007) ───────

# FR-T5-OTA-001 — telemetry module exists with required public API
_test_ota_001_rust_telemetry_module() {
  local mod="$TELEMETRY_DIR/mod.rs"
  if [ ! -f "$mod" ]; then
    echo "    telemetry module missing: $mod" >&2
    return 1
  fi
  if ! grep -q "pub fn setup_telemetry" "$mod"; then
    echo "    pub fn setup_telemetry missing in $mod" >&2
    return 1
  fi
  if ! grep -q "pub struct TelemetryConfig" "$mod"; then
    echo "    pub struct TelemetryConfig missing in $mod" >&2
    return 1
  fi
  if ! grep -q "service.name" "$mod"; then
    echo "    service.name resource attribute missing in $mod" >&2
    return 1
  fi
}

# FR-T5-OTA-004 / FR-T5-OTA-025 — workspace Cargo.toml has OTel deps
_test_ota_002_rust_cargo_otel_deps() {
  local needles=(
    'opentelemetry'
    'opentelemetry_sdk'
    'opentelemetry-otlp'
    'tracing-opentelemetry'
    'tower-http'
  )
  for n in "${needles[@]}"; do
    if ! grep -q "^$n " "$INFRA_CARGO" && ! grep -q "^$n=" "$INFRA_CARGO"; then
      echo "    workspace dep missing: $n in $INFRA_CARGO" >&2
      return 1
    fi
  done
  # tower-http MUST carry features = ["trace"]
  if ! grep -E '^tower-http\s*=.*features\s*=\s*\[.*"trace".*\]' "$INFRA_CARGO" >/dev/null; then
    echo "    tower-http features=[\"trace\"] missing in $INFRA_CARGO" >&2
    return 1
  fi
}

# FR-T5-OTA-008 — bin-server main calls setup_telemetry
_test_ota_003_rust_main_setup_telemetry() {
  if [ ! -f "$BIN_SERVER_MAIN" ]; then
    echo "    bin-server main missing: $BIN_SERVER_MAIN" >&2
    return 1
  fi
  if ! grep -q "setup_telemetry(" "$BIN_SERVER_MAIN"; then
    echo "    setup_telemetry( call missing in $BIN_SERVER_MAIN" >&2
    return 1
  fi
}

# FR-T5-OTA-007 — bin-server main calls provider.shutdown()
_test_ota_004_rust_main_shutdown() {
  if ! grep -q "\.shutdown()" "$BIN_SERVER_MAIN"; then
    echo "    provider.shutdown() missing in $BIN_SERVER_MAIN" >&2
    return 1
  fi
}

# FR-T5-OTA-020 / FR-T5-OTA-024 — axum TraceLayer wired with traceparent extraction
_test_ota_005_rust_axum_tracelayer() {
  # Look in main.rs and the middleware sibling module
  local mw="$TELEMETRY_DIR/middleware.rs"
  local found_layer=0
  local found_extract=0
  for f in "$BIN_SERVER_MAIN" "$mw"; do
    [ -f "$f" ] || continue
    grep -q "TraceLayer::new_for_http" "$f" && found_layer=1
    grep -q "make_span_with" "$f" && found_extract=1
    grep -q "traceparent" "$f" && found_extract=1
  done
  if [ "$found_layer" -ne 1 ]; then
    echo "    TraceLayer::new_for_http missing across main.rs + middleware.rs" >&2
    return 1
  fi
  if [ "$found_extract" -ne 1 ]; then
    echo "    make_span_with / traceparent extraction missing" >&2
    return 1
  fi
}

# FR-T5-OTA-022 — propagation.rs declares MetadataMapCarrier as Extractor
_test_ota_006_rust_tonic_metadata_carrier() {
  local prop="$TELEMETRY_DIR/propagation.rs"
  if [ ! -f "$prop" ]; then
    echo "    propagation helper missing: $prop" >&2
    return 1
  fi
  if ! grep -q "MetadataMapCarrier" "$prop"; then
    echo "    MetadataMapCarrier struct missing in $prop" >&2
    return 1
  fi
  if ! grep -q "Extractor" "$prop"; then
    echo "    Extractor impl missing in $prop" >&2
    return 1
  fi
}

# FR-T5-OTA-023 — propagation.rs declares HeaderMapCarrier as Injector
_test_ota_007_rust_propagation_helper() {
  local prop="$TELEMETRY_DIR/propagation.rs"
  if [ ! -f "$prop" ]; then
    echo "    propagation helper missing: $prop" >&2
    return 1
  fi
  if ! grep -q "HeaderMapCarrier" "$prop"; then
    echo "    HeaderMapCarrier struct missing in $prop" >&2
    return 1
  fi
  if ! grep -q "Injector" "$prop"; then
    echo "    Injector impl missing in $prop" >&2
    return 1
  fi
}

# ─── L1 tests — Flutter SDK init (FR-T5-OTA-040..050) ────────────

# FR-T5-OTA-040 / FR-T5-OTA-046 — telemetry_setup.dart exists with required API
_test_ota_010_dart_telemetry_setup() {
  local f="$LIB_TELEMETRY_DIR/telemetry_setup.dart"
  if [ ! -f "$f" ]; then
    echo "    telemetry_setup.dart missing: $f" >&2
    return 1
  fi
  if ! grep -q "Future<void> setupTelemetry" "$f"; then
    echo "    Future<void> setupTelemetry signature missing in $f" >&2
    return 1
  fi
  if ! grep -q "registerGlobalTracerProvider" "$f"; then
    echo "    registerGlobalTracerProvider call missing in $f" >&2
    return 1
  fi
}

# FR-T5-OTA-042 / FR-T5-OTA-064 — pubspec dependencies
_test_ota_011_dart_pubspec_otel() {
  if [ ! -f "$PUBSPEC" ]; then
    echo "    pubspec.yaml missing: $PUBSPEC" >&2
    return 1
  fi
  if ! grep -qE "^\s*opentelemetry:" "$PUBSPEC"; then
    echo "    opentelemetry: dep missing in $PUBSPEC" >&2
    return 1
  fi
  if ! grep -qE "^\s*dio:" "$PUBSPEC"; then
    echo "    dio: dep missing in $PUBSPEC" >&2
    return 1
  fi
}

# FR-T5-OTA-047 — main.dart bootstrap shape
_test_ota_012_dart_main_setup_telemetry() {
  if [ ! -f "$LIB_MAIN" ]; then
    echo "    main.dart missing: $LIB_MAIN" >&2
    return 1
  fi
  if ! grep -q "setupTelemetry" "$LIB_MAIN"; then
    echo "    setupTelemetry call missing in $LIB_MAIN" >&2
    return 1
  fi
  if ! grep -q "Bloc.observer" "$LIB_MAIN"; then
    echo "    Bloc.observer assignment missing in $LIB_MAIN" >&2
    return 1
  fi
  if ! grep -q "navigatorObservers" "$LIB_MAIN"; then
    echo "    navigatorObservers parameter missing in $LIB_MAIN" >&2
    return 1
  fi
}

# FR-T5-OTA-048 / FR-T5-OTA-049 / FR-T5-OTA-050 — observer files exist
_test_ota_013_dart_observers() {
  local nav="$LIB_TELEMETRY_DIR/observers/tracing_navigation_observer.dart"
  local bloc="$LIB_TELEMETRY_DIR/observers/tracing_bloc_observer.dart"
  local err="$LIB_TELEMETRY_DIR/error_reporter.dart"
  for f in "$nav" "$bloc" "$err"; do
    if [ ! -f "$f" ]; then
      echo "    observer file missing: $f" >&2
      return 1
    fi
  done
}

# FR-T5-OTA-060 / FR-T5-OTA-063 — TracingInterceptor exists
_test_ota_014_dart_tracing_interceptor() {
  local f="$LIB_TELEMETRY_DIR/interceptors/tracing_interceptor.dart"
  if [ ! -f "$f" ]; then
    echo "    tracing_interceptor.dart missing: $f" >&2
    return 1
  fi
  if ! grep -q "extends Interceptor" "$f"; then
    echo "    'extends Interceptor' missing in $f" >&2
    return 1
  fi
  if ! grep -q "W3CTraceContextPropagator" "$f"; then
    echo "    W3CTraceContextPropagator missing in $f" >&2
    return 1
  fi
  if ! grep -q "_sanitizePath" "$f"; then
    echo "    _sanitizePath helper missing in $f" >&2
    return 1
  fi
}

# FR-T5-OTA-061 — greeting_repository_impl wires TracingInterceptor
_test_ota_015_dart_repo_wires_interceptor() {
  if [ ! -f "$GREETING_REPO" ]; then
    echo "    greeting_repository_impl missing: $GREETING_REPO" >&2
    return 1
  fi
  if ! grep -q "TracingInterceptor" "$GREETING_REPO"; then
    echo "    TracingInterceptor not wired in $GREETING_REPO" >&2
    return 1
  fi
}

# ─── L1 tests — demo-005 (FR-T5-OTA-009 / FR-T5-OTA-033) ─────────

# FR-T5-OTA-009 / FR-T5-OTA-030 — application use case carries #[tracing::instrument]
_test_ota_020_app_use_case_instrument() {
  if [ ! -d "$APP_CRATE_DIR" ]; then
    echo "    application crate src missing: $APP_CRATE_DIR" >&2
    return 1
  fi
  if ! grep -rq "#\[tracing::instrument" "$APP_CRATE_DIR"; then
    echo "    no #[tracing::instrument] annotation in $APP_CRATE_DIR" >&2
    return 1
  fi
}

# FR-T5-OTA-033 — demo doc has 'Trace this in SigNoz' section
_test_ota_021_demo_doc_signoz_section() {
  if [ ! -f "$DEMO_DOC" ]; then
    echo "    demo doc missing: $DEMO_DOC" >&2
    return 1
  fi
  if ! grep -q "^## Trace this in SigNoz$" "$DEMO_DOC"; then
    echo "    '## Trace this in SigNoz' H2 section missing in $DEMO_DOC" >&2
    return 1
  fi
}

# ─── L1 tests — env config (FR-T5-OTA-070..072) ──────────────────

# FR-T5-OTA-070 / FR-T5-OTA-071 — env config documented (trio + DEPLOYMENT_ENV).
#
# NOTE : the original spec target was `.env.example`, but the impl-time
# permission gate denies writes to dotfile-prefixed paths in this worktree.
# The trio is documented in README.md § "Environment configuration"
# instead — same audit semantics (committed, adopter-visible, FR coverage
# preserved). Phase D : promote env config to a dotfile when the
# permission gate is loosened.
_test_ota_030_env_example_trio() {
  if [ ! -f "$ENV_DOC" ]; then
    echo "    env doc missing: $ENV_DOC" >&2
    return 1
  fi
  local needles=(
    "OTEL_EXPORTER_OTLP_ENDPOINT"
    "OTEL_SERVICE_NAME"
    "OTEL_RESOURCE_ATTRIBUTES"
    "DEPLOYMENT_ENV"
  )
  for n in "${needles[@]}"; do
    if ! grep -q "$n" "$ENV_DOC"; then
      echo "    env var missing: $n in $ENV_DOC" >&2
      return 1
    fi
  done
}

# ─── L2 smoke tests (gated by LEVEL contains 2) ─────────────────

# FR-T5-OTA-008 / NFR-T5-OTA-002 — cargo build -p bin-server passes
_test_ota_l2_001_cargo_build_bin_server() {
  if _skip_if_no_toolchain cargo; then return 0; fi
  if ! (cd "$BACKEND" && cargo build -p bin-server --locked >/dev/null 2>&1); then
    echo "    cargo build -p bin-server failed" >&2
    return 1
  fi
}

# FR-T5-OTA-047 / NFR-T5-OTA-002 — flutter analyze passes.
#
# Q-004 RESOLVED 2026-05-12 : `flutter/opentelemetry.md` was realigned to
# the actual `opentelemetry: 0.18.11` (Workiva) API surface in the sibling
# change `t5-otel-dart-api-realign` (standard v1.0.0 → v1.1.0). The Dart
# example code in this worktree was realigned in the Q-004 follow-up
# commit : `CollectorExporter(Uri)` replaces fabricated `OtlpHttpSpanExporter`,
# `BatchSpanProcessor` takes positional exporter + named params,
# `ParentBasedSampler(AlwaysOnSampler())` replaces fabricated
# `TraceIdRatioBasedSampler(1.0)`, `StatusCode.{ok,error}` replaces
# fabricated `SpanStatusCode.*`, `setStatus(code, description)` is now
# positional (not `description:` named), and `contextWithSpan(Context, Span)`
# replaces the JS/Java-style `Context.current.withSpan(...)`. The legacy
# `exporter_otlp_*.dart` sub-imports are removed in favour of the two
# canonical entry points `api.dart` + `sdk.dart`.
#
# This test now runs `flutter analyze` against the realigned example and
# expects exit 0. It skips cleanly when `flutter` is not on PATH so the
# CI L1 matrix (no toolchain) and dev hosts without Flutter installed do
# not regress. The L2 matrix entry in `forge-ci.yml` runs this with the
# Flutter toolchain installed.
_test_ota_l2_002_flutter_analyze() {
  if _skip_if_no_toolchain flutter; then return 0; fi
  if ! (cd "$FRONTEND" && flutter analyze >/dev/null 2>&1); then
    echo "    flutter analyze failed in $FRONTEND" >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T.5 — t5-otel-app harness (level $LEVEL) ──"
  echo ""
  echo "Phase B L1 — Rust SDK init"
  run_test _test_ota_001_rust_telemetry_module
  run_test _test_ota_002_rust_cargo_otel_deps
  run_test _test_ota_003_rust_main_setup_telemetry
  run_test _test_ota_004_rust_main_shutdown
  run_test _test_ota_005_rust_axum_tracelayer
  run_test _test_ota_006_rust_tonic_metadata_carrier
  run_test _test_ota_007_rust_propagation_helper

  echo ""
  echo "Phase B L1 — Flutter SDK init"
  run_test _test_ota_010_dart_telemetry_setup
  run_test _test_ota_011_dart_pubspec_otel
  run_test _test_ota_012_dart_main_setup_telemetry
  run_test _test_ota_013_dart_observers
  run_test _test_ota_014_dart_tracing_interceptor
  run_test _test_ota_015_dart_repo_wires_interceptor

  echo ""
  echo "Phase B L1 — demo-005 + env"
  run_test _test_ota_020_app_use_case_instrument
  run_test _test_ota_021_demo_doc_signoz_section
  run_test _test_ota_030_env_example_trio

  case ",$LEVEL," in
    *,2,*)
      echo ""
      echo "Phase B L2 — toolchain smoke"
      run_test _test_ota_l2_001_cargo_build_bin_server
      run_test _test_ota_l2_002_flutter_analyze
      ;;
  esac

  print_summary
}

main "$@"
