#!/usr/bin/env bash
# Forge — `validate-change-yaml.sh` schema validator for per-change .forge.yaml
# <!-- Audit: F.2 (f2-yaml-schema, FR-YS-013..015) -->
#
# Validates a `.forge/changes/<name>/.forge.yaml` against
# `.forge/schemas/change.schema.json`, then enforces post-schema
# coherence rules (timeline-vs-status).
#
# Usage :
#   bash .forge/scripts/validate-change-yaml.sh <path-to-.forge.yaml>
#
# Exit codes :
#   0 — valid
#   1 — invalid (errors emitted on stderr, one per line)
#   2 — usage error (missing arg, file not found, schema not found)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCHEMA="$FORGE_ROOT/.forge/schemas/change.schema.json"

err() { echo "validate-change-yaml: $*" >&2; }

if [ $# -lt 1 ]; then
  err "usage: validate-change-yaml.sh <path-to-.forge.yaml>"
  exit 2
fi
target="$1"
if [ ! -f "$target" ]; then
  err "file not found: $target"
  exit 2
fi
if [ ! -f "$SCHEMA" ]; then
  err "schema not found: $SCHEMA"
  exit 2
fi

# Run validation in Python inline (no jsonschema lib — pure stdlib + PyYAML).
python3 - "$target" "$SCHEMA" <<'PY'
import json, re, sys
import yaml

target_path, schema_path = sys.argv[1], sys.argv[2]

errors = []

try:
    with open(target_path) as f:
        data = yaml.safe_load(f) or {}
except yaml.YAMLError as e:
    print(f"validate-change-yaml: {target_path}: yaml: parse error: {e}", file=sys.stderr)
    sys.exit(1)

# Coerce datetime.date / datetime.datetime to ISO string. PyYAML parses
# unquoted ISO dates (`2026-04-30`) as date objects ; the schema treats
# them as `type: string` (we never quote dates in `.forge.yaml`). Walk
# the tree and stringify dates.
import datetime
def _coerce_dates(node):
    if isinstance(node, dict):
        return {k: _coerce_dates(v) for k, v in node.items()}
    if isinstance(node, list):
        return [_coerce_dates(v) for v in node]
    if isinstance(node, (datetime.date, datetime.datetime)):
        return node.isoformat()[:10]  # YYYY-MM-DD
    return node
data = _coerce_dates(data)

with open(schema_path) as f:
    schema = json.load(f)


def emit(field, reason):
    errors.append(f"validate-change-yaml: {target_path}: {field}: {reason}")


# ── Phase 1: schema validation ───────────────────────────────

if not isinstance(data, dict):
    emit("(root)", "expected object, got " + type(data).__name__)
else:
    # Required keys
    for key in schema.get("required", []):
        if key not in data:
            emit(key, "required field missing")

    # additionalProperties: false
    if schema.get("additionalProperties") is False:
        for key in data.keys():
            if key not in schema.get("properties", {}):
                emit(key, "unknown field (additionalProperties: false)")

    # Per-property checks
    for key, value in data.items():
        prop_schema = schema.get("properties", {}).get(key)
        if not prop_schema:
            continue  # already flagged above if root additionalProperties=false

        # Type
        expected_type = prop_schema.get("type")
        type_map = {
            "string": str,
            "object": dict,
            "array": list,
            "integer": int,
            "number": (int, float),
            "boolean": bool,
        }
        if expected_type and expected_type in type_map:
            if not isinstance(value, type_map[expected_type]):
                emit(key, f"expected type {expected_type}, got {type(value).__name__}")
                continue  # skip further checks on this field

        # Enum
        if "enum" in prop_schema:
            if value not in prop_schema["enum"]:
                emit(key, f"'{value}' not in enum {prop_schema['enum']}")

        # Pattern (string only)
        if "pattern" in prop_schema and isinstance(value, str):
            if not re.match(prop_schema["pattern"], value):
                emit(key, f"pattern mismatch (expected /{prop_schema['pattern']}/)")

        # timeline sub-validation
        if key == "timeline" and isinstance(value, dict):
            tl_schema = prop_schema
            tl_props = tl_schema.get("properties", {})
            if tl_schema.get("additionalProperties") is False:
                for sub in value.keys():
                    if sub not in tl_props:
                        emit(f"timeline.{sub}", "unknown timeline phase")
            for sub_key, sub_value in value.items():
                sub_schema = tl_props.get(sub_key, {})
                if "pattern" in sub_schema and isinstance(sub_value, str):
                    if not re.match(sub_schema["pattern"], sub_value):
                        emit(f"timeline.{sub_key}", f"pattern mismatch (expected /{sub_schema['pattern']}/)")
                elif not isinstance(sub_value, str):
                    emit(f"timeline.{sub_key}", f"expected type string, got {type(sub_value).__name__}")


# ── Phase 2: timeline coherence ──────────────────────────────

status = data.get("status") if isinstance(data, dict) else None
timeline = data.get("timeline", {}) if isinstance(data, dict) else {}
if isinstance(status, str) and isinstance(timeline, dict):
    # FR-YS-008: timeline.<phase> required when status >= phase.
    phase_order = ["proposed", "specified", "designed", "planned", "implemented", "archived"]
    if status in phase_order:
        idx = phase_order.index(status)
        for phase in phase_order[1:idx + 1]:  # specified onwards (proposed is implicitly present in `created`)
            if phase not in timeline:
                emit(f"timeline.{phase}", f"missing while status is '{status}'")
    # FR-YS-009: when archived, all prior phases must be in timeline.
    if status == "archived":
        for phase in phase_order:
            if phase not in timeline:
                emit(f"timeline.{phase}", f"missing while status is 'archived' (full timeline required)")


if errors:
    for e in errors:
        print(e, file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PY
rc=$?
exit $rc
