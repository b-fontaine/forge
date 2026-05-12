#!/usr/bin/env bash
# Forge — `forge-demeter-scan.sh` — K.3 Data-stewardship scanner
# <!-- Audit: K.3 (k3-demeter, FR-K3-DEM-060..074 / ADR-K3-004) -->
#
# Walks Cargo.lock / package-lock.json / pnpm-lock.yaml /
# yarn.lock / pubspec.lock under --target and matches dependencies
# against `.forge/data/cloud-act-publishers.yml` deny-list. Emits a
# JSON or Markdown report ; exit code maps severity envelope.
#
# Usage :
#   bin/forge-demeter-scan.sh [--target <dir>] [--tier T1|T2|T3]
#                             [--output <path>] [--format json|md]
#
# Defaults : --target $(pwd), --tier from .forge/.forge-tier,
#            --output demeter-report.json, --format json.
#
# Exit codes :
#   0 — CLEARED (no findings, no Critical / High in report).
#   1 — CONCERNS (Medium findings present, no Critical / High).
#   2 — usage error (bad args, missing lockfile, missing target).
#   3 — BLOCKED (Critical or High findings present).
#
# Determinism : SOURCE_DATE_EPOCH (POSIX env var) controls
# `metadata.generated_at` for reproducible builds (NFR-K3-DEM-005).
# Findings sorted by (severity_rank, rule_id, evidence) for byte
# stability ; JSON uses sort_keys.
#
# Pattern : bash thin + Python 3 inline (F.2 / J.7 / J.8.d).
# Stdlib only : tomllib (≥ 3.11), json, yaml (PyYAML, already
# required by Forge), os, sys, datetime, re. No paid scanning
# service per NFR-K3-DEM-006.

set -uo pipefail

OUTPUT="demeter-report.json"
FORMAT="json"
TARGET="$(pwd)"
TIER=""

err() { echo "forge-demeter-scan: $*" >&2; }

usage() {
  cat <<EOF
Usage: forge-demeter-scan.sh [--target <dir>] [--tier T1|T2|T3]
                              [--output <path>] [--format json|md]

Walks Cargo.lock / package-lock.json / pnpm-lock.yaml /
yarn.lock / pubspec.lock under <target> and emits a CycloneDX-
sibling data-stewardship report.

Defaults : --target \$(pwd), --tier from .forge/.forge-tier,
           --output demeter-report.json, --format json.

Exit codes :
  0 CLEARED   no findings or only Low / Informational
  1 CONCERNS  Medium findings present
  2 usage error / missing lockfile
  3 BLOCKED   Critical or High findings present

Per FR-K3-DEM-060..074 + ADR-K3-004.
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
    --tier) TIER="${2:-}"; shift 2 ;;
    --tier=*) TIER="${1#*=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) err "unknown argument: $1"; usage >&2; exit 2 ;;
  esac
done

if [ "$FORMAT" != "json" ] && [ "$FORMAT" != "md" ]; then
  err "invalid --format '$FORMAT' (expected json|md)"; exit 2
fi

if [ ! -d "$TARGET" ]; then
  err "target directory not found: $TARGET"; exit 2
fi

TARGET="$(cd "$TARGET" && pwd)"

# Tier resolution : --tier flag wins ; else read .forge/.forge-tier ;
# else emit [NEEDS CLARIFICATION:] and exit 1.
if [ -z "$TIER" ]; then
  if [ -f "$TARGET/.forge/.forge-tier" ]; then
    TIER="$(head -1 "$TARGET/.forge/.forge-tier" | tr -d '[:space:]')"
  fi
fi
if [ -z "$TIER" ]; then
  err "[NEEDS CLARIFICATION: compliance tier undeclared — pass --tier T1|T2|T3 or write .forge/.forge-tier]"
  exit 1
fi
case "$TIER" in
  T1|T2|T3) ;;
  *) err "invalid --tier '$TIER' (expected T1|T2|T3)"; exit 2 ;;
esac

# Resolve repository-rooted publisher list : the scanner script
# lives at <repo>/bin/forge-demeter-scan.sh and the data file at
# <repo>/.forge/data/cloud-act-publishers.yml.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLISHERS_YML="$REPO_ROOT/.forge/data/cloud-act-publishers.yml"

