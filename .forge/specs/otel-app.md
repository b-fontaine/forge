# Spec: otel-app

<!-- Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation in flagship example. -->
<!-- Source change : `.forge/changes/t5-otel-app/` (archived 2026-05-12). -->
<!-- Phase A counterpart : `.forge/specs/otel-stack.md` (infra side, archived 2026-05-10). -->

**Namespace** : `FR-T5-OTA-*` / `NFR-T5-OTA-*` (distinct from Phase A's
`FR-OTEL-*` namespace).
**Constitution** : v1.1.0. Pas d'amendement requis (additive
SDK instrumentation in the flagship example ; no new article, no
standard amendment beyond the v1.1.0 realign of
`flutter/opentelemetry.md` delivered by the sibling change
`t5-otel-dart-api-realign`).

**Standards consumed** :
- `.forge/standards/rust/opentelemetry.md` v1.0.0
  (Resource attrs, batch exporter, traceparent propagation, gRPC
  metadata extractor).
- `.forge/standards/flutter/opentelemetry.md` **v1.1.0**
  (realigned to `opentelemetry: 0.18.11` Workiva pub.dev pkg by the
  sibling change `t5-otel-dart-api-realign`, ratifying Q-004 ; the
  example Dart code in this change is the first adopter of the
  v1.1.0 surface).
- `.forge/standards/observability.yaml` v1.1.0
  (sampler `parentbased_traceidratio`, ratios per env, OTLP).

**Templates** : N/A. The instrumentation is example-scoped ; the
template tree under `.forge/templates/archetypes/full-stack-monorepo/`
keeps its scaffolder-default state. Promotion to the template is a
T6 (B.8) concern when the flagship migrates to `2.0.0`.

**Example mirror** :
`examples/forge-fsm-example/backend/crates/infrastructure/src/telemetry/`
+ `examples/forge-fsm-example/frontend/lib/core/telemetry/`.

**Harness** : `.forge/scripts/tests/t5-otel-app.test.sh`
(16 L1 hermetic + 2 L2 toolchain-gated).

---

## Functional Requirements

### Cluster 1 — Rust backend SDK init (FR-T5-OTA-001..010)

| ID            | Requirement summary                                                                                                                                                                                                                                                                                  |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FR-T5-OTA-001 | `crates/infrastructure/src/telemetry/mod.rs` exists with public `setup_telemetry`.                                                                                                                                                                                                                   |
| FR-T5-OTA-002 | `TelemetryConfig` struct with `service_name`, `service_version`, `environment`, `otlp_endpoint`, `sample_rate` ; `from_env()` constructor.                                                                                                                                                          |
| FR-T5-OTA-003 | `Resource::new(...)` includes `service.name`, `service.version`, `deployment.environment`, `host.name`.                                                                                                                                                                                              |
| FR-T5-OTA-004 | OTLP exporter via `opentelemetry_otlp::SpanExporter::builder().with_http().with_protocol(Protocol::HttpBinary).with_endpoint(...)` per ADR-T5-OTA-002.                                                                                                                                                |
| FR-T5-OTA-005 | SDK sampler `ParentBased(TraceIdRatioBased(rate))` per ADR-T5-OTA-003 (env-tier ratio is enforced collector-side per ADR-OTEL-001).                                                                                                                                                                 |
| FR-T5-OTA-006 | `tracing-opentelemetry::layer().with_tracer(...)` composed into `tracing_subscriber::registry()` alongside `EnvFilter` + JSON `fmt`.                                                                                                                                                                |
| FR-T5-OTA-007 | `bin-server/main.rs` calls `provider.shutdown()` on `tokio::signal::ctrl_c()` so buffered spans are flushed before the runtime exits.                                                                                                                                                                |
| FR-T5-OTA-008 | `bin-server/main.rs` bootstrap : load `TelemetryConfig` → `setup_telemetry()` → axum + connectrpc server → shutdown signal → `provider.shutdown()`.                                                                                                                                                  |
| FR-T5-OTA-009 | At least the Greeter use case in `crates/application/` carries `#[tracing::instrument(skip(self), fields(otel.kind = "internal", rpc.service = "greeting.v1.GreeterService", rpc.method = "Greet"))]`.                                                                                                |
| FR-T5-OTA-010 | No PII (emails, passwords, tokens, names) in span attributes (Article XI.6 privacy).                                                                                                                                                                                                                 |

