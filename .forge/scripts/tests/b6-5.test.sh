#!/usr/bin/env bash
# Forge — B.6.5 event-driven-eu per-layer CI workflow templates harness
# <!-- Audit: B.6.5 (b6-5-ci-templates) — forge-events / forge-workflows / forge-infra -->
#
# TDD contract for the three per-layer CI workflow templates shipped by the
# event-driven-eu archetype (sibling of the full-stack-monorepo delivery.test.sh
# structural checks). The templates render INTO a scaffolded project's
# .github/workflows/; they are NOT this repo's own forge-ci.yml.
#
#   L1 (hermetic, grep/structure):
#     T-001  the three workflow .tmpl files exist under 1.0.0/.github/workflows
#     T-002  each parses as YAML with the right name + on:{pull_request,push}
#            (forge-workflows also has workflow_dispatch for the opt-in leg)
#     T-003  Task-target references: forge-events/forge-workflows run
#            `task backend:lint`; forge-infra runs `task asyncapi:validate`
#     T-004  temporal-sdk leg is OPT-IN + NON-BLOCKING (workflow_dispatch-gated);
#            the default saga gate runs `cargo test -p saga` (default features)
#     T-005  dorny/paths-filter@v3 scoping is correct per layer
#     T-006  crate scoping: forge-events -p events/-p eventstore; forge-workflows -p saga
#     T-007  Forge gates present + ordered (linter after verify); no
#            continue-on-error/if: always(); concurrency + permissions blocks present
#     T-008  forge-infra validates NATS config (-t), AsyncAPI, Postgres migration
#            with the archetype's pinned images (nats:2.10 / postgres:17)
#     T-009  the three files are registered in scaffold-plan.yaml (substitute:true)
#   L2 (toolchain-gated, skip when absent):
#     T-L2-001 render plan via overlay.sh → the three workflows land under
#              .github/workflows/*.yml, no .tmpl/<placeholder> survives, valid YAML

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
WORKFLOWS_DIR="$TPL_DIR/.github/workflows"
PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"
OVERLAY_SH="$FORGE_ROOT/.forge/scripts/scaffolder/overlay.sh"

EVENTS="$WORKFLOWS_DIR/forge-events.yml.tmpl"
WORKFLOWSF="$WORKFLOWS_DIR/forge-workflows.yml.tmpl"
INFRA="$WORKFLOWS_DIR/forge-infra.yml.tmpl"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b65_l1_001_files_exist() {
  local ok=1
  for f in "$EVENTS" "$WORKFLOWSF" "$INFRA"; do
    [ -f "$f" ] || { echo "    FAIL T-001: missing workflow template ${f#"$TPL_DIR/"} (FR-B6-CI-001)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b65_l1_002_yaml_shape() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-002: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-002: PyYAML absent" >&2; return 0; }
  EVENTS="$EVENTS" WORKFLOWSF="$WORKFLOWSF" INFRA="$INFRA" python3 - <<'PY'
import os, sys, yaml
# YAML 1.1: a bare `on:` key resolves to boolean True — accept either key.
def triggers(d):
    t = d.get('on', d.get(True, {}))
    return t if isinstance(t, dict) else ({} if t is None else {t: None} if isinstance(t, str) else {})
checks = [
    (os.environ['EVENTS'],    'forge-events',    ['pull_request', 'push']),
    (os.environ['WORKFLOWSF'],'forge-workflows', ['pull_request', 'push', 'workflow_dispatch']),
    (os.environ['INFRA'],     'forge-infra',     ['pull_request', 'push']),
]
ok = True
for path, name, need in checks:
    try:
        d = yaml.safe_load(open(path))
    except Exception as e:
        print(f"    FAIL T-002: {os.path.basename(path)} not valid YAML: {e}"); ok = False; continue
    if not isinstance(d, dict):
        print(f"    FAIL T-002: {os.path.basename(path)} root not a mapping"); ok = False; continue
    if d.get('name') != name:
        print(f"    FAIL T-002: {os.path.basename(path)} name={d.get('name')!r} != {name!r} (FR-B6-CI-002)"); ok = False
    tr = triggers(d)
    for ev in need:
        if ev not in tr:
            print(f"    FAIL T-002: {os.path.basename(path)} on: missing {ev} (FR-B6-CI-002/021)"); ok = False
sys.exit(0 if ok else 1)
PY
}

