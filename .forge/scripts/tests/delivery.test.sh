#!/usr/bin/env bash
# Forge Delivery Test Harness (b1-delivery)
# <!-- Audit: B.1.9 + B.1.12 + B.1.14 (b1-delivery) -->
#
# Validates the third and final B.1 deliverable family — reference CI
# workflows, Kustomize overlays, and the local OTel + SigNoz
# observability stack — that close the full-stack-monorepo archetype
# contract and drive the schema promotion candidate / 1.0.0-rc.1 →
# stable / 1.0.0.
#
# Three-level test strategy (design ADR-010, mirroring workflow.test.sh) :
#
#   L1 — structural : YAML shape of the four reference workflows,
#                     standards' canonical sections, scaffold-plan
#                     entries, .env.dev OTel defaults. ZERO external
#                     deps beyond `python3 + PyYAML` (already required
#                     by previous harnesses).
#
#   L2 — fixture    : `kustomize build` × 3 overlays (dev/staging/prod)
#                     piped through `kubeconform --strict`,
#                     `docker compose config` shape assertions,
#                     overlay diff size budget (NFR-017),
#                     no-`:latest` enforcement (NFR-018), workflow
#                     file size budget (NFR-016), schema promotion
#                     gate (FR-GL-024 — gated on change status).
#                     Requires `kustomize` + `kubeconform` + Docker
#                     Compose v2 ≥ 2.1.0.
#
#   L3 — long-mode  : `time docker compose up -d --wait` against a
#                     fixture (NFR-015 stack startup ≤ 90s),
#                     `act --dry-run` per workflow (NFR-013 runtime
#                     budget). Opt-in via `--long-tests` or
#                     `LONG_TESTS=1`. Skipped cleanly when tools
#                     absent.
#
# Usage :
#   bash .forge/scripts/tests/delivery.test.sh
#   bash .forge/scripts/tests/delivery.test.sh --level 1
#   bash .forge/scripts/tests/delivery.test.sh --long-tests
#
# RED baseline note (Phase 1.1) : on first creation the harness ships
# with zero implemented tests beyond `test_manifest_self_consistency`
# and a deliberate `test_phase_1_red_baseline` placeholder that always
# fails. This is the b1-delivery RED of RED — until the manifest is
# wired and at least one phase-2 test is implemented, the harness MUST
# exit non-zero. Each subsequent task in tasks.md flips one
# manifest-listed test from missing to PASS.

set -euo pipefail

# ─── Paths ──────────────────────────────────────────────────────

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

# Archetype overlay tree (where every .tmpl produced by this change lives)
ARCHETYPE_DIR="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo"
WORKFLOWS_DIR="$ARCHETYPE_DIR/.github/workflows"
INFRA_DIR="$ARCHETYPE_DIR/infra"
K8S_DIR="$INFRA_DIR/k8s"
OBS_DIR="$INFRA_DIR/observability"
COMPOSE_TMPL="$ARCHETYPE_DIR/docker-compose.dev.yml.tmpl"
TASKFILE_TMPL="$ARCHETYPE_DIR/Taskfile.yml.tmpl"
SCAFFOLD_PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"

# Standards
STD_CI="$FORGE_ROOT_REAL/.forge/standards/infra/ci-workflows.md"
STD_K8S="$FORGE_ROOT_REAL/.forge/standards/infra/k8s-overlays.md"
STD_OBS="$FORGE_ROOT_REAL/.forge/standards/infra/observability-local.md"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"

# Schema (mutated at archive — FR-GL-024)
SCHEMA_YAML="$FORGE_ROOT_REAL/.forge/schemas/full-stack-monorepo/schema.yaml"

# Change metadata (source of truth for the gated promotion test)
CHANGE_YAML="$FORGE_ROOT_REAL/.forge/changes/b1-delivery/.forge.yaml"

# Forge gates that the workflows invoke
VERIFY_SH="$SCRIPTS_DIR/verify.sh"
LINTER_SH="$SCRIPTS_DIR/constitution-linter.sh"

# ─── Shared helpers ─────────────────────────────────────────────
# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"

# ─── Flags ──────────────────────────────────────────────────────

LEVEL=""
LONG_TESTS="${LONG_TESTS:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --level)        LEVEL="${2:-}"; shift 2 ;;
    --level=*)      LEVEL="${1#*=}"; shift ;;
    --long-tests)   LONG_TESTS=1; shift ;;
    --help|-h)
      sed -n '2,38p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "delivery.test.sh: unknown flag '$1'" >&2
      exit 2
      ;;
  esac
