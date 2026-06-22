#!/usr/bin/env bash
# Forge — K.2 Sibyl (AI/RAG Specialist) Test Harness (b7-pythia)
# <!-- Audit: K.2 (b7-pythia) -->
# <!-- Audit: B.7.4 (b7-pythia) -->
#
# Validates the K.2 deliverables across 3 sub-modules :
#
#   K.2.a — Sibyl persona file
#     - .claude/agents/sibyl.md (persona, checklists, output, rules,
#       integration, anti-hallucination, audit cross-references)
#
#   K.2.b — Standards-index additive triggers (NO new standard)
#     - .forge/standards/index.yml (rag-patterns / llm-gateway / mcp-servers
#       triggers extended with the Sibyl keyword — no new entry, no new file)
#
#   K.2.c — Janus + CLAUDE.md integration
#     - .claude/agents/cross-layer-orchestrator.md (Dispatch Table row +
#       Step 3 ai-native-rag note + Quality Gates bullet — delta, ADR-K2-004)
#     - CLAUDE.md trigger row
#
# DIVERGENCE FROM THE k3-demeter PRECEDENT (ADR-K2-003) : Sibyl is a pure
# advisory / tuning specialist. This brick ships NO scanner (`bin/forge-*.sh`),
# NO data file (`.forge/data/*.yml`), NO new standard. The negative guards
# `_test_b7p_013_no_new_standard` + `_test_b7p_018_no_scanner` assert this.
#
# Name-resolution (NFR-K2-PYT-007) : the agent path is resolved from a single
# `PYTHIA_AGENT` variable (default `.claude/agents/sibyl.md`, the ADR-K2-001
# ratified path — Q-001 resolved to "Sibyl"), overridable by env, so the suite
# asserts file + anchors, not the literal name.
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

# NFR-K2-PYT-007 — single name-resolution variable (ADR-K2-001 → "Sibyl").
PYTHIA_AGENT="${PYTHIA_AGENT:-$FORGE_ROOT_REAL/.claude/agents/sibyl.md}"
JANUS_AGENT="$FORGE_ROOT_REAL/.claude/agents/cross-layer-orchestrator.md"
JANUS_RULES_STD="$FORGE_ROOT_REAL/.forge/standards/global/janus-orchestration-rules.md"
DEMETER_AGENT="$FORGE_ROOT_REAL/.claude/agents/demeter.md"
STANDARDS_INDEX="$FORGE_ROOT_REAL/.forge/standards/index.yml"
STANDARDS_GLOBAL_DIR="$FORGE_ROOT_REAL/.forge/standards/global"
REPO_CLAUDE_MD="$FORGE_ROOT_REAL/CLAUDE.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (18 tests)
# MANIFEST: _test_b7p_001_persona_exists          — FR-K2-PYT-001 file presence
# MANIFEST: _test_b7p_002_audit_comment           — FR-K2-PYT-010 audit comments (K.2 + B.7.4)
# MANIFEST: _test_b7p_003_persona_h2              — FR-K2-PYT-002/003 Persona + Purpose H2
# MANIFEST: _test_b7p_004_checklists_h2           — FR-K2-PYT-004 Checklists H2 + 4 H3
# MANIFEST: _test_b7p_005_checklists_items        — FR-K2-PYT-004 ≥ 5 [ ] items per H3
# MANIFEST: _test_b7p_006_output_h2               — FR-K2-PYT-005 Output: RAG Readiness Report
# MANIFEST: _test_b7p_007_rule_catalogue          — FR-K2-PYT-006/120..125 K2-RULE-001..006
# MANIFEST: _test_b7p_008_fallback_blocking       — FR-K2-PYT-125 K2-RULE-006 Blocking + XI.5
# MANIFEST: _test_b7p_009_integration             — FR-K2-PYT-007 Integration H2 + Janus/Oracle/Demeter
# MANIFEST: _test_b7p_010_anti_halluc             — FR-K2-PYT-008 Anti-Hallucination Protocol
# MANIFEST: _test_b7p_011_standards_consumed      — FR-K2-PYT-003/020..027 three b7-standards referenced
# MANIFEST: _test_b7p_012_index_triggers          — FR-K2-PYT-080 index.yml triggers extended
# MANIFEST: _test_b7p_013_no_new_standard         — FR-K2-PYT-081 no new global/*.md standard
# MANIFEST: _test_b7p_014_janus_dispatch_row      — FR-K2-PYT-082 Janus dispatch row
# MANIFEST: _test_b7p_015_janus_step3_note        — FR-K2-PYT-083 Step 3 note + Step 9 UNCHANGED guard
# MANIFEST: _test_b7p_016_claude_md_trigger       — FR-K2-PYT-084 CLAUDE.md trigger row
# MANIFEST: _test_b7p_017_no_namespace_collision  — FR-K2-PYT-086 K2-RULE / J8-RULE / K3-RULE separation
# MANIFEST: _test_b7p_018_no_scanner              — NFR-K2-PYT-002 / ADR-K2-003 no scanner / data file
#
# L2 (1 fixture test)
# MANIFEST: _test_b7p_l2_anchor_integrity   — NFR-K2-PYT-007 fresh-checkout anchor integrity

