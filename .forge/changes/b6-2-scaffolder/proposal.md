# Proposal: b6-2-scaffolder

<!-- Created: 2026-07-10 -->
<!-- Schema: default -->
<!-- Audit: B.6.2 (docs/new-archetypes-plan.md §6.1 — event-driven-eu scaffolder, full) -->

## Problem

B.6.1 (`b6-1-schema`, archived 2026-07-10) shipped
`.forge/schemas/event-driven-eu/1.0.0.yaml` (`stage: candidate` /
`scaffoldable: false`) — the archetype scaffold schema — but the archetype is
**inert**: it is not registered in the CLI dispatch table, there are no templates
(`templates/archetypes/event-driven-eu/` does not exist), and there is no
scaffolder body. Nothing downstream (standards B.6.3, Hermes-Async B.6.4, CI
pipelines, Helm charts, example, promotion harness) can proceed until a scaffold
backbone exists.

This brick ships that backbone in one change (mirroring the sibling B.7.2
`b7-2-scaffolder`): register the archetype + a **gated** wrapper, ship the
`templates/archetypes/event-driven-eu/1.0.0/*` tree + the scaffold-plan + the
**verify-then-pin** of the Rust crates, and prove the rendered backend builds.

**Ground truth (re-read 2026-07-10, Article III.4):**

- `templates/archetypes/event-driven-eu/1.0.0/` — **absent**. The ai-native-rag
  archetype (`templates/archetypes/ai-native-rag/1.0.0/`) + `full-stack-monorepo`
  are the structural precedent.
- `init.sh` is hardcoded to `full-stack-monorepo` (flutter/buf/5×cargo-new) and
  cannot render a second archetype — the wrapper must render via `overlay.sh`
  directly (the ADR-B7-2-007 precedent). `overlay.sh` substitutes `<project-name>`
  / `<reverse-domain>` / `<root-module>`.
- **`candidate ⇒ scaffoldable:false` is invariant** (b8-3b). Promotion to `stable`
  CANNOT happen here — it rides B.6.7 (the ≥35-test snapshot harness), mirroring
  B.7.6 / B.8.14-C2. The CLI keeps refusing `forge init --archetype event-driven-eu`
  (exit 3) until then; the backbone is validated by a fixture driving `overlay.sh`
  directly.
- **Registering a candidate couples to the CLI e2e** (the B.7.2a lesson, re-read
  live): `cli/src/cli.ts` `--archetype` help string + its golden snapshot
  (`cli/test/e2e/__snapshots__/help/init.snap.txt`) must name the new archetype;
  `archetypes-smoke.test.ts` partitions `status: candidate` into the refusing set
  (exit 3 + no dir) — and this brick **activates that candidate block for the first
  time** (ai-native-rag is now `status: stable`).
- **Verify-then-pin candidates, confirmed LIVE 2026-07-10** (`cargo add --dry-run`,
  cargo 1.97.0): `async-nats = 0.49.1`, `sqlx = 0.9.0`, `temporalio-sdk = 0.5.0`,
  `temporalio-client = 0.5.0`. The plan's `temporalio-sdk = 0.4.0` note is
  superseded by LIVE `0.5.0` (the same drift discipline as the B.7 `rmcp` case).
  Pinned in the rendered `backend/Cargo.toml.tmpl`, never in a standard.

## Solution

1. **Backend templates** (`templates/archetypes/event-driven-eu/1.0.0/backend/`,
   Rust/Vulcan): a Cargo workspace with four crates —
   - `events` — NATS JetStream (async-nats): versioned/idempotent `EventEnvelope`,
     `EventPublisher` port + `JetStreamPublisher` (dedup via `Nats-Msg-Id`),
     `InboxDedup` (inbox pattern).
   - `eventstore` — append-only Postgres store (sqlx runtime queries) +
     `InMemoryEventStore` + read-model `Projection`s.
   - `saga` — Temporal **activity-only** saga: `Activity` marker traits + a
     deterministic compensation coordinator. The pre-alpha native SDK
     (`temporalio-sdk`/`-client`) is behind an OFF-by-default `temporal-sdk`
     feature (Article VIII.2 + the pre-alpha caveat).
   - `bin-server` — axum entrypoint + DI wiring only.
2. **Infra + shared templates**: a MINIMAL dev NATS JetStream overlay
   (`infra/nats/`), a Postgres event-store schema/migration
   (`infra/postgres/init-eventstore.sql`), an OPTIONAL local-dev Temporal overlay
   (`infra/temporal/`), a `shared/asyncapi/` starter AsyncAPI **3.1.0** contract,
   and `shared/protos/` (Connect SSoT + buf codegen). The production NATS JetStream
   Helm chart + Temporal cluster are B.6.6 (NOT here); a frontend ops console is
   deferred (ADR-B6-1-004).
