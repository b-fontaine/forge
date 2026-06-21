# Standard — MCP servers

<!-- Audit: B.7.3 (b7-standards) — ai-native-rag archetype. -->
<!-- Schema mapping: documents the `mcp-servers` component of -->
<!-- `.forge/schemas/ai-native-rag/1.0.0.yaml` (delivered_by: B.7.3). -->
<!-- Pattern standard — NO version pins (rmcp pin rides with B.7.2-full ; -->
<!-- baseline in .forge/research/b7-standards-verify-then-pin.md). -->

> **Status**: pattern guidance for the `ai-native-rag` archetype (T7).
> **Schema component mapping**: `mcp-servers` (`ai-native-rag/1.0.0.yaml`) ↔ this
> standard (1:1). The schema references it as `delivered_by: B.7.3`.

## Schema mapping & scope

The archetype ships MCP server stubs (`db` / `file` / `search`) built on the
official Rust SDK **`rmcp`**. This standard documents the server pattern,
security, auth, and versioning. The `rmcp` version pin is delivered by
B.7.2-full's `Cargo.toml.tmpl` (verify-then-pin LIVE), NOT here.

## rmcp server pattern

- Use the official `rmcp` crate (`modelcontextprotocol/rust-sdk`) with the
  `server` feature; tokio async runtime.
- Declarative tools via the `#[tool_router]` / `#[tool]` macros (`rmcp-macros`):
  each tool is a typed method whose `JsonSchema` params are auto-derived.
- Transports: **stdio** for local hosts (e.g. desktop AI clients); the axum-native
  `StreamableHttpService` (`/mcp` endpoint, SSE) for web/cloud deployments —
  consistent with the archetype's axum backend.
- Cargo dependency form (version is a placeholder — pinned by B.7.2-full):
  `rmcp = { version = "<pinned-by-B.7.2-full>", features = ["server"] }`.

## Security

- **Least privilege**: a tool exposes exactly one capability; no general-purpose
  "run this" tool. The `db` / `file` / `search` stubs are sandboxed to a fixed
  scope (a specific schema / a whitelisted directory / a bounded index).
- **Validate every input**: rely on the derived `JsonSchema` plus explicit bounds
  checks; treat all tool arguments as untrusted.
- **No arbitrary execution**: tool implementations MUST NOT shell out, eval, or
  perform filesystem/command operations derived from raw tool arguments. Path
  arguments are resolved against an allow-list, never used verbatim.
- Tools that touch persistence go through the same tenant-scoping as the app.

## Authentication

- The streamable-HTTP transport supports **OAuth 2.1 + PKCE (S256) + RFC 8707**
  resource binding, with Protected-Resource-Metadata / Authorization-Server-Metadata
  discovery and automatic token refresh. SSE endpoints (`GET /mcp/sse`,
  `POST /mcp/message`) require a valid token.
- Reuse the archetype's identity plane — do not introduce a second IdP: tokens are
  issued by **Zitadel** (`identity.yaml`, B.8.7) and validated at the edge by the
  **Envoy SecurityPolicy JWT** wiring (B.8.12). The MCP server trusts the same
  issuer/JWKS.

## Versioning & maturity

- Negotiate the MCP protocol version; pin `rmcp` **exactly** and re-verify at every
  bump.
- **rmcp maturity caveat (verify-then-pin, Article III.4)**: the Rust SDK is
  upstream **Tier 3** (conformance assessment 2026-02-25) — it meets the ≥80%
  conformance pass rate but explicitly "fails ... stable release versioning". This
  is fast-moving, pre-stable-process software. Concretely, at authoring (2026-06-13)
  the crate version differed across **three** sources — README `0.16.0`, Context7
  index `0.5.0`, and **crates.io LIVE `1.7.0`** — so the pin MUST be taken from a
  LIVE `cargo` resolution, never from documentation. Keep `rmcp` on the
  upstream-release watch-list (mirrors the connectrpc pre-1.0 waiver in
  `transport.yaml`); re-verify when it reaches a stable release process.

## Constitutional Compliance

- **XI.6** — MCP tools that surface user data minimise PII and respect consent/DPA.
- **IX.6** — tool invocations are traced (latency, errors) alongside the LLM spans.
- **VIII** — MCP-over-HTTP rides the sanctioned ingress (Envoy) + identity
  (Zitadel); no parallel gateway or IdP.
- **III.4** — the rmcp transport/auth API is Context7-verified
  (`research` §2); the maturity caveat + three-source version conflict are recorded
  verbatim, not glossed; no rmcp version is pinned here.

## Out-of-scope

- **Version pins** (`rmcp`, `rmcp-macros`) — B.7.2-full `Cargo.toml.tmpl`,
  verify-then-pin LIVE (baseline: `research` §1 — `rmcp` 1.7.0 at authoring).
- Concrete MCP server implementations + templates — B.7.2-full.
- Runtime Janus AI refusal rules (J.8.c) — `b7-9-janus-ai`.
