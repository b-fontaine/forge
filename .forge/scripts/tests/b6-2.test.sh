#!/usr/bin/env bash
# Forge — B.6.2 event-driven-eu scaffolder backbone harness
# <!-- Audit: B.6.2 (b6-2-scaffolder) — templates + backbone + verify-then-pin -->
#
# TDD contract for the event-driven-eu/1.0.0 scaffold backbone (sibling of the
# ai-native-rag b7-2.test.sh). L1 is the CI level (the harness job has python+node
# but no rust, so the L2 cargo-check leg only skips there — L2 stays local/opt-in;
# the comprehensive >=35-test promotion suite is B.6.7's job).
#
#   L1 (hermetic, grep/structure):
#     T-001  template layer-root tree exists (backend/infra/shared/asyncapi + protos)
#     T-002  scaffold-plan exists + references EXACTLY the .tmpl tree (no orphan/dangling)
#     T-003  verify-then-pin research file records the LIVE pins
#     T-004  pins live only in backend Cargo.toml.tmpl (none leaked into a standard)
#     T-005  scaffolder wrapper exists + executable + bash shebang
#     T-006  wrapper refuses exit 3 + zero writes while candidate
#     T-007  standards-conformance grep: NATS idempotency + event store + saga markers
#     T-008  AsyncAPI 3.1 contract present + declares asyncapi: 3.1.0
#     T-009  schema stays candidate/scaffoldable:false (promotion is B.6.7)
#     T-010  dispatch-table registers event-driven-eu (candidate) → wrapper path
#   L2 (toolchain-gated, skip when absent):
#     T-L2-001 render plan via overlay.sh → no .tmpl / no <placeholder>, byte-stable
#     T-L2-002 cargo check the rendered backend workspace (default features)
#     T-L2-003 gated wrapper render path works end-to-end (FORGE_EDE_FORCE_SCAFFOLD=1)

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
PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"
OVERLAY_SH="$FORGE_ROOT/.forge/scripts/scaffolder/overlay.sh"
WRAPPER="$FORGE_ROOT/bin/forge-init-event-driven-eu.sh"
SCHEMA="$FORGE_ROOT/.forge/schemas/event-driven-eu/1.0.0.yaml"
RESEARCH="$FORGE_ROOT/.forge/research/b6-2-verify-then-pin.md"
DISPATCH="$FORGE_ROOT/.forge/scaffolding/dispatch-table.yml"
STD_DIR="$FORGE_ROOT/.forge/standards"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

