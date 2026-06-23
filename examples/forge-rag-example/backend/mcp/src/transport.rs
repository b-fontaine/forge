//! MCP transports, feature-gated (ADR-B7-2-005). The tools are defined once in
//! the crate root; each transport serves the same [`crate::SearchServer`].
//!
//!   - `mcp-stdio` (default) → [`stdio`] — local-dev hosts (desktop AI clients).
//!   - `mcp-http` → [`http`] — `StreamableHttpService` for web/cloud, OAuth 2.1.

#[cfg(feature = "mcp-stdio")]
pub mod stdio;

#[cfg(feature = "mcp-http")]
pub mod http;
