#!/usr/bin/env bash
# Forge — B.8.4 Envoy Gateway 2.0.0 template-brick harness
# <!-- Audit: B.8.4 (b8-4-envoy-gateway) — first real 2.0.0 template brick gate -->
#
# Validates the b8-4-envoy-gateway deliverables (design.md § Test Strategy):
#
#   T-001  2.0.0/infra/k8s/envoy-gateway/ tree has the 6 expected .tmpl files (FR-B84-001, ADR-B84-001)
#   T-002  resources are Gateway-API-native; no Ingress / Kong CRD kinds         (FR-B84-014)
#   T-003  HTTPRoute backendRefs the <project-name>-backend Service               (FR-B84-012/040, ADR-B84-004)
#   T-004  kustomization.yaml.tmpl lists all four data-plane manifests            (FR-B84-021, ADR-B84-003)
#   T-005  L2 skip-pass: kustomize build when present + substituted, else PASS    (FR-B84-021, ADR-B84-003)
#   T-006  root-level gateway.yaml passes J.7 in DIRECTORY mode + is enumerated   (FR-B84-030/031)
#   T-007  standard registered: index.yml path + REVIEW.md basename ledger row    (FR-B84-031)
#   T-008  2.0.0.yaml envoy comp: standard: gateway.yaml, no pin_source, resolves (FR-B84-032, ADR-B84-002)
#   T-009  anti-hallucination: chart/bundle semver pins live only in gateway.yaml (NFR-B84-001/005, ADR-B84-005)
#   T-010  additive — flat 1.0.0 Kong tree byte-untouched (kong.yml.example.tmpl) (FR-B84-002, NFR-B84-003)
#   T-011  frozen schema.yaml (1.0.0) still version: "1.0.0" (anchored)           (NFR-B84-003, b8-3 T-014)
#   T-012  coupling guard: b8-3 (17/17) + b8-3b (12/12) stay GREEN (exit-code)    (NFR-B84-004)
#
# 12 L1 tests. Budget L1 ≤ 5 s, zero net/Docker. T-005 kustomize is skip-pass.
# Mirrors b8-3.test.sh / delivery.test.sh structure (--level flag + _helpers.sh).

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
EG_DIR="$TEMPLATE_ROOT/2.0.0/infra/k8s/envoy-gateway"
KONG_TMPL="$TEMPLATE_ROOT/infra/kong/kong.yml.example.tmpl"

STANDARDS_DIR="$FORGE_ROOT/.forge/standards"
GATEWAY_STD="$STANDARDS_DIR/gateway.yaml"
INDEX_YML="$STANDARDS_DIR/index.yml"
REVIEW_MD="$STANDARDS_DIR/REVIEW.md"
VALIDATOR="$FORGE_ROOT/bin/validate-standards-yaml.sh"

SCHEMA_20="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/2.0.0.yaml"
SCHEMA_10="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/schema.yaml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

have_kustomize() { command -v kustomize >/dev/null 2>&1; }

# Expected data-plane manifest .tmpl files (the four Gateway-API resources).
DATAPLANE_TMPLS=(gatewayclass.yaml.tmpl gateway.yaml.tmpl httproute.yaml.tmpl backendtlspolicy.yaml.tmpl)

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b84_l1_001_tree_files() {
  local expected=(kustomization.yaml.tmpl gatewayclass.yaml.tmpl gateway.yaml.tmpl \
    httproute.yaml.tmpl backendtlspolicy.yaml.tmpl README.md.tmpl)
  local missing=()
  for f in "${expected[@]}"; do
    [ -f "$EG_DIR/$f" ] || missing+=("$f")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    FAIL T-001: missing .tmpl file(s) under $EG_DIR: ${missing[*]} (FR-B84-001, ADR-B84-001)" >&2
    return 1
  fi
}

_assert_gw_native() {
  # _assert_gw_native <file> <kind> — assert the manifest declares the
  # Gateway-API apiVersion AND the expected kind. Echoes a FAIL line + returns
  # 1 on either miss. Avoids the `A && B || C` SC2015 ambiguity (explicit if).
  local file="$1" kind="$2"
  if ! grep -qF 'gateway.networking.k8s.io/v1' "$EG_DIR/$file"; then
    echo "    FAIL T-002: $file missing gateway.networking.k8s.io/v1 apiVersion (FR-B84-014)" >&2
    return 1
  fi
  if ! grep -qE "^kind: ${kind}[[:space:]]*\$" "$EG_DIR/$file"; then
    echo "    FAIL T-002: $file missing 'kind: $kind' (FR-B84-014)" >&2
    return 1
  fi
}