### Cluster 2 — Rust server-side middleware (FR-T5-OTA-020..025)

| ID            | Requirement summary                                                                                                                                                                                                                                                          |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FR-T5-OTA-020 | `tower-http::TraceLayer::new_for_http()` wired with `make_span_with` extracting W3C `traceparent` via `TraceContextPropagator` per ADR-T5-OTA-004.                                                                                                                            |
| FR-T5-OTA-021 | connectrpc OTel layer composed **outside** `Router::into_axum_service()` via Tower (reuses ADR-T5-001 pattern from `t5-connect-codegen`).                                                                                                                                    |
| FR-T5-OTA-022 | `MetadataMapCarrier` Extractor for `tonic::metadata::MetadataMap` (gRPC server-side traceparent extraction).                                                                                                                                                                  |
| FR-T5-OTA-023 | `HeaderMapCarrier` Injector for `reqwest::HeaderMap` (outbound HTTP traceparent injection helper).                                                                                                                                                                            |
| FR-T5-OTA-024 | Middleware ordering : `TraceLayer` is **outermost** so spans capture the full request lifetime including downstream layers.                                                                                                                                                  |
| FR-T5-OTA-025 | `tower-http` workspace dependency with `features = ["trace"]` ; Cargo.lock pinned per ADR-T5-OTA-001.                                                                                                                                                                        |

### Cluster 3 — Demo-005 traceparent round-trip (FR-T5-OTA-030..033)

| ID            | Requirement summary                                                                                                                                                                                                                                                          |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FR-T5-OTA-030 | Greeter use case span name `greeter.greet` with `rpc.system`, `rpc.service`, `rpc.method` attributes.                                                                                                                                                                        |
| FR-T5-OTA-031 | Span parent linkage : Flutter root span → axum server span → connectrpc handler span → application use case span (all share one `traceId`).                                                                                                                                  |
| FR-T5-OTA-032 | Greeter response shape unchanged (proto contract `shared/protos/v1/greeting/greeting.proto` byte-equal pre/post this change).                                                                                                                                                |
| FR-T5-OTA-033 | `examples/forge-fsm-example/docs/demo-005-connect-greeting.md` ships `## Trace this in SigNoz` H2 section (4-span tree walkthrough).                                                                                                                                          |

### Cluster 4 — Flutter SDK init (FR-T5-OTA-040..050)

Realises `flutter/opentelemetry.md` **v1.1.0** § SDK Initialization +
§ Navigation Observer + § BLoC Observer + § Error Instrumentation.

| ID            | Requirement summary                                                                                                                                                                                                                                                          |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FR-T5-OTA-040 | `lib/core/telemetry/telemetry_setup.dart` exists with `Future<void> setupTelemetry({required AppConfig config})`.                                                                                                                                                            |
| FR-T5-OTA-041 | Imports limited to `package:opentelemetry/api.dart` + `package:opentelemetry/sdk.dart` (Workiva 0.18.11 canonical entry points ; legacy `exporter_otlp_*.dart` sub-imports do not exist in this pkg layout per `flutter/opentelemetry.md` v1.1.0).                              |
| FR-T5-OTA-042 | `pubspec.yaml` declares `opentelemetry: ^0.18.0` + `dio: ^5.7.0` ; `flutter pub get` resolves `opentelemetry 0.18.11` + `dio 5.9.2` per the T-VER-DART-001 deferred-pin pattern.                                                                                            |
| FR-T5-OTA-043 | Resource attributes : `service.name`, `service.version`, `deployment.environment`, `device.platform`, `device.os.version`.                                                                                                                                                  |
| FR-T5-OTA-044 | `BatchSpanProcessor(exporter, maxExportBatchSize: 512, scheduledDelayMillis: 5000)` — positional exporter, named tuning params (no wrapping config object in 0.18.11 per v1.1.0 standard).                                                                                  |
| FR-T5-OTA-045 | OTLP HTTP/protobuf exporter via `CollectorExporter(Uri.parse('${endpoint}/v1/traces'))` (Workiva 0.18.11 — exported by `sdk.dart`). Replaces the fabricated `OtlpHttpSpanExporter` from the v1.0.0 standard (Q-004).                                                          |
| FR-T5-OTA-046 | `registerGlobalTracerProvider(tracerProvider)` called at the end of `setupTelemetry` so observers / interceptors resolve the global provider.                                                                                                                                |
| FR-T5-OTA-047 | `lib/main.dart` bootstrap order per ADR-T5-OTA-005 : `ensureInitialized` → `AppConfig.fromEnv` → `setupTelemetry` → `Bloc.observer` → error handlers → `runApp(MaterialApp(navigatorObservers: [...]))`.                                                                       |
| FR-T5-OTA-048 | `TracingNavigationObserver` extends `NavigatorObserver` ; emits span per `didPush` / `didReplace`.                                                                                                                                                                            |
| FR-T5-OTA-049 | `TracingBlocObserver` extends `BlocObserver` ; emits span per `onEvent` + `recordException` on `onError`.                                                                                                                                                                    |
| FR-T5-OTA-050 | `ErrorReporter` class with `report(error, stackTrace, {context})` ; plain class (deferred `@lazySingleton` per ADR-T5-OTA-005).                                                                                                                                              |

