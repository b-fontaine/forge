# Specs: b6-2-scaffolder

<!-- Specified: 2026-07-10 -->
<!-- Namespace: FR-B6-2-* / NFR-B6-2-* / ADR-B6-2-* -->
<!-- Source: proposal.md + .forge/schemas/event-driven-eu/1.0.0.yaml (B.6.1) -->
<!--         + templates/archetypes/ai-native-rag/1.0.0 (structural precedent, B.7.2) -->

**Constitution** : v2.0.0 (no bump — additive; consumes §VIII.1 Envoy/Connect +
§VIII.2 Temporal + persistence/observability/identity standards as ratified).

**Format** : ADDED requirements only (new template tree + scaffolder body + dispatch
registration). This file's requirements append to `.forge/specs/event-driven-eu.md`
on archive.

**Ground truth (re-read 2026-07-10, Article III.4)**:
- Canonical archetype templates live at
  `.forge/templates/archetypes/<archetype>/<version>/`; the bundled mirror is
  `cli/assets/.forge/templates/...` (`npm run bundle`; `cli/assets` is gitignored).
- The wrapper renders via `overlay.sh` (init.sh is flagship-hardcoded), the
  ADR-B7-2-007 precedent. overlay.sh substitutes `<project-name>` /
  `<reverse-domain>` / `<root-module>`.
- **`candidate ⇒ scaffoldable:false` is invariant** (b8-3b). Promotion to stable is
  gated on B.6.7 — NOT this brick (ADR-B6-2-001).
- Registering a candidate couples to the CLI e2e (`cli/src/cli.ts` help + snapshot;
  `archetypes-smoke.test.ts` candidate partition — activated for the first time
  here). Verified live.

---

## Resolved scope decisions (from proposal open questions)

- **Q-1 (Temporal depth) → RESOLVED: activity-only, feature-gated re-export.** The
  native SDK is Public Preview / pre-alpha; the saga crate ships pure-Rust
  activity-only logic (marker traits + a compensation coordinator) always, and the
  SDK behind an OFF-by-default `temporal-sdk` feature (a documented re-export seam,
  no fabricated workflow API). See `ADR-B6-2-004`.
- **Q-2 (tonic/Connect) → RESOLVED: consume by reference.** Connect/gRPC is
  consumed via `shared/protos` + `buf.gen.yaml` + transport.yaml (no inline
  tonic/prost pin in the backend workspace), mirroring ai-native-rag. See
  `ADR-B6-2-002`.
- **Q-3 (frontend) → RESOLVED: no frontend in the first cut** (ADR-B6-1-004). The
  schema's frontend layer is a declared-but-deferred ops surface. See `ADR-B6-2-003`.

---

## ADDED Requirements

### Template tree & scaffold plan

- **FR-B6-2-001** — A versioned template tree MUST exist at
  `.forge/templates/archetypes/event-driven-eu/1.0.0/` with the layer roots
  `backend/`, `infra/`, `shared/asyncapi/`, `shared/protos/`, plus root files
  (README/CLAUDE/.gitignore/.env.example/Taskfile/docker-compose.dev.yml). Every
  authored file carries the `.tmpl` suffix `overlay.sh` strips on render. A
  `shared/asyncapi/asyncapi.yaml` MUST declare `asyncapi: 3.1.0` (verified the
  latest released 3.x spec, 2026-07-10).
- **FR-B6-2-002** — A `scaffold-plan.yaml` MUST drive the render, schema-shaped like
  the ai-native-rag plan (archetype/version/official_scaffolders/templates/
  post_steps), referencing EXACTLY the `1.0.0/` tree (no orphan, no dangling).
- **FR-B6-2-003** — Rendering the plan into an empty target via `overlay.sh` MUST
  produce a tree with no `.tmpl` suffix and no unsubstituted `<placeholder>`
  remaining, byte-stable across two renders (determinism).

### Backend layer (`FR-BE-`, Vulcan/Rust)

- **FR-B6-2-010** — A Cargo workspace MUST be scaffolded (`backend/Cargo.toml.tmpl`
  + four per-crate manifests: `events`, `eventstore`, `saga`, `bin-server`);
  `cargo check`/`cargo test` clean on the rendered tree (L2 fixture,
  toolchain-gated skip when cargo absent).
