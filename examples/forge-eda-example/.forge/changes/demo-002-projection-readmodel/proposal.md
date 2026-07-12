# Proposal: demo-002-projection-readmodel

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- Layers: [backend] — single-layer demo -->

## Problem

demo-001 showed the *write* half of the event backbone (ingestion →
NATS JetStream). The *read* half — turning the persisted event stream
into a query-optimised **read model** — is the archetype's second
event-driven surface, and it too needs a concrete, TDD-driven
demonstration. Without it, the `eventstore/` modules (`EventStore`,
`PgEventStore`, `InMemoryEventStore`, `Projection`) and the consumer-side
`InboxDedup` read as disconnected primitives.

## Solution

Demonstrate the CQRS read side end-to-end: append events to the Postgres
append-only event store, then **fold** the persisted stream into a
read-model projection — deterministically and replayably, guarded by the
inbox dedup so a redelivered event is handled exactly once.

1. **Append-only store** — persist events via the `EventStore` port
   (`backend/eventstore/src/store.rs`), idempotent on
   `idempotency_key` (`ON CONFLICT DO NOTHING` in Postgres; the
   `InMemoryEventStore` mirror for tests/local-dev), each assigned a
   monotonic global `seq`.
2. **Projection** — fold the read stream into a view via the
   `Projection` trait (`backend/eventstore/src/projection.rs`):
   `apply(&event)` per event, `view()` to read. Projections MUST be
   **deterministic and idempotent** — folding the same log twice yields
   the same view, so a projection can be **rebuilt** from the store at
   any time.
3. **Inbox dedup** — the consumer-side `InboxDedup`
   (`backend/events/src/consumer.rs`) records processed
   `idempotency_key`s so a redelivered event (NATS at-least-once) is
   folded **exactly once** — the inbox half of the outbox/inbox pattern.

This is the archetype's projection + outbox/inbox discipline made
concrete: the read model is a pure function of the event log, and the
consumer is idempotent under redelivery.

This demo is **deliberately illustrative** — a `CountByType`-style
projection over an in-memory fixture; not a tuned production materialiser.

## Scope In

- The `eventstore/` read path: the `EventStore` port (append idempotent
  on `idempotency_key`, `read_stream` in `seq` order), the `Projection`
  trait, and the deterministic-replay property.
- The consumer `InboxDedup` guard (outbox/inbox pattern): first delivery
  processes, duplicate skips.
- cucumber-rs BDD: append → project → read model, then replay yields the
  same view and a redelivery is deduplicated.

## Scope Out

- No live Postgres (tests use `InMemoryEventStore`; the `PgEventStore`
  SQL DDL ships in `infra/postgres/init-eventstore.sql` but is not run in
  tests — no database).
- No ingestion (demo-001) and no saga (demo-003).
- No projection-store persistence tuning (the demo folds into an
  in-memory view; adopters persist the materialised view per workload).

## Impact

- **Users affected**: adopters evaluating the read / projection surface
  of the `event-driven-eu` archetype.
- **Technical impact**: illustrative; the product code lives in the
  rendered `backend/eventstore/` + `backend/events/` workspace with
  inline `#[cfg(test)]` tests.
- **Dependencies**: `demo-001-ingestion-http-nats` (the events it folds);
  the rendered backbone (`b6-2-scaffolder`) — `eventstore/` + `events/`
  modules + the verify-then-pin'd crate set (`sqlx`, `serde_json`).
- **Risk level**: Low (illustrative, additive, no external calls).

## Constitution Compliance

- **Article I (TDD)**: `eventstore/` + `events/` ship RED→GREEN→REFACTOR
  inline tests (append-then-read order, idempotent append, projection
  fold, inbox first/duplicate).
- **Article II (BDD)**: `features/projection_readmodel.feature` covers
  append → project → replay + inbox dedup.
- **Article III (Specs before code)**: this proposal → specs → design →
  tasks precedes the (already-scaffolded) implementation.
- **Article VII (Rust architecture)**: hexagonal; `EventStore` /
  `Projection` are ports; domain free of `sqlx`; no `unwrap()`/`panic!()`
  in production paths.
- **event_specifics**: outbox/inbox pattern (inbox dedup) + deterministic
  projection replay are the demo's core requirements.

---

**Gate**: Proposal complete. Next → `/forge:specify demo-002-projection-readmodel`.
