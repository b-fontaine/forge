#!/usr/bin/env bash
# Forge — Archetype Overlay Renderer (b1-scaffolder)
# <!-- Audit: B.1.2 (part of b1-scaffolder, overlay renderer) -->
#
# Consumes the scaffold-plan.yaml for an archetype, iterates its
# templates[] list, and renders each into a target directory. For
# entries with `substitute: true`, the placeholders <project-name>,
# <reverse-domain>, <root-module> are replaced. For `substitute: false`
# (or missing), files are copied byte-identical.
#
# After rendering, writes <target>/.forge/scaffold-manifest.yaml with
# the archetype version, a SHA of the plan, a SHA of the template set,
# and the scaffold date (controllable via SOURCE_DATE_EPOCH for
# reproducible-build testing — NFR-005 idempotence).
#
# Usage:
#   overlay.sh --target <dir> --project-name <name> --reverse-domain <fqdn> \
#              [--root-module <mod>] [--force] [--dry-run] \
#              [--phase pre_cargo_new|post_cargo_new] [--plan <file>]
#
# `--plan` (default `scaffold-plan.yaml`) selects which scaffold plan inside the
# archetype directory drives the render. A bare filename is resolved against the
# archetype dir; an absolute path is used as-is. Introduced by b8-14-promotion-flip
# (C2) so a Kong-less 2.0.0 plan (scaffold-plan-2.0.0.yaml) can be rendered without
# editing the byte-frozen 1.0.0 base. Omitting it preserves the legacy 1.0.0 path.
#
# `--phase` (default `pre_cargo_new`) filters the templates[] list :
#    - pre_cargo_new  : runs ONLY entries with no `phase` field or
#                       `phase: pre_cargo_new` (legacy behaviour).
#    - post_cargo_new : runs ONLY entries with `phase: post_cargo_new`,
#                       implicit force=true (cargo new has just written
#                       a stub Cargo.toml / lib.rs that we now overwrite).
#                       The scaffold-manifest.yaml is NOT rewritten in
#                       this phase (it was finalised by the pre pass).
#
# Introduced by t5-connect-codegen (ADR-T5-006) so the flagship template
# can ship Rust crate code that overlays cargo new output.
#
# Exit codes:
#   0 — success
#   1 — unexpected error
#   2 — missing or malformed argument
#   3 — regex validation failure (project-name or reverse-domain)
#   4 — target file exists and --force not provided

set -euo pipefail

# ─── Argument parsing ──────────────────────────────────────────

TARGET=""
PROJECT_NAME=""
REVERSE_DOMAIN=""
ROOT_MODULE=""
FORCE="false"
DRY_RUN="false"
PHASE="pre_cargo_new"
PLAN=""

while [ $# -gt 0 ]; do
  case "$1" in
    --target)         TARGET="${2:-}"; shift 2 ;;
    --target=*)       TARGET="${1#*=}"; shift ;;
    --project-name)   PROJECT_NAME="${2:-}"; shift 2 ;;
    --project-name=*) PROJECT_NAME="${1#*=}"; shift ;;
    --reverse-domain)   REVERSE_DOMAIN="${2:-}"; shift 2 ;;
    --reverse-domain=*) REVERSE_DOMAIN="${1#*=}"; shift ;;
    --root-module)     ROOT_MODULE="${2:-}"; shift 2 ;;
    --root-module=*)   ROOT_MODULE="${1#*=}"; shift ;;
    --force)          FORCE="true"; shift ;;
    --dry-run)        DRY_RUN="true"; shift ;;
    --phase)          PHASE="${2:-}"; shift 2 ;;
    --phase=*)        PHASE="${1#*=}"; shift ;;
    --plan)           PLAN="${2:-}"; shift 2 ;;
    --plan=*)         PLAN="${1#*=}"; shift ;;
    --help|-h)
      sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "overlay.sh: unknown flag '$1'" >&2
      exit 2
      ;;
  esac
done

case "$PHASE" in
  pre_cargo_new|post_cargo_new) ;;
  *)
    echo "overlay.sh: --phase must be 'pre_cargo_new' or 'post_cargo_new', got '$PHASE'" >&2
    exit 2
    ;;
esac

