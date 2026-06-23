# Forge Constitution

**Version**: v1.0.0  
**Status**: Ratified  
**Effective**: 2026-04-08

---

## Preamble

This Constitution is the supreme governing document of every project built with the Forge framework. It supersedes all other guidance, preferences, conventions, and habits. Every agent, every developer, and every automated system operating within a Forge project is bound by its articles without exception.

The purpose of this Constitution is to eliminate ambiguity, enforce quality at the structural level, and ensure that software built under Forge is correct, maintainable, observable, and aligned with its stated specifications. Quality is not a matter of willpower — it is a matter of process. This document defines that process.

When any article of this Constitution conflicts with a team preference, a shortcut, a deadline pressure, or a "it's just this once" rationale, the Constitution wins. Always.

---

## Article I — Test-Driven Development (NON-NEGOTIABLE)

### I.1 — The Fundamental Law

No production code SHALL be written without a failing test that justifies its existence. This is not a guideline. This is not a best practice. This is the law.

### I.2 — The Immutable TDD Cycle

Every unit of production code MUST pass through all five stages:

1. **RED** — Write a test that describes the desired behavior. The test must fail because the behavior does not yet exist.
2. **Verify RED** — Execute the test suite. Confirm the new test fails for the right reason. A test that passes before implementation is a broken test.
3. **GREEN** — Write the minimal code necessary to make the failing test pass. No more. No less. No speculative generality.
4. **Verify GREEN** — Execute the test suite. Confirm all tests pass, including the new one.
5. **REFACTOR** — Improve the structure, clarity, and design of the code without changing its observable behavior. Run tests again to confirm nothing broke.

No stage may be skipped. No stage may be combined with another. The cycle is immutable.

### I.3 — Applicable Technology

This article applies universally:

- **Dart / Flutter**: `flutter_test` for unit and widget tests; `bdd_widget_test` for BDD widget tests; `mocktail` for mocking.
- **Rust**: `#[test]` and `#[cfg(test)]` modules for unit tests; `cucumber-rs` for BDD integration tests; `mockall` for mocking.

### I.4 — Prohibited Exemptions

The following justifications for skipping TDD are explicitly prohibited and SHALL result in a constitutional violation:

- "It's too simple to test."
- "It's just a utility function."
- "We'll add tests later."
- "This is a prototype."
- "Tests would take too long."

There are no exemptions.

---

## Article II — Behavior-Driven Development

### II.1 — Scenarios Before Implementation

Every user-facing feature MUST have Given/When/Then scenarios written and reviewed before any implementation begins. Scenarios serve as the specification contract between the product vision and the code.

### II.2 — Gherkin as the Language of Intent

All BDD scenarios SHALL be written in Gherkin syntax using `.feature` files:

```gherkin
Feature: <Feature name>
  As a <persona>
  I want <capability>
  So that <benefit>

  Scenario: <Scenario name>
    Given <precondition>
    When <action>
    Then <expected outcome>
```

Scenarios MUST be human-readable and verifiable by non-engineers.

### II.3 — Flutter BDD

Flutter projects SHALL use `bdd_widget_test` integrated with Gherkin `.feature` files. Every widget that presents user-facing behavior MUST have a corresponding `.feature` scenario. Step definitions live alongside feature files. Widget rendering tests use `flutter_test`'s `testWidgets`.

### II.4 — Rust BDD

Rust projects SHALL use `cucumber-rs` with Gherkin `.feature` files for integration and acceptance tests. Async scenarios use `tokio`. Step definitions are registered via the `#[given]`, `#[when]`, `#[then]` attributes.

### II.5 — Scenario Coverage

A feature is not considered implemented until:
1. All `.feature` scenarios for that feature pass.
2. Unit tests for all underlying logic pass.
3. Code coverage meets the threshold defined in Article X.

---

## Article III — Specs Before Code

### III.1 — The Pipeline is Mandatory

No implementation work SHALL begin without a completed specification. The required pipeline is:

```
Proposal → Specs → Design → Tasks → Implementation
```

Each stage is a gate. A stage MUST be completed and approved before the next begins.

### III.2 — Spec Location

All specifications reside in `.forge/changes/<change-id>/`. A change directory MUST contain at minimum:
- `proposal.md` — Problem statement and proposed solution
- `specs.md` — Detailed behavioral requirements using RFC 2119 language
- `design.md` — Architecture and design decisions
- `tasks.md` — Broken-down implementation tasks

### III.3 — RFC 2119 Language

Specifications MUST use RFC 2119 keywords with their defined meanings:

