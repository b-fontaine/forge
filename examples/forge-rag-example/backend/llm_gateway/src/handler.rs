//! The axum surface + request orchestration for the gateway.
//!
//! `process_query` is the one place the guards compose: decide the route
//! (kill-switch / tier-refusal / budget → fallback, else upstream), call the
//! upstream through the [`Upstream`] port (so the XI.5 fallback branch is
//! unit-testable with the AI mocked to fail), redact + emit the prompt audit
//! (IX.6 / XI.6), and return either a generated answer or the non-AI fallback.

use async_trait::async_trait;
use axum::routing::post;
use axum::Router;
use rag::SourceChunk;

use crate::audit::{self, PromptAudit};
use crate::fallback::{non_ai_fallback, FallbackAnswer};
use crate::{decide_route, GatewayConfig, Route};

/// The upstream LLM port. Abstracted as a trait so tests can inject a failing /
/// unavailable upstream to exercise the Article XI.5 fallback branch (the real
/// impl wraps the `async-openai` OpenAI-compatible client).
#[async_trait]
pub trait Upstream: Send + Sync {
    /// Generate an answer for `prompt` grounded in `sources`. Errors model an
    /// unavailable / failing upstream (network down, 5xx, timeout).
    async fn generate(&self, prompt: &str, sources: &[SourceChunk]) -> Result<String, UpstreamError>;
}

/// Upstream failure — any error degrades to the non-AI fallback (XI.5).
#[derive(Debug, thiserror::Error)]
#[error("llm upstream unavailable: {0}")]
pub struct UpstreamError(pub String);

/// The gateway's answer: either a generated completion or the non-AI fallback.
#[derive(Debug, Clone, PartialEq)]
pub enum GatewayAnswer {
    /// A generated answer from the upstream.
    Generated(String),
    /// The non-AI fallback (ranked sources) — XI.5.
    Fallback(FallbackAnswer),
}

/// Orchestrate one query end-to-end. `estimated_tokens` feeds the budget guard;
/// `sources` are the retrieved chunks (used to ground the prompt AND to serve
/// the fallback). Always emits a PII-redacted prompt-audit record (IX.6).
pub async fn process_query<U: Upstream>(
    config: &GatewayConfig,
    upstream: &U,
    tenant: &str,
    model: &str,
    prompt: &str,
    estimated_tokens: u32,
    sources: Vec<SourceChunk>,
) -> GatewayAnswer {
    // PII guard (XI.6): never let raw prompt text reach a log/span.
    let _redacted_prompt = audit::redact_pii(prompt);

    let mut record = PromptAudit {
        model: model.to_string(),
        tenant: tenant.to_string(),
        tier: config.tier,
        prompt_tokens: estimated_tokens,
        completion_tokens: 0,
        fallback_invoked: false,
        // The unary path is never cancelled mid-flight (B.7.10 streaming-only).
        cancelled: false,
    };

    let answer = match decide_route(config, estimated_tokens) {
        Route::Fallback(reason) => {
            record.fallback_invoked = true;
            GatewayAnswer::Fallback(non_ai_fallback(reason, sources))
        }
        Route::Upstream => match upstream.generate(prompt, &sources).await {
            Ok(text) => {
                record.completion_tokens = text.split_whitespace().count() as u32;
                GatewayAnswer::Generated(text)
            }
            Err(_) => {
                // Upstream down → degrade, do not fail open (XI.5). Record the
                // outage as UpstreamUnavailable (NOT KillSwitch) so the IX.6
                // prompt-audit trail accurately attributes the fallback cause.
                record.fallback_invoked = true;
                GatewayAnswer::Fallback(non_ai_fallback(
                    crate::FallbackReason::UpstreamUnavailable,
                    sources,
                ))
            }
        },
    };

    audit::emit(&record);
    answer
}

/// Build the gateway's axum router. The `/v1/chat/completions` route is the
/// OpenAI-compatible proxy surface the frontend (and app code) calls; the
/// concrete handler wiring (config + upstream client + retrieval) is attached
/// by the bin-server. Returns an empty-but-valid router as the seed surface.
pub fn router() -> Router {
    Router::new().route("/v1/chat/completions", post(|| async { "not yet wired" }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{FallbackReason, Provider};
    use rag::ComplianceTier;

    /// An upstream that always fails — models "AI unavailable" for the XI.5 test.
    struct FailingUpstream;
    #[async_trait]
    impl Upstream for FailingUpstream {
        async fn generate(&self, _p: &str, _s: &[SourceChunk]) -> Result<String, UpstreamError> {
            Err(UpstreamError("simulated outage".into()))
        }
    }

    /// An upstream that always succeeds.
    struct OkUpstream;
    #[async_trait]
    impl Upstream for OkUpstream {
        async fn generate(&self, _p: &str, _s: &[SourceChunk]) -> Result<String, UpstreamError> {
            Ok("generated answer".into())
        }
    }

    fn sources() -> Vec<SourceChunk> {
        vec![SourceChunk {
            document_id: "doc-1".into(),
            content: "grounding".into(),
            score: 0.9,
        }]
    }

    #[tokio::test]
    async fn upstream_down_degrades_to_non_ai_fallback() {
        // BDD: "When the AI upstream is unavailable, Then a non-AI fallback path
        // is exercised (Article XI.5)."
        let answer = process_query(
            &GatewayConfig::default(),
            &FailingUpstream,
            "tenant-a",
            "mistral-small",
            "what is forge?",
            100,
            sources(),
        )
        .await;
        match answer {
            GatewayAnswer::Fallback(f) => {
                assert_eq!(f.sources, sources());
                // IX.6 audit fidelity: an upstream outage is recorded as
                // UpstreamUnavailable, NOT conflated with the kill switch.
                assert_eq!(f.reason, crate::FallbackReason::UpstreamUnavailable);
            }
            other => panic!("expected fallback, got {other:?}"),
        }
    }

    #[tokio::test]
    async fn healthy_upstream_returns_generated_answer() {
        let answer = process_query(
            &GatewayConfig::default(),
            &OkUpstream,
            "tenant-a",
            "mistral-small",
            "hello",
            10,
            sources(),
        )
        .await;
        assert_eq!(answer, GatewayAnswer::Generated("generated answer".into()));
    }

    #[tokio::test]
    async fn kill_switch_serves_fallback_without_calling_upstream() {
        // Even with a healthy upstream, the kill switch (XI.5) forces fallback.
        let config = GatewayConfig { kill_switch: true, ..GatewayConfig::default() };
        let answer = process_query(
            &config, &OkUpstream, "t", "m", "q", 1, sources(),
        )
        .await;
        assert!(matches!(
            answer,
            GatewayAnswer::Fallback(FallbackAnswer { reason: FallbackReason::KillSwitch, .. })
        ));
    }

    #[tokio::test]
    async fn t3_forbidden_provider_serves_fallback() {
        let config = GatewayConfig {
            provider: Provider::OpenAiDirect,
            tier: ComplianceTier::T3,
            ..GatewayConfig::default()
        };
        let answer = process_query(
            &config, &OkUpstream, "t", "m", "q", 1, sources(),
        )
        .await;
        assert!(matches!(
            answer,
            GatewayAnswer::Fallback(FallbackAnswer {
                reason: FallbackReason::ProviderForbiddenAtTier,
                ..
            })
        ));
    }
}
