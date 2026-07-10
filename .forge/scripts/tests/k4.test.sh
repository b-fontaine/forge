#!/usr/bin/env bash
# Forge — K.4 Iris-Web Test Harness (k4-iris-web)
# <!-- Audit: K.4 (k4-iris-web) -->
#
# Validates the K.4 deliverables across 3 sub-modules :
#
#   K.4.a — Iris-Web persona file
#     - .claude/agents/iris-web.md (persona, checklists, output, rules,
#       integration, anti-hallucination, audit cross-references)
#
#   K.4.b — Qwik frontend patterns standard
#     - .forge/standards/global/qwik-frontend-patterns.md
#       (resumability, routes, SSR/SSG, Connect-ES, streaming, components,
#        Vitest ; references web-frontend.yaml for pins — never copies)
#
#   K.4.c — Standards + dispatch integration
#     - .forge/standards/index.yml (registration)
#     - .claude/agents/cross-layer-orchestrator.md (additive Janus row)
#     - CLAUDE.md trigger row (Hera's row untouched)
#
# 22 tests : 20 L1 hermetic + 2 L2 cross-surface.
# Performance : L1 <= 5 s, full <= 20 s wall-clock.

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

IRIS_AGENT="$FORGE_ROOT_REAL/.claude/agents/iris-web.md"
JANUS_AGENT="$FORGE_ROOT_REAL/.claude/agents/cross-layer-orchestrator.md"
QWIK_STD="$FORGE_ROOT_REAL/.forge/standards/global/qwik-frontend-patterns.md"
WEB_FRONTEND_YAML="$FORGE_ROOT_REAL/.forge/standards/web-frontend.yaml"
STANDARDS_INDEX="$FORGE_ROOT_REAL/.forge/standards/index.yml"
REPO_CLAUDE_MD="$FORGE_ROOT_REAL/CLAUDE.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ─── Manifest ────────────────────────────────────────────────────
#
# L1 (20 tests)
# MANIFEST: _test_k4_001_persona_exists                    — FR-K4-IW-001 file presence
# MANIFEST: _test_k4_002_audit_comment                     — FR-K4-IW-010 audit comment
# MANIFEST: _test_k4_003_persona_h2                        — FR-K4-IW-002/003 Persona+Purpose H2
# MANIFEST: _test_k4_004_checklists_h2                     — FR-K4-IW-004 Checklists H2 + 4 H3
# MANIFEST: _test_k4_005_checklists_items                  — FR-K4-IW-004 >= 5 [ ] items per H3
# MANIFEST: _test_k4_006_output_h2                         — FR-K4-IW-005 Output: Web Frontend Readiness Report
# MANIFEST: _test_k4_007_rule_catalogue                    — FR-K4-IW-006/120..125 K4-RULE-001..006
# MANIFEST: _test_k4_008_integration                       — FR-K4-IW-007 Integration H2 + Janus + Hera
# MANIFEST: _test_k4_009_anti_halluc                       — FR-K4-IW-008 Anti-Hallucination Protocol
# MANIFEST: _test_k4_010_audit_xrefs                       — FR-K4-IW-011 Audit cross-references
# MANIFEST: _test_k4_011_standard_exists                   — FR-K4-IW-080 qwik-frontend-patterns.md
# MANIFEST: _test_k4_012_standard_resumability_routes_ssr  — FR-K4-IW-020..022 conventions
# MANIFEST: _test_k4_013_standard_connect_streaming        — FR-K4-IW-023..024 Connect-ES + streaming
# MANIFEST: _test_k4_014_standard_components_vitest        — FR-K4-IW-025..026 components + Vitest
# MANIFEST: _test_k4_015_standard_pins_reference           — FR-K4-IW-081 references web-frontend.yaml
# MANIFEST: _test_k4_016_index_registered                  — FR-K4-IW-082 standards/index.yml entry
# MANIFEST: _test_k4_017_janus_dispatch_row                — FR-K4-IW-083 Iris-Web dispatch row
# MANIFEST: _test_k4_018_claude_md_trigger                 — FR-K4-IW-084 CLAUDE.md trigger row
# MANIFEST: _test_k4_019_hera_scope_intact                 — FR-K4-IW-085/NFR-006 Hera row untouched
# MANIFEST: _test_k4_020_namespace_forward                 — FR-K4-IW-085/NFR-005 namespace + pwa-forward
#
# L2 (2 cross-surface tests)
# MANIFEST: _test_k4_l2_catalogue_sync       — FR-K4-IW-102 persona <-> standard rule sync
# MANIFEST: _test_k4_l2_no_pin_duplication   — FR-K4-IW-102/NFR-003 single source of truth

