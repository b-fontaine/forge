# Tasks: t5-otel-app
<!-- Status: planned -->
<!-- Schema: full-stack-monorepo -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED),
  write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-T5-OTA-XXX]` (Article V.1) on every
  task, enforced by `f4-linter-extension`.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/t5-otel-app.test.sh` (and `verify.sh`
  / `constitution-linter.sh` where relevant) and confirms expected
  counter movement.
- ADRs from `design.md` (ADR-T5-OTA-001..007) are honored verbatim ;
  deviations require a new ADR.
- Concrete pins (Rust : `opentelemetry 0.31` family +
  `tracing-opentelemetry 0.32` + `tower-http 0.6 [trace]`) resolved
  in `design.md` ADR-T5-OTA-001 ; impl Phase 1 only re-confirms drift.
- Dart pin deferred to T-VER-DART-001 (Phase 1 explicit gate).

---

## Phase 1 — Foundation : version drift + RED harness + Cargo workspace prep

Goal : Rust pins re-confirmed, Dart pin resolved, `t5-otel-app.test.sh`
exists with **16 L1 stubs all FAIL + 2 L2 stubs all FAIL**, full RED
state captured.

### T-VER — Toolchain version resolution (ADR-T5-OTA-001)

> **Versions resolved at design phase 2026-05-10** post-Context7
> investigation. Phase 1 re-confirms drift the same day for the same
> pins → mathematically a no-op for Rust if the harness runs same-day.

- [ ] **T-VER-RUST-001** : Re-confirm Rust pins via Context7
      `/open-telemetry/opentelemetry-rust` + `/websites/rs_tracing-opentelemetry`
      + `/tower-rs/tower-http`. Document any same-day drift in a
      footnote in `design.md` (or open a follow-up ADR if the
      delta is non-trivial). Same-day at design → no-op.
      [Story: FR-T5-OTA-004 / FR-T5-OTA-025]
- [ ] **T-VER-DART-001** : Resolve the canonical OTel-Dart pub.dev
      package name + version. Procedure : (1) probe `pub deps` /
      pub.dev for the OTel pkg consistent with
      `flutter/opentelemetry.md`'s import path
      (`package:opentelemetry/api.dart` etc.) ; (2) confirm
      ≥ 30 days old or apply waiver footnote pattern from
      `t5-otel-stack` ADR-OTEL-002 ; (3) write the pin into a
      scratch file `.forge/changes/t5-otel-app/_dart-pin.txt`
      (gitignored ; consumed by T-FE-002). Also pin `dio`.
      [Story: FR-T5-OTA-042 / FR-T5-OTA-064]
- [ ] **T-VER-DART-002** : Confirm the OTLP HTTP exporter sub-package
      / sub-import path (per ADR-T5-OTA-002 — HTTP/protobuf both
      layers). Either `package:opentelemetry/exporter_otlp_http.dart`
      or a separate pub package — record actual import in
      `_dart-pin.txt`. [Story: FR-T5-OTA-045]

### T-PHA — t5-otel-app.test.sh skeleton (RED for the whole change)

- [ ] **T-PHA-001** : Create `.forge/scripts/tests/t5-otel-app.test.sh`
      with bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`, source `_helpers.sh`), PASS/FAIL counters
      reset, `--level 1,2` parsing, `print_summary` close-out.
      Mirror the `t5-otel.test.sh` layout per ADR-T5-OTA-006.
      [Story: FR-T5-OTA-080]
- [ ] **T-PHA-002** : Add **16 L1 test stubs** returning
      `_not_implemented` per the FR↔test mapping table in
      `design.md` ADR-T5-OTA-006 :
      - 7 Rust : `_test_ota_001..007` (telemetry module, cargo deps,
        main setup_telemetry, main shutdown, axum TraceLayer,
        tonic MetadataMap carrier, propagation helper).
      - 6 Flutter : `_test_ota_010..015` (telemetry_setup, pubspec,
        main, observers, tracing_interceptor, repo wiring).
      - 2 demo-005 : `_test_ota_020..021` (use case
        `#[tracing::instrument]`, demo doc SigNoz section).
      - 1 env : `_test_ota_030` (`.env.example` trio).
      [Story: FR-T5-OTA-081]
