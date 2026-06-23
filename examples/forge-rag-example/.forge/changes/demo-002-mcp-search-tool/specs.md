# Specs: demo-002-mcp-search-tool

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- Layers: [backend] — single-layer. FR prefix: FR-BE-* (Article IV delta). -->

This spec follows the Article IV delta convention. It ADDs the MCP
`search` tool requirements to the `forge-rag-example` backend. The
implementation lives in the rendered `backend/mcp/` workspace.

## ADDED Requirements

### FR-BE-010: rmcp `search` tool with schema-validated input

- **MUST** — the `search` tool is declared with the rmcp
  `#[tool_router]` / `#[tool]` macros so it is registered exactly once.
- **MUST** — the tool's input parameters (`query`, `limit`) derive a
  JSON Schema (`schemars`) that rmcp uses to validate every inbound call;
  the advertised schema names both fields.

**Implemented in:** `backend/mcp/src/lib.rs` (`SearchServer::search`,
`SearchParameters`).
**Constitution reference:** Articles VII, `mcp-servers.md`.
**Testable:** yes — `mcp::tests::search_parameters_schema_describes_fields`.

### FR-BE-011: Least privilege — bounded, read-only search

- **MUST** — the `search` tool returns at most
  `min(limit, MAX_SEARCH_LIMIT)` hits; `limit = 0` (unset) maps to a
  small default. The hard cap is a named constant, never a magic literal.
- **MUST** — the tool is read-only over a bounded in-memory index: no
  filesystem access, no shell, no SQL built from raw arguments
  (`mcp-servers.md` least-privilege).

**Implemented in:** `backend/mcp/src/lib.rs` (`effective_limit`,
`MAX_SEARCH_LIMIT`).
**Constitution reference:** `mcp-servers.md`.
**Testable:** yes — `mcp::tests::limit_is_clamped_to_max_for_least_privilege`,
`mcp::tests::search_respects_the_hard_cap`.

### FR-BE-012: Dual transport behind Cargo features

- **MUST** — the same tool is served over two transports selected by
  Cargo features (ADR-B7-2-005):
  - `mcp-stdio` (default) — local-dev hosts (`transport/stdio.rs`).
  - `mcp-http` — `StreamableHttpService` on the axum router
    (`transport/http.rs`).
- **MUST** — neither transport changes the tool's behaviour or its
  least-privilege bound (the tool is declared once).

**Implemented in:** `backend/mcp/src/transport.rs`,
`backend/mcp/src/transport/{stdio,http}.rs`.
**Testable:** yes — transport-construction tests (feature-gated).

### FR-BE-013: OAuth 2.1 → Zitadel on the network transport

- **MUST** — the streamable-HTTP transport carries the OAuth 2.1 hook
  (the `auth` rmcp feature) routing to Zitadel/Envoy-OIDC; stdio (local)
  needs no network auth.
- **SHALL** — the OAuth wiring is a documented hook in this demo (no live
  IdP in tests, no network).

**Implemented in:** `backend/mcp/src/transport/http.rs` (auth hook) +
`infra` (Zitadel by reference).
**Constitution reference:** `mcp-servers.md` (auth), Article IX.
**Testable:** yes — the HTTP transport names the auth layer (static).

## Acceptance Criteria (Gherkin)

### AC-BE-010: search returns matching hits

```gherkin
Given an MCP search server over a bounded read-only index
When the search tool is called with query "fox"
Then the matching document is returned as a hit
```

### AC-BE-011: search respects the hard cap (least privilege)

```gherkin
Given an MCP search server over an index of 100 matching documents
When the search tool is called with limit 1000
Then at most MAX_SEARCH_LIMIT hits are returned
```

### AC-BE-012: input is schema-validated

```gherkin
Given the search tool's advertised JSON Schema
When an MCP host inspects the tool contract
Then the schema names both the "query" and "limit" parameters
```

## Scope

**In scope:** FR-BE-010..013 (the `search` tool, dual transport, least
privilege, OAuth hook).
**Out of scope:** generation (demo-003), the `rag/` pipeline internals
(demo-001), a live OAuth IdP, ranking tuning.
