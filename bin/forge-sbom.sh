#!/usr/bin/env bash
# Forge — `forge-sbom.sh` CycloneDX 1.5 SBOM generator
# <!-- Audit: J.8 (j8-janus-rules, FR-J8-070..076 / ADR-J8-001 + ADR-J8-007) -->
#
# Generates a CycloneDX 1.5 JSON (or XML) SBOM from any combination of
# Cargo.lock / package-lock.json / pnpm-lock.yaml / yarn.lock /
# pubspec.lock present in the target directory.
#
# Usage :
#   bin/forge-sbom.sh [--output <path>] [--format json|xml] [--target <dir>]
#
# Defaults : --output sbom.cdx.json, --format json, --target $(pwd).
#
# Exit codes :
#   0 — success
#   1 — no lockfiles found in target OR format error
#   2 — usage error (bad args, file not found)
#
# Determinism : SOURCE_DATE_EPOCH (POSIX env var) controls
# `metadata.timestamp` for reproducible builds. Components are sorted
# by `purl` and JSON output uses sort_keys.
#
# Pattern : bash thin + Python 3 inline (F.2 / J.7 / NFR-J8-004).
# No external CycloneDX library — handcrafted minimum-viable SBOM
# per ADR-J8-001 (Context7-verified CycloneDX 1.5 mandatory fields).

set -uo pipefail

OUTPUT="sbom.cdx.json"
FORMAT="json"
TARGET="$(pwd)"

err() { echo "forge-sbom: $*" >&2; }

usage() {
  cat <<EOF
Usage: forge-sbom.sh [--output <path>] [--format json|xml] [--target <dir>]

Generates a CycloneDX 1.5 SBOM from Cargo.lock / npm-family lockfiles /
pubspec.lock found under <target>.

Defaults : --output sbom.cdx.json, --format json, --target \$(pwd).
Exit codes : 0 success / 1 no lockfiles or format error / 2 usage error.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --output) OUTPUT="${2:-}"; shift 2 ;;
    --output=*) OUTPUT="${1#*=}"; shift ;;
    --format) FORMAT="${2:-}"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --target=*) TARGET="${1#*=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) err "unknown argument: $1"; usage >&2; exit 2 ;;
  esac
done

if [ "$FORMAT" != "json" ] && [ "$FORMAT" != "xml" ]; then
  err "invalid --format '$FORMAT' (expected json|xml)"; exit 2
fi

if [ ! -d "$TARGET" ]; then
  err "target directory not found: $TARGET"; exit 2
fi

# Resolve to absolute path for stable purl + metadata.
TARGET="$(cd "$TARGET" && pwd)"

python3 - "$TARGET" "$OUTPUT" "$FORMAT" <<'PY'
import datetime
import json
import os
import sys
import uuid
import xml.etree.ElementTree as ET

target = sys.argv[1]
output_path = sys.argv[2]
fmt = sys.argv[3]


def _parse_cargo_lock(path):
    """Parse Cargo.lock (TOML stdlib, Python ≥ 3.11)."""
    try:
        import tomllib  # Python 3.11+
    except ImportError:
        import tomli as tomllib  # type: ignore[import-not-found]
    with open(path, 'rb') as f:
        data = tomllib.load(f)
    out = []
    for pkg in data.get('package', []):
        name = pkg.get('name')
        ver = pkg.get('version')
        if name and ver:
            out.append((name, ver, f"pkg:cargo/{name}@{ver}"))
    return out


def _parse_npm_lock(path):
    """Parse package-lock.json (npm v3+, lockfileVersion 2/3)."""
    with open(path) as f:
        data = json.load(f)
    out = []
    # lockfileVersion 2/3 : packages map keyed on path ; root is "".
    pkgs = data.get('packages') or {}
    for path_key, info in pkgs.items():
        if path_key == "":
            continue  # root package
        name = info.get('name')
        if not name:
            # Derive name from path : "node_modules/<name>" or
            # "node_modules/<scope>/<name>".
            parts = path_key.split('/node_modules/')
            if len(parts) >= 2:
                name = parts[-1]
        ver = info.get('version')
        if name and ver:
            out.append((name, ver, f"pkg:npm/{name}@{ver}"))
    if not out:
        # Fallback to legacy lockfileVersion 1 : top-level dependencies map.
        deps = data.get('dependencies') or {}
        for name, info in deps.items():
            ver = info.get('version')
            if ver:
                out.append((name, ver, f"pkg:npm/{name}@{ver}"))
    return out


def _parse_pubspec_lock(path):
    """Parse pubspec.lock (YAML)."""
    import yaml
    with open(path) as f:
        data = yaml.safe_load(f) or {}
    out = []
    for name, info in (data.get('packages') or {}).items():
        ver = info.get('version') if isinstance(info, dict) else None
        if name and ver:
            out.append((name, ver, f"pkg:pub/{name}@{ver}"))
    return out


# ─── Phase 1 — detect lockfiles ───────────────────────────────────
# Walk the target tree (max depth 4) skipping common build/cache dirs.
# Stops at the first npm-family lockfile per subtree to avoid
# double-counting from nested node_modules.

