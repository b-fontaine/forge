#!/usr/bin/env bash
# Forge — B.8.6 Connect-RPC 2.0.0 transport-brick harness
# <!-- Audit: B.8.6 (b8-6-connect-rpc) — 2.0.0 transport template brick gate -->
#
# Validates the b8-6-connect-rpc deliverables (design.md § Testing Strategy):
#
#   T-001  2.0.0/shared/protos/ subtree: buf.gen.yaml.tmpl + README.md.tmpl       (FR-B86-051, ADR-B86-002)
#   T-002  2.0.0/backend/crates/grpc-api/: src/transport_connect.rs.tmpl + Cargo  (FR-B86-051, ADR-B86-002)
#   T-003  2.0.0 buf.gen.yaml.tmpl carries all 7 plugin remote refs               (FR-B86-052, FR-B86-003/006)
#   T-004  2.0.0 Cargo.toml.tmpl carries the =0.6.1 connect pin + =0.6.0 buffa    (FR-B86-052, ADR-B86-002)
#   T-005  frozen 1.0.0 buf.gen.yaml.tmpl still has connectrpc/dart:v1.0.0        (FR-B86-053, NFR-B86-002)
#   T-006  frozen 1.0.0 transport_connect.rs.tmpl + Cargo.toml.tmpl byte-sentinel (FR-B86-053, NFR-B86-002)
#   T-007  transport.yaml version: "1.3.0" AND no stale "v1.1.0" header           (FR-B86-054, ADR-B86-005)
#   T-008  transport.yaml versions_2_0_0 block + 4 Rust crate keys                (FR-B86-055, ADR-B86-005)
#   T-009  REVIEW.md row referencing transport.yaml + 1.3.0 (FR-J7-023 anchor)    (FR-B86-056, FR-B86-023)
#   T-010  2.0.0.yaml connect-rpc delivered annotation + delta additive-first     (FR-B86-057, FR-B86-030/032)
#   T-011  coupling guard: b8-3 (17/17) + b8-3b (12/12) stay GREEN (exit-code)    (NFR-B86-003, FR-B86-058)
#   T-012  CHANGELOG.md has a B.8.6 / connect-rpc entry                           (FR-B86-059, NFR-B86-001)
#
# 12 L1 tests. Budget L1 ≤ 2 s, zero net/Docker. The live crate verify-then-pin
# is a /forge:implement step, NOT an L1 assertion. T-011 is exit-code only (the
# b8-4/b8-5 T-coupling strategy) — keeps the coupling guard within the budget.
# Mirrors b8-5.test.sh / b8-4.test.sh structure (--level flag + _helpers.sh).

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
FORGE_ROOT="$(cd "$SCRIPTS_DIR/../.." && pwd)"

TEMPLATE_ROOT="$FORGE_ROOT/.forge/templates/archetypes/full-stack-monorepo"
# 2.0.0 transport subtree (the B.8.6 deliverable).
PROTOS_DIR="$TEMPLATE_ROOT/2.0.0/shared/protos"
BUF_GEN_20="$PROTOS_DIR/buf.gen.yaml.tmpl"
PROTOS_README="$PROTOS_DIR/README.md.tmpl"
BACK_DIR="$TEMPLATE_ROOT/2.0.0/backend/crates/grpc-api"
ADAPTER_20="$BACK_DIR/src/transport_connect.rs.tmpl"
CARGO_20="$BACK_DIR/Cargo.toml.tmpl"
# Frozen 1.0.0 flat templates (byte-unchanged sentinels).
BUF_GEN_10="$TEMPLATE_ROOT/shared/protos/buf.gen.yaml.tmpl"
ADAPTER_10="$TEMPLATE_ROOT/backend/crates/grpc-api/src/transport_connect.rs.tmpl"
CARGO_10="$TEMPLATE_ROOT/backend/crates/grpc-api/Cargo.toml.tmpl"

STANDARDS_DIR="$FORGE_ROOT/.forge/standards"
TRANSPORT_STD="$STANDARDS_DIR/transport.yaml"
REVIEW_MD="$STANDARDS_DIR/REVIEW.md"

