# Specifications: b6-3-standards

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.6.3 (docs/new-archetypes-plan.md §6.1 — event-driven-eu standards) -->

**Namespace** : `FR-B6-STD-*` / `NFR-B6-STD-*` / `ADR-B6-STD-*`.
**Constitution** : v2.0.0, unchanged. Additive — three `{global,infra}/*.md` pattern
standards + index/REVIEW registration. Ships NO version pins (b6-2 research shipped
them in B.6.2's `Cargo.toml.tmpl`).
**Governing articles** : III.1/III.2, III.4 (anti-hallucination), IV (additive),
VIII.2 (Temporal, no ad-hoc saga).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | §6.1 B.6.3 — `standards/global/event-driven.md` + `standards/global/asyncapi-contracts.md` + `standards/infra/nats-jetstream.md` (effort M) |
| **Schema fwd-refs (observed)** | `event-driven-eu/1.0.0.yaml` components `nats-jetstream`/`asyncapi`/`event-patterns` carry `delivered_by: B.6.3` |
| **Scaffolder (observed, B.6.2)** | `backend/{events,eventstore,saga}/src/*.rs.tmpl`, `shared/asyncapi/asyncapi.yaml.tmpl` (AsyncAPI 3.1.0), `infra/nats/jetstream.conf.tmpl` (dev), `infra/postgres/init-eventstore.sql.tmpl` (events + inbox tables) |
| **AsyncAPI tooling (verified LIVE 2026-07-10)** | `@asyncapi/cli` 6.0.2 → `asyncapi validate` + `asyncapi diff OLD NEW -t breaking\|non-breaking\|unclassified\|all --no-error`; `@asyncapi/diff` 0.5.0 (breaking-change lib); `@asyncapi/parser` 3.6.0 |
| **Pin-home precedent (observed)** | b6-2 research pinned `async-nats 0.49.1`/`sqlx 0.9.0`/`temporalio-sdk 0.5.0` in B.6.2 `Cargo.toml.tmpl`; standards stay pin-free (transport.yaml/b8-6) |
| **Existing machinery (observed)** | `infra/temporal.md` (VIII.2 workflow API), `event_specifics.eu_sovereignty` (no Kafka SaaS US), `persistence.yaml` (postgres-17), `observability.yaml` |
| **index.yml / REVIEW pattern (observed)** | `.md` entry = id/path/triggers/scope/priority; REVIEW birth entry per standard |
| **Downstream** | B.6.4 (Hermes-Async references these paths), B.6.5 (CI wiring `asyncapi diff`), B.6.6 (Helm cluster), B.6.10 (forbidden Kafka SaaS) |
| **Release target** | maintainer-set ([Unreleased]) |

---

## ADDED Requirements

### Functional

#### Cluster 1 — event-driven.md (FR-B6-STD-001 → 006)

##### FR-B6-STD-001 — file + required sections
`global/event-driven.md` MUST exist with H2 sections covering: schema mapping;
event envelope & versioning; idempotency keys; saga & compensation; process
manager; outbox & inbox; Constitutional Compliance; Out-of-scope.

##### FR-B6-STD-002 — event versioning grounded in the scaffold
MUST document the `EventEnvelope.event_version` field and the
`events.v<version>.<EventType>` subject scheme (`backend/events/src/envelope.rs`),
and the `(event_type, event_version)` deserializer-selection rule. No fabricated
field names.

##### FR-B6-STD-003 — idempotency keys grounded in the scaffold
MUST document the idempotency key as (a) the JetStream `Nats-Msg-Id` publish-dedup
header (`backend/events/src/publisher.rs`), (b) the event-store append uniqueness key
(`ON CONFLICT (idempotency_key) DO NOTHING`, `backend/eventstore/src/store.rs` +
`infra/postgres/init-eventstore.sql`), and (c) the inbox dedup key
(`backend/events/src/consumer.rs`).

##### FR-B6-STD-004 — saga = Temporal activity-only (VIII.2)
MUST state that ad-hoc saga in application code is forbidden (Article VIII.2 —
Temporal), describe the reverse-order compensation coordinator
(`backend/saga/src/compensation.rs`) and the activity-only worker surface
(`backend/saga/src/activity.rs`, `temporal.rs` feature-gated OFF), and REFERENCE
`infra/temporal.md` for the workflow/worker API rather than restating it.

##### FR-B6-STD-005 — outbox/inbox honesty (III.4)
MUST document the inbox pattern as implemented (`InboxDedup` + `inbox` table) AND
the outbox pattern as `recommended` per `event_specifics.outbox_inbox_pattern`,
explicitly noting that the B.6.2 first cut ships NO transactional outbox (it relies
on idempotent append + `Nats-Msg-Id` dedup) — an honest follow-up, not a claim it
exists.

##### FR-B6-STD-006 — projections + process manager
MUST document deterministic, replayable projections
(`backend/eventstore/src/projection.rs`) and the process-manager pattern as a
documented variant (a stateful coordinator reacting to events), noting it is not
scaffolded in the first cut.

#### Cluster 2 — asyncapi-contracts.md (FR-B6-STD-010 → 014)

##### FR-B6-STD-010 — file + required sections
`global/asyncapi-contracts.md` MUST exist with H2: schema mapping; AsyncAPI 3.1 as
single source of truth; versioning discipline; contract validation; breaking-change
detection; Constitutional Compliance; Out-of-scope.

##### FR-B6-STD-011 — AsyncAPI 3.1.0 grounded in the scaffold
MUST document the `asyncapi: 3.1.0` contract (`shared/asyncapi/asyncapi.yaml`), its
channels/operations/messages shape, and that subjects/headers mirror the Rust
envelope (`Nats-Msg-Id`, `events.v<n>.<Type>`).

##### FR-B6-STD-012 — versioning discipline
MUST distinguish three version axes: the AsyncAPI document `info.version` (semver),
the per-event `event_version` (envelope + subject), and additive-vs-breaking message
schema evolution; MUST require a new `event_version` (new subject) for breaking
payload changes rather than mutating a published message shape.

##### FR-B6-STD-013 — contract validation (verified LIVE)
MUST document `asyncapi validate` (`@asyncapi/cli`, wired as `task
asyncapi:validate` → `npx -y @asyncapi/cli validate asyncapi.yaml`) with
`--fail-severity` for CI. Version-verified LIVE; no tool version pinned inline.

##### FR-B6-STD-014 — breaking-change detection (buf-breaking equivalent, LIVE)
MUST document `asyncapi diff OLD NEW` (`-t breaking|non-breaking|unclassified|all`,
`--no-error`, `-o overrides`) as the AsyncAPI analogue of `buf breaking`, backed by
`@asyncapi/diff`, and MUST note that the B.6.2 `Taskfile` wires only `validate` —
wiring `diff` into the Taskfile/CI is a Hermes-Async (B.6.4) / CI (B.6.5) follow-up
(honest gap, III.4).

#### Cluster 3 — nats-jetstream.md (FR-B6-STD-020 → 024)

##### FR-B6-STD-020 — file + required sections
`infra/nats-jetstream.md` MUST exist with H2: schema mapping; clustering & RAFT;
persistence; consumer groups; EU sovereignty; Constitutional Compliance;
Out-of-scope.

##### FR-B6-STD-021 — clustering & RAFT
MUST document the production topology (odd-sized cluster, ≥3 nodes; RAFT-based
metadata + stream replication; quorum/`replicas`) as the production counterpart to
the single-node dev `jetstream.conf`, and MUST state this is delivered as a Helm
chart in B.6.6 (not this doc).

##### FR-B6-STD-022 — persistence
MUST document JetStream stream persistence: `file` storage, `max_bytes`/`max_age`/
`max_msgs` retention limits, `replicas` for HA, and the relationship to the dev
`store_dir` / `max_file_store` in `jetstream.conf`.

##### FR-B6-STD-023 — consumer groups
MUST document durable consumers, pull vs push, queue (work-queue) groups for
horizontal scaling, ack policy + redelivery (at-least-once → why the inbox dedup
exists), tying redelivery back to `event-driven.md`'s inbox pattern.

##### FR-B6-STD-024 — EU sovereignty
MUST state the no-Kafka-SaaS-US rule (`event_specifics.eu_sovereignty`: Confluent
Cloud forbidden; NATS JetStream / Redpanda acceptable, EU-deployable) and REFERENCE
the B.6.10 enforcement rule (Janus) rather than restating a rule catalogue.

#### Cluster 4 — registration & harness (FR-B6-STD-030 → 032)

##### FR-B6-STD-030 — index.yml entries
`.forge/standards/index.yml` MUST gain one entry per standard (id/path/triggers/
scope/priority), triggers chosen for JIT injection (e.g. event-driven, saga, outbox,
inbox, idempotency, event-versioning; asyncapi, event-contracts, contract-validation;
nats, jetstream, raft, consumer-group, hermes-async).

##### FR-B6-STD-031 — REVIEW.md birth entries
`.forge/standards/REVIEW.md` MUST gain an append-only birth entry per standard
(dated 2026-07-10).

##### FR-B6-STD-032 — harness
`.forge/scripts/tests/b6-3.test.sh` MUST assert each standard exists + carries its
required H2 sections + a Constitutional-Compliance section + an Out-of-scope note +
a schema-mapping note; index.yml has the 3 entries; REVIEW.md has the 3 births; AND
that no standard inlines a forbidden version-pin pattern (negative grep for
`async-nats = "<digit>`, `sqlx = "<digit>`, `temporalio-sdk = "<digit>`). Registered
in `forge-ci.yml`.

### Non-Functional

##### NFR-B6-STD-001 — additive
No existing standard/schema/constitution/CLI/template edited; only new `.md` +
index/REVIEW appends + new harness + CI registration.

##### NFR-B6-STD-002 — no pins anywhere
No crate version pin in any of the three standards (FR-B6-STD-032). Pins live only in
B.6.2's `Cargo.toml.tmpl` (b6-2 verify-then-pin research). Tool versions
(`@asyncapi/cli` etc.) are stated as LIVE-verified facts, not inlined as pins.

##### NFR-B6-STD-003 — grounded or deferred (III.4)
Every technical claim is grounded in a scaffolded file path OR a LIVE-verified tool
fact OR flagged as a deferred follow-up (outbox / process-manager / `asyncapi diff`
wiring / Helm cluster). No fabricated API surface.

##### NFR-B6-STD-004 — gates green
`verify.sh`, `constitution-linter.sh`, `validate-standards-yaml.sh` (no new yaml, so
no-op), and the harness suite stay GREEN.

## ADRs (seeded — resolved at /forge:design)

- **ADR-B6-STD-001** — `.md` pattern docs, zero pins (transport.yaml/b8-6 + b6-2 research).
- **ADR-B6-STD-002** — describe the scaffolder, flag gaps; don't invent (III.4).
- **ADR-B6-STD-003** — reference existing machinery (`infra/temporal.md`,
  `event_specifics`, B.6.10), don't duplicate.

## Acceptance Criteria (impl)

1. Three `{global,infra}/*.md` exist with all required H2 sections + Constitutional
   Compliance + Out-of-scope + schema-mapping.
2. No crate version pin in any standard (negative-grep harness test passes).
3. index.yml has 3 new entries; REVIEW.md has 3 birth entries.
4. `b6-3.test.sh` GREEN; registered in forge-ci.yml.
5. verify.sh + constitution-linter.sh + validate-standards-yaml.sh no regression.
6. Schema/constitution/existing-standards untouched.
