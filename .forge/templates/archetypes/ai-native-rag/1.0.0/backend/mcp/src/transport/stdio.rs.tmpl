//! stdio transport (feature `mcp-stdio`, default) — serves the MCP server over
//! stdin/stdout for local-dev hosts (desktop AI clients) per `mcp-servers.md`.
//!
//! Uses rmcp's `transport-io` feature (the `(Stdin, Stdout)` pair implements
//! `IntoTransport`). `serve` returns a running service whose `waiting()` future
//! resolves when the peer disconnects.

use rmcp::transport::io::stdio;
use rmcp::ServiceExt;

use crate::SearchServer;

/// Serve the [`SearchServer`] over stdio until the peer disconnects. Wire this
/// from a `bin` target (or the bin-server) when the local-dev MCP host launches
/// the process. The server's read-only index is supplied by the caller.
pub async fn serve(server: SearchServer) -> anyhow::Result<()> {
    let running = server.serve(stdio()).await?;
    running.waiting().await?;
    Ok(())
}
