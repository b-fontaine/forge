#!/usr/bin/env bash
# Forge — B.7.5 + B.7.8 AI-Act + DORA Regulatory Artefacts Test Harness
# Audit: B.7.5+B.7.8 (b7-5-ai-act)
#
# Validates the B.7.5 + B.7.8 deliverables :
#
#   - .forge/compliance/ai-act/   — 5 AI-Act artefacts (risk-classification,
#     transparency-obligations, model-card.template, dataset-card.template,
#     obligations-index.yaml).
#   - .forge/compliance/dora/     — 3 DORA artefacts (incident-reporting,
#     roi-register.template.yaml, obligations-index.yaml).
#   - .forge/standards/global/ai-act-dora-artefacts.md v1.0.0
#     (≥ 6 H2 sections, ≥ 3 RFC-2119 MUST NOT clauses, two-phase
#     BDFL → Themis governance).
#   - .forge/scripts/compliance/bundle.sh extended to collect the
#     regulatory members under regulatory/{ai-act,dora}/ (additive).
#   - .forge/standards/global/compliance-artefacts-bundle.md bumped
#     1.0.0 → 1.1.0 (I.6 contract, lock-step amendment).
#   - .forge/standards/index.yml entry + REVIEW.md ratification entry.
#   - docs/COMPLIANCE.md new H2 (## Regulatory artefacts (AI Act + DORA)).
#   - CHANGELOG.md [Unreleased] entry.
#
# Anti-hallucination (Article III.4 — LOAD-BEARING) : the negative-grep
# guard _test_b75_030 FAILS if any "Article \d+" / "Art. \d+" / "recital"
# pattern appears under .forge/compliance/{ai-act,dora}/ OUTSIDE a
# [NEEDS CLARIFICATION] marker. Mirrors the b7-3 T-007 negative-grep guard.
#
# 16 L1 + 3 L2 = 19 tests.
# Performance budget : L1 ≤ 5 s wall-clock ; L2 ≤ 10 s additional
# (NFR-B75-008).

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

AIACT_DIR="$FORGE_ROOT_REAL/.forge/compliance/ai-act"
DORA_DIR="$FORGE_ROOT_REAL/.forge/compliance/dora"
STD_FILE="$FORGE_ROOT_REAL/.forge/standards/global/ai-act-dora-artefacts.md"
I6_STD="$FORGE_ROOT_REAL/.forge/standards/global/compliance-artefacts-bundle.md"
BUNDLE_SCRIPT="$FORGE_ROOT_REAL/.forge/scripts/compliance/bundle.sh"
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
# L1 (16 tests)
# MANIFEST: _test_b75_001_compliance_dirs_present     — FR-B75-AA-001 / FR-B75-DO-001
# MANIFEST: _test_b75_002_audit_comments              — FR-B75-AA-002 / FR-B75-DO-002
# MANIFEST: _test_b75_010_risk_classification         — FR-B75-AA-010 / FR-B75-AA-011
# MANIFEST: _test_b75_011_transparency_obligations    — FR-B75-AA-012
# MANIFEST: _test_b75_012_model_dataset_cards         — FR-B75-AA-020 / FR-B75-AA-021
# MANIFEST: _test_b75_013_aiact_obligations_index     — FR-B75-AA-025 / FR-B75-AA-026
# MANIFEST: _test_b75_020_incident_reporting          — FR-B75-DO-010 / FR-B75-DO-011
# MANIFEST: _test_b75_021_roi_register                — FR-B75-DO-015
# MANIFEST: _test_b75_022_dora_obligations_index      — FR-B75-DO-016
# MANIFEST: _test_b75_030_no_fabricated_citation      — FR-B75-BD-102 / FR-B75-AA-030 / FR-B75-DO-020
# MANIFEST: _test_b75_040_standard_presence_frontmatter — FR-B75-BD-020 / FR-B75-BD-021
# MANIFEST: _test_b75_041_standard_h2_must_not_governance — FR-B75-BD-022 / FR-B75-BD-024 / FR-B75-BD-026
# MANIFEST: _test_b75_050_index_review_entries        — FR-B75-BD-030 / FR-B75-BD-031
# MANIFEST: _test_b75_051_i6_standard_amended         — FR-B75-BD-010 / FR-B75-BD-011
# MANIFEST: _test_b75_060_compliance_doc_h2           — FR-B75-BD-120
# MANIFEST: _test_b75_061_changelog_entry             — FR-B75-BD-122
#
# L2 (3 tests)
# MANIFEST: _test_b75_l2_bundle_integration           — FR-B75-BD-110 / FR-B75-BD-001 / FR-B75-BD-002
# MANIFEST: _test_b75_l2_bundle_determinism           — FR-B75-BD-110 / FR-B75-BD-003 / NFR-B75-002
# MANIFEST: _test_b75_l2_graceful_absence             — FR-B75-BD-111 / FR-B75-BD-004