### Cluster 5 — Flutter Connect/HTTP traceparent injection (FR-T5-OTA-060..064)

| ID            | Requirement summary                                                                                                                                                                                                                                                          |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FR-T5-OTA-060 | `lib/core/telemetry/interceptors/tracing_interceptor.dart` extends `Interceptor` ; emits client-kind span per request ; injects W3C `traceparent` via `W3CTraceContextPropagator` + `contextWithSpan(Context.current, span)` (top-level helper per v1.1.0 standard, Q-004).      |
| FR-T5-OTA-061 | `greeting_repository_impl.dart` constructs the Connect/Dio client with `dio.interceptors.add(TracingInterceptor())`.                                                                                                                                                          |
| FR-T5-OTA-062 | Unit test asserts the emitted request carries a `traceparent` header matching `^00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]$`.                                                                                                                                                        |
| FR-T5-OTA-063 | `_sanitizePath` helper replaces UUIDs and numeric IDs with `{id}` to bound span-name cardinality.                                                                                                                                                                            |
| FR-T5-OTA-064 | `dio: ^5.7.0` workspace pin ; `flutter pub get` resolves `5.9.2`.                                                                                                                                                                                                            |

### Cluster 6 — Environment configuration (FR-T5-OTA-070..072)

| ID            | Requirement summary                                                                                                                                                                                                                                                          |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FR-T5-OTA-070 | Env trio documented : `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES` (W3C OTel SDK env names per ADR-T5-OTA-007).                                                                                                                              |
| FR-T5-OTA-071 | `DEPLOYMENT_ENV` documented (Forge-specific marker for dev/staging/prod resource attribute).                                                                                                                                                                                  |
| FR-T5-OTA-072 | `OTEL_TRACES_SAMPLER` + `OTEL_TRACES_SAMPLER_ARG` documented as the env hooks for future ratio toggling without rewriting init code.                                                                                                                                          |

> **NOTE** : the original spec target was `.env.example`, but the
> impl-time permission gate denies writes to dotfile-prefixed paths
> in this worktree. The trio is documented in
> `examples/forge-fsm-example/README.md` § "Environment configuration"
> instead — same audit semantics (committed, adopter-visible, FR
> coverage preserved). Phase D : promote env config to a dotfile when
> the permission gate is loosened.

### Cluster 7 — Test harness `t5-otel-app.test.sh` (FR-T5-OTA-080..082)

| ID            | Requirement summary                                                                                                                                                                                                                                                          |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FR-T5-OTA-080 | `.forge/scripts/tests/t5-otel-app.test.sh` exists, mirroring the J.7 / T.5 layout.                                                                                                                                                                                           |
| FR-T5-OTA-081 | L1 coverage : **16 L1 tests** (7 Rust SDK + 6 Flutter SDK + 2 demo-005 + 1 env) — all hermetic (no network, no toolchain).                                                                                                                                                    |
| FR-T5-OTA-082 | L2 coverage : **2 L2 smoke tests** — `cargo build -p bin-server` and `flutter analyze`. Gated by `_skip_if_no_toolchain` ; expected-pass once Q-004 is resolved (delivered by this change + sibling `t5-otel-dart-api-realign`).                                              |

### Cluster 8 — CI registration (FR-T5-OTA-090)

| ID            | Requirement summary                                                                                                                                                                                                                                                          |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FR-T5-OTA-090 | `.github/workflows/forge-ci.yml` `harness` job registers `t5-otel-app.test.sh --level 1` immediately after `t5-otel.test.sh`. L2 matrix entry (with toolchain) added at finalisation.                                                                                          |

