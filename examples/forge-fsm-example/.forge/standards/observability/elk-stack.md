# ELK Stack Standard

## Components

| Component | Role |
|---|---|
| Elasticsearch | Storage, full-text search, aggregations |
| Filebeat | Lightweight log shipper (reads from files/containers) |
| Logstash | Log transformation pipeline (optional — use Filebeat processors when possible) |
| Kibana | Visualization, dashboards, alerts |
| Elastic APM | Application performance monitoring |

---

## Architecture

```
Services (stdout JSON logs)
        │
    Filebeat (DaemonSet)
        │
   [Logstash pipeline]   ← optional, for complex transforms
        │
  Elasticsearch cluster
        │
     Kibana UI
```

For simple log shipping, skip Logstash and use Filebeat processors directly.

---

## Structured JSON Log Format

Every service must emit logs in this JSON format. Configure your logging framework to output JSON, never plaintext.

```json
{
  "@timestamp": "2025-01-01T12:00:00.000Z",
  "log.level": "error",
  "message": "Payment charge failed for order ord-123",
  "service.name": "order-service",
  "service.version": "1.2.3",
  "deployment.environment": "production",
  "trace.id": "abc123def456789012345678",
  "span.id": "789abc012345",
  "error.type": "CardDeclinedError",
  "error.message": "Card ending 4242 was declined by issuer",
  "error.stack_trace": "at payment::charge (payment.rs:42)\n...",
  "order.id": "ord-123",
  "user.id": "usr-456",
  "http.method": "POST",
  "http.status_code": 402,
  "duration_ms": 823
}
```

### Rust (tracing-subscriber JSON)

```rust
// src/infrastructure/telemetry/setup.rs
tracing_subscriber::fmt()
    .json()
    .with_current_span(true)
    .with_span_list(false)
    .with_target(true)
    .with_level(true)
    .with_thread_ids(false)
    .init();
```

### Dart/Flutter (structured_logger)

```dart
Logger.root.onRecord.listen((record) {
  final log = {
    '@timestamp': record.time.toIso8601String(),
    'log.level': record.level.name,
    'message': record.message,
    'service.name': 'my-flutter-app',
    'service.version': appVersion,
  };
  if (record.error != null) {
    log['error.message'] = record.error.toString();
    log['error.stack_trace'] = record.stackTrace?.toString() ?? '';
  }
  print(jsonEncode(log));
});
```

---

## Filebeat Configuration

```yaml
# infra/elk/filebeat.yaml
apiVersion: beat.k8s.elastic.co/v1beta1
kind: Beat
metadata:
  name: filebeat
  namespace: observability
spec:
  type: filebeat
  version: 8.16.0
  elasticsearchRef:
    name: elasticsearch

  daemonSet:
    podTemplate:
      spec:
        tolerations:
          - effect: NoSchedule
            operator: Exists
        containers:
          - name: filebeat
            resources:
              requests:
                cpu: "100m"
                memory: "200Mi"
              limits:
                cpu: "500m"
                memory: "500Mi"

  config:
    filebeat.autodiscover:
      providers:
        - type: kubernetes
          node: ${NODE_NAME}
          hints.enabled: true
          hints.default_config:
            type: container
            paths:
              - /var/log/containers/*${data.kubernetes.container.id}.log

    processors:
      # Parse JSON logs
      - decode_json_fields:
          fields: ["message"]
          target: ""
          overwrite_keys: true

      # Add Kubernetes metadata
      - add_kubernetes_metadata:
          host: ${NODE_NAME}
          matchers:
            - logs_path:
                logs_path: "/var/log/containers/"

      # Drop health check logs
      - drop_event:
          when:
            or:
              - contains:
                  message: "/healthz"
              - equals:
                  log.level: "debug"

    output.elasticsearch:
      index: "logs-%{[service.name]}-%{+yyyy.MM.dd}"
```

---

## Index Lifecycle Management (ILM)