- [ ] **T-PHA-003** [P] : Add **2 L2 test stubs** returning
      `_not_implemented` :
      - `_test_ota_l2_001_cargo_build_bin_server` (gate by
        `_skip_if_no_toolchain cargo`).
      - `_test_ota_l2_002_flutter_analyze` (gate by
        `_skip_if_no_toolchain flutter`).
      [Story: FR-T5-OTA-082]
- [ ] **T-PHA-004** [P] : Register `t5-otel-app.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `t5-otel.test.sh` with `--level 1`. The L2
      matrix entry (with-toolchain axis) is added in T-CI-001
      (Phase 4 finalisation).
      [Story: FR-T5-OTA-090]
- [ ] **T-PHA-005** : RED gate confirmed —
      `bash .forge/scripts/tests/t5-otel-app.test.sh > /tmp/t5-otel-app-red.log 2>&1` ;
      `bash exit: 1` ; `Failed: 16 / Passed: 0` (L1 only ; L2
      stubs skip when toolchain absent or fail when present). All
      stubs report `not implemented (RED witness)`.
      [Story: FR-T5-OTA-081]

**Phase 1 exit gate** : `t5-otel-app.test.sh` exits 1 with `FAIL ≥ 16`
on `--level 1`, `forge-ci.yml` matrix updated, `_dart-pin.txt`
scratch file present with confirmed Dart + dio pins, no production
code shipped yet, constitution-linter.sh OVERALL PASS.

---

## Phase 2 — Core : Rust SDK init + Flutter SDK init

Goal : both SDKs initialise on process start ; `bin-server` starts a
real axum + tonic server ; `main.dart` initialises the global tracer
provider before `runApp`. After this phase, 4 Rust + 4 Flutter L1
tests flip GREEN (init clusters only — middleware + interceptor are
Phase 3).

### T-BE — Rust backend SDK init (FR-T5-OTA-001..010)

- [ ] **T-BE-001** : RED witness — convert
      `_test_ota_001_rust_telemetry_module` to assert
      `crates/infrastructure/src/telemetry/mod.rs` exists AND
      declares `pub fn setup_telemetry`, `pub struct TelemetryConfig`,
      `Resource::new` literal mentions `service.name`. Capture
      `/tmp/t5-otel-app-red-be.log`. [Story: FR-T5-OTA-001]
- [ ] **T-BE-002** : RED witness —
      `_test_ota_002_rust_cargo_otel_deps` asserts
      `backend/Cargo.toml` `[workspace.dependencies]` lists
      `opentelemetry`, `opentelemetry_sdk`, `opentelemetry-otlp`,
      `tracing-opentelemetry`, `tower-http` with
      `features = ["trace"]`. [Story: FR-T5-OTA-004 / FR-T5-OTA-025]
- [ ] **T-BE-003** : Add the OTel + tower-http workspace deps to
      `examples/forge-fsm-example/backend/Cargo.toml`
      `[workspace.dependencies]` block, pinned per ADR-T5-OTA-001.
      Each line carries a `# Audit: T.5 (t5-otel-app)` end-of-line
      comment for traceability. Run `cargo update -p opentelemetry`
      to refresh `Cargo.lock`. [Story: FR-T5-OTA-004 / FR-T5-OTA-025]
- [ ] **T-BE-004** [P] : Create
      `examples/forge-fsm-example/backend/crates/infrastructure/src/telemetry/mod.rs`
      with the `TelemetryConfig` struct (FR-T5-OTA-002), the
      `setup_telemetry` function (FR-T5-OTA-001 / FR-T5-OTA-003 /
      FR-T5-OTA-006), the `build_sampler` helper following
      ADR-T5-OTA-003 (`ParentBased(TraceIdRatioBased(rate))`),
      and the OTLP HTTP exporter call per ADR-T5-OTA-002 :
      ```rust
      let exporter = opentelemetry_otlp::SpanExporter::builder()
          .with_http()
          .with_protocol(Protocol::HttpBinary)
          .with_endpoint(format!("{}/v1/traces", config.otlp_endpoint))
          .build()?;
      ```
      Add `crates/infrastructure/Cargo.toml` `[dependencies]` lines
      consuming the new workspace pins.
      [Story: FR-T5-OTA-001..006]