# ─── Helpers ────────────────────────────────────────────────────

# Count `[ ]` markers inside a named H3 block (until the next H3/H2).
_count_checklist_items() {
  local file="$1" section="$2"
  awk -v s="### $section" '
    $0 == s {flag=1; next}
    /^### / {flag=0}
    /^## / {flag=0}
    flag && /\[ \]/ {n++}
    END {print n+0}
  ' "$file"
}

# ─── L1 tests ───────────────────────────────────────────────────

# FR-K4-IW-001 Iris-Web persona file exists
_test_k4_001_persona_exists() {
  if [ ! -f "$IRIS_AGENT" ]; then
    echo "    persona file missing: $IRIS_AGENT" >&2; return 1
  fi
}

# FR-K4-IW-010 audit comment at top of file
_test_k4_002_audit_comment() {
  if [ ! -f "$IRIS_AGENT" ]; then
    echo "    persona file missing: $IRIS_AGENT" >&2; return 1
  fi
  if ! head -5 "$IRIS_AGENT" | grep -q "<!-- Audit: K.4 (k4-iris-web) -->"; then
    echo "    audit comment missing in first 5 lines of $IRIS_AGENT" >&2; return 1
  fi
}

# FR-K4-IW-002/003 ## Persona + ## Purpose H2 anchors
_test_k4_003_persona_h2() {
  if [ ! -f "$IRIS_AGENT" ]; then
    echo "    persona file missing: $IRIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Persona$" "$IRIS_AGENT"; then
    echo "    ## Persona H2 missing in $IRIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Purpose$" "$IRIS_AGENT"; then
    echo "    ## Purpose H2 missing in $IRIS_AGENT" >&2; return 1
  fi
}

# FR-K4-IW-004 ## Checklists + 4 H3 sub-sections
_test_k4_004_checklists_h2() {
  if [ ! -f "$IRIS_AGENT" ]; then
    echo "    persona file missing: $IRIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Checklists$" "$IRIS_AGENT"; then
    echo "    ## Checklists H2 missing in $IRIS_AGENT" >&2; return 1
  fi
  for h3 in \
    "### Resumability & Rendering" \
    "### Routing & SSR-SSG Boundaries" \
    "### Connect-ES & Streaming" \
    "### Components & Vitest Testing"; do
    if ! grep -qF "$h3" "$IRIS_AGENT"; then
      echo "    checklist H3 missing: '$h3'" >&2; return 1
    fi
  done
}

# FR-K4-IW-004 >= 5 [ ] items per checklist sub-section
_test_k4_005_checklists_items() {
  if [ ! -f "$IRIS_AGENT" ]; then
    echo "    persona file missing: $IRIS_AGENT" >&2; return 1
  fi
  for section in \
    "Resumability & Rendering" \
    "Routing & SSR-SSG Boundaries" \
    "Connect-ES & Streaming" \
    "Components & Vitest Testing"; do
    local count
    count="$(_count_checklist_items "$IRIS_AGENT" "$section")"
    if [ "$count" -lt 5 ]; then
      echo "    H3 '$section' has only $count '[ ]' items (expected >= 5)" >&2; return 1
    fi
  done
}

# FR-K4-IW-005 ## Output: Web Frontend Readiness Report H2
_test_k4_006_output_h2() {
  if [ ! -f "$IRIS_AGENT" ]; then
    echo "    persona file missing: $IRIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Output: Web Frontend Readiness Report$" "$IRIS_AGENT"; then
    echo "    ## Output: Web Frontend Readiness Report H2 missing" >&2; return 1
  fi
  if ! grep -q "| Severity |" "$IRIS_AGENT"; then
    echo "    Severity summary table missing" >&2; return 1
  fi
}

# FR-K4-IW-006 / 120..125 ## Rule Catalogue + K4-RULE-001..006
_test_k4_007_rule_catalogue() {
  if [ ! -f "$IRIS_AGENT" ]; then
    echo "    persona file missing: $IRIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Rule Catalogue$" "$IRIS_AGENT"; then
    echo "    ## Rule Catalogue H2 missing" >&2; return 1
  fi
  for rule in K4-RULE-001 K4-RULE-002 K4-RULE-003 K4-RULE-004 K4-RULE-005 K4-RULE-006; do
    if ! grep -q "$rule" "$IRIS_AGENT"; then
      echo "    $rule anchor missing in $IRIS_AGENT" >&2; return 1
    fi
  done
}

