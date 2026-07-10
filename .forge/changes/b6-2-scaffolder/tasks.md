# Tasks: b6-2-scaffolder

<!-- Status: archived -->
<!-- TDD-ordered (Article I). Tests = b6-2.test.sh assertions (RED before templates, -->
<!-- GREEN after) AND rendered-code #[cfg(test)] validated by L2 cargo test/check. -->

## Phase 0: Verify-then-pin + harness skeleton ✅ (2026-07-10)

- [x] Verify-then-pin LIVE (`cargo add --dry-run`, cargo 1.97.0): `async-nats = 0.49.1`,
  `sqlx = 0.9.0`, `temporalio-sdk = 0.5.0`, `temporalio-client = 0.5.0` — recorded in
  `.forge/research/b6-2-verify-then-pin.md`. Plan's `temporalio-sdk = 0.4.0` superseded
  by LIVE 0.5.0. [Story: FR-B6-2-040]
- [x] API grounding by compile-probe (async-nats JetStream publish_with_headers +
  Nats-Msg-Id; sqlx runtime query/try_get) — no fabrication. [Article III.4]
- [x] AsyncAPI 3.1.0 existence verified live (official schema HTTP 200 + title). [III.4]

## Phase 1: Backend workspace (Rust, Vulcan — all TDD, developed + tested in a scratch workspace) ✅

- [x] `backend/Cargo.toml` workspace (events/eventstore/saga/bin-server) + pin ledger
  (pins ONLY here — FR-B6-2-041). `cargo check --workspace` clean. [FR-B6-2-010]
- [x] `events`: `EventEnvelope` (versioned/idempotent), `EventPublisher` port +
  `JetStreamPublisher` (Nats-Msg-Id dedup), `InboxDedup`. 5 tests. [FR-B6-2-011]
- [x] `eventstore`: `EventStore` port + `PgEventStore` (sqlx runtime, idempotent
  append) + `InMemoryEventStore` + `Projection`. 4 tests. [FR-B6-2-012]
- [x] `saga`: `Activity` marker traits + `Saga`/`SagaStep` compensation coordinator
  (reverse-order undo) + `temporal.rs` behind OFF-by-default `temporal-sdk` feature.
  3 tests + feature-on build proven. [FR-B6-2-013, ADR-B6-2-004]
- [x] `bin-server`: axum entrypoint + `wiring` (DI only, startup self-check). 4 tests.
  [FR-B6-2-014]
- [x] Gate: `cargo test --workspace` 16/0, `cargo clippy --all-targets -- -D warnings
  -D clippy::unwrap_used -D clippy::expect_used` clean, `cargo fmt --check` clean,
  `RUSTDOCFLAGS=-D missing-docs cargo doc` clean. No unwrap/expect/panic in src.
  [NFR-B6-2-003, Tribune]

## Phase 2: Infra + shared + root templates ✅

- [x] Root: README/CLAUDE/.gitignore/.env.example/Taskfile/docker-compose.dev.yml
  (NATS JetStream + Postgres + backend placeholder). [FR-B6-2-001/020]
- [x] `infra/nats/jetstream.conf` (minimal dev JetStream) + `infra/postgres/init-eventstore.sql`
  (append-only events + inbox, matches PgEventStore) + `infra/temporal/` (OPTIONAL
  dev overlay). [FR-B6-2-020]
- [x] `shared/asyncapi/asyncapi.yaml` AsyncAPI **3.1.0** contract — validated against
  the official 3.1.0 JSON schema (jsonschema PASS). [FR-B6-2-030]
- [x] `shared/protos/` (buf.yaml + buf.gen.yaml + seed events.proto) — Connect by
  reference (no inline tonic pin). [FR-B6-2-031, ADR-B6-2-002]
- [x] No frontend rendered (ADR-B6-2-003 / ADR-B6-1-004 — deferred).

## Phase 3: Scaffold-plan + wrapper + dispatch ✅

- [x] `scaffold-plan.yaml` auto-generated to match the tree EXACTLY (40 entries, no
  orphan/dangling; substitute auto-detected). [FR-B6-2-002]
- [x] `bin/forge-init-event-driven-eu.sh` gated wrapper: refuses exit 3 + zero writes
  while candidate; renders via overlay.sh under FORGE_EDE_FORCE_SCAFFOLD=1. Verified
  direct (0 files on refusal; clean gated render). [FR-B6-2-050/051]
- [x] `dispatch-table.yml` entry (`status: candidate`, `since: 0.6.0`). [FR-B6-2-050]

## Phase 4: CLI coupling + harness + CI ✅

- [x] `cli/src/cli.ts` `--archetype` help string names event-driven-eu; help snapshot
  regenerated (`vitest -u`, 6/6). [FR-B6-2-052]
- [x] Built + bundled CLI: `forge init --archetype event-driven-eu` → exit 3 + no
  scaffold dir (verified). `cd cli && npm test` → event-driven-eu candidate refusal
  test GREEN; 88/89 pass (the 1 failure is the PRE-EXISTING ai-native-rag scaffold
  `.forge/constitution.md`, B.7 scope — see follow-up below). [FR-B6-2-051/052]
- [x] `b6-2.test.sh` L1 10 + L2 3, registered in `forge-ci.yml` (`--level 1`; L2
  cargo-check stays local — the harness job has no rust). Full run: L1 10/10, L1,2
  13/13 (render-clean + rendered cargo check + gated wrapper render). [FR-B6-2-060]

## Phase 5: No-regression ✅

- [x] `verify.sh` PASS, `constitution-linter.sh` OVERALL PASS, `validate-foundations.sh`
  PASS (event-driven-eu versioned-schema sibling PASS), `b6-1.test.sh` 18/0,
  `b5.test.sh` (modulo pre-existing CLI-not-built L2 skips). [NFR-B6-2-002]

## Constitutional Compliance Gate (per phase)
No task requires violating TDD (every rendered module is RED→GREEN), bypassing specs
(all tasks cite FR/ADR), or breaking architecture articles. No `[TASK VIOLATION]`.

## Follow-up left OPEN (later B.6 bricks / out of scope — honest disclosure)
- **Promotion candidate→stable/scaffoldable + ≥35-test snapshot harness** → B.6.7.
- **Framework-asset copy at scaffold time**: this wrapper (like ai-native-rag's)
  renders via overlay.sh ONLY — it does NOT copy the base framework `.forge/` assets
  the way init.sh does. When B.6.7 promotes event-driven-eu + adds a cli-trust
  scaffold fixture, it must decide whether the wrapper copies framework assets
  (mirroring init.sh Step 1) — the SAME gap the pre-existing ai-native-rag fixture
  failure surfaces (spawned as a separate task).
- **Standards** event-driven.md / asyncapi-contracts.md / nats-jetstream.md → B.6.3.
- **Hermes-Async (B.6.4), CI pipeline templates (B.6.5), Helm NATS/Temporal cluster
  (B.6.6), example project (B.6.8), compliance hooks (B.6.9), Kafka-SaaS interdiction
  list (B.6.10)** → later bricks.
- **Real Temporal worker wiring** (behind `temporal-sdk`): the crates are proven to
  build; wiring the actual activity worker/client from the pinned crate docs is an
  adopter/later step (the SDK is pre-alpha).
- **Frontend ops console** → a later change (ADR-B6-1-004).
- **Independent review (Article V)**: authored+implemented by a single executor in
  one session; a separate reviewer pass is the honest deferred gate.
