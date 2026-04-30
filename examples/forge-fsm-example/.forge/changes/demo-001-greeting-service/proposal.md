# Proposal: demo-001-greeting-service

<!-- Audit: C.1 (illustrative demo of c1-reference-project) -->
<!-- Layers: [backend] — single-layer demo -->

## Problem

The `forge-fsm-example` project ships with a scaffolded backend
that has no actual gRPC service yet. Adopters reading the example
need a concrete demonstration of how a **single-layer backend
change** flows through the Forge pipeline — from proposal to
archive — with real Rust code, real tests, and a real proto
contract.

## Solution

Add a minimal `Greeter` gRPC service that exposes a single RPC
`Greet(GreetRequest) returns (GreetResponse)`. The service lives
in `backend/crates/grpc-api/`, delegates to a use case in
`backend/crates/application/`, which orchestrates a pure domain
entity in `backend/crates/domain/` (hexagonal layering per
Article VII).

The proto contract lives in `shared/protos/v1/greeting/greeting.proto`
and is the single source of truth for the cross-layer interface.

This demo is **deliberately trivial** — its purpose is to
demonstrate the full TDD + hexagonal + proto-first discipline,
not to ship a real product feature.

## Scope In

- New proto file `shared/protos/v1/greeting/greeting.proto`
  declaring `service GreeterService { rpc Greet(...) ... }`.
- A pure `Greeting` domain entity in `crates/domain/`.
- A `greet_use_case` in `crates/application/`.
- A `GreeterServiceImpl` in `crates/grpc-api/` (tonic handler).
- Unit tests for the domain entity (RED → GREEN cycle).
- Integration test for the tonic handler against an in-process
  server.
- BDD scenario in `features/greeter.feature` covering the happy
  path.

## Scope Out

- No persistence (the greeting is computed, not stored).
- No frontend consumption (demo-002 covers that).
- No rate limiting (demo-003 covers that).
- No internationalization (English only).
- No authentication.

## Impact

- **Technical impact**: Small. ~50 lines of Rust code across 3
  crates + 1 proto file + 2 test files.
- **Dependencies**: None (`b1-scaffolder` already produced the
  empty hexagonal workspace).
- **Risk level**: Trivial. The demo is illustrative, not
  load-bearing.

## Constitution compliance

- **Article I (TDD)**: every Rust function ships with a unit test
  written RED-first, exercising the domain logic before the
  handler.
- **Article II (BDD)**: `features/greeter.feature` gives a
  user-facing scenario in Gherkin.
- **Article III (Specs Before Code)**: this proposal precedes the
  spec which precedes the design which precedes the code.
- **Article IV (Delta-Based)**: `specs.md` uses ADDED-only
  delta semantics.
- **Article VII (Rust Architecture)**: domain crate has zero
  external deps, application orchestrates ports, grpc-api is the
  adapter. Errors via `thiserror`. No `unwrap()` / `panic!()` in
  production code paths.
- **Article IX (Observability)**: handler instruments the RPC
  via the `tracing` crate (one root span per request).
