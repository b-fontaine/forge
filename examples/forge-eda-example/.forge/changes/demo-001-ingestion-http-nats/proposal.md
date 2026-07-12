# Proposal: demo-001-ingestion-http-nats

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- Layers: [backend] — single-layer demo -->

## Problem

The `forge-eda-example` project ships a scaffolded `backend/events/`
workspace, but an adopter reading the example needs a concrete
demonstration of how a **single-layer backend change** flows through the
Forge pipeline — proposal → archive — for the archetype's first
event-driven surface: **ingestion**. Without it, the `events/` modules
(`EventEnvelope`, `EventPublisher`, `JetStreamPublisher`) read as
disconnected primitives rather than a coherent, TDD-driven feature.

## Solution

Demonstrate command ingestion end-to-end: an axum HTTP endpoint accepts
a request, wraps it in an idempotent, versioned `EventEnvelope`, and
publishes it to **NATS JetStream** — the first half of the event
backbone.

1. **Envelope** — build a versioned, idempotent `EventEnvelope`
   (`backend/events/src/envelope.rs`): a fresh `id`, a business
   `idempotency_key` (e.g. `order-42`), an `event_version`, and a
   type/version-namespaced subject `events.v<version>.<event_type>`.
2. **Publish** — publish through the `EventPublisher` port
   (`backend/events/src/publisher.rs`); the `JetStreamPublisher` impl
   sets the `Nats-Msg-Id` header to the envelope's `idempotency_key` so
   the JetStream server **deduplicates** re-published events within its
   dedup window.
3. **Ingest** — the axum surface (`backend/bin-server/`) maps an
   inbound command to `EventService.Publish`
   (`shared/protos/v1/events/events.proto`), returning the assigned
   `event_id` + a `deduplicated` flag.

This is the archetype's `event-design` phase made concrete: the event
contract (AsyncAPI 3.1 in `shared/asyncapi/` + the Connect `EventService`
proto) precedes the handler, and every event carries the versioning +
idempotency metadata the archetype mandates (`event_specifics`).

This demo is **deliberately illustrative** — its purpose is to
demonstrate the full TDD + hexagonal + event-versioning discipline for
the ingestion surface, not to ship a tuned production gateway.

## Scope In

- The `events/` ingestion TDD cycle: the versioned + idempotent
  `EventEnvelope`, the type/version subject namespacing, the
  `EventPublisher` port, and the `Nats-Msg-Id` publish-dedup contract.
- cucumber-rs BDD: ingest → publish → (idempotent) re-publish is a no-op.

## Scope Out

- No live NATS server (tests use the in-memory `RecordingPublisher` port
  fake shipped in `events/src/publisher.rs`; no network).
- No consumer / projection (that is demo-002's surface).
- No saga orchestration (demo-003).
- No tuning of the JetStream stream/consumer config, dedup window, or
  retention — the sovereign defaults only; adopters tune per workload.

## Impact

- **Users affected**: adopters evaluating the ingestion surface of the
  `event-driven-eu` archetype.
- **Technical impact**: illustrative; the product code lives in the
  rendered `backend/events/` workspace with inline `#[cfg(test)]` tests.
- **Dependencies**: the rendered `event-driven-eu/1.0.0` backbone
  (`b6-2-scaffolder`) — provides the `events/` modules + the
  verify-then-pin'd crate set (`async-nats`, `serde_json`, `uuid`,
  `chrono`).
- **Risk level**: Low (illustrative, additive, no external calls).

## Constitution Compliance

- **Article I (TDD)**: `events/` modules ship RED→GREEN→REFACTOR inline
  tests (subject namespacing, idempotency-key override, serde round-trip,
  publisher port).
- **Article II (BDD)**: `features/ingestion_http_nats.feature` covers
  ingest → publish → idempotent re-publish.
- **Article III (Specs before code)**: this proposal → specs → design →
  tasks precedes the (already-scaffolded) implementation.
- **Article VII (Rust architecture)**: hexagonal; `EventPublisher` is a
  port; no `unwrap()`/`panic!()` in production paths.
- **event_specifics**: event versioning + idempotency keys
  (`Nats-Msg-Id` dedup) are the demo's core requirements.

---

**Gate**: Proposal complete. Next → `/forge:specify demo-001-ingestion-http-nats`.
