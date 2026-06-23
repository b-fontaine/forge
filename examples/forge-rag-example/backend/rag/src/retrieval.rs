//! Hybrid retrieval — fuse the dense-vector (pgvector HNSW) leg with the sparse
//! BM25/full-text leg via **Reciprocal Rank Fusion** (`rag-patterns.md`:
//! "combine pgvector similarity with Postgres full-text search ... then fuse
//! with Reciprocal Rank Fusion (RRF)").
//!
//! RRF score for a document is `Σ 1 / (k + rank)` over each ranked list it
//! appears in (rank is 0-based here; `k` defaults to 60 per the canonical RRF
//! paper). RRF needs only the *ranks*, not the raw (incomparable) scores, which
//! is exactly why it is robust across a cosine-distance list and a BM25 list.

/// The conventional RRF damping constant (Cormack et al.).
pub const DEFAULT_RRF_K: f32 = 60.0;

/// A ranked list of document ids, best-first.
pub type RankedList<'a> = &'a [String];

/// Fuse several ranked lists into one ranking via Reciprocal Rank Fusion.
/// Returns `(document_id, fused_score)` sorted by descending fused score, with
/// ties broken by `document_id` for deterministic output (NFR-B7-2-004).
pub fn reciprocal_rank_fusion(lists: &[RankedList], k: f32) -> Vec<(String, f32)> {
    use std::collections::HashMap;

    let mut scores: HashMap<String, f32> = HashMap::new();
    for list in lists {
        for (rank, doc_id) in list.iter().enumerate() {
            *scores.entry(doc_id.clone()).or_insert(0.0) += 1.0 / (k + rank as f32);
        }
    }

    let mut fused: Vec<(String, f32)> = scores.into_iter().collect();
    fused.sort_by(|a, b| {
        b.1.partial_cmp(&a.1)
            .unwrap_or(std::cmp::Ordering::Equal)
            .then_with(|| a.0.cmp(&b.0))
    });
    fused
}

#[cfg(test)]
mod tests {
    use super::*;

    fn list(ids: &[&str]) -> Vec<String> {
        ids.iter().map(|s| s.to_string()).collect()
    }

    #[test]
    fn rrf_rewards_documents_ranked_high_in_both_lists() {
        // "b" is rank 0 in the vector list and rank 0 in the BM25 list → it must
        // outrank "a" (only top of one list) and "c" (only top of the other).
        let vector = list(&["b", "a", "c"]);
        let bm25 = list(&["b", "c", "a"]);
        let fused = reciprocal_rank_fusion(&[&vector, &bm25], DEFAULT_RRF_K);

        assert_eq!(fused[0].0, "b");
        // "b" appears at rank 0 in both → score = 2/(k+0)
        let expected_b = 2.0 / DEFAULT_RRF_K;
        assert!((fused[0].1 - expected_b).abs() < 1e-6);
    }

    #[test]
    fn rrf_is_deterministic_on_ties() {
        // Two docs each appear once at rank 0 in disjoint lists → equal scores;
        // the tie must break alphabetically so output is byte-stable.
        let l1 = list(&["x"]);
        let l2 = list(&["a"]);
        let fused = reciprocal_rank_fusion(&[&l1, &l2], DEFAULT_RRF_K);
        assert_eq!(fused[0].0, "a");
        assert_eq!(fused[1].0, "x");
        assert!((fused[0].1 - fused[1].1).abs() < 1e-9);
    }

    #[test]
    fn rrf_handles_empty_input() {
        let fused = reciprocal_rank_fusion(&[], DEFAULT_RRF_K);
        assert!(fused.is_empty());
    }
}
