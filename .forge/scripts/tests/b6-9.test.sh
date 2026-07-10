#!/usr/bin/env bash
# Forge — B.6.9 event-driven-eu NIS2 + DORA Compliance Hooks Test Harness
# Audit: B.6.9 (b6-9-compliance)
#
# Validates the B.6.9 deliverables :
#
#   - .forge/compliance/nis2/     — 3 NIS2 artefacts (incident-reporting,
#     incident-report.template.yaml, obligations-index.yaml).
#   - .forge/scripts/compliance/dora-roi-helper.sh — the DORA Register-of-
#     Information submission helper (drives the b7-5 dora RoI base, specialises
#     it for the event-driven-eu NATS/Temporal/Postgres stack).
#   - .forge/standards/global/nis2-dora-eda-artefacts.md v1.0.0
#     (>= 6 H2 sections, >= 3 RFC-2119 MUST NOT clauses, two-phase
#     BDFL -> Themis governance, SBOM-wiring section).
#   - .forge/scripts/compliance/bundle.sh extended to collect the nis2
#     members under regulatory/nis2/ (additive).
#   - .forge/standards/global/compliance-artefacts-bundle.md bumped
#     1.1.0 -> 1.2.0 (I.6 contract, lock-step amendment).
#   - .forge/standards/index.yml entry + REVIEW.md ratification entry.
#   - docs/COMPLIANCE.md new H2 (## Regulatory artefacts (NIS2 + DORA event-driven)).
#   - CHANGELOG.md [Unreleased] entry.
#   - b7-5.test.sh::_test_b75_001 nis2-reserved assertion amended in lock-step
#     (ADR-B69-006) — nis2/ now legitimately created, cra/ still reserved.
#
# Anti-hallucination (Article III.4 — LOAD-BEARING) : the negative-grep
# guard _test_b69_030 FAILS if any "Article \d+" / "Art. \d+" / "recital"
# pattern appears under .forge/compliance/nis2/ OUTSIDE a
# [NEEDS CLARIFICATION] marker. Mirrors the b7-5 T-030 negative-grep guard.
#
# 17 L1 + 3 L2 = 20 tests.
# Performance budget : L1 <= 5 s wall-clock ; L2 <= 10 s additional
# (NFR-B69-008).

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
FORGE_ROOT_REAL="$(cd "$SCRIPTS_DIR/../.." && pwd)"

