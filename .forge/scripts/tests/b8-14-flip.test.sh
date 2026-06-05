#!/usr/bin/env bash
# Forge B.8.14 FLIP — enablement harness (b8-14-promotion-flip, C2)
# <!-- Audit: B.8.14 (b8-14-promotion-flip) — enablement / point-of-no-return C2 -->
#
# C1 (ratification: Constitution v2.0.0, §VIII.1 Kong→Envoy) already landed.
# C2 (this) ENABLES a Kong-less 2.0.0 front-door: `forge init --archetype
# full-stack-monorepo` must now scaffold a Kong-LESS, Envoy/Connect tree, while
# migrate-flagship stays ADDITIVE forever (1.0.0 adopters keep Kong — proven by
# b8-12 + b8-15 line ~225, which this harness leaves untouched).
#
# Test strategy (mirrors the b8-2/b8-15 split):
#   L1 — hermetic (grep/python-parse/overlay-render, no toolchain): the 2.0.0
#        scaffold-plan is Kong-less + Envoy-bearing; `overlay.sh --plan` renders a
#        Kong-less tree; the 2.0.0 schema is promoted (stable + scaffoldable:true);
#        the CLI scaffoldable:false guard + the versioned wrapper exist; the
#        constitution anchor (C1) holds; CI registration; and — KEEP-green — the
#        1.0.0 plan STILL carries Kong (fresh-scaffold removal must never touch
#        the 1.0.0 base or the additive migrate path).
#   L2 — env-gated (FORGE_B8_14_FLIP_LIVE=1 + flutter/cargo/buf): a real
#        `forge init` via bin/forge-init-fsm-2.0.0.sh yields a Kong-less Envoy
#        tree that passes validate-foundations.
#
# Usage:
#   bash .forge/scripts/tests/b8-14-flip.test.sh [--level 1|1,2]
#
# MANIFEST (test fn → FR):
#   _test_b814f_001_plan_kongless          — FR-FLIP-021 (2.0.0 plan omits Kong, has Envoy/Connect)
#   _test_b814f_002_plan_schema_valid      — FR-FLIP-021 (plan satisfies scaffolder plan-schema)
#   _test_b814f_003_schema_promoted        — FR-FLIP-020 (2.0.0.yaml stable + scaffoldable:true)
#   _test_b814f_004_overlay_renders_kongless — FR-FLIP-023 (overlay --plan → no Kong, Envoy present)
#   _test_b814f_005_versioned_wrapper       — FR-FLIP-021 (bin/forge-init-fsm-2.0.0.sh selects the 2.0.0 plan)
#   _test_b814f_006_cli_scaffoldable_guard  — FR-FLIP-022 (CLI refuses scaffoldable:false; schema-version reader)
#   _test_b814f_007_constitution_anchor     — FR-FLIP-002 (C1: constitution v2.0.0 + §VIII.1 Envoy)
#   _test_b814f_008_forgeci_registration    — FR-FLIP-030 (this harness registered in forge-ci.yml)
#   _test_b814f_009_migrate_still_additive   — FR-FLIP-024 (1.0.0 plan keeps Kong; migrate additive-only)
#   _test_b814f_l2_real_kongless_scaffold    — FR-FLIP-023 (L2: real forge init → Kong-less Envoy tree)

set -uo pipefail

# ─── --level parse (default 1) ──────────────────────────────────
LEVEL="1"
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  case "$arg" in --level=*) LEVEL="${arg#*=}" ;; esac
  prev="$arg"
done

# ─── Paths ──────────────────────────────────────────────────────
HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

ARCHETYPE_DIR="$FORGE_ROOT_REAL/.forge/templates/archetypes/full-stack-monorepo"
PLAN_10="$ARCHETYPE_DIR/scaffold-plan.yaml"
PLAN_20="$ARCHETYPE_DIR/scaffold-plan-2.0.0.yaml"
PLAN_20_NAME="scaffold-plan-2.0.0.yaml"
SCHEMA_20="$FORGE_ROOT_REAL/.forge/schemas/full-stack-monorepo/2.0.0.yaml"
OVERLAY_SH="$SCRIPTS_DIR/scaffolder/overlay.sh"
CONSTITUTION="$FORGE_ROOT_REAL/.forge/constitution.md"
FSM_20_WRAPPER="$FORGE_ROOT_REAL/bin/forge-init-fsm-2.0.0.sh"
INIT_ARCH_TS="$FORGE_ROOT_REAL/cli/src/commands/init-archetype.ts"
SCHEMA_VERSION_TS="$FORGE_ROOT_REAL/cli/src/domain/schema-version.ts"
MIGRATE_SH="$FORGE_ROOT_REAL/bin/forge-migrate-flagship.sh"
FORGE_CI="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"

