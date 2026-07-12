# backend/ — forge-eda-example (Vulcan)

Rust workspace for the event-driven-eu backend. Hexagonal (Article VII.1);
`bin-server` is DI wiring only (VII.3); typed errors (`thiserror` in libs, `anyhow`
in the binary, VII.3); `tracing` on the request path (IX.4).

## Crates

| Crate | Responsibility |
|-------|----------------|
| `events` | NATS JetStream backbone: versioned/idempotent `EventEnvelope`, `EventPublisher` port + `JetStreamPublisher` (dedup via `Nats-Msg-Id`), `InboxDedup` (inbox pattern) |
| `eventstore` | Append-only Postgres event store (`PgEventStore`, sqlx runtime queries) + `InMemoryEventStore` (tests/dev) + read-model `Projection`s |
| `saga` | Temporal **activity-only** saga: `Activity` marker traits + a deterministic compensation coordinator (`Saga`/`SagaStep`). The pre-alpha native SDK is behind the OFF-by-default `temporal-sdk` feature |
| `bin-server` | axum entrypoint + DI wiring (health probe + startup self-check) |

## Rules

1. TDD: every crate ships `#[cfg(test)]` tests. RED → GREEN → REFACTOR.
2. `cargo test --workspace` + `cargo clippy --workspace --all-targets -- -D warnings`
   + `cargo fmt --all --check` clean before merge (Tribune).
3. No `unwrap()`/`expect()`/`panic!` in `src/` (test code excepted).
4. **Temporal**: activity-only (VIII.2). The native `temporalio-sdk` is Public
   Preview / pre-alpha — do NOT scaffold `#[workflow]` definitions; wire real
   workers from the pinned crate's docs behind `--features temporal-sdk`.
5. Connect/gRPC is consumed BY REFERENCE via `../shared/protos` + `buf generate`
   (transport.yaml); no `tonic`/`prost` pin is inlined in this workspace.

Every external crate pin lives in `Cargo.toml` (verify-then-pin LIVE — see
`.forge/research/b6-2-verify-then-pin.md`), never in a standard.
