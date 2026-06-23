# Specs: demo-003-rag-query-ui

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- Layers: [backend, frontend] — multi-layer. Per-layer delta: FR-BE-* + FR-FE-*. -->

This spec follows the Article IV delta convention with **per-layer** FR
prefixes (Article IV multi-layer + FR-GL-016): `FR-BE-*` for the backend
gateway layer, `FR-FE-*` for the Qwik frontend layer. The implementation
lives in `backend/llm_gateway/` and `frontend/web-public/`.

## ADDED Requirements — Backend (gateway streaming path)

### FR-BE-020: Server-streaming QueryStream with one-shot sources frame

- **MUST** — the gateway orchestrates `RagService.QueryStream`: emit a
  one-shot `sources` frame (the retrieved chunks) before any token, then
  stream `token_delta` frames, then a terminal frame (`done = true`).
- **MUST** — backpressure is bounded by a named channel capacity
  constant (no unbounded buffering).

**Implemented in:** `backend/llm_gateway/src/streaming.rs`
(`process_query_stream`, `STREAM_CHANNEL_CAPACITY`).
**Constitution reference:** Articles XI.4, `llm-gateway.md`.
**Testable:** yes — `streaming::tests::healthy_upstream_streams_sources_then_tokens_then_done`.

### FR-BE-021: Prompt-audit span across the stream (IX.6)

- **MUST** — a PII-redacted close-time prompt-audit record is emitted in
  every terminating case (success, fallback, cancellation), carrying the
  final token counts, `fallback_invoked`, and `cancelled`.
- **MUST** — raw prompt text never reaches a log/span (XI.6 PII guard).

**Implemented in:** `backend/llm_gateway/src/{streaming.rs,audit.rs}`.
**Constitution reference:** Articles IX.6, XI.6.
**Testable:** yes — audit emission is exercised by the streaming tests.

### FR-BE-022: XI.5 fallback degrades the stream to a fallback-marked chunk

- **MUST** — the kill-switch / over-budget / tier-refusal guards run
  before any upstream call; a refused route emits a single fallback-marked
  terminal chunk (pre-stream XI.5) with no upstream call.
- **MUST** — a mid-stream upstream failure keeps the partial tokens
  already delivered and terminates with a `fallback_used = true`,
  `done = true` marker (terminate-with-marker, `b7-10` ADR-B7-10-003).
- **MUST** — the unary `RagService.Query` path is retained as the
  documented degradation target (`b7-10` ADR-B7-10-001).

**Implemented in:** `backend/llm_gateway/src/streaming.rs`
(`decide_route`, `QueryChunk::fallback_terminal`).
**Constitution reference:** Article XI.5.
**Testable:** yes — `streaming::tests::{pre_stream,mid_stream,kill_switch,over_budget,t3_*}`.

## ADDED Requirements — Frontend (Qwik streaming UI)

### FR-FE-001: Progressive token render via queryStream

- **MUST** — the query screen consumes `queryStream` with `for await`,
  appending each `token_delta` to a Qwik signal so the answer renders
  progressively (Article XI.4 — no blocking synchronous AI call).
- **MUST** — the one-shot `sources` frame renders the grounding chunks.

**Implemented in:** `frontend/web-public/src/routes/index.tsx`,
`frontend/web-public/src/lib/connect-client.ts` (`queryStream`).
**Constitution reference:** Article XI.4, `web-frontend.yaml`.
**Testable:** yes — Qwik component test over a fake stream.

### FR-FE-002: fallbackUsed indicator + degrade-to-unary

- **MUST** — a `fallbackUsed` indicator surfaces whenever the served
  answer used the non-AI fallback (whichever path served it).
- **MUST** — on repeated transient stream errors the UI applies
  exponential-backoff retry and, on exhausting the bounded attempts,
  **degrades to the unary `query()` path** (UI-layer XI.5 fallback).
- **SHALL** — the backoff is a named, tested helper (no magic numbers).

**Implemented in:** `frontend/web-public/src/routes/index.tsx`,
`connect-client.ts` (`exponentialBackoffMs`, `DEFAULT_RETRY_POLICY`).
**Constitution reference:** Article XI.5.
**Testable:** yes — backoff unit test + the degrade-to-unary component test.

### FR-FE-003: Stop control + cancel-on-unmount

- **MUST** — a Stop control aborts the in-flight stream via an
  `AbortController`; the stream is also aborted on component unmount so no
  orphaned stream survives navigation.

**Implemented in:** `frontend/web-public/src/routes/index.tsx`
(`AbortController`, `useVisibleTask$` cleanup).
**Constitution reference:** `web-frontend.yaml` (FR-B7-10-022).
**Testable:** yes — component test asserts abort on Stop / unmount.

## Acceptance Criteria (Gherkin)

### AC-001: streaming happy path renders progressively

```gherkin
Given the gateway upstream streams the tokens "Forge" " enforces" " TDD"
When the user submits a question through the Qwik query screen
Then the grounding sources render first
And the answer renders progressively as "Forge enforces TDD"
And fallbackUsed is false
```

### AC-002: fallback path degrades to unary and shows the indicator

```gherkin
Given the streaming upstream is unavailable
When the user submits a question
And the bounded stream retries are exhausted
Then the UI degrades to the unary query path
And the fallbackUsed indicator is shown
```

## Cross-layer contract alignment

The two layers align on `shared/protos/v1/rag/rag.proto`
(`RagService.QueryStream` returning `stream QueryChunk` with
`token_delta`, `sources`, `done`, `fallback_used`) — the single source of
truth shipped by `b7-10-streaming` and consumed by both layers.

## Scope

**In scope:** FR-BE-020..022 (gateway streaming) + FR-FE-001..003 (Qwik
UI). **Out of scope:** the transport itself (`b7-10`), the `rag/`
internals (demo-001), the MCP surface (demo-002), live LLM calls.
