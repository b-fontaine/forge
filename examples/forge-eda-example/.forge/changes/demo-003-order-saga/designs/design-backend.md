# Design (backend layer): demo-003-order-saga

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- Layer: backend (FR-BE-*). Multi-layer change → per-layer design (FR-GL-016). -->

This is the **backend-layer** design for the order-fulfillment saga
(FR-BE-001..003). The infra-layer design (the Temporal cluster the worker
targets) is in `designs/design-infra.md`; Janus coordinates the two.

## Architecture Decisions

### ADR-BE-001: In-process compensation core is the unit-testable saga logic

**Context.** Article VIII.2 mandates Temporal for durable orchestration,
but the durable retry/timeout machinery is not unit-testable without a
Temporal server. FR-BE-001 still needs the **compensation ordering** to
be provably correct.

**Decision.** Split the concern. The deterministic `Saga` coordinator
(`compensation.rs`) owns the *ordering* logic — run forward, compensate
completed steps in reverse on failure — and is fully unit-tested in
process (no Temporal). Temporal owns the *durability* (retries, timeouts,
heartbeats) at runtime. The coordinator is what a Temporal workflow (or,
today, an activity chain) drives.

**Consequences.** ✅ The reverse-order compensation is a hermetic unit
test (`failure_compensates_completed_steps_in_reverse`). ✅ No Temporal
server needed for `cargo test`. ⚠️ The coordinator is not itself durable
— durability is Temporal's job at runtime (documented seam).

### ADR-BE-002: Steps are idempotent `SagaStep` ports; effects are Temporal activities

**Context.** FR-BE-002/003 — Temporal is at-least-once, so every step's
forward + compensating action must be safe to re-run, and heavy side
effects must run as activities (not in a workflow body).

**Decision.** `SagaStep` is an `async_trait` port with `name` +
idempotent `execute` + idempotent `compensate`. The concrete order steps
(reserve stock / charge payment / confirm shipment) are backed by
Temporal **activities** registered by `saga.`-namespaced names
(`registered_activity_names`). The workflow body is omitted — the native
SDK's workflow API is pre-alpha.

**Consequences.** ✅ Retry-safe steps. ✅ Activities are namespaced so
they don't collide in the shared Temporal namespace. ⚠️ The full workflow
definition lands when the SDK's workflow API stabilises (the
`temporal-sdk` feature seam is ready).

### ADR-BE-003: Native Temporal SDK behind an OFF-by-default feature

**Context.** `temporalio-sdk` / `temporalio-client` are Public Preview /
pre-alpha; compiling them by default would make `cargo build` fragile
across toolchains.

**Decision.** `temporal.rs` re-exports the SDK crates only under the
`temporal-sdk` feature (OFF by default). Default builds compile the
coordinator + activities (hermetic); enabling the feature wires a real
activity-only worker (per the pinned crate's docs — API taken live, not
invented).

**Consequences.** ✅ Hermetic default `cargo test`. ✅ A clear opt-in path
to a live worker. ⚠️ The live-worker wiring is exercised only under the
opt-in feature (not in the parse-only example CI job).

## Standards Applied

| Standard | How |
|---|---|
| `infra/temporal` | activity-only bias; SDK feature-gated; no workflow bodies |
| `global/event-driven` | saga / process-manager + reverse-order compensation |
| `rust/architecture` | `SagaStep`/`Activity` ports; typed `SagaError`; no unwrap/panic |

## Constitutional compliance gate

| Article | Gate-blocked? | Justification |
|---|---|---|
| I — TDD | NO | inline RED→GREEN tests in compensation/activity |
| VII — Rust | NO | ports; typed errors; no unwrap/panic |
| VIII.2 — Temporal | NO | activity-only; no ad-hoc saga; durability is Temporal's |
