//! `eventstore` — append-only Postgres event store + read-model projections.
//!
//! The [`EventStore`] port (hexagonal) has a Postgres implementation
//! ([`PgEventStore`], sqlx) and an [`InMemoryEventStore`] for unit tests + local
//! dev. Appends are idempotent on the envelope `idempotency_key` (a unique index in
//! Postgres; a de-dup check in memory) so a retried append is a no-op. Projections
//! ([`Projection`]) fold the event stream into query-optimised read models.
//!
//! Schema: `infra/postgres/init-eventstore.sql`. Standard: persistence.yaml
//! (postgres-17) + global/event-driven.md (delivered by B.6.3).
pub mod projection;
pub mod store;

pub use projection::Projection;
pub use store::{EventStore, EventStoreError, InMemoryEventStore, PgEventStore, StoredEvent};
