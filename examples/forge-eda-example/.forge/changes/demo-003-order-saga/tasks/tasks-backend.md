# Tasks (backend layer): demo-003-order-saga

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- Layer: backend (FR-BE-*). TDD-ordered: RED before GREEN per Article I. -->
<!-- Product code lives in the rendered backend/saga/ workspace. -->

## Phase 1: Compensation core (FR-BE-001)

- [x] RED — `compensation::tests::all_steps_succeed_runs_no_compensation`
  (3 steps all succeed → exec a,b,c; no compensation). [Story: FR-BE-001]
- [x] RED — `compensation::tests::failure_compensates_completed_steps_in_reverse`
  (c fails → comp b, comp a in reverse; original error returned).
  [Story: FR-BE-001]
- [x] GREEN — `Saga::run` (forward run + reverse-order best-effort
  compensation). [Story: FR-BE-001]
- [x] REFACTOR — `SagaError::StepFailed { step, reason }` typed error.
  [Story: FR-BE-001]

## Phase 2: SagaStep port (FR-BE-002)

- [x] RED — recording-step fixture asserting idempotent execute/compensate.
  [Story: FR-BE-002]
- [x] GREEN — `SagaStep` `async_trait` port (`name`/`execute`/`compensate`).
  [Story: FR-BE-002]

## Phase 3: Temporal activity registry (FR-BE-003)

- [x] RED — `activity::tests::activities_have_stable_namespaced_names`
  (all names start with `saga.`). [Story: FR-BE-003]
- [x] GREEN — `Activity` port + `registered_activity_names()`
  (reserve/charge/confirm activities). [Story: FR-BE-003]
- [x] GREEN — `temporal.rs` SDK re-export behind the OFF-by-default
  `temporal-sdk` feature (default builds hermetic). [Story: FR-BE-003]
- [x] GREEN — cucumber-rs steps: happy path + compensation path.
  [Story: FR-BE-003]

## Phase 4: Quality + archive (backend)

- [x] `cargo clippy --workspace -- -D warnings` (no unwrap/panic in prod).
  [Story: FR-BE-001]
- [x] `cargo test --workspace` (saga tests + feature) green — default
  build, `temporal-sdk` feature OFF. [Story: FR-BE-003]
- [x] Mark backend tasks `[x]` (archived with the infra layer).
  [Story: FR-BE-002]