### Cluster 9 — Documentation + spec consolidation (FR-T5-OTA-100..103)

| ID            | Requirement summary                                                                                                                                                                                                                                                          |
|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FR-T5-OTA-100 | **This file** — `.forge/specs/otel-app.md` consolidating all `FR-T5-OTA-*` + `NFR-T5-OTA-*` requirements into the canonical spec tree (mirror of `.forge/specs/otel-stack.md`).                                                                                                |
| FR-T5-OTA-101 | `docs/new-archetypes-plan.md` inventory + T5 quarter row updated noting Phase B done + Q-004 resolved.                                                                                                                                                                       |
| FR-T5-OTA-102 | `CHANGELOG.md` `[Unreleased]` entry shipped with the impl commit (8bf3865) ; the Q-004 follow-up commit (15b774c) tightens the wording to reference the v1.1.0 standard.                                                                                                     |
| FR-T5-OTA-103 | `backend/CLAUDE.md` + `frontend/CLAUDE.md` per-layer routing unaffected — they already declare `rust/opentelemetry` + `flutter/opentelemetry` as load-on-trigger standards. Validated, no edit needed.                                                                       |

---

## Non-Functional Requirements

| ID             | Requirement summary                                                                                                                                                                                                                                                          |
|----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NFR-T5-OTA-001 | Snapshot tarball budget : N/A (example-scoped, the template tree is untouched).                                                                                                                                                                                              |
| NFR-T5-OTA-002 | Backward compatibility : `cargo build -p bin-server` AND `flutter analyze` on `examples/forge-fsm-example/` MUST exit 0. **Confirmed 2026-05-12** post-Q-004 follow-up : 18/18 GREEN at `--level 1,2` with both toolchains on PATH.                                              |
| NFR-T5-OTA-003 | Article V audit trail : every task in `tasks.md` carries `[Story: FR-T5-OTA-XXX]`.                                                                                                                                                                                            |
| NFR-T5-OTA-004 | No new app-side framework dep beyond OTel : additions limited to the OTel crate / pub.dev families (`opentelemetry-*`, `tracing-opentelemetry`, `tower-http [trace]`, `opentelemetry` Dart pkg, `dio`).                                                                       |
| NFR-T5-OTA-005 | Performance budget : harness `--level 1` ≤ 8 s wall-clock ; `--level 1,2` ≤ 90 s.                                                                                                                                                                                            |
| NFR-T5-OTA-006 | No PII telemetry : span attributes MUST NOT carry emails, passwords, tokens, or names.                                                                                                                                                                                       |
| NFR-T5-OTA-007 | Span export does not block app startup : `setup_telemetry` returns within 500 ms wall-clock on a fresh process ; the OTLP exporter creation is lazy ; the first batch flush is asynchronous.                                                                                  |

---

## BDD Acceptance Criteria

User-facing surface : the demo-005-connect-greeting round trip.
Article II.1 scenario shipped at
`examples/forge-fsm-example/test/features/demo_005_traceparent.feature` :

```gherkin
Feature: Distributed tracing across the demo-005 round trip
  As a developer running the forge-fsm-example flagship project
  I want pressing the "Greet" button to produce a connected backend span tree
  So that I can see the full request path in SigNoz with a single traceId

  Scenario: Flutter HTTP request produces a connected backend span tree
    Given the Flutter app is launched and the greeting screen is displayed
    When the user types "Forge" in the name field
    And the user taps the "Greet" button
    Then a span "user.interaction greet" is started in the Flutter SDK
    And the outbound request carries a "traceparent" header
    And the Rust axum middleware extracts the parent context from "traceparent"
    And the connectrpc handler creates a child span "greeter.greet" inheriting that context
    And all four spans share the same traceId in the OTLP export
    And the SigNoz UI displays a single trace tree connecting Flutter → axum → connectrpc → application
```

