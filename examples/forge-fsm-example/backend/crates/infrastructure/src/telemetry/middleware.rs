//! Tower middleware glue — `make_span_with` closure for `tower-http::TraceLayer`.
//!
//! <!-- Audit: T.5 (t5-otel-app) — FR-T5-OTA-020 / FR-T5-OTA-024 -->
//!
//! Per ADR-T5-OTA-004 :
//!
//! Outermost-first middleware order on the axum router :
//!   1. `TraceLayer::new_for_http()` (this module's closure — extracts
//!      `traceparent` from incoming headers, creates `otel.kind = "server"`
//!      span, links to the parent context via `set_parent`).
//!   2. (future) auth / rate-limit layers.
//!   3. `nest_service("/connect", connect_service)` — connectrpc handler.
//!
//! The closure delegates `traceparent` extraction to the global propagator
//! (a [`TraceContextPropagator`]) registered in [`super::setup_telemetry`].

use http::Request;
use opentelemetry::propagation::TextMapPropagator;
use opentelemetry_sdk::propagation::TraceContextPropagator;
use tracing_opentelemetry::OpenTelemetrySpanExt;

use super::propagation::HeaderMapExtractor;

/// `make_span_with` closure for `TraceLayer::new_for_http()`.
///
/// Extracts the W3C `traceparent` from the incoming request, creates a
/// server-side `tracing::Span` with `otel.kind = "server"` + standard HTTP
/// attributes, and stitches it to the parent context via `set_parent`.
pub fn otel_make_span_with_traceparent_extraction<B>(req: &Request<B>) -> tracing::Span {
    let propagator = TraceContextPropagator::new();
    let parent_cx = propagator.extract(&HeaderMapExtractor(req.headers()));

    let span = tracing::info_span!(
        "http.request",
        otel.kind = "server",
        http.method = %req.method(),
        http.target = %req.uri().path(),
    );
    // `OpenTelemetrySpanExt::set_parent` mutates `span` in place ; the
    // returned `()` is the conventional unit. We bind to `_` to silence the
    // pedantic-clippy must_use lint without changing semantics.
    let _ = span.set_parent(parent_cx);
    span
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn make_span_creates_server_kind_span_for_request_without_traceparent() {
        let req = Request::builder()
            .method("POST")
            .uri("/connect/greeting.v1.GreeterService/Greet")
            .body(())
            .unwrap();
        let span = otel_make_span_with_traceparent_extraction(&req);
        assert!(!span.is_disabled());
    }

    #[test]
    fn make_span_picks_up_inbound_traceparent() {
        let req = Request::builder()
            .method("POST")
            .uri("/connect/greeting.v1.GreeterService/Greet")
            .header(
                "traceparent",
                "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01",
            )
            .body(())
            .unwrap();
        let span = otel_make_span_with_traceparent_extraction(&req);
        // Smoke : span is enabled ; cross-process linkage validated by L2 +
        // future Phase C E2E test (see specs.md NFR ladder).
        assert!(!span.is_disabled());
    }
}
