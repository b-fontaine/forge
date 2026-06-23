# Proposal: demo-002-mcp-search-tool

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- Layers: [backend] — single-layer demo -->

## Problem

demo-001 built the `rag/` retriever, but it is reachable only from
inside the backend. Adopters integrating the RAG corpus with MCP-capable
hosts (IDEs, agents, Claude Desktop) need a concrete demonstration of how
to expose the retriever as an **MCP `search` tool** — over both local
(stdio) and networked (streamable-HTTP) transports — following the
`mcp-servers.md` security posture. Without it, the `backend/mcp/` module
reads as an isolated stub.

## Solution

Demonstrate a single-layer backend change that exposes the retriever as
an MCP `search` tool built on the official Rust SDK `rmcp`:

1. **Tool declaration** — `#[tool_router]` / `#[tool]` macros declare a
   `search` tool once (`mcp/src/lib.rs`), with a `schemars`-derived input
   schema so every inbound call is schema-validated.
2. **Dual transport** — the same tool is served over two transports
   behind Cargo features (`mcp/src/transport/`):
   - `stdio` (feature `mcp-stdio`, default) for local-dev hosts.
   - streamable-HTTP (feature `mcp-http`) via `StreamableHttpService`,
     with OAuth 2.1 → Zitadel/Envoy-OIDC (the `auth` rmcp feature).
3. **Least privilege** — one capability per tool; `search` is bounded
   (a hard `MAX_SEARCH_LIMIT` cap, read-only, no filesystem/shell/SQL
   from raw arguments).

This is the `mcp/` surface made concrete, demonstrating the MCP security
posture from `mcp-servers.md`.

This demo is **deliberately illustrative** — its purpose is to
demonstrate the MCP tool + dual-transport + security discipline, not to
ship a tuned production search server.

## Scope In

- The rmcp `#[tool_router]` `search` tool with a schema-validated input.
- Dual transport (stdio + streamable-HTTP) behind Cargo features.
- The least-privilege contract: bounded limit, read-only index.
- The OAuth 2.1 → Zitadel hook on the HTTP transport.
- cucumber-rs BDD: search happy path + the bounded (capped) path.

## Scope Out

- No live OAuth server (the Zitadel wiring is a documented hook; tests
  exercise the tool directly, no network).
- No generation / LLM gateway (demo-003) and no frontend (demo-003).
- No tuning of the search ranking (the bounded substring index is
  illustrative; adopters back it with demo-001's retriever).

## Impact

- **Users affected**: adopters integrating the RAG corpus with
  MCP-capable hosts.
- **Technical impact**: illustrative; the product code lives in the
  rendered `backend/mcp/` workspace with inline `#[cfg(test)]` tests.
- **Dependencies**: demo-001 (the retriever the tool exposes); the
  rendered backbone's `rmcp = 1.7.0` pin (verify-then-pin, `b7-2`).
- **Risk level**: Low (illustrative, additive, no external calls).

## Constitution Compliance

- **Article I (TDD)**: `mcp/` ships RED→GREEN tests (schema describes
  fields, limit clamping, bounded search).
- **Article II (BDD)**: `features/mcp_search.feature` covers the happy +
  bounded paths.
- **Article III (Specs before code)**: this proposal → specs → design →
  tasks precedes the (already-scaffolded) implementation.
- **Article VII (Rust architecture)**: hexagonal; no `unwrap()`/`panic!()`
  in production paths.
- **Article IX/XI (security posture)**: least privilege, schema-validated
  input, bounded results, OAuth on the network transport.

---

**Gate**: Proposal complete. Next → `/forge:specify demo-002-mcp-search-tool`.
