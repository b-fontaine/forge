#!/usr/bin/env bash
# Forge — T5.1.E Cargo Pin Refresh Test Harness (t5-cargo-pin-refresh)
# <!-- Audit: T5.1.E (t5-cargo-pin-refresh) -->
#
# Validates the T5.1.E deliverables :
#
#   - `buffa` + `buffa-types` pinned at `=0.3.0` (not the previous
#     dead `=0.3.3`) in source template + bundled-assets mirror.
#   - `transport.yaml` bumped v1.1.0 → v1.2.0 (additive) with the
#     two pins corrected + the WAIVER comment block rewritten per
#     ADR-T5CPR-003 to separate WAIVER (connectrpc family, still
#     at =0.3.3) from CORRECTION (buffa family, now =0.3.0).
#   - REVIEW.md ledger has an `Updated 2026-05-16` entry referencing
#     `transport.yaml` 1.1.0 → 1.2.0 + this change ID.
#   - Snapshot tarballs regenerated so their embedded
#     Cargo.toml.tmpl carries the corrected pins.
#   - CHANGELOG `[Unreleased]` entry citing the change.
#
# 10 L1 + 1 L2 = 11 tests.
# Performance budget : L1 ≤ 3 s wall-clock (NFR-T5CPR-002).

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

TEMPLATE="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/Cargo.toml.tmpl"
MIRROR="$FORGE_ROOT_REAL/cli/assets/.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/Cargo.toml.tmpl"
STANDARD="$FORGE_ROOT_REAL/.forge/standards/transport.yaml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
SNAPSHOT="$FORGE_ROOT_REAL/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
SNAPSHOT_MIRROR="$FORGE_ROOT_REAL/cli/assets/.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (10 tests)
# MANIFEST: _test_t5c_l1_001_source_template            — FR-T5CPR-001 / FR-T5CPR-002
# MANIFEST: _test_t5c_l1_002_source_no_dead_pin         — FR-T5CPR-001 / FR-T5CPR-002 (negative)
# MANIFEST: _test_t5c_l1_003_mirror_template            — FR-T5CPR-005
# MANIFEST: _test_t5c_l1_004_standard_version           — FR-T5CPR-020 / MR-T5CPR-003
# MANIFEST: _test_t5c_l1_005_standard_pins              — FR-T5CPR-021 / FR-T5CPR-022
# MANIFEST: _test_t5c_l1_006_standard_waiver_rewritten  — FR-T5CPR-023 / ADR-T5CPR-003
# MANIFEST: _test_t5c_l1_007_review_ledger              — FR-T5CPR-024
# MANIFEST: _test_t5c_l1_008_snapshot_content           — FR-T5CPR-052
# MANIFEST: _test_t5c_l1_009_snapshot_mirror_identity   — FR-T5CPR-053
# MANIFEST: _test_t5c_l1_010_changelog_entry            — FR-T5CPR-100
#
# L2 (1 test, opt-in via FORGE_T5C_LIVE=1 ; skip-pass otherwise)
# MANIFEST: _test_t5c_l2_resolve_against_crates_io      — FR-T5CPR-074

# ─── L1 tests ────────────────────────────────────────────────────

_not_implemented() {
  echo "    not implemented yet (RED witness)" >&2
  return 1
}

_test_t5c_l1_001_source_template() {
  if [ ! -f "$TEMPLATE" ]; then
    echo "    source template missing: $TEMPLATE" >&2; return 1
  fi
  if ! grep -Fq 'buffa        = "=0.3.0"' "$TEMPLATE"; then
    echo "    source template missing buffa = \"=0.3.0\"" >&2; return 1
  fi
  if ! grep -Fq 'buffa-types  = "=0.3.0"' "$TEMPLATE"; then
    echo "    source template missing buffa-types = \"=0.3.0\"" >&2; return 1
  fi
}

_test_t5c_l1_002_source_no_dead_pin() {
  if [ ! -f "$TEMPLATE" ]; then
    echo "    source template missing: $TEMPLATE" >&2; return 1
  fi
  # The dead pin must not appear for buffa or buffa-types.
  # connectrpc / connectrpc-build keep =0.3.3 (valid).
  if grep -Eq '^buffa(-types)?[[:space:]]+=[[:space:]]*"=0\.3\.3"' "$TEMPLATE"; then
    echo "    source template still contains dead pin buffa(-types) = \"=0.3.3\"" >&2
    return 1
  fi
}

_test_t5c_l1_003_mirror_template() {
  if [ ! -f "$MIRROR" ]; then
    echo "    bundled-assets mirror missing: $MIRROR" >&2; return 1
  fi
  if ! diff -q "$TEMPLATE" "$MIRROR" > /dev/null 2>&1; then
    echo "    source template and bundled mirror are NOT byte-identical" >&2
    diff "$TEMPLATE" "$MIRROR" | head -10 | sed 's/^/      /' >&2
    return 1
  fi
}