# ─── Helpers ────────────────────────────────────────────────────

_setup_l2() {
  L2_TMP="$(mk_tmpdir_with_trap forge-b7p-l2)"
}

_teardown_l2() {
  if [ -n "${L2_TMP:-}" ] && [ -d "$L2_TMP" ]; then
    rm -rf "$L2_TMP"
  fi
}

_not_implemented() {
  echo "    not implemented (RED witness — pending implementation tasks)" >&2
  return 1
}

# ─── L1 stubs ───────────────────────────────────────────────────

# FR-K2-PYT-001 Sibyl persona file exists
_test_b7p_001_persona_exists() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
}

# FR-K2-PYT-010 audit comments (K.2 + B.7.4) in first 6 lines
_test_b7p_002_audit_comment() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  if ! head -6 "$PYTHIA_AGENT" | grep -q "<!-- Audit: K.2 (b7-pythia) -->"; then
    echo "    audit comment '<!-- Audit: K.2 (b7-pythia) -->' missing in first 6 lines" >&2; return 1
  fi
  if ! head -6 "$PYTHIA_AGENT" | grep -q "<!-- Audit: B.7.4 (b7-pythia) -->"; then
    echo "    audit comment '<!-- Audit: B.7.4 (b7-pythia) -->' missing in first 6 lines" >&2; return 1
  fi
}

# FR-K2-PYT-002/003 ## Persona + ## Purpose H2 anchors
_test_b7p_003_persona_h2() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Persona$" "$PYTHIA_AGENT"; then
    echo "    ## Persona H2 missing in $PYTHIA_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Purpose$" "$PYTHIA_AGENT"; then
    echo "    ## Purpose H2 missing in $PYTHIA_AGENT" >&2; return 1
  fi
}

# FR-K2-PYT-004 ## Checklists + 4 H3 sub-sections
_test_b7p_004_checklists_h2() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Checklists$" "$PYTHIA_AGENT"; then
    echo "    ## Checklists H2 missing in $PYTHIA_AGENT" >&2; return 1
  fi
  if ! grep -q "^### Embeddings & Retrieval$" "$PYTHIA_AGENT"; then
    echo "    ### Embeddings & Retrieval H3 missing" >&2; return 1
  fi
  if ! grep -q "^### pgvector HNSW Tuning$" "$PYTHIA_AGENT"; then
    echo "    ### pgvector HNSW Tuning H3 missing" >&2; return 1
  fi
  if ! grep -q "^### MCP Server Hardening$" "$PYTHIA_AGENT"; then
    echo "    ### MCP Server Hardening H3 missing" >&2; return 1
  fi
  if ! grep -q "^### Prompt Audit & Fallback$" "$PYTHIA_AGENT"; then
    echo "    ### Prompt Audit & Fallback H3 missing" >&2; return 1
  fi
}