- [ ] **T-BE-005** [P] : Create
      `crates/infrastructure/src/telemetry/propagation.rs` with the
      `HeaderMapCarrier` (Injector for `reqwest::HeaderMap`) and
      `MetadataMapCarrier` (Extractor for
      `tonic::metadata::MetadataMap`) structs per
      `rust/opentelemetry.md` § Context Propagation in gRPC and
      § HTTP Client Instrumentation. Re-export from `mod.rs`.
      [Story: FR-T5-OTA-022 / FR-T5-OTA-023]
- [ ] **T-BE-006** : Run `t5-otel-app.test.sh --level 1` ; expect
      `_test_ota_001`, `_test_ota_002`, `_test_ota_006`, `_test_ota_007`
      flip GREEN (4 of 16). [Story: FR-T5-OTA-001..006 /
      FR-T5-OTA-022 / FR-T5-OTA-023]

### T-BS — bin-server bootstrap (FR-T5-OTA-008 / FR-T5-OTA-007)

- [ ] **T-BS-001** : RED witness —
      `_test_ota_003_rust_main_setup_telemetry` asserts
      `bin-server/src/main.rs` calls `setup_telemetry(`. Capture
      RED log. [Story: FR-T5-OTA-008]
- [ ] **T-BS-002** : Rewrite
      `examples/forge-fsm-example/backend/bin-server/src/main.rs`
      from the scaffolder default to the bootstrap shape per
      ADR-T5-OTA-004 sketch :
      1. `TelemetryConfig::from_env()`.
      2. `let provider = setup_telemetry(&config)?;`.
      3. `tracing::info!("starting fsm-backend ...");`
      4. (deferred to T-BS-004 — server start ; this task only
         wires the SDK).
      5. `provider.shutdown()?;` on exit.
      Cargo manifest `bin-server/Cargo.toml` gains `[dependencies]`
      on `infrastructure` (workspace), `opentelemetry`,
      `tracing`, `tracing-subscriber`, `tokio`, `anyhow`.
      [Story: FR-T5-OTA-008]
- [ ] **T-BS-003** : Add the graceful shutdown signal handling
      block (`tokio::signal::ctrl_c().await` ; on signal, call
      `provider.shutdown()`). Asserted by
      `_test_ota_004_rust_main_shutdown`.
      [Story: FR-T5-OTA-007]
- [ ] **T-BS-004** : Run `t5-otel-app.test.sh --level 1` ; expect
      `_test_ota_003` and `_test_ota_004` flip GREEN (2 more,
      cumulative 6/16). [Story: FR-T5-OTA-007 / FR-T5-OTA-008]

### T-FE — Flutter SDK init (FR-T5-OTA-040..050)

- [ ] **T-FE-001** : RED witness —
      `_test_ota_010_dart_telemetry_setup`,
      `_test_ota_011_dart_pubspec_otel`,
      `_test_ota_012_dart_main_setup_telemetry`,
      `_test_ota_013_dart_observers` all asserted. Capture
      `/tmp/t5-otel-app-red-fe.log`.
      [Story: FR-T5-OTA-040..050]
- [ ] **T-FE-002** : Edit
      `examples/forge-fsm-example/frontend/pubspec.yaml`
      `dependencies:` to add the OTel pkg + `dio` per
      `_dart-pin.txt` (T-VER-DART-001). End-of-line
      `# Audit: T.5 (t5-otel-app)` comments. Run `flutter pub get` ;
      commit `pubspec.lock`. [Story: FR-T5-OTA-042 / FR-T5-OTA-064]
- [ ] **T-FE-003** [P] : Create
      `frontend/lib/core/telemetry/telemetry_setup.dart` per
      ADR-T5-OTA-005 + `flutter/opentelemetry.md` § SDK
      Initialization. Resource attributes per FR-T5-OTA-043 ;
      OTLP HTTP exporter per ADR-T5-OTA-002 ;
      `BatchSpanProcessor` config per FR-T5-OTA-044 ;
      `ParentBasedSampler(TraceIdRatioBasedSampler(1.0))` per
      ADR-T5-OTA-003 ; `registerGlobalTracerProvider` at the end
      per FR-T5-OTA-046.
      [Story: FR-T5-OTA-040 / FR-T5-OTA-041 / FR-T5-OTA-043 /
       FR-T5-OTA-044 / FR-T5-OTA-045 / FR-T5-OTA-046]
