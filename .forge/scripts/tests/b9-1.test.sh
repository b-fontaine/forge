#!/usr/bin/env bash
# Forge — B.9.1 mobile-pwa-first 2.0.0 candidate schema harness
# <!-- Audit: B.9.1 (b9-1-schema) — mobile-pwa-first/2.0.0 archetype scaffold schema gate -->
#
# Validates the b9-1-schema deliverables:
#   (1) .forge/schemas/mobile-pwa-first/2.0.0.yaml  (new candidate schema)
#   (2) the `layer_profile` relaxation of check_versioned_schema_siblings
#       in validate-foundations.sh (ADR-B9-1-001), incl. its backward-compat
#
#   T-001  2.0.0.yaml exists at the versioned path (FR-B9-1-002)
#   T-002  parses as a YAML mapping; legacy `archetype:`/`schema_version:` keys ABSENT (FR-B9-1-001)
#   T-003  name/version/stage == mobile-pwa-first / 2.0.0 / candidate (FR-B9-1-002)
#   T-004  scaffoldable is False (FR-B9-1-003)
#   T-005  tdd_enforced / bdd_required_for_user_facing / coverage_threshold 80 (FR-B9-1-004)
#   T-006  header block documents candidate / promotion / additive (FR-B9-1-005)
#   T-007  golden_tests_required carried forward from tdd-flutter (FR-B9-1-006)
#   T-008  layers ids == EXACTLY {app, web-pwa}, each with id/path/fr_id_prefix/primary_agent (FR-B9-1-010)
#   T-009  app→Hera, web-pwa→Iris-Web (FR-B9-1-011)
#   T-010  NEGATIVE — no fabricated backend/infra stub layer (FR-B9-1-012)
#   T-011  validate-foundations.sh PASSes on the live tree incl. this schema (FR-B9-1-013)
#   T-012  BACKWARD-COMPAT — a 3-layer schema with NO layer_profile still PASSes (FR-B9-1-014)
#   T-013  NEGATIVE — layer_profile absent + triple incomplete still KOs (FR-B9-1-014)
#   T-014  NEGATIVE — unknown layer_profile value KOs (ADR-B9-1-001)
#   T-015  phases inlined; no `extends:` key (FR-B9-1-020)
#   T-016  full tdd-flutter chain preserved, `features` before `design` (FR-B9-1-021)
#   T-017  `channel-decision` present, between `specs` and `features` (FR-B9-1-022)
#   T-018  pwa_specifics block present (FR-B9-1-023)
#   T-019  zero inline pin: no forbidden key, no \d+\.\d+ scalar in components (FR-B9-1-030)
#   T-020  the 4 PWA components carry standard:pwa.yaml (flipped by B.9.2; FR-B9-1-031 AMENDED — now serves FR-B9-2-030)
#   T-021  mobile-only schema + wrapper + templates untouched (FR-B9-1-040)
#   T-022  dispatch-table.yml HAS a mobile-pwa-first key (flipped by B.9.2) (FR-B9-1-041)
#   T-023  bundled cli/assets mirror matches canonical WHEN PRESENT (it is gitignored);
#          the 5 example artefacts stay free of the versioned-schema function (ADR-B9-1-001)
#   T-L2-001 (opt-in) forge init --archetype mobile-pwa-first refuses with exit 3 and
#            renders nothing (NFR-B9-1-002). Was exit 2 (dispatch gate) until B.9.2
#            registered the dispatch key; T-022 flipped in the same change.
#
# 23 L1 + 1 L2. Performance budget: L1 <= 5 s, zero net/Docker. Structural invariants
# (name==dir, version==file, candidate⇒scaffoldable:false, phases non-empty) are ALSO
# enforced generically by validate-foundations.sh check_versioned_schema_siblings
# (B.8.3.b, as relaxed here); this harness adds the archetype-specific content asserts
# plus the relaxation's own backward-compat proof.

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

SCHEMA="$FORGE_ROOT/.forge/schemas/mobile-pwa-first/2.0.0.yaml"
STANDARDS_DIR="$FORGE_ROOT/.forge/standards"
VALIDATOR="$SCRIPTS_DIR/validate-foundations.sh"

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
        raw = f.read()
    d = yaml.safe_load(raw)
