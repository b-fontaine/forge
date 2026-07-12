#!/usr/bin/env bash
# Forge — K.1 Hermes-Async (Event-Driven Messenger) Test Harness (b6-4-hermes-async)
# <!-- Audit: K.1 (b6-4-hermes-async) -->
# <!-- Audit: B.6.4 (b6-4-hermes-async) -->
#
# Validates the K.1 deliverables across 2 sub-modules :
#
#   K.1.a — Hermes-Async persona file
#     - .claude/agents/hermes-async.md (persona, checklists, output, K1-RULE
#       catalogue, integration, anti-hallucination, audit cross-references)
#
#   K.1.b — CLAUDE.md + GUIDE.md registration
#     - CLAUDE.md agent-delegation row
#     - docs/GUIDE.md "Agents Transversaux" row
#
# DIVERGENCE FROM THE k3-demeter PRECEDENT (ADR-K1-003, mirrors b7-pythia
# ADR-K2-003) : Hermes-Async is a pure advisory / review-time specialist. This
# brick ships NO scanner (`bin/forge-*.sh`), NO data file (`.forge/data/*.yml`),
# NO new standard. It also edits NO Janus file and NO standards index
# (task-boundary, FR-B6-HA-083). The negative guards
# `_test_b64_014_no_new_standard` + `_test_b64_015_no_janus_index_edit` +
# `_test_b64_016_no_scanner` assert this.
#
# The three B.6.3 standards Hermes-Async consumes
# (global/event-driven.md, global/asyncapi-contracts.md, infra/nats-jetstream.md)
# are authored by the sibling `b6-3-standards` lane and are referenced BY PATH in
# the persona. This harness does NOT require them present on disk (NFR-B6-HA-004).
#
# Name-resolution (NFR-B6-HA-007) : the agent path is resolved from a single
# `HERMES_AGENT` variable (default `.claude/agents/hermes-async.md`), overridable
# by env, so the suite asserts file + anchors, not the literal name.
#
# 19 tests : 18 L1 hermetic + 1 L2 fixture-based.
# Performance : L1 ≤ 3 s (pure grep), full ≤ 5 s wall-clock (no Python, no cargo).

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

# NFR-B6-HA-007 — single name-resolution variable (ADR-K1-001 → "Hermes-Async").
HERMES_AGENT="${HERMES_AGENT:-$FORGE_ROOT_REAL/.claude/agents/hermes-async.md}"
JANUS_AGENT="$FORGE_ROOT_REAL/.claude/agents/cross-layer-orchestrator.md"
JANUS_RULES_STD="$FORGE_ROOT_REAL/.forge/standards/global/janus-orchestration-rules.md"
DEMETER_AGENT="$FORGE_ROOT_REAL/.claude/agents/demeter.md"
SIBYL_AGENT="$FORGE_ROOT_REAL/.claude/agents/sibyl.md"
STANDARDS_INDEX="$FORGE_ROOT_REAL/.forge/standards/index.yml"
STANDARDS_DIR="$FORGE_ROOT_REAL/.forge/standards"
REPO_CLAUDE_MD="$FORGE_ROOT_REAL/CLAUDE.md"
GUIDE_MD="$FORGE_ROOT_REAL/docs/GUIDE.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (18 tests)
# MANIFEST: _test_b64_001_persona_exists          — FR-B6-HA-001 file presence
# MANIFEST: _test_b64_002_audit_comment           — FR-B6-HA-010 audit comments (K.1 + B.6.4)
# MANIFEST: _test_b64_003_persona_h2              — FR-B6-HA-002/003 Persona + Purpose H2
# MANIFEST: _test_b64_004_checklists_h2           — FR-B6-HA-004 Checklists H2 + 4 H3
# MANIFEST: _test_b64_005_checklists_items        — FR-B6-HA-004 ≥ 5 [ ] items per H3
# MANIFEST: _test_b64_006_output_h2               — FR-B6-HA-005 Output: Event Contract Readiness Report
# MANIFEST: _test_b64_007_rule_catalogue          — FR-B6-HA-006/120..125 K1-RULE-001..006
# MANIFEST: _test_b64_008_idempotency_blocking    — FR-B6-HA-125 K1-RULE-006 Blocking + VIII.2
# MANIFEST: _test_b64_009_integration             — FR-B6-HA-007 Integration H2 + Janus/Hermes-API/Vulcan
# MANIFEST: _test_b64_010_anti_halluc             — FR-B6-HA-008 Anti-Hallucination + Context7
# MANIFEST: _test_b64_011_standards_consumed      — FR-B6-HA-003/020..027 three B.6.3 standards by path
# MANIFEST: _test_b64_012_claude_md_trigger       — FR-B6-HA-080 CLAUDE.md trigger row
# MANIFEST: _test_b64_013_guide_md_row            — FR-B6-HA-081 GUIDE.md agent-table row
# MANIFEST: _test_b64_014_no_new_standard         — FR-B6-HA-082 no new hermes-authored standard
# MANIFEST: _test_b64_015_no_janus_index_edit     — FR-B6-HA-083 Janus + index.yml untouched
# MANIFEST: _test_b64_016_no_scanner              — FR-B6-HA-084 / NFR-B6-HA-002 no scanner / data file
# MANIFEST: _test_b64_017_real_code_shapes        — FR-B6-HA-085 real scaffolded code shapes referenced
# MANIFEST: _test_b64_018_no_namespace_collision  — FR-B6-HA-086 K1-RULE / J8 / K2 / K3-RULE separation
#
# L2 (1 fixture test)
# MANIFEST: _test_b64_l2_anchor_integrity   — NFR-B6-HA-007 fresh-checkout anchor integrity

