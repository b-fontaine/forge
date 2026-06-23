//! Non-AI fallback (Article XI.5). When the LLM upstream is unavailable, the
//! kill switch is engaged, the token budget is exceeded, or the provider is
//! forbidden at the tier, the gateway degrades to a NON-AI answer instead of
//! failing open — per `llm-gateway.md` / `rag-patterns.md`: "RAG returns ranked
//! source documents ... so the non-AI fallback can show sources".

use rag::SourceChunk;

use crate::FallbackReason;

/// A degraded, non-AI answer: the ranked source chunks the retrieval pipeline
/// found, with no generated prose. The caller renders these as citations.
#[derive(Debug, Clone, PartialEq)]
pub struct FallbackAnswer {
    /// Human-readable note on why the AI path was skipped (for the UI/audit).
    pub reason: FallbackReason,
    /// The ranked source chunks (best-first) — the non-AI substitute for a
    /// generated answer.
    pub sources: Vec<SourceChunk>,
}

/// Build the non-AI fallback from the retrieved sources. This NEVER calls an
/// LLM; it is the guaranteed-available degraded path (XI.5).
pub fn non_ai_fallback(reason: FallbackReason, sources: Vec<SourceChunk>) -> FallbackAnswer {
    FallbackAnswer { reason, sources }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn chunk(id: &str, score: f32) -> SourceChunk {
        SourceChunk {
            document_id: id.to_string(),
            content: format!("content {id}"),
            score,
        }
    }

    #[test]
    fn fallback_returns_ranked_sources_without_calling_ai() {
        // Article XI.5: the fallback is a non-AI path — it surfaces the ranked
        // sources so the user still gets a useful, traceable answer.
        let sources = vec![chunk("doc-1", 0.9), chunk("doc-2", 0.7)];
        let answer = non_ai_fallback(FallbackReason::KillSwitch, sources.clone());
        assert_eq!(answer.reason, FallbackReason::KillSwitch);
        assert_eq!(answer.sources, sources);
    }

    #[test]
    fn fallback_is_available_even_with_no_sources() {
        // Degraded, not broken: an empty source set is still a valid (if empty)
        // non-AI answer, never a hard error.
        let answer = non_ai_fallback(FallbackReason::BudgetExceeded, vec![]);
        assert!(answer.sources.is_empty());
        assert_eq!(answer.reason, FallbackReason::BudgetExceeded);
    }
}
