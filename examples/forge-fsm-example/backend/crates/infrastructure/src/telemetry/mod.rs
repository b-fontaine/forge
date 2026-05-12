//! Telemetry — OpenTelemetry SDK init for the fsm-backend.
//!
//! <!-- Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation -->
//!
//! Per ADR-T5-OTA-001..ADR-T5-OTA-005 :
//!
//! - `opentelemetry 0.31` family + `tracing-opentelemetry 0.32` + `tower-http 0.6 [trace]`.
//! - OTLP **HTTP/protobuf** transport (port 4318) — explicit deviation from
//!   `rust/opentelemetry.md` § Setup snippet (which uses gRPC / `with_tonic()`).
//!   The deviation is symmetric with the Flutter exporter (also HTTP/protobuf)
//!   per ADR-T5-OTA-002 ; the standard's snippet is illustrative, not a hard pin.
//! - Sampler `ParentBased(TraceIdRatioBased(rate))` per ADR-T5-OTA-003 ;
//!   default `rate = 1.0` (collector-side `probabilistic_sampler` from Phase A
//!   reduces to env-tier ratio downstream).
//! - W3C `traceparent` extraction lives in `middleware.rs` ; outbound carriers
//!   live in `propagation.rs`.
//!
//! No PII in resource or span attributes (FR-T5-OTA-010 / NFR-T5-OTA-006).

use std::time::Duration;

use anyhow::Context;
use opentelemetry::{KeyValue, trace::TracerProvider as _};
use opentelemetry_otlp::{Protocol, WithExportConfig};
use opentelemetry_sdk::{
    Resource,
    propagation::TraceContextPropagator,
    trace::{Sampler, SdkTracerProvider},
};
use tracing_subscriber::{EnvFilter, layer::SubscriberExt, util::SubscriberInitExt};

pub mod middleware;
pub mod propagation;

pub use middleware::otel_make_span_with_traceparent_extraction;
pub use propagation::{HeaderMapCarrier, MetadataMapCarrier};

/// Telemetry config — sourced from env via [`TelemetryConfig::from_env`].
///
/// Field names mirror `rust/opentelemetry.md` § Setup verbatim. The
/// `otlp_endpoint` is a base URL (no `/v1/traces` suffix) ; the suffix is
/// appended inside [`build_span_exporter`] so the same env value also drives
/// future `/v1/metrics` and `/v1/logs` paths.
#[derive(Debug, Clone)]
pub struct TelemetryConfig {
    pub service_name: String,
    pub service_version: String,
    pub environment: String,
    pub otlp_endpoint: String,
    pub sample_rate: f64,
}

impl TelemetryConfig {
    /// Read W3C-standard OTel env vars + Forge-specific `DEPLOYMENT_ENV` per
    /// ADR-T5-OTA-007.
    pub fn from_env() -> Self {
        let service_name =
            std::env::var("OTEL_SERVICE_NAME").unwrap_or_else(|_| "fsm-backend".to_string());
        let service_version =
            std::env::var("CARGO_PKG_VERSION").unwrap_or_else(|_| "0.1.0".to_string());
        let environment = std::env::var("DEPLOYMENT_ENV").unwrap_or_else(|_| "dev".to_string());
        let otlp_endpoint = std::env::var("OTEL_EXPORTER_OTLP_ENDPOINT")
            .unwrap_or_else(|_| "http://fsm-otel-collector:4318".to_string());
        let sample_rate = std::env::var("OTEL_TRACES_SAMPLER_ARG")
            .ok()
            .and_then(|s| s.parse::<f64>().ok())
            .unwrap_or(1.0);
        Self {
            service_name,
            service_version,
            environment,
            otlp_endpoint,
            sample_rate,
        }
    }
}

/// `ParentBased(TraceIdRatioBased(rate))` per ADR-T5-OTA-003.
///
/// Default `rate = 1.0` is a head-side no-op ; the Phase A collector
/// (`processors.probabilistic_sampler`) enforces the env-tier ratio downstream.
/// A future Phase D change can drop the SDK ratio without rewriting this fn.
fn build_sampler(rate: f64) -> Sampler {
    Sampler::ParentBased(Box::new(Sampler::TraceIdRatioBased(rate)))
}