# ─── Helpers ────────────────────────────────────────────────────

_setup_l2() {
  L2_TMP="$(mk_tmpdir_with_trap forge-b64-l2)"
}

_teardown_l2() {
  if [ -n "${L2_TMP:-}" ] && [ -d "$L2_TMP" ]; then
    rm -rf "$L2_TMP"
  fi
}

# ─── L1 tests ───────────────────────────────────────────────────

# FR-B6-HA-001 Hermes-Async persona file exists
_test_b64_001_persona_exists() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
}

# FR-B6-HA-010 audit comments (K.1 + B.6.4) in first 6 lines
_test_b64_002_audit_comment() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  if ! head -6 "$HERMES_AGENT" | grep -q "<!-- Audit: K.1 (b6-4-hermes-async) -->"; then
    echo "    audit comment '<!-- Audit: K.1 (b6-4-hermes-async) -->' missing in first 6 lines" >&2; return 1
  fi
  if ! head -6 "$HERMES_AGENT" | grep -q "<!-- Audit: B.6.4 (b6-4-hermes-async) -->"; then
    echo "    audit comment '<!-- Audit: B.6.4 (b6-4-hermes-async) -->' missing in first 6 lines" >&2; return 1
  fi
}

# FR-B6-HA-002/003 ## Persona + ## Purpose H2 anchors
_test_b64_003_persona_h2() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Persona$" "$HERMES_AGENT"; then
    echo "    ## Persona H2 missing in $HERMES_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Purpose$" "$HERMES_AGENT"; then
    echo "    ## Purpose H2 missing in $HERMES_AGENT" >&2; return 1
  fi
}

# FR-B6-HA-004 ## Checklists + 4 H3 sub-sections
_test_b64_004_checklists_h2() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Checklists$" "$HERMES_AGENT"; then
    echo "    ## Checklists H2 missing in $HERMES_AGENT" >&2; return 1
  fi
  if ! grep -q "^### AsyncAPI Contract Maintenance$" "$HERMES_AGENT"; then
    echo "    ### AsyncAPI Contract Maintenance H3 missing" >&2; return 1
  fi
  if ! grep -q "^### NATS/Kafka Binding Generation$" "$HERMES_AGENT"; then
    echo "    ### NATS/Kafka Binding Generation H3 missing" >&2; return 1
  fi
  if ! grep -q "^### Idempotency-Key Enforcement$" "$HERMES_AGENT"; then
    echo "    ### Idempotency-Key Enforcement H3 missing" >&2; return 1
  fi
  if ! grep -q "^### Event Versioning & Compatibility$" "$HERMES_AGENT"; then
    echo "    ### Event Versioning & Compatibility H3 missing" >&2; return 1
  fi
}

# FR-B6-HA-004 ≥ 5 [ ] items per checklist sub-section
_test_b64_005_checklists_items() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  for section in "AsyncAPI Contract Maintenance" "NATS/Kafka Binding Generation" "Idempotency-Key Enforcement" "Event Versioning & Compatibility"; do
    local count
    count="$(awk -v s="### $section" '
      $0 == s {flag=1; next}
      /^### / {flag=0}
      flag && /\[ \]/ {n++}
      END {print n+0}
    ' "$HERMES_AGENT")"
    if [ "$count" -lt 5 ]; then
      echo "    H3 '$section' has only $count '[ ]' items (expected ≥ 5)" >&2; return 1
    fi
  done
}

