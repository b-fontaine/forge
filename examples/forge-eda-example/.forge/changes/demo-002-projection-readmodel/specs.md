# Specs: demo-002-projection-readmodel

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- Layers: [backend] — single-layer. FR prefix: FR-BE-* (Article IV delta). -->

This spec follows the Article IV delta convention. It ADDs the
event-store + read-model-projection requirements to the
`forge-eda-example` backend. The implementation lives in the rendered
`backend/eventstore/` + `backend/events/` workspace.

## ADDED Requirements

### FR-BE-001: Append-only event store, idempotent on `idempotency_key`

- **MUST** — events are appended through an `EventStore` port
  (`backend/eventstore/src/store.rs`); the append is **idempotent** on
  `idempotency_key` (a retried append is a no-op — `ON CONFLICT
  (idempotency_key) DO NOTHING` in `PgEventStore`; the same guard in the
  `InMemoryEventStore` mirror).
- **MUST** — each appended event is assigned a monotonic global `seq`;
  `read_stream(stream_id)` returns the stream's events in ascending `seq`
  order.
- **MUST** — the domain stays free of `sqlx` — the store is addressed
  only through the port (Article VII domain purity).

**Implemented in:** `backend/eventstore/src/store.rs`
(`EventStore`, `PgEventStore`, `InMemoryEventStore`, `StoredEvent`).
**Constitution reference:** Article VII; `event-driven.md`.
**Testable:** yes — `store::tests::append_then_read_preserves_order`,
`append_is_idempotent_on_idempotency_key`.

### FR-BE-002: Deterministic, replayable read-model projection

- **MUST** — a read model is built by a `Projection`
  (`backend/eventstore/src/projection.rs`): `apply(&mut self, &event)`
  folds one event, `view()` borrows the current view.
- **MUST** — projections are **deterministic and idempotent
  (replayable)**: folding the same event log twice yields the same view,
  so the read model can be **rebuilt** from the event store at any time.

**Implemented in:** `backend/eventstore/src/projection.rs`
(`Projection` trait).
**Constitution reference:** Article VII; `event-driven.md` (projection
rebuild). **Testable:** yes — `projection::tests::projection_folds_events_into_a_view`.

### FR-BE-003: Consumer inbox dedup (outbox/inbox pattern)

- **MUST** — the consumer records processed `idempotency_key`s in an
  `InboxDedup` (`backend/events/src/consumer.rs`): `mark_processed`
  returns `true` the FIRST time a key is seen (process the event) and
  `false` for a duplicate (skip it).
- **MUST** — a redelivered event (NATS gives at-least-once delivery) is
  folded into the projection **exactly once** — the inbox half of the
  outbox/inbox pattern.

**Implemented in:** `backend/events/src/consumer.rs` (`InboxDedup`).
**Constitution reference:** `event-driven.md` (outbox/inbox).
**Testable:** yes — `consumer::tests::first_delivery_processes_duplicate_skips`.

## Acceptance Criteria (Gherkin)

### AC-BE-001: Fold the event stream into a read model

```gherkin
Given events "A", "A", "B" are appended to the event store for stream "s"
When the CountByType projection folds the read stream
Then the read model reports A = 2 and B = 1
```

### AC-BE-002: Projection replay is deterministic

```gherkin
Given a read model built from the event store
When the projection is rebuilt from the same event log
Then the resulting view is identical (deterministic replay)
```

### AC-BE-003: Redelivered event is deduplicated (inbox)

```gherkin
Given an event with idempotency_key "k1" has already been processed
When the same event is redelivered
Then the inbox marks it a duplicate and it is skipped
And the projection is folded only once
```

## Scope

**In scope:** FR-BE-001..003 (the event store + projection + inbox dedup).
**Out of scope:** ingestion (demo-001), saga (demo-003), materialised-view
persistence tuning.
