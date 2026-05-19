#!/usr/bin/env bash
# Forge — T5.1.E bin-server deps harness (t5-bin-server-deps)
# <!-- Audit: T5.1.E (t5-bin-server-deps) -->
#
# Validates the T5.1.E follow-on deliverables :
#
#   - `backend/Cargo.toml.tmpl::[workspace.dependencies]` declares
#     `axum = "0.8"`, `tower-http = { version = "0.6", features = ["trace"] }`,
#     `http = "1"` (FR-T5BSD-001..003).
#   - `backend/bin-server/Cargo.toml.tmpl` exists with the canonical
#     [package] + [dependencies] block per FR-T5BSD-020..025.
#   - Bundled-assets mirrors byte-identical.
#   - Snapshot tarball regenerated.
#   - CHANGELOG entry.
#
# 9 L1 + 1 L2 = 10 tests.
# Performance budget : L1 ≤ 3 s wall-clock (NFR-T5BSD-002).

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

WORKSPACE_CARGO="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/backend/Cargo.toml.tmpl"
WORKSPACE_CARGO_MIRROR="$FORGE_ROOT_REAL/cli/assets/.forge/templates/archetypes/full-stack-monorepo/backend/Cargo.toml.tmpl"
BIN_SERVER_CARGO="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/backend/bin-server/Cargo.toml.tmpl"
BIN_SERVER_CARGO_MIRROR="$FORGE_ROOT_REAL/cli/assets/.forge/templates/archetypes/full-stack-monorepo/backend/bin-server/Cargo.toml.tmpl"
SNAPSHOT="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (9 tests)
# MANIFEST: _test_t5bsd_l1_001_workspace_axum            — FR-T5BSD-001
# MANIFEST: _test_t5bsd_l1_002_workspace_tower_http      — FR-T5BSD-002
# MANIFEST: _test_t5bsd_l1_003_workspace_http            — FR-T5BSD-003
# MANIFEST: _test_t5bsd_l1_004_bin_server_manifest_exists — FR-T5BSD-020 / FR-T5BSD-024
# MANIFEST: _test_t5bsd_l1_005_bin_server_grpc_api_path_dep — FR-T5BSD-022
# MANIFEST: _test_t5bsd_l1_006_bin_server_workspace_deps  — FR-T5BSD-023
# MANIFEST: _test_t5bsd_l1_007_mirror_byte_identity       — FR-T5BSD-050
# MANIFEST: _test_t5bsd_l1_008_snapshot_content           — FR-T5BSD-051
# MANIFEST: _test_t5bsd_l1_009_changelog_entry            — FR-T5BSD-100
#
# L2 (1 test, opt-in via FORGE_T5BSD_LIVE=1)
# MANIFEST: _test_t5bsd_l2_cargo_check_fresh_scaffold     — FR-T5BSD-072

# ─── L1 tests ────────────────────────────────────────────────────

_not_implemented() {
  echo "    not implemented yet (RED witness)" >&2
  return 1
}

_test_t5bsd_l1_001_workspace_axum() {
  if [ ! -f "$WORKSPACE_CARGO" ]; then
    echo "    workspace Cargo.toml.tmpl missing" >&2; return 1
  fi
  if ! grep -Fq 'axum = "0.8"' "$WORKSPACE_CARGO"; then
    echo "    workspace.dependencies missing axum = \"0.8\"" >&2; return 1
  fi
}

_test_t5bsd_l1_002_workspace_tower_http() {
  if [ ! -f "$WORKSPACE_CARGO" ]; then
    echo "    workspace Cargo.toml.tmpl missing" >&2; return 1
  fi
  if ! grep -Fq 'tower-http = { version = "0.6", features = ["trace"] }' "$WORKSPACE_CARGO"; then
    echo "    workspace.dependencies missing tower-http 0.6 with trace feature" >&2
    return 1
  fi
}

