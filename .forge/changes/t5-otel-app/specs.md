# Specifications: t5-otel-app
<!-- Status: specified -->
<!-- Schema: full-stack-monorepo -->

**Namespace** : `FR-T5-OTA-*` / `NFR-T5-OTA-*` (distinct from Phase A's
`FR-OTEL-*`). **Constitution** : v1.1.0. Pas d'amendement requis.

## Source Documents

| Field             | Value                                                                                                                                            |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| **ADR base**      | `t5-otel-stack` archived 2026-05-10 (FR-OTEL-001..082 + ADR-OTEL-001..007 — Phase A infra)                                                       |
| **Plan ref**      | `docs/new-archetypes-plan.md` L994-1000 (Phase B = SDK instrumentation in `examples/forge-fsm-example/`)                                        |
| **Roadmap ref**   | `.forge/changes/t5-otel-stack/proposal.md` § Scope Out items 1 & 2 ("NOT instrumenting backend Rust code" + "NOT instrumenting frontend Dart code")|
| **Standard ref (Rust)** | `.forge/standards/rust/opentelemetry.md` (Resource attrs, batch exporter, traceparent propagation, gRPC metadata extractor)                |
| **Standard ref (Flutter)** | `.forge/standards/flutter/opentelemetry.md` (BatchSpanProcessor, TracingInterceptor, BLoC observer, navigation observer, W3C traceparent) |
| **Standard ref (cross-cutting)** | `.forge/standards/observability.yaml` v1.1.0 (sampler `parentbased_traceidratio`, ratios per env, OTLP)                          |
| **Pattern reuse** | `t5-connect-codegen` archived 2026-05-06 (Connect handler ADR-T5-001 — OTel layer applied **outside** `connectrpc::Router::into_axum_service()` via Tower) |
| **Deferred test** | `t5-connect-codegen/tasks.md` § "DEFERRED 2026-05-06" — `_test_t5_l2_traceparent_dual` waits on Phase C (E2E through Envoy/Kong)                |

No new external standard pinned. SDK crates / packages pin themselves
via Context7 lookup at design time (Q-001).

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Rust backend SDK init (FR-T5-OTA-001..010)

##### FR-T5-OTA-001 — Telemetry module exists

`examples/forge-fsm-example/backend/crates/infrastructure/src/telemetry/mod.rs`
MUST exist as the SDK init entry point, exposed via the
`infrastructure::telemetry` module path. The module SHALL declare a
public `setup_telemetry(config: &TelemetryConfig) -> anyhow::Result<SdkTracerProvider>`
function matching the `rust/opentelemetry.md` standard's signature.

##### FR-T5-OTA-002 — TelemetryConfig struct

A `TelemetryConfig` struct MUST exist with at minimum the four fields
mandated by `rust/opentelemetry.md` § Setup :

```rust
pub struct TelemetryConfig {
    pub service_name: String,
    pub service_version: String,
    pub environment: String,
    pub otlp_endpoint: String,
    pub sample_rate: f64,
}
```

The `From<env>` constructor MUST read `OTEL_SERVICE_NAME`,
`OTEL_EXPORTER_OTLP_ENDPOINT`, and an environment indicator
(`DEPLOYMENT_ENV` or fall through to `dev`).

##### FR-T5-OTA-003 — Resource attributes

`Resource::new(...)` MUST include the four mandatory attributes
(`service.name`, `service.version`, `deployment.environment`,
`host.name`) per `rust/opentelemetry.md` § Setup. Service name SHALL
default to `fsm-backend`.

##### FR-T5-OTA-004 — OTLP exporter

`opentelemetry_otlp::SpanExporter::builder().with_<transport>().with_endpoint(...)`
MUST be invoked. Transport (gRPC `with_tonic()` vs HTTP `with_http()`)
locked at design time (Q-002, will be ADR-T5-OTA-002).

##### FR-T5-OTA-005 — Sampler

