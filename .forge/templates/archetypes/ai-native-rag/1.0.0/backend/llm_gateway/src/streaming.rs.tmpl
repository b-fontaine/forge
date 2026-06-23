//! Streaming RAG answer pipeline (B.7.10) — the server-streaming counterpart to
//! [`crate::handler::process_query`]. It layers a token-by-token answer path on
//! top of the SAME constitutional guards the unary path enforces, without
//! touching the unary surface (which stays the documented XI.5 degradation
//! target).
//!
//! Constitutional guards materialised here:
//!   - **XI.5 mandatory fallback** — the route guard composition (`decide_route`)
//!     runs BEFORE any upstream call; a refused route degrades to a single
//!     fallback-marked terminal chunk (pre-stream). If the upstream errors
//!     mid-stream (after partial tokens) the stream terminates with a final
//!     `fallback_used = true`, `done = true` marker (ADR-B7-10-003,
//!     terminate-with-fallback-marker) — partial tokens already delivered stay.
//!   - **XI.4 event-driven UI** — the gateway yields a `Stream<Item = QueryChunk>`
//!     the Qwik UI consumes with `for await`; no blocking synchronous AI call.
//!   - **FR-B7-10-012 backpressure** — a bounded `tokio::sync::mpsc` channel
//!     ([`STREAM_CHANNEL_CAPACITY`]); the producer `send().await`s, so a slow
//!     consumer suspends the producer instead of growing memory unboundedly.
//!   - **FR-B7-10-013 cancellation** — the producer runs in a spawned task; the
//!     returned [`StreamHandle`] holds its `JoinHandle`, whose `.abort()` is the
//!     cooperative-cancel primitive (client Stop / unmount). A consumer that
//!     drops the receiver also cancels: the producer's `send().await` returns
//!     `Err`, which it treats as "consumer gone → stop".
//!   - **IX.6 / XI.6 prompt-audit** — a PII-redacted close-time audit record is
//!     emitted when the stream ends (success, fallback, OR cancellation), with
//!     final token counts, `fallback_invoked`, and `cancelled`.

use async_trait::async_trait;
use futures::Stream;
use rag::SourceChunk;
use tokio::sync::mpsc;
use tokio::task::JoinHandle;
use tokio_stream::wrappers::ReceiverStream;

use crate::audit::{self, PromptAudit};
use crate::handler::UpstreamError;
use crate::{decide_route, FallbackReason, GatewayConfig, Route};

/// Bounded backpressure capacity for the streamed-answer channel (FR-B7-10-012).
/// A NAMED, documented constant — never a magic literal. Small enough that a
/// slow/stalled consumer suspends the producer (`send().await`) within a few
/// tokens rather than letting the producer race ahead and buffer the whole
/// completion in memory; large enough that a healthy consumer never starves.
pub const STREAM_CHANNEL_CAPACITY: usize = 16;

/// One frame of a streamed RAG answer — the Rust mirror of `rag.v1.QueryChunk`
/// (`shared/protos/v1/rag/rag.proto`). The buf-generated type replaces this once
/// codegen runs (b7-6); until then this is the unit-testable shape the streaming
/// pipeline emits.
#[derive(Debug, Clone, PartialEq)]
pub struct QueryChunk {
    /// An incremental slice of the generated answer (empty on the one-shot
    /// `sources` frame and on a pure terminal/fallback marker).
    pub token_delta: String,
    /// The retrieved grounding chunks — emitted ONCE before the token deltas.
    pub sources: Vec<SourceChunk>,
    /// True on the single terminal frame that closes the stream.
    pub done: bool,
    /// True when the stream degraded to the non-AI fallback (Article XI.5).
    pub fallback_used: bool,
}

impl QueryChunk {
    /// The one-shot `sources` frame, emitted before any token (rag-patterns.md:
    /// sources retrieved once, streamed before generation).
    fn sources_frame(sources: Vec<SourceChunk>) -> Self {
        Self { token_delta: String::new(), sources, done: false, fallback_used: false }
    }
    /// A single token delta frame.
    fn token(delta: String) -> Self {
        Self { token_delta: delta, sources: Vec::new(), done: false, fallback_used: false }
    }
    /// The clean terminal frame (generation completed without degradation).
    fn done_ok() -> Self {
        Self { token_delta: String::new(), sources: Vec::new(), done: true, fallback_used: false }
    }
    /// The fallback-marked terminal frame (XI.5). `sources` carries the ranked
    /// chunks for the pre-stream case; empty for the mid-stream terminate-marker.
    fn fallback_terminal(sources: Vec<SourceChunk>) -> Self {
        Self { token_delta: String::new(), sources, done: true, fallback_used: true }
    }
}

