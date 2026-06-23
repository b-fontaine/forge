<!-- Audit: B.7.2 (b7-2-scaffolder, Phase 1) — ai-native-rag backend/rag README -->
<!-- Standard: .forge/standards/global/rag-patterns.md -->

# `forge-rag-example` — RAG pipeline

The retrieval-augmented-generation pipeline for `forge-rag-example`, conforming to
`.forge/standards/global/rag-patterns.md`.

> **Status**: Phase 1 ships this README + the module placeholder so the layer
> root exists. The Rust source (the `Embedder` trait + impls, hybrid retrieval,
> re-ranking, pgvector access) and its tests land in Phase 2. The `pgvector` and
> `fastembed` pins live only in the rendered `Cargo.toml.tmpl` (`ADR-B7-2-003`).

## Stages (per `global/rag-patterns.md`)

1. **Chunking + embeddings** — documents are chunked, then embedded via the
   `embeddings::Embedder` trait (`ADR-B7-2-004`):
   - `MistralEmbedder` (default, T1/T2) — `async-openai` against a
     Mistral-EU / Scaleway / vLLM OpenAI-compatible base.
   - `LocalEmbedder` (T3 forced, XI.5 fallback) — `fastembed` in-process ONNX
     (zero egress). Model download is a documented first-run / build step.
   Selection is driven by `FORGE_EU_TIER` + `EMBEDDINGS_PROVIDER`.
2. **Hybrid retrieval** — dense vector ANN (pgvector HNSW, `vector_cosine_ops`)
   fused with sparse BM25 via Reciprocal Rank Fusion (RRF).
3. **Re-ranking** — coarse→exact re-ranking of the fused candidate set.
4. **Persistence** — pgvector HNSW indexes (reuses the B.8.5
   `pgvector:0.8.2-pg17` extension); see `infra/postgres/init-pgvector.sql`.

## Execution model

Heavy retrieval / embedding work runs as **Temporal activity-only** workers
(the `temporalio-sdk` is pre-alpha; activity-only avoids the workflow-determinism
surface). Workflow orchestration is consumed from the B.8 Temporal substrate.

## Article XI.5 fallback

If the embeddings provider or the LLM upstream is unavailable, the pipeline
degrades to the local embedding path and a non-AI answer (cached / refusal)
rather than failing open. The fallback branch is unit-tested.
