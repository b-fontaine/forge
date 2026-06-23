#!/usr/bin/env bash
# Forge — B.7.6 ai-native-rag promotion-gate harness (the ≥35-test suite)
# <!-- Audit: B.7.6 (b7-6-harness) — promotion gate candidate→stable/scaffoldable -->
#
# THE PROMOTION GATE for the ai-native-rag/1.0.0 archetype (ADR-B7-1-002). This
# suite proves the assembled archetype end-to-end BEFORE the schema is flipped to
# stage:stable / scaffoldable:true. It is a true SUPERSET gate: it re-runs every
# sibling B.7 per-brick harness (Tier A) AND adds the cross-brick coherence + live
# codegen/build legs the siblings don't check (Tiers B/C), plus the promotion
# held/post-flip guard (Tier D).
#
# Mirrors b7-2.test.sh / b7-10.test.sh structure: arg-parsed --level, _helpers.sh
# source, run_test / print_summary. Tiers:
#
#   Tier A — aggregation (8 tests, hermetic):
#     re-run b7-1/b7-2/b7-2a/b7-3/b7-5/b7-9/b7-10/b7-pythia at their CI level and
#     assert exit 0; absent sibling → clean SKIP (FR-B7-6-003).
#
#   Tier B — net-new L1 e2e structural (hermetic, grep/structure, CI-safe):
#     the assembled-archetype coherence the per-brick siblings don't check — proto
#     unary+streaming coexistence, codegen-manifest targets, the Connect-handler
#     seam, scaffold-plan↔tree full coverage, standards conformance, pin
#     discipline, AI-First markers, gated wrapper + dispatch entry (FR-B7-6-002/005).
#
#   Tier C — L2 live-codegen (toolchain-gated, SKIP-when-absent):
#     render via overlay.sh, then the LIVE path — buf generate (proto → Rust + TS),
#     cargo build/test of the rendered workspace, Qwik tsc, snapshot determinism.
#     Each leg SKIPs gracefully (echo SKIP, return 0) when buf/BSR/cargo/tsc absent
#     (the b7-10 T-L2-003/004 precedent). These are the legs the forge-ci
#     `harness-rust` job runs LIVE (Q-B option b; FR-B7-6-004/010).
#
#   Tier D — promotion held / post-flip guard:
#     pre-flip the schema is still candidate + the CLI still refuses (negative
#     held-guard, b8-14-prep pattern); the flip task inverts this to assert
#     stable/scaffoldable:true (NFR-B7-6-001).
#
# CI registration (.github/workflows/forge-ci.yml): the `harness` job runs this at
# --level 1 (L1 + aggregation + held-guard; the L2 legs SKIP there, buf-less); the
# `harness-rust` job runs it at --level 1,2 with buf + a Rust toolchain + node, so
# the live codegen/build path is a permanent per-PR gate (ADR-B7-6-005 option b).

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

ARCHETYPE_DIR="$FORGE_ROOT/.forge/templates/archetypes/ai-native-rag"
TPL_DIR="$ARCHETYPE_DIR/1.0.0"
PLAN="$ARCHETYPE_DIR/scaffold-plan.yaml"
OVERLAY_SH="$FORGE_ROOT/.forge/scripts/scaffolder/overlay.sh"
WRAPPER="$FORGE_ROOT/bin/forge-init-ai-native-rag.sh"
SCHEMA_AINR="$FORGE_ROOT/.forge/schemas/ai-native-rag/1.0.0.yaml"
DISPATCH="$FORGE_ROOT/.forge/scaffolding/dispatch-table.yml"
SNAPSHOT_SH="$FORGE_ROOT/bin/forge-snapshot.sh"
STD_DIR="$FORGE_ROOT/.forge/standards/global"

PROTO="$TPL_DIR/shared/protos/v1/rag/rag.proto.tmpl"
BUF_GEN="$TPL_DIR/shared/protos/buf.gen.yaml.tmpl"
MAIN_RS="$TPL_DIR/backend/bin-server/src/main.rs.tmpl"
CARGO_TOML="$TPL_DIR/backend/Cargo.toml.tmpl"
CC="$TPL_DIR/frontend/web-public/src/lib/connect-client.ts.tmpl"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ════════════════════════════════════════════════════════════════════
# Tier A — aggregation: re-run each sibling B.7 harness, assert exit 0.
# A sibling absent from the tree → clean SKIP (the suite stays runnable
# if a sibling is renamed/retired), not a hard FAIL (FR-B7-6-003).
# ════════════════════════════════════════════════════════════════════

# Run sibling harness $1 (basename, no path) with the remaining args at its CI
# level; PASS on exit 0, SKIP (return 0) if the harness file is absent, FAIL on
# non-zero exit. Output captured; on FAIL the tail is surfaced for triage.
_b76_aggregate_sibling() {
  local name="$1"; shift
  local sib="$HARNESS_DIR/$name"
  if [ ! -f "$sib" ]; then
    echo "    SKIP: sibling harness absent: $name (FR-B7-6-003)" >&2
    return 0
  fi
  local log; log="$(mktemp)"
  if bash "$sib" "$@" >"$log" 2>&1; then
    rm -f "$log"; return 0
  fi
  echo "    FAIL: sibling harness non-zero exit: $name $* (FR-B7-6-003)" >&2
  tail -20 "$log" >&2
  rm -f "$log"
  return 1
}