# In post_cargo_new phase, force is implicit (cargo just wrote stubs).
if [ "$PHASE" = "post_cargo_new" ]; then
  FORCE="true"
fi

# ─── Required args ──────────────────────────────────────────────

[ -n "$TARGET" ]         || { echo "overlay.sh: --target is required" >&2; exit 2; }
[ -n "$PROJECT_NAME" ]   || { echo "overlay.sh: --project-name is required" >&2; exit 2; }
[ -n "$REVERSE_DOMAIN" ] || { echo "overlay.sh: --reverse-domain is required" >&2; exit 2; }

# Derive root-module from project-name if not provided (kebab → snake).
if [ -z "$ROOT_MODULE" ]; then
  ROOT_MODULE="${PROJECT_NAME//-/_}"
fi

# ─── Regex validation (Aegis — must run BEFORE any interpolation) ───

PROJECT_NAME_RE='^[a-z][a-z0-9_-]{0,39}$'
REVERSE_DOMAIN_RE='^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)+$'

if ! [[ "$PROJECT_NAME" =~ $PROJECT_NAME_RE ]]; then
  echo "overlay.sh: --project-name '$PROJECT_NAME' does not match $PROJECT_NAME_RE" >&2
  exit 3
fi
if ! [[ "$REVERSE_DOMAIN" =~ $REVERSE_DOMAIN_RE ]]; then
  echo "overlay.sh: --reverse-domain '$REVERSE_DOMAIN' does not match reverse-DNS pattern" >&2
  exit 3
fi

# ─── Locate the archetype ──────────────────────────────────────

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_ROOT_SRC="$(cd "$HERE/../../.." && pwd)"
ARCHETYPE_DIR="$FORGE_ROOT_SRC/.forge/templates/archetypes/full-stack-monorepo"