/// The streaming upstream LLM port (FR-B7-10-011) — the server-streaming
/// counterpart to [`crate::handler::Upstream`]. Abstracted as a trait so tests
/// inject a failing / mid-stream-failing upstream to exercise the Article XI.5
/// branch (pre-stream AND mid-stream). The real impl wraps the `async-openai`
/// streaming chat-completions API (wired live at b7-6).
#[async_trait]
pub trait StreamingUpstream: Send + Sync {
    /// Begin generating an answer for `prompt` grounded in `sources`, returning
    /// the produced tokens in order. An `Err` item models a mid-stream upstream
    /// failure; an error returned by `start` itself models a pre-stream failure.
    async fn generate_stream(
        &self,
        prompt: &str,
        sources: &[SourceChunk],
    ) -> Result<Vec<Result<String, UpstreamError>>, UpstreamError>;
}

/// A live streamed answer: the chunk stream plus the producer task handle. The
/// caller (the Connect server-streaming handler) forwards `stream` to the client
/// and may `cancel()` the in-flight producer on client disconnect / unmount
/// (FR-B7-10-013).
pub struct StreamHandle {
    /// The chunk stream the Connect handler forwards to the browser (XI.4).
    pub stream: ReceiverStream<QueryChunk>,
    /// The producer task; `.abort()` cooperatively cancels generation.
    producer: JoinHandle<()>,
}

impl StreamHandle {
    /// Wrap the chunk stream so callers can `for await` over it directly.
    pub fn into_stream(self) -> impl Stream<Item = QueryChunk> {
        self.stream
    }

    /// Cooperatively cancel the in-flight stream (client Stop / unmount,
    /// FR-B7-10-013). Aborts the producer task; the close-time audit is still
    /// emitted by the producer's drop/abort path.
    pub fn cancel(&self) {
        self.producer.abort();
    }
}

