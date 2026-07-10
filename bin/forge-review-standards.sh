#!/usr/bin/env bash
# Forge — `forge-review-standards.sh` — K.5 Themis standards-review cadence
# <!-- Audit: K.5 (k5-themis, FR-K5-THE-020..036 / ADR-K5-002) -->
#
# Walks .forge/standards/ under --target for last_reviewed / expires_at
# frontmatter (top-level YAML in *.yaml standards + fenced ```yaml
# blocks in *.md standards), classifies each standard FRESH / DUE-SOON
# / EXPIRED / STRUCTURAL against a configurable review window, and emits
# a deterministic Standards Review Report (JSON or Markdown). Carries
# the verbatim NIS2 / DORA / CRA / AI Act regulatory-deadline calendar.
#
# Usage :
#   bin/forge-review-standards.sh [--target <dir>] [--window <days>]
#                                 [--output <path>] [--format json|md]
#                                 [--bundle] [--strict]
#
# Defaults : --target $(pwd), --window 30,
#            --output standards-review-report.json, --format json.
#
# Exit codes :
#   0 — CLEARED (no expired standards, none due within the window).
#   1 — REVIEW-DUE (review debt present; WARN-level, NON-blocking by
#       default per standards-lifecycle.md "WARN n'est jamais bloquant").
#   2 — usage error (bad args, target not a dir, .forge/standards/ absent).
#   3 — BLOCKED (only with --strict AND ≥ 1 expired non-structural standard).
#
# Determinism : SOURCE_DATE_EPOCH (POSIX env var) fixes "today" and the
# report timestamp for byte-identical output (NFR-K5-THE-005). Standards
# sorted by path ; findings by (severity_rank, rule_id, location) ; JSON
# uses sort_keys.
#
# --bundle : DRIVES (never forks) the I.6 bundle
# .forge/scripts/compliance/bundle.sh after writing a deterministic
# regulatory-deadline summary. Themis never edits or re-implements the
# bundle recipe.
#
# Pattern : bash thin + Python 3 inline (F.2 / J.7 / J.8.d / K.3).
# Stdlib only : os, sys, json, re, datetime + PyYAML (already required
# by Forge). No paid service, fully offline per NFR-K5-THE-034.

set -uo pipefail

OUTPUT="standards-review-report.json"
FORMAT="json"
TARGET="$(pwd)"
WINDOW="30"
BUNDLE="0"
STRICT="0"

err() { echo "forge-review-standards: $*" >&2; }

usage() {
  cat <<EOF
Usage: forge-review-standards.sh [--target <dir>] [--window <days>]
                                 [--output <path>] [--format json|md]
                                 [--bundle] [--strict]

Walks <target>/.forge/standards/ for last_reviewed / expires_at
frontmatter and emits a Standards Review Report. Carries the verbatim
NIS2 / DORA / CRA / AI Act regulatory-deadline calendar.

Defaults : --target \$(pwd), --window 30,
           --output standards-review-report.json, --format json.

Exit codes :
  0 CLEARED     no expired standards, none due within the window
  1 REVIEW-DUE  review debt present (WARN, non-blocking by default)
  2 usage error / .forge/standards/ absent
  3 BLOCKED     --strict + expired standard present

--bundle drives .forge/scripts/compliance/bundle.sh (never forks it).
Per FR-K5-THE-020..036 + ADR-K5-002.
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
    --window) WINDOW="${2:-}"; shift 2 ;;
    --window=*) WINDOW="${1#*=}"; shift ;;
    --bundle) BUNDLE="1"; shift ;;
    --strict) STRICT="1"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) err "unknown argument: $1"; usage >&2; exit 2 ;;
  esac
done

if [ "$FORMAT" != "json" ] && [ "$FORMAT" != "md" ]; then
  err "invalid --format '$FORMAT' (expected json|md)"; exit 2
fi

case "$WINDOW" in
  ''|*[!0-9]*) err "invalid --window '$WINDOW' (expected a positive integer)"; exit 2 ;;
esac

if [ ! -d "$TARGET" ]; then
  err "target directory not found: $TARGET"; exit 2
fi

TARGET="$(cd "$TARGET" && pwd)"

if [ ! -d "$TARGET/.forge/standards" ]; then
  err "no standards corpus at $TARGET/.forge/standards (nothing to review)"
  exit 2
fi

