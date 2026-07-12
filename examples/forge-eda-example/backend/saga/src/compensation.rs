//! In-process saga coordinator with reverse-order compensation.
//!
//! This is the deterministic, unit-testable CORE each Temporal activity chain
//! drives. It runs steps forward and, on the first failure, runs the compensations
//! for the already-completed steps in REVERSE order. In production the durable
//! retry/timeout/heartbeat semantics come from Temporal (the `temporal-sdk`
//! feature); this core keeps the compensation *ordering* logic testable without a
//! Temporal server (`event_specifics.saga_compensation`).

use async_trait::async_trait;

/// Errors raised while running a saga.
#[derive(Debug, thiserror::Error)]
pub enum SagaError {
    /// A step's forward action failed. Carries the failing step name + reason.
    #[error("saga step '{step}' failed: {reason}")]
    StepFailed {
        /// The failing step's name.
        step: &'static str,
        /// Why it failed.
        reason: String,
    },
}

/// One saga step: a forward action + its compensating (undo) action. Both MUST be
/// idempotent so Temporal can safely retry them.
#[async_trait]
pub trait SagaStep: Send + Sync {
    /// Stable step name (for tracing/logging and error reporting).
    fn name(&self) -> &'static str;
    /// Run the forward action.
    async fn execute(&self) -> Result<(), SagaError>;
    /// Undo the forward action (called during compensation, reverse order).
    async fn compensate(&self) -> Result<(), SagaError>;
}

/// Runs a sequence of [`SagaStep`]s with reverse-order compensation on failure.
#[derive(Default)]
pub struct Saga<'a> {
    steps: Vec<&'a dyn SagaStep>,
}

impl<'a> Saga<'a> {
    /// A new, empty saga.
    pub fn new() -> Self {
        Self { steps: Vec::new() }
    }

    /// Append a step (builder style).
    #[must_use]
    pub fn step(mut self, step: &'a dyn SagaStep) -> Self {
        self.steps.push(step);
        self
    }

    /// Execute steps in order. On the first forward failure, compensate the
    /// already-completed steps in REVERSE order (best effort — a compensation error
    /// does not mask the original failure) and return the original error.
    pub async fn run(&self) -> Result<(), SagaError> {
        let mut completed: Vec<&'a dyn SagaStep> = Vec::new();
        for step in &self.steps {
            match step.execute().await {
                Ok(()) => completed.push(*step),
                Err(err) => {
                    for done in completed.iter().rev() {
                        // Best-effort compensation; the caller's tracing layer records
                        // a compensation failure. The original error is still returned
                        // so the saga surfaces its true cause.
                        let _ = done.compensate().await;
                    }
                    return Err(err);
                }
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::{Arc, Mutex};

    /// Records the order in which execute/compensate ran, and can be told to fail.
    struct RecordingStep {
        step_name: &'static str,
        fail: bool,
        log: Arc<Mutex<Vec<String>>>,
    }

    #[async_trait]
    impl SagaStep for RecordingStep {
        fn name(&self) -> &'static str {
            self.step_name
        }
        async fn execute(&self) -> Result<(), SagaError> {
            if let Ok(mut l) = self.log.lock() {
                l.push(format!("exec:{}", self.step_name));
            }
            if self.fail {
                return Err(SagaError::StepFailed {
                    step: self.step_name,
                    reason: "boom".into(),
                });
            }
            Ok(())
        }
        async fn compensate(&self) -> Result<(), SagaError> {
            if let Ok(mut l) = self.log.lock() {
                l.push(format!("comp:{}", self.step_name));
            }
            Ok(())
        }
    }

    fn snapshot(log: &Arc<Mutex<Vec<String>>>) -> Vec<String> {
        log.lock().map(|l| l.clone()).unwrap_or_default()
    }

    #[tokio::test]
    async fn all_steps_succeed_runs_no_compensation() {
        let log = Arc::new(Mutex::new(Vec::new()));
        let a = RecordingStep {
            step_name: "a",
            fail: false,
            log: log.clone(),
        };
        let b = RecordingStep {
            step_name: "b",
            fail: false,
            log: log.clone(),
        };
        let result = Saga::new().step(&a).step(&b).run().await;
        assert!(result.is_ok());
        assert_eq!(snapshot(&log), vec!["exec:a", "exec:b"]);
    }

    #[tokio::test]
    async fn failure_compensates_completed_steps_in_reverse() {
        let log = Arc::new(Mutex::new(Vec::new()));
        let a = RecordingStep {
            step_name: "a",
            fail: false,
            log: log.clone(),
        };
        let b = RecordingStep {
            step_name: "b",
            fail: false,
            log: log.clone(),
        };
        let c = RecordingStep {
            step_name: "c",
            fail: true,
            log: log.clone(),
        };
        let result = Saga::new().step(&a).step(&b).step(&c).run().await;
        assert!(matches!(
            result,
            Err(SagaError::StepFailed { step: "c", .. })
        ));
        // a, b executed; c failed; then compensate b, a (reverse); c never completed.
        assert_eq!(
            snapshot(&log),
            vec!["exec:a", "exec:b", "exec:c", "comp:b", "comp:a"]
        );
    }
}
