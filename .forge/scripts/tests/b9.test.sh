#!/usr/bin/env bash
# Forge — B.9.11 mobile-pwa-first / 2.0.0 promotion gate
# <!-- Audit: B.9.11 (b9-11-promotion-gate) — candidate→stable promotion invariant -->
#
# Asserts the PROMOTED STATE of `mobile-pwa-first / 2.0.0` as a standing invariant —
# not that a promotion happened (ADR-B911-002). A harness that asserted the event would
# be green exactly once and meaningless afterwards; this one catches a half-reverted
# schema, a dispatch status that drifts back, a fixture deleted in a cleanup, or a
# matrix row lost to a doc edit.
#
# WHY THE COHERENCE CELLS EXIST. cli/test/e2e/archetypes-smoke.test.ts partitions
# archetypes off the dispatch `status` field: `scaffoldable = status !== "candidate"`
# (needs a trust fixture) and `candidates = status === "candidate"` (asserts an exit-3
# refusal). So a scaffoldable SCHEMA left at dispatch `status: candidate` is internally
# inconsistent and the refusal test breaks. b7-6 shipped exactly that and needed a
# follow-up commit (d21dda1) to repair it. T-012..T-015 assert the agreement in BOTH
# directions so the half-state cannot return.
#
#   T-001..T-006  schema: stage, scaffoldable, their agreement, header, layer_profile, layers
#   T-007..T-011  dispatch: status, scaffolder, signals, since, the mobile-only alias
#   T-012..T-015  schema <-> dispatch coherence, both directions
#   T-016..T-018  wrapper scaffolds WITHOUT the harness override; the override is inert
#   T-019..T-021  CLI trust fixture (FR-T51-055)
#   T-022..T-025  docs: the matrix row + its status cell, MIGRATION-PATHS, the decision tree
#   T-026..T-028  tooling still runs against the promoted archetype
#   T-L2-001      a real wrapper render produces both surfaces
#   T-L2-002      the rendered tree satisfies the CLI trust fixture's path matrix
#
# 28 L1 + 2 L2. Zero network, zero Docker, zero npm at L1.

set -uo pipefail

# Stream greps use `grep -q ... <<<"$x"` or `< <(producer)`, never `producer | grep -q`:
# under pipefail the early-exiting reader makes the writer take SIGPIPE (141) and the
# assertion reports the opposite of the truth (t5-helpers-sigpipe).

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

SCHEMA="$FORGE_ROOT/.forge/schemas/mobile-pwa-first/2.0.0.yaml"
DISPATCH="$FORGE_ROOT/.forge/scaffolding/dispatch-table.yml"
WRAPPER="$FORGE_ROOT/bin/forge-init-mobile-pwa-first.sh"
FIXTURE="$FORGE_ROOT/cli/test/e2e/archetype-fixtures/mobile-pwa-first.yml"
ARCHETYPES_DOC="$FORGE_ROOT/docs/ARCHETYPES.md"
MIGRATION_PATHS="$FORGE_ROOT/docs/MIGRATION-PATHS.md"
MIGRATE_MPWA="$FORGE_ROOT/bin/forge-migrate-mobile-pwa.sh"
GEN_BLOC="$FORGE_ROOT/bin/forge-gen-bloc.sh"

PROBE_NAME="promoprobe"
# The org the cli smoke test uses, deliberately: T-021 checks the fixture against a
# render, and a fixture path that depends on the org (the Kotlin package directory)
# would agree with a differently-organised probe and disagree with CI. That is exactly
# how the first version of this brick shipped a fixture the cli Vitest job rejected.
PROBE_DOMAIN="dev.forge.test"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

_have_py_yaml() { command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; }

# The dispatch entry for mobile-pwa-first, read as YAML rather than grepped. A bare
# `grep "^    status:"` matches whichever archetype block happens to come first — the
# trap b9-3 T-023 documents, on a table where a candidate→stable flip cascades.
_dispatch_field() {
  _have_py_yaml || return 1
  python3 - "$DISPATCH" "$1" <<'PY'
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
e = (d.get('archetypes') or {}).get('mobile-pwa-first') or {}
v = e.get(sys.argv[2])
print('' if v is None else v)
PY
}

