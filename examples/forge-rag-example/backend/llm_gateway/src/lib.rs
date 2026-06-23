//! `llm_gateway` — a thin axum proxy fronting all LLM calls (decision A,
//! `global/llm-gateway.md`). Application code never calls a provider SDK
//! directly; it calls the gateway, so audit, budgets, tier-refusal, the kill
//! switch, and the mandatory non-AI fallback are enforced in ONE place.
//!
//! Constitutional guards materialised here:
//!   - **IX.6** prompt-audit span ([`audit`]) on every call.
//!   - **XI.5** token budget + kill switch + non-AI fallback ([`fallback`]).
//!   - **XI.6** PII guard ([`audit::redact_pii`]) before any logging.
//!   - tier-aware refusal **hooks** ([`Provider::forbidden_at`]) referencing
//!     I.3 forbidden-components + compliance-tiers (runtime rules → b7-9).

pub mod audit;
pub mod fallback;
pub mod handler;
/// Streaming RAG answer pipeline (B.7.10) — the server-streaming counterpart to
/// [`handler::process_query`], with backpressure / cancellation / pre- and
/// mid-stream XI.5 fallback / close-time prompt-audit. Additive: the unary path
/// is untouched.
pub mod streaming;

use rag::ComplianceTier;

/// Sanctioned upstream providers (`llm-gateway.md` Providers).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Provider {
    /// Mistral on Scaleway (EU-sovereign) — sanctioned at all tiers.
    MistralScaleway,
    /// Self-hosted vLLM (EU) — sanctioned at all tiers.
    VllmSelfHosted,
    /// OpenAI direct — T1 only; forbidden at T3 (CLOUD Act).
    OpenAiDirect,
}

impl Provider {
    /// Tier-aware refusal hook: is this provider forbidden at `tier`?
    /// T3 forbids OpenAI-direct / Vertex / Bedrock (`llm-gateway.md` tier-aware
    /// refusal; enforced at runtime by `b7-9-janus-ai`, hooked here).
    pub fn forbidden_at(self, tier: ComplianceTier) -> bool {
        matches!(
            (self, tier),
            (Provider::OpenAiDirect, ComplianceTier::T3)
        )
    }
}

/// Gateway configuration (sourced from `LLM_GATEWAY_*` env, see `.env.example`).
#[derive(Debug, Clone)]
pub struct GatewayConfig {
    /// OpenAI-compatible upstream base URL.
    pub upstream_base_url: String,
    /// Selected upstream provider.
    pub provider: Provider,
    /// Per-request token budget; over-budget ⇒ degrade to fallback (XI.5).
    pub token_budget: u32,
    /// Global kill switch; when true all LLM routing is disabled (XI.5).
    pub kill_switch: bool,
    /// Active compliance tier (drives tier-aware refusal).
    pub tier: ComplianceTier,
}

impl Default for GatewayConfig {
    fn default() -> Self {
        Self {
            upstream_base_url: "https://api.mistral.ai/v1".to_string(),
            provider: Provider::MistralScaleway,
            token_budget: 8192,
            kill_switch: false,
            tier: ComplianceTier::T1,
        }
    }
}

/// The routing decision the gateway makes for a request, BEFORE any network
/// call. This is the pure, unit-testable core of the XI.5 guard.
#[derive(Debug, Clone, PartialEq)]
pub enum Route {
    /// Forward to the configured OpenAI-compatible upstream.
    Upstream,
    /// Serve the non-AI fallback, with the reason (XI.5 / tier refusal).
    Fallback(FallbackReason),
}

/// Why a request was routed to the non-AI fallback.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FallbackReason {
    /// The global kill switch is engaged (XI.5).
    KillSwitch,
    /// The request's estimated tokens exceed the per-request budget (XI.5).
    BudgetExceeded,
    /// The configured provider is forbidden at the active tier (tier refusal).
    ProviderForbiddenAtTier,
    /// The AI upstream was unreachable / errored (a genuine outage, distinct
    /// from the kill switch). Recorded separately so the IX.6 prompt-audit trail
    /// — the AI-Act evidence (B.7.5) — does not conflate an outage with an
    /// operator-engaged kill switch.
    UpstreamUnavailable,
}

/// Decide how to route a request given its estimated prompt token count. Pure:
/// no I/O, fully unit-testable. Order of guards is significant — kill switch and
/// tier refusal are hard gates; budget is the soft degrade.
pub fn decide_route(config: &GatewayConfig, estimated_tokens: u32) -> Route {
    if config.kill_switch {
        return Route::Fallback(FallbackReason::KillSwitch);
    }
    if config.provider.forbidden_at(config.tier) {
        return Route::Fallback(FallbackReason::ProviderForbiddenAtTier);
    }
    if estimated_tokens > config.token_budget {
        return Route::Fallback(FallbackReason::BudgetExceeded);
    }
    Route::Upstream
}

#[cfg(test)]
mod tests {
    use super::*;

    fn cfg() -> GatewayConfig {
        GatewayConfig::default()
    }

    #[test]
    fn healthy_request_routes_upstream() {
        assert_eq!(decide_route(&cfg(), 100), Route::Upstream);
    }

    #[test]
    fn kill_switch_forces_fallback() {
        // Article XI.5: the kill switch disables all LLM routing; the archetype
        // MUST keep functioning on the non-AI fallback.
        let c = GatewayConfig { kill_switch: true, ..cfg() };
        assert_eq!(decide_route(&c, 1), Route::Fallback(FallbackReason::KillSwitch));
    }

    #[test]
    fn over_budget_degrades_to_fallback_not_error() {
        // Article XI.5: over-budget requests DEGRADE to fallback, not a hard 500.
        let c = GatewayConfig { token_budget: 50, ..cfg() };
        assert_eq!(
            decide_route(&c, 51),
            Route::Fallback(FallbackReason::BudgetExceeded)
        );
        assert_eq!(decide_route(&c, 50), Route::Upstream);
    }

    #[test]
    fn openai_direct_forbidden_at_t3_falls_back() {
        let c = GatewayConfig {
            provider: Provider::OpenAiDirect,
            tier: ComplianceTier::T3,
            ..cfg()
        };
        assert_eq!(
            decide_route(&c, 1),
            Route::Fallback(FallbackReason::ProviderForbiddenAtTier)
        );
    }

    #[test]
    fn openai_direct_allowed_at_t1() {
        let c = GatewayConfig {
            provider: Provider::OpenAiDirect,
            tier: ComplianceTier::T1,
            ..cfg()
        };
        assert_eq!(decide_route(&c, 1), Route::Upstream);
    }

    #[test]
    fn eu_providers_never_forbidden() {
        for tier in [ComplianceTier::T1, ComplianceTier::T2, ComplianceTier::T3] {
            assert!(!Provider::MistralScaleway.forbidden_at(tier));
            assert!(!Provider::VllmSelfHosted.forbidden_at(tier));
        }
    }
}
