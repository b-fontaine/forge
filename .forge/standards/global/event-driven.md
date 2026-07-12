# Standard — Event-driven patterns

<!-- Audit: B.6.3 (b6-3-standards) — event-driven-eu archetype. -->
<!-- Schema mapping: documents the `event-patterns` component of -->
<!-- `.forge/schemas/event-driven-eu/1.0.0.yaml` (delivered_by: B.6.3) + its -->
<!-- `event_specifics` block. -->
<!-- Pattern standard — NO crate version pins (async-nats / sqlx / temporalio-sdk -->
<!-- pins ride with B.6.2's Cargo.toml.tmpl ; baseline in -->
<!-- .forge/research/b6-2-verify-then-pin.md). -->

> **Status**: pattern guidance for the `event-driven-eu` archetype (T7).
> **Schema component mapping**: `event-patterns` (role `saga-outbox-inbox`, in
> `event-driven-eu/1.0.0.yaml`) ↔ this standard. The schema references it as
> `delivered_by: B.6.3`; the `event_specifics` block (event_versioning /
> idempotency_keys / saga_compensation / outbox_inbox_pattern) is realised here.

## Schema mapping & scope

The archetype backend (`backend/{events,eventstore,saga}`) implements the
event-driven core: a versioned, idempotent event envelope carried over NATS
JetStream, an append-only Postgres event store with replayable projections, and a
Temporal **activity-only** saga surface. This standard documents those patterns and
the rules the `event_specifics` schema block mandates. It pins NO crate versions
(they live in B.6.2's `Cargo.toml.tmpl`; see `.forge/research/b6-2-verify-then-pin.md`).

Sibling standards: `global/asyncapi-contracts.md` (the event contract), and
`infra/nats-jetstream.md` (the broker topology).

## Event envelope & versioning

Every domain event travels in a single versioned envelope
(`backend/events/src/envelope.rs`, `EventEnvelope`):

- `id` (UUID) · `stream_id` · `event_type` · `event_version` (u32) ·
  `idempotency_key` · `payload` (JSON) · `occurred_at` (UTC).
- The JetStream subject is namespaced by type **and** version:
  `events.v<version>.<EventType>` (`EventEnvelope::subject()`), e.g.
  `events.v2.OrderPlaced`.

**Event-versioning rules** (`event_specifics.event_versioning: required`):

- A consumer selects its deserializer by the tuple `(event_type, event_version)`.
  Never branch on payload shape alone.
- **Additive, in-place** changes (a new OPTIONAL field with a default) keep the same
  `event_version`.
- **Breaking** changes to a published event (removing/renaming a field, changing a
  type, tightening a constraint) MUST bump `event_version` and therefore publish on a
  **new subject** (`events.v<n+1>....`). Old and new versions coexist until every
  consumer has migrated; the old subject is retired only after drain.
- The wire contract for each event is mirrored in `shared/asyncapi/asyncapi.yaml`
  (see `global/asyncapi-contracts.md`) — bump both together.

## Idempotency keys

`event_specifics.idempotency_keys: required`. One stable key threads through all
three dedup surfaces so that at-least-once delivery and retries never
double-apply an effect:

1. **Publish dedup** — `JetStreamPublisher` sets the `Nats-Msg-Id` header to the
   envelope `idempotency_key` (`backend/events/src/publisher.rs`); the JetStream
   server drops re-publishes within its dedup window.
2. **Append dedup** — the event store appends with
   `ON CONFLICT (idempotency_key) DO NOTHING` (`backend/eventstore/src/store.rs`;
   the `events` table has a UNIQUE index on `idempotency_key` in
   `infra/postgres/init-eventstore.sql`), so a retried append is a no-op.
3. **Consume dedup (inbox)** — `InboxDedup` records processed keys
   (`backend/events/src/consumer.rs`), backed in production by the `inbox` table.

Prefer a **stable business key** (`EventEnvelope::with_idempotency_key("order-42")`)
over the default (the random event id) wherever publish/append/consume must be
idempotent across process restarts.

## Saga & compensation

Article **VIII.2** forbids ad-hoc saga implementations in application code and
mandates **Temporal** for durable, multi-step, cross-service workflows. This
archetype therefore keeps saga side effects in Temporal **activities only**:

- `backend/saga/src/activity.rs` declares idempotent, retry-safe activity markers
  (`saga.persist_event`, `saga.publish_event`, …) that the Temporal worker
  registers; there are NO `#[workflow]` definitions in application code.
- `backend/saga/src/temporal.rs` re-exports the native `temporalio-sdk` /
  `temporalio-client` behind the **OFF-by-default** `temporal-sdk` feature (the
  workflow API is Public Preview and "will continue to evolve"), so default builds
  stay hermetic.
- `backend/saga/src/compensation.rs` is the deterministic, unit-testable core: a
  `Saga` runs steps forward and, on the first failure, runs the compensations for the
  already-completed steps in **reverse order** (best-effort — a compensation error
  does not mask the original failure). `event_specifics.saga_compensation: required`.

For the Temporal worker/activity/workflow API, determinism rules, task-queue
layout, workflow-ID-as-business-key, retry policy, and the pin-exactly-and-re-verify
discipline, follow **`infra/temporal.md`** (Article VIII.2) — this standard does not
restate it. `exactly_once` is achieved `via_temporal_and_idempotency_keys`
(schema `event_specifics`).

## Process manager

A **process manager** (a.k.a. saga orchestrator) is a stateful coordinator that
subscribes to events, maintains its own state, and issues commands in reaction —
distinct from the stateless reverse-compensation `Saga` above. Use one when a
long-lived business process must react to events arriving over time (timeouts,
human approval, fan-in of several events). In this archetype a process manager is
implemented as a **Temporal workflow** driving activities (Article VIII.2), keyed by
its business id — never as an ad-hoc in-memory loop.

> First-cut note (Article III.4): the B.6.2 scaffolder ships the reverse-order
> `Saga` coordinator + activity markers, **not** a concrete process-manager
> workflow. This section is pattern guidance for adopters; the Temporal workflow
> surface lands when the `temporal-sdk` feature is enabled (see `infra/temporal.md`).

## Outbox & inbox

`event_specifics.outbox_inbox_pattern: recommended`.

- **Inbox (implemented)** — consumers dedup redelivered events on `idempotency_key`
  before applying side effects (`backend/events/src/consumer.rs::InboxDedup`, durable
  `inbox` table). This is why NATS at-least-once delivery is safe here.
- **Outbox (recommended pattern — NOT in the B.6.2 first cut)** — to publish an event
  atomically with the state change that produced it, write the event to an `outbox`
  table in the **same DB transaction** as the state change, then a relay/poller
  publishes committed outbox rows to JetStream and marks them sent. This removes the
  dual-write race between "commit state" and "publish event".
  > **First-cut honesty (Article III.4):** the scaffolder does NOT ship a
  > transactional outbox table or relay. Its publish path relies on the append-only
  > event store (`events`) as the source of truth plus `Nats-Msg-Id` publish dedup
  > and idempotent consumers. Adopters who need atomic state+publish add the `outbox`
  > table + relay; this is a documented follow-up (candidate for Hermes-Async, B.6.4),
  > not a claim it already exists.

## Projections & read models

Read models are built by folding the event log
(`backend/eventstore/src/projection.rs`, `Projection` trait). Projections MUST be
**deterministic and idempotent (replayable)**: folding the same log twice yields the
same view, so any read model can be rebuilt from the event store at any time
(`EventStore::read_stream` returns events in ascending global `seq` order). Keep
projection `apply` free of external side effects — side effects belong in a Temporal
activity, never in a projection or a consumer callback.

## EU sovereignty

`event_specifics.eu_sovereignty` forbids US Kafka SaaS (Confluent Cloud) and accepts
NATS JetStream / Redpanda (EU-deployable). The broker topology and this rule are
detailed in `infra/nats-jetstream.md`; the CI/scaffold-time **enforcement** of the
forbidden-Kafka-SaaS rule is delivered separately by Janus (B.6.10) — this standard
states the rule and defers enforcement.

## Constitutional Compliance

- **VIII.2** — no ad-hoc saga in application code; durable workflows run on Temporal
  (activity-only bias here). API + rules deferred to `infra/temporal.md`.
- **VII.1 / VII.3** — the event/store/saga surfaces are hexagonal ports
  (`EventPublisher`, `EventStore`, `SagaStep`, `Activity`) with `thiserror` typed
  errors and in-memory fakes for tests; no `unwrap`/`panic` on the request path.
- **IX** — events, publishes, appends, and activities are trace/metric points
  (`observability.yaml`, SigNoz/OBI/Coroot); redelivery and compensation are
  observable.
- **III.4** — every claim above is grounded in a scaffolded file path; the outbox and
  process-manager gaps are recorded, not glossed; no crate version is pinned here.

## Out-of-scope

- **Crate version pins** (`async-nats`, `sqlx`, `temporalio-sdk`, `temporalio-client`)
  — B.6.2 `Cargo.toml.tmpl`, verify-then-pin LIVE (baseline:
  `.forge/research/b6-2-verify-then-pin.md`).
- **Temporal workflow/worker API** — `infra/temporal.md`.
- **The event contract (AsyncAPI)** — `global/asyncapi-contracts.md`.
- **Broker clustering / persistence / consumer groups** — `infra/nats-jetstream.md`.
- **AsyncAPI bindings + idempotency-key placement automation** — Hermes-Async (B.6.4).
- **Forbidden-Kafka-SaaS enforcement rule** — Janus (B.6.10).
- **Transactional outbox table + relay, concrete process-manager workflow** —
  documented follow-ups, not shipped in the B.6.2 first cut.