- **MUST** / **SHALL** / **REQUIRED**: Absolute requirement.
- **MUST NOT** / **SHALL NOT**: Absolute prohibition.
- **SHOULD** / **RECOMMENDED**: Strong preference; deviations require explicit justification.
- **SHOULD NOT** / **NOT RECOMMENDED**: Strong discouragement; deviations require explicit justification.
- **MAY** / **OPTIONAL**: Truly optional; either choice is acceptable.

### III.4 — Ambiguity Protocol

When a specification contains ambiguity, contradictions, or undefined behavior, the implementing agent or developer MUST:

1. Output `[NEEDS CLARIFICATION: <specific question>]`
2. STOP all implementation work
3. Wait for clarification before proceeding

Guessing at intent is prohibited. Assumptions that turn out to be wrong cost more than the time saved by not asking.

---

## Article IV — Delta-Based Change Management

### IV.1 — Incremental Modifications Only

Specifications and documentation SHALL be modified incrementally, not rewritten wholesale. Changes to existing specs MUST use the delta format:

```markdown
## ADDED Requirements

- <new requirement>

## MODIFIED Requirements

- <requirement reference>  
  Previously: <old text>  
  Now: <new text>

## REMOVED Requirements

- <requirement reference> — Removed because <reason>
```

### IV.2 — No Complete Rewrites

Complete rewrites of specification documents are prohibited unless the prior document is explicitly deprecated and archived. History must be preserved.

### IV.3 — Parallel Changes

Multiple changes MAY be active on the same specification simultaneously, provided each change targets different sections and is tracked under separate change IDs in `.forge/changes/`.

### IV.4 — Change Lifecycle

Changes progress through defined states: `proposed` → `specified` → `designed` → `planned` → `implemented` → `archived`. State is tracked in the change's `.forge.yaml` metadata file.

---

## Article V — Constitutional Compliance Gate

### V.1 — Pre-Implementation Verification

The `/forge:plan` command MUST verify every proposed implementation task against this Constitution before allowing work to begin. Verification checks include:

- Corresponding spec exists in `.forge/changes/`
- TDD cycle is planned for each implementation task
- BDD scenarios exist for all user-facing behaviors
- Architecture choices comply with Articles VI, VII, and VIII
- Observability requirements from Article IX are addressed

### V.2 — Violation Handling

A constitutional violation MUST block progress. The blocking agent or system SHALL:

1. Clearly identify which article is violated
2. Describe the nature of the violation
3. Propose a compliant path forward

Work MUST NOT proceed around a violation. There are no workarounds to the Constitution.

### V.3 — Violation Escalation

Repeated or willful violations SHALL be escalated to the project maintainer. A pattern of violations indicates a process breakdown that requires structural remediation, not individual correction.

---

## Article VI — Flutter Architecture

### VI.1 — Architectural Pattern

Flutter projects SHALL follow Clean Architecture combined with Feature-Sliced Design (FSD) for module organization. Layers from outermost to innermost:

- **Presentation**: Widgets, BLoC/Cubit, UI state
- **Domain**: Use cases, entities, repository interfaces
- **Data**: Repository implementations, data sources, DTOs

Dependencies MUST point inward. Domain layer MUST have zero dependencies on Flutter or external packages.

### VI.2 — Module Structure

Features SHALL be organized as self-contained modules with lazy loading. No module may import from another module's internal layers — only from that module's public API surface.

### VI.3 — State Management

State management SHALL use `flutter_bloc` exclusively:
- **Cubit**: For simple, synchronous state with no complex event processing.
- **Bloc**: For complex state with distinct events and multiple transitions.

No other state management library (Provider, Riverpod, GetX, MobX, etc.) is permitted without explicit constitutional amendment.

### VI.4 — Dependency Injection

Dependency injection SHALL use `get_it` as the service locator and `injectable` for code generation of registrations. Constructor injection is mandatory — service locator calls MUST NOT appear inside business logic classes.

### VI.5 — Networking

All HTTP API communication SHALL use `retrofit` for type-safe API definitions and `dio` as the HTTP client. Raw `http` package usage is prohibited in application code. Interceptors handle auth, logging, and retry logic.

### VI.6 — Reactive Programming

Asynchronous data flow SHALL use Dart `Stream` and `StreamController`. No third-party reactive library (RxDart, etc.) is required; Dart's native streams are the standard. BLoC streams and Flutter's `StreamBuilder` integrate directly.

### VI.7 — Adaptive and Responsive Design

All UI MUST be adaptive (platform-aware) and responsive (screen-size-aware). Hardcoded pixel values for layout dimensions are prohibited. Use `LayoutBuilder`, `MediaQuery`, and platform detection for adaptive behavior.

