# Verify-then-pin — b7-2-scaffolder (B.7.2 full)

> **Type** : research note (Phase 0, `/forge:implement b7-2-scaffolder`)
> **Date** : 2026-06-21
> **Method** : `cargo add --dry-run` in a throwaway scratch crate (no repo mutation),
>   toolchain `cargo 1.96.0 / rustc 1.96.0`. Article III.4 — pins are resolved LIVE,
>   never copied from a note. Supersedes the b7-standards baseline (2026-06-13) where
>   versions diverged.
> **Consumes** : `.forge/changes/b7-2-scaffolder/specs.md` FR-B7-2-040/041,
>   `design.md` ADR-B7-2-003/004/005.

## Resolved LIVE versions (2026-06-21)

| Crate | b7-standards baseline (2026-06-13) | **LIVE resolved (2026-06-21)** | Δ |
|---|---|---|---|
| `rmcp` | 1.7.0 (README 0.16.0 / Context7 0.5.0 / crates.io 1.7.0) | **`rmcp = "1.7.0"`** | drift resolved → 1.7.0 |
| `pgvector` (Rust crate) | 0.4.2 | **`pgvector = "0.4.2"`** | unchanged |
| `async-openai` | 0.41.0 | **`async-openai = "0.41.1"`** | patch bump 0.41.0→0.41.1 |
| `fastembed` | "5" (Context7) | **`fastembed = "5.17.2"`** | pinned to LIVE 5.17.2 |

> The rmcp 0.16.0/0.5.0/1.7.0 three-way drift (ADR-B7-3-003) is **resolved to 1.7.0**:
> crates.io is the ground truth; the README/Context7 snapshots were stale.

## rmcp 1.7.0 — feature gates (confirmed via `cargo add rmcp --dry-run`)

Base (always on for the MCP crate):
- `server` — server functionality + tool system
- `macros` — `#[tool]` / `#[tool_router]`
- `schemars` — JSON Schema for tool params
- `auth` — OAuth 2.0 (→ Zitadel/Envoy-OIDC, mcp-servers.md)

Transport gates (ADR-B7-2-005 dual transport, feature-gated):
- **stdio** → `transport-io` (server side) [+ `transport-child-process` if a client spawns a stdio server]
- **streamable-HTTP** (`StreamableHttpService`) → `transport-streamable-http-server`
  (+ `transport-streamable-http-server-session`), requires `server-side-http` + `tower`

Full available transport features observed: `transport-io`, `transport-child-process`,
`transport-worker`, `transport-streamable-http-server`,
`transport-streamable-http-server-session`, `transport-streamable-http-client(+reqwest/unix-socket)`,
`server-side-http`, `tower`.

### Proposed Cargo feature wiring for the rendered template (ADR-B7-2-005)

```toml
# backend/.../mcp crate — pins live HERE only (ADR-B7-2-003), never in standards
[dependencies]
rmcp = { version = "1.7.0", features = ["server", "macros", "schemars", "auth"] }

[features]
default = ["mcp-stdio"]
mcp-stdio = []   # gates rmcp "transport-io" wiring in transport/stdio.rs
mcp-http  = []   # gates rmcp "transport-streamable-http-server" + "server-side-http" + "tower"
```
(Exact feature plumbing finalised at the `mcp/transport/*` task, L2 cargo-check'd.)

## Embeddings (ADR-B7-2-004, Q-3) — dual `Embedder`

- `MistralEmbedder` (default, T1/T2) → `async-openai = "0.41.1"` with
  `.with_api_base("https://api.mistral.ai/...")` (Scaleway-EU / vLLM, OpenAI-compatible).
- `LocalEmbedder` (T3 forced, XI.5 fallback) → `fastembed = "5.17.2"`,
  `TextEmbedding::try_new(InitOptions::new(EmbeddingModel::AllMiniLML6V2))` → `.embed(docs, None)`
  (in-process ONNX, dim 384, zero egress). Model download = first-run/build step (documented).

## pgvector — reuse B.8.5 extension; Rust crate is the access layer

- Extension: **reused** `pgvector/pgvector:0.8.2-pg17` (B.8.5) — NOT re-introduced.
- Rust crate: `pgvector = "0.4.2"` with the `sqlx` feature for HNSW `vector_cosine_ops`
  ANN queries.

## Pin placement (FR-B7-2-041, ADR-B7-2-003)

All four pins land **only** in the rendered `backend/.../Cargo.toml.tmpl`. No
`global/*.md` standard gains a version (`b7-3.test.sh` T-007 no-inline-pin guard
stays GREEN). L2 harness re-verifies the rendered tree compiles with these pins.

## Re-verification note

`async-openai` moved 0.41.0→0.41.1 and `fastembed` resolved to 5.17.2 since the
b7-standards baseline — confirming why pins MUST be resolved at the consuming
brick, not carried from an upstream note (coroot/Q-004 lesson). `b7-6-harness`
re-verifies LIVE again at promotion.