# ─── L1 tests ────────────────────────────────────────────────────

_not_implemented() {
  echo "    not implemented yet (RED witness)" >&2
  return 1
}

AIACT_MEMBERS=(
  "risk-classification.md"
  "transparency-obligations.md"
  "model-card.template.md"
  "dataset-card.template.md"
  "obligations-index.yaml"
)
DORA_MEMBERS=(
  "incident-reporting.md"
  "roi-register.template.yaml"
  "obligations-index.yaml"
)

# FR-B75-AA-001 / FR-B75-DO-001 — .forge/compliance/{ai-act,dora}/ present with members
_test_b75_001_compliance_dirs_present() {
  if [ ! -d "$AIACT_DIR" ]; then
    echo "    ai-act dir missing: $AIACT_DIR" >&2; return 1
  fi
  if [ ! -d "$DORA_DIR" ]; then
    echo "    dora dir missing: $DORA_DIR" >&2; return 1
  fi
  local m
  for m in "${AIACT_MEMBERS[@]}"; do
    if [ ! -f "$AIACT_DIR/$m" ]; then
      echo "    ai-act member missing: $m" >&2; return 1
    fi
  done
  for m in "${DORA_MEMBERS[@]}"; do
    if [ ! -f "$DORA_DIR/$m" ]; then
      echo "    dora member missing: $m" >&2; return 1
    fi
  done
  # cra/ is RESERVED — deliberately NOT created (ADR-B75-001). The sibling
  # nis2/ reservation was DROPPED in lock-step by b6-9-compliance (ADR-B69-006):
  # B.6.9 legitimately ships .forge/compliance/nis2/ for the event-driven-eu
  # archetype, so asserting its absence here would break main. cra/ stays reserved.
  if [ -d "$FORGE_ROOT_REAL/.forge/compliance/cra" ]; then
    echo "    cra/ should be reserved (not created) — ADR-B75-001" >&2; return 1
  fi
}

