# Rust OpenTelemetry Standard

## Technology Stack

| Crate | Role |
|---|---|
| `tracing` | Structured logging and span instrumentation |
| `tracing-subscriber` | Subscriber configuration |
| `tracing-opentelemetry` | Bridge tracing spans → OTel spans |
| `opentelemetry` | OTel SDK core |
| `opentelemetry-otlp` | OTLP exporter (gRPC or HTTP) |
| `opentelemetry_sdk` | SDK implementation |
| `opentelemetry-semantic-conventions` | Standard attribute names |

---

## Setup

```rust
// src/infrastructure/telemetry/setup.rs
use opentelemetry::KeyValue;
use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::{
    runtime,
    trace::{self, Sampler},
    Resource,
};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

pub fn setup_telemetry(config: &TelemetryConfig) -> anyhow::Result<SdkTracerProvider> {
    let resource = Resource::new(vec![
        KeyValue::new("service.name", config.service_name.clone()),
        KeyValue::new("service.version", config.service_version.clone()),
        KeyValue::new("deployment.environment", config.environment.clone()),
        KeyValue::new("host.name", hostname::get()?.to_string_lossy().to_string()),
    ]);

    let exporter = opentelemetry_otlp::SpanExporter::builder()
        .with_tonic()
        .with_endpoint(&config.otlp_endpoint)
        .with_timeout(Duration::from_secs(5))
        .build()?;

    let provider = opentelemetry_sdk::trace::SdkTracerProvider::builder()
        .with_resource(resource)
        .with_batch_exporter(exporter, runtime::Tokio)
        .with_sampler(build_sampler(config.sample_rate))
        .build();

    let tracer = provider.tracer(config.service_name.clone());
    let otel_layer = tracing_opentelemetry::layer().with_tracer(tracer);

    let env_filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("info"));

    let fmt_layer = tracing_subscriber::fmt::layer()
        .json()
        .with_current_span(true)
        .with_span_list(true);

    tracing_subscriber::registry()
        .with(env_filter)
        .with(fmt_layer)
        .with(otel_layer)
        .init();

    Ok(provider)
}

fn build_sampler(sample_rate: f64) -> Sampler {
    if sample_rate >= 1.0 {
        Sampler::AlwaysOn
    } else {
        Sampler::TraceIdRatioBased(sample_rate)
    }
}

pub struct TelemetryConfig {
    pub service_name: String,
    pub service_version: String,
    pub environment: String,
    pub otlp_endpoint: String,
    pub sample_rate: f64, // 0.0–1.0; use 1.0 in dev, 0.1 in prod
}
```

---

## Graceful Shutdown

```rust
// src/infrastructure/server/grpc_server.rs
pub async fn run(config: AppConfig, token: CancellationToken) -> anyhow::Result<()> {
    let tracer_provider = setup_telemetry(&config.telemetry)?;

    // ... build and run server ...

    token.cancelled().await;

    tracing::info!("Flushing telemetry before shutdown");
    tracer_provider.shutdown()?;

    Ok(())
}
```

---

## Instrumentation with #[tracing::instrument]

```rust
// Instrument async functions automatically
#[tracing::instrument(
    skip(self, password),  // never record passwords or secrets
    fields(
        user.email = %email,
        otel.kind = "internal",
    )
)]
pub async fn sign_in(&self, email: &str, password: &str) -> anyhow::Result<User> {
    let span = tracing::Span::current();

    let user = self.user_repo.find_by_email(email).await
        .inspect_err(|e| tracing::error!(error = %e, "Repository lookup failed"))?
        .ok_or(DomainError::UserNotFound)?;

    // Record dynamic values after they are known
    span.record("user.id", user.id.to_string());
    span.record("user.role", user.role.to_string());

    Ok(user)
}
```

```rust
// Manual span for fine-grained control
pub async fn process_order(&self, order: Order) -> anyhow::Result<()> {
    let span = tracing::info_span!(
        "order.process",
        order.id = %order.id,
        order.total_cents = order.total_cents,
        otel.kind = "internal",
    );
    let _enter = span.enter();

    tracing::info!("Processing order");

    // Add events at key points
    tracing::info!(items = order.items.len(), "Reserving inventory");
    self.inventory.reserve(&order.items).await
        .inspect_err(|e| tracing::error!(error = %e, "Inventory reservation failed"))?;

    tracing::info!("Charging payment");
    self.payment.charge(order.total_cents).await
        .inspect_err(|e| tracing::error!(error = %e, "Payment charge failed"))?;

    tracing::info!("Order processed successfully");
    Ok(())
}
```

---

## Error Recording

