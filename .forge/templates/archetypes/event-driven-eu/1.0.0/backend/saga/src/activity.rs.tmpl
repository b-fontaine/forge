//! Temporal activity marker traits (activity-only worker surface).
//!
//! The `temporalio-sdk` workflow API is Public Preview / pre-alpha, so this
//! archetype runs saga side effects as Temporal **activities only** — NO
//! `#[workflow]` definitions live here. The Temporal worker runtime is consumed
//! from the B8O substrate by reference (orchestration.yaml); this module declares
//! the *activities* that substrate registers. Each activity MUST be idempotent and
//! safe to re-run (Temporal at-least-once semantics).

use async_trait::async_trait;

/// A Temporal activity: a named, idempotent, retry-safe async unit of work.
#[async_trait]
pub trait Activity: Send + Sync {
    /// Stable activity name used for Temporal task registration/routing.
    fn name(&self) -> &'static str;
}

/// Activity: persist an event to the event store (side effect isolated from the
/// workflow so Temporal owns its retry/timeout policy).
pub struct PersistEventActivity;

#[async_trait]
impl Activity for PersistEventActivity {
    fn name(&self) -> &'static str {
        "saga.persist_event"
    }
}

/// Activity: publish an event to NATS JetStream.
pub struct PublishEventActivity;

#[async_trait]
impl Activity for PublishEventActivity {
    fn name(&self) -> &'static str {
        "saga.publish_event"
    }
}

/// The activity names this crate registers with the Temporal worker (activity-only
/// registration — the worker iterates this list at startup).
pub fn registered_activity_names() -> Vec<&'static str> {
    vec![PersistEventActivity.name(), PublishEventActivity.name()]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn activities_have_stable_namespaced_names() {
        let names = registered_activity_names();
        assert!(names.contains(&"saga.persist_event"));
        assert!(names.contains(&"saga.publish_event"));
        // Namespaced under `saga.` so they don't collide with other layers'
        // activities in the shared Temporal namespace.
        assert!(names.iter().all(|n| n.starts_with("saga.")));
    }
}