_test_b84_l1_002_gateway_api_native() {
  local ok=1
  # Each manifest declares the Gateway-API apiVersion + its expected kind.
  _assert_gw_native gatewayclass.yaml.tmpl     GatewayClass    || ok=0
  _assert_gw_native gateway.yaml.tmpl          Gateway         || ok=0
  _assert_gw_native httproute.yaml.tmpl        HTTPRoute       || ok=0
  _assert_gw_native backendtlspolicy.yaml.tmpl BackendTLSPolicy || ok=0
  # NO Ingress, NO Kong CRDs anywhere in the tree. Match the bare
  # `apiVersion: networking.k8s.io/v1` (Ingress group) — NOT the
  # `gateway.networking.k8s.io/v1` GA group (note the required leading space,
  # which excludes the `gateway.`-prefixed form), and NOT `kind: Ingress`.
  if grep -rqE 'apiVersion:[[:space:]]+networking\.k8s\.io/v1|kind:[[:space:]]*Ingress' "$EG_DIR" 2>/dev/null; then
    echo "    FAIL T-002: networking.k8s.io/v1 Ingress found in envoy-gateway tree (must be Gateway-API-native only) (FR-B84-014)" >&2; ok=0
  fi
  if grep -rqiE 'configuration\.konghq\.com|kind:[[:space:]]*Kong' "$EG_DIR" 2>/dev/null; then
    echo "    FAIL T-002: Kong CRD kind found in envoy-gateway tree (FR-B84-014)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b84_l1_003_httproute_backend() {
  if ! grep -qF 'name: <project-name>-backend' "$EG_DIR/httproute.yaml.tmpl"; then
    echo "    FAIL T-003: httproute.yaml.tmpl does not backendRef <project-name>-backend (Kong-parity fsm-backend) (FR-B84-012/040, ADR-B84-004)" >&2
    return 1
  fi
  # The backendRef must sit under backendRefs (additive route to the shared backend).
  if ! grep -qF 'backendRefs:' "$EG_DIR/httproute.yaml.tmpl"; then
    echo "    FAIL T-003: httproute.yaml.tmpl has no backendRefs: block (FR-B84-012)" >&2
    return 1
  fi
}