_schema_field() {
  sed -n "s/^$1:[[:space:]]*//p" "$SCHEMA" | head -1 | tr -d '"' | awk '{print $1}'
}

# ─── Schema (T-001..T-006) ───────────────────────────────────────────────────

_test_b9_l1_001_stage_stable() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-001: schema missing: $SCHEMA (FR-B911-002)" >&2; return 1; }
  local v; v="$(_schema_field stage)"
  [ "$v" = "stable" ] \
    || { echo "    FAIL T-001: stage='$v', expected 'stable' — the promotion is B.9.11's deliverable (FR-B911-002)" >&2; return 1; }
}

_test_b9_l1_002_scaffoldable_true() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-002: schema missing (see T-001)" >&2; return 1; }
  local v; v="$(_schema_field scaffoldable)"
  [ "$v" = "true" ] \
    || { echo "    FAIL T-002: scaffoldable='$v', expected 'true' (FR-B911-002)" >&2; return 1; }
}

# The validator's rule is `candidate ⇒ scaffoldable: false`; stable is exempt. Asserting
# the PAIR rather than the two fields separately is what catches a half-reverted flip.
_test_b9_l1_003_stage_and_scaffoldable_agree() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-003: schema missing (see T-001)" >&2; return 1; }
  local stage sc; stage="$(_schema_field stage)"; sc="$(_schema_field scaffoldable)"
  if [ "$stage" = "candidate" ] && [ "$sc" = "true" ]; then
    echo "    FAIL T-003: stage=candidate with scaffoldable=true — forbidden by the b8-3b validator (FR-B911-002)" >&2; return 1
  fi
  if [ "$stage" = "stable" ] && [ "$sc" != "true" ]; then
    echo "    FAIL T-003: stage=stable with scaffoldable='$sc' — a stable schema that cannot scaffold (FR-B911-002)" >&2; return 1
  fi
}

_test_b9_l1_004_header_records_the_promotion() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-004: schema missing (see T-001)" >&2; return 1; }
  local head; head="$(head -40 "$SCHEMA")"
  local ok=1
  grep -qF -- "B.9.11" <<<"$head" \
    || { echo "    FAIL T-004: the header no longer names B.9.11 as the promoter (FR-B911-002)" >&2; ok=0; }
  grep -qiE "promot(ed|ion)" <<<"$head" \
    || { echo "    FAIL T-004: the header does not record the promotion (FR-B911-002)" >&2; ok=0; }
  # The header used to say the schema IS a candidate. After the flip that sentence is
  # false, and a header describing a state that no longer holds is the defect b9-4 was
  # opened to fix one file over.
  if grep -qE "This schema is \`?stage: candidate" <<<"$head"; then
    echo "    FAIL T-004: the header still declares the schema a candidate (FR-B911-002)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b9_l1_005_layer_profile_client_only() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-005: schema missing (see T-001)" >&2; return 1; }
  grep -qE "^layer_profile:[[:space:]]*client-only" "$SCHEMA" \
    || { echo "    FAIL T-005: layer_profile is no longer client-only — the promotion must not change the archetype's shape (NFR-B911-003)" >&2; return 1; }
}

_test_b9_l1_006_two_layers() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-006: schema missing (see T-001)" >&2; return 1; }
  _have_py_yaml || { echo "    FAIL T-006: python3+PyYAML required" >&2; return 1; }
  python3 - "$SCHEMA" <<'PY' >&2
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
ids = sorted(str((l or {}).get('id','')) for l in (d.get('layers') or []))
if ids != ['app', 'web-pwa']:
    print(f"    FAIL T-006: layers are {ids}, expected ['app', 'web-pwa'] (NFR-B911-003)")
    raise SystemExit(1)
PY
}

# ─── Dispatch (T-007..T-011) ─────────────────────────────────────────────────

_test_b9_l1_007_dispatch_status_stable() {
  local v; v="$(_dispatch_field status)" || { echo "    FAIL T-007: python3+PyYAML required" >&2; return 1; }
  [ "$v" = "stable" ] \
    || { echo "    FAIL T-007: dispatch status='$v', expected 'stable'. There is no green state that keeps 'candidate' once the schema scaffolds — the cli smoke test partitions on this field (FR-B911-003)" >&2; return 1; }
}

