#!/usr/bin/env bash
# Forge — B.7.1 ai-native-rag 1.0.0 candidate schema harness
# <!-- Audit: B.7.1 (b7-1-schema) — ai-native-rag/1.0.0 archetype scaffold schema gate -->
#
# Validates the b7-1-schema deliverable .forge/schemas/ai-native-rag/1.0.0.yaml:
#
#   T-001  1.0.0.yaml exists at the versioned path (FR-B7-1-001/002)
#   T-002  file parses as valid YAML mapping root (FR-B7-1-001)
#   T-003  name == 'ai-native-rag' (FR-B7-1-002 + b8-3b name==dir invariant)
#   T-004  version == '1.0.0' (FR-B7-1-002 + b8-3b filename<->version invariant)
#   T-005  stage == 'candidate' (FR-B7-1-002)
#   T-006  scaffoldable is False (FR-B7-1-003 + b8-3b candidate=>scaffoldable:false)
#   T-007  tdd_enforced/bdd_required_for_user_facing/coverage_threshold (FR-B7-1-004)
#   T-008  layers[] ids ⊇ {backend, frontend, infra} (FR-B7-1-010)
#   T-009  frontend layer has a qwik web-public surface (FR-B7-1-011/012, ADR-B7-1-004)
#   T-010  every components[] entry has a name; components non-empty (FR-B7-1-030)
#   T-011  existing standard: refs resolve to real files (FR-B7-1-031)
#   T-012  no component carries a forbidden inline pin key {version,pin,image} (FR-B7-1-031)
#   T-013  no components[] scalar value matches \d+\.\d+ (no inline pin crept in) (FR-B7-1-032)
#   T-014  phases inline & include ai_brainstorm + embeddings-pipeline + prompt-audit (FR-B7-1-020..023, ADR-B7-1-001)
#   T-015  ai_specifics present (fallback_mandatory, pii_handling, token_budget_documented) (FR-B7-1-024)
#   T-016  deferred components {llm-gateway,mcp-servers,rag-pipeline} carry delivered_by:B.7.3, no standard ref (FR-B7-1-032, ADR-B7-1-003)
#   T-017  ai_fallback_required True + cross_layer.agent Janus + fr_id_prefix_cross_layer FR-GL- (FR-B7-1-013/024)
#
#   T-018  header block documents candidate semantics (candidate/scaffoldable/additive) (FR-B7-1-005)
#   T-L2-001 (opt-in) forge init --archetype ai-native-rag ⇒ exit 2 unknown-archetype refusal (dispatch-table gate; FORGE_B7_1_LIVE=1 + built CLI; skip-pass otherwise)
#
# 18 L1 + 1 L2 tests. Performance budget: L1 ≤ 5 s, zero net/Docker. Structural
# invariants (name==dir, version==file, layer triple, candidate=>scaffoldable:false,
# phases non-empty) are ALSO enforced generically by validate-foundations.sh
# check_versioned_schema_siblings (B.8.3.b); this harness adds the AI-specific
# content asserts that the generic validator does not cover.

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

