//! pgvector HNSW access (`rag-patterns.md` pgvector tuning). The dense leg of
//! hybrid retrieval is an ANN query against the `rag_chunks_embedding_hnsw`
//! index built `USING hnsw (embedding vector_cosine_ops)` (see
//! `infra/postgres/init-pgvector.sql`).
//!
//! Queries are built as runtime `sqlx` strings (no compile-time `DATABASE_URL`
//! is required, so the workspace stays hermetic). The cosine distance operator
//! `<=>` matches the `vector_cosine_ops` opclass; `hnsw.ef_search` trades recall
//! for latency per workload.

use pgvector::Vector;
use sqlx::postgres::PgPool;

use crate::SourceChunk;

/// The cosine-distance ANN query against the HNSW index. `$1` binds the query
/// vector, `$2` the `LIMIT`. `<=>` is pgvector's cosine-distance operator
/// (matches `vector_cosine_ops`); ascending distance = most similar first.
pub const HNSW_COSINE_QUERY: &str = "\
SELECT document_id, content, 1.0 - (embedding <=> $1) AS score \
FROM rag_chunks \
ORDER BY embedding <=> $1 \
LIMIT $2";

/// `SET hnsw.ef_search` — higher improves recall at the cost of latency
/// (`rag-patterns.md` HNSW tuning). Applied per session before the ANN query.
pub fn ef_search_stmt(ef_search: u32) -> String {
    format!("SET hnsw.ef_search = {ef_search}")
}

/// Run the dense-vector ANN leg: tune `ef_search`, then fetch the `limit`
/// nearest chunks by cosine distance. Returns scored [`SourceChunk`]s
/// (best-first). This is the vector input to [`crate::retrieval`]'s RRF fusion.
pub async fn vector_search(
    pool: &PgPool,
    query_embedding: Vec<f32>,
    limit: i64,
    ef_search: u32,
) -> Result<Vec<SourceChunk>, sqlx::Error> {
    // `ef_search` is a `u32` (never user input), so the formatted SET statement
    // is injection-safe; sqlx 0.9 requires us to assert that explicitly.
    sqlx::query(sqlx::AssertSqlSafe(ef_search_stmt(ef_search)))
        .execute(pool)
        .await?;

    let rows: Vec<(String, String, f64)> = sqlx::query_as(HNSW_COSINE_QUERY)
        .bind(Vector::from(query_embedding))
        .bind(limit)
        .fetch_all(pool)
        .await?;

    Ok(rows
        .into_iter()
        .map(|(document_id, content, score)| SourceChunk {
            document_id,
            content,
            score: score as f32,
        })
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ann_query_uses_cosine_operator() {
        // Guards the opclass/operator pairing: vector_cosine_ops ⇔ `<=>`.
        assert!(HNSW_COSINE_QUERY.contains("<=>"));
        assert!(HNSW_COSINE_QUERY.contains("rag_chunks"));
        assert!(HNSW_COSINE_QUERY.contains("ORDER BY"));
    }

    #[test]
    fn ef_search_stmt_formats() {
        assert_eq!(ef_search_stmt(100), "SET hnsw.ef_search = 100");
    }
}