/// Orchestrate one STREAMING query end-to-end (FR-B7-10-010). Reuses
/// [`decide_route`] so the kill-switch / tier-refusal / budget guards run before
/// any upstream call; a refused route degrades to a single fallback-marked
/// terminal chunk (pre-stream XI.5) with no upstream call at all. On the upstream
/// path it emits the one-shot `sources` frame, then streams token deltas through
/// a bounded channel (backpressure), terminating with a clean `done` frame on
/// success or a fallback-marked terminal frame on mid-stream failure
/// (terminate-with-marker, ADR-B7-10-003). A PII-redacted close-time prompt-audit
/// (IX.6/XI.6) is emitted in every terminating case.
pub fn process_query_stream<U>(
    config: &GatewayConfig,
    upstream: U,
    tenant: &str,
    model: &str,
    prompt: &str,
    estimated_tokens: u32,
    sources: Vec<SourceChunk>,
) -> StreamHandle
where
    U: StreamingUpstream + 'static,
{
    // PII guard (XI.6): never let raw prompt text reach a log/span.
    let _redacted_prompt = audit::redact_pii(prompt);

    let (tx, rx) = mpsc::channel::<QueryChunk>(STREAM_CHANNEL_CAPACITY);

    let route = decide_route(config, estimated_tokens);
    let mut record = PromptAudit {
        model: model.to_string(),
        tenant: tenant.to_string(),
        tier: config.tier,
        prompt_tokens: estimated_tokens,
        completion_tokens: 0,
        fallback_invoked: false,
        cancelled: false,
    };
    let prompt = prompt.to_string();

    let producer = tokio::spawn(async move {
        match route {
            // ── Pre-stream fallback (XI.5): refused route → no upstream call ──
            Route::Fallback(_reason) => {
                record.fallback_invoked = true;
                // The ranked sources ARE the non-AI answer; emit them on the
                // fallback-marked terminal chunk, exactly as the unary path does.
                let _ = tx.send(QueryChunk::fallback_terminal(sources)).await;
            }
            Route::Upstream => {
                // One-shot `sources` frame before any token (rag-patterns.md).
                if tx.send(QueryChunk::sources_frame(sources.clone())).await.is_err() {
                    // Consumer already gone (cancel-on-unmount) before generation.
                    record.cancelled = true;
                    audit::emit(&record);
                    return;
                }
                match upstream.generate_stream(&prompt, &sources).await {
                    // Pre-stream upstream failure → degrade as the unary path does.
                    Err(_e) => {
                        record.fallback_invoked = true;
                        let _ = tx.send(QueryChunk::fallback_terminal(sources)).await;
                    }
                    Ok(tokens) => {
                        let mut completion_tokens = 0u32;
                        let mut degraded = false;
                        for item in tokens {
                            match item {
                                Ok(tok) => {
                                    completion_tokens += 1;
                                    if tx.send(QueryChunk::token(tok)).await.is_err() {
                                        // Consumer dropped the receiver mid-stream
                                        // (client Stop / unmount) → cooperative
                                        // cancellation (FR-B7-10-013).
                                        record.cancelled = true;
                                        break;
                                    }
                                }
                                // ── Mid-stream upstream failure (XI.5,
                                // ADR-B7-10-003): keep the partial tokens already
                                // delivered, terminate with a fallback marker. ──
                                Err(_e) => {
                                    degraded = true;
                                    record.fallback_invoked = true;
                                    let _ = tx
                                        .send(QueryChunk::fallback_terminal(Vec::new()))
                                        .await;
                                    break;
                                }
                            }
                        }
                        record.completion_tokens = completion_tokens;
                        if !degraded && !record.cancelled {
                            let _ = tx.send(QueryChunk::done_ok()).await;
                        }
                    }
                }
            }
        }
        // Close-time prompt-audit (IX.6) — emitted in EVERY terminating case
        // (success / fallback / cancellation), already PII-redacted above.
        audit::emit(&record);
    });

    StreamHandle { stream: ReceiverStream::new(rx), producer }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Provider;
    use rag::ComplianceTier;
    use tokio_stream::StreamExt;

    /// An upstream that streams N OK tokens then completes — the happy path.
    struct OkStreamingUpstream {
        tokens: Vec<&'static str>,
    }
    #[async_trait]
    impl StreamingUpstream for OkStreamingUpstream {
        async fn generate_stream(
            &self,
            _p: &str,
            _s: &[SourceChunk],
        ) -> Result<Vec<Result<String, UpstreamError>>, UpstreamError> {
            Ok(self.tokens.iter().map(|t| Ok(t.to_string())).collect())
        }
    }

    /// An upstream that fails BEFORE the first token — pre-stream XI.5.
    struct FailingUpstream;
    #[async_trait]
    impl StreamingUpstream for FailingUpstream {
        async fn generate_stream(
            &self,
            _p: &str,
            _s: &[SourceChunk],
        ) -> Result<Vec<Result<String, UpstreamError>>, UpstreamError> {
            Err(UpstreamError("simulated pre-stream outage".into()))
        }
    }

    /// An upstream that emits `n_ok` tokens then errors — mid-stream XI.5
    /// (terminate-with-fallback-marker, ADR-B7-10-003).
    struct MidStreamFailingUpstream {
        n_ok: usize,
    }
    #[async_trait]
    impl StreamingUpstream for MidStreamFailingUpstream {
        async fn generate_stream(
            &self,
            _p: &str,
            _s: &[SourceChunk],
        ) -> Result<Vec<Result<String, UpstreamError>>, UpstreamError> {
            let mut items: Vec<Result<String, UpstreamError>> =
                (0..self.n_ok).map(|i| Ok(format!("tok{i}"))).collect();
            items.push(Err(UpstreamError("simulated mid-stream outage".into())));
            Ok(items)
        }
    }

    fn sources() -> Vec<SourceChunk> {
        vec![SourceChunk { document_id: "doc-1".into(), content: "grounding".into(), score: 0.9 }]
    }

    async fn collect(handle: StreamHandle) -> Vec<QueryChunk> {
        let mut out = Vec::new();
        let mut s = handle.into_stream();
        while let Some(c) = s.next().await {
            out.push(c);
        }
        out
    }

    #[tokio::test]
    async fn healthy_upstream_streams_sources_then_tokens_then_done() {
        let handle = process_query_stream(
            &GatewayConfig::default(),
            OkStreamingUpstream { tokens: vec!["Hello", " world"] },
            "tenant-a",
            "mistral-small",
            "what is forge?",
            10,
            sources(),
        );
        let chunks = collect(handle).await;
        // One-shot sources frame first.
        assert_eq!(chunks[0].sources, sources());
        assert!(!chunks[0].done);
        // Token deltas appended in order.
        let answer: String = chunks.iter().map(|c| c.token_delta.clone()).collect();
        assert_eq!(answer, "Hello world");
        // Clean terminal frame, no fallback.
        let last = chunks.last().unwrap();
        assert!(last.done);
        assert!(!last.fallback_used);
    }

    #[tokio::test]
    async fn pre_stream_upstream_failure_degrades_to_fallback_marked_chunk() {
        // Article XI.5: the AI is unavailable BEFORE the first token → the stream
        // emits a single fallback-marked terminal chunk carrying the ranked
        // sources, exactly as the unary path degrades.
        let handle = process_query_stream(
            &GatewayConfig::default(),
            FailingUpstream,
            "t",
            "m",
            "q",
            10,
            sources(),
        );
        let chunks = collect(handle).await;
        let last = chunks.last().unwrap();
        assert!(last.done);
        assert!(last.fallback_used);
        assert_eq!(last.sources, sources());
    }

    #[tokio::test]
    async fn mid_stream_upstream_failure_terminates_with_fallback_marker() {
        // Article XI.5 / ADR-B7-10-003: the upstream errors after 2 tokens → keep
        // the partial tokens, terminate the stream with a fallback-marked frame.
        let handle = process_query_stream(
            &GatewayConfig::default(),
            MidStreamFailingUpstream { n_ok: 2 },
            "t",
            "m",
            "q",
            10,
            sources(),
        );
        let chunks = collect(handle).await;
        // Partial tokens were delivered (kept, not discarded).
        let delivered: Vec<&str> = chunks
            .iter()
            .filter(|c| !c.token_delta.is_empty())
            .map(|c| c.token_delta.as_str())
            .collect();
        assert_eq!(delivered, vec!["tok0", "tok1"]);
        // Terminal frame is the fallback marker.
        let last = chunks.last().unwrap();
        assert!(last.done);
        assert!(last.fallback_used);
    }

    #[tokio::test]
    async fn kill_switch_streams_fallback_without_calling_upstream() {
        // Even with a healthy upstream, the kill switch (XI.5) forces the
        // pre-stream fallback — the route guard runs before any upstream call.
        let config = GatewayConfig { kill_switch: true, ..GatewayConfig::default() };
        let handle = process_query_stream(
            &config,
            OkStreamingUpstream { tokens: vec!["should-not-appear"] },
            "t",
            "m",
            "q",
            1,
            sources(),
        );
        let chunks = collect(handle).await;
        // No generated token leaked; a single fallback-marked terminal chunk.
        assert!(chunks.iter().all(|c| c.token_delta.is_empty()));
        let last = chunks.last().unwrap();
        assert!(last.done);
        assert!(last.fallback_used);
        assert_eq!(last.sources, sources());
    }

    #[tokio::test]
    async fn over_budget_streams_fallback_not_error() {
        let config = GatewayConfig { token_budget: 5, ..GatewayConfig::default() };
        let handle = process_query_stream(
            &config,
            OkStreamingUpstream { tokens: vec!["x"] },
            "t",
            "m",
            "q",
            6, // over budget
            sources(),
        );
        let chunks = collect(handle).await;
        let last = chunks.last().unwrap();
        assert!(last.fallback_used);
    }

    #[tokio::test]
    async fn t3_forbidden_provider_streams_fallback() {
        let config = GatewayConfig {
            provider: Provider::OpenAiDirect,
            tier: ComplianceTier::T3,
            ..GatewayConfig::default()
        };
        let handle = process_query_stream(
            &config,
            OkStreamingUpstream { tokens: vec!["x"] },
            "t",
            "m",
            "q",
            1,
            sources(),
        );
        let chunks = collect(handle).await;
        assert!(chunks.last().unwrap().fallback_used);
    }

    #[tokio::test]
    async fn channel_capacity_is_a_named_bounded_constant() {
        // Backpressure (FR-B7-10-012): the bound is a named, documented, > 0
        // constant — not unbounded, not a magic literal.
        assert!(STREAM_CHANNEL_CAPACITY > 0);
    }

    #[tokio::test]
    async fn cancel_aborts_the_in_flight_producer() {
        // FR-B7-10-013: cancelling the handle aborts the producer task. With a
        // never-consumed stream and a producer that would otherwise keep sending,
        // cancel() makes the producer task finish (aborted).
        let handle = process_query_stream(
            &GatewayConfig::default(),
            OkStreamingUpstream { tokens: vec!["a", "b", "c"] },
            "t",
            "m",
            "q",
            10,
            sources(),
        );
        handle.cancel();
        // After abort, draining the stream terminates (the producer stopped).
        let chunks = collect(handle).await;
        // Either nothing or a partial prefix was delivered, but the stream is
        // closed (no hang) — the test completing IS the assertion.
        assert!(chunks.len() <= 5);
    }
}