# FR-K2-PYT-004 ≥ 5 [ ] items per checklist sub-section
_test_b7p_005_checklists_items() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  for section in "Embeddings & Retrieval" "pgvector HNSW Tuning" "MCP Server Hardening" "Prompt Audit & Fallback"; do
    local count
    count="$(awk -v s="### $section" '
      $0 == s {flag=1; next}
      /^### / {flag=0}
      flag && /\[ \]/ {n++}
      END {print n+0}
    ' "$PYTHIA_AGENT")"
    if [ "$count" -lt 5 ]; then
      echo "    H3 '$section' has only $count '[ ]' items (expected ≥ 5)" >&2; return 1
    fi
  done
}

# FR-K2-PYT-005 ## Output: RAG Readiness Report H2 + Summary table
_test_b7p_006_output_h2() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Output: RAG Readiness Report$" "$PYTHIA_AGENT"; then
    echo "    ## Output: RAG Readiness Report H2 missing" >&2; return 1
  fi
  if ! grep -q "| Severity |" "$PYTHIA_AGENT"; then
    echo "    Severity summary table missing" >&2; return 1
  fi
}

# FR-K2-PYT-006 / 120..125 ## Recommendation Catalogue + K2-RULE-001..006
_test_b7p_007_rule_catalogue() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Recommendation Catalogue$" "$PYTHIA_AGENT"; then
    echo "    ## Recommendation Catalogue H2 missing" >&2; return 1
  fi
  for rule in K2-RULE-001 K2-RULE-002 K2-RULE-003 K2-RULE-004 K2-RULE-005 K2-RULE-006; do
    if ! grep -q "$rule" "$PYTHIA_AGENT"; then
      echo "    $rule anchor missing in $PYTHIA_AGENT" >&2; return 1
    fi
  done
}

# FR-K2-PYT-125 K2-RULE-006 present + Blocking severity + XI.5 reference
_test_b7p_008_fallback_blocking() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  # The K2-RULE-006 row must carry both 'Blocking' and an 'XI.5' reference.
  if ! grep "K2-RULE-006" "$PYTHIA_AGENT" | grep -q "Blocking"; then
    echo "    K2-RULE-006 not marked Blocking" >&2; return 1
  fi
  if ! grep "K2-RULE-006" "$PYTHIA_AGENT" | grep -q "XI.5"; then
    echo "    K2-RULE-006 does not cite XI.5" >&2; return 1
  fi
}

# FR-K2-PYT-007 ## Integration H2 + Janus / Oracle / Demeter mentions
_test_b7p_009_integration() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Integration$" "$PYTHIA_AGENT"; then
    echo "    ## Integration H2 missing" >&2; return 1
  fi
  if ! grep -q "cross-layer-orchestrator" "$PYTHIA_AGENT"; then
    echo "    cross-layer-orchestrator reference missing" >&2; return 1
  fi
  if ! grep -q "Oracle" "$PYTHIA_AGENT"; then
    echo "    Oracle relationship missing" >&2; return 1
  fi
  if ! grep -q "Demeter" "$PYTHIA_AGENT"; then
    echo "    Demeter relationship missing" >&2; return 1
  fi
}

# FR-K2-PYT-008 ## Anti-Hallucination Protocol H2 + [NEEDS CLARIFICATION:
_test_b7p_010_anti_halluc() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Anti-Hallucination Protocol$" "$PYTHIA_AGENT"; then
    echo "    ## Anti-Hallucination Protocol H2 missing" >&2; return 1
  fi
  if ! grep -q "\[NEEDS CLARIFICATION:" "$PYTHIA_AGENT"; then
    echo "    [NEEDS CLARIFICATION: marker mention missing" >&2; return 1
  fi
}

