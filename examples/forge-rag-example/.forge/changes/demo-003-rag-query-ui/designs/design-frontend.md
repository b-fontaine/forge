# Design (frontend): demo-003-rag-query-ui

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- Layer: frontend (Qwik streaming UI). Per-layer design (FR-GL-016). -->

Turns the FR-FE-001..003 (frontend) deltas into the Qwik `web-public/`
decisions. Governed by `web-frontend.yaml` and consumes the
`b7-10-streaming` `queryStream` client helper.

## Architecture Decisions

### ADR-FE-001: progressive render via a Qwik signal appended in `for await`

**Context.** FR-FE-001 — the answer must render token-by-token, not as a
single blocking response (Article XI.4).

**Decision.** `routes/index.tsx` consumes `queryStream(question, 0,
signal)` with `for await`, appending each `chunk.tokenDelta` to an
`answer` signal; the one-shot `sources` frame fills a `sources` signal.
The answer paragraph is `aria-live="polite"` so assistive tech announces
progressive updates.

**Consequences.** ✅ Perceived latency drops (first token renders
immediately). ✅ Accessible progressive updates.

### ADR-FE-002: bounded backoff retry → degrade to unary (UI-layer XI.5)

**Context.** FR-FE-002 — transient stream errors must not surface as a
hard failure; the UI must have a fallback.

**Decision.** On a transient stream error the component retries with
`exponentialBackoffMs(attempt, DEFAULT_RETRY_POLICY)` up to
`maxAttempts`; on exhaustion it calls the unary `query()` and surfaces
`fallbackUsed`. The backoff helper + policy are named, tested constants
(no magic numbers). An aborted (Stop/unmount) stream does NOT retry.

**Consequences.** ✅ The UI degrades gracefully (SSE → unary → non-AI
answer). ✅ The retry math is unit-testable. ⚠️ The retry/degrade ladder
is bounded so a persistent outage ends in the unary fallback, not a hang.

### ADR-FE-003: AbortController for Stop + cancel-on-unmount

**Context.** FR-FE-003 — an in-flight stream must be cancellable and must
not outlive the route.

**Decision.** Each attempt creates an `AbortController` kept in a signal;
the Stop button and a `useVisibleTask$` cleanup both call `.abort()`. The
`signal` is threaded into `queryStream` so Connect aborts the underlying
fetch.

**Consequences.** ✅ No orphaned streams on navigation. ✅ Stop is
immediate.

## Standards Applied

| Standard | How |
|---|---|
| `web-frontend.yaml` | Qwik City SSR, Connect-ES v2 client, signals |
| `global/proto-contracts` | consumes `queryStream` (generated from rag.proto) |

## Cross-layer alignment

The frontend's `RagChunk` interface mirrors the backend's `QueryChunk` /
`rag.v1.QueryChunk` (`token_delta`, `sources`, `done`, `fallback_used`) —
the proto is the single source of truth.

## Constitutional compliance gate (frontend)

| Article | Gate-blocked? | Justification |
|---|---|---|
| I — TDD | NO | component test over a fake stream + backoff unit test |
| II — BDD | NO | `features/rag_query_ui.feature` (shared with backend) |
| XI.4/XI.5 — AI-First | NO | progressive render; degrade-to-unary; fallbackUsed |

✅ No violation (frontend layer).