# FR-K4-IW-007 ## Integration H2 + Janus arbitration + Hera boundary
_test_k4_008_integration() {
  if [ ! -f "$IRIS_AGENT" ]; then
    echo "    persona file missing: $IRIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Integration$" "$IRIS_AGENT"; then
    echo "    ## Integration H2 missing" >&2; return 1
  fi
  if ! grep -q "cross-layer-orchestrator" "$IRIS_AGENT"; then
    echo "    cross-layer-orchestrator (Janus) reference missing" >&2; return 1
  fi
  if ! grep -q "Hera" "$IRIS_AGENT"; then
    echo "    Hera scope-boundary reference missing" >&2; return 1
  fi
}

# FR-K4-IW-008 ## Anti-Hallucination Protocol H2
_test_k4_009_anti_halluc() {
  if [ ! -f "$IRIS_AGENT" ]; then
    echo "    persona file missing: $IRIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Anti-Hallucination Protocol$" "$IRIS_AGENT"; then
    echo "    ## Anti-Hallucination Protocol H2 missing" >&2; return 1
  fi
  if ! grep -q "\[NEEDS CLARIFICATION:" "$IRIS_AGENT"; then
    echo "    [NEEDS CLARIFICATION: marker mention missing" >&2; return 1
  fi
}

# FR-K4-IW-011 ## Audit cross-references footer
_test_k4_010_audit_xrefs() {
  if [ ! -f "$IRIS_AGENT" ]; then
    echo "    persona file missing: $IRIS_AGENT" >&2; return 1
  fi
  if ! grep -q "^## Audit cross-references$" "$IRIS_AGENT"; then
    echo "    ## Audit cross-references H2 missing" >&2; return 1
  fi
  if ! grep -q "ARCHITECTURE-TARGET" "$IRIS_AGENT"; then
    echo "    ARCHITECTURE-TARGET source citation missing" >&2; return 1
  fi
  if ! grep -q "§9.2" "$IRIS_AGENT"; then
    echo "    §9.2 line citation missing" >&2; return 1
  fi
}

# FR-K4-IW-080 standard file exists with >= 5 H2 sections
_test_k4_011_standard_exists() {
  if [ ! -f "$QWIK_STD" ]; then
    echo "    standard missing: $QWIK_STD" >&2; return 1
  fi
  local h2_count
  h2_count="$(grep -cE '^## ' "$QWIK_STD")"
  if [ "$h2_count" -lt 5 ]; then
    echo "    expected >= 5 H2 sections in $QWIK_STD, got $h2_count" >&2; return 1
  fi
}

# FR-K4-IW-020..022 resumability + routes + SSR/SSG conventions
_test_k4_012_standard_resumability_routes_ssr() {
  if [ ! -f "$QWIK_STD" ]; then
    echo "    standard missing: $QWIK_STD" >&2; return 1
  fi
  if ! grep -qi "resumab" "$QWIK_STD"; then
    echo "    resumability convention missing" >&2; return 1
  fi
  if ! grep -q "routes/" "$QWIK_STD"; then
    echo "    routes/ convention missing" >&2; return 1
  fi
  if ! grep -q "SSR" "$QWIK_STD" || ! grep -q "SSG" "$QWIK_STD"; then
    echo "    SSR/SSG boundary convention missing" >&2; return 1
  fi
}

# FR-K4-IW-023..024 Connect-ES client + streaming/cancel-on-unmount
_test_k4_013_standard_connect_streaming() {
  if [ ! -f "$QWIK_STD" ]; then
    echo "    standard missing: $QWIK_STD" >&2; return 1
  fi
  if ! grep -qi "connect-es" "$QWIK_STD" && ! grep -q "connect-client" "$QWIK_STD"; then
    echo "    Connect-ES client convention missing" >&2; return 1
  fi
  if ! grep -q "for await" "$QWIK_STD"; then
    echo "    streaming for-await convention missing" >&2; return 1
  fi
  if ! grep -qi "cancel-on-unmount" "$QWIK_STD" && ! grep -q "useVisibleTask\$" "$QWIK_STD"; then
    echo "    cancel-on-unmount convention missing" >&2; return 1
  fi
  if ! grep -q "B.7.10" "$QWIK_STD"; then
    echo "    B.7.10 streaming precedent reference missing" >&2; return 1
  fi
}