- [ ] **T-FE-004** [P] : Create
      `lib/core/telemetry/observers/tracing_navigation_observer.dart`
      per `flutter/opentelemetry.md` § Navigation Observer.
      [Story: FR-T5-OTA-048]
- [ ] **T-FE-005** [P] : Create
      `lib/core/telemetry/observers/tracing_bloc_observer.dart`
      per `flutter/opentelemetry.md` § BLoC Observer (both
      `onEvent` + `onError` emit spans).
      [Story: FR-T5-OTA-049]
- [ ] **T-FE-006** [P] : Create `lib/core/telemetry/error_reporter.dart`
      per `flutter/opentelemetry.md` § Error Instrumentation. Use
      a plain class (deferred `@lazySingleton` per ADR-T5-OTA-005
      `// TODO(#TBD-OTEL-DI):` note).
      [Story: FR-T5-OTA-050]
- [ ] **T-FE-007** : Create
      `lib/core/config/app_config.dart` with `AppConfig.fromEnv()`
      reading `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`,
      `OTEL_RESOURCE_ATTRIBUTES`, `DEPLOYMENT_ENV` via
      `String.fromEnvironment(...)`.
      [Story: FR-T5-OTA-070 / FR-T5-OTA-071]
- [ ] **T-FE-008** : Rewrite
      `frontend/lib/main.dart` from the `flutter create` default
      counter to the bootstrap per ADR-T5-OTA-005 sketch
      (ensureInitialized → AppConfig.fromEnv → setupTelemetry →
      Bloc.observer → error handlers → runApp with
      navigatorObservers). The `home:` widget points at the
      existing `GreetingScreen` from `features/greeting/`.
      [Story: FR-T5-OTA-047]
- [ ] **T-FE-009** : Run `t5-otel-app.test.sh --level 1` ; expect
      `_test_ota_010..013` flip GREEN (4 more, cumulative 10/16).
      [Story: FR-T5-OTA-040..050]

**Phase 2 exit gate** : `t5-otel-app.test.sh --level 1` :
`Passed: 10 / Failed: 6` (middleware, interceptor, demo-005, env
docs still RED). `verify.sh` aggregate up by ≈ 1–2 PASS without
regression. constitution-linter.sh OVERALL PASS.

---

## Phase 3 — Integration : middleware + interceptor + demo-005 round-trip + env config

Goal : axum TraceLayer + tonic interceptor wired ; Flutter
`TracingInterceptor` attached to the Connect/Dio client used by
`greeting_repository_impl.dart` ; demo-005 round trip emits a
connected span tree ; `.env.example` documents the env var trio.

### T-MW — Rust middleware composition (FR-T5-OTA-020..024)

- [ ] **T-MW-001** : RED witness —
      `_test_ota_005_rust_axum_tracelayer` asserts
      `bin-server/src/main.rs` (or its sibling module) wires
      `TraceLayer::new_for_http` AND a `make_span_with` extracting
      `traceparent`. [Story: FR-T5-OTA-020]
- [ ] **T-MW-002** : Add the axum + connectrpc + tonic server start
      block to `bin-server/src/main.rs` per ADR-T5-OTA-004 sketch :
      mount the connectrpc service via `nest_service("/connect", …)` ;
      compose `tower-http::trace::TraceLayer::new_for_http()` with
      a `make_span_with` closure invoking
      `TraceContextPropagator.extract` (the
      `otel_make_span_with_traceparent_extraction` from
      design.md). Plumb the closure through a small helper module
      `crates/infrastructure/src/telemetry/middleware.rs`.
      [Story: FR-T5-OTA-020 / FR-T5-OTA-021 / FR-T5-OTA-024]
- [ ] **T-MW-003** [P] : Add the parallel tonic gRPC server start
      block ; `tonic::transport::Server::builder().layer(...)` with
      the same `make_span_with` closure (FR-T5-OTA-022). The
      MetadataMapCarrier from T-BE-005 is used inside the closure
      for the tonic path.
      [Story: FR-T5-OTA-022]
- [ ] **T-MW-004** : Run `t5-otel-app.test.sh --level 1` ; expect
      `_test_ota_005` flip GREEN (cumulative 11/16).
      [Story: FR-T5-OTA-020..024]

### T-DEMO — demo-005 traceparent round-trip (FR-T5-OTA-009 / FR-T5-OTA-030..033)