```json
// PUT _ilm/policy/logs-policy
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "1d"
          },
          "set_priority": { "priority": 100 }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "shrink": { "number_of_shards": 1 },
          "forcemerge": { "max_num_segments": 1 },
          "set_priority": { "priority": 50 }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "freeze": {},
          "set_priority": { "priority": 0 }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

---

## Index Template

```json
// PUT _index_template/logs-template
{
  "index_patterns": ["logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1,
      "index.lifecycle.name": "logs-policy",
      "index.lifecycle.rollover_alias": "logs"
    },
    "mappings": {
      "dynamic": "false",
      "properties": {
        "@timestamp": { "type": "date" },
        "log.level": { "type": "keyword" },
        "message": { "type": "text" },
        "service.name": { "type": "keyword" },
        "service.version": { "type": "keyword" },
        "deployment.environment": { "type": "keyword" },
        "trace.id": { "type": "keyword" },
        "span.id": { "type": "keyword" },
        "error.type": { "type": "keyword" },
        "error.message": { "type": "text" },
        "duration_ms": { "type": "long" },
        "http.status_code": { "type": "short" }
      }
    }
  }
}
```

---

## Elastic APM Integration

```yaml
# For services that can't use OTel — use Elastic APM agent
# Prefer OTel for new services; use APM for legacy services only

# apm-server configuration
apm-server:
  host: "0.0.0.0:8200"
  rum:
    enabled: true
    allowed_origins: ["https://app.example.com"]
  auth:
    secret_token: "${APM_SECRET_TOKEN}"

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
```

---

## Kibana Dashboards

### Standard Queries

```
# All errors in the last 15 minutes
log.level: "error" AND @timestamp > now-15m

# Logs for a specific trace
trace.id: "abc123def456"

# Slow operations
duration_ms > 1000

# Specific service errors
service.name: "order-service" AND log.level: ("error" OR "critical")

# HTTP 5xx errors
http.status_code >= 500
```

### Saved Searches

Create these saved searches in Kibana for each service:
1. `<service>-errors`: `service.name: "<service>" AND log.level: "error"`
2. `<service>-slow`: `service.name: "<service>" AND duration_ms > 1000`
3. `<service>-all`: `service.name: "<service>"`

---

## Kibana Alerting

```json
// POST /api/alerting/rule
{
  "name": "High error rate in order-service",
  "rule_type_id": "es_query",
  "schedule": { "interval": "1m" },
  "params": {
    "index": ["logs-order-service-*"],
    "timeField": "@timestamp",
    "esQuery": {
      "query": {
        "bool": {
          "must": [
            { "term": { "log.level": "error" } },
            { "range": { "@timestamp": { "gte": "now-5m" } } }
          ]
        }
      }
    },
    "threshold": [100],
    "thresholdComparator": ">"
  },
  "actions": [{
    "id": "slack-connector-id",
    "group": "threshold met",
    "params": {
      "message": "High error rate in order-service: {{context.value}} errors in last 5m"
    }
  }]
}
```

---

## Rules

- **JSON log format is mandatory**: no plaintext logs; configure tracing-subscriber/logger to emit JSON
- **`@timestamp` in ISO 8601 format**: Elasticsearch auto-parses this as a date field
- **`trace.id` and `span.id` in every log record**: enables correlation with APM/SigNoz traces
- **ILM policy on every index**: hot (1 day) → warm (7 days) → cold (30 days) → delete (90 days)
- **Dynamic mapping disabled**: use explicit mappings via index template to control field types
- **Health check logs filtered at Filebeat**: do not ship them to Elasticsearch
- **Debug logs never shipped to Elasticsearch in production**: filter at Filebeat processor level
- **No sensitive data in log messages**: no passwords, tokens, PII; log `user.id` (internal), never `email`
- **Index per service per day**: `logs-<service>-yyyy.MM.dd` — enables per-service retention policies
