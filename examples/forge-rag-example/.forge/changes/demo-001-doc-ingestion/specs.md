# Specs: demo-001-doc-ingestion

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- Layers: [backend] — single-layer. FR prefix: FR-BE-* (Article IV delta). -->

This spec follows the Article IV delta convention. It ADDs the
document-ingestion + RAG-query requirements to the `forge-rag-example`
backend. The implementation lives in the rendered `backend/rag/`
workspace.

## ADDED Requirements

### FR-BE-001: Token-budgeted chunking

- **MUST** — documents are split into word-windows of a configured
  `max_words` with a token-budgeted `overlap` shared between consecutive
  windows so context is not severed mid-thought (`rag-patterns.md`).
- **MUST** — `overlap` is clamped below `max_words` so the window always
  advances (no infinite loop); empty input yields zero chunks.
- **MUST** — each chunk carries its 0-based `ordinal` for provenance.

**Implemented in:** `backend/rag/src/chunking.rs` (`chunk_words`).
**Testable:** yes — `chunking::tests::*`.

### FR-BE-002: Embedder trait + tier-aware backend selection

- **MUST** — embeddings are produced through a provider-agnostic
  `Embedder` port (cloud + local impls both implement it).
- **MUST** — backend selection is tier-aware: T1/T2 honour the configured
  provider preference (default cloud `MistralEmbedder`); **T3 forces the
  in-process `LocalEmbedder`** — cloud embedding providers are forbidden
  at T3 (EU sovereignty, Article XI.6).
- **SHALL** — selection is a pure, unit-testable function
  (`select_backend`) so the rule is verified without constructing a heavy
  embedder.

**Implemented in:** `backend/rag/src/embeddings.rs`
(`Embedder`, `select_backend`).
**Constitution reference:** Articles VII, XI.6, `compliance-tiers`.
**Testable:** yes — `embeddings::tests::t3_forces_local_*`.

### FR-BE-003: pgvector HNSW upsert (`vector_cosine_ops`)

- **MUST** — chunk vectors are upserted into Postgres/pgvector with an
  HNSW index over `vector_cosine_ops` (`infra/postgres/init-pgvector.sql`).
- **MUST** — the store is addressed through a port so the domain stays
  free of `sqlx` (Article VII domain purity).

**Implemented in:** `backend/rag/src/pgvector_store.rs`.
**Testable:** yes — store-contract tests (the SQL DDL ships in infra).

### FR-BE-004: Hybrid retrieval via Reciprocal Rank Fusion

- **MUST** — the dense (pgvector similarity) leg and the sparse
  (BM25/full-text) leg are fused via RRF (`Σ 1/(k+rank)`), needing only
  ranks (not the incomparable raw scores).
- **MUST** — fusion output is deterministic: ties break by `document_id`
  so the ranking is byte-stable.

**Implemented in:** `backend/rag/src/retrieval.rs`
(`reciprocal_rank_fusion`, `DEFAULT_RRF_K`).
**Testable:** yes — `retrieval::tests::rrf_*`.

### FR-BE-005: Coarse→exact re-ranking

- **MUST** — the fused candidate set is re-ranked (coarse retrieval →
  exact re-rank) before the top-k is returned (`rag-patterns.md`).

**Implemented in:** `backend/rag/src/rerank.rs`.
**Testable:** yes — `rerank::tests::*`.

### FR-BE-006: Article XI.5 embedder fallback + grounded answer

- **MUST** — when the cloud embedder is unavailable, the pipeline
  degrades to the local in-process embedder (non-AI fallback path).
- **MUST** — the answer is grounded: every returned answer carries its
  supporting `SourceChunk`s with fused scores (citations always attached).
- **MUST** — `QueryResponse.fallback_used` is true when the non-AI
  fallback produced the answer.

**Implemented in:** `backend/rag/src/lib.rs` (`SourceChunk`,
`ComplianceTier`) + the gateway's unary handler (`llm_gateway`).
**Constitution reference:** Article XI.5.
**Testable:** yes — covered by `features/doc_ingestion.feature`.

## Acceptance Criteria (Gherkin)

### AC-BE-001: Ingest then query returns a grounded answer

```gherkin
Given a document is chunked, embedded, and upserted into pgvector
When a user queries a question about that document
Then the hybrid retriever fuses the vector and BM25 legs via RRF
And the top-ranked source chunks are returned as grounding
And the answer cites those source chunks
```

### AC-BE-002: T3 forces the local embedder (XI.6)

```gherkin
Given the compliance tier is T3
When the embedder backend is selected
Then the in-process LocalEmbedder is chosen
And no cloud embedding provider is contacted (zero egress)
```

### AC-BE-003: Embedder fallback (XI.5)

```gherkin
Given the cloud embedder is unavailable
When a document is embedded
Then the pipeline degrades to the local in-process embedder
And the query still returns ranked source chunks as the answer
And fallback_used is true
```

## Scope

**In scope:** FR-BE-001..006 (the `rag/` pipeline + the XI.5/XI.6 paths).
**Out of scope:** generation (demo-003), MCP (demo-002), tuning.
