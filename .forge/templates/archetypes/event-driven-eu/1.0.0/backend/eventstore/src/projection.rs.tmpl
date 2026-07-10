//! Read-model projections — fold the event stream into a query-optimised view.

use events::EventEnvelope;

/// A projection folds events into a read model. Projections MUST be deterministic
/// and idempotent (replayable): folding the same event log twice yields the same
/// view, so a projection can be rebuilt from the event store at any time.
pub trait Projection {
    /// The read-model type this projection maintains.
    type View;
    /// Fold one event into the running view.
    fn apply(&mut self, event: &EventEnvelope);
    /// Borrow the current view.
    fn view(&self) -> &Self::View;
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A trivial projection counting events per `event_type`.
    #[derive(Default)]
    struct CountByType {
        counts: std::collections::BTreeMap<String, u64>,
    }

    impl Projection for CountByType {
        type View = std::collections::BTreeMap<String, u64>;
        fn apply(&mut self, event: &EventEnvelope) {
            *self.counts.entry(event.event_type.clone()).or_insert(0) += 1;
        }
        fn view(&self) -> &Self::View {
            &self.counts
        }
    }

    #[test]
    fn projection_folds_events_into_a_view() {
        let mut p = CountByType::default();
        p.apply(&EventEnvelope::new("s", "A", 1, serde_json::json!({})));
        p.apply(&EventEnvelope::new("s", "A", 1, serde_json::json!({})));
        p.apply(&EventEnvelope::new("s", "B", 1, serde_json::json!({})));
        assert_eq!(p.view().get("A"), Some(&2));
        assert_eq!(p.view().get("B"), Some(&1));
    }
}
