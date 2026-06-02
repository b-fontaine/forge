#!/usr/bin/env bash
# Forge — B.8.7 Zitadel 2.0.0 identity-brick harness
# <!-- Audit: B.8.7 (b8-7-zitadel) — 2.0.0 identity template brick gate -->
#
# Validates the b8-7-zitadel deliverables (design.md § Testing Strategy +
# specs.md Spec Delta ADR-B87-001 — chart-referenced hybrid, 4-file subtree,
# NO kustomization.yaml.tmpl):
#
#   T-001  2.0.0/infra/zitadel/values-forge.yaml.tmpl exists                       (FR-B87-071, ADR-B87-001)
#   T-002  2.0.0/infra/zitadel/README.md.tmpl exists                               (FR-B87-071, FR-B87-003)
#   T-003  2.0.0/infra/zitadel/docker-compose.fragment.yml.tmpl exists             (FR-B87-071, FR-B87-031)
#   T-004  2.0.0/infra/zitadel/bootstrap.md.tmpl exists                            (FR-B87-071, ADR-B87-003)
#   T-005  values-forge.yaml.tmpl carries both Aegis sentinels + NO MachineKeyPath/PatPath (FR-B87-074, FR-B87-006, P-18)
#   T-006  no plaintext secret value in any file under 2.0.0/infra/zitadel/        (FR-B87-073, NFR-B87-004)
#   T-007  README.md.tmpl OIDC-delegation section + scope-out phrase + AGPL note   (FR-B87-063/064, FR-B87-062, ADR-B87-006)
#   T-008  identity.yaml version: "1.1.0" + versions: map (zitadel_chart + zitadel) (FR-B87-075, ADR-B87-005)
#   T-009  REVIEW.md row referencing identity.yaml + 1.1.0 (FR-J7-023 anchor)      (FR-B87-076)
#   T-010  2.0.0.yaml zitadel delivered annotation + delta additive-first intact   (FR-B87-077, FR-B87-050/052)
#   T-011  coupling guard: b8-3 (17/17) + b8-3b (12/12) stay GREEN (exit-code)     (NFR-B87-003, FR-B87-078)
#   T-012  CHANGELOG.md has a b8-7-zitadel entry (whole-file grep)                 (FR-B87-079, NFR-B87-001)
#
# 12 L1 tests. Budget L1 ≤ 2 s, zero net/Docker/Helm. The live chart/image
# verify-then-pin is a /forge:implement step, NOT an L1 assertion. T-011 is
# exit-code only (the b8-4/b8-5/b8-6 coupling strategy) — keeps the coupling
# guard within budget. Mirrors b8-6.test.sh structure (--level flag + _helpers.sh).

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
# 2.0.0 identity subtree (the B.8.7 deliverable — chart-referenced hybrid).
ZITADEL_DIR="$TEMPLATE_ROOT/2.0.0/infra/zitadel"
VALUES_20="$ZITADEL_DIR/values-forge.yaml.tmpl"
ZITADEL_README="$ZITADEL_DIR/README.md.tmpl"
COMPOSE_20="$ZITADEL_DIR/docker-compose.fragment.yml.tmpl"
BOOTSTRAP_20="$ZITADEL_DIR/bootstrap.md.tmpl"

STANDARDS_DIR="$FORGE_ROOT/.forge/standards"
IDENTITY_STD="$STANDARDS_DIR/identity.yaml"
REVIEW_MD="$STANDARDS_DIR/REVIEW.md"

SCHEMA_20="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/2.0.0.yaml"
CHANGELOG="$FORGE_ROOT/CHANGELOG.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b87_l1_001_values_overlay_present() {
  [ -f "$VALUES_20" ] \
    || { echo "    FAIL T-001: missing values-forge.yaml.tmpl under $ZITADEL_DIR (FR-B87-071, ADR-B87-001)" >&2; return 1; }
}

_test_b87_l1_002_readme_present() {
  [ -f "$ZITADEL_README" ] \
    || { echo "    FAIL T-002: missing README.md.tmpl under $ZITADEL_DIR (FR-B87-071, FR-B87-003)" >&2; return 1; }
}

