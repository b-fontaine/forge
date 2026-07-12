//! The append-only event store: port, Postgres impl, and in-memory impl.

use async_trait::async_trait;
use events::EventEnvelope;

/// A persisted event, read back from the store with its assigned global sequence.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StoredEvent {
    /// Monotonic global sequence assigned by the store on append.
    pub seq: i64,
    /// The envelope that was appended.
    pub envelope: EventEnvelope,
}

/// Errors raised by the event store.
#[derive(Debug, thiserror::Error)]
pub enum EventStoreError {
    /// The underlying database returned an error.
    #[error("database: {0}")]
    Database(String),
    /// (De)serialising an event payload failed.
    #[error("serde: {0}")]
    Serde(#[from] serde_json::Error),
}

/// Append-only event store port (hexagonal). Appends MUST be idempotent on
/// `envelope.idempotency_key` so a retried append is a no-op.
#[async_trait]
pub trait EventStore: Send + Sync {
    /// Append one event. Idempotent on `envelope.idempotency_key`.
    async fn append(&self, event: &EventEnvelope) -> Result<(), EventStoreError>;
    /// Read all events for a stream, in ascending sequence order.
    async fn read_stream(&self, stream_id: &str) -> Result<Vec<StoredEvent>, EventStoreError>;
}

/// Postgres [`EventStore`] backed by sqlx. The schema lives in
/// `infra/postgres/init-eventstore.sql` (an append-only `events` table with a
/// `BIGSERIAL seq` and a UNIQUE index on `idempotency_key`).
///
/// Uses the runtime `sqlx::query(...)` API (NOT the compile-time-checked `query!`
/// macro) so the crate builds with no `DATABASE_URL` and no live database.
pub struct PgEventStore {
    pool: sqlx::PgPool,
}

impl PgEventStore {
    /// Wrap a connection pool. Build one with `sqlx::PgPool::connect(url).await?`.
    pub fn new(pool: sqlx::PgPool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl EventStore for PgEventStore {
    async fn append(&self, event: &EventEnvelope) -> Result<(), EventStoreError> {
        sqlx::query(
            "INSERT INTO events \
             (event_id, stream_id, event_type, event_version, idempotency_key, payload, occurred_at) \
             VALUES ($1, $2, $3, $4, $5, $6, $7) \
             ON CONFLICT (idempotency_key) DO NOTHING",
        )
        .bind(event.id)
        .bind(&event.stream_id)
        .bind(&event.event_type)
        .bind(i64::from(event.event_version))
        .bind(&event.idempotency_key)
        .bind(&event.payload)
        .bind(event.occurred_at)
        .execute(&self.pool)
        .await
        .map_err(|e| EventStoreError::Database(e.to_string()))?;
        Ok(())
    }

    async fn read_stream(&self, stream_id: &str) -> Result<Vec<StoredEvent>, EventStoreError> {
        use sqlx::Row;
        let rows = sqlx::query(
            "SELECT seq, event_id, stream_id, event_type, event_version, \
                    idempotency_key, payload, occurred_at \
             FROM events WHERE stream_id = $1 ORDER BY seq ASC",
        )
        .bind(stream_id)
        .fetch_all(&self.pool)
        .await
        .map_err(|e| EventStoreError::Database(e.to_string()))?;

        let mut out = Vec::with_capacity(rows.len());
        for row in &rows {
            let version: i64 = row
                .try_get("event_version")
                .map_err(|e| EventStoreError::Database(e.to_string()))?;
            let envelope = EventEnvelope {
                id: row
                    .try_get("event_id")
                    .map_err(|e| EventStoreError::Database(e.to_string()))?,
                stream_id: row
                    .try_get("stream_id")
                    .map_err(|e| EventStoreError::Database(e.to_string()))?,
                event_type: row
                    .try_get("event_type")
                    .map_err(|e| EventStoreError::Database(e.to_string()))?,
                event_version: u32::try_from(version).unwrap_or(0),
                idempotency_key: row
                    .try_get("idempotency_key")
                    .map_err(|e| EventStoreError::Database(e.to_string()))?,
                payload: row
                    .try_get("payload")
                    .map_err(|e| EventStoreError::Database(e.to_string()))?,
                occurred_at: row
                    .try_get("occurred_at")
                    .map_err(|e| EventStoreError::Database(e.to_string()))?,
            };
            let seq: i64 = row
                .try_get("seq")
                .map_err(|e| EventStoreError::Database(e.to_string()))?;
            out.push(StoredEvent { seq, envelope });
        }
        Ok(out)
    }
}

/// In-memory [`EventStore`] for unit tests and local dev (no Postgres needed).
/// Idempotent on `idempotency_key`, assigns sequences in append order.
#[derive(Default)]
pub struct InMemoryEventStore {
    inner: tokio::sync::Mutex<Vec<StoredEvent>>,
}

impl InMemoryEventStore {
    /// A new, empty in-memory store.
    pub fn new() -> Self {
        Self::default()
    }
}

#[async_trait]
impl EventStore for InMemoryEventStore {
    async fn append(&self, event: &EventEnvelope) -> Result<(), EventStoreError> {
        let mut guard = self.inner.lock().await;
        if guard
            .iter()
            .any(|s| s.envelope.idempotency_key == event.idempotency_key)
        {
            return Ok(()); // idempotent: already appended
        }
        let seq = i64::try_from(guard.len()).unwrap_or(i64::MAX) + 1;
        guard.push(StoredEvent {
            seq,
            envelope: event.clone(),
        });
        Ok(())
    }

    async fn read_stream(&self, stream_id: &str) -> Result<Vec<StoredEvent>, EventStoreError> {
        let guard = self.inner.lock().await;
        Ok(guard
            .iter()
            .filter(|s| s.envelope.stream_id == stream_id)
            .cloned()
            .collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn append_then_read_preserves_order() {
        let store = InMemoryEventStore::new();
        let e1 = EventEnvelope::new("s1", "A", 1, serde_json::json!({})).with_idempotency_key("k1");
        let e2 = EventEnvelope::new("s1", "B", 1, serde_json::json!({})).with_idempotency_key("k2");
        assert!(store.append(&e1).await.is_ok());
        assert!(store.append(&e2).await.is_ok());
        let read = store.read_stream("s1").await.unwrap_or_default();
        assert_eq!(read.len(), 2);
        assert_eq!(read[0].seq, 1);
        assert_eq!(read[1].seq, 2);
        assert_eq!(read[0].envelope.event_type, "A");
    }

    #[tokio::test]
    async fn append_is_idempotent_on_idempotency_key() {
        let store = InMemoryEventStore::new();
        let e = EventEnvelope::new("s1", "A", 1, serde_json::json!({})).with_idempotency_key("dup");
        assert!(store.append(&e).await.is_ok());
        assert!(store.append(&e).await.is_ok()); // retried append
        let read = store.read_stream("s1").await.unwrap_or_default();
        assert_eq!(read.len(), 1, "retried append must be a no-op");
    }

    #[tokio::test]
    async fn read_stream_filters_by_stream() {
        let store = InMemoryEventStore::new();
        assert!(store
            .append(
                &EventEnvelope::new("a", "A", 1, serde_json::json!({})).with_idempotency_key("1")
            )
            .await
            .is_ok());
        assert!(store
            .append(
                &EventEnvelope::new("b", "B", 1, serde_json::json!({})).with_idempotency_key("2")
            )
            .await
            .is_ok());
        assert_eq!(store.read_stream("a").await.unwrap_or_default().len(), 1);
        assert_eq!(store.read_stream("b").await.unwrap_or_default().len(), 1);
    }
}
