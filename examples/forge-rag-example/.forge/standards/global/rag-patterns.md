# Standard — RAG patterns (retrieval-augmented generation)

<!-- Audit: B.7.3 (b7-standards) — ai-native-rag archetype. -->
<!-- Schema mapping: documents the `rag-pipeline` component of -->
<!-- `.forge/schemas/ai-native-rag/1.0.0.yaml` (delivered_by: B.7.3). -->
<!-- Pattern standard — NO version pins (pins ride with B.7.2-full's -->
<!-- Cargo.toml.tmpl, verify-then-pin LIVE ; baseline in -->
<!-- .forge/research/b7-standards-verify-then-pin.md). -->

> **Status**: pattern guidance for the `ai-native-rag` archetype (T7).
> **Schema component mapping**: the schema component `rag-pipeline`
> (`ai-native-rag/1.0.0.yaml`) is documented by this standard; the schema
> references it as `delivered_by: B.7.3`.

## Schema mapping & scope

`rag-pipeline` (schema component) ↔ `rag-patterns.md` (this standard). RAG runs on
Postgres + pgvector (the `pgvector-0.8` extension is pinned in `persistence.yaml`;
the Rust `pgvector` crate pin is delivered by B.7.2-full, not here). This standard
is patterns only — chunking, retrieval, re-ranking, tuning, evaluation, EU
sovereignty.

## Chunking & embeddings

- Chunk by semantic unit (heading/paragraph/code-block), not fixed byte windows;
  keep a token-budgeted overlap (≈10–20%) so context isn't severed mid-thought.
- Store `embedding vector(N)` alongside the source text + provenance metadata
  (doc id, chunk ordinal, source URI, ingest timestamp) for citation + audit.
- Normalise embeddings when the model expects cosine space; pick the distance op
  to match the model (`vector_cosine_ops` for cosine-trained encoders).
- Embedding model choice is tier-gated (see *EU sovereignty* below).

## Retrieval (vector + hybrid)

- Distance operators: `<->` (L2), `<=>` (cosine), `<#>` (negative inner product).
  Match the operator to the embedding space.
- **Hybrid search** (recommended for recall): combine pgvector similarity with
  Postgres full-text search (BM25-like `ts_rank`), then fuse with **Reciprocal
  Rank Fusion** (RRF) or a cross-encoder. Hybrid beats pure-vector on keyword-heavy
  or out-of-distribution queries.
- For filtered retrieval (WHERE + ORDER BY distance), enable iterative scan so the
  `LIMIT` is still satisfied after filtering:
  `SET hnsw.iterative_scan = 'strict_order';` (or `'relaxed_order'` for recall).

## Re-ranking

- **Coarse → exact** two-stage: a wide cheap pass then an exact re-order. With
  binary quantization: `binary_quantize(embedding)::bit(N)` `<~>` (Hamming) for a
  large candidate set (`LIMIT` 100–1000), then re-rank the candidates by the exact
  `<->`/`<=>` distance to the original vectors (`LIMIT` 10). Cuts cost on large
  corpora while preserving top-k quality.
- Optionally re-rank the shortlist with a cross-encoder before handing context to
  the LLM.

## pgvector HNSW tuning

- Build the index with the matching opclass, e.g.
  `CREATE INDEX ON items USING hnsw (embedding vector_cosine_ops);`.
- **Recall vs speed**: `SET hnsw.ef_search = N;` — higher `ef_search` improves
  recall at the cost of latency. Tune per workload against a labelled eval set.
- **Filtered queries**: `hnsw.iterative_scan` (`strict_order` | `relaxed_order` |
  `off`) keeps the result set full when a WHERE clause prunes candidates.
- Large/high-volume vector workloads: see `persistence.yaml` rationale (Citus
  sharding > ~5 TB; this archetype is the high-volume vector tenant).

## Context-window management

- Budget the prompt: reserve tokens for system + question + answer; fill the
  remainder with the highest-ranked chunks, newest-or-most-relevant first.
- De-duplicate near-identical chunks; always attach citations (provenance
  metadata) so answers are traceable and the non-AI fallback can show sources.

## Evaluation

- Maintain a labelled retrieval eval set; track recall@k / nDCG for retrieval and
  faithfulness/groundedness for generation. Gate changes on eval, not vibes
  (aligns with the schema's `embeddings-pipeline` phase — spec the pipeline +
  its eval before design).

## EU sovereignty

- The embeddings provider is **tier-gated**. T3 (EU-strict) MUST use a
  self-hosted embeddings model or an EU-sovereign provider (e.g. Mistral on
  Scaleway); OpenAI-direct embeddings are forbidden at T3. This standard does NOT
  restate the tier matrix — see `compliance-tiers.md` (T1/T2/T3) and
  `data-stewardship-rules.md` (Demeter, dependency jurisdiction). The LLM call
  itself is governed by `llm-gateway.md`.

## Constitutional Compliance

- **Article XI.5** — RAG features MUST have a non-AI fallback (e.g. return ranked
  source documents / full-text search results when generation is unavailable).
- **Article XI.6** — minimise PII in chunks sent to embedding/LLM providers;
  honour consent + DPA (see `data-stewardship-rules.md`).
- **Article IX.6** — retrieval + generation spans are traced (latency, token
  counts, fallback invocations) per the schema's `prompt-audit` phase.
- **Article III.4** — all pgvector SQL here is Context7-verified
  (`.forge/research/b7-standards-verify-then-pin.md` §2); no fabricated API.

## Out-of-scope

- **Version pins** (Rust `pgvector` crate, embedding model) — delivered by
  B.7.2-full's `Cargo.toml.tmpl` / scaffold, verify-then-pin LIVE; the baseline is
  recorded in `.forge/research/b7-standards-verify-then-pin.md` §1.
- Templates / scaffold-plan / runtime code — B.7.2-full.
- Runtime Janus refusal rules for AI archetypes (J.8.c) — `b7-9-janus-ai`.
