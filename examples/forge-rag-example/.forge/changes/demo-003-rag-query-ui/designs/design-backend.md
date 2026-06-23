# Design (backend): demo-003-rag-query-ui

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- Layer: backend (gateway streaming path). Per-layer design (FR-GL-016). -->

Turns the FR-BE-020..022 (backend) deltas into the `llm_gateway/`
streaming decisions. Governed by `global/llm-gateway.md` and consumes the
`b7-10-streaming` `QueryStream` contract.

## Architecture Decisions

### ADR-BE-001: bounded mpsc channel + spawned producer for QueryStream

**Context.** FR-BE-020 requires server-streaming with backpressure and
cancellation.

**Decision.** `process_query_stream` spawns a producer task that sends
`QueryChunk`s through a bounded `tokio::sync::mpsc` channel
(`STREAM_CHANNEL_CAPACITY = 16`); the handler forwards the
`ReceiverStream` to the Connect server-streaming response. A slow
consumer suspends the producer (`send().await`); a dropped receiver
(client Stop / unmount) makes `send().await` return `Err`, which the
producer treats as cooperative cancellation.

**Consequences.** ✅ Memory-bounded under a slow consumer. ✅
Cancellation is cooperative (no orphaned generation). ⚠️ The real
async-openai streaming upstream is wired live at b7-6; tests inject a
`StreamingUpstream` fake.

### ADR-BE-002: route guards run before any upstream call (XI.5)

**Context.** FR-BE-022 — kill-switch, over-budget, and tier-refusal must
prevent egress, not just mark the result.

**Decision.** `decide_route(config, estimated_tokens)` runs first; a
`Route::Fallback` emits a single fallback-marked terminal chunk carrying
the ranked sources (the non-AI answer) with **no upstream call**. A
mid-stream upstream error keeps partial tokens and terminates with a
`fallback_used = true` marker (ADR-B7-10-003). The unary `Query` path is
the documented degradation target (ADR-B7-10-001).

**Consequences.** ✅ T3 / kill-switch / over-budget never reach the
upstream. ✅ Partial answers are preserved on mid-stream failure.

### ADR-BE-003: close-time PII-redacted prompt-audit (IX.6/XI.6)

**Context.** FR-BE-021 — every terminating case must be audited without
leaking prompt text.

**Decision.** The prompt is `redact_pii`'d before any span; a
`PromptAudit` record (model, tenant, tier, token counts,
`fallback_invoked`, `cancelled`) is `audit::emit`'d in every terminating
branch (success / fallback / cancellation).

**Consequences.** ✅ Uniform audit coverage incl. cancellation. ✅ No raw
prompt in logs/spans.

## Standards Applied

| Standard | How |
|---|---|
| `global/llm-gateway` | streaming proxy, prompt-audit, budget/kill-switch, XI.5 fallback |
| `global/proto-contracts` | consumes `RagService.QueryStream` (b7-10) |
| `rust/async-patterns` | tokio mpsc + spawned producer + ReceiverStream |

## Constitutional compliance gate (backend)

| Article | Gate-blocked? | Justification |
|---|---|---|
| I — TDD | NO | `streaming::tests::*` cover happy/fallback/cancel/budget/T3 |
| IX.6 — Prompt audit | NO | close-time PII-redacted audit in every branch |
| XI.4/XI.5 — AI-First | NO | event-driven stream; guards before upstream; fallback marker |

✅ No violation (backend layer).