_test_b9_l1_008_dispatch_scaffolder() {
  local v; v="$(_dispatch_field scaffolder)" || return 1
  [ "$v" = "bin/forge-init-mobile-pwa-first.sh" ] \
    || { echo "    FAIL T-008: dispatch scaffolder='$v' (FR-B911-003)" >&2; return 1; }
  [ -x "$FORGE_ROOT/$v" ] \
    || { echo "    FAIL T-008: the named scaffolder is not executable: $v (FR-B911-003)" >&2; return 1; }
}

_test_b9_l1_009_dispatch_signals() {
  _have_py_yaml || { echo "    FAIL T-009: python3+PyYAML required" >&2; return 1; }
  python3 - "$DISPATCH" <<'PY' >&2
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
e = (d.get('archetypes') or {}).get('mobile-pwa-first') or {}
sig = set(e.get('signals') or [])
want = {'pubspec.yaml', 'web-pwa/package.json'}
if not want <= sig:
    print(f"    FAIL T-009: signals {sorted(sig)} miss {sorted(want - sig)} — auto-detection cannot tell this archetype from mobile-only without the web-pwa signal (FR-B911-003)")
    raise SystemExit(1)
PY
}

_test_b9_l1_010_dispatch_since() {
  local v; v="$(_dispatch_field since)" || return 1
  [ -n "$v" ] \
    || { echo "    FAIL T-010: dispatch entry declares no since: (FR-B911-003)" >&2; return 1; }
}

# The alias must keep pointing here. A promotion that orphaned mobile-only's `target:`
# would leave every v0.3.0 adopter without a documented successor.
_test_b9_l1_011_mobile_only_alias_intact() {
  _have_py_yaml || { echo "    FAIL T-011: python3+PyYAML required" >&2; return 1; }
  python3 - "$DISPATCH" <<'PY' >&2
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
e = (d.get('archetypes') or {}).get('mobile-only') or {}
bad = False
if e.get('status') != 'legacy_alias':
    print(f"    FAIL T-011: mobile-only status={e.get('status')!r}, expected 'legacy_alias' (FR-B911-003)"); bad = True
if e.get('target') != 'mobile-pwa-first':
    print(f"    FAIL T-011: mobile-only target={e.get('target')!r}, expected 'mobile-pwa-first' (FR-B911-003)"); bad = True
raise SystemExit(1 if bad else 0)
PY
}

# ─── Coherence, both directions (T-012..T-015) ───────────────────────────────

_test_b9_l1_012_scaffoldable_schema_implies_non_candidate_dispatch() {
  local sc st; sc="$(_schema_field scaffoldable)"; st="$(_dispatch_field status)" || return 1
  if [ "$sc" = "true" ] && [ "$st" = "candidate" ]; then
    echo "    FAIL T-012: the schema scaffolds but the dispatch says candidate — the cli smoke test will assert an exit-3 refusal that no longer happens (d21dda1, FR-B911-003)" >&2
    return 1
  fi
}

_test_b9_l1_013_non_candidate_dispatch_implies_scaffoldable_schema() {
  local sc st; sc="$(_schema_field scaffoldable)"; st="$(_dispatch_field status)" || return 1
  if [ "$st" != "candidate" ] && [ "$sc" != "true" ]; then
    echo "    FAIL T-013: the dispatch says '$st' but the schema is scaffoldable='$sc' — the cli smoke test will try to scaffold and require a fixture for an archetype that refuses (FR-B911-003)" >&2
    return 1
  fi
}

# FR-T51-055: every archetype the dispatch reports as scaffoldable needs a trust fixture.
_test_b9_l1_014_scaffoldable_implies_fixture() {
  local st; st="$(_dispatch_field status)" || return 1
  if [ "$st" != "candidate" ] && [ ! -f "$FIXTURE" ]; then
    echo "    FAIL T-014: dispatch status='$st' (scaffoldable) but no CLI trust fixture at $FIXTURE (FR-T51-055 / FR-B911-004)" >&2
    return 1
  fi
}

