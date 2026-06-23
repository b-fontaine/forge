<!-- Audit: B.7.2 (b7-2-scaffolder, Phase 1) — ai-native-rag backend/mcp README -->
<!-- Standard: .forge/standards/global/mcp-servers.md -->

# `forge-rag-example` — MCP servers

Model Context Protocol (MCP) servers for `forge-rag-example`, built on the official
Rust SDK **`rmcp`**. Tools are defined once with the `#[tool_router]` /
`#[tool]` macros and exposed over two transports behind Cargo features.

> **Status**: Phase 1 ships this README + the module placeholder so the layer
> root exists. The `rmcp` server, the stub tool, and the transport wiring land
> in Phase 2. The `rmcp` pin lives only in the rendered `Cargo.toml.tmpl`
> (`ADR-B7-2-003`).

## Transports (per `global/mcp-servers.md`, `ADR-B7-2-005`)

| Transport | Cargo feature | Use case |
|-----------|---------------|----------|
| `transport/stdio.rs` | `mcp-stdio` (default) | local dev, subprocess clients |
| `transport/http.rs`  | `mcp-http`            | prod — `StreamableHttpService` on the axum router, `auth` (OAuth 2.1 PKCE / RFC 8707) → Zitadel / Envoy-OIDC |

## Conformance

- **Least privilege** — each tool declares the narrowest capability it needs.
- **Input validation** — tool params are schema-validated (`schemars`).
- **OAuth 2.1** — the HTTP transport authenticates against Zitadel (reused
  B.8.7 substrate); no tool runs unauthenticated in prod.
- At least one stub tool server among `db` | `file` | `search` is rendered so
  the server is exercisable end-to-end.