if [ ! -f "$PUBLISHERS_YML" ]; then
  err "publisher list not found at $PUBLISHERS_YML"; exit 2
fi

python3 - "$TARGET" "$OUTPUT" "$FORMAT" "$TIER" "$PUBLISHERS_YML" <<'PY'
import datetime
import json
import os
import re
import sys

target = sys.argv[1]
output_path = sys.argv[2]
fmt = sys.argv[3]
tier = sys.argv[4]
publishers_yml = sys.argv[5]


# ─── Severity envelope ────────────────────────────────────────────
SEV_RANK = {
    'Critical': 0,
    'High': 1,
    'Medium': 2,
    'Low': 3,
    'Informational': 4,
}


def _scale_severity_for_rule_001(declared_tier):
    """K3-RULE-001 severity scales per FR-K3-DEM-068."""
    return {'T1': 'Informational', 'T2': 'High', 'T3': 'Critical'}[declared_tier]


# ─── Parsers ───────────────────────────────────────────────────────


def _parse_cargo_lock(path):
    """Parse Cargo.lock (TOML stdlib, Python ≥ 3.11)."""
    try:
        import tomllib
    except ImportError:  # Python < 3.11 fallback
        import tomli as tomllib  # type: ignore[import-not-found]
    with open(path, 'rb') as f:
        data = tomllib.load(f)
    out = []
    for pkg in data.get('package', []):
        name = pkg.get('name')
        ver = pkg.get('version')
        source = pkg.get('source', '') or ''
        if name and ver:
            out.append(('cargo', name, ver, source))
    return out


def _parse_npm_lock(path):
    """Parse package-lock.json (npm v3+, lockfileVersion 2/3)."""
    with open(path) as f:
        data = json.load(f)
    out = []
    pkgs = data.get('packages') or {}
    for path_key, info in pkgs.items():
        if path_key == "":
            continue
        name = info.get('name')
        if not name:
            parts = path_key.split('/node_modules/')
            if len(parts) >= 2:
                name = parts[-1]
        ver = info.get('version')
        resolved = info.get('resolved', '') or ''
        if name and ver:
            out.append(('npm', name, ver, resolved))
    if not out:
        deps = data.get('dependencies') or {}
        for name, info in deps.items():
            ver = info.get('version')
            if ver:
                out.append(('npm', name, ver, ''))
    return out


def _parse_pnpm_lock(path):
    import yaml
    with open(path) as f:
        data = yaml.safe_load(f) or {}
    out = []
    pkgs = data.get('packages') or {}
    for key, info in pkgs.items():
        # Keys look like '/foo/1.2.3' or 'foo@1.2.3'.
        m = re.match(r'^/?(@?[^/]+(?:/[^/]+)?)/(.+?)(?:\(.*)?$', key)
        if m:
            name = m.group(1)
            ver = m.group(2)
            out.append(('npm', name, ver, ''))
    return out


def _parse_yarn_lock(path):
    out = []
    with open(path) as f:
        text = f.read()
    # yarn-classic blocks: `name@^range`, ..., :\n  version "X"
    # Use simple regex pass.
    blocks = re.split(r'\n(?=[^\s])', text)
    for blk in blocks:
        head = blk.splitlines()[0] if blk.strip() else ''
        m_name = re.match(r'^"?([^@\s]+(?:/[^@]+)?)@', head)
        m_ver = re.search(r'^\s+version\s+"([^"]+)"', blk, re.MULTILINE)
        if m_name and m_ver:
            out.append(('npm', m_name.group(1), m_ver.group(1), ''))
    return out


def _parse_pubspec_lock(path):
    import yaml
    with open(path) as f:
        data = yaml.safe_load(f) or {}
    out = []
    for name, info in (data.get('packages') or {}).items():
        if not isinstance(info, dict):
            continue
        ver = info.get('version')
        desc = info.get('description', {}) or {}
        if isinstance(desc, dict):
            publisher_hint = desc.get('name', '') or ''
        else:
            publisher_hint = ''
        if name and ver:
            out.append(('pub', name, ver, publisher_hint))
    return out


# ─── Detect lockfiles (depth ≤ 3, FR-K3-DEM-062) ───────────────────
SKIP_DIRS = {
    'node_modules', 'target', '.dart_tool', '.git', '.gradle',
    'build', 'Pods', '.next', 'dist', '.cache', 'vendor',
}