# Resolve OUTPUT to an absolute path so the report lands where the
# caller expects regardless of cwd changes inside Python.
case "$OUTPUT" in
  /*) ;;
  *) OUTPUT="$(pwd)/$OUTPUT" ;;
esac

python3 - "$TARGET" "$OUTPUT" "$FORMAT" "$WINDOW" "$STRICT" <<'PY'
import datetime
import json
import os
import re
import sys

target = sys.argv[1]
output_path = sys.argv[2]
fmt = sys.argv[3]
window_days = int(sys.argv[4])
strict = sys.argv[5] == "1"

SCANNER_VERSION = "0.1.0"

# ─── "today" — SOURCE_DATE_EPOCH-pinned for determinism ──────────
sde_env = os.environ.get("SOURCE_DATE_EPOCH")
if sde_env is not None and sde_env != "":
    _dt = datetime.datetime.fromtimestamp(int(sde_env), tz=datetime.timezone.utc)
    today = _dt.date()
    generated_at = _dt.isoformat().replace("+00:00", "Z")
else:
    _dt = datetime.datetime.now(tz=datetime.timezone.utc)
    today = _dt.date()
    generated_at = _dt.isoformat().replace("+00:00", "Z")

horizon = today + datetime.timedelta(days=365)
window_end = today + datetime.timedelta(days=window_days)

# ─── Regulatory-deadline calendar — VERBATIM from ────────────────
# docs/new-archetypes-plan.md §7.1 I.6 bullet (lines 2629-2634).
# Dates copied byte-for-byte ; never invented (Article III.4 /
# NFR-K5-THE-009). The `dates` ISO values transcribe the verbatim
# French-abbreviated deadlines for the horizon check only.
REGULATORY_CALENDAR = [
    {"regulation": "NIS2",
     "deadline": "NIS2 reporting 24h/72h",
     "dates": []},
    {"regulation": "DORA",
     "deadline": "DORA RoI ESA submission 30 avr 2026",
     "dates": ["2026-04-30"]},
    {"regulation": "CRA",
     "deadline": "CRA reporting 11 sept 2026, full requirements 11 déc 2027",
     "dates": ["2026-09-11", "2027-12-11"]},
    {"regulation": "AI Act",
     "deadline": "AI Act phases 2025–2027 par catégorie de risque",
     "dates": []},
]

SEVERITY_RANK = {
    "Critical": 0, "High": 1, "Medium": 2, "Low": 3, "Informational": 4,
}

FRONTMATTER_KEYS = ("version", "last_reviewed", "expires_at",
                    "exception_constitutional")


def _clean_scalar(raw):
    v = raw.split("#", 1)[0].strip()
    v = v.strip('"').strip("'")
    return v


def _parse_yaml_standard(path):
    """Top-level (column-0) key scan for a *.yaml standard.

    Deliberately NOT yaml.safe_load : the *.yaml standards carry inline
    comments and folded rationale blocks ; a targeted top-level key scan
    is more robust to the mixed comment / '>-' shapes.
    """
    fm = {}
    try:
        with open(path, encoding="utf-8") as f:
            for raw in f:
                line = raw.rstrip("\n")
                if not line or line[0] in (" ", "\t", "#"):
                    continue
                if ":" not in line:
                    continue
                key, _, val = line.partition(":")
                key = key.strip()
                if key in FRONTMATTER_KEYS and key not in fm:
                    fm[key] = _clean_scalar(val)
    except OSError:
        return {}
    return fm


def _parse_md_standard(path):
    """Read the first fenced ```yaml block of a *.md standard."""
    fm = {}
    in_block = False
    try:
        with open(path, encoding="utf-8") as f:
            for raw in f:
                line = raw.rstrip("\n")
                stripped = line.strip()
                if not in_block:
                    if stripped == "```yaml":
                        in_block = True
                    continue
                if stripped == "```":
                    break
                if ":" not in stripped or stripped.startswith("#"):
                    continue
                key, _, val = stripped.partition(":")
                key = key.strip()
                if key in FRONTMATTER_KEYS and key not in fm:
                    fm[key] = _clean_scalar(val)
    except OSError:
        return {}
    return fm


# ─── Phase 1 — discover standards ────────────────────────────────
standards_dir = os.path.join(target, ".forge", "standards")
discovered = []
for root, _dirs, files in os.walk(standards_dir):
    for name in files:
        if name in ("REVIEW.md", "index.yml", "index.yaml"):
            continue
        if not (name.endswith(".yaml") or name.endswith(".md")):
            continue
        full = os.path.join(root, name)
        rel = os.path.relpath(full, target)
        discovered.append((rel, full, name.endswith(".yaml")))

discovered.sort(key=lambda t: t[0])

# ─── Phase 2 + 3 — parse + classify ──────────────────────────────
standards_report = []
findings = []
cleared = []
clarifications = []


def _is_prose_subdir(rel):
    parts = rel.replace("\\", "/").split("/")
    # .forge/standards/<subdir>/...
    if len(parts) >= 4 and parts[3 - 1] in (
        "flutter", "rust", "infra", "observability",
    ):
        return True
    return False


def _add_finding(rule_id, severity, category, location, evidence, risk,
                 remediation, verification):
    findings.append({
        "rule_id": rule_id,
        "severity": severity,
        "category": category,
        "location": location,
        "evidence": evidence,
        "risk": risk,
        "remediation": remediation,
        "verification": verification,
    })


for rel, full, is_yaml in discovered:
    fm = _parse_yaml_standard(full) if is_yaml else _parse_md_standard(full)
    last_reviewed = fm.get("last_reviewed")
    expires_at = fm.get("expires_at")
    exc = str(fm.get("exception_constitutional", "")).lower() == "true"
    version = fm.get("version")

    # No lifecycle frontmatter at all → K5-RULE-003.
    if last_reviewed is None and expires_at is None:
        # *.md prose predates the T.4 contract → Informational (avoid a
        # false-positive storm) ; *.yaml MUST carry it (J.7 territory) →
        # Medium.
        sev = "Medium" if is_yaml else "Informational"
        _add_finding(
            "K5-RULE-003", sev, "review-cadence", rel,
            "no last_reviewed / expires_at frontmatter",
            "standard is outside the 12-month review cadence",
            "add the standards-lifecycle.md frontmatter contract",
            "re-run bin/forge-review-standards.sh",
        )
        standards_report.append({
            "path": rel, "version": version,
            "last_reviewed": last_reviewed, "expires_at": expires_at,
            "status": "NO-FRONTMATTER",
        })
        continue

    # Structural-exception coherence (K5-RULE-005).
    is_never = (expires_at == "never")
    if is_never != exc:
        _add_finding(
            "K5-RULE-005", "Medium", "structural-coherence", rel,
            "expires_at: %s / exception_constitutional: %s"
            % (expires_at, exc),
            "structural-exception keys disagree (XOR)",
            "align expires_at: never <=> exception_constitutional: true "
            "per standards-lifecycle.md Article-XII coupling",
            "re-run bin/forge-review-standards.sh",
        )

    # Structural exception → skip expiry (Cleared).
    if is_never and exc:
        standards_report.append({
            "path": rel, "version": version,
            "last_reviewed": last_reviewed, "expires_at": expires_at,
            "status": "STRUCTURAL",
        })
        cleared.append({"path": rel, "status": "STRUCTURAL"})
        continue
    if is_never and not exc:
        # never without constitutional flag — reported via K5-RULE-005
        # above ; treat as non-expiring for the cadence classification.
        standards_report.append({
            "path": rel, "version": version,
            "last_reviewed": last_reviewed, "expires_at": expires_at,
            "status": "STRUCTURAL-INCOHERENT",
        })
        continue

    # Dated expires_at — parse ISO-8601.
    try:
        exp_date = datetime.date.fromisoformat(expires_at)
    except (ValueError, TypeError):
        clarifications.append(
            "[NEEDS CLARIFICATION: unparseable expires_at in %s — "
            "expected YYYY-MM-DD or 'never']" % rel
        )
        standards_report.append({
            "path": rel, "version": version,
            "last_reviewed": last_reviewed, "expires_at": expires_at,
            "status": "UNPARSEABLE",
        })
        continue

    if exp_date < today:
        status = "EXPIRED"
        _add_finding(
            "K5-RULE-001", "Medium", "review-cadence", rel,
            "expires_at: %s (< today %s)" % (expires_at, today.isoformat()),
            "standard is past its 12-month review window",
            "review the standard, refresh last_reviewed / expires_at, "
            "append a REVIEW.md entry (open a Forge change if REPLACE / "
            "DEPRECATE)",
            "re-run bin/forge-review-standards.sh",
        )
    elif exp_date <= window_end:
        status = "DUE-SOON"
        _add_finding(
            "K5-RULE-002", "Low", "review-cadence", rel,
            "expires_at: %s (within %d-day window)"
            % (expires_at, window_days),
            "standard's review window is closing",
            "schedule the review before %s" % expires_at,
            "re-run bin/forge-review-standards.sh",
        )
    else:
        status = "FRESH"
        cleared.append({"path": rel, "status": "FRESH"})

    standards_report.append({
        "path": rel, "version": version,
        "last_reviewed": last_reviewed, "expires_at": expires_at,
        "status": status,
    })

# ─── Regulatory horizon (K5-RULE-004) ────────────────────────────
for entry in REGULATORY_CALENDAR:
    for iso in entry["dates"]:
        try:
            d = datetime.date.fromisoformat(iso)
        except ValueError:
            continue
        if today <= d <= horizon:
            _add_finding(
                "K5-RULE-004", "Informational", "regulatory-deadline",
                entry["regulation"],
                "%s (%s within 365-day horizon)" % (entry["deadline"], iso),
                "an EU regulatory milestone is approaching",
                "verify the repo's compliance artefacts address it; "
                "drive the I.6 bundle (--bundle)",
                "re-run bin/forge-review-standards.sh",
            )

# ─── Verdict + exit code ─────────────────────────────────────────
findings.sort(key=lambda f: (
    SEVERITY_RANK.get(f["severity"], 9), f["rule_id"], f["location"],
))

summary = {k: 0 for k in
           ("critical", "high", "medium", "low", "informational")}
for f in findings:
    summary[f["severity"].lower()] += 1
summary["cleared"] = len(cleared)

has_expired = any(f["rule_id"] == "K5-RULE-001" for f in findings)
review_debt = any(f["severity"] in ("Medium", "Low") for f in findings)

if strict and has_expired:
    overall_status = "BLOCKED"
    exit_code = 3
elif review_debt:
    overall_status = "REVIEW-DUE"
    exit_code = 1
else:
    overall_status = "CLEARED"
    exit_code = 0

report = {
    "version": "1.0.0",
    "generated_at": generated_at,
    "target": target,
    "review_window_days": window_days,
    "summary": summary,
    "overall_status": overall_status,
    "standards": standards_report,
    "findings": findings,
    "regulatory_deadlines": [
        {"regulation": e["regulation"], "deadline": e["deadline"],
         "dates": e["dates"]}
        for e in REGULATORY_CALENDAR
    ],
    "cleared": cleared,
    "metadata": {
        "scanner_version": SCANNER_VERSION,
        "standards_scanned": len(discovered),
        "coverage_mode": "frontmatter-walk",
        "strict": strict,
        "clarifications": clarifications,
    },
}

# ─── Emit ────────────────────────────────────────────────────────
if fmt == "json":
    out = json.dumps(report, sort_keys=True, indent=2) + "\n"
else:
    lines = []
    lines.append("## Standards Review Report")
    lines.append("**Officer**: Themis")
    lines.append("**Date**: %s" % generated_at)
    lines.append("**Review window**: %d days" % window_days)
    lines.append("**Scope**: %s/.forge/standards" % target)
    lines.append("")
    lines.append("### Summary")
    lines.append("")
    lines.append("| Severity | Count |")
    lines.append("|---|---|")
    for sev in ("Critical", "High", "Medium", "Low", "Informational"):
        lines.append("| %s | %d |" % (sev, summary[sev.lower()]))
    lines.append("| Cleared | %d |" % summary["cleared"])
    lines.append("")
    lines.append("**Overall status**: %s" % overall_status)
    lines.append("")
    lines.append("### Findings")
    lines.append("")
    if findings:
        for f in findings:
            lines.append("#### [%s] %s: %s"
                         % (f["severity"], f["rule_id"], f["location"]))
            lines.append("- **Evidence**: %s" % f["evidence"])
            lines.append("- **Risk**: %s" % f["risk"])
            lines.append("- **Remediation**: %s" % f["remediation"])
            lines.append("")
    else:
        lines.append("_None._")
        lines.append("")
    lines.append("### Regulatory deadlines")
    lines.append("")
    for e in REGULATORY_CALENDAR:
        lines.append("- %s" % e["deadline"])
    lines.append("")
    out = "\n".join(lines) + "\n"

with open(output_path, "w", encoding="utf-8") as f:
    f.write(out)

print("forge-review-standards: %s (%d standards, status %s)"
      % (output_path, len(discovered), overall_status), file=sys.stderr)
for c in clarifications:
    print("forge-review-standards: %s" % c, file=sys.stderr)

sys.exit(exit_code)
PY
rc=$?

# ─── --bundle : DRIVE (never fork) the I.6 compliance bundle ──────
if [ "$BUNDLE" = "1" ]; then
  OUT_DIR="$(cd "$(dirname "$OUTPUT")" && pwd)"
  SUMMARY="$OUT_DIR/forge-regulatory-deadlines.md"
  cat > "$SUMMARY" <<'SUMEOF'
# Forge — EU Regulatory-Deadline Summary (Themis, K.5)

<!-- Generated by bin/forge-review-standards.sh --bundle. Dates copied
     VERBATIM from docs/new-archetypes-plan.md §7.1 I.6 bullet — never
     invented (Article III.4). -->

- NIS2 reporting 24h/72h
- DORA RoI ESA submission 30 avr 2026
- CRA reporting 11 sept 2026, full requirements 11 déc 2027
- AI Act phases 2025–2027 par catégorie de risque
SUMEOF
  echo "forge-review-standards: wrote regulatory summary $SUMMARY" >&2

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  BUNDLE_SH="$REPO_ROOT/.forge/scripts/compliance/bundle.sh"
  if [ -x "$BUNDLE_SH" ]; then
    # DRIVE the canonical I.6 bundle — never fork or byte-alter it.
    bash "$BUNDLE_SH" --target "$TARGET" || true
  else
    err "I.6 bundle.sh not found at $BUNDLE_SH — regulatory summary written, bundle not regenerated"
  fi
fi

exit $rc