_test_b65_l1_003_task_targets() {
  local ok=1
  grep -qF 'task backend:lint' "$EVENTS"     || { echo "    FAIL T-003: forge-events missing 'task backend:lint' (FR-B6-CI-010)" >&2; ok=0; }
  grep -qF 'task backend:lint' "$WORKFLOWSF" || { echo "    FAIL T-003: forge-workflows missing 'task backend:lint' (FR-B6-CI-020)" >&2; ok=0; }
  grep -qF 'task asyncapi:validate' "$INFRA" || { echo "    FAIL T-003: forge-infra missing 'task asyncapi:validate' (FR-B6-CI-031)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b65_l1_004_temporal_optin_nonblocking() {
  local ok=1
  grep -qF -- '--features temporal-sdk' "$WORKFLOWSF" \
    || { echo "    FAIL T-004: forge-workflows missing opt-in '--features temporal-sdk' leg (FR-B6-CI-021)" >&2; ok=0; }
  grep -qE "github\.event_name[[:space:]]*==[[:space:]]*'workflow_dispatch'" "$WORKFLOWSF" \
    || { echo "    FAIL T-004: temporal-sdk leg not gated on workflow_dispatch (non-blocking) (FR-B6-CI-021, ADR-B6-CI-002)" >&2; ok=0; }
  grep -qE 'cargo (test|build).*-p[[:space:]]+saga' "$WORKFLOWSF" \
    || { echo "    FAIL T-004: default saga gate must run cargo -p saga (default features) (FR-B6-CI-020)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b65_l1_005_paths_filter() {
  local ok=1
  for f in "$EVENTS" "$WORKFLOWSF" "$INFRA"; do
    grep -qF 'dorny/paths-filter@v3' "$f" \
      || { echo "    FAIL T-005: ${f##*/} missing dorny/paths-filter@v3 (FR-B6-CI-003)" >&2; ok=0; }
  done
  grep -qF 'backend/events/**' "$EVENTS"      || { echo "    FAIL T-005: forge-events filter missing backend/events/** (FR-B6-CI-003)" >&2; ok=0; }
  grep -qF 'backend/eventstore/**' "$EVENTS"  || { echo "    FAIL T-005: forge-events filter missing backend/eventstore/** (FR-B6-CI-003)" >&2; ok=0; }
  grep -qF 'backend/saga/**' "$WORKFLOWSF"    || { echo "    FAIL T-005: forge-workflows filter missing backend/saga/** (FR-B6-CI-003)" >&2; ok=0; }
  grep -qF 'infra/**' "$INFRA"                || { echo "    FAIL T-005: forge-infra filter missing infra/** (FR-B6-CI-003)" >&2; ok=0; }
  grep -qF 'shared/asyncapi/**' "$INFRA"      || { echo "    FAIL T-005: forge-infra filter missing shared/asyncapi/** (FR-B6-CI-003)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b65_l1_006_crate_scoping() {
  local ok=1
  grep -qE '\-p[[:space:]]+events' "$EVENTS"      || { echo "    FAIL T-006: forge-events must be crate-scoped -p events (FR-B6-CI-010, ADR-B6-CI-001)" >&2; ok=0; }
  grep -qE '\-p[[:space:]]+eventstore' "$EVENTS"  || { echo "    FAIL T-006: forge-events must be crate-scoped -p eventstore (FR-B6-CI-010)" >&2; ok=0; }
  grep -qE '\-p[[:space:]]+saga' "$WORKFLOWSF"     || { echo "    FAIL T-006: forge-workflows must be crate-scoped -p saga (FR-B6-CI-020)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b65_l1_007_gates_and_failure_semantics() {
  local ok=1
  for f in "$EVENTS" "$WORKFLOWSF" "$INFRA"; do
    local base="${f##*/}"
    grep -qF '.forge/scripts/verify.sh' "$f"             || { echo "    FAIL T-007: $base missing verify.sh gate (FR-B6-CI-040)" >&2; ok=0; }
    grep -qF '.forge/scripts/constitution-linter.sh' "$f" || { echo "    FAIL T-007: $base missing constitution-linter.sh gate (FR-B6-CI-040)" >&2; ok=0; }
    # linter must appear AFTER verify (ordering)
    local vl ll
    vl=$(grep -n 'verify.sh' "$f" | tail -1 | cut -d: -f1)
    ll=$(grep -n 'constitution-linter.sh' "$f" | tail -1 | cut -d: -f1)
    { [ -n "$vl" ] && [ -n "$ll" ] && [ "$ll" -gt "$vl" ]; } \
      || { echo "    FAIL T-007: $base constitution-linter.sh must follow verify.sh (FR-B6-CI-040)" >&2; ok=0; }
    # failure semantics
    grep -qE 'continue-on-error[[:space:]]*:[[:space:]]*true' "$f" \
      && { echo "    FAIL T-007: $base uses forbidden continue-on-error: true (FR-B6-CI-041)" >&2; ok=0; }
    grep -qE 'if[[:space:]]*:[[:space:]]*always\(\)' "$f" \
      && { echo "    FAIL T-007: $base uses if: always() (no teardown workflow here) (FR-B6-CI-041)" >&2; ok=0; }
    # structural blocks
    grep -qE '^concurrency:' "$f"  || { echo "    FAIL T-007: $base missing concurrency block (FR-B6-CI-002)" >&2; ok=0; }
    grep -qE '^permissions:' "$f"  || { echo "    FAIL T-007: $base missing permissions block (FR-B6-CI-002)" >&2; ok=0; }
    grep -qF 'contents: read' "$f" || { echo "    FAIL T-007: $base missing 'permissions: contents: read' (FR-B6-CI-002)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b65_l1_008_infra_checks() {
  local ok=1
  grep -qF 'nats-server' "$INFRA"                 || { echo "    FAIL T-008: forge-infra missing nats-server config lint (FR-B6-CI-030)" >&2; ok=0; }
  grep -qE 'nats-server .*-t\b' "$INFRA"           || { echo "    FAIL T-008: forge-infra NATS lint must use the -t config-test flag (FR-B6-CI-030)" >&2; ok=0; }
  grep -qF 'infra/nats/jetstream.conf' "$INFRA"   || { echo "    FAIL T-008: forge-infra must reference infra/nats/jetstream.conf (FR-B6-CI-030)" >&2; ok=0; }
  grep -qF 'nats:2.10' "$INFRA"                   || { echo "    FAIL T-008: forge-infra must pin nats:2.10 image (NFR-B6-CI-003)" >&2; ok=0; }
  grep -qF 'infra/postgres/init-eventstore.sql' "$INFRA" || { echo "    FAIL T-008: forge-infra missing Postgres migration check (FR-B6-CI-032)" >&2; ok=0; }
  grep -qF 'psql' "$INFRA"                        || { echo "    FAIL T-008: forge-infra migration check must use psql (FR-B6-CI-032)" >&2; ok=0; }
  grep -qF 'postgres:17' "$INFRA"                 || { echo "    FAIL T-008: forge-infra must pin postgres:17 image (NFR-B6-CI-003, FR-B6-CI-032)" >&2; ok=0; }
  grep -qE ':latest\b' "$INFRA"                   && { echo "    FAIL T-008: forge-infra uses a :latest image tag (NFR-B6-CI-003)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b65_l1_009_plan_registration() {
  [ -f "$PLAN" ] || { echo "    FAIL T-009: scaffold-plan missing: $PLAN (FR-B6-CI-050)" >&2; return 1; }
  local ok=1
  for f in forge-events forge-workflows forge-infra; do
    grep -qF "1.0.0/.github/workflows/${f}.yml.tmpl" "$PLAN" \
      || { echo "    FAIL T-009: plan missing source 1.0.0/.github/workflows/${f}.yml.tmpl (FR-B6-CI-050)" >&2; ok=0; }
    grep -qF ".github/workflows/${f}.yml" "$PLAN" \
      || { echo "    FAIL T-009: plan missing target .github/workflows/${f}.yml (FR-B6-CI-050)" >&2; ok=0; }
  done
  # substitute:true must accompany the workflow entries (concurrency carries <project-name>)
  PLAN="$PLAN" python3 - <<'PY' 2>/dev/null || { echo "    FAIL T-009: workflow entries must be substitute:true (FR-B6-CI-050)" >&2; ok=0; }
import os, sys, yaml
p = yaml.safe_load(open(os.environ['PLAN']))
want = {f".github/workflows/{n}.yml" for n in ("forge-events","forge-workflows","forge-infra")}
seen = {e['target']: e.get('substitute') for e in p.get('templates', []) if e.get('target') in want}
sys.exit(0 if want <= set(seen) and all(seen[t] is True for t in want) else 1)
PY
  [ "$ok" = "1" ]
}

# ── L2 (toolchain-gated) ──────────────────────────────────────────
_b65_render_plan() {
  local out_dir="$1"
  local absplan; absplan="$(mktemp)"
  ARCHETYPE_DIR="$ARCHETYPE_DIR" PLAN="$PLAN" ABSPLAN="$absplan" python3 - <<'PY' || { rm -f "$absplan"; return 1; }
import os, yaml
arch = os.environ['ARCHETYPE_DIR']
with open(os.environ['PLAN']) as f:
    plan = yaml.safe_load(f)
for e in plan.get('templates', []):
    s = e.get('source', '')
    if s and not os.path.isabs(s):
        e['source'] = os.path.join(arch, s)
with open(os.environ['ABSPLAN'], 'w') as f:
    yaml.safe_dump(plan, f, sort_keys=False)
PY
  SOURCE_DATE_EPOCH=0 bash "$OVERLAY_SH" --target "$out_dir" --project-name probe \
    --reverse-domain example.com --plan "$absplan" --force >/dev/null 2>&1
  local rc=$?
  rm -f "$absplan"
  return $rc
}

_test_b65_l2_001_render_clean() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-001: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-L2-001: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-L2-001: plan absent" >&2; return 0; }
  [ -f "$OVERLAY_SH" ] || { echo "    SKIP T-L2-001: overlay.sh absent" >&2; return 0; }
  local work; work="$(mktemp -d)"
  local out="$work/r1"
  _b65_render_plan "$out" || { echo "    FAIL T-L2-001: overlay render failed (FR-B6-CI-001)" >&2; rm -rf "$work"; return 1; }
  local ok=1
  local wfdir="$out/.github/workflows"
  for f in forge-events forge-workflows forge-infra; do
    [ -f "$wfdir/$f.yml" ] || { echo "    FAIL T-L2-001: rendered $f.yml missing (FR-B6-CI-001)" >&2; ok=0; }
  done
  [ -z "$(find "$wfdir" -name '*.tmpl' 2>/dev/null)" ] || { echo "    FAIL T-L2-001: .tmpl survived render under .github/workflows (FR-B6-CI-001)" >&2; ok=0; }
  ! grep -rqE '<(project-name|reverse-domain|root-module)>' "$wfdir" 2>/dev/null || { echo "    FAIL T-L2-001: unsubstituted <placeholder> in rendered workflow (FR-B6-CI-001)" >&2; ok=0; }
  # each rendered workflow parses as YAML
  WFDIR="$wfdir" python3 - <<'PY' || { echo "    FAIL T-L2-001: a rendered workflow is not valid YAML (FR-B6-CI-001)" >&2; ok=0; }
import os, sys, yaml
d = os.environ['WFDIR']
bad = 0
for n in ("forge-events","forge-workflows","forge-infra"):
    try:
        yaml.safe_load(open(os.path.join(d, f"{n}.yml")))
    except Exception as e:
        print(f"    {n}.yml: {e}"); bad = 1
sys.exit(bad)
PY
  rm -rf "$work"
  [ "$ok" = "1" ]
}

main() {
  echo "── B.6.5 — b6-5-ci-templates — level $LEVEL ──"
  run_test _test_b65_l1_001_files_exist
  run_test _test_b65_l1_002_yaml_shape
  run_test _test_b65_l1_003_task_targets
  run_test _test_b65_l1_004_temporal_optin_nonblocking
  run_test _test_b65_l1_005_paths_filter
  run_test _test_b65_l1_006_crate_scoping
  run_test _test_b65_l1_007_gates_and_failure_semantics
  run_test _test_b65_l1_008_infra_checks
  run_test _test_b65_l1_009_plan_registration
  case "$LEVEL" in
    *2*) run_test _test_b65_l2_001_render_clean ;;
  esac
  print_summary
}

main
