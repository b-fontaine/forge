#!/usr/bin/env bash
# Forge — `bundle.sh` deterministic compliance artefacts bundle generator
# <!-- Audit: I.6 (i6-compliance-artefacts) FR-I6-CA-001..020 / ADR-I6-CA-001..003 -->
#
# Produces a deterministic `.tgz` (gzip POSIX tar) bundling the
# four canonical Forge compliance artefacts :
#
#   - tier-matrix/compliance-tiers.md          (I.2 standard, copied verbatim)
#   - templates/forge-dpa-declared.template    (I.6 DPA template, copied verbatim)
#   - audit/audit-ledger.json                  (script-generated snapshot)
#   - audit/audit-ledger.md                    (script-generated snapshot)
#   - sbom/sbom.cdx.json                       (output of bin/forge-sbom.sh)
#   - MANIFEST                                 (script-generated index)
#
# Usage :
#   bash .forge/scripts/compliance/bundle.sh \
#     [--output <path>] [--target <dir>]
#
# Defaults : --output forge-compliance-artefacts.tgz, --target $(pwd).
#
# Exit codes :
#   0 — bundle written successfully
#   1 — missing source artefact (one of the 4 canonical surfaces absent)
#   2 — usage error (bad args, target not a directory)
#
# Determinism : when `SOURCE_DATE_EPOCH` is set (POSIX env var, integer
# Unix timestamp), per-member tar mtimes + the gzip header mtime are
# pinned ; two consecutive runs produce byte-identical .tgz outputs
# (NFR-I6-CA-005, asserted by .forge/scripts/tests/i6.test.sh L2).
#
# Pattern : bash thin + Python 3 inline (mirrors `bin/forge-sbom.sh`
# per NFR-I6-CA-004 — F.2 / J.7 / J.8.d reuse).

set -uo pipefail

OUTPUT="forge-compliance-artefacts.tgz"
TARGET="$(pwd)"

err() { echo "forge-compliance-bundle: $*" >&2; }

usage() {
  cat <<EOF
Usage: bundle.sh [--output <path>] [--target <dir>]

Produces a deterministic .tgz bundling the Forge compliance artefacts
(tier matrix + DPA template + audit ledger snapshot + SBOM + MANIFEST).

Defaults : --output forge-compliance-artefacts.tgz, --target \$(pwd).
Exit codes : 0 success / 1 missing source artefact / 2 usage error.
Determinism : set SOURCE_DATE_EPOCH for byte-identical output across runs.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --output) OUTPUT="${2:-}"; shift 2 ;;
    --output=*) OUTPUT="${1#*=}"; shift ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --target=*) TARGET="${1#*=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) err "unknown argument: $1"; usage >&2; exit 2 ;;
  esac
done

if [ ! -d "$TARGET" ]; then
  err "target directory not found: $TARGET"; exit 2
fi

# Resolve to absolute path so member sources are stable inside Python.
TARGET="$(cd "$TARGET" && pwd)"

# ─── Source-artefact validation (FR-I6-CA-007) ────────────────────
TIER_MATRIX="$TARGET/.forge/standards/global/compliance-tiers.md"
DPA_TEMPLATE="$TARGET/.forge/templates/compliance/forge-dpa-declared.template"
CHANGES_DIR="$TARGET/.forge/changes"
REVIEW_MD="$TARGET/.forge/standards/REVIEW.md"
SBOM_SCRIPT="$TARGET/bin/forge-sbom.sh"

for required in "$TIER_MATRIX" "$DPA_TEMPLATE" "$REVIEW_MD"; do
  if [ ! -f "$required" ]; then
    err "missing source artefact: $required"; exit 1
  fi
done
if [ ! -d "$CHANGES_DIR" ]; then
  err "missing source artefact: $CHANGES_DIR"; exit 1
fi

# Resolve OUTPUT to absolute path so the bundle lands where the caller
# expects regardless of subsequent cwd changes inside Python.
case "$OUTPUT" in
  /*) ;;
  *) OUTPUT="$(pwd)/$OUTPUT" ;;
esac

python3 - "$TARGET" "$OUTPUT" "$SBOM_SCRIPT" <<'PY'
import datetime
import gzip
import hashlib
import io
import json
import os
import re
import subprocess
import sys
import tarfile
import tempfile

target = sys.argv[1]
output_path = sys.argv[2]
sbom_script = sys.argv[3]


def _read_bytes(path):
    with open(path, "rb") as f:
        return f.read()


def _utc_iso(epoch=None):
    if epoch is None:
        dt = datetime.datetime.now(tz=datetime.timezone.utc)
    else:
        dt = datetime.datetime.fromtimestamp(int(epoch), tz=datetime.timezone.utc)
    return dt.isoformat().replace("+00:00", "Z")


sde_env = os.environ.get("SOURCE_DATE_EPOCH")
sde = int(sde_env) if sde_env is not None else None
generated_at = _utc_iso(sde)


# ─── Phase 1 — collect static-source members ─────────────────────
tier_matrix = _read_bytes(
    os.path.join(target, ".forge/standards/global/compliance-tiers.md")
)
dpa_template = _read_bytes(
    os.path.join(target, ".forge/templates/compliance/forge-dpa-declared.template")
)


# ─── Phase 2 — build audit ledger snapshot ───────────────────────
# Sources :
#   .forge/changes/*/.forge.yaml with `status: archived`
#   .forge/standards/REVIEW.md H2 dated lines
#   Hard-coded active rule catalogues (K3-RULE-001..006 ; J8-RULE-001..003)

