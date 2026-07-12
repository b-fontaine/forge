# Proposal: b6-3-standards

<!-- Created: 2026-07-10 -->
<!-- Schema: default -->
<!-- Audit: B.6.3 (docs/new-archetypes-plan.md §6.1 — event-driven-eu standards) -->

## Problem

B.6.1 shipped `.forge/schemas/event-driven-eu/1.0.0.yaml` and B.6.2 shipped the
scaffolder `.forge/templates/archetypes/event-driven-eu/1.0.0/`. Three of the
schema's components reference standards as `delivered_by: B.6.3` that **do not
exist yet**:

- `nats-jetstream` (role `event-backbone`) → `infra/nats-jetstream.md`
- `asyncapi` (role `event-contracts`) → `global/asyncapi-contracts.md`
- `event-patterns` (role `saga-outbox-inbox`) → `global/event-driven.md`

Until they land, the schema's references are forward-pointers with no target, and
the scaffolded Rust crates (`backend/{events,eventstore,saga}`), the AsyncAPI 3.1
contract (`shared/asyncapi/`), and the dev NATS config (`infra/nats/`) carry inline
comments deferring their clustering / versioning / pattern rules to standards that
are not written. This change ships those three pattern standards.

**Ground truth (re-read 2026-07-10, Article III.4):**

- **Two standard families** in `.forge/standards/`: versioned `*.yaml`
  (frontmatter-validated by `j7-validate-standards-yaml`, 12-month review, may pin)
  and `global|infra/*.md` human-readable pattern docs. Plan §6.1 B.6.3 names all
  three as `standards/{global,infra}/*.md` — **pattern docs, not pin-bearing yaml**
  (mirrors the B.7.3 `standards/global/*.md` decision).
- **The pin-home precedent is unambiguous** and already applied to this archetype:
  the b6-2 verify-then-pin research (`.forge/research/b6-2-verify-then-pin.md`)
  resolved `async-nats 0.49.1` / `sqlx 0.9.0` / `temporalio-sdk 0.5.0` LIVE and
  those pins already ship in B.6.2's `backend/**/Cargo.toml.tmpl`. Pins live with
  the consuming template, NOT in a standard (transport.yaml/b8-6 precedent). ⇒ these
  standards pin NOTHING.
- **What the B.6.2 scaffolder actually implements** (re-read, real — these standards
  must DESCRIBE this, not invent):
  - `backend/events/src/envelope.rs` — `EventEnvelope` (id/stream_id/event_type/
    `event_version`/`idempotency_key`/payload/occurred_at); `subject()` →
    `events.v<version>.<EventType>`.
  - `backend/events/src/publisher.rs` — `EventPublisher` port + `JetStreamPublisher`
    setting `Nats-Msg-Id` = idempotency key (JetStream server-side dedup).
  - `backend/events/src/consumer.rs` — `InboxDedup` (inbox pattern), backed in prod
    by the `inbox` table (`infra/postgres/init-eventstore.sql`).
  - `backend/eventstore/src/{store,projection}.rs` — append-only `EventStore`
    (idempotent on `idempotency_key`, `ON CONFLICT DO NOTHING`) + replayable
    `Projection`.
  - `backend/saga/src/{compensation,activity,temporal}.rs` — reverse-order
    compensation coordinator + activity-only markers + feature-gated (OFF) native
    Temporal SDK re-export.
  - `shared/asyncapi/asyncapi.yaml` — AsyncAPI **3.1.0**; `task asyncapi:validate`
    → `npx -y @asyncapi/cli validate asyncapi.yaml`.
  - `infra/nats/jetstream.conf` — single-node LOCAL DEV JetStream; comments defer
    production clustering/RAFT/persistence/consumer-groups to B.6.3 + the Helm chart
    (B.6.6).
- **First-cut GAPS to flag honestly, not paper over** (Article III.4):
  - **No transactional OUTBOX**: the scaffolder ships the INBOX (`consumer.rs` +
    `inbox` table) and relies on idempotent append + `Nats-Msg-Id` dedup on the
    publish side. The schema marks `outbox_inbox_pattern: recommended`; the outbox
    relay/table is NOT in the B.6.2 first cut. `event-driven.md` documents the
    pattern and flags this as a follow-up.
  - **No process-manager code**: the saga coordinator + Temporal activities are the
    orchestration surface; "process manager" is documented as a pattern variant.
  - **`asyncapi diff` not wired**: the B.6.2 `Taskfile` wires `validate` only, not
    the breaking-change gate. `asyncapi-contracts.md` documents `asyncapi diff` and
    flags wiring it into the Taskfile/CI as Hermes-Async (B.6.4) / CI (B.6.5) work.

## Solution

Author three pattern standards (no version pins), register them in `index.yml`, add
`REVIEW.md` birth entries, and ship a harness asserting their presence + required
structure + no-inline-pin.

1. **`global/event-driven.md`** — event envelope & versioning; idempotency keys;
   saga & reverse-order compensation (Temporal activity-only, Article VIII.2);
   process manager; outbox & inbox patterns; projections/read models; EU
   sovereignty; Constitutional Compliance; Out-of-scope. References the scaffolded
   crates by path.
2. **`global/asyncapi-contracts.md`** — AsyncAPI 3.1 as the event single source of
   truth; versioning discipline (spec `info.version`, envelope `event_version`,
   subject `events.v<n>.<Type>`); contract validation (`asyncapi validate`);
   **breaking-change detection via `asyncapi diff`** (the buf-breaking equivalent —
   verified LIVE, see below); Constitutional Compliance; Out-of-scope.
