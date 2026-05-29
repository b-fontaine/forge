#!/usr/bin/env bash
# Forge — T.5 OTel Stack Test Harness (t5-otel-stack)
# <!-- Audit: T.5 (t5-otel-stack) — Phase 1 ARCHITECTURE-TARGET ADR-008 -->
#
# Validates the additive infra-side OTel + OBI + Coroot stack deliverables
# of t5-otel-stack on the full-stack-monorepo / 1.0.0 archetype :
#
#   - OBI eBPF DaemonSet manifest with unprivileged capabilities (FR-OTEL-001..010)
#   - Coroot deployment multi-doc manifest (FR-OTEL-020..023)
#   - OTel collector probabilistic_sampler base config (FR-OTEL-030..035)
#   - Env-tier sampler-patch overlay (prod) (FR-OTEL-032)
#   - Aegis privileged DaemonSet docs (FR-OTEL-040..041)
#   - Example mirror parity (FR-OTEL-050)
#   - observability.yaml v1.0.0 → v1.1.0 + REVIEW.md ledger entry (FR-OTEL-080)
#
# 14 L1 hermetic tests. No L2 fixtures (FR-OTEL-062 — kustomize build +
# kubeconform deferred to a follow-up change).
# Performance budget : L1 ≤ 5 s wall-clock (NFR-OTEL-005).

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

ARCHETYPE_DIR="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo"
INFRA_DIR="$ARCHETYPE_DIR/infra"
K8S_BASE="$INFRA_DIR/k8s/base"
K8S_OVERLAYS="$INFRA_DIR/k8s/overlays"
OBI_TPL="$K8S_BASE/obi-daemonset.yaml.tmpl"
COROOT_TPL="$K8S_BASE/coroot-deployment.yaml.tmpl"
COLLECTOR_TPL="$INFRA_DIR/observability/otel-collector-config.yaml.tmpl"
PROD_PATCH_TPL="$K8S_OVERLAYS/prod/sampler-patch.yaml.tmpl"
INFRA_CLAUDE_TPL="$INFRA_DIR/CLAUDE.md.tmpl"
INFRA_README_TPL="$K8S_BASE/README.md.tmpl"
EXAMPLE_DIR="$FORGE_ROOT_REAL/examples/forge-fsm-example"
EXAMPLE_OBI="$EXAMPLE_DIR/infra/k8s/base/obi-daemonset.yaml"
STD_OBSERVABILITY="$FORGE_ROOT_REAL/.forge/standards/observability.yaml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (14 tests)
# MANIFEST: _test_otel_001_obi_exists      — FR-OTEL-001 OBI DaemonSet template exists
# MANIFEST: _test_otel_002_obi_kind        — FR-OTEL-002 kind: DaemonSet
# MANIFEST: _test_otel_003_obi_caps        — FR-OTEL-003 capabilities BPF/SYS_PTRACE/NET_RAW/PERFMON
# MANIFEST: _test_otel_004_obi_host        — FR-OTEL-004 hostPID/hostNetwork
# MANIFEST: _test_otel_005_obi_kernel      — FR-OTEL-005 nodeSelector forge.dev/kernel-min-58
# MANIFEST: _test_otel_006_obi_image       — FR-OTEL-007 grafana/beyla:<tag> (no :latest ; narrowed b8-obi-refresh)
# MANIFEST: _test_otel_007_obi_aegis       — FR-OTEL-010 forge.dev/aegis-audit annotation
# MANIFEST: _test_otel_020_coroot_exists   — FR-OTEL-020 Coroot manifest exists, multi-doc
# MANIFEST: _test_otel_021_coroot_image    — FR-OTEL-021 coroot/coroot:1.4.4
# MANIFEST: _test_otel_030_sampler_base    — FR-OTEL-030/031/035 probabilistic_sampler base
# MANIFEST: _test_otel_032_overlay_prod    — FR-OTEL-032 prod overlay sampling_percentage 10
# MANIFEST: _test_otel_040_aegis_doc       — FR-OTEL-040/041 CLAUDE.md + README docs
# MANIFEST: _test_otel_050_example_mirror  — FR-OTEL-050 example/forge-fsm-example/ parity
# MANIFEST: _test_otel_080_standard_bumped — FR-OTEL-080 observability.yaml v1.1.0 + REVIEW.md

# ─── Helpers ────────────────────────────────────────────────────

_not_implemented() {
  echo "    not implemented (RED witness — pending implementation tasks)" >&2
  return 1
}

# ─── L1 tests ───────────────────────────────────────────────────

# FR-OTEL-001 OBI DaemonSet template exists
_test_otel_001_obi_exists() {
  if [ ! -f "$OBI_TPL" ]; then
    echo "    OBI DaemonSet template missing: $OBI_TPL" >&2
    return 1
  fi
}