### VI.8 — Golden Tests

Every custom widget with non-trivial visual output MUST have a golden test. Golden files are committed to version control. Golden tests run in CI and failures block merge.

### VI.9 — Accessibility

All widgets MUST pass Flutter's accessibility checker. Semantic labels are required for all interactive elements. Color contrast ratios MUST meet WCAG AA standards minimum.

### VI.10 — Internationalization

All user-visible strings MUST be externalized via `intl` and `flutter_localizations`. Zero hardcoded strings in widget code. The default locale is set explicitly and all supported locales are declared in `MaterialApp`.

---

## Article VII — Rust Architecture

### VII.1 — Architectural Pattern

Rust projects SHALL follow Hexagonal Architecture (Ports and Adapters):

- **Domain core**: Pure business logic, entities, and port interfaces. No external dependencies.
- **Application layer**: Use cases that orchestrate domain logic through ports.
- **Adapters**: Concrete implementations of ports (HTTP handlers, database clients, gRPC services, CLI).

### VII.2 — gRPC and Protocol Buffers

Inter-service communication in Rust SHALL use `tonic` for gRPC and Protocol Buffers for schema definition. `.proto` files are the source of truth for service contracts. No ad-hoc JSON APIs between services.

### VII.3 — Error Handling

Error handling SHALL follow these rules:
- Library crates MUST use `thiserror` for typed, derive-based error types.
- Application crates SHALL use `anyhow` for context-rich error propagation.
- `unwrap()`, `expect()`, and `panic!()` are prohibited in production code paths. Test code may use them.
- Every fallible function MUST return `Result<T, E>`. Error variants MUST be exhaustive.

### VII.4 — Async Runtime

All async code SHALL use `tokio` as the runtime. No mixing of async runtimes. Blocking operations MUST be wrapped in `tokio::task::spawn_blocking`.

### VII.5 — BDD Integration Tests

Rust integration and acceptance tests SHALL use `cucumber-rs` with Gherkin `.feature` files, consistent with Article II. Feature files live in `tests/features/`.

### VII.6 — Unsafe Code

`unsafe` blocks are prohibited without:
1. A documented justification comment explaining why unsafe is necessary
2. A safety invariant comment explaining why the usage is sound
3. A review sign-off from a designated reviewer

Zero undocumented `unsafe` blocks.

### VII.7 — Clippy and Compiler Warnings

All Rust code MUST compile with zero warnings. Clippy MUST pass with `-D warnings` (deny all warnings). No `#[allow(...)]` suppressions without a comment explaining why the suppression is justified.

---

## Article VIII — Infrastructure

### VIII.1 — API Gateway

Kong SHALL be used as the API gateway for routing REST requests to gRPC backends. REST↔gRPC transcoding is handled at the gateway layer, not in application code. Application services speak gRPC natively.

### VIII.2 — Workflow Orchestration

Long-running, multi-step workflows that span microservices SHALL use Temporal for orchestration. Temporal workflows provide durability, retryability, and observability for complex business processes. No ad-hoc saga implementations in application code.

### VIII.3 — Containerization

All services SHALL be containerized using Docker multi-stage builds with distroless base images for production stages. Multi-stage builds separate build-time tools from runtime artifacts. Final images contain only the runtime binary and its dependencies.

### VIII.4 — Small Project Profiles

For small projects that do not require a full microservice stack:
- **Flutter + Firebase**: Acceptable for consumer apps without complex backend logic. Firebase provides auth, Firestore, and Functions.
- **Rust CLI alone**: Acceptable for command-line tools. Use `clap` for argument parsing. No unnecessary service dependencies.

### VIII.5 — Infrastructure as Code

All infrastructure configuration SHALL be version-controlled. No manual infrastructure changes in production. Configuration drift is a constitutional violation.

---

## Article IX — Observability

### IX.1 — OpenTelemetry as Universal Standard

OpenTelemetry (OTel) is the mandatory observability standard for all services and applications. Every service MUST export:
- **Traces**: Distributed traces with span context propagation across service boundaries.
- **Metrics**: Application and business metrics (counters, histograms, gauges).
- **Logs**: Structured logs correlated with trace and span IDs.

### IX.2 — Export Protocol

All telemetry data SHALL be exported via OTLP (OpenTelemetry Protocol) to a configurable collector endpoint. The collector backend is flexible and project-specific.

### IX.3 — Flutter Observability

Flutter applications SHALL use `opentelemetry_dart` for tracing and metrics. User interactions, navigation events, and API calls MUST be instrumented. Trace context SHALL be propagated in outbound HTTP headers.

