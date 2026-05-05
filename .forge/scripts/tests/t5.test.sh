#!/usr/bin/env bash
# Forge — T5 Connect codegen Test Harness (t5-connect-codegen)
# <!-- Audit: T.5 (t5-connect-codegen) -->
#
# Validates the additive Connect-RPC deliverables of t5-connect-codegen :
#   - buf.gen.yaml extension with 5 plugin entries (FR-T5-CC-001..003 + ADR-T5-001 Rust local plugins)
#   - tonic-build invocation preserved (FR-T5-CC-004)
#   - gen/connect/ added to template .gitignore (FR-T5-CC-005)
#   - transport.yaml v1.1.0 with codegen.connect_layout_version + codegen.versions (FR-T5-CC-020..023)
#   - Rust transport/connect.rs adapter using connectrpc + into_axum_service() (FR-T5-CC-010..013)
#   - main.rs preserves tonic gRPC bind ; mounts /connect (FR-T5-CC-010..011)
#   - Domain layer untouched (FR-T5-CC-012)
#   - demo-005-connect-greeting archived in examples (FR-T5-CC-030..035)
#   - constitution-linter.sh transport-codegen-coverage WARN-only (FR-T5-CC-040..041)
#   - snapshot tarball regenerated within 500 KB budget (FR-T5-CC-050..051)
#
# 30 tests : 25 L1 hermetic + 5 L2 fixture-based.
# Performance budget : L1 ≤ 5 s, full ≤ 30 s wall-clock (NFR-T5-CC-001).
# L2 SKIP semantics : when `buf` CLI is absent locally, L2 tests print
# `[SKIP: buf CLI missing]` and return 0 (counted as PASS for the
# purpose of run_test ; CI always has buf).

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

STD_DIR="$FORGE_ROOT_REAL/.forge/standards"
TPL_DIR="$FORGE_ROOT_REAL/templates/full-stack-monorepo/1.0.0"
PROTO_DIR="$TPL_DIR/proto"
BACKEND_DIR="$TPL_DIR/backend"
EXAMPLE_DIR="$FORGE_ROOT_REAL/examples/forge-fsm-example"
DEMO5_DIR="$EXAMPLE_DIR/.forge/changes/demo-005-connect-greeting"
LINTER="$FORGE_ROOT_REAL/.forge/scripts/constitution-linter.sh"
SNAPSHOT="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (25 tests)
# MANIFEST: _test_t5_001 — FR-T5-CC-001 buf.gen.yaml parses
# MANIFEST: _test_t5_002 — FR-T5-CC-001 buf.gen.yaml has buf.build/connectrpc/go entry
# MANIFEST: _test_t5_003 — FR-T5-CC-002 buf.gen.yaml has buf.build/bufbuild/es entry (Connect v2)
# MANIFEST: _test_t5_004 — FR-T5-CC-003 buf.gen.yaml has buf.build/connectrpc/dart official entry
# MANIFEST: _test_t5_005 — ADR-T5-001 buf.gen.yaml has local protoc-gen-buffa entry
# MANIFEST: _test_t5_006 — ADR-T5-001 buf.gen.yaml has local protoc-gen-connect-rust entry
# MANIFEST: _test_t5_007 — FR-T5-CC-004 tonic-build invocation preserved in build.rs
# MANIFEST: _test_t5_008 — FR-T5-CC-005 template .gitignore lists gen/connect/
# MANIFEST: _test_t5_009 — FR-T5-CC-020 transport.yaml version is 1.1.0
# MANIFEST: _test_t5_010 — FR-T5-CC-021 transport.yaml has codegen.connect_layout_version: 1
# MANIFEST: _test_t5_011 — FR-T5-CC-022 transport.yaml codegen.versions includes connectrpc =0.3.3
# MANIFEST: _test_t5_012 — FR-T5-CC-023 REVIEW.md has Updated entry for transport.yaml v1.1.0
# MANIFEST: _test_t5_013 — FR-T5-CC-010 transport/connect.rs module exists
# MANIFEST: _test_t5_014 — FR-T5-CC-010 main.rs mounts /connect via connect::into_router
# MANIFEST: _test_t5_015 — FR-T5-CC-013 connect.rs OTel layer is outside connectrpc service
# MANIFEST: _test_t5_016 — FR-T5-CC-011 main.rs tonic gRPC server bind unchanged
# MANIFEST: _test_t5_017 — FR-T5-CC-012 domain layer untouched (no diff)
# MANIFEST: _test_t5_018 — FR-T5-CC-030 demo-005-connect-greeting archived shape
# MANIFEST: _test_t5_019 — FR-T5-CC-031 demo-005 specs.md has 2 BDD scenarios
# MANIFEST: _test_t5_020 — FR-T5-CC-032 connect-client.ts parses with node --check
# MANIFEST: _test_t5_021 — FR-T5-CC-040 linter transport-codegen-coverage WARN positive
# MANIFEST: _test_t5_022 — FR-T5-CC-041 linter respects FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1
# MANIFEST: _test_t5_023 — FR-T5-CC-050 snapshot tarball regenerated (mtime > baseline)
# MANIFEST: _test_t5_024 — FR-T5-CC-051 snapshot tarball ≤ 500 KB gzipped
# MANIFEST: _test_t5_025 — FR-T5-CC-035 example README.md links demo-005
#
# L2 (5 fixture tests)
# MANIFEST: _test_t5_l2_buf_gen_layouts       — FR-T5-CC-064 buf generate produces 3 lang trees
# MANIFEST: _test_t5_l2_dart_smoke            — FR-T5-CC-003 official Dart plugin codegen succeeds
# MANIFEST: _test_t5_l2_traceparent_dual      — FR-T5-CC-014 + FR-T5-CC-033 dual codec traceparent E2E
# MANIFEST: _test_t5_l2_cargo_fixture_build   — FR-T5-CC-064 cargo build of fixture workspace
# MANIFEST: _test_t5_l2_connectrpc_dual_codec — FR-T5-CC-014 connect+json AND gRPC-Web both 200

