# Prometheus + Grafana Standard

## Architecture

```
Services (/metrics endpoint)
        │
    Prometheus (pull scraping every 15s)
        │
     Grafana (visualization + alerting)
        │
  AlertManager (routing → PagerDuty / Slack)
```

---

## Prometheus Setup

### Kubernetes Deployment (kube-prometheus-stack)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values infra/prometheus/values.yaml
```

```yaml
# infra/prometheus/values.yaml
prometheus:
  prometheusSpec:
    retention: 15d
    retentionSize: "50GB"
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 100Gi

    # Scrape all ServiceMonitors across namespaces
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false

grafana:
  adminPassword: "${GRAFANA_ADMIN_PASSWORD}"
  persistence:
    enabled: true
  plugins:
    - grafana-piechart-panel

alertmanager:
  config:
    global:
      slack_api_url: "${SLACK_WEBHOOK_URL}"
    route:
      receiver: slack-default
      routes:
        - match:
            severity: critical
          receiver: pagerduty-critical
    receivers:
      - name: slack-default
        slack_configs:
          - channel: '#alerts'
            title: '{{ .GroupLabels.alertname }}'
            text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
      - name: pagerduty-critical
        pagerduty_configs:
          - routing_key: "${PAGERDUTY_KEY}"
```

---

## Exposing /metrics in Rust (with metrics crate)

```rust
// Cargo.toml
[dependencies]
metrics = "0.23"
metrics-exporter-prometheus = "0.15"

// src/infrastructure/telemetry/metrics.rs
use metrics_exporter_prometheus::PrometheusBuilder;

pub fn setup_metrics(port: u16) -> anyhow::Result<()> {
    PrometheusBuilder::new()
        .with_http_listener(([0, 0, 0, 0], port))
        .install()
        .context("Installing Prometheus metrics exporter")?;

    Ok(())
}

// Instrument your code
use metrics::{counter, gauge, histogram};

// Counter: monotonically increasing value
counter!("http_server_requests_total",
    "method" => method.to_string(),
    "path" => path.to_string(),
    "status_code" => status.as_str()
).increment(1);

// Histogram: distribution of values (latency, sizes)
histogram!("http_server_request_duration_seconds",
    "method" => method.to_string(),
    "path" => sanitized_path
).record(duration.as_secs_f64());

// Gauge: current value (connections, queue depth)
gauge!("grpc_server_active_connections").set(active_connections as f64);
```

---

## Metric Naming Convention

```
# Format: <namespace>_<subsystem>_<name>_<unit>

# HTTP server
http_server_requests_total{method, path, status_code}
http_server_request_duration_seconds_bucket{method, path}
http_server_active_requests{method}
http_server_request_size_bytes_bucket{method, path}
http_server_response_size_bytes_bucket{method, path}

# gRPC server
grpc_server_requests_total{method, service, status_code}
grpc_server_request_duration_seconds_bucket{method, service}

# Database
db_query_duration_seconds_bucket{operation, table}
db_pool_connections_active
db_pool_connections_idle
db_pool_connections_max

# Cache
cache_hit_total{cache}
cache_miss_total{cache}
cache_evictions_total{cache}

# Business metrics
orders_created_total{currency}
orders_failed_total{reason}
payments_charged_cents_total{currency}
active_users
```

Rules:
- Use `_total` suffix for counters
- Use `_seconds` for time durations (not milliseconds)
- Use `_bytes` for sizes
- Use `_ratio` for rates 0–1
- Labels are low-cardinality: user IDs are never labels (use log correlation instead)

---

## ServiceMonitor (for Kubernetes scraping)

```yaml
# k8s/base/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-service
  namespace: production
  labels:
    release: kube-prometheus-stack   # must match Prometheus selector
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: my-service
  endpoints:
    - port: metrics
      interval: 15s
      path: /metrics
      scrapeTimeout: 10s
```

---

## Grafana Dashboards

### Dashboard as Code (Grafonnet)

```python
# infra/grafana/dashboards/service-health.jsonnet
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;

