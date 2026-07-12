# Tasks: demo-001-ingestion-http-nats

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- TDD-ordered: RED test before GREEN impl per Article I. -->
<!-- The product code lives in the rendered backend/events/ workspace; these -->
<!-- tasks document the RED→GREEN→REFACTOR cycle that produced it. -->

## Phase 1: Event envelope (FR-BE-001)

- [x] RED — `envelope::tests::subject_is_namespaced_by_version_and_type`
  asserts `EventEnvelope::new("order-1","OrderPlaced",2,..).subject()`
  == `events.v2.OrderPlaced`. [Story: FR-BE-001]
- [x] RED — `envelope::tests::idempotency_key_defaults_to_id_and_is_overridable`.
  [Story: FR-BE-001]
- [x] GREEN — implement `EventEnvelope::new` / `with_idempotency_key` /
  `subject`. [Story: FR-BE-001]
- [x] REFACTOR — derive `Serialize`/`Deserialize`; `serde_round_trips` test.
  [Story: FR-BE-001]

## Phase 2: Publisher port + JetStream dedup (FR-BE-002)

- [x] RED — `publisher::tests::publisher_port_records_published_events`
  (drives the `EventPublisher` port through the in-memory fake).
  [Story: FR-BE-002]
- [x] GREEN — `EventPublisher` `async_trait` port + `PublishError`.
  [Story: FR-BE-002]
- [x] GREEN — `JetStreamPublisher` sets `Nats-Msg-Id` = `idempotency_key`
  and awaits the JetStream ack. [Story: FR-BE-002]

## Phase 3: HTTP ingestion → EventService.Publish (FR-BE-003)

- [x] RED — feature scenario: ingest a command, assert it publishes to
  the versioned subject. [Story: FR-BE-003]
- [x] GREEN — map the axum command to `EventService.Publish`
  (`stream_id`/`event_type`/`event_version`/`idempotency_key`/`payload`).
  [Story: FR-BE-003]
- [x] GREEN — idempotent re-publish returns `deduplicated = true`.
  [Story: FR-BE-003]

## Phase 4: Quality + archive

- [x] `cargo clippy --workspace -- -D warnings` (no unwrap/panic in prod).
  [Story: FR-BE-002]
- [x] `cargo test --workspace` (events unit tests + the feature) green.
  [Story: FR-BE-001]
- [x] Mark all `[x]`, set status: archived, populate timeline.
  [Story: FR-BE-003]