# FR-B6-HA-005 ## Output: Event Contract Readiness Report H2 + Summary table
_test_b64_006_output_h2() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Output: Event Contract Readiness Report$" "$HERMES_AGENT"; then
    echo "    ## Output: Event Contract Readiness Report H2 missing" >&2; return 1
  fi
  if ! grep -q "| Severity |" "$HERMES_AGENT"; then
    echo "    Severity summary table missing" >&2; return 1
  fi
}

# FR-B6-HA-006 / 120..125 ## Recommendation Catalogue + K1-RULE-001..006
_test_b64_007_rule_catalogue() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Recommendation Catalogue$" "$HERMES_AGENT"; then
    echo "    ## Recommendation Catalogue H2 missing" >&2; return 1
  fi
  for rule in K1-RULE-001 K1-RULE-002 K1-RULE-003 K1-RULE-004 K1-RULE-005 K1-RULE-006; do
    if ! grep -q "$rule" "$HERMES_AGENT"; then
      echo "    $rule anchor missing in $HERMES_AGENT" >&2; return 1
    fi
  done
}

# FR-B6-HA-125 K1-RULE-006 present + Blocking severity + VIII.2 reference
_test_b64_008_idempotency_blocking() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  if ! grep "K1-RULE-006" "$HERMES_AGENT" | grep -q "Blocking"; then
    echo "    K1-RULE-006 not marked Blocking" >&2; return 1
  fi
  if ! grep "K1-RULE-006" "$HERMES_AGENT" | grep -q "VIII.2"; then
    echo "    K1-RULE-006 does not cite VIII.2" >&2; return 1
  fi
}

# FR-B6-HA-007 ## Integration H2 + Janus / Hermes-API / Vulcan mentions
_test_b64_009_integration() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Integration$" "$HERMES_AGENT"; then
    echo "    ## Integration H2 missing" >&2; return 1
  fi
  if ! grep -q "cross-layer-orchestrator" "$HERMES_AGENT"; then
    echo "    cross-layer-orchestrator reference missing" >&2; return 1
  fi
  if ! grep -q "Hermes-API" "$HERMES_AGENT"; then
    echo "    Hermes-API relationship missing" >&2; return 1
  fi
  if ! grep -q "Vulcan" "$HERMES_AGENT"; then
    echo "    Vulcan relationship missing" >&2; return 1
  fi
}

# FR-B6-HA-008 ## Anti-Hallucination Protocol H2 + [NEEDS CLARIFICATION: + Context7
_test_b64_010_anti_halluc() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Anti-Hallucination Protocol$" "$HERMES_AGENT"; then
    echo "    ## Anti-Hallucination Protocol H2 missing" >&2; return 1
  fi
  if ! grep -q "\[NEEDS CLARIFICATION:" "$HERMES_AGENT"; then
    echo "    [NEEDS CLARIFICATION: marker mention missing" >&2; return 1
  fi
  if ! grep -q "Context7" "$HERMES_AGENT"; then
    echo "    Context7 LIVE-verification mandate missing" >&2; return 1
  fi
}

# FR-B6-HA-003 / 020..027 persona references all three B.6.3 standards by path
_test_b64_011_standards_consumed() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  for std in "event-driven.md" "asyncapi-contracts.md" "nats-jetstream.md"; do
    if ! grep -q "$std" "$HERMES_AGENT"; then
      echo "    B.6.3 standard reference missing: $std" >&2; return 1
    fi
  done
}

# FR-B6-HA-080 repo CLAUDE.md trigger row contains the Hermes-Async row
_test_b64_012_claude_md_trigger() {
  if [ ! -f "$REPO_CLAUDE_MD" ]; then
    echo "    repo CLAUDE.md missing: $REPO_CLAUDE_MD" >&2; return 1
  fi
  if ! grep -q "| Event-driven / AsyncAPI | \*\*Hermes-Async\*\* | Event-Driven Messenger |" "$REPO_CLAUDE_MD"; then
    echo "    Hermes-Async delegation row missing in $REPO_CLAUDE_MD" >&2; return 1
  fi
}