# ─── Shared helpers (run_test / print_summary / counters) ───────
# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0; FAIL=0; FAIL_NAMES=()

# ─── L1 : hermetic ──────────────────────────────────────────────

# FR-FLIP-021 — the 2.0.0 plan exists, drops the Kong copy-op, and pulls in the
# Envoy gateway + Connect transport from the 2.0.0/ fragment tree.
_test_b814f_001_plan_kongless() {
  [ -f "$PLAN_20" ] || { echo "    $PLAN_20_NAME missing (Kong-less 2.0.0 plan not authored)" >&2; return 1; }
  if grep -qE 'infra/kong/kong\.yml\.example\.tmpl' "$PLAN_20"; then
    echo "    2.0.0 plan still copies the Kong declarative config (must be omitted)" >&2; return 1
  fi
  grep -qE '2\.0\.0/infra/k8s/envoy-gateway' "$PLAN_20" || {
    echo "    2.0.0 plan does not reference the 2.0.0/ Envoy gateway fragments" >&2; return 1; }
  grep -qiE 'transport_connect|connect' "$PLAN_20" || {
    echo "    2.0.0 plan does not reference the Connect-RPC transport" >&2; return 1; }
}

# FR-FLIP-021 — plan satisfies the same plan-schema scaffolder.test.sh enforces.
_test_b814f_002_plan_schema_valid() {
  [ -f "$PLAN_20" ] || { echo "    $PLAN_20_NAME missing" >&2; return 1; }
  local result
  result=$(python3 - "$PLAN_20" "$ARCHETYPE_DIR" <<'PY'
import sys, yaml, os
plan_path, archetype_dir = sys.argv[1], sys.argv[2]
with open(plan_path, encoding='utf-8') as f:
    data = yaml.safe_load(f)
if not isinstance(data, dict):
    print("KO: plan not a mapping"); sys.exit(0)
required = {"archetype", "version", "official_scaffolders", "templates", "post_steps"}
missing = sorted(required - set(data.keys()))
if missing:
    print(f"KO: missing keys {missing}"); sys.exit(0)
if data.get("archetype") != "full-stack-monorepo":
    print(f"KO: archetype != full-stack-monorepo ({data.get('archetype')})"); sys.exit(0)
if str(data.get("version")) != "2.0.0":
    print(f"KO: version != 2.0.0 ({data.get('version')})"); sys.exit(0)
templates = data.get("templates", [])
if not isinstance(templates, list) or len(templates) < 20:
    print(f"KO: templates count {len(templates) if isinstance(templates, list) else 'NA'} < 20"); sys.exit(0)
miss = []
for e in templates:
    if not isinstance(e, dict) or not e.get("source"):
        miss.append("<bad entry>"); continue
    if not os.path.isfile(os.path.join(archetype_dir, e["source"])):
        miss.append(e["source"])
if miss:
    print(f"KO: missing sources {miss}"); sys.exit(0)
print("OK")
PY
)
  [ "$result" = "OK" ] || { echo "    plan-schema: $result" >&2; return 1; }
}

# FR-FLIP-020 — the schema flip: stable + scaffoldable:true (was candidate/false).
_test_b814f_003_schema_promoted() {
  [ -f "$SCHEMA_20" ] || { echo "    2.0.0.yaml missing" >&2; return 1; }
  grep -qE '^stage: *stable' "$SCHEMA_20" || {
    echo "    2.0.0.yaml stage != stable (schema not promoted)" >&2; return 1; }
  grep -qE '^scaffoldable: *true' "$SCHEMA_20" || {
    echo "    2.0.0.yaml scaffoldable != true (flip not enabled)" >&2; return 1; }
}

