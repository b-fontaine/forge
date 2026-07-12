#!/usr/bin/env bash
# Forge — B.6.6 event-driven-eu production Helm charts harness
# <!-- Audit: B.6.6 (b6-6-helm) — Temporal cluster + Postgres backing, NATS JetStream cluster, T2/T3 docs -->
#
# Validates the b6-6-helm deliverables (design.md § Test Strategy):
#
#   T-001  infra/k8s/ tree has the 5 expected .tmpl files                        (FR-B6-HELM-001/020/041)
#   T-002  Temporal overlay enables all four roles (frontend/history/matching/worker) (FR-B6-HELM-002)
#   T-003  Temporal overlay: Postgres datastores (default+visibility, postgres12) (FR-B6-HELM-003)
#   T-004  Temporal overlay: numHistoryShards + schema-setup wiring               (FR-B6-HELM-004/005)
#   T-005  Temporal overlay uses no removed shapes (no cassandra:, no persistence.default) (ADR-B6-HELM-002)
#   T-006  NATS overlay: 3-node RAFT cluster + JetStream file-store PVC + monitor (FR-B6-HELM-021/022/023)
#   T-007  no re-pin of temporalio-sdk/client/async-nats under infra/k8s; Cargo pins 0.5.0 (NFR-B6-HELM-002)
#   T-008  live pins single-sourced in READMEs (temporal 1.5.0/1.31.1, nats 2.14.2) (NFR-B6-HELM-001)
#   T-009  each README documents T1/T2/T3 self-host posture; nats documents consumers (FR-B6-HELM-040/024)
#   T-010  scaffold-plan registers all 5 new sources                             (FR-B6-HELM-050)
#   T-011  secrets never committed (no inline password:/token: in overlays)      (NFR-B6-HELM-003)
#   T-012  each substituted values-forge.yaml.tmpl is valid YAML                 (NFR-B6-HELM-004)
#   T-013  schema is stable/scaffoldable:true (promoted B.6.7) + b6-2 stays GREEN (NFR-B6-HELM-005)
#   T-L2-001  helm template each overlay against the upstream chart (skip-pass)  (NFR-B6-HELM-001)
#
# 13 L1 + 1 L2. Budget L1 <= 5 s, zero net/Docker. T-L2-001 helm render is skip-pass.
# Mirrors b8-4.test.sh / b6-2.test.sh structure (--level flag + _helpers.sh).

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

ARCHETYPE_DIR="$FORGE_ROOT/.forge/templates/archetypes/event-driven-eu"
TPL_DIR="$ARCHETYPE_DIR/1.0.0"
K8S_DIR="$TPL_DIR/infra/k8s"
TEMPORAL_DIR="$K8S_DIR/temporal-cluster"
NATS_DIR="$K8S_DIR/nats-jetstream"
TEMPORAL_VALUES="$TEMPORAL_DIR/values-forge.yaml.tmpl"
TEMPORAL_README="$TEMPORAL_DIR/README.md.tmpl"
NATS_VALUES="$NATS_DIR/values-forge.yaml.tmpl"
NATS_README="$NATS_DIR/README.md.tmpl"
K8S_README="$K8S_DIR/README.md.tmpl"
CARGO="$TPL_DIR/backend/Cargo.toml.tmpl"
PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"
SCHEMA="$FORGE_ROOT/.forge/schemas/event-driven-eu/1.0.0.yaml"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

have_helm() { command -v helm >/dev/null 2>&1; }

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b66_l1_001_tree_files() {
  local expected=(
    "$K8S_README"
    "$TEMPORAL_VALUES" "$TEMPORAL_README"
    "$NATS_VALUES" "$NATS_README"
  )
  local missing=()
  for f in "${expected[@]}"; do
    [ -f "$f" ] || missing+=("${f#"$TPL_DIR/"}")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    FAIL T-001: missing infra/k8s .tmpl file(s): ${missing[*]} (FR-B6-HELM-001/020/041)" >&2
    return 1
  fi
}