# FR-K4-IW-025..026 component conventions + Vitest
_test_k4_014_standard_components_vitest() {
  if [ ! -f "$QWIK_STD" ]; then
    echo "    standard missing: $QWIK_STD" >&2; return 1
  fi
  if ! grep -q "component\$" "$QWIK_STD"; then
    echo "    component\$ convention missing" >&2; return 1
  fi
  if ! grep -qi "vitest" "$QWIK_STD"; then
    echo "    Vitest testing convention missing" >&2; return 1
  fi
}

# FR-K4-IW-081 standard references web-frontend.yaml (single source of truth)
_test_k4_015_standard_pins_reference() {
  if [ ! -f "$QWIK_STD" ]; then
    echo "    standard missing: $QWIK_STD" >&2; return 1
  fi
  if ! grep -q "web-frontend.yaml" "$QWIK_STD"; then
    echo "    web-frontend.yaml single-source-of-truth reference missing" >&2; return 1
  fi
}

# FR-K4-IW-082 standards/index.yml registers qwik-frontend-patterns
_test_k4_016_index_registered() {
  if [ ! -f "$STANDARDS_INDEX" ]; then
    echo "    standards index missing: $STANDARDS_INDEX" >&2; return 1
  fi
  if ! grep -q "id: global/qwik-frontend-patterns" "$STANDARDS_INDEX"; then
    echo "    qwik-frontend-patterns entry missing in $STANDARDS_INDEX" >&2; return 1
  fi
  for trig in "iris-web" "qwik" "sveltekit" "resumability" "connect-es" "vitest" "k4-rule"; do
    if ! grep -A 6 "id: global/qwik-frontend-patterns" "$STANDARDS_INDEX" | grep -q "$trig"; then
      echo "    trigger '$trig' missing on qwik-frontend-patterns entry" >&2; return 1
    fi
  done
}

# FR-K4-IW-083 Janus dispatch table contains Iris-Web row
_test_k4_017_janus_dispatch_row() {
  if [ ! -f "$JANUS_AGENT" ]; then
    echo "    janus agent missing: $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -q "\*\*Iris-Web\*\*" "$JANUS_AGENT"; then
    echo "    Iris-Web dispatch row missing in $JANUS_AGENT" >&2; return 1
  fi
  if ! grep -q "web-public" "$JANUS_AGENT"; then
    echo "    web-public dispatch scope missing in $JANUS_AGENT" >&2; return 1
  fi
}

# FR-K4-IW-084 repo CLAUDE.md trigger row contains Iris-Web
_test_k4_018_claude_md_trigger() {
  if [ ! -f "$REPO_CLAUDE_MD" ]; then
    echo "    repo CLAUDE.md missing: $REPO_CLAUDE_MD" >&2; return 1
  fi
  if ! grep -q "\*\*Iris-Web\*\*" "$REPO_CLAUDE_MD"; then
    echo "    Iris-Web trigger row missing in $REPO_CLAUDE_MD" >&2; return 1
  fi
  if ! grep -q "Frontend Web Specialist" "$REPO_CLAUDE_MD"; then
    echo "    Iris-Web role label missing in $REPO_CLAUDE_MD" >&2; return 1
  fi
}

# FR-K4-IW-085 / NFR-006 Hera Flutter scope intact (additive, not narrowed)
_test_k4_019_hera_scope_intact() {
  if [ ! -f "$JANUS_AGENT" ] || [ ! -f "$REPO_CLAUDE_MD" ]; then
    echo "    janus agent or CLAUDE.md missing" >&2; return 1
  fi
  # Hera's Flutter orchestrator row must remain in the Janus dispatch table.
  if ! grep -q "\*\*Hera\*\* (Flutter Orchestrator)" "$JANUS_AGENT"; then
    echo "    Hera Flutter Orchestrator row missing/narrowed in $JANUS_AGENT" >&2; return 1
  fi
  # Hera's Flutter delegation row must remain in the repo CLAUDE.md.
  if ! grep -q "| Flutter code | \*\*Hera\*\* | Flutter Team Orchestrator |" "$REPO_CLAUDE_MD"; then
    echo "    Hera Flutter row missing/narrowed in $REPO_CLAUDE_MD" >&2; return 1
  fi
}