def _walk(root_path, max_depth=3):
    detected = []
    base_depth = root_path.rstrip(os.sep).count(os.sep)
    for dirpath, dirnames, filenames in os.walk(root_path):
        depth = dirpath.rstrip(os.sep).count(os.sep) - base_depth
        if depth > max_depth:
            dirnames[:] = []
            continue
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith('.')]
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            if fn == 'Cargo.lock':
                detected.append(('cargo-lock', full))
            elif fn == 'package-lock.json':
                detected.append(('npm-lock', full))
            elif fn == 'pnpm-lock.yaml':
                detected.append(('pnpm-lock', full))
            elif fn == 'yarn.lock':
                detected.append(('yarn-lock', full))
            elif fn == 'pubspec.lock':
                detected.append(('pubspec-lock', full))
            elif fn == 'Cargo.toml':
                detected.append(('cargo-toml', full))
    return detected


detected = _walk(target, max_depth=3)
lockfile_detected = [d for d in detected if d[0] != 'cargo-toml']

if not lockfile_detected:
    print(
        f"forge-demeter-scan: no lockfile found under {target} "
        f"(expected Cargo.lock / package-lock.json / pnpm-lock.yaml / "
        f"yarn.lock / pubspec.lock at depth ≤ 3)",
        file=sys.stderr,
    )
    sys.exit(2)

# ─── Parse + flatten ───────────────────────────────────────────────
deps = []
for kind, path in lockfile_detected:
    try:
        if kind == 'cargo-lock':
            deps.extend(_parse_cargo_lock(path))
        elif kind == 'npm-lock':
            deps.extend(_parse_npm_lock(path))
        elif kind == 'pnpm-lock':
            deps.extend(_parse_pnpm_lock(path))
        elif kind == 'yarn-lock':
            deps.extend(_parse_yarn_lock(path))
        elif kind == 'pubspec-lock':
            deps.extend(_parse_pubspec_lock(path))
    except Exception as e:
        print(f"forge-demeter-scan: parse error in {path}: {e}", file=sys.stderr)
        sys.exit(2)

# ─── Load deny-list ───────────────────────────────────────────────
import yaml

with open(publishers_yml) as f:
    pub_data = yaml.safe_load(f) or {}

publisher_list_version = pub_data.get('version', '0.0.0')
publisher_list_last_reviewed = pub_data.get('last_reviewed', '1970-01-01')
publisher_list_expires_at = pub_data.get('expires_at', '1970-01-01')

ecosystems = pub_data.get('ecosystems') or {}
deny_cargo = ecosystems.get('cargo') or []
deny_npm = ecosystems.get('npm') or []
deny_pub = ecosystems.get('pub') or []


def _match_publisher(eco, name, hint):
    """Match (eco, name, publisher hint) against deny-list. Return
    matching deny entry dict or None."""
    candidates = {
        'cargo': deny_cargo,
        'npm': deny_npm,
        'pub': deny_pub,
    }.get(eco, [])
    for entry in candidates:
        pat = entry.get('publisher', '')
        if not pat:
            continue
        # Glob-ish : '*' becomes a wildcard.
        regex = '^' + re.escape(pat).replace(r'\*', '.*') + '$'
        if re.match(regex, name) or (hint and re.match(regex, hint)):
            return entry
    return None


# ─── Phase 3 — match + classify ──────────────────────────────────
findings = []
cleared = []

for eco, name, ver, hint in deps:
    hit = _match_publisher(eco, name, hint)
    if hit:
        sev = _scale_severity_for_rule_001(tier)
        findings.append({
            'rule_id': 'K3-RULE-001',
            'severity': sev,
            'category': 'cloud-act',
            'location': f'{eco}:{name}@{ver}',
            'evidence': f'{name}@{ver} (publisher pattern: {hit.get("publisher", "")}, jurisdiction: {hit.get("jurisdiction", "")})',
            'risk': f'CLOUD Act exposure — publisher under {hit.get("jurisdiction", "")} jurisdiction is incompatible with declared tier {tier}',
            'remediation': '1. Replace with EU-jurisdiction equivalent. 2. OR formally downgrade declared tier with audit trail.',
            'verification': f'Re-run `forge-demeter-scan.sh --tier {tier}` and confirm no K3-RULE-001 findings.',
        })
    else:
        cleared.append({'rule_id': 'K3-RULE-001', 'verified': f'{eco}:{name}@{ver}'})

