# Tasks: b6-3-standards

<!-- Status: archived -->
<!-- Schema: default -->
<!-- Audit: B.6.3 (docs/new-archetypes-plan.md §6.1 — event-driven-eu standards) -->

TDD-ordered (Article I). Deliverable: three `{global,infra}/*.md` pattern standards
(no crate pins) describing the B.6.2 scaffolder + index/REVIEW registration +
harness. Harness authored FIRST.

## Phase 1: RED — failing harness

- [x] **T1.1** Author `.forge/scripts/tests/b6-3.test.sh` (sources `_helpers.sh`).
  L1: each of event-driven/asyncapi-contracts/nats-jetstream.md exists; each has its
  required H2 sections (per design blueprint) + a Constitutional-Compliance section
  + an Out-of-scope note + a schema-mapping note; index.yml has the 3 entries;
  REVIEW.md has the 3 birth entries; **negative grep**: no inline crate pin
  (`async-nats = "<digit>`, `sqlx = "<digit>`, `temporalio-sdk = "<digit>`) in any of
  the three. [Story: FR-B6-STD-001/010/020/030/031/032, NFR-B6-STD-002]
- [x] **T1.2** Run `bash .forge/scripts/tests/b6-3.test.sh --level 1` → **verify RED**
  (no standards yet). [Gate: Article I]

## Phase 2: GREEN — author the standards

- [x] **T2.1** `global/event-driven.md` (FR-B6-STD-001..006) — event envelope &
  versioning, idempotency keys (`Nats-Msg-Id`/append/inbox), saga & reverse-order
  compensation (Temporal activity-only, VIII.2, refs `infra/temporal.md`), process
  manager (variant, not scaffolded), outbox & inbox (inbox shipped; outbox
  recommended, NOT in first cut), projections, EU sovereignty, Constitutional
  Compliance, Out-of-scope. [P]
- [x] **T2.2** `global/asyncapi-contracts.md` (FR-B6-STD-010..014) — AsyncAPI 3.1
  SSoT, versioning discipline, `asyncapi validate`, breaking-change `asyncapi diff`
  (buf-breaking equivalent, LIVE-verified; Taskfile wires validate only — follow-up),
  Constitutional Compliance, Out-of-scope. [P]
- [x] **T2.3** `infra/nats-jetstream.md` (FR-B6-STD-020..024) — clustering & RAFT,
  persistence, consumer groups (durable/pull-push/queue/ack → inbox), EU sovereignty
  (no Kafka SaaS US; Redpanda; B.6.10), Constitutional Compliance, Out-of-scope. [P]
- [x] **T2.4** Add 3 entries to `.forge/standards/index.yml` (id/path/triggers/
  scope/priority). [Story: FR-B6-STD-030]
- [x] **T2.5** Add 3 birth entries to `.forge/standards/REVIEW.md` (2026-07-10).
  [Story: FR-B6-STD-031]
- [x] **T2.6** Run `b6-3.test.sh --level 1` → **verify GREEN**. [Gate: Article I]

## Phase 3: Integration

- [x] **T3.1** Register `b6-3.test.sh` in `.github/workflows/forge-ci.yml` (B.6
  chain, after `b6-2.test.sh`). [Story: FR-B6-STD-032]
- [x] **T3.2** Run `validate-standards-yaml.sh` → no-op/GREEN (no new yaml).

## Phase 4: Quality

- [x] **T4.1** `verify.sh` + `constitution-linter.sh` → no regression. [NFR-B6-STD-004]
- [x] **T4.2** `git diff --name-only` → additive: 3 new `.md` + harness + change
  artifacts; edits limited to index.yml (append), REVIEW.md (append), CI matrix. No
  schema/constitution/existing-standard/template touched. [NFR-B6-STD-001]
- [x] **T4.3** REFACTOR; re-run b6-3 harness → GREEN.
- [x] **T4.4** Archive (state → archived; timeline).

## Constitution Gate (per task)
- TDD: harness RED (T1.2) before docs GREEN (T2.6). ✓
- Additive; every task cites its FR/NFR/ADR. ✓ No [TASK VIOLATION].

## Parallelization
- T2.1–T2.3 are `[P]` (three independent files); author together, then T2.4/T2.5
  registration, then the single GREEN gate (T2.6).
