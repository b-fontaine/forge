# Specs: demo-001-greeting-service

<!-- Audit: C.1 (illustrative demo) -->
<!-- Layers: [backend] -->
<!-- Format: ADDED-only delta on the implicit baseline (no prior specs). -->

## ADDED Requirements

### FR-IN-001: Proto contract `greeting.v1.GreeterService`

- **MUST** — `shared/protos/v1/greeting/greeting.proto` declares
  `package greeting.v1`.
- **MUST** — declares `service GreeterService` with one RPC
  `Greet(GreetRequest) returns (GreetResponse)`.
- **MUST** — `GreetRequest` has one field `string name = 1;`.
- **MUST** — `GreetResponse` has one field `string message = 1;`.
- **MUST** — passes `buf lint` with the workspace's STANDARD
  ruleset configured by `b1-scaffolder` (no warnings, no
  suppressions).

**Constitution reference:** Articles IV, IX.4. **Testable:** yes —
`buf lint shared/protos`.

### FR-BE-001: Domain entity `Greeting`

- **MUST** — `backend/crates/domain/src/greeting.rs` declares a
  pure struct `Greeting` with one method
  `Greeting::for_name(name: &str) -> Greeting` that builds a
  greeting message of the form `"Hello, {name}!"`.
- **MUST** — empty `name` returns
  `Greeting::for_name("") -> Greeting { message: "Hello, world!" }`
  (the convention is "world" as the default audience).
- **MUST** — the domain crate's `Cargo.toml` MUST NOT add any
  dependency outside the standard library + `thiserror` (Article
  VII.1 — domain has zero external deps).
- **SHALL** — `Greeting::message()` returns the rendered string.

**Constitution reference:** Article VII (Hexagonal Rust).
**Testable:** yes — unit tests in `domain/src/greeting.rs`.

### FR-BE-002: Use case `GreetUseCase`

- **MUST** — `backend/crates/application/src/greet.rs` declares
  a use case `GreetUseCase::execute(name: String) -> Greeting`
  that delegates to `Greeting::for_name`.
- **SHALL** — the use case is the only orchestration layer
  between the gRPC adapter (FR-BE-003) and the domain entity
  (FR-BE-001) — the adapter MUST NOT construct `Greeting`
  directly.
- **MUST** — the application crate has no dependency on `tonic`,
  `tokio`, or any infrastructure crate (Article VII.1).

**Constitution reference:** Article VII. **Testable:** yes — unit
test in `application/src/greet.rs`.

### FR-BE-003: gRPC adapter `GreeterServiceImpl`

- **MUST** — `backend/crates/grpc-api/src/greeter.rs` implements
  the `GreeterService` trait generated from the proto, delegating
  to `GreetUseCase`.
- **MUST** — the adapter creates a root `tracing` span on every
  RPC (Article IX.4 — request-handler spans).
- **MUST** — the adapter returns `tonic::Status::ok(...)` on
  success ; never panics on a malformed request.
- **MUST** — registered in `bin-server/src/main.rs` so the
  binary serves `greeting.v1.GreeterService`.

**Constitution reference:** Articles VII, IX.4. **Testable:** yes —
integration test in `grpc-api/tests/greeter_integration.rs`
using a tonic in-process server.

## Acceptance Criteria (BDD)

### AC-001: Default greeting

```gherkin
Feature: Greeter service
  As a backend gRPC client
  I want to call the Greet RPC
  So that I receive a polite hello message

  Scenario: Greeter responds with hello message
    Given the Greeter service is running
    When I call Greet with name "world"
    Then I receive a response with message "Hello, world!"

  Scenario: Greeter handles empty name with the default audience
    Given the Greeter service is running
    When I call Greet with name ""
    Then I receive a response with message "Hello, world!"
```

(Both scenarios are exercised by `features/greeter.feature` via
`cucumber-rs`.)
