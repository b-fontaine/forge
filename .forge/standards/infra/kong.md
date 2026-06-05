# Kong API Gateway Standard — ⚠️ DEPRECATED (tombstone)

> **DEPRECATED at Constitution v2.0.0 (Amendment #2, 2026-06-05, `b8-14-promotion-flip`).**
> §VIII.1 now mandates **Envoy Gateway** (see `.forge/standards/gateway.yaml`) with
> end-to-end **Connect-RPC** (`.forge/standards/transport.yaml`) replacing the
> gateway REST↔gRPC transcoding this standard described. This file is a **tombstone**
> kept for `full-stack-monorepo` **1.0.0** adopters during the deprecation window
> (**EOL 2026-12-05**, T+6 months); it is no longer indexed in
> `.forge/standards/index.yml` and is removed after EOL. New 2.0.0 projects use
> Envoy + Connect. Migration: `docs/MIGRATIONS.md`; reversal: `docs/ROLLBACK.md`.
> The content below is **historical** (1.0.0 Kong gateway) — superseded.

## Use Cases

| Use Case | Kong Plugin / Feature |
|---|---|
| REST ↔ gRPC transcoding | `grpc-gateway` plugin + proto HTTP annotations |
| Rate limiting | `rate-limiting` plugin (per consumer, per IP) |
| JWT authentication | `jwt` plugin |
| API key authentication | `key-auth` plugin |
| Request transformation | `request-transformer` plugin |
| Response transformation | `response-transformer` plugin |
| Request size limiting | `request-size-limiting` plugin |
| CORS | `cors` plugin |
| Access logging | `file-log` or `http-log` plugin |
| Caching | `proxy-cache` plugin |

---

## Declarative Configuration (kong.yml)

All Kong configuration is managed declaratively in version control. Never configure Kong via Admin API directly in production.

```yaml
# infra/kong/kong.yml
_format_version: "3.0"
_transform: true

services:
  - name: auth-service
    url: grpc://auth-service.production.svc.cluster.local:50051
    protocol: grpc
    connect_timeout: 5000
    write_timeout: 10000
    read_timeout: 30000
    tags: [production, auth]
    routes:
      - name: auth-rest
        protocols: [http, https]
        paths: ["/v1/auth"]
        methods: [GET, POST, PUT, PATCH, DELETE]
        strip_path: false
        plugins:
          - name: grpc-gateway
            config:
              proto: /usr/local/kong/proto/api/v1/auth.proto
          - name: request-size-limiting
            config:
              allowed_payload_size: 1    # 1 MB max request body
          - name: cors
            config:
              origins: ["https://app.example.com", "https://admin.example.com"]
              methods: [GET, POST, PUT, PATCH, DELETE, OPTIONS]
              headers: [Authorization, Content-Type, X-Request-ID]
              exposed_headers: [X-Request-ID, X-RateLimit-Remaining]
              max_age: 3600
              credentials: true

  - name: users-service
    url: grpc://users-service.production.svc.cluster.local:50051
    protocol: grpc
    tags: [production, users]
    routes:
      - name: users-rest
        protocols: [http, https]
        paths: ["/v1/users"]
        plugins:
          - name: grpc-gateway
            config:
              proto: /usr/local/kong/proto/api/v1/users.proto
          - name: jwt
            config:
              secret_is_base64: false
              key_claim_name: sub
          - name: rate-limiting
            config:
              minute: 60
              hour: 1000
              policy: redis
              redis_host: redis.cache.svc.cluster.local
              redis_port: 6379
          - name: request-size-limiting
            config:
              allowed_payload_size: 5

consumers:
  - username: mobile-app
    jwt_secrets:
      - algorithm: RS256
        rsa_public_key: |
          -----BEGIN PUBLIC KEY-----
          MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
          -----END PUBLIC KEY-----

  - username: internal-service
    keyauth_credentials:
      - key: "{{ env \"INTERNAL_API_KEY\" }}"

plugins:
  # Global plugins — applied to all services
  - name: file-log
    config:
      path: /dev/stdout
      reopen: false

  - name: http-log
    config:
      http_endpoint: http://otel-collector.observability.svc.cluster.local:4318/v1/logs
      method: POST
      timeout: 1000
      keepalive: 60000
      flush_timeout: 2

  - name: prometheus
    config:
      status_code_metrics: true
      latency_metrics: true
      bandwidth_metrics: true
      upstream_health_metrics: true
```

---

## gRPC Transcoding

gRPC-gateway transcoding converts REST HTTP requests to gRPC calls using proto HTTP annotations.

### Proto Annotations

```protobuf
// proto/api/v1/users.proto
import "google/api/annotations.proto";

service UsersService {
  rpc GetUser(GetUserRequest) returns (User) {
    option (google.api.http) = {
      get: "/v1/users/{id}"
    };
  }

  rpc CreateUser(CreateUserRequest) returns (User) {
    option (google.api.http) = {
      post: "/v1/users"
      body: "*"
    };
  }

  rpc UpdateUser(UpdateUserRequest) returns (User) {
    option (google.api.http) = {
      patch: "/v1/users/{id}"
      body: "*"
    };
  }

  rpc DeleteUser(DeleteUserRequest) returns (google.protobuf.Empty) {
    option (google.api.http) = {
      delete: "/v1/users/{id}"
    };
  }

  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse) {
    option (google.api.http) = {
      get: "/v1/users"
    };
  }
}
```

### Kong Plugin Config

```yaml
plugins:
  - name: grpc-gateway
    config:
      proto: /usr/local/kong/proto/api/v1/users.proto
```

Proto files must be present in the Kong container at the configured path. Mount them via ConfigMap.

---

## Rate Limiting Configuration

```yaml
# Per-consumer rate limiting
plugins:
  - name: rate-limiting
    consumer: mobile-app
    config:
      second: 10
      minute: 100
      hour: 2000
      policy: redis
      redis_host: redis.cache.svc.cluster.local
      redis_port: 6379
      hide_client_headers: false    # expose rate limit headers to clients
      fault_tolerant: true          # if redis is down, allow traffic

# Per-IP rate limiting for unauthenticated endpoints
  - name: rate-limiting
    route: auth-rest
    config:
      minute: 10
      hour: 50
      policy: local                 # no Redis needed for low-volume endpoints
      limit_by: ip
```

---

## Request Transformation

```yaml
plugins:
  - name: request-transformer
    config:
      add:
        headers:
          - "X-Service-Version: {{ .Chart.AppVersion }}"
          - "X-Request-Source: kong"
      remove:
        headers:
          - "X-Internal-Secret"     # strip internal headers before forwarding
      rename:
        headers:
          - "X-Auth-Token:Authorization"
```

---

## Health Checks

```yaml
services:
  - name: my-service
    url: grpc://my-service.production.svc.cluster.local:50051
    healthchecks:
      active:
        type: grpcs
        grpc_service: "grpc.health.v1.Health"
        healthy:
          interval: 10
          successes: 1
        unhealthy:
          interval: 5
          http_failures: 2
          tcp_failures: 2
          timeouts: 2
      passive:
        type: grpcs
        healthy:
          successes: 5
        unhealthy:
          http_failures: 5
          tcp_failures: 5
          timeouts: 5
```

---

## Deployment via decK

```bash
# Sync config to Kong
deck sync --config infra/kong/kong.yml --select-tag production

# Validate without applying
deck validate --config infra/kong/kong.yml

# Diff against current running config
deck diff --config infra/kong/kong.yml --select-tag production

# Export current running config (for initial bootstrap)
deck dump --output-file infra/kong/kong.dump.yml
```

---

## CI/CD Integration

```yaml
# .github/workflows/kong.yml
jobs:
  validate-kong-config:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate Kong config
        run: |
          docker run --rm \
            -v $(pwd)/infra/kong:/config \
            kong/deck:latest \
            validate --config /config/kong.yml
      - name: Diff against staging
        run: |
          deck diff \
            --config infra/kong/kong.yml \
            --kong-addr https://kong-admin.staging.example.com \
            --select-tag staging

  deploy-kong-staging:
    needs: validate-kong-config
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Sync to staging
        run: |
          deck sync \
            --config infra/kong/kong.yml \
            --kong-addr https://kong-admin.staging.example.com \
            --select-tag staging
```

---

## Rules

- **All configuration in git**: never use Kong Admin API directly in production; use `deck sync` from CI
- **Health checks configured on every upstream**: both active and passive health checking enabled
- **Rate limits on all public routes**: unauthenticated routes rate-limited by IP; authenticated by consumer
- **Request size limits on all POST/PUT/PATCH routes**: default 1MB, increase only with justification
- **Access logs enabled globally**: send to OTel collector via `http-log` plugin
- **gRPC transcoding configured per route**: every gRPC service has a corresponding REST route with proto annotation
- **Proto files versioned with the config**: proto files mounted in Kong container match the services being exposed
- **Secrets are environment variables**: use `{{ env "VAR_NAME" }}` syntax; never hardcode credentials in kong.yml
- **`select-tag` per environment**: use tags (`production`, `staging`) to manage multi-environment configs in one file