SCHEMA="$FORGE_ROOT/.forge/schemas/ai-native-rag/1.0.0.yaml"
STANDARDS_DIR="$FORGE_ROOT/.forge/standards"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Shared YAML parse helper (single python3 call, cached) ───────────────────
_py() {
  python3 - "$SCHEMA" "$STANDARDS_DIR" <<'PYEOF'
import sys, yaml, re, os

schema_path = sys.argv[1]
std_dir     = sys.argv[2]

try:
    with open(schema_path, 'r', encoding='utf-8') as f:
        d = yaml.safe_load(f)
except FileNotFoundError:
    print("MISSING"); sys.exit(0)
except yaml.YAMLError as e:
    print(f"YAML_ERROR:{e}"); sys.exit(0)

if not isinstance(d, dict):
    print("NOT_MAPPING"); sys.exit(0)

r = {}

# identity
r['name']    = d.get('name', 'MISSING')
r['version'] = d.get('version', 'MISSING')
r['stage']   = d.get('stage', 'MISSING')
r['scaffoldable'] = repr(d.get('scaffoldable', 'MISSING'))

# tdd/bdd/coverage + ai flags
r['tdd_enforced']                   = repr(d.get('tdd_enforced', 'MISSING'))
r['bdd_required_for_user_facing']   = repr(d.get('bdd_required_for_user_facing', 'MISSING'))
r['coverage_threshold']             = repr(d.get('coverage_threshold', 'MISSING'))
r['ai_fallback_required']           = repr(d.get('ai_fallback_required', 'MISSING'))

# layers
layers = d.get('layers', []) or []
layer_ids = {l['id'] for l in layers if isinstance(l, dict) and 'id' in l}
r['layer_ids'] = ','.join(sorted(layer_ids))

# frontend surfaces (qwik web-public)
fe = next((l for l in layers if isinstance(l, dict) and l.get('id') == 'frontend'), None)
if fe:
    surfaces = fe.get('surfaces', []) or []
    qwik_pub = any(
        isinstance(s, dict) and s.get('id') == 'web-public' and s.get('stack') == 'qwik'
        for s in surfaces
    )
    r['qwik_web_public'] = repr(qwik_pub)
else:
    r['qwik_web_public'] = 'NO_FRONTEND'

# components
components = d.get('components', []) or []
comp_names = [c.get('name', 'MISSING') for c in components if isinstance(c, dict)]
r['comp_count'] = str(len(comp_names))
r['comp_missing_name'] = str(any(n == 'MISSING' for n in comp_names))

# existing standard refs resolve
bad_refs = []
for c in components:
    if not isinstance(c, dict): continue
    ref = c.get('standard')
    if ref and not os.path.isfile(os.path.join(std_dir, ref)):
        bad_refs.append(ref)
r['bad_standard_refs'] = ','.join(bad_refs) if bad_refs else 'OK'

# forbidden inline pin keys
forbidden = {'version', 'pin', 'image'}
pin_viol = []
for c in components:
    if not isinstance(c, dict): continue
    hit = set(c.keys()) & forbidden
    if hit:
        pin_viol.append(f"{c.get('name','?')}:{','.join(sorted(hit))}")
r['pin_violations'] = ';'.join(pin_viol) if pin_viol else 'OK'

# no scalar value at components[] level matches ^\d+\.\d+ (value-walk, not grep)
vre = re.compile(r'^\d+\.\d+')
val_viol = []
for c in components:
    if not isinstance(c, dict): continue
    for k, v in c.items():
        if isinstance(v, str) and vre.match(v):
            val_viol.append(f"{c.get('name','?')}.{k}={v!r}")
r['val_violations'] = ';'.join(val_viol) if val_viol else 'OK'

# phases inline & include the AI-First + B.7.1 ids
phases = d.get('phases', []) or []
phase_ids = {p['id'] for p in phases if isinstance(p, dict) and 'id' in p}
r['phase_count'] = str(len(phases))
for need in ('ai_brainstorm', 'embeddings-pipeline', 'prompt-audit'):
    r[f'phase_{need}'] = str(need in phase_ids)

# ai_specifics
ais = d.get('ai_specifics', {}) or {}
r['ais_fallback']   = repr(ais.get('fallback_mandatory', 'MISSING'))
r['ais_pii']        = repr(ais.get('pii_handling', 'MISSING'))
r['ais_token']      = repr(ais.get('token_budget_documented', 'MISSING'))

# deferred components carry delivered_by:B.7.3 and no standard ref
deferred = {'llm-gateway', 'mcp-servers', 'rag-pipeline'}
bad_def = []
seen_def = set()
for c in components:
    if not isinstance(c, dict): continue
    nm = c.get('name')
    if nm in deferred:
        seen_def.add(nm)
        if c.get('delivered_by') != 'B.7.3':
            bad_def.append(f"{nm}:delivered_by={c.get('delivered_by')!r}")
        if 'standard' in c:
            bad_def.append(f"{nm}:has-standard-ref")
missing_def = deferred - seen_def
if missing_def:
    bad_def.append("missing:" + ','.join(sorted(missing_def)))
r['deferred_check'] = ';'.join(bad_def) if bad_def else 'OK'

# cross-layer parity
cl = d.get('cross_layer', {}) or {}
r['cross_layer_agent'] = cl.get('agent', 'MISSING') if isinstance(cl, dict) else 'NOT_MAPPING'
r['fr_cross'] = d.get('fr_id_prefix_cross_layer', 'MISSING')

for k, v in r.items():
    print(f"{k}={v}")
PYEOF
}

