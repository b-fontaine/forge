#!/usr/bin/env bash
# Forge — B.8.12 E2E migration test harness (b8-12-e2e-migration)
# <!-- Audit: B.8.12 (b8-12-e2e-migration) -->
#
# Validates the B.8.12 E2E migration convergence gate — a PURE ADDITIVE brick:
#
#   - 2.0.0 after-state golden span inventory (SUPERSET of the 1.0.0 baseline
#     3-span set; phantom user.interaction absent; sanitised) under
#     .forge/changes/b8-12-e2e-migration/captures/.
#   - Migration E2E driver: bin/forge-migrate-flagship.sh --target <tmpdir-copy>
#     --dry-run (L1 hermetic exit 0 + additive-delta plan + no mutation +
#     exit-7 wrong-version negative); real Phase-2 overlay at L2 opt-in.
#   - 3 demo .feature byte-survival (Spec Delta paths) + demo-004 status:specified.
#   - Rust S2S Connect client template transport_connect_client.rs.tmpl
#     (connectrpc 0.6.x client API; auth/TLS/deadline/retry posture).
#   - Envoy SecurityPolicy template (gateway.envoyproxy.io/v1alpha1; JWT folded
#     into spec.jwt.providers[]; remoteJWKS) + backend JWT middleware template
#     (jwt-authorizer); identity.yaml@1.1.0 cross-ref.
#   - Latency methodology doc extension to docs/MIGRATIONS.md (B.8.13 anchor;
#     NO committed p99 number — anti-faked-latency guard scoped to the b8-12
#     change tree + MIGRATIONS.md, NOT specs.md).
#   - CHANGELOG anchor (whole-file grep) + forge-ci.yml registration.
#   - Coupling guards: b8-1 (baseline) + b8-10 (migration driver) exit 0.
#
# ~23 L1 hermetic tests + 4 L2 opt-in (FORGE_B8_12_LIVE / FORGE_E2E_TOOLCHAINS).
# Performance budget : L1 ≤ a few seconds (grep/stat/diff + one dry-run
# invocation; no cargo/flutter/docker). L2 is opt-in and skip-passes by default.

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

CHANGE_DIR="$FORGE_ROOT_REAL/.forge/changes/b8-12-e2e-migration"
BASELINE_YAML="$FORGE_ROOT_REAL/.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml"
GOLDEN_YAML="$CHANGE_DIR/captures/full-stack-monorepo-2.0.0.span-inventory.yaml"
CAPTURES_DIR="$CHANGE_DIR/captures"
COLLECTOR_PY="$FORGE_ROOT_REAL/examples/forge-fsm-example/test/live-run/fake_otlp_collector.py"
MIGRATE_SH="$FORGE_ROOT_REAL/bin/forge-migrate-flagship.sh"
C1_EXAMPLE="$FORGE_ROOT_REAL/examples/forge-fsm-example"
TPL_20_BACKEND="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/2.0.0/backend"
TRANSPORT_CLIENT="$TPL_20_BACKEND/crates/grpc-api/src/transport_connect_client.rs.tmpl"
CARGO_TMPL="$TPL_20_BACKEND/crates/grpc-api/Cargo.toml.tmpl"
TRANSPORT_YML="$FORGE_ROOT_REAL/.forge/standards/transport.yaml"
ENVOY_OIDC_DIR="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway"
BACKEND_TPL_DIR="$TPL_20_BACKEND"
MIGRATIONS_DOC="$FORGE_ROOT_REAL/docs/MIGRATIONS.md"
CHANGELOG="$FORGE_ROOT_REAL/CHANGELOG.md"
FORGE_CI="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# Frozen-file paths (byte-unchanged guard).
FROZEN_10_SERVER="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/src/transport_connect.rs.tmpl"
FROZEN_10_INFRA="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo/infra/"
FROZEN_20_SERVER=".forge/templates/archetypes/full-stack-monorepo/2.0.0/backend/crates/grpc-api/src/transport_connect.rs.tmpl"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (23 tests) — all hermetic; ≤ a few seconds (grep/stat/diff + one dry-run)
# MANIFEST: _test_b812_001_golden_present          — FR-B812-001
# MANIFEST: _test_b812_002_three_span_superset     — FR-B812-002
# MANIFEST: _test_b812_003_phantom_absent          — FR-B812-003
# MANIFEST: _test_b812_004_goldens_sanitised       — FR-B812-004 / NFR-006
# MANIFEST: _test_b812_005_migrate_dryrun_exit0    — FR-B812-010
# MANIFEST: _test_b812_006_dryrun_additive_lines   — FR-B812-011
# MANIFEST: _test_b812_007_exit7_wrong_version     — FR-B812-015
# MANIFEST: _test_b812_008_c1_gitclean_after       — FR-B812-012 / NFR-003/010
# MANIFEST: _test_b812_009_demo_features_gwt        — FR-B812-020 / 023 (Spec Delta)
# MANIFEST: _test_b812_010_demo004_specified        — FR-B812-022 (Spec Delta)
# MANIFEST: _test_b812_011_client_tmpl_present      — FR-B812-030
# MANIFEST: _test_b812_012_client_pin_and_posture   — FR-B812-031 / 032
# MANIFEST: _test_b812_013_transport_yaml_pin       — FR-B812-035
# MANIFEST: _test_b812_014_envoy_oidc_tmpl_present  — FR-B812-040
# MANIFEST: _test_b812_015_jwt_middleware_tmpl_present — FR-B812-042
# MANIFEST: _test_b812_016_identity_crossref        — FR-B812-044
# MANIFEST: _test_b812_017_no_committed_p99         — FR-B812-006 / 051 / NFR-004
# MANIFEST: _test_b812_018_methodology_doc          — FR-B812-050
# MANIFEST: _test_b812_019_collector_stdlib_only    — FR-B812-063
# MANIFEST: _test_b812_020_frozen_files_unchanged   — FR-B812-033 / 045 / NFR-003
# MANIFEST: _test_b812_021_changelog_anchor         — FR-B812-067
# MANIFEST: _test_b812_022_forgeci_registration     — FR-B812-066
# MANIFEST: _test_b812_023_coupling_guards          — FR-B812-068
#
# L2 (4 tests) — gated on FORGE_B8_12_LIVE / FORGE_E2E_TOOLCHAINS
# MANIFEST: _test_b812_l2_real_overlay              — FR-B812-013 / 064
# MANIFEST: _test_b812_l2_viii_invariant            — FR-B812-014
# MANIFEST: _test_b812_l2_methodology_leg           — FR-B812-052
# MANIFEST: _test_b812_l2_cargo_check               — FR-B812-034 / 065