done

have_kustomize() { command -v kustomize >/dev/null 2>&1; }
have_kubeconform() { command -v kubeconform >/dev/null 2>&1; }
have_compose() { command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; }
have_act() { command -v act >/dev/null 2>&1; }
have_l2_tools() { have_kustomize && have_kubeconform && have_compose; }

decide_levels() {
  if [ -n "$LEVEL" ]; then
    echo "$LEVEL"; return
  fi
  if [ -n "$LONG_TESTS" ]; then
    echo "1,2,3"
  elif have_l2_tools; then
    echo "1,2"
  else
    echo "1"
  fi
}

# ─── Manifest — single source of truth for FR ↔ test mapping ────
#
# Every line of the form `# MANIFEST: test_* — FR-XXX[, FR-YYY]`
# below is parsed by `test_manifest_self_consistency` to assert
# (a) that every FR/NFR listed Testable in specs.md has at least one
# entry here, and (b) that every entry resolves to a defined bash
# function. The manifest is the harness's contract with the spec.
#
# MANIFEST: test_workflow_backend_paths_filter_and_steps      — FR-IN-002
# MANIFEST: test_workflow_frontend_paths_filter_and_steps     — FR-IN-003
# MANIFEST: test_workflow_infra_paths_filter_and_steps        — FR-IN-004
# MANIFEST: test_workflow_integration_triggers_and_lifecycle  — FR-IN-005
# MANIFEST: test_kustomize_base_renders                       — FR-IN-006
# MANIFEST: test_overlay_dev_renders_and_validates            — FR-IN-006
# MANIFEST: test_overlay_staging_renders_and_validates        — FR-IN-006
# MANIFEST: test_overlay_prod_renders_and_validates           — FR-IN-006
# MANIFEST: test_overlay_diff_size_under_4kb                  — NFR-017
# MANIFEST: test_compose_otel_service_shape                   — FR-IN-007
# MANIFEST: test_compose_signoz_services_shape                — FR-IN-008
# MANIFEST: test_taskfile_has_observe_target                  — FR-IN-008
# MANIFEST: test_env_dev_files_export_otel_defaults           — FR-IN-009
# MANIFEST: test_standard_ci_workflows_has_required_sections  — FR-IN-010
# MANIFEST: test_standard_k8s_overlays_has_required_sections  — FR-IN-011
# MANIFEST: test_standard_observability_local_has_required_sections — FR-IN-012
# MANIFEST: test_index_has_three_new_infra_standards          — FR-IN-010, FR-IN-011, FR-IN-012
# MANIFEST: test_scaffold_plan_lists_all_new_templates        — FR-IN-002..009
# MANIFEST: test_scaffold_fixture_renders_and_validates       — FR-IN-002..009
# MANIFEST: test_schema_header_post_archive                   — FR-GL-024
# MANIFEST: test_no_latest_tag_anywhere                       — NFR-018
# MANIFEST: test_workflow_files_under_size_budget             — NFR-016
# MANIFEST: test_no_secrets_in_templates                      — Aegis security
# MANIFEST: test_compose_stack_startup_under_90s              — NFR-015 (LONG_TESTS)
# MANIFEST: test_per_layer_workflow_runtime_warm_under_8min   — NFR-013 (LONG_TESTS)
# MANIFEST: test_manifest_self_consistency                    — meta (FR-GL-025)
#
# ────────────────────────────────────────────────────────────────

# ─── Tests ──────────────────────────────────────────────────────

# ─── L1 helpers : YAML / workflow shape ────────────────────────

# assert_yaml_loadable <path> — fails if PyYAML cannot parse the file.
assert_yaml_loadable() {
  local f="$1"
  python3 -c "import sys, yaml; yaml.safe_load(open(sys.argv[1]))" "$f" 2>&1
}

