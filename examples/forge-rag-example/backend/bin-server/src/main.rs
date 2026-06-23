//! `bin-server` — top-level entrypoint for the ai-native-rag backend.
//!
//! Wires the three net-new layers onto one axum surface:
//!   - the **LLM gateway** proxy (`llm_gateway::handler::router`) — the
//!     OpenAI-compatible front for all model traffic (audit/budget/fallback);
//!   - the **MCP** server (`mcp`) — tools over stdio (default) or, with
//!     `--features mcp-http`, the streamable-HTTP transport on the same router.
//!
//! Substrate consumed **by reference** from the full-stack 2.0.0 stack (memo §3),
//! NOT re-invented here (FR-B7-2-011):
//!   - **Connect-RPC transport** — the `grpc-api` crate's `transport_connect`
//!     adapter (nested under `/connect`); the RAG `rag.v1.RagService` handler is
//!     registered there once codegen runs (`task proto`).
//!   - **Temporal** workers (B8O) run the `rag` activity-only tasks
//!     (`rag::worker`); the worker runtime is the substrate's, not redeclared.
//!   - **Zitadel** OIDC (B.8.7) + **Envoy SecurityPolicy JWT** (B.8.12) validate
//!     tokens at the edge; the MCP HTTP transport reuses this identity plane.
//!   - **OTel** app SDK (`t5-otel-app`) — swap the `TraceLayer` below for the
//!     OTel-specific layer to get W3C `traceparent` propagation.
//!
//! No business logic lives here (Article VII.3 — bin-server is DI wiring only).

use std::net::SocketAddr;

use axum::Router;
use tower_http::trace::TraceLayer;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // ── Tracing init (prompt-audit spans land here; see llm_gateway::audit) ──
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    // ── Compose the axum surface ─────────────────────────────────────────
    // The gateway exposes the OpenAI-compatible proxy; mount additional
    // substrate routes (Connect under /connect) at the adopter's wiring step.
    // `mut` is only used when the `mcp-http` feature mounts the MCP router below.
    #[allow(unused_mut)]
    let mut app: Router = Router::new().merge(llm_gateway::handler::router());

    // MCP streamable-HTTP transport (feature-gated). Default builds ship the
    // stdio transport (launched as a subprocess by a local MCP host); the HTTP
    // transport mounts on this same axum router for web/cloud deployments.
    #[cfg(feature = "mcp-http")]
    {
        let seed_index = vec![(
            "welcome".to_string(),
            "Replace this bounded index with your real document store.".to_string(),
        )];
        app = app.merge(mcp::transport::http::router(seed_index));
    }

    let app = app.layer(TraceLayer::new_for_http());

    let addr: SocketAddr = "0.0.0.0:8088".parse()?;
    let listener = tokio::net::TcpListener::bind(addr).await?;
    tracing::info!(target: "bin_server", %addr, "ai-native-rag backend listening");
    axum::serve(listener, app.into_make_service()).await?;
    Ok(())
}
