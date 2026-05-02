#!/usr/bin/env bash
# Forge — F.2 Change YAML Schema Test Harness (f2-yaml-schema)
# <!-- Audit: F.2 (f2-yaml-schema) -->
#
# Validates :
#  - Schema JSON file at .forge/schemas/change.schema.json (FR-YS-001..012)
#  - Validator script .forge/scripts/validate-change-yaml.sh (FR-YS-013..015)
#  - verify.sh "Change YAML Schema" section (FR-YS-016)
#  - Standard global/change-yaml-schema.md + index entry (FR-YS-018, FR-YS-019)
#  - Docs reference (FR-YS-020)
#  - Backward compatibility: 11 archived changes pass (NFR-YS-001) [L2]
#  - L2 fixture-based: valid/invalid name/status/timeline cases [L2]

set -uo pipefail

LEVEL="1"
prev=""
for arg in "$@"; do
  if [ "$prev" = "--level" ]; then LEVEL="$arg"; fi
  case "$arg" in
    --level=*) LEVEL="${arg#*=}" ;;
  esac
  prev="$arg"
done

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$HARNESS_DIR/.." && pwd)"
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

SCHEMA_JSON="$FORGE_ROOT_REAL/.forge/schemas/change.schema.json"
VALIDATOR="$FORGE_ROOT_REAL/.forge/scripts/validate-change-yaml.sh"
VERIFY_SH="$FORGE_ROOT_REAL/.forge/scripts/verify.sh"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
STD_YS="$FORGE_ROOT_REAL/.forge/standards/global/change-yaml-schema.md"
CI_WORKFLOW="$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml"
DOCS_SCHEMA="$FORGE_ROOT_REAL/docs/SCHEMA.md"
DOCS_GUIDE="$FORGE_ROOT_REAL/docs/GUIDE.md"
CHANGES_DIR="$FORGE_ROOT_REAL/.forge/changes"
ARCHETYPES_DIR="$FORGE_ROOT_REAL/.forge/schemas"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# MANIFEST: _test_f2_001 — FR-YS-001 schema.json exists + parses
# MANIFEST: _test_f2_002 — FR-YS-001 schema declares required + additionalProperties
# MANIFEST: _test_f2_003 — FR-YS-002 name pattern
# MANIFEST: _test_f2_004 — FR-YS-003 status enum 6 values
# MANIFEST: _test_f2_005 — FR-YS-004 created ISO date pattern
# MANIFEST: _test_f2_006 — FR-YS-005 schema enum (drift detector vs filesystem)
# MANIFEST: _test_f2_007 — FR-YS-006 constitution_version semver pattern
# MANIFEST: _test_f2_008 — FR-YS-013 validator script exists + executable
# MANIFEST: _test_f2_009 — FR-YS-016 verify.sh "Change YAML Schema" section
# MANIFEST: _test_f2_010 — FR-YS-018 standard exists with 5 H2 sections
# MANIFEST: _test_f2_011 — FR-YS-019 index.yml entry
# MANIFEST: _test_f2_012 — FR-YS-020 docs SCHEMA.md or GUIDE.md mentions schema
# MANIFEST: _test_f2_013 — FR-YS-021 CI workflow registers f2.test.sh
#
# L2 fixture-based
# MANIFEST: _test_f2_l2_001 — valid .forge.yaml → exit 0
# MANIFEST: _test_f2_l2_002 — invalid name (uppercase) → exit 1
# MANIFEST: _test_f2_l2_003 — invalid status (closed) → exit 1
# MANIFEST: _test_f2_l2_004 — archived without timeline.archived → exit 1
# MANIFEST: _test_f2_l2_005 — all 11 archived changes pass (NFR-YS-001)

# ─── L1 tests ────────────────────────────────────────────────────

_test_f2_001() {
  [ -f "$SCHEMA_JSON" ] || { echo "    expected: $SCHEMA_JSON" >&2; return 1; }
  python3 -c "import json; json.load(open('$SCHEMA_JSON'))" \
    || { echo "    schema.json not valid JSON" >&2; return 1; }
}

_test_f2_002() {
  [ -f "$SCHEMA_JSON" ] || { echo "    schema missing" >&2; return 1; }
  python3 - "$SCHEMA_JSON" <<'PY' || return 1
import json, sys
d = json.load(open(sys.argv[1]))
required = d.get('required', [])
for k in ['name', 'status', 'created', 'schema', 'constitution_version']:
    if k not in required:
        print(f"    required key missing: {k}", file=sys.stderr); sys.exit(1)
if d.get('additionalProperties') is not False:
    print("    additionalProperties not false", file=sys.stderr); sys.exit(1)
PY
}

_test_f2_003() {
  [ -f "$SCHEMA_JSON" ] || { echo "    schema missing" >&2; return 1; }
  python3 - "$SCHEMA_JSON" <<'PY' || return 1
import json, sys
d = json.load(open(sys.argv[1]))
pat = d.get('properties', {}).get('name', {}).get('pattern', '')
if not pat.startswith('^[a-z]'):
    print(f"    name pattern not starting with [a-z]: {pat}", file=sys.stderr); sys.exit(1)
PY
}