# Cargo workspace drift (K3-RULE-005) — Cargo.toml without sibling Cargo.lock.
cargo_toml_paths = [p for k, p in detected if k == 'cargo-toml']
cargo_lock_dirs = {os.path.dirname(p) for k, p in detected if k == 'cargo-lock'}
for ct in cargo_toml_paths:
    ct_dir = os.path.dirname(ct)
    # Only flag workspace roots — quick heuristic : look for [workspace]
    # or for a top-level project Cargo.toml without a sibling Cargo.lock.
    if ct_dir not in cargo_lock_dirs:
        # Walk upward to see if any ancestor has a Cargo.lock (workspace
        # member without its own lock is fine).
        ancestor = ct_dir
        while ancestor and ancestor != target:
            if ancestor in cargo_lock_dirs:
                break
            ancestor = os.path.dirname(ancestor)
        else:
            findings.append({
                'rule_id': 'K3-RULE-005',
                'severity': 'Medium',
                'category': 'tier-mismatch',
                'location': ct,
                'evidence': f'Cargo.toml present at {ct} but no Cargo.lock found in ancestor tree',
                'risk': 'Cargo workspace drift — dependencies cannot be deterministically jurisdiction-classified without a lockfile.',
                'remediation': '1. Run `cargo generate-lockfile` in the workspace root. 2. Re-run `forge-demeter-scan.sh`.',
                'verification': 'Confirm Cargo.lock is present and the next scan reports no K3-RULE-005 finding.',
            })

# DPA undeclared at T1 (K3-RULE-002).
if tier == 'T1':
    dpa_path = os.path.join(target, '.forge', '.forge-dpa-declared')
    if not os.path.isfile(dpa_path):
        findings.append({
            'rule_id': 'K3-RULE-002',
            'severity': 'High',
            'category': 'dpa',
            'location': dpa_path,
            'evidence': 'Tier=T1 declared but `.forge/.forge-dpa-declared` ledger is absent.',
            'risk': 'T1 workloads using ⚠️-T1 components require a DPA declaration ; absence breaks RGPD Article 28 attestation chain.',
            'remediation': '1. Create `.forge/.forge-dpa-declared` with content `T1: <ISO-8601-date> <free-form-ref>` + trailing newline. 2. OR drop ⚠️-T1 components from the project.',
            'verification': 'Confirm ledger exists with expected shape ; re-run scanner ; expect no K3-RULE-002 finding.',
        })

# Publisher list staleness (K3-RULE-006).
sde_env = os.environ.get('SOURCE_DATE_EPOCH')
if sde_env:
    today = datetime.datetime.fromtimestamp(int(sde_env), tz=datetime.timezone.utc).date()
else:
    today = datetime.datetime.now(tz=datetime.timezone.utc).date()
try:
    expires = datetime.date.fromisoformat(publisher_list_expires_at)
    if expires < today:
        findings.append({
            'rule_id': 'K3-RULE-006',
            'severity': 'Medium',
            'category': 'data-classification',
            'location': publishers_yml,
            'evidence': f'expires_at={publisher_list_expires_at} < today={today.isoformat()}',
            'risk': 'Stale deny-list — false negatives possible (recent acquisitions not yet reflected).',
            'remediation': '1. Refresh `.forge/data/cloud-act-publishers.yml` per ADR-K3-003 cadence. 2. Bump `version` and `last_reviewed` ; recompute `expires_at`.',
            'verification': 'Confirm `expires_at >= today` ; re-run scanner ; expect no K3-RULE-006 finding.',
        })
except (ValueError, TypeError):
    pass

# ─── Sort + summarise ─────────────────────────────────────────────
findings.sort(key=lambda f: (
    SEV_RANK.get(f['severity'], 99),
    f['rule_id'],
    f['evidence'],
))
cleared.sort(key=lambda c: (c['rule_id'], c['verified']))

