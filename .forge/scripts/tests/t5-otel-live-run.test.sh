#!/usr/bin/env bash
# Forge — T.5 Phase D OTel Live-Run Harness (t5-otel-live-run)
# <!-- Audit: T.5 (t5-otel-live-run) — Phase D collector-boundary contract validation -->
#
# Validates the additive Phase D deliverables :
#   - Fake OTLP collector (Python stdlib only) under
#     `examples/forge-fsm-example/test/live-run/fake_otlp_collector.py`.
#   - Smoke driver `examples/forge-fsm-example/test/live-run/run_smoke.sh`.
#   - Golden captures under `.forge/changes/t5-otel-live-run/captures/`.
#   - BDD feature `examples/forge-fsm-example/test/features/traceparent_live_run.feature`.
#   - Docker-compose live-run config (opt-in via FORGE_LIVE_RUN_DOCKER=1).
#   - CI matrix registration.
#
# 8 L1 hermetic tests + 1 L2 docker smoke (opt-in).
# Performance budget : L1 ≤ 10 s, L2 ≤ 60 s.
#
# Phase D is HERMETIC by default — the L1 leg drives a Python fake
# collector + canned OTLP probe. Docker leg is opt-in.

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
LIVE_RUN_DIR="$EXAMPLE/test/live-run"
COLLECTOR_PY="$LIVE_RUN_DIR/fake_otlp_collector.py"
DRIVER_SH="$LIVE_RUN_DIR/run_smoke.sh"
COMPOSE_YML="$LIVE_RUN_DIR/docker-compose.live-run.yml"
FEATURE_FILE="$EXAMPLE/test/features/traceparent_live_run.feature"
CAPTURES_DIR="$FORGE_ROOT_REAL/.forge/changes/t5-otel-live-run/captures"
DIRECT_GOLDEN="$CAPTURES_DIR/direct.golden.json"
KONG_GOLDEN="$CAPTURES_DIR/kong.golden.json"
CI_YML="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (8 tests) — all hermetic, no network, no Docker
# MANIFEST: _test_olr_001_driver_files_exist            — FR-T5-OLR-001 / FR-T5-OLR-020
# MANIFEST: _test_olr_002_collector_stdlib_only         — FR-T5-OLR-010
# MANIFEST: _test_olr_003_smoke_driver_runs             — FR-T5-OLR-021..027
# MANIFEST: _test_olr_004_capture_matches_direct_golden — FR-T5-OLR-040 / FR-T5-OLR-009
# MANIFEST: _test_olr_005_capture_matches_kong_golden   — FR-T5-OLR-041 / FR-T5-OLR-009
# MANIFEST: _test_olr_010_feature_file_exists           — FR-T5-OLR-060..064
# MANIFEST: _test_olr_020_goldens_sanitised             — FR-T5-OLR-043 / FR-T5-OLR-087
# MANIFEST: _test_olr_030_ci_matrix_entry               — FR-T5-OLR-120 / FR-T5-OLR-088 / NFR-T5-OLR-005
#
# L2 (1 test) — gated by --level 2 + FORGE_LIVE_RUN_DOCKER=1
# MANIFEST: _test_olr_l2_001_docker_compose_smoke       — FR-T5-OLR-101

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

# ─── L1 tests — driver + collector files (FR-T5-OLR-001 / FR-T5-OLR-020) ──

_test_olr_001_driver_files_exist() {
  if [ ! -f "$COLLECTOR_PY" ]; then
    echo "    collector missing: $COLLECTOR_PY" >&2
    return 1
  fi
  if [ ! -f "$DRIVER_SH" ]; then
    echo "    driver missing: $DRIVER_SH" >&2
    return 1
  fi
  if ! grep -q "Audit: T.5 (t5-otel-live-run)" "$COLLECTOR_PY"; then
    echo "    audit header missing in $COLLECTOR_PY" >&2
    return 1
  fi
  if ! grep -q "Audit: T.5 (t5-otel-live-run)" "$DRIVER_SH"; then
    echo "    audit header missing in $DRIVER_SH" >&2
    return 1
  fi
}

