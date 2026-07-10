//! [`EventPublisher`] port + a NATS JetStream implementation.

use async_nats::jetstream;
use async_nats::HeaderMap;
use async_trait::async_trait;

use crate::envelope::EventEnvelope;

/// Errors raised while publishing an event.
#[derive(Debug, thiserror::Error)]
pub enum PublishError {
    /// Serialising the envelope failed.
    #[error("serialize event: {0}")]
    Serialize(#[from] serde_json::Error),
    /// The JetStream publish or its acknowledgement failed.
    #[error("jetstream publish: {0}")]
    Publish(String),
}

/// A sink that publishes domain events. Trait-based (hexagonal port) so the
/// request path depends on an abstraction and tests can use an in-memory fake.
#[async_trait]
pub trait EventPublisher: Send + Sync {
    /// Publish one event. Implementations MUST be idempotent with respect to the
    /// envelope's `idempotency_key`.
    async fn publish(&self, event: &EventEnvelope) -> Result<(), PublishError>;
}

/// NATS JetStream implementation of [`EventPublisher`]. Sets the `Nats-Msg-Id`
/// header to the envelope idempotency key so the JetStream server deduplicates
/// re-published events within its configured dedup window.
pub struct JetStreamPublisher {
    ctx: jetstream::Context,
}

impl JetStreamPublisher {
    /// Wrap a JetStream context. Obtain one with
    /// `async_nats::jetstream::new(async_nats::connect(url).await?)`.
    pub fn new(ctx: jetstream::Context) -> Self {
        Self { ctx }
    }
}

#[async_trait]
impl EventPublisher for JetStreamPublisher {
    async fn publish(&self, event: &EventEnvelope) -> Result<(), PublishError> {
        let body = serde_json::to_vec(event)?;
        let mut headers = HeaderMap::new();
        headers.insert("Nats-Msg-Id", event.idempotency_key.as_str());
        let ack = self
            .ctx
            .publish_with_headers(event.subject(), headers, body.into())
            .await
            .map_err(|e| PublishError::Publish(e.to_string()))?;
        ack.await
            .map_err(|e| PublishError::Publish(e.to_string()))?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Mutex;

    /// In-memory fake used to test code that depends on the [`EventPublisher`] port
    /// without a live NATS server.
    #[derive(Default)]
    struct RecordingPublisher {
        published: Mutex<Vec<EventEnvelope>>,
    }

    #[async_trait]
    impl EventPublisher for RecordingPublisher {
        async fn publish(&self, event: &EventEnvelope) -> Result<(), PublishError> {
            if let Ok(mut guard) = self.published.lock() {
                guard.push(event.clone());
            }
            Ok(())
        }
    }

    #[tokio::test]
    async fn publisher_port_records_published_events() {
        let pubr = RecordingPublisher::default();
        let e = EventEnvelope::new("s", "T", 1, serde_json::json!({}));
        assert!(pubr.publish(&e).await.is_ok());
        let n = pubr.published.lock().map(|g| g.len()).unwrap_or(0);
        assert_eq!(n, 1);
    }
}