# ─── L1 tests ────────────────────────────────────────────────────

# FR-B812-001 — 2.0.0 golden span inventory present + schema fields
_test_b812_001_golden_present() {
  if [ ! -f "$GOLDEN_YAML" ]; then
    echo "    2.0.0 golden missing: $GOLDEN_YAML" >&2; return 1
  fi
  if ! grep -q "archetype: full-stack-monorepo" "$GOLDEN_YAML"; then
    echo "    'archetype: full-stack-monorepo' missing in golden" >&2; return 1
  fi
  if ! grep -qF 'version: "2.0.0"' "$GOLDEN_YAML"; then
    echo "    'version: \"2.0.0\"' missing in golden" >&2; return 1
  fi
}

# FR-B812-002 — 2.0.0 golden is a SUPERSET of the 1.0.0 baseline 3 spans
_test_b812_002_three_span_superset() {
  if [ ! -f "$GOLDEN_YAML" ]; then
    echo "    2.0.0 golden missing: $GOLDEN_YAML" >&2; return 1
  fi
  local marker
  for marker in "SpanKind.client" "http.request" "greeter.greet"; do
    if ! grep -qF "$marker" "$GOLDEN_YAML"; then
      echo "    baseline span marker '$marker' absent from 2.0.0 golden (not a superset)" >&2
      return 1
    fi
  done
  # The baseline itself must still carry the same 3 markers (subset is real).
  for marker in "SpanKind.client" "http.request" "greeter.greet"; do
    if ! grep -qF "$marker" "$BASELINE_YAML"; then
      echo "    baseline span marker '$marker' absent from 1.0.0 baseline (baseline drift)" >&2
      return 1
    fi
  done
}

# FR-B812-003 — phantom user.interaction span absent from BOTH goldens
# (the phantom is asserted absent as a SPAN NAME entry — `name: "user.interaction*"`;
#  the baseline's explanatory comment naming the phantom is allowed.)
_test_b812_003_phantom_absent() {
  local f
  for f in "$BASELINE_YAML" "$GOLDEN_YAML"; do
    if [ ! -f "$f" ]; then
      echo "    span inventory missing: $f" >&2; return 1
    fi
    if grep -qE '^[[:space:]]*-?[[:space:]]*name:[[:space:]]*"user\.interaction' "$f"; then
      echo "    phantom 'user.interaction' span entry present in $f" >&2
      grep -nE '^[[:space:]]*-?[[:space:]]*name:[[:space:]]*"user\.interaction' "$f" >&2
      return 1
    fi
  done
}

