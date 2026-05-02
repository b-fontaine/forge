# Design: demo-001-greeting-service

<!-- Audit: C.1 (illustrative demo) -->
<!-- Layers: [backend] -->

## Architecture Decisions

### ADR-001: Hexagonal layering with explicit use case

**Context.** The `Greeting` entity is trivial (one factory + one
method). A naive implementation could put the greeting logic
directly in the gRPC handler. But that would violate Article
VII.1 (domain ↔ adapter separation) and set a bad example for
adopters reading the demo.

**Decision.**

Three crates participate :

- `crates/domain/` declares the `Greeting` entity (pure, no
  dependencies).
- `crates/application/` declares the `GreetUseCase` (depends
  only on `domain`).
- `crates/grpc-api/` declares `GreeterServiceImpl` (depends on
  `application` + `domain` + `tonic` + `tracing`).

The gRPC handler is the ONLY adapter — it MUST NOT short-circuit
the use case.

**Consequences.**

- ✅ Demo correctly illustrates the hexagonal pattern.
- ✅ Adding a CLI adapter (e.g. `bin-server` calls the same use
  case directly) is a one-line wire-up.
- ⚠️ Trivial overhead for a one-method entity. Acceptable — the
  demo's didactic value outweighs the boilerplate cost.

**Constitution Compliance:** Article VII.1 confirmed.

### ADR-002: Cucumber-rs for BDD, in-process tonic server for integration

**Context.** Article II requires Gherkin scenarios for every
user-facing feature. Article VII.5 mandates `cucumber-rs` for
Rust BDD. We need a way to exercise the full RPC pipeline
(client → tonic → handler → use case → entity) end-to-end.

**Decision.**

- BDD steps live in `backend/tests/greeter_steps.rs` using
  `cucumber-rs`'s `#[given]`/`#[when]`/`#[then]` macros.
- Each scenario boots an **in-process tonic server** on a
  random port, registers `GreeterServiceImpl`, opens a tonic
  client, and invokes the RPC. The full pipeline is exercised
  per scenario.
- The cucumber harness uses `tokio::test`'s multi-thread runtime
  to allow server + client to run concurrently.

**Consequences.**

- ✅ End-to-end coverage with no network dependency.
- ✅ Scenarios run in <100 ms each (no Docker, no real network).
- ⚠️ One-time setup cost — adopters reading the demo learn the
  pattern from this single example.

**Constitution Compliance:** Articles II, VII.5 confirmed.

### ADR-003: Errors via `thiserror`, no `unwrap()` in production paths

**Context.** Article VII.3 prohibits `unwrap()` / `expect()` /
`panic!()` in production code paths. The demo's code is
production-quality even though the feature is trivial.

**Decision.**

- The domain entity returns `Greeting` directly (no fallible
  path — empty name is handled by defaulting to "world").
- The use case returns `Greeting` directly.
- The gRPC adapter wraps results in `Result<Response<...>,
  Status>` and converts any future error variant via
  `thiserror`-derived types. For this demo, the only failure
  mode is "future feature" — not exercised at archive time.

**Consequences.**

- ✅ Sets a good example for adopters.
- ✅ Future demos can extend the error story without restructuring.

**Constitution Compliance:** Article VII.3 confirmed.

## Component diagram

```mermaid
graph LR
    Client[gRPC client] -->|"Greet(GreetRequest)"| Adapter[GreeterServiceImpl<br/>crates/grpc-api/]
    Adapter -->|execute(name)| UseCase[GreetUseCase<br/>crates/application/]
    UseCase -->|for_name(name)| Entity[Greeting<br/>crates/domain/]
    Entity -->|Greeting{message}| UseCase
    UseCase -->|Greeting| Adapter
    Adapter -->|"GreetResponse{message}"| Client
```

## Testing Strategy

| Test | Type | Location |
|---|---|---|
| `Greeting::for_name("Alice")` returns "Hello, Alice!" | unit | `crates/domain/src/greeting.rs` `#[cfg(test)] mod tests` |
| `Greeting::for_name("")` returns "Hello, world!" | unit | same |
| `GreetUseCase::execute` delegates to `Greeting::for_name` | unit | `crates/application/src/greet.rs` |
| `GreeterServiceImpl::greet` creates root tracing span | unit | `crates/grpc-api/src/greeter.rs` |
| In-process tonic Greet call succeeds | integration | `crates/grpc-api/tests/greeter_integration.rs` |
| BDD scenarios from `features/greeter.feature` pass | BDD | `tests/greeter_steps.rs` (workspace-level) |

## Standards Applied

- `rust/architecture.md` — hexagonal 5-crate layout.
- `rust/error-handling.md` — `thiserror` only ; no `unwrap()`.
- `rust/testing.md` — `#[test]` for unit ; `cucumber-rs` for BDD.
- `rust/grpc.md` — `tonic` + `prost` ; service in `grpc-api`.
- `rust/opentelemetry.md` — root span via `tracing::instrument`.

✅ Constitutional gate green. Proceeding to /forge:plan.
