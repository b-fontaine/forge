# Standard — Local Observability (OTel + SigNoz)

<!-- Audit: B.1.14 (b1-delivery, FR-IN-012) -->
<!-- Scope: infra | Priority: high -->
<!-- Triggers: observability, otel, opentelemetry, signoz, traces, metrics, logs, otlp, collector, clickhouse -->

> Authoritative reference for the local observability stack wired
> into `docker-compose.dev.yml`. This file is the **single source
> of truth** for the pinned image versions ; the compose template
> references the version table below, never vice versa.

## Local OTel + SigNoz topology

Four services, one network (`fsm-dev`), one named volume :

```
[ fsm-backend ] ──OTLP/gRPC :4317───┐
                                    ├──→ [ fsm-otel-collector ] ──→ [ fsm-signoz-query ] ──→ [ fsm-signoz-clickhouse ]
[ fsm-frontend ] ──OTLP/HTTP :4318──┘                                       ↑                          (signoz-clickhouse-data)
                                                                            │
                                                              [ fsm-signoz-frontend ] ←── browser :3301
```

**Single-instance collector** (ADR-006) — no agent/gateway split.
For local dev this keeps the mental model small. Production
parity is logical (same receivers + processors + exporters config
shape), not topological — see § Migration to production
observability for the contrast.

| Container               | Image                                        | Pinned version (single source of truth) |
|-------------------------|----------------------------------------------|------------------------------------------|
| fsm-otel-collector      | otel/opentelemetry-collector-contrib         | **0.96.0**                               |
| fsm-signoz-clickhouse   | clickhouse/clickhouse-server                 | **24.1.2-alpine**                        |
| fsm-signoz-query        | signoz/query-service                         | **0.55.1**                               |
| fsm-signoz-frontend     | signoz/frontend                              | **0.55.1**                               |

Bumping any of these versions is a Forge change. The compose
template's `image:` lines are authored from this table — when the
table moves, the compose moves with it.

## App-side OTLP configuration

Both apps consume the collector via env vars shipped in
`.env.dev` (FR-IN-009). Per-layer protocol differs because the
official Dart OTel SDK does not yet support OTLP/gRPC :

| Layer    | Endpoint                            | Protocol         | Service name                  |
|----------|-------------------------------------|------------------|-------------------------------|
| backend  | `http://otel-collector:4317`        | `grpc`           | `<project-name>-backend`      |
| frontend | `http://otel-collector:4318`        | `http/protobuf`  | `<project-name>-frontend`     |

Common env vars (both layers) :

```
OTEL_EXPORTER_OTLP_ENDPOINT=...
OTEL_EXPORTER_OTLP_PROTOCOL=...
OTEL_SERVICE_NAME=...
OTEL_TRACES_EXPORTER=otlp
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
OTEL_RESOURCE_ATTRIBUTES=service.namespace=<project-name>,deployment.environment=dev
```

Three signals MUST be configured (Article IX). Disabling any
exporter without a Forge change is a violation.

## Versioning policy

Image pins follow this protocol :

1. **Bumps go through a change cycle.** A maintainer opens a
   `<project>-otel-bump` (or similar) Forge change with the
   rationale, runs the integration workflow against the new
   versions, archives the change, and only then updates the
   table above and the compose template.
2. **Pin to specific versions, never floating tags.** `:latest`,
   `:0`, and `:0.96` are all forbidden ; only fully-qualified
   versions like `0.96.0` are allowed.
3. **Re-tag drift is acknowledged.** Registries can re-tag the
   same `0.96.0` to a different digest. Mitigation : the
   integration workflow logs the resolved digest in the cache
   step ; if the digest changes unexpectedly, the change is
   visible in CI logs.

## Trace sampling defaults

Local dev runs with **no head sampling** — every span is exported.
This is acceptable because :
- Local traffic is human-scale (developer-driven).
- Memory limits in the collector config (`memory_limiter` 256
  MiB cap, 64 MiB spike) prevent accidental floods.

Production observability (out of scope here) MUST add **tail
sampling** in the collector to keep retention costs sane — see
§ Migration to production observability.

## Migration to production observability

This stack is **explicitly local-dev only**. Migration to a
production-grade observability backend is out of scope for B.1
and follows a separate runbook :

1. **Replace the local collector** with a managed sidecar (or
   gateway) — same `receivers + processors + exporters` config
   shape, different deployment topology. Keep the `otlp` exporter
   pointed at the managed query backend (Grafana Cloud, Tempo,
   Datadog, NewRelic, etc.) instead of `fsm-signoz-query`.
2. **Add `tailsampling` processor** to the production collector
   config to retain only error traces + a 1-5% probabilistic
   sample of successful traces. Reduces retention cost by 1-2
   orders of magnitude.
3. **Enable auth on SigNoz** if the team chooses to run it
   self-hosted in prod (the local config has `auth.enabled: false`
   — flipping this flag is the FIRST step on any non-dev
   deployment, see `standards/infra/k8s-overlays.md` § Secret
   management).
4. **Apply retention policy** at the storage layer. Production
   defaults : 30d traces, 90d metrics, 30d logs (vs the dev
   defaults of 7/30/7 declared in `signoz-config.yaml.tmpl`).
5. **Wire alerts**. The collector itself does not alert ; the
   query backend does. Alert rules live outside Forge's scope
   for v1.0.0.

The local stack and the production stack share **the same OTLP
contract** — apps configured for `task dev` will export to a
production collector with no code changes, just an
`OTEL_EXPORTER_OTLP_ENDPOINT` swap. This is the migration
guarantee Forge ships.

## Startup Baselines

<!-- Added by c1-reference-project (2026-04-30) — measured against
     examples/forge-fsm-example/. Authoritative ledger for the
     NFR-015 threshold declared in
     .forge/specs/full-stack-monorepo.md. -->

NFR-015 caps the time `docker compose -f docker-compose.dev.yml
up -d --wait` takes to bring the four observability services
(`fsm-otel-collector`, `fsm-signoz-clickhouse`,
`fsm-signoz-query`, `fsm-signoz-frontend`) to a healthy state at
**90 seconds** on a developer-class machine (8 CPU cores, 16 GB
RAM, SSD).

| NFR | Threshold | Baseline | Measured on | Hardware | Notes |
|---|---|---|---|---|---|
| NFR-015 | 90 s | TBD | first contributor `task dev:up` after c1 merges | record CPU + RAM + SSD model | bound by ClickHouse boot + SigNoz initial migrations |

When a contributor records the baseline, append the date and the
exact host hardware (CPU model, RAM, SSD type). Re-measure on
every minor bump of any pinned image version listed in the
"Versioning policy" section above.
