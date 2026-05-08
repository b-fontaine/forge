#!/usr/bin/env bash
# Forge — `validate-standards-yaml.sh` schema validator for .forge/standards/*.yaml
# <!-- Audit: J.7 (j7-validate-standards-yaml, FR-J7-060..064) -->
#
# Validates one or more `.forge/standards/<name>.yaml` files against
# `.forge/schemas/standard.schema.json` (Phase 1) plus the lifecycle
# invariants from `global/standards-lifecycle.md` (Phase 2).
#
# Phase 2 includes :
#   - bidirectional Article XII coupling : `expires_at: never` ⇔ `exception_constitutional: true` (FR-J7-020)
#   - `expires_at > last_reviewed` strict ordering when both dated (FR-J7-021)
#   - 12-month review cycle informational ([STD-INFO]) (FR-J7-022)
#   - REVIEW.md ledger drift : declared `version` MUST appear (FR-J7-023, ADR-J7-003)
#   - `linter_rule` cross-reference into `constitution-linter.sh` (FR-J7-030, ADR-J7-002)
#   - `index.yml` triggers reachability + orphan-standard INFO (FR-J7-050..051)
#   - `forbidden:` list shape + no-duplicate (FR-J7-040..041)
#
# Usage :
#   bash bin/validate-standards-yaml.sh                 # default .forge/standards/
#   bash bin/validate-standards-yaml.sh <dir>           # validate every *.yaml in <dir>
#   bash bin/validate-standards-yaml.sh <file.yaml>     # validate a single file
#
# Output :
#   stdout  [STD-PASS] <relative-path>            for clean files
#           [STD-INFO: <path>:<field>: <reason>]  non-blocking informational lines
#   stderr  [STD-FAIL: <path>:<field>: <reason>]  one line per violation
#
# Exit codes :
#   0 — all PASS (INFO lines do not affect exit)
#   1 — ≥ 1 FAIL
#   2 — usage error (missing arg, file not found, schema not found)
#
# Environment overrides (test-only, undocumented in the user-facing standard) :
#   FORGE_J7_LINTER_PATH    override constitution-linter.sh path
#   FORGE_J7_REVIEW_PATH    override REVIEW.md path
#   FORGE_J7_INDEX_PATH     override index.yml path
#   FORGE_J7_SCHEMA_PATH    override schema path
#
# F.2 helpers reused : PyYAML date coercion (lines 55-67 of validate-change-yaml.sh),
# Phase-1 schema-walk skeleton (lines 78-139), error-accumulation pattern.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SCHEMA="${FORGE_J7_SCHEMA_PATH:-$FORGE_ROOT/.forge/schemas/standard.schema.json}"
DEFAULT_STD_DIR="$FORGE_ROOT/.forge/standards"

err() { echo "validate-standards-yaml: $*" >&2; }

target="${1:-$DEFAULT_STD_DIR}"

if [ ! -e "$target" ]; then
  err "path not found: $target"
  exit 2
fi
if [ ! -f "$SCHEMA" ]; then
  err "schema not found: $SCHEMA"
  exit 2
fi