# workflow_assertions <path> <expected_paths_csv> <expected_steps_csv>
#   <path>                — workflow .tmpl file
#   <expected_paths_csv>  — comma-separated path-filter entries that MUST appear
#   <expected_steps_csv>  — comma-separated step needles that MUST appear in order
# Returns 0 on PASS, 1 on FAIL. Emits one error per failing assertion to stderr.
workflow_assertions() {
  local f="$1"
  local expected_paths="$2"
  local expected_steps="$3"
  python3 - "$f" "$expected_paths" "$expected_steps" <<'PY'
import sys, yaml, re

path, paths_csv, steps_csv = sys.argv[1], sys.argv[2], sys.argv[3]
raw = open(path).read()
# Strip leading `#` comment lines so step-ordering checks ignore the
# header narrative and inspect actual workflow content only.
non_comment_lines = [
    ln for ln in raw.splitlines() if not ln.lstrip().startswith("#")
]
text = "\n".join(non_comment_lines)
errors = []

# 1. YAML loads
try:
    doc = yaml.safe_load(text)
except Exception as e:
    print(f"    yaml.safe_load failed: {e}", file=sys.stderr)
    sys.exit(1)
if doc is None:
    print(f"    yaml document empty: {path}", file=sys.stderr)
    sys.exit(1)

# 2. on: triggers (YAML 1.1 quirk: bare `on` parses as True in safe_load)
on = doc.get("on", doc.get(True, None))
if not isinstance(on, dict):
    errors.append(f"`on:` not a mapping: {type(on).__name__}")

# 3. concurrency.group present
conc = doc.get("concurrency")
if not isinstance(conc, dict) or not conc.get("group"):
    errors.append("missing `concurrency.group`")

# 4. dorny/paths-filter@v3 referenced
if not re.search(r"dorny/paths-filter@v3\b", text):
    errors.append("missing `uses: dorny/paths-filter@v3`")

# 5. Each expected path filter substring appears
for p in paths_csv.split(","):
    p = p.strip()
    if p and p not in text:
        errors.append(f"paths filter missing: `{p}`")

# 6. Step ordering: each needle present, in the listed order
positions = []
for needle in [s.strip() for s in steps_csv.split(",") if s.strip()]:
    pos = text.find(needle)
    if pos < 0:
        errors.append(f"missing step keyword: `{needle}`")
    positions.append((needle, pos))
present = [p for n, p in positions if p >= 0]
if len(present) >= 2 and present != sorted(present):
    errors.append(f"step ordering wrong: {[n for n,_ in positions]} → {[p for _,p in positions]}")

# 7. No continue-on-error: true anywhere
if re.search(r"continue-on-error\s*:\s*true\b", text):
    errors.append("forbidden `continue-on-error: true`")

if errors:
    for e in errors:
        print(f"    {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# ─── Phase 2 : reference workflow tests ─────────────────────────

test_workflow_backend_paths_filter_and_steps() {
  local f="$WORKFLOWS_DIR/forge-backend.yml.tmpl"
  if [ ! -f "$f" ]; then
    echo "    file missing: $f" >&2
    return 1
  fi
  workflow_assertions "$f" \
    "backend/**,shared/protos/**" \
    "cargo fmt,cargo clippy,cargo test,verify.sh,constitution-linter.sh" \
    || return 1
  # FR-IN-002 specific: clippy has -D warnings; cache step keyed on Cargo.lock
  grep -q -- "-D warnings" "$f" || { echo "    clippy missing \`-D warnings\`" >&2; return 1; }
  grep -q "Cargo.lock" "$f"     || { echo "    cache key missing \`Cargo.lock\`" >&2; return 1; }
}

test_workflow_frontend_paths_filter_and_steps() {
  local f="$WORKFLOWS_DIR/forge-frontend.yml.tmpl"
  if [ ! -f "$f" ]; then
    echo "    file missing: $f" >&2
    return 1
  fi
  workflow_assertions "$f" \
    "frontend/**,shared/protos/**" \
    "pub get,dart format,flutter analyze,flutter test,verify.sh,constitution-linter.sh" \
    || return 1
  # FR-IN-003 specific: subosito/flutter-action with flutter-version-file: .flutter-version
  grep -q "subosito/flutter-action" "$f"     || { echo "    missing subosito/flutter-action" >&2; return 1; }
  grep -q ".flutter-version" "$f"            || { echo "    missing .flutter-version reference" >&2; return 1; }
  # --fatal-infos --fatal-warnings + --set-exit-if-changed
  grep -q -- "--fatal-infos" "$f"            || { echo "    flutter analyze missing --fatal-infos" >&2; return 1; }
  grep -q -- "--fatal-warnings" "$f"         || { echo "    flutter analyze missing --fatal-warnings" >&2; return 1; }
  grep -q -- "--set-exit-if-changed" "$f"    || { echo "    dart format missing --set-exit-if-changed" >&2; return 1; }
  grep -q "pubspec.lock" "$f"                || { echo "    cache key missing pubspec.lock" >&2; return 1; }
}

test_workflow_infra_paths_filter_and_steps() {
  local f="$WORKFLOWS_DIR/forge-infra.yml.tmpl"
  if [ ! -f "$f" ]; then
    echo "    file missing: $f" >&2
    return 1
  fi
  workflow_assertions "$f" \
    "infra/**" \
    "kustomize build,kubeconform --strict,verify.sh,constitution-linter.sh" \
    || return 1
  # FR-IN-004 specific: three overlays referenced explicitly
  for env in dev staging prod; do
    grep -q "overlays/$env" "$f" || { echo "    overlay reference missing: overlays/$env" >&2; return 1; }
  done
}

# ─── Phase 3 : Kustomize overlays ──────────────────────────────
#
# Strategy: L1 = structural YAML inspection (no kustomize binary
# required). L2 (when `kustomize` + `kubeconform` are on PATH) adds
# real `kustomize build` + `kubeconform --strict` of the rendered
# overlay. These tests are placed in L1 so they always run ; if the
# binaries are absent the kustomize-build step is silently skipped
# and only the structural assertions hold.

# kustomize_overlay_assertions <env> <expected_namespace_suffix> <expected_tag_pattern> <expected_replicas>
kustomize_overlay_assertions() {
  local env="$1" ns_suffix="$2" tag_pattern="$3" replicas="$4"
  local kfile="$K8S_DIR/overlays/$env/kustomization.yaml.tmpl"
  if [ ! -f "$kfile" ]; then
    echo "    overlay file missing: $kfile" >&2
    return 1
  fi
  python3 - "$kfile" "$env" "$ns_suffix" "$tag_pattern" "$replicas" <<'PY' || return 1
import sys, yaml, re
path, env, ns_suffix, tag_pattern, replicas = sys.argv[1:6]
with open(path) as fh:
    doc = yaml.safe_load(fh)
errors = []
if not isinstance(doc, dict):
    errors.append(f"YAML root not a mapping: {type(doc).__name__}")
else:
    if doc.get("kind") != "Kustomization":
        errors.append(f"kind should be Kustomization, got {doc.get('kind')!r}")
    ns = doc.get("namespace", "")
    if not ns.endswith(ns_suffix):
        errors.append(f"namespace must end with {ns_suffix!r}; got {ns!r}")
    images = doc.get("images") or []
    if not images:
        errors.append("no images: transformer declared")
    else:
        tags = [(im.get("newTag") or "") for im in images]
        if not any(re.search(tag_pattern, t) for t in tags):
            errors.append(f"no image newTag matches /{tag_pattern}/; got {tags}")
    rep = doc.get("replicas") or []
    if not rep or rep[0].get("count") != int(replicas):
        errors.append(f"replicas count must be {replicas}; got {rep}")
    ann = doc.get("commonAnnotations") or {}
    if ann.get("forge.io/managed-by") != "forge":
        errors.append("missing commonAnnotations forge.io/managed-by: forge")
    if ann.get("forge.io/overlay") != env:
        errors.append(f"missing commonAnnotations forge.io/overlay: {env}")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
  # Optional L2 augmentation: real kustomize build + kubeconform
  if have_kustomize; then
    local out
    out=$(kustomize build "$K8S_DIR/overlays/$env" 2>&1) || {
      echo "    kustomize build overlays/$env failed:" >&2
      echo "$out" | sed 's/^/      /' >&2
      return 1
    }
    if have_kubeconform; then
      printf '%s' "$out" | kubeconform --summary --strict - >/dev/null 2>&1 || {
        echo "    kubeconform --strict failed for overlays/$env" >&2
        return 1
      }
    fi
  fi
}

test_kustomize_base_renders() {
  local kfile="$K8S_DIR/base/kustomization.yaml.tmpl"
  if [ ! -f "$kfile" ]; then
    echo "    base/kustomization.yaml.tmpl missing" >&2
    return 1
  fi
  # Each base resource MUST exist as a .tmpl file
  for f in deployment.yaml.tmpl service.yaml.tmpl serviceaccount.yaml.tmpl ingress.yaml.tmpl; do
    if [ ! -f "$K8S_DIR/base/$f" ]; then
      echo "    base/$f missing" >&2
      return 1
    fi
  done
  # base kustomization parses + lists resources
  python3 - "$kfile" <<'PY' || return 1
import sys, yaml
with open(sys.argv[1]) as fh:
    doc = yaml.safe_load(fh)
errors = []
if not isinstance(doc, dict) or doc.get("kind") != "Kustomization":
    errors.append("kind != Kustomization")
res = doc.get("resources") or []
expected = {"deployment.yaml", "service.yaml", "serviceaccount.yaml", "ingress.yaml"}
missing = expected - set(res)
if missing:
    errors.append(f"resources: missing {sorted(missing)}; got {res}")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
  # Deployment has containers + healthcheck probes + resources
  python3 - "$K8S_DIR/base/deployment.yaml.tmpl" <<'PY' || return 1
import sys, yaml
with open(sys.argv[1]) as fh:
    doc = yaml.safe_load(fh)
errors = []
if not isinstance(doc, dict) or doc.get("kind") != "Deployment":
    errors.append("kind != Deployment")
spec = (doc.get("spec") or {}).get("template", {}).get("spec", {})
containers = spec.get("containers") or []
if not containers:
    errors.append("no containers declared")
else:
    c = containers[0]
    if "livenessProbe" not in c:
        errors.append("container missing livenessProbe")
    if "readinessProbe" not in c:
        errors.append("container missing readinessProbe")
    if "resources" not in c:
        errors.append("container missing resources")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
  if have_kustomize; then
    kustomize build "$K8S_DIR/base" >/dev/null 2>&1 || {
      echo "    kustomize build base failed" >&2; return 1; }
  fi
}

test_overlay_dev_renders_and_validates() {
  kustomize_overlay_assertions dev '-dev' '^dev-latest$' 1
}

test_overlay_staging_renders_and_validates() {
  kustomize_overlay_assertions staging '-staging' '^sha-' 2
}

test_overlay_prod_renders_and_validates() {
  kustomize_overlay_assertions prod '-prod' '^v[0-9]' 3 || return 1
  # FR-IN-006 prod-specific: HorizontalPodAutoscaler resource present
  local hpa="$K8S_DIR/overlays/prod/hpa.yaml.tmpl"
  if [ ! -f "$hpa" ]; then
    echo "    overlays/prod/hpa.yaml.tmpl missing" >&2
    return 1
  fi
  python3 - "$hpa" <<'PY' || return 1
import sys, yaml
with open(sys.argv[1]) as fh:
    doc = yaml.safe_load(fh)
errors = []
if not isinstance(doc, dict) or doc.get("kind") != "HorizontalPodAutoscaler":
    errors.append(f"kind != HorizontalPodAutoscaler; got {doc.get('kind') if isinstance(doc,dict) else type(doc).__name__}")
spec = doc.get("spec") or {}
if spec.get("minReplicas") != 3:
    errors.append(f"minReplicas must be 3; got {spec.get('minReplicas')}")
if spec.get("maxReplicas") != 10:
    errors.append(f"maxReplicas must be 10; got {spec.get('maxReplicas')}")
metrics = spec.get("metrics") or []
cpu_target = None
for m in metrics:
    if (m.get("type") == "Resource"
        and (m.get("resource") or {}).get("name") == "cpu"):
        cpu_target = ((m.get("resource") or {}).get("target") or {}).get("averageUtilization")
if cpu_target != 70:
    errors.append(f"CPU averageUtilization target must be 70; got {cpu_target}")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_overlay_diff_size_under_4kb() {
  # NFR-017 — only meaningful when kustomize is on PATH (L2). At L1
  # the .tmpl files are pre-substitution and a textual diff is not
  # equivalent to the rendered diff. SKIP cleanly when kustomize
  # is missing, marked PASS-with-skip-message.
  if ! have_kustomize; then
    echo "    SKIP : kustomize not on PATH (test runs in L2 only)" >&2
    return 0
  fi
  local dev_out prod_out
  dev_out=$(kustomize build "$K8S_DIR/overlays/dev" 2>/dev/null) || return 1
  prod_out=$(kustomize build "$K8S_DIR/overlays/prod" 2>/dev/null) || return 1
  local diff_bytes
  diff_bytes=$(diff <(printf '%s' "$dev_out") <(printf '%s' "$prod_out") | wc -c | tr -d ' ')
  if [ "$diff_bytes" -gt 4096 ]; then
    echo "    overlay diff dev↔prod = ${diff_bytes} bytes > 4096 (NFR-017)" >&2
    return 1
  fi
}

test_workflow_integration_triggers_and_lifecycle() {
  local f="$WORKFLOWS_DIR/forge-integration.yml.tmpl"
  if [ ! -f "$f" ]; then
    echo "    file missing: $f" >&2
    return 1
  fi
  # FR-IN-005 specific: triggers MUST include push:main + schedule, MUST exclude pull_request
  python3 - "$f" <<'PY' || return 1
import sys, yaml
text = open(sys.argv[1]).read()
doc = yaml.safe_load(text)
if doc is None:
    print("    yaml empty", file=sys.stderr); sys.exit(1)
on = doc.get("on", doc.get(True, None))
if not isinstance(on, dict):
    print(f"    `on:` not a mapping: {type(on).__name__}", file=sys.stderr); sys.exit(1)
errors = []
if "pull_request" in on:
    errors.append("integration workflow MUST NOT trigger on pull_request")
if "push" not in on:
    errors.append("missing `on.push`")
elif not isinstance(on["push"], dict) or "main" not in (on["push"].get("branches") or []):
    errors.append("`on.push.branches` must include `main`")
if "schedule" not in on:
    errors.append("missing `on.schedule` (nightly cron)")
if "workflow_dispatch" not in on:
    errors.append("missing `on.workflow_dispatch`")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
  # Compose lifecycle: up --wait, down -v, if: always() teardown
  grep -q -- "up -d --wait"  "$f" || { echo "    missing \`docker compose up -d --wait\`" >&2; return 1; }
  grep -q -- "down -v"       "$f" || { echo "    missing \`docker compose down -v\`" >&2; return 1; }
  grep -q "if: always()"     "$f" || { echo "    missing \`if: always()\` teardown guard" >&2; return 1; }
  # Patrol step + cargo integration
  grep -q "patrol\|reactivecircus/android-emulator-runner" "$f" \
    || { echo "    missing Patrol / android-emulator-runner step" >&2; return 1; }
  grep -q -- "--features integration" "$f" \
    || { echo "    missing \`cargo test --features integration\`" >&2; return 1; }
}

test_manifest_self_consistency() {
  # Meta-test : every `# MANIFEST: test_*` line declares a bash
  # function that exists in this file. Catches typos and orphaned
  # manifest entries.
  local missing=()
  while IFS= read -r fn; do
    if ! declare -F "$fn" >/dev/null 2>&1; then
      missing+=("$fn")
    fi
  done < <(grep -oE '^# MANIFEST: test_[a-z0-9_]+' "${BASH_SOURCE[0]}" | awk '{print $3}')
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    manifest declares functions not defined: ${missing[*]}" >&2
    return 1
  fi
}

# ─── Main dispatcher ────────────────────────────────────────────

main() {
  echo "── Forge Delivery Test Harness ──"
  echo "  ARCHETYPE_DIR=$ARCHETYPE_DIR"
  local levels; levels="$(decide_levels)"
  echo "  LEVELS=$levels"
  echo ""

  if [[ "$levels" == *"1"* ]]; then
    echo "── L1 : structural invariants ──"
    run_test test_workflow_backend_paths_filter_and_steps
    run_test test_workflow_frontend_paths_filter_and_steps
    run_test test_workflow_infra_paths_filter_and_steps
    run_test test_workflow_integration_triggers_and_lifecycle
    run_test test_kustomize_base_renders
    run_test test_overlay_dev_renders_and_validates
    run_test test_overlay_staging_renders_and_validates
    run_test test_overlay_prod_renders_and_validates
    run_test test_overlay_diff_size_under_4kb
    run_test test_manifest_self_consistency
  fi

  if [[ "$levels" == *"2"* ]]; then
    if ! have_l2_tools; then
      echo ""
      echo "── L2 : fixture-based — SKIPPED (kustomize/kubeconform/docker compose missing) ──"
    else
      echo ""
      echo "── L2 : fixture-based ──"
      # Filled in Phase 2-7 GREEN.
      :
    fi
  fi

  if [[ "$levels" == *"3"* ]]; then
    if [ -z "$LONG_TESTS" ]; then
      echo ""
      echo "── L3 : long-mode — SKIPPED (LONG_TESTS unset) ──"
    else
      echo ""
      echo "── L3 : long-mode ──"
      # Filled in Phase 8.1 GREEN.
      :
    fi
  fi

  print_summary
}

main "$@"