The SDK sampler MUST be configured per the resolution of Q-003 at
design time. The collector enforces the env-tier ratio (Phase A) ;
the SDK ships the matching head-side counterpart (`AlwaysOn` or
`ParentBased(TraceIdRatioBased)` — locked at design time).

##### FR-T5-OTA-006 — `tracing-opentelemetry` bridge

`tracing-opentelemetry::layer().with_tracer(provider.tracer(...))`
MUST be composed into the `tracing_subscriber::registry()` alongside
the existing `EnvFilter` + JSON `fmt` layer per `rust/opentelemetry.md`.

##### FR-T5-OTA-007 — Graceful shutdown

`bin-server/main.rs` MUST call `tracer_provider.shutdown()` on
process termination (`tokio::signal::ctrl_c` OR
`CancellationToken` cancelled) BEFORE the runtime exits, so buffered
spans are flushed. Per `rust/opentelemetry.md` § Graceful Shutdown.

##### FR-T5-OTA-008 — bin-server bootstrap

`examples/forge-fsm-example/backend/bin-server/src/main.rs` MUST be
rewritten from the scaffolder default (`println!("Hello, world!")`)
to :
1. Load `TelemetryConfig` from env.
2. Call `setup_telemetry(&config)` and bind the returned provider.
3. Start the axum + connectrpc server (existing
   `t5-connect-codegen` glue).
4. Await shutdown signal, call `provider.shutdown()`.

##### FR-T5-OTA-009 — `#[tracing::instrument]` annotations

At least the demo-005 use case (the Greeter handler in
`crates/application/`) MUST carry a `#[tracing::instrument]` macro
following `rust/opentelemetry.md` § Instrumentation : `skip(self)` on
secrets-bearing receivers, `fields(otel.kind = "internal")`, dynamic
attributes recorded via `span.record()`.

##### FR-T5-OTA-010 — No PII in attributes

Any span attribute set in this change MUST NOT contain emails,
passwords, tokens, or names per `rust/opentelemetry.md` § Rules.
Asserted at code-review and constitution-linter time
(`Article XI.6` privacy / data minimisation).

---

#### Cluster 2 — Rust server-side middleware (FR-T5-OTA-020..025)

##### FR-T5-OTA-020 — axum TraceLayer

The axum top-level router used to mount the connectrpc service MUST
wrap a `tower_http::trace::TraceLayer::new_for_http()` (or `_for_grpc()`
on the tonic side) configured with `make_span_with` that pulls the
W3C `traceparent` from the incoming request headers via
`TraceContextPropagator::extract`. Server span `otel.kind = "server"`.

##### FR-T5-OTA-021 — connectrpc OTel layer composition

Per `t5-connect-codegen/design.md` ADR-T5-001, the OTel layer SHALL
be applied **outside** the `connectrpc::Router::into_axum_service()`
call : the connectrpc service is mounted under `/connect`, and the
parent axum router carries the `TraceLayer`. This preserves the
contract established by `t5-connect-codegen` (FR-T5-CC-013).

##### FR-T5-OTA-022 — tonic gRPC interceptor

The legacy tonic gRPC server (still mounted alongside the connectrpc
service per `t5-connect-codegen` non-breaking guarantee) MUST extract
`traceparent` from `tonic::metadata::MetadataMap` via the
`MetadataMapCarrier` pattern shown in `rust/opentelemetry.md`
§ Context Propagation in gRPC.

##### FR-T5-OTA-023 — Outbound traceparent injection helper

A reusable helper module
`crates/infrastructure/src/telemetry/propagation.rs` MUST expose :
- A `HeaderMapCarrier` adapter implementing
  `opentelemetry::propagation::Injector` for `reqwest::HeaderMap`.
- A `MetadataMapCarrier` adapter implementing the same for
  `tonic::metadata::MetadataMap`.

Even though demo-005 has no outbound HTTP yet, this helper ships in
Phase B so adopter-copy-paste reuses it (Phase A's `forge upgrade`
ergonomics analogue).

##### FR-T5-OTA-024 — Middleware ordering