_test_t5c_l1_004_standard_version() {
  # v1.2.0 corrected the buffa pin (t5-cargo-pin-refresh, 2026-05-16) ;
  # v1.3.0 added the additive codegen.versions_2_0_0 block for the B.8.6
  # 2.0.0 line (b8-6-connect-rpc, 2026-06-02) — the 1.0.0 codegen.versions
  # map this harness pins below is byte-unchanged (sibling-harness coupling
  # bump per ADR-B8-OBI-006 hybrid precedent).
  if [ ! -f "$STANDARD" ]; then
    echo "    transport.yaml missing: $STANDARD" >&2; return 1
  fi
  if ! grep -Eq '^version:[[:space:]]*"1\.3\.0"' "$STANDARD"; then
    echo "    transport.yaml::version is not \"1.3.0\"" >&2
    grep -E '^version:' "$STANDARD" | head -1 | sed 's/^/      /' >&2
    return 1
  fi
}

_test_t5c_l1_005_standard_pins() {
  if [ ! -f "$STANDARD" ]; then
    echo "    transport.yaml missing: $STANDARD" >&2; return 1
  fi
  if ! grep -Fq 'buffa: "=0.3.0"' "$STANDARD"; then
    echo "    transport.yaml does not declare buffa: \"=0.3.0\"" >&2; return 1
  fi
  if ! grep -Fq 'buffa-types: "=0.3.0"' "$STANDARD"; then
    echo "    transport.yaml does not declare buffa-types: \"=0.3.0\"" >&2; return 1
  fi
  # Negative — the dead pin must not appear for buffa-family.
  if grep -Eq '^[[:space:]]+buffa(-types)?:[[:space:]]+"=0\.3\.3"' "$STANDARD"; then
    echo "    transport.yaml still contains dead pin buffa(-types): \"=0.3.3\"" >&2
    return 1
  fi
}

_test_t5c_l1_006_standard_waiver_rewritten() {
  if [ ! -f "$STANDARD" ]; then
    echo "    transport.yaml missing: $STANDARD" >&2; return 1
  fi
  # The amendment note dated 2026-05-16 referencing the change ID MUST be present.
  if ! grep -Fq 'Amend 2026-05-16 (t5-cargo-pin-refresh' "$STANDARD"; then
    echo "    transport.yaml lacks the Amend 2026-05-16 (t5-cargo-pin-refresh ...) annotation" >&2
    return 1
  fi
  # CORRECTION marker present (per ADR-T5CPR-003 wording).
  if ! grep -Fq "CORRECTION" "$STANDARD"; then
    echo "    transport.yaml lacks the CORRECTION marker separating it from WAIVER" >&2
    return 1
  fi
}

_test_t5c_l1_007_review_ledger() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing: $REVIEW_MD" >&2; return 1
  fi
  if ! grep -Fq "t5-cargo-pin-refresh" "$REVIEW_MD"; then
    echo "    REVIEW.md does not reference t5-cargo-pin-refresh" >&2; return 1
  fi
  if ! grep -Fq "2026-05-16" "$REVIEW_MD"; then
    echo "    REVIEW.md has no 2026-05-16 entry" >&2; return 1
  fi
}

_test_t5c_l1_008_snapshot_content() {
  if [ ! -f "$SNAPSHOT" ]; then
    echo "    snapshot missing: $SNAPSHOT" >&2; return 1
  fi
  # Extract the embedded Cargo.toml.tmpl + grep for the corrected pin.
  # Resolve the in-tar pathname via `tar -tzf` first (portable across
  # BSD tar on macOS and GNU tar on Linux CI) — the previous direct
  # `tar -xzOf "*pattern"` only matched on BSD tar (GNU tar requires
  # `--wildcards`, BSD tar globs by default ; the asymmetry made this
  # test pass locally on macOS but RED on Linux CI runners).
  local pathname
  pathname=$(tar -tzf "$SNAPSHOT" 2>/dev/null | grep '/grpc-api/Cargo\.toml\.tmpl$' | head -1 || true)
  if [ -z "$pathname" ]; then
    echo "    snapshot does not embed grpc-api/Cargo.toml.tmpl" >&2; return 1
  fi
  local extracted
  extracted=$(tar -xzOf "$SNAPSHOT" "$pathname" 2>/dev/null || true)
  if [ -z "$extracted" ]; then
    echo "    snapshot extraction of $pathname returned empty" >&2; return 1
  fi
  if ! printf '%s' "$extracted" | grep -Fq 'buffa        = "=0.3.0"'; then
    echo "    snapshot embedded Cargo.toml.tmpl missing buffa = \"=0.3.0\"" >&2
    return 1
  fi
  if printf '%s' "$extracted" | grep -Eq '^buffa(-types)?[[:space:]]+=[[:space:]]*"=0\.3\.3"'; then
    echo "    snapshot embedded Cargo.toml.tmpl still contains dead pin buffa(-types) = \"=0.3.3\"" >&2
    return 1
  fi
}

