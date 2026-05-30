#!/usr/bin/env bash
# Forge — B.8.3 flagship 2.0.0 candidate schema harness
# <!-- Audit: B.8.3 (b8-3-schema-candidate) — 2.0.0 candidate schema gate -->
#
# Validates the b8-3-schema-candidate deliverables:
#
#   T-001  2.0.0.yaml exists at the versioned path (FR-B8-3-001/002, ADR-B8-3-001)
#   T-002  file parses as valid YAML mapping root (FR-B8-3-001/002)
#   T-003  name == 'full-stack-monorepo' (FR-B8-3-002)
#   T-004  version == '2.0.0' (FR-B8-3-002)
#   T-005  stage == 'candidate' (FR-B8-3-002)
#   T-006  scaffoldable is False (FR-B8-3-041, ADR-B8-3-003/005)
#   T-007  tdd_enforced/bdd_required_for_user_facing/coverage_threshold (FR-B8-3-003)
#   T-008  layers[] ids ⊇ {backend, frontend, infra} (FR-B8-3-020)
#   T-009  frontend layer has surfaces web-public + web-backoffice (FR-B8-3-021)
#   T-010  every components[] entry has a name field (FR-B8-3-010/011)
#   T-011  every standard: reference resolves to an existing file (FR-B8-3-011)
#   T-012  no component carries a forbidden inline pin key (FR-B8-3-012, ADR-B8-3-002)
#   T-013  migration_deltas[] is present and non-empty (FR-B8-3-030)
#   T-014  frozen schema.yaml (1.0.0) still present + version unchanged (FR-B8-3-004)
#   T-015  no YAML scalar value at components[] level matches \d+\.\d+ (NFR-B8-3-001)
#   T-016  postgres component has migration_note + postgres-16 delta entry (FR-B8-3-013)
#   T-017  bump_at == 'B.8.14' (FR-B8-3-031)
#
# 17 L1 tests. Performance budget: L1 ≤ 5 s, zero net/Docker.
# Only gate aware of 2.0.0.yaml (ADR-B8-3-001); existing shared validators
# remain unaware until B.8.3.b (proposed — not yet ratified in plan §4.2).

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