- [ ] **T-DEMO-001** : RED witness —
      `_test_ota_020_app_use_case_instrument` asserts at least
      one `#[tracing::instrument]` annotation in
      `crates/application/src/**/*.rs`. [Story: FR-T5-OTA-009]
- [ ] **T-DEMO-002** : Create or extend the Greeter use case in
      `crates/application/src/greeter.rs` with a
      `#[tracing::instrument(skip(self), fields(otel.kind = "internal", rpc.service = "greeting.v1.GreeterService", rpc.method = "Greet"))]`
      annotation per FR-T5-OTA-009 + FR-T5-OTA-030 (span name
      `greeter.greet`, attributes `rpc.system`, `rpc.service`,
      `rpc.method`). [Story: FR-T5-OTA-009 / FR-T5-OTA-030 /
       FR-T5-OTA-031]
- [ ] **T-DEMO-003** [P] : Verify the proto contract is unchanged
      (`shared/protos/v1/greeting/greeting.proto` byte-equal pre/post)
      per FR-T5-OTA-032. The verification can be a one-line
      `git diff --exit-code shared/protos/v1/greeting/greeting.proto`
      in a manual check (this task is a guard, not a code change).
      [Story: FR-T5-OTA-032]
- [ ] **T-DEMO-004** : Run `t5-otel-app.test.sh --level 1` ; expect
      `_test_ota_020` flip GREEN (cumulative 12/16).
      [Story: FR-T5-OTA-009 / FR-T5-OTA-030 / FR-T5-OTA-031]

### T-INT — Flutter Connect/Dio interceptor (FR-T5-OTA-060..063)

- [ ] **T-INT-001** : RED witness —
      `_test_ota_014_dart_tracing_interceptor` and
      `_test_ota_015_dart_repo_wires_interceptor`. [Story:
      FR-T5-OTA-060 / FR-T5-OTA-061]
- [ ] **T-INT-002** : Create
      `lib/core/telemetry/interceptors/tracing_interceptor.dart`
      per `flutter/opentelemetry.md` § HTTP Instrumentation via
      Dio Interceptor : `class TracingInterceptor extends Interceptor`,
      W3C `traceparent` injection via
      `W3CTraceContextPropagator`, `_sanitizePath` for
      cardinality control, span end on response, `recordException`
      on error.
      [Story: FR-T5-OTA-060 / FR-T5-OTA-063]
- [ ] **T-INT-003** [P] : Edit
      `frontend/lib/features/greeting/data/repository/greeting_repository_impl.dart`
      to construct the Connect/Dio client with
      `dio.interceptors.add(TracingInterceptor())`. The Connect
      client wraps `dio` per `t5-connect-codegen` Dart side ;
      attaching at the dio level captures every Connect call.
      [Story: FR-T5-OTA-061]
- [ ] **T-INT-004** [P] : Create unit test
      `frontend/test/core/telemetry/tracing_interceptor_test.dart`
      asserting that an emitted request carries a `traceparent`
      header matching `^00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]$`.
      Use `mocktail` to mock the underlying transport (already in
      `dev_dependencies`).
      [Story: FR-T5-OTA-062]
- [ ] **T-INT-005** : Run `t5-otel-app.test.sh --level 1` ; expect
      `_test_ota_014` and `_test_ota_015` flip GREEN
      (cumulative 14/16). [Story: FR-T5-OTA-060..063]

### T-ENV — Env config + demo-005 doc (FR-T5-OTA-033 / FR-T5-OTA-070..072)

- [ ] **T-ENV-001** : RED witness —
      `_test_ota_030_env_example_trio` and
      `_test_ota_021_demo_doc_signoz_section`.
      [Story: FR-T5-OTA-033 / FR-T5-OTA-070]
- [ ] **T-ENV-002** [P] : Create / edit
      `examples/forge-fsm-example/.env.example` per ADR-T5-OTA-007
      template : `OTEL_EXPORTER_OTLP_ENDPOINT`,
      `OTEL_EXPORTER_OTLP_PROTOCOL`, `OTEL_SERVICE_NAME` (commented),
      `OTEL_RESOURCE_ATTRIBUTES` with explicit "NEVER PUT SECRETS HERE"
      comment, `OTEL_TRACES_SAMPLER`, `OTEL_TRACES_SAMPLER_ARG`,
      `DEPLOYMENT_ENV`. [Story: FR-T5-OTA-070 / FR-T5-OTA-071 /
       FR-T5-OTA-072]