- **FR-B6-2-011** — An `events` crate MUST scaffold the NATS JetStream backbone: a
  versioned/idempotent event envelope, an `EventPublisher` port + a JetStream impl
  that sets `Nats-Msg-Id` = idempotency key (server-side dedup), and an inbox-dedup
  consumer guard (inbox pattern). API verified LIVE against async-nats 0.49.1.
- **FR-B6-2-012** — An `eventstore` crate MUST scaffold an append-only Postgres
  event store (sqlx runtime queries; idempotent append `ON CONFLICT (idempotency_key)
  DO NOTHING`) + an in-memory impl (tests/dev) + a read-model projection trait.
- **FR-B6-2-013** — A `saga` crate MUST scaffold Temporal **activity-only**
  orchestration: activity marker traits + a deterministic compensation coordinator
  (forward + reverse-order undo). The native `temporalio-sdk`/`temporalio-client`
  MUST be behind an OFF-by-default `temporal-sdk` feature (pre-alpha caveat;
  Article VIII.2). No `#[workflow]` definitions are scaffolded.
- **FR-B6-2-014** — A `bin-server` crate MUST scaffold an axum entrypoint doing DI
  wiring only (health probe + a startup self-check that exercises the event-store
  port), consuming the substrate (Connect/Temporal/observability) by reference.

### Infra layer (`FR-IN-`, Atlas)

- **FR-B6-2-020** — Infra manifests MUST be scaffolded: a MINIMAL dev NATS
  JetStream config (`infra/nats/jetstream.conf`), a Postgres event-store schema
  (`infra/postgres/init-eventstore.sql`, matching `eventstore`), and an OPTIONAL
  local-dev Temporal overlay (`infra/temporal/docker-compose.temporal.yml`). The
  base `docker-compose.dev.yml` MUST bring up NATS JetStream + Postgres. No
  production Helm chart (B.6.6) and no new infra component beyond these.

### Event contracts & transport

- **FR-B6-2-030** — A `shared/asyncapi/asyncapi.yaml` AsyncAPI 3.1 contract MUST be
  scaffolded (channels/messages over NATS JetStream; the event SSoT), validating
  against the official 3.1.0 schema.
- **FR-B6-2-031** — A `shared/protos/` buf module (`buf.yaml`, `buf.gen.yaml`, a
  seed proto) MUST be scaffolded per transport.yaml (Connect SSoT). Connect/gRPC is
  consumed BY REFERENCE (no inline tonic/prost pin in the backend workspace).

### Verify-then-pin (Article III.4)

- **FR-B6-2-040** — Each external Rust dependency MUST be verified LIVE
  (`cargo add`/crates.io), recorded in `.forge/research/b6-2-verify-then-pin.md`:
  `async-nats`, `sqlx`, `temporalio-sdk`, `temporalio-client`. The plan's
  `temporalio-sdk = 0.4.0` note is superseded by LIVE `0.5.0`.
- **FR-B6-2-041** — All version pins MUST live in the rendered
  `backend/Cargo.toml.tmpl` (the consuming template), not in any standard.

### Scaffolder wrapper, dispatch & CLI coupling

- **FR-B6-2-050** — `event-driven-eu` MUST be registered in
  `.forge/scaffolding/dispatch-table.yml` (`status: candidate`, scaffolder
  `bin/forge-init-event-driven-eu.sh`, `since: 0.6.0`), and a **gated**
  `bin/forge-init-event-driven-eu.sh` MUST exist (stable ABI:
  `--target`/`--project-name`/`--reverse-domain`/`--force`), rendering via
  `overlay.sh` when scaffoldable and refusing (exit 3, zero writes) while candidate.
- **FR-B6-2-051** — Because the schema stays `candidate`, `forge init --archetype
  event-driven-eu` through the CLI MUST refuse with **exit 3** and create NO
  scaffold dir. The wrapper's real render path is validated by a fixture with the
  harness-only `FORGE_EDE_FORCE_SCAFFOLD=1` override.
- **FR-B6-2-052** — CLI coupling MUST stay green: `cli/src/cli.ts` `--archetype`
  help string names `event-driven-eu`; the help snapshot is regenerated;
  `cd cli && npm test` passes with `event-driven-eu` in the `archetypes-smoke`
  refusing-candidate partition (this brick activates that block for the first time).

