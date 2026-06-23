# Proposal: demo-003-rag-query-ui

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- Layers: [backend, frontend] — multi-layer (Janus, FR-GL-015) -->

## Problem

demo-001 built the retriever and demo-002 exposed it over MCP, but the
archetype's flagship UX — a **streaming** RAG query surface a human uses
in the browser — is undemonstrated. Adopters need a concrete
**multi-layer** change showing how the Qwik `web-public` UI consumes the
LLM gateway's server-streamed answer, how the answer renders
progressively token-by-token, and how the Article XI.5 fallback surfaces
in the UI. This is also the example's demonstration of **Janus**
cross-layer orchestration (≥ 2 layers → per-layer designs + tasks).

## Solution

A multi-layer (`[backend, frontend]`) change wiring the streaming RAG
query end-to-end:

- **Backend (`llm_gateway/`)** — the server-streaming
  `RagService.QueryStream` path (from `b7-10-streaming`): retrieve →
  emit a one-shot `sources` frame → stream `token_delta` frames → a
  terminal frame. The **prompt-audit span (IX.6)** wraps the whole
  stream; the **token budget + kill-switch** and **tier refusal** guards
  run *before* any upstream call. On a refused route or an upstream
  failure the stream **degrades to a fallback-marked terminal chunk**
  (Article XI.5), consistent with the unary `RagService.Query` path being
  retained as the degradation target (`b7-10` ADR-B7-10-001).
- **Frontend (Qwik `web-public/`)** — a query screen consuming
  `queryStream` with `for await`, **appending each `token_delta` to a
  signal so the answer renders progressively** (Article XI.4 — no
  blocking AI call). It renders the grounding sources and a
  **`fallbackUsed` indicator**. On repeated transient stream errors it
  applies exponential-backoff retry and, on exhaustion, **degrades to the
  unary `query()` path** (the UI-layer XI.5 fallback). A Stop control
  cancels the in-flight stream (cancel-on-unmount too).

This is the cross-layer surface that naturally triggers Janus and
demonstrates per-layer delta semantics (FR-BE-* + FR-FE-*).

This demo is **deliberately illustrative** — its purpose is to
demonstrate the multi-layer streaming discipline + the AI-First gateway
path, not to ship a tuned production UI.

## Scope In

- Backend: the `QueryStream` gateway path with prompt-audit (IX.6),
  budget/kill-switch/tier guards, and the XI.5 pre-/mid-stream fallback
  degrading to a fallback-marked terminal chunk.
- Frontend: the Qwik streaming query component (progressive token
  render, sources, `fallbackUsed` indicator, Stop/cancel, retry →
  degrade-to-unary).
- The `shared/protos/v1/rag/rag.proto` `RagService.QueryStream` contract
  (consumed, shipped by `b7-10-streaming`).
- BDD: the streaming happy path + the `fallbackUsed` (degrade-to-unary)
  path.

## Scope Out

- The streaming **transport** itself (Connect server-streaming / SSE) —
  delivered by `b7-10-streaming`; this demo **consumes** it.
- The `rag/` pipeline internals (demo-001) and the MCP surface (demo-002).
- No live LLM upstream (tests inject a streaming upstream fake; no
  network).
- No WebTransport (a documented forward alternative, not a Connect-ES
  transport — `b7-10` ADR-B7-10-005).

## Impact

- **Users affected**: adopters building the human-facing streaming RAG
  surface; demonstrates Janus multi-layer orchestration.
- **Technical impact**: illustrative; backend product code lives in
  `backend/llm_gateway/src/streaming.rs`, frontend in
  `frontend/web-public/src/{routes/index.tsx,lib/connect-client.ts}`.
- **Dependencies**: demo-001 (retriever); **`b7-10-streaming`** (hard —
  the `QueryStream`/`queryStream` contract + the streaming templates the
  tree was rendered from).
- **Risk level**: Low-Medium (multi-layer; illustrative; no network).

## Constitution Compliance

- **Article I (TDD)**: backend `streaming.rs` ships RED→GREEN tests
  (happy, pre-/mid-stream fallback, kill-switch, budget, T3,
  cancellation); frontend ships a `queryStream`/backoff component test.
- **Article II (BDD)**: `features/rag_query_ui.feature` covers the
  streaming happy + fallback paths.
- **Article III (Specs before code)**: per-layer specs → per-layer
  designs → per-layer tasks precede the (already-scaffolded) impl.
- **Article IV (Delta)**: per-layer delta — FR-BE-* + FR-FE-*.
- **Article IX.6 (Prompt audit)**: the gateway audits the streaming path.
- **Article XI.4/XI.5 (AI-First)**: progressive (event-driven) render;
  the stream degrades to a fallback-marked chunk / the unary path.

---

**Gate**: Proposal complete. Next → `/forge:specify demo-003-rag-query-ui`.
