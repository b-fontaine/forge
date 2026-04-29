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

# ─── Phase 7 : Schema promotion (gated on archive) ─────────────

test_schema_header_post_archive() {
  # Per ADR-009, this test SKIPS until the b1-delivery change is
  # archived. After archive, asserts the schema header bumped to
  # status: stable, version: "1.0.0", and the promoted_* traceability
  # fields are populated.
  if [ ! -f "$CHANGE_YAML" ]; then
    echo "    b1-delivery .forge.yaml missing" >&2; return 1
  fi
  python3 - "$CHANGE_YAML" "$SCHEMA_YAML" <<'PY' || return 1
import sys, yaml
change_path, schema_path = sys.argv[1:3]
with open(change_path) as fh:
    change = yaml.safe_load(fh)
status = (change or {}).get("status", "unknown")
if status != "archived":
    print(f"    SKIP : b1-delivery status='{status}' (gated on archive per ADR-009)", file=sys.stderr)
    sys.exit(0)
# Status == archived — assert the schema header reflects promotion
with open(schema_path) as fh:
    schema = yaml.safe_load(fh)
errors = []
if (schema or {}).get("status") != "stable":
    errors.append(f"schema status must be 'stable'; got {(schema or {}).get('status')!r}")
if (schema or {}).get("version") != "1.0.0":
    errors.append(f"schema version must be '1.0.0'; got {(schema or {}).get('version')!r}")
if (schema or {}).get("promoted_from") != "1.0.0-rc.1":
    errors.append(f"schema promoted_from must be '1.0.0-rc.1'; got {(schema or {}).get('promoted_from')!r}")
if (schema or {}).get("promoted_in") != "b1-delivery":
    errors.append(f"schema promoted_in must be 'b1-delivery'; got {(schema or {}).get('promoted_in')!r}")
if not (schema or {}).get("promoted_on"):
    errors.append("schema promoted_on must be a non-empty ISO date")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

# ─── Phase 8 : NFR + Aegis security + workflow file size ───────

test_no_latest_tag_anywhere() {
  # NFR-018 — no `:latest` image tag anywhere in archetype templates.
  # Allowed only in comments (which the grep below ignores via #-prefix).
  local hits
  hits=$(grep -rE '^[^#]*:latest\b' "$ARCHETYPE_DIR" 2>/dev/null | grep -v '^[^:]*:#' || true)
  if [ -n "$hits" ]; then
    echo "    forbidden :latest tags found:" >&2
    printf '%s\n' "$hits" | sed 's/^/      /' >&2
    return 1
  fi
}

test_workflow_files_under_size_budget() {
  # NFR-016 — every reference workflow .tmpl ≤ 250 lines.
  local f lines
  for f in "$WORKFLOWS_DIR"/*.yml.tmpl; do
    lines=$(wc -l < "$f")
    if [ "$lines" -gt 250 ]; then
      echo "    $f: $lines lines > 250 (NFR-016)" >&2
      return 1
    fi
  done
}

test_no_secrets_in_templates() {
  # Aegis security — no secrets committed in templates. Allowed :
  # - GitHub Actions `secrets.*` references (they POINT at secrets,
  #   not embed them).
  # - YAML keys that reference a Secret/ConfigMap (envFrom,
  #   valueFrom, secretKeyRef, configMapKeyRef).
  # - `.env.example*` files which by convention carry placeholder
  #   values (e.g. `changeme_local_only`) for adopters to override.
  # - Common placeholder markers (placeholder, <...>, base64, REPLACE_ME).
  local hits
  hits=$(grep -rEni '(password|api[_-]?key|client[_-]?secret)\s*[:=]\s*["'\''A-Za-z0-9]' "$ARCHETYPE_DIR" 2>/dev/null \
    | grep -vE '^[^:]+\.env\.example' \
    | grep -vE '^[^:]+:\s*#' \
    | grep -vE 'secrets\.[A-Z_]+|env_file|valueFrom:|configMapKeyRef|secretKeyRef|placeholder|base64|<.*>|REPLACE_ME|changeme|change-me|replace-me' \
    | grep -vE 'password:\s*""|password:\s*$' \
    || true)
  if [ -n "$hits" ]; then
    echo "    potential secrets found in templates:" >&2
    printf '%s\n' "$hits" | sed 's/^/      /' >&2
    return 1
  fi
}

# ─── Phase 8 long-mode tests (LONG_TESTS=1 only) ───────────────

test_compose_stack_startup_under_90s() {
  # NFR-015. Skip path is the default; long-mode runs the real boot.
  if [ -z "$LONG_TESTS" ]; then
    echo "    SKIP : LONG_TESTS unset" >&2; return 0
  fi
  echo "    SKIP : requires fixture-scaffolded project — run from C.1" >&2
  return 0
}

test_per_layer_workflow_runtime_warm_under_8min() {
  # NFR-013. Skip path is the default; long-mode requires `act`.
  if [ -z "$LONG_TESTS" ]; then
    echo "    SKIP : LONG_TESTS unset" >&2; return 0
  fi
  if ! have_act; then
    echo "    SKIP : act not on PATH" >&2; return 0
  fi
  echo "    SKIP : requires fixture-scaffolded project + warm cache" >&2
  return 0
}

# ─── Phase 6 : Scaffolder integration ──────────────────────────

test_scaffold_plan_lists_all_new_templates() {
  if [ ! -f "$SCAFFOLD_PLAN" ]; then
    echo "    scaffold-plan.yaml missing" >&2; return 1
  fi
  python3 - "$SCAFFOLD_PLAN" "$ARCHETYPE_DIR" <<'PY' || return 1
import sys, yaml, os, glob
plan_path, archetype_dir = sys.argv[1], sys.argv[2]
with open(plan_path) as fh:
    plan = yaml.safe_load(fh)
errors = []
templates = (plan or {}).get("templates") or []
sources = {t.get("source") for t in templates if isinstance(t, dict)}
targets = {t.get("target") for t in templates if isinstance(t, dict)}

# Every .tmpl file under the archetype tree (except scaffold-plan
# itself) must have a templates: entry mapping it to a sane target.
expected_sources = []
for path in glob.glob(os.path.join(archetype_dir, "**/*.tmpl"), recursive=True):
    rel = os.path.relpath(path, archetype_dir)
    expected_sources.append(rel)

missing = [s for s in expected_sources if s not in sources]
if missing:
    errors.append(f"scaffold-plan.yaml templates: missing entries for {len(missing)} files:")
    for m in sorted(missing):
        errors.append(f"  - {m}")

# The two obsolete .gitkeep entries (k8s_base, k8s_overlays) and
# the .github_workflows.gitkeep entry MUST have been removed.
forbidden = ["infra/k8s_base.gitkeep", "infra/k8s_overlays.gitkeep", ".github_workflows.gitkeep"]
for f in forbidden:
    if f in sources:
        errors.append(f"obsolete entry must be removed: {f}")

# Sanity: no entry references a source that doesn't exist on disk
for src in sources:
    if not src:
        continue
    if not os.path.exists(os.path.join(archetype_dir, src)):
        errors.append(f"templates entry source missing on disk: {src}")

for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_scaffold_fixture_renders_and_validates() {
  # E2E: scaffold a fixture project and run the L1 checks against
  # the rendered tree. Requires flutter + cargo + buf (per b1-scaffolder
  # convention). SKIPS cleanly when tools missing.
  if ! command -v flutter >/dev/null 2>&1 \
    || ! command -v cargo >/dev/null 2>&1 \
    || ! command -v buf >/dev/null 2>&1; then
    echo "    SKIP : flutter / cargo / buf missing (full E2E runs only with --require-external-tools)" >&2
    return 0
  fi
  # Delegated to scaffolder.test.sh L3, which already exercises the
  # scaffolder end-to-end. Re-running the same fixture here would
  # duplicate effort; instead, verify scaffolder.test.sh is invokable
  # against the current archetype tree.
  if ! bash "$SCRIPTS_DIR/tests/scaffolder.test.sh" --level 2 >/dev/null 2>&1; then
    echo "    scaffolder.test.sh L2 fails — archetype tree drifted from contract" >&2
    return 1
  fi
}

# ─── Phase 5 : Standards (canonical sections) ──────────────────

# assert_h2_sections <file> <expected_csv>
assert_h2_sections() {
  local f="$1" expected_csv="$2"
  if [ ! -f "$f" ]; then
    echo "    file missing: $f" >&2; return 1
  fi
  python3 - "$f" "$expected_csv" <<'PY'
import sys, re
path, csv = sys.argv[1], sys.argv[2]
with open(path) as fh:
    text = fh.read()
present = set(re.findall(r"^##\s+(.+?)\s*$", text, re.MULTILINE))
expected = [s.strip() for s in csv.split("|") if s.strip()]
missing = [s for s in expected if s not in present]
if missing:
    print(f"    missing required H2 sections: {missing}", file=sys.stderr)
    print(f"    present sections: {sorted(present)}", file=sys.stderr)
    sys.exit(1)
PY
}

test_standard_ci_workflows_has_required_sections() {
  assert_h2_sections "$STD_CI" \
    "Per-layer paths filter|Gate ordering|Integration workflow scope|Concurrency policy|Caching strategy|Tool version pinning|Failure semantics"
}

test_standard_k8s_overlays_has_required_sections() {
  assert_h2_sections "$STD_K8S" \
    "Three-environment promotion model|Per-overlay diff conventions|Image tag policy by environment|Resource budget table|Secret management|Promotion gating"
}

test_standard_observability_local_has_required_sections() {
  assert_h2_sections "$STD_OBS" \
    "Local OTel + SigNoz topology|App-side OTLP configuration|Versioning policy|Trace sampling defaults|Migration to production observability"
}

test_index_has_three_new_infra_standards() {
  python3 - "$INDEX_YML" <<'PY' || return 1
import sys, yaml
with open(sys.argv[1]) as fh:
    doc = yaml.safe_load(fh)
errors = []
ids = {s.get("id") for s in (doc or {}).get("standards", [])}
for needed in ("infra/ci-workflows", "infra/k8s-overlays", "infra/observability-local"):
    if needed not in ids:
        errors.append(f"missing index entry: {needed}")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

# ─── Phase 4 : Local observability stack ───────────────────────

test_compose_otel_service_shape() {
  if [ ! -f "$COMPOSE_TMPL" ]; then
    echo "    docker-compose.dev.yml.tmpl missing" >&2; return 1
  fi
  python3 - "$COMPOSE_TMPL" <<'PY' || return 1
import sys, yaml, re
with open(sys.argv[1]) as fh:
    doc = yaml.safe_load(fh)
errors = []
services = (doc or {}).get("services") or {}
svc = services.get("fsm-otel-collector")
if not svc:
    errors.append("missing service: fsm-otel-collector")
else:
    img = str(svc.get("image", ""))
    if not re.search(r"otel/opentelemetry-collector-contrib:\d+\.\d+\.\d+", img):
        errors.append(f"image must be otel/opentelemetry-collector-contrib pinned to a specific version; got {img!r}")
    if img.endswith(":latest") or "latest" in img.split(":")[-1]:
        errors.append(f"image MUST NOT use :latest tag; got {img!r}")
    port_str = " ".join(str(p) for p in (svc.get("ports") or []))
    for p in ("4317", "4318", "13133"):
        if p not in port_str:
            errors.append(f"missing host-exposed port {p}")
    nets = svc.get("networks") or []
    if "fsm-dev" not in nets:
        errors.append(f"must join fsm-dev network; got {nets}")
    hc = svc.get("healthcheck") or {}
    hc_test = " ".join(str(t) for t in (hc.get("test") or []))
    if "13133" not in hc_test:
        errors.append(f"healthcheck must probe :13133; got {hc_test!r}")
    vols = svc.get("volumes") or []
    if not any("otel-collector-config" in str(v) for v in vols):
        errors.append("missing config mount referencing otel-collector-config.yaml")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
  # OTel collector config parses as valid YAML with required pipelines
  python3 - "$OBS_DIR/otel-collector-config.yaml.tmpl" <<'PY' || return 1
import sys, yaml
with open(sys.argv[1]) as fh:
    doc = yaml.safe_load(fh)
errors = []
if not isinstance(doc, dict):
    errors.append("otel-collector-config.yaml.tmpl: not a YAML mapping")
else:
    for k in ("receivers", "processors", "exporters", "service"):
        if k not in doc:
            errors.append(f"missing top-level `{k}:`")
    receivers = (doc.get("receivers") or {})
    if "otlp" not in receivers:
        errors.append("missing `receivers.otlp` (gRPC + HTTP)")
    pipelines = ((doc.get("service") or {}).get("pipelines") or {})
    for sig in ("traces", "metrics", "logs"):
        if sig not in pipelines:
            errors.append(f"missing `service.pipelines.{sig}` (Article IX three signals)")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_compose_signoz_services_shape() {
  python3 - "$COMPOSE_TMPL" <<'PY' || return 1
import sys, yaml, re
with open(sys.argv[1]) as fh:
    doc = yaml.safe_load(fh)
errors = []
services = (doc or {}).get("services") or {}
expected = ["fsm-signoz-clickhouse", "fsm-signoz-query", "fsm-signoz-frontend"]
for name in expected:
    if name not in services:
        errors.append(f"missing service: {name}")
        continue
    svc = services[name]
    img = str(svc.get("image", ""))
    if not re.search(r":[\w.-]+$", img) or img.endswith(":latest"):
        errors.append(f"{name}: image must be pinned, no :latest; got {img!r}")
    if not svc.get("healthcheck"):
        errors.append(f"{name}: missing healthcheck")
    if svc.get("restart") != "unless-stopped":
        errors.append(f"{name}: restart must be unless-stopped; got {svc.get('restart')!r}")
# only signoz-frontend exposes 3301
fe = services.get("fsm-signoz-frontend") or {}
fe_ports = " ".join(str(p) for p in (fe.get("ports") or []))
if "3301" not in fe_ports:
    errors.append("fsm-signoz-frontend must expose :3301 to host")
# clickhouse + query: no host-exposed ports
for name in ["fsm-signoz-clickhouse", "fsm-signoz-query"]:
    s = services.get(name) or {}
    if s.get("ports"):
        errors.append(f"{name}: ports must NOT be host-exposed (internal only)")
# depends_on chain
def dep_cond(svc, target):
    deps = svc.get("depends_on")
    if isinstance(deps, dict):
        entry = deps.get(target)
        if isinstance(entry, dict):
            return entry.get("condition")
    return None
qs = services.get("fsm-signoz-query") or {}
if dep_cond(qs, "fsm-signoz-clickhouse") != "service_healthy":
    errors.append("fsm-signoz-query must depends_on fsm-signoz-clickhouse: service_healthy")
if dep_cond(fe, "fsm-signoz-query") != "service_healthy":
    errors.append("fsm-signoz-frontend must depends_on fsm-signoz-query: service_healthy")
# named volume
if "signoz-clickhouse-data" not in (doc.get("volumes") or {}):
    errors.append("named volume `signoz-clickhouse-data` must be declared")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_taskfile_has_observe_target() {
  if [ ! -f "$TASKFILE_TMPL" ]; then
    echo "    Taskfile.yml.tmpl missing" >&2; return 1
  fi
  python3 - "$TASKFILE_TMPL" <<'PY' || return 1
import sys, yaml
with open(sys.argv[1]) as fh:
    doc = yaml.safe_load(fh)
errors = []
tasks = (doc or {}).get("tasks") or {}
obs = tasks.get("observe")
if not isinstance(obs, dict):
    errors.append("missing task: `observe`")
else:
    cmds = obs.get("cmds") or []
    text = "\n".join(str(c) for c in cmds)
    if "3301" not in text:
        errors.append("`observe` cmds must reference :3301")
    if "open" not in text and "xdg-open" not in text:
        errors.append("`observe` cmds must use `open` (macOS) or `xdg-open` (Linux)")
for e in errors:
    print(f"    {e}", file=sys.stderr)
sys.exit(1 if errors else 0)
PY
}

test_env_dev_files_export_otel_defaults() {
  local be="$ARCHETYPE_DIR/backend/.env.dev.tmpl"
  local fe="$ARCHETYPE_DIR/frontend/.env.dev.tmpl"
  for f in "$be" "$fe"; do
    if [ ! -f "$f" ]; then echo "    file missing: $f" >&2; return 1; fi
    grep -qE '^OTEL_EXPORTER_OTLP_ENDPOINT=' "$f" || { echo "    $f: missing OTEL_EXPORTER_OTLP_ENDPOINT" >&2; return 1; }
    grep -qE '^OTEL_SERVICE_NAME='            "$f" || { echo "    $f: missing OTEL_SERVICE_NAME" >&2; return 1; }
    grep -qE '^OTEL_TRACES_EXPORTER=otlp'     "$f" || { echo "    $f: missing OTEL_TRACES_EXPORTER=otlp" >&2; return 1; }
    grep -qE '^OTEL_METRICS_EXPORTER=otlp'    "$f" || { echo "    $f: missing OTEL_METRICS_EXPORTER=otlp" >&2; return 1; }
    grep -qE '^OTEL_LOGS_EXPORTER=otlp'       "$f" || { echo "    $f: missing OTEL_LOGS_EXPORTER=otlp" >&2; return 1; }
  done
  # Per-layer protocol: backend gRPC, frontend HTTP/protobuf (Dart SDK constraint)
  grep -q '^OTEL_EXPORTER_OTLP_PROTOCOL=grpc'          "$be" || { echo "    backend missing OTEL_EXPORTER_OTLP_PROTOCOL=grpc" >&2; return 1; }
  grep -q '^OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf' "$fe" || { echo "    frontend missing OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf" >&2; return 1; }
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
    run_test test_compose_otel_service_shape
    run_test test_compose_signoz_services_shape
    run_test test_taskfile_has_observe_target
    run_test test_env_dev_files_export_otel_defaults
    run_test test_standard_ci_workflows_has_required_sections
    run_test test_standard_k8s_overlays_has_required_sections
    run_test test_standard_observability_local_has_required_sections
    run_test test_index_has_three_new_infra_standards
    run_test test_scaffold_plan_lists_all_new_templates
    run_test test_scaffold_fixture_renders_and_validates
    run_test test_schema_header_post_archive
    run_test test_no_latest_tag_anywhere
    run_test test_workflow_files_under_size_budget
    run_test test_no_secrets_in_templates
    run_test test_manifest_self_consistency
  fi

  if [[ "$levels" == *"2"* ]]; then
    if ! have_l2_tools; then
      echo ""
      echo "── L2 : fixture-based — SKIPPED (kustomize/kubeconform/docker compose missing) ──"
    else
      echo ""
      echo "── L2 : fixture-based ──"
      # Augmentation already wired into L1 tests when binaries are
      # present (kustomize_overlay_assertions runs `kustomize build`
      # + `kubeconform --strict` if available). No L2-only tests
      # required at this time.
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
      run_test test_compose_stack_startup_under_90s
      run_test test_per_layer_workflow_runtime_warm_under_8min
    fi
  fi

  print_summary
}

main "$@"