# Resolve the file list. If target is a directory, glob top-level *.yaml
# (excluding index.yml). If target is a file, validate it directly.
files=()
if [ -d "$target" ]; then
  for f in "$target"/*.yaml; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    [ "$base" = "index.yml" ] && continue
    files+=("$f")
  done
else
  files+=("$target")
fi

if [ "${#files[@]}" -eq 0 ]; then
  err "no .yaml files found under: $target"
  exit 2
fi

# Resolve cross-reference paths. Defaults are sibling-of-target for
# REVIEW.md / index.yml when target is a dir, else dirname-of-file
# for the single-file case. Env vars override for tests.
if [ -d "$target" ]; then
  ctx_dir="$target"
else
  ctx_dir="$(cd "$(dirname "$target")" && pwd)"
fi
REVIEW_PATH="${FORGE_J7_REVIEW_PATH:-$ctx_dir/REVIEW.md}"
INDEX_PATH="${FORGE_J7_INDEX_PATH:-$ctx_dir/index.yml}"
LINTER_PATH="${FORGE_J7_LINTER_PATH:-$FORGE_ROOT/.forge/scripts/constitution-linter.sh}"

# Build the file-list argument as one path per line for Python.
file_list_str=""
for f in "${files[@]}"; do
  file_list_str+="$f"$'\n'
done

python3 - "$SCHEMA" "$REVIEW_PATH" "$INDEX_PATH" "$LINTER_PATH" "$FORGE_ROOT" "$file_list_str" <<'PY'
import datetime
import json
import os
import re
import sys

import yaml

schema_path = sys.argv[1]
review_path = sys.argv[2]
index_path = sys.argv[3]
linter_path = sys.argv[4]
forge_root = sys.argv[5]
file_list = [p for p in sys.argv[6].splitlines() if p.strip()]


def relpath(p: str) -> str:
    try:
        return os.path.relpath(p, forge_root)
    except ValueError:
        return p


def coerce_dates(node):
    if isinstance(node, dict):
        return {k: coerce_dates(v) for k, v in node.items()}
    if isinstance(node, list):
        return [coerce_dates(v) for v in node]
    if isinstance(node, (datetime.date, datetime.datetime)):
        return node.isoformat()[:10]
    return node


with open(schema_path) as f:
    schema = json.load(f)

# Cache cross-reference contexts (read once, reused per file).
review_text = ""
if os.path.isfile(review_path):
    with open(review_path) as f:
        review_text = f.read()

index_data = {}
if os.path.isfile(index_path):
    try:
        with open(index_path) as f:
            index_data = yaml.safe_load(f) or {}
    except yaml.YAMLError:
        index_data = {}

linter_text = ""
if os.path.isfile(linter_path):
    with open(linter_path) as f:
        linter_text = f.read()


# Collect all referenced standard paths from index.yml (FR-J7-050).
def _collect_index_paths(node):
    out = []
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "path" and isinstance(v, str):
                out.append(v)
            else:
                out.extend(_collect_index_paths(v))
    elif isinstance(node, list):
        for v in node:
            out.extend(_collect_index_paths(v))
    return out


index_paths = _collect_index_paths(index_data)


type_map = {
    "string": (str,),
    "object": (dict,),
    "array": (list,),
    "integer": (int,),
    "number": (int, float),
    "boolean": (bool,),
}


def _type_match(value, expected):
    if isinstance(expected, list):
        for et in expected:
            if et == "null" and value is None:
                return True
            if et in type_map and isinstance(value, type_map[et]):
                # bool is subclass of int — narrow check
                if et == "integer" and isinstance(value, bool):
                    continue
                return True
        return False
    if expected in type_map:
        if expected == "integer" and isinstance(value, bool):
            return False
        return isinstance(value, type_map[expected])
    return True


had_global_fail = False
emitted_orphan_check = False
indexed_files = set()
for ip in index_paths:
    base = os.path.basename(ip)
    indexed_files.add(base)


def validate_file(path: str):
    global had_global_fail
    rel = relpath(path)
    errors = []
    infos = []

    try:
        with open(path) as f:
            data = yaml.safe_load(f) or {}
    except yaml.YAMLError as e:
        print(f"[STD-FAIL: {rel}:(yaml): parse error: {e}]", file=sys.stderr)
        had_global_fail = True
        return

    data = coerce_dates(data)

    if not isinstance(data, dict):
        print(f"[STD-FAIL: {rel}:(root): expected object, got {type(data).__name__}]", file=sys.stderr)
        had_global_fail = True
        return

    # ── Phase 1: schema field walk ─────────────────────────────
    for key in schema.get("required", []):
        if key not in data:
            errors.append((key, "required field missing"))

    for key, value in data.items():
        prop = schema.get("properties", {}).get(key)
        if not prop:
            continue  # body fields — additionalProperties:true at root

        # Type
        expected_type = prop.get("type")
        if expected_type and not _type_match(value, expected_type):
            actual = "null" if value is None else type(value).__name__
            errors.append((key, f"expected type {expected_type}, got {actual}"))
            continue

        # Pattern (string only)
        if "pattern" in prop and isinstance(value, str):
            if not re.match(prop["pattern"], value):
                errors.append((key, f"pattern mismatch (expected /{prop['pattern']}/)"))

        # minLength (string only)
        if "minLength" in prop and isinstance(value, str):
            if len(value) < prop["minLength"]:
                errors.append((key, f"minLength {prop['minLength']} not met (got len {len(value)})"))

        # Nested object schema (enforcement)
        if isinstance(value, dict) and prop.get("type") == "object":
            sub_props = prop.get("properties", {})
            for sub_req in prop.get("required", []):
                if sub_req not in value:
                    errors.append((f"{key}.{sub_req}", "required field missing"))
            if prop.get("additionalProperties") is False:
                for sub_key in value.keys():
                    if sub_key not in sub_props:
                        errors.append((f"{key}.{sub_key}", "unknown field (additionalProperties: false)"))
            for sub_key, sub_value in value.items():
                sub_schema = sub_props.get(sub_key, {})
                sub_type = sub_schema.get("type")
                if sub_type and not _type_match(sub_value, sub_type):
                    sub_actual = "null" if sub_value is None else type(sub_value).__name__
                    errors.append((f"{key}.{sub_key}", f"expected type {sub_type}, got {sub_actual}"))

    # ── Phase 2: lifecycle invariants ──────────────────────────
    expires_at = data.get("expires_at")
    last_reviewed = data.get("last_reviewed")
    exc = data.get("exception_constitutional")
    version = data.get("version")
    linter_rule = data.get("linter_rule")
    forbidden = data.get("forbidden")

    # FR-J7-005 expires_at polymorphic check (date OR "never")
    if isinstance(expires_at, str):
        if expires_at != "never" and not re.match(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$", expires_at):
            errors.append(("expires_at", f"expected ISO date or 'never', got '{expires_at}'"))

    # FR-J7-007 linter_rule kebab-case pattern when non-null
    if isinstance(linter_rule, str):
        if not re.match(r"^[a-z][a-z0-9-]*$", linter_rule):
            errors.append(("linter_rule", f"pattern mismatch (expected kebab-case, got '{linter_rule}')"))

    # FR-J7-020 bidirectional Article XII coupling
    if expires_at == "never" and exc is False:
        errors.append(("expires_at", "never requires exception_constitutional: true (Article XII)"))
    if exc is True and isinstance(expires_at, str) and expires_at != "never":
        errors.append(("exception_constitutional", "true requires expires_at: never (Article XII)"))

    # FR-J7-021 expires_at > last_reviewed strict ordering when dated
    if (
        isinstance(expires_at, str)
        and isinstance(last_reviewed, str)
        and expires_at != "never"
        and re.match(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$", expires_at)
        and re.match(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$", last_reviewed)
    ):
        try:
            d_exp = datetime.date.fromisoformat(expires_at)
            d_lr = datetime.date.fromisoformat(last_reviewed)
            if d_exp <= d_lr:
                errors.append(("expires_at", f"must be strictly greater than last_reviewed ({expires_at} <= {last_reviewed})"))
            # FR-J7-022 informational : > 13 months loose
            if (d_exp - d_lr).days > 13 * 30 + 5:  # tolerant ~ 13 months + 5d slack
                infos.append(("expires_at", f"cycle exceeds ~12 months ({(d_exp - d_lr).days} days)"))
        except ValueError:
            pass  # invalid dates already flagged by schema phase

    # FR-J7-023 REVIEW.md drift — full ledger scan (ADR-J7-003)
    if review_text and isinstance(version, str):
        base = os.path.basename(path)
        # Match a markdown table row : | <basename> | <version> | ...
        needle = re.compile(
            r"\|\s*" + re.escape(base) + r"\s*\|\s*" + re.escape(version) + r"\s*\|",
            re.M,
        )
        if not needle.search(review_text):
            errors.append(("version", f"declared {version} not present in REVIEW.md ledger"))

    # FR-J7-030 linter_rule cross-reference — section-anchor grep (ADR-J7-002)
    if isinstance(linter_rule, str) and linter_text:
        anchor = re.compile(
            r"^\s*(echo|#).*\b" + re.escape(linter_rule) + r"\b",
            re.M,
        )
        if not anchor.search(linter_text):
            errors.append(("linter_rule", f"rule \"{linter_rule}\" not found as section header or comment in constitution-linter.sh"))

    # FR-J7-040 / FR-J7-041 forbidden list shape + no-duplicate
    if isinstance(forbidden, list):
        seen = {}
        for i, entry in enumerate(forbidden):
            if not isinstance(entry, str):
                errors.append((f"forbidden[{i}]", f"expected string, got {type(entry).__name__}"))
                continue
            if entry != entry.strip() or entry == "":
                errors.append((f"forbidden[{i}]", f"empty or untrimmed entry: '{entry}'"))
                continue
            if entry in seen:
                errors.append((f"forbidden[{i}]", f"duplicate entry '{entry}' (first at index {seen[entry]})"))
            else:
                seen[entry] = i

    # ── Emit ───────────────────────────────────────────────────
    if errors:
        for field, reason in errors:
            print(f"[STD-FAIL: {rel}:{field}: {reason}]", file=sys.stderr)
        had_global_fail = True
    else:
        print(f"[STD-PASS] {rel}")

    for field, reason in infos:
        print(f"[STD-INFO: {rel}:{field}: {reason}]")


for path in file_list:
    validate_file(path)


# ── Phase 2 cross-cutting : index.yml triggers + orphan check ───

if index_data:
    # FR-J7-050 dangling triggers : every index.yml `path:` to a standard MUST exist.
    # index.yml uses paths relative to .forge/ (e.g. "standards/global/tdd-rules.md"
    # resolves to .forge/standards/global/tdd-rules.md).
    for ip in index_paths:
        if not ip.endswith(".yaml") and not ip.endswith(".md"):
            continue
        if os.path.isabs(ip):
            candidates = [ip]
        else:
            candidates = [
                os.path.join(forge_root, ".forge", ip),  # canonical : index.yml paths are .forge-relative
                os.path.join(forge_root, ip),            # fallback : repo-root-relative
            ]
        if not any(os.path.isfile(c) for c in candidates):
            print(
                f"[STD-FAIL: index.yml:trigger: dangling path '{ip}' (file does not exist)]",
                file=sys.stderr,
            )
            had_global_fail = True

    # FR-J7-051 orphan standards (informational only)
    for path in file_list:
        base = os.path.basename(path)
        if base not in indexed_files:
            print(f"[STD-INFO: {relpath(path)}:index: standard not referenced by any index.yml trigger]")


sys.exit(1 if had_global_fail else 0)
PY
rc=$?
exit $rc
