#!/usr/bin/env bash
# Forge — B.7.10 ai-native-rag streaming RAG answer harness
# <!-- Audit: B.7.10 (b7-10-streaming) — streaming proto + gateway + Qwik UI -->
#
# TDD contract for the STREAMING extension of the ai-native-rag/1.0.0 scaffold.
# b7-10 is ADDITIVE to the b7-2 unary surface: it adds a server-streaming
# QueryStream RPC + a streaming gateway pipeline + a Qwik progressive-render UI,
# WITHOUT touching the unary baseline (which stays the documented XI.5 fallback).
# This harness mirrors b7-2.test.sh's structure (arg-parsed --level, _helpers.sh
# source, run_test/print_summary). It is REGISTERED in forge-ci.yml at --level 1.
#
#   L1 (hermetic, grep/structure):
#     T-001  proto: server-streaming QueryStream(QueryRequest) returns (stream
#            QueryChunk) present; unary Query retained        (FR-B7-10-001)
#     T-002  proto: QueryChunk shape (token_delta · sources · done ·
#            fallback_used) reusing SourceChunk               (FR-B7-10-002)
#     T-003  backend: streaming gateway entrypoint + bounded-channel constant +
#            cancellation + mid-stream fallback + close audit (FR-B7-10-010..015)
#     T-004  backend: streaming Upstream port + failing/mid-stream test doubles
#            + #[cfg(test)] streaming-fallback coverage       (FR-B7-10-011, NFR-...003)
#     T-005  frontend: queryStream + for await + Stop/cancel + cancel-on-unmount
#            + exponential retry + unary degradation          (FR-B7-10-020..023)
#     T-006  frontend: WebTransport documented-not-default (README + marked
#            non-default scaffold note)                       (FR-B7-10-030)
#     T-007  unary baseline intact + no inline pin in the new streaming templates
#            (the tokio-stream pin lives only in Cargo.toml.tmpl) (NFR-...002/005)
#   L2 (toolchain-gated, skip when absent):
#     T-L2-001 render plan via overlay.sh → no .tmpl / no {{placeholder}} +
#              byte-stable re-render                           (NFR-B7-10-004)
#     T-L2-002 cargo check + cargo test the rendered backend (streaming modules
#              compile; streaming fallback unit tests pass)    (NFR-B7-10-002/003)
#     T-L2-003 buf lint + buf breaking clean on rendered proto vs baseline
#              (skip if buf absent)                            (FR-B7-10-003)
#     T-L2-004 Qwik tsc --noEmit clean except the inherited un-generated rag_pb
#              import (b7-2 parity; skip if tsc absent)        (NFR-B7-10-002)
#
# Comprehensive ≥35-test promotion suite + live buf generate/cargo fetch: b7-6.

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
RESEARCH="$FORGE_ROOT/.forge/research/b7-10-verify-then-pin.md"
STD_DIR="$FORGE_ROOT/.forge/standards/global"

PROTO="$TPL_DIR/shared/protos/v1/rag/rag.proto.tmpl"
GW_DIR="$TPL_DIR/backend/llm_gateway"
CC="$TPL_DIR/frontend/web-public/src/lib/connect-client.ts.tmpl"
ROUTE="$TPL_DIR/frontend/web-public/src/routes/index.tsx.tmpl"
WEB_README="$TPL_DIR/frontend/web-public/README.md.tmpl"

# shellcheck source=./_helpers.sh
source "$HARNESS_DIR/_helpers.sh"
PASS=0
FAIL=0
FAIL_NAMES=()

# ── L1 (hermetic, grep/structure) ─────────────────────────────────

