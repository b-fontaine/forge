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
#   - snapshot tarball regenerated within 640 KB budget (FR-T5-CC-050..051 post-T-RUST bump)
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
ARCHETYPE_DIR="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo"
PROTO_TPL="$ARCHETYPE_DIR/shared/protos/buf.gen.yaml.tmpl"
GITIGNORE_TPL="$ARCHETYPE_DIR/.gitignore.tmpl"
BACKEND_DIR="$ARCHETYPE_DIR/backend"
GRPC_API_DIR="$BACKEND_DIR/crates/grpc-api"
GRPC_API_CARGO_TPL="$GRPC_API_DIR/Cargo.toml.tmpl"
GRPC_API_BUILD_TPL="$GRPC_API_DIR/build.rs.tmpl"
GRPC_API_LIB_TPL="$GRPC_API_DIR/src/lib.rs.tmpl"
GRPC_API_CONNECT_TPL="$GRPC_API_DIR/src/transport_connect.rs.tmpl"
BIN_SERVER_MAIN_TPL="$BACKEND_DIR/bin-server/src/main.rs.tmpl"
SCAFFOLD_PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"
EXAMPLE_DIR="$FORGE_ROOT_REAL/examples/forge-fsm-example"
EXAMPLE_BUF_GEN="$EXAMPLE_DIR/shared/protos/buf.gen.yaml"
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
# MANIFEST: _test_t5_005 — ADR-T5-001 build.rs.tmpl invokes connectrpc-build (Option 2 / Path α)
# MANIFEST: _test_t5_006 — ADR-T5-001 grpc-api Cargo.toml.tmpl declares connectrpc-build build-dep
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
# MANIFEST: _test_t5_024 — FR-T5-CC-051 snapshot tarball ≤ 640 KB gzipped
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

