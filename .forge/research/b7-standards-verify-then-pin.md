# Research — B.7.3 verify-then-pin baseline + Context7 grounding

> **Type**: research note (input to `b7-standards`, 2026-06-13)
> **Purpose**: record the LIVE-verified dependency baseline + the pattern
>   grounding for the three B.7.3 standards. Pins are DEFERRED to B.7.2-full
>   (the brick that ships the consuming `Cargo.toml.tmpl`), to be RE-verified
>   LIVE then — this note is the baseline, not a pin source.
> **Source contexts**: `.forge/_memory/b7-ai-native-rag-exploration.md` (ratified),
>   plan §6.2 B.7.3, CLAUDE.md rule 6 (Context7 mandatory), the Q-004/Q-006/coroot
>   verify-then-pin lesson institutionalised in `standards-lifecycle.md` v1.1.0.

## 1. Verify-then-pin baseline (crates.io LIVE, 2026-06-13)

`cargo search` against the live crates.io index — NOT Context7 snapshots, NOT
READMEs (both proven stale below).

| Crate | LIVE version | Role | Notes |
|-------|-------------|------|-------|
| `rmcp` | **1.7.0** | MCP server/client SDK (official, `modelcontextprotocol/rust-sdk`) | `features = ["server"]`; `rmcp-macros` 1.7.0 (`#[tool_router]`). tokio async. |
| `pgvector` | **0.4.2** | Rust crate — `Vector` type for sqlx/postgres/diesel | DISTINCT from the `pgvector-0.8` Postgres *extension* already pinned in `persistence.yaml`. |
| `async-openai` | **0.41.0** | OpenAI-compatible HTTP client (Rust) | candidate upstream client for the in-repo LLM gateway proxy → Mistral-Scaleway / vLLM (both expose OpenAI-compatible APIs). Pre-1.0. |

### ⚠️ rmcp — THREE conflicting version sources (the Q-004 trap, live)

- Context7 README snippet: `rmcp = "0.16.0"`
- Context7 library index: `rmcp_v0_5_0`
- **crates.io LIVE: `1.7.0`**

Three different answers; only `cargo search` was correct. Had B.7.x pinned rmcp
from any doc source, B.7.2-full would have shipped a broken `Cargo.toml`. This is
the canonical justification for the verify-then-pin discipline and is recorded in
`mcp-servers.md` as a MUST.

### rmcp maturity caveat (Article III.4 — record, don't gloss)

The upstream conformance assessment (`rust-sdk/conformance/results/
2026-02-25-rust-sdk-assessment.md`) classifies the Rust SDK as **Tier 3**: it
meets the ≥80% conformance pass rate but "fails ... stable release versioning"
and other operational/maintenance criteria. ⇒ `mcp-servers.md` MUST flag rmcp as
fast-moving / pre-stable-process and require exact-pin + re-verify-at-bump, on the
upstream-release watch-list (mirrors the connectrpc pre-1.0 waiver pattern in
`transport.yaml`).

**These versions are a BASELINE for B.7.2-full, not pins shipped by B.7.3.**
Per the `transport.yaml`/b8-6 precedent, version pins land in a `.yaml` standard
WITH the consuming template (B.7.2-full `Cargo.toml.tmpl`), re-verified LIVE then.

## 2. Pattern grounding (Context7, 2026-06-13)

### rag-patterns.md
- **HNSW recall/speed**: `SET hnsw.ef_search = N` (higher = better recall, slower).
- **Filtered queries**: `SET hnsw.iterative_scan = 'strict_order' | 'relaxed_order'`
  to still satisfy `LIMIT` after WHERE filtering.
- **Coarse-then-exact re-rank**: `binary_quantize(embedding)::bit(N)` `<~>` (Hamming)
  for a fast wide candidate pass (LIMIT 100–1000), then re-order by exact
  `<->`/`<=>` distance LIMIT 10.
- **Hybrid search**: combine pgvector with Postgres full-text (BM25-like) via
  **Reciprocal Rank Fusion** or a cross-encoder re-ranker (pgvector README).
- Distance ops: `<->` L2, `<=>` cosine, `<#>` inner product; `vector_cosine_ops`
  HNSW opclass.

### llm-gateway.md
- In-repo Rust axum proxy; upstream via OpenAI-compatible client (`async-openai`)
  → Mistral-Scaleway / vLLM (EU) / OpenAI (fallback, T1 only).
- **Tier-aware refusal** couples to existing EU machinery: `compliance-tiers.md`
  (T1/T2/T3), `forbidden-components-rules.md` (I.3 — T3 forbids OpenAI-direct /
  Vertex / Bedrock), Demeter (K.3), J.8.c (Janus AI rules, deferred to b7-9).
- Prompt-audit logs (wires `prompt-audit` schema phase + Article IX.6 token
  counts / fallback invocations), BYOK, tenant-scoped budgets, kill switch.
- PII minimisation + explicit consent (Article XI.6); mandatory non-AI fallback
  (Article XI.5).

### mcp-servers.md
- rmcp server pattern: `#[tool_router]`/`#[tool]` macros; stdio (local hosts) +
  `StreamableHttpService` (axum, web/cloud) transports.
- **Security**: least-privilege tools, validate every tool input (JsonSchema),
  NO arbitrary filesystem/command execution from tool args; sandboxed `db`/`file`/
  `search` stubs.
- **Auth**: rmcp supports OAuth 2.1 + PKCE (S256) + RFC 8707 resource binding +
  Protected-Resource-Metadata discovery → couples to Zitadel (B.8.7) + Envoy
  SecurityPolicy JWT (B.8.12). SSE endpoints require a valid OAuth token.
- **Versioning**: protocol-version negotiation; pin rmcp exactly, re-verify at bump
  (Tier-3 caveat above).

## 3. Scope decision (maintainer 2026-06-13)

B.7.3 ships the **three `.md` pattern standards only** (rag-patterns / llm-gateway
/ mcp-servers) + `index.yml` triggers + `REVIEW.md` birth entries + a harness. It
ships **NO version pins** (no new `.yaml`): the §1 baseline rides with B.7.2-full's
`Cargo.toml.tmpl` (transport.yaml/b8-6 precedent), re-verified LIVE there. Avoids
orphan pins under the j7 gate + 12-month review with no consumer.