dashboard.new(
  'Service Health',
  uid='service-health',
  tags=['service', 'generated'],
  time_from='now-1h',
)
.addTemplate(
  grafana.template.datasource('DS_PROMETHEUS', 'prometheus', 'Prometheus')
)
.addTemplate(
  grafana.template.new(
    'service',
    '$DS_PROMETHEUS',
    'label_values(http_server_requests_total, service_name)',
    label='Service',
    multi=false,
  )
)
.addRow(
  row.new('Traffic')
  .addPanel(
    graphPanel.new('Request Rate')
    .addTarget(prometheus.target(
      'sum(rate(http_server_requests_total{service_name="$service"}[5m])) by (status_code)',
      legendFormat='{{status_code}}'
    ))
  )
  .addPanel(
    graphPanel.new('P99 Latency')
    .addTarget(prometheus.target(
      'histogram_quantile(0.99, sum(rate(http_server_request_duration_seconds_bucket{service_name="$service"}[5m])) by (le))',
      legendFormat='p99'
    ))
  )
)
```

Deploy dashboards via ConfigMap:

```yaml
# Grafana auto-loads dashboards from ConfigMaps with this label
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-health-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  service-health.json: |
    { ... dashboard JSON ... }
```

---

## Alerting Rules (PrometheusRule)

```yaml
# k8s/base/prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: my-service-alerts
  namespace: production
  labels:
    release: kube-prometheus-stack
spec:
  groups:
    - name: my-service.rules
      interval: 30s
      rules:
        # Recording rule: pre-compute error rate for dashboards
        - record: job:http_server_error_rate:ratio5m
          expr: |
            sum(rate(http_server_requests_total{status_code=~"5.."}[5m])) by (service_name)
            /
            sum(rate(http_server_requests_total[5m])) by (service_name)

        # Alert: high error rate
        - alert: HighErrorRate
          expr: job:http_server_error_rate:ratio5m > 0.05
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "High error rate in {{ $labels.service_name }}"
            description: "Error rate is {{ $value | humanizePercentage }} (threshold 5%) for {{ $labels.service_name }}"
            runbook: "https://wiki.example.com/runbooks/high-error-rate"

        # Alert: high latency
        - alert: HighP99Latency
          expr: |
            histogram_quantile(0.99,
              sum(rate(http_server_request_duration_seconds_bucket[5m])) by (le, service_name)
            ) > 2
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "High P99 latency in {{ $labels.service_name }}"
            description: "P99 latency is {{ $value | humanizeDuration }} (threshold 2s)"
            runbook: "https://wiki.example.com/runbooks/high-latency"

        # Alert: service down
        - alert: ServiceDown
          expr: absent(up{job="my-service"}) or up{job="my-service"} == 0
          for: 2m
          labels:
            severity: critical
          annotations:
            summary: "Service {{ $labels.job }} is down"
            description: "No metrics received from {{ $labels.job }} for more than 2 minutes"
            runbook: "https://wiki.example.com/runbooks/service-down"

        # Alert: pod restart storm
        - alert: PodRestartStorm
          expr: |
            rate(kube_pod_container_status_restarts_total{namespace="production"}[15m]) > 0
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "Pod {{ $labels.pod }} is restarting repeatedly"
```

---

## PromQL Reference

```promql
# Request rate per minute
rate(http_server_requests_total[5m]) * 60

# Error rate percentage
100 * rate(http_server_requests_total{status_code=~"5.."}[5m])
    / rate(http_server_requests_total[5m])

# P95 latency
histogram_quantile(0.95,
  sum(rate(http_server_request_duration_seconds_bucket[5m])) by (le)
)

# Top 5 slowest endpoints
topk(5,
  histogram_quantile(0.99,
    sum(rate(http_server_request_duration_seconds_bucket[5m])) by (le, path)
  )
)

# DB connection pool saturation
db_pool_connections_active / db_pool_connections_max

# Cache hit ratio
rate(cache_hit_total[5m])
  / (rate(cache_hit_total[5m]) + rate(cache_miss_total[5m]))
```

---

## Rules

- **Metric naming follows the standard**: `<namespace>_<subsystem>_<name>_<unit>` with `_total`, `_seconds`, `_bytes` suffixes
- **Labels are low-cardinality**: paths are sanitized (IDs replaced with `{id}`), no user IDs or emails
- **Every service has a ServiceMonitor**: scraping is configured in Kubernetes, not in prometheus.yaml
- **Every service has at minimum 3 alerts**: error rate, latency, and service-down
- **Alerts have runbook URLs**: every alert annotation includes a `runbook` link
- **Dashboards are code**: JSON/Jsonnet committed to `infra/grafana/dashboards/`, deployed via ConfigMap
- **Recording rules for expensive queries**: pre-compute complex PromQL expressions as recording rules
- **P95 and P99 are always measured**: never only average latency
- **Retention is 15 days hot**: long-term metrics stored via Prometheus remote write to Thanos or Cortex
- **Alert thresholds are documented**: every threshold has a comment explaining why it was chosen
