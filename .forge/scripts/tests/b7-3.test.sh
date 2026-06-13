#!/usr/bin/env bash
# Forge — B.7.3 ai-native-rag standards harness
# <!-- Audit: B.7.3 (b7-standards) — rag-patterns / llm-gateway / mcp-servers .md -->
#
# Validates the three pattern standards + their registration:
#
#   T-001  rag-patterns.md exists + required H2 sections (FR-B7-3-001/002)
#   T-002  llm-gateway.md exists + required H2 sections (FR-B7-3-010)
#   T-003  mcp-servers.md exists + required H2 sections (FR-B7-3-020)
#   T-004  each standard has Constitutional Compliance + Out-of-scope + Schema-mapping (FR-B7-3-024)
#   T-005  index.yml registers all three (FR-B7-3-030)
#   T-006  REVIEW.md has a birth entry for all three (FR-B7-3-031)
#   T-007  NO inline version pin in any standard (NFR-B7-3-002, FR-B7-3-004/014/023)
#
# 7 L1 tests. Performance budget: L1 ≤ 3 s, zero net/Docker. The standards are
# pattern docs (no version pins); pins ride with B.7.2-full (transport.yaml/b8-6
# precedent). T-007 guards against an accidental inline pin via a negative grep
# for the Cargo.toml form `<crate> = "<digit>` (placeholders like
# "<pinned-by-B.7.2-full>" are allowed — they don't start with a digit).

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
FORGE_ROOT="$(cd "$SCRIPTS_DIR/../.." && pwd)"

STD_DIR="$FORGE_ROOT/.forge/standards/global"
RAG="$STD_DIR/rag-patterns.md"
GW="$STD_DIR/llm-gateway.md"
MCP="$STD_DIR/mcp-servers.md"
INDEX="$FORGE_ROOT/.forge/standards/index.yml"
REVIEW="$FORGE_ROOT/.forge/standards/REVIEW.md"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# _has_h2 <file> <keyword> — case-insensitive grep for an H2 heading containing keyword
_has_h2() { grep -qiE "^##[^#].*$2" "$1" 2>/dev/null; }