# FR-OTEL-002 kind: DaemonSet
_test_otel_002_obi_kind() {
  if ! grep -q "^kind: DaemonSet$" "$OBI_TPL"; then
    echo "    kind: DaemonSet not found in $OBI_TPL" >&2
    return 1
  fi
}

# FR-OTEL-003 unprivileged capabilities (ADR-OTEL-004)
_test_otel_003_obi_caps() {
  local needles=("BPF" "SYS_PTRACE" "NET_RAW" "CHECKPOINT_RESTORE" "DAC_READ_SEARCH" "PERFMON")
  for n in "${needles[@]}"; do
    if ! grep -q "^[[:space:]]*- $n$" "$OBI_TPL"; then
      echo "    capability missing: $n in $OBI_TPL" >&2
      return 1
    fi
  done
}

# FR-OTEL-004 hostPID + hostNetwork
_test_otel_004_obi_host() {
  if ! grep -q "^[[:space:]]*hostPID: true$" "$OBI_TPL"; then
    echo "    hostPID: true not found in $OBI_TPL" >&2; return 1
  fi
  if ! grep -q "^[[:space:]]*hostNetwork: true$" "$OBI_TPL"; then
    echo "    hostNetwork: true not found in $OBI_TPL" >&2; return 1
  fi
}

# FR-OTEL-005 nodeSelector forge.dev/kernel-min-58: "true"
_test_otel_005_obi_kernel() {
  if ! grep -q 'forge.dev/kernel-min-58: "true"' "$OBI_TPL"; then
    echo "    forge.dev/kernel-min-58 nodeSelector not found in $OBI_TPL" >&2; return 1
  fi
}

# FR-OTEL-007 image grafana/beyla:<any-tag> (no :latest)
# Narrowed per ADR-B8-OBI-006 (sibling-harness coupling break, 2026-05-29) :
# pin VALUE ownership transferred to b8-obi.test.sh ; t5-otel.test.sh now
# asserts only the invariants this harness legitimately owns — image prefix
# present + non-:latest invariant.
_test_otel_006_obi_image() {
  if ! grep -qE "^[[:space:]]*image: grafana/beyla:[^[:space:]]+$" "$OBI_TPL"; then
    echo "    expected 'image: grafana/beyla:<tag>' in $OBI_TPL" >&2; return 1
  fi
  if grep -q "image: grafana/beyla:latest" "$OBI_TPL"; then
    echo "    forbidden ':latest' tag found in $OBI_TPL" >&2; return 1
  fi
}

# FR-OTEL-010 forge.dev/aegis-audit annotation
_test_otel_007_obi_aegis() {
  if ! grep -q 'forge.dev/aegis-audit: "required"' "$OBI_TPL"; then
    echo "    forge.dev/aegis-audit annotation missing in $OBI_TPL" >&2; return 1
  fi
}

# FR-OTEL-020 Coroot template exists, multi-doc (Deployment + Service + ConfigMap)
_test_otel_020_coroot_exists() {
  if [ ! -f "$COROOT_TPL" ]; then
    echo "    Coroot template missing: $COROOT_TPL" >&2; return 1
  fi
  local needles=("kind: Deployment" "kind: Service" "kind: ConfigMap")
  for n in "${needles[@]}"; do
    if ! grep -q "^${n}$" "$COROOT_TPL"; then
      echo "    multi-doc missing '${n}' in $COROOT_TPL" >&2; return 1
    fi
  done
}

# FR-OTEL-021 Coroot image pin (current trio state)
# b8-coroot-rehost rehosted coroot docker.io/coroot/coroot:1.4.4 →
# ghcr.io/coroot/coroot:1.20.2 (no v-prefix, ADR-B8-COR-001). Track the
# current value ; the owning assertion lives in b8-coroot.test.sh::009.
# Updated 2026-05-27 by b8-signoz-unified to fix a pre-existing CI-red escape.
_test_otel_021_coroot_image() {
  if ! grep -q "^[[:space:]]*image: ghcr.io/coroot/coroot:1.20.2$" "$COROOT_TPL"; then
    echo "    expected 'image: ghcr.io/coroot/coroot:1.20.2' in $COROOT_TPL" >&2; return 1
  fi
}

# FR-OTEL-030/031/035 probabilistic_sampler base (ratio 100, traceID anchor)
_test_otel_030_sampler_base() {
  if ! grep -q "^[[:space:]]*probabilistic_sampler:$" "$COLLECTOR_TPL"; then
    echo "    probabilistic_sampler block missing in $COLLECTOR_TPL" >&2; return 1
  fi
  if ! grep -q "^[[:space:]]*sampling_percentage: 100$" "$COLLECTOR_TPL"; then
    echo "    sampling_percentage: 100 (dev default) missing in $COLLECTOR_TPL" >&2; return 1
  fi
  if ! grep -q "^[[:space:]]*attribute_source: traceID$" "$COLLECTOR_TPL"; then
    echo "    attribute_source: traceID missing in $COLLECTOR_TPL" >&2; return 1
  fi
  # Pipeline wiring : probabilistic_sampler MUST be in the traces processor list.
  if ! grep -q "processors: \[memory_limiter, probabilistic_sampler, batch\]" "$COLLECTOR_TPL"; then
    echo "    probabilistic_sampler not wired in traces pipeline of $COLLECTOR_TPL" >&2; return 1
  fi
}

