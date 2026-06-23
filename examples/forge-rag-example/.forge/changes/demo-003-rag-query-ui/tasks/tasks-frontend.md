# Tasks (frontend): demo-003-rag-query-ui

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- Layer: frontend. TDD-ordered (Article I). Product code in -->
<!-- frontend/web-public/src/{routes/index.tsx,lib/connect-client.ts}. -->

## Phase 1: queryStream client helper (FR-FE-001)

- [x] RED — unit test: `queryStream` yields `RagChunk`s mapping
  `token_delta`/`sources`/`done`/`fallback_used` from the generated type.
- [x] GREEN — `queryStream(question, topK, signal)` async generator over
  `ragClient.queryStream(...)` (Connect-ES v2 server-streaming).

## Phase 2: Progressive render (FR-FE-001)

- [x] RED — component test: feeding `["Forge"," enforces"," TDD"]`
  renders the answer progressively as "Forge enforces TDD" and renders
  the one-shot sources.
- [x] GREEN — `routes/index.tsx` appends `chunk.tokenDelta` to the
  `answer` signal in `for await`; `aria-live="polite"`.

## Phase 3: Backoff + degrade-to-unary (FR-FE-002)

- [x] RED — unit test: `exponentialBackoffMs(attempt)` = base·2^attempt
  capped at `maxDelayMs`.
- [x] RED — component test: exhausting stream retries degrades to the
  unary `query()` path and sets `fallbackUsed`.
- [x] GREEN — bounded retry loop with `DEFAULT_RETRY_POLICY`; on
  exhaustion call `query()`; surface `fallbackUsed`.
- [x] GREEN — `fallbackUsed` indicator block (role="status").

## Phase 4: Stop + cancel-on-unmount (FR-FE-003)

- [x] RED — component test: Stop aborts the in-flight stream; unmount
  aborts it too.
- [x] GREEN — per-attempt `AbortController` in a signal; Stop handler +
  `useVisibleTask$` cleanup both `.abort()`; `signal` threaded into
  `queryStream`.

## Phase 5: Quality + archive

- [x] Qwik lint + type-check; component test suite green.
- [x] Mark all `[x]` (frontend layer complete).