/// Build the OTLP HTTP/protobuf span exporter.
///
/// Deviation from `rust/opentelemetry.md` § Setup snippet : the standard
/// shows `with_tonic()` (gRPC). ADR-T5-OTA-002 picks HTTP/protobuf both
/// layers — see module doc.
fn build_span_exporter(
    config: &TelemetryConfig,
) -> anyhow::Result<opentelemetry_otlp::SpanExporter> {
    let endpoint = format!("{}/v1/traces", config.otlp_endpoint.trim_end_matches('/'));
    opentelemetry_otlp::SpanExporter::builder()
        .with_http()
        .with_protocol(Protocol::HttpBinary)
        .with_endpoint(endpoint)
        .with_timeout(Duration::from_secs(5))
        .build()
        .context("building OTLP HTTP span exporter")
}

/// Initialise the global tracer provider + the `tracing` subscriber.
///
/// Returns the [`SdkTracerProvider`] so the caller can call `.shutdown()`
/// on graceful shutdown (FR-T5-OTA-007).
pub fn setup_telemetry(config: &TelemetryConfig) -> anyhow::Result<SdkTracerProvider> {
    let host_name = hostname::get()
        .map(|h| h.to_string_lossy().into_owned())
        .unwrap_or_else(|_| "unknown".to_string());

    // Mandatory resource attributes per FR-T5-OTA-003.
    // service.name / service.version / deployment.environment / host.name.
    let resource = Resource::builder()
        .with_attributes(vec![
            KeyValue::new("service.name", config.service_name.clone()),
            KeyValue::new("service.version", config.service_version.clone()),
            KeyValue::new("deployment.environment", config.environment.clone()),
            KeyValue::new("host.name", host_name),
        ])
        .build();

    let exporter = build_span_exporter(config)?;
    let provider = SdkTracerProvider::builder()
        .with_resource(resource)
        .with_batch_exporter(exporter)
        .with_sampler(build_sampler(config.sample_rate))
        .build();

    // Register W3C traceparent propagator globally so cross-process
    // injectors / extractors pick it up by default.
    opentelemetry::global::set_text_map_propagator(TraceContextPropagator::new());
    opentelemetry::global::set_tracer_provider(provider.clone());

    let tracer = provider.tracer(config.service_name.clone());
    let otel_layer = tracing_opentelemetry::layer().with_tracer(tracer);

    let env_filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));
    let fmt_layer = tracing_subscriber::fmt::layer()
        .json()
        .with_current_span(true)
        .with_span_list(true);

    // `try_init` so test harnesses can call setup_telemetry idempotently.
    let _ = tracing_subscriber::registry()
        .with(env_filter)
        .with(fmt_layer)
        .with(otel_layer)
        .try_init();

    Ok(provider)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn from_env_defaults_when_unset() {
        // Save+restore env so parallel tests don't pollute each other.
        // SAFETY: Rust 2024 marks env mutation as unsafe due to multi-thread
        // race risk ; this test mutates a known set of vars and restores
        // them within the same fn ; tests run with `--test-threads=1` in CI.
        let old_name = std::env::var("OTEL_SERVICE_NAME").ok();
        let old_env = std::env::var("DEPLOYMENT_ENV").ok();
        unsafe {
            std::env::remove_var("OTEL_SERVICE_NAME");
            std::env::remove_var("DEPLOYMENT_ENV");
        }

        let cfg = TelemetryConfig::from_env();
        assert_eq!(cfg.service_name, "fsm-backend");
        assert_eq!(cfg.environment, "dev");

        unsafe {
            if let Some(v) = old_name {
                std::env::set_var("OTEL_SERVICE_NAME", v);
            }
            if let Some(v) = old_env {
                std::env::set_var("DEPLOYMENT_ENV", v);
            }
        }
    }

    #[test]
    fn build_sampler_returns_parent_based_traceid_ratio() {
        // Smoke : function returns without panic for several rates.
        let _ = build_sampler(1.0);
        let _ = build_sampler(0.5);
        let _ = build_sampler(0.1);
    }
}