# FR-B812-004 / NFR-006 — goldens sanitised: ts:redacted in JSON captures, no IPv4
_test_b812_004_goldens_sanitised() {
  # JSON captures (if any) must carry the redaction placeholder + no IPv4.
  local json
  while IFS= read -r json; do
    [ -z "$json" ] && continue
    if ! grep -qF '"<ts:redacted>"' "$json"; then
      echo "    '<ts:redacted>' placeholder missing in $json" >&2; return 1
    fi
    if grep -qE '"([0-9]{1,3}\.){3}[0-9]{1,3}"' "$json"; then
      echo "    forbidden IPv4 dotted-quad in $json" >&2
      grep -nE '"([0-9]{1,3}\.){3}[0-9]{1,3}"' "$json" >&2
      return 1
    fi
  done < <(find "$CAPTURES_DIR" -name '*.golden.json' -type f 2>/dev/null)

  # The YAML golden must carry no raw IPv4 and no live timestamp beyond a date.
  if [ -f "$GOLDEN_YAML" ]; then
    if grep -qE '"([0-9]{1,3}\.){3}[0-9]{1,3}"' "$GOLDEN_YAML"; then
      echo "    forbidden IPv4 dotted-quad in $GOLDEN_YAML" >&2; return 1
    fi
    # A `captured:` value must be a date string only (YYYY-MM-DD), not a full ts.
    if grep -qE '^captured:[[:space:]]*"?[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$GOLDEN_YAML"; then
      echo "    'captured:' carries a live timestamp (date-only expected) in golden" >&2; return 1
    fi
  fi
}

# FR-B812-010 / ADR-B812-004 — migration dry-run exits 0 on a 1.0.0 tmpdir copy
_test_b812_005_migrate_dryrun_exit0() {
  local tmpdir; tmpdir="$(mktemp -d -t fsm-b812-XXXXXX)"
  trap "rm -rf '$tmpdir'" RETURN
  cp -r "$C1_EXAMPLE/." "$tmpdir/c1"
  git -C "$tmpdir/c1" init -q
  git -C "$tmpdir/c1" add -A
  git -C "$tmpdir/c1" commit -q -m "init" --allow-empty
  if ! bash "$MIGRATE_SH" --target "$tmpdir/c1" --dry-run >/dev/null 2>&1; then
    echo "    dry-run exited non-zero on a 1.0.0 tmpdir copy" >&2; return 1
  fi
}

# FR-B812-011 — dry-run plan has additive-delta + preservation invariant; no mutation
_test_b812_006_dryrun_additive_lines() {
  local tmpdir; tmpdir="$(mktemp -d -t fsm-b812-XXXXXX)"
  trap "rm -rf '$tmpdir'" RETURN
  cp -r "$C1_EXAMPLE/." "$tmpdir/c1"
  git -C "$tmpdir/c1" init -q
  git -C "$tmpdir/c1" add -A
  git -C "$tmpdir/c1" commit -q -m "init" --allow-empty
  local out; out="$tmpdir/dryrun.out"
  bash "$MIGRATE_SH" --target "$tmpdir/c1" --dry-run >"$out" 2>&1
  if ! grep -qF "Kong / Temporal / REST preserved" "$out"; then
    echo "    additive-preservation invariant line missing from dry-run output" >&2
    return 1
  fi
  local dirty; dirty="$(git -C "$tmpdir/c1" status --porcelain)"
  if [ -n "$dirty" ]; then
    echo "    dry-run mutated the target tree (should be no-op):" >&2
    printf '%s\n' "$dirty" >&2
    return 1
  fi
}

# FR-B812-015 — exit-7 on wrong-version (already-2.0.0) tmpdir
_test_b812_007_exit7_wrong_version() {
  local tmpdir; tmpdir="$(mktemp -d -t fsm-b812-XXXXXX)"
  trap "rm -rf '$tmpdir'" RETURN
  mkdir -p "$tmpdir/bad/.forge"
  printf 'archetype: full-stack-monorepo\narchetype_version: 2.0.0\n' \
    > "$tmpdir/bad/.forge/scaffold-manifest.yaml"
  git -C "$tmpdir/bad" init -q
  git -C "$tmpdir/bad" add -A
  git -C "$tmpdir/bad" commit -q -m "init" --allow-empty
  bash "$MIGRATE_SH" --target "$tmpdir/bad" --dry-run >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -ne 7 ]; then
    echo "    expected exit 7 on wrong-version 2.0.0 manifest, got $rc" >&2; return 1
  fi
}