_test_f2_004() {
  [ -f "$SCHEMA_JSON" ] || { echo "    schema missing" >&2; return 1; }
  python3 - "$SCHEMA_JSON" <<'PY' || return 1
import json, sys
d = json.load(open(sys.argv[1]))
enum = d.get('properties', {}).get('status', {}).get('enum', [])
expected = {'proposed', 'specified', 'designed', 'planned', 'implemented', 'archived'}
if set(enum) != expected:
    print(f"    status enum mismatch: got {sorted(enum)}, want {sorted(expected)}", file=sys.stderr); sys.exit(1)
PY
}

_test_f2_005() {
  [ -f "$SCHEMA_JSON" ] || { echo "    schema missing" >&2; return 1; }
  python3 - "$SCHEMA_JSON" <<'PY' || return 1
import json, sys
d = json.load(open(sys.argv[1]))
pat = d.get('properties', {}).get('created', {}).get('pattern', '')
# Expected ISO 8601 simple: ^[0-9]{4}-[0-9]{2}-[0-9]{2}$
if '[0-9]{4}' not in pat or '[0-9]{2}' not in pat:
    print(f"    created pattern not ISO 8601: {pat}", file=sys.stderr); sys.exit(1)
PY
}

_test_f2_006() {
  [ -f "$SCHEMA_JSON" ] || { echo "    schema missing" >&2; return 1; }
  # Drift detector: enum schema MUST equal set of dirs under .forge/schemas/.
  python3 - "$SCHEMA_JSON" "$ARCHETYPES_DIR" <<'PY' || return 1
import json, os, sys
schema_path = sys.argv[1]
archetypes_dir = sys.argv[2]
d = json.load(open(schema_path))
enum_in_schema = set(d.get('properties', {}).get('schema', {}).get('enum', []))
on_disk = set()
for entry in os.listdir(archetypes_dir):
    full = os.path.join(archetypes_dir, entry)
    if os.path.isdir(full) and os.path.isfile(os.path.join(full, 'schema.yaml')):
        on_disk.add(entry)
missing_in_schema = on_disk - enum_in_schema
extra_in_schema = enum_in_schema - on_disk
if missing_in_schema or extra_in_schema:
    if missing_in_schema:
        print(f"    archetype on disk but not in enum: {sorted(missing_in_schema)}", file=sys.stderr)
    if extra_in_schema:
        print(f"    enum has archetype not on disk: {sorted(extra_in_schema)}", file=sys.stderr)
    sys.exit(1)
PY
}

_test_f2_007() {
  [ -f "$SCHEMA_JSON" ] || { echo "    schema missing" >&2; return 1; }
  python3 - "$SCHEMA_JSON" <<'PY' || return 1
import json, sys
d = json.load(open(sys.argv[1]))
pat = d.get('properties', {}).get('constitution_version', {}).get('pattern', '')
if '[0-9]+' not in pat or pat.count('\\\\.') < 2:
    # Looking for ^[0-9]+\.[0-9]+\.[0-9]+$
    if '\\.' not in pat:
        print(f"    constitution_version pattern not semver-like: {pat}", file=sys.stderr); sys.exit(1)
PY
}

_test_f2_008() {
  [ -f "$VALIDATOR" ] || { echo "    expected: $VALIDATOR" >&2; return 1; }
  [ -x "$VALIDATOR" ] || { echo "    validator not executable" >&2; return 1; }
}

_test_f2_009() {
  [ -f "$VERIFY_SH" ] || { echo "    verify.sh missing" >&2; return 1; }
  grep -qiE 'Change YAML Schema' "$VERIFY_SH" \
    || { echo "    'Change YAML Schema' section missing in verify.sh" >&2; return 1; }
}

_test_f2_010() {
  [ -f "$STD_YS" ] || { echo "    expected: $STD_YS" >&2; return 1; }
  local sections=("Purpose" "Schema Reference" "Required Fields" \
                  "Timeline Coherence Rules" "Extending the Schema")
  local missing=()
  for s in "${sections[@]}"; do
    grep -qE "^## ${s}\$" "$STD_YS" || missing+=("$s")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    missing H2 sections: ${missing[*]}" >&2; return 1
  fi
}

_test_f2_011() {
  [ -f "$INDEX_YML" ] || { echo "    index.yml missing" >&2; return 1; }
  grep -qF 'change-yaml-schema' "$INDEX_YML" \
    || { echo "    change-yaml-schema entry missing in index.yml" >&2; return 1; }
}