### IX.4 — Rust Observability

Rust services SHALL use `tracing` for structured logging and span-based tracing, with `tracing-opentelemetry` as the bridge to the OTel SDK. Every request handler MUST create a root span. Downstream calls MUST propagate span context.

### IX.5 — Backend Flexibility

The observability backend is not mandated. Acceptable backends include:
- SigNoz (recommended for self-hosted)
- ELK Stack (Elasticsearch + Logstash + Kibana)
- Prometheus + Grafana (for metrics-heavy workloads)
- Any OTLP-compatible backend

The application code MUST remain backend-agnostic. Backend configuration is in the collector, not the application.

### IX.6 — AI Feature Observability

AI-powered features (voice, inference, agent calls) MUST be traced end-to-end. Latency, token counts, error rates, and fallback invocations are mandatory metrics for any AI integration.

---

## Article X — Code Quality

### X.1 — Coverage Threshold

Test coverage SHALL be measured and MUST remain at or above **80%** for all production code. Coverage is measured by line coverage at minimum; branch coverage is strongly recommended. Coverage checks run in CI and failures block merge.

### X.2 — Architecture Boundary Enforcement

Module and layer boundaries defined in Articles VI and VII MUST be enforced by automated tooling:
- **Flutter**: `dart analyze` with custom lint rules or `dependency_validator`.
- **Rust**: Module visibility (`pub(crate)`, `pub(super)`) enforced by the compiler; architecture tests via `cargo-modules` or integration test assertions.

No boundary violations MAY be merged.

### X.3 — Public API Documentation

All public APIs (public functions, classes, methods, types) MUST have documentation comments. For Dart, `///` doc comments. For Rust, `///` doc comments with `cargo doc` generating valid documentation. Undocumented public APIs are a quality violation.

### X.4 — No Unresolved TODOs

`TODO` and `FIXME` comments MUST NOT be merged without a corresponding tracked issue reference in the comment. Format: `// TODO(#123): description` or `// FIXME(#456): description`. Untracked TODOs are prohibited.

### X.5 — Static Analysis

- **Flutter**: `flutter analyze` MUST pass with zero warnings. `dart format` MUST be applied. Custom lint rules in `analysis_options.yaml` are enforced.
- **Rust**: `cargo clippy -- -D warnings` MUST pass. `cargo fmt` MUST be applied. `rustfmt.toml` configuration is version-controlled.

### X.6 — Security Scanning

Dependencies SHALL be scanned for known vulnerabilities:
- **Dart/Flutter**: `dart pub audit`
- **Rust**: `cargo audit`

Critical or high severity vulnerabilities MUST be resolved before release.

---

## Article XI — AI-First Design

### XI.1 — Agent-Native Architecture

Systems incorporating AI capabilities SHALL be designed as first-class agent-native systems. This means:
- Core domain logic is expressed as composable, describable functions that agents can invoke.
- State is observable and inspectable by agents.
- Actions are idempotent where possible, enabling agent retry without side effects.

### XI.2 — Voice Interface Standards

Voice-enabled features SHALL use WebRTC for real-time audio transport. Voice sessions MUST be fully instrumented with OTLP tracing, capturing: session start/end, transcription latency, intent recognition, response generation time, and audio quality metrics.

### XI.3 — Generative UI

Generative UI features SHALL use schema-driven generation. The AI produces a structured JSON schema describing the UI; a deterministic renderer interprets the schema. No direct AI-generated HTML or widget code is executed without a schema validation step.

### XI.4 — Frontend Agent Integration

Frontend applications that integrate with AI agents SHALL use an event-driven architecture. Agent responses arrive as events; the UI subscribes to event streams. No blocking synchronous AI calls in the UI thread.

### XI.5 — Mandatory Fallback

Every AI-powered feature MUST have a defined fallback behavior for when the AI is unavailable, degraded, or returns an error. The fallback MUST be tested as part of the feature's test suite. A feature with no fallback is not considered complete.

### XI.6 — Privacy and Data Minimization

AI features MUST NOT send personally identifiable information (PII) to external AI services without explicit user consent and appropriate data handling agreements. Data sent to AI services SHALL be minimized to what is strictly necessary for the feature's function.

---

## Amendments

| Amendment | Date | Description | Ratified By |
|-----------|------|-------------|-------------|
| — | — | No amendments yet | — |

---

*This Constitution is versioned. Proposed amendments must be submitted as Forge change proposals and ratified by project maintainers before taking effect. Ratified amendments are appended to the table above and take effect from their ratification date.*
