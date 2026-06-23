# SigNoz Observability Standard

## Overview

SigNoz is the primary observability backend for traces and logs. It uses ClickHouse for storage and provides unified trace, log, and metric exploration.

## Architecture

```
Services (via OTel Collector)
        │
        ▼
SigNoz OTel Collector
        │
        ▼
ClickHouse (storage)
        │
        ▼
SigNoz Query Service
        │
        ▼
SigNoz Frontend (UI at :3301)
```

---

## Kubernetes Deployment

```yaml
# Use the official Helm chart
helm repo add signoz https://charts.signoz.io
helm repo update

helm install signoz signoz/signoz \
  --namespace observability \
  --create-namespace \
  --values infra/signoz/values.yaml
```

```yaml
# infra/signoz/values.yaml
clickhouse:
  persistence:
    enabled: true
    size: 100Gi
  resources:
    requests:
      cpu: "2"
      memory: "4Gi"
    limits:
      cpu: "4"
      memory: "8Gi"

queryService:
  resources:
    requests:
      cpu: "200m"
      memory: "512Mi"

frontend:
  service:
    type: ClusterIP
  ingress:
    enabled: true
    ingressClassName: kong
    hosts:
      - host: signoz.internal.example.com
        paths:
          - path: /
            pathType: Prefix
```

---

## Dashboard Patterns

### Service Health Dashboard

Create one dashboard per service with these panels:

**Row 1: Traffic**
- Request rate (RPS) — grouped by status code
- Error rate (%) — `rate(http_server_request_total{status_code=~"5.."}[5m]) / rate(http_server_request_total[5m]) * 100`
- P95 and P99 latency

**Row 2: Resources**
- CPU usage
- Memory usage
- Active connections / goroutines

**Row 3: Business Metrics**
- Service-specific: orders per minute, successful sign-ins, active users

### Query Examples (ClickHouse SQL via SigNoz)

```sql
-- Top 10 slowest endpoints in the last hour
SELECT
    name as endpoint,
    count() as call_count,
    quantile(0.95)(durationNano) / 1e6 as p95_ms,
    quantile(0.99)(durationNano) / 1e6 as p99_ms
FROM signoz_traces.distributed_signoz_index_v2
WHERE
    serviceName = 'auth-service'
    AND timestamp > now() - INTERVAL 1 HOUR
    AND statusCode != 'STATUS_CODE_ERROR'
GROUP BY endpoint
ORDER BY p95_ms DESC
LIMIT 10;

-- Error rate by service over time
SELECT
    toStartOfMinute(timestamp) as minute,
    serviceName,
    countIf(statusCode = 'STATUS_CODE_ERROR') as errors,
    count() as total,
    errors / total * 100 as error_rate
FROM signoz_traces.distributed_signoz_index_v2
WHERE timestamp > now() - INTERVAL 1 HOUR
GROUP BY minute, serviceName
ORDER BY minute DESC;

-- Trace count by status and operation
SELECT
    name,
    statusCode,
    count() as count
FROM signoz_traces.distributed_signoz_index_v2
WHERE
    serviceName = 'order-service'
    AND timestamp > now() - INTERVAL 24 HOUR
GROUP BY name, statusCode
ORDER BY count DESC;
```

---

## Alerting Rules

Configure alerts in SigNoz UI under Alerts → New Alert Rule.

### Error Rate Alert

```yaml
# Alert: High error rate
condition: >5% error rate over 5 minutes
query: |
  rate(signoz_calls_total{service_name="auth-service",status_code="STATUS_CODE_ERROR"}[5m])
  /
  rate(signoz_calls_total{service_name="auth-service"}[5m])
  * 100 > 5
severity: critical
notification_channels: [pagerduty-on-call, slack-alerts]
resolve_threshold: <1% for 5 minutes
```

### High Latency Alert

```yaml
# Alert: P99 latency exceeds threshold
condition: P99 > 2s for 5 minutes
query: |
  histogram_quantile(0.99,
    rate(signoz_latency_bucket{service_name="order-service"}[5m])
  ) > 2
severity: warning
notification_channels: [slack-alerts]
```

### Service Down Alert

```yaml
# Alert: No traces received from service
condition: No data for 5 minutes
query: |
  absent(rate(signoz_calls_total{service_name="auth-service"}[5m]))
severity: critical
notification_channels: [pagerduty-on-call]
```

---

## Log Exploration

Structured JSON logs from services are ingested via the OTel Collector log pipeline.

Useful log queries in SigNoz:

```
# All errors from a service in the last hour
service.name = "auth-service" AND severity = "ERROR"

# Logs for a specific trace
trace_id = "abc123def456"

# Slow database queries
db.system EXISTS AND db.duration_ms > 500

# Authentication failures
message CONTAINS "Invalid credentials" AND service.name = "auth-service"
```

---

## Trace Analysis

### Finding Problem Traces

1. Go to Traces → Filter by `service.name` and time range
2. Sort by `Duration (desc)` to find slowest traces
3. Filter by `Status = ERROR` to find failed requests
4. Click any trace to see the full span waterfall

### Understanding Span Waterfall

- **Gaps between spans**: network latency or CPU wait time
- **Wide spans with no children**: blocking operations (check if needs `spawn_blocking`)
- **Many repeated children**: N+1 query pattern
- **Long database spans**: add index or optimize query

---

## Service Map

SigNoz automatically generates a service map from trace data. Use it to:
- Verify all expected service dependencies are present
- Identify unexpected connections (security concern)
- Find services with high error rates at a glance

---

## Rules

- **Every service emits traces to the SigNoz OTel Collector**: no direct SDK-to-ClickHouse connections
- **Service health dashboard is created before launch**: not after an incident
- **At minimum three alerts per service**: error rate, latency, and service-down
- **Alerts are tested before production**: use the SigNoz alert test feature or trigger a deliberate error
- **Log retention**: keep 30 days hot in ClickHouse, archive to S3 for 90 days
- **Trace retention**: 7 days hot, 30 days archive
- **Dashboard as code**: export SigNoz dashboards as JSON and commit to `infra/signoz/dashboards/`
- **Access control**: SigNoz is on an internal-only ingress; never exposed to the public internet
- **ClickHouse backup**: enable automated backups to S3, test restore quarterly
