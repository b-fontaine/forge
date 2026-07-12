# Tasks (infra layer): demo-003-order-saga

<!-- Audit: B.6.8 (illustrative demo of b6-8-example) -->
<!-- Layer: infra (FR-IN-*). Multi-layer change → per-layer tasks (FR-GL-016). -->
<!-- Infra is consumed by reference (B8O substrate); no new provisioning. -->

## Phase 1: Point the worker at the Temporal cluster (FR-IN-001)

- [x] Confirm the dev overlay `infra/temporal/docker-compose.temporal.yml`
  provides a single-node Temporal + Postgres for `task dev:up`.
  [Story: FR-IN-001]
- [x] Confirm the prod Helm values `infra/k8s/temporal-cluster/
  values-forge.yaml` cover history/matching/frontend/worker + Postgres
  backing (b6-6-helm substrate). [Story: FR-IN-001]
- [x] Document the saga worker's task-queue + namespace binding in
  `infra/temporal/README.md` (config per environment; not re-decided).
  [Story: FR-IN-001]

## Phase 2: Structural validation (FR-IN-001)

- [x] Assert the rendered `infra/**/*.yaml` parses (the EDA `example` CI
  gate globs + `yaml.safe_load`s it). [Story: FR-IN-001]
- [x] No new infra provisioning — the Temporal cluster is reused by
  reference (ADR-IN-001). [Story: FR-IN-001]

## Phase 3: Archive (infra)

- [x] Mark infra tasks `[x]`; archive the change with the backend layer.
  [Story: FR-IN-001]