_test_t5bsd_l1_003_workspace_http() {
  if [ ! -f "$WORKSPACE_CARGO" ]; then
    echo "    workspace Cargo.toml.tmpl missing" >&2; return 1
  fi
  if ! grep -Fq 'http = "1"' "$WORKSPACE_CARGO"; then
    echo "    workspace.dependencies missing http = \"1\"" >&2; return 1
  fi
}

_test_t5bsd_l1_004_bin_server_manifest_exists() {
  if [ ! -f "$BIN_SERVER_CARGO" ]; then
    echo "    bin-server/Cargo.toml.tmpl missing: $BIN_SERVER_CARGO" >&2; return 1
  fi
  if ! head -10 "$BIN_SERVER_CARGO" | grep -Fq "Audit: T5.1.E (t5-bin-server-deps)"; then
    echo "    bin-server/Cargo.toml.tmpl missing audit comment in first 10 lines" >&2
    return 1
  fi
  if ! grep -Fq 'name = "bin-server"' "$BIN_SERVER_CARGO"; then
    echo "    bin-server/Cargo.toml.tmpl missing package name = \"bin-server\"" >&2
    return 1
  fi
}

_test_t5bsd_l1_005_bin_server_grpc_api_path_dep() {
  if [ ! -f "$BIN_SERVER_CARGO" ]; then
    echo "    bin-server/Cargo.toml.tmpl missing" >&2; return 1
  fi
  if ! grep -Fq 'grpc-api = { path = "../crates/grpc-api" }' "$BIN_SERVER_CARGO"; then
    echo "    bin-server/Cargo.toml.tmpl missing grpc-api path dep" >&2
    return 1
  fi
}

_test_t5bsd_l1_006_bin_server_workspace_deps() {
  if [ ! -f "$BIN_SERVER_CARGO" ]; then
    echo "    bin-server/Cargo.toml.tmpl missing" >&2; return 1
  fi
  local dep
  for dep in tokio anyhow tracing tracing-subscriber tonic axum tower-http http; do
    if ! grep -Eq "^${dep}[[:space:]]*=[[:space:]]*\{[[:space:]]+workspace[[:space:]]*=[[:space:]]*true[[:space:]]+\}" "$BIN_SERVER_CARGO"; then
      echo "    bin-server/Cargo.toml.tmpl missing workspace-inherited dep: $dep" >&2
      return 1
    fi
  done
}

_test_t5bsd_l1_007_mirror_byte_identity() {
  if [ ! -f "$WORKSPACE_CARGO" ] || [ ! -f "$WORKSPACE_CARGO_MIRROR" ]; then
    echo "    workspace cargo source or mirror missing" >&2; return 1
  fi
  if ! diff -q "$WORKSPACE_CARGO" "$WORKSPACE_CARGO_MIRROR" > /dev/null 2>&1; then
    echo "    workspace Cargo.toml.tmpl source + mirror not byte-identical" >&2
    return 1
  fi
  if [ ! -f "$BIN_SERVER_CARGO" ] || [ ! -f "$BIN_SERVER_CARGO_MIRROR" ]; then
    echo "    bin-server cargo source or mirror missing" >&2; return 1
  fi
  if ! diff -q "$BIN_SERVER_CARGO" "$BIN_SERVER_CARGO_MIRROR" > /dev/null 2>&1; then
    echo "    bin-server Cargo.toml.tmpl source + mirror not byte-identical" >&2
    return 1
  fi
}