_PY_OUT=""
_ensure_py_cache() {
  if [ -z "$_PY_OUT" ]; then
    _PY_OUT=$(_py 2>&1) || { echo "    python3 helper failed: $_PY_OUT" >&2; return 1; }
  fi
}
_get() { echo "$_PY_OUT" | grep "^${1}=" | head -1 | cut -d= -f2-; }

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b71_l1_001_schema_exists() {
  if [ ! -f "$SCHEMA" ]; then
    echo "    FAIL T-001: 1.0.0.yaml missing: $SCHEMA (FR-B7-1-001/002)" >&2; return 1
  fi
}

_test_b71_l1_002_valid_yaml_mapping() {
  local out; out=$(_py 2>&1) || { echo "    FAIL T-002: _py helper error: $out" >&2; return 1; }
  case "$(echo "$out" | head -1)" in
    MISSING)     echo "    FAIL T-002: schema missing (should be caught by T-001)" >&2; return 1 ;;
    YAML_ERROR*) echo "    FAIL T-002: YAML parse error" >&2; return 1 ;;
    NOT_MAPPING) echo "    FAIL T-002: root is not a YAML mapping" >&2; return 1 ;;
  esac
}

_test_b71_l1_003_name() {
  _ensure_py_cache || return 1
  local v; v=$(_get name)
  [ "$v" = "ai-native-rag" ] || { echo "    FAIL T-003: name='$v' != 'ai-native-rag' (FR-B7-1-002)" >&2; return 1; }
}

_test_b71_l1_004_version() {
  _ensure_py_cache || return 1
  local v; v=$(_get version)
  [ "$v" = "1.0.0" ] || { echo "    FAIL T-004: version='$v' != '1.0.0' (FR-B7-1-002)" >&2; return 1; }
}

_test_b71_l1_005_stage() {
  _ensure_py_cache || return 1
  local v; v=$(_get stage)
  [ "$v" = "candidate" ] || { echo "    FAIL T-005: stage='$v' != 'candidate' (FR-B7-1-002)" >&2; return 1; }
}

_test_b71_l1_006_scaffoldable_false() {
  _ensure_py_cache || return 1
  local v; v=$(_get scaffoldable)
  [ "$v" = "False" ] || { echo "    FAIL T-006: scaffoldable=$v != False (FR-B7-1-003; b8-3b candidate⇒scaffoldable:false)" >&2; return 1; }
}

_test_b71_l1_007_tdd_bdd_coverage() {
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get tdd_enforced)" = "True" ] || { echo "    FAIL T-007: tdd_enforced != True (FR-B7-1-004)" >&2; ok=0; }
  [ "$(_get bdd_required_for_user_facing)" = "True" ] || { echo "    FAIL T-007: bdd_required_for_user_facing != True (FR-B7-1-004)" >&2; ok=0; }
  [ "$(_get coverage_threshold)" = "80" ] || { echo "    FAIL T-007: coverage_threshold != 80 (FR-B7-1-004)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b71_l1_008_layer_triple() {
  _ensure_py_cache || return 1
  local ids; ids=$(_get layer_ids); local ok=1
  case "$ids" in *backend*)  ;; *) echo "    FAIL T-008: 'backend' missing (ids=$ids) (FR-B7-1-010)" >&2; ok=0 ;; esac
  case "$ids" in *frontend*) ;; *) echo "    FAIL T-008: 'frontend' missing (FR-B7-1-010)" >&2; ok=0 ;; esac
  case "$ids" in *infra*)    ;; *) echo "    FAIL T-008: 'infra' missing (FR-B7-1-010)" >&2; ok=0 ;; esac
  [ "$ok" = "1" ]
}

_test_b71_l1_009_qwik_web_public_surface() {
  _ensure_py_cache || return 1
  local v; v=$(_get qwik_web_public)
  [ "$v" = "True" ] || { echo "    FAIL T-009: frontend has no qwik web-public surface (got $v) (FR-B7-1-011/012)" >&2; return 1; }
}