# FR-B6-HA-081 docs/GUIDE.md "Agents Transversaux" row contains Hermes-Async
_test_b64_013_guide_md_row() {
  if [ ! -f "$GUIDE_MD" ]; then
    echo "    docs/GUIDE.md missing: $GUIDE_MD" >&2; return 1
  fi
  if ! grep -q "| Event-Driven Messenger | Hermes-Async |" "$GUIDE_MD"; then
    echo "    Hermes-Async row missing in $GUIDE_MD agent table" >&2; return 1
  fi
}

# FR-B6-HA-082 no NEW hermes-authored standard (ownership by reference)
_test_b64_014_no_new_standard() {
  # Hermes-Async consumes the three b6-3 standards by reference. This change MUST
  # NOT author a new standard (e.g. no hermes-async-rules.md, no event-driven-rules.md).
  # Guard against task-creep toward K.3's data-stewardship-rules.md shape. NOTE: this
  # does NOT require the b6-3 standards to exist (they arrive via the sibling lane).
  for forbidden in "$STANDARDS_DIR/global/hermes-async-rules.md" \
                   "$STANDARDS_DIR/global/hermes-rules.md" \
                   "$STANDARDS_DIR/global/event-driven-rules.md" \
                   "$STANDARDS_DIR/global/asyncapi-rules.md"; do
    if [ -f "$forbidden" ]; then
      echo "    forbidden new standard authored: $forbidden (ADR-K1-003 — consumes b6-3 by reference)" >&2; return 1
    fi
  done
}

# FR-B6-HA-083 Janus + standards-index NOT edited by this change (task-boundary)
_test_b64_015_no_janus_index_edit() {
  # Divergence from b7-pythia: this brick wires NO Janus dispatch row and NO index
  # trigger. The persona may DESCRIBE Janus routing, but the Janus file itself must
  # not gain a Hermes-Async dispatch row, and index.yml must not gain a hermes-async
  # entry OF ITS OWN. Sibling standards (b6-3, global/event-driven.md and
  # global/asyncapi-contracts.md) legitimately cite "hermes-async" inside their own
  # `triggers: [...]` list — that's the standard describing its consumer, not this
  # change editing index.yml — so only an `id:`/`path:` field naming hermes-async
  # (i.e. a whole new entry authored BY this change) counts as a violation.
  if [ -f "$JANUS_AGENT" ] && grep -q "Hermes-Async" "$JANUS_AGENT"; then
    echo "    Janus edited (Hermes-Async row present in $JANUS_AGENT — out of scope, FR-B6-HA-083)" >&2; return 1
  fi
  if [ -f "$STANDARDS_INDEX" ] && grep -Eiq '^\s*-?\s*(id|path)\s*:.*hermes-async' "$STANDARDS_INDEX"; then
    echo "    standards index edited (hermes-async id/path entry in $STANDARDS_INDEX — out of scope, FR-B6-HA-083)" >&2; return 1
  fi
}

# FR-B6-HA-084 / NFR-B6-HA-002 no scanner script + no data file (advisory-only)
_test_b64_016_no_scanner() {
  for s in "$FORGE_ROOT_REAL"/bin/forge-hermes*.sh "$FORGE_ROOT_REAL"/bin/forge-async*.sh; do
    if [ -e "$s" ]; then
      echo "    forbidden scanner script present: $s (ADR-K1-003 — advisory only)" >&2; return 1
    fi
  done
  for d in "$FORGE_ROOT_REAL"/.forge/data/hermes*.yml "$FORGE_ROOT_REAL"/.forge/data/async*.yml; do
    if [ -e "$d" ]; then
      echo "    forbidden data file present: $d (ADR-K1-003 — advisory only)" >&2; return 1
    fi
  done
}

# FR-B6-HA-085 persona references the real scaffolded code shapes (not generic advice)
_test_b64_017_real_code_shapes() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  if ! grep -q "EventEnvelope" "$HERMES_AGENT"; then
    echo "    real code shape 'EventEnvelope' not referenced" >&2; return 1
  fi
  if ! grep -q "Nats-Msg-Id" "$HERMES_AGENT"; then
    echo "    real code shape 'Nats-Msg-Id' not referenced" >&2; return 1
  fi
  if ! grep -q "idempotency_key" "$HERMES_AGENT"; then
    echo "    real code shape 'idempotency_key' not referenced" >&2; return 1
  fi
  if ! grep -q "events\.v" "$HERMES_AGENT"; then
    echo "    real code shape 'events.v<version>.<EventType>' subject namespacing not referenced" >&2; return 1
  fi
}