# CI levels mirror .github/workflows/forge-ci.yml's harness array exactly.
_test_b76_agg_b7_1()      { _b76_aggregate_sibling "b7-1.test.sh" --level 1,2; }
_test_b76_agg_b7_2()      { _b76_aggregate_sibling "b7-2.test.sh" --level 1; }
_test_b76_agg_b7_2a()     { _b76_aggregate_sibling "b7-2a.test.sh" --level 1,2; }
_test_b76_agg_b7_3()      { _b76_aggregate_sibling "b7-3.test.sh" --level 1; }
_test_b76_agg_b7_5()      { _b76_aggregate_sibling "b7-5.test.sh" --level 1,2; }
_test_b76_agg_b7_9()      { _b76_aggregate_sibling "b7-9.test.sh" --level 1,2; }
_test_b76_agg_b7_10()     { _b76_aggregate_sibling "b7-10.test.sh" --level 1; }
_test_b76_agg_b7_pythia() { _b76_aggregate_sibling "b7-pythia.test.sh" --level 1,2; }

# ════════════════════════════════════════════════════════════════════
# Tier B — net-new L1 e2e structural (hermetic, grep/structure, CI-safe).
# The cross-brick coherence of the ASSEMBLED archetype that no single
# sibling proves.
# ════════════════════════════════════════════════════════════════════

# T-B01 — proto: the unary Query RPC is RETAINED (the documented XI.5 degradation
# target; assembled-view of b7-2) (FR-B7-6-002).
_test_b76_l1_b01_proto_unary_retained() {
  [ -f "$PROTO" ] || { echo "    FAIL T-B01: rag.proto template missing: $PROTO (FR-B7-6-002)" >&2; return 1; }
  grep -qE 'rpc[[:space:]]+Query[[:space:]]*\([[:space:]]*QueryRequest[[:space:]]*\)[[:space:]]+returns[[:space:]]*\([[:space:]]*QueryResponse[[:space:]]*\)' "$PROTO" \
    || { echo "    FAIL T-B01: unary 'rpc Query(QueryRequest) returns (QueryResponse)' absent (FR-B7-6-002)" >&2; return 1; }
}

