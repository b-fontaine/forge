# Standard — NATS JetStream

<!-- Audit: B.6.3 (b6-3-standards) — event-driven-eu archetype. -->
<!-- Schema mapping: documents the `nats-jetstream` component of -->
<!-- `.forge/schemas/event-driven-eu/1.0.0.yaml` (delivered_by: B.6.3). -->
<!-- NATS clustering/consumer facts verified against docs.nats.io (2026-07-10). -->
<!-- Pattern standard — NO version pins ; the production cluster ships as a Helm -->
<!-- chart in B.6.6, NOT here. -->

> **Status**: pattern guidance for the `event-driven-eu` archetype (T7).
> **Schema component mapping**: `nats-jetstream` (role `event-backbone`, in
> `event-driven-eu/1.0.0.yaml`) ↔ this standard (1:1). The schema references it as
> `delivered_by: B.6.3`.

## Schema mapping & scope

NATS JetStream is the archetype's event backbone
(`event_specifics.eu_sovereignty.acceptable: [nats-jetstream, redpanda]`). The
scaffolder ships a **single-node local-dev** config (`infra/nats/jetstream.conf`)
started by `docker-compose.dev.yml`; its own comments defer production clustering,
persistence tuning, and consumer groups to **this** standard + the Helm chart
(B.6.6). This document is the production counterpart to that dev overlay; it pins NO
versions and does not itself ship the chart (that is B.6.6).

Sibling standards: `global/event-driven.md` (envelope, idempotency, inbox) and
`global/asyncapi-contracts.md` (the channel contract).

## Clustering & RAFT consensus

JetStream uses a NATS-optimised **RAFT** algorithm for clustering, organised into
three RAFT group types (docs.nats.io, verified 2026-07-10):

- **Meta Group** — every server joins it; it manages the JetStream API and cluster
  metadata.
- **Stream Group** — each stream forms a RAFT group that synchronises its state and
  data across its members.
- **Consumer Group** — each consumer forms a RAFT group that synchronises consumer
  (delivery/ack) state across its members.

**Cluster sizing** — run an **odd** number of JetStream-enabled servers; NATS
recommends **3 or 5**. A quorum is `½·cluster_size + 1` (a 3-node cluster needs 2
healthy servers; a 5-node cluster needs 3) — the minimum to guarantee at least one
node holds the most recent data/state after a catastrophic failure. The dev
`jetstream.conf` is a single node (`server_name: ede-nats-dev`, no `cluster{}`
block) and is explicitly NOT a production topology.

## Persistence

- **Storage** — production streams use `file` storage (durable, disk-backed). The
  dev config sets `store_dir: "/data"` with modest caps (`max_memory_store` 256 MB,
  `max_file_store` 2 GB); production sizing is a chart value (B.6.6), not this file.
- **Replication** — set a stream's replica count for HA. A replicated stream's RAFT
  group tolerates the loss of a **minority** of its replicas by the same quorum rule
  above: 3 replicas survive 1 lost node, 5 replicas survive 2. Use an odd replica
  count no greater than the cluster size.
- **Retention & limits** — bound each stream with the JetStream limits
  (`max_bytes`, `max_msgs`, `max_age`, `max_msgs_per_subject`) and choose a retention
  policy: `limits` (age/size caps — the default, right for the append-only event
  log), `interest`, or `workqueue` (a message is removed once a consumer has consumed
  it — for a pure work queue). The Postgres event store
  (`infra/postgres/init-eventstore.sql`) remains the durable system of record; NATS
  retention governs replay/backfill windows, not the source of truth.

## Consumer groups

Consumer facts (docs.nats.io, verified 2026-07-10):

- **Durable vs ephemeral** — production consumers are **durable** (explicit name or
  `InactiveThreshold`): they persist their state and survive server/client restarts.
  Ephemeral consumers keep state only in memory and auto-delete after inactivity —
  dev/tooling only.
- **Pull vs push** — prefer **pull** consumers for backend workers: clients fetch
  batches on demand with built-in flow control and explicit error handling. Push
  consumers deliver to a subject and are simpler for sequential replay.
- **Horizontal scaling (work sharing)** — a **pull** consumer scales by running
  multiple subscribers that share one durable consumer (each `fetch` competes for the
  next messages). A **push** consumer uses a `DeliverGroup` (a queue-group name) to
  distribute messages across subscribers, analogous to core-NATS queue groups.
- **Ack & redelivery** — use `AckExplicit` (the default: each message individually
  acked) for at-least-once processing; `AckAll` / `AckNone` only when their weaker
  guarantees are acceptable. An un-acked message is **redelivered** after `AckWait`,
  bounded by `MaxDeliver`. Because delivery is at-least-once, consumers **must** dedup
  on the idempotency key — this is exactly why `global/event-driven.md`'s inbox
  pattern (`InboxDedup` + the `inbox` table) exists. Send poison messages (that
  exhaust `MaxDeliver`) to a dead-letter subject/stream for inspection.

## EU sovereignty

`event_specifics.eu_sovereignty.no_kafka_saas_us: true` — **US-managed Kafka SaaS
(Confluent Cloud) is forbidden.** Acceptable brokers are **NATS JetStream** and
**Redpanda** (both CNCF-adjacent and EU-deployable/self-hostable). Self-host the
cluster in an EU region (or an EU-sovereign managed offering) consistent with the
project's compliance tier (`global/compliance-tiers.md`,
`global/data-stewardship-rules.md`). The scaffold/CI **enforcement** of the
forbidden-Kafka-SaaS rule is delivered by Janus (B.6.10) — this standard states the
rule; B.6.10 enforces it.

## Constitutional Compliance

- **VIII.5 (IaC)** — the cluster is defined as a version-controlled Helm chart
  (B.6.6), never hand-provisioned; no config drift.
- **IX** — the broker exports health/metrics (the dev config already opens the
  monitoring endpoint `http_port: 8222` — `/healthz`, `/jsz`); production scrapes
  feed the `observability.yaml` backend (SigNoz/OBI/Coroot).
- **Data sovereignty** — EU-region self-host + no US Kafka SaaS, aligned with
  `data-stewardship-rules.md` (K.3) and `compliance-tiers.md` (I.2).
- **III.4** — clustering/consumer facts are quoted from docs.nats.io (verified
  2026-07-10); production chart values are deferred to B.6.6, not fabricated here.

## Out-of-scope

- **The production Helm chart** (cluster manifests, replica counts, storage classes,
  resource limits) — B.6.6.
- **Version pins** (NATS server image, `async-nats` crate) — the crate pin is in
  B.6.2 `Cargo.toml.tmpl`; the server image tag is a chart value (B.6.6).
- **Forbidden-Kafka-SaaS enforcement rule** — Janus (B.6.10).
- **Envelope / idempotency / inbox semantics** — `global/event-driven.md`.
- **The channel/message contract** — `global/asyncapi-contracts.md`.
- **Temporal cluster** — `infra/temporal.md` + B.6.6.