summary = {
    'critical': sum(1 for f in findings if f['severity'] == 'Critical'),
    'high': sum(1 for f in findings if f['severity'] == 'High'),
    'medium': sum(1 for f in findings if f['severity'] == 'Medium'),
    'low': sum(1 for f in findings if f['severity'] == 'Low'),
    'informational': sum(1 for f in findings if f['severity'] == 'Informational'),
    'cleared': len(cleared),
}

if summary['critical'] > 0 or summary['high'] > 0:
    overall = 'BLOCKED'
    exit_code = 3
elif summary['medium'] > 0:
    overall = 'CONCERNS'
    exit_code = 1
else:
    overall = 'CLEARED'
    exit_code = 0

# ─── Emit ─────────────────────────────────────────────────────────
if sde_env:
    timestamp = datetime.datetime.fromtimestamp(
        int(sde_env), tz=datetime.timezone.utc,
    ).isoformat().replace('+00:00', 'Z')
else:
    timestamp = datetime.datetime.now(
        tz=datetime.timezone.utc,
    ).isoformat().replace('+00:00', 'Z')

coverage_mode = 'offline-deny-list-only'  # FR-K3-DEM-070 — always offline in this baseline

report = {
    'version': '1.0.0',
    'generated_at': timestamp,
    'target': target,
    'declared_tier': tier,
    'summary': summary,
    'overall_status': overall,
    'findings': findings,
    'cleared': cleared,
    'metadata': {
        'scanner_version': '0.1.0',
        'publisher_list_version': publisher_list_version,
        'publisher_list_last_reviewed': publisher_list_last_reviewed,
        'publisher_list_expires_at': publisher_list_expires_at,
        'coverage_mode': coverage_mode,
        'lockfiles_found': sorted(p for _, p in lockfile_detected),
    },
}

if fmt == 'json':
    rendered = json.dumps(report, sort_keys=True, indent=2) + '\n'
    if output_path == '-':
        sys.stdout.write(rendered)
    else:
        with open(output_path, 'w') as f:
            f.write(rendered)
elif fmt == 'md':
    lines = []
    lines.append('## Data Stewardship Audit Report')
    lines.append(f'**Project**: {os.path.basename(target)}')
    lines.append(f'**Date**: {timestamp}')
    lines.append('**Auditor**: Demeter')
    lines.append(f'**Scope**: {target} (tier {tier})')
    lines.append('')
    lines.append('---')
    lines.append('')
    lines.append('### Summary')
    lines.append('')
    lines.append('| Severity | Count |')
    lines.append('|---|---|')
    lines.append(f"| Critical | {summary['critical']} |")
    lines.append(f"| High | {summary['high']} |")
    lines.append(f"| Medium | {summary['medium']} |")
    lines.append(f"| Low | {summary['low']} |")
    lines.append(f"| Informational | {summary['informational']} |")
    lines.append('')
    lines.append(f'**Overall status**: {overall}')
    lines.append('')
    lines.append('---')
    lines.append('')
    lines.append('### Findings')
    lines.append('')
    if not findings:
        lines.append('_No findings._')
    else:
        for f_ in findings:
            lines.append(f"#### [{f_['severity'].upper()}] {f_['rule_id']}: {f_['category']}")
            lines.append(f"**Category**: {f_['category']}")
            lines.append(f"**Location**: `{f_['location']}`")
            lines.append(f"**Evidence**: {f_['evidence']}")
            lines.append(f"**Risk**: {f_['risk']}")
            lines.append(f"**Remediation**: {f_['remediation']}")
            lines.append(f"**Verification**: {f_['verification']}")
            lines.append('')
    lines.append('---')
    lines.append('')
    lines.append('### Cleared Items')
    lines.append('')
    if not cleared:
        lines.append('_No items cleared._')
    else:
        for c in cleared[:25]:
            lines.append(f"- {c['rule_id']}: {c['verified']}")
        if len(cleared) > 25:
            lines.append(f"- ... ({len(cleared) - 25} more cleared items)")
    rendered = '\n'.join(lines) + '\n'
    if output_path == '-':
        sys.stdout.write(rendered)
    else:
        with open(output_path, 'w') as f:
            f.write(rendered)

print(
    f"forge-demeter-scan: wrote {output_path} "
    f"({len(findings)} findings, status {overall}, tier {tier})",
    file=sys.stderr,
)
sys.exit(exit_code)
PY
rc=$?
exit $rc
