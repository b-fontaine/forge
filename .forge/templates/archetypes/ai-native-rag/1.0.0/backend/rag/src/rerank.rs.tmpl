//! Re-ranking — coarse→exact two-stage re-order (`rag-patterns.md`: "a wide
//! cheap pass then an exact re-order ... re-rank the candidates by the exact
//! distance ... LIMIT 10").
//!
//! The coarse pass (e.g. binary-quantized Hamming over a large candidate set)
//! happens in the store; this module performs the **exact** re-order of the
//! shortlist by cosine similarity to the query vector and truncates to `top_k`.

use crate::SourceChunk;

/// A candidate chunk plus its dense embedding, as returned by the coarse pass.
#[derive(Debug, Clone)]
pub struct Candidate {
    /// The chunk (provenance + text + provisional score).
    pub chunk: SourceChunk,
    /// The candidate's dense embedding (for the exact re-rank).
    pub embedding: Vec<f32>,
}

/// Cosine similarity in [-1, 1]; 0.0 when either vector is zero-length or the
/// dimensions differ (defensive — never panics on bad input).
pub fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    if a.len() != b.len() || a.is_empty() {
        return 0.0;
    }
    let dot: f32 = a.iter().zip(b).map(|(x, y)| x * y).sum();
    let na: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let nb: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();
    if na == 0.0 || nb == 0.0 {
        0.0
    } else {
        dot / (na * nb)
    }
}

/// Exact re-rank of the coarse candidate set against `query` by cosine
/// similarity, returning the top `top_k` as scored [`SourceChunk`]s
/// (best-first). Ties break by `document_id` for determinism.
pub fn rerank_exact(query: &[f32], candidates: Vec<Candidate>, top_k: usize) -> Vec<SourceChunk> {
    let mut scored: Vec<SourceChunk> = candidates
        .into_iter()
        .map(|c| SourceChunk {
            score: cosine_similarity(query, &c.embedding),
            ..c.chunk
        })
        .collect();

    scored.sort_by(|a, b| {
        b.score
            .partial_cmp(&a.score)
            .unwrap_or(std::cmp::Ordering::Equal)
            .then_with(|| a.document_id.cmp(&b.document_id))
    });
    scored.truncate(top_k);
    scored
}

#[cfg(test)]
mod tests {
    use super::*;

    fn cand(id: &str, embedding: Vec<f32>) -> Candidate {
        Candidate {
            chunk: SourceChunk {
                document_id: id.to_string(),
                content: format!("content of {id}"),
                score: 0.0,
            },
            embedding,
        }
    }

    #[test]
    fn rerank_orders_by_cosine_to_query() {
        let query = vec![1.0, 0.0];
        let candidates = vec![
            cand("orthogonal", vec![0.0, 1.0]), // cosine 0
            cand("aligned", vec![1.0, 0.0]),    // cosine 1 — should rank first
            cand("opposite", vec![-1.0, 0.0]),  // cosine -1 — last
        ];
        let ranked = rerank_exact(&query, candidates, 10);
        assert_eq!(ranked[0].document_id, "aligned");
        assert_eq!(ranked[1].document_id, "orthogonal");
        assert_eq!(ranked[2].document_id, "opposite");
        assert!((ranked[0].score - 1.0).abs() < 1e-6);
    }

    #[test]
    fn rerank_truncates_to_top_k() {
        let query = vec![1.0, 0.0];
        let candidates = vec![
            cand("a", vec![1.0, 0.0]),
            cand("b", vec![0.9, 0.1]),
            cand("c", vec![0.1, 0.9]),
        ];
        let ranked = rerank_exact(&query, candidates, 2);
        assert_eq!(ranked.len(), 2);
        assert_eq!(ranked[0].document_id, "a");
    }

    #[test]
    fn cosine_is_defensive_on_bad_input() {
        assert_eq!(cosine_similarity(&[], &[]), 0.0);
        assert_eq!(cosine_similarity(&[1.0, 2.0], &[1.0]), 0.0);
        assert_eq!(cosine_similarity(&[0.0, 0.0], &[1.0, 1.0]), 0.0);
    }
}
