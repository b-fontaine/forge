//! `mcp` — Model Context Protocol server(s) for the ai-native-rag archetype,
//! built on the official Rust SDK `rmcp` (`global/mcp-servers.md`).
//!
//! Tools are declared once with the `#[tool_router(server_handler)]` / `#[tool]`
//! macros and exposed over two transports behind Cargo features (ADR-B7-2-005):
//!   - [`transport::stdio`] (feature `mcp-stdio`, default) — local-dev hosts.
//!   - [`transport::http`] (feature `mcp-http`) — `StreamableHttpService` on the
//!     axum router, OAuth 2.1 → Zitadel/Envoy-OIDC (the `auth` rmcp feature).
//!
//! Security (`mcp-servers.md`): least privilege (one capability per tool), every
//! input schema-validated (`schemars`), no arbitrary execution, search bounded
//! to a fixed in-memory index.

pub mod transport;

use rmcp::handler::server::wrapper::{Json, Parameters};
use rmcp::{tool, tool_router};
use serde::{Deserialize, Serialize};

/// Parameters for the `search` tool. Schema is auto-derived (`JsonSchema`) and
/// used to validate every inbound tool call (`mcp-servers.md` input validation).
#[derive(Debug, Deserialize, schemars::JsonSchema, Default)]
pub struct SearchParameters {
    /// The query string to match against the bounded document index.
    pub query: String,
    /// Maximum number of hits to return (bounded server-side to a safe cap).
    #[serde(default)]
    pub limit: u32,
}

/// One search hit.
#[derive(Debug, Serialize, schemars::JsonSchema, PartialEq)]
pub struct SearchHit {
    /// Document id of the match.
    pub document_id: String,
    /// A short snippet of the matched content.
    pub snippet: String,
}

/// The `search` tool's output.
#[derive(Debug, Serialize, schemars::JsonSchema)]
pub struct SearchOutput {
    /// The matched hits (capped at the server-side limit).
    pub hits: Vec<SearchHit>,
}

/// Hard upper bound on `limit` — least-privilege: a tool never returns an
/// unbounded result set regardless of what the caller asks for.
pub const MAX_SEARCH_LIMIT: u32 = 50;

/// The MCP search server — the `search` stub server (`db`|`file`|`search`)
/// mandated by `mcp-servers.md`. Wraps a bounded, read-only document index;
/// the `#[tool_router(server_handler)]` macro generates the `ToolRouter` and the
/// `ServerHandler` impl (dispatch calls `Self::tool_router()`).
pub struct SearchServer {
    index: Vec<(String, String)>,
}

#[tool_router(server_handler)]
impl SearchServer {
    /// Search the bounded index for `query`, returning at most
    /// `min(limit, MAX_SEARCH_LIMIT)` hits. Least-privilege + input-validated:
    /// no filesystem, no shell, no SQL from raw arguments (`mcp-servers.md`).
    #[tool(name = "search", description = "Full-text search over a bounded, read-only document index")]
    pub fn search(&self, Parameters(params): Parameters<SearchParameters>) -> Json<SearchOutput> {
        let cap = effective_limit(params.limit);
        let needle = params.query.to_lowercase();
        let hits = self
            .index
            .iter()
            .filter(|(_, content)| content.to_lowercase().contains(&needle))
            .take(cap as usize)
            .map(|(document_id, content)| SearchHit {
                document_id: document_id.clone(),
                snippet: content.chars().take(120).collect(),
            })
            .collect();
        Json(SearchOutput { hits })
    }
}

impl SearchServer {
    /// Build a server over a fixed, read-only index (the bounded scope).
    pub fn new(index: Vec<(String, String)>) -> Self {
        Self { index }
    }
}

/// Clamp the requested limit to `[1, MAX_SEARCH_LIMIT]`. `0` (unset) ⇒ a small
/// default; anything over the cap is clamped (least privilege).
pub fn effective_limit(requested: u32) -> u32 {
    match requested {
        0 => 10,
        n => n.min(MAX_SEARCH_LIMIT),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn search_parameters_schema_describes_fields() {
        // The derived JSON Schema is what rmcp uses to validate tool input.
        // It must name both params so the protocol advertises a typed contract.
        let schema = schemars::schema_for!(SearchParameters);
        let json = serde_json::to_string(&schema).unwrap();
        assert!(json.contains("query"), "schema must describe `query`: {json}");
        assert!(json.contains("limit"), "schema must describe `limit`: {json}");
    }

    #[test]
    fn limit_is_clamped_to_max_for_least_privilege() {
        assert_eq!(effective_limit(0), 10);
        assert_eq!(effective_limit(5), 5);
        assert_eq!(effective_limit(1000), MAX_SEARCH_LIMIT);
    }

    #[test]
    fn search_matches_bounded_index_case_insensitively() {
        let server = SearchServer::new(vec![
            ("doc-1".into(), "The quick brown Fox".into()),
            ("doc-2".into(), "lazy dog".into()),
        ]);
        let Json(out) = server.search(Parameters(SearchParameters {
            query: "fox".into(),
            limit: 0,
        }));
        assert_eq!(out.hits.len(), 1);
        assert_eq!(out.hits[0].document_id, "doc-1");
    }

    #[test]
    fn search_respects_the_hard_cap() {
        let index: Vec<(String, String)> = (0..100)
            .map(|i| (format!("doc-{i}"), "match".to_string()))
            .collect();
        let server = SearchServer::new(index);
        let Json(out) = server.search(Parameters(SearchParameters {
            query: "match".into(),
            limit: 1000,
        }));
        assert_eq!(out.hits.len(), MAX_SEARCH_LIMIT as usize);
    }
}