3. **Verify-then-pin**: `cargo add` LIVE for `async-nats` / `sqlx` /
   `temporalio-sdk` / `temporalio-client`; pinned in `backend/Cargo.toml.tmpl`;
   recorded in `.forge/research/b6-2-verify-then-pin.md`.
4. **Scaffolder wrapper + dispatch**: register `event-driven-eu` in
   `dispatch-table.yml` (`status: candidate`) + a **gated** `bin/forge-init-event-driven-eu.sh`
   (refuses exit 3 while candidate; renders via overlay.sh when scaffoldable). Keep
   the CLI e2e green (help string + snapshot + smoke candidate partition).

## Scope In

- `templates/archetypes/event-driven-eu/1.0.0/{backend,infra,shared}/*` tree +
  `scaffold-plan.yaml`.
- Verify-then-pin LIVE of `async-nats`/`sqlx`/`temporalio-sdk`/`temporalio-client`,
  pinned in the rendered `backend/Cargo.toml.tmpl`.
- `dispatch-table.yml` entry (candidate) + gated `bin/forge-init-event-driven-eu.sh`.
- CLI coupling: `cli/src/cli.ts` help string + regenerated help snapshot.
- `.forge/scripts/tests/b6-2.test.sh` (L1 + toolchain-gated L2) + `forge-ci.yml`.
- Scaffold-time validation proving the rendered backend `cargo check`/`cargo test`.

## Scope Out (Explicit Exclusions)

- **Candidate → stable / scaffoldable:true promotion** — gated on B.6.7 (b8-3b
  invariant). The CLI stays refusing exit 3 after this brick.
- **Standards** `event-driven.md` / `asyncapi-contracts.md` / `nats-jetstream.md` —
  B.6.3. Referenced by the schema/templates; not created here.
- **Agent Hermes-Async (K.1 / B.6.4)**, **CI pipeline templates (B.6.5)**,
  **production Helm NATS/Temporal cluster (B.6.6)**, **example project (B.6.8,
  `examples/forge-eda-example/`)**, **compliance hooks (B.6.9)**, **Kafka-SaaS
  interdiction rule list (B.6.10)** — later bricks/lanes.
- **Frontend ops console** — deferred (ADR-B6-1-004). No frontend rendered in the
  first cut.
- **Full promotion harness** `b6.test.sh ≥35` + snapshot tarball — B.6.7.

## Impact

- **Users**: adopters still cannot `init` to a *stable* event-driven-eu after this
  brick (candidate), but the backbone becomes reviewable/testable and renders via
  the gated wrapper. No impact on existing archetypes.
- **Technical**: net-new `templates/archetypes/event-driven-eu/1.0.0/` tree
  (largest surface of the B.6 chain); existing-file edits confined to the
  dispatch table, the new wrapper, the CLI help string + snapshot, the CI matrix,
  and the b6 harness.
- **Dependencies**: B.6.1 (schema). Reuses the B.8 substrate (Connect/transport,
  Postgres/persistence, observability, identity) + B8O (Temporal) by reference.

## Constitution Compliance (v2.0.0)

- **Article I (TDD)**: RED→GREEN on the harness + rendered-code `#[cfg(test)]`
  tests (16 unit tests across the four crates).
- **Article II (BDD)**: the user-facing capability (rendering a building
  event-driven project) gets Given/When/Then scenarios (`features/`).
- **Article III (Specs Before Code + III.4)**: proposal→specs→design→tasks; every
  external version is verify-then-pin LIVE (async-nats/sqlx/temporalio pins + the
  AsyncAPI 3.1.0 spec existence were all confirmed live, not asserted from memory).
- **Article VII (Rust)**: hexagonal; typed errors (thiserror/anyhow); `bin-server`
  is DI wiring only; no `unwrap`/`expect`/`panic!` in `src/`.
- **Article VIII.2 (Temporal)**: saga is Temporal activity-only; no ad-hoc saga —
  the compensation coordinator is the deterministic core a Temporal activity chain
  drives.
- **Article IX.4 (tracing)**: `tracing` on the request path.

## Open Questions (to resolve at specify/design)

- **Q-1** — Temporal SDK integration depth: real feature-gated worker wiring vs
  reference-only re-export, given the pre-alpha workflow API (→ ADR at design).
- **Q-2** — tonic/Connect: inline pin in backend vs consume-by-reference via
  protos + transport.yaml (mirror ai-native-rag) (→ ADR at design).
- **Q-3** — frontend layer: the schema declares one but this archetype is
  backend-centric — confirm no frontend renders in the first cut (→ ADR).

---

**Gate**: Proposal created. Next → `/forge:specify b6-2-scaffolder`.