_test_b9_l1_015_schema_name_matches_dir() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-015: schema missing (see T-001)" >&2; return 1; }
  local n; n="$(_schema_field name)"
  [ "$n" = "mobile-pwa-first" ] \
    || { echo "    FAIL T-015: schema name='$n' does not match its directory (FR-B911-002)" >&2; return 1; }
}

# ─── Wrapper (T-016..T-018) ──────────────────────────────────────────────────

# THE test the promotion exists for: the wrapper scaffolds with NO override. Its gate is
# data-driven off the schema, so this proves the flip rather than assuming it.
_test_b9_l1_016_wrapper_scaffolds_without_override() {
  [ -x "$WRAPPER" ] || { echo "    FAIL T-016: wrapper missing or not executable (FR-B911-007)" >&2; return 1; }
  local work; work="$(mktemp -d -t forge-b911-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '$work'" RETURN
  SOURCE_DATE_EPOCH=0 bash "$WRAPPER" --target "$work/out" \
    --project-name "$PROBE_NAME" --reverse-domain "$PROBE_DOMAIN" --force >/dev/null 2>&1
  local rc=$?
  [ "$rc" = "0" ] \
    || { echo "    FAIL T-016: wrapper exited $rc WITHOUT FORGE_MPF_FORCE_SCAFFOLD — a promoted archetype must scaffold unaided (FR-B911-007)" >&2; return 1; }
  [ -f "$work/out/pubspec.yaml" ] \
    || { echo "    FAIL T-016: no pubspec.yaml in the render (FR-B911-007)" >&2; return 1; }
}