# FR-OTEL-032 prod overlay sampling_percentage: 10
_test_otel_032_overlay_prod() {
  if [ ! -f "$PROD_PATCH_TPL" ]; then
    echo "    prod sampler-patch missing: $PROD_PATCH_TPL" >&2; return 1
  fi
  if ! grep -q "^[[:space:]]*sampling_percentage: 10$" "$PROD_PATCH_TPL"; then
    echo "    expected 'sampling_percentage: 10' in $PROD_PATCH_TPL" >&2; return 1
  fi
}

# FR-OTEL-040/041 Aegis docs in CLAUDE.md + README checklist
_test_otel_040_aegis_doc() {
  if ! grep -q "^## Privileged DaemonSet — Aegis audit required$" "$INFRA_CLAUDE_TPL"; then
    echo "    Aegis H2 section missing in $INFRA_CLAUDE_TPL" >&2; return 1
  fi
  if ! grep -q "^## Deployment prerequisites$" "$INFRA_README_TPL"; then
    echo "    Deployment prerequisites checklist missing in $INFRA_README_TPL" >&2; return 1
  fi
}

# FR-OTEL-050 example mirror parity
_test_otel_050_example_mirror() {
  local pairs=(
    "$OBI_TPL:$EXAMPLE_DIR/infra/k8s/base/obi-daemonset.yaml"
    "$COROOT_TPL:$EXAMPLE_DIR/infra/k8s/base/coroot-deployment.yaml"
    "$COLLECTOR_TPL:$EXAMPLE_DIR/infra/observability/otel-collector-config.yaml"
    "$PROD_PATCH_TPL:$EXAMPLE_DIR/infra/k8s/overlays/prod/sampler-patch.yaml"
    "$INFRA_DIR/k8s/overlays/staging/sampler-patch.yaml.tmpl:$EXAMPLE_DIR/infra/k8s/overlays/staging/sampler-patch.yaml"
    "$INFRA_DIR/k8s/overlays/dev/sampler-patch.yaml.tmpl:$EXAMPLE_DIR/infra/k8s/overlays/dev/sampler-patch.yaml"
  )
  for pair in "${pairs[@]}"; do
    local rendered="${pair##*:}"
    if [ ! -f "$rendered" ]; then
      echo "    example mirror missing: $rendered" >&2
      return 1
    fi
  done
}

# FR-OTEL-080 — t5-otel-stack's persistent observability.yaml deliverables.
# observability.yaml is shared across the b8-observability-rearch trio, which
# legitimately mutates the top-level `version:`, `versions.coroot`, and
# `versions.beyla`. Those moving targets are owned by the trio harnesses
# (b8-coroot.test.sh, b8-signoz.test.sh, b8-obi.test.sh). t5-otel-stack's
# STABLE contributions are the `versions.beyla` KEY (introduced here, no
# longer pinned to a value) + the append-only REVIEW.md v1.1.0 birth row
# (never removed). Narrowed 2026-05-29 by b8-obi-refresh per ADR-B8-OBI-006
# — pin VALUE ownership transferred to b8-obi.test.sh ; this assertion now
# guards only key existence to prevent accidental deletion of the OBI pin
# slot by a future cross-cutting bump.
_test_otel_080_standard_bumped() {
  if ! grep -qE '^[[:space:]]*beyla:' "$STD_OBSERVABILITY"; then
    echo "    versions.beyla: key missing in observability.yaml" >&2; return 1
  fi
  # Append-only ledger keeps the v1.1.0 birth row regardless of later bumps.
  if ! grep -qE '\| observability\.yaml +\| 1\.1\.0 +\|' "$REVIEW_MD"; then
    echo "    REVIEW.md ledger row for observability.yaml v1.1.0 missing" >&2; return 1
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── T.5 — t5-otel-stack harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — additive OTel + OBI + Coroot stack manifests"
  run_test _test_otel_001_obi_exists
  run_test _test_otel_002_obi_kind
  run_test _test_otel_003_obi_caps
  run_test _test_otel_004_obi_host
  run_test _test_otel_005_obi_kernel
  run_test _test_otel_006_obi_image
  run_test _test_otel_007_obi_aegis
  run_test _test_otel_020_coroot_exists
  run_test _test_otel_021_coroot_image
  run_test _test_otel_030_sampler_base
  run_test _test_otel_032_overlay_prod
  run_test _test_otel_040_aegis_doc
  run_test _test_otel_050_example_mirror
  run_test _test_otel_080_standard_bumped

  print_summary
}

main "$@"
