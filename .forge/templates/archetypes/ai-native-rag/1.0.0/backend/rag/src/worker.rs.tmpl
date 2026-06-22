//! Temporal **activity-only** worker for heavy retrieval/embedding work.
//!
//! Per the schema + design (memo §6): the `temporalio-sdk` is pre-alpha, so the
//! archetype runs RAG heavy work as Temporal **activities only** — no workflow
//! definitions live here (workflow determinism is the pre-alpha surface to
//! avoid). The Temporal worker runtime itself is consumed from the B8O substrate
//! by reference (`orchestration.yaml`); this module declares the *activities*
//! that substrate registers.
//!
//! An activity is a plain async unit of work with a stable name; it must be
//! idempotent and side-effect-safe to re-run (Temporal at-least-once semantics).

use async_trait::async_trait;

/// A Temporal activity: a named, idempotent, retry-safe async unit of work.
/// The B8O Temporal worker registers implementations of this trait as
/// activity-only tasks (no workflow code here).
#[async_trait]
pub trait Activity: Send + Sync {
    /// Stable activity name used for Temporal task registration/routing.
    fn name(&self) -> &'static str;
}

/// The heavy embedding activity: embed + upsert a batch of chunks. Runs as a
/// Temporal activity so retries/timeouts are handled by the substrate, not by
/// the request path. Marker type — the concrete embed/upsert is wired to
/// [`crate::embeddings`] + [`crate::pgvector_store`] at adopter integration.
pub struct EmbedAndIndexActivity;

#[async_trait]
impl Activity for EmbedAndIndexActivity {
    fn name(&self) -> &'static str {
        "rag.embed_and_index"
    }
}

/// The heavy retrieval activity: hybrid retrieve + re-rank for a query. Activity
/// so a slow ANN scan never blocks the gateway request thread.
pub struct HybridRetrieveActivity;

#[async_trait]
impl Activity for HybridRetrieveActivity {
    fn name(&self) -> &'static str {
        "rag.hybrid_retrieve"
    }
}

/// The activity names this crate registers with the Temporal worker. The B8O
/// worker iterates this list at startup (activity-only registration).
pub fn registered_activity_names() -> Vec<&'static str> {
    vec![
        EmbedAndIndexActivity.name(),
        HybridRetrieveActivity.name(),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn activities_have_stable_namespaced_names() {
        let names = registered_activity_names();
        assert!(names.contains(&"rag.embed_and_index"));
        assert!(names.contains(&"rag.hybrid_retrieve"));
        // Names are namespaced under `rag.` so they don't collide with other
        // layers' activities in the shared Temporal namespace.
        assert!(names.iter().all(|n| n.starts_with("rag.")));
    }
}