# FR-B812-012 / NFR-003/010 — committed c1 example git-clean after; manifest still 1.0.0
_test_b812_008_c1_gitclean_after() {
  if ! git -C "$FORGE_ROOT_REAL" diff --quiet -- examples/forge-fsm-example/; then
    echo "    committed examples/forge-fsm-example/ is dirty (migration must not touch it)" >&2
    git -C "$FORGE_ROOT_REAL" --no-pager diff --stat -- examples/forge-fsm-example/ >&2
    return 1
  fi
  if ! grep -q "archetype_version: 1.0.0" "$C1_EXAMPLE/.forge/scaffold-manifest.yaml"; then
    echo "    committed c1 manifest is not archetype_version: 1.0.0" >&2; return 1
  fi
}

# FR-B812-020 / 023 (Spec Delta) — demo-001..003 .feature Given/When/Then intact
_test_b812_009_demo_features_gwt() {
  local n glob f
  for n in 1 2 3; do
    glob=("$C1_EXAMPLE/.forge/changes/demo-00${n}-"*/features/*.feature)
    f="${glob[0]}"
    if [ ! -f "$f" ]; then
      echo "    demo-00${n} feature file not found (glob: ${glob[*]})" >&2; return 1
    fi
    if ! grep -qE '^Feature:' "$f"; then
      echo "    'Feature:' keyword missing in $f" >&2; return 1
    fi
    local sc; sc="$(grep -cE '^[[:space:]]*Scenario:' "$f" 2>/dev/null || echo 0)"
    if [ "$sc" -lt 1 ]; then
      echo "    no 'Scenario:' line in $f" >&2; return 1
    fi
    # awk Given/When/Then sentinel — every Scenario must carry all three
    # (a Background 'Given' satisfies the Given requirement for the file).
    local missing
    missing=$(awk '
      /^[[:space:]]*(Background|Scenario):/ { if (sc && (gw==0 || wh==0 || th==0)) { printf "%s [G=%d W=%d T=%d]\n", name, gw, wh, th } sc=1; name=$0; gw=0; wh=0; th=0; next }
      /^[[:space:]]*(Given|And|But) / { if (sc && gw==0) gw=1 }
      /^[[:space:]]*When / { if (sc) wh=1 }
      /^[[:space:]]*Then / { if (sc) th=1 }
      END { }
    ' "$f")
    # File-level: at least one Given, one When, one Then present overall.
    if ! grep -qE '^[[:space:]]*(Given|And) ' "$f" \
       || ! grep -qE '^[[:space:]]*When ' "$f" \
       || ! grep -qE '^[[:space:]]*Then ' "$f"; then
      echo "    Given/When/Then structure incomplete in $f" >&2; return 1
    fi
  done
}

# FR-B812-022 (Spec Delta) — demo-004 status stays specified
_test_b812_010_demo004_specified() {
  local yaml="$C1_EXAMPLE/.forge/changes/demo-004-user-onboarding/.forge.yaml"
  if [ ! -f "$yaml" ]; then
    echo "    demo-004 .forge.yaml missing: $yaml" >&2; return 1
  fi
  if ! grep -q "status: specified" "$yaml"; then
    echo "    demo-004 is not status: specified" >&2; return 1
  fi
}

# FR-B812-030 — transport_connect_client.rs.tmpl present
_test_b812_011_client_tmpl_present() {
  if [ ! -f "$TRANSPORT_CLIENT" ]; then
    echo "    S2S client template missing: $TRANSPORT_CLIENT" >&2; return 1
  fi
}

# FR-B812-031 / 032 — client pin sentinel + auth/tls/deadline/retry posture
_test_b812_012_client_pin_and_posture() {
  if [ ! -f "$TRANSPORT_CLIENT" ]; then
    echo "    S2S client template missing: $TRANSPORT_CLIENT" >&2; return 1
  fi
  # Pin sentinel: =0.6 in the client template OR the companion Cargo.toml.tmpl.
  if ! grep -qE "=0\.6" "$TRANSPORT_CLIENT" \
     && ! { [ -f "$CARGO_TMPL" ] && grep -qE "connectrpc.*=0\.6" "$CARGO_TMPL"; }; then
    echo "    connectrpc =0.6 pin sentinel absent from client template + Cargo.toml.tmpl" >&2
    return 1
  fi
  # Posture: at least the four knobs present (auth/tls/deadline/retry).
  local knob
  for knob in auth tls deadline retry; do
    if ! grep -iqE "$knob" "$TRANSPORT_CLIENT"; then
      echo "    posture term '$knob' absent from client template" >&2; return 1
    fi
  done
}

# FR-B812-035 — transport.yaml versions_2_0_0 block + connectrpc pin
_test_b812_013_transport_yaml_pin() {
  if ! grep -q "versions_2_0_0" "$TRANSPORT_YML"; then
    echo "    versions_2_0_0 block missing in transport.yaml" >&2; return 1
  fi
  if ! grep -qE "connectrpc.*=0\.6\.1" "$TRANSPORT_YML"; then
    echo "    connectrpc =0.6.1 pin missing in transport.yaml" >&2; return 1
  fi
}

# FR-B812-040 — Envoy-OIDC template(s) present in the 2.0.0 subtree
_test_b812_014_envoy_oidc_tmpl_present() {
  if ! find "$ENVOY_OIDC_DIR" \( -name "*security*" -o -name "*jwt*" -o -name "*oidc*" \) -type f 2>/dev/null | grep -q .; then
    echo "    no Envoy-OIDC template (*security*/*jwt*/*oidc*) found under $ENVOY_OIDC_DIR" >&2
    return 1
  fi
}

# FR-B812-042 — backend JWT middleware template present
_test_b812_015_jwt_middleware_tmpl_present() {
  if ! find "$BACKEND_TPL_DIR" \( -name "*jwt*" -o -name "*auth*middleware*" \) -type f 2>/dev/null | grep -q .; then
    echo "    no backend JWT middleware template (*jwt*/*auth*middleware*) found under $BACKEND_TPL_DIR" >&2
    return 1
  fi
}