NIS2_DIR="$FORGE_ROOT_REAL/.forge/compliance/nis2"
STD_FILE="$FORGE_ROOT_REAL/.forge/standards/global/nis2-dora-eda-artefacts.md"
I6_STD="$FORGE_ROOT_REAL/.forge/standards/global/compliance-artefacts-bundle.md"
BUNDLE_SCRIPT="$FORGE_ROOT_REAL/.forge/scripts/compliance/bundle.sh"
ROI_HELPER="$FORGE_ROOT_REAL/.forge/scripts/compliance/dora-roi-helper.sh"
DORA_TEMPLATE="$FORGE_ROOT_REAL/.forge/compliance/dora/roi-register.template.yaml"
B75_HARNESS="$FORGE_ROOT_REAL/.forge/scripts/tests/b7-5.test.sh"
INDEX_YML="$FORGE_ROOT_REAL/.forge/standards/index.yml"
REVIEW_MD="$FORGE_ROOT_REAL/.forge/standards/REVIEW.md"
COMPLIANCE_DOC="$FORGE_ROOT_REAL/docs/COMPLIANCE.md"
CHANGELOG_MD="$FORGE_ROOT_REAL/CHANGELOG.md"
# L2 fixtures stage the I.6 canonical surfaces from these real sources.
DPA_TEMPLATE="$FORGE_ROOT_REAL/.forge/templates/compliance/forge-dpa-declared.template"
TIER_MATRIX_STD="$FORGE_ROOT_REAL/.forge/standards/global/compliance-tiers.md"
SBOM_SCRIPT="$FORGE_ROOT_REAL/bin/forge-sbom.sh"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (17 tests)
# MANIFEST: _test_b69_001_nis2_dir_present            — FR-B69-NIS2-001
# MANIFEST: _test_b69_002_audit_comments              — FR-B69-NIS2-002
# MANIFEST: _test_b69_010_incident_reporting          — FR-B69-NIS2-010 / FR-B69-NIS2-011
# MANIFEST: _test_b69_011_incident_report_template    — FR-B69-NIS2-012
# MANIFEST: _test_b69_012_nis2_obligations_index      — FR-B69-NIS2-013 / FR-B69-SBOM-010
# MANIFEST: _test_b69_020_dora_roi_helper_present     — FR-B69-DORA-001
# MANIFEST: _test_b69_021_dora_roi_helper_runs        — FR-B69-DORA-010 / FR-B69-DORA-020
# MANIFEST: _test_b69_030_no_fabricated_citation      — FR-B69-BD-102 / FR-B69-NIS2-030
# MANIFEST: _test_b69_040_standard_presence_frontmatter — FR-B69-BD-020 / FR-B69-BD-021
# MANIFEST: _test_b69_041_standard_h2_must_not_governance — FR-B69-BD-022 / FR-B69-BD-024 / FR-B69-BD-026
# MANIFEST: _test_b69_042_standard_sbom_wiring        — FR-B69-SBOM-001
# MANIFEST: _test_b69_050_index_review_entries        — FR-B69-BD-030 / FR-B69-BD-031
# MANIFEST: _test_b69_051_i6_standard_amended         — FR-B69-BD-010 / FR-B69-BD-011
# MANIFEST: _test_b69_052_bundle_walks_nis2           — FR-B69-BD-001
# MANIFEST: _test_b69_053_b75_harness_lockstep        — FR-B69-BD-130
# MANIFEST: _test_b69_060_compliance_doc_h2           — FR-B69-BD-120
# MANIFEST: _test_b69_061_changelog_entry             — FR-B69-BD-121
#
# L2 (3 tests)
# MANIFEST: _test_b69_l2_bundle_integration           — FR-B69-BD-110 / FR-B69-BD-001 / FR-B69-BD-002
# MANIFEST: _test_b69_l2_bundle_determinism           — FR-B69-BD-110 / FR-B69-BD-003 / NFR-B69-002
# MANIFEST: _test_b69_l2_graceful_absence             — FR-B69-BD-111 / FR-B69-BD-004

# ─── L1 tests ────────────────────────────────────────────────────

NIS2_MEMBERS=(
  "incident-reporting.md"
  "incident-report.template.yaml"
  "obligations-index.yaml"
)

# FR-B69-NIS2-001 — .forge/compliance/nis2/ present with members ; cra/ reserved
_test_b69_001_nis2_dir_present() {
  if [ ! -d "$NIS2_DIR" ]; then
    echo "    nis2 dir missing: $NIS2_DIR" >&2; return 1
  fi
  local m
  for m in "${NIS2_MEMBERS[@]}"; do
    if [ ! -f "$NIS2_DIR/$m" ]; then
      echo "    nis2 member missing: $m" >&2; return 1
    fi
  done
  # cra/ is RESERVED — deliberately NOT created (ADR-B69-001).
  if [ -d "$FORGE_ROOT_REAL/.forge/compliance/cra" ]; then
    echo "    cra/ should be reserved (not created) — ADR-B69-001" >&2; return 1
  fi
}