_test_t5c_l1_009_snapshot_mirror_identity() {
  if [ ! -f "$SNAPSHOT" ]; then
    echo "    source snapshot missing: $SNAPSHOT" >&2; return 1
  fi
  if [ ! -f "$SNAPSHOT_MIRROR" ]; then
    echo "    bundled mirror snapshot missing: $SNAPSHOT_MIRROR" >&2; return 1
  fi
  if ! diff -q "$SNAPSHOT" "$SNAPSHOT_MIRROR" > /dev/null 2>&1; then
    echo "    source snapshot and bundled mirror are NOT byte-identical" >&2
    return 1
  fi
}

_test_t5c_l1_010_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing: $CHANGELOG_MD" >&2; return 1
  fi
  # The change shipped in v0.3.3, so its entry has graduated from [Unreleased]
  # to a versioned section. Assert the permanent record exists anywhere in the
  # changelog (mirrors the REVIEW.md ledger check above).
  if ! grep -Fq "t5-cargo-pin-refresh" "$CHANGELOG_MD"; then
    echo "    CHANGELOG.md does not mention t5-cargo-pin-refresh" >&2
    return 1
  fi
}

# ─── L2 tests (opt-in) ───────────────────────────────────────────

# FR-T5CPR-074 — live crates.io resolution check (opt-in)
_test_t5c_l2_resolve_against_crates_io() {
  if [ "${FORGE_T5C_LIVE:-0}" != "1" ]; then
    echo "    skipped (FORGE_T5C_LIVE unset — opt-in)" >&2
    return 0
  fi
  # Three assertions :
  #   (a) buffa 0.3.0 exists, non-yanked
  #   (b) buffa-types 0.3.0 exists, non-yanked
  #   (c) connectrpc 0.3.3 declares `buffa = "^0.3"`
  local ua="forge-cli-trust/0.3.x (t5-cargo-pin-refresh)"
  local r
  r=$(curl -sS -H "User-Agent: $ua" "https://crates.io/api/v1/crates/buffa" 2>/dev/null \
    | python3 -c "import json,sys; d=json.load(sys.stdin); v=[x for x in d.get('versions',[]) if x['num']=='0.3.0']; print('OK' if v and not v[0]['yanked'] else 'FAIL')") || true
  if [ "$r" != "OK" ]; then
    echo "    buffa 0.3.0 not findable / yanked / network unreachable" >&2
    return 1
  fi
  r=$(curl -sS -H "User-Agent: $ua" "https://crates.io/api/v1/crates/buffa-types" 2>/dev/null \
    | python3 -c "import json,sys; d=json.load(sys.stdin); v=[x for x in d.get('versions',[]) if x['num']=='0.3.0']; print('OK' if v and not v[0]['yanked'] else 'FAIL')") || true
  if [ "$r" != "OK" ]; then
    echo "    buffa-types 0.3.0 not findable / yanked" >&2
    return 1
  fi
  r=$(curl -sS -H "User-Agent: $ua" "https://crates.io/api/v1/crates/connectrpc/0.3.3/dependencies" 2>/dev/null \
    | python3 -c "import json,sys; d=json.load(sys.stdin); deps=[x for x in d.get('dependencies',[]) if x['crate_id']=='buffa' and x['kind']=='normal']; print('OK' if deps and '0.3' in deps[0]['req'] else 'FAIL')") || true
  if [ "$r" != "OK" ]; then
    echo "    connectrpc 0.3.3 does not declare buffa = ^0.3" >&2
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T5.1.E — t5-cargo-pin-refresh — level $LEVEL ──"

  # L1 always runs.
  run_test _test_t5c_l1_001_source_template
  run_test _test_t5c_l1_002_source_no_dead_pin
  run_test _test_t5c_l1_003_mirror_template
  run_test _test_t5c_l1_004_standard_version
  run_test _test_t5c_l1_005_standard_pins
  run_test _test_t5c_l1_006_standard_waiver_rewritten
  run_test _test_t5c_l1_007_review_ledger
  run_test _test_t5c_l1_008_snapshot_content
  run_test _test_t5c_l1_009_snapshot_mirror_identity
  run_test _test_t5c_l1_010_changelog_entry

  # L2 runs when --level includes 2 or "all".
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — live crates.io check (opt-in FORGE_T5C_LIVE=1)"
    run_test _test_t5c_l2_resolve_against_crates_io
  fi

  print_summary
}

main "$@"