_test_b73_l1_001_rag_patterns() {
  [ -f "$RAG" ] || { echo "    FAIL T-001: rag-patterns.md missing: $RAG (FR-B7-3-001)" >&2; return 1; }
  local ok=1
  for kw in "Retrieval" "Re-ranking" "HNSW" "Chunking|Embedding"; do
    _has_h2 "$RAG" "$kw" || { echo "    FAIL T-001: rag-patterns.md missing H2 ~ '$kw' (FR-B7-3-001/002)" >&2; ok=0; }
  done
  # pgvector specifics (FR-B7-3-002): ef_search + iterative_scan present in body
  grep -qiE "ef_search" "$RAG" || { echo "    FAIL T-001: rag-patterns.md missing hnsw.ef_search (FR-B7-3-002)" >&2; ok=0; }
  grep -qiE "iterative_scan" "$RAG" || { echo "    FAIL T-001: rag-patterns.md missing hnsw.iterative_scan (FR-B7-3-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b73_l1_002_llm_gateway() {
  [ -f "$GW" ] || { echo "    FAIL T-002: llm-gateway.md missing: $GW (FR-B7-3-010)" >&2; return 1; }
  local ok=1
  for kw in "Proxy|architecture" "Provider" "Tier-aware|refusal" "Prompt audit|observability" "fallback|PII"; do
    _has_h2 "$GW" "$kw" || { echo "    FAIL T-002: llm-gateway.md missing H2 ~ '$kw' (FR-B7-3-010)" >&2; ok=0; }
  done
  # tier-aware refusal references the existing EU machinery (FR-B7-3-011)
  grep -qiE "forbidden-components|compliance-tiers" "$GW" || { echo "    FAIL T-002: llm-gateway.md must reference forbidden-components/compliance-tiers (FR-B7-3-011)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b73_l1_003_mcp_servers() {
  [ -f "$MCP" ] || { echo "    FAIL T-003: mcp-servers.md missing: $MCP (FR-B7-3-020)" >&2; return 1; }
  local ok=1
  for kw in "rmcp|server pattern" "Security" "Auth" "Versioning|maturity"; do
    _has_h2 "$MCP" "$kw" || { echo "    FAIL T-003: mcp-servers.md missing H2 ~ '$kw' (FR-B7-3-020)" >&2; ok=0; }
  done
  # rmcp Tier-3 / verify-then-pin caveat (FR-B7-3-023)
  grep -qiE "Tier.?3|verify-then-pin" "$MCP" || { echo "    FAIL T-003: mcp-servers.md missing rmcp Tier-3 / verify-then-pin caveat (FR-B7-3-023)" >&2; ok=0; }
  # OAuth coupling (FR-B7-3-022)
  grep -qiE "OAuth|zitadel" "$MCP" || { echo "    FAIL T-003: mcp-servers.md missing OAuth/Zitadel coupling (FR-B7-3-022)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

_test_b73_l1_004_common_sections() {
  local ok=1
  for f in "$RAG" "$GW" "$MCP"; do
    [ -f "$f" ] || { echo "    FAIL T-004: $f missing (covered by T-001..003)" >&2; ok=0; continue; }
    _has_h2 "$f" "Constitutional Compliance" || { echo "    FAIL T-004: $(basename "$f") missing '## Constitutional Compliance'" >&2; ok=0; }
    _has_h2 "$f" "Out-of-scope|Out of scope" || { echo "    FAIL T-004: $(basename "$f") missing Out-of-scope section" >&2; ok=0; }
    grep -qiE "schema (component )?mapping|ai-native-rag/1.0.0" "$f" || { echo "    FAIL T-004: $(basename "$f") missing schema-mapping note (FR-B7-3-024)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b73_l1_005_index_entries() {
  [ -f "$INDEX" ] || { echo "    FAIL T-005: index.yml missing" >&2; return 1; }
  local ok=1
  for s in rag-patterns llm-gateway mcp-servers; do
    grep -qE "global/$s\b" "$INDEX" || { echo "    FAIL T-005: index.yml has no entry for global/$s (FR-B7-3-030)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b73_l1_006_review_births() {
  [ -f "$REVIEW" ] || { echo "    FAIL T-006: REVIEW.md missing" >&2; return 1; }
  local ok=1
  for s in rag-patterns llm-gateway mcp-servers; do
    grep -qE "$s\.md" "$REVIEW" || { echo "    FAIL T-006: REVIEW.md has no birth entry for $s.md (FR-B7-3-031)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

_test_b73_l1_007_no_inline_pins() {
  # NFR-B7-3-002 — no Cargo.toml-style version pin (`<crate> = "<digit>`) in any
  # standard. Placeholder forms ("<pinned-by-B.7.2-full>") are allowed.
  local hits ok=1
  for f in "$RAG" "$GW" "$MCP"; do
    [ -f "$f" ] || continue
    hits=$(grep -nE '(rmcp|pgvector|async-openai)[[:space:]]*=[[:space:]]*"[0-9]' "$f" 2>/dev/null || true)
    if [ -n "$hits" ]; then
      echo "    FAIL T-007: $(basename "$f") inlines a version pin (NFR-B7-3-002): $hits" >&2; ok=0
    fi
  done
  [ "$ok" = "1" ]
}

main() {
  echo "── B.7.3 — b7-standards — level $LEVEL ──"
  run_test _test_b73_l1_001_rag_patterns
  run_test _test_b73_l1_002_llm_gateway
  run_test _test_b73_l1_003_mcp_servers
  run_test _test_b73_l1_004_common_sections
  run_test _test_b73_l1_005_index_entries
  run_test _test_b73_l1_006_review_births
  run_test _test_b73_l1_007_no_inline_pins
  print_summary
}

main