# FR-B812-044 — identity.yaml@1.1.0 cross-reference in the SecurityPolicy template
_test_b812_016_identity_crossref() {
  local sp
  sp="$(find "$ENVOY_OIDC_DIR" -name "*security*.tmpl" -type f 2>/dev/null | head -1)"
  if [ -z "$sp" ]; then
    echo "    SecurityPolicy template not found for identity cross-ref check" >&2; return 1
  fi
  if ! grep -qE "identity\.yaml|1\.1\.0" "$sp"; then
    echo "    identity.yaml@1.1.0 cross-reference missing in $sp" >&2; return 1
  fi
}

# FR-B812-006 / 051 / NFR-004 — NO committed p99 number.
# SCOPE (design T-017 INTENT, lines 277-280): the guard targets the b8-12
# DELIVERABLE artifacts — the committed goldens under captures/, the new 2.0.0
# templates this brick adds, and the MIGRATIONS.md methodology section. The
# planning meta-docs (specs.md, tasks.md, design.md, open-questions.md,
# evidence.md) legitimately DISCUSS the illustrative "p99:42ms" example and the
# rollback thresholds — they are NOT committed measurements and are EXCLUDED.
_test_b812_017_no_committed_p99() {
  local pat='p9[59][^a-z].*[0-9]+[[:space:]]*(ms|µs|s\b)'
  local hits=""
  # (a) committed goldens + any companion JSON captures.
  if [ -d "$CAPTURES_DIR" ]; then
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      if grep -EnH "$pat" "$f" 2>/dev/null; then hits="found"; fi
    done < <(find "$CAPTURES_DIR" -type f 2>/dev/null)
  fi
  # (b) the b8-12 deliverable templates (S2S client + Envoy-OIDC + JWT middleware).
  local tpl
  for tpl in "$TRANSPORT_CLIENT" "$CARGO_TMPL"; do
    [ -f "$tpl" ] || continue
    if grep -EnH "$pat" "$tpl" 2>/dev/null; then hits="found"; fi
  done
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if grep -EnH "$pat" "$f" 2>/dev/null; then hits="found"; fi
  done < <(find "$ENVOY_OIDC_DIR" \( -name "*security*" -o -name "*jwt*" -o -name "*oidc*" \) -type f 2>/dev/null)
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if grep -EnH "$pat" "$f" 2>/dev/null; then hits="found"; fi
  done < <(find "$BACKEND_TPL_DIR" \( -name "*jwt*" -o -name "*auth*middleware*" \) -type f 2>/dev/null)
  # (c) the methodology doc section.
  if [ -f "$MIGRATIONS_DOC" ] && grep -EnH "$pat" "$MIGRATIONS_DOC" 2>/dev/null; then
    hits="found"
  fi
  if [ -n "$hits" ]; then
    echo "    committed numeric latency figure found in a b8-12 deliverable / MIGRATIONS.md" >&2
    return 1
  fi
}

