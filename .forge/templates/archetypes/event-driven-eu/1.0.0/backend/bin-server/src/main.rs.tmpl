//! `bin-server` — the event-driven-eu backend entrypoint (DI wiring only).
//!
//! Composes the axum HTTP surface and documents the wiring seams for the three
//! net-new layers (see [`wiring`]):
//!
//! - `events` — NATS JetStream publisher/consumer (`async_nats::connect` →
//!   `jetstream::new` → inject a `JetStreamPublisher`);
//! - `eventstore` — Postgres append-only store (`PgEventStore` from a
//!   `sqlx::PgPool`; `InMemoryEventStore` for local dev);
//! - `saga` — Temporal ACTIVITY-ONLY workers (register
//!   `saga::registered_activity_names` on the B8O substrate worker; enable the
//!   `temporal-sdk` feature to pull the SDK).
//!
//! The Connect-RPC gRPC surface is generated from `shared/protos/` by `buf generate`
//! (transport.yaml, derived_outputs incl. asyncapi-3.1) and mounted under `/connect`
//! at the adopter's codegen step — consumed by reference, not wired here.

mod wiring;

use axum::routing::get;
use axum::Router;
use std::net::SocketAddr;
use tower_http::trace::TraceLayer;

/// Liveness probe.
async fn health() -> &'static str {
    "ok"
}

/// Build the axum application router (kept separate from `main` so it is testable).
fn app() -> Router {
    Router::new()
        .route("/health", get(health))
        .layer(TraceLayer::new_for_http())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();

    // Build local-dev dependencies (swap for Postgres + NATS in production; see
    // wiring.rs) and run a startup self-check that exercises the event-store port.
    let backend = wiring::Backend::local();
    let wired_events = wiring::smoke_roundtrip(&backend).await?;
    tracing::info!(
        target: "bin_server",
        activities = ?backend.saga_activities,
        wired_events,
        "event-driven-eu backend wired (activity-only saga registry; event-store self-check ok)"
    );

    let addr: SocketAddr = "0.0.0.0:8080".parse()?;
    let listener = tokio::net::TcpListener::bind(addr).await?;
    tracing::info!(target: "bin_server", %addr, "event-driven-eu backend listening");
    axum::serve(listener, app().into_make_service()).await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn health_returns_ok() {
        assert_eq!(health().await, "ok");
    }

    #[test]
    fn app_builds() {
        let _app = app();
    }
}
