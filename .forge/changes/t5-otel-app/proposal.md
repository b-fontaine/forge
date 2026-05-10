# Proposal: t5-otel-app
<!-- Created: 2026-05-10 -->
<!-- Schema: full-stack-monorepo -->

## Problem

`t5-otel-stack` (archived 2026-05-10) shipped the **infra side** of the
SigNoz + OBI eBPF + Coroot triplet on the `full-stack-monorepo / 1.0.0`
flagship template : OBI DaemonSet, Coroot deployment, OTel collector
`probabilistic_sampler`, env-tier overlays. The archetype TEMPLATE has the
infra ; the EXAMPLE PROJECT (`examples/forge-fsm-example/`) inherits the
infra YAMLs but the application code is **NOT yet emitting traces** :

- `examples/forge-fsm-example/backend/bin-server/src/main.rs` is the
  scaffolder default (`println!("Hello, world!")`) — no `tracing`
  subscriber wired, no OTLP exporter, no `tracing-opentelemetry`
  bridge, no axum / tonic / connectrpc middleware emitting spans.
- `examples/forge-fsm-example/frontend/lib/main.dart` is the
  `flutter create` default counter — no `opentelemetry_dart` SDK init,
  no `Resource` attributes (`service.name`,
  `deployment.environment`), no `traceparent` injection on outbound
  HTTP / Connect / gRPC requests, no BLoC observer, no navigation
  observer.

Concrete consequences :

1. **Article IX is unrealised at the application layer for the
   flagship example.** Article IX.1 mandates traces + metrics + logs on
   *every service and application*. The infra collector is ready to
   receive OTLP traffic but receives nothing from the app processes.
   OBI eBPF compensates partially with kernel-side spans, but those
   carry zero application context (no `service.name`, no business
   span attributes, no traceparent-correlated parent IDs from the
   Flutter UI).
2. **The traceparent E2E validation deferred from T.5
   (`_test_t5_l2_traceparent_dual` in
   `t5-connect-codegen/tasks.md` § "DEFERRED 2026-05-06") still cannot
   run.** That deferred test asserts a span tree starting in the
   Flutter client traverses Envoy / Kong, lands in the Rust backend,
   and reports up to SigNoz with **the same `traceId`** at every hop.
   Without SDK instrumentation on either end, no trace is emitted to
   correlate.
3. **Phase A's adopter promise is half-credible.** Adopters who
   `forge init --archetype full-stack-monorepo` after Phase A get the
   infra but have to write the SDK setup themselves. The reference
   project that demonstrates the archetype does not do it. New
   adopters reading `examples/forge-fsm-example/` for cargo-cult
   guidance see nothing.
4. **`flutter/opentelemetry.md` and `rust/opentelemetry.md`
   standards are unanchored.** Both files describe code patterns
   (`tracing-opentelemetry` setup, `TracingInterceptor` Dio
   interceptor, BLoC observer, `traceparent` propagation) that have
   no reference implementation in the example. `verify.sh` cannot
   gate on them ; `constitution-linter.sh` cannot enforce them.

`docs/new-archetypes-plan.md` lines 994-1000 enumerate the deliverables
explicitly :

> ✅ Lancer Phase 1 OTel + OBI + Coroot stack — Done 2026-05-10 via
> `t5-otel-stack` (Phase A infra-only). **Phase B (SDK instrumentation
> `examples/forge-fsm-example/`) et Phase C (E2E traceparent) restent
> à livrer comme changes suivants.**

Phase B = this change. Phase C = the next change after this one.

## Solution

Land the **app side** of the OTel + OBI + Coroot stack as a
self-contained additive change in the **example flagship project only**
(`examples/forge-fsm-example/`). The archetype TEMPLATE
(`templates/full-stack-monorepo/`) is **not** modified by this change —
that is Phase A's territory, already shipped. Strict scope :

1. **Rust backend SDK init** in
   `examples/forge-fsm-example/backend/bin-server/src/main.rs` and a
   new `examples/forge-fsm-example/backend/crates/infrastructure/src/telemetry/`
   module : `tracing` + `tracing-subscriber` + `tracing-opentelemetry`
   bridge + `opentelemetry` SDK + `opentelemetry-otlp` exporter.
   `Resource` attributes : `service.name`, `service.version`,
   `deployment.environment`, `host.name`. Sampler delegates to the
   collector-side `probabilistic_sampler` (Phase A) ; the SDK ships
   `Sampler::AlwaysOn` because the env-tier ratio is enforced
   downstream — head-side ratio behaviour is documented as Phase C
   territory.