SCHEMA_20="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/2.0.0.yaml"
SCHEMA_10="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/schema.yaml"
STANDARDS_DIR="$FORGE_ROOT/.forge/standards"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Shared YAML parse helper ─────────────────────────────────────────────────
# Runs a python3 snippet against SCHEMA_20; prints result to stdout.
# Returns 1 if python3 exits non-zero.
_py() {
  python3 - "$SCHEMA_20" "$STANDARDS_DIR" "$SCHEMA_10" <<'PYEOF'
import sys, yaml, re

schema_20   = sys.argv[1]
std_dir     = sys.argv[2]
schema_10   = sys.argv[3]

try:
    with open(schema_20, 'r', encoding='utf-8') as f:
        d = yaml.safe_load(f)
except FileNotFoundError:
    print("MISSING"); sys.exit(0)
except yaml.YAMLError as e:
    print(f"YAML_ERROR:{e}"); sys.exit(0)

if not isinstance(d, dict):
    print("NOT_MAPPING"); sys.exit(0)

results = {}

# T-003..005: identity
results['name']    = d.get('name', 'MISSING')
results['version'] = d.get('version', 'MISSING')
results['stage']   = d.get('stage', 'MISSING')

# T-006: scaffoldable
results['scaffoldable'] = repr(d.get('scaffoldable', 'MISSING'))

# T-007: TDD/BDD/coverage
results['tdd_enforced']              = repr(d.get('tdd_enforced', 'MISSING'))
results['bdd_required_for_user_facing'] = repr(d.get('bdd_required_for_user_facing', 'MISSING'))
results['coverage_threshold']        = repr(d.get('coverage_threshold', 'MISSING'))

# T-008: layer ids
layers = d.get('layers', [])
layer_ids = {l['id'] for l in layers if isinstance(l, dict) and 'id' in l}
results['layer_ids'] = ','.join(sorted(layer_ids))

# T-009: frontend surfaces
fe = next((l for l in layers if isinstance(l, dict) and l.get('id') == 'frontend'), None)
if fe:
    surfaces = fe.get('surfaces', [])
    surf_ids = {s['id'] for s in surfaces if isinstance(s, dict) and 'id' in s}
    results['surface_ids'] = ','.join(sorted(surf_ids))
else:
    results['surface_ids'] = 'NO_FRONTEND'

# T-010: all components have name
components = d.get('components', [])
comp_names = [c.get('name', 'MISSING') for c in components if isinstance(c, dict)]
results['comp_names'] = ','.join(comp_names)
results['comp_missing_name'] = str(any(n == 'MISSING' for n in comp_names))

# T-011: standard: refs resolve
import os
bad_refs = []
for c in components:
    if not isinstance(c, dict): continue
    ref = c.get('standard')
    if ref:
        path = os.path.join(std_dir, ref)
        if not os.path.isfile(path):
            bad_refs.append(ref)
results['bad_standard_refs'] = ','.join(bad_refs) if bad_refs else 'OK'

# T-012: no forbidden inline pin keys (exact key-set; pin_source is permitted)
forbidden = {'version', 'pin', 'image'}
pin_violations = []
for c in components:
    if not isinstance(c, dict): continue
    hit = set(c.keys()) & forbidden
    if hit:
        pin_violations.append(f"{c.get('name','?')}:{','.join(sorted(hit))}")
results['pin_violations'] = ';'.join(pin_violations) if pin_violations else 'OK'

# T-013: migration_deltas non-empty
deltas = d.get('migration_deltas', [])
results['delta_count'] = str(len(deltas))

# T-014: frozen schema.yaml present + version == 1.0.0
try:
    with open(schema_10, 'r', encoding='utf-8') as f:
        d10 = yaml.safe_load(f)
    results['schema10_version'] = d10.get('version', 'MISSING') if isinstance(d10, dict) else 'NOT_MAPPING'
except FileNotFoundError:
    results['schema10_version'] = 'FILE_MISSING'

# T-015: no scalar value at components[] level matches ^\d+\.\d+
# value-walk (NOT textual grep — avoids false-positive on YAML comments)
version_re = re.compile(r'^\d+\.\d+')
val_violations = []
for c in components:
    if not isinstance(c, dict): continue
    for k, v in c.items():
        if isinstance(v, str) and version_re.match(v):
            val_violations.append(f"{c.get('name','?')}.{k}={v!r}")
results['val_violations'] = ';'.join(val_violations) if val_violations else 'OK'

# T-016: postgres component has migration_note + postgres-16 delta entry
pg_comp = next((c for c in components if isinstance(c, dict) and 'postgres' in c.get('name','').lower()), None)
results['pg_has_migration_note'] = repr('migration_note' in pg_comp) if pg_comp else 'NO_PG_COMP'
results['pg16_delta'] = repr(any(
    isinstance(delta, dict) and delta.get('from','').startswith('postgres-16')
    for delta in deltas
))

# T-017: bump_at
results['bump_at'] = d.get('bump_at', 'MISSING')

# Print all results as KEY=VALUE lines
for k, v in results.items():
    print(f"{k}={v}")
PYEOF
}

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b83_l1_001_schema_exists() {
  if [ ! -f "$SCHEMA_20" ]; then
    echo "    FAIL T-001: 2.0.0.yaml missing: $SCHEMA_20 (FR-B8-3-001/002, ADR-B8-3-001)" >&2
    return 1
  fi
}

_test_b83_l1_002_valid_yaml_mapping() {
  local out; out=$(_py 2>&1) || { echo "    FAIL T-002: _py helper error: $out" >&2; return 1; }
  local first; first=$(echo "$out" | head -1)
  case "$first" in
    MISSING)   echo "    FAIL T-002: 2.0.0.yaml missing (should be caught by T-001)" >&2; return 1 ;;
    YAML_ERROR*) echo "    FAIL T-002: YAML parse error — ${first#YAML_ERROR:}" >&2; return 1 ;;
    NOT_MAPPING) echo "    FAIL T-002: root is not a YAML mapping" >&2; return 1 ;;
  esac
}

# Cache the parsed output so we only call python3 once for T-003..T-017.
_PY_OUT=""
_ensure_py_cache() {
  if [ -z "$_PY_OUT" ]; then
    _PY_OUT=$(_py 2>&1) || { echo "    python3 helper failed: $_PY_OUT" >&2; return 1; }
  fi
}
_get() { echo "$_PY_OUT" | grep "^${1}=" | head -1 | cut -d= -f2-; }