def _parse_change_yaml(path):
    """Minimal-dependency YAML reader for the small .forge.yaml shape.

    We avoid importing yaml here to keep the bundle path zero-dep
    (PyYAML is an upstream Forge requirement but we don't need it for
    the bundle's own ledger parsing). The yaml shape used by Forge
    change files is mechanically simple : top-level scalars and one
    list (`parent_audit_items`) plus a `timeline:` block of scalars.
    """
    name = None
    status = None
    archived = None
    parent_items = []
    in_parent_items = False
    in_timeline = False
    try:
        with open(path) as f:
            for raw in f:
                line = raw.rstrip("\n")
                if not line.strip() or line.lstrip().startswith("#"):
                    continue
                # Detect top-level keys at column 0.
                if not line.startswith(" "):
                    in_parent_items = False
                    in_timeline = False
                    if line.startswith("name:"):
                        name = line.split(":", 1)[1].strip().strip('"').strip("'")
                    elif line.startswith("status:"):
                        status = line.split(":", 1)[1].strip().strip('"').strip("'")
                    elif line.startswith("parent_audit_items:"):
                        in_parent_items = True
                    elif line.startswith("timeline:"):
                        in_timeline = True
                    continue
                # Indented contexts.
                stripped = line.strip()
                if in_parent_items and stripped.startswith("- "):
                    val = stripped[2:].split("#", 1)[0].strip()
                    val = val.strip('"').strip("'")
                    if val:
                        parent_items.append(val)
                elif in_timeline and ":" in stripped:
                    k, _, v = stripped.partition(":")
                    v = v.split("#", 1)[0].strip().strip('"').strip("'")
                    if k.strip() == "archived" and v:
                        archived = v
    except OSError:
        return None
    if name is None or status != "archived":
        return None
    return {
        "name": name,
        "archived": archived or "",
        "parent_audit_items": parent_items,
    }


archived_changes = []
changes_dir = os.path.join(target, ".forge/changes")
if os.path.isdir(changes_dir):
    for entry in sorted(os.listdir(changes_dir)):
        cfg = os.path.join(changes_dir, entry, ".forge.yaml")
        if os.path.isfile(cfg):
            parsed = _parse_change_yaml(cfg)
            if parsed is not None:
                archived_changes.append(parsed)

# Deterministic order : by archived ascending then name ascending.
archived_changes.sort(key=lambda c: (c["archived"], c["name"]))


# REVIEW.md H2 dated headers — regex `^## (\d{4}-\d{2}-\d{2}) — (.+)$`.
review_path = os.path.join(target, ".forge/standards/REVIEW.md")
standards_reviews = []
H2_RE = re.compile(r"^## (\d{4}-\d{2}-\d{2}) — (.+)$")
if os.path.isfile(review_path):
    with open(review_path) as f:
        for line in f:
            m = H2_RE.match(line.rstrip("\n"))
            if m:
                standards_reviews.append({"date": m.group(1), "title": m.group(2).strip()})

standards_reviews.sort(key=lambda r: (r["date"], r["title"]))


# Framework version from VERSION file.
fw_version_path = os.path.join(target, "VERSION")
framework_version = "unknown"
if os.path.isfile(fw_version_path):
    framework_version = open(fw_version_path).read().strip() or "unknown"


audit_ledger = {
    "schema_version": "1.0.0",
    "generated_at": generated_at,
    "framework_version": framework_version,
    "archived_changes": archived_changes,
    "standards_reviews": standards_reviews,
    "active_rule_catalogues": ["K3-RULE-001..006", "J8-RULE-001..003"],
}

audit_ledger_json = (
    json.dumps(audit_ledger, sort_keys=True, indent=2) + "\n"
).encode("utf-8")


# Audit ledger Markdown.
md_lines = []
md_lines.append("# Forge Compliance — Audit Ledger Snapshot")
md_lines.append("")
md_lines.append(f"> Generated at {generated_at}")
md_lines.append(f"> Framework version: {framework_version}")
md_lines.append("")
md_lines.append("## Archived changes")
md_lines.append("")
if archived_changes:
    md_lines.append("| Change | Archived | Parent audit items |")
    md_lines.append("|--------|----------|--------------------|")
    for c in archived_changes:
        items = ", ".join(c["parent_audit_items"]) if c["parent_audit_items"] else "—"
        md_lines.append(f"| `{c['name']}` | {c['archived'] or '—'} | {items} |")
else:
    md_lines.append("_None on record._")