_test_b87_l1_003_compose_fragment_present() {
  [ -f "$COMPOSE_20" ] \
    || { echo "    FAIL T-003: missing docker-compose.fragment.yml.tmpl under $ZITADEL_DIR (FR-B87-071, FR-B87-031)" >&2; return 1; }
}

_test_b87_l1_004_bootstrap_doc_present() {
  [ -f "$BOOTSTRAP_20" ] \
    || { echo "    FAIL T-004: missing bootstrap.md.tmpl under $ZITADEL_DIR (FR-B87-071, ADR-B87-003)" >&2; return 1; }
}

_test_b87_l1_005_aegis_sentinels_and_no_chart_managed_keys() {
  if [ ! -f "$VALUES_20" ]; then
    echo "    FAIL T-005: values-forge.yaml.tmpl missing: $VALUES_20 (FR-B87-074)" >&2; return 1
  fi
  local ok=1
  # Both Aegis annotation sentinels (FR-B87-006; mirrors obi-daemonset.yaml.tmpl).
  grep -qF 'forge.dev/aegis-audit: "required"' "$VALUES_20" \
    || { echo "    FAIL T-005: values-forge.yaml.tmpl missing forge.dev/aegis-audit: \"required\" (FR-B87-006/074)" >&2; ok=0; }
  grep -qF 'forge.dev/standard: "identity.yaml@1.1.0"' "$VALUES_20" \
    || { echo "    FAIL T-005: values-forge.yaml.tmpl missing forge.dev/standard: \"identity.yaml@1.1.0\" (FR-B87-006/074)" >&2; ok=0; }
  # The masterkeySecretName key-presence sentinel (Spec Delta FR-B87-072).
  grep -qF 'masterkeySecretName' "$VALUES_20" \
    || { echo "    FAIL T-005: values-forge.yaml.tmpl missing masterkeySecretName key (Spec Delta FR-B87-072)" >&2; ok=0; }
  # CHART-MANAGED keys MUST NOT be set (evidence.md P-18/Finding 8: setting
  # MachineKeyPath/PatPath manually causes the deployment to fail). Guard against
  # an active YAML key (allow them in comments documenting the prohibition).
  if grep -qE '^[[:space:]]*MachineKeyPath:' "$VALUES_20"; then
    echo "    FAIL T-005: values-forge.yaml.tmpl sets MachineKeyPath: — CHART-MANAGED, must NOT be set (P-18, Finding 8)" >&2; ok=0
  fi
  if grep -qE '^[[:space:]]*PatPath:' "$VALUES_20"; then
    echo "    FAIL T-005: values-forge.yaml.tmpl sets PatPath: — CHART-MANAGED, must NOT be set (P-18, Finding 8)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b87_l1_006_no_secret_values() {
  if [ ! -d "$ZITADEL_DIR" ]; then
    # Subtree absent (RED baseline) → no secrets either → PASS (design.md T-006 note).
    return 0
  fi
  # No literal password/masterkey VALUE in any subtree file. A value is a
  # `password:`/`masterkey:` followed by a non-reference, non-comment, non-empty
  # char. Env-var refs (${...}), secretKeyRef placeholders, warnings (NEVER),
  # comments (#), and template vars (<...>) are allowed.
  local hits
  hits=$(grep -rnE '(password|masterkey)[[:space:]]*:[[:space:]]*[^$#{<[:space:]"]' "$ZITADEL_DIR" 2>/dev/null \
    | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' \
    | grep -viE 'NEVER|secretKeyRef|valueFrom|<[a-z-]+>|generated|deploy[- ]time|placeholder' \
    || true)
  if [ -n "$hits" ]; then
    echo "    FAIL T-006: possible plaintext secret value(s) in $ZITADEL_DIR (FR-B87-073, NFR-B87-004):" >&2
    printf '%s\n' "$hits" | sed 's/^/      /' >&2
    return 1
  fi
}

_test_b87_l1_007_readme_oidc_agpl_scopeout() {
  if [ ! -f "$ZITADEL_README" ]; then
    echo "    FAIL T-007: README.md.tmpl missing: $ZITADEL_README (FR-B87-063)" >&2; return 1
  fi
  local ok=1
  # OIDC delegation section (FR-B87-063).
  grep -qiE 'OIDC|Envoy' "$ZITADEL_README" \
    || { echo "    FAIL T-007: README.md.tmpl has no OIDC/Envoy delegation section (FR-B87-063)" >&2; ok=0; }
  # Explicit scope-out phrase (FR-B87-064).
  grep -qE 'NOT shipped in this brick|deferred to B\.8\.10' "$ZITADEL_README" \
    || { echo "    FAIL T-007: README.md.tmpl missing scope-out phrase ('NOT shipped in this brick'/'deferred to B.8.10') (FR-B87-064)" >&2; ok=0; }
  # AGPL licensing note (FR-B87-062).
  grep -qF 'AGPL' "$ZITADEL_README" \
    || { echo "    FAIL T-007: README.md.tmpl missing AGPL licensing note (FR-B87-062)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b87_l1_008_identity_version_and_versions_block() {
  if [ ! -f "$IDENTITY_STD" ]; then
    echo "    FAIL T-008: identity.yaml missing: $IDENTITY_STD (FR-B87-075)" >&2; return 1
  fi
  local ok=1
  # version: field is "1.1.0" (additive bump, ADR-B87-005).
  grep -qE '^version:[[:space:]]*"1\.1\.0"' "$IDENTITY_STD" \
    || { echo "    FAIL T-008: identity.yaml version: field is not \"1.1.0\" (FR-B87-040, ADR-B87-005)" >&2; ok=0; }
  # First versions: map present with at least zitadel_chart + zitadel keys.
  grep -qE '^versions:' "$IDENTITY_STD" \
    || { echo "    FAIL T-008: identity.yaml has no top-level versions: map (FR-B87-041, ADR-B87-005)" >&2; ok=0; }
  grep -qE '^[[:space:]]+zitadel_chart:' "$IDENTITY_STD" \
    || { echo "    FAIL T-008: identity.yaml versions: missing 'zitadel_chart:' key (FR-B87-041)" >&2; ok=0; }
  grep -qE '^[[:space:]]+zitadel:' "$IDENTITY_STD" \
    || { echo "    FAIL T-008: identity.yaml versions: missing 'zitadel:' key (FR-B87-041)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b87_l1_009_review_md_row() {
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    FAIL T-009: REVIEW.md missing: $REVIEW_MD (FR-B87-076)" >&2; return 1
  fi
  # FR-J7-023 anchor: the REVIEW.md cell is the BARE basename + version 1.1.0.
  grep -qE '\|[[:space:]]*identity\.yaml[[:space:]]*\|[[:space:]]*1\.1\.0[[:space:]]*\|' "$REVIEW_MD" \
    || { echo "    FAIL T-009: REVIEW.md has no '| identity.yaml | 1.1.0 |' ledger row (basename anchor, FR-J7-023)" >&2; return 1; }
}

_test_b87_l1_010_schema_annotation_and_delta() {
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
c = next((c for c in comps if isinstance(c, dict) and c.get('name') == 'zitadel'), None)
if c is None:
    print("NO_ZITADEL"); sys.exit(0)
std = c.get('standard', 'MISSING')
resolves = os.path.isfile(os.path.join(std_dir, std)) if isinstance(std, str) and std != 'MISSING' else False
forbidden = {'version', 'pin', 'image'}
pin = ','.join(sorted(set(c.keys()) & forbidden)) or 'NONE'
deltas = d.get('migration_deltas', []) if isinstance(d, dict) else []
delta = next((x for x in deltas if isinstance(x, dict) and x.get('to') == 'zitadel'), None)
strat = (delta or {}).get('strategy', 'MISSING') if delta else 'NO_DELTA'
print(f"standard={std}")
print(f"resolves={resolves}")
print(f"pin={pin}")
print(f"strategy={strat}")
PY
)
  case "$out" in
    ERR:*)      echo "    FAIL T-010: 2.0.0.yaml parse error — ${out#ERR:} (FR-B87-050)" >&2; return 1 ;;
    NO_ZITADEL) echo "    FAIL T-010: no zitadel component in 2.0.0.yaml (FR-B87-050)" >&2; return 1 ;;
  esac
  local std res pin strat ok=1
  std=$(printf '%s' "$out" | grep '^standard=' | cut -d= -f2-)
  res=$(printf '%s' "$out" | grep '^resolves=' | cut -d= -f2-)
  pin=$(printf '%s' "$out" | grep '^pin=' | cut -d= -f2-)
  strat=$(printf '%s' "$out" | grep '^strategy=' | cut -d= -f2-)
  [ "$std" = "identity.yaml" ] || { echo "    FAIL T-010: zitadel comp standard='$std' != 'identity.yaml' (FR-B87-050)" >&2; ok=0; }
  [ "$res" = "True" ]          || { echo "    FAIL T-010: identity.yaml ref does not resolve (re-asserts b8-3 T-011) (FR-B87-077)" >&2; ok=0; }
  [ "$pin" = "NONE" ]          || { echo "    FAIL T-010: zitadel comp carries forbidden inline-pin key(s): $pin (FR-B87-051)" >&2; ok=0; }
  [ "$strat" = "additive-first" ] || { echo "    FAIL T-010: implicit-auth->zitadel delta strategy='$strat' != 'additive-first' (FR-B87-052)" >&2; ok=0; }
  # The delivered annotation comment must be present (FR-B87-053).
  grep -qE 'B\.8\.7.*delivered|delivered.*B\.8\.7' "$SCHEMA_20" \
    || { echo "    FAIL T-010: 2.0.0.yaml has no 'B.8.7 delivered' annotation comment (FR-B87-053)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b87_l1_011_sibling_harness_coupling() {
  # Exit-code-only coupling guard (NO output parse — keeps T-011 within the
  # ≤ 2 s L1 budget, the b8-4/b8-5/b8-6 coupling strategy). b8-3 (17/17) +
  # b8-3b (12/12) MUST stay GREEN under the B.8.7 edits.
  bash "$HARNESS_DIR/b8-3.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-011: b8-3.test.sh --level 1 is RED under the B.8.7 edit (NFR-B87-003 coupling regression)" >&2; return 1; }
  bash "$HARNESS_DIR/b8-3b.test.sh" --level 1 >/dev/null 2>&1 \
    || { echo "    FAIL T-011: b8-3b.test.sh --level 1 is RED under the B.8.7 edit (NFR-B87-003 coupling regression)" >&2; return 1; }
}