```rust
// Record errors in spans; do not swallow them
async fn handler(&self, req: Request<Req>) -> Result<Response<Res>, Status> {
    self.service
        .do_thing(req.into_inner())
        .await
        .map(|r| Response::new(r.into()))
        .map_err(|err| {
            // Record in span
            tracing::error!(
                error.type = err.root_cause().type_id().map(|_| ""),
                error.message = %err,
                "Request failed"
            );
            map_to_status(err)
        })
}

// Use ? with context for propagation — the span captures the error automatically
// when tracing-opentelemetry is active
async fn inner(&self) -> anyhow::Result<()> {
    step_one().await.context("step one failed")?;
    step_two().await.context("step two failed")?;
    Ok(())
}
```

---

## HTTP Client Instrumentation (reqwest)

```rust
// Inject W3C traceparent header into outbound HTTP requests
use opentelemetry::propagation::TextMapPropagator;
use opentelemetry_sdk::propagation::TraceContextPropagator;
use tracing_opentelemetry::OpenTelemetrySpanExt;

pub async fn get_with_tracing(client: &reqwest::Client, url: &str) -> anyhow::Result<String> {
    let span = tracing::info_span!("http.client", http.method = "GET", http.url = url);

    // Inject context into headers
    let mut headers = reqwest::header::HeaderMap::new();
    let propagator = TraceContextPropagator::new();
    let cx = span.context();
    propagator.inject_context(&cx, &mut HeaderMapCarrier(&mut headers));

    let response = client
        .get(url)
        .headers(headers)
        .send()
        .await
        .context("HTTP GET failed")?;

    let status = response.status().as_u16();
    span.record("http.status_code", status);

    if !response.status().is_success() {
        tracing::error!(http.status_code = status, "HTTP request failed");
    }

    response.text().await.context("Reading response body")
}

struct HeaderMapCarrier<'a>(&'a mut reqwest::header::HeaderMap);

impl opentelemetry::propagation::Injector for HeaderMapCarrier<'_> {
    fn set(&mut self, key: &str, value: String) {
        if let Ok(name) = reqwest::header::HeaderName::from_bytes(key.as_bytes()) {
            if let Ok(val) = reqwest::header::HeaderValue::from_str(&value) {
                self.0.insert(name, val);
            }
        }
    }
}
```

---

## Context Propagation in gRPC

```rust
// Extract trace context from incoming gRPC metadata
use opentelemetry::propagation::TextMapPropagator;
use tonic::metadata::MetadataMap;

pub fn extract_context(metadata: &MetadataMap) -> opentelemetry::Context {
    let propagator = TraceContextPropagator::new();
    propagator.extract(&MetadataMapCarrier(metadata))
}

struct MetadataMapCarrier<'a>(&'a MetadataMap);

impl opentelemetry::propagation::Extractor for MetadataMapCarrier<'_> {
    fn get(&self, key: &str) -> Option<&str> {
        self.0.get(key).and_then(|v| v.to_str().ok())
    }

    fn keys(&self) -> Vec<&str> {
        self.0.keys().map(|k| k.as_str()).collect()
    }
}
```

---

## Standard Field Names

Use semantic convention attribute names consistently:

```rust
// Service
"service.name"          // required
"service.version"       // required
"deployment.environment" // required

// HTTP client spans
"http.method"
"http.url"
"http.status_code"
"net.peer.name"

// Database spans
"db.system"             // "postgresql", "redis"
"db.name"
"db.operation"          // "SELECT", "INSERT"
"db.statement"          // only in dev; never in prod (may contain PII)

// Messaging spans
"messaging.system"      // "kafka", "rabbitmq"
"messaging.destination"
"messaging.operation"   // "publish", "receive"

// User (safe fields only — no PII)
"user.id"               // internal ID, not email
"user.role"
```

---

## Rules

- **Graceful shutdown always calls `provider.shutdown()`**: ensures buffered spans are flushed before process exits
- **Never record PII in span attributes**: no emails, passwords, tokens, or names
- **Use `skip` in `#[instrument]` for sensitive parameters**: `skip(self, password, token)`
- **Log at the handling point only**: `tracing::error!` where you catch the error, not where you propagate with `?`
- **Sample rate is configurable per environment**: 100% in dev, 10–20% in production, 100% for errors
- **`service.name`, `service.version`, `deployment.environment` are mandatory resource attributes**
- **W3C `traceparent` header is propagated in all outbound HTTP and gRPC calls**
- **Span kind must be set**: `otel.kind = "server"` for inbound, `"client"` for outbound, `"internal"` for domain
- **Batch exporter is always used**: never use the synchronous exporter in production
