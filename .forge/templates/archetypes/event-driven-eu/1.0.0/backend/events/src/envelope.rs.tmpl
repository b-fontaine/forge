//! The versioned, idempotent envelope every domain event travels in.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A domain event wrapped for transport over NATS JetStream and persistence in the
/// Postgres event store. Carries the event-versioning + idempotency metadata the
/// archetype mandates (`event_specifics` in the schema).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct EventEnvelope {
    /// Unique event id (also the default idempotency key).
    pub id: Uuid,
    /// Logical stream this event belongs to (e.g. an aggregate id).
    pub stream_id: String,
    /// The event type name (e.g. `OrderPlaced`).
    pub event_type: String,
    /// Schema version of `payload` for this `event_type` (event versioning — a
    /// consumer selects the right deserializer by (`event_type`, `event_version`)).
    pub event_version: u32,
    /// Idempotency key — stable across retries. Used as the JetStream `Nats-Msg-Id`
    /// (publish dedup) and as the event-store uniqueness key (append dedup).
    pub idempotency_key: String,
    /// The event body.
    pub payload: serde_json::Value,
    /// When the event occurred (UTC).
    pub occurred_at: DateTime<Utc>,
}

impl EventEnvelope {
    /// Build a new envelope with a fresh id + timestamp. The idempotency key
    /// defaults to the event id; call [`EventEnvelope::with_idempotency_key`] to use
    /// a business key (e.g. `order-42`) so publish + append retries are safe.
    pub fn new(
        stream_id: impl Into<String>,
        event_type: impl Into<String>,
        event_version: u32,
        payload: serde_json::Value,
    ) -> Self {
        let id = Uuid::new_v4();
        Self {
            id,
            stream_id: stream_id.into(),
            event_type: event_type.into(),
            event_version,
            idempotency_key: id.to_string(),
            payload,
            occurred_at: Utc::now(),
        }
    }

    /// Override the idempotency key with a stable business key (recommended —
    /// `event_specifics.idempotency_keys`).
    #[must_use]
    pub fn with_idempotency_key(mut self, key: impl Into<String>) -> Self {
        self.idempotency_key = key.into();
        self
    }

    /// The JetStream subject this event publishes to, namespaced by type + version:
    /// `events.v<version>.<event_type>`.
    pub fn subject(&self) -> String {
        format!("events.v{}.{}", self.event_version, self.event_type)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn subject_is_namespaced_by_version_and_type() {
        let e = EventEnvelope::new("order-1", "OrderPlaced", 2, serde_json::json!({"total": 9}));
        assert_eq!(e.subject(), "events.v2.OrderPlaced");
    }

    #[test]
    fn idempotency_key_defaults_to_id_and_is_overridable() {
        let e = EventEnvelope::new("s", "T", 1, serde_json::json!({}));
        assert_eq!(e.idempotency_key, e.id.to_string());
        let e = e.with_idempotency_key("order-42");
        assert_eq!(e.idempotency_key, "order-42");
    }

    #[test]
    fn serde_round_trips() {
        let e = EventEnvelope::new("s", "T", 1, serde_json::json!({"k": "v"}));
        let json = serde_json::to_string(&e).unwrap_or_default();
        let back = serde_json::from_str::<EventEnvelope>(&json).ok();
        assert_eq!(back.as_ref(), Some(&e));
    }
}