# FR-T5-OLR-010 — Collector is stdlib-only (no third-party imports)
_test_olr_002_collector_stdlib_only() {
  if [ ! -f "$COLLECTOR_PY" ]; then
    echo "    collector missing: $COLLECTOR_PY" >&2
    return 1
  fi
  # Forbidden imports — any of these would defeat the hermetic property.
  local forbidden=("protobuf" "google.protobuf" "grpc" "requests" "httpx" "yaml" "opentelemetry")
  for mod in "${forbidden[@]}"; do
    if grep -qE "^(import|from)[[:space:]]+${mod}([[:space:]]|\.|$)" "$COLLECTOR_PY"; then
      echo "    forbidden import '$mod' in $COLLECTOR_PY" >&2
      grep -nE "^(import|from)[[:space:]]+${mod}" "$COLLECTOR_PY" >&2
      return 1
    fi
  done
}

# FR-T5-OLR-021..027 — Smoke driver runs end-to-end, exit 0, capture appears
_test_olr_003_smoke_driver_runs() {
  if _skip_if_no_toolchain python3; then return 0; fi
  if [ ! -x "$DRIVER_SH" ] && [ ! -f "$DRIVER_SH" ]; then
    echo "    driver missing or not executable: $DRIVER_SH" >&2
    return 1
  fi
  local tmpdir
  tmpdir=$(mktemp -d -t fsm-live-run-XXXXXX)
  trap "rm -rf '$tmpdir'" RETURN
  if ! bash "$DRIVER_SH" --out "$tmpdir" --scenario direct >/dev/null 2>"$tmpdir/stderr.log"; then
    echo "    driver exited non-zero ; stderr:" >&2
    sed 's/^/      /' "$tmpdir/stderr.log" >&2 || true
    return 1
  fi
  if ! ls "$tmpdir"/capture-*.json >/dev/null 2>&1; then
    echo "    no capture-NNN.json file appeared in $tmpdir" >&2
    return 1
  fi
}

# FR-T5-OLR-040 / FR-T5-OLR-009 — Direct capture matches the committed golden
_test_olr_004_capture_matches_direct_golden() {
  if _skip_if_no_toolchain python3; then return 0; fi
  if [ ! -f "$DIRECT_GOLDEN" ]; then
    echo "    direct golden missing: $DIRECT_GOLDEN" >&2
    return 1
  fi
  local tmpdir
  tmpdir=$(mktemp -d -t fsm-live-run-XXXXXX)
  trap "rm -rf '$tmpdir'" RETURN
  if ! bash "$DRIVER_SH" --out "$tmpdir" --scenario direct >/dev/null 2>"$tmpdir/stderr.log"; then
    echo "    driver failed before diff ; stderr:" >&2
    sed 's/^/      /' "$tmpdir/stderr.log" >&2 || true
    return 1
  fi
  local cap
  cap=$(ls "$tmpdir"/capture-*.json 2>/dev/null | head -1)
  if [ -z "$cap" ]; then
    echo "    no capture produced in $tmpdir" >&2
    return 1
  fi
  if ! diff -q "$cap" "$DIRECT_GOLDEN" >/dev/null 2>&1; then
    echo "    direct capture does NOT match golden ; diff:" >&2
    diff "$cap" "$DIRECT_GOLDEN" 2>&1 | sed 's/^/      /' >&2 || true
    return 1
  fi
}

# FR-T5-OLR-041 / FR-T5-OLR-009 — Kong capture matches the committed golden
_test_olr_005_capture_matches_kong_golden() {
  if _skip_if_no_toolchain python3; then return 0; fi
  if [ ! -f "$KONG_GOLDEN" ]; then
    echo "    kong golden missing: $KONG_GOLDEN" >&2
    return 1
  fi
  local tmpdir
  tmpdir=$(mktemp -d -t fsm-live-run-XXXXXX)
  trap "rm -rf '$tmpdir'" RETURN
  if ! bash "$DRIVER_SH" --out "$tmpdir" --scenario kong >/dev/null 2>"$tmpdir/stderr.log"; then
    echo "    driver failed before diff ; stderr:" >&2
    sed 's/^/      /' "$tmpdir/stderr.log" >&2 || true
    return 1
  fi
  local cap
  cap=$(ls "$tmpdir"/capture-*.json 2>/dev/null | head -1)
  if [ -z "$cap" ]; then
    echo "    no capture produced in $tmpdir" >&2
    return 1
  fi
  if ! diff -q "$cap" "$KONG_GOLDEN" >/dev/null 2>&1; then
    echo "    kong capture does NOT match golden ; diff:" >&2
    diff "$cap" "$KONG_GOLDEN" 2>&1 | sed 's/^/      /' >&2 || true
    return 1
  fi
}

