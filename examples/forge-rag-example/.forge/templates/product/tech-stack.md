# Technology Stack

<!--
  This document is the canonical reference for technology choices across the project.
  Every technology listed here MUST have a documented justification.
  Changes to this document require a Forge change proposal and constitutional compliance check.
  
  Version each entry when the version changes — include the date of the change.
  Last updated: <!-- YYYY-MM-DD -->
-->

## Frontend

### Flutter / Dart

| Field             | Value                                                                               |
|-------------------|-------------------------------------------------------------------------------------|
| **Technology**    | Flutter                                                                             |
| **Language**      | Dart                                                                                |
| **Version**       | <!-- e.g., Flutter 3.x / Dart 3.x — pin to specific version -->                     |
| **Justification** | <!-- Why Flutter? What alternatives were considered and why were they rejected? --> |

**Key Libraries**:

| Library                 | Version          | Role                           | Justification                                                                            |
|-------------------------|------------------|--------------------------------|------------------------------------------------------------------------------------------|
| `flutter_bloc`          | <!-- version --> | State management               | Mandated by Article VI.3 of the Constitution. Predictable, testable, event-driven state. |
| `get_it`                | <!-- version --> | Service locator / DI container | Constructor injection with centralized registration. Works without BuildContext.         |
| `injectable`            | <!-- version --> | DI code generation             | Eliminates boilerplate registration code; integrates with `get_it`.                      |
| `retrofit`              | <!-- version --> | Type-safe HTTP client          | Generates type-safe API clients from annotated interfaces. Reduces manual parsing.       |
| `dio`                   | <!-- version --> | HTTP client (backing retrofit) | Interceptor-based HTTP; supports auth, logging, retry.                                   |
| `bdd_widget_test`       | <!-- version --> | BDD widget testing             | Mandated by Article II.3. Enables Gherkin-driven widget acceptance tests.                |
| `mocktail`              | <!-- version --> | Mocking library                | Null-safe mocking for unit tests. Preferred over `mockito` for Dart 3 compatibility.     |
| `opentelemetry_dart`    | <!-- version --> | Observability / OTel SDK       | Mandated by Article IX.3. Traces, metrics, logs via OTLP.                                |
| `intl`                  | <!-- version --> | Internationalization           | Mandated by Article VI.10. ARB-based string externalization.                             |
| `flutter_localizations` | <!-- version --> | Localization delegates         | Standard Flutter localization support; works with `intl`.                                |
| <!-- library -->        | <!-- version --> | <!-- role -->                  | <!-- justification -->                                                                   |

**Additional Notes**:

<!--
  Document any non-obvious configuration choices:
  - `analysis_options.yaml` rules that are customized
  - Flutter flavor/environment setup
  - Code generation setup (build_runner configuration)
  - Golden test configuration
-->

---

## Backend

### Rust

| Field             | Value                                                                     |
|-------------------|---------------------------------------------------------------------------|
| **Technology**    | Rust                                                                      |
| **Version**       | <!-- e.g., 1.77.0 — pin to MSRV (minimum supported Rust version) -->      |
| **Edition**       | <!-- e.g., 2021 -->                                                       |
| **Justification** | <!-- Why Rust? Performance, memory safety, systems programming needs? --> |

**Key Libraries (Crates)**:

| Crate                   | Version          | Role                          | Justification                                                                  |
|-------------------------|------------------|-------------------------------|--------------------------------------------------------------------------------|
| `tokio`                 | <!-- version --> | Async runtime                 | Mandated by Article VII.4. Industry standard; feature-complete async I/O.      |
| `tonic`                 | <!-- version --> | gRPC framework                | Mandated by Article VII.2. Type-safe gRPC from `.proto` definitions.           |
| `prost`                 | <!-- version --> | Protocol Buffers              | Code generation from `.proto` files; integrates with `tonic`.                  |
| `thiserror`             | <!-- version --> | Typed error derivation        | Mandated by Article VII.3 for library crates. Clean, derive-based error types. |
| `anyhow`                | <!-- version --> | Error context propagation     | Mandated by Article VII.3 for application crates. Rich error chains.           |
| `tracing`               | <!-- version --> | Structured logging + spans    | Mandated by Article IX.4. Integrates with OpenTelemetry.                       |
| `tracing-opentelemetry` | <!-- version --> | OTel bridge for tracing       | Connects `tracing` spans to the OTel SDK for OTLP export.                      |
| `opentelemetry`         | <!-- version --> | OTel SDK                      | Core SDK for traces and metrics export.                                        |
| `opentelemetry-otlp`    | <!-- version --> | OTLP exporter                 | Exports telemetry to any OTLP-compatible backend.                              |
| `cucumber`              | <!-- version --> | BDD test framework            | Mandated by Article VII.5 and Article II.4. Gherkin-driven acceptance tests.   |
| `mockall`               | <!-- version --> | Mock generation               | Derive-based mocking for trait-based test doubles.                             |
| `clap`                  | <!-- version --> | CLI argument parsing          | Mandated by Article VIII.4 for CLI projects. Derive-based, ergonomic.          |
| `serde`                 | <!-- version --> | Serialization/deserialization | Universal data serialization. JSON, TOML, YAML, Protobuf support via features. |
| <!-- crate -->          | <!-- version --> | <!-- role -->                 | <!-- justification -->                                                         |

**Additional Notes**:

<!--
  Document:
  - Workspace structure (single crate vs. cargo workspace)
  - MSRV policy
  - Clippy configuration (clippy.toml)
  - rustfmt configuration (rustfmt.toml)
  - Any `unsafe` crates in use and their documented justification (per Article VII.6)
-->

---

## Infrastructure

### API Gateway

| Field             | Value                                                                                    |
|-------------------|------------------------------------------------------------------------------------------|
| **Technology**    | Kong                                                                                     |
| **Version**       | <!-- version -->                                                                         |
| **Justification** | Mandated by Article VIII.1. REST↔gRPC transcoding; plugin ecosystem; declarative config. |

**Key Plugins / Configuration**:

| Plugin          | Purpose                  |
|-----------------|--------------------------|
| `grpc-gateway`  | REST to gRPC transcoding |
| `rate-limiting` | Per-consumer rate limits |
| `jwt`           | JWT authentication       |
| <!-- plugin --> | <!-- purpose -->         |

### Workflow Orchestration

| Field             | Value                                                                                       |
|-------------------|---------------------------------------------------------------------------------------------|
| **Technology**    | Temporal                                                                                    |
| **Version**       | <!-- version -->                                                                            |
| **SDK**           | <!-- Rust SDK / Go SDK / TypeScript SDK -->                                                 |
| **Justification** | Mandated by Article VIII.2. Durable workflows; built-in retry; workflow history visibility. |

### Containerization

| Field                    | Value                                                                            |
|--------------------------|----------------------------------------------------------------------------------|
| **Technology**           | Docker                                                                           |
| **Base Image (build)**   | <!-- e.g., rust:1.77-bookworm -->                                                |
| **Base Image (runtime)** | <!-- e.g., gcr.io/distroless/cc-debian12 -->                                     |
| **Justification**        | Mandated by Article VIII.3. Multi-stage + distroless for minimal attack surface. |

### Container Orchestration

| Field             | Value                                        |
|-------------------|----------------------------------------------|
| **Technology**    | <!-- e.g., Kubernetes, Cloud Run, Fly.io --> |
| **Version**       | <!-- version / managed service -->           |
| **Justification** | <!-- Why this choice? -->                    |

### Additional Infrastructure

| Component                    | Technology                | Version          | Justification          |
|------------------------------|---------------------------|------------------|------------------------|
| <!-- e.g., Database -->      | <!-- e.g., PostgreSQL --> | <!-- version --> | <!-- justification --> |
| <!-- e.g., Cache -->         | <!-- e.g., Redis -->      | <!-- version --> | <!-- justification --> |
| <!-- e.g., Message Queue --> | <!-- e.g., NATS -->       | <!-- version --> | <!-- justification --> |

---

## Observability

Mandated by Article IX. All observability choices MUST be OTel-compatible.