_test_b9_l1_017_render_carries_both_surfaces() {
  [ -x "$WRAPPER" ] || { echo "    FAIL T-017: wrapper missing (see T-016)" >&2; return 1; }
  local work; work="$(mktemp -d -t forge-b911s-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '$work'" RETURN
  SOURCE_DATE_EPOCH=0 bash "$WRAPPER" --target "$work/out" \
    --project-name "$PROBE_NAME" --reverse-domain "$PROBE_DOMAIN" --force >/dev/null 2>&1 \
    || { echo "    FAIL T-017: render failed (see T-016)" >&2; return 1; }
  local ok=1 f
  for f in lib/main.dart web-pwa/package.json oidc-provider.json .forge/scaffold-manifest.yaml; do
    [ -f "$work/out/$f" ] \
      || { echo "    FAIL T-017: $f absent — a promoted mobile-pwa-first render carries BOTH surfaces (FR-B911-002)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

# The override is now inert: it must not change the outcome.
_test_b9_l1_018_override_is_inert() {
  [ -x "$WRAPPER" ] || { echo "    FAIL T-018: wrapper missing (see T-016)" >&2; return 1; }
  local work; work="$(mktemp -d -t forge-b911o-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '$work'" RETURN
  SOURCE_DATE_EPOCH=0 FORGE_MPF_FORCE_SCAFFOLD=1 bash "$WRAPPER" --target "$work/out" \
    --project-name "$PROBE_NAME" --reverse-domain "$PROBE_DOMAIN" --force >/dev/null 2>&1
  local rc=$?
  [ "$rc" = "0" ] \
    || { echo "    FAIL T-018: with the override set the wrapper exited $rc; post-promotion it must be inert, not harmful (FR-B911-007)" >&2; return 1; }
}

# ─── CLI trust fixture (T-019..T-021) ────────────────────────────────────────

_test_b9_l1_019_fixture_exists() {
  [ -f "$FIXTURE" ] \
    || { echo "    FAIL T-019: $FIXTURE missing — FR-T51-055 requires one per scaffoldable archetype (FR-B911-004)" >&2; return 1; }
}

_test_b9_l1_020_fixture_shape() {
  [ -f "$FIXTURE" ] || { echo "    FAIL T-020: fixture missing (see T-019)" >&2; return 1; }
  _have_py_yaml || { echo "    FAIL T-020: python3+PyYAML required" >&2; return 1; }
  python3 - "$FIXTURE" <<'PY' >&2
import sys, yaml
d = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
bad = False
if d.get('archetype') != 'mobile-pwa-first':
    print(f"    FAIL T-020: fixture archetype={d.get('archetype')!r} (FR-B911-004)"); bad = True
if d.get('has_rust_backend') is not False:
    print("    FAIL T-020: has_rust_backend must be false — the archetype is client-only (FR-B911-004)"); bad = True
if d.get('has_flutter_frontend') is not True:
    print("    FAIL T-020: has_flutter_frontend must be true (FR-B911-004)"); bad = True
req = d.get('required_paths') or []
if len(req) < 10:
    print(f"    FAIL T-020: {len(req)} required_paths, expected >= 10 (FR-B911-004)"); bad = True
for p in ('web-pwa/package.json', 'oidc-provider.json'):
    if p not in req:
        print(f"    FAIL T-020: required_paths omits {p} — the surface the promotion is about (FR-B911-004)"); bad = True
raise SystemExit(1 if bad else 0)
PY
}

# The fixture must describe a tree the scaffolder actually produces. A fixture listing
# paths that are never rendered is a test that can only fail, and one omitting paths that
# are is a test that cannot.
_test_b9_l1_021_fixture_matches_a_render() {
  [ -f "$FIXTURE" ] || { echo "    FAIL T-021: fixture missing (see T-019)" >&2; return 1; }
  [ -x "$WRAPPER" ] || { echo "    FAIL T-021: wrapper missing (see T-016)" >&2; return 1; }
  _have_py_yaml || { echo "    FAIL T-021: python3+PyYAML required" >&2; return 1; }
  local work; work="$(mktemp -d -t forge-b911f-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '$work'" RETURN
  SOURCE_DATE_EPOCH=0 bash "$WRAPPER" --target "$work/out" \
    --project-name "$PROBE_NAME" --reverse-domain "$PROBE_DOMAIN" --force >/dev/null 2>&1 \
    || { echo "    FAIL T-021: render failed (see T-016)" >&2; return 1; }
  FIXTURE="$FIXTURE" OUT="$work/out" python3 - <<'PY' >&2
import os, sys, yaml
d = yaml.safe_load(open(os.environ['FIXTURE'], encoding='utf-8')) or {}
out = os.environ['OUT']
bad = False
for p in (d.get('required_paths') or []):
    if not os.path.exists(os.path.join(out, p)):
        print(f"    FAIL T-021: fixture requires {p}, which a real render does not produce (FR-B911-004)"); bad = True
for p in (d.get('forbidden_paths') or []):
    if os.path.exists(os.path.join(out, p)):
        print(f"    FAIL T-021: fixture forbids {p}, which a real render DOES produce (FR-B911-004)"); bad = True
raise SystemExit(1 if bad else 0)
PY
}

# ─── Docs (T-022..T-025) ─────────────────────────────────────────────────────

_test_b9_l1_022_matrix_row_present() {
  [ -f "$ARCHETYPES_DOC" ] || { echo "    FAIL T-022: docs/ARCHETYPES.md missing (FR-B911-006)" >&2; return 1; }
  local rows
  rows="$(awk '/^## Available archetypes/{f=1;next} f&&/^## /{exit} f&&/^\|/{print}' "$ARCHETYPES_DOC")"
  grep -qF -- '| `mobile-pwa-first`' <<<"$rows" \
    || { echo "    FAIL T-022: no mobile-pwa-first row in the Available archetypes table — a promoted archetype is pickable and must be listed (FR-B911-006)" >&2; return 1; }
}

_test_b9_l1_023_matrix_row_says_active() {
  [ -f "$ARCHETYPES_DOC" ] || { echo "    FAIL T-023: docs/ARCHETYPES.md missing (see T-022)" >&2; return 1; }
  local row
  row="$(awk '/^## Available archetypes/{f=1;next} f&&/^## /{exit} f&&/^\| `mobile-pwa-first`/{print}' "$ARCHETYPES_DOC")"
  [ -n "$row" ] || { echo "    FAIL T-023: row absent (see T-022)" >&2; return 1; }
  grep -qF -- "Active" <<<"$row" \
    || { echo "    FAIL T-023: the mobile-pwa-first row does not read Active — it is stable and scaffoldable (FR-B911-006)" >&2; return 1; }
  if grep -qF -- "candidate" <<<"$row"; then
    echo "    FAIL T-023: the row still says candidate (FR-B911-006)" >&2; return 1
  fi
}

_test_b9_l1_024_migration_paths_no_longer_candidate() {
  [ -f "$MIGRATION_PATHS" ] || { echo "    FAIL T-024: docs/MIGRATION-PATHS.md missing (FR-B911-006)" >&2; return 1; }
  local sec
  sec="$(awk '/^## B\.9 /{f=1;print;next} f&&/^## /{exit} f{print}' "$MIGRATION_PATHS")"
  [ -n "$sec" ] || { echo "    FAIL T-024: no B.9 section (FR-B911-006)" >&2; return 1; }
  local ok=1
  if grep -qF -- 'stage: candidate' <<<"$sec"; then
    echo "    FAIL T-024: the section still calls the target schema a candidate (FR-B911-006)" >&2; ok=0
  fi
  if grep -qF -- 'exit 3' <<<"$sec"; then
    echo "    FAIL T-024: the section still says forge init exits 3 — it renders now (FR-B911-006)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b9_l1_025_decision_tree_survives() {
  [ -f "$ARCHETYPES_DOC" ] || { echo "    FAIL T-025: docs/ARCHETYPES.md missing (see T-022)" >&2; return 1; }
  grep -qE '^## Choosing the mobile channel' "$ARCHETYPES_DOC" \
    || { echo "    FAIL T-025: the B.9.4 channel decision tree is gone — the promotion must not cost it (NFR-B911-003)" >&2; return 1; }
}

# ─── Tooling (T-026..T-028) ──────────────────────────────────────────────────

_test_b9_l1_026_migration_script_still_runs() {
  [ -x "$MIGRATE_MPWA" ] \
    || { echo "    FAIL T-026: $MIGRATE_MPWA missing or not executable (NFR-B911-003)" >&2; return 1; }
  bash "$MIGRATE_MPWA" --help >/dev/null 2>&1 \
    || { echo "    FAIL T-026: the B.9.9 migration script no longer answers --help (NFR-B911-003)" >&2; return 1; }
}

_test_b9_l1_027_bloc_generator_still_runs() {
  [ -x "$GEN_BLOC" ] \
    || { echo "    FAIL T-027: $GEN_BLOC missing or not executable (NFR-B911-003)" >&2; return 1; }
  bash "$GEN_BLOC" --help >/dev/null 2>&1 \
    || { echo "    FAIL T-027: the B.9.5 generator no longer answers --help (NFR-B911-003)" >&2; return 1; }
}

# The promotion must not have been bought by loosening the archetype's own rule.
#
# NEGATIVE, so it asserts on the DECLARED DEPENDENCIES, never on a textual occurrence.
# The template's `_audit` block says, at line 11, "NO @connectrpc/* dependency:
# mobile-pwa-first is layer_profile client-only and..." — a bare grep reads that
# explanation as the violation. The first version of this cell did exactly that and
# went red on a correct tree. Same trap as b9-2 T-013/T-014, same fix.
_test_b9_l1_028_no_connect_in_webpwa() {
  local pkg="$FORGE_ROOT/.forge/templates/archetypes/mobile-pwa-first/2.0.0/web-pwa/package.json.tmpl"
  [ -f "$pkg" ] || { echo "    FAIL T-028: web-pwa package.json template missing (NFR-B911-003)" >&2; return 1; }
  _have_py_yaml || { echo "    FAIL T-028: python3 required" >&2; return 1; }
  python3 - "$pkg" <<'PYEOF' >&2
import sys, json
d = json.load(open(sys.argv[1], encoding='utf-8'))
bad = [k for sec in ('dependencies', 'devDependencies', 'peerDependencies')
       for k in d.get(sec, {}) if k.startswith('@connectrpc/')]
if bad:
    print(f"    FAIL T-028: @connectrpc dependency declared in a client-only archetype: {bad} — ADR-B9-2-001 (NFR-B911-003)")
    raise SystemExit(1)
PYEOF
}

# ─── L2 (opt-in) ─────────────────────────────────────────────────────────────

_test_b9_l2_001_cli_init_renders() {
  local cli="$FORGE_ROOT/cli/dist/index.js"
  if [ ! -f "$cli" ]; then
    echo "    SKIP T-L2-001: build+bundle the CLI to run the live render check" >&2
    return 0
  fi
  local tmp; tmp="$(mktemp -d -t forge-b911cli-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" RETURN
  ( cd "$tmp" && node "$cli" init smoke_mobile_pwa_first --archetype mobile-pwa-first \
      --org dev.forge.test >/dev/null 2>&1 )
  local rc=$?
  [ "$rc" = "0" ] \
    || { echo "    FAIL T-L2-001: forge init exited $rc; a promoted archetype renders instead of refusing (FR-B911-002)" >&2; return 1; }
  [ -f "$tmp/smoke_mobile_pwa_first/web-pwa/package.json" ] \
    || { echo "    FAIL T-L2-001: the CLI render carries no web-pwa surface (FR-B911-002)" >&2; return 1; }
}

_test_b9_l2_002_cli_render_matches_fixture() {
  local cli="$FORGE_ROOT/cli/dist/index.js"
  if [ ! -f "$cli" ] || [ ! -f "$FIXTURE" ]; then
    echo "    SKIP T-L2-002: needs a built CLI and the fixture" >&2
    return 0
  fi
  local tmp; tmp="$(mktemp -d -t forge-b911cf-XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" RETURN
  ( cd "$tmp" && node "$cli" init smoke_mobile_pwa_first --archetype mobile-pwa-first \
      --org dev.forge.test >/dev/null 2>&1 ) || {
    echo "    FAIL T-L2-002: render failed (see T-L2-001)" >&2; return 1; }
  FIXTURE="$FIXTURE" OUT="$tmp/smoke_mobile_pwa_first" python3 - <<'PY' >&2
import os, yaml
d = yaml.safe_load(open(os.environ['FIXTURE'], encoding='utf-8')) or {}
out = os.environ['OUT']
bad = False
for p in (d.get('required_paths') or []):
    if not os.path.exists(os.path.join(out, p)):
        print(f"    FAIL T-L2-002: the CLI render lacks fixture path {p} (FR-B911-004)"); bad = True
raise SystemExit(1 if bad else 0)
PY
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.9.11 promotion gate — mobile-pwa-first / 2.0.0 ──"
  run_test _test_b9_l1_001_stage_stable
  run_test _test_b9_l1_002_scaffoldable_true
  run_test _test_b9_l1_003_stage_and_scaffoldable_agree
  run_test _test_b9_l1_004_header_records_the_promotion
  run_test _test_b9_l1_005_layer_profile_client_only
  run_test _test_b9_l1_006_two_layers
  run_test _test_b9_l1_007_dispatch_status_stable
  run_test _test_b9_l1_008_dispatch_scaffolder
  run_test _test_b9_l1_009_dispatch_signals
  run_test _test_b9_l1_010_dispatch_since
  run_test _test_b9_l1_011_mobile_only_alias_intact
  run_test _test_b9_l1_012_scaffoldable_schema_implies_non_candidate_dispatch
  run_test _test_b9_l1_013_non_candidate_dispatch_implies_scaffoldable_schema
  run_test _test_b9_l1_014_scaffoldable_implies_fixture
  run_test _test_b9_l1_015_schema_name_matches_dir
  run_test _test_b9_l1_016_wrapper_scaffolds_without_override
  run_test _test_b9_l1_017_render_carries_both_surfaces
  run_test _test_b9_l1_018_override_is_inert
  run_test _test_b9_l1_019_fixture_exists
  run_test _test_b9_l1_020_fixture_shape
  run_test _test_b9_l1_021_fixture_matches_a_render
  run_test _test_b9_l1_022_matrix_row_present
  run_test _test_b9_l1_023_matrix_row_says_active
  run_test _test_b9_l1_024_migration_paths_no_longer_candidate
  run_test _test_b9_l1_025_decision_tree_survives
  run_test _test_b9_l1_026_migration_script_still_runs
  run_test _test_b9_l1_027_bloc_generator_still_runs
  run_test _test_b9_l1_028_no_connect_in_webpwa
  case "$LEVEL" in
    *2*)
      run_test _test_b9_l2_001_cli_init_renders
      run_test _test_b9_l2_002_cli_render_matches_fixture
      ;;
  esac
  print_summary
}

main
