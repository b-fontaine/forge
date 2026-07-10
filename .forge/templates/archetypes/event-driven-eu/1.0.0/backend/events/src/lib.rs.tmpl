//! `events` — NATS JetStream event backbone for the event-driven-eu archetype.
//!
//! Ships the versioned, idempotent [`EventEnvelope`]; an [`EventPublisher`] port
//! with a JetStream implementation ([`JetStreamPublisher`]) that deduplicates via
//! the `Nats-Msg-Id` header (JetStream server-side dedup); and the consumer-side
//! [`InboxDedup`] (inbox pattern). Heavy or long-running processing belongs in a
//! Temporal activity (see the `saga` crate), never in a consumer callback.
//!
//! Standards: infra/nats-jetstream.md + global/event-driven.md (both delivered by
//! B.6.3) govern clustering, event versioning, and the outbox/inbox patterns.
pub mod consumer;
pub mod envelope;
pub mod publisher;

pub use consumer::InboxDedup;
pub use envelope::EventEnvelope;
pub use publisher::{EventPublisher, JetStreamPublisher, PublishError};
