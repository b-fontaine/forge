# Tasks (backend layer): demo-003-rate-limit

<!-- Layer: backend -->
<!-- TDD-ordered. All tasks marked [x] post-archive. -->

## Phase 1: Tracing event (TDD)

- [x] **RED** — Add unit test in
  `backend/crates/grpc-api/src/greeter.rs` that captures
  `tracing::warn!` events with target `greeter.rate_limit` via
  the `tracing-test` helper, asserts the event is emitted when
  the handler observes a synthetic `tonic::Status::resource_exhausted("429")`.
  Run `cargo test -p grpc-api` — fail. [Story: FR-BE-001]
- [x] **GREEN** — In the handler, after the use case returns,
  inspect the response (or the synthetic upstream signal in
  this demo's test) ; if status is `ResourceExhausted`, emit
  `tracing::warn!(target: "greeter.rate_limit",
  consumer = ?consumer_id, code = 8, "rate-limit hit")`.
  Run — pass. [Story: FR-BE-001]
- [x] **REFACTOR** — `cargo clippy --workspace -- -D warnings`.

## Phase 2: Quality gate

- [x] Run `bash .forge/scripts/verify.sh` from the example root
  — backend section all green.
- [x] No new `unwrap()` / `panic!()` in production paths.