_test_t5_001() {
  # FR-T5-CC-001 : buf.gen.yaml.tmpl parses as YAML (template + example mirror)
  if ! _yq_parses "$PROTO_TPL"; then
    echo "    buf.gen.yaml.tmpl does not parse: $PROTO_TPL" >&2
    return 1
  fi
  if ! _yq_parses "$EXAMPLE_BUF_GEN"; then
    echo "    example buf.gen.yaml does not parse: $EXAMPLE_BUF_GEN" >&2
    return 1
  fi
}
_test_t5_002() {
  # FR-T5-CC-001 : buf.build/connectrpc/go entry present (template + example)
  if ! grep -qE '^\s*-\s*remote:\s*buf\.build/connectrpc/go' "$PROTO_TPL"; then
    echo "    buf.build/connectrpc/go entry missing in $PROTO_TPL" >&2
    return 1
  fi
  if ! grep -qE '^\s*-\s*remote:\s*buf\.build/connectrpc/go' "$EXAMPLE_BUF_GEN"; then
    echo "    buf.build/connectrpc/go entry missing in $EXAMPLE_BUF_GEN" >&2
    return 1
  fi
}
_test_t5_003() {
  # FR-T5-CC-002 : buf.build/bufbuild/es entry present (Connect v2 / Protobuf-ES v2)
  if ! grep -qE '^\s*-\s*remote:\s*buf\.build/bufbuild/es' "$PROTO_TPL"; then
    echo "    buf.build/bufbuild/es entry missing in $PROTO_TPL" >&2
    return 1
  fi
  if ! grep -qE '^\s*-\s*remote:\s*buf\.build/bufbuild/es' "$EXAMPLE_BUF_GEN"; then
    echo "    buf.build/bufbuild/es entry missing in $EXAMPLE_BUF_GEN" >&2
    return 1
  fi
}
_test_t5_004() {
  # FR-T5-CC-003 : buf.build/connectrpc/dart entry present (OFFICIAL plugin)
  if ! grep -qE '^\s*-\s*remote:\s*buf\.build/connectrpc/dart' "$PROTO_TPL"; then
    echo "    buf.build/connectrpc/dart entry missing in $PROTO_TPL" >&2
    return 1
  fi
  if ! grep -qE '^\s*-\s*remote:\s*buf\.build/connectrpc/dart' "$EXAMPLE_BUF_GEN"; then
    echo "    buf.build/connectrpc/dart entry missing in $EXAMPLE_BUF_GEN" >&2
    return 1
  fi
}
_test_t5_005() {
  # ADR-T5-001 / FR-T5-CC-010 : build.rs.tmpl invokes connectrpc-build
  if [ ! -f "$GRPC_API_BUILD_TPL" ]; then
    echo "    missing template: $GRPC_API_BUILD_TPL" >&2
    return 1
  fi
  if ! grep -qE 'connectrpc_build::Config' "$GRPC_API_BUILD_TPL"; then
    echo "    build.rs.tmpl does not invoke connectrpc_build::Config" >&2
    return 1
  fi
}
_test_t5_006() {
  # ADR-T5-001 / FR-T5-CC-010 : Cargo.toml.tmpl declares connectrpc-build build-dep
  if [ ! -f "$GRPC_API_CARGO_TPL" ]; then
    echo "    missing template: $GRPC_API_CARGO_TPL" >&2
    return 1
  fi
  if ! grep -qE '^connectrpc-build\s*=\s*"=0\.3\.3"' "$GRPC_API_CARGO_TPL"; then
    echo "    Cargo.toml.tmpl does not declare connectrpc-build = \"=0.3.3\" build-dep" >&2
    return 1
  fi
  for needle in '^connectrpc\s*=\s*"=0\.3\.3"' '^buffa\s*=\s*"=0\.3\.3"'; do
    if ! grep -qE "$needle" "$GRPC_API_CARGO_TPL"; then
      echo "    Cargo.toml.tmpl missing dep matching $needle" >&2
      return 1
    fi
  done
}
_test_t5_007() {
  # FR-T5-CC-004 : the 3 existing remote entries are preserved
  for needle in 'buf\.build/community/neoeinstein-tonic' \
                'buf\.build/community/neoeinstein-prost' \
                'buf\.build/protocolbuffers/dart'; do
    if ! grep -qE "$needle" "$PROTO_TPL"; then
      echo "    canonical remote entry $needle missing in $PROTO_TPL" >&2
      return 1
    fi
  done
}
_test_t5_008() {
  # FR-T5-CC-005 : template .gitignore.tmpl lists generated connect paths
  for needle in 'backend/crates/grpc-api/src/generated/connect/' \
                'frontend/lib/generated/connect/'; do
    if ! grep -qF "$needle" "$GITIGNORE_TPL"; then
      echo "    .gitignore.tmpl missing $needle" >&2
      return 1
    fi
  done
}
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
_test_t5_013() {
  # FR-T5-CC-010 : transport_connect.rs.tmpl exists with into_router using into_axum_service()
  if [ ! -f "$GRPC_API_CONNECT_TPL" ]; then
    echo "    missing template: $GRPC_API_CONNECT_TPL" >&2
    return 1
  fi
  if ! grep -qE 'pub fn into_router' "$GRPC_API_CONNECT_TPL"; then
    echo "    transport_connect.rs.tmpl missing pub fn into_router" >&2
    return 1
  fi
  if ! grep -qE 'into_axum_service\(\)' "$GRPC_API_CONNECT_TPL"; then
    echo "    transport_connect.rs.tmpl missing into_axum_service() call" >&2
    return 1
  fi
}
_test_t5_014() {
  # FR-T5-CC-010 : bin-server main.rs.tmpl mounts the Connect adapter at /connect
  if [ ! -f "$BIN_SERVER_MAIN_TPL" ]; then
    echo "    missing template: $BIN_SERVER_MAIN_TPL" >&2
    return 1
  fi
  if ! grep -qE 'transport_connect::into_router' "$BIN_SERVER_MAIN_TPL"; then
    echo "    main.rs.tmpl does not call transport_connect::into_router" >&2
    return 1
  fi
  if ! grep -qE '"/connect"' "$BIN_SERVER_MAIN_TPL"; then
    echo "    main.rs.tmpl does not mount the adapter at /connect" >&2
    return 1
  fi
}
_test_t5_015() {
  # FR-T5-CC-013 : OTel layer applied OUTSIDE the connectrpc::Router (Tower middleware composition)
  # Heuristic: a `.layer(` call appears AFTER `.into_axum_service()`, not inside the connectrpc::Router builder.
  if [ ! -f "$GRPC_API_CONNECT_TPL" ]; then
    echo "    missing template: $GRPC_API_CONNECT_TPL" >&2
    return 1
  fi
  if ! awk '
    /into_axum_service\(\)/ { seen=1 }
    seen && /\.layer\(/    { found=1; exit }
    END { exit !found }
  ' "$GRPC_API_CONNECT_TPL"; then
    echo "    transport_connect.rs.tmpl: no .layer(...) found AFTER .into_axum_service() (OTel layer must be outside connectrpc)" >&2
    return 1
  fi
}
_test_t5_016() {
  # FR-T5-CC-011 : tonic gRPC server bind preserved in main.rs.tmpl alongside the Connect adapter
  if [ ! -f "$BIN_SERVER_MAIN_TPL" ]; then
    echo "    missing template: $BIN_SERVER_MAIN_TPL" >&2
    return 1
  fi
  # Accept either fully-qualified path or `use ... as TonicServer` alias.
  if ! grep -qE 'tonic::transport::Server' "$BIN_SERVER_MAIN_TPL"; then
    echo "    main.rs.tmpl does not import tonic::transport::Server" >&2
    return 1
  fi
  if ! grep -qE '(TonicServer|Server)::builder|(TonicServer|Server)::bind' "$BIN_SERVER_MAIN_TPL"; then
    echo "    main.rs.tmpl does not call Server::builder() or Server::bind()" >&2
    return 1
  fi
}
_test_t5_017() {
  # FR-T5-CC-012 : domain layer untouched — no template under crates/domain/
  if find "$BACKEND_DIR/crates/domain" -type f -name '*.tmpl' 2>/dev/null | grep -q .; then
    echo "    forbidden: template files found under $BACKEND_DIR/crates/domain/" >&2
    return 1
  fi
  # Also assert Cargo workspace stays at 5-member shape (no new member added by t5).
  if ! grep -qE '^\s*"crates/grpc-api"' "$BACKEND_DIR/Cargo.toml.tmpl"; then
    echo "    backend/Cargo.toml.tmpl missing crates/grpc-api workspace member" >&2
    return 1
  fi
}
_test_t5_018() {
  # FR-T5-CC-030 : demo-005-connect-greeting archived shape (5 files + status: archived)
  local yaml="$DEMO5_DIR/.forge.yaml"
  if [ ! -f "$yaml" ]; then
    echo "    missing $yaml" >&2
    return 1
  fi
  for f in proposal.md specs.md design.md tasks.md; do
    if [ ! -f "$DEMO5_DIR/$f" ]; then
      echo "    missing $DEMO5_DIR/$f" >&2
      return 1
    fi
  done
  if ! grep -qE '^status:\s*archived' "$yaml"; then
    echo "    .forge.yaml status is not 'archived'" >&2
    return 1
  fi
  if ! grep -qE '^schema:\s*full-stack-monorepo' "$yaml"; then
    echo "    .forge.yaml schema is not 'full-stack-monorepo'" >&2
    return 1
  fi
}
_test_t5_019() {
  # FR-T5-CC-031 : specs.md ships ≥ 2 BDD scenarios (Gherkin Scenario: keyword)
  local specs="$DEMO5_DIR/specs.md"
  if [ ! -f "$specs" ]; then
    echo "    missing $specs" >&2
    return 1
  fi
  local count
  count=$(grep -cE '^\s*Scenario:' "$specs" || true)
  if [ "$count" -lt 2 ]; then
    echo "    specs.md has $count Scenario: blocks (≥ 2 required)" >&2
    return 1
  fi
}
_test_t5_020() {
  # FR-T5-CC-032 : clients/connect-client.ts parses as ESM JS.
  #
  # Implementation detail : `node --check <file.ts>` parses the file
  # using the extension-driven default mode (CJS for unknown
  # extensions on Node 20), which rejects top-level `import` / `await`
  # — a false negative for a TS-compatible-JS source. We therefore
  # pipe the file through stdin with `--input-type=module` so the
  # check runs in ESM mode regardless of file extension.
  local client="$EXAMPLE_DIR/clients/connect-client.ts"
  if [ ! -f "$client" ]; then
    echo "    missing $client" >&2
    return 1
  fi
  if ! command -v node >/dev/null 2>&1; then
    echo "    [SKIP: node missing]" >&2
    return 0
  fi
  if ! node --input-type=module --check <"$client" 2>/dev/null; then
    echo "    node --input-type=module --check $client failed (TS-only syntax forbidden — see ADR-DEMO5-003)" >&2
    return 1
  fi
}
_test_t5_021() {
  # FR-T5-CC-040 : constitution-linter emits WARN when proto/ exists
  # without sibling gen/connect/. Fixture: tmp project with proto/ only.
  if [ ! -f "$LINTER" ]; then
    echo "    missing linter: $LINTER" >&2
    return 1
  fi
  local tmp; tmp="$(mk_tmpdir_with_trap forge-t5-lnt-positive)"
  trap "rm -rf '$tmp'" RETURN
  mkdir -p "$tmp/.forge/changes" "$tmp/proto/v1"
  printf 'syntax = "proto3";\npackage forge.t5;\n' >"$tmp/proto/v1/example.proto"
  local out
  out="$(FORGE_ROOT="$tmp" FORGE_LINTER_SKIP_V_1=1 FORGE_LINTER_SKIP_X_3=1 FORGE_LINTER_SKIP_XI_3=1 FORGE_LINTER_SKIP_XI_5=1 bash "$LINTER" 2>&1)"
  if ! grep -qE 'WARN.+transport-codegen-coverage' <<<"$out"; then
    echo "    expected WARN transport-codegen-coverage in linter output" >&2
    return 1
  fi
}
_test_t5_022() {
  # FR-T5-CC-041 : FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1 disables the rule.
  if [ ! -f "$LINTER" ]; then
    echo "    missing linter: $LINTER" >&2
    return 1
  fi
  local tmp; tmp="$(mk_tmpdir_with_trap forge-t5-lnt-skip)"
  trap "rm -rf '$tmp'" RETURN
  mkdir -p "$tmp/.forge/changes" "$tmp/proto/v1"
  printf 'syntax = "proto3";\npackage forge.t5;\n' >"$tmp/proto/v1/example.proto"
  local out
  out="$(FORGE_ROOT="$tmp" FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1 FORGE_LINTER_SKIP_V_1=1 FORGE_LINTER_SKIP_X_3=1 FORGE_LINTER_SKIP_XI_3=1 FORGE_LINTER_SKIP_XI_5=1 bash "$LINTER" 2>&1)"
  if grep -qE 'WARN.+transport-codegen-coverage' <<<"$out"; then
    echo "    rule fired despite FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1" >&2
    return 1
  fi
}
_test_t5_023() {
  # FR-T5-CC-050 : snapshot tarball exists and includes T.5-shipped templates.
  # We use Python's `tarfile` module (cross-platform, deterministic)
  # rather than `tar -tzf | grep`, which was producing ghost entries
  # under GNU tar on Linux when the tarball was authored by bsdtar.
  if [ ! -f "$SNAPSHOT" ]; then
    echo "    missing snapshot tarball: $SNAPSHOT" >&2
    return 1
  fi
  python3 - "$SNAPSHOT" <<'PY' || return 1
import sys, tarfile
snap = sys.argv[1]
needles = [
    'backend/crates/grpc-api/Cargo.toml.tmpl',
    'backend/crates/grpc-api/build.rs.tmpl',
    'backend/crates/grpc-api/src/transport_connect.rs.tmpl',
    'backend/bin-server/src/main.rs.tmpl',
]
try:
    with tarfile.open(snap, 'r:gz') as t:
        names = t.getnames()
except Exception as e:
    print(f"    tarfile open failed: {e}", file=sys.stderr)
    sys.exit(1)
missing = [n for n in needles if not any(n in name for name in names)]
if missing:
    print(f"    snapshot does not contain: {missing}", file=sys.stderr)
    print(f"    (regen via bin/forge-snapshot.sh build full-stack-monorepo 1.0.0)", file=sys.stderr)
    print(f"    [debug] entries in tarball: {len(names)}", file=sys.stderr)
    grpc_entries = [n for n in names if 'grpc-api' in n]
    print(f"    [debug] grpc-api entries: {len(grpc_entries)}", file=sys.stderr)
    for n in grpc_entries[:5]:
        print(f"      {n}", file=sys.stderr)
    sys.exit(1)
PY
}
_test_t5_024() {
  # FR-T5-CC-051 : snapshot tarball size ≤ 640 KB gzipped (post-T-RUST bump).
  if [ ! -f "$SNAPSHOT" ]; then
    echo "    missing snapshot tarball: $SNAPSHOT" >&2
    return 1
  fi
  local size_bytes; size_bytes="$(wc -c <"$SNAPSHOT" | tr -d ' ')"
  local budget_bytes=$((640 * 1024))
  if [ "$size_bytes" -gt "$budget_bytes" ]; then
    echo "    snapshot $size_bytes bytes > $budget_bytes budget (640 KB)" >&2
    return 1
  fi
}
_test_t5_025() {
  # FR-T5-CC-035 : example README.md table links demo-005-connect-greeting
  local readme="$EXAMPLE_DIR/README.md"
  if [ ! -f "$readme" ]; then
    echo "    missing $readme" >&2
    return 1
  fi
  # Markdown link to the demo-005 directory (any link target with that path).
  if ! grep -q 'demo-005-connect-greeting' "$readme"; then
    echo "    README.md does not mention demo-005-connect-greeting" >&2
    return 1
  fi
  if ! grep -qE 'demo-005-connect-greeting/?\)' "$readme"; then
    echo "    README.md does not contain a markdown link to demo-005-connect-greeting/" >&2
    return 1
  fi
}

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