_test_f2_012() {
  if [ -f "$DOCS_SCHEMA" ]; then
    grep -qiE 'change.yaml|schema' "$DOCS_SCHEMA" \
      || { echo "    docs/SCHEMA.md does not reference schema" >&2; return 1; }
  elif [ -f "$DOCS_GUIDE" ]; then
    grep -qiE 'change yaml schema|change.yaml schema' "$DOCS_GUIDE" \
      || { echo "    docs/GUIDE.md missing schema section" >&2; return 1; }
  else
    echo "    neither docs/SCHEMA.md nor docs/GUIDE.md exists" >&2; return 1
  fi
}

_test_f2_013() {
  [ -f "$CI_WORKFLOW" ] || { echo "    forge-ci.yml missing" >&2; return 1; }
  grep -qF 'f2.test.sh' "$CI_WORKFLOW" \
    || { echo "    f2.test.sh not registered in forge-ci.yml" >&2; return 1; }
}

# ─── L2 fixture-based tests ──────────────────────────────────────

_make_fixture_yaml() {
  # _make_fixture_yaml <path> <name> <status> [timeline-block]
  local path="$1" name="$2" status="$3" timeline_block="${4:-}"
  cat > "$path" <<EOF
name: $name
status: $status
created: 2026-04-30
schema: default
constitution_version: "1.1.0"
EOF
  if [ -n "$timeline_block" ]; then
    printf '%s\n' "$timeline_block" >> "$path"
  fi
}

_test_f2_l2_001() {
  [ -x "$VALIDATOR" ] || { echo "    validator missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f2-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_yaml "$tmp/.forge.yaml" "valid-change" "proposed" \
    "timeline:
  proposed: 2026-04-30"
  local rc=0
  bash "$VALIDATOR" "$tmp/.forge.yaml" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "    valid yaml rejected, exit $rc" >&2; return 1
  fi
}

_test_f2_l2_002() {
  [ -x "$VALIDATOR" ] || { echo "    validator missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f2-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_yaml "$tmp/.forge.yaml" "Invalid_Name" "proposed" \
    "timeline:
  proposed: 2026-04-30"
  local rc=0
  bash "$VALIDATOR" "$tmp/.forge.yaml" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "    invalid name accepted (uppercase + underscore)" >&2; return 1
  fi
}

_test_f2_l2_003() {
  [ -x "$VALIDATOR" ] || { echo "    validator missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f2-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  _make_fixture_yaml "$tmp/.forge.yaml" "test-change" "closed"
  local rc=0
  bash "$VALIDATOR" "$tmp/.forge.yaml" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "    invalid status 'closed' accepted" >&2; return 1
  fi
}

_test_f2_l2_004() {
  [ -x "$VALIDATOR" ] || { echo "    validator missing" >&2; return 1; }
  local tmp
  tmp=$(mktemp -d -t f2-l2-XXXXXX)
  trap "rm -rf '$tmp'" RETURN
  # archived but no timeline.archived
  _make_fixture_yaml "$tmp/.forge.yaml" "test-change" "archived" \
    "timeline:
  proposed: 2026-04-29
  specified: 2026-04-29
  designed: 2026-04-29
  planned: 2026-04-29
  implemented: 2026-04-30"
  local rc=0
  bash "$VALIDATOR" "$tmp/.forge.yaml" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "    archived without timeline.archived accepted" >&2; return 1
  fi
}

_test_f2_l2_005() {
  [ -x "$VALIDATOR" ] || { echo "    validator missing" >&2; return 1; }
  [ -d "$CHANGES_DIR" ] || { echo "    changes dir missing" >&2; return 1; }
  local failed=()
  for yaml in "$CHANGES_DIR"/*/.forge.yaml; do
    [ -f "$yaml" ] || continue
    if ! bash "$VALIDATOR" "$yaml" >/dev/null 2>&1; then
      failed+=("$yaml")
    fi
  done
  if [ "${#failed[@]}" -gt 0 ]; then
    echo "    NFR-YS-001 violation: ${#failed[@]} archived change(s) fail validation" >&2
    for f in "${failed[@]}"; do echo "      - $f" >&2; done
    return 1
  fi
}

# ─── Main ───────────────────────────────────────────────────────

main() {
  echo "Forge — f2-yaml-schema Test Harness"
  echo "FORGE_ROOT_REAL=$FORGE_ROOT_REAL"
  echo "LEVEL=$LEVEL"
  echo ""
  echo "── L1 hermetic ──"
  run_test _test_f2_001
  run_test _test_f2_002
  run_test _test_f2_003
  run_test _test_f2_004
  run_test _test_f2_005
  run_test _test_f2_006
  run_test _test_f2_007
  run_test _test_f2_008
  run_test _test_f2_009
  run_test _test_f2_010
  run_test _test_f2_011
  run_test _test_f2_012
  run_test _test_f2_013

  case ",$LEVEL," in
    *,2,*)
      echo ""
      echo "── L2 fixture-based ──"
      run_test _test_f2_l2_001
      run_test _test_f2_l2_002
      run_test _test_f2_l2_003
      run_test _test_f2_l2_004
      run_test _test_f2_l2_005
      ;;
  esac

  print_summary
}

main "$@"