# FR-K2-PYT-003 / 020..027 persona references all three b7-standards
_test_b7p_011_standards_consumed() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  for std in "rag-patterns" "llm-gateway" "mcp-servers"; do
    if ! grep -q "$std" "$PYTHIA_AGENT"; then
      echo "    b7-standard reference missing: $std" >&2; return 1
    fi
  done
}

# FR-K2-PYT-080 index.yml rag-patterns/llm-gateway/mcp-servers triggers extended
_test_b7p_012_index_triggers() {
  if [ ! -f "$STANDARDS_INDEX" ]; then
    echo "    standards index missing: $STANDARDS_INDEX" >&2; return 1
  fi
  # Each of the three B.7.3 entries must carry the 'sibyl' trigger keyword
  # within its 5-line block.
  for entry in "global/rag-patterns" "global/llm-gateway" "global/mcp-servers"; do
    if ! grep -A 5 "id: $entry" "$STANDARDS_INDEX" | grep -q "sibyl"; then
      echo "    'sibyl' trigger missing on $entry entry" >&2; return 1
    fi
  done
  # rag-patterns also gains the ef-search + embeddings-tuning tuning keywords.
  if ! grep -A 5 "id: global/rag-patterns" "$STANDARDS_INDEX" | grep -q "ef-search"; then
    echo "    'ef-search' trigger missing on rag-patterns entry" >&2; return 1
  fi
  if ! grep -A 5 "id: global/rag-patterns" "$STANDARDS_INDEX" | grep -q "embeddings-tuning"; then
    echo "    'embeddings-tuning' trigger missing on rag-patterns entry" >&2; return 1
  fi
}

# FR-K2-PYT-081 no NEW global/*.md standard authored by this change
_test_b7p_013_no_new_standard() {
  # Sibyl owns the three pre-existing b7-standards by reference. This change
  # MUST NOT author a new global/*.md standard (e.g. no rag-tuning-rules.md,
  # no sibyl-rules.md, no ai-rag-*.md). Guard against task-creep toward K.3's
  # data-stewardship-rules.md shape.
  for forbidden in "$STANDARDS_GLOBAL_DIR/sibyl-rules.md" \
                   "$STANDARDS_GLOBAL_DIR/pythia-rules.md" \
                   "$STANDARDS_GLOBAL_DIR/rag-tuning-rules.md" \
                   "$STANDARDS_GLOBAL_DIR/ai-rag-rules.md"; do
    if [ -f "$forbidden" ]; then
      echo "    forbidden new standard authored: $forbidden (ADR-K2-005 — additive triggers only)" >&2; return 1
    fi
  done
  # The three b7-standards Sibyl consumes MUST exist (ownership by reference).
  for std in rag-patterns llm-gateway mcp-servers; do
    if [ ! -f "$STANDARDS_GLOBAL_DIR/$std.md" ]; then
      echo "    expected pre-existing b7-standard missing: $std.md" >&2; return 1
    fi
  done
}

# FR-K2-PYT-082 Janus Dispatch Table contains the Sibyl AI/RAG row
_test_b7p_014_janus_dispatch_row() {
  if [ ! -f "$JANUS_AGENT" ]; then
    echo "    janus agent missing: $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -q "AI/RAG specialist work on" "$JANUS_AGENT"; then
    echo "    Sibyl AI/RAG dispatch row missing in $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -q "\*\*Sibyl\*\*" "$JANUS_AGENT"; then
    echo "    Sibyl agent name not bolded in dispatch row" >&2; return 1
  fi
}

