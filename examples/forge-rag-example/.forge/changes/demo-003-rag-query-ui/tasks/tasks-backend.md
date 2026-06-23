# Tasks (backend): demo-003-rag-query-ui

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- Layer: backend. TDD-ordered (Article I). Product code in -->
<!-- backend/llm_gateway/src/streaming.rs (b7-10 contract). -->

## Phase 1: Streaming orchestration (FR-BE-020)

- [x] RED — `streaming::tests::healthy_upstream_streams_sources_then_tokens_then_done`
  (one-shot sources frame → token deltas → clean terminal).
- [x] RED — `streaming::tests::channel_capacity_is_a_named_bounded_constant`.
- [x] GREEN — `process_query_stream` spawns a producer over a bounded
  `mpsc` channel; returns a `StreamHandle` wrapping `ReceiverStream`.
- [x] REFACTOR — `STREAM_CHANNEL_CAPACITY = 16` named constant.

## Phase 2: XI.5 fallback paths (FR-BE-022)

- [x] RED — `pre_stream_upstream_failure_degrades_to_fallback_marked_chunk`.
- [x] RED — `mid_stream_upstream_failure_terminates_with_fallback_marker`
  (partial tokens kept).
- [x] RED — `kill_switch_streams_fallback_without_calling_upstream`.
- [x] RED — `over_budget_streams_fallback_not_error`.
- [x] RED — `t3_forbidden_provider_streams_fallback`.
- [x] GREEN — `decide_route` guard before any upstream call;
  `QueryChunk::fallback_terminal` for pre-/mid-stream degradation.

## Phase 3: Prompt-audit (FR-BE-021)

- [x] RED — assert a close-time audit is emitted on success / fallback /
  cancellation.
- [x] GREEN — `redact_pii` the prompt; `audit::emit(PromptAudit{..})` in
  every terminating branch (incl. `cancelled`).

## Phase 4: Cancellation (FR-BE-020)

- [x] RED — `cancel_aborts_the_in_flight_producer`.
- [x] GREEN — `StreamHandle::cancel` aborts the producer; dropped receiver
  also cancels (cooperative).

## Phase 5: Quality + archive

- [x] `cargo clippy --workspace -- -D warnings` (no unwrap/panic in prod).
- [x] `cargo test --workspace` (all `streaming` tests) green.
- [x] Mark all `[x]` (backend layer complete).