# Plan selection (b8-14-promotion-flip C2). Default = the frozen 1.0.0 plan, so
# omitting --plan is byte-identical to the legacy behaviour. A bare filename is
# resolved against the archetype dir; an absolute path is honoured as-is.
if [ -n "$PLAN" ]; then
  case "$PLAN" in
    /*) SCAFFOLD_PLAN="$PLAN" ;;
    *)  SCAFFOLD_PLAN="$ARCHETYPE_DIR/$PLAN" ;;
  esac
else
  SCAFFOLD_PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"
fi

[ -f "$SCAFFOLD_PLAN" ] || { echo "overlay.sh: scaffold plan not found at $SCAFFOLD_PLAN" >&2; exit 1; }

# Pin manifest timestamp for reproducible-build testing if caller sets
# SOURCE_DATE_EPOCH (POSIX-compliant reproducible-builds convention).
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-}"

# ─── Main render + manifest (python3 + PyYAML) ─────────────────

# Tool versions are optional — populated by init.sh in the L3 path,
# empty in direct (L2) overlay invocations.
export OVERLAY_FLUTTER_VERSION="${OVERLAY_FLUTTER_VERSION:-}"
export OVERLAY_CARGO_VERSION="${OVERLAY_CARGO_VERSION:-}"
export OVERLAY_BUF_VERSION="${OVERLAY_BUF_VERSION:-}"

export ARCHETYPE_DIR SCAFFOLD_PLAN TARGET PROJECT_NAME REVERSE_DOMAIN ROOT_MODULE FORCE DRY_RUN SOURCE_DATE_EPOCH PHASE

python3 - <<'PY'
import os, sys, yaml, shutil, hashlib, datetime

archetype_dir   = os.environ['ARCHETYPE_DIR']
plan_path       = os.environ['SCAFFOLD_PLAN']
target          = os.environ['TARGET']
project_name    = os.environ['PROJECT_NAME']
reverse_domain  = os.environ['REVERSE_DOMAIN']
root_module     = os.environ['ROOT_MODULE']
force           = os.environ['FORCE'] == 'true'
dry_run         = os.environ['DRY_RUN'] == 'true'
sde             = os.environ.get('SOURCE_DATE_EPOCH', '')
phase           = os.environ.get('PHASE', 'pre_cargo_new')

with open(plan_path, 'r', encoding='utf-8') as f:
    plan = yaml.safe_load(f)

# Filter templates by phase. Default phase for entries without an
# explicit `phase` field is `pre_cargo_new` (legacy / b1-scaffolder
# entries). Entries with `phase: post_cargo_new` are introduced by
# t5-connect-codegen ADR-T5-006.
all_templates = plan.get('templates', [])
templates = [
    e for e in all_templates
    if e.get('phase', 'pre_cargo_new') == phase
]

def substitute(content: str) -> str:
    return (content
            .replace('<project-name>', project_name)
            .replace('<reverse-domain>', reverse_domain)
            .replace('<root-module>', root_module))

# Render each template.
for entry in templates:
    src_rel = entry['source']
    tgt_rel = entry['target']
    subst = entry.get('substitute', False)
    src = os.path.join(archetype_dir, src_rel)
    tgt = os.path.join(target, tgt_rel)

    if dry_run:
        sys.stderr.write(f"DRY: {src_rel} -> {tgt_rel} (substitute={subst})\n")
        continue

    if os.path.exists(tgt) and not force:
        sys.stderr.write(f"overlay.sh: target exists and --force not set: {tgt_rel}\n")
        sys.exit(4)

    os.makedirs(os.path.dirname(tgt) or '.', exist_ok=True)

    if subst:
        with open(src, 'r', encoding='utf-8') as f:
            content = f.read()
        with open(tgt, 'w', encoding='utf-8') as f:
            f.write(substitute(content))
    else:
        shutil.copy2(src, tgt)

if dry_run:
    sys.exit(0)

# Compute SHAs for audit manifest.
def sha256_path(path: str) -> str:
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()

# In post_cargo_new phase, the scaffold-manifest.yaml has already
# been written by the pre_cargo_new pass — do not rewrite it here.
if phase == 'post_cargo_new':
    sys.stderr.write(
        f"overlay.sh: {len(templates)} post_cargo_new templates rendered into {target}\n"
    )
    sys.exit(0)

plan_sha = sha256_path(plan_path)

# Manifest must hash the FULL template set (not just the current
# phase), so adopters get a stable template_set_sha regardless of
# phase ordering.
tmpl_hash = hashlib.sha256()
for entry in sorted(all_templates, key=lambda e: e['source']):
    src = os.path.join(archetype_dir, entry['source'])
    tmpl_hash.update(entry['source'].encode('utf-8'))
    tmpl_hash.update(b'\0')
    with open(src, 'rb') as f:
        tmpl_hash.update(f.read())
    tmpl_hash.update(b'\0')
template_set_sha = tmpl_hash.hexdigest()

# Scaffold date — SOURCE_DATE_EPOCH overrides real time for idempotence.
if sde:
    try:
        ts = int(sde)
        scaffold_date = datetime.datetime.fromtimestamp(ts, datetime.timezone.utc).isoformat()
    except ValueError:
        sys.stderr.write(f"overlay.sh: SOURCE_DATE_EPOCH='{sde}' is not an integer\n")
        sys.exit(2)
else:
    scaffold_date = datetime.datetime.now(datetime.timezone.utc).isoformat()

tools = {}
for name, env_key in (('flutter', 'OVERLAY_FLUTTER_VERSION'),
                       ('cargo',   'OVERLAY_CARGO_VERSION'),
                       ('buf',     'OVERLAY_BUF_VERSION')):
    val = os.environ.get(env_key, '')
    if val:
        tools[name] = val

manifest = {
    'archetype': plan.get('archetype'),
    'archetype_version': plan.get('version'),
    'scaffold_plan_sha': plan_sha,
    'template_set_sha': template_set_sha,
    # Populated by init.sh via OVERLAY_*_VERSION env vars.
    # Empty dict when overlay.sh is invoked directly (L2 harness).
    'tools': tools,
    'scaffold_date': scaffold_date,
    'project_name': project_name,
    'reverse_domain': reverse_domain,
    'root_module': root_module,
}

manifest_path = os.path.join(target, '.forge', 'scaffold-manifest.yaml')
os.makedirs(os.path.dirname(manifest_path), exist_ok=True)
with open(manifest_path, 'w', encoding='utf-8') as f:
    yaml.safe_dump(manifest, f, default_flow_style=False, sort_keys=True)

sys.stderr.write(
    f"overlay.sh: {len(templates)} templates rendered into {target}\n"
    f"overlay.sh: scaffold-manifest.yaml written\n"
)
PY
