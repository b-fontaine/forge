# Specs: demo-001-ingestion-http-nats

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- Layers: [backend] — single-layer. FR prefix: FR-BE-* (Article IV delta). -->

This spec follows the Article IV delta convention. It ADDs the
HTTP-ingestion + NATS-publish requirements to the `forge-eda-example`
backend. The implementation lives in the rendered `backend/events/` +
`backend/bin-server/` workspace.

## ADDED Requirements

### FR-BE-001: Versioned, idempotent event envelope

- **MUST** — every domain event travels in an `EventEnvelope` carrying a
  unique `id`, a `stream_id`, an `event_type`, an `event_version`, an
  `idempotency_key`, the JSON `payload`, and an `occurred_at` timestamp
  (`backend/events/src/envelope.rs`).
- **MUST** — the `idempotency_key` defaults to the event `id` but MUST be
  overridable with a stable **business key** (e.g. `order-42`) so publish
  and store-append retries are safe (`with_idempotency_key`).
- **MUST** — the JetStream subject is namespaced by version + type:
  `events.v<event_version>.<event_type>` (so a consumer selects the right
  deserializer by `(event_type, event_version)` — event versioning).

**Implemented in:** `backend/events/src/envelope.rs`
(`EventEnvelope::new`, `with_idempotency_key`, `subject`).
**Constitution reference:** Article VII; `event-driven.md` (event
versioning + idempotency keys). **Testable:** yes — `envelope::tests::*`.

### FR-BE-002: `EventPublisher` port + JetStream `Nats-Msg-Id` dedup

- **MUST** — events are published through a provider-agnostic
  `EventPublisher` port so the request path depends on an abstraction and
  tests can use an in-memory fake.
- **MUST** — the `JetStreamPublisher` impl sets the `Nats-Msg-Id` header
  to the envelope's `idempotency_key`, so the JetStream server
  **deduplicates** a re-published event within its dedup window
  (publish-side idempotency).
- **MUST** — the publish waits on the JetStream `ack`; a failed publish
  or ack surfaces as a typed `PublishError` (no `unwrap`/`panic`).

**Implemented in:** `backend/events/src/publisher.rs`
(`EventPublisher`, `JetStreamPublisher`, `PublishError`).
**Constitution reference:** Article VII; `nats-jetstream.md`.
**Testable:** yes — `publisher::tests::publisher_port_records_published_events`.

### FR-BE-003: HTTP ingestion maps to `EventService.Publish`

- **MUST** — the axum ingestion surface accepts a command and maps it to
  the `EventService.Publish` Connect RPC
  (`shared/protos/v1/events/events.proto`): `stream_id`, `event_type`,
  `event_version`, `idempotency_key`, `payload_json` in →
  `event_id` + `deduplicated` out.
- **MUST** — a re-submitted command with the same `idempotency_key`
  returns `deduplicated = true` and MUST NOT double-publish.

**Implemented in:** `backend/bin-server/` (axum surface) + the
`EventService` proto contract.
**Constitution reference:** Article VII; `proto-contracts.md`.
**Testable:** yes — covered by `features/ingestion_http_nats.feature`.

## Acceptance Criteria (Gherkin)

### AC-BE-001: Ingest publishes a versioned event to JetStream

```gherkin
Given an ingestion command for stream "order-1" of type "OrderPlaced" version 2
When the command is ingested
Then a versioned, idempotent EventEnvelope is built
And it is published to the JetStream subject "events.v2.OrderPlaced"
And the response carries the assigned event_id
```

### AC-BE-002: Idempotent re-publish is deduplicated

```gherkin
Given a command with idempotency_key "order-42" has already been published
When the same command is submitted again
Then the Nats-Msg-Id dedup suppresses the duplicate
And the response reports deduplicated = true
```

## Scope

**In scope:** FR-BE-001..003 (the `events/` ingestion path + the
`Nats-Msg-Id` dedup contract).
**Out of scope:** projection (demo-002), saga (demo-003), JetStream
stream/consumer tuning.