except FileNotFoundError:
    print("MISSING"); sys.exit(0)
except yaml.YAMLError as e:
    print(f"YAML_ERROR:{e}"); sys.exit(0)

if not isinstance(d, dict):
    print("NOT_MAPPING"); sys.exit(0)

r = {}

# identity
r['name']         = d.get('name', 'MISSING')
r['version']      = d.get('version', 'MISSING')
r['stage']        = d.get('stage', 'MISSING')
r['scaffoldable'] = repr(d.get('scaffoldable', 'MISSING'))
r['layer_profile'] = d.get('layer_profile', 'MISSING')

# the legacy mobile-only shape MUST NOT be reused (FR-B9-1-001)
r['has_legacy_archetype_key'] = str('archetype' in d)
r['has_legacy_schema_version_key'] = str('schema_version' in d)
r['has_extends'] = str('extends' in d)

# flags
r['tdd_enforced']                 = repr(d.get('tdd_enforced', 'MISSING'))
r['bdd_required_for_user_facing'] = repr(d.get('bdd_required_for_user_facing', 'MISSING'))
r['coverage_threshold']           = repr(d.get('coverage_threshold', 'MISSING'))
r['golden_tests_required']        = repr(d.get('golden_tests_required', 'MISSING'))

# layers
layers = d.get('layers', []) or []
layer_ids = {l['id'] for l in layers if isinstance(l, dict) and 'id' in l}
r['layer_ids'] = ','.join(sorted(layer_ids))
incomplete = []
for l in layers:
    if not isinstance(l, dict):
        incomplete.append('non-mapping'); continue
    for k in ('id', 'path', 'fr_id_prefix', 'primary_agent'):
        if k not in l:
            incomplete.append(f"{l.get('id','?')}:{k}")
r['layers_incomplete'] = ';'.join(incomplete) if incomplete else 'OK'
agents = {l.get('id'): l.get('primary_agent') for l in layers if isinstance(l, dict)}
r['agent_app']     = str(agents.get('app', 'MISSING'))
r['agent_web_pwa'] = str(agents.get('web-pwa', 'MISSING'))

# components
components = d.get('components', []) or []
comp_names = [c.get('name', 'MISSING') for c in components if isinstance(c, dict)]
r['comp_count'] = str(len(comp_names))

bad_refs = []
for c in components:
    if not isinstance(c, dict): continue
    ref = c.get('standard')
    if ref and not os.path.isfile(os.path.join(std_dir, ref)):
        bad_refs.append(ref)
r['bad_standard_refs'] = ','.join(bad_refs) if bad_refs else 'OK'

forbidden = {'version', 'pin', 'image'}
pin_viol = []
for c in components:
    if not isinstance(c, dict): continue
    hit = set(c.keys()) & forbidden
    if hit:
        pin_viol.append(f"{c.get('name','?')}:{','.join(sorted(hit))}")
r['pin_violations'] = ';'.join(pin_viol) if pin_viol else 'OK'

vre = re.compile(r'^\d+\.\d+')
val_viol = []
for c in components:
    if not isinstance(c, dict): continue
    for k, v in c.items():
        if isinstance(v, str) and vre.match(v):
            val_viol.append(f"{c.get('name','?')}.{k}={v!r}")
r['val_violations'] = ';'.join(val_viol) if val_viol else 'OK'

# The four PWA components. FLIPPED BY B.9.2 (b9-2-web-pwa, coupled edit):
# at B.9.1 time they carried `delivered_by: B.9.2` with NO standard ref, because no
# standard governed them yet — a recorded gap, never a fabricated name. B.9.2 created
# the role-named `pwa.yaml` (ADR-B9-2-004) and repointed all four, so the assertion
# inverts: each MUST now carry `standard: pwa.yaml` and MUST NOT carry `delivered_by`.
# This is the third b9-1 assertion coupled to B.9.2 (with T-022 and T-L2-001) — the
# b9-2 plan named only the first two; this one surfaced at implement.
deferred = {'service-worker', 'web-push', 'offline-shell', 'manifest'}
bad_def, seen_def = [], set()
for c in components:
    if not isinstance(c, dict): continue
    nm = c.get('name')
    if nm in deferred:
        seen_def.add(nm)
        if c.get('standard') != 'pwa.yaml':
            bad_def.append(f"{nm}:standard={c.get('standard')!r}")
        if 'delivered_by' in c:
            bad_def.append(f"{nm}:still-deferred")
