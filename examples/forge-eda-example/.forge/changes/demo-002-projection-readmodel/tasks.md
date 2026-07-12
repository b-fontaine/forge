# Tasks: demo-002-projection-readmodel

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- TDD-ordered: RED test before GREEN impl per Article I. -->
<!-- The product code lives in the rendered backend/eventstore/ + events/ -->
<!-- workspace; these tasks document the RED→GREEN→REFACTOR cycle. -->

## Phase 1: Append-only event store (FR-BE-001)

- [x] RED — `store::tests::append_then_read_preserves_order` (append two
  events, read back in `seq` order). [Story: FR-BE-001]
- [x] RED — `store::tests::append_is_idempotent_on_idempotency_key`
  (retried append is a no-op). [Story: FR-BE-001]
- [x] GREEN — `EventStore` port + `InMemoryEventStore` (seq assignment +
  key dedup). [Story: FR-BE-001]
- [x] GREEN — `PgEventStore` runtime `sqlx::query` (no `DATABASE_URL`
  needed) + `infra/postgres/init-eventstore.sql` DDL. [Story: FR-BE-001]

## Phase 2: Read-model projection (FR-BE-002)

- [x] RED — `projection::tests::projection_folds_events_into_a_view`
  (CountByType folds A,A,B → A=2,B=1). [Story: FR-BE-002]
- [x] GREEN — `Projection` trait (`apply` + `view`), pure fold.
  [Story: FR-BE-002]
- [x] REFACTOR — assert deterministic replay (rebuild == original view).
  [Story: FR-BE-002]

## Phase 3: Consumer inbox dedup (FR-BE-003)

- [x] RED — `consumer::tests::first_delivery_processes_duplicate_skips`.
  [Story: FR-BE-003]
- [x] GREEN — `InboxDedup::mark_processed` / `is_processed`.
  [Story: FR-BE-003]
- [x] GREEN — cucumber-rs steps: append → project → replay + redelivery
  dedup. [Story: FR-BE-003]

## Phase 4: Quality + archive

- [x] `cargo clippy --workspace -- -D warnings` (no unwrap/panic in prod).
  [Story: FR-BE-001]
- [x] `cargo test --workspace` (eventstore + consumer tests + feature) green.
  [Story: FR-BE-002]
- [x] Mark all `[x]`, set status: archived, populate timeline.
  [Story: FR-BE-003]
