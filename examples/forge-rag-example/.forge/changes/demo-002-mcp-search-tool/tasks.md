# Tasks: demo-002-mcp-search-tool

<!-- Audit: B.7.7 (illustrative demo of b7-7-example) -->
<!-- TDD-ordered: RED test before GREEN impl per Article I. -->
<!-- The product code lives in the rendered backend/mcp/ workspace; these -->
<!-- tasks document the RED→GREEN→REFACTOR cycle that produced it. -->

## Phase 1: Tool + schema (FR-BE-010)

- [x] RED — `mcp::tests::search_parameters_schema_describes_fields`
  asserts the derived JSON Schema names `query` and `limit`.
- [x] GREEN — `SearchParameters` (`schemars::JsonSchema`) + the
  `#[tool(name = "search")]` method on `SearchServer`.
- [x] GREEN — `#[tool_router(server_handler)]` generates the `ToolRouter`
  + `ServerHandler` impl.
- [x] REFACTOR — `SearchHit` / `SearchOutput` typed result structs.

## Phase 2: Least privilege (FR-BE-011)

- [x] RED — `mcp::tests::limit_is_clamped_to_max_for_least_privilege`.
- [x] RED — `mcp::tests::search_respects_the_hard_cap` (100 matches,
  limit 1000 ⇒ MAX_SEARCH_LIMIT hits).
- [x] RED — `mcp::tests::search_matches_bounded_index_case_insensitively`.
- [x] GREEN — `effective_limit` clamp + `MAX_SEARCH_LIMIT = 50` constant.
- [x] GREEN — bounded read-only substring search over the in-memory index.

## Phase 3: Dual transport (FR-BE-012)

- [x] RED — transport-construction test (stdio default builds; http
  builds under `mcp-http`).
- [x] GREEN — `transport/stdio.rs` (feature `mcp-stdio`, default).
- [x] GREEN — `transport/http.rs` (`StreamableHttpService`, feature
  `mcp-http`).
- [x] REFACTOR — `transport.rs` mounts the shared `ToolRouter` for both.

## Phase 4: OAuth hook (FR-BE-013)

- [x] GREEN — compose the rmcp `auth` (OAuth 2.1) layer on the HTTP
  transport, routing to Zitadel/Envoy-OIDC (documented hook).
- [x] GREEN — stdio carries no network auth (local trust).

## Phase 5: BDD + quality + archive

- [x] GREEN — `features/mcp_search.feature` (happy + bounded paths).
- [x] `cargo clippy --workspace -- -D warnings` (no unwrap/panic in prod).
- [x] `cargo test --workspace` (all `mcp/` unit tests + the feature) green.
- [x] Mark all `[x]`, set status: archived, populate timeline.