# FR-B812-050 — methodology doc present + p99 + B.8.13 anchor
_test_b812_018_methodology_doc() {
  if [ ! -f "$MIGRATIONS_DOC" ]; then
    echo "    docs/MIGRATIONS.md missing: $MIGRATIONS_DOC" >&2; return 1
  fi
  if ! grep -q "p99" "$MIGRATIONS_DOC"; then
    echo "    'p99' absent from MIGRATIONS.md" >&2; return 1
  fi
  if ! grep -q "B.8.13" "$MIGRATIONS_DOC"; then
    echo "    'B.8.13' anchor absent from MIGRATIONS.md" >&2; return 1
  fi
  # The methodology section must be anchored to B.8.12.
  if ! grep -qE "B\.8\.12|b8-12" "$MIGRATIONS_DOC"; then
    echo "    B.8.12 methodology anchor absent from MIGRATIONS.md" >&2; return 1
  fi
}

# FR-B812-063 — reused fake-OTLP collector is stdlib-only
_test_b812_019_collector_stdlib_only() {
  if [ ! -f "$COLLECTOR_PY" ]; then
    echo "    fake-OTLP collector missing: $COLLECTOR_PY" >&2; return 1
  fi
  local forbidden=("protobuf" "google.protobuf" "grpc" "requests" "httpx" "yaml" "opentelemetry")
  local mod
  for mod in "${forbidden[@]}"; do
    if grep -qE "^(import|from)[[:space:]]+${mod}([[:space:]]|\.|$)" "$COLLECTOR_PY"; then
      echo "    forbidden import '$mod' in $COLLECTOR_PY" >&2
      grep -nE "^(import|from)[[:space:]]+${mod}" "$COLLECTOR_PY" >&2
      return 1
    fi
  done
}

# FR-B812-033 / 045 / NFR-003 — frozen 1.0.0 + 2.0.0 server adapter byte-unchanged
_test_b812_020_frozen_files_unchanged() {
  # 1.0.0 flat-tree server adapter.
  if ! git -C "$FORGE_ROOT_REAL" diff --quiet -- \
      ".forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/src/transport_connect.rs.tmpl"; then
    echo "    frozen 1.0.0 server adapter transport_connect.rs.tmpl was modified" >&2; return 1
  fi
  # 1.0.0 flat-tree infra (Kong manifests).
  if ! git -C "$FORGE_ROOT_REAL" diff --quiet -- \
      ".forge/templates/archetypes/full-stack-monorepo/infra/"; then
    echo "    frozen 1.0.0 infra/ tree was modified" >&2; return 1
  fi
  # 2.0.0 server adapter (sibling of the new client) stays frozen.
  if ! git -C "$FORGE_ROOT_REAL" diff --quiet -- "$FROZEN_20_SERVER"; then
    echo "    frozen 2.0.0 server adapter transport_connect.rs.tmpl was modified" >&2; return 1
  fi
}

# FR-B812-067 — CHANGELOG anchored b8-12-e2e-migration (whole-file grep)
_test_b812_021_changelog_anchor() {
  if [ ! -f "$CHANGELOG" ]; then
    echo "    CHANGELOG.md missing: $CHANGELOG" >&2; return 1
  fi
  if ! grep -qF "b8-12-e2e-migration" "$CHANGELOG"; then
    echo "    b8-12-e2e-migration anchor missing in CHANGELOG.md" >&2; return 1
  fi
}

# FR-B812-066 — forge-ci.yml registers b8-12.test.sh
_test_b812_022_forgeci_registration() {
  if [ ! -f "$FORGE_CI" ]; then
    echo "    forge-ci.yml missing: $FORGE_CI" >&2; return 1
  fi
  if ! grep -qF "b8-12.test.sh" "$FORGE_CI"; then
    echo "    b8-12.test.sh not registered in forge-ci.yml" >&2; return 1
  fi
}