_test_b84_l1_004_kustomization_lists_manifests() {
  local kz="$EG_DIR/kustomization.yaml.tmpl"
  local ok=1
  for m in gatewayclass.yaml gateway.yaml httproute.yaml backendtlspolicy.yaml; do
    grep -qE "^[[:space:]]*-[[:space:]]+$m([[:space:]]|\$)" "$kz" \
      || { echo "    FAIL T-004: kustomization.yaml.tmpl resources: missing '$m' (FR-B84-021, ADR-B84-003)" >&2; ok=0; }
  done
  grep -qF 'kind: Kustomization' "$kz" || { echo "    FAIL T-004: kustomization.yaml.tmpl not a Kustomization (FR-B84-021)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b84_l1_005_kustomize_build_skip_pass() {
  # L2 skip-pass: only meaningful when kustomize is on PATH AND substituted
  # (non-.tmpl) manifests exist. The framework repo ships only .tmpl files, so
  # this PASSes by skip (mirrors delivery.test.sh:358 have_kustomize guard).
  if have_kustomize && [ -f "$EG_DIR/kustomization.yaml" ]; then
    if ! kustomize build "$EG_DIR" >/dev/null 2>&1; then
      echo "    FAIL T-005: kustomize build of $EG_DIR failed (FR-B84-021)" >&2
      return 1
    fi
  fi
  # else: skip-pass (no kustomize binary or no substituted manifests).
  return 0
}

_test_b84_l1_006_gateway_std_j7_dir_mode() {
  if [ ! -f "$GATEWAY_STD" ]; then
    echo "    FAIL T-006: root-level standard missing: $GATEWAY_STD (FR-B84-030)" >&2
    return 1
  fi
  # The non-recursive "$target"/*.yaml glob (validate-standards-yaml.sh:67 ==
  # verify.sh:650) must enumerate the root-level gateway.yaml. Assert presence
  # at the standards root that the glob walks.
  local enumerated=0
  for f in "$STANDARDS_DIR"/*.yaml; do
    [ "$(basename "$f")" = "gateway.yaml" ] && enumerated=1
  done
  if [ "$enumerated" -ne 1 ]; then
    echo "    FAIL T-006: gateway.yaml not enumerated by the non-recursive standards-root glob (ADR-B84-002) (FR-B84-030)" >&2
    return 1
  fi
  # Directory mode is mandatory: it exercises the FR-J7-023 REVIEW.md ledger +
  # FR-J7-050/051 index.yml cross-cutting checks against the new file.
  local out rc
  out=$(bash "$VALIDATOR" "$STANDARDS_DIR/" 2>&1); rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    FAIL T-006: validate-standards-yaml.sh (dir mode) exited $rc (FR-B84-030/031)" >&2
    printf '%s\n' "$out" | grep -F 'STD-FAIL' | head -5 >&2
    return 1
  fi
  if ! printf '%s' "$out" | grep -qE '\[STD-PASS\] .*standards/gateway\.yaml'; then
    echo "    FAIL T-006: no [STD-PASS] line for standards/gateway.yaml in dir-mode output (FR-B84-030)" >&2
    return 1
  fi
}

_test_b84_l1_007_standard_registered() {
  local ok=1
  grep -qE '^[[:space:]]*path:[[:space:]]*standards/gateway\.yaml[[:space:]]*$' "$INDEX_YML" \
    || { echo "    FAIL T-007: index.yml has no 'path: standards/gateway.yaml' trigger entry (FR-B84-031)" >&2; ok=0; }
  # FR-J7-023 anchor: the REVIEW.md cell is the BARE basename, never prefixed.
  grep -qE '\|[[:space:]]*gateway\.yaml[[:space:]]*\|[[:space:]]*1\.0\.0[[:space:]]*\|' "$REVIEW_MD" \
    || { echo "    FAIL T-007: REVIEW.md has no '| gateway.yaml | 1.0.0 |' ledger row (basename anchor, FR-J7-023)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b84_l1_008_schema_standard_ref() {
  local out
  out=$(python3 - "$SCHEMA_20" "$STANDARDS_DIR" <<'PYEOF'
import sys, os, yaml
schema_20, std_dir = sys.argv[1], sys.argv[2]
try:
    with open(schema_20, encoding='utf-8') as f:
        d = yaml.safe_load(f)
except Exception as e:
    print(f"ERR:{e}"); sys.exit(0)
comps = d.get('components', []) if isinstance(d, dict) else []
envoy = next((c for c in comps if isinstance(c, dict) and c.get('name') == 'envoy-gateway'), None)
if envoy is None:
    print("NO_ENVOY"); sys.exit(0)
std = envoy.get('standard', 'MISSING')
has_pin_source = 'pin_source' in envoy
resolves = os.path.isfile(os.path.join(std_dir, std)) if isinstance(std, str) and std != 'MISSING' else False
print(f"standard={std}")
print(f"has_pin_source={has_pin_source}")
print(f"resolves={resolves}")
PYEOF
)
  case "$out" in
    ERR:*)    echo "    FAIL T-008: 2.0.0.yaml parse error — ${out#ERR:} (FR-B84-032)" >&2; return 1 ;;
    NO_ENVOY) echo "    FAIL T-008: no envoy-gateway component in 2.0.0.yaml (FR-B84-032)" >&2; return 1 ;;
  esac
  local std hps res
  std=$(printf '%s' "$out" | grep '^standard=' | cut -d= -f2-)
  hps=$(printf '%s' "$out" | grep '^has_pin_source=' | cut -d= -f2-)
  res=$(printf '%s' "$out" | grep '^resolves=' | cut -d= -f2-)
  local ok=1
  [ "$std" = "gateway.yaml" ]  || { echo "    FAIL T-008: envoy comp standard='$std' != 'gateway.yaml' (FR-B84-032)" >&2; ok=0; }
  [ "$hps" = "False" ]         || { echo "    FAIL T-008: envoy comp still carries pin_source (must be removed) (ADR-B84-002)" >&2; ok=0; }
  [ "$res" = "True" ]          || { echo "    FAIL T-008: standard ref 'gateway.yaml' does not resolve to an existing file (re-asserts b8-3 T-011)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b84_l1_009_anti_hallucination() {
  local ok=1
  # The chart + CRD-bundle semver pins (v1.8.0 / v1.5.1) are the verified
  # pins; they live in the gateway.yaml standard versions: block (single
  # source of truth), NOT hard-coded loose in the data-plane manifest .tmpls.
  grep -qF 'envoy_gateway_chart: "v1.8.0"' "$GATEWAY_STD" \
    || { echo "    FAIL T-009: gateway.yaml versions.envoy_gateway_chart != \"v1.8.0\" (ADR-B84-005, FR-B84-022)" >&2; ok=0; }
  grep -qF 'gateway_api_bundle: "v1.5.1"' "$GATEWAY_STD" \
    || { echo "    FAIL T-009: gateway.yaml versions.gateway_api_bundle != \"v1.5.1\" (ADR-B84-005, FR-B84-022)" >&2; ok=0; }
  # No chart/bundle semver pin may appear in the four DATA-PLANE manifests
  # (the README install doc legitimately carries the chart --version; the
  # manifests must not). Guards against a fabricated/duplicated inline pin.
  for m in "${DATAPLANE_TMPLS[@]}"; do
    if grep -qE 'v1\.8\.0|gateway-helm' "$EG_DIR/$m" 2>/dev/null; then
      echo "    FAIL T-009: chart pin / gateway-helm leaked into data-plane manifest $m (must live only in gateway.yaml) (NFR-B84-001)" >&2; ok=0
    fi
  done
  # Manifests must use ONLY the GA apiVersion constant — no alpha/beta drift.
  for m in "${DATAPLANE_TMPLS[@]}"; do
    if grep -qE 'gateway\.networking\.k8s\.io/v1(alpha|beta)' "$EG_DIR/$m" 2>/dev/null; then
      echo "    FAIL T-009: non-GA apiVersion (v1alpha*/v1beta*) in $m — bundle v1.5.1 GAs all four at v1 (ADR-B84-005)" >&2; ok=0
    fi
  done
  [ "$ok" = "1" ]
}

