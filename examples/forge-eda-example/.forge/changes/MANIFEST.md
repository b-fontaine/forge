# Demo changes — manifest

<!-- Audit: B.6.8 (b6-8-example FR-EDAEX-006) -->

This file is the **chronological index** of demo changes shipped under
`examples/forge-eda-example/.forge/changes/`. Listed in archive order so
adopters reading the directory get a narrative of the event-driven
discipline.

| Demo | Status | One-line summary |
|---|---|---|
| [`demo-001-ingestion-http-nats`](demo-001-ingestion-http-nats/) | archived (2026-07-12) | Single-layer backend — HTTP ingestion → NATS JetStream: an axum command is wrapped in a versioned, idempotent `EventEnvelope` and published with `Nats-Msg-Id` dedup; event versioning + idempotency keys; cucumber-rs BDD. |
| [`demo-002-projection-readmodel`](demo-002-projection-readmodel/) | archived (2026-07-12) | Single-layer backend — event store → read model: a consumer folds the persisted Postgres event stream into a deterministic, replayable projection, guarded by the inbox dedup (outbox/inbox pattern); cucumber-rs BDD. |
| [`demo-003-order-saga`](demo-003-order-saga/) | archived (2026-07-12) | Multi-layer (backend + infra, Janus) — a Temporal **activity-only** 3-step order saga (reserve stock → charge payment → confirm shipment) with reverse-order compensation on failure (Article VIII.2); the backend saga crate + the infra Temporal cluster substrate. Per-layer designs/ + tasks/. |

Each demo's change directory contains the canonical artefacts:
`.forge.yaml`, `proposal.md`, `specs.md`, `design.md` (or per-layer
`designs/design-<layer>.md`), `tasks.md` (or per-layer
`tasks/tasks-<layer>.md`), and `features/<demo>.feature` for the BDD
scenarios.

For the example tree's top-level navigation see `../../README.md`; for
the `examples/` directory README in the Forge framework repo see
`../../../README.md`.