SCHEMA_20="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/2.0.0.yaml"
CHANGELOG="$FORGE_ROOT/CHANGELOG.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b86_l1_001_protos_subtree() {
  local ok=1
  local expected=(buf.gen.yaml.tmpl README.md.tmpl)
  for f in "${expected[@]}"; do
    [ -f "$PROTOS_DIR/$f" ] \
      || { echo "    FAIL T-001: missing $f under $PROTOS_DIR (FR-B86-051, ADR-B86-002)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b86_l1_002_backend_subtree() {
  local ok=1
  [ -f "$ADAPTER_20" ] \
    || { echo "    FAIL T-002: missing src/transport_connect.rs.tmpl under $BACK_DIR (FR-B86-051, ADR-B86-002)" >&2; ok=0; }
  [ -f "$CARGO_20" ] \
    || { echo "    FAIL T-002: missing Cargo.toml.tmpl under $BACK_DIR (FR-B86-051, ADR-B86-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b86_l1_003_seven_plugins() {
  if [ ! -f "$BUF_GEN_20" ]; then
    echo "    FAIL T-003: 2.0.0 buf.gen.yaml.tmpl missing: $BUF_GEN_20 (FR-B86-052)" >&2; return 1
  fi
  local ok=1
  # The seven plugin remote references (Article VII.2: neoeinstein-tonic RETAINED).
  local sentinels=(
    neoeinstein-tonic
    neoeinstein-prost
    protocolbuffers/dart
    connectrpc/go
    bufbuild/es
    connectrpc/dart
  )
  for s in "${sentinels[@]}"; do
    grep -qF "$s" "$BUF_GEN_20" \
      || { echo "    FAIL T-003: 2.0.0 buf.gen.yaml.tmpl missing plugin remote ref '$s' (FR-B86-052, FR-B86-003/006)" >&2; ok=0; }
  done
  # connect-go bumped to v1.20.0 in the 2.0.0 variant (Phase 0 P-13 BSR confirmed).
  grep -qF 'connectrpc/go:v1.20.0' "$BUF_GEN_20" \
    || { echo "    FAIL T-003: 2.0.0 buf.gen.yaml.tmpl connect-go not at v1.20.0 (Phase 0 P-13, ADR-B86-003)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b86_l1_004_cargo_pins() {
  if [ ! -f "$CARGO_20" ]; then
    echo "    FAIL T-004: 2.0.0 Cargo.toml.tmpl missing: $CARGO_20 (FR-B86-052)" >&2; return 1
  fi
  local ok=1
  # The modernized 2.0.0 connect pin set (ADR-B86-001).
  grep -qF '=0.6.1' "$CARGO_20" \
    || { echo "    FAIL T-004: 2.0.0 Cargo.toml.tmpl has no =0.6.1 connect pin (ADR-B86-001/002)" >&2; ok=0; }
  grep -qF '=0.6.0' "$CARGO_20" \
    || { echo "    FAIL T-004: 2.0.0 Cargo.toml.tmpl has no =0.6.0 buffa pin (ADR-B86-001/002)" >&2; ok=0; }
  # The axum feature is still required (non-default) — ADR-B86-001.
  grep -qF 'features = ["axum"]' "$CARGO_20" \
    || { echo "    FAIL T-004: 2.0.0 Cargo.toml.tmpl connectrpc missing features = [\"axum\"] (ADR-B86-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b86_l1_005_frozen_buf_gen_sentinel() {
  if [ ! -f "$BUF_GEN_10" ]; then
    echo "    FAIL T-005: frozen 1.0.0 buf.gen.yaml.tmpl missing: $BUF_GEN_10 (NFR-B86-002)" >&2; return 1
  fi
  # The frozen 1.0.0 manifest still carries the official connect-dart v1.0.0 pin
  # AND connect-go is still v1.19.2 (the 2.0.0 bump to v1.20.0 must NOT bleed in).
  local ok=1
  grep -qF 'connectrpc/dart:v1.0.0' "$BUF_GEN_10" \
    || { echo "    FAIL T-005: frozen 1.0.0 connectrpc/dart:v1.0.0 sentinel missing/modified (NFR-B86-002)" >&2; ok=0; }
  grep -qF 'connectrpc/go:v1.19.2' "$BUF_GEN_10" \
    || { echo "    FAIL T-005: frozen 1.0.0 connectrpc/go:v1.19.2 sentinel missing/modified (NFR-B86-002, FR-B86-007)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b86_l1_006_frozen_adapter_sentinel() {
  local ok=1
  if [ ! -f "$ADAPTER_10" ]; then
    echo "    FAIL T-006: frozen 1.0.0 transport_connect.rs.tmpl missing: $ADAPTER_10 (NFR-B86-002)" >&2; ok=0
  elif ! grep -qF 'into_axum_router' "$ADAPTER_10"; then
    echo "    FAIL T-006: frozen 1.0.0 adapter into_axum_router() sentinel missing/modified — 0.3.x surface must stay frozen (NFR-B86-002)" >&2; ok=0
  fi
  if [ ! -f "$CARGO_10" ]; then
    echo "    FAIL T-006: frozen 1.0.0 Cargo.toml.tmpl missing: $CARGO_10 (NFR-B86-002)" >&2; ok=0
  elif ! grep -qF '=0.3.3' "$CARGO_10"; then
    echo "    FAIL T-006: frozen 1.0.0 Cargo.toml.tmpl =0.3.3 pin sentinel missing/modified (NFR-B86-002, FR-B86-011)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b86_l1_007_transport_version_and_header() {
  if [ ! -f "$TRANSPORT_STD" ]; then
    echo "    FAIL T-007: transport.yaml missing: $TRANSPORT_STD (FR-B86-054)" >&2; return 1
  fi
  local ok=1
  # version: field is "1.3.0" (additive bump, ADR-B86-005).
  grep -qE '^version:[[:space:]]*"1\.3\.0"' "$TRANSPORT_STD" \
    || { echo "    FAIL T-007: transport.yaml version: field is not \"1.3.0\" (FR-B86-020, ADR-B86-005)" >&2; ok=0; }
  # The stale "v1.1.0" header comment must be gone (FR-B86-022 header fix).
  if grep -qF 'v1.1.0' "$TRANSPORT_STD"; then
    echo "    FAIL T-007: transport.yaml still contains a stale 'v1.1.0' reference — header not fixed (FR-B86-022)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b86_l1_008_versions_2_0_0_block() {
  if [ ! -f "$TRANSPORT_STD" ]; then
    echo "    FAIL T-008: transport.yaml missing: $TRANSPORT_STD (FR-B86-055)" >&2; return 1
  fi
  local ok=1
  grep -qF 'versions_2_0_0' "$TRANSPORT_STD" \
    || { echo "    FAIL T-008: transport.yaml has no versions_2_0_0 block (FR-B86-055, ADR-B86-005)" >&2; ok=0; }
  # The four Rust crate keys must be present in the block.
  for key in connectrpc connectrpc-build buffa buffa-types; do
    grep -qE "^[[:space:]]+${key}:" "$TRANSPORT_STD" \
      || { echo "    FAIL T-008: transport.yaml versions_2_0_0 missing '$key:' key (FR-B86-055)" >&2; ok=0; }
  done
  # The 2.0.0-line Rust pins (0.6.1/0.6.0) must be present (the modernized set).
  grep -qF '=0.6.1' "$TRANSPORT_STD" \
    || { echo "    FAIL T-008: transport.yaml versions_2_0_0 has no =0.6.1 pin (ADR-B86-001/005)" >&2; ok=0; }
  grep -qF '=0.6.0' "$TRANSPORT_STD" \
    || { echo "    FAIL T-008: transport.yaml versions_2_0_0 has no =0.6.0 pin (ADR-B86-001/005)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b86_l1_009_review_md_row() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    FAIL T-009: REVIEW.md missing: $REVIEW_MD (FR-B86-056)" >&2; return 1
  fi
  # FR-J7-023 anchor: the REVIEW.md cell is the BARE basename + version 1.3.0.
  grep -qE '\|[[:space:]]*transport\.yaml[[:space:]]*\|[[:space:]]*1\.3\.0[[:space:]]*\|' "$REVIEW_MD" \
    || { echo "    FAIL T-009: REVIEW.md has no '| transport.yaml | 1.3.0 |' ledger row (basename anchor, FR-J7-023)" >&2; return 1; }
}

_test_b86_l1_010_schema_annotation_and_delta() {
  local out
  out=$(python3 - "$SCHEMA_20" "$STANDARDS_DIR" <<'PY'
import sys, os, yaml
try:
    with open(sys.argv[1], encoding='utf-8') as f:
        d = yaml.safe_load(f)
except Exception as e:
    print(f"ERR:{e}"); sys.exit(0)
std_dir = sys.argv[2]
comps = d.get('components', []) if isinstance(d, dict) else []
c = next((c for c in comps if isinstance(c, dict) and c.get('name') == 'connect-rpc'), None)
if c is None:
    print("NO_CONNECT"); sys.exit(0)
std = c.get('standard', 'MISSING')
resolves = os.path.isfile(os.path.join(std_dir, std)) if isinstance(std, str) and std != 'MISSING' else False
forbidden = {'version', 'pin', 'image'}
pin = ','.join(sorted(set(c.keys()) & forbidden)) or 'NONE'
deltas = d.get('migration_deltas', []) if isinstance(d, dict) else []
delta = next((x for x in deltas if isinstance(x, dict) and x.get('to') == 'connect-rpc'), None)
strat = (delta or {}).get('strategy', 'MISSING') if delta else 'NO_DELTA'
print(f"standard={std}")
print(f"resolves={resolves}")
print(f"pin={pin}")
print(f"strategy={strat}")
PY
)
  case "$out" in
    ERR:*)      echo "    FAIL T-010: 2.0.0.yaml parse error — ${out#ERR:} (FR-B86-030)" >&2; return 1 ;;
    NO_CONNECT) echo "    FAIL T-010: no connect-rpc component in 2.0.0.yaml (FR-B86-030)" >&2; return 1 ;;
  esac
  local std res pin strat ok=1
  std=$(printf '%s' "$out" | grep '^standard=' | cut -d= -f2-)
  res=$(printf '%s' "$out" | grep '^resolves=' | cut -d= -f2-)
  pin=$(printf '%s' "$out" | grep '^pin=' | cut -d= -f2-)
  strat=$(printf '%s' "$out" | grep '^strategy=' | cut -d= -f2-)
  [ "$std" = "transport.yaml" ] || { echo "    FAIL T-010: connect-rpc comp standard='$std' != 'transport.yaml' (FR-B86-030)" >&2; ok=0; }
  [ "$res" = "True" ]           || { echo "    FAIL T-010: transport.yaml ref does not resolve (re-asserts b8-3 T-011) (FR-B86-057)" >&2; ok=0; }
  [ "$pin" = "NONE" ]           || { echo "    FAIL T-010: connect-rpc comp carries forbidden inline-pin key(s): $pin (FR-B86-031)" >&2; ok=0; }
  [ "$strat" = "additive-first" ] || { echo "    FAIL T-010: rest-bridge->connect-rpc delta strategy='$strat' != 'additive-first' (FR-B86-032)" >&2; ok=0; }
  # The delivered annotation comment must be present on the standard: line (FR-B86-033).
  grep -qF 'B.8.6 delivered' "$SCHEMA_20" \
    || { echo "    FAIL T-010: 2.0.0.yaml has no 'B.8.6 delivered' annotation comment (FR-B86-033)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b86_l1_011_sibling_harness_coupling() {
  # Exit-code-only coupling guard (NO output parse — keeps T-011 within the
  # ≤ 2 s L1 budget, the b8-4/b8-5 coupling strategy). b8-3 (17/17) + b8-3b
  # (12/12) MUST stay GREEN under the B.8.6 edits.
  bash "$HARNESS_DIR/b8-3.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-011: b8-3.test.sh --level 1 is RED under the B.8.6 edit (NFR-B86-003 coupling regression)" >&2; return 1; }
  bash "$HARNESS_DIR/b8-3b.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-011: b8-3b.test.sh --level 1 is RED under the B.8.6 edit (NFR-B86-003 coupling regression)" >&2; return 1; }
}

_test_b86_l1_012_changelog_entry() {
  if [ ! -f "$CHANGELOG" ]; then
    echo "    FAIL T-012: CHANGELOG.md missing: $CHANGELOG (FR-B86-059)" >&2; return 1
  fi
  # A B.8.6 entry must exist (grep the whole file per the changelog-test
  # [Unreleased]-coupling lesson — survives release graduation). Anchored on
  # the change NAME `b8-6-connect-rpc` (not the bare "B.8.6" string, which the
  # B.8.4 entry already mentions in prose at line ~107 — that would false-pass).
  if ! grep -qF 'b8-6-connect-rpc' "$CHANGELOG"; then
    echo "    FAIL T-012: CHANGELOG.md has no b8-6-connect-rpc entry (FR-B86-059)" >&2
    return 1
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.8.6 — b8-6-connect-rpc — level $LEVEL ──"
  run_test _test_b86_l1_001_protos_subtree
  run_test _test_b86_l1_002_backend_subtree
  run_test _test_b86_l1_003_seven_plugins
  run_test _test_b86_l1_004_cargo_pins
  run_test _test_b86_l1_005_frozen_buf_gen_sentinel
  run_test _test_b86_l1_006_frozen_adapter_sentinel
  run_test _test_b86_l1_007_transport_version_and_header
  run_test _test_b86_l1_008_versions_2_0_0_block
  run_test _test_b86_l1_009_review_md_row
  run_test _test_b86_l1_010_schema_annotation_and_delta
  run_test _test_b86_l1_011_sibling_harness_coupling
  run_test _test_b86_l1_012_changelog_entry
  print_summary
}

main