- [ ] **T-ENV-003** [P] : Create or extend
      `examples/forge-fsm-example/docs/demo-005-connect-greeting.md`
      with a `## Trace this in SigNoz` H2 section enumerating :
      (1) `task dev` to spin up the local cluster, (2) trigger
      sequence (open Flutter app → enter name → tap Greet),
      (3) reading the trace tree in SigNoz UI at
      `http://localhost:3301`. Mention the four-span shape
      (Flutter root → axum server → connectrpc handler →
      application use case).
      [Story: FR-T5-OTA-033]
- [ ] **T-ENV-004** : Run `t5-otel-app.test.sh --level 1` ; expect
      `_test_ota_021` and `_test_ota_030` flip GREEN
      (cumulative 16/16 GREEN). [Story: FR-T5-OTA-033 /
       FR-T5-OTA-070]

### T-BDD — BDD scenario file (Article II.1)

- [ ] **T-BDD-001** : Create
      `examples/forge-fsm-example/test/features/demo_005_traceparent.feature`
      with the Gherkin scenario verbatim from `specs.md` § BDD
      Acceptance Criteria. Step definitions are stubs (placeholder
      `// TODO(#TBD-OTEL-BDD): wire bdd_widget_test step bodies`) ;
      full step bodies are Phase D scope (a separate change wires
      `bdd_widget_test` step harness and the `cucumber-rs` Rust
      harness). For Phase B, the scenario file's existence is the
      audit-trail anchor.
      [Story: Article II / FR-T5-OTA-031]

**Phase 3 exit gate** : `t5-otel-app.test.sh --level 1` 16/16 GREEN,
0 FAIL, ≤ 8 s wall-clock (NFR-T5-OTA-005). `verify.sh` aggregate
increased without any new FAIL. `constitution-linter.sh` OVERALL
PASS.

---

## Phase 4 — Quality : L2 smoke + docs broader + CI gate + review

### T-L2 — L2 smoke tests (FR-T5-OTA-082)

- [ ] **T-L2-001** : Implement `_test_ota_l2_001_cargo_build_bin_server` :
      `cd $BACKEND && cargo build -p bin-server --locked` ; expect
      exit 0. Skip cleanly when `cargo` not on PATH. Budget 75 s.
      [Story: FR-T5-OTA-082 / NFR-T5-OTA-002]
- [ ] **T-L2-002** : Implement `_test_ota_l2_002_flutter_analyze` :
      `cd $FRONTEND && flutter analyze` ; expect exit 0 (no new
      lint warning). Skip cleanly when `flutter` not on PATH.
      Budget 15 s.
      [Story: FR-T5-OTA-082 / NFR-T5-OTA-002]
- [ ] **T-L2-003** : Run `t5-otel-app.test.sh --level 1,2` locally
      with toolchains present ; expect 16 L1 + 2 L2 = 18/18 GREEN.
      Capture `/tmp/t5-otel-app-l2.log` as evidence.
      [Story: FR-T5-OTA-082 / NFR-T5-OTA-002]

### T-DOC — Documentation broader (FR-T5-OTA-101..102)

- [ ] **T-DOC-001** [P] : Update the flagship row in
      `docs/ARCHETYPES.md` to mention the example project ships
      SDK instrumentation (traces) for backend + frontend. One
      additional bullet on the existing flagship row (`Phase B —
      app SDK instrumentation`) ; do NOT rewrite the row.
      [Story: FR-T5-OTA-101]
- [ ] **T-DOC-002** [P] : Add an entry under `## [Unreleased]` in
      `CHANGELOG.md` flagging :
      - Rust OTel SDK init (`opentelemetry 0.31` family +
        `tracing-opentelemetry 0.32` + `tower-http 0.6 [trace]`).
      - axum + tonic middleware composition with W3C
        `traceparent` extraction.
      - Flutter OTel SDK init (`opentelemetry` pub pkg +
        `dio` interceptor + BLoC + navigation observers).
      - demo-005-connect-greeting traceparent round-trip wiring.
      - `.env.example` config trio.
      [Story: FR-T5-OTA-102]