_test_b87_l1_012_changelog_entry() {
  if [ ! -f "$CHANGELOG" ]; then
    echo "    FAIL T-012: CHANGELOG.md missing: $CHANGELOG (FR-B87-079)" >&2; return 1
  fi
  # A B.8.7 entry must exist (grep the whole file per the changelog-test
  # [Unreleased]-coupling lesson — survives release graduation). Anchored on
  # the change NAME `b8-7-zitadel` (not the bare "B.8.7" string, which a sibling
  # entry could mention in prose — that would false-pass).
  if ! grep -qF 'b8-7-zitadel' "$CHANGELOG"; then
    echo "    FAIL T-012: CHANGELOG.md has no b8-7-zitadel entry (FR-B87-079)" >&2
    return 1
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.8.7 — b8-7-zitadel — level $LEVEL ──"
  run_test _test_b87_l1_001_values_overlay_present
  run_test _test_b87_l1_002_readme_present
  run_test _test_b87_l1_003_compose_fragment_present
  run_test _test_b87_l1_004_bootstrap_doc_present
  run_test _test_b87_l1_005_aegis_sentinels_and_no_chart_managed_keys
  run_test _test_b87_l1_006_no_secret_values
  run_test _test_b87_l1_007_readme_oidc_agpl_scopeout
  run_test _test_b87_l1_008_identity_version_and_versions_block
  run_test _test_b87_l1_009_review_md_row
  run_test _test_b87_l1_010_schema_annotation_and_delta
  run_test _test_b87_l1_011_sibling_harness_coupling
  run_test _test_b87_l1_012_changelog_entry
  print_summary
}

main
