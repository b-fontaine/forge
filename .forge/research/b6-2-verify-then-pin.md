# B.6.2 event-driven-eu — verify-then-pin (LIVE crates.io)

<!-- Audit: B.6.2 (b6-2-scaffolder) — verify-then-pin evidence (Article III.4) -->

All pins below were resolved **LIVE** with `cargo add --dry-run` (cargo 1.97.0,
2026-07-10) against crates.io — NOT copied from any note, README, or Context7
index. Per the repo lesson (rmcp README-vs-Context7-vs-LIVE drift, and the plan's
own `temporalio-sdk = 0.4.0` note now superseded), **crates.io LIVE wins**. Pins
live ONLY in the rendered `backend/**/Cargo.toml.tmpl` (the consuming templates);
no `global/*.md` standard gains a version (transport/orchestration/persistence
standards stay pin-free).

## Resolved pins

| Crate | LIVE version (2026-07-10) | Where used | Notes |
|-------|---------------------------|------------|-------|
| `async-nats` | `0.49.1` | `events/` | NATS JetStream client. Idempotent publish via the `Nats-Msg-Id` header (JetStream server-side dedup). API verified by compile-probe: `jetstream::new(client)` → `ctx.publish_with_headers(subject, HeaderMap, payload).await?` → `ack.await?`. |
| `sqlx` | `0.9.0` | `eventstore/` | Postgres append-only event store. Features `runtime-tokio`, `tls-rustls-ring`, `postgres`, `macros`, `chrono`, `uuid`. **Runtime** `sqlx::query(...)` only (NOT the compile-time-checked `query!` macro — no DATABASE_URL needed to build). sqlx 0.9 split the old `runtime-tokio-rustls` umbrella into `runtime-tokio` + `tls-rustls-ring`. |
| `temporalio-sdk` | `0.5.0` | `saga/` (feature `temporal-sdk`, OFF by default) | Native Rust Temporal SDK — **Public Preview / pre-alpha** (`infra/temporal.md`: "the API can and will continue to evolve"). Plan §6.1's `0.4.0` note is superseded by LIVE `0.5.0`. Feature-gated OFF so default `cargo build`/`test`/`check` stays hermetic and does NOT compile the unstable workflow API; the saga crate ships pure-Rust **activity-only** saga logic (marker traits + a compensation coordinator) that always compiles. Proven to BUILD standalone (`cargo check` 1m03s, exit 0) — but only re-exported behind the feature (no workflow-macro API call, no fabricated method surface). |
| `temporalio-client` | `0.5.0` | `saga/` (feature `temporal-sdk`, OFF by default) | Companion client crate; same activity-only / feature-gated treatment. |

## Consumed BY REFERENCE (no inline pin in this archetype's Cargo.toml)

- **Connect-RPC / tonic / prost** — per `transport.yaml` (v1.3.0, ADR-003/ADR-009):
  the archetype ships `shared/protos/` (buf SSoT) + `buf.gen.yaml` (neoeinstein-tonic
  + neoeinstein-prost + Connect-ES + Connect-Go plugins) and `derived_outputs`
  include `asyncapi-3.1`. The Rust gRPC/Connect stubs are generated from protos by
  `buf generate` at the adopter/codegen step (deferred, mirroring ai-native-rag's
  "Connect consumed by reference" — B.7.2 ADR-B7-2-007). No `tonic`/`prost`/
  `connectrpc` pin is inlined in the backend workspace for the first cut.
- **pgvector / observability / identity / temporal cluster** — reused from the B.8
  substrate + the referenced standards; not re-pinned here.

## Core dep set (standard, non-pinned-family)

`tokio` (1, features full), `async-trait` (0.1), `futures` (0.3), `thiserror` (1),
`anyhow` (1), `tracing` (0.1), `tracing-subscriber` (0.3, env-filter), `axum` (0.8,
per transport.yaml server_runtime), `tower` (0.5), `tower-http` (0.6, trace),
`http` (1), `serde` (1, derive), `serde_json` (1), `uuid` (1, v4+serde), `chrono`
(0.4, serde). All verified building together (`cargo check` exit 0, 2026-07-10).
