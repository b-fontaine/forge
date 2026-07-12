# Proposal: b6-5-ci-templates

<!-- Created: 2026-07-10 -->
<!-- Schema: default -->
<!-- Audit: B.6.5 (docs/new-archetypes-plan.md §6.1 — event-driven-eu per-layer CI templates) -->

## Problem

B.6.2 (`b6-2-scaffolder`, archived 2026-07-10) shipped the
`event-driven-eu/1.0.0` template tree (Rust backend workspace, NATS JetStream +
Postgres event store + Temporal activity-only saga, AsyncAPI 3.1 contracts, a
Taskfile exposing `backend:lint` / `backend:build` / `backend:test` /
`asyncapi:validate`). What the tree does **not** yet ship is a CI story: a
project scaffolded from this archetype has no GitHub Actions workflows, so there
is no automated gate on its event/workflow/infra layers.

`full-stack-monorepo` (B.1.9, `b1-delivery`) already established the convention —
per-layer workflows (`forge-frontend.yml` / `forge-backend.yml` /
`forge-infra.yml` / `forge-integration.yml`) that live under the archetype's
`.github/workflows/` and are scaffolded into the adopter's project, filtered with
`dorny/paths-filter@v3`, ending in the Forge gates (`verify.sh` +
`constitution-linter.sh`). The `event-driven-eu` archetype needs the equivalent,
adapted to its layer decomposition (events, workflows/saga, infra).

Per the plan §6.1 (B.6.5): "Templates pipelines CI : workflows par layer
(`forge-events.yml`, `forge-workflows.yml`, `forge-infra.yml`)".

**Ground truth (re-read 2026-07-10, Article III.4):**

- `full-stack-monorepo/.github/workflows/*.yml.tmpl` — the structural precedent
  (name / `on: pull_request+push` / concurrency / `permissions: contents: read`
  / a `filter` job using `dorny/paths-filter@v3` / a gated `build` job / the
  Forge gates last). The `event-driven-eu` archetype has **no** `.github/`
  subtree yet.
- The archetype's `Taskfile.yml.tmpl` defines the canonical dev gates:
  `backend:lint` (`cargo clippy --workspace --all-targets -- -D warnings` +
  `cargo fmt --all --check`), `backend:build`, `backend:test`
  (`cargo test --workspace`), `asyncapi:validate`
  (`npx -y @asyncapi/cli validate asyncapi.yaml`), `proto` (`buf generate`).
  CI MUST invoke these targets so CI and local dev stay in lock-step.
- The backend is ONE Cargo workspace with four members (`events`, `eventstore`,
  `saga`, `bin-server`). The per-workflow split is by **change surface**
  (paths-filter), not by cloning the workspace test three times.
- The `saga` crate keeps the pre-alpha native `temporalio-sdk` behind an
  OFF-by-default `temporal-sdk` feature (ADR-B6-2-004). Default CI MUST NOT
  enable it; any exercise of it MUST be opt-in and non-blocking.
- `b6-2.test.sh` T-002 asserts the scaffold-plan references EXACTLY the `.tmpl`
  tree (no orphan / no dangling). Adding three workflow templates therefore
  REQUIRES registering them in `scaffold-plan.yaml`, or b6-2's harness goes red.
- Image pins already chosen by the archetype: `nats:2.10-alpine`,
  `postgres:17-alpine` (docker-compose.dev.yml.tmpl). CI reuses those exact pins.
- AsyncAPI 3.1.0 validation via `@asyncapi/cli` bundles the official 3.1.0
  schema — the same official-schema check the archetype's `asyncapi:validate`
  task and B.6.2 grounding used.

## Solution

Ship three per-layer workflow templates under
`.forge/templates/archetypes/event-driven-eu/1.0.0/.github/workflows/` and
register them in `scaffold-plan.yaml`:

1. **`forge-events.yml.tmpl`** — gates the `events` + `eventstore` crates (NATS
   JetStream publisher/consumer, Postgres event store). paths-filter on
   `backend/events/**`, `backend/eventstore/**`, `backend/Cargo.*`,
   `shared/protos/**`. Runs `task backend:lint` (workspace Tribune gate) then a
   crate-scoped `cargo build`/`cargo test -p events -p eventstore`, then the
   Forge gates.
2. **`forge-workflows.yml.tmpl`** — gates the `saga` crate (Temporal). paths-filter
   on `backend/saga/**`, `backend/Cargo.*`. Runs `task backend:lint` then
   `cargo build`/`cargo test -p saga` with **default features** (the pre-alpha
   `temporal-sdk` stays OFF), then the Forge gates. A separate opt-in
   `saga-temporal-sdk` job runs `cargo test -p saga --features temporal-sdk`
   ONLY on `workflow_dispatch` — clearly non-blocking (never gates a PR).
