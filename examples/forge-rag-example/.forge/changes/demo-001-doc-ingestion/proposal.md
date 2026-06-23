# Proposal: demo-001-doc-ingestion

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- Layers: [backend] — single-layer demo -->

## Problem

The `forge-rag-example` project ships a scaffolded `backend/rag/`
workspace, but an adopter reading the example needs a concrete
demonstration of how a **single-layer backend change** flows through the
Forge pipeline — proposal → archive — for the RAG-specific surface: the
document-ingestion + query pipeline. Without it, the `rag/` modules
(chunking, embeddings, retrieval, re-rank, pgvector) read as disconnected
primitives rather than a coherent, TDD-driven feature.

## Solution

Demonstrate document ingestion + RAG query end-to-end across the `rag/`
pipeline:

1. **Chunking** — split a document into token-budgeted, overlapping
   windows (`rag/src/chunking.rs`).
2. **Embeddings** — embed chunks via the `Embedder` trait, with
   **tier-aware backend selection** (`rag/src/embeddings.rs`):
   T1/T2 use the cloud `MistralEmbedder`; **T3 forces the in-process
   `LocalEmbedder`** (zero egress — Article XI.6).
3. **pgvector HNSW upsert** — persist vectors with `vector_cosine_ops`
   (`rag/src/pgvector_store.rs`, `infra/postgres/init-pgvector.sql`).
4. **Hybrid retrieval** — fuse the dense (pgvector) leg and the sparse
   (BM25/full-text) leg via **Reciprocal Rank Fusion**
   (`rag/src/retrieval.rs`).
5. **Re-ranking** — coarse→exact re-rank the fused candidates
   (`rag/src/rerank.rs`).
6. **Grounded answer** — assemble the answer with its source citations
   (`rag.v1.QueryResponse`).

This is the `embeddings-pipeline` phase made concrete. Article XI.5's
non-AI fallback is exercised: when the cloud embedder is unavailable the
pipeline degrades to the local in-process embedder; the retrieved,
ranked source chunks ARE the non-AI answer when no generator runs.

This demo is **deliberately illustrative** — its purpose is to
demonstrate the full TDD + hexagonal + AI-First discipline for the RAG
pipeline, not to ship a tuned production retriever.

## Scope In

- The `rag/` pipeline TDD cycle: chunking, the `Embedder` trait + the
  tier-aware `select_backend` hook, RRF fusion, re-ranking, the pgvector
  HNSW store contract.
- The Article XI.5 embedder fallback (cloud → local) and the Article
  XI.6 in-process local path (zero egress for sovereign tiers).
- cucumber-rs BDD: ingest → query → grounded answer + the fallback path.

## Scope Out

- No live cloud embedding calls (tests use the deterministic local /
  fake path; the cloud `MistralEmbedder` is wired but not invoked in
  tests — no network).
- No generation step (the LLM gateway generation path is demo-003's
  surface; here the ranked sources are the answer).
- No MCP surface (demo-002) and no frontend (demo-003).
- No tuning of chunk size, RRF `k`, or the re-rank model — defaults
  only; adopters tune per corpus.

## Impact

- **Users affected**: adopters evaluating the RAG pipeline surface of
  the `ai-native-rag` archetype.
- **Technical impact**: illustrative; the product code lives in the
  rendered `backend/rag/` workspace with inline `#[cfg(test)]` tests.
- **Dependencies**: the rendered `ai-native-rag/1.0.0` backbone
  (`b7-2-scaffolder`) — provides the `rag/` modules + the verify-then-pin
  crate set (`pgvector`, `async-openai`, `fastembed`).
- **Risk level**: Low (illustrative, additive, no external calls).

## Constitution Compliance

- **Article I (TDD)**: every `rag/` module ships RED→GREEN→REFACTOR
  inline tests (chunking windows, RRF determinism, tier selection).
- **Article II (BDD)**: `features/doc_ingestion.feature` covers ingest →
  query → grounded answer + the fallback path.
- **Article III (Specs before code)**: this proposal → specs → design →
  tasks precedes the (already-scaffolded) implementation.
- **Article VII (Rust architecture)**: hexagonal; `Embedder` is a port;
  no `unwrap()`/`panic!()` in production paths.
- **Article XI.5 / XI.6 (AI-First)**: the embedder fallback (cloud →
  local) + the in-process local path (zero egress, T3).

---

**Gate**: Proposal complete. Next → `/forge:specify demo-001-doc-ingestion`.