_test_b71_l1_010_components_have_name() {
  _ensure_py_cache || return 1
  [ "$(_get comp_missing_name)" = "False" ] || { echo "    FAIL T-010: a component lacks 'name' (or comp_missing_name key absent) (FR-B7-1-030)" >&2; return 1; }
  local n; n=$(_get comp_count)
  { [ -n "$n" ] && [ "$n" != "0" ]; } || { echo "    FAIL T-010: components[] empty/absent (count='$n') (FR-B7-1-030)" >&2; return 1; }
}

_test_b71_l1_011_standard_refs_resolve() {
  _ensure_py_cache || return 1
  local v; v=$(_get bad_standard_refs)
  [ "$v" = "OK" ] || { echo "    FAIL T-011: standard: refs do not resolve: $v (FR-B7-1-031)" >&2; return 1; }
}

_test_b71_l1_012_no_forbidden_pin_keys() {
  _ensure_py_cache || return 1
  local v; v=$(_get pin_violations)
  [ "$v" = "OK" ] || { echo "    FAIL T-012: forbidden inline pin key(s) {version|pin|image}: $v (FR-B7-1-031)" >&2; return 1; }
}

_test_b71_l1_013_no_inline_version_values() {
  _ensure_py_cache || return 1
  local v; v=$(_get val_violations)
  [ "$v" = "OK" ] || { echo "    FAIL T-013: component scalar matches \\d+\\.\\d+ (inline pin crept in): $v (FR-B7-1-032)" >&2; return 1; }
}

