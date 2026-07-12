# OpenTelemetry Standard

## Three Pillars

| Pillar | Purpose | OTel Data Type |
|---|---|---|
| Traces | Distributed request flow across services | `Span`, `Trace` |
| Metrics | Aggregated numerical measurements | `Counter`, `Gauge`, `Histogram` |
| Logs | Discrete events with context | `LogRecord` |

Correlate all three using `trace_id` and `span_id` in log records, so you can jump from a metric anomaly → trace → logs.

---

## Collector Architecture

```
┌─────────────────────┐      OTLP/gRPC      ┌─────────────────────────┐
│  Flutter App        │ ──────────────────► │                         │
├─────────────────────┤                      │  OTel Collector         │
│  Rust Service       │ ──────────────────► │  (Deployment: sidecar   │
├─────────────────────┤                      │   or standalone)        │
│  Cloud Function     │ ──────────────────► │                         │
└─────────────────────┘                      └────────────┬────────────┘
                                                          │
                              ┌───────────────────────────┤
                              │                           │
                    ┌─────────▼─────────┐     ┌──────────▼──────────┐
                    │    SigNoz          │     │   Prometheus        │
                    │  (traces + logs)  │     │   (metrics)         │
                    └───────────────────┘     └─────────────────────┘
```

---

## Collector Configuration

```yaml
# infra/otel/otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
        cors:
          allowed_origins: ["https://app.example.com"]

  # Scrape Prometheus endpoints
  prometheus:
    config:
      scrape_configs:
        - job_name: 'rust-services'
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names: [production, staging]
          relabel_configs:
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
              action: keep
              regex: "true"
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port]
              action: replace
              target_label: __address__
              replacement: "${1}:${2}"

processors:
  # Prevent memory exhaustion under load
  memory_limiter:
    check_interval: 5s
    limit_percentage: 80
    spike_limit_percentage: 25

  # Batch to reduce network calls
  batch:
    timeout: 5s
    send_batch_size: 512
    send_batch_max_size: 1024

  # Add resource attributes from k8s metadata
  k8sattributes:
    extract:
      metadata:
        - k8s.namespace.name
        - k8s.deployment.name
        - k8s.pod.name
        - k8s.node.name
        - k8s.container.name

  # Sample traces to reduce volume
  probabilistic_sampler:
    sampling_percentage: 10    # 10% in production

  # Drop health check traces (high volume, low value)
  filter/health:
    traces:
      span:
        - 'attributes["http.target"] == "/healthz"'
        - 'attributes["grpc.method"] == "Check"'

  # Redact PII from attributes
  redaction:
    allow_all_keys: true
    blocked_values:
      - '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'  # email
      - '\b\d{3}-\d{2}-\d{4}\b'                                   # SSN

exporters:
  # Traces and logs to SigNoz
  otlp/signoz:
    endpoint: signoz-otel-collector.observability.svc.cluster.local:4317
    tls:
      insecure: true

  # Metrics to Prometheus
  prometheus:
    endpoint: "0.0.0.0:9090"
    namespace: app

  # Debug exporter (dev only)
  debug:
    verbosity: normal

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, k8sattributes, filter/health, redaction, batch]
      exporters: [otlp/signoz]

    metrics:
      receivers: [otlp, prometheus]
      processors: [memory_limiter, k8sattributes, batch]
      exporters: [prometheus, otlp/signoz]

    logs:
      receivers: [otlp]
      processors: [memory_limiter, k8sattributes, redaction, batch]
      exporters: [otlp/signoz]

  extensions: [health_check, pprof, zpages]
  telemetry:
    logs:
      level: info
```

---

## Resource Attributes Standard

Every service must emit these resource attributes:

| Attribute | Example | Required |
|---|---|---|
| `service.name` | `auth-service` | Yes |
| `service.version` | `1.2.3` | Yes |
| `deployment.environment` | `production` | Yes |
| `host.name` | `pod-abc123` | Auto via k8sattributes |
| `k8s.namespace.name` | `production` | Auto via k8sattributes |
| `k8s.deployment.name` | `auth-service` | Auto via k8sattributes |
| `telemetry.sdk.language` | `rust` | Auto |
| `telemetry.sdk.version` | `1.x.x` | Auto |

---

## Instrumentation Rules

### Traces

- Every inbound request (gRPC, HTTP, queue consumer) starts a root span
- Every outbound call (HTTP, gRPC, database) creates a child span
- Span names follow: `<OPERATION> <TARGET>` — e.g., `GET /v1/users/{id}`, `INSERT users`
- W3C `traceparent` header propagated in all HTTP/gRPC outbound calls
- Span kind: `SERVER` (inbound), `CLIENT` (outbound), `INTERNAL` (domain logic)

### Metrics

```
# Naming convention: <namespace>_<subsystem>_<unit>_<total|sum|bucket>
http_server_request_duration_seconds_bucket
http_server_request_total
grpc_server_requests_total
db_query_duration_seconds_bucket
cache_hit_total
cache_miss_total
```

Emit at minimum:
- Request rate (counter)
- Error rate (counter with `error=true` label)
- Latency (histogram with p50, p95, p99)
- In-flight requests (gauge)

### Logs

```json
{
  "timestamp": "2025-01-01T12:00:00.000Z",
  "level": "error",
  "message": "Payment charge failed",
  "service.name": "order-service",
  "service.version": "1.2.3",
  "trace_id": "abc123def456",
  "span_id": "789abc",
  "error.type": "CardDeclinedError",
  "error.message": "Card ending 4242 was declined",
  "order.id": "ord-123",
  "user.id": "usr-456"
}
```

---

## Context Propagation

W3C Trace Context (`traceparent` header) must be propagated:
- In all HTTP requests (header injection in client middleware)
- In all gRPC calls (metadata injection in interceptor)
- In all message queue messages (message attribute or header)
- In Cloud Functions triggered by Firestore/Storage events (available via `context.traceContext`)

---

## Sampling Strategy

| Environment | Strategy | Rate |
|---|---|---|
| Development | Always sample | 100% |
| Staging | Always sample | 100% |
| Production | Probabilistic | 10% |
| Production (errors) | Always sample errors | 100% |
| Production (slow requests) | Sample if > 1s | 100% |

Use tail-based sampling in the collector to ensure errors and slow requests are always captured even at low sampling rates.

---

## Rules

- **OTel Collector is mandatory**: apps export to collector, not directly to backend
- **Collector is the single routing point**: adding a new backend means changing collector config only
- **`memory_limiter` processor is always first**: prevents collector OOM
- **`batch` processor is always last before exporters**: reduces export frequency
- **Health check spans are filtered out**: they are high-volume and low-value
- **PII redaction is applied in the collector**: services should never emit PII, but the collector is the safety net
- **Resource attributes are set at startup, not per-span**: use SDK resource configuration
- **Correlation: logs must include `trace_id` and `span_id`**: configure logging framework to auto-inject from active span
