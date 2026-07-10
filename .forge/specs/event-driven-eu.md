# Spec: event-driven-eu

<!-- Audit: B.6.1 (b6-1-schema) — event-driven-eu/1.0.0 archetype scaffold schema. -->
<!-- This file accumulates the archived requirements for the event-driven-eu     -->
<!-- archetype (plan §6.1, T7). Source change: `.forge/changes/b6-1-schema/`      -->
<!-- (archived 2026-07-10). First brick of the B.6 chain; B.6.2 (scaffolder),     -->
<!-- B.6.3 (standards), B.6.4 (Hermes-Async), etc. APPEND to this file as they    -->
<!-- archive.                                                                     -->

**Namespace** : `FR-B6-1-*` / `NFR-B6-1-*` / `ADR-B6-1-*` (+ `FR-B6-2-*` from B.6.2,
`FR-B6-CI-*` from B.6.5).

**Constitution** : v2.0.0 (no bump — additive; consumes §VIII.1 Envoy/Connect +
§VIII.2 Temporal as-is; the `saga-orchestration` phase materialises §VIII.2's "no
ad-hoc saga implementations in application code").

**Position** : T7, first of the B.6 incremental chain (sibling of the B.7
`ai-native-rag` chain). Ships the `event-driven-eu / 1.0.0` **candidate** archetype
scaffold schema — the shared contract every downstream B.6 brick validates against.

## B.6.1 — archetype scaffold schema (archived 2026-07-10)

The schema `.forge/schemas/event-driven-eu/1.0.0.yaml` MUST:

- Use the archetype-scaffold-schema shape (FR-B6-1-001): `name`/`version`/`stage`/
  `scaffoldable`/`description`/`tdd_enforced`/`bdd_required_for_user_facing`/
  `coverage_threshold`/`layers`/`fr_id_prefix_cross_layer`/`cross_layer`/`phases`.
- Declare `name: event-driven-eu`, `version: "1.0.0"`, `stage: candidate`,
  `scaffoldable: false` (FR-B6-1-002/003; b8-3b candidate⇒scaffoldable:false).
- Carry `tdd_enforced: true`, `bdd_required_for_user_facing: true`,
  `coverage_threshold: 80` (FR-B6-1-004) + a candidate header block documenting the
  promotion trigger (B.6.7) + additivity (FR-B6-1-005).
- Declare the backend/frontend/infra layer triple, each with
  id/path/fr_id_prefix/primary_agent (FR-B6-1-010; the frontend hosts a **deferred**
  ops-console surface — ADR-B6-1-004, the archetype is backend-centric).
- Inline the tdd-rust phases (NOT via `extends`; ADR-B6-1-001) + the two B.6.1
  additions: `event-design` (AsyncAPI 3.1 contracts before design, FR-B6-1-022) and
  `saga-orchestration` (Temporal saga design gate, FR-B6-1-023, VIII.2).
- Carry an `event_specifics` block (event_versioning / idempotency_keys /
  saga_compensation / outbox_inbox_pattern / eu_sovereignty; FR-B6-1-024).
- Declare the component SET reference-only (FR-B6-1-030/031): temporal→orchestration.yaml,
  postgres→persistence.yaml, connect-rpc→transport.yaml, zitadel→identity.yaml,
  observability→observability.yaml; and mark `nats-jetstream`/`asyncapi`/`event-patterns`
  `delivered_by: B.6.3` with no inline pin (FR-B6-1-032, ADR-B6-1-003).

**ADRs**: ADR-B6-1-001 (phases inlined) · ADR-B6-1-002 (candidate; promotion→B.6.7)
· ADR-B6-1-003 (components reference-only; nats/event/asyncapi deferred to B.6.3) ·
ADR-B6-1-004 (backend/frontend/infra triple; frontend = deferred ops surface).

**Verification (archived state)**: `b6-1.test.sh` 18/18 L1 GREEN;
`validate-foundations.sh` → `FR-GL-001-versioned:event-driven-eu/1.0.0.yaml` PASS;
`verify.sh` + `constitution-linter.sh` no regression;
`forge init --archetype event-driven-eu` refuses cleanly (exit 2 pre-registration;
exit 3 once B.6.2 registers it while the schema stays candidate).

## B.6.2 — scaffolder backbone (archived 2026-07-10)

Ships `.forge/templates/archetypes/event-driven-eu/1.0.0/` (backend + infra +
shared) + `scaffold-plan.yaml` + the gated `bin/forge-init-event-driven-eu.sh`
wrapper + the `dispatch-table.yml` registration (`status: candidate`, `since: 0.6.0`).

- **Backend** (Rust workspace, FR-B6-2-010..014): `events` (NATS JetStream —
  versioned/idempotent `EventEnvelope`, `EventPublisher` port + `JetStreamPublisher`
  dedup via `Nats-Msg-Id`, `InboxDedup`), `eventstore` (append-only Postgres
  `PgEventStore` + `InMemoryEventStore` + `Projection`), `saga` (Temporal
  activity-only: `Activity` marker traits + `Saga`/`SagaStep` compensation
  coordinator; native SDK behind OFF-by-default `temporal-sdk` feature),
  `bin-server` (axum entrypoint + DI). Verify-then-pin LIVE (FR-B6-2-040):
  `async-nats 0.49.1`, `sqlx 0.9.0`, `temporalio-sdk 0.5.0`, `temporalio-client
  0.5.0` — pins ONLY in `backend/Cargo.toml` (FR-B6-2-041).
- **Infra** (FR-B6-2-020): dev NATS JetStream config, Postgres event-store schema
  (`init-eventstore.sql`), optional local-dev Temporal overlay,
  `docker-compose.dev.yml` (NATS + Postgres).
- **Event contracts/transport** (FR-B6-2-030/031): AsyncAPI **3.1.0** contract
  (`shared/asyncapi/`, validated against the official schema) + `shared/protos/`
  (buf SSoT; Connect consumed by reference).
- **CLI** (FR-B6-2-050..052): `forge init --archetype event-driven-eu` refuses
  exit 3 + writes nothing (schema stays candidate; promotion → B.6.7).

**ADRs**: ADR-B6-2-001 (promotion→B.6.7) · ADR-B6-2-002 (Connect by reference) ·
ADR-B6-2-003 (no frontend first cut) · ADR-B6-2-004 (Temporal activity-only +
feature-gated) · ADR-B6-2-005 (pins only in Cargo.toml).

**Verification (archived state)**: rendered `cargo test --workspace` 16/0 +
`clippy -D warnings` + `fmt --check` clean; `b6-2.test.sh` L1 10/10, L1,2 13/13
(render-clean + rendered cargo check + gated wrapper render); built CLI
`forge init --archetype event-driven-eu` → exit 3, no scaffold dir; `cd cli &&
npm test` 88/89 (the 1 failure is the pre-existing ai-native-rag scaffold fixture,
B.7 scope, reproduced on the b6-2-reverted baseline).

## B.6.5 — per-layer CI templates (archived 2026-07-10)

Ships three GitHub Actions workflow templates under
`.forge/templates/archetypes/event-driven-eu/1.0.0/.github/workflows/`, scaffolded
into an adopter's `.github/workflows/` and registered in `scaffold-plan.yaml`
(`substitute: true`; FR-B6-CI-050). Mirrors the `full-stack-monorepo` per-layer
convention, adapted to the event-driven layer decomposition.

- **`forge-events.yml`** (FR-B6-CI-010): gates the `events` + `eventstore` crates.
  `dorny/paths-filter@v3` on `backend/events/**` / `backend/eventstore/**` /
  `backend/Cargo.*` / `shared/protos/**` → `task backend:lint` (workspace clippy
  `-D warnings` + `fmt --check`) → crate-scoped `cargo build/test -p events -p
  eventstore` → Forge gates.
- **`forge-workflows.yml`** (FR-B6-CI-020/021): gates the `saga` crate. Blocking
  job runs `task backend:lint` + `cargo build/test -p saga` with **default
  features** (the pre-alpha `temporal-sdk` stays OFF). A separate
  `saga-temporal-sdk` job runs `cargo test -p saga --features temporal-sdk` ONLY
  on `workflow_dispatch` — clearly NON-BLOCKING, no `continue-on-error`
  (ADR-B6-CI-002; honours ADR-B6-2-004 + §VIII.2).
- **`forge-infra.yml`** (FR-B6-CI-030/031/032): NATS JetStream config lint
  (`nats-server -c infra/nats/jetstream.conf -t`), AsyncAPI 3.1 validation
  (`task asyncapi:validate` → official schema), Postgres migration check
  (`init-eventstore.sql` applied twice against `postgres:17-alpine` — validity +
  idempotency) → Forge gates.
- **Cross-cutting** (FR-B6-CI-002/040/041, NFR-B6-CI-003): each workflow has
  `concurrency` + `permissions: contents: read`, ends in `verify.sh` →
  `constitution-linter.sh`, uses no `continue-on-error`/`if: always()`, and pins
  all actions + the archetype's `nats:2.10-alpine` / `postgres:17-alpine` images.

**ADRs**: ADR-B6-CI-001 (crate-scoped tests + workspace lint) · ADR-B6-CI-002
(non-blocking temporal-sdk via `workflow_dispatch`) · ADR-B6-CI-003 (Postgres
migration applied twice) · ADR-B6-CI-004 (no `forge-integration` analogue this cut).

**Verification (archived state)**: `b6-5.test.sh` L1 9/9, L1,2 10/10 (render-clean
via `overlay.sh`, valid YAML); `b6-2.test.sh` L1,2 13/13 (plan↔tree coverage stays
green after the three new `.tmpl` entries); `b6-1.test.sh` 19/19; `verify.sh`
518/0 PASS; `constitution-linter.sh` OVERALL PASS. Additive — the schema stays
candidate/`scaffoldable:false` (promotion → B.6.7).