# FR-B6-HA-086 K1-RULE never appears in J8/K2/K3 surfaces (and vice-versa)
_test_b64_018_no_namespace_collision() {
  # K1-RULE must NOT leak into the Janus agent, the J.8 standard, the Demeter
  # persona, or the Sibyl persona (disjoint namespaces).
  for surface in "$JANUS_AGENT" "$JANUS_RULES_STD" "$DEMETER_AGENT" "$SIBYL_AGENT"; do
    if [ -f "$surface" ] && grep -q "K1-RULE" "$surface" 2>/dev/null; then
      echo "    K1-RULE leaked into $surface" >&2; return 1
    fi
  done
  # J8-RULE / K2-RULE / K3-RULE must NOT be over-cited in the Hermes persona
  # (≤ 2 cross-link acknowledgements each).
  if [ -f "$HERMES_AGENT" ]; then
    local n
    for ns in J8-RULE K2-RULE K3-RULE; do
      # grep -c prints a count (0 when none) even on exit 1; capture it without a
      # second `echo 0` (which would produce a two-line "0\n0" and break `[ -gt ]`).
      n="$(grep -c "$ns" "$HERMES_AGENT" 2>/dev/null)" || true
      if [ "$n" -gt 2 ]; then
        echo "    $ns over-cited in $HERMES_AGENT ($n hits, expected ≤ 2 cross-links)" >&2; return 1
      fi
    done
  fi
}

# ─── L2 test ────────────────────────────────────────────────────

# NFR-B6-HA-007 — copy $HERMES_AGENT into a tmpdir, re-run the L1 anchor greps
# against the isolated copy (fresh-checkout simulation — proves the persona is
# self-contained, no scanner needed).
_test_b64_l2_anchor_integrity() {
  if [ ! -f "$HERMES_AGENT" ]; then
    echo "    persona file missing: $HERMES_AGENT" >&2; return 1
  fi
  _setup_l2
  trap '_teardown_l2' RETURN
  local copy="$L2_TMP/hermes-async.md"
  cp "$HERMES_AGENT" "$copy"
  for anchor in \
    "^## Persona$" \
    "^## Purpose$" \
    "^## Checklists$" \
    "^### AsyncAPI Contract Maintenance$" \
    "^### NATS/Kafka Binding Generation$" \
    "^### Idempotency-Key Enforcement$" \
    "^### Event Versioning & Compatibility$" \
    "^## Output: Event Contract Readiness Report$" \
    "^## Recommendation Catalogue$" \
    "^## Integration$" \
    "^## Anti-Hallucination Protocol$"; do
    if ! grep -q "$anchor" "$copy"; then
      echo "    anchor '$anchor' missing on isolated copy" >&2; return 1
    fi
  done
  for rule in K1-RULE-001 K1-RULE-002 K1-RULE-003 K1-RULE-004 K1-RULE-005 K1-RULE-006; do
    if ! grep -q "$rule" "$copy"; then
      echo "    rule '$rule' missing on isolated copy" >&2; return 1
    fi
  done
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── K.1 — b6-4-hermes-async (Hermes-Async) harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — persona + CLAUDE.md + GUIDE.md + guards"
  run_test _test_b64_001_persona_exists
  run_test _test_b64_002_audit_comment
  run_test _test_b64_003_persona_h2
  run_test _test_b64_004_checklists_h2
  run_test _test_b64_005_checklists_items
  run_test _test_b64_006_output_h2
  run_test _test_b64_007_rule_catalogue
  run_test _test_b64_008_idempotency_blocking
  run_test _test_b64_009_integration
  run_test _test_b64_010_anti_halluc
  run_test _test_b64_011_standards_consumed
  run_test _test_b64_012_claude_md_trigger
  run_test _test_b64_013_guide_md_row
  run_test _test_b64_014_no_new_standard
  run_test _test_b64_015_no_janus_index_edit
  run_test _test_b64_016_no_scanner
  run_test _test_b64_017_real_code_shapes
  run_test _test_b64_018_no_namespace_collision

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — fresh-checkout anchor integrity"
    run_test _test_b64_l2_anchor_integrity
  fi

  print_summary
}

main "$@"