_test_t5bsd_l1_008_snapshot_content() {
  if [ ! -f "$SNAPSHOT" ]; then
    echo "    snapshot missing: $SNAPSHOT" >&2; return 1
  fi
  # Resolve the in-tar pathname via `tar -tzf` first (portable across
  # BSD tar on macOS and GNU tar on Linux CI — BSD tar globs by default,
  # GNU tar requires `--wildcards`). Same pattern as
  # t5-cargo.test.sh::_test_t5c_l1_008_snapshot_content.
  local pathname
  pathname=$(tar -tzf "$SNAPSHOT" 2>/dev/null | grep '/bin-server/Cargo\.toml\.tmpl$' | head -1 || true)
  if [ -z "$pathname" ]; then
    echo "    snapshot does not embed bin-server/Cargo.toml.tmpl" >&2
    return 1
  fi
  local extracted
  extracted=$(tar -xzOf "$SNAPSHOT" "$pathname" 2>/dev/null || true)
  if [ -z "$extracted" ]; then
    echo "    snapshot extraction of $pathname returned empty" >&2
    return 1
  fi
  if ! printf '%s' "$extracted" | grep -Fq 'name = "bin-server"'; then
    echo "    snapshot embedded bin-server manifest missing name = \"bin-server\"" >&2
    return 1
  fi
}

_test_t5bsd_l1_009_changelog_entry() {
  # FR-T5BSD-100 intent : the change is documented in CHANGELOG.md. The
  # change was active under `## [Unreleased]` during its lifecycle and
  # migrated to the v0.3.3 released section on 2026-05-16 (commit
  # 60fa53b). The assertion is satisfied as long as the change name
  # appears anywhere in the changelog post-release, since the seal moves
  # entries from Unreleased to a versioned heading.
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing" >&2; return 1
  fi
  if ! grep -Fq "t5-bin-server-deps" "$CHANGELOG_MD"; then
    echo "    CHANGELOG.md does not mention t5-bin-server-deps (expected under [Unreleased] pre-release, or a sealed [X.Y.Z] section post-release)" >&2
    return 1
  fi
}

# ─── L2 tests (opt-in) ───────────────────────────────────────────

_test_t5bsd_l2_cargo_check_fresh_scaffold() {
  if [ "${FORGE_T5BSD_LIVE:-0}" != "1" ]; then
    echo "    skipped (FORGE_T5BSD_LIVE unset — opt-in)" >&2
    return 0
  fi
  if ! command -v cargo > /dev/null 2>&1; then
    echo "    skipped (cargo absent on PATH)" >&2
    return 0
  fi
  local tmp
  tmp=$(mktemp -d "/tmp/forge-t5bsd-XXXXXX")
  rm -rf "$tmp"  # exercise mkdir -p
  if ! node "$FORGE_ROOT_REAL/cli/dist/index.js" init smoke_t5bsd \
      --archetype full-stack-monorepo --org dev.forge.test --target "$tmp" > /dev/null 2>&1; then
    echo "    forge init failed" >&2
    rm -rf "$tmp"; return 1
  fi
  if ! (cd "$tmp/backend" && cargo check --workspace > /dev/null 2>&1); then
    echo "    cargo check --workspace failed on fresh scaffold" >&2
    rm -rf "$tmp"; return 1
  fi
  rm -rf "$tmp"
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T5.1.E — t5-bin-server-deps — level $LEVEL ──"

  # L1 always runs.
  run_test _test_t5bsd_l1_001_workspace_axum
  run_test _test_t5bsd_l1_002_workspace_tower_http
  run_test _test_t5bsd_l1_003_workspace_http
  run_test _test_t5bsd_l1_004_bin_server_manifest_exists
  run_test _test_t5bsd_l1_005_bin_server_grpc_api_path_dep
  run_test _test_t5bsd_l1_006_bin_server_workspace_deps
  run_test _test_t5bsd_l1_007_mirror_byte_identity
  run_test _test_t5bsd_l1_008_snapshot_content
  run_test _test_t5bsd_l1_009_changelog_entry

  # L2 runs when --level includes 2 or "all".
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — live cargo check on fresh scaffold (opt-in FORGE_T5BSD_LIVE=1)"
    run_test _test_t5bsd_l2_cargo_check_fresh_scaffold
  fi

  print_summary
}

main "$@"