# FR-FLIP-023 — render the 2.0.0 plan via overlay.sh --plan into a tmpdir and
# prove the produced tree is Kong-less + Envoy-bearing. overlay.sh is pure
# python file-copy, so this is hermetic (no flutter/cargo/buf).
_test_b814f_004_overlay_renders_kongless() {
  [ -f "$PLAN_20" ] || { echo "    $PLAN_20_NAME missing" >&2; return 1; }
  local tmp; tmp="$(mktemp -d 2>/dev/null || mktemp -d -t b814f)"
  trap "rm -rf '$tmp'" RETURN
  if ! bash "$OVERLAY_SH" --plan "$PLAN_20_NAME" --target "$tmp" \
        --project-name foo --reverse-domain com.example --force >/dev/null 2>"$tmp/err"; then
    echo "    overlay.sh --plan $PLAN_20_NAME failed:" >&2
    sed 's/^/      /' "$tmp/err" >&2
    return 1
  fi
  [ ! -d "$tmp/infra/kong" ] || { echo "    rendered tree has infra/kong/ (must be Kong-less)" >&2; return 1; }
  if [ -f "$tmp/docker-compose.dev.yml" ] && grep -qE '^[[:space:]]*fsm-kong:' "$tmp/docker-compose.dev.yml"; then
    echo "    rendered docker-compose.dev.yml still defines fsm-kong" >&2; return 1
  fi
  ls "$tmp"/infra/k8s/envoy-gateway/* >/dev/null 2>&1 || {
    echo "    rendered tree has no infra/k8s/envoy-gateway/ (Envoy missing)" >&2; return 1; }
}

# FR-FLIP-021 — the 2.0.0 scaffolder wrapper exists and selects the 2.0.0 plan.
_test_b814f_005_versioned_wrapper() {
  [ -f "$FSM_20_WRAPPER" ] || { echo "    bin/forge-init-fsm-2.0.0.sh missing" >&2; return 1; }
  grep -qF "$PLAN_20_NAME" "$FSM_20_WRAPPER" || {
    echo "    forge-init-fsm-2.0.0.sh does not reference $PLAN_20_NAME" >&2; return 1; }
}

# FR-FLIP-022 — the deferred B.8.3.b guard: CLI reads versioned schemas + refuses
# a selected scaffoldable:false schema. Source-level presence (behavior covered
# by cli vitest).
_test_b814f_006_cli_scaffoldable_guard() {
  [ -f "$SCHEMA_VERSION_TS" ] || { echo "    cli/src/domain/schema-version.ts missing (no versioned-schema reader)" >&2; return 1; }
  grep -qF "scaffoldable" "$INIT_ARCH_TS" || {
    echo "    init-archetype.ts has no scaffoldable refusal guard" >&2; return 1; }
}

# FR-FLIP-002 — C1 anchor: constitution ratified to v2.0.0 with §VIII.1 Envoy.
_test_b814f_007_constitution_anchor() {
  [ -f "$CONSTITUTION" ] || { echo "    constitution.md missing" >&2; return 1; }
  grep -qE '^\*\*Version\*\*: *v2\.0\.0' "$CONSTITUTION" || {
    echo "    constitution Version != v2.0.0 (C1 not present?)" >&2; return 1; }
  grep -qiF "Envoy Gateway SHALL be used as the API gateway" "$CONSTITUTION" || {
    echo "    §VIII.1 'Envoy Gateway SHALL' missing (C1 not present?)" >&2; return 1; }
}

# FR-FLIP-030 — this harness is registered in the forge-ci hardcoded array.
_test_b814f_008_forgeci_registration() {
  [ -f "$FORGE_CI" ] || { echo "    forge-ci.yml missing" >&2; return 1; }
  grep -qF "b8-14-flip.test.sh" "$FORGE_CI" || {
    echo "    b8-14-flip.test.sh not registered in forge-ci.yml" >&2; return 1; }
}

# FR-FLIP-024 — KEEP-GREEN invariant: the Kong-less front-door is FRESH-SCAFFOLD
# ONLY. The 1.0.0 plan must STILL carry Kong, and migrate-flagship must stay
# additive-only (1.0.0 adopters keep Kong). Guards against C2 over-reaching into
# the 1.0.0 base / the migrate path (b8-12 + b8-15:225 enforce the rest).
_test_b814f_009_migrate_still_additive() {
  grep -qE 'infra/kong/kong\.yml\.example\.tmpl' "$PLAN_10" || {
    echo "    1.0.0 plan no longer copies Kong — fresh-scaffold removal leaked into the 1.0.0 base" >&2; return 1; }
  [ -f "$MIGRATE_SH" ] || { echo "    bin/forge-migrate-flagship.sh missing" >&2; return 1; }
  grep -qiE 'ADDITIVE.ONLY|additive only|never removes' "$MIGRATE_SH" || {
    echo "    migrate-flagship no longer declares additive-only" >&2; return 1; }
  if grep -niE '(^|[^#])(rm|rmdir|git rm)[^#]*(kong|temporal|rest)' "$MIGRATE_SH" | grep -qv '#'; then
    echo "    migrate-flagship contains a Kong/Temporal/REST removal — additive invariant broken" >&2; return 1
  fi
}

# ─── L2 : real scaffold (env-gated) ─────────────────────────────

# FR-FLIP-023 — full `forge init` via the 2.0.0 wrapper yields a Kong-less Envoy
# tree that passes validate-foundations. Requires flutter+cargo+buf + opt-in.
_test_b814f_l2_real_kongless_scaffold() {
  if [ "${FORGE_B8_14_FLIP_LIVE:-}" != "1" ]; then
    echo "    [skip] L2 real scaffold — set FORGE_B8_14_FLIP_LIVE=1 (needs flutter/cargo/buf)" >&2
    return 0
  fi
  if ! { command -v flutter >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1 && command -v buf >/dev/null 2>&1; }; then
    echo "    [skip] L2 real scaffold — flutter/cargo/buf not all on PATH" >&2
    return 0
  fi
  [ -f "$FSM_20_WRAPPER" ] || { echo "    forge-init-fsm-2.0.0.sh missing" >&2; return 1; }
  local tmp; tmp="$(mktemp -d 2>/dev/null || mktemp -d -t b814f-l2)"
  trap "rm -rf '$tmp'" RETURN
  local tgt="$tmp/demo20"
  if ! bash "$FSM_20_WRAPPER" --target "$tgt" --project-name demo20 \
        --reverse-domain com.example.forgetest >"$tmp/log" 2>&1; then
    echo "    forge-init-fsm-2.0.0.sh failed — see log tail:" >&2
    tail -20 "$tmp/log" >&2
    return 1
  fi
  [ ! -d "$tgt/infra/kong" ] || { echo "    scaffolded tree has infra/kong/" >&2; return 1; }
  if grep -qE '^[[:space:]]*fsm-kong:' "$tgt/docker-compose.dev.yml" 2>/dev/null; then
    echo "    scaffolded docker-compose.dev.yml still defines fsm-kong" >&2; return 1
  fi
  ls "$tgt"/infra/k8s/envoy-gateway/* >/dev/null 2>&1 || {
    echo "    scaffolded tree has no Envoy gateway" >&2; return 1; }
}

# ─── Main ───────────────────────────────────────────────────────
main() {
  echo "── Forge B.8.14 FLIP enablement harness (C2) ──"
  echo "  LEVEL=$LEVEL"
  echo ""

  echo "── L1 : hermetic ──"
  run_test _test_b814f_001_plan_kongless
  run_test _test_b814f_002_plan_schema_valid
  run_test _test_b814f_003_schema_promoted
  run_test _test_b814f_004_overlay_renders_kongless
  run_test _test_b814f_005_versioned_wrapper
  run_test _test_b814f_006_cli_scaffoldable_guard
  run_test _test_b814f_007_constitution_anchor
  run_test _test_b814f_008_forgeci_registration
  run_test _test_b814f_009_migrate_still_additive

  case ",$LEVEL," in
    *,2,*)
      echo ""
      echo "── L2 : real scaffold (env-gated) ──"
      run_test _test_b814f_l2_real_kongless_scaffold
      ;;
  esac

  echo ""
  print_summary
}

main "$@"
