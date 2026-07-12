//! Dependency-injection wiring for the event-driven-eu backend.
//!
//! Article VII.3 — the binary holds NO business logic; it composes the ports each
//! layer exposes. This module builds the local-dev / test defaults (no network):
//! an in-memory event store and the saga activity registry. In production, swap the
//! `InMemoryEventStore` for a `PgEventStore` (Postgres) and construct a
//! `JetStreamPublisher` from `async_nats::connect` — see each crate's docs.

use eventstore::{EventStore, InMemoryEventStore};

/// The wired-up backend dependencies (local-dev / test profile).
pub struct Backend {
    /// The append-only event store (in-memory default; `PgEventStore` in prod).
    pub store: InMemoryEventStore,
    /// The saga activity names the Temporal worker registers (activity-only).
    pub saga_activities: Vec<&'static str>,
}

impl Backend {
    /// Build the local-dev / test backend (no network dependencies).
    pub fn local() -> Self {
        Self {
            store: InMemoryEventStore::new(),
            saga_activities: saga::registered_activity_names(),
        }
    }
}

/// Assert the store port is reachable by appending + reading one event. Returns the
/// number of events in the stream after a round-trip (used by the smoke test and as
/// a documented wiring example).
pub async fn smoke_roundtrip(backend: &Backend) -> Result<usize, eventstore::EventStoreError> {
    let event = events::EventEnvelope::new("smoke", "Wired", 1, serde_json::json!({"ok": true}))
        .with_idempotency_key("smoke-1");
    backend.store.append(&event).await?;
    Ok(backend.store.read_stream("smoke").await?.len())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn local_backend_registers_saga_activities() {
        let backend = Backend::local();
        assert!(backend
            .saga_activities
            .iter()
            .any(|n| n.starts_with("saga.")));
    }

    #[tokio::test]
    async fn smoke_roundtrip_persists_and_reads_one_event() {
        let backend = Backend::local();
        let n = smoke_roundtrip(&backend).await.unwrap_or_default();
        assert_eq!(n, 1);
    }
}