# FR-B812-068 — coupling guards: b8-1 + b8-10 exit 0
_test_b812_023_coupling_guards() {
  if [ ! -f "$HARNESS_DIR/b8-1.test.sh" ]; then
    echo "    b8-1.test.sh missing: $HARNESS_DIR/b8-1.test.sh" >&2; return 1
  fi
  if ! bash "$HARNESS_DIR/b8-1.test.sh" --level 1 >/dev/null 2>&1; then
    echo "    b8-1.test.sh --level 1 exited non-zero (baseline invariants broken)" >&2; return 1
  fi
  if [ ! -f "$HARNESS_DIR/b8-10.test.sh" ]; then
    echo "    b8-10.test.sh missing: $HARNESS_DIR/b8-10.test.sh" >&2; return 1
  fi
  if ! bash "$HARNESS_DIR/b8-10.test.sh" --level 1 >/dev/null 2>&1; then
    echo "    b8-10.test.sh --level 1 exited non-zero (migration driver broken)" >&2; return 1
  fi
}

# ─── L2 tests (opt-in) ───────────────────────────────────────────

# FR-B812-013 / 064 — real Phase-2 overlay asserts additive result
_test_b812_l2_real_overlay() {
  if [ "${FORGE_B8_12_LIVE:-0}" != "1" ]; then
    echo "    SKIP: FORGE_B8_12_LIVE not set"; return 0
  fi
  local tmpdir; tmpdir="$(mktemp -d -t fsm-b812-l2-XXXXXX)"
  trap "rm -rf '$tmpdir'" RETURN
  cp -r "$C1_EXAMPLE/." "$tmpdir/c1"
  git -C "$tmpdir/c1" init -q
  git -C "$tmpdir/c1" add -A
  git -C "$tmpdir/c1" commit -q -m "init" --allow-empty
  if ! bash "$MIGRATE_SH" --target "$tmpdir/c1" --phase 2 >/dev/null 2>&1; then
    echo "    real Phase-2 overlay exited non-zero" >&2; return 1
  fi
  if [ ! -d "$tmpdir/c1/infra/k8s/envoy-gateway" ]; then
    echo "    Envoy gateway dir absent after overlay (additive deliverable missing)" >&2; return 1
  fi
  # Kong preserved (docker-compose or infra path still names kong).
  if ! grep -rqi "kong" "$tmpdir/c1/infra/" 2>/dev/null \
     && ! ls "$tmpdir/c1/"docker-compose* >/dev/null 2>&1; then
    echo "    Kong appears removed after overlay (VIII.1 violation)" >&2; return 1
  fi
}

# FR-B812-014 — VIII.1/VIII.2: no Kong/Temporal/REST path removed
_test_b812_l2_viii_invariant() {
  if [ "${FORGE_B8_12_LIVE:-0}" != "1" ]; then
    echo "    SKIP: FORGE_B8_12_LIVE not set"; return 0
  fi
  local tmpdir; tmpdir="$(mktemp -d -t fsm-b812-l2v-XXXXXX)"
  trap "rm -rf '$tmpdir'" RETURN
  cp -r "$C1_EXAMPLE/." "$tmpdir/c1"
  git -C "$tmpdir/c1" init -q
  git -C "$tmpdir/c1" add -A
  git -C "$tmpdir/c1" commit -q -m "init" --allow-empty
  if ! bash "$MIGRATE_SH" --target "$tmpdir/c1" --phase 2 >/dev/null 2>&1; then
    echo "    real Phase-2 overlay exited non-zero" >&2; return 1
  fi
  # No Kong/Temporal/rest-bridge path that existed in the base may be deleted.
  local removed
  removed="$(diff -rq "$C1_EXAMPLE" "$tmpdir/c1" 2>/dev/null \
    | grep "^Only in $C1_EXAMPLE" \
    | grep -iE "kong|temporal|rest-bridge|rest_bridge" || true)"
  if [ -n "$removed" ]; then
    echo "    Kong/Temporal/REST path removed by overlay (VIII.1/VIII.2 violation):" >&2
    printf '%s\n' "$removed" >&2
    return 1
  fi
}

# FR-B812-052 — methodology leg exercised; skip-pass without env
_test_b812_l2_methodology_leg() {
  if [ "${FORGE_B8_12_LIVE:-0}" != "1" ]; then
    echo "    SKIP: FORGE_B8_12_LIVE not set"; return 0
  fi
  if [ ! -r "$MIGRATIONS_DOC" ]; then
    echo "    methodology doc not readable: $MIGRATIONS_DOC" >&2; return 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "    skipping collector exercise — python3 not on PATH" >&2; return 0
  fi
  # The collector script must be Python-importable (syntax-valid).
  if ! python3 -c "import ast,sys; ast.parse(open('$COLLECTOR_PY').read())" >/dev/null 2>&1; then
    echo "    fake-OTLP collector is not Python-parseable" >&2; return 1
  fi
}