missing_def = deferred - seen_def
if missing_def:
    bad_def.append("missing:" + ','.join(sorted(missing_def)))
r['deferred_check'] = ';'.join(bad_def) if bad_def else 'OK'

# phases — order matters for the channel-decision placement
phases = d.get('phases', []) or []
phase_list = [p['id'] for p in phases if isinstance(p, dict) and 'id' in p]
phase_ids = set(phase_list)
r['phase_count'] = str(len(phases))
r['phase_order'] = ','.join(phase_list)
for need in ('proposal', 'specs', 'features', 'design', 'tasks',
             'implementation', 'review', 'archive', 'channel-decision'):
    r[f'phase_{need}'] = str(need in phase_ids)

def _idx(pid):
    return phase_list.index(pid) if pid in phase_list else -1
r['idx_specs']    = str(_idx('specs'))
r['idx_channel']  = str(_idx('channel-decision'))
r['idx_features'] = str(_idx('features'))
r['idx_design']   = str(_idx('design'))

# pwa_specifics
ps = d.get('pwa_specifics', {}) or {}
r['pwa_specifics_present'] = str(isinstance(ps, dict) and len(ps) > 0)

# header block (leading comment lines)
header = []
for line in raw.splitlines():
    if line.startswith('#'):
        header.append(line)
    elif line.strip() == '':
        continue
    else:
        break
h = '\n'.join(header).lower()
r['header_candidate'] = str('candidate' in h)
r['header_promotion'] = str('promot' in h)
r['header_additive']  = str('additive' in h)

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

# ─── Validator fixture helpers (T-012..T-014) ────────────────────────────────
# Build a throwaway FORGE_ROOT holding ONLY a versioned schema sibling, then run
# the real validator against it and grep the FR-GL-001-versioned line. Other
# validator checks will FAIL in such a minimal root — irrelevant here, we assert
# only on the versioned-sibling line (the foundations.test.sh fixture pattern).
_mk_versioned_fixture() {
  local arch="$1" fname="$2" body="$3" root
  root="$(mktemp -d -t forge-b9-1-fixture-XXXXXX)"
  mkdir -p "$root/.forge/schemas/$arch"
  printf '%s' "$body" > "$root/.forge/schemas/$arch/$fname"
  echo "$root"
}

_versioned_line() {
  FORGE_ROOT="$1" bash "$VALIDATOR" 2>&1 | grep "FR-GL-001-versioned" || true
}

_THREE_LAYER_BODY='name: fixture-arch
version: "1.0.0"
stage: draft
layers:
  - {id: backend, path: backend/, fr_id_prefix: FR-BE-, primary_agent: Vulcan}
  - {id: frontend, path: frontend/, fr_id_prefix: FR-FE-, primary_agent: Hera}
  - {id: infra, path: infra/, fr_id_prefix: FR-IN-, primary_agent: Atlas}
phases:
  - {id: proposal}
'

# ─── L1 tests ────────────────────────────────────────────────────────────────

_test_b91_l1_001_schema_exists() {
  [ -f "$SCHEMA" ] || { echo "    FAIL T-001: 2.0.0.yaml missing: $SCHEMA (FR-B9-1-002)" >&2; return 1; }
}