_test_b62_l1_001_tree_roots() {
  local ok=1
  for d in "backend" "infra" "shared/asyncapi" "shared/protos"; do
    [ -d "$TPL_DIR/$d" ] || { echo "    FAIL T-001: missing template layer root $TPL_DIR/$d (FR-B6-2-001)" >&2; ok=0; }
  done
  # backend workspace members
  for c in "events" "eventstore" "saga" "bin-server"; do
    [ -d "$TPL_DIR/backend/$c" ] || { echo "    FAIL T-001: missing backend crate $c (FR-B6-2-010)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b62_l1_002_plan_coverage() {
  [ -f "$PLAN" ] || { echo "    FAIL T-002: scaffold-plan missing: $PLAN (FR-B6-2-002)" >&2; return 1; }
  local ok=1
  # every .tmpl in the tree must be referenced by the plan (no orphan)
  while IFS= read -r f; do
    rel="${f#"$TPL_DIR/"}"
    grep -qF "1.0.0/$rel" "$PLAN" || { echo "    FAIL T-002: tree file not in plan: 1.0.0/$rel (FR-B6-2-002)" >&2; ok=0; }
  done < <(find "$TPL_DIR" -type f -name '*.tmpl' 2>/dev/null)
  # every plan source must exist in the tree (no dangling). Use POSIX [[:space:]]
  # (BSD sed does not honour \s) and trim any stray whitespace.
  while IFS= read -r src; do
    src="$(printf '%s' "$src" | tr -d '[:space:]')"
    [ -z "$src" ] && continue
    [ -f "$ARCHETYPE_DIR/$src" ] || { echo "    FAIL T-002: plan references missing file: $src (FR-B6-2-002)" >&2; ok=0; }
  done < <(grep -E '^[[:space:]]*- source:' "$PLAN" | sed -E 's/^[[:space:]]*-[[:space:]]*source:[[:space:]]*//')
  [ "$ok" = "1" ]
}

_test_b62_l1_003_verify_then_pin_recorded() {
  [ -f "$RESEARCH" ] || { echo "    FAIL T-003: verify-then-pin research file missing: $RESEARCH (FR-B6-2-040)" >&2; return 1; }
  local ok=1
  for crate in "async-nats" "sqlx" "temporalio-sdk" "temporalio-client"; do
    grep -qE "\`?${crate}\`?" "$RESEARCH" || { echo "    FAIL T-003: research file missing pin for '$crate' (FR-B6-2-040)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b62_l1_004_pins_only_in_cargo() {
  local ok=1
  # No net-new pin inside any standard yaml (single source of truth stays the template).
  for f in "$STD_DIR"/*.yaml "$STD_DIR"/infra/*.md "$STD_DIR"/global/*.md; do
    [ -f "$f" ] || continue
    hits=$(grep -nE '(async-nats|temporalio-sdk)[[:space:]]*=[[:space:]]*"[0-9]' "$f" 2>/dev/null || true)
    [ -z "$hits" ] || { echo "    FAIL T-004: $(basename "$f") inlines a pin (FR-B6-2-041): $hits" >&2; ok=0; }
  done
  # pins MUST appear in the backend workspace Cargo.toml.tmpl
  grep -qE 'async-nats[[:space:]]*=' "$TPL_DIR/backend/Cargo.toml.tmpl" \
    || { echo "    FAIL T-004: async-nats pin not in backend/Cargo.toml.tmpl (FR-B6-2-041)" >&2; ok=0; }
  grep -qE 'temporalio-sdk[[:space:]]*=' "$TPL_DIR/backend/Cargo.toml.tmpl" \
    || { echo "    FAIL T-004: temporalio-sdk pin not in backend/Cargo.toml.tmpl (FR-B6-2-041)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b62_l1_005_wrapper_present() {
  [ -f "$WRAPPER" ] || { echo "    FAIL T-005: scaffolder wrapper missing: $WRAPPER (FR-B6-2-050)" >&2; return 1; }
  [ -x "$WRAPPER" ] || { echo "    FAIL T-005: wrapper not executable (FR-B6-2-050)" >&2; return 1; }
  head -1 "$WRAPPER" | grep -qE '^#!.*(bash|sh)' || { echo "    FAIL T-005: wrapper missing shebang (FR-B6-2-050)" >&2; return 1; }
}

_test_b62_l1_006_wrapper_refuses_while_candidate() {
  [ -f "$WRAPPER" ] || { echo "    FAIL T-006: wrapper missing (FR-B6-2-051)" >&2; return 1; }
  local out; out="$(mk_tmpdir_with_trap b6-2-refuse)"
  trap "rm -rf '$out'" RETURN
  local rc=0
  bash "$WRAPPER" --target "$out/proj" --project-name demo --reverse-domain com.example.demo >/dev/null 2>&1 || rc=$?
  local ok=1
  [ "$rc" = "3" ] || { echo "    FAIL T-006: wrapper exit $rc, expected 3 (candidate refusal) (FR-B6-2-051)" >&2; ok=0; }
  [ ! -d "$out/proj" ] || { echo "    FAIL T-006: refused wrapper still created a scaffold dir (FR-B6-2-051)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b62_l1_007_standards_conformance() {
  local be="$TPL_DIR/backend"
  [ -d "$be" ] || { echo "    FAIL T-007: backend template tree missing (FR-B6-2-060)" >&2; return 1; }
  local ok=1
  _conf() {
    grep -rqE "$1" "$2" 2>/dev/null || { echo "    FAIL T-007: $4 marker absent under ${2#"$TPL_DIR/"} ($3)" >&2; ok=0; }
  }
  # events: NATS JetStream idempotency (Nats-Msg-Id) + inbox dedup
  _conf 'Nats-Msg-Id' "$be/events" "event-driven.md" "JetStream idempotent publish (Nats-Msg-Id)"
  _conf 'InboxDedup|inbox' "$be/events" "event-driven.md" "inbox pattern (consumer dedup)"
  _conf 'idempotency_key' "$be/events" "event-driven.md" "idempotency keys"
  # eventstore: append-only + idempotent append
  _conf 'ON CONFLICT|append-only|EventStore' "$be/eventstore" "event-driven.md" "append-only event store"
  # saga: Temporal activity-only + compensation
  _conf 'activity-only|activity_only|Activity' "$be/saga" "event-driven.md" "Temporal activity-only saga"
  _conf 'compensate|compensation' "$be/saga" "event-driven.md" "saga compensation"
  _conf 'temporalio-sdk|temporal-sdk' "$be/Cargo.toml.tmpl" "orchestration.yaml" "temporalio-sdk pin (feature-gated)"
  [ "$ok" = "1" ]
}

_test_b62_l1_008_asyncapi_contract() {
  local api="$TPL_DIR/shared/asyncapi/asyncapi.yaml.tmpl"
  [ -f "$api" ] || { echo "    FAIL T-008: AsyncAPI contract missing: $api (FR-B6-2-001)" >&2; return 1; }
  grep -qE '^asyncapi:\s*3\.1\.0' "$api" || { echo "    FAIL T-008: asyncapi field is not 3.1.0 (FR-B6-2-001)" >&2; return 1; }
}

_test_b62_l1_009_schema_still_candidate() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-009: schema missing: $SCHEMA" >&2; return 1; }
  local ok=1
  grep -qE '^\s*stage:\s*candidate' "$SCHEMA" || { echo "    FAIL T-009: schema stage != candidate — B.6.2 must NOT promote (promotion is B.6.7)" >&2; ok=0; }
  grep -qE '^\s*scaffoldable:\s*false' "$SCHEMA" || { echo "    FAIL T-009: schema scaffoldable != false (b8-3b candidate⇒false)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b62_l1_010_dispatch_registered() {
  [ -f "$DISPATCH" ] || { echo "    FAIL T-010: dispatch-table missing" >&2; return 1; }
  DISPATCH="$DISPATCH" python3 - <<'PY'
import os, yaml, sys
d = yaml.safe_load(open(os.environ['DISPATCH']))
a = (d.get('archetypes') or {}).get('event-driven-eu')
if not a:
    print("    FAIL T-010: event-driven-eu not registered in dispatch-table (FR-B6-2-050)"); sys.exit(1)
ok = True
if a.get('name') != 'event-driven-eu':
    print("    FAIL T-010: dispatch name mismatch"); ok = False
if a.get('scaffolder') != 'bin/forge-init-event-driven-eu.sh':
    print(f"    FAIL T-010: scaffolder path wrong: {a.get('scaffolder')!r}"); ok = False
if a.get('status') != 'candidate':
    print(f"    FAIL T-010: status must be candidate (got {a.get('status')!r}) — promotion is B.6.7"); ok = False
sys.exit(0 if ok else 1)
PY
}

# ── L2 (toolchain-gated) ──────────────────────────────────────────
_b62_render_plan() {
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

_test_b62_l2_001_render_clean() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-001: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-L2-001: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-L2-001: plan absent" >&2; return 0; }
  [ -f "$OVERLAY_SH" ] || { echo "    SKIP T-L2-001: overlay.sh absent" >&2; return 0; }
  local work; work="$(mktemp -d)"
  local out1="$work/r1" out2="$work/r2"
  _b62_render_plan "$out1" || { echo "    FAIL T-L2-001: overlay render failed (FR-B6-2-003)" >&2; rm -rf "$work"; return 1; }
  local ok=1
  [ -z "$(find "$out1" -name '*.tmpl' 2>/dev/null)" ] || { echo "    FAIL T-L2-001: .tmpl survived render (FR-B6-2-003)" >&2; ok=0; }
  ! grep -rqE '<(project-name|reverse-domain|root-module)>' "$out1" 2>/dev/null || { echo "    FAIL T-L2-001: unsubstituted <placeholder> (FR-B6-2-003)" >&2; ok=0; }
  _b62_render_plan "$out2" || { echo "    FAIL T-L2-001: second render failed (NFR-B6-2-004)" >&2; rm -rf "$work"; return 1; }
  diff -r "$out1" "$out2" >/dev/null 2>&1 || { echo "    FAIL T-L2-001: re-render not byte-stable (NFR-B6-2-004)" >&2; ok=0; }
  rm -rf "$work"
  [ "$ok" = "1" ]
}

_test_b62_l2_002_cargo_check() {
  command -v cargo >/dev/null 2>&1 || { echo "    SKIP T-L2-002: cargo absent" >&2; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-002: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-L2-002: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-L2-002: plan absent" >&2; return 0; }
  [ -d "$TPL_DIR/backend" ] || { echo "    SKIP T-L2-002: backend tree absent" >&2; return 0; }
  local work; work="$(mktemp -d)"; local out="$work/render"
  _b62_render_plan "$out" || { echo "    FAIL T-L2-002: render failed (FR-B6-2-010)" >&2; rm -rf "$work"; return 1; }
  local log="$work/cargo.log"
  if ! ( cd "$out/backend" && cargo check --workspace ) >"$log" 2>&1; then
    if grep -qiE 'failed to (download|get|fetch|load source)|no matching package|could not (connect|resolve)|network|offline' "$log"; then
      echo "    SKIP T-L2-002: cargo check skipped — crate registry unavailable (offline)" >&2
      rm -rf "$work"; return 0
    fi
    echo "    FAIL T-L2-002: cargo check failed on rendered backend (FR-B6-2-010)" >&2
    tail -20 "$log" >&2
    rm -rf "$work"; return 1
  fi
  rm -rf "$work"
  return 0
}

_test_b62_l2_003_wrapper_render_path() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-003: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-L2-003: PyYAML absent" >&2; return 0; }
  [ -f "$WRAPPER" ] || { echo "    SKIP T-L2-003: wrapper absent" >&2; return 0; }
  [ -f "$OVERLAY_SH" ] || { echo "    SKIP T-L2-003: overlay.sh absent" >&2; return 0; }
  local out; out="$(mktemp -d)"; local tgt="$out/proj"
  local rc=0
  FORGE_EDE_FORCE_SCAFFOLD=1 bash "$WRAPPER" \
    --target "$tgt" --project-name probe --reverse-domain example.com --force \
    >/dev/null 2>"$out/err" || rc=$?
  local ok=1
  [ "$rc" = "0" ] || { echo "    FAIL T-L2-003: gated wrapper render exit $rc, expected 0 (FR-B6-2-050)" >&2; tail -5 "$out/err" >&2; ok=0; }
  [ -d "$tgt/backend" ] && [ -d "$tgt/infra" ] && [ -d "$tgt/shared" ] \
    || { echo "    FAIL T-L2-003: wrapper render missing layer roots (FR-B6-2-050)" >&2; ok=0; }
  [ -z "$(find "$tgt" -name '*.tmpl' 2>/dev/null)" ] || { echo "    FAIL T-L2-003: .tmpl survived wrapper render" >&2; ok=0; }
  rm -rf "$out"
  [ "$ok" = "1" ]
}

main() {
  echo "── B.6.2 — b6-2-scaffolder — level $LEVEL ──"
  run_test _test_b62_l1_001_tree_roots
  run_test _test_b62_l1_002_plan_coverage
  run_test _test_b62_l1_003_verify_then_pin_recorded
  run_test _test_b62_l1_004_pins_only_in_cargo
  run_test _test_b62_l1_005_wrapper_present
  run_test _test_b62_l1_006_wrapper_refuses_while_candidate
  run_test _test_b62_l1_007_standards_conformance
  run_test _test_b62_l1_008_asyncapi_contract
  run_test _test_b62_l1_009_schema_still_candidate
  run_test _test_b62_l1_010_dispatch_registered
  case "$LEVEL" in
    *2*)
      run_test _test_b62_l2_001_render_clean
      run_test _test_b62_l2_002_cargo_check
      run_test _test_b62_l2_003_wrapper_render_path
      ;;
  esac
  print_summary
}

main
