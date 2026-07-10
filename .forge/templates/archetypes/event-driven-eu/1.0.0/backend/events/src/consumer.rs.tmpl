//! Consumer-side idempotency guard (inbox pattern).

use std::collections::HashSet;

/// Tracks idempotency keys already processed so a redelivered event (NATS gives
/// at-least-once delivery) is handled exactly once — the inbox pattern
/// (`event_specifics.outbox_inbox_pattern`). In production, back this with a
/// Postgres `inbox` table keyed by `idempotency_key`; this in-memory version is the
/// unit-testable core and a local-dev default.
#[derive(Debug, Default)]
pub struct InboxDedup {
    seen: HashSet<String>,
}

impl InboxDedup {
    /// A new, empty inbox.
    pub fn new() -> Self {
        Self::default()
    }

    /// Record a key as processed. Returns `true` the FIRST time a key is seen
    /// (caller SHOULD process the event) and `false` for a duplicate (caller SHOULD
    /// skip it).
    pub fn mark_processed(&mut self, idempotency_key: &str) -> bool {
        self.seen.insert(idempotency_key.to_string())
    }

    /// Whether a key has already been processed.
    pub fn is_processed(&self, idempotency_key: &str) -> bool {
        self.seen.contains(idempotency_key)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn first_delivery_processes_duplicate_skips() {
        let mut inbox = InboxDedup::new();
        assert!(inbox.mark_processed("k1"), "first delivery must process");
        assert!(!inbox.mark_processed("k1"), "duplicate must be skipped");
        assert!(inbox.is_processed("k1"));
        assert!(!inbox.is_processed("k2"));
    }
}