Tower middleware order on the axum router MUST be (outermost first) :
1. `TraceLayer` (creates server span ; extracts traceparent).
2. Any auth / rate-limit layers (none in demo-005).
3. The connectrpc service.

The order MUST be documented inline in `bin-server/main.rs` for
adopter clarity.

##### FR-T5-OTA-025 — `tower-http` workspace dependency

`backend/Cargo.toml` `[workspace.dependencies]` MUST gain
`tower-http = { version = "...", features = ["trace"] }`. Exact pin
locked at design time (Q-001 sibling — Context7 review of
`/tower-rs/tower-http`).

---

#### Cluster 3 — Demo-005 traceparent round-trip (FR-T5-OTA-030..033)

##### FR-T5-OTA-030 — Greeter use case spans

The Rust Greeter handler in
`crates/grpc-api/src/lib.rs` (or its connectrpc adapter, at impl
discretion) MUST create a child span on each `Greet` call ; the
span name SHALL be `greeter.greet` ; attributes SHALL include
`rpc.system = "connect"` (or `"grpc"` for the tonic path),
`rpc.service = "greeting.v1.GreeterService"`, `rpc.method = "Greet"`.

##### FR-T5-OTA-031 — Span parent linkage

The child span created in FR-T5-OTA-030 MUST inherit its parent
context from the W3C `traceparent` header extracted by the
middleware (FR-T5-OTA-020 / FR-T5-OTA-022). Asserted in the L2 smoke
test by capturing the debug exporter output and confirming `spanId`
of the child equals the `parentSpanId` carried by the request.

##### FR-T5-OTA-032 — Greeter response unchanged

The wire-level response of `Greet` (proto contract `greeting.v1`)
MUST remain `Hello, {name}!` — no field added, no field removed.
Telemetry is observability only ; protocol contract is frozen at
`shared/protos/v1/greeting/greeting.proto`.

##### FR-T5-OTA-033 — demo-005 documentation

`examples/forge-fsm-example/docs/demo-005-connect-greeting.md` (or
`README.md` if the doc tree convention is flat) MUST gain a
`## Trace this in SigNoz` section with three subsections :
1. Spinning up the local dev cluster (`task dev`).
2. Triggering the demo-005 round trip.
3. Reading the resulting trace tree (Flutter root → axum server →
   connectrpc handler → application use case) in the SigNoz UI.

---

#### Cluster 4 — Flutter SDK init (FR-T5-OTA-040..050)

##### FR-T5-OTA-040 — Telemetry setup module exists

`examples/forge-fsm-example/frontend/lib/core/telemetry/telemetry_setup.dart`
MUST exist exposing a `Future<void> setupTelemetry({required AppConfig config})`
function matching the `flutter/opentelemetry.md` § SDK Initialization
signature.

##### FR-T5-OTA-041 — Dart OTel package import

The package import path used by `telemetry_setup.dart` MUST be the
canonical pub.dev package name resolved at design time (Q-001).
The standard's example uses `package:opentelemetry/api.dart` +
`package:opentelemetry/sdk.dart` +
`package:opentelemetry/exporter_otlp_<transport>.dart` ; the
final import path is locked by ADR-T5-OTA-001.

##### FR-T5-OTA-042 — pubspec dependency

`examples/forge-fsm-example/frontend/pubspec.yaml` `dependencies:`
section MUST gain the OTel pub.dev package(s) at the version pin
resolved by ADR-T5-OTA-001. `pubspec.lock` SHOULD be regenerated by
`flutter pub get` ; lock-file is committed.

##### FR-T5-OTA-043 — Resource attributes

The `Resource` MUST set the four mandatory attributes per
`flutter/opentelemetry.md` :
- `ResourceAttributes.serviceName` = `fsm-frontend` (default).
- `ResourceAttributes.serviceVersion` = `1.0.0+1` (read from
  `pubspec.yaml`).
- `ResourceAttributes.deploymentEnvironment` = `'dev'` |
  `'staging'` | `'prod'` from build flavor.
- `device.platform` = `Platform.operatingSystem`.