# ─── Helpers ────────────────────────────────────────────────────

_yq_eval() {
  if command -v yq >/dev/null 2>&1; then
    yq eval "$1" "$2" 2>/dev/null
  else
    python3 - "$1" "$2" <<'PY' 2>/dev/null
import sys, yaml
expr = sys.argv[1]
path = sys.argv[2]
with open(path) as f:
    data = yaml.safe_load(f)
keys = [k for k in expr.lstrip('.').split('.') if k]
val = data
for k in keys:
    if isinstance(val, dict) and k in val:
        val = val[k]
    else:
        sys.exit(1)
if isinstance(val, (list, dict)):
    print(yaml.safe_dump(val).strip())
else:
    print(val)
PY
  fi
}

_yq_parses() {
  if command -v yq >/dev/null 2>&1; then
    yq eval '.' "$1" >/dev/null 2>&1
  else
    python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$1" >/dev/null 2>&1
  fi
}

_skip_if_no_buf() {
  if ! command -v buf >/dev/null 2>&1; then
    echo "    [SKIP: buf CLI missing — install via buf.build/docs/cli/installation]" >&2
    return 0  # treated as PASS-with-skip in run_test reporting
  fi
  return 99  # sentinel : continue with the L2 test
}

_setup_l2() {
  L2_TMP="$(mk_tmpdir_with_trap forge-t5-fixtures)"
}

_teardown_l2() {
  if [ -n "${L2_TMP:-}" ] && [ -d "$L2_TMP" ]; then
    rm -rf "$L2_TMP"
  fi
}

# Sentinel-fail helper : every stub returns FAIL with a "not implemented"
# stderr message. The body is replaced with real assertions in subsequent
# T-STD-*, T-BUF-*, T-RUST-*, T-DEMO-*, T-LNT-*, T-SNP-*, T-L2-* tasks.
_not_implemented() {
  echo "    not implemented (RED witness — pending implementation tasks)" >&2
  return 1
}

# ─── L1 stubs ───────────────────────────────────────────────────

