//! Embeddings — the `Embedder` trait and its tier-aware selection (ADR-B7-2-004).
//!
//! Two impls back the trait:
//!   - [`MistralEmbedder`] (default, T1/T2) — `async-openai` against a
//!     Mistral-EU / Scaleway / vLLM OpenAI-compatible base.
//!   - `LocalEmbedder` (feature `local-embeddings`, T3 forced + XI.5 fallback) —
//!     `fastembed` in-process ONNX (zero egress). Gated behind an off-by-default
//!     feature because it pulls ONNX Runtime (a heavy native dep).
//!
//! Selection is driven by [`crate::ComplianceTier`] + the configured provider:
//! T1/T2 default to Mistral with Local as the XI.5 fallback; **T3 forces Local**
//! (cloud embedding providers are forbidden at T3 — `rag-patterns.md` EU
//! sovereignty + `llm-gateway.md` tier-aware refusal).

use async_trait::async_trait;
use thiserror::Error;

use crate::ComplianceTier;

/// Errors surfaced by an [`Embedder`].
#[derive(Debug, Error)]
pub enum EmbedError {
    /// The upstream provider was unreachable or returned an error.
    #[error("embedding provider unavailable: {0}")]
    ProviderUnavailable(String),
    /// The selected provider is forbidden at the active compliance tier.
    #[error("provider forbidden at tier {tier:?}")]
    ForbiddenAtTier { tier: ComplianceTier },
}

/// Produces dense vector embeddings for text. Both the cloud and local impls
/// implement this so the pipeline is provider-agnostic (Article VII boundary).
#[async_trait]
pub trait Embedder: Send + Sync {
    /// Embed a batch of documents into dense vectors.
    async fn embed(&self, docs: &[String]) -> Result<Vec<Vec<f32>>, EmbedError>;

    /// The embedding dimension this embedder produces.
    fn dimension(&self) -> usize;
}

/// Which embedding backend a tier/provider combination selects. Returned by
/// [`select_backend`] so selection is unit-testable without constructing a
/// real (heavy) embedder.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EmbedderKind {
    /// Cloud, OpenAI-compatible (Mistral-EU / Scaleway / vLLM).
    Mistral,
    /// In-process ONNX (fastembed) — zero egress.
    Local,
}

/// Configured provider preference (from `EMBEDDINGS_PROVIDER`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProviderPreference {
    /// Prefer the cloud Mistral-EU provider (default for T1/T2).
    Mistral,
    /// Prefer the in-process local embedder.
    Local,
}

/// Tier-aware backend selection (ADR-B7-2-004):
///   - **T3 forces [`EmbedderKind::Local`]** regardless of preference — cloud
///     embedding providers are forbidden at T3 (zero egress).
///   - T1/T2 honour the configured preference.
///
/// This is the tier-aware refusal **hook** referenced by `llm-gateway.md`; the
/// runtime Janus refusal rules themselves live in `b7-9-janus-ai`.
pub fn select_backend(tier: ComplianceTier, pref: ProviderPreference) -> EmbedderKind {
    match tier {
        ComplianceTier::T3 => EmbedderKind::Local,
        _ => match pref {
            ProviderPreference::Mistral => EmbedderKind::Mistral,
            ProviderPreference::Local => EmbedderKind::Local,
        },
    }
}

/// Cloud embedder using an OpenAI-compatible API (`async-openai`) pointed at a
/// Mistral-EU / Scaleway / vLLM base URL. Default for T1/T2.
pub struct MistralEmbedder {
    client: async_openai::Client<async_openai::config::OpenAIConfig>,
    model: String,
    dimension: usize,
}

impl MistralEmbedder {
    /// Build a Mistral embedder against an OpenAI-compatible `base_url`.
    /// `api_key` is the per-tenant BYOK key (never committed — XI.6).
    pub fn new(base_url: &str, api_key: &str, model: impl Into<String>, dimension: usize) -> Self {
        let config = async_openai::config::OpenAIConfig::new()
            .with_api_base(base_url)
            .with_api_key(api_key);
        Self {
            client: async_openai::Client::with_config(config),
            model: model.into(),
            dimension,
        }
    }

