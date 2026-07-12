# Specs: demo-003-order-saga

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- Layers: [backend, infra] — multi-layer (Janus). Per-layer FR prefixes: -->
<!-- FR-BE-* (backend saga crate), FR-IN-* (infra Temporal cluster). -->

This spec follows the Article IV delta convention with **per-layer**
requirement IDs (FR-GL-016: a multi-layer change delegates child
requirements to layer prefixes). The cross-layer intent (FR-GL-*) is a
durable, compensating order-fulfillment saga; it is realised by the
backend saga crate (FR-BE-*) running on the infra Temporal cluster
(FR-IN-*). The implementation lives in the rendered `backend/saga/` +
`infra/temporal/` + `infra/k8s/temporal-cluster/`.

## Cross-layer requirement

### FR-GL-001: Durable, compensating 3-step order-fulfillment saga

- **MUST** — an order is fulfilled by a 3-step saga (reserve stock →
  charge payment → confirm shipment) that either completes all steps or,
  on the first failure, undoes the completed steps in reverse order.
- **MUST** — the durable retry/timeout semantics come from Temporal
  (Article VIII.2); the application code owns only the compensation
  ordering + the activity definitions. This decomposes into FR-BE-* (the
  saga crate) + FR-IN-* (the Temporal cluster).

**Constitution reference:** Article VIII.2. Routed to **Janus** (≥ 2
layers, FR-GL-015). **Testable:** yes — `features/order_saga.feature`.

## ADDED Requirements — backend (`backend/saga/`)

### FR-BE-001: Saga coordinator with reverse-order compensation

- **MUST** — the `Saga` coordinator (`backend/saga/src/compensation.rs`)
  runs `SagaStep`s in order; on the first forward failure it runs the
  compensations of the **already-completed** steps in **reverse order**,
  then returns the original error (compensation is best-effort and MUST
  NOT mask the original cause).
- **MUST** — a step that never completed is NOT compensated.

**Implemented in:** `backend/saga/src/compensation.rs`
(`Saga`, `SagaStep`, `SagaError`).
**Constitution reference:** Article VIII.2; `event-driven.md` (saga /
compensation). **Testable:** yes —
`compensation::tests::failure_compensates_completed_steps_in_reverse`,
`all_steps_succeed_runs_no_compensation`.

### FR-BE-002: Idempotent `SagaStep` port (execute + compensate)

- **MUST** — each step is a `SagaStep` with a stable `name()`, an
  `execute()` forward action, and a `compensate()` undo action; **both
  MUST be idempotent** so Temporal can safely retry them (at-least-once).

**Implemented in:** `backend/saga/src/compensation.rs` (`SagaStep`).
**Constitution reference:** Article VII; VIII.2. **Testable:** yes —
covered by the compensation tests.

### FR-BE-003: Temporal activity registry (activity-only)

- **MUST** — heavy side effects run as Temporal **activities**
  (`backend/saga/src/activity.rs`): the order-fulfillment activities are
  registered by stable, `saga.`-namespaced names via
  `registered_activity_names()` (so they do not collide with other
  layers' activities in the shared Temporal namespace).
- **MUST** — NO `#[workflow]` bodies ship — the native SDK's workflow API
  is pre-alpha; the SDK access (`temporalio-sdk` / `temporalio-client`)
  is behind the OFF-by-default `temporal-sdk` feature
  (`backend/saga/src/temporal.rs`), so default `cargo build`/`test` stays
  hermetic.

**Implemented in:** `backend/saga/src/activity.rs`,
`backend/saga/src/temporal.rs`.
**Constitution reference:** Article VIII.2; `infra/temporal.md`.
**Testable:** yes — `activity::tests::activities_have_stable_namespaced_names`.

## ADDED Requirements — infra (`infra/`)

### FR-IN-001: Temporal cluster substrate the worker targets

- **MUST** — the saga worker connects to a Temporal cluster provided by
  the archetype's infra: the dev
  `infra/temporal/docker-compose.temporal.yml` overlay for local runs,
  and the production `infra/k8s/temporal-cluster/` Helm values
  (history/matching/frontend/worker services + Postgres backing).
- **MUST** — the cluster is consumed **by reference** (the B8O substrate,
  `infra/temporal.md`); this demo does NOT re-decide the cluster
  topology, it points the saga worker at it.

**Implemented in:** `infra/temporal/`, `infra/k8s/temporal-cluster/`.
**Constitution reference:** Article VIII; `infra/temporal.md`.
**Testable:** structural — the rendered infra YAML parses (the EDA
`example` CI gate parses `infra/**/*.yaml`).

## Acceptance Criteria (Gherkin)

### AC-GL-001: Happy path completes all three steps

```gherkin
Given an order saga with steps reserve-stock, charge-payment, confirm-shipment
When the saga runs and every step succeeds
Then all three steps execute in order
And no compensation runs
```

### AC-GL-002: A mid-saga failure compensates in reverse order

```gherkin
Given an order saga where confirm-shipment fails
When the saga runs
Then reserve-stock and charge-payment execute
And confirm-shipment fails
And charge-payment then reserve-stock are compensated in reverse order
And the original failure is returned
```

## Scope

**In scope:** FR-GL-001 (cross-layer), FR-BE-001..003 (saga crate),
FR-IN-001 (Temporal cluster substrate).
**Out of scope:** live Temporal (feature OFF), ingestion/projection
re-implementation (demo-001/002), cluster topology re-decisions.