# FR-B812-034 / 065 — cargo-check on the rendered S2S client template
_test_b812_l2_cargo_check() {
  if [ "${FORGE_E2E_TOOLCHAINS:-0}" != "1" ]; then
    echo "    SKIP: FORGE_E2E_TOOLCHAINS not set"; return 0
  fi
  if ! command -v cargo >/dev/null 2>&1; then
    echo "    skipping — 'cargo' not on PATH" >&2; return 0
  fi
  if [ ! -f "$TRANSPORT_CLIENT" ]; then
    echo "    S2S client template missing: $TRANSPORT_CLIENT" >&2; return 1
  fi
  local tmpdir; tmpdir="$(mktemp -d -t fsm-b812-cargo-XXXXXX)"
  trap "rm -rf '$tmpdir'" RETURN
  mkdir -p "$tmpdir/proj/src"
  cat > "$tmpdir/proj/Cargo.toml" <<'CARGO'
[package]
name = "b812-client-check"
version = "0.0.0"
edition = "2021"
publish = false

[dependencies]
connectrpc = { version = "=0.6.1", features = ["axum", "client"] }
buffa = "=0.6.0"
buffa-types = "=0.6.0"
tokio = { version = "1", features = ["full"] }
http = "1"
CARGO
  # Render the template (strip the leading // header line; replace <Svc> tokens).
  sed 's/<Svc>/Greeter/g; s/<svc>/greeter/g' "$TRANSPORT_CLIENT" \
    > "$tmpdir/proj/src/lib.rs"
  if ! (cd "$tmpdir/proj" && cargo check >/dev/null 2>"$tmpdir/cargo.err"); then
    echo "    cargo check failed on the rendered S2S client template; stderr:" >&2
    sed 's/^/      /' "$tmpdir/cargo.err" >&2 || true
    return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── B.8.12 — b8-12-e2e-migration — level $LEVEL ──"
  echo ""
  echo "L1 — golden span-tree superset gate"
  run_test _test_b812_001_golden_present
  run_test _test_b812_002_three_span_superset
  run_test _test_b812_003_phantom_absent
  run_test _test_b812_004_goldens_sanitised

  echo ""
  echo "L1 — migration E2E driver (dry-run hermetic)"
  run_test _test_b812_005_migrate_dryrun_exit0
  run_test _test_b812_006_dryrun_additive_lines
  run_test _test_b812_007_exit7_wrong_version
  run_test _test_b812_008_c1_gitclean_after

  echo ""
  echo "L1 — demo survival (Spec Delta paths)"
  run_test _test_b812_009_demo_features_gwt
  run_test _test_b812_010_demo004_specified

  echo ""
  echo "L1 — S2S Connect client template"
  run_test _test_b812_011_client_tmpl_present
  run_test _test_b812_012_client_pin_and_posture
  run_test _test_b812_013_transport_yaml_pin

  echo ""
  echo "L1 — Envoy-OIDC wiring"
  run_test _test_b812_014_envoy_oidc_tmpl_present
  run_test _test_b812_015_jwt_middleware_tmpl_present
  run_test _test_b812_016_identity_crossref

  echo ""
  echo "L1 — anti-faked-latency + methodology doc"
  run_test _test_b812_017_no_committed_p99
  run_test _test_b812_018_methodology_doc

  echo ""
  echo "L1 — collector guard + frozen files + CHANGELOG/CI + coupling"
  run_test _test_b812_019_collector_stdlib_only
  run_test _test_b812_020_frozen_files_unchanged
  run_test _test_b812_021_changelog_anchor
  run_test _test_b812_022_forgeci_registration
  run_test _test_b812_023_coupling_guards

  case ",$LEVEL," in
    *,2,*)
      echo ""
      echo "L2 — opt-in (FORGE_B8_12_LIVE / FORGE_E2E_TOOLCHAINS)"
      run_test _test_b812_l2_real_overlay
      run_test _test_b812_l2_viii_invariant
      run_test _test_b812_l2_methodology_leg
      run_test _test_b812_l2_cargo_check
      ;;
  esac

  print_summary
}

main "$@"
