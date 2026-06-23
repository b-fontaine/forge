//! Streamable-HTTP transport (feature `mcp-http`) — serves the MCP server as an
//! axum-native `StreamableHttpService` on `/mcp` (`mcp-servers.md`).
//!
//! Authentication: the streamable-HTTP transport supports OAuth 2.1 + PKCE +
//! RFC 8707 (rmcp `auth` feature). Tokens are issued by **Zitadel**
//! (`identity.yaml`, B.8.7) and validated at the edge by the **Envoy
//! SecurityPolicy JWT** wiring (B.8.12) — the MCP server reuses the archetype's
//! identity plane; it does NOT introduce a second IdP. The JWT-validation layer
//! is attached at the Envoy edge (infra) and/or as a tower layer on this router.

use std::sync::Arc;

use axum::Router;
use rmcp::transport::streamable_http_server::session::local::LocalSessionManager;
use rmcp::transport::streamable_http_server::{StreamableHttpServerConfig, StreamableHttpService};

use crate::SearchServer;

/// The route the MCP streamable-HTTP service is mounted at.
pub const MCP_ROUTE: &str = "/mcp";

/// Build an axum [`Router`] that serves the [`SearchServer`] over streamable
/// HTTP at [`MCP_ROUTE`]. The `index` is cloned into each session's server
/// instance by the service factory (read-only, bounded scope).
///
/// The returned router is mounted on the bin-server's top-level axum app (the
/// same axum surface as the LLM gateway). Attach the OAuth 2.1 / JWT validation
/// tower layer (Zitadel/Envoy-OIDC) at the call site before serving in prod.
pub fn router(index: Vec<(String, String)>) -> Router {
    let session_manager = Arc::new(LocalSessionManager::default());
    let config = StreamableHttpServerConfig::default();

    let service = StreamableHttpService::new(
        move || Ok(SearchServer::new(index.clone())),
        session_manager,
        config,
    );

    Router::new().route_service(MCP_ROUTE, service)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_router_without_panicking() {
        // Smoke: the streamable-HTTP service mounts on axum at /mcp. Exercising
        // the feature-gated wiring keeps the http transport build-tested (L2
        // feature-matrix), not just declared.
        let _router = router(vec![("doc-1".into(), "hello".into())]);
        assert_eq!(MCP_ROUTE, "/mcp");
    }
}