    /// Borrow the underlying client (used by the gateway upstream wiring).
    pub fn client(&self) -> &async_openai::Client<async_openai::config::OpenAIConfig> {
        &self.client
    }
}

#[async_trait]
impl Embedder for MistralEmbedder {
    async fn embed(&self, docs: &[String]) -> Result<Vec<Vec<f32>>, EmbedError> {
        use async_openai::types::embeddings::{CreateEmbeddingRequestArgs, EmbeddingInput};

        let request = CreateEmbeddingRequestArgs::default()
            .model(&self.model)
            .input(EmbeddingInput::StringArray(docs.to_vec()))
            .build()
            .map_err(|e| EmbedError::ProviderUnavailable(e.to_string()))?;

        let response = self
            .client
            .embeddings()
            .create(request)
            .await
            .map_err(|e| EmbedError::ProviderUnavailable(e.to_string()))?;

        Ok(response.data.into_iter().map(|d| d.embedding).collect())
    }

    fn dimension(&self) -> usize {
        self.dimension
    }
}

/// In-process ONNX embedder (fastembed). Gated behind `local-embeddings`
/// because ONNX Runtime is a heavy native dependency; T3 / the XI.5 fallback
/// build with `--features local-embeddings`.
#[cfg(feature = "local-embeddings")]
pub struct LocalEmbedder {
    // fastembed's `TextEmbedding::embed` takes `&mut self`; the `Embedder` trait
    // is `&self` (shared, Send + Sync). A Mutex bridges the two so the local
    // embedder is usable behind a shared reference like the cloud one.
    model: std::sync::Mutex<fastembed::TextEmbedding>,
    dimension: usize,
}

#[cfg(feature = "local-embeddings")]
impl LocalEmbedder {
    /// Initialise the local embedder. The model is downloaded on first run
    /// (documented build/first-run step). Defaults to AllMiniLML6V2 (dim 384).
    pub fn new() -> Result<Self, EmbedError> {
        let model = fastembed::TextEmbedding::try_new(fastembed::InitOptions::new(
            fastembed::EmbeddingModel::AllMiniLML6V2,
        ))
        .map_err(|e| EmbedError::ProviderUnavailable(e.to_string()))?;
        Ok(Self {
            model: std::sync::Mutex::new(model),
            dimension: 384,
        })
    }
}

#[cfg(feature = "local-embeddings")]
#[async_trait]
impl Embedder for LocalEmbedder {
    async fn embed(&self, docs: &[String]) -> Result<Vec<Vec<f32>>, EmbedError> {
        let mut model = self
            .model
            .lock()
            .map_err(|e| EmbedError::ProviderUnavailable(e.to_string()))?;
        model
            .embed(docs.to_vec(), None)
            .map_err(|e| EmbedError::ProviderUnavailable(e.to_string()))
    }

    fn dimension(&self) -> usize {
        self.dimension
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn t3_forces_local_even_when_mistral_preferred() {
        // Article XI.5 / EU sovereignty: T3 must never select a cloud provider.
        let kind = select_backend(ComplianceTier::T3, ProviderPreference::Mistral);
        assert_eq!(kind, EmbedderKind::Local);
    }

    #[test]
    fn t1_t2_honour_mistral_preference() {
        assert_eq!(
            select_backend(ComplianceTier::T1, ProviderPreference::Mistral),
            EmbedderKind::Mistral
        );
        assert_eq!(
            select_backend(ComplianceTier::T2, ProviderPreference::Mistral),
            EmbedderKind::Mistral
        );
    }

    #[test]
    fn local_preference_selects_local_at_any_tier() {
        for tier in [ComplianceTier::T1, ComplianceTier::T2, ComplianceTier::T3] {
            assert_eq!(
                select_backend(tier, ProviderPreference::Local),
                EmbedderKind::Local
            );
        }
    }

    #[test]
    fn tier_parses_from_env_value() {
        assert_eq!(ComplianceTier::from_env_value("T3"), ComplianceTier::T3);
        assert_eq!(ComplianceTier::from_env_value("t2"), ComplianceTier::T2);
        assert_eq!(ComplianceTier::from_env_value(""), ComplianceTier::T1);
        assert_eq!(ComplianceTier::from_env_value("bogus"), ComplianceTier::T1);
    }
}