_test_b83_l1_003_name() {
  _ensure_py_cache || return 1
  local v; v=$(_get name)
  if [ "$v" != "full-stack-monorepo" ]; then
    echo "    FAIL T-003: name='$v' != 'full-stack-monorepo' (FR-B8-3-002)" >&2; return 1
  fi
}

_test_b83_l1_004_version() {
  _ensure_py_cache || return 1
  local v; v=$(_get version)
  if [ "$v" != "2.0.0" ]; then
    echo "    FAIL T-004: version='$v' != '2.0.0' (FR-B8-3-002)" >&2; return 1
  fi
}

_test_b83_l1_005_stage() {
  _ensure_py_cache || return 1
  local v; v=$(_get stage)
  if [ "$v" != "candidate" ]; then
    echo "    FAIL T-005: stage='$v' != 'candidate' (FR-B8-3-002)" >&2; return 1
  fi
}

_test_b83_l1_006_scaffoldable_false() {
  _ensure_py_cache || return 1
  local v; v=$(_get scaffoldable)
  if [ "$v" != "False" ]; then
    echo "    FAIL T-006: scaffoldable=$v != False (FR-B8-3-041, ADR-B8-3-003/005)" >&2; return 1
  fi
}

_test_b83_l1_007_tdd_bdd_coverage() {
  _ensure_py_cache || return 1
  local tdd bdd cov
  tdd=$(_get tdd_enforced)
  bdd=$(_get bdd_required_for_user_facing)
  cov=$(_get coverage_threshold)
  local ok=1
  [ "$tdd" = "True" ]  || { echo "    FAIL T-007: tdd_enforced=$tdd != True (FR-B8-3-003)" >&2; ok=0; }
  [ "$bdd" = "True" ]  || { echo "    FAIL T-007: bdd_required_for_user_facing=$bdd != True (FR-B8-3-003)" >&2; ok=0; }
  [ "$cov" = "80" ]    || { echo "    FAIL T-007: coverage_threshold=$cov != 80 (FR-B8-3-003)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b83_l1_008_layer_triple() {
  _ensure_py_cache || return 1
  local ids; ids=$(_get layer_ids)
  local ok=1
  case "$ids" in *backend*)  ;; *) echo "    FAIL T-008: 'backend' missing from layers (ids=$ids) (FR-B8-3-020)" >&2; ok=0 ;; esac
  case "$ids" in *frontend*) ;; *) echo "    FAIL T-008: 'frontend' missing from layers (FR-B8-3-020)" >&2; ok=0 ;; esac
  case "$ids" in *infra*)    ;; *) echo "    FAIL T-008: 'infra' missing from layers (FR-B8-3-020)" >&2; ok=0 ;; esac
  [ "$ok" = "1" ]
}

_test_b83_l1_009_frontend_surfaces() {
  _ensure_py_cache || return 1
  local ids; ids=$(_get surface_ids)
  local ok=1
  case "$ids" in *web-public*)     ;; *) echo "    FAIL T-009: surface 'web-public' missing (ids=$ids) (FR-B8-3-021)" >&2; ok=0 ;; esac
  case "$ids" in *web-backoffice*) ;; *) echo "    FAIL T-009: surface 'web-backoffice' missing (FR-B8-3-021)" >&2; ok=0 ;; esac
  [ "$ok" = "1" ]
}

_test_b83_l1_010_components_have_name() {
  _ensure_py_cache || return 1
  local v; v=$(_get comp_missing_name)
  if [ "$v" = "True" ]; then
    echo "    FAIL T-010: at least one component lacks a 'name' field (FR-B8-3-010/011)" >&2; return 1
  fi
  local names; names=$(_get comp_names)
  if [ -z "$names" ]; then
    echo "    FAIL T-010: components[] is empty or missing (FR-B8-3-010)" >&2; return 1
  fi
}

_test_b83_l1_011_standard_refs_resolve() {
  _ensure_py_cache || return 1
  local v; v=$(_get bad_standard_refs)
  if [ "$v" != "OK" ]; then
    echo "    FAIL T-011: standard: references do not resolve to existing files: $v (FR-B8-3-011)" >&2; return 1
  fi
}

