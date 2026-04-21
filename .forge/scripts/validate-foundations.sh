#!/usr/bin/env bash
# Forge — Foundations Structural Validator
# <!-- Audit: B.1 (b1-foundations) -->
#
# Validates that the deliverables of change `b1-foundations` are present
# and well-formed in the current FORGE_ROOT. Invoked from verify.sh on
# monorepo projects (i.e. when .forge/schemas/full-stack-monorepo/
# exists) and directly by b1-scaffolder once it lands.
#
# Contract:
#   - Exit 0 iff every FR-GL-00N check passes.
#   - Exit 1 if any check fails.
#   - Emits one line per FR-GL-00N check to stdout:
#       "PASS: FR-GL-00N — <short message>"
#       "FAIL: FR-GL-00N — <short message>"
#   - Idempotent: running twice on the same FORGE_ROOT produces the
#     same output and exit code (NFR-001).
#   - Must run < 2s on a standard dev machine (NFR-002).
#
# Parsing strategy (ADR-002): small python3 heredocs embedded in each
# check_* function, using yaml.safe_load only. No external deps beyond
# python3 stdlib, which is already present in the forge/linter image.
#
# Usage:
#   bash .forge/scripts/validate-foundations.sh
#   FORGE_ROOT=/path/to/fixture bash .forge/scripts/validate-foundations.sh

set -euo pipefail

FORGE_ROOT="${FORGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

PASS=0
FAIL=0

# ─── PASS/FAIL helpers ──────────────────────────────────────────

pass_fr() {
  # pass_fr <FR-GL-XXX> <message>
  PASS=$((PASS + 1))
  printf 'PASS: %s — %s\n' "$1" "$2"
}

fail_fr() {
  # fail_fr <FR-GL-XXX> <message>
  FAIL=$((FAIL + 1))
  printf 'FAIL: %s — %s\n' "$1" "$2"
}

finalize() {
  # finalize — prints nothing else; caller sees PASS/FAIL lines.
  # Exits 0 if FAIL==0, else 1.
  if [ "$FAIL" -eq 0 ]; then
    return 0
  fi
  return 1
}

# ─── Section presence helper ────────────────────────────────────

# check_sections <fr_id> <path> <section1> [section2 ...]
# Fails fast with a message listing missing sections.
check_sections() {
  local fr="$1"; shift
  local path="$1"; shift
  local rel="${path#$FORGE_ROOT/}"
  if [ ! -f "$path" ]; then
    fail_fr "$fr" "standard file missing: $rel"
    return
  fi
  local missing=()
  local section
  for section in "$@"; do
    # -F fixed string, -x match entire line, -q quiet
    if ! grep -qFx "## $section" "$path"; then
      missing+=("$section")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    # Join array with ", " for readability.
    local joined
    joined=$(IFS=, ; printf '%s' "${missing[*]}")
    joined="${joined//,/, }"
    fail_fr "$fr" "missing sections in $rel: $joined"
    return
  fi
  pass_fr "$fr" "${rel} has all required sections"
}

# ─── Individual FR checks ───────────────────────────────────────

check_schema_full_stack_monorepo() {
  local path="$FORGE_ROOT/.forge/schemas/full-stack-monorepo/schema.yaml"
  if [ ! -f "$path" ]; then
    fail_fr "FR-GL-001" "schema file missing: .forge/schemas/full-stack-monorepo/schema.yaml"
    return
  fi
  local result
  result=$(python3 - "$path" <<'PY'
import sys, re, yaml
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f"KO: YAML parse error: {e}"); sys.exit(0)

if not isinstance(data, dict):
    print("KO: schema root is not a mapping"); sys.exit(0)

if data.get('name') != 'full-stack-monorepo':
    print(f"KO: name mismatch (got {data.get('name')!r}, expected 'full-stack-monorepo')"); sys.exit(0)

version = data.get('version')
if not isinstance(version, str) or not re.match(r'^\d+\.\d+\.\d+(-[\w.-]+)?$', version):
    print(f"KO: version does not match SemVer (got {version!r})"); sys.exit(0)

layers = data.get('layers')
if not isinstance(layers, list) or not layers:
    print("KO: layers missing or empty"); sys.exit(0)

layer_ids = {l.get('id') for l in layers if isinstance(l, dict)}
required = {'backend', 'frontend', 'infra'}
if not required.issubset(layer_ids):
    missing = sorted(required - layer_ids)
    print(f"KO: layers must include at least backend, frontend, infra (missing: {missing})"); sys.exit(0)

for layer in layers:
    for key in ('id', 'path', 'fr_id_prefix', 'primary_agent'):
        if key not in layer:
            print(f"KO: layer {layer.get('id','?')!r} missing field {key!r}"); sys.exit(0)

stage = data.get('stage')
if stage not in ('draft', 'candidate', 'stable'):
    print(f"KO: stage must be one of draft/candidate/stable (got {stage!r})"); sys.exit(0)

if stage == 'stable':
    m = re.match(r'^(\d+)\.(\d+)\.(\d+)(-.*)?$', version)
    if not m or int(m.group(1)) < 1 or m.group(4):
        print(f"KO: stage=stable requires version >= 1.0.0 without prerelease (got {version!r})"); sys.exit(0)

phases = data.get('phases')
if not isinstance(phases, list) or not phases:
    print("KO: phases missing or empty"); sys.exit(0)

print(f"OK: schema {version} stage={stage} layers={sorted(layer_ids)}")
PY
)
  if [[ "$result" == OK:* ]]; then
    pass_fr "FR-GL-001" "${result#OK: }"
  else
    fail_fr "FR-GL-001" "${result#KO: }"
  fi
}

