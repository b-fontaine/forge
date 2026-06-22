//! `rag` — retrieval-augmented-generation pipeline for the ai-native-rag archetype.
//!
//! Conforms to `.forge/standards/global/rag-patterns.md`:
//! chunking + embeddings, hybrid retrieval (vector + BM25 + RRF), coarse→exact
//! re-ranking, pgvector HNSW (`vector_cosine_ops`). Heavy retrieval/embedding
//! work runs as a Temporal **activity-only** worker (`worker`).
//!
//! Article XI.5: the embeddings layer ships a non-AI/degraded fallback path
//! (the local in-process embedder + ranked-source retrieval). Article XI.6:
//! the local path keeps text in-process (zero egress) for sovereign tiers.

pub mod chunking;
pub mod embeddings;
pub mod pgvector_store;
pub mod rerank;
pub mod retrieval;
pub mod worker;

/// EU compliance tier (see `compliance-tiers.md`). Drives embeddings-provider
/// selection: T1/T2 may use a cloud provider with a local fallback; T3 forces
/// the zero-egress local path.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ComplianceTier {
    /// T1 — least restrictive.
    T1,
    /// T2 — moderate.
    T2,
    /// T3 — EU-strict / sovereign: cloud embedding providers are forbidden.
    T3,
}

impl ComplianceTier {
    /// Parse the `FORGE_EU_TIER` env value. Unknown / missing ⇒ the safe
    /// default (T1) — callers override per their deployment.
    pub fn from_env_value(raw: &str) -> Self {
        match raw.trim().to_ascii_uppercase().as_str() {
            "T2" => Self::T2,
            "T3" => Self::T3,
            _ => Self::T1,
        }
    }
}

/// A retrieved document chunk with its fused score and provenance, per
/// `rag-patterns.md` ("always attach citations").
#[derive(Debug, Clone, PartialEq)]
pub struct SourceChunk {
    /// Source document id (provenance / citation).
    pub document_id: String,
    /// Chunk text used as grounding context.
    pub content: String,
    /// Fused retrieval score (higher = more relevant).
    pub score: f32,
}