# FR-B75-AA-002 / FR-B75-DO-002 — audit anchor in first 5 lines of every member
_test_b75_002_audit_comments() {
  local f
  for f in "$AIACT_DIR"/* "$DORA_DIR"/*; do
    [ -f "$f" ] || continue
    if ! head -5 "$f" | grep -Fq "Audit: B.7.5+B.7.8 (b7-5-ai-act)"; then
      echo "    audit anchor missing in first 5 lines of: $f" >&2; return 1
    fi
  done
}

# FR-B75-AA-010 / FR-B75-AA-011 — risk-classification.md grounded posture + markers
_test_b75_010_risk_classification() {
  local f="$AIACT_DIR/risk-classification.md"
  if [ ! -f "$f" ]; then
    echo "    risk-classification.md missing" >&2; return 1
  fi
  # Grounded posture : transparency obligations + the §10.3 / llm-gateway citation.
  if ! grep -Fq "transparency" "$f"; then
    echo "    grounded transparency-obligation posture missing" >&2; return 1
  fi
  if ! grep -Eq "10\.3|llm-gateway" "$f"; then
    echo "    grounded source citation (§10.3 / llm-gateway.md) missing" >&2; return 1
  fi
  # Escalation triggers (finance/regulated context — Q-003).
  if ! grep -Eiq "escalation|finance|regulated" "$f"; then
    echo "    escalation triggers missing" >&2; return 1
  fi
  # The Q-001 + Q-003 [NEEDS CLARIFICATION] markers (≥ 2).
  local nc
  nc="$(grep -c "\[NEEDS CLARIFICATION" "$f")"
  if [ "$nc" -lt 2 ]; then
    echo "    expected ≥ 2 [NEEDS CLARIFICATION] markers, got $nc" >&2; return 1
  fi
}

# FR-B75-AA-012 — transparency-obligations.md evidence-surface cross-links
_test_b75_011_transparency_obligations() {
  local f="$AIACT_DIR/transparency-obligations.md"
  if [ ! -f "$f" ]; then
    echo "    transparency-obligations.md missing" >&2; return 1
  fi
  if ! grep -Fq "fallbackUsed" "$f"; then
    echo "    Qwik fallbackUsed evidence surface missing" >&2; return 1
  fi
  if ! grep -Eq "FR-B7-2-020" "$f"; then
    echo "    b7-2-scaffolder FR-B7-2-020 cross-link missing" >&2; return 1
  fi
  if ! grep -Eiq "prompt-audit|IX\.6" "$f"; then
    echo "    IX.6 prompt-audit evidence surface missing" >&2; return 1
  fi
}

# FR-B75-AA-020 / FR-B75-AA-021 — model-card + dataset-card skeleton headers
_test_b75_012_model_dataset_cards() {
  local mc="$AIACT_DIR/model-card.template.md"
  local dc="$AIACT_DIR/dataset-card.template.md"
  if [ ! -f "$mc" ]; then
    echo "    model-card.template.md missing" >&2; return 1
  fi
  if [ ! -f "$dc" ]; then
    echo "    dataset-card.template.md missing" >&2; return 1
  fi
  # Adopter-fillable skeleton uses <FILL: ...> placeholders.
  local c
  for c in "$mc" "$dc"; do
    if ! grep -Fq "<FILL:" "$c"; then
      echo "    skeleton placeholder '<FILL:' missing in: $c" >&2; return 1
    fi
    # Q-004 bias-eval [NEEDS CLARIFICATION] in the header.
    if ! grep -Fq "[NEEDS CLARIFICATION" "$c"; then
      echo "    Q-004 [NEEDS CLARIFICATION] bias-eval marker missing in: $c" >&2; return 1
    fi
  done
}

# FR-B75-AA-025 / FR-B75-AA-026 — ai-act obligations-index.yaml shape
_test_b75_013_aiact_obligations_index() {
  local f="$AIACT_DIR/obligations-index.yaml"
  if [ ! -f "$f" ]; then
    echo "    ai-act obligations-index.yaml missing" >&2; return 1
  fi
  python3 - "$f" "ai-act" <<'PY'
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
# Two grounded obligations (transparency + logging-record-keeping).
if len(satisfied) < 2:
    print("    expected ≥ 2 satisfied obligations", file=sys.stderr); sys.exit(1)
# Every satisfied obligation MUST name a concrete evidence surface.
for o in satisfied:
    sb = o.get("satisfied_by")
    if not isinstance(sb, list) or not sb:
        print(f"    satisfied obligation '{o.get('id')}' has no satisfied_by surface", file=sys.stderr); sys.exit(1)
# Ungrounded obligations flagged needs-clarification + themis_owner K.5.
if not needs:
    print("    expected ≥ 1 needs-clarification obligation", file=sys.stderr); sys.exit(1)
for o in needs:
    if o.get("themis_owner") != "K.5":
        print(f"    needs-clarification '{o.get('id')}' missing themis_owner: K.5", file=sys.stderr); sys.exit(1)
PY
}

# FR-B75-DO-010 / FR-B75-DO-011 — incident-reporting.md grounded figures + marker
_test_b75_020_incident_reporting() {
  local f="$DORA_DIR/incident-reporting.md"
  if [ ! -f "$f" ]; then
    echo "    incident-reporting.md missing" >&2; return 1
  fi
  # Grounded "< 24h" charter figure (§9.2) + the RoI "30 avr 2026" deadline (§10.4).
  if ! grep -Eq "24h|24 h" "$f"; then
    echo "    grounded '< 24h' charter figure missing" >&2; return 1
  fi
  if ! grep -Fq "30 avr 2026" "$f"; then
    echo "    grounded RoI '30 avr 2026' deadline missing" >&2; return 1
  fi
  # Evidence surfaces : audit-ledger + prompt-audit.
  if ! grep -Eiq "audit-ledger|audit ledger" "$f"; then
    echo "    I.6 audit-ledger evidence surface missing" >&2; return 1
  fi
  if ! grep -Eiq "prompt-audit|IX\.6" "$f"; then
    echo "    IX.6 prompt-audit evidence surface missing" >&2; return 1
  fi
  # Q-002 [NEEDS CLARIFICATION] for the precise DORA windows.
  if ! grep -Fq "[NEEDS CLARIFICATION" "$f"; then
    echo "    Q-002 [NEEDS CLARIFICATION] notification-window marker missing" >&2; return 1
  fi
}

# FR-B75-DO-015 — roi-register.template.yaml skeleton
_test_b75_021_roi_register() {
  local f="$DORA_DIR/roi-register.template.yaml"
  if [ ! -f "$f" ]; then
    echo "    roi-register.template.yaml missing" >&2; return 1
  fi
  # Valid YAML.
  python3 - "$f" <<'PY'
import sys, yaml
try:
    yaml.safe_load(open(sys.argv[1]))
except yaml.YAMLError as e:
    print(f"    invalid YAML: {e}", file=sys.stderr); sys.exit(1)
PY
  local rc=$?
  [ "$rc" -eq 0 ] || return 1
  # Adopter-fillable + the Q [NEEDS CLARIFICATION] for the authoritative schema.
  if ! grep -Fq "[NEEDS CLARIFICATION" "$f"; then
    echo "    [NEEDS CLARIFICATION] RoI-schema marker missing" >&2; return 1
  fi
}

# FR-B75-DO-016 — dora obligations-index.yaml shape
_test_b75_022_dora_obligations_index() {
  local f="$DORA_DIR/obligations-index.yaml"
  if [ ! -f "$f" ]; then
    echo "    dora obligations-index.yaml missing" >&2; return 1
  fi
  python3 - "$f" "dora" <<'PY'
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
if not satisfied:
    print("    expected ≥ 1 satisfied obligation (incident-reporting / RoI)", file=sys.stderr); sys.exit(1)
for o in satisfied:
    sb = o.get("satisfied_by")
    if not isinstance(sb, list) or not sb:
        print(f"    satisfied obligation '{o.get('id')}' has no satisfied_by surface", file=sys.stderr); sys.exit(1)
if not needs:
    print("    expected ≥ 1 needs-clarification obligation", file=sys.stderr); sys.exit(1)
for o in needs:
    if o.get("themis_owner") != "K.5":
        print(f"    needs-clarification '{o.get('id')}' missing themis_owner: K.5", file=sys.stderr); sys.exit(1)
PY
}

# FR-B75-BD-102 / FR-B75-AA-030 / FR-B75-DO-020 — negative-grep anti-hallucination.
# Mirrors the b7-3 T-007 guard. FAILS if any "Article \d+" / "Art. \d+" /
# "recital" pattern appears under .forge/compliance/{ai-act,dora}/ OUTSIDE a
# [NEEDS CLARIFICATION marker. Article III.4 deterministic backstop.
_test_b75_030_no_fabricated_citation() {
  local f hits ok=1
  for f in "$AIACT_DIR"/* "$DORA_DIR"/*; do
    [ -f "$f" ] || continue
    # Grep for the forbidden citation patterns, drop any line that carries a
    # [NEEDS CLARIFICATION marker (those are the legitimate deferred slots).
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

# FR-B75-BD-020 / FR-B75-BD-021 — standard presence + H1 + frontmatter
_test_b75_040_standard_presence_frontmatter() {
  if [ ! -f "$STD_FILE" ]; then
    echo "    standard file missing: $STD_FILE" >&2; return 1
  fi
  if ! grep -q "^# Standard — AI Act + DORA Regulatory Artefacts" "$STD_FILE"; then
    echo "    H1 anchor missing" >&2; return 1
  fi
  if ! head -5 "$STD_FILE" | grep -Fq "Audit: B.7.5+B.7.8 (b7-5-ai-act)"; then
    echo "    audit comment missing in first 5 lines" >&2; return 1
  fi
  if ! head -5 "$STD_FILE" | grep -Fq "Trigger:"; then
    echo "    trigger comment missing in first 5 lines" >&2; return 1
  fi
  if ! grep -q "version: 1.0.0" "$STD_FILE"; then
    echo "    'version: 1.0.0' missing" >&2; return 1
  fi
  if ! grep -q "last_reviewed: 2026-06-22" "$STD_FILE"; then
    echo "    'last_reviewed: 2026-06-22' missing" >&2; return 1
  fi
  if ! grep -q "expires_at: 2027-06-22" "$STD_FILE"; then
    echo "    'expires_at: 2027-06-22' missing" >&2; return 1
  fi
}

# FR-B75-BD-022 / FR-B75-BD-024 / FR-B75-BD-026 — ≥ 6 H2 + ≥ 3 MUST NOT + governance
_test_b75_041_standard_h2_must_not_governance() {
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
  # Governance two-phase section MUST name BDFL Phase A + Themis Phase B.
  if ! grep -Fq "Themis" "$STD_FILE"; then
    echo "    Themis cross-link missing" >&2; return 1
  fi
}

# FR-B75-BD-030 / FR-B75-BD-031 — index.yml entry + REVIEW.md entries
_test_b75_050_index_review_entries() {
  if [ ! -f "$INDEX_YML" ]; then
    echo "    index.yml missing" >&2; return 1
  fi
  if ! grep -Fq "id: global/ai-act-dora-artefacts" "$INDEX_YML"; then
    echo "    'id: global/ai-act-dora-artefacts' missing in index.yml" >&2; return 1
  fi
  if ! grep -Fq "path: standards/global/ai-act-dora-artefacts.md" "$INDEX_YML"; then
    echo "    'path: standards/global/ai-act-dora-artefacts.md' missing in index.yml" >&2; return 1
  fi
  local trigger
  for trigger in ai-act dora compliance regulatory model-card dataset-card transparency incident-reporting themis; do
    if ! grep -Fq "$trigger" "$INDEX_YML"; then
      echo "    index trigger '$trigger' missing" >&2; return 1
    fi
  done
  if [ ! -f "$REVIEW_MD" ]; then
    echo "    REVIEW.md missing" >&2; return 1
  fi
  if ! grep -Fq "## 2026-06-22 — Initial ratification (b7-5-ai-act, B.7.5 + B.7.8)" "$REVIEW_MD"; then
    echo "    REVIEW.md ratification H2 missing" >&2; return 1
  fi
  if ! grep -Fq "global/ai-act-dora-artefacts.md" "$REVIEW_MD"; then
    echo "    new-standard reference missing in REVIEW.md" >&2; return 1
  fi
  # The I.6 1.0.0 → 1.1.0 amendment recorded in the same entry.
  if ! grep -Fq "1.0.0 → 1.1.0" "$REVIEW_MD"; then
    echo "    I.6 '1.0.0 → 1.1.0' amendment record missing in REVIEW.md" >&2; return 1
  fi
}

# FR-B75-BD-010 / FR-B75-BD-011 — I.6 standard bundle-schema table + minor bump
# LOCK-STEP NOTE (b6-9-compliance, 2026-07-10) : the I.6 bundle standard's
# `version:` is a mutable field bumped by each additive expansion (b7-5 → 1.1.0,
# b6-9 → 1.2.0, future CRA → 1.3.0). Per the REVIEW.md "Option B" precedent
# (i2.test.sh / i3.test.sh, 2026-06-22), a sibling change's gate MUST NOT
# exact-pin another standard's mutable version — it is relaxed here to a
# semver-validity check (>= the 1.1.0 at which the ai-act/dora rows landed). The
# real assertion (the ai-act/dora schema rows are present) is unchanged.
_test_b75_051_i6_standard_amended() {
  if [ ! -f "$I6_STD" ]; then
    echo "    I.6 standard missing: $I6_STD" >&2; return 1
  fi
  if ! grep -Eq "version: 1\.[1-9][0-9]*\.[0-9]+" "$I6_STD"; then
    echo "    I.6 standard version not a valid >= 1.1.0 semver (ai-act/dora rows expected)" >&2; return 1
  fi
  if ! grep -Fq "regulatory/ai-act/" "$I6_STD"; then
    echo "    'regulatory/ai-act/' bundle-schema row missing in I.6 standard" >&2; return 1
  fi
  if ! grep -Fq "regulatory/dora/" "$I6_STD"; then
    echo "    'regulatory/dora/' bundle-schema row missing in I.6 standard" >&2; return 1
  fi
}

# FR-B75-BD-120 — docs/COMPLIANCE.md H2
_test_b75_060_compliance_doc_h2() {
  if [ ! -f "$COMPLIANCE_DOC" ]; then
    echo "    docs/COMPLIANCE.md missing" >&2; return 1
  fi
  if ! grep -q "^## Regulatory artefacts (AI Act + DORA)" "$COMPLIANCE_DOC"; then
    echo "    '## Regulatory artefacts (AI Act + DORA)' H2 missing" >&2; return 1
  fi
  if ! grep -Fq "ai-act-dora-artefacts.md" "$COMPLIANCE_DOC"; then
    echo "    new-standard cross-link missing" >&2; return 1
  fi
  if ! grep -Fq "regulatory/" "$COMPLIANCE_DOC"; then
    echo "    bundle 'regulatory/' subdirectory cross-link missing" >&2; return 1
  fi
}

# FR-B75-BD-122 — CHANGELOG entry
_test_b75_061_changelog_entry() {
  if [ ! -f "$CHANGELOG_MD" ]; then
    echo "    CHANGELOG.md missing" >&2; return 1
  fi
  if ! grep -Fq "b7-5-ai-act" "$CHANGELOG_MD"; then
    echo "    'b7-5-ai-act' reference missing in CHANGELOG.md" >&2; return 1
  fi
  if ! grep -Eq "AI.?Act.*DORA|DORA.*AI.?Act" "$CHANGELOG_MD"; then
    echo "    'AI Act + DORA' phrase missing in CHANGELOG.md" >&2; return 1
  fi
}

# ─── L2 helpers ──────────────────────────────────────────────────

L2_TMP=""

# _setup_l2 <with_regulatory:0|1> — stage a synthetic target tree with the 4
# I.6 canonical surfaces (so bundle.sh succeeds). When the first arg is 1, also
# stage the live regulatory artefacts under .forge/compliance/{ai-act,dora}/.
# The fixture builds its OWN tmpdir (never reads the live worktree's bundle
# output), so it is hermetic and does not couple to i6's count.
_setup_l2() {
  local with_reg="${1:-0}"
  L2_TMP="$(mk_tmpdir_with_trap forge-b75-l2)"

  mkdir -p \
    "$L2_TMP/.forge/standards/global" \
    "$L2_TMP/.forge/templates/compliance" \
    "$L2_TMP/.forge/changes/sample-archived" \
    "$L2_TMP/bin"

  # Tier matrix standard (real copy if present, else a stub).
  if [ -f "$TIER_MATRIX_STD" ]; then
    cp "$TIER_MATRIX_STD" "$L2_TMP/.forge/standards/global/compliance-tiers.md"
  else
    echo "# Standard — Compliance Tiers" > "$L2_TMP/.forge/standards/global/compliance-tiers.md"
  fi

  # DPA template (real copy if present, else a stub).
  if [ -f "$DPA_TEMPLATE" ]; then
    cp "$DPA_TEMPLATE" "$L2_TMP/.forge/templates/compliance/forge-dpa-declared.template"
  else
    printf '# stub DPA template\n' > "$L2_TMP/.forge/templates/compliance/forge-dpa-declared.template"
  fi

  # Minimal REVIEW.md.
  cat > "$L2_TMP/.forge/standards/REVIEW.md" <<'REV'
# Forge Standards Review Ledger

## 2026-06-22 — Initial ratification (sample)

- **Decision**: KEEP
REV

  # One archived change stub.
  cat > "$L2_TMP/.forge/changes/sample-archived/.forge.yaml" <<'CHG'
name: sample-archived
status: archived
created: 2026-06-01
parent_audit_items:
  - SAMPLE.1
timeline:
  archived: 2026-06-10
CHG

  # SBOM script (real copy if present — bundle treats "no lockfile" as non-fatal).
  if [ -f "$SBOM_SCRIPT" ]; then
    cp "$SBOM_SCRIPT" "$L2_TMP/bin/forge-sbom.sh"
    chmod +x "$L2_TMP/bin/forge-sbom.sh"
  fi

  echo "0.0.0-test" > "$L2_TMP/VERSION"

  # Regulatory artefacts (the live ones) when requested.
  if [ "$with_reg" = "1" ]; then
    mkdir -p "$L2_TMP/.forge/compliance/ai-act" "$L2_TMP/.forge/compliance/dora"
    cp "$AIACT_DIR"/* "$L2_TMP/.forge/compliance/ai-act/"
    cp "$DORA_DIR"/* "$L2_TMP/.forge/compliance/dora/"
  fi
}

_teardown_l2() {
  if [ -n "${L2_TMP:-}" ] && [ -d "$L2_TMP" ]; then
    rm -rf "$L2_TMP"
  fi
  L2_TMP=""
}

# ─── L2 tests ────────────────────────────────────────────────────

# FR-B75-BD-110 / FR-B75-BD-001 / FR-B75-BD-002 — bundle integration
_test_b75_l2_bundle_integration() {
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
  # The 6 base members are still present (additive — FR-B75-BD-002).
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
  # Every regulatory artefact is carried under regulatory/{ai-act,dora}/.
  local f reg name
  for reg in ai-act dora; do
    for f in "$L2_TMP/.forge/compliance/$reg"/*; do
      [ -f "$f" ] || continue
      name="$(basename "$f")"
      if ! printf '%s\n' "$listing" | grep -Fxq "regulatory/$reg/$name"; then
        echo "    expected regulatory member missing: regulatory/$reg/$name" >&2
        return 1
      fi
    done
  done
  # The MANIFEST lists every member (sorted sha256 lines ≥ base 5 + regulatory 8).
  local manifest_lines
  manifest_lines="$(tar -xOzf "$out" MANIFEST 2>/dev/null | grep -c '^[0-9a-f]\{64\}')"
  if [ "$manifest_lines" -lt 13 ]; then
    echo "    MANIFEST expected ≥ 13 entries (5 base + 8 regulatory), got $manifest_lines" >&2
    return 1
  fi
}

# FR-B75-BD-110 / FR-B75-BD-003 / NFR-B75-002 — determinism with regulatory members
_test_b75_l2_bundle_determinism() {
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
    echo "    extended bundles NOT byte-identical (NFR-B75-002 violation)" >&2
    return 1
  fi
}

# FR-B75-BD-111 / FR-B75-BD-004 — graceful absence
_test_b75_l2_graceful_absence() {
  _setup_l2 0
  trap '_teardown_l2' RETURN
  # No .forge/compliance/{ai-act,dora}/ in this fixture.
  local out="$L2_TMP/bundle.tgz"
  bash "$BUNDLE_SCRIPT" --target "$L2_TMP" --output "$out" >/dev/null 2>&1
  local rc=$?
  assert_eq "0" "$rc" "bundle exit code (graceful absence)" || return 1
  if [ ! -f "$out" ]; then
    echo "    bundle output not produced: $out" >&2; return 1
  fi
  local listing
  listing="$(tar -tzf "$out" 2>/dev/null | sort)"
  # Zero regulatory members.
  if printf '%s\n' "$listing" | grep -q '^regulatory/'; then
    echo "    regulatory members present despite absent source dirs" >&2
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
  echo "── B.7.5 + B.7.8 — b7-5-ai-act — level $LEVEL ──"

  # L1 always runs.
  run_test _test_b75_001_compliance_dirs_present
  run_test _test_b75_002_audit_comments
  run_test _test_b75_010_risk_classification
  run_test _test_b75_011_transparency_obligations
  run_test _test_b75_012_model_dataset_cards
  run_test _test_b75_013_aiact_obligations_index
  run_test _test_b75_020_incident_reporting
  run_test _test_b75_021_roi_register
  run_test _test_b75_022_dora_obligations_index
  run_test _test_b75_030_no_fabricated_citation
  run_test _test_b75_040_standard_presence_frontmatter
  run_test _test_b75_041_standard_h2_must_not_governance
  run_test _test_b75_050_index_review_entries
  run_test _test_b75_051_i6_standard_amended
  run_test _test_b75_060_compliance_doc_h2
  run_test _test_b75_061_changelog_entry

  # L2 runs when --level includes 2 or "all".
  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]] || [[ "$LEVEL" == "all" ]]; then
    echo ""
    echo "Phase 2: L2 — fixture-based bundle integration / determinism / graceful-absence"
    run_test _test_b75_l2_bundle_integration
    run_test _test_b75_l2_bundle_determinism
    run_test _test_b75_l2_graceful_absence
  fi

  print_summary
}

main "$@"