3. **`infra/nats-jetstream.md`** — clustering & RAFT consensus; persistence (streams,
   file store, retention, replicas); consumer groups (durable pull/push, queue
   groups, ack policy); EU sovereignty (no Kafka SaaS US, Redpanda acceptable);
   Constitutional Compliance; Out-of-scope.

**AsyncAPI tooling — verified LIVE 2026-07-10 (Article III.4, "don't assume"):**
`@asyncapi/cli` **6.0.2** provides `asyncapi validate [SPEC]` (with
`--fail-severity error|warn|info|hint`) and `asyncapi diff OLD NEW -t
breaking|non-breaking|unclassified|all [--no-error] [-o overrides] -f json|yaml|md`,
backed by the `@asyncapi/diff` **0.5.0** library ("compares two AsyncAPI Documents …
pointing out … breaking changes") and `@asyncapi/parser` **3.6.0**. `asyncapi diff`
IS the AsyncAPI analogue of `buf breaking`: it classifies changes and exits non-zero
on breaking ones unless `--no-error`. NO version of any tool is pinned in the
standards (npx-resolved at run time; a concrete pin, if wanted, is CI/Taskfile
territory — B.6.4/B.6.5).

Decisions for `/forge:design` (ADRs); leanings stated:

- **ADR-B6-STD-001 — `.md` pattern docs, zero version pins.** Lean: per the
  transport.yaml/b8-6 precedent + b6-2 research, the `async-nats`/`sqlx`/
  `temporalio-sdk` pins already ride with B.6.2's `Cargo.toml.tmpl`. Rejected:
  shipping a pin-bearing `.yaml` (orphan pins under j7 + 12-month review).
- **ADR-B6-STD-002 — describe the scaffolder, flag gaps; don't invent.** Lean: each
  standard references the real scaffolded files and marks the outbox / process-
  manager / `asyncapi diff`-wiring gaps as follow-ups (B.6.4/B.6.5/B.6.6), never as
  shipped.
- **ADR-B6-STD-003 — couple to existing machinery, don't duplicate.** Lean:
  `event-driven.md` references `infra/temporal.md` (Article VIII.2) for the workflow
  API rather than restating it; EU-sovereignty references `event_specifics` + the
  B.6.10 forbidden-Kafka-SaaS rule rather than pre-empting it.

## Scope In

- `.forge/standards/global/event-driven.md` (new).
- `.forge/standards/global/asyncapi-contracts.md` (new).
- `.forge/standards/infra/nats-jetstream.md` (new).
- `.forge/standards/index.yml` — three entries.
- `.forge/standards/REVIEW.md` — three birth entries.
- `.forge/scripts/tests/b6-3.test.sh` — presence + required-section + no-pin harness; CI.
- Change artifacts.

## Scope Out (Explicit Exclusions)

- **Version pins** (`async-nats` / `sqlx` / `temporalio-sdk` / `temporalio-client`)
  — already delivered by B.6.2 `Cargo.toml.tmpl` (b6-2 verify-then-pin research).
- **A pin-bearing `.yaml` standard** — not created (ADR-B6-STD-001).
- **Templates / scaffolder** — B.6.2 (already merged).
- **AsyncAPI bindings/codegen + idempotency-key placement automation** — Hermes-Async
  (B.6.4).
- **CI pipeline templates** (wiring `asyncapi diff` into a per-layer workflow) — B.6.5.
- **NATS/Temporal Helm charts** (the production cluster this standard describes) — B.6.6.
- **Forbidden Kafka-SaaS-US enforcement rule (Janus)** — B.6.10.
- **Schema promotion** — schema stays candidate/scaffoldable:false until B.6.7.

## Impact

- **Users**: B.6 archetype authors gain the ratified event-driven / AsyncAPI / NATS
  JetStream patterns the scaffolder implements. No runtime/CLI change; no existing
  archetype affected. The three `.md` resolve the b6-1 schema forward-references.
- **Dependencies**: B.6.1 (schema referencing these), B.6.2 (scaffolder the
  standards describe). Unblocks B.6.4 (Hermes-Async references these paths), B.6.5,
  B.6.6.

## Constitution Compliance

- **III.1/III.2 (Specs before code)**: propose+specify first; standards authored at
  impl (harness RED before the docs).
- **III.4 (Anti-Hallucination)**: AsyncAPI CLI verified LIVE (npm 2026-07-10); every
  pattern claim grounded in a scaffolded file path; the outbox / process-manager /
  `asyncapi diff`-wiring gaps recorded, not glossed; no pin fabricated.
- **IV (Delta-based)**: additive — three new `.md` + index/REVIEW appends; no
  existing standard/schema/constitution edited.
- **VIII.2**: `event-driven.md` encodes "no ad-hoc saga in application code —
  Temporal" and defers the workflow API to `infra/temporal.md`.
- **XII (Governance)**: no amendment; `.md` standards are not Article-XII
  structural-exception yaml.

## Open Questions (seed)

- **Q-001** — do the three `.md` carry a `linter_rule:`-style enforcement hook, or
  pure guidance? (Lean: pure guidance now; the forbidden-Kafka-SaaS enforcement is
  B.6.10 / Janus. Resolve at design.)
- **Q-002** — `event-patterns` (schema component name) vs `event-driven.md` (standard
  filename): confirm the mapping resolves by intent. (Lean: keep both names; note the
  mapping in the standard header. Resolve at design.)
