# Proposal: demo-003-order-saga

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- Layers: [backend, infra] — multi-layer (Janus) demo -->

## Problem

demo-001 (ingestion) and demo-002 (projection) are single-layer backend
changes. An adopter also needs to see (1) how a **multi-layer** change
flows through the **Janus** cross-layer orchestrator, and (2) the
archetype's flagship discipline: a **durable, multi-step process** with
compensation. Article VIII.2 forbids ad-hoc saga logic in application
code and mandates **Temporal** — so a saga demo is the natural showcase
for both.

The archetype's `frontend` layer is a single DEFERRED `ops-console`
surface (ADR-B6-1-004), so the multi-layer axis here is **[backend,
infra]**: the `saga` crate (backend) plus the Temporal cluster substrate
it runs on (infra).

## Solution

Demonstrate a 3-step **order fulfillment saga** — *reserve stock →
charge payment → confirm shipment* — orchestrated Temporal
activity-only, with **reverse-order compensation** on failure.

- **Backend** (`backend/saga/`):
  1. **Coordinator core** — the in-process `Saga` runs steps forward and,
     on the first failure, runs the compensations for the
     already-completed steps in **reverse order** (`compensation.rs`).
     This deterministic core is the unit-testable compensation-ordering
     logic.
  2. **Activities** — each side effect is a Temporal **activity**
     (`activity.rs`: `ReserveStock`, `ChargePayment`, `ConfirmShipment`),
     registered by name on the worker (`registered_activity_names`). NO
     `#[workflow]` bodies (the native SDK's workflow API is pre-alpha).
  3. **SDK seam** — the native `temporalio-sdk` / `temporalio-client`
     access is behind the OFF-by-default `temporal-sdk` feature
     (`temporal.rs`), so default builds stay hermetic.
- **Infra** (`infra/`): the Temporal cluster the worker connects to —
  the dev `docker-compose.temporal.yml` overlay and the production
  `k8s/temporal-cluster/` Helm values (history/matching/frontend/worker +
  Postgres backing). Consumed **by reference** (the B8O substrate), not
  re-decided per demo.

This is Article VIII.2 made concrete: durable retry/timeout/heartbeat
semantics come from Temporal; the demo owns only the **compensation
ordering** (the deterministic core) and the **activity registry**.

This demo is **deliberately illustrative** — three in-memory saga steps
with recording compensation; not a production order service.

## Scope In

- **Backend**: the `Saga` coordinator (forward run + reverse-order
  compensation), the 3 order-fulfillment activities + their registration,
  the `SagaStep` port (idempotent execute/compensate), the feature-gated
  Temporal SDK seam.
- **Infra**: the Temporal cluster substrate the worker targets (dev
  compose overlay + prod Helm values), referenced from the saga design.
- cucumber-rs BDD: the 3-step happy path + the compensation path (a
  mid-saga failure compensates completed steps in reverse).

## Scope Out

- No live Temporal server (tests drive the in-process coordinator; the
  `temporal-sdk` feature is OFF, so no SDK crates compile by default).
- No new infra provisioning — the Temporal cluster is the archetype's
  existing B8O substrate, consumed by reference (not re-decided here).
- No ingestion/projection re-implementation (demo-001/002); the saga's
  effects reuse those surfaces.

## Impact

- **Users affected**: adopters evaluating the saga / process-manager
  surface + the multi-layer (Janus) workflow of the archetype.
- **Technical impact**: illustrative; the product code lives in the
  rendered `backend/saga/` workspace (inline `#[cfg(test)]` tests) and
  the rendered `infra/temporal/` + `infra/k8s/temporal-cluster/`.
- **Dependencies**: `demo-001` + `demo-002` (the events/read-model the
  saga's effects touch); the rendered backbone (`b6-2-scaffolder`) —
  `saga/` crate + Temporal infra; `infra/temporal.md` (B8O substrate).
- **Risk level**: Low (illustrative, additive, no external calls; the
  pre-alpha SDK stays feature-gated OFF).

## Constitution Compliance

- **Article I (TDD)**: `saga/` ships RED→GREEN→REFACTOR inline tests
  (all-succeed runs no compensation; a failure compensates completed
  steps in reverse; activities have stable namespaced names).
- **Article II (BDD)**: `features/order_saga.feature` covers the happy
  path + the compensation path.
- **Article III (Specs before code)**: proposal → specs → per-layer
  designs → per-layer tasks precede the (already-scaffolded)
  implementation.
- **Article VII (Rust architecture)**: hexagonal; `SagaStep`/`Activity`
  are ports; no `unwrap()`/`panic!()` in production paths.
- **Article VIII.2 (Temporal)**: durable orchestration is Temporal
  activity-only; the in-process coordinator is the testable core; **no
  ad-hoc saga logic in application code**.

---

**Gate**: Proposal complete. Next → `/forge:specify demo-003-order-saga`.