##### FR-T5-OTA-044 — BatchSpanProcessor

The exporter MUST be wrapped in a `BatchSpanProcessor` with the
standard's defaults : `maxExportBatchSize: 512`,
`scheduledDelayMillis: 5000`, `exportTimeoutMillis: 30000`.

##### FR-T5-OTA-045 — OTLP exporter

The OTLP exporter (gRPC vs HTTP) MUST match the resolution of Q-002
at design time. Insecure mode MUST be allowed for `dev` /
`staging` ; production MUST default to `insecure: false`.

##### FR-T5-OTA-046 — Global tracer provider

`registerGlobalTracerProvider(tracerProvider)` MUST be invoked at the
end of `setupTelemetry` so subsequent code can call
`globalTracerProvider.getTracer(...)` per the standard.

##### FR-T5-OTA-047 — `main.dart` bootstrap

`examples/forge-fsm-example/frontend/lib/main.dart` MUST be
rewritten from the `flutter create` default counter to :
1. `WidgetsFlutterBinding.ensureInitialized()`.
2. Call `await setupTelemetry(...)` BEFORE `runApp`.
3. Register `Bloc.observer = TracingBlocObserver()`.
4. Pass `[TracingNavigationObserver()]` to the `MaterialApp`'s
   `navigatorObservers`.
5. Hook `FlutterError.onError` and `PlatformDispatcher.instance.onError`
   to the `ErrorReporter` (per the standard).
6. Run the existing greeting feature screen as `home:`.

##### FR-T5-OTA-048 — TracingNavigationObserver class

`lib/core/telemetry/observers/tracing_navigation_observer.dart` MUST
exist as a `NavigatorObserver` subclass following
`flutter/opentelemetry.md` § Navigation Observer.

##### FR-T5-OTA-049 — TracingBlocObserver class

`lib/core/telemetry/observers/tracing_bloc_observer.dart` MUST exist
as a `BlocObserver` subclass following `flutter/opentelemetry.md`
§ BLoC Observer. Both `onEvent` and `onError` SHALL emit spans.

##### FR-T5-OTA-050 — ErrorReporter class

`lib/core/telemetry/error_reporter.dart` MUST exist with the
`ErrorReporter` class shown in `flutter/opentelemetry.md` § Error
Instrumentation. `get_it` registration is `@lazySingleton` per
Article VI.4.

---

#### Cluster 5 — Flutter Connect/HTTP traceparent injection (FR-T5-OTA-060..064)

##### FR-T5-OTA-060 — TracingInterceptor exists

`lib/core/telemetry/interceptors/tracing_interceptor.dart` MUST
exist as a `dio.Interceptor` subclass following the body of
`flutter/opentelemetry.md` § HTTP Instrumentation via Dio
Interceptor (header-injection via `W3CTraceContextPropagator`,
`SpanKind.client`, end-on-response, `recordException` on error).

##### FR-T5-OTA-061 — Connect client wired with the interceptor

The Connect/Dart client used by
`lib/features/greeting/data/repository/greeting_repository_impl.dart`
to call the backend MUST attach the `TracingInterceptor` to its
underlying transport. Because the Connect/Dart client wraps `dio`
under the hood, attaching the interceptor on the `dio.Interceptors`
list is sufficient.

##### FR-T5-OTA-062 — `traceparent` header asserted in tests

A unit test in `test/core/telemetry/tracing_interceptor_test.dart`
MUST assert that a request emitted through the interceptor carries
a `traceparent` header matching the W3C regex
`^00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]$`.

##### FR-T5-OTA-063 — Path cardinality control