3. **`forge-infra.yml.tmpl`** — infra validation. paths-filter on `infra/**`,
   `shared/asyncapi/**`. NATS JetStream config lint
   (`nats-server -c infra/nats/jetstream.conf -t`), AsyncAPI 3.1 contract
   validation (`task asyncapi:validate` → official 3.1.0 schema), Postgres
   migration check (apply `infra/postgres/init-eventstore.sql` against an
   ephemeral `postgres:17-alpine`, twice, to prove idempotent DDL), then the
   Forge gates.

Gated by a new TDD harness `.forge/scripts/tests/b6-5.test.sh` (mirroring
`b6-1`/`b6-2` style), registered in `forge-ci.yml`.

## Scope In

- Three workflow templates under
  `.forge/templates/archetypes/event-driven-eu/1.0.0/.github/workflows/`.
- Registration of those three files in
  `.forge/templates/archetypes/event-driven-eu/scaffold-plan.yaml`.
- `.forge/scripts/tests/b6-5.test.sh` (L1 structural + L2 toolchain-gated render)
  + registration in `forge-ci.yml`.
- CHANGELOG `[Unreleased]` entry.

## Scope Out (Explicit Exclusions)

- **The repo's own `.github/workflows/forge-ci.yml`** — untouched except to
  register the new harness in the matrix.
- **Production Helm CI / deployment pipelines** — B.6.6.
- **A cross-layer integration workflow** (`forge-integration.yml` analogue) —
  not in the plan's B.6.5 line (which names exactly three per-layer workflows);
  the archetype has no frontend/E2E surface in the first cut (ADR-B6-2-003). If
  a future change adds an ops-console, an integration workflow rides that.
- **Promotion candidate→stable** — B.6.7. The archetype stays candidate; these
  templates are validated by rendering via `overlay.sh` directly (mirroring
  b6-2's L2), not through a scaffoldable CLI init.
- **Editing the archetype schema / other archetypes / the constitution.**
- **A dedicated `ci-workflows` standard for event-driven-eu** — the existing
  `.forge/standards/infra/ci-workflows.md` is scoped to `full-stack-monorepo`;
  this brick reuses its conventions by reference without amending it (a shared
  event-driven CI standard, if desired, is a later B.6.3-adjacent change).

## Impact

- **Users**: a project scaffolded from `event-driven-eu` (once promoted, B.6.7)
  gets three ready per-layer CI workflows wired to the archetype's Taskfile.
- **Technical**: net-new `.github/workflows/` subtree in the archetype +
  three lines in `scaffold-plan.yaml` + one harness + one CI-matrix line. No
  change to the backend/infra/shared templates themselves.
- **Dependencies**: B.6.2 (the template tree + Taskfile targets these workflows
  invoke). Reuses `dorny/paths-filter@v3`, `dtolnay/rust-toolchain`,
  `arduino/setup-task@v2`, `actions/setup-node@v4` by reference.
- **Parallel lanes**: B.6.6 (Helm) may also touch `scaffold-plan.yaml`; the only
  overlap is additive list entries, resolved centrally.

## Constitution Compliance (v2.0.0)

- **Article I (TDD)**: RED→GREEN on `b6-5.test.sh` — the harness asserts the
  three templates before they exist (RED), then passes once authored (GREEN).
- **Article II (BDD)**: the user-facing capability (a scaffolded project gets
  per-layer CI) gets Given/When/Then scenarios (`features/`).
- **Article III (Specs Before Code + III.4)**: proposal→specs→design→tasks; the
  NATS `-t` config-test flag, the `@asyncapi/cli validate` official-schema check,
  and the image pins are all grounded in the archetype's own shipped files, not
  asserted from memory.
- **Article VIII.2 (Temporal)**: the workflows respect the activity-only /
  feature-OFF-by-default posture — default CI never compiles the pre-alpha SDK.
- **Article X (Quality)**: every workflow ends in the Forge gates; no
  `continue-on-error: true`; the workspace clippy gate stays `-D warnings`.

## Open Questions (to resolve at specify/design)

- **Q-1** — Workspace vs crate-scoped test split: run `task backend:test`
  (whole workspace) in each workflow, or crate-scoped `cargo test -p`? (→ ADR)
- **Q-2** — Temporal opt-in mechanism: `continue-on-error: true` vs a
  `workflow_dispatch`-gated separate job for the non-blocking `temporal-sdk`
  leg? (→ ADR)
- **Q-3** — Postgres migration check depth: syntax-only vs apply-against-live +
  idempotency re-run? (→ ADR)

---

**Gate**: Proposal created. Next → `/forge:specify b6-5-ci-templates`.