# FR-K2-PYT-083 Step 3 ai-native-rag note + Step 9 Demeter narrative UNCHANGED
_test_b7p_015_janus_step3_note() {
  if [ ! -f "$JANUS_AGENT" ]; then
    echo "    janus agent missing: $JANUS_AGENT" >&2; return 1
  fi
  # Step 3 H3 gains an ai-native-rag Sibyl design-pass note.
  local step3_block
  step3_block="$(awk '
    /^### Step 3 — / {flag=1}
    /^### Step 4 — / {flag=0}
    flag {print}
  ' "$JANUS_AGENT")"
  if ! printf '%s' "$step3_block" | grep -q "ai-native-rag"; then
    echo "    Step 3 ai-native-rag note missing" >&2; return 1
  fi
  if ! printf '%s' "$step3_block" | grep -q "Sibyl"; then
    echo "    Step 3 Sibyl reference missing" >&2; return 1
  fi
  # COLLISION GUARD (NFR-K2-PYT-006) : the Step 9 Demeter narrative must be
  # byte-unchanged — Sibyl never touches Step 9 (b7-9-janus-ai territory is the
  # Forbidden catalogue ; Step 9 is Aegis + Demeter, owned by k3-demeter).
  if ! grep -q "^### Step 9 — Security & Data-Stewardship Pass (Aegis + Demeter)$" "$JANUS_AGENT"; then
    echo "    Step 9 Demeter narrative altered (must stay unchanged — collision guard)" >&2; return 1
  fi
  # Sibyl must NOT leak into the Step 9 block.
  local step9_block
  step9_block="$(awk '
    /^### Step 9 — / {flag=1}
    /^### Step 10 — / {flag=0}
    flag {print}
  ' "$JANUS_AGENT")"
  if printf '%s' "$step9_block" | grep -q "Sibyl"; then
    echo "    Sibyl leaked into Step 9 (must stay in Step 3 — collision guard)" >&2; return 1
  fi
}

# FR-K2-PYT-084 repo CLAUDE.md trigger row contains the AI/RAG specialist
_test_b7p_016_claude_md_trigger() {
  if [ ! -f "$REPO_CLAUDE_MD" ]; then
    echo "    repo CLAUDE.md missing: $REPO_CLAUDE_MD" >&2; return 1
  fi
  if ! grep -q "| AI/RAG tuning | \*\*Sibyl\*\* | AI/RAG Specialist |" "$REPO_CLAUDE_MD"; then
    echo "    Sibyl AI/RAG trigger row missing in $REPO_CLAUDE_MD" >&2; return 1
  fi
}

# FR-K2-PYT-086 K2-RULE never appears in J8/K3 surfaces (and vice-versa)
_test_b7p_017_no_namespace_collision() {
  # K2-RULE must NOT leak into the Janus agent file, the J.8 standard, or the
  # Demeter persona (rule-body leakage check — disjoint namespaces).
  if grep -q "K2-RULE" "$JANUS_AGENT" 2>/dev/null; then
    echo "    K2-RULE leaked into $JANUS_AGENT" >&2; return 1
  fi
  if [ -f "$JANUS_RULES_STD" ] && grep -q "K2-RULE" "$JANUS_RULES_STD" 2>/dev/null; then
    echo "    K2-RULE leaked into $JANUS_RULES_STD" >&2; return 1
  fi
  if [ -f "$DEMETER_AGENT" ] && grep -q "K2-RULE" "$DEMETER_AGENT" 2>/dev/null; then
    echo "    K2-RULE leaked into $DEMETER_AGENT" >&2; return 1
  fi
  # J8-RULE / K3-RULE must NOT appear in the Sibyl persona except as a bounded
  # cross-link acknowledgement (≤ 2 occurrences each).
  if [ -f "$PYTHIA_AGENT" ]; then
    local nj nk
    nj="$(grep -c "J8-RULE" "$PYTHIA_AGENT" 2>/dev/null || echo 0)"
    nk="$(grep -c "K3-RULE" "$PYTHIA_AGENT" 2>/dev/null || echo 0)"
    if [ "$nj" -gt 2 ]; then
      echo "    J8-RULE over-cited in $PYTHIA_AGENT ($nj hits, expected ≤ 2 cross-links)" >&2; return 1
    fi
    if [ "$nk" -gt 2 ]; then
      echo "    K3-RULE over-cited in $PYTHIA_AGENT ($nk hits, expected ≤ 2 cross-links)" >&2; return 1
    fi
  fi
}