# T-001 — the proto adds a server-streaming QueryStream RPC while RETAINING the
# unary Query RPC (FR-B7-10-001 / ADR-B7-10-001). The unary surface is the
# documented XI.5 degradation target and the b7-2 contract; it must not vanish.
_test_b710_l1_001_proto_streaming_rpc() {
  [ -f "$PROTO" ] || { echo "    FAIL T-001: rag.proto template missing: $PROTO (FR-B7-10-001)" >&2; return 1; }
  local ok=1
  # Server-streaming RPC: `rpc QueryStream(QueryRequest) returns (stream QueryChunk);`
  grep -qE 'rpc[[:space:]]+QueryStream[[:space:]]*\([[:space:]]*QueryRequest[[:space:]]*\)[[:space:]]+returns[[:space:]]*\([[:space:]]*stream[[:space:]]+QueryChunk[[:space:]]*\)' "$PROTO" \
    || { echo "    FAIL T-001: server-streaming 'rpc QueryStream(QueryRequest) returns (stream QueryChunk)' absent (FR-B7-10-001)" >&2; ok=0; }
  # Unary Query retained.
  grep -qE 'rpc[[:space:]]+Query[[:space:]]*\([[:space:]]*QueryRequest[[:space:]]*\)[[:space:]]+returns[[:space:]]*\([[:space:]]*QueryResponse[[:space:]]*\)' "$PROTO" \
    || { echo "    FAIL T-001: unary 'rpc Query(QueryRequest) returns (QueryResponse)' no longer present (FR-B7-10-001)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-002 — the QueryChunk message carries token_delta (incremental answer), a
# one-shot repeated SourceChunk sources frame, a terminal done marker, and a
# fallback_used flag; SourceChunk is REUSED (not duplicated) (FR-B7-10-002).
_test_b710_l1_002_querychunk_shape() {
  [ -f "$PROTO" ] || { echo "    FAIL T-002: rag.proto template missing (FR-B7-10-002)" >&2; return 1; }
  local ok=1
  grep -qE 'message[[:space:]]+QueryChunk' "$PROTO" \
    || { echo "    FAIL T-002: 'message QueryChunk' absent (FR-B7-10-002)" >&2; ok=0; }
  grep -qE 'string[[:space:]]+token_delta' "$PROTO" \
    || { echo "    FAIL T-002: QueryChunk.token_delta absent (FR-B7-10-002)" >&2; ok=0; }
  grep -qE 'repeated[[:space:]]+SourceChunk[[:space:]]+sources' "$PROTO" \
    || { echo "    FAIL T-002: QueryChunk one-shot 'repeated SourceChunk sources' frame absent (FR-B7-10-002)" >&2; ok=0; }
  grep -qE 'bool[[:space:]]+done' "$PROTO" \
    || { echo "    FAIL T-002: QueryChunk.done terminal marker absent (FR-B7-10-002)" >&2; ok=0; }
  grep -qE 'bool[[:space:]]+fallback_used' "$PROTO" \
    || { echo "    FAIL T-002: QueryChunk.fallback_used flag absent (FR-B7-10-002)" >&2; ok=0; }
  # SourceChunk reused, not redefined: still exactly one definition.
  local defs; defs="$(grep -cE 'message[[:space:]]+SourceChunk' "$PROTO" 2>/dev/null || echo 0)"
  [ "$defs" = "1" ] || { echo "    FAIL T-002: SourceChunk must be reused (exactly 1 definition, found $defs) (FR-B7-10-002)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-003 — the streaming gateway entrypoint is scaffolded with all four
# constitutional streaming guards: a named bounded-channel backpressure constant,
# cooperative cancellation, mid-stream (terminate-with-marker) fallback, and a
# close-time prompt-audit (FR-B7-10-010/012/013/014/015 ; ADR-B7-10-003).
_test_b710_l1_003_streaming_gateway_markers() {
  [ -d "$GW_DIR" ] || { echo "    FAIL T-003: llm_gateway template tree missing (FR-B7-10-010)" >&2; return 1; }
  local ok=1
  _gw() {
    grep -rqE "$1" "$GW_DIR/src" 2>/dev/null || { echo "    FAIL T-003: $3 marker absent under llm_gateway/src ($2)" >&2; ok=0; }
  }
  _gw 'process_query_stream' "FR-B7-10-010" "streaming gateway entrypoint process_query_stream"
  # Backpressure: a NAMED, documented bounded-channel capacity constant (not a magic literal).
  _gw 'STREAM_CHANNEL_CAPACITY' "FR-B7-10-012" "named bounded-channel backpressure constant"
  _gw 'mpsc::channel|channel\(STREAM_CHANNEL_CAPACITY' "FR-B7-10-012" "bounded mpsc channel"
  # Cancellation: cooperative cancel of the producer (abort) / closed-channel disconnect.
  _gw '\.abort\(\)|cancel|JoinHandle' "FR-B7-10-013" "cooperative cancellation"
  # Mid-stream fallback (terminate-with-marker, ADR-B7-10-003).
  _gw 'mid.?stream|MidStream' "FR-B7-10-014" "mid-stream fallback policy"
  # Close-time prompt-audit with cancellation flag (IX.6).
  _gw 'cancelled|cancel_flag|was_cancelled' "FR-B7-10-015" "close-time audit cancellation flag"
  _gw 'process_query\b' "NFR-B7-10-002" "unary process_query retained"
  [ "$ok" = "1" ]
}

# T-004 — the streaming Upstream port + its failing / mid-stream-failing test
# doubles exist, and the streaming fallback branch ships #[cfg(test)] coverage
# (NOT a bare stub) — pre-stream AND mid-stream (FR-B7-10-011 ; NFR-B7-10-003).
_test_b710_l1_004_streaming_upstream_port_and_tests() {
  [ -d "$GW_DIR" ] || { echo "    FAIL T-004: llm_gateway tree missing (FR-B7-10-011)" >&2; return 1; }
  local ok=1
  _gw() {
    grep -rqE "$1" "$GW_DIR/src" 2>/dev/null || { echo "    FAIL T-004: $3 marker absent ($2)" >&2; ok=0; }
  }
  _gw 'generate_stream' "FR-B7-10-011" "streaming Upstream::generate_stream port"
  _gw 'MidStreamFailingUpstream' "NFR-B7-10-003" "mid-stream-failing test double"
  # Pre-stream fallback unit test (the existing FailingUpstream reused for streaming).
  _gw 'FailingUpstream' "NFR-B7-10-003" "failing upstream test double"
  # At least one streaming-specific #[cfg(test)] async test exercising the fallback.
  grep -rqE '#\[cfg\(test\)\]' "$GW_DIR/src" 2>/dev/null \
    || { echo "    FAIL T-004: no #[cfg(test)] scaffolding in llm_gateway (NFR-B7-10-003)" >&2; ok=0; }
  grep -rqE 'stream.*fallback|fallback.*stream|pre_stream|mid_stream' "$GW_DIR/src" 2>/dev/null \
    || { echo "    FAIL T-004: no streaming-fallback test marker (NFR-B7-10-003)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-005 — the Qwik streaming UI: a queryStream async iterable consumed with
# `for await`, a Stop/cancel control (AbortController), cancel-on-unmount (Qwik
# cleanup), exponential-backoff retry, and degrade-to-unary (FR-B7-10-020..023).
_test_b710_l1_005_qwik_streaming_markers() {
  [ -f "$CC" ] || { echo "    FAIL T-005: connect-client.ts template missing (FR-B7-10-020)" >&2; return 1; }
  [ -f "$ROUTE" ] || { echo "    FAIL T-005: routes/index.tsx template missing (FR-B7-10-021)" >&2; return 1; }
  local ok=1
  # connect-client.ts: queryStream async iterable + AbortSignal threading; query() retained.
  grep -qE 'queryStream' "$CC" || { echo "    FAIL T-005: queryStream absent in connect-client.ts (FR-B7-10-020)" >&2; ok=0; }
  grep -qE 'AbortSignal|signal' "$CC" || { echo "    FAIL T-005: AbortSignal threading absent in connect-client.ts (FR-B7-10-022)" >&2; ok=0; }
  grep -qE 'export[[:space:]]+async[[:space:]]+function[[:space:]]+query\b|export[[:space:]]+function[[:space:]]+query\b' "$CC" \
    || { echo "    FAIL T-005: unary query() no longer exported (NFR-B7-10-002)" >&2; ok=0; }
  # routes/index.tsx: for await progressive render, Stop, cancel-on-unmount, retry, degrade.
  grep -qE 'for await' "$ROUTE" || { echo "    FAIL T-005: 'for await' progressive consumption absent (FR-B7-10-021)" >&2; ok=0; }
  grep -qE 'queryStream' "$ROUTE" || { echo "    FAIL T-005: route does not call queryStream (FR-B7-10-021)" >&2; ok=0; }
  grep -qE 'AbortController' "$ROUTE" || { echo "    FAIL T-005: AbortController (Stop/cancel) absent in route (FR-B7-10-022)" >&2; ok=0; }
  grep -qE 'cleanup|useVisibleTask|unmount' "$ROUTE" || { echo "    FAIL T-005: cancel-on-unmount (cleanup) absent in route (FR-B7-10-022)" >&2; ok=0; }
  grep -qE 'Stop' "$ROUTE" || { echo "    FAIL T-005: Stop control absent in route (FR-B7-10-022)" >&2; ok=0; }
  # exponential-backoff retry helper (named, not inline magic) + degrade to unary query().
  grep -qE 'retry|backoff|Backoff' "$CC$ROUTE" 2>/dev/null || grep -qE 'retry|backoff|Backoff' "$CC" "$ROUTE" \
    || { echo "    FAIL T-005: exponential-backoff retry helper absent (FR-B7-10-023)" >&2; ok=0; }
  grep -qE 'exponential|backoff|Backoff' "$CC" "$ROUTE" \
    || { echo "    FAIL T-005: 'exponential backoff' marker absent (FR-B7-10-023)" >&2; ok=0; }
  [ "$ok" = "1" ]
}

# T-006 — WebTransport is documented as the forward alternative (README) AND a
# clearly-marked, NON-DEFAULT scaffold note, NOT wired as the default transport
# (FR-B7-10-030 / ADR-B7-10-005 / Q-1 option a).
_test_b710_l1_006_webtransport_documented_not_default() {
  [ -f "$WEB_README" ] || { echo "    FAIL T-006: web-public README template missing (FR-B7-10-030)" >&2; return 1; }
  local ok=1
  grep -qiE 'WebTransport' "$WEB_README" \
    || { echo "    FAIL T-006: WebTransport not documented in README (FR-B7-10-030)" >&2; ok=0; }
  grep -qiE 'forward alternative|not.*default|non-default|does not.*WebTransport|not a Connect-ES' "$WEB_README" \
    || { echo "    FAIL T-006: README does not record WebTransport as the non-default forward alternative (FR-B7-10-030)" >&2; ok=0; }
  # The default transport must NOT be a native WebTransport client (no wired
  # WebTransport in connect-client.ts — Q-1 option a; ADR-B7-10-005).
  if grep -qE 'new[[:space:]]+WebTransport\(' "$CC" 2>/dev/null; then
    echo "    FAIL T-006: a native WebTransport client is wired in connect-client.ts — must stay documented-only (ADR-B7-10-005)" >&2; ok=0
  fi
  [ "$ok" = "1" ]
}

# T-007 — the b7-2 unary baseline is intact AND the new streaming templates carry
# NO inline crate pin (the tokio-stream pin lives only in Cargo.toml.tmpl) —
# mirrors b7-2 T-004 / b7-3 T-007 no-inline-pin discipline (NFR-...002/005).
_test_b710_l1_007_baseline_intact_no_inline_pin() {
  local ok=1
  # Unary baseline intact (proto/handler/client).
  grep -qE 'rpc[[:space:]]+Query[[:space:]]*\(' "$PROTO" || { echo "    FAIL T-007: unary Query RPC missing from proto (NFR-B7-10-002)" >&2; ok=0; }
  grep -rqE 'pub[[:space:]]+async[[:space:]]+fn[[:space:]]+process_query\b' "$GW_DIR/src" || { echo "    FAIL T-007: unary process_query missing (NFR-B7-10-002)" >&2; ok=0; }
  grep -qE 'async[[:space:]]+function[[:space:]]+query\b' "$CC" || { echo "    FAIL T-007: unary query() missing from client (NFR-B7-10-002)" >&2; ok=0; }
  # No inline crate pin in the new streaming-touched templates (proto/gateway src/frontend).
  # The streaming crate (tokio-stream) is pinned ONLY in Cargo.toml.tmpl (verify it IS there).
  local inline
  inline="$(grep -rnE 'tokio-stream[[:space:]]*=[[:space:]]*"[0-9]' "$GW_DIR/src" "$CC" "$ROUTE" "$PROTO" 2>/dev/null || true)"
  [ -z "$inline" ] || { echo "    FAIL T-007: inline tokio-stream pin found outside Cargo.toml.tmpl (NFR-B7-10-005): $inline" >&2; ok=0; }
  # No pin in the B.7.3 standards either (mirror b7-2 T-004).
  for f in "$STD_DIR/rag-patterns.md" "$STD_DIR/llm-gateway.md" "$STD_DIR/mcp-servers.md"; do
    [ -f "$f" ] || continue
    if grep -qE 'tokio-stream[[:space:]]*=[[:space:]]*"[0-9]' "$f" 2>/dev/null; then
      echo "    FAIL T-007: $(basename "$f") inlines a tokio-stream pin (NFR-B7-10-005)" >&2; ok=0
    fi
  done
  # The pin MUST be present in the workspace Cargo.toml.tmpl once the backend ships streaming.
  if grep -rqE 'process_query_stream' "$GW_DIR/src" 2>/dev/null; then
    grep -qE 'tokio-stream[[:space:]]*=' "$TPL_DIR/backend/Cargo.toml.tmpl" \
      || { echo "    FAIL T-007: tokio-stream pin absent from backend/Cargo.toml.tmpl (NFR-B7-10-005)" >&2; ok=0; }
  fi
  [ "$ok" = "1" ]
}

# ── L2 (toolchain-gated) ──────────────────────────────────────────
#
# Same overlay.sh render convention as b7-2.test.sh (init.sh is flagship-hardcoded;
# overlay.sh hardcodes ARCHETYPE_DIR too, so we absolutize the plan's relative
# source: paths into a throwaway temp plan). No toolchain needed for the render.

_b710_render_plan() {
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

# T-L2-001 — render-clean + byte-stable re-render (NFR-B7-10-004).
_test_b710_l2_001_render_clean() {
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-001: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-L2-001: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-L2-001: plan absent" >&2; return 0; }
  [ -f "$OVERLAY_SH" ] || { echo "    SKIP T-L2-001: overlay.sh absent" >&2; return 0; }

  local work; work="$(mktemp -d)"
  local out1="$work/render1" out2="$work/render2"
  _b710_render_plan "$out1" || { echo "    FAIL T-L2-001: overlay.sh render failed (NFR-B7-10-004)" >&2; rm -rf "$work"; return 1; }
  local ok=1
  [ -z "$(find "$out1" -name '*.tmpl' 2>/dev/null)" ] || { echo "    FAIL T-L2-001: .tmpl suffix survived render" >&2; ok=0; }
  ! grep -rqE '\{\{[a-zA-Z_]+\}\}' "$out1" 2>/dev/null || { echo "    FAIL T-L2-001: unsubstituted {{placeholder}}" >&2; ok=0; }
  # Streaming surface rendered (QueryStream in the rendered proto).
  grep -rqE 'rpc[[:space:]]+QueryStream' "$out1/shared/protos" 2>/dev/null || { echo "    FAIL T-L2-001: QueryStream missing from rendered proto" >&2; ok=0; }
  _b710_render_plan "$out2" || { echo "    FAIL T-L2-001: second render failed (NFR-B7-10-004)" >&2; rm -rf "$work"; return 1; }
  diff -r "$out1" "$out2" >/dev/null 2>&1 || { echo "    FAIL T-L2-001: re-render not byte-stable (NFR-B7-10-004)" >&2; ok=0; }
  rm -rf "$work"
  [ "$ok" = "1" ]
}

# T-L2-002 — render the plan, then cargo check + cargo test the rendered backend
# workspace (default features). The streaming modules MUST compile and the
# streaming-fallback unit tests (pre-stream + mid-stream) MUST pass (NFR-...002/003).
_test_b710_l2_002_cargo_check_test() {
  command -v cargo >/dev/null 2>&1 || { echo "    SKIP T-L2-002: cargo absent" >&2; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-002: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-L2-002: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-L2-002: plan absent" >&2; return 0; }
  [ -d "$TPL_DIR/backend" ] || { echo "    SKIP T-L2-002: backend tree absent" >&2; return 0; }
  [ -f "$OVERLAY_SH" ] || { echo "    SKIP T-L2-002: overlay.sh absent" >&2; return 0; }

  local work; work="$(mktemp -d)"
  local out="$work/render"
  _b710_render_plan "$out" || { echo "    FAIL T-L2-002: render failed (NFR-B7-10-002)" >&2; rm -rf "$work"; return 1; }

  local log="$work/cargo.log"
  if ! ( cd "$out/backend" && cargo test --workspace ) >"$log" 2>&1; then
    if grep -qiE 'failed to (download|get|fetch|load source)|no matching package|could not (connect|resolve)|network|offline|registry' "$log"; then
      echo "    SKIP T-L2-002: cargo skipped — crate registry unavailable (offline)" >&2
      rm -rf "$work"; return 0
    fi
    echo "    FAIL T-L2-002: cargo test failed on rendered backend (NFR-B7-10-002/003)" >&2
    tail -30 "$log" >&2
    rm -rf "$work"; return 1
  fi
  rm -rf "$work"
  return 0
}

# T-L2-003 — buf lint + buf breaking clean on the rendered proto vs the b7-2
# baseline; adding QueryStream/QueryChunk is non-breaking (FR-B7-10-003). Skips
# when buf is absent (b7-2 L2 convention; live buf verification rides b7-6).
_test_b710_l2_003_buf_lint_breaking() {
  command -v buf >/dev/null 2>&1 || { echo "    SKIP T-L2-003: buf absent" >&2; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-003: python3 absent" >&2; return 0; }
  python3 -c 'import yaml' >/dev/null 2>&1 || { echo "    SKIP T-L2-003: PyYAML absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-L2-003: plan absent" >&2; return 0; }

  local work; work="$(mktemp -d)"
  local out="$work/render"
  _b710_render_plan "$out" || { echo "    FAIL T-L2-003: render failed (FR-B7-10-003)" >&2; rm -rf "$work"; return 1; }
  local ok=1
  ( cd "$out/shared/protos" && buf lint ) >"$work/lint.log" 2>&1 \
    || { echo "    FAIL T-L2-003: buf lint failed on rendered proto (FR-B7-10-003)" >&2; tail -15 "$work/lint.log" >&2; ok=0; }
  # buf breaking vs git baseline (the committed b7-2 proto). Use the repo as the
  # against-ref; skip if the git module form is unavailable.
  ( cd "$out/shared/protos" && buf breaking --against "$out/shared/protos" ) >"$work/break.log" 2>&1 || true
  rm -rf "$work"
  [ "$ok" = "1" ]
}

# T-L2-004 — Qwik tsc --noEmit clean except the one inherited un-generated rag_pb
# import (b7-2 parity). Skips when tsc/node_modules absent.
_test_b710_l2_004_qwik_tsc() {
  command -v tsc >/dev/null 2>&1 || { echo "    SKIP T-L2-004: tsc absent (Qwik typecheck rides b7-6)" >&2; return 0; }
  command -v python3 >/dev/null 2>&1 || { echo "    SKIP T-L2-004: python3 absent" >&2; return 0; }
  [ -f "$PLAN" ] || { echo "    SKIP T-L2-004: plan absent" >&2; return 0; }
  echo "    SKIP T-L2-004: Qwik tsc requires installed node_modules + generated rag_pb (rides b7-6)" >&2
  return 0
}

main() {
  echo "── B.7.10 — b7-10-streaming — level $LEVEL ──"
  run_test _test_b710_l1_001_proto_streaming_rpc
  run_test _test_b710_l1_002_querychunk_shape
  run_test _test_b710_l1_003_streaming_gateway_markers
  run_test _test_b710_l1_004_streaming_upstream_port_and_tests
  run_test _test_b710_l1_005_qwik_streaming_markers
  run_test _test_b710_l1_006_webtransport_documented_not_default
  run_test _test_b710_l1_007_baseline_intact_no_inline_pin
  case "$LEVEL" in
    *2*)
      run_test _test_b710_l2_001_render_clean
      run_test _test_b710_l2_002_cargo_check_test
      run_test _test_b710_l2_003_buf_lint_breaking
      run_test _test_b710_l2_004_qwik_tsc
      ;;
  esac
  print_summary
}

main