_test_t5_001() { _not_implemented; }   # buf.gen.yaml parses
_test_t5_002() { _not_implemented; }   # connectrpc/go entry
_test_t5_003() { _not_implemented; }   # bufbuild/es entry
_test_t5_004() { _not_implemented; }   # connectrpc/dart entry
_test_t5_005() { _not_implemented; }   # local protoc-gen-buffa
_test_t5_006() { _not_implemented; }   # local protoc-gen-connect-rust
_test_t5_007() { _not_implemented; }   # tonic-build preserved
_test_t5_008() { _not_implemented; }   # gen/connect/ in .gitignore
_test_t5_009() {
  # FR-T5-CC-020 : transport.yaml version is 1.1.0
  local v
  v="$(_yq_eval '.version' "$STD_DIR/transport.yaml")"
  assert_eq "1.1.0" "$v" "transport.yaml version"
}
_test_t5_010() {
  # FR-T5-CC-021 : transport.yaml has codegen.connect_layout_version: 1
  local v
  v="$(_yq_eval '.codegen.connect_layout_version' "$STD_DIR/transport.yaml")"
  assert_eq "1" "$v" "transport.yaml codegen.connect_layout_version"
}
_test_t5_011() {
  # FR-T5-CC-022 : codegen.versions includes connectrpc =0.3.3 (sentinel pin)
  local v
  v="$(_yq_eval '.codegen.versions.connectrpc' "$STD_DIR/transport.yaml")"
  assert_eq "=0.3.3" "$v" "transport.yaml codegen.versions.connectrpc"
}
_test_t5_012() {
  # FR-T5-CC-023 : REVIEW.md has Updated entry for transport.yaml v1.1.0
  if ! grep -qE 'transport\.yaml.*1\.1\.0' "$STD_DIR/REVIEW.md"; then
    echo "    REVIEW.md missing Updated entry for transport.yaml v1.1.0" >&2
    return 1
  fi
}
_test_t5_013() { _not_implemented; }   # transport/connect.rs exists
_test_t5_014() { _not_implemented; }   # main.rs mounts /connect
_test_t5_015() { _not_implemented; }   # OTel outside connectrpc
_test_t5_016() { _not_implemented; }   # tonic gRPC bind unchanged
_test_t5_017() { _not_implemented; }   # domain untouched
_test_t5_018() { _not_implemented; }   # demo-005 archived shape
_test_t5_019() { _not_implemented; }   # demo-005 has 2 BDD scenarios
_test_t5_020() { _not_implemented; }   # connect-client.ts parses
_test_t5_021() { _not_implemented; }   # linter WARN positive
_test_t5_022() { _not_implemented; }   # linter SKIP env var honored
_test_t5_023() { _not_implemented; }   # snapshot regenerated
_test_t5_024() { _not_implemented; }   # snapshot ≤ 500 KB
_test_t5_025() { _not_implemented; }   # README links demo-005

# ─── L2 stubs (run only at level 2) ─────────────────────────────

_test_t5_l2_buf_gen_layouts() {
  _skip_if_no_buf; rc=$?; [ $rc -eq 0 ] && return 0
  _setup_l2
  trap '_teardown_l2' RETURN
  _not_implemented
}

_test_t5_l2_dart_smoke() {
  _skip_if_no_buf; rc=$?; [ $rc -eq 0 ] && return 0
  _setup_l2
  trap '_teardown_l2' RETURN
  _not_implemented
}

_test_t5_l2_traceparent_dual() {
  _skip_if_no_buf; rc=$?; [ $rc -eq 0 ] && return 0
  if ! command -v cargo >/dev/null 2>&1 || ! command -v node >/dev/null 2>&1; then
    echo "    [SKIP: cargo or node missing]" >&2
    return 0
  fi
  _setup_l2
  trap '_teardown_l2' RETURN
  _not_implemented
}

_test_t5_l2_cargo_fixture_build() {
  if ! command -v cargo >/dev/null 2>&1; then
    echo "    [SKIP: cargo missing]" >&2
    return 0
  fi
  _setup_l2
  trap '_teardown_l2' RETURN
  _not_implemented
}

_test_t5_l2_connectrpc_dual_codec() {
  if ! command -v cargo >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
    echo "    [SKIP: cargo or curl missing]" >&2
    return 0
  fi
  _setup_l2
  trap '_teardown_l2' RETURN
  _not_implemented
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T.5 — t5-connect-codegen harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — additive Connect codegen artefacts"
  for n in $(seq 1 25); do
    run_test "_test_t5_$(printf '%03d' "$n")"
  done

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based"
    run_test _test_t5_l2_buf_gen_layouts
    run_test _test_t5_l2_dart_smoke
    run_test _test_t5_l2_traceparent_dual
    run_test _test_t5_l2_cargo_fixture_build
    run_test _test_t5_l2_connectrpc_dual_codec
  fi

  print_summary
}

main "$@"