# FR-B69-NIS2-002 — audit anchor in first 5 lines of every member
_test_b69_002_audit_comments() {
  local f
  for f in "$NIS2_DIR"/*; do
    [ -f "$f" ] || continue
    if ! head -5 "$f" | grep -Fq "Audit: B.6.9 (b6-9-compliance)"; then
      echo "    audit anchor missing in first 5 lines of: $f" >&2; return 1
    fi
  done
}

# FR-B69-NIS2-010 / FR-B69-NIS2-011 — incident-reporting.md grounded windows + scoping
_test_b69_010_incident_reporting() {
  local f="$NIS2_DIR/incident-reporting.md"
  if [ ! -f "$f" ]; then
    echo "    incident-reporting.md missing" >&2; return 1
  fi
  # Grounded reporting windows "24h/72h" (verbatim, §10.4 / §7.1) + "< 24h" (§9.2).
  if ! grep -Eq "24h/72h|24h / 72h" "$f"; then
    echo "    grounded '24h/72h' reporting-window figure missing" >&2; return 1
  fi
  if ! grep -Eq "< ?24h|24h" "$f"; then
    echo "    grounded '< 24h' charter figure missing" >&2; return 1
  fi
  # Operational surface scoped to the event stack (NATS / Temporal / Postgres).
  if ! grep -Eiq "NATS" "$f"; then
    echo "    NATS JetStream operational scenario missing" >&2; return 1
  fi
  if ! grep -Eiq "Temporal" "$f"; then
    echo "    Temporal operational scenario missing" >&2; return 1
  fi
  if ! grep -Eiq "Postgres" "$f"; then
    echo "    Postgres event-store operational scenario missing" >&2; return 1
  fi
  # Evidence surface : I.6 audit-ledger.
  if ! grep -Eiq "audit-ledger|audit ledger" "$f"; then
    echo "    I.6 audit-ledger evidence surface missing" >&2; return 1
  fi
  # Q-001 [NEEDS CLARIFICATION] marker for the precise NIS2 stage breakdown.
  if ! grep -Fq "[NEEDS CLARIFICATION" "$f"; then
    echo "    Q-001 [NEEDS CLARIFICATION] reporting-stage marker missing" >&2; return 1
  fi
}

# FR-B69-NIS2-012 — incident-report.template.yaml skeleton
_test_b69_011_incident_report_template() {
  local f="$NIS2_DIR/incident-report.template.yaml"
  if [ ! -f "$f" ]; then
    echo "    incident-report.template.yaml missing" >&2; return 1
  fi
  # Valid YAML.
  python3 - "$f" <<'PY'
import sys, yaml
try:
    yaml.safe_load(open(sys.argv[1]))
except yaml.YAMLError as e:
    print(f"    invalid YAML: {e}", file=sys.stderr); sys.exit(1)
PY
  [ "$?" -eq 0 ] || return 1
  if ! grep -Fq "<FILL:" "$f"; then
    echo "    skeleton placeholder '<FILL:' missing" >&2; return 1
  fi
  if ! grep -Fq "[NEEDS CLARIFICATION" "$f"; then
    echo "    [NEEDS CLARIFICATION] CSIRT-schema marker missing" >&2; return 1
  fi
}

# FR-B69-NIS2-013 / FR-B69-SBOM-010 — nis2 obligations-index.yaml shape
_test_b69_012_nis2_obligations_index() {
  local f="$NIS2_DIR/obligations-index.yaml"
  if [ ! -f "$f" ]; then
    echo "    nis2 obligations-index.yaml missing" >&2; return 1
  fi
  python3 - "$f" "nis2" <<'PY'
import sys, yaml
path, reg = sys.argv[1], sys.argv[2]
try:
    d = yaml.safe_load(open(path)) or {}
except yaml.YAMLError as e:
    print(f"    invalid YAML: {e}", file=sys.stderr); sys.exit(1)
if d.get("schema_version") != "1.0.0":
    print("    schema_version != 1.0.0", file=sys.stderr); sys.exit(1)
if d.get("regulation") != reg:
    print(f"    regulation != {reg}", file=sys.stderr); sys.exit(1)
obs = d.get("obligations")
if not isinstance(obs, list) or not obs:
    print("    obligations: must be a non-empty list", file=sys.stderr); sys.exit(1)
satisfied = [o for o in obs if o.get("status") == "satisfied"]
needs = [o for o in obs if o.get("status") == "needs-clarification"]
# Two grounded obligations (incident-reporting + supply-chain-security).
if len(satisfied) < 2:
    print("    expected >= 2 satisfied obligations", file=sys.stderr); sys.exit(1)
ids = {o.get("id") for o in satisfied}
if "supply-chain-security" not in ids:
    print("    missing grounded 'supply-chain-security' (SBOM) obligation", file=sys.stderr); sys.exit(1)
for o in satisfied:
    sb = o.get("satisfied_by")
    if not isinstance(sb, list) or not sb:
        print(f"    satisfied obligation '{o.get('id')}' has no satisfied_by surface", file=sys.stderr); sys.exit(1)
# The supply-chain obligation MUST name the SBOM surface.
sc = next(o for o in satisfied if o.get("id") == "supply-chain-security")
if not any("sbom" in str(s).lower() for s in sc.get("satisfied_by", [])):
    print("    supply-chain-security must name the SBOM evidence surface", file=sys.stderr); sys.exit(1)
if not needs:
    print("    expected >= 1 needs-clarification obligation", file=sys.stderr); sys.exit(1)
for o in needs:
    if o.get("themis_owner") != "K.5":
        print(f"    needs-clarification '{o.get('id')}' missing themis_owner: K.5", file=sys.stderr); sys.exit(1)
PY
}

# FR-B69-DORA-001 — dora-roi-helper.sh presence + header + --help
_test_b69_020_dora_roi_helper_present() {
  if [ ! -f "$ROI_HELPER" ]; then
    echo "    dora-roi-helper.sh missing: $ROI_HELPER" >&2; return 1
  fi
  if [ ! -x "$ROI_HELPER" ]; then
    echo "    dora-roi-helper.sh not executable" >&2; return 1
  fi
  if ! head -5 "$ROI_HELPER" | grep -Fq "Audit: B.6.9 (b6-9-compliance)"; then
    echo "    audit comment missing in first 5 lines" >&2; return 1
  fi
  bash "$ROI_HELPER" --help >/dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    echo "    --help did not exit 0" >&2; return 1
  fi
}

# FR-B69-DORA-010 / FR-B69-DORA-020 — helper runs + emits stack-specialised RoI
ROI_TMP=""
_teardown_roi() {
  if [ -n "${ROI_TMP:-}" ] && [ -d "$ROI_TMP" ]; then
    rm -rf "$ROI_TMP"
  fi
  ROI_TMP=""
}
_test_b69_021_dora_roi_helper_runs() {
  if [ ! -f "$ROI_HELPER" ]; then
    echo "    dora-roi-helper.sh missing" >&2; return 1
  fi
  ROI_TMP="$(mk_tmpdir_with_trap forge-b69-roi)"
  trap '_teardown_roi' RETURN
  local out="$ROI_TMP/roi.yaml"
  bash "$ROI_HELPER" --target "$FORGE_ROOT_REAL" --output "$out" >/dev/null 2>&1
  local rc=$?
  assert_eq "0" "$rc" "dora-roi-helper exit code" || return 1
  if [ ! -f "$out" ]; then
    echo "    RoI output not produced: $out" >&2; return 1
  fi
  # Valid YAML.
  python3 - "$out" <<'PY'
import sys, yaml
try:
    yaml.safe_load(open(sys.argv[1]))
except yaml.YAMLError as e:
    print(f"    invalid RoI YAML: {e}", file=sys.stderr); sys.exit(1)
PY
  [ "$?" -eq 0 ] || return 1
  # The event-driven-eu ICT third-party provider categories are enumerated.
  local prov
  for prov in "NATS" "Temporal" "Postgres"; do
    if ! grep -Fq "$prov" "$out"; then
      echo "    RoI missing ICT third-party provider: $prov" >&2; return 1
    fi
  done
  # Grounded 30 avr 2026 deadline + the [NEEDS CLARIFICATION] schema marker.
  if ! grep -Fq "30 avr 2026" "$out"; then
    echo "    grounded '30 avr 2026' ESA deadline missing in RoI" >&2; return 1
  fi
  if ! grep -Fq "[NEEDS CLARIFICATION" "$out"; then
    echo "    [NEEDS CLARIFICATION] RoI-schema marker missing in output" >&2; return 1
  fi
}

# FR-B69-BD-102 / FR-B69-NIS2-030 — negative-grep anti-hallucination.
# Mirrors the b7-5 _test_b75_030 guard.
_test_b69_030_no_fabricated_citation() {
  local f hits ok=1
  for f in "$NIS2_DIR"/*; do
    [ -f "$f" ] || continue
    hits="$(grep -niE 'Article[[:space:]]+[0-9]+|Art\.[[:space:]]*[0-9]+|recital' "$f" 2>/dev/null \
              | grep -vF '[NEEDS CLARIFICATION' || true)"
    if [ -n "$hits" ]; then
      echo "    FAIL: fabricated/ungrounded citation in $(basename "$f"):" >&2
      printf '%s\n' "$hits" | sed 's/^/      /' >&2
      ok=0
    fi
  done
  [ "$ok" = "1" ]
}

# FR-B69-BD-020 / FR-B69-BD-021 — standard presence + H1 + frontmatter
_test_b69_040_standard_presence_frontmatter() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -q "^# Standard — NIS2 + DORA Event-Driven Regulatory Artefacts" "$STD_FILE"; then
    echo "    H1 anchor missing" >&2; return 1
  fi
  if ! head -5 "$STD_FILE" | grep -Fq "Audit: B.6.9 (b6-9-compliance)"; then
    echo "    audit comment missing in first 5 lines" >&2; return 1
  fi
  if ! head -5 "$STD_FILE" | grep -Fq "Trigger:"; then
    echo "    trigger comment missing in first 5 lines" >&2; return 1
  fi
  if ! grep -q "version: 1.0.0" "$STD_FILE"; then
    echo "    'version: 1.0.0' missing" >&2; return 1
  fi
  if ! grep -q "last_reviewed: 2026-07-10" "$STD_FILE"; then
    echo "    'last_reviewed: 2026-07-10' missing" >&2; return 1
  fi
  if ! grep -q "expires_at: 2027-07-10" "$STD_FILE"; then
    echo "    'expires_at: 2027-07-10' missing" >&2; return 1
  fi
}

# FR-B69-BD-022 / FR-B69-BD-024 / FR-B69-BD-026 — >= 6 H2 + >= 3 MUST NOT + governance
_test_b69_041_standard_h2_must_not_governance() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  local count
  count="$(grep -c "^## " "$STD_FILE")"
  if [ "$count" -lt 6 ]; then
    echo "    H2 section count $count < 6 minimum" >&2; return 1
  fi
  local section missing=()
  for section in \
    "## Purpose & EU regulatory scope" \
    "## Artefact content schema" \
    "## Obligation → evidence traceability" \
    "## Governance — two phases (BDFL → Themis)" \
    "## Consumption protocol" \
    "## Interdictions"; do
    if ! grep -Fq "$section" "$STD_FILE"; then
      missing+=("$section")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "    missing H2 section(s): ${missing[*]}" >&2; return 1
  fi
  local mn
  mn="$(grep -c "MUST NOT" "$STD_FILE")"
  if [ "$mn" -lt 3 ]; then
    echo "    MUST NOT count $mn < 3 minimum" >&2; return 1
  fi
  if ! grep -Fq "Themis" "$STD_FILE"; then
    echo "    Themis cross-link missing" >&2; return 1
  fi
}

# FR-B69-SBOM-001 — standard documents SBOM rides bin/forge-sbom.sh (no new code)
_test_b69_042_standard_sbom_wiring() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -Fq "bin/forge-sbom.sh" "$STD_FILE"; then
    echo "    SBOM wiring: 'bin/forge-sbom.sh' reference missing" >&2; return 1
  fi
  if ! grep -Fq "Cargo.lock" "$STD_FILE"; then
    echo "    SBOM wiring: 'Cargo.lock' reference missing" >&2; return 1
  fi
  if ! grep -Fq "sbom/sbom.cdx.json" "$STD_FILE"; then
    echo "    SBOM wiring: 'sbom/sbom.cdx.json' bundle-member reference missing" >&2; return 1
  fi
}

# FR-B69-BD-030 / FR-B69-BD-031 — index.yml entry + REVIEW.md entries
_test_b69_050_index_review_entries() {
  if [ ! -f "$INDEX_YML" ]; then
    echo "    index.yml missing" >&2; return 1
  fi
  if ! grep -Fq "id: global/nis2-dora-eda-artefacts" "$INDEX_YML"; then
    echo "    'id: global/nis2-dora-eda-artefacts' missing in index.yml" >&2; return 1
  fi
  if ! grep -Fq "path: standards/global/nis2-dora-eda-artefacts.md" "$INDEX_YML"; then
    echo "    'path: standards/global/nis2-dora-eda-artefacts.md' missing in index.yml" >&2; return 1
  fi
  local trigger
  for trigger in nis2 dora event-driven-eu compliance regulatory incident-reporting roi sbom supply-chain themis; do
    if ! grep -Fq "$trigger" "$INDEX_YML"; then
      echo "    index trigger '$trigger' missing" >&2; return 1
    fi
  done
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing" >&2; return 1
  fi
  if ! grep -Fq "## 2026-07-10 — Initial ratification (b6-9-compliance, B.6.9)" "$REVIEW_MD"; then
    echo "    REVIEW.md ratification H2 missing" >&2; return 1
  fi
  if ! grep -Fq "global/nis2-dora-eda-artefacts.md" "$REVIEW_MD"; then
    echo "    new-standard reference missing in REVIEW.md" >&2; return 1
  fi
  # The I.6 1.1.0 → 1.2.0 amendment recorded in the same entry.
  if ! grep -Fq "1.1.0 → 1.2.0" "$REVIEW_MD"; then
    echo "    I.6 '1.1.0 → 1.2.0' amendment record missing in REVIEW.md" >&2; return 1
  fi
}

# FR-B69-BD-010 / FR-B69-BD-011 — I.6 standard bundle-schema table + 1.2.0
_test_b69_051_i6_standard_amended() {
  if [ ! -f "$I6_STD" ]; then
    echo "    I.6 standard missing: $I6_STD" >&2; return 1
  fi
  if ! grep -q "version: 1.2.0" "$I6_STD"; then
    echo "    I.6 standard not bumped to 'version: 1.2.0'" >&2; return 1
  fi
  if ! grep -Fq "regulatory/nis2/" "$I6_STD"; then
    echo "    'regulatory/nis2/' bundle-schema row missing in I.6 standard" >&2; return 1
  fi
}

# FR-B69-BD-001 — bundle.sh directory-walk collects nis2
_test_b69_052_bundle_walks_nis2() {
  if [ ! -f "$BUNDLE_SCRIPT" ]; then
    echo "    bundle.sh missing: $BUNDLE_SCRIPT" >&2; return 1
  fi
  if ! grep -Eq 'for _reg in .*"nis2"' "$BUNDLE_SCRIPT"; then
    echo "    bundle.sh walk tuple does not include \"nis2\"" >&2; return 1
  fi
}

# FR-B69-BD-130 — b7-5 sibling-harness lock-step amendment present
_test_b69_053_b75_harness_lockstep() {
  if [ ! -f "$B75_HARNESS" ]; then
    echo "    b7-5.test.sh missing: $B75_HARNESS" >&2; return 1
  fi
  # The nis2/-reserved assertion must be GONE (B.6.9 now creates nis2/). We match
  # the unique echo message of the removed check, not the path string (which may
  # legitimately appear in an explanatory lock-step comment).
  if grep -Fq "nis2/ should be reserved" "$B75_HARNESS"; then
    echo "    b7-5.test.sh still asserts nis2/ reserved — lock-step edit missing" >&2; return 1
  fi
  # The cra/-reserved assertion must REMAIN (cra untouched).
  if ! grep -Fq "cra/ should be reserved" "$B75_HARNESS"; then
    echo "    b7-5.test.sh cra/-reserved assertion should be kept" >&2; return 1
  fi
}

# FR-B69-BD-120 — docs/COMPLIANCE.md H2
_test_b69_060_compliance_doc_h2() {
  if [ ! -f "$COMPLIANCE_DOC" ]; then
    echo "    docs/COMPLIANCE.md missing" >&2; return 1
  fi
  if ! grep -q "^## Regulatory artefacts (NIS2 + DORA event-driven)" "$COMPLIANCE_DOC"; then
    echo "    '## Regulatory artefacts (NIS2 + DORA event-driven)' H2 missing" >&2; return 1
  fi
  if ! grep -Fq "nis2-dora-eda-artefacts.md" "$COMPLIANCE_DOC"; then
    echo "    new-standard cross-link missing" >&2; return 1
  fi
  if ! grep -Fq "regulatory/nis2/" "$COMPLIANCE_DOC"; then
    echo "    bundle 'regulatory/nis2/' subdirectory cross-link missing" >&2; return 1
  fi
}

# FR-B69-BD-121 — CHANGELOG entry
_test_b69_061_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing" >&2; return 1
  fi
  if ! grep -Fq "b6-9-compliance" "$CHANGELOG_MD"; then
    echo "    'b6-9-compliance' reference missing in CHANGELOG.md" >&2; return 1
  fi
  if ! grep -Eq "NIS2.*DORA|DORA.*NIS2" "$CHANGELOG_MD"; then
    echo "    'NIS2 + DORA' phrase missing in CHANGELOG.md" >&2; return 1
  fi
}

# ─── L2 helpers ──────────────────────────────────────────────────

L2_TMP=""

# _setup_l2 <with_nis2:0|1> — stage a synthetic target tree with the 4 I.6
# canonical surfaces (so bundle.sh succeeds). When the first arg is 1, also
# stage the live nis2 artefacts under .forge/compliance/nis2/. The fixture
# builds its OWN tmpdir (never reads the live worktree's bundle output), so it
# is hermetic and does not couple to i6 / b7-5 counts.
_setup_l2() {
  local with_nis2="${1:-0}"
  L2_TMP="$(mk_tmpdir_with_trap forge-b69-l2)"

  mkdir -p \
    "$L2_TMP/.forge/standards/global" \
    "$L2_TMP/.forge/templates/compliance" \
    "$L2_TMP/.forge/changes/sample-archived" \
    "$L2_TMP/bin"

  if [ -f "$TIER_MATRIX_STD" ]; then
    cp "$TIER_MATRIX_STD" "$L2_TMP/.forge/standards/global/compliance-tiers.md"
  else
    echo "# Standard — Compliance Tiers" > "$L2_TMP/.forge/standards/global/compliance-tiers.md"
  fi

  if [ -f "$DPA_TEMPLATE" ]; then
    cp "$DPA_TEMPLATE" "$L2_TMP/.forge/templates/compliance/forge-dpa-declared.template"
  else
    printf '# stub DPA template\n' > "$L2_TMP/.forge/templates/compliance/forge-dpa-declared.template"
  fi

  cat > "$L2_TMP/.forge/standards/REVIEW.md" <<'REV'
# Forge Standards Review Ledger

## 2026-07-10 — Initial ratification (sample)

- **Decision**: KEEP
REV

  cat > "$L2_TMP/.forge/changes/sample-archived/.forge.yaml" <<'CHG'
name: sample-archived
status: archived
created: 2026-06-01
parent_audit_items:
  - SAMPLE.1
timeline:
  archived: 2026-06-10
CHG

  if [ -f "$SBOM_SCRIPT" ]; then
    cp "$SBOM_SCRIPT" "$L2_TMP/bin/forge-sbom.sh"
    chmod +x "$L2_TMP/bin/forge-sbom.sh"
  fi

  echo "0.0.0-test" > "$L2_TMP/VERSION"

  if [ "$with_nis2" = "1" ]; then
    mkdir -p "$L2_TMP/.forge/compliance/nis2"
    cp "$NIS2_DIR"/* "$L2_TMP/.forge/compliance/nis2/"
  fi
}

_teardown_l2() {
  if [ -n "${L2_TMP:-}" ] && [ -d "$L2_TMP" ]; then
    rm -rf "$L2_TMP"
  fi
  L2_TMP=""
}

# ─── L2 tests ────────────────────────────────────────────────────

# FR-B69-BD-110 / FR-B69-BD-001 / FR-B69-BD-002 — bundle integration
_test_b69_l2_bundle_integration() {
  _setup_l2 1
  trap '_teardown_l2' RETURN
  local out="$L2_TMP/bundle.tgz"
  bash "$BUNDLE_SCRIPT" --target "$L2_TMP" --output "$out" >/dev/null 2>&1
  local rc=$?
  assert_eq "0" "$rc" "bundle exit code (integration fixture)" || return 1
  if [ ! -f "$out" ]; then
    echo "    bundle output not produced: $out" >&2; return 1
  fi
  local listing
  listing="$(tar -tzf "$out" 2>/dev/null | sort)"
  # The 6 base members are still present (additive — FR-B69-BD-002).
  local member
  for member in MANIFEST \
    "tier-matrix/compliance-tiers.md" \
    "templates/forge-dpa-declared.template" \
    "audit/audit-ledger.json" \
    "audit/audit-ledger.md" \
    "sbom/sbom.cdx.json"; do
    if ! printf '%s\n' "$listing" | grep -Fxq "$member"; then
      echo "    expected base bundle member missing: $member" >&2
      printf '%s\n' "$listing" | sed 's/^/      /' >&2
      return 1
    fi
  done
  # Every nis2 artefact is carried under regulatory/nis2/.
  local f name
  for f in "$L2_TMP/.forge/compliance/nis2"/*; do
    [ -f "$f" ] || continue
    name="$(basename "$f")"
    if ! printf '%s\n' "$listing" | grep -Fxq "regulatory/nis2/$name"; then
      echo "    expected regulatory member missing: regulatory/nis2/$name" >&2
      return 1
    fi
  done
  # The MANIFEST lists every member (5 base non-MANIFEST + 3 nis2 = >= 8).
  local manifest_lines
  manifest_lines="$(tar -xOzf "$out" MANIFEST 2>/dev/null | grep -c '^[0-9a-f]\{64\}')"
  if [ "$manifest_lines" -lt 8 ]; then
    echo "    MANIFEST expected >= 8 entries (5 base + 3 nis2), got $manifest_lines" >&2
    return 1
  fi
}

# FR-B69-BD-110 / FR-B69-BD-003 / NFR-B69-002 — determinism with nis2 members
_test_b69_l2_bundle_determinism() {
  _setup_l2 1
  trap '_teardown_l2' RETURN
  local b1="$L2_TMP/bundle1.tgz"
  local b2="$L2_TMP/bundle2.tgz"
  SOURCE_DATE_EPOCH=0 bash "$BUNDLE_SCRIPT" --target "$L2_TMP" --output "$b1" >/dev/null 2>&1
  local rc1=$?
  SOURCE_DATE_EPOCH=0 bash "$BUNDLE_SCRIPT" --target "$L2_TMP" --output "$b2" >/dev/null 2>&1
  local rc2=$?
  assert_eq "0" "$rc1" "first run exit" || return 1
  assert_eq "0" "$rc2" "second run exit" || return 1
  if ! diff -q "$b1" "$b2" >/dev/null 2>&1; then
    echo "    extended bundles NOT byte-identical (NFR-B69-002 violation)" >&2
    return 1
  fi
}

# FR-B69-BD-111 / FR-B69-BD-004 — graceful absence
_test_b69_l2_graceful_absence() {
  _setup_l2 0
  trap '_teardown_l2' RETURN
  local out="$L2_TMP/bundle.tgz"
  bash "$BUNDLE_SCRIPT" --target "$L2_TMP" --output "$out" >/dev/null 2>&1
  local rc=$?
  assert_eq "0" "$rc" "bundle exit code (graceful absence)" || return 1
  if [ ! -f "$out" ]; then
    echo "    bundle output not produced: $out" >&2; return 1
  fi
  local listing
  listing="$(tar -tzf "$out" 2>/dev/null | sort)"
  # Zero nis2 members.
  if printf '%s\n' "$listing" | grep -q '^regulatory/nis2/'; then
    echo "    nis2 members present despite absent source dir" >&2
    printf '%s\n' "$listing" | sed 's/^/      /' >&2
    return 1
  fi
  # The base 6 members are still all present.
  local member
  for member in MANIFEST \
    "tier-matrix/compliance-tiers.md" \
    "templates/forge-dpa-declared.template" \
    "audit/audit-ledger.json" \
    "audit/audit-ledger.md" \
    "sbom/sbom.cdx.json"; do
    if ! printf '%s\n' "$listing" | grep -Fxq "$member"; then
      echo "    expected base member missing in graceful-absence fixture: $member" >&2
      return 1
    fi
  done
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── B.6.9 — b6-9-compliance — level $LEVEL ──"

  # L1 always runs.
  run_test _test_b69_001_nis2_dir_present
  run_test _test_b69_002_audit_comments
  run_test _test_b69_010_incident_reporting
  run_test _test_b69_011_incident_report_template
  run_test _test_b69_012_nis2_obligations_index
  run_test _test_b69_020_dora_roi_helper_present
  run_test _test_b69_021_dora_roi_helper_runs
  run_test _test_b69_030_no_fabricated_citation
  run_test _test_b69_040_standard_presence_frontmatter
  run_test _test_b69_041_standard_h2_must_not_governance
  run_test _test_b69_042_standard_sbom_wiring
  run_test _test_b69_050_index_review_entries
  run_test _test_b69_051_i6_standard_amended
  run_test _test_b69_052_bundle_walks_nis2
  run_test _test_b69_053_b75_harness_lockstep
  run_test _test_b69_060_compliance_doc_h2
  run_test _test_b69_061_changelog_entry

  # L2 runs when --level includes 2 or "all".
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based bundle integration / determinism / graceful-absence"
    run_test _test_b69_l2_bundle_integration
    run_test _test_b69_l2_bundle_determinism
    run_test _test_b69_l2_graceful_absence
  fi

  print_summary
}

main "$@"
