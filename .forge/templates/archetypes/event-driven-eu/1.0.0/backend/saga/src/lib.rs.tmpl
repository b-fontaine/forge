//! `saga` — Temporal ACTIVITY-ONLY saga orchestration for the event-driven-eu
//! archetype.
//!
//! Article VIII.2 forbids ad-hoc saga implementations in application code and
//! mandates Temporal for durable multi-step workflows. This crate ships the
//! activity-only surface:
//!
//! - [`activity`] — activity marker traits the Temporal worker registers (heavy
//!   side effects run as activities, not in the workflow body);
//! - [`compensation`] — a deterministic, unit-testable saga coordinator that runs
//!   steps forward and compensates completed steps in REVERSE order on failure;
//! - `temporal` — the pre-alpha native Temporal SDK, behind the OFF-by-default
//!   `temporal-sdk` feature (the workflow API "will continue to evolve" —
//!   infra/temporal.md — so default builds do not compile it).
pub mod activity;
pub mod compensation;
#[cfg(feature = "temporal-sdk")]
pub mod temporal;

pub use activity::{registered_activity_names, Activity};
pub use compensation::{Saga, SagaError, SagaStep};