check_standard_monorepo_layout() {
  check_sections "FR-GL-002" \
    "$FORGE_ROOT/.forge/standards/global/monorepo-layout.md" \
    "Arborescence" \
    "Interdictions" \
    "CLAUDE.md imbriqués" \
    "Préfixes FR-ID"
}

check_standard_proto_contracts() {
  check_sections "FR-GL-003" \
    "$FORGE_ROOT/.forge/standards/global/proto-contracts.md" \
    "Arborescence shared/protos" \
    "Versioning (v1, v2, deprecation)" \
    "Gates CI (buf lint + buf breaking)" \
    "Génération des stubs (tonic-build, protoc_plugin)" \
    "Interdictions"
}

check_standard_docker_compose() {
  check_sections "FR-GL-004" \
    "$FORGE_ROOT/.forge/standards/infra/docker-compose.md" \
    "Service naming (fsm-*)" \
    "Réseau unique (fsm-dev)" \
    "Healthchecks obligatoires" \
    "Variables d'env (.env.example versionné)" \
    "Interdiction docker-compose.yml non suffixé"
}

check_git_workflow_scoped_commits() {
  local path="$FORGE_ROOT/.forge/standards/global/git-workflow.md"
  if [ ! -f "$path" ]; then
    fail_fr "FR-GL-005" "git-workflow.md missing"
    return
  fi
  if ! grep -qFx '## Scoped Conventional Commits (monorepo-only)' "$path"; then
    fail_fr "FR-GL-005" "section 'Scoped Conventional Commits (monorepo-only)' missing"
    return
  fi
  # Closed scope list must appear on one line containing all 7 tokens in order.
  if ! grep -qE 'backend.*frontend.*infra.*protos.*forge.*docs.*ci' "$path"; then
    fail_fr "FR-GL-005" "closed scope list {backend, frontend, infra, protos, forge, docs, ci} not found"
    return
  fi
  pass_fr "FR-GL-005" "git-workflow scoped commits section present"
}

check_index_new_entries() {
  local path="$FORGE_ROOT/.forge/standards/index.yml"
  if [ ! -f "$path" ]; then
    fail_fr "FR-GL-007" "index.yml missing"
    return
  fi
  local result
  result=$(python3 - "$path" <<'PY'
import sys, yaml
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f"KO: YAML parse error: {e}"); sys.exit(0)

standards = data.get('standards') if isinstance(data, dict) else None
if not isinstance(standards, list):
    print("KO: standards root missing or not a list"); sys.exit(0)

expected = {
    'global/monorepo-layout': {'scope': 'monorepo', 'priority': 'high'},
    'global/proto-contracts': {'scope': 'protos', 'priority': 'high'},
    'infra/docker-compose': {'scope': 'infra', 'priority': 'medium'},
}

found = {}
for entry in standards:
    if not isinstance(entry, dict): continue
    eid = entry.get('id')
    if eid in expected:
        found[eid] = entry

missing = sorted(set(expected) - set(found))
if missing:
    print(f"KO: missing index entries: {missing}"); sys.exit(0)

for eid, want in expected.items():
    got = found[eid]
    if got.get('scope') != want['scope']:
        print(f"KO: {eid} scope mismatch (got {got.get('scope')!r}, expected {want['scope']!r})"); sys.exit(0)
    if got.get('priority') != want['priority']:
        print(f"KO: {eid} priority mismatch (got {got.get('priority')!r}, expected {want['priority']!r})"); sys.exit(0)
    if not isinstance(got.get('triggers'), list) or not got['triggers']:
        print(f"KO: {eid} triggers missing or empty"); sys.exit(0)

print("OK: 3 new monorepo standards present and well-formed")
PY
)
  if [[ "$result" == OK:* ]]; then
    pass_fr "FR-GL-007" "${result#OK: }"
  else
    fail_fr "FR-GL-007" "${result#KO: }"
  fi
}

check_versioning_monorepo_section() {
  local path="$FORGE_ROOT/docs/VERSIONING.md"
  if [ ! -f "$path" ]; then
    fail_fr "FR-GL-006" "docs/VERSIONING.md missing"
    return
  fi
  if ! grep -qFx '## Monorepo Versioning Models' "$path"; then
    fail_fr "FR-GL-006" "section 'Monorepo Versioning Models' missing"
    return
  fi
  if ! grep -qFx '### Release-train' "$path"; then
    fail_fr "FR-GL-006" "subsection '### Release-train' missing"
    return
  fi
  if ! grep -qFx '### Per-package via release-please' "$path"; then
    fail_fr "FR-GL-006" "subsection '### Per-package via release-please' missing"
    return
  fi
  pass_fr "FR-GL-006" "versioning monorepo models present"
}

# ─── Main dispatcher ────────────────────────────────────────────

main() {
  # The Phase 1 RED stub for FR-GL-001 was replaced by check_schema_full_stack_monorepo
  # during Phase 2.1. Phase 3.1 task "remove the stub" is therefore retroactively done.
  check_schema_full_stack_monorepo
  check_standard_monorepo_layout
  check_standard_proto_contracts
  check_standard_docker_compose
  check_git_workflow_scoped_commits
  check_versioning_monorepo_section
  check_index_new_entries

  finalize
}

main "$@"