_test_b83_l1_012_no_forbidden_pin_keys() {
  _ensure_py_cache || return 1
  local v; v=$(_get pin_violations)
  if [ "$v" != "OK" ]; then
    echo "    FAIL T-012: component(s) carry forbidden inline pin key(s) {version|pin|image}: $v" >&2
    echo "    (pin_source is permitted; exact key-set check — ADR-B8-3-002, FR-B8-3-012)" >&2
    return 1
  fi
}

_test_b83_l1_013_migration_deltas_nonempty() {
  _ensure_py_cache || return 1
  local v; v=$(_get delta_count)
  if [ "$v" = "0" ] || [ -z "$v" ]; then
    echo "    FAIL T-013: migration_deltas[] is absent or empty (FR-B8-3-030)" >&2; return 1
  fi
}

_test_b83_l1_014_frozen_schema_intact() {
  _ensure_py_cache || return 1
  if [ ! -f "$SCHEMA_10" ]; then
    echo "    FAIL T-014: frozen schema.yaml (1.0.0) is MISSING: $SCHEMA_10 (FR-B8-3-004)" >&2; return 1
  fi
  local v; v=$(_get schema10_version)
  if [ "$v" != "1.0.0" ]; then
    echo "    FAIL T-014: schema.yaml version='$v' != '1.0.0' — 1.0.0 schema was modified! (NFR-B8-3-003)" >&2; return 1
  fi
}

_test_b83_l1_015_no_inline_version_values() {
  _ensure_py_cache || return 1
  local v; v=$(_get val_violations)
  if [ "$v" != "OK" ]; then
    echo "    FAIL T-015: component scalar value(s) match \\d+\\.\\d+ (inline pin crept in): $v" >&2
    echo "    (yaml.safe_load value-walk, not grep — NFR-B8-3-001, ADR-B8-3-002)" >&2
    return 1
  fi
}

_test_b83_l1_016_postgres_migration_note_and_delta() {
  _ensure_py_cache || return 1
  local note16
  note16=$(_get pg_has_migration_note)
  local pg16
  pg16=$(_get pg16_delta)
  local ok=1
  case "$note16" in
    "True") ;;
    "NO_PG_COMP") echo "    FAIL T-016: no postgres component found in components[] (FR-B8-3-013)" >&2; ok=0 ;;
    *) echo "    FAIL T-016: postgres component lacks migration_note field (pg_has_migration_note=$note16) (FR-B8-3-013)" >&2; ok=0 ;;
  esac
  if [ "$pg16" != "True" ]; then
    echo "    FAIL T-016: migration_deltas[] has no entry with from=postgres-16* (pg16_delta=$pg16) (FR-B8-3-013)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b83_l1_017_bump_at_b814() {
  _ensure_py_cache || return 1
  local v; v=$(_get bump_at)
  if [ "$v" != "B.8.14" ]; then
    echo "    FAIL T-017: bump_at='$v' != 'B.8.14' (FR-B8-3-031)" >&2; return 1
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.8.3 — b8-3-schema-candidate — level $LEVEL ──"
  run_test _test_b83_l1_001_schema_exists
  run_test _test_b83_l1_002_valid_yaml_mapping
  run_test _test_b83_l1_003_name
  run_test _test_b83_l1_004_version
  run_test _test_b83_l1_005_stage
  run_test _test_b83_l1_006_scaffoldable_false
  run_test _test_b83_l1_007_tdd_bdd_coverage
  run_test _test_b83_l1_008_layer_triple
  run_test _test_b83_l1_009_frontend_surfaces
  run_test _test_b83_l1_010_components_have_name
  run_test _test_b83_l1_011_standard_refs_resolve
  run_test _test_b83_l1_012_no_forbidden_pin_keys
  run_test _test_b83_l1_013_migration_deltas_nonempty
  run_test _test_b83_l1_014_frozen_schema_intact
  run_test _test_b83_l1_015_no_inline_version_values
  run_test _test_b83_l1_016_postgres_migration_note_and_delta
  run_test _test_b83_l1_017_bump_at_b814
  print_summary
}

main