# FR-T5-OLR-060..064 — BDD feature file shape
_test_olr_010_feature_file_exists() {
  if [ ! -f "$FEATURE_FILE" ]; then
    echo "    feature file missing: $FEATURE_FILE" >&2
    return 1
  fi
  if ! grep -q "Audit: T.5 (t5-otel-live-run)" "$FEATURE_FILE"; then
    echo "    audit header missing in $FEATURE_FILE" >&2
    return 1
  fi
  local count
  count=$(grep -cE '^[[:space:]]*Scenario:' "$FEATURE_FILE" 2>/dev/null || echo 0)
  if [ "$count" -ne 2 ]; then
    echo "    expected 2 'Scenario:' lines, found $count" >&2
    return 1
  fi
  if ! grep -qE '^Feature:' "$FEATURE_FILE"; then
    echo "    'Feature:' keyword missing" >&2
    return 1
  fi
  local missing
  missing=$(awk '
    /^[[:space:]]*Scenario:/ { sc=NR; name=$0; gw=0; wh=0; th=0; next }
    /^[[:space:]]*(Given|And|But) / { if (sc) { if (gw == 0) gw=1 } }
    /^[[:space:]]*When / { if (sc) wh=1 }
    /^[[:space:]]*Then / { if (sc) th=1 }
    /^[[:space:]]*Scenario:/ || /^Feature:/ || /^$/ { if (sc && (gw==0 || wh==0 || th==0)) { printf "%s [G=%d W=%d T=%d]\n", name, gw, wh, th; sc=0 } }
    END { if (sc && (gw==0 || wh==0 || th==0)) { printf "%s [G=%d W=%d T=%d]\n", name, gw, wh, th } }
  ' "$FEATURE_FILE")
  if [ -n "$missing" ]; then
    echo "    scenario(s) missing Given/When/Then:" >&2
    echo "$missing" | sed 's/^/      /' >&2
    return 1
  fi
  # Phase B symbol forward-pointer
  local found=0
  for sym in HeaderMapExtractor MetadataMapCarrier HeaderMapCarrier; do
    if grep -q "$sym" "$FEATURE_FILE"; then found=1; break; fi
  done
  if [ "$found" -ne 1 ]; then
    echo "    no Phase B symbol referenced in $FEATURE_FILE" >&2
    return 1
  fi
  # Cross-reference to Phase C feature
  if ! grep -q "traceparent_e2e.feature" "$FEATURE_FILE"; then
    echo "    Phase C cross-reference missing in $FEATURE_FILE" >&2
    return 1
  fi
}

# FR-T5-OLR-043 / FR-T5-OLR-087 — Both goldens are sanitised (no IPs, ts redacted)
_test_olr_020_goldens_sanitised() {
  for golden in "$DIRECT_GOLDEN" "$KONG_GOLDEN"; do
    if [ ! -f "$golden" ]; then
      echo "    golden missing: $golden" >&2
      return 1
    fi
    if ! grep -q '"<ts:redacted>"' "$golden"; then
      echo "    timestamp sanitiser placeholder '<ts:redacted>' missing in $golden" >&2
      return 1
    fi
    if grep -qE '"([0-9]{1,3}\.){3}[0-9]{1,3}"' "$golden"; then
      echo "    forbidden : IPv4 dotted-quad pattern found in $golden" >&2
      grep -nE '"([0-9]{1,3}\.){3}[0-9]{1,3}"' "$golden" >&2 || true
      return 1
    fi
  done
}

# FR-T5-OLR-120 / FR-T5-OLR-088 / NFR-T5-OLR-005 — CI matrix entry + file size
_test_olr_030_ci_matrix_entry() {
  if [ ! -f "$CI_YML" ]; then
    echo "    forge-ci.yml missing: $CI_YML" >&2
    return 1
  fi
  if ! grep -q "t5-otel-live-run.test.sh" "$CI_YML"; then
    echo "    t5-otel-live-run.test.sh entry missing in $CI_YML" >&2
    return 1
  fi
  if ! grep -E "t5-otel-live-run\.test\.sh.*--level 1" "$CI_YML" >/dev/null; then
    echo "    --level 1 flag missing on t5-otel-live-run.test.sh" >&2
    return 1
  fi
  local line_tpe line_olr
  line_tpe=$(grep -n "t5-otel-traceparent-e2e.test.sh" "$CI_YML" | head -1 | cut -d: -f1 || echo 0)
  line_olr=$(grep -n "t5-otel-live-run.test.sh" "$CI_YML" | head -1 | cut -d: -f1 || echo 0)
  if [ "$line_tpe" -eq 0 ] || [ "$line_olr" -eq 0 ] || [ "$line_olr" -le "$line_tpe" ]; then
    echo "    t5-otel-live-run.test.sh MUST appear after t5-otel-traceparent-e2e.test.sh (tpe=$line_tpe olr=$line_olr)" >&2
    return 1
  fi
  # NFR-T5-OLR-005 / NFR-CI-002 — forge-ci.yml ≤ 340 lines (bumped 300→340
  # 2026-06-23 by b7-7-example's second-tree RAG gate; in sync with c1/g1/t5-1).
  local total
  total=$(wc -l < "$CI_YML" | tr -d ' ')
  if [ "$total" -gt 340 ]; then
    echo "    forge-ci.yml is $total lines, exceeds NFR-CI-002 budget of 340" >&2
    return 1
  fi
}

# ─── L2 smoke (gated by LEVEL contains 2 AND FORGE_LIVE_RUN_DOCKER=1) ──

# FR-T5-OLR-101 — Docker-compose opt-in smoke
_test_olr_l2_001_docker_compose_smoke() {
  if [ "${FORGE_LIVE_RUN_DOCKER:-0}" != "1" ]; then
    echo "    skipping — FORGE_LIVE_RUN_DOCKER != 1 (docker leg is opt-in)" >&2
    return 0
  fi
  if ! command -v docker >/dev/null 2>&1; then
    echo "    skipping — 'docker' not on PATH" >&2
    return 0
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo "    skipping — 'docker compose' subcommand unavailable" >&2
    return 0
  fi
  if [ ! -f "$COMPOSE_YML" ]; then
    echo "    docker-compose live-run config missing: $COMPOSE_YML" >&2
    return 1
  fi
  # Boot the minimal stack, run --probe-only against it, then teardown.
  local proj="fsm-live-run-$$"
  local tmpdir
  tmpdir=$(mktemp -d -t fsm-live-run-docker-XXXXXX)
  trap "docker compose -f '$COMPOSE_YML' -p '$proj' down -v >/dev/null 2>&1 || true; rm -rf '$tmpdir'" RETURN
  if ! (cd "$LIVE_RUN_DIR" && docker compose -f "$COMPOSE_YML" -p "$proj" up -d --wait >/dev/null 2>&1); then
    echo "    docker compose up failed" >&2
    return 1
  fi
  # The compose stack maps :4318 to host ; probe locally.
  if ! bash "$DRIVER_SH" --out "$tmpdir" --scenario direct --probe-only >/dev/null 2>"$tmpdir/stderr.log"; then
    echo "    --probe-only driver failed against docker stack" >&2
    sed 's/^/      /' "$tmpdir/stderr.log" >&2 || true
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T.5 — t5-otel-live-run harness (level $LEVEL) ──"
  echo ""
  echo "Phase D L1 — driver + collector files"
  run_test _test_olr_001_driver_files_exist
  run_test _test_olr_002_collector_stdlib_only

  echo ""
  echo "Phase D L1 — smoke driver execution + golden captures"
  run_test _test_olr_003_smoke_driver_runs
  run_test _test_olr_004_capture_matches_direct_golden
  run_test _test_olr_005_capture_matches_kong_golden

  echo ""
  echo "Phase D L1 — BDD feature + sanitisation evidence"
  run_test _test_olr_010_feature_file_exists
  run_test _test_olr_020_goldens_sanitised

  echo ""
  echo "Phase D L1 — CI matrix registration"
  run_test _test_olr_030_ci_matrix_entry

  case ",$LEVEL," in
    *,2,*)
      echo ""
      echo "Phase D L2 — docker-compose smoke (opt-in via FORGE_LIVE_RUN_DOCKER=1)"
      run_test _test_olr_l2_001_docker_compose_smoke
      ;;
  esac

  print_summary
}

main "$@"
