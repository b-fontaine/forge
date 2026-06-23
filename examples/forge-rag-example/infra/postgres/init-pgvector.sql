-- <!-- Audit: B.7.2 (b7-2-scaffolder, Phase 1) — ai-native-rag pgvector + HNSW init -->
-- Structural precedent: full-stack-monorepo/2.0.0/infra/postgres/init-pgvector.sql.tmpl
--
-- Enable pgvector in the forge-rag-example database and create the HNSW index the
-- RAG pipeline's hybrid retrieval depends on. Runs once on first DB init via
-- docker-entrypoint-initdb.d. The image (pgvector:0.8.2-pg17, reused B.8.5)
-- ships the extension files; the CREATE EXTENSION makes it available here.
-- pgvector extension version target = pgvector-0.8 (policy: persistence.yaml).

CREATE EXTENSION IF NOT EXISTS vector;

-- ── RAG document chunks ──────────────────────────────────────────────────────
-- Seed table for the RAG pipeline (backend/rag/). The embedding dimension below
-- matches the default LocalEmbedder model (AllMiniLML6V2 → dim 384); adjust to
-- your chosen embeddings provider before loading real data.
CREATE TABLE IF NOT EXISTS rag_chunks (
    id          BIGSERIAL  PRIMARY KEY,
    document_id TEXT        NOT NULL,
    content     TEXT        NOT NULL,
    embedding   vector(384) NOT NULL
);

-- ── HNSW index (vector_cosine_ops) ───────────────────────────────────────────
-- Dense-vector ANN index for the vector leg of hybrid retrieval (the BM25 leg
-- is handled by Postgres full-text search; the two are fused via RRF in the RAG
-- pipeline). vector_cosine_ops matches the cosine-similarity retrieval the
-- rag-patterns standard prescribes.
CREATE INDEX IF NOT EXISTS rag_chunks_embedding_hnsw
    ON rag_chunks
    USING hnsw (embedding vector_cosine_ops);

-- ── BM25 / full-text leg ─────────────────────────────────────────────────────
-- GIN index over the tsvector of content for the sparse retrieval leg.
CREATE INDEX IF NOT EXISTS rag_chunks_content_fts
    ON rag_chunks
    USING gin (to_tsvector('simple', content));