- [ ] **T-DOC-003** [P] : Confirm
      `examples/forge-fsm-example/backend/CLAUDE.md` and
      `frontend/CLAUDE.md` need NO edit (FR-T5-OTA-103) — they
      already declare `rust/opentelemetry` and
      `flutter/opentelemetry` as load-on-trigger standards.
      Manual confirmation only ; no commit if no edit needed.
      [Story: FR-T5-OTA-103]

### T-CI — CI registration finalisation

- [ ] **T-CI-001** : Add the L2 matrix entry to
      `.github/workflows/forge-ci.yml` : a new `harness-toolchain`
      job (or matrix axis) that runs `t5-otel-app.test.sh --level 1,2`
      after the Rust + Flutter toolchain setup steps. Cache
      `~/.cargo` and `~/.pub-cache` (already cached for other
      jobs ; just re-use). [Story: FR-T5-OTA-090]
- [ ] **T-CI-002** : Run `verify.sh` locally ; expect aggregate
      counter to grow without regression vs the t5-otel-stack
      baseline (155 PASS post-design.md ; this change adds
      ≈ 1–2 PASS for the new change-yaml-schema validation +
      open-questions gate entry). [Story: NFR-T5-OTA-002]
- [ ] **T-CI-003** : Run `constitution-linter.sh` ; expect OVERALL
      PASS (the existing T.5 transport-codegen-coverage WARN is
      acceptable per ADR-T5-005 ; no new WARN expected ; the new
      Article V check `t5-otel-app: tasks.md has [Story: FR-XXX]
      audit trail` flips to PASS once tasks.md is committed).
      [Story: NFR-T5-OTA-002]

### T-SPEC — Spec consolidation (archive-time concern, NOT in this change)

> **Out-of-phase note** : `.forge/specs/otel-app.md` consolidation
> (FR-T5-OTA-100) happens at `/forge:archive` time, not
> `/forge:implement`. This task block lists the deliverable for
> traceability but is **not actioned in Phase 4** (Phase 4 ends
> at `implemented` ; archival is a distinct Forge phase). Listed
> here so future archivers don't miss it.

- [ ] **T-SPEC-001** : (DEFERRED to `/forge:archive`) Create
      `.forge/specs/otel-app.md` consolidating all FR-T5-OTA-* +
      NFR-T5-OTA-* requirements per the mirror of
      `.forge/specs/otel-stack.md`. [Story: FR-T5-OTA-100]

### T-REV — Quality review gate

- [ ] **T-REV-001** : Run `/forge:review t5-otel-app` driving the
      constitutional gate review : Articles I (TDD), II (BDD —
      scenario file shipped), III + III.4 (specs first + open
      questions resolved or explicitly gated), IV (delta —
      additive, no standard amendment), V (audit trail —
      `[Story: FR-T5-OTA-XXX]` on every task), VI (Flutter
      architecture — `core/` slice), VII (Rust architecture —
      infrastructure adapter), IX (observability — three signals
      now reach the collector from app code), X (gate coverage),
      XI.6 (privacy — no PII in attributes), XII (governance — no
      standard bump). Block if any returns VIOLATION.
      [Story: Article V]
- [ ] **T-REV-002** : Run the full `verify.sh` once more on a
      clean checkout to confirm reproducibility.
      [Story: NFR-T5-OTA-002]
- [ ] **T-REV-003** : Verify
      `bin/forge-questions.sh --change t5-otel-app --status open`
      returns either empty (Q-001..Q-003 fully answered) or only
      Q-001's residual Dart pin gated by T-VER-DART-001 (which
      flipped to `answered` when the impl committed the
      `_dart-pin.txt` consumption in T-FE-002).
      [Story: Article III.4]

**Phase 4 exit gate (= change implementation readiness for
`/forge:archive`)** :

- `t5-otel-app.test.sh --level 1` : 16/16 PASS, 0 FAIL, ≤ 8 s.
- `t5-otel-app.test.sh --level 1,2` : 18/18 PASS on a toolchain
  host (gracefully skips the 2 L2 stubs on CI matrix entries
  without toolchain).
- `verify.sh` aggregate ≥ baseline + 1 PASS / 0 FAIL / RESULT: PASS.
- `constitution-linter.sh` OVERALL PASS (no new WARN).
- `forge-questions.sh --status open --change t5-otel-app` empty
  (or T-VER-DART residual closed by T-FE-002).