### Harness

- **FR-B6-2-060** — `.forge/scripts/tests/b6-2.test.sh` MUST be added + registered
  in `forge-ci.yml`, with L1 (structure / plan-coverage / no-stray-placeholder /
  pins-only-in-Cargo / wrapper-refuses / standards-conformance / asyncapi-3.1 /
  schema-still-candidate / dispatch-registered) and L2 (toolchain-gated render +
  `cargo check` on the rendered backend + gated wrapper render). The ≥35-test
  promotion suite is B.6.7.

## Non-Functional

- **NFR-B6-2-001** — Additive: no edit to `event-driven-eu/1.0.0.yaml` (stays
  candidate/scaffoldable:false), the constitution, or other archetypes' templates.
  Existing-file edits confined to: dispatch table, the new wrapper, `cli/src/cli.ts`
  help + its snapshot, the CI matrix, and the b6-2 harness.
- **NFR-B6-2-002** — No regression: `verify.sh`, `constitution-linter.sh`,
  `validate-foundations.sh`, `b6-1.test.sh`, `b7-1.test.sh`, `b5.test.sh` (modulo
  the pre-existing CLI-not-built L2 skips), and `cd cli && npm test` all stay GREEN.
- **NFR-B6-2-003** — Rendered backend crates ship `#[cfg(test)]` tests (TDD-ready),
  not bare stubs (Article I). No `unwrap()`/`expect()`/`panic!` in `src/`.
- **NFR-B6-2-004** — Determinism: render of a fixed plan into a fixed target is
  byte-stable across runs.

## BDD Acceptance Criteria

```gherkin
Feature: event-driven-eu scaffold backbone (candidate, pre-promotion)

  Scenario: rendering the scaffold-plan produces a clean tree
    Given the event-driven-eu/1.0.0 template tree and scaffold-plan
    When overlay.sh renders the plan into an empty target directory
    Then the target contains backend/, infra/, shared/asyncapi/, shared/protos/
    And no file retains a .tmpl suffix
    And no unsubstituted <placeholder> remains

  Scenario: the rendered backend builds and tests
    Given a freshly rendered event-driven-eu target
    When cargo test runs on the backend workspace
    Then it completes without error
    And the events, eventstore, saga and bin-server crates ship tests

  Scenario: the CLI still refuses init for the candidate archetype
    Given the schema is stage:candidate / scaffoldable:false
    When a user runs forge init --archetype event-driven-eu
    Then the CLI refuses with exit 3 and writes nothing

  Scenario: a saga compensates completed steps in reverse on failure
    Given a saga with steps a, b, then a failing step c
    When the saga runs
    Then a and b execute, c fails, and b then a are compensated in reverse order
```

## ADRs (proposed — to ratify at design)

- **ADR-B6-2-001** — Promotion deferred to B.6.7 (b8-3b invariant); validate via
  direct overlay.sh fixture, not the CLI scaffoldable gate.
- **ADR-B6-2-002** — Connect/tonic consumed by reference via protos + transport.yaml
  (no inline backend pin), mirroring ai-native-rag B.7.2.
- **ADR-B6-2-003** — No frontend in the first cut (ADR-B6-1-004); the schema's
  frontend layer is a declared-but-deferred ops surface.
- **ADR-B6-2-004** — Temporal activity-only + feature-gated (`temporal-sdk`, OFF by
  default) re-export; no fabricated workflow API (pre-alpha caveat).
- **ADR-B6-2-005** — Pins live only in `backend/Cargo.toml.tmpl`; standards stay
  pin-free.

## Anti-Hallucination Pass

- Every external version is verify-then-pin LIVE (FR-B6-2-040), pinned only in the
  consuming template (FR-B6-2-041). AsyncAPI 3.1.0's existence was confirmed live
  (official schema HTTP 200 + title "AsyncAPI 3.1.0 schema"), not asserted from
  memory. async-nats/sqlx APIs were confirmed by compile-probe.
- `[NEEDS CLARIFICATION]`: none blocking.

---

**Gate**: Specs written. Next: `/forge:design b6-2-scaffolder`.
