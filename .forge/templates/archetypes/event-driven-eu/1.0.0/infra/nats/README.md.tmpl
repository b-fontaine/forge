# NATS JetStream (dev)

Minimal single-node JetStream for local development, driven by `jetstream.conf`
and started by `docker-compose.dev.yml` (`task dev:up`).

- **Client**: `nats://localhost:${ARG_NATS_PORT:-4222}`
- **Monitoring**: http://localhost:8222 (`/healthz`, `/jsz`)

The backend publishes events with a `Nats-Msg-Id` header equal to the event
idempotency key, so JetStream deduplicates re-publishes within its dedup window
(see `backend/events/src/publisher.rs`).

> Production clustering (RAFT, 3-node, persistence, consumer groups) is governed by
> `infra/nats-jetstream.md` (B.6.3) and shipped as a Helm chart in B.6.6 — NOT this
> dev overlay. No Kafka SaaS US (Confluent Cloud) per the EU-sovereignty rule
> (`event_specifics.eu_sovereignty`; Redpanda is an acceptable alternative — B.6.10).
