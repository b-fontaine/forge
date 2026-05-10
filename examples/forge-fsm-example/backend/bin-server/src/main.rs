//! fsm-backend bootstrap.
//!
//! <!-- Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation -->
//!
//! Per ADR-T5-OTA-004 :
//!
//! 1. `TelemetryConfig::from_env()` — read W3C OTel env vars + `DEPLOYMENT_ENV`.
//! 2. `setup_telemetry(&config)` — init the global tracer provider, register
//!    the W3C `traceparent` propagator, plumb `tracing-opentelemetry` into the
//!    `tracing` subscriber.
//! 3. (deferred) start the axum + connectrpc server with the
//!    `TraceLayer::new_for_http()` wrapping the connectrpc service via
//!    `nest_service("/connect", ...)`. The middleware composition closure
//!    [`infrastructure::telemetry::otel_make_span_with_traceparent_extraction`]
//!    extracts the inbound `traceparent` and creates a server-kind span.
//! 4. `tokio::signal::ctrl_c()` — graceful shutdown.
//! 5. `provider.shutdown()` — flush buffered spans before process exit
//!    (FR-T5-OTA-007).
//!
//! Note : steps 3 are documented as the target shape ; demo-005 currently
//! exercises the connectrpc path via the integration tests in
//! `crates/grpc-api/`. The bootstrap demonstrates SDK init + graceful
//! shutdown so adopters copy-paste a complete reference. The full server
//! wiring is left for a follow-up change (Phase C — see proposal.md scope).
//!
//! Deviation note (ADR-T5-OTA-002) : OTLP HTTP/protobuf both layers — the
//! `rust/opentelemetry.md` § Setup snippet shows `with_tonic()` (gRPC) ; this
//! example uses `.with_http().with_protocol(Protocol::HttpBinary)` for symmetry
//! with the Flutter exporter and the Phase A collector :4318 receiver.

use anyhow::Context;
use http::Request;
use infrastructure::telemetry::{
    otel_make_span_with_traceparent_extraction, setup_telemetry, TelemetryConfig,
};
use tower_http::trace::TraceLayer;
use tracing::Level;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // 1. Load env-driven config.
    let config = TelemetryConfig::from_env();

    // 2. Init OTel SDK + tracing subscriber.
    let provider = setup_telemetry(&config).context("setup_telemetry failed")?;

    tracing::info!(
        service.name = %config.service_name,
        deployment.environment = %config.environment,
        "starting fsm-backend"
    );

    // 3. Demonstrate the TraceLayer + traceparent extraction shape — the
    //    connectrpc service mount happens via nest_service("/connect", ...)
    //    in a follow-up change (Phase C scope per proposal.md). We capture
    //    the layer construction here so adopters see the pattern verbatim.
    //
    //    Middleware order (FR-T5-OTA-024) — outermost first :
    //      TraceLayer (server span + traceparent extract)
    //        → [future] auth / rate-limit
    //          → nest_service("/connect", connect_service)
    // The fn is generic over the request body `B` ; we wrap it in a closure
    // that fixes a concrete `Request<Body>` so `make_span_with`'s trait
    // bound resolves. Adopters mounting connectrpc via
    // `nest_service("/connect", ...)` keep this exact closure shape.
    let _trace_layer = TraceLayer::new_for_http()
        .make_span_with(|req: &Request<axum::body::Body>| {
            otel_make_span_with_traceparent_extraction(req)
        })
        .on_request(tower_http::trace::DefaultOnRequest::new().level(Level::INFO))
        .on_response(tower_http::trace::DefaultOnResponse::new().level(Level::INFO));

    // 4. Wait for shutdown signal — Ctrl+C in dev, SIGTERM from k8s in prod.
    tokio::signal::ctrl_c()
        .await
        .context("waiting for ctrl_c")?;

    tracing::info!("Flushing telemetry before shutdown");

    // 5. Flush buffered spans before process exit.
    provider.shutdown().context("provider.shutdown failed")?;

    Ok(())
}
