# Tasks: b6-5-ci-templates

<!-- Status: archived -->
<!-- TDD-ordered (Article I). Tests = b6-5.test.sh assertions (RED before templates, -->
<!-- GREEN after). Each task cites its FR/ADR [Story: FR-...]. -->

## Phase 0: Harness skeleton (RED) ✅

- [x] Author `.forge/scripts/tests/b6-5.test.sh` (mirror b6-1/b6-2 style, source
  `_helpers.sh`, `--level` parse, L1 + toolchain-gated L2). Run it: RED (the
  three workflow templates do not exist yet). [Story: FR-B6-CI-060]

## Phase 1: Workflow templates (GREEN)

- [x] `forge-events.yml.tmpl` — filter(events/eventstore/protos/Cargo.*) →
  rust toolchain + cache + setup-task → `task backend:lint` →
  `cargo build/test -p events -p eventstore` → verify.sh → linter.
  [Story: FR-B6-CI-001/002/003/010/040/041]
- [x] `forge-workflows.yml.tmpl` — filter(saga/Cargo.*) → toolchain + cache +
  setup-task → `task backend:lint` → `cargo build/test -p saga` (default feats)
  → verify.sh → linter; + opt-in `saga-temporal-sdk` job (workflow_dispatch,
  non-blocking). [Story: FR-B6-CI-001/002/003/020/021/040/041]
- [x] `forge-infra.yml.tmpl` — filter(infra/shared-asyncapi) → NATS config-test
  (`nats-server -c … -t`, nats:2.10-alpine) → setup-node + setup-task +
  `task asyncapi:validate` → psql apply init-eventstore.sql ×2
  (postgres:17-alpine) → verify.sh → linter.
  [Story: FR-B6-CI-001/002/003/030/031/032/033/040/041]

## Phase 2: Scaffold-plan registration (GREEN)

- [x] Register the three `.tmpl` files in
  `.forge/templates/archetypes/event-driven-eu/scaffold-plan.yaml` (source /
  target / substitute:true). [Story: FR-B6-CI-050]

## Phase 3: Verify GREEN + no-regression

- [x] `b6-5.test.sh --level 1,2` GREEN. [Story: FR-B6-CI-060]
- [x] `b6-2.test.sh --level 1,2` still GREEN (plan↔tree coverage). [NFR-B6-CI-002]
- [x] `b6-1.test.sh`, `verify.sh`, `constitution-linter.sh` no regression.
  [NFR-B6-CI-002]

## Phase 4: Integration

- [x] Register `b6-5.test.sh` in `.github/workflows/forge-ci.yml` matrix.
  [Story: FR-B6-CI-060]
- [x] CHANGELOG `[Unreleased]` entry.
- [x] BDD `features/b6-5-ci-templates.feature`. [Article II]

## Constitutional Compliance Gate (per phase)
No task requires violating TDD (harness RED→GREEN), bypassing specs (all tasks
cite FR/ADR), or breaking architecture articles. No `[TASK VIOLATION]`.

## Follow-up left OPEN (out of scope — honest disclosure)
- **Promotion candidate→stable** → B.6.7 (the CLI still refuses init; workflows
  are validated by direct overlay render).
- **forge-integration.yml analogue** → rides a later change that adds a
  frontend/ops-console surface (ADR-B6-CI-004).
- **A shared event-driven CI standard** (analogue of ci-workflows.md) → a later
  B.6.3-adjacent change if desired; this brick reuses full-stack conventions by
  reference.
- **Independent review (Article V)**: authored + implemented by a single
  executor; a separate reviewer/maintainer pass is the honest deferred gate.
