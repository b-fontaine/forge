# Specs: b6-5-ci-templates

<!-- Specified: 2026-07-10 -->
<!-- Namespace: FR-B6-CI-* / NFR-B6-CI-* / ADR-B6-CI-* -->
<!-- Source: proposal.md + .forge/templates/archetypes/full-stack-monorepo/.github/workflows/* -->
<!--         (structural precedent, B.1.9) + event-driven-eu/1.0.0/Taskfile.yml.tmpl (B.6.2) -->

**Constitution** : v2.0.0 (no bump — additive; consumes §VIII.2 Temporal +
Article X quality gates as ratified).

**Format** : ADDED requirements only (new per-layer CI workflow templates +
scaffold-plan registration + harness). This file's requirements append to
`.forge/specs/event-driven-eu.md` on archive.

**Ground truth (re-read 2026-07-10, Article III.4)**:
- The four `full-stack-monorepo` workflow templates are the structural contract:
  `name` / `on: {pull_request,push} branches:[main]` / `concurrency.group:
  forge-<layer>-<project-name>-${{ github.ref }}` / `permissions: contents:
  read` / a `filter` job (`dorny/paths-filter@v3`) whose output gates a `build`
  job / step order ending in `verify.sh` then `constitution-linter.sh`.
- The archetype Taskfile targets CI invokes: `backend:lint`, `backend:build`,
  `backend:test`, `asyncapi:validate`.
- The `saga` crate's `temporal-sdk` feature is OFF by default (ADR-B6-2-004);
  `cargo test -p saga` (default) never compiles the pre-alpha SDK.
- `nats-server -c <file> -t` tests a NATS config and exits (the config-lint
  idiom); `nats:2.10-alpine` and `postgres:17-alpine` are the archetype's
  pinned images (docker-compose.dev.yml.tmpl).
- `overlay.sh` substitutes only `<project-name>` / `<reverse-domain>` /
  `<root-module>`; GitHub `${{ ... }}` expressions are NOT placeholders and
  MUST survive render. The repo's render-clean convention (b6-2.test.sh
  T-L2-001) checks for surviving `.tmpl` suffix and surviving
  `<(project-name|reverse-domain|root-module)>` — NOT `{{...}}`.
- Adding `.tmpl` files couples to `b6-2.test.sh` T-002 (plan↔tree coverage):
  the three new files MUST be registered in `scaffold-plan.yaml`.

---

## Resolved scope decisions (from proposal open questions)

- **Q-1 (test split) → RESOLVED: crate-scoped `cargo test -p`.** The backend is
  one workspace; running `task backend:test` (whole workspace) in each of the
  three workflows would triple the compute for a scoped change. Each workflow
  builds/tests ONLY its surface crates (`-p events -p eventstore`, `-p saga`).
  The workspace-wide **lint** gate (`task backend:lint`) is still invoked per
  workflow — clippy `-D warnings` is a cheap, workspace-consistent quality gate
  and MUST stay workspace-scoped (a change to `events` must not silently break
  `saga`'s clippy). See `ADR-B6-CI-001`.
- **Q-2 (Temporal opt-in) → RESOLVED: `workflow_dispatch`-gated separate job, no
  `continue-on-error`.** The non-blocking `--features temporal-sdk` leg is a
  distinct `saga-temporal-sdk` job gated `if: github.event_name ==
  'workflow_dispatch'` — it never runs on `pull_request`/`push`, so it can never
  gate a PR, and it avoids the `continue-on-error: true` pattern the
  `ci-workflows.md` failure-semantics section forbids in reference workflows.
  See `ADR-B6-CI-002`.
- **Q-3 (Postgres check) → RESOLVED: apply against a live ephemeral Postgres,
  twice.** The migration check spins up a `postgres:17-alpine` service and runs
  `psql -v ON_ERROR_STOP=1 -f infra/postgres/init-eventstore.sql` twice: the
  first proves valid DDL against a real server; the second proves the migration
  is idempotent (all statements use `IF NOT EXISTS`). See `ADR-B6-CI-003`.

---

## ADDED Requirements

### Workflow template tree

- **FR-B6-CI-001** — Three workflow templates MUST exist under
  `.forge/templates/archetypes/event-driven-eu/1.0.0/.github/workflows/`:
  `forge-events.yml.tmpl`, `forge-workflows.yml.tmpl`, `forge-infra.yml.tmpl`.
  Each MUST be valid YAML after `overlay.sh` render and MUST carry a
  documentary header comment naming its audit item (B.6.5) and change surface.
- **FR-B6-CI-002** — Each workflow MUST declare, mirroring the
  `full-stack-monorepo` convention: `name: forge-<layer>`; `on:` with
  `pull_request` and `push` to `branches: [main]`; a `concurrency.group` of the
  form `forge-<layer>-<project-name>-${{ github.ref }}` with
  `cancel-in-progress: true`; and `permissions: contents: read`.
- **FR-B6-CI-003** — Each workflow MUST gate its heavy job behind a `filter`
  job using `dorny/paths-filter@v3`, so the workflow ALWAYS runs (satisfying
  branch-protection required-status) but the build/validate job skips with
  SUCCESS when its paths are untouched. Path scoping:
  - `forge-events`: `backend/events/**`, `backend/eventstore/**`,
    `backend/Cargo.toml`, `backend/Cargo.lock`, `backend/rust-toolchain.toml`,
    `shared/protos/**`.
  - `forge-workflows`: `backend/saga/**`, `backend/Cargo.toml`,
    `backend/Cargo.lock`, `backend/rust-toolchain.toml`.
  - `forge-infra`: `infra/**`, `shared/asyncapi/**`.

### forge-events (events + eventstore crates)

- **FR-B6-CI-010** — `forge-events.yml.tmpl` MUST, in its gated job: install the
  Rust toolchain (`dtolnay/rust-toolchain@stable` with `rustfmt, clippy`), cache
  cargo (`~/.cargo/registry`, `~/.cargo/git`, `backend/target` keyed on
  `backend/Cargo.lock`), install go-task (`arduino/setup-task@v2`), run
  `task backend:lint` (the workspace clippy `-D warnings` + `fmt --check` gate),
  then run crate-scoped `cargo build -p events -p eventstore` and
  `cargo test -p events -p eventstore` (working-directory `backend`), then the
  Forge gates.

### forge-workflows (saga crate — Temporal)

- **FR-B6-CI-020** — `forge-workflows.yml.tmpl` MUST, in its gated job: install
  the Rust toolchain + cache + go-task as FR-B6-CI-010, run `task backend:lint`,
  then crate-scoped `cargo build -p saga` and `cargo test -p saga` with
  **default features only** (the `temporal-sdk` feature stays OFF — the pre-alpha
  native SDK is never compiled by the blocking gate), then the Forge gates.
- **FR-B6-CI-021** — A separate opt-in `saga-temporal-sdk` job MUST run
  `cargo test -p saga --features temporal-sdk` gated `if: github.event_name ==
  'workflow_dispatch'`, clearly commented NON-BLOCKING (pre-alpha; Public
  Preview). It MUST NOT run on `pull_request` or `push`. The workflow's `on:`
  MUST therefore include `workflow_dispatch`.

### forge-infra (NATS / AsyncAPI / Postgres)

- **FR-B6-CI-030** — `forge-infra.yml.tmpl` MUST validate the NATS JetStream
  config by running the NATS server config-test:
  `nats-server -c infra/nats/jetstream.conf -t` (via the pinned
  `nats:2.10-alpine` image), which parses the config and exits non-zero on error.
- **FR-B6-CI-031** — `forge-infra.yml.tmpl` MUST validate the AsyncAPI 3.1
  contract against the official schema by installing Node
  (`actions/setup-node@v4`) + go-task and running `task asyncapi:validate`
  (`npx -y @asyncapi/cli validate asyncapi.yaml`, which bundles the official
  AsyncAPI 3.1.0 schema).
- **FR-B6-CI-032** — `forge-infra.yml.tmpl` MUST validate the Postgres migration
  by applying `infra/postgres/init-eventstore.sql` against an ephemeral
  `postgres:17-alpine` service with `psql -v ON_ERROR_STOP=1`, applied TWICE to
  prove idempotency.
- **FR-B6-CI-033** — `forge-infra.yml.tmpl` MUST end its job with the Forge gates
  (`verify.sh` then `constitution-linter.sh`).

### Gate ordering & failure semantics

- **FR-B6-CI-040** — In every workflow, the Forge gates
  (`bash .forge/scripts/verify.sh` then
  `bash .forge/scripts/constitution-linter.sh`) MUST be the LAST two steps of
  the gated job, in that order (mirroring `ci-workflows.md` gate ordering).
- **FR-B6-CI-041** — No workflow MAY use `continue-on-error: true` and no
  workflow MAY use `if: always()` (there is no integration/teardown workflow
  here). Failures MUST surface.

### Scaffold-plan registration

- **FR-B6-CI-050** — The three workflow templates MUST be registered in
  `.forge/templates/archetypes/event-driven-eu/scaffold-plan.yaml` `templates:`
  list, each with `source: 1.0.0/.github/workflows/<file>.tmpl`,
  `target: .github/workflows/<file>.yml`, `substitute: true` (the concurrency
  group carries `<project-name>`). Registration MUST keep `b6-2.test.sh` T-002
  (plan↔tree, no orphan/dangling) GREEN.

### Harness

- **FR-B6-CI-060** — `.forge/scripts/tests/b6-5.test.sh` MUST be added (mirroring
  `b6-1`/`b6-2` style, sourcing `_helpers.sh`) and registered in
  `forge-ci.yml`. L1 (hermetic, grep/structure): the three files exist + parse
  as YAML with the right `name:`/`on:`; each references the right Task targets +
  crate scoping; paths-filter scoping is correct; the temporal-sdk leg is opt-in
  and non-blocking; the Forge gates are present and last; the three files are
  registered in `scaffold-plan.yaml`; no `continue-on-error`. L2 (toolchain-gated,
  python3+PyYAML+overlay.sh): render the plan and assert the three workflows
  render to `.github/workflows/*.yml` with no surviving `.tmpl`/`<placeholder>`
  and parse as valid YAML.

## Non-Functional

- **NFR-B6-CI-001** — Additive: no edit to `event-driven-eu/1.0.0.yaml` (stays
  candidate/scaffoldable:false), the constitution, other archetypes' templates,
  or the backend/infra/shared templates. Existing-file edits confined to:
  `scaffold-plan.yaml` (additive list entries), `forge-ci.yml` (one matrix
  line), and `CHANGELOG.md`.
- **NFR-B6-CI-002** — No regression: `b6-2.test.sh` (L1 + L2), `b6-1.test.sh`,
  `verify.sh`, `constitution-linter.sh`, and `delivery.test.sh` (full-stack
  scope, unaffected) all stay GREEN.
- **NFR-B6-CI-003** — Tool pins: all third-party actions pinned
  (`dorny/paths-filter@v3`, `dtolnay/rust-toolchain@stable`,
  `arduino/setup-task@v2`, `actions/setup-node@v4`, `actions/checkout@v4`,
  `actions/cache@v4`); container images pinned to the archetype's existing pins
  (`nats:2.10-alpine`, `postgres:17-alpine`); no `:latest`.
- **NFR-B6-CI-004** — Render determinism: the three workflows render byte-stable
  across two `overlay.sh` runs (implied by b6-2 T-L2-001 NFR; b6-5 need not
  re-assert stability but MUST NOT introduce nondeterministic content).

## BDD Acceptance Criteria

```gherkin
Feature: event-driven-eu per-layer CI templates

  Scenario: the three per-layer workflow templates exist and render clean
    Given the event-driven-eu/1.0.0 template tree
    When overlay.sh renders the scaffold-plan into an empty target
    Then .github/workflows/ contains forge-events.yml, forge-workflows.yml and forge-infra.yml
    And none retains a .tmpl suffix or an unsubstituted <placeholder>
    And each parses as valid YAML

  Scenario: each workflow invokes the archetype's Task targets
    Given the rendered workflows
    When their steps are inspected
    Then forge-events and forge-workflows run "task backend:lint"
    And forge-infra runs "task asyncapi:validate"

  Scenario: the default saga gate does not compile the pre-alpha Temporal SDK
    Given forge-workflows.yml
    When it runs on a pull_request
    Then the blocking saga job runs "cargo test -p saga" with default features
    And the "--features temporal-sdk" job runs only on workflow_dispatch

  Scenario: the three templates are registered in the scaffold-plan
    Given scaffold-plan.yaml
    When its templates list is inspected
    Then each of the three workflow .tmpl files is present with substitute: true
    And b6-2.test.sh T-002 (plan↔tree coverage) stays green
```

## ADRs (proposed — to ratify at design)

- **ADR-B6-CI-001** — Crate-scoped `cargo test -p` per workflow; workspace-wide
  `task backend:lint` as the shared clippy/fmt gate.
- **ADR-B6-CI-002** — Non-blocking `temporal-sdk` leg as a `workflow_dispatch`-only
  job (no `continue-on-error`).
- **ADR-B6-CI-003** — Postgres migration check applies the SQL twice against a
  live `postgres:17-alpine` (validity + idempotency).
- **ADR-B6-CI-004** — No `forge-integration.yml` analogue in this cut (plan names
  exactly three per-layer workflows; no frontend/E2E surface yet).

## Anti-Hallucination Pass

- The NATS `-t` config-test flag, the `@asyncapi/cli validate` official-schema
  behaviour, and the image pins are grounded in the archetype's own shipped
  files (Taskfile, docker-compose.dev.yml, asyncapi.yaml) — not asserted from
  memory. GitHub Action pins reuse those already used by the full-stack
  reference workflows.
- `[NEEDS CLARIFICATION]`: none blocking.

---

**Gate**: Specs written. Next: `/forge:design b6-5-ci-templates`.