| Component           | Technology                                     | Version          | Notes                               |
|---------------------|------------------------------------------------|------------------|-------------------------------------|
| **OTel Collector**  | <!-- e.g., OpenTelemetry Collector Contrib --> | <!-- version --> | Receives OTLP; fans out to backends |
| **Tracing Backend** | <!-- e.g., SigNoz, Jaeger, Tempo -->           | <!-- version --> | <!-- justification -->              |
| **Metrics Backend** | <!-- e.g., Prometheus + Grafana, SigNoz -->    | <!-- version --> | <!-- justification -->              |
| **Log Backend**     | <!-- e.g., Loki, ELK, SigNoz -->               | <!-- version --> | <!-- justification -->              |
| **Alerting**        | <!-- e.g., Grafana Alerting, PagerDuty -->     | <!-- version --> | <!-- justification -->              |

**OTLP Endpoint Configuration**:

<!--
  Document where services should send telemetry.
  Keep credentials out of this document — reference environment variable names only.
  
  Example:
  - Endpoint: `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable
  - Protocol: gRPC (port 4317) or HTTP/protobuf (port 4318)
  - Auth: `OTEL_EXPORTER_OTLP_HEADERS` for bearer token auth
-->

---

## AI / ML

<!--
  Document AI and ML components. If AI features are not present, note that here.
  If AI features exist, they MUST comply with Article XI of the Constitution.
-->

| Component                   | Technology                                     | Version              | Role            | Justification                                            |
|-----------------------------|------------------------------------------------|----------------------|-----------------|----------------------------------------------------------|
| <!-- e.g., LLM Provider --> | <!-- e.g., OpenAI, Anthropic, local Ollama --> | <!-- API version --> | <!-- role -->   | <!-- justification -->                                   |
| <!-- e.g., Voice -->        | <!-- e.g., WebRTC + Deepgram -->               | <!-- version -->     | Real-time voice | Mandated by Article XI.2 when voice features are present |
| <!-- e.g., Vector DB -->    | <!-- e.g., Qdrant, pgvector -->                | <!-- version -->     | <!-- role -->   | <!-- justification -->                                   |
| <!-- component -->          | <!-- technology -->                            | <!-- version -->     | <!-- role -->   | <!-- justification -->                                   |

**Fallback Strategy**:

<!--
  Document the fallback behavior for each AI feature (mandated by Article XI.5).
  Example:
  - LLM unavailable → cached response for read paths; graceful error + queue for write paths
  - Voice unavailable → text input fallback with same functionality
-->

---

## Development Tools

| Tool                  | Version                        | Purpose                                | Notes                                            |
|-----------------------|--------------------------------|----------------------------------------|--------------------------------------------------|
| **Claude Code**       | latest                         | AI-assisted development                | Forge framework primary interface                |
| **Context7 MCP**      | `@upstash/context7-mcp@latest` | Live library documentation             | Configured in `.mcp.json`; mandated by CLAUDE.md |
| `build_runner` (Dart) | <!-- version -->               | Code generation                        | Generates DI, API clients, mocks                 |
| `flutter_gen`         | <!-- version -->               | Asset code generation                  | Type-safe asset references                       |
| `cargo-audit`         | <!-- version -->               | Rust dependency security scanning      | Mandated by Article X.6                          |
| `cargo-modules`       | <!-- version -->               | Rust module architecture visualization | Architecture boundary verification               |
| `cargo-tarpaulin`     | <!-- version -->               | Rust code coverage                     | Mandated coverage threshold: ≥ 80% (Article X.1) |
| `lcov` / `genhtml`    | <!-- version -->               | Flutter/Dart coverage reporting        | Visualizes `flutter test --coverage` output      |
| <!-- tool -->         | <!-- version -->               | <!-- purpose -->                       | <!-- notes -->                                   |

**CI/CD Platform**:

| Field               | Value                                               |
|---------------------|-----------------------------------------------------|
| **Platform**        | <!-- e.g., GitHub Actions, GitLab CI, Buildkite --> |
| **Config location** | <!-- e.g., .github/workflows/ -->                   |
| **Key pipelines**   | <!-- e.g., PR checks, release, nightly coverage --> |

**Required CI Checks (all must pass before merge)**:

- [ ] `flutter analyze` — zero warnings
- [ ] `flutter test --coverage` — coverage ≥ 80%
- [ ] Golden tests pass
- [ ] `cargo clippy -- -D warnings` — zero warnings
- [ ] `cargo test` — all tests pass (unit + BDD)
- [ ] `cargo audit` — no critical/high vulnerabilities
- [ ] `dart pub audit` — no critical/high vulnerabilities
- [ ] Constitutional compliance gate (`/forge:plan` output reviewed)