Full step bodies (Flutter `bdd_widget_test` + Rust `cucumber-rs`) are
Phase D scope ; the scenario file's existence is the Phase B audit
anchor (per the spec's own Cluster 7 closure).

A second BDD scenario (Phase C scope, **out of this change**) will
extend the trace tree through Envoy / Kong : the
`_test_t5_l2_traceparent_dual` deferred from `t5-connect-codegen`.

---

## ADRs (T5-OTA design)

| ID            | Decision summary                                                                                                                                                                                                                                                          |
|---------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ADR-T5-OTA-001 | Pin family : Rust `opentelemetry 0.31` + `tracing-opentelemetry 0.32` + `tower-http 0.6 [trace]` ; Dart `opentelemetry: 0.18.11` (Workiva) + `dio: 5.9.2`. T-VER-DART-001 deferred-pin pattern used for the Dart side.                                                       |
| ADR-T5-OTA-002 | OTLP transport : **HTTP/protobuf both layers** on port 4318. Deviates from `rust/opentelemetry.md` § Setup snippet (gRPC) for symmetry with Flutter mobile constraints. Documented inline in `bin-server/main.rs` and the infrastructure telemetry module doc.            |
| ADR-T5-OTA-003 | SDK-side sampler : Rust `ParentBased(TraceIdRatioBased(rate))` ; Flutter `ParentBasedSampler(AlwaysOnSampler())` (per Q-004 realign — the Dart `TraceIdRatioBased*` class is not exported by `opentelemetry: 0.18.11`). Env-tier ratio enforced collector-side per ADR-OTEL-001. |
| ADR-T5-OTA-004 | axum + tonic middleware composition : `tower-http::TraceLayer::new_for_http()` outermost ; connectrpc OTel layer composed via Tower outside `Router::into_axum_service()` (reuses ADR-T5-001 from `t5-connect-codegen`).                                                  |
| ADR-T5-OTA-005 | Flutter init order : `ensureInitialized` → `AppConfig.fromEnv` → `setupTelemetry` → `Bloc.observer` → error handlers → `runApp(MaterialApp(navigatorObservers: [...]))`. `ErrorReporter` plain class ; deferred `@lazySingleton` once `injectable` lands.                  |
| ADR-T5-OTA-006 | Test harness layout : 16 L1 + 2 L2, MANIFEST comment block, `_not_implemented` RED stubs ; mirrors `t5-otel.test.sh`.                                                                                                                                                       |
| ADR-T5-OTA-007 | Env var names : W3C OTel SDK canonical (`OTEL_*`) + Forge-specific `DEPLOYMENT_ENV`. No Forge-prefix surface. `OTEL_TRACES_SAMPLER` + `OTEL_TRACES_SAMPLER_ARG` documented as future ratio toggles.                                                                          |

Full design rationale + Mermaid diagrams + Open Questions resolution :
`.forge/changes/t5-otel-app/design.md`.

---

## Open Questions Resolution

| ID    | Resolution                                                                                                                                                                                                                                                                                       |
|-------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Q-001 | Canonical Dart pkg : `opentelemetry: ^0.18.0` (Workiva, single bundled package). Resolved by ADR-T5-OTA-001 at design time.                                                                                                                                                                       |
| Q-002 | OTLP transport : HTTP/protobuf both layers on port 4318. Resolved by ADR-T5-OTA-002 at design time.                                                                                                                                                                                              |
| Q-003 | SDK sampler : `ParentBased(TraceIdRatioBased(1.0))` Rust + `ParentBasedSampler(AlwaysOnSampler())` Flutter (revised after Q-004 — the Dart `TraceIdRatioBased*` class is not exported by 0.18.11). Env-tier ratio enforced collector-side per ADR-OTEL-001.                                       |
| Q-004 | Resolved 2026-05-12 by sibling change `t5-otel-dart-api-realign` (commit `280e39e`) bumping `flutter/opentelemetry.md` v1.0.0 → v1.1.0 to ratify the actual `opentelemetry: 0.18.11` (Workiva) API surface ; the Dart example code in this change was realigned to v1.1.0 in commit `15b774c`. |

---

## Phase scope reminder

- **Phase A (`t5-otel-stack`, archived 2026-05-10)** : infra-side
  templates (OBI eBPF DaemonSet + Coroot + collector sampler +
  env-tier overlays).
- **Phase B (this change, archived 2026-05-12)** : app-side SDK
  instrumentation in the flagship example (`examples/forge-fsm-example/`).
- **Phase C (deferred)** : E2E traceparent validation through
  Envoy / Kong (the `_test_t5_l2_traceparent_dual` from
  `t5-connect-codegen` ; reactivates in T6 / B.8).
- **Phase D (deferred)** : promote SDK instrumentation from
  example-scoped to template-scoped (T6 / B.8 — flagship migration
  `1.0.0 → 2.0.0`) ; full BDD step bodies for the .feature scenarios.