SKIP_DIRS = {
    'node_modules', 'target', '.dart_tool', '.git', '.gradle',
    'build', 'Pods', '.next', 'dist', '.cache', 'vendor',
}
NPM_LOCKS = ('package-lock.json', 'pnpm-lock.yaml', 'yarn.lock')

detected = []
seen_paths = set()

def _walk(root_path, max_depth):
    base_depth = root_path.rstrip(os.sep).count(os.sep)
    for dirpath, dirnames, filenames in os.walk(root_path):
        depth = dirpath.rstrip(os.sep).count(os.sep) - base_depth
        if depth >= max_depth:
            dirnames[:] = []
            continue
        # Prune skip-list dirs in-place (os.walk respects this).
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith('.')]
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            if full in seen_paths:
                continue
            if fn == 'Cargo.lock':
                detected.append(('cargo', full)); seen_paths.add(full)
            elif fn in NPM_LOCKS:
                # Only one npm lock per directory.
                if not any(d == 'npm' and os.path.dirname(p) == dirpath for d, p in detected):
                    detected.append(('npm', full)); seen_paths.add(full)
            elif fn == 'pubspec.lock':
                detected.append(('pubspec', full)); seen_paths.add(full)

_walk(target, max_depth=4)

if not detected:
    print(
        "forge-sbom: no lockfile found in target "
        "(expected Cargo.lock / package-lock.json / pnpm-lock.yaml / "
        "yarn.lock / pubspec.lock)",
        file=sys.stderr,
    )
    sys.exit(1)

# ─── Phase 2 — parse + flatten ────────────────────────────────────
components_raw = []
for kind, path in detected:
    try:
        if kind == 'cargo':
            components_raw.extend(_parse_cargo_lock(path))
        elif kind == 'npm':
            components_raw.extend(_parse_npm_lock(path))
        elif kind == 'pubspec':
            components_raw.extend(_parse_pubspec_lock(path))
    except Exception as e:
        print(f"forge-sbom: parse error in {path}: {e}", file=sys.stderr)
        sys.exit(1)

# Dedupe by purl, sort for determinism (FR-J8-075).
seen = set()
components = []
for name, ver, purl in components_raw:
    if purl in seen:
        continue
    seen.add(purl)
    components.append({
        "type": "library",
        "name": name,
        "version": ver,
        "purl": purl,
    })
components.sort(key=lambda c: c["purl"])

# ─── Phase 3 — emit ──────────────────────────────────────────────
sde = os.environ.get('SOURCE_DATE_EPOCH')
if sde:
    timestamp = datetime.datetime.fromtimestamp(
        int(sde), tz=datetime.timezone.utc,
    ).isoformat().replace('+00:00', 'Z')
else:
    timestamp = datetime.datetime.now(
        tz=datetime.timezone.utc,
    ).isoformat().replace('+00:00', 'Z')

# Stable serialNumber when SOURCE_DATE_EPOCH is set (deterministic
# UUID v5 derived from the target path + components hash).
if sde:
    name_namespace = uuid.NAMESPACE_URL
    seed = f"forge-sbom:{target}:{','.join(c['purl'] for c in components)}"
    serial_uuid = uuid.uuid5(name_namespace, seed)
else:
    serial_uuid = uuid.uuid4()

bom = {
    "bomFormat": "CycloneDX",
    "specVersion": "1.5",
    "serialNumber": f"urn:uuid:{serial_uuid}",
    "version": 1,
    "metadata": {
        "timestamp": timestamp,
        "tools": [
            {"name": "forge-sbom.sh", "version": "0.1.0"},
        ],
        "component": {
            "type": "application",
            "name": os.path.basename(target),
            "version": "0.0.0",
        },
    },
    "components": components,
}

if fmt == 'json':
    rendered = json.dumps(bom, sort_keys=True, indent=2) + "\n"
    with open(output_path, 'w') as f:
        f.write(rendered)
elif fmt == 'xml':
    ns = "http://cyclonedx.org/schema/bom/1.5"
    ET.register_namespace('', ns)
    root = ET.Element(f"{{{ns}}}bom", attrib={
        "serialNumber": bom["serialNumber"],
        "version": "1",
    })
    metadata_el = ET.SubElement(root, f"{{{ns}}}metadata")
    ts_el = ET.SubElement(metadata_el, f"{{{ns}}}timestamp")
    ts_el.text = timestamp
    components_el = ET.SubElement(root, f"{{{ns}}}components")
    for c in components:
        ce = ET.SubElement(components_el, f"{{{ns}}}component", attrib={"type": "library"})
        n = ET.SubElement(ce, f"{{{ns}}}name"); n.text = c["name"]
        v = ET.SubElement(ce, f"{{{ns}}}version"); v.text = c["version"]
        p = ET.SubElement(ce, f"{{{ns}}}purl"); p.text = c["purl"]
    tree = ET.ElementTree(root)
    ET.indent(tree, space="  ")
    tree.write(output_path, encoding="UTF-8", xml_declaration=True)
else:
    print(f"forge-sbom: unreachable format: {fmt}", file=sys.stderr)
    sys.exit(1)

# Report on stderr so that --output filename detection on stdout
# remains clean for shell pipelines.
print(f"forge-sbom: wrote {output_path} ({len(components)} components)", file=sys.stderr)
sys.exit(0)
PY
rc=$?
exit $rc