# NFR-K2-PYT-002 / ADR-K2-003 no scanner script + no data file (advisory-only)
_test_b7p_018_no_scanner() {
  # ADR-K2-003 : Sibyl is a pure advisory agent. No executable scanner, no
  # data file. Guard against task-creep toward the k3-demeter scanner shape.
  for s in "$FORGE_ROOT_REAL"/bin/forge-pythia*.sh "$FORGE_ROOT_REAL"/bin/forge-sibyl*.sh; do
    if [ -e "$s" ]; then
      echo "    forbidden scanner script present: $s (ADR-K2-003 — advisory only)" >&2; return 1
    fi
  done
  for d in "$FORGE_ROOT_REAL"/.forge/data/pythia*.yml "$FORGE_ROOT_REAL"/.forge/data/sibyl*.yml; do
    if [ -e "$d" ]; then
      echo "    forbidden data file present: $d (ADR-K2-003 — advisory only)" >&2; return 1
    fi
  done
}

# ─── L2 stubs ───────────────────────────────────────────────────

# NFR-K2-PYT-007 — copy $PYTHIA_AGENT into a tmpdir, re-run the L1 anchor greps
# against the isolated copy (fresh-checkout simulation — proves the persona is
# self-contained, no scanner needed).
_test_b7p_l2_anchor_integrity() {
  if [ ! -f "$PYTHIA_AGENT" ]; then
    echo "    persona file missing: $PYTHIA_AGENT" >&2; return 1
  fi
  _setup_l2
  trap '_teardown_l2' RETURN
  local copy="$L2_TMP/sibyl.md"
  cp "$PYTHIA_AGENT" "$copy"
  # Re-run the structural anchor greps against the isolated copy — proves the
  # persona is self-contained (no scanner, no repo-relative state needed).
  for anchor in \
    "^## Persona$" \
    "^## Purpose$" \
    "^## Checklists$" \
    "^### Embeddings & Retrieval$" \
    "^### pgvector HNSW Tuning$" \
    "^### MCP Server Hardening$" \
    "^### Prompt Audit & Fallback$" \
    "^## Output: RAG Readiness Report$" \
    "^## Recommendation Catalogue$" \
    "^## Integration$" \
    "^## Anti-Hallucination Protocol$"; do
    if ! grep -q "$anchor" "$copy"; then
      echo "    anchor '$anchor' missing on isolated copy" >&2; return 1
    fi
  done
  for rule in K2-RULE-001 K2-RULE-002 K2-RULE-003 K2-RULE-004 K2-RULE-005 K2-RULE-006; do
    if ! grep -q "$rule" "$copy"; then
      echo "    rule '$rule' missing on isolated copy" >&2; return 1
    fi
  done
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "── K.2 — b7-pythia (Sibyl) harness (level $LEVEL) ──"
  echo ""
  echo "Phase 1: L1 — persona + index + Janus + integration anchors"
  run_test _test_b7p_001_persona_exists
  run_test _test_b7p_002_audit_comment
  run_test _test_b7p_003_persona_h2
  run_test _test_b7p_004_checklists_h2
  run_test _test_b7p_005_checklists_items
  run_test _test_b7p_006_output_h2
  run_test _test_b7p_007_rule_catalogue
  run_test _test_b7p_008_fallback_blocking
  run_test _test_b7p_009_integration
  run_test _test_b7p_010_anti_halluc
  run_test _test_b7p_011_standards_consumed
  run_test _test_b7p_012_index_triggers
  run_test _test_b7p_013_no_new_standard
  run_test _test_b7p_014_janus_dispatch_row
  run_test _test_b7p_015_janus_step3_note
  run_test _test_b7p_016_claude_md_trigger
  run_test _test_b7p_017_no_namespace_collision
  run_test _test_b7p_018_no_scanner

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — fresh-checkout anchor integrity"
    run_test _test_b7p_l2_anchor_integrity
  fi

  print_summary
}

main "$@"