2. **Rust server-side middleware** : axum `TraceLayer` from
   `tower-http` + `tracing-opentelemetry::OpenTelemetrySpanExt`
   plumbing + W3C `traceparent` extraction on incoming requests
   (gRPC `MetadataMap` and HTTP headers). The connectrpc handler
   from `t5-connect-codegen` gains the OTel layer via Tower
   composition per `t5-connect-codegen/design.md` ADR-T5-001.
3. **Rust outbound propagation** : `TraceContextPropagator` injects
   `traceparent` on every reqwest call (none yet in the demo, but
   the helper module ships as a re-usable utility for adopters).
4. **Flutter SDK init** in
   `examples/forge-fsm-example/frontend/lib/main.dart` plus a new
   `examples/forge-fsm-example/frontend/lib/core/telemetry/`
   module : `opentelemetry_dart` SDK + `OtlpHttpSpanExporter` (HTTP
   /v1/traces) + `BatchSpanProcessor` + `Resource` (`service.name`,
   `service.version`, `deployment.environment`,
   `device.platform`).
5. **Flutter Connect/HTTP propagation** : a `TracingInterceptor`
   compatible with the Connect/Dart client (or the underlying `dio`
   transport) injecting W3C `traceparent` on outbound
   demo-005-connect-greeting calls. `TracingNavigationObserver` and
   `TracingBlocObserver` per `flutter/opentelemetry.md`.
6. **Demo update** : `demo-005-connect-greeting` (shipped in
   `t5-connect-codegen` 2026-05-06) is upgraded to round-trip a real
   traceparent. Pressing the greeting button in the Flutter UI starts
   a span ; the span context is propagated over the Connect call ;
   the Rust handler creates a child span ; the child span exports to
   the OTel collector. `examples/forge-fsm-example/docs/demo-005-connect-greeting.md`
   gains a "Trace this in SigNoz" section.
7. **Env-driven config** : both stacks read
   `OTEL_EXPORTER_OTLP_ENDPOINT` (default `http://localhost:4318`),
   `OTEL_SERVICE_NAME` (default `fsm-backend` / `fsm-frontend`),
   `OTEL_RESOURCE_ATTRIBUTES` (passed through to the resource).
   `examples/forge-fsm-example/.env.example` documents the trio.
8. **Test harness** : new `.forge/scripts/tests/t5-otel-app.test.sh`
   (≈ 16 L1 + 2 L2). L1 = static checks (Cargo.toml has crates,
   pubspec has packages, init module exists, traceparent helper
   exists, env vars documented). L2 = behavioural smoke
   (`cargo build -p bin-server`, `flutter test`, optionally a
   spans-emitted-in-stdout assertion via the `debug` exporter
   already present in the collector pipeline).