_test_b71_l1_014_phases_inline_ai_first() {
  _ensure_py_cache || return 1
  [ "$(_get phase_count)" != "0" ] || { echo "    FAIL T-014: phases[] empty/absent — not inlined (ADR-B7-1-001)" >&2; return 1; }
  local ok=1
  [ "$(_get phase_ai_brainstorm)" = "True" ]      || { echo "    FAIL T-014: phase 'ai_brainstorm' missing (FR-B7-1-021)" >&2; ok=0; }
  [ "$(_get 'phase_embeddings-pipeline')" = "True" ] || { echo "    FAIL T-014: phase 'embeddings-pipeline' missing (FR-B7-1-022)" >&2; ok=0; }
  [ "$(_get 'phase_prompt-audit')" = "True" ]     || { echo "    FAIL T-014: phase 'prompt-audit' missing (FR-B7-1-023)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b71_l1_015_ai_specifics_present() {
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get ais_fallback)" = "True" ] || { echo "    FAIL T-015: ai_specifics.fallback_mandatory != True (FR-B7-1-024, XI.5)" >&2; ok=0; }
  [ "$(_get ais_pii)" = "'explicit_consent_required'" ] || { echo "    FAIL T-015: ai_specifics.pii_handling != explicit_consent_required (FR-B7-1-024, XI.6)" >&2; ok=0; }
  [ "$(_get ais_token)" = "True" ] || { echo "    FAIL T-015: ai_specifics.token_budget_documented != True (FR-B7-1-024, IX.6)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b71_l1_016_deferred_components() {
  _ensure_py_cache || return 1
  local v; v=$(_get deferred_check)
  [ "$v" = "OK" ] || { echo "    FAIL T-016: deferred components must carry delivered_by:B.7.3, no standard ref: $v (FR-B7-1-032, ADR-B7-1-003)" >&2; return 1; }
}

_test_b71_l1_017_ai_flags_and_cross_layer() {
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get ai_fallback_required)" = "True" ] || { echo "    FAIL T-017: ai_fallback_required != True (FR-B7-1-024)" >&2; ok=0; }
  [ "$(_get cross_layer_agent)" = "Janus" ] || { echo "    FAIL T-017: cross_layer.agent != Janus (FR-B7-1-013)" >&2; ok=0; }
  [ "$(_get fr_cross)" = "FR-GL-" ] || { echo "    FAIL T-017: fr_id_prefix_cross_layer != FR-GL- (FR-B7-1-013)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b71_l1_018_header_block() {
  # FR-B7-1-005: the documentary header comment block (lines before `name:`) MUST
  # state candidate semantics, the promotion trigger, and additivity. Grep the
  # header region only (not the YAML body, where `stage: candidate` would give a
  # false pass). Fails loud if the file is missing (awk yields empty).
  local header; header=$(awk '/^[^#]/{exit} {print}' "$SCHEMA" 2>/dev/null)
  local ok=1
  printf '%s' "$header" | grep -qiE 'candidate'  || { echo "    FAIL T-018: header block missing 'candidate' semantics (FR-B7-1-005)" >&2; ok=0; }
  printf '%s' "$header" | grep -qiE 'promotion'  || { echo "    FAIL T-018: header block missing promotion trigger (FR-B7-1-005)" >&2; ok=0; }
  printf '%s' "$header" | grep -qiE 'additive'   || { echo "    FAIL T-018: header block missing additivity note (FR-B7-1-005)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# ─── L2 tests (opt-in live) ───────────────────────────────────────────────────

_test_b71_l2_001_init_refuses() {
  # The refusal contract (verified live against the built CLI, 2026-06-11):
  # `forge init <name> --archetype ai-native-rag --org <rd>` exits **2**
  # ("unknown archetype"). init.ts:210-216 checks the dispatch-table FIRST, and
  # ai-native-rag is not registered in .forge/scaffolding/dispatch-table.yml, so
  # the dispatch gate fires before the schema-version layer. The exit-3
  # selectScaffoldableVersion-null guard (init.ts:232-238) is DOWNSTREAM and not
  # reachable for this archetype yet; it becomes the active gate only once B.7.2
  # registers ai-native-rag in the dispatch-table while the schema stays
  # candidate/scaffoldable:false (update this assertion to exit 3 then — see
  # open-questions.md Q-005). Either way init refuses cleanly with NO scaffold
  # (NFR-B7-1-002). Opt-in (FORGE_B7_1_LIVE=1) + requires cli/dist/index.js;
  # skip-pass otherwise (mirrors b8-15 FORGE_B8_15_LIVE).
  local cli="$FORGE_ROOT/cli/dist/index.js"
  if [ "${FORGE_B7_1_LIVE:-0}" != "1" ] || [ ! -f "$cli" ]; then
    echo "    SKIP T-L2-001: set FORGE_B7_1_LIVE=1 with a built CLI (cli/dist/index.js) to run the live init-refusal check" >&2
    return 0
  fi
  local tmp; tmp=$(mk_tmpdir_with_trap b7-1-init)
  trap "rm -rf '$tmp'" RETURN
  ( cd "$tmp" && node "$cli" init testproj --archetype ai-native-rag --org com.example.test >/dev/null 2>&1 )
  local rc=$?
  if [ "$rc" != "2" ]; then
    echo "    FAIL T-L2-001: forge init --archetype ai-native-rag exit=$rc != 2 (expected clean refusal — unknown archetype; dispatch-table gate, init.ts:210)" >&2
    return 1
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.7.1 — b7-1-schema — level $LEVEL ──"
  run_test _test_b71_l1_001_schema_exists
  run_test _test_b71_l1_002_valid_yaml_mapping
  run_test _test_b71_l1_003_name
  run_test _test_b71_l1_004_version
  run_test _test_b71_l1_005_stage
  run_test _test_b71_l1_006_scaffoldable_false
  run_test _test_b71_l1_007_tdd_bdd_coverage
  run_test _test_b71_l1_008_layer_triple
  run_test _test_b71_l1_009_qwik_web_public_surface
  run_test _test_b71_l1_010_components_have_name
  run_test _test_b71_l1_011_standard_refs_resolve
  run_test _test_b71_l1_012_no_forbidden_pin_keys
  run_test _test_b71_l1_013_no_inline_version_values
  run_test _test_b71_l1_014_phases_inline_ai_first
  run_test _test_b71_l1_015_ai_specifics_present
  run_test _test_b71_l1_016_deferred_components
  run_test _test_b71_l1_017_ai_flags_and_cross_layer
  run_test _test_b71_l1_018_header_block
  case "$LEVEL" in
    *2*) run_test _test_b71_l2_001_init_refuses ;;
  esac
  print_summary
}

main