# FR-K4-IW-085 / NFR-005 namespace separation + mobile-pwa-first forward mention
_test_k4_020_namespace_forward() {
  if [ ! -f "$IRIS_AGENT" ] || [ ! -f "$QWIK_STD" ]; then
    echo "    persona or standard missing" >&2; return 1
  fi
  # The K.4 surfaces must NOT reuse the J.8 / K.3 rule-ID literals.
  if grep -q "J8-RULE" "$IRIS_AGENT" || grep -q "J8-RULE" "$QWIK_STD"; then
    echo "    J8-RULE literal leaked into a K.4 surface" >&2; return 1
  fi
  if grep -q "K3-RULE" "$IRIS_AGENT" || grep -q "K3-RULE" "$QWIK_STD"; then
    echo "    K3-RULE literal leaked into a K.4 surface" >&2; return 1
  fi
  # Forward stability : mobile-pwa-first must be named as a forward consumer.
  if ! grep -q "mobile-pwa-first" "$IRIS_AGENT" && ! grep -q "mobile-pwa-first" "$QWIK_STD"; then
    echo "    mobile-pwa-first forward-consumer mention missing" >&2; return 1
  fi
}

# ─── L2 cross-surface tests ─────────────────────────────────────

# FR-K4-IW-102 — every K4-RULE-NNN in the persona also appears in the standard
_test_k4_l2_catalogue_sync() {
  if [ ! -f "$IRIS_AGENT" ] || [ ! -f "$QWIK_STD" ]; then
    echo "    persona or standard missing" >&2; return 1
  fi
  for rule in K4-RULE-001 K4-RULE-002 K4-RULE-003 K4-RULE-004 K4-RULE-005 K4-RULE-006; do
    if ! grep -q "$rule" "$IRIS_AGENT"; then
      echo "    $rule missing from persona" >&2; return 1
    fi
    if ! grep -q "$rule" "$QWIK_STD"; then
      echo "    $rule missing from standard (catalogue out of sync)" >&2; return 1
    fi
  done
}

# FR-K4-IW-102 / NFR-003 — standard references web-frontend.yaml + omits the exact vite pin
_test_k4_l2_no_pin_duplication() {
  if [ ! -f "$QWIK_STD" ]; then
    echo "    standard missing: $QWIK_STD" >&2; return 1
  fi
  if ! grep -q "web-frontend.yaml" "$QWIK_STD"; then
    echo "    single-source-of-truth reference to web-frontend.yaml missing" >&2; return 1
  fi
  # web-frontend.yaml owns the exact vite pin "7.3.5"; the conventions
  # standard MUST NOT reproduce it (single source of truth, NFR-K4-IW-003).
  if grep -q "7.3.5" "$QWIK_STD"; then
    echo "    vite pin literal '7.3.5' duplicated in the conventions standard" >&2; return 1
  fi
  # Sanity : the pin genuinely lives in web-frontend.yaml (guards a false pass
  # if the pin source ever moves).
  if [ -f "$WEB_FRONTEND_YAML" ] && ! grep -q "7.3.5" "$WEB_FRONTEND_YAML"; then
    echo "    NOTE: vite pin no longer in web-frontend.yaml — re-verify single source of truth" >&2
  fi
}

# ─── Main ────────────────────────────────────────────────────────

main() {
  echo "-- K.4 — k4-iris-web harness (level $LEVEL) --"
  echo ""
  echo "Phase 1: L1 — persona + standard + integration anchors"
  run_test _test_k4_001_persona_exists
  run_test _test_k4_002_audit_comment
  run_test _test_k4_003_persona_h2
  run_test _test_k4_004_checklists_h2
  run_test _test_k4_005_checklists_items
  run_test _test_k4_006_output_h2
  run_test _test_k4_007_rule_catalogue
  run_test _test_k4_008_integration
  run_test _test_k4_009_anti_halluc
  run_test _test_k4_010_audit_xrefs
  run_test _test_k4_011_standard_exists
  run_test _test_k4_012_standard_resumability_routes_ssr
  run_test _test_k4_013_standard_connect_streaming
  run_test _test_k4_014_standard_components_vitest
  run_test _test_k4_015_standard_pins_reference
  run_test _test_k4_016_index_registered
  run_test _test_k4_017_janus_dispatch_row
  run_test _test_k4_018_claude_md_trigger
  run_test _test_k4_019_hera_scope_intact
  run_test _test_k4_020_namespace_forward

  if [[ ",$LEVEL," == *",2,"* ]] || [[ "$LEVEL" == "1,2" ]] || [[ "$LEVEL" == "2" ]]; then
    echo ""
    echo "Phase 2: L2 — cross-surface coherence"
    run_test _test_k4_l2_catalogue_sync
    run_test _test_k4_l2_no_pin_duplication
  fi

  print_summary
}

main "$@"