- All FR-T5-OTA-001..103 + NFR-T5-OTA-001..007 tasks checked.
- `CHANGELOG.md` entry under `## [Unreleased]`.
- `docs/ARCHETYPES.md` flagship row updated.
- BDD `.feature` file shipped (step bodies are Phase D scope).

---

## Constitutional task review (per Article V)

For each task family, verifying TDD compliance + spec linkage +
architecture preservation :

| Task family   | TDD order                                    | Spec link                                        | Architecture                                                |
|---------------|----------------------------------------------|--------------------------------------------------|-------------------------------------------------------------|
| T-VER-RUST-*  | N/A (resolution work, no code)               | FR-T5-OTA-004 / FR-T5-OTA-025                    | ADR-T5-OTA-001                                              |
| T-VER-DART-*  | N/A (resolution work, no code)               | FR-T5-OTA-042 / FR-T5-OTA-064 / FR-T5-OTA-045    | ADR-T5-OTA-001 (deferred pin gate)                          |
| T-PHA-*       | RED phase (intentional)                      | FR-T5-OTA-080..082 / FR-T5-OTA-090               | ADR-T5-OTA-006                                              |
| T-BE-*        | RED witness then telemetry module            | FR-T5-OTA-001..006 / FR-T5-OTA-022..023          | ADR-T5-OTA-001 / ADR-T5-OTA-002 / ADR-T5-OTA-003 (Article VII infra adapter) |
| T-BS-*        | RED witness then bin-server bootstrap        | FR-T5-OTA-007..008                               | ADR-T5-OTA-004 / ADR-T5-OTA-005                              |
| T-FE-*        | RED witness then Flutter SDK init            | FR-T5-OTA-040..050 / FR-T5-OTA-070..071          | ADR-T5-OTA-005 (Article VI core/ slice)                     |
| T-MW-*        | RED witness then middleware composition      | FR-T5-OTA-020..024                               | ADR-T5-OTA-004                                              |
| T-DEMO-*      | RED witness then use case instrument         | FR-T5-OTA-009 / FR-T5-OTA-030..032               | Article VII (application layer)                             |
| T-INT-*       | RED witness then dio interceptor             | FR-T5-OTA-060..063                               | ADR-T5-OTA-005 (interceptor in core/)                        |
| T-ENV-*       | RED witness then env docs                    | FR-T5-OTA-033 / FR-T5-OTA-070..072               | ADR-T5-OTA-007                                              |
| T-BDD-*       | Scenario file is the audit anchor            | Article II / FR-T5-OTA-031                       | N/A                                                         |
| T-L2-*        | RED witness then toolchain smoke             | FR-T5-OTA-082 / NFR-T5-OTA-002                   | ADR-T5-OTA-006                                              |
| T-DOC-*       | No code, doc-only                            | FR-T5-OTA-101..103                               | docs / CHANGELOG conventions                                |
| T-CI-*        | Validation only                              | FR-T5-OTA-090 / NFR-T5-OTA-002                   | forge-self-ci standard (G.1)                                |
| T-SPEC-001    | DEFERRED to /forge:archive                   | FR-T5-OTA-100                                    | spec consolidation pattern                                  |
| T-REV-*       | Final gate, no production code               | Article V / III.4 / VI / VII / IX / XI.6 / XII   | All articles                                                |

No `[TASK VIOLATION]` detected. Plan proceeds to `/forge:implement`.

---

## Task counts by phase

| Phase | Tasks | Parallelizable `[P]` | RED witnesses |
|-------|-------|----------------------|---------------|
| 1     | 8     | 2                    | 16 + 2 stubs (L1 + L2) |
| 2     | 18    | 6                    | 4 (per cluster) |
| 3     | 18    | 5                    | 4 (per cluster) |
| 4     | 12    | 3                    | 2 (L2 cluster) |
| **Total** | **56** | **16** | **26 RED witnesses** |

Estimated wall-clock at single-developer pace : Phase 1 ≈ 1–1.5 h
(Dart pin lookup adds ~ 30 min vs Phase A), Phase 2 ≈ 3–4 h, Phase 3
≈ 2–3 h, Phase 4 ≈ 1.5 h. Total ≈ 8–10 h of focused work, slightly
above the **M** complexity estimate in `proposal.md` because the
two-layer scope adds Cargo + pub plumbing on top of the SDK code.