The interceptor MUST sanitize URL paths (replace UUIDs and numeric
IDs with `{id}` per the standard's `_sanitizePath` helper) before
using them as the span name, to keep span name cardinality bounded.

##### FR-T5-OTA-064 — `dio` workspace dependency

If the Connect/Dart client does not already pull `dio` transitively,
`pubspec.yaml` MUST gain `dio:` as a direct dependency at a version
pin locked by Q-001 sibling resolution.

---

#### Cluster 6 — Env-driven config (FR-T5-OTA-070..072)

##### FR-T5-OTA-070 — `.env.example` documents the trio

`examples/forge-fsm-example/.env.example` MUST exist (or be created
if absent) documenting at minimum :
- `OTEL_EXPORTER_OTLP_ENDPOINT` — default
  `http://localhost:4318` (HTTP) or `:4317` (gRPC) per Q-002 +
  `:4318` for HTTP path. Inside the cluster, defaults to
  `http://fsm-otel-collector:4318` (matches Phase A
  `infra/observability/otel-collector-config.yaml` HTTP receiver).
- `OTEL_SERVICE_NAME` — defaults `fsm-backend` / `fsm-frontend`
  per layer.
- `OTEL_RESOURCE_ATTRIBUTES` — comma-separated key=value list,
  passed through to the resource builder.
- `DEPLOYMENT_ENV` — `dev` | `staging` | `prod`.

##### FR-T5-OTA-071 — Defaults match the in-cluster collector

When env vars are unset, both stacks MUST default to
`http://fsm-otel-collector:<port>` per the existing service name
established by the Phase A overlays. Local-dev (host machine)
adopters override via `.env`.

##### FR-T5-OTA-072 — Secrets are NEVER read from env attributes

`OTEL_RESOURCE_ATTRIBUTES` MUST NOT carry secrets. Documented in
`.env.example` and in the Aegis warning section of
`infra/CLAUDE.md` (already shipped by Phase A — referenced, not
modified).

---

#### Cluster 7 — Test harness `t5-otel-app.test.sh` (FR-T5-OTA-080..082)

##### FR-T5-OTA-080 — Harness exists

`.forge/scripts/tests/t5-otel-app.test.sh` MUST exist mirroring the
`t5-otel.test.sh` layout (bash header,
`source _helpers.sh`, PASS/FAIL counters, `--level 1,2` parsing,
`print_summary`).

##### FR-T5-OTA-081 — L1 coverage ≥ 16 tests

Minimum 16 L1 tests covering :
- 4 Rust SDK init tests : telemetry module exists (FR-T5-OTA-001),
  Cargo.toml has the OTel crates (FR-T5-OTA-004 / FR-T5-OTA-025),
  bin-server main.rs has setup_telemetry call (FR-T5-OTA-008),
  graceful shutdown call present (FR-T5-OTA-007).
- 3 Rust middleware tests : axum TraceLayer wired
  (FR-T5-OTA-020), tonic interceptor present (FR-T5-OTA-022),
  HeaderMapCarrier helper exists (FR-T5-OTA-023).
- 4 Flutter SDK init tests : telemetry_setup.dart exists
  (FR-T5-OTA-040), pubspec.yaml has the OTel pkg
  (FR-T5-OTA-042), main.dart has setupTelemetry call
  (FR-T5-OTA-047), navigation observer + bloc observer files exist
  (FR-T5-OTA-048 / FR-T5-OTA-049).
- 2 Flutter Connect tests : tracing_interceptor.dart exists
  (FR-T5-OTA-060), greeting_repository_impl wires the interceptor
  (FR-T5-OTA-061).
- 2 demo-005 round-trip tests : application use case carries
  `#[tracing::instrument]` (FR-T5-OTA-009), demo doc has
  "Trace this in SigNoz" section (FR-T5-OTA-033).
- 1 env config test : `.env.example` mentions the trio
  (FR-T5-OTA-070).

##### FR-T5-OTA-082 — L2 fixtures (≥ 2 smoke tests)

Two L2 smoke tests :
1. `cargo build -p bin-server` succeeds with the new SDK deps in
   the workspace (compile-only, no run). FR-T5-OTA-008 closure.
2. `flutter analyze` passes on the example frontend tree (no new
   lint warnings ; the OTel imports resolve). FR-T5-OTA-047
   closure.

A third optional L2 — running `bin-server` against a stub OTLP
receiver and asserting at least one span lands — is **deferred**
to Phase C. The L2 layer in Phase B stays compile-time only.

---

#### Cluster 8 — CI registration (FR-T5-OTA-090)

##### FR-T5-OTA-090 — `forge-ci.yml` matrix entry

`.github/workflows/forge-ci.yml` `harness` job MUST register
`t5-otel-app.test.sh` immediately after `t5-otel.test.sh` with
`--level 1`. L2 smoke tests run in a separate matrix entry that
sets up Rust + Flutter toolchains (or are gated behind a
`with-toolchain: true` matrix axis ; locked at design time).

---

#### Cluster 9 — Documentation + spec consolidation (FR-T5-OTA-100..103)

##### FR-T5-OTA-100 — `.forge/specs/otel-app.md` consolidation

A new consolidated spec
`.forge/specs/otel-app.md` MUST be created at archive time merging
all `FR-T5-OTA-*` and `NFR-T5-OTA-*` requirements from this change
into the canonical spec tree, mirroring how
`.forge/specs/otel-stack.md` consolidates `FR-OTEL-*`.

##### FR-T5-OTA-101 — `docs/ARCHETYPES.md` row update

The flagship row in `docs/ARCHETYPES.md` MUST gain a one-line
mention that the example project ships SDK instrumentation
(traces) for backend + frontend, in addition to the infra YAMLs
shipped at Phase A.

##### FR-T5-OTA-102 — `CHANGELOG.md` entry

`CHANGELOG.md` MUST gain an entry under `## [Unreleased]` flagging :
Rust OTel SDK init (`tracing-opentelemetry` bridge, OTLP exporter),
Flutter OTel SDK init (BatchSpanProcessor, TracingInterceptor,
BLoC + navigation observers), demo-005 traceparent round-trip,
`.env.example` config trio.

##### FR-T5-OTA-103 — Per-layer CLAUDE.md unaffected

`backend/CLAUDE.md` and `frontend/CLAUDE.md` (per-layer routing)
MUST NOT need edits — they already declare `rust/opentelemetry`
and `flutter/opentelemetry` standards as load-on-trigger. This
change validates that declaration without re-anchoring it.

---

### Non-Functional Requirements

#### NFR-T5-OTA-001 — Snapshot tarball budget

The example project does NOT ship inside the
`.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz` (only
the template does, per the existing `b1-scaffolder` convention).
Therefore the snapshot tarball size is **not affected** by this
change. Budget is N/A — kept as a tracked NFR for symmetry with
Phase A's NFR-OTEL-001 ; expected delta = 0 KB.

#### NFR-T5-OTA-002 — Backward compatibility (build green)

After this change, `cargo build -p bin-server` AND `flutter build`
on `examples/forge-fsm-example/` MUST succeed without manual
intervention. The dependency additions are additive ; no existing
import is broken.

#### NFR-T5-OTA-003 — Article V audit trail

Every task in `tasks.md` MUST carry a `[Story: FR-T5-OTA-XXX]` tag.

#### NFR-T5-OTA-004 — No new app-side framework dep beyond OTel

This change MUST NOT introduce any unrelated runtime dependency.
The accepted additions are limited to the OTel crate / pub.dev
families (`opentelemetry-*`, `tracing-opentelemetry`, `tower-http`
for the trace feature, `opentelemetry` Dart pkg). Anything else is
a constitutional violation surfaced by code review.

#### NFR-T5-OTA-005 — Performance budget (harness)

Harness `t5-otel-app.test.sh --level 1` MUST complete in ≤ 8 s
wall-clock (looser than Phase A's 5 s because L1 reads more files
across more layers). L2 budget : ≤ 90 s (compile-time of
bin-server + `flutter analyze`).

#### NFR-T5-OTA-006 — No PII telemetry

Span attributes MUST NOT carry emails, passwords, tokens, or names.
Asserted by code review (the `[Story: FR-T5-OTA-010]` tag links to
this NFR via `rust/opentelemetry.md` rules).

#### NFR-T5-OTA-007 — Span export does not block app startup

`setup_telemetry` MUST return within 500 ms wall-clock on a fresh
process. The OTLP exporter creation SHALL be lazy ; the first
batch flush happens asynchronously after the user emits the first
span.

---

## BDD Acceptance Criteria

The user-facing surface this change touches is the demo-005-connect-greeting
round trip. The Article II.1 minimum scenario :

```gherkin
Feature: Distributed tracing across the demo-005 round trip
  As a developer running the forge-fsm-example flagship project
  I want pressing the "Greet" button to produce a connected backend span tree
  So that I can see the full request path in SigNoz with a single traceId

  Background:
    Given the local dev cluster is running ("task dev")
    And the OTel collector is reachable at http://fsm-otel-collector:4318
    And the SigNoz UI is reachable at http://localhost:3301

  Scenario: Flutter HTTP request produces a connected backend span tree
    Given the Flutter app is launched and the greeting screen is displayed
    When the user types "Forge" in the name field
    And the user taps the "Greet" button
    Then a span "user.interaction greet" is started in the Flutter SDK
    And a span "POST /connect/greeting.v1.GreeterService/Greet" is started by the TracingInterceptor
    And the outbound request carries a "traceparent" header matching "00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]"
    And the Rust axum middleware extracts the parent context from "traceparent"
    And the connectrpc handler creates a child span "greeter.greet" inheriting that context
    And the application use case (annotated with #[tracing::instrument]) creates a grand-child span
    And all four spans share the same traceId in the OTLP export
    And the SigNoz UI displays a single trace tree connecting Flutter → axum → connectrpc → application
```

Step definitions live alongside the harness :
- Flutter `bdd_widget_test` for the screen-side scenario steps
  (`Given … displayed`, `When user taps`).
- Rust `cucumber-rs` step definitions for the backend assertions
  (`Then connectrpc creates a child span`, `Then traceId matches`).

The full `.feature` file SHALL ship at
`examples/forge-fsm-example/test/features/demo_005_traceparent.feature`.

A second BDD scenario (Phase C scope, **out of this change**) will
extend the trace tree through Envoy / Kong : that is the
`_test_t5_l2_traceparent_dual` deferred from `t5-connect-codegen`.

---

## Anti-Hallucination Pass

For each FR :

- **Testable** : every FR is asserted by at least one test in
  `t5-otel-app.test.sh` (mapping captured in `tasks.md` during
  `/forge:plan`).
- **Unambiguous** : 3 ambiguities flagged in `open-questions.md`
  (Q-001 Dart pkg name + Q-002 OTLP transport + Q-003 SDK sampler)
  for `/forge:design` resolution. No inline `[NEEDS CLARIFICATION:]`
  markers in this `specs.md` because every ambiguity is
  cross-referenced to an open question.
- **Constitution-compliant** : Articles I (TDD), II (BDD scenario
  required for user-facing greeting round trip), III (specs first),
  V (audit trail), VI (Flutter architecture — `core/` slice for
  cross-cutting telemetry), VII (Rust architecture —
  infrastructure layer for SDK adapter), IX (observability),
  XI.6 (privacy / no PII), XII (governance — no standard bump
  needed). All honored.

---

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none in this `specs.md`.
All ambiguities tracked in `open-questions.md` :

- **Q-001** (FR-T5-OTA-041 / FR-T5-OTA-042, Dart pkg + version) →
  to be resolved in `design.md` ADR-T5-OTA-001 via Context7
  review of the canonical OTel-Dart pub.dev package.
- **Q-002** (FR-T5-OTA-004 / FR-T5-OTA-045, OTLP transport
  per layer) → to be resolved in `design.md` ADR-T5-OTA-002 with
  per-layer justification (Rust gRPC vs Dart HTTP).
- **Q-003** (FR-T5-OTA-005, SDK-side sampler shape) → to be
  resolved in `design.md` ADR-T5-OTA-003 (`AlwaysOn` vs
  `ParentBased(TraceIdRatioBased)`).