9. **Spec consolidation** : new
   `.forge/specs/otel-app.md` namespaced `FR-T5-OTA-*` + `NFR-T5-OTA-*`
   (distinct from Phase A's `FR-OTEL-*`).
10. **No changes** to `templates/full-stack-monorepo/` (Phase A
    territory). **No changes** to the existing infra YAMLs in
    `examples/forge-fsm-example/infra/` (Phase A mirror, already
    correct). **No** Aegis automation, **no** SBOM update, **no**
    new external observability backend.

## Scope In

- Rust backend SDK init module (`bin-server/main.rs` +
  `crates/infrastructure/src/telemetry/`).
- Rust axum / connectrpc middleware composition (incoming
  `traceparent` extraction, server span creation).
- Rust outbound `TraceContextPropagator` helper (reqwest carrier).
- Flutter SDK init (`lib/core/telemetry/`).
- Flutter `TracingInterceptor` for Connect/Dio + BLoC observer +
  navigation observer.
- demo-005 traceparent round-trip wiring.
- `.env.example` env-var documentation.
- New harness `.forge/scripts/tests/t5-otel-app.test.sh` (L1 + L2 light).
- CI registration in `.github/workflows/forge-ci.yml`.
- New consolidated spec `.forge/specs/otel-app.md`.
- `CHANGELOG.md` entry under `## [Unreleased]`.

## Scope Out (Explicit Exclusions)

- **NOT** the W3C traceparent E2E validation through Envoy / Kong
  (`_test_t5_l2_traceparent_dual` ; that is **Phase C** — depends on
  this change + a full envoy/kong span-attestation harness).
- **NOT** modifying the archetype TEMPLATE
  (`templates/full-stack-monorepo/`). Phase A territory.
- **NOT** modifying the existing infra YAMLs under
  `examples/forge-fsm-example/infra/` — Phase A mirror is correct.
- **NOT** changing `observability.yaml` standard (no version bump
  needed ; SDK code does not change the standard's contract).
- **NOT** changing `transport.yaml` standard.
- **NOT** introducing metrics or logs SDK pipelines beyond what
  `tracing-subscriber` already gives for free (the `tracing` ecosystem
  emits structured logs ; metrics SDK init is deferred to a
  future change because demo-005 has zero metrics-worthy
  surface).
- **NOT** AI feature instrumentation (Article XI.2) — out of scope
  for this demo.
- **NOT** Datadog / Honeycomb / New Relic exporters (forbidden by
  `observability.yaml::forbidden: [datadog]`).
- **NOT** CycloneDX SBOM regeneration (J.8.d's job ; the new SDK
  deps will be picked up automatically when J.8.d's `forge-sbom.sh`
  next runs against the example).
- **NOT** Aegis security audit automation (deployment-time concern).

## Impact

- **Users affected** : `examples/forge-fsm-example/` is the
  **reference implementation** consulted by every adopter scaffolding
  a new project under `full-stack-monorepo / 1.0.0`. After this
  change, copying patterns from the example to a new project gives
  fully instrumented backend + frontend out of the box. No archetype
  template change, so `forge init` adopters keep getting the
  Phase A infra and now have a code reference to follow.
- **Technical impact** : ~3 new Rust files (telemetry module +
  re-exports + middleware glue) + ~1 modified Rust file (main.rs
  bootstrap) + ~3 new Dart files (telemetry setup + interceptor +
  observers) + ~2 modified Dart files (main.dart bootstrap +
  greeting repository to use the instrumented Connect client) + 1
  demo doc update + 1 new harness + 1 new spec + 1 CHANGELOG entry.
  **Effort `M`** (comparable to `t5-otel-stack` Phase A).
- **Dependencies** :
  - `t5-otel-stack` ✅ archived 2026-05-10 (provides infra side).
  - `t5-connect-codegen` ✅ archived 2026-05-06 (provides the
    Connect transport that demo-005 instruments).
  - `observability.yaml` v1.1.0 ✅ shipped under Phase A.
  - `flutter/opentelemetry.md` + `rust/opentelemetry.md`
    standards ✅ already exist (T.4 baseline) — this change is
    their first reference implementation.
- **New runtime dependencies** :
  - **Rust** : `opentelemetry`, `opentelemetry_sdk`,
    `opentelemetry-otlp`, `tracing-opentelemetry`,
    `opentelemetry-semantic-conventions`. Exact versions resolved at
    `/forge:design` via Context7 (`/open-telemetry/opentelemetry-rust`).
    `tracing` + `tracing-subscriber` already declared in workspace.
  - **Dart** : `opentelemetry` (the canonical Dart SDK package on
    pub.dev — naming verified at `/forge:design` via Context7,
    Q-001). Optionally one of the OTLP exporter sub-packages.
- **Risk level** : **Medium**. Medium because the OTel-Dart
  ecosystem is younger than its Rust counterpart (Q-001 — package
  name + maturity verified at design time) and because middleware
  composition order in Rust (axum → connectrpc → tonic) needs to
  preserve the ordering already established by `t5-connect-codegen`
  (ADR-T5-001 : OTel layer applied **outside** the connectrpc
  service via Tower). Mitigated by Context7-verified pins, RED-witness
  cadence per cluster, and L2 smoke tests.

## Constitution Compliance

### Article I — TDD

RED → GREEN → REFACTOR enforced. Phase 1 of `tasks.md` writes
`t5-otel-app.test.sh` with all L1 stubs returning `_not_implemented`
(full RED witness). Phase 2 implements one cluster at a time
(Rust-init / Rust-middleware / Flutter-init / Flutter-interceptor /
demo-005-roundtrip), each preceded by a RED witness on the affected
test cluster. Same cadence as `t5-otel-stack`,
`t5-connect-codegen`, `j8-janus-rules`.

### Article II — BDD

User-facing : pressing the greeting button in the Flutter UI MUST
produce a span tree visible in SigNoz with the same `traceId` from
Flutter root span to backend handler span. ≥ 1 BDD scenario
(`Given/When/Then`) shipped in `specs.md` § BDD. `bdd_widget_test`
on the Flutter side ; `cucumber-rs` on the Rust side optional (the
spans-emitted assertion is a smoke test, not a behavioural Gherkin
scenario per se — locked at design time).

### Article III — Specs Before Code

Confirmed : `/forge:specify` writes `specs.md` with `FR-T5-OTA-*`
namespace before any code ships. `/forge:design` ratifies the
crate / package pins via Context7 and locks middleware composition
order before `/forge:implement`.

### Article III.4 — `[NEEDS CLARIFICATION:]` Discipline

Open questions captured below ; resolved before status flips to
`implemented`.

### Article V — Audit Trail

Each task tagged `[Story: FR-T5-OTA-XXX]` (Article V.1).

### Article VI — Flutter Architecture

`telemetry/` lives under `lib/core/` (FSD `core/` slice — cross-cutting
concerns) per `flutter/architecture.md`. The `TracingInterceptor`
attaches to the existing Connect/Dio client used by
`features/greeting/data/`. No domain-layer Flutter import. No
direct `setState` ; all observers integrate with the existing
`flutter_bloc` v9 Cubit.

### Article VII — Rust Architecture

The telemetry setup module is an **adapter** under
`crates/infrastructure/src/telemetry/` per Article VII.1
(infrastructure ports & adapters). `bin-server/main.rs` only
**wires** the setup at startup ; no business logic. Domain crate
gets zero new dependencies. `application/` may gain
`#[tracing::instrument]` annotations on use cases but no OTel
crate imports — `tracing` is already a workspace dependency and
the `tracing-opentelemetry` bridge is purely composition-time.

### Article VIII — Infrastructure

N/A here. Phase A delivered the infra ; Phase B is the
application side. The harness asserts the Phase A endpoints
(`OTEL_EXPORTER_OTLP_ENDPOINT: http://fsm-otel-collector:4318`)
are the defaults, but ships no new infra YAML.

### Article IX — Observability

This change **realises** Article IX at the application layer of
the flagship example, completing the Phase A → Phase B sequence.
After this change, the example emits traces from end to end ;
metrics + logs SDK pipelines remain Phase D scope (out of this
change).

### Article XII — Governance

`observability.yaml` unchanged — **no REVIEW.md ledger entry
required** (additive realisation does not constitute a review
event per the standard's lifecycle rules). Future bumps to
`observability.yaml` (e.g. when the OTel SDK forks) will trigger a
review entry.

## Citations

- `docs/new-archetypes-plan.md` lines **994-1000** — Phase A done,
  Phase B + Phase C pending as follow-up changes.
- `.forge/changes/t5-otel-stack/design.md` ADR-OTEL-001 (sampler
  collector-side) — Phase A locked the collector ratio mechanism ;
  this change confirms the SDK ships `Sampler::AlwaysOn` because
  the ratio enforcement is downstream.
- `.forge/changes/t5-otel-stack/design.md` ADR-OTEL-002 (Beyla
  2.0.1, Coroot 1.4.4) — Phase A's image pins ; this change
  consumes them indirectly via the running collector.
- `.forge/changes/t5-otel-stack/design.md` ADR-OTEL-003
  (`observability.yaml` 1.0.0 → 1.1.0) — Phase A bumped the
  standard ; this change does NOT bump it again.
- `.forge/changes/t5-otel-stack/design.md` ADR-OTEL-004
  (unprivileged-with-capabilities OBI) — Phase A's posture ;
  this change is independent (OBI eBPF runs orthogonally to SDK
  spans, both feed the same collector).
- `.forge/changes/t5-otel-stack/design.md` ADR-OTEL-005
  (Kustomize overlay structure) — referenced for the
  collector endpoint that the SDK must target.
- `.forge/changes/t5-otel-stack/design.md` ADR-OTEL-006 (Coroot
  multi-doc structure) — informational ; this change does not
  touch Coroot manifests.
- `.forge/changes/t5-otel-stack/design.md` ADR-OTEL-007
  (`forge.dev/kernel-min-58` opt-in) — informational ; SDK code
  is kernel-version-agnostic.
- `.forge/changes/t5-connect-codegen/design.md` ADR-T5-001
  (`connectrpc` Rust crate) — this change wires the OTel
  middleware **outside** the connectrpc service per the contract
  established there.

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none in this proposal.
Three open questions raised at this phase, all tracked in
`open-questions.md` and resolved during `/forge:design` :

- **Q-001** (Dart OTel package name + version) : the canonical
  pub.dev package historically appeared under several names
  (`opentelemetry_api`, `opentelemetry_sdk`, `opentelemetry_dart`,
  bundled `opentelemetry`). Resolve via Context7
  (`/open-telemetry/opentelemetry-dart` or equivalent) at
  `/forge:design`. Also lock the OTLP exporter package
  (`opentelemetry_exporter_otlp_grpc` vs HTTP variant).
- **Q-002** (OTLP transport : gRPC vs HTTP) : the collector listens
  on both `:4317` (gRPC) and `:4318` (HTTP/protobuf). Pick one
  per layer (Rust + Dart may differ — Dart SDKs historically have
  better HTTP support, Rust has better gRPC support). Justify at
  `/forge:design`.
- **Q-003** (Sampler on the SDK side) : ADR-OTEL-001 locked the
  ratio enforcement collector-side. SDK can ship `AlwaysOn`
  (every span exported, collector decides) OR
  `ParentBased(TraceIdRatioBased(1.0))` (matches the standard's
  *intent* exactly but adds a no-op layer). Decide at design time.