_test_b84_l1_010_kong_tree_untouched() {
  if [ ! -f "$KONG_TMPL" ]; then
    echo "    FAIL T-010: flat 1.0.0 Kong template missing: $KONG_TMPL (FR-B84-002, NFR-B84-003)" >&2
    return 1
  fi
  # Sentinel content of the frozen Kong example intact (additive-first: B.8.4
  # removes nothing from the Kong tree).
  local ok=1
  grep -qF '_format_version: "3.0"' "$KONG_TMPL" || { echo "    FAIL T-010: Kong _format_version sentinel missing/modified (NFR-B84-003)" >&2; ok=0; }
  grep -qF 'url: http://fsm-backend:8080' "$KONG_TMPL" || { echo "    FAIL T-010: Kong fsm-backend upstream sentinel missing/modified (NFR-B84-003)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b84_l1_011_frozen_schema_intact() {
  if [ ! -f "$SCHEMA_10" ]; then
    echo "    FAIL T-011: frozen schema.yaml (1.0.0) missing: $SCHEMA_10 (NFR-B84-003)" >&2
    return 1
  fi
  # Stricter anchored form (b8-3b T-012 / b8-3b.test.sh:189) — a loose substring
  # grep would also match e.g. version: "1.0.0-rc".
  grep -qx 'version: "1.0.0"' "$SCHEMA_10" \
    || { echo "    FAIL T-011: frozen schema.yaml is not version: \"1.0.0\" — the candidate edit bled into the frozen schema (NFR-B84-003)" >&2; return 1; }
}

_test_b84_l1_012_sibling_harness_coupling() {
  # Exit-code-only coupling guard (design Test Strategy: NO output parse, keeps
  # T-012 within the ≤ 5 s L1 budget). b8-3 (17/17) + b8-3b (12/12) MUST stay GREEN.
  bash "$HARNESS_DIR/b8-3.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-012: b8-3.test.sh --level 1 is RED under the B.8.4 edit (NFR-B84-004 coupling regression)" >&2; return 1; }
  bash "$HARNESS_DIR/b8-3b.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-012: b8-3b.test.sh --level 1 is RED under the B.8.4 edit (NFR-B84-004 coupling regression)" >&2; return 1; }
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.8.4 — b8-4-envoy-gateway — level $LEVEL ──"
  run_test _test_b84_l1_001_tree_files
  run_test _test_b84_l1_002_gateway_api_native
  run_test _test_b84_l1_003_httproute_backend
  run_test _test_b84_l1_004_kustomization_lists_manifests
  run_test _test_b84_l1_005_kustomize_build_skip_pass
  run_test _test_b84_l1_006_gateway_std_j7_dir_mode
  run_test _test_b84_l1_007_standard_registered
  run_test _test_b84_l1_008_schema_standard_ref
  run_test _test_b84_l1_009_anti_hallucination
  run_test _test_b84_l1_010_kong_tree_untouched
  run_test _test_b84_l1_011_frozen_schema_intact
  run_test _test_b84_l1_012_sibling_harness_coupling
  print_summary
}

main
