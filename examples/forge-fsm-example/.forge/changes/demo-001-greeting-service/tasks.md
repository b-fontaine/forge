# Tasks: demo-001-greeting-service

<!-- Audit: C.1 (illustrative demo) -->
<!-- TDD-ordered. All tasks marked [x] post-archive. -->

## Phase 1: Foundation — proto contract

- [x] Add `shared/protos/v1/greeting/greeting.proto` declaring
  `service GreeterService` + `Greet` RPC + `GreetRequest` +
  `GreetResponse`. [Story: FR-IN-001]
- [x] Run `task proto` to regenerate Dart + Rust stubs.
  [Story: FR-IN-001]
- [x] Confirm `buf lint shared/protos` passes (zero warnings).
  [Story: FR-IN-001]

## Phase 2: Domain — `Greeting` entity (TDD)

- [x] **RED** — Write `crates/domain/src/greeting.rs` with
  `#[cfg(test)] mod tests` containing the test
  `for_name_with_world_returns_hello_world` asserting
  `Greeting::for_name("world").message() == "Hello, world!"`.
  Run `cargo test -p domain` — confirm fail (no `Greeting` yet).
  [Story: FR-BE-001]
- [x] **GREEN** — Implement `pub struct Greeting { message: String }`
  with associated `pub fn for_name(name: &str) -> Greeting`
  returning `Greeting { message: format!("Hello, {}!", if name.is_empty() {"world"} else {name}) }`.
  Run `cargo test -p domain` — confirm pass. [Story: FR-BE-001]
- [x] **RED** — Add test `for_name_with_empty_returns_default_audience`
  asserting `Greeting::for_name("").message() == "Hello, world!"`.
  Run — confirm pass (already covered by GREEN above ; this is a
  fixture-only addition for explicit coverage). [Story: FR-BE-001]
- [x] **REFACTOR** — Run `cargo clippy -p domain -- -D warnings`.
  Zero warnings. [Story: Article X.5]

## Phase 3: Application — `GreetUseCase` (TDD)

- [x] **RED** — Write `crates/application/src/greet.rs` with a
  test `execute_returns_greeting_for_name`. Run — confirm fail.
  [Story: FR-BE-002]
- [x] **GREEN** — Implement `GreetUseCase::execute(name: String) -> Greeting`
  delegating to `Greeting::for_name`. Run — confirm pass.
  [Story: FR-BE-002]
- [x] **REFACTOR** — `cargo clippy -p application -- -D warnings`.
  [Story: Article X.5]

## Phase 4: Adapter — `GreeterServiceImpl` (TDD)

- [x] **RED** — Write integration test
  `crates/grpc-api/tests/greeter_integration.rs` booting an
  in-process tonic server on a random port, calling `Greet` with
  name "world", asserting response message. Run — confirm fail.
  [Story: FR-BE-003]
- [x] **GREEN** — Implement `GreeterServiceImpl` in
  `crates/grpc-api/src/greeter.rs`, register in
  `bin-server/src/main.rs`. Run — confirm pass. [Story: FR-BE-003]
- [x] Add `tracing::instrument` on the handler to create a root
  span per RPC (Article IX.4). [Story: FR-BE-003]
- [x] **REFACTOR** — `cargo clippy --workspace -- -D warnings`.
  [Story: Article X.5]

## Phase 5: BDD scenarios (Article II)

- [x] Author `features/greeter.feature` with the two scenarios
  from `specs.md` AC-001. [Story: AC-001]
- [x] Add `tests/greeter_steps.rs` with cucumber-rs step
  definitions. Run `cargo test --test greeter_steps` — both
  scenarios pass. [Story: AC-001]

## Phase 6: Quality gate (Tribune)

- [x] Run `bash .forge/scripts/verify.sh` from the example tree
  root — backend section all green.
- [x] Run `bash .forge/scripts/constitution-linter.sh` —
  Articles I/II/III/VII confirmed.
- [x] No `TODO`s without tracked-issue annotations.
- [x] All public APIs documented (Article X.3).

## Phase 7: Archive

- [x] /forge:archive merges this demo's specs into the example's
  `.forge/specs/full-stack-monorepo.md` (or scoped equivalent
  for the example tree).
- [x] `.forge.yaml` updated to `status: archived`,
  `timeline.archived: 2026-04-30`.
