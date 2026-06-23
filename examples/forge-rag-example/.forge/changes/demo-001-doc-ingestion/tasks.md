# Tasks: demo-001-doc-ingestion

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- TDD-ordered: RED test before GREEN impl per Article I. -->
<!-- The product code lives in the rendered backend/rag/ workspace; these -->
<!-- tasks document the RED→GREEN→REFACTOR cycle that produced it. -->

## Phase 1: Chunking (FR-BE-001)

- [x] RED — `chunking::tests::windows_advance_and_overlap` asserts
  `chunk_words("a b c d e f", 3, 1)` yields `[a b c],[c d e],[e f]`.
- [x] RED — `chunking::tests::overlap_clamped_below_window_so_it_terminates`.
- [x] GREEN — implement `chunk_words` (word-window + clamped overlap).
- [x] REFACTOR — extract the `Chunk { ordinal, text }` provenance struct.

## Phase 2: Embedder + tier selection (FR-BE-002)

- [x] RED — `embeddings::tests::t3_forces_local_even_when_mistral_preferred`.
- [x] RED — `embeddings::tests::t1_t2_honour_mistral_preference`.
- [x] GREEN — `Embedder` trait + `select_backend(tier, pref)`.
- [x] GREEN — `MistralEmbedder` (async-openai) + `LocalEmbedder`
  (fastembed, feature `local-embeddings`).
- [x] REFACTOR — `EmbedderKind` enum so selection is pure / testable.

## Phase 3: pgvector HNSW store (FR-BE-003)

- [x] RED — store-contract test (upsert then nearest-neighbour returns
  the upserted id).
- [x] GREEN — `pgvector_store` upsert + ANN query (`vector_cosine_ops`).
- [x] GREEN — `infra/postgres/init-pgvector.sql` HNSW index DDL.

## Phase 4: Hybrid retrieval + RRF (FR-BE-004)

- [x] RED — `retrieval::tests::rrf_rewards_documents_ranked_high_in_both_lists`.
- [x] RED — `retrieval::tests::rrf_is_deterministic_on_ties`.
- [x] GREEN — `reciprocal_rank_fusion(lists, k)` with deterministic tie-break.
- [x] REFACTOR — `DEFAULT_RRF_K = 60.0` named constant (no magic number).

## Phase 5: Re-ranking (FR-BE-005)

- [x] RED — `rerank::tests::*` (coarse→exact ordering).
- [x] GREEN — coarse→exact re-rank over the fused candidates.

## Phase 6: Fallback + grounded answer (FR-BE-006)

- [x] RED — fallback-path scenario in `features/doc_ingestion.feature`.
- [x] GREEN — cloud→local embedder degradation; ranked sources as the
  non-AI answer; `fallback_used = true`.
- [x] GREEN — cucumber-rs steps drive ingest → query → grounded answer.

## Phase 7: Quality + archive

- [x] `cargo clippy --workspace -- -D warnings` (no unwrap/panic in prod).
- [x] `cargo test --workspace` (all `rag/` unit tests + the feature) green.
- [x] Mark all `[x]`, set status: archived, populate timeline.