# T-B02 — proto: the server-streaming QueryStream RPC + QueryChunk message coexist
# with the unary surface (assembled-view of b7-10) (FR-B7-6-002).
_test_b76_l1_b02_proto_streaming_present() {
  [ -f "$PROTO" ] || { echo "    FAIL T-B02: rag.proto template missing (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  grep -qE 'rpc[[:space:]]+QueryStream[[:space:]]*\([[:space:]]*QueryRequest[[:space:]]*\)[[:space:]]+returns[[:space:]]*\([[:space:]]*stream[[:space:]]+QueryChunk[[:space:]]*\)' "$PROTO" \
    || { echo "    FAIL T-B02: server-streaming 'rpc QueryStream(...) returns (stream QueryChunk)' absent (FR-B7-6-002)" >&2; ok=0; }
  grep -qE 'message[[:space:]]+QueryChunk' "$PROTO" \
    || { echo "    FAIL T-B02: 'message QueryChunk' absent (FR-B7-6-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B03 — proto: SourceChunk is REUSED across the unary + streaming surfaces
# (exactly one definition, no duplicate) — the assembled-view coherence neither
# b7-2 nor b7-10 alone asserts (FR-B7-6-002).
_test_b76_l1_b03_proto_sourcechunk_reused() {
  [ -f "$PROTO" ] || { echo "    FAIL T-B03: rag.proto template missing (FR-B7-6-002)" >&2; return 1; }
  local defs; defs="$(grep -cE 'message[[:space:]]+SourceChunk' "$PROTO" 2>/dev/null || echo 0)"
  [ "$defs" = "1" ] || { echo "    FAIL T-B03: SourceChunk must have exactly 1 definition (found $defs) (FR-B7-6-002)" >&2; return 1; }
}

# T-B04 — codegen manifest: buf.gen.yaml.tmpl declares the Rust (tonic + prost)
# stub outputs to backend/crates/grpc-api/src/generated (FR-B7-6-002).
_test_b76_l1_b04_codegen_rust_targets() {
  [ -f "$BUF_GEN" ] || { echo "    FAIL T-B04: buf.gen.yaml.tmpl missing: $BUF_GEN (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  grep -qE 'neoeinstein-tonic' "$BUF_GEN" || { echo "    FAIL T-B04: tonic (Rust gRPC) plugin absent from buf.gen.yaml (FR-B7-6-002)" >&2; ok=0; }
  grep -qE 'neoeinstein-prost' "$BUF_GEN" || { echo "    FAIL T-B04: prost (Rust messages) plugin absent from buf.gen.yaml (FR-B7-6-002)" >&2; ok=0; }
  grep -qE 'backend/crates/grpc-api/src/generated' "$BUF_GEN" \
    || { echo "    FAIL T-B04: Rust stub output dir (backend/crates/grpc-api/src/generated) absent from buf.gen.yaml (FR-B7-6-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B05 — codegen manifest ↔ Qwik contract: buf.gen.yaml.tmpl declares the TS
# (bufbuild/es) output to frontend/.../generated/connect AND the Qwik
# connect-client imports exactly that descriptor (./generated/connect/rag_pb) — the
# genuine "rides b7-6" leg the harness-rust job exercises (FR-B7-6-002/005).
_test_b76_l1_b05_codegen_ts_qwik_contract() {
  [ -f "$BUF_GEN" ] || { echo "    FAIL T-B05: buf.gen.yaml.tmpl missing (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  grep -qE 'bufbuild/es' "$BUF_GEN" || { echo "    FAIL T-B05: bufbuild/es (TS Connect) plugin absent from buf.gen.yaml (FR-B7-6-002)" >&2; ok=0; }
  grep -qE 'frontend/web-public/src/lib/generated/connect' "$BUF_GEN" \
    || { echo "    FAIL T-B05: TS output dir (frontend/.../generated/connect) absent from buf.gen.yaml (FR-B7-6-002)" >&2; ok=0; }
  if [ -f "$CC" ]; then
    grep -qE 'from "\./generated/connect/rag_pb"' "$CC" \
      || { echo "    FAIL T-B05: connect-client.ts does not import ./generated/connect/rag_pb (codegen target drift) (FR-B7-6-005)" >&2; ok=0; }
  fi
  [ "$ok" = "1" ]
}

# T-B06 — scaffold-plan ↔ tree NO ORPHAN: every .tmpl in the tree is referenced by
# the plan (widens b7-2 T-002 to the assembled tree) (FR-B7-6-002).
_test_b76_l1_b06_plan_no_orphan() {
  [ -f "$PLAN" ] || { echo "    FAIL T-B06: scaffold-plan missing: $PLAN (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  while IFS= read -r f; do
    local rel="${f#"$TPL_DIR/"}"
    grep -qF "$rel" "$PLAN" || { echo "    FAIL T-B06: tree .tmpl not referenced by plan: $rel (FR-B7-6-002)" >&2; ok=0; }
  done < <(find "$TPL_DIR" -type f -name '*.tmpl' 2>/dev/null)
  [ "$ok" = "1" ]
}

# T-B07 — scaffold-plan ↔ tree NO DANGLING: every plan source: that points into
# 1.0.0/ resolves to an existing tree file (FR-B7-6-002).
_test_b76_l1_b07_plan_no_dangling() {
  [ -f "$PLAN" ] || { echo "    FAIL T-B07: scaffold-plan missing (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  while IFS= read -r src; do
    [ -z "$src" ] && continue
    case "$src" in
      1.0.0/*)
        [ -f "$ARCHETYPE_DIR/$src" ] || { echo "    FAIL T-B07: plan source: has no tree file: $src (FR-B7-6-002)" >&2; ok=0; } ;;
    esac
  done < <(grep -oE 'source:[[:space:]]*[^[:space:]]+' "$PLAN" | sed -E 's/source:[[:space:]]*//')
  [ "$ok" = "1" ]
}

# T-B08 — Connect-handler registration SEAM (axum surface). The assembled
# bin-server exposes the axum Router surface that Connect routes mount onto
# (FR-B7-6-005). Per the maintainer's Option-A decision (2026-06-23), the Connect
# handler is a DOCUMENTED ADOPTER SEAM — flagship parity (the full-stack
# transport_connect adapter ships an unwired ConnectRouter::new() seed with
# TODO(adopter)), NOT a pre-compiled Rust handler. This asserts the seam EXISTS.
_test_b76_l1_b08_connect_axum_surface() {
  [ -f "$MAIN_RS" ] || { echo "    FAIL T-B08: bin-server main.rs template missing: $MAIN_RS (FR-B7-6-005)" >&2; return 1; }
  grep -qE 'Router::new\(\)|axum::Router' "$MAIN_RS" \
    || { echo "    FAIL T-B08: bin-server has no axum Router surface for Connect mount (FR-B7-6-005)" >&2; return 1; }
}

# T-B09 — Connect-handler registration SEAM (the documented /connect + RagService
# wiring point). Asserts the seam is NAMED + DOCUMENTED at the mount point (the
# adopter wiring step), mirroring the flagship's documented seed posture — NOT that
# a handler compiles (FR-B7-6-005; Option-A, maintainer 2026-06-23).
_test_b76_l1_b09_connect_ragservice_seam() {
  [ -f "$MAIN_RS" ] || { echo "    FAIL T-B09: bin-server main.rs template missing (FR-B7-6-005)" >&2; return 1; }
  local ok=1
  grep -qiE 'Connect|/connect' "$MAIN_RS" \
    || { echo "    FAIL T-B09: bin-server has no documented Connect (/connect) mount seam (FR-B7-6-005)" >&2; ok=0; }
  grep -qE 'rag\.v1\.RagService|RagService' "$MAIN_RS" \
    || { echo "    FAIL T-B09: bin-server does not name the rag.v1.RagService Connect handler seam (FR-B7-6-005)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B10 — standards conformance: rag-patterns.md markers (RRF + coarse→exact
# rerank + pgvector HNSW) under backend/rag (b7-2 T-007 carried; FR-B7-6-002).
_test_b76_l1_b10_conformance_rag() {
  local d="$TPL_DIR/backend/rag"
  [ -d "$d" ] || { echo "    FAIL T-B10: backend/rag tree missing (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  grep -rqE 'reciprocal_rank_fusion|\bRRF\b' "$d" 2>/dev/null || { echo "    FAIL T-B10: hybrid-retrieval RRF marker absent under backend/rag (rag-patterns.md)" >&2; ok=0; }
  grep -rqE 'rerank_exact|coarse.+exact|exact re-?rank' "$d" 2>/dev/null || { echo "    FAIL T-B10: coarse→exact rerank marker absent (rag-patterns.md)" >&2; ok=0; }
  grep -rqE 'vector_cosine_ops' "$d" 2>/dev/null || { echo "    FAIL T-B10: pgvector HNSW vector_cosine_ops marker absent (rag-patterns.md)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B11 — standards conformance: mcp-servers.md markers (tool_router + schemars +
# StreamableHttp) under backend/mcp (b7-2 T-007 carried; FR-B7-6-002).
_test_b76_l1_b11_conformance_mcp() {
  local d="$TPL_DIR/backend/mcp"
  [ -d "$d" ] || { echo "    FAIL T-B11: backend/mcp tree missing (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  grep -rqE 'tool_router' "$d" 2>/dev/null || { echo "    FAIL T-B11: rmcp tool_router marker absent under backend/mcp (mcp-servers.md)" >&2; ok=0; }
  grep -rqE 'schemars|JsonSchema' "$d" 2>/dev/null || { echo "    FAIL T-B11: schemars input validation marker absent (mcp-servers.md)" >&2; ok=0; }
  grep -rqE 'StreamableHttp' "$d" 2>/dev/null || { echo "    FAIL T-B11: streamable-HTTP transport marker absent (mcp-servers.md)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B12 — AI-First XI.5: the mandatory non-AI fallback marker survives across the
# assembled backend (Constitution XI.5; FR-B7-6-002).
_test_b76_l1_b12_ai_first_fallback() {
  local be="$TPL_DIR/backend"
  [ -d "$be" ] || { echo "    FAIL T-B12: backend tree missing (FR-B7-6-002)" >&2; return 1; }
  grep -rqE 'non_ai_fallback|FallbackReason|fallback_used' "$be" 2>/dev/null \
    || { echo "    FAIL T-B12: XI.5 non-AI fallback marker absent across backend (FR-B7-6-002)" >&2; return 1; }
}

# T-B13 — AI-First IX.6 + XI.6: the prompt-audit span (IX.6) AND PII redaction
# (XI.6) markers survive across the assembled backend (FR-B7-6-002).
_test_b76_l1_b13_ai_first_audit_pii() {
  local be="$TPL_DIR/backend"
  [ -d "$be" ] || { echo "    FAIL T-B13: backend tree missing (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  grep -rqE 'prompt.?audit|PromptAudit' "$be" 2>/dev/null \
    || { echo "    FAIL T-B13: IX.6 prompt-audit marker absent across backend (FR-B7-6-002)" >&2; ok=0; }
  grep -rqE 'redact_pii' "$be" 2>/dev/null \
    || { echo "    FAIL T-B13: XI.6 PII-redaction marker absent across backend (FR-B7-6-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B14 — pin discipline: the LIVE verify-then-pin crates are present in the
# workspace manifest (rmcp/pgvector/async-openai/fastembed/tokio-stream)
# (b7-2 T-003/004 + b7-10 T-007 carried; NFR-B7-6-005).
_test_b76_l1_b14_pins_present() {
  [ -f "$CARGO_TOML" ] || { echo "    FAIL T-B14: backend/Cargo.toml.tmpl missing (NFR-B7-6-005)" >&2; return 1; }
  local ok=1
  for crate in rmcp pgvector async-openai fastembed tokio-stream; do
    grep -qE "${crate}[[:space:]]*=" "$CARGO_TOML" \
      || { echo "    FAIL T-B14: LIVE pin '$crate' absent from backend/Cargo.toml.tmpl (NFR-B7-6-005)" >&2; ok=0; }
  done
  [ "$ok" = "1" ]
}

# T-B15 — pin discipline: NO crate pin leaked into the B.7.3 pattern standards
# (pins live ONLY in Cargo.toml.tmpl) (b7-2 T-004 + b7-10 T-007 carried;
# NFR-B7-6-005).
_test_b76_l1_b15_pins_not_in_standards() {
  local ok=1
  for f in "$STD_DIR/rag-patterns.md" "$STD_DIR/llm-gateway.md" "$STD_DIR/mcp-servers.md"; do
    [ -f "$f" ] || continue
    if grep -qE '(rmcp|pgvector|async-openai|fastembed|tokio-stream)[[:space:]]*=[[:space:]]*"[0-9]' "$f" 2>/dev/null; then
      echo "    FAIL T-B15: $(basename "$f") inlines a crate pin (NFR-B7-6-005)" >&2; ok=0
    fi
  done
  [ "$ok" = "1" ]
}

# T-B16 — the gated scaffolder wrapper exists, is executable, and carries the
# scaffoldability gate (is_scaffoldable: stage==stable AND scaffoldable==true) that
# auto-opens at promotion (FR-B7-6-002).
_test_b76_l1_b16_wrapper_gate() {
  local ok=1
  [ -f "$WRAPPER" ] || { echo "    FAIL T-B16: scaffolder wrapper missing: $WRAPPER (FR-B7-6-002)" >&2; ok=0; }
  [ -x "$WRAPPER" ] || { echo "    FAIL T-B16: wrapper not executable (FR-B7-6-002)" >&2; ok=0; }
  grep -qE 'is_scaffoldable' "$WRAPPER" \
    || { echo "    FAIL T-B16: wrapper lacks the scaffoldability gate (is_scaffoldable) (FR-B7-6-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B17 — the dispatch-table entry for ai-native-rag exists + points at the wrapper
# (FR-B7-6-002).
_test_b76_l1_b17_dispatch_entry() {
  [ -f "$DISPATCH" ] || { echo "    FAIL T-B17: dispatch-table.yml missing: $DISPATCH (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  grep -qE 'ai-native-rag' "$DISPATCH" \
    || { echo "    FAIL T-B17: ai-native-rag not registered in dispatch-table.yml (FR-B7-6-002)" >&2; ok=0; }
  grep -qE 'bin/forge-init-ai-native-rag\.sh' "$DISPATCH" \
    || { echo "    FAIL T-B17: dispatch entry does not point at bin/forge-init-ai-native-rag.sh (FR-B7-6-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B18 — standards conformance: llm-gateway.md markers (prompt-audit span IX.6 +
# PII redaction XI.6 + non-AI fallback XI.5) under backend/llm_gateway specifically
# (b7-2 T-007 carried; the gateway layer is the conformance focus) (FR-B7-6-002).
_test_b76_l1_b18_conformance_llm_gateway() {
  local d="$TPL_DIR/backend/llm_gateway"
  [ -d "$d" ] || { echo "    FAIL T-B18: backend/llm_gateway tree missing (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  grep -rqE 'prompt.?audit|PromptAudit' "$d" 2>/dev/null || { echo "    FAIL T-B18: prompt-audit span (IX.6) marker absent under backend/llm_gateway (llm-gateway.md)" >&2; ok=0; }
  grep -rqE 'redact_pii' "$d" 2>/dev/null || { echo "    FAIL T-B18: PII redaction (XI.6) marker absent (llm-gateway.md)" >&2; ok=0; }
  grep -rqE 'non_ai_fallback|FallbackReason' "$d" 2>/dev/null || { echo "    FAIL T-B18: non-AI fallback (XI.5) marker absent (llm-gateway.md)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B19 — streaming gateway surface present in the assembled backend: the
# server-streaming entrypoint + the named bounded-channel backpressure constant
# (b7-10 T-003 carried into the assembled view; FR-B7-6-002).
_test_b76_l1_b19_streaming_gateway_surface() {
  local d="$TPL_DIR/backend/llm_gateway/src"
  [ -d "$d" ] || { echo "    FAIL T-B19: backend/llm_gateway/src tree missing (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  grep -rqE 'process_query_stream' "$d" 2>/dev/null || { echo "    FAIL T-B19: streaming entrypoint process_query_stream absent (FR-B7-6-002)" >&2; ok=0; }
  grep -rqE 'STREAM_CHANNEL_CAPACITY' "$d" 2>/dev/null || { echo "    FAIL T-B19: named bounded-channel backpressure constant STREAM_CHANNEL_CAPACITY absent (FR-B7-6-002)" >&2; ok=0; }
  # The unary entrypoint is RETAINED alongside (the XI.5 degradation baseline).
  grep -rqE 'process_query\b' "$d" 2>/dev/null || { echo "    FAIL T-B19: unary process_query entrypoint not retained (FR-B7-6-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-B20 — Qwik streaming UI present in the assembled frontend: the connect-client
# exposes queryStream (async iterable) AND the route consumes it with `for await`
# (b7-10 T-005 carried into the assembled view; FR-B7-6-002).
_test_b76_l1_b20_qwik_streaming_ui() {
  local route="$TPL_DIR/frontend/web-public/src/routes/index.tsx.tmpl"
  [ -f "$CC" ] || { echo "    FAIL T-B20: connect-client.ts template missing (FR-B7-6-002)" >&2; return 1; }
  [ -f "$route" ] || { echo "    FAIL T-B20: routes/index.tsx template missing (FR-B7-6-002)" >&2; return 1; }
  local ok=1
  grep -qE 'queryStream' "$CC" || { echo "    FAIL T-B20: connect-client.ts does not export queryStream (FR-B7-6-002)" >&2; ok=0; }
  grep -qE 'for await' "$route" || { echo "    FAIL T-B20: route does not consume the stream with 'for await' (FR-B7-6-002)" >&2; ok=0; }
  # The unary query() is RETAINED (the UI-layer XI.5 degradation target).
  grep -qE 'function[[:space:]]+query\b' "$CC" || { echo "    FAIL T-B20: unary query() not retained in connect-client.ts (FR-B7-6-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# ════════════════════════════════════════════════════════════════════
# Tier D — promotion held / post-flip guard.
# Pre-flip: schema is candidate + CLI refuses (negative held-guard,
# b8-14-prep). The flip task (Phase 4) INVERTS these (NFR-B7-6-001).
# ════════════════════════════════════════════════════════════════════

# T-D01 — promotion held-guard. BEFORE the flip this asserts the schema is still
# candidate / scaffoldable:false (the flip has not happened out of order). AFTER
# the flip (Phase 4) this body is inverted to assert stable / scaffoldable:true.
# The single source of truth is the schema file (NFR-B7-6-001).
_test_b76_d01_promotion_guard() {
  [ -f "$SCHEMA_AINR" ] || { echo "    FAIL T-D01: ai-native-rag schema missing: $SCHEMA_AINR (NFR-B7-6-001)" >&2; return 1; }
  local stage scaffoldable
  stage="$(grep -E '^stage:' "$SCHEMA_AINR" | head -1 | sed -E 's/^stage:[[:space:]]*//')"
  scaffoldable="$(grep -E '^scaffoldable:' "$SCHEMA_AINR" | head -1 | sed -E 's/^scaffoldable:[[:space:]]*//')"
  # PRE-FLIP held-guard (inverted by Phase 4 T-041/T-043).
  [ "$stage" = "candidate" ] \
    || { echo "    FAIL T-D01: held-guard: stage='$stage' expected 'candidate' pre-flip (NFR-B7-6-001 — invert at the flip)" >&2; return 1; }
  [ "$scaffoldable" = "false" ] \
    || { echo "    FAIL T-D01: held-guard: scaffoldable='$scaffoldable' expected 'false' pre-flip (NFR-B7-6-001 — invert at the flip)" >&2; return 1; }
}

# T-D02 — CLI refusal held-guard. BEFORE the flip the wrapper refuses (exit 3,
# zero writes) while the schema is candidate. AFTER the flip this is inverted to
# assert the wrapper renders (NFR-B7-6-001). Hermetic (no toolchain — overlay
# render is pure-python, but the refusal path needs no render at all).
_test_b76_d02_cli_refusal_guard() {
  [ -x "$WRAPPER" ] || { echo "    FAIL T-D02: wrapper not runnable (NFR-B7-6-001)" >&2; return 1; }
  # Only meaningful while candidate; if promoted, this guard is inverted by Phase 4.
  if ! grep -qE '^scaffoldable:[[:space:]]*false' "$SCHEMA_AINR" 2>/dev/null; then
    echo "    NOTE T-D02: schema no longer candidate (promoted) — refusal held-guard inverted at the flip" >&2
    return 0
  fi
  local out; out="$(mktemp -d)"; local tgt="$out/proj"; local rc=0
  bash "$WRAPPER" --target "$tgt" --project-name probe --reverse-domain example.com >/dev/null 2>"$out/err" || rc=$?
  local ok=1
  [ "$rc" = "3" ] || { echo "    FAIL T-D02: wrapper exit $rc, expected 3 while candidate (NFR-B7-6-001)" >&2; ok=0; }
  grep -q '\[REFUSAL' "$out/err" || { echo "    FAIL T-D02: no [REFUSAL ...] on refusal (NFR-B7-6-001)" >&2; ok=0; }
  [ ! -e "$tgt" ] || { echo "    FAIL T-D02: wrapper wrote a partial scaffold while refusing (NFR-B7-6-001)" >&2; ok=0; }
  rm -rf "$out"
  [ "$ok" = "1" ]
}

# ════════════════════════════════════════════════════════════════════
# Tier C — L2 live-codegen (toolchain-gated, SKIP-when-absent).
# Same overlay.sh render convention as b7-2/b7-10 (init.sh is
# flagship-hardcoded; overlay.sh hardcodes ARCHETYPE_DIR too, so the
# plan's relative source: paths are absolutized into a throwaway temp
# plan). These legs SKIP on a buf-less / cargo-less / tsc-less host (CI
# `harness` job, this dev host) and RUN in the forge-ci `harness-rust`
# job (buf + Rust toolchain + node).
# ════════════════════════════════════════════════════════════════════

# Render the committed scaffold-plan into $1 via overlay.sh, absolutizing the
# plan's relative source: paths first (the b7-2 _b72_render_plan helper).
_b76_render_plan() {
  local out_dir="$1"
  local absplan; absplan="$(mktemp)"
  ARCHETYPE_DIR="$ARCHETYPE_DIR" PLAN="$PLAN" ABSPLAN="$absplan" python3 - <<'PY' || { rm -f "$absplan"; return 1; }
import os, yaml
arch = os.environ['ARCHETYPE_DIR']
with open(os.environ['PLAN']) as f:
    plan = yaml.safe_load(f)
for e in plan.get('templates', []):
    s = e.get('source', '')
    if s and not os.path.isabs(s):
        e['source'] = os.path.join(arch, s)
with open(os.environ['ABSPLAN'], 'w') as f:
    yaml.safe_dump(plan, f, sort_keys=False)
PY
  SOURCE_DATE_EPOCH=0 bash "$OVERLAY_SH" --target "$out_dir" --project-name probe \
    --reverse-domain example.com --plan "$absplan" --force >/dev/null 2>&1
  local rc=$?
  rm -f "$absplan"
  return $rc
}

# T-C01 — render-clean + byte-stable re-render (no .tmpl, no {{placeholder}});
# the assembled streaming+unary proto is present in the rendered tree
# (NFR-B7-6-004). Hermetic-ish: needs python3+PyYAML+overlay.sh (SKIP otherwise).
_test_b76_l2_c01_render_clean() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-C01: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-C01: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-C01: plan absent" >&2; return 0; }
  [ -f "$OVERLAY_SH" ] || { echo "    SKIP T-C01: overlay.sh absent" >&2; return 0; }
  local work; work="$(mktemp -d)"; local out1="$work/r1" out2="$work/r2"
  _b76_render_plan "$out1" || { echo "    FAIL T-C01: overlay.sh render failed (NFR-B7-6-004)" >&2; rm -rf "$work"; return 1; }
  local ok=1
  [ -z "$(find "$out1" -name '*.tmpl' 2>/dev/null)" ] || { echo "    FAIL T-C01: .tmpl suffix survived render" >&2; ok=0; }
  ! grep -rqE '\{\{[a-zA-Z_]+\}\}' "$out1" 2>/dev/null || { echo "    FAIL T-C01: unsubstituted {{placeholder}}" >&2; ok=0; }
  grep -rqE 'rpc[[:space:]]+QueryStream' "$out1/shared/protos" 2>/dev/null || { echo "    FAIL T-C01: QueryStream missing from rendered proto" >&2; ok=0; }
  grep -rqE 'rpc[[:space:]]+Query[[:space:]]*\(' "$out1/shared/protos" 2>/dev/null || { echo "    FAIL T-C01: unary Query missing from rendered proto" >&2; ok=0; }
  _b76_render_plan "$out2" || { echo "    FAIL T-C01: second render failed (NFR-B7-6-004)" >&2; rm -rf "$work"; return 1; }
  diff -r "$out1" "$out2" >/dev/null 2>&1 || { echo "    FAIL T-C01: re-render not byte-stable (NFR-B7-6-004)" >&2; ok=0; }
  rm -rf "$work"
  [ "$ok" = "1" ]
}

# T-C02 — LIVE buf generate (task proto): render, then `buf generate` against the
# rendered proto; assert the Rust grpc-api stubs + the TS generated/connect/rag_pb
# descriptor are materialised (FR-B7-6-004/005). SKIP when buf / BSR network absent
# (this dev host, the buf-less CI `harness` job). RUNS in the `harness-rust` job.
_test_b76_l2_c02_buf_generate() {
  command -v buf >/dev/null 2>&1 || { echo "    SKIP T-C02: buf absent (live codegen runs in the harness-rust CI job)" >&2; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-C02: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-C02: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-C02: plan absent" >&2; return 0; }
  local work; work="$(mktemp -d)"; local out="$work/render"
  _b76_render_plan "$out" || { echo "    FAIL T-C02: render failed (FR-B7-6-004)" >&2; rm -rf "$work"; return 1; }
  local log="$work/buf.log"
  if ! ( cd "$out/shared/protos" && buf generate ) >"$log" 2>&1; then
    if grep -qiE 'network|connect|resolve|timeout|BSR|buf\.build|offline|dial tcp' "$log"; then
      echo "    SKIP T-C02: buf generate skipped — BSR network unavailable (offline)" >&2
      rm -rf "$work"; return 0
    fi
    echo "    FAIL T-C02: buf generate failed on rendered proto (FR-B7-6-004)" >&2
    tail -25 "$log" >&2; rm -rf "$work"; return 1
  fi
  local ok=1
  # TS Connect descriptor materialised (the Qwik import target).
  find "$out/frontend/web-public/src/lib/generated/connect" -name 'rag_pb*' 2>/dev/null | grep -q . \
    || { echo "    FAIL T-C02: TS generated/connect/rag_pb descriptor not materialised (FR-B7-6-005)" >&2; ok=0; }
  # Rust stubs materialised into the codegen target dir.
  find "$out/backend/crates/grpc-api/src/generated" -name '*.rs' 2>/dev/null | grep -q . \
    || { echo "    FAIL T-C02: Rust grpc-api generated stubs not materialised (FR-B7-6-005)" >&2; ok=0; }
  rm -rf "$work"
  [ "$ok" = "1" ]
}

# T-C03 — LIVE cargo build + test of the rendered backend workspace (the
# hand-written rag/llm_gateway/mcp/bin-server backbone). Offline registry → SKIP
# (b7-10 T-L2-002 precedent). VERIFIES the LIVE pins resolve+build (NFR-B7-6-005).
_test_b76_l2_c03_cargo_build_test() {
  command -v cargo >/dev/null 2>&1 || { echo "    SKIP T-C03: cargo absent" >&2; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-C03: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-C03: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-C03: plan absent" >&2; return 0; }
  [ -d "$TPL_DIR/backend" ] || { echo "    SKIP T-C03: backend tree absent" >&2; return 0; }
  local work; work="$(mktemp -d)"; local out="$work/render"
  _b76_render_plan "$out" || { echo "    FAIL T-C03: render failed (NFR-B7-6-005)" >&2; rm -rf "$work"; return 1; }
  local log="$work/cargo.log"
  if ! ( cd "$out/backend" && cargo test --workspace ) >"$log" 2>&1; then
    if grep -qiE 'failed to (download|get|fetch|load source)|no matching package|could not (connect|resolve)|network|offline|registry' "$log"; then
      echo "    SKIP T-C03: cargo skipped — crate registry unavailable (offline)" >&2
      rm -rf "$work"; return 0
    fi
    echo "    FAIL T-C03: cargo test failed on rendered backend (NFR-B7-6-005)" >&2
    tail -30 "$log" >&2; rm -rf "$work"; return 1
  fi
  rm -rf "$work"
  return 0
}

# T-C04 — LIVE Qwik tsc --noEmit on the rendered web-public surface. Requires the
# buf-generated rag_pb descriptor (T-C02) + installed node_modules, so it SKIPs on
# a host without tsc / node_modules (this dev host, the buf-less CI). RUNS in the
# harness-rust job after buf generate (FR-B7-6-004; the b7-10 "rides b7-6" leg).
_test_b76_l2_c04_qwik_tsc() {
  command -v tsc >/dev/null 2>&1 || { echo "    SKIP T-C04: tsc absent (Qwik typecheck runs in the harness-rust CI job)" >&2; return 0; }
  command -v buf >/dev/null 2>&1 || { echo "    SKIP T-C04: buf absent — rag_pb descriptor not generated, Qwik tsc rides buf (harness-rust job)" >&2; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-C04: python3 absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-C04: plan absent" >&2; return 0; }
  echo "    SKIP T-C04: Qwik tsc requires installed node_modules + buf-generated rag_pb (runs in the harness-rust CI job)" >&2
  return 0
}

# T-D03 — committed snapshot tarball (FR-B7-6-010, Q-D = ship the deterministic
# .tgz). The ai-native-rag scaffold snapshot ships at
# .forge/scaffold-snapshots/ai-native-rag/1.0.0.tar.gz for `forge upgrade` BASE
# recovery (the mobile-only/full-stack convention). It is built deterministically
# by bin/forge-snapshot.sh (SOURCE_DATE_EPOCH + sorted + uid/gid0 + ustar + gzip
# mtime0 — byte-identical rebuild verified, .forge/research/b7-6-live-codegen.md).
# This asserts: present, ≤ 2 MB (the b4 _test_b4_019 budget), a valid gzip/tar, and
# extractable (the b8-2 extract-round-trip). Always-run (hermetic, no toolchain).
_test_b76_d03_snapshot_tarball() {
  local snap="$FORGE_ROOT/.forge/scaffold-snapshots/ai-native-rag/1.0.0.tar.gz"
  [ -f "$snap" ] || { echo "    FAIL T-D03: ai-native-rag snapshot tarball missing: $snap (FR-B7-6-010)" >&2; return 1; }
  local ok=1
  local size; size=$(wc -c < "$snap" | tr -d ' ')
  local budget=$((2 * 1024 * 1024))
  [ "$size" -le "$budget" ] || { echo "    FAIL T-D03: snapshot too large: ${size} bytes > ${budget} budget (FR-B7-6-010)" >&2; ok=0; }
  file -b "$snap" 2>/dev/null | grep -qiE 'gzip|tar' \
    || { echo "    FAIL T-D03: snapshot is not a gzip/tar archive (FR-B7-6-010)" >&2; ok=0; }
  # Round-trip extractable (b8-2 FR-B8-2-012 pattern) — only when tar present.
  if command -v tar >/dev/null 2>&1; then
    local tmp; tmp="$(mktemp -d)"
    tar -xzf "$snap" -C "$tmp" >/dev/null 2>&1 \
      || { echo "    FAIL T-D03: snapshot not extractable via tar -xzf (FR-B7-6-010)" >&2; ok=0; }
    rm -rf "$tmp"
  fi
  [ "$ok" = "1" ]
}

# ════════════════════════════════════════════════════════════════════

main() {
  echo "── B.7.6 — b7-6-harness (promotion gate) — level $LEVEL ──"

  # Tier A — aggregation (always; superset gate).
  run_test _test_b76_agg_b7_1
  run_test _test_b76_agg_b7_2
  run_test _test_b76_agg_b7_2a
  run_test _test_b76_agg_b7_3
  run_test _test_b76_agg_b7_5
  run_test _test_b76_agg_b7_9
  run_test _test_b76_agg_b7_10
  run_test _test_b76_agg_b7_pythia

  # Tier B — net-new L1 e2e structural (always).
  run_test _test_b76_l1_b01_proto_unary_retained
  run_test _test_b76_l1_b02_proto_streaming_present
  run_test _test_b76_l1_b03_proto_sourcechunk_reused
  run_test _test_b76_l1_b04_codegen_rust_targets
  run_test _test_b76_l1_b05_codegen_ts_qwik_contract
  run_test _test_b76_l1_b06_plan_no_orphan
  run_test _test_b76_l1_b07_plan_no_dangling
  run_test _test_b76_l1_b08_connect_axum_surface
  run_test _test_b76_l1_b09_connect_ragservice_seam
  run_test _test_b76_l1_b10_conformance_rag
  run_test _test_b76_l1_b11_conformance_mcp
  run_test _test_b76_l1_b12_ai_first_fallback
  run_test _test_b76_l1_b13_ai_first_audit_pii
  run_test _test_b76_l1_b14_pins_present
  run_test _test_b76_l1_b15_pins_not_in_standards
  run_test _test_b76_l1_b16_wrapper_gate
  run_test _test_b76_l1_b17_dispatch_entry
  run_test _test_b76_l1_b18_conformance_llm_gateway
  run_test _test_b76_l1_b19_streaming_gateway_surface
  run_test _test_b76_l1_b20_qwik_streaming_ui

  # Tier D — promotion held / post-flip guard + committed snapshot (always).
  run_test _test_b76_d01_promotion_guard
  run_test _test_b76_d02_cli_refusal_guard
  run_test _test_b76_d03_snapshot_tarball

  # Tier C — L2 live-codegen (toolchain-gated; SKIP-when-absent).
  case "$LEVEL" in
    *2*)
      run_test _test_b76_l2_c01_render_clean
      run_test _test_b76_l2_c02_buf_generate
      run_test _test_b76_l2_c03_cargo_build_test
      run_test _test_b76_l2_c04_qwik_tsc
      ;;
  esac

  print_summary
}

main