_test_b66_l1_002_temporal_four_roles() {
  [ -f "$TEMPORAL_VALUES" ] || { echo "    FAIL T-002: temporal overlay missing (FR-B6-HELM-002)" >&2; return 1; }
  local ok=1
  for role in frontend history matching worker; do
    grep -qE "^  ${role}:[[:space:]]*\$" "$TEMPORAL_VALUES" \
      || { echo "    FAIL T-002: temporal overlay missing server role '$role' (FR-B6-HELM-002)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b66_l1_003_temporal_postgres() {
  [ -f "$TEMPORAL_VALUES" ] || { echo "    FAIL T-003: temporal overlay missing (FR-B6-HELM-003)" >&2; return 1; }
  local ok=1
  grep -qF 'datastores:' "$TEMPORAL_VALUES"          || { echo "    FAIL T-003: no persistence.datastores block (FR-B6-HELM-003)" >&2; ok=0; }
  grep -qF 'defaultStore: default' "$TEMPORAL_VALUES" || { echo "    FAIL T-003: no defaultStore: default (FR-B6-HELM-003)" >&2; ok=0; }
  grep -qF 'visibilityStore: visibility' "$TEMPORAL_VALUES" || { echo "    FAIL T-003: no visibilityStore: visibility (FR-B6-HELM-003)" >&2; ok=0; }
  # postgres plugin on both stores (postgres12 or postgres12_pgx), never mysql/cassandra
  [ "$(grep -cE 'pluginName:[[:space:]]*postgres12' "$TEMPORAL_VALUES")" -ge 2 ] \
    || { echo "    FAIL T-003: expected >=2 postgres12 datastores (default + visibility) (FR-B6-HELM-003)" >&2; ok=0; }
  grep -qF 'existingSecret:' "$TEMPORAL_VALUES"       || { echo "    FAIL T-003: DB password not sourced from existingSecret (FR-B6-HELM-003, NFR-B6-HELM-003)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b66_l1_004_temporal_shards_schema() {
  [ -f "$TEMPORAL_VALUES" ] || { echo "    FAIL T-004: temporal overlay missing (FR-B6-HELM-004)" >&2; return 1; }
  local ok=1
  grep -qE 'numHistoryShards:[[:space:]]*[0-9]+' "$TEMPORAL_VALUES" \
    || { echo "    FAIL T-004: numHistoryShards not set (FR-B6-HELM-004)" >&2; ok=0; }
  # schema setup wired: either the schema: block (useHelmHooks) or admintools:
  grep -qE '^schema:|useHelmHooks:|^admintools:' "$TEMPORAL_VALUES" \
    || { echo "    FAIL T-004: no schema-setup wiring (schema:/useHelmHooks:/admintools:) (FR-B6-HELM-005)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b66_l1_005_temporal_no_removed_shapes() {
  [ -f "$TEMPORAL_VALUES" ] || { echo "    FAIL T-005: temporal overlay missing (ADR-B6-HELM-002)" >&2; return 1; }
  local ok=1
  # cassandra top-level key was removed in chart v1.0.0-rc.2 (LIVE validation error)
  if grep -qE '^cassandra:' "$TEMPORAL_VALUES"; then
    echo "    FAIL T-005: top-level 'cassandra:' key present — removed in chart v1.0.0-rc.2 (ADR-B6-HELM-002)" >&2; ok=0
  fi
  # server.config.persistence.default was removed — must use datastores.<name>.
  # The (correct) datastores child 'default:' is at 8-space indent; the removed
  # shape is a 'default:' mapping key at 6-space indent (sibling of datastores:).
  if grep -qE '^      default:[[:space:]]*$' "$TEMPORAL_VALUES"; then
    echo "    FAIL T-005: 'server.config.persistence.default:' removed shape present — migrate to datastores.<name> (ADR-B6-HELM-002)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b66_l1_006_nats_cluster_jetstream() {
  [ -f "$NATS_VALUES" ] || { echo "    FAIL T-006: nats overlay missing (FR-B6-HELM-021)" >&2; return 1; }
  local ok=1
  grep -qE '^  cluster:[[:space:]]*$' "$NATS_VALUES"   || { echo "    FAIL T-006: no config.cluster block (FR-B6-HELM-021)" >&2; ok=0; }
  grep -qE 'replicas:[[:space:]]*[3-9]' "$NATS_VALUES"  || { echo "    FAIL T-006: cluster replicas < 3 (RAFT quorum) (FR-B6-HELM-021)" >&2; ok=0; }
  grep -qE '^  jetstream:[[:space:]]*$' "$NATS_VALUES" || { echo "    FAIL T-006: no config.jetstream block (FR-B6-HELM-022)" >&2; ok=0; }
  grep -qF 'fileStore:' "$NATS_VALUES"                  || { echo "    FAIL T-006: no jetstream fileStore (FR-B6-HELM-022)" >&2; ok=0; }
  grep -qF 'pvc:' "$NATS_VALUES"                        || { echo "    FAIL T-006: no jetstream fileStore PVC (FR-B6-HELM-022)" >&2; ok=0; }
  grep -qE '^  monitor:[[:space:]]*$' "$NATS_VALUES"   || { echo "    FAIL T-006: no config.monitor block (FR-B6-HELM-023)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b66_l1_007_no_crate_repin() {
  local ok=1
  # No B.6.6 chart file may re-pin the client crates (single source = Cargo.toml).
  if grep -rqE '(temporalio-sdk|temporalio-client|async-nats)[[:space:]]*=[[:space:]]*"[0-9]' "$K8S_DIR" 2>/dev/null; then
    echo "    FAIL T-007: a crate pin leaked into infra/k8s (must live only in backend/Cargo.toml) (NFR-B6-HELM-002)" >&2; ok=0
  fi
  # Cargo.toml still pins the client SDK at 0.5.0 (untouched).
  grep -qE 'temporalio-sdk[[:space:]]*=[[:space:]]*"0\.5\.0"' "$CARGO" \
    || { echo "    FAIL T-007: backend/Cargo.toml.tmpl no longer pins temporalio-sdk = \"0.5.0\" (NFR-B6-HELM-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b66_l1_008_pins_single_sourced() {
  local ok=1
  grep -qF '1.5.0' "$TEMPORAL_README"  || { echo "    FAIL T-008: temporal README missing chart pin 1.5.0 (NFR-B6-HELM-001)" >&2; ok=0; }
  grep -qF '1.31.1' "$TEMPORAL_README" || { echo "    FAIL T-008: temporal README missing server appVersion 1.31.1 (NFR-B6-HELM-001)" >&2; ok=0; }
  grep -qF '2.14.2' "$NATS_README"     || { echo "    FAIL T-008: nats README missing chart/app pin 2.14.2 (NFR-B6-HELM-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b66_l1_009_compliance_docs() {
  local ok=1
  for rd in "$TEMPORAL_README" "$NATS_README" "$K8S_README"; do
    [ -f "$rd" ] || { echo "    FAIL T-009: README missing: ${rd#"$TPL_DIR/"} (FR-B6-HELM-040/041)" >&2; ok=0; continue; }
    grep -qE '\bT2\b' "$rd" && grep -qE '\bT3\b' "$rd" && grep -qiF 'self-host' "$rd" \
      || { echo "    FAIL T-009: ${rd#"$TPL_DIR/"} lacks T2/T3 self-host posture (FR-B6-HELM-040)" >&2; ok=0; }
  done
  # NATS README documents runtime durable-consumer / queue-group provisioning.
  grep -qiE 'queue[ -]?group|durable consumer|durable' "$NATS_README" \
    || { echo "    FAIL T-009: nats README lacks durable-consumer / queue-group docs (FR-B6-HELM-024)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b66_l1_010_scaffold_plan_coverage() {
  [ -f "$PLAN" ] || { echo "    FAIL T-010: scaffold-plan missing: $PLAN (FR-B6-HELM-050)" >&2; return 1; }
  local ok=1
  local sources=(
    "1.0.0/infra/k8s/README.md.tmpl"
    "1.0.0/infra/k8s/temporal-cluster/values-forge.yaml.tmpl"
    "1.0.0/infra/k8s/temporal-cluster/README.md.tmpl"
    "1.0.0/infra/k8s/nats-jetstream/values-forge.yaml.tmpl"
    "1.0.0/infra/k8s/nats-jetstream/README.md.tmpl"
  )
  for s in "${sources[@]}"; do
    grep -qF "$s" "$PLAN" || { echo "    FAIL T-010: scaffold-plan missing source $s (FR-B6-HELM-050)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b66_l1_011_no_committed_secrets() {
  local ok=1
  for v in "$TEMPORAL_VALUES" "$NATS_VALUES"; do
    [ -f "$v" ] || continue
    # No inline password:/token: keys — DB/auth secrets come from K8s Secrets.
    if grep -qE '^[[:space:]]*(password|token):[[:space:]]*\S' "$v"; then
      echo "    FAIL T-011: inline password/token value in ${v#"$TPL_DIR/"} (NFR-B6-HELM-003)" >&2; ok=0
    fi
  done
  [ "$ok" = "1" ]
}

_test_b66_l1_012_values_valid_yaml() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-012: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-012: PyYAML absent" >&2; return 0; }
  local out
  out=$(TEMPORAL_VALUES="$TEMPORAL_VALUES" NATS_VALUES="$NATS_VALUES" python3 - <<'PYEOF'
import os, yaml
for env in ("TEMPORAL_VALUES", "NATS_VALUES"):
    p = os.environ[env]
    try:
        with open(p, encoding="utf-8") as f:
            txt = f.read().replace("<project-name>", "demo")
        yaml.safe_load(txt)
    except Exception as e:
        print(f"BAD:{env}:{e}")
PYEOF
)
  if [ -n "$out" ]; then
    echo "    FAIL T-012: values overlay is not valid YAML after substitution: $out (NFR-B6-HELM-004)" >&2
    return 1
  fi
}

_test_b66_l1_013_schema_candidate_and_coupling() {
  # POST-PROMOTION (B.6.7 flip): the schema is now stage:stable / scaffoldable:true
  # (B.6.6 did not promote it — B.6.7 did). Inverted from the pre-flip candidate
  # assertion by b6-7-harness (function name kept for the T-013 manifest). The
  # coupling guard below (b6-2 stays GREEN) is unaffected by the promotion.
  local ok=1
  [ -f "$SCHEMA" ] || { echo "    FAIL T-013: schema missing: $SCHEMA (NFR-B6-HELM-005)" >&2; return 1; }
  grep -qE '^\s*stage:\s*stable' "$SCHEMA" || { echo "    FAIL T-013: schema stage != stable (expected the B.6.7 promotion) (NFR-B6-HELM-005)" >&2; ok=0; }
  grep -qE '^\s*scaffoldable:\s*true' "$SCHEMA" || { echo "    FAIL T-013: schema scaffoldable != true (expected the B.6.7 promotion) (NFR-B6-HELM-005)" >&2; ok=0; }
  # Coupling guard (exit-code only): the B.6.2 scaffold-plan/tree bijection stays GREEN.
  bash "$HARNESS_DIR/b6-2.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-013: b6-2.test.sh --level 1 is RED under the B.6.6 edit (tree<->plan bijection regression)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# ─── L2 (toolchain-gated: helm + upstream repos) ──────────────────────────────
_b66_render_overlay() {
  # _b66_render_overlay <release> <chart> <values-tmpl> — substitute <project-name>
  # then `helm template`. Returns helm's exit code.
  local rel="$1" chart="$2" tmpl="$3"
  local sub; sub="$(mktemp)"
  sed 's/<project-name>/demo/g' "$tmpl" > "$sub"
  helm template "$rel" "$chart" -f "$sub" >/dev/null 2>&1
  local rc=$?
  rm -f "$sub"
  return $rc
}

_test_b66_l2_001_helm_render() {
  have_helm || { echo "    SKIP T-L2-001: helm absent" >&2; return 0; }
  local rendered=0
  if helm show chart temporal/temporal >/dev/null 2>&1; then
    _b66_render_overlay t temporal/temporal "$TEMPORAL_VALUES" \
      || { echo "    FAIL T-L2-001: helm template of the Temporal overlay failed (NFR-B6-HELM-001)" >&2; return 1; }
    rendered=1
  fi
  if helm show chart nats/nats >/dev/null 2>&1; then
    _b66_render_overlay n nats/nats "$NATS_VALUES" \
      || { echo "    FAIL T-L2-001: helm template of the NATS overlay failed (NFR-B6-HELM-001)" >&2; return 1; }
    rendered=1
  fi
  [ "$rendered" = "1" ] || echo "    SKIP T-L2-001: upstream temporal/nats helm repos not added" >&2
  return 0
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.6.6 — b6-6-helm — level $LEVEL ──"
  run_test _test_b66_l1_001_tree_files
  run_test _test_b66_l1_002_temporal_four_roles
  run_test _test_b66_l1_003_temporal_postgres
  run_test _test_b66_l1_004_temporal_shards_schema
  run_test _test_b66_l1_005_temporal_no_removed_shapes
  run_test _test_b66_l1_006_nats_cluster_jetstream
  run_test _test_b66_l1_007_no_crate_repin
  run_test _test_b66_l1_008_pins_single_sourced
  run_test _test_b66_l1_009_compliance_docs
  run_test _test_b66_l1_010_scaffold_plan_coverage
  run_test _test_b66_l1_011_no_committed_secrets
  run_test _test_b66_l1_012_values_valid_yaml
  run_test _test_b66_l1_013_schema_candidate_and_coupling
  case "$LEVEL" in
    *2*) run_test _test_b66_l2_001_helm_render ;;
  esac
  print_summary
}

main