_test_b91_l1_002_valid_yaml_not_legacy_shape() {
  local out; out=$(_py 2>&1) || { echo "    FAIL T-002: _py helper error: $out" >&2; return 1; }
  case "$(echo "$out" | head -1)" in
    MISSING)     echo "    FAIL T-002: schema missing (see T-001)" >&2; return 1 ;;
    YAML_ERROR*) echo "    FAIL T-002: YAML parse error" >&2; return 1 ;;
    NOT_MAPPING) echo "    FAIL T-002: root is not a YAML mapping" >&2; return 1 ;;
  esac
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get has_legacy_archetype_key)" = "False" ] || { echo "    FAIL T-002: legacy 'archetype:' key present — must use the scaffold-schema shape (FR-B9-1-001)" >&2; ok=0; }
  [ "$(_get has_legacy_schema_version_key)" = "False" ] || { echo "    FAIL T-002: legacy 'schema_version:' key present (FR-B9-1-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b91_l1_003_identity() {
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get name)" = "mobile-pwa-first" ] || { echo "    FAIL T-003: name='$(_get name)' != 'mobile-pwa-first' (FR-B9-1-002)" >&2; ok=0; }
  [ "$(_get version)" = "2.0.0" ] || { echo "    FAIL T-003: version='$(_get version)' != '2.0.0' (FR-B9-1-002)" >&2; ok=0; }
  # INVERTED by b9-11-promotion-gate (2026-09-12): candidate -> stable (ADR-B911-001).
  [ "$(_get stage)" = "stable" ] || { echo "    FAIL T-003: stage='$(_get stage)' != 'stable' — promoted by B.9.11 (FR-B9-1-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# INVERTED by b9-11-promotion-gate (2026-09-12). The property under test is
# unchanged — the schema's declared stage — only which value is correct. Deleting
# the cell would convert a caught regression into a silent one (ADR-B911-001).
_test_b91_l1_004_scaffoldable_true() {
  _ensure_py_cache || return 1
  local v; v=$(_get scaffoldable)
  [ "$v" = "True" ] || { echo "    FAIL T-004: scaffoldable=$v != True — promoted by B.9.11 (FR-B9-1-003)" >&2; return 1; }
}

_test_b91_l1_005_tdd_bdd_coverage() {
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get tdd_enforced)" = "True" ] || { echo "    FAIL T-005: tdd_enforced != True (FR-B9-1-004)" >&2; ok=0; }
  [ "$(_get bdd_required_for_user_facing)" = "True" ] || { echo "    FAIL T-005: bdd_required_for_user_facing != True (FR-B9-1-004)" >&2; ok=0; }
  [ "$(_get coverage_threshold)" = "80" ] || { echo "    FAIL T-005: coverage_threshold != 80 (FR-B9-1-004)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b91_l1_006_header_block() {
  _ensure_py_cache || return 1
  local ok=1
  # INVERTED by b9-11-promotion-gate: the header used to declare candidate semantics.
  # Post-promotion it must record the promotion instead. `header_promotion` below still
  # covers the trigger; this row now asserts the header names the promoting brick, so a
  # header left describing the old state fails (ADR-B911-001).
  grep -qF -- "B.9.11" "$SCHEMA" || { echo "    FAIL T-006: header block does not name B.9.11 as the promoter (FR-B9-1-005)" >&2; ok=0; }
  [ "$(_get header_promotion)" = "True" ] || { echo "    FAIL T-006: header block missing promotion trigger (FR-B9-1-005)" >&2; ok=0; }
  [ "$(_get header_additive)" = "True" ] || { echo "    FAIL T-006: header block missing additivity note (FR-B9-1-005)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b91_l1_007_golden_tests_required() {
  _ensure_py_cache || return 1
  local v; v=$(_get golden_tests_required)
  [ "$v" = "True" ] || { echo "    FAIL T-007: golden_tests_required=$v != True (FR-B9-1-006)" >&2; return 1; }
}

_test_b91_l1_008_layers_exactly_two() {
  _ensure_py_cache || return 1
  local ids; ids=$(_get layer_ids); local ok=1
  [ "$ids" = "app,web-pwa" ] || { echo "    FAIL T-008: layer ids='$ids', expected exactly 'app,web-pwa' (FR-B9-1-010)" >&2; ok=0; }
  [ "$(_get layers_incomplete)" = "OK" ] || { echo "    FAIL T-008: incomplete layers: $(_get layers_incomplete) (FR-B9-1-010)" >&2; ok=0; }
  [ "$(_get layer_profile)" = "client-only" ] || { echo "    FAIL T-008: layer_profile='$(_get layer_profile)' != 'client-only' (ADR-B9-1-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b91_l1_009_layer_agents() {
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get agent_app)" = "Hera" ] || { echo "    FAIL T-009: app primary_agent='$(_get agent_app)' != 'Hera' (FR-B9-1-011)" >&2; ok=0; }
  [ "$(_get agent_web_pwa)" = "Iris-Web" ] || { echo "    FAIL T-009: web-pwa primary_agent='$(_get agent_web_pwa)' != 'Iris-Web' (FR-B9-1-011)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b91_l1_010_neg_no_stub_layers() {
  # FR-B9-1-012 — the whole point of ADR-B9-1-001 is that we do NOT fabricate
  # backend/infra layers to appease the validator.
  _ensure_py_cache || return 1
  local ids; ids=$(_get layer_ids); local ok=1
  case ",$ids," in *,backend,*) echo "    FAIL T-010: fabricated 'backend' layer present — FR-B9-1-012 forbids a layer that scaffolds nothing" >&2; ok=0 ;; esac
  case ",$ids," in *,infra,*)   echo "    FAIL T-010: fabricated 'infra' layer present (FR-B9-1-012)" >&2; ok=0 ;; esac
  [ "$ok" = "1" ]
}

_test_b91_l1_011_live_validator_pass() {
  local out; out=$(bash "$VALIDATOR" 2>&1)
  printf '%s' "$out" | grep -q "PASS: FR-GL-001-versioned:mobile-pwa-first/2.0.0.yaml" \
    || { echo "    FAIL T-011: no PASS line for mobile-pwa-first/2.0.0.yaml (FR-B9-1-013)" >&2; return 1; }
  printf '%s' "$out" | grep -q "profile=client-only" \
    || { echo "    FAIL T-011: OK line does not report profile=client-only (ADR-B9-1-001)" >&2; return 1; }
}

_test_b91_l1_012_backward_compat_no_profile() {
  # FR-B9-1-014 — a pre-B.9.1 schema (3 layers, NO layer_profile) must still PASS.
  local root; root=$(_mk_versioned_fixture fixture-arch 1.0.0.yaml "$_THREE_LAYER_BODY")
  trap "rm -rf '$root'" RETURN
  local line; line=$(_versioned_line "$root")
  printf '%s' "$line" | grep -q "^PASS: FR-GL-001-versioned:fixture-arch/1.0.0.yaml" \
    || { echo "    FAIL T-012: 3-layer schema without layer_profile did not PASS — backward-compat regression (FR-B9-1-014). Got: $line" >&2; return 1; }
}

_test_b91_l1_013_neg_default_profile_still_enforces_triple() {
  # FR-B9-1-014 — omitting layer_profile must keep the triple mandatory.
  local body; body=$(printf '%s' "$_THREE_LAYER_BODY" | grep -v 'id: infra')
  local root; root=$(_mk_versioned_fixture fixture-arch 1.0.0.yaml "$body")
  trap "rm -rf '$root'" RETURN
  local line; line=$(_versioned_line "$root")
  printf '%s' "$line" | grep -q "layers must include backend, frontend, infra" \
    || { echo "    FAIL T-013: a schema missing 'infra' with no layer_profile did NOT KO — the default is not enforcing the triple (FR-B9-1-014). Got: $line" >&2; return 1; }
}

_test_b91_l1_014_neg_unknown_profile() {
  local body; body="${_THREE_LAYER_BODY}layer_profile: banana
"
  local root; root=$(_mk_versioned_fixture fixture-arch 1.0.0.yaml "$body")
  trap "rm -rf '$root'" RETURN
  local line; line=$(_versioned_line "$root")
  printf '%s' "$line" | grep -q "layer_profile must be one of" \
    || { echo "    FAIL T-014: unknown layer_profile value did not KO (ADR-B9-1-001). Got: $line" >&2; return 1; }
}

_test_b91_l1_015_phases_inline_no_extends() {
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get has_extends)" = "False" ] || { echo "    FAIL T-015: 'extends:' key present — no scaffold-schema loader resolves it (FR-B9-1-020)" >&2; ok=0; }
  [ "$(_get phase_count)" -ge 8 ] 2>/dev/null || { echo "    FAIL T-015: phase_count=$(_get phase_count) < 8 — phases not inlined (FR-B9-1-020)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b91_l1_016_tdd_flutter_chain() {
  _ensure_py_cache || return 1
  local ok=1
  for p in proposal specs features design tasks implementation review archive; do
    [ "$(_get "phase_$p")" = "True" ] || { echo "    FAIL T-016: phase '$p' missing (FR-B9-1-021)" >&2; ok=0; }
  done
  # NOT named `fi`/`di`: `fi` is the `if` terminator keyword, and shellcheck
  # flags `local fi ...` as SC1010 (CI `Shell lint` is severity=warning, so a
  # warning is a red job, not advice).
  local fidx didx; fidx=$(_get idx_features); didx=$(_get idx_design)
  # Guard: empty when the schema is absent (RED phase) — keep the failure clean
  # instead of emitting a bash integer-expression error.
  [ -n "$fidx" ] || fidx=-1
  [ -n "$didx" ] || didx=-1
  if [ "$fidx" -lt 0 ] || [ "$didx" -lt 0 ] || [ "$fidx" -ge "$didx" ]; then
    echo "    FAIL T-016: 'features' (idx $fidx) must precede 'design' (idx $didx) — BDD-before-design gate (FR-B9-1-021)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b91_l1_017_channel_decision_placement() {
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get phase_channel-decision)" = "True" ] || { echo "    FAIL T-017: 'channel-decision' phase missing (FR-B9-1-022)" >&2; return 1; }
  # `fidx`, not `fi` — see the SC1010 note in T-016 above.
  local si ci fidx; si=$(_get idx_specs); ci=$(_get idx_channel); fidx=$(_get idx_features)
  [ -n "$si" ] || si=-1
  [ -n "$ci" ] || ci=-1
  [ -n "$fidx" ] || fidx=-1
  if [ "$si" -lt 0 ] || [ "$ci" -lt 0 ] || [ "$fidx" -lt 0 ] || [ "$si" -ge "$ci" ] || [ "$ci" -ge "$fidx" ]; then
    echo "    FAIL T-017: expected specs($si) < channel-decision($ci) < features($fidx) — order '$(_get phase_order)' (FR-B9-1-022, ADR-B9-1-003)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

_test_b91_l1_018_pwa_specifics() {
  _ensure_py_cache || return 1
  [ "$(_get pwa_specifics_present)" = "True" ] || { echo "    FAIL T-018: pwa_specifics block missing or empty (FR-B9-1-023)" >&2; return 1; }
}

_test_b91_l1_019_no_inline_pin() {
  _ensure_py_cache || return 1
  local ok=1
  [ "$(_get comp_count)" -gt 0 ] 2>/dev/null || { echo "    FAIL T-019: components[] empty (FR-B9-1-030)" >&2; ok=0; }
  [ "$(_get pin_violations)" = "OK" ] || { echo "    FAIL T-019: forbidden inline pin key(s): $(_get pin_violations) (FR-B9-1-030)" >&2; ok=0; }
  [ "$(_get val_violations)" = "OK" ] || { echo "    FAIL T-019: inline version-looking value(s): $(_get val_violations) (NFR-B9-1-005)" >&2; ok=0; }
  [ "$(_get bad_standard_refs)" = "OK" ] || { echo "    FAIL T-019: unresolvable standard ref(s): $(_get bad_standard_refs) (FR-B9-1-030)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b91_l1_020_deferred_components() {
  _ensure_py_cache || return 1
  [ "$(_get deferred_check)" = "OK" ] || { echo "    FAIL T-020: PWA components wrong: $(_get deferred_check) — expected standard:pwa.yaml and NO delivered_by (FR-B9-2-030, which amends FR-B9-1-031; do NOT restore the delivered_by forward-pointer — pwa.yaml shipped in B.9.2)" >&2; return 1; }
}

_test_b91_l1_021_mobile_only_untouched() {
  local ok=1
  [ -f "$FORGE_ROOT/.forge/schemas/mobile-only/schema.yaml" ] || { echo "    FAIL T-021: mobile-only/schema.yaml is gone (FR-B9-1-040)" >&2; ok=0; }
  [ -f "$FORGE_ROOT/bin/forge-init-mobile-only.sh" ] || { echo "    FAIL T-021: bin/forge-init-mobile-only.sh is gone (FR-B9-1-040)" >&2; ok=0; }
  [ -d "$FORGE_ROOT/.forge/templates/archetypes/mobile-only" ] || { echo "    FAIL T-021: mobile-only template tree is gone (FR-B9-1-040)" >&2; ok=0; }
  grep -q "^archetype: mobile-only" "$FORGE_ROOT/.forge/schemas/mobile-only/schema.yaml" 2>/dev/null \
    || { echo "    FAIL T-021: mobile-only/schema.yaml no longer declares 'archetype: mobile-only' (FR-B9-1-040)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b91_l1_022_dispatch_table_untouched() {
  # FLIPPED BY B.9.2 (coupled edit). At B.9.1 time this asserted the ABSENCE of a
  # `mobile-pwa-first:` key — registering one was explicitly B.9.2/B.9.11 territory.
  # b9-2-web-pwa registered it (FR-B9-2-020), which is what moves the init refusal
  # from exit 2 to exit 3, so the assertion inverts and T-L2-001 flips with it.
  # Function name kept for the T-022 manifest.
  local dt="$FORGE_ROOT/.forge/scaffolding/dispatch-table.yml"
  grep -qE "^  mobile-pwa-first:" "$dt" \
    || { echo "    FAIL T-022: no 'mobile-pwa-first:' key in dispatch-table.yml — B.9.2 registers it (FR-B9-1-041, flipped)" >&2; return 1; }
  grep -qE "^\s+target: mobile-pwa-first" "$dt" \
    || { echo "    FAIL T-022: the T.4 legacy-alias 'target: mobile-pwa-first' line is missing from dispatch-table.yml (FR-B9-1-041)" >&2; return 1; }
  grep -qE "^  mobile-only:" "$dt" \
    || { echo "    FAIL T-022: the mobile-only: legacy alias entry was removed (FR-B9-1-041)" >&2; return 1; }
  return 0
}

_test_b91_l1_023_validator_mirrors_in_sync() {
  # ADR-B9-1-001 (CORRECTED at impl, 2026-07-27) — the FRAMEWORK mirror set is TWO
  # files, not seven. The five copies under examples/ and cli/assets/examples/ are
  # 396-line SCAFFOLDED ARTEFACTS frozen at the B.1 baseline: they do not contain
  # `check_versioned_schema_siblings` at all (added later by B.8.3.b) and MUST NOT be
  # synced — doing so would rewrite example projects with framework-internal logic.
  # This test asserts both halves: the 2 real mirrors match, and the 5 artefacts stay
  # free of the function.
  local canonical="$FORGE_ROOT/.forge/scripts/validate-foundations.sh"
  local mirror="$FORGE_ROOT/cli/assets/.forge/scripts/validate-foundations.sh"
  local ok=1

  # cli/assets/ is GITIGNORED (cli/.gitignore:3) — a pure `npm run bundle` output.
  # It is absent from a fresh checkout, so its consistency is only assertable when
  # it has actually been bundled. Checking it unconditionally would fail CI.
  if [ -f "$mirror" ]; then
    cmp -s "$canonical" "$mirror" \
      || { echo "    FAIL T-023: bundled cli/assets/.forge/scripts/validate-foundations.sh drifted from canonical — re-run 'npm run bundle' (ADR-B9-1-001)" >&2; ok=0; }
  fi

  local f leaked=""
  while IFS= read -r f; do
    case "$f" in "$canonical"|"$mirror") continue ;; esac
    if grep -q "check_versioned_schema_siblings" "$f" 2>/dev/null; then
      leaked="$leaked $f"
    fi
  done < <(find "$FORGE_ROOT" -name validate-foundations.sh -not -path "*/node_modules/*" | sort)
  [ -z "$leaked" ] \
    || { echo "    FAIL T-023: framework-internal versioned-schema logic leaked into scaffolded example artefact(s):$leaked — they are B.1-baseline outputs, not mirrors (ADR-B9-1-001)" >&2; ok=0; }

  [ "$ok" = "1" ]
}

# ─── L2 tests (opt-in live) ───────────────────────────────────────────────────

_test_b91_l2_001_init_renders() {
  # NFR-B9-1-002 — the refusal MUST be clean (non-zero, no half-rendered tree).
  # FLIPPED BY B.9.2: the code is now **3**. b9-2-web-pwa registered a
  # `mobile-pwa-first:` dispatch key, so init.ts:210-217 no longer short-circuits and
  # execution reaches the B.8.14 guard at init.ts:238, which refuses because the 2.0.0
  # schema is still stage:candidate / scaffoldable:false (promotion is B.9.11's).
  # Coupled with T-022 — both flipped in the same change, by design.
  # Requires the built+bundled CLI. Opt-in via FORGE_B9_1_LIVE=1; skip-pass otherwise.
  local cli="$FORGE_ROOT/cli/dist/index.js"
  if [ "${FORGE_B9_1_LIVE:-0}" != "1" ] || [ ! -f "$cli" ]; then
    echo "    SKIP T-L2-001: set FORGE_B9_1_LIVE=1 with a built+bundled CLI (cli/dist/index.js) to run the live refusal check" >&2
    return 0
  fi
  local tmp; tmp=$(mk_tmpdir_with_trap b9-1-init)
  trap "rm -rf '$tmp'" RETURN
  # INVERTED by b9-11-promotion-gate: the schema is stable/scaffoldable:true, so init
  # RENDERS. The property under test is still "init's behaviour matches the schema's
  # declared stage" (ADR-B911-001).
  ( cd "$tmp" && node "$cli" init pwaproj --archetype mobile-pwa-first --org com.example.test >/dev/null 2>&1 )
  local rc=$?
  [ "$rc" = "0" ] || { echo "    FAIL T-L2-001: forge init --archetype mobile-pwa-first exit=$rc, expected 0 — promoted by B.9.11 (NFR-B9-1-002)" >&2; return 1; }
  [ -f "$tmp/pwaproj/web-pwa/package.json" ] || { echo "    FAIL T-L2-001: no web-pwa surface in the render (NFR-B9-1-002)" >&2; return 1; }
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo "── B.9.1 — b9-1-schema — level $LEVEL ──"
  run_test _test_b91_l1_001_schema_exists
  run_test _test_b91_l1_002_valid_yaml_not_legacy_shape
  run_test _test_b91_l1_003_identity
  run_test _test_b91_l1_004_scaffoldable_true
  run_test _test_b91_l1_005_tdd_bdd_coverage
  run_test _test_b91_l1_006_header_block
  run_test _test_b91_l1_007_golden_tests_required
  run_test _test_b91_l1_008_layers_exactly_two
  run_test _test_b91_l1_009_layer_agents
  run_test _test_b91_l1_010_neg_no_stub_layers
  run_test _test_b91_l1_011_live_validator_pass
  run_test _test_b91_l1_012_backward_compat_no_profile
  run_test _test_b91_l1_013_neg_default_profile_still_enforces_triple
  run_test _test_b91_l1_014_neg_unknown_profile
  run_test _test_b91_l1_015_phases_inline_no_extends
  run_test _test_b91_l1_016_tdd_flutter_chain
  run_test _test_b91_l1_017_channel_decision_placement
  run_test _test_b91_l1_018_pwa_specifics
  run_test _test_b91_l1_019_no_inline_pin
  run_test _test_b91_l1_020_deferred_components
  run_test _test_b91_l1_021_mobile_only_untouched
  run_test _test_b91_l1_022_dispatch_table_untouched
  run_test _test_b91_l1_023_validator_mirrors_in_sync
  case "$LEVEL" in
    *2*) run_test _test_b91_l2_001_init_renders ;;
  esac
  print_summary
}

main