md_lines.append("")
md_lines.append("## Standards reviews")
md_lines.append("")
if standards_reviews:
    md_lines.append("| Date | Title |")
    md_lines.append("|------|-------|")
    for r in standards_reviews:
        md_lines.append(f"| {r['date']} | {r['title']} |")
else:
    md_lines.append("_None on record._")
md_lines.append("")
md_lines.append("## Active rule catalogues")
md_lines.append("")
for cat in audit_ledger["active_rule_catalogues"]:
    md_lines.append(f"- `{cat}`")
md_lines.append("")

audit_ledger_md = ("\n".join(md_lines)).encode("utf-8")


# ─── Phase 3 — SBOM via bin/forge-sbom.sh ────────────────────────
def _empty_sbom():
    """Minimal CycloneDX 1.5 envelope used when no lockfile is found
    in the target tree (FR-I6-CA-019 — non-fatal SBOM)."""
    import uuid as _uuid
    seed = f"forge-bundle-empty:{target}"
    serial = _uuid.uuid5(_uuid.NAMESPACE_URL, seed)
    bom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "serialNumber": f"urn:uuid:{serial}",
        "version": 1,
        "metadata": {
            "timestamp": generated_at,
            "tools": [{"name": "forge-compliance-bundle.sh", "version": "1.0.0"}],
            "component": {
                "type": "application",
                "name": os.path.basename(target.rstrip("/")) or "forge-project",
                "version": "0.0.0",
            },
        },
        "components": [],
    }
    return (json.dumps(bom, sort_keys=True, indent=2) + "\n").encode("utf-8")


sbom_bytes = None
if os.path.isfile(sbom_script):
    with tempfile.NamedTemporaryFile(
        prefix="forge-bundle-sbom-", suffix=".cdx.json", delete=False
    ) as tmp:
        sbom_tmp = tmp.name
    try:
        env = os.environ.copy()
        # SOURCE_DATE_EPOCH propagates naturally via os.environ.
        rc = subprocess.call(
            ["bash", sbom_script, "--target", target, "--output", sbom_tmp],
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if rc == 0 and os.path.isfile(sbom_tmp) and os.path.getsize(sbom_tmp) > 0:
            sbom_bytes = _read_bytes(sbom_tmp)
        elif rc == 1:
            print(
                "forge-compliance-bundle: no lockfiles in target — SBOM empty",
                file=sys.stderr,
            )
            sbom_bytes = _empty_sbom()
        else:
            print(
                f"forge-compliance-bundle: forge-sbom.sh failed (rc={rc})",
                file=sys.stderr,
            )
            sys.exit(1)
    finally:
        try:
            os.unlink(sbom_tmp)
        except OSError:
            pass
else:
    # No SBOM script present at the target — emit the minimal envelope
    # so the bundle remains schema-stable.
    sbom_bytes = _empty_sbom()


# ─── Phase 4 — assemble bundle members ───────────────────────────
# Member order is alphabetical by path. MANIFEST is computed last so
# it captures every other member.
members = {
    "audit/audit-ledger.json": audit_ledger_json,
    "audit/audit-ledger.md": audit_ledger_md,
    "sbom/sbom.cdx.json": sbom_bytes,
    "templates/forge-dpa-declared.template": dpa_template,
    "tier-matrix/compliance-tiers.md": tier_matrix,
}

# MANIFEST format : "<sha256-hex>  <size-bytes>  <member-path>\n" sorted.
manifest_lines = []
for path in sorted(members.keys()):
    blob = members[path]
    sha = hashlib.sha256(blob).hexdigest()
    manifest_lines.append(f"{sha}  {len(blob)}  {path}\n")
manifest_bytes = "".join(manifest_lines).encode("utf-8")
members["MANIFEST"] = manifest_bytes


# ─── Phase 5 — emit .tgz deterministically ───────────────────────
tar_buf = io.BytesIO()
member_mtime = sde if sde is not None else int(
    datetime.datetime.now(tz=datetime.timezone.utc).timestamp()
)
with tarfile.open(fileobj=tar_buf, mode="w", format=tarfile.USTAR_FORMAT) as tar:
    for path in sorted(members.keys()):
        blob = members[path]
        ti = tarfile.TarInfo(name=path)
        ti.size = len(blob)
        ti.mtime = member_mtime
        ti.mode = 0o644
        ti.uid = 0
        ti.gid = 0
        ti.uname = ""
        ti.gname = ""
        ti.type = tarfile.REGTYPE
        tar.addfile(ti, io.BytesIO(blob))

# Wrap into a gzip stream with mtime pinned for byte-stability.
gz_mtime = sde if sde is not None else None
with open(output_path, "wb") as out:
    with gzip.GzipFile(
        filename="",
        mode="wb",
        fileobj=out,
        mtime=gz_mtime,
    ) as gz:
        gz.write(tar_buf.getvalue())

size = os.path.getsize(output_path)
print(
    f"forge-compliance-bundle: wrote {output_path} "
    f"({len(members)} members, {size} bytes)",
    file=sys.stderr,
)
sys.exit(0)
PY
rc=$?
exit $rc
