# Specifications: t5-otel-traceparent-e2e
<!-- Status: specified -->
<!-- Schema: full-stack-monorepo -->

**Namespace** : `FR-T5-TPE-*` / `NFR-T5-TPE-*` (distinct from Phase A's
`FR-OTEL-*` and Phase B's `FR-T5-OTA-*`). **Constitution** : v1.1.0.
Pas d'amendement requis.

## Source Documents

| Field             | Value                                                                                                            |
|-------------------|------------------------------------------------------------------------------------------------------------------|
| **ADR base (A)**  | `t5-otel-stack` archived 2026-05-10 (FR-OTEL-001..082 + ADR-OTEL-001..007 — Phase A infra)                       |
| **ADR base (B)**  | `t5-otel-app` archived 2026-05-10 (FR-T5-OTA-001..103 + ADR-T5-OTA-001..007 — Phase B SDK + middleware)          |
| **ADR base (CC)** | `t5-connect-codegen` archived 2026-05-06 (FR-T5-CC-001..072 + ADR-T5-001..006 — Connect transport host of demo-005) |
| **Plan ref**      | `docs/new-archetypes-plan.md` L994–1000 (Phase C = E2E traceparent validation)                                   |
| **Standard ref (cross-cutting)** | `.forge/standards/observability.yaml` v1.1.0 (sampler `parentbased_traceidratio`, ratios per env, OTLP)|
| **Standard ref (Kong)**          | `.forge/standards/infra/kong.md` (declarative config only, no admin API)                            |
| **Standard ref (Rust)**          | `.forge/standards/rust/opentelemetry.md` (`HeaderMapExtractor`, `MetadataMapCarrier` patterns)      |
| **Standard ref (Flutter)**       | `.forge/standards/flutter/opentelemetry.md` (W3C traceparent injection — Q-004 caveat applies)      |
| **Deferred test uplifted**       | `t5-connect-codegen/tasks.md` § "DEFERRED 2026-05-06" — `_test_t5_l2_traceparent_dual` closes here  |
| **Forward-pointer**              | `docs/ARCHITECTURE-TARGET.md` ADR-001 (Envoy migration — out of this change's scope)                |

No new external standard pinned. No standard version bump.

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — BDD feature file (FR-T5-TPE-001..010)

##### FR-T5-TPE-001 — Feature file exists

`examples/forge-fsm-example/test/features/traceparent_e2e.feature`
MUST exist as a full Gherkin feature distinct from
`demo_005_traceparent.feature` (Phase B's stub). The feature file
header `Feature:` line SHALL declare the W3C traceparent E2E
validation intent in English.

##### FR-T5-TPE-002 — Three named scenarios

The feature file MUST declare exactly three scenarios (no more, no
less in this change ; Phase D may add live-run scenarios) :

1. **Scenario** : `Direct path — Flutter to axum to connectrpc handler
   to use case` — 4 spans, 1 traceId.
2. **Scenario** : `Kong path — Flutter to Kong to axum to handler to
   use case` — 5 spans, traceparent preserved through Kong.
3. **Scenario** : `Sampled-off path — incoming traceparent with sampled
   bit = 0` — spans recorded but NOT exported per
   `observability.yaml::sampler: parentbased_traceidratio`.

Asserted by the harness via three `^  Scenario:` line greps.

##### FR-T5-TPE-003 — Gherkin Given/When/Then discipline

Every scenario MUST follow the standard Gherkin shape : at least one
`Given`, at least one `When`, at least one `Then`. Background block
allowed. Step language is English to match the Phase B stub.

##### FR-T5-TPE-004 — Direct path scenario span list

The direct-path scenario MUST mention all four span layers by name :
- Flutter client span (named via the Phase B `TracingInterceptor`).
- axum server span (named per `tower-http::TraceLayer::new_for_http`
  `make_span_with` closure).
- connectrpc handler span.
- application use case span (the `#[tracing::instrument]` annotation
  from Phase B FR-T5-OTA-009).

##### FR-T5-TPE-005 — Kong path scenario gateway hop

The Kong-path scenario MUST mention the Kong gateway hop explicitly
between the Flutter client and the axum server, e.g. :

```gherkin
Then the outbound request carries a "traceparent" header
And the Kong gateway forwards the request preserving the "traceparent" header verbatim
And the Rust axum middleware extracts the parent context from the preserved "traceparent"
```

Five spans total (Flutter client → Kong implicit / no SDK span → axum
server → connectrpc handler → use case). Kong does NOT emit its own
OTel span in the current example tree ; it acts as a transparent
passthrough.

##### FR-T5-TPE-006 — Sampled-off scenario semantics

The sampled-off scenario MUST quote :
- An incoming `traceparent: 00-{traceId}-{spanId}-00` literal (the
  `-00` suffix = sampled bit cleared).
- The expected behaviour : spans are **recorded** (the `tracing` span
  handle exists, attributes are settable) but **NOT exported** by
  the `BatchSpanProcessor` per `ParentBased(TraceIdRatioBased(rate))`
  contract.
- The collector receives zero spans for that request's traceId.

Resolution of the exact Rust SDK 0.31 behaviour is locked at design
time (Q-001).

##### FR-T5-TPE-007 — Symbol-name forward-pointer

At least one scenario step MUST reference one of Phase B's actual
exported symbols by name : `HeaderMapExtractor`, `MetadataMapCarrier`,
or `HeaderMapCarrier` (the trio shipped in
`backend/crates/infrastructure/src/telemetry/propagation.rs`). This
gives future readers a code-link from BDD text to the actual carrier
type. Symbol names MUST match the Phase B source verbatim.

##### FR-T5-TPE-008 — Step body deferral notice

The feature file MUST carry a `TODO(#TBD-OTEL-PHASE-D):` style
comment near the end declaring that step bodies (Flutter
`bdd_widget_test` step definitions + Rust `cucumber-rs` step
definitions + live-run docker-compose driver) are deferred to
Phase D. This mirrors the Phase B stub's
`TODO(#TBD-OTEL-BDD):` pattern.

##### FR-T5-TPE-009 — Phase B stub coexistence

The new `traceparent_e2e.feature` MUST coexist with the Phase B
`demo_005_traceparent.feature` in the same `test/features/`
directory. Neither file deletes nor renames the other. Together they
form the BDD evidence for FR-T5-OTA-031 (Phase B direct path) +
FR-T5-TPE-001..010 (Phase C E2E paths).

##### FR-T5-TPE-010 — Audit comment

The feature file SHALL carry a header comment
`<!-- Audit: T.5 (t5-otel-traceparent-e2e) — Phase C E2E traceparent
through Kong gateway -->` for `f4-linter-extension` audit-trail
discovery, mirroring `demo_005_traceparent.feature`'s header.

---

#### Cluster 2 — Kong gateway preservation (FR-T5-TPE-020..025)

##### FR-T5-TPE-020 — kong.yml.example state verified

`examples/forge-fsm-example/infra/kong/kong.yml.example` MUST be
audited at implementation time. If the file ALREADY preserves
`traceparent` by absence of header-strip directives (the expected
case as of 2026-05-11), the change is purely additive (comment-only).
If the file ships an unexpected header-strip directive touching
`traceparent`, this change MUST patch it.

##### FR-T5-TPE-021 — Explicit traceparent contract comment

`kong.yml.example` MUST carry a comment block in the routes /
plugins section declaring :

```yaml
# W3C trace context preservation (T.5 Phase C, t5-otel-traceparent-e2e)
# This gateway MUST forward incoming `traceparent` and `tracestate`
# headers verbatim to the upstream service. Kong's default
# behaviour (no `request_transformer` plugin asks to remove them)
# preserves them. DO NOT add a `request_transformer.remove.headers`
# entry stripping these headers.
```

The comment is contractual : adopters who copy the file get a
written guarantee.

##### FR-T5-TPE-022 — No request_transformer stripping traceparent

The harness MUST grep `kong.yml.example` and FAIL if any
`request_transformer` plugin's `remove.headers` array (or its
`replace`, `rename` sibling arrays) mentions `traceparent` or
`tracestate`. This is a defensive gate against accidental
regression.

##### FR-T5-TPE-023 — No headers.traceparent disable directive

The harness MUST grep `kong.yml.example` and FAIL if any line of
the form `headers.traceparent: false` or
`disable.headers.traceparent` exists. Kong has multiple historical
ways to strip headers ; the gate covers the most common.

##### FR-T5-TPE-024 — preserve_host policy unchanged

`kong.yml.example` `preserve_host: false` (current value) MUST NOT
be changed by this scope. `preserve_host` controls the `Host`
header and is orthogonal to W3C tracing — out of scope.

##### FR-T5-TPE-025 — Routes shape unchanged

The two existing services (`forge-fsm-example-backend` HTTP +
`greeter` gRPC) and their routes MUST remain byte-identical except
for the additive comment of FR-T5-TPE-021. The harness greps the
`services:` block for unchanged service names.

---

#### Cluster 3 — L1 harness `t5-otel-traceparent-e2e.test.sh` (FR-T5-TPE-040..047)

##### FR-T5-TPE-040 — Harness exists

`.forge/scripts/tests/t5-otel-traceparent-e2e.test.sh` MUST exist
mirroring the Phase B `t5-otel-app.test.sh` layout (bash header,
`source _helpers.sh`, PASS/FAIL counters, `--level 1,2` parsing,
`print_summary`).

##### FR-T5-TPE-041 — L1 test : feature file presence + audit header

`_test_tpe_001_feature_file_exists` MUST assert
`examples/forge-fsm-example/test/features/traceparent_e2e.feature`
exists AND carries the audit header comment per FR-T5-TPE-010.

##### FR-T5-TPE-042 — L1 test : three scenarios present

`_test_tpe_002_three_scenarios` MUST assert the feature file
contains exactly three `^  Scenario:` lines (no more, no less). The
scenario names MUST mention `Direct`, `Kong`, and `Sampled-off`
(case-insensitive).

##### FR-T5-TPE-043 — L1 test : Given/When/Then discipline

`_test_tpe_003_gherkin_shape` MUST assert each scenario carries at
least one `Given`, one `When`, one `Then` (Background's `Given`
counts toward the scenario's Given requirement).

##### FR-T5-TPE-044 — L1 test : symbol-name forward-pointer

`_test_tpe_004_symbol_forward_pointer` MUST assert at least one of
`HeaderMapExtractor`, `MetadataMapCarrier`, or `HeaderMapCarrier`
appears in the feature file text.

##### FR-T5-TPE-045 — L1 test : Kong preserves traceparent

`_test_tpe_010_kong_no_traceparent_strip` MUST assert
`kong.yml.example` has no `request_transformer.remove.headers`
entry mentioning `traceparent` AND no `headers.traceparent: false`
directive (defensive against regression).

##### FR-T5-TPE-046 — L1 test : Kong contract comment present

`_test_tpe_011_kong_contract_comment` MUST assert
`kong.yml.example` contains the W3C trace context preservation
comment block per FR-T5-TPE-021 (grep for the literal
"W3C trace context preservation" anchor).

##### FR-T5-TPE-047 — L1 test : Forge-CI matrix entry

`_test_tpe_020_ci_matrix_entry` MUST assert
`.github/workflows/forge-ci.yml` lists the new harness
`t5-otel-traceparent-e2e.test.sh` immediately after
`t5-otel-app.test.sh`, with `--level 1`.

---

#### Cluster 4 — L2 inheritance from Phase B (FR-T5-TPE-060..062)

##### FR-T5-TPE-060 — L2 cargo build inheritance

`_test_tpe_l2_001_cargo_build_inherited` MUST run
`cargo build -p bin-server --locked` in the example tree and expect
exit 0. Skips cleanly when `cargo` is absent. Mirrors Phase B's
`_test_ota_l2_001_cargo_build_bin_server`.

##### FR-T5-TPE-061 — L2 flutter analyze xfail inheritance (Q-004 cascade)

`_test_tpe_l2_002_flutter_analyze_inherited` MUST gracefully xfail
with an inline comment explaining the Q-004 cascade : the
`flutter/opentelemetry.md` standard predates an API realignment
that hasn't yet happened on the pub.dev `opentelemetry 0.18.x`
side. The `t5-otel-dart-api-realign` change addresses Q-004
separately. The xfail comment MUST mention :
- The Phase B test ID this xfail mirrors
  (`_test_ota_l2_002_flutter_analyze`).
- The Q-004 reference.
- The future-change name `t5-otel-dart-api-realign`.
- The "L1 anchors GREEN ; this L2 reactivates once Q-004 is
  resolved" phrasing for symmetry with Phase B.

##### FR-T5-TPE-062 — L2 gate phrasing identical to Phase B

The xfail comment in `_test_tpe_l2_002` MUST be phrased to match
Phase B's `_test_ota_l2_002_flutter_analyze` xfail comment style
verbatim where possible. This makes the inheritance auditable by
a simple diff of the two xfail blocks.

---

#### Cluster 5 — CI registration (FR-T5-TPE-080)

##### FR-T5-TPE-080 — `forge-ci.yml` matrix entry

`.github/workflows/forge-ci.yml` `harness` job MUST register
`t5-otel-traceparent-e2e.test.sh` immediately after
`t5-otel-app.test.sh` with `--level 1`. The step name MUST be
`t5-otel-traceparent-e2e.test.sh` for shell-grep auditability.

---

#### Cluster 6 — Documentation (FR-T5-TPE-090..091)

##### FR-T5-TPE-090 — `CHANGELOG.md` entry

`CHANGELOG.md` MUST gain an entry under `## [Unreleased]` flagging :
the BDD feature file `traceparent_e2e.feature`, the Kong gateway
preservation comment, the harness `t5-otel-traceparent-e2e.test.sh`,
and the forward-pointer to the deferred Envoy validation.

##### FR-T5-TPE-091 — Phase D deferral note in tasks.md

`tasks.md` MUST carry an explicit "Phase D — DEFERRED" section
enumerating the live-run leg deliverables : docker-compose driver,
stub OTLP receiver, traceId consistency assertion, SigNoz API
verification. This makes the scope split discoverable by future
implementers.

---

### Non-Functional Requirements

#### NFR-T5-TPE-001 — Performance budget (harness)

Harness `t5-otel-traceparent-e2e.test.sh --level 1` MUST complete in
≤ 3 s wall-clock (tight because all 7 L1 tests are simple greps
against ≤ 4 files). L2 budget : ≤ 90 s (inherited from Phase B).

#### NFR-T5-TPE-002 — Backward compatibility (build green)

After this change, `cargo build -p bin-server` MUST still succeed
without manual intervention. The dependency surface is unchanged
from Phase B ; this change adds zero new runtime deps.

#### NFR-T5-TPE-003 — Article V audit trail

Every task in `tasks.md` MUST carry a `[Story: FR-T5-TPE-XXX]` tag.

#### NFR-T5-TPE-004 — No production code edits

This change MUST NOT modify any `.rs`, `.dart`, `.proto`, or
`Cargo.toml` / `pubspec.yaml` file. Only `.feature`, `.yml.example`
(comment-only), `.sh`, `.yml` (CI matrix), and `.md` files are
touched. Hard architectural constraint — verified by
`git diff --stat` review.

#### NFR-T5-TPE-005 — Q-004 xfail inheritance documented

The `_test_tpe_l2_002` xfail comment MUST forward-reference the
Phase B equivalent (`_test_ota_l2_002`) and the future-change name
(`t5-otel-dart-api-realign`). This ensures Q-004 resolution
cascades cleanly to both harnesses when triaged.

#### NFR-T5-TPE-006 — Phase C ↔ Phase D scope discoverable

`tasks.md` § "Phase D — DEFERRED" MUST be present and reference at
least three of : `docker compose up`, `flutter run`, SigNoz API,
stub OTLP receiver, programmatic traceId assertion. Reader landing
on `tasks.md` must immediately understand what this change does
NOT do.

#### NFR-T5-TPE-007 — Envoy out-of-scope forward-pointer

`design.md` § Out of scope MUST cite `docs/ARCHITECTURE-TARGET.md`
ADR-001 (Envoy migration) and name the future change handling
Envoy traceparent validation (`b8-envoy-migration` per Q-002
resolution). Adopter reading `design.md` must know where Envoy
will be addressed.

---

## BDD Acceptance Criteria

The user-facing surface this change touches is the demo-005
round-trip evidence loop through the Kong gateway. Three Article II
scenarios ship inline below ; they are the source-of-truth that
`traceparent_e2e.feature` MUST mirror verbatim.

```gherkin
Feature: W3C traceparent end-to-end validation across the example archetype
  As a Forge full-stack-monorepo archetype consumer
  I want pressing the "Greet" button to produce a connected span tree at every hop
  So that SigNoz shows one traceId from Flutter root span to backend handler span

  Background:
    Given the example flagship stack ships the Phase A OTel collector at "http://fsm-otel-collector:4318"
    And the Phase B Rust SDK init wires "TraceContextPropagator" via "HeaderMapExtractor"
    And the Phase B Flutter SDK init wires "TracingInterceptor" with W3C "traceparent" injection
    And the Kong gateway preserves incoming "traceparent" and "tracestate" headers verbatim

  Scenario: Direct path — Flutter to axum to connectrpc handler to use case
    Given the Flutter app calls the backend directly (no gateway hop)
    When the user taps "Greet" with name "Forge"
    Then the Flutter client emits a span "POST /connect/greeting.v1.GreeterService/Greet"
    And the outbound request carries a "traceparent" header matching "00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]"
    And the Rust axum middleware creates a server span via "TraceLayer::new_for_http().make_span_with"
    And the connectrpc handler creates a child span "greeter.greet"
    And the use case `#[tracing::instrument]` creates a grand-child span
    And the four spans share the same "traceId" in the OTLP export

  Scenario: Kong path — Flutter to Kong to axum to handler to use case
    Given the Flutter app calls the backend through the Kong gateway
    And the Kong declarative config (kong.yml.example) has no "request_transformer.remove.headers" entry for "traceparent"
    When the user taps "Greet" with name "Forge"
    Then the Flutter client emits a span with a "traceparent" header
    And the Kong gateway forwards the request preserving "traceparent" and "tracestate" verbatim
    And the Rust axum middleware extracts the parent context from the preserved "traceparent" using "HeaderMapExtractor"
    And the connectrpc handler creates a child span "greeter.greet"
    And the use case `#[tracing::instrument]` creates a grand-child span
    And the five spans (four app + zero Kong, Kong is transparent) share the same "traceId" in the OTLP export

  Scenario: Sampled-off path — incoming traceparent with sampled bit cleared
    Given a client sends a "traceparent" header "00-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-bbbbbbbbbbbbbbbb-00"
    When the request reaches the Rust axum middleware
    Then the server span is recorded by the SDK (the "tracing" span handle is valid)
    But the "BatchSpanProcessor" does NOT export the span (ParentBased sampler honors the cleared sampled flag)
    And the OTel collector receives zero spans for "traceId" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    And SigNoz shows no trace tree for that traceId

# TODO(#TBD-OTEL-PHASE-D): Phase D wires the bdd_widget_test step bodies
# (Flutter side), the cucumber-rs step bodies (Rust side), and the
# docker-compose live-run driver. Phase C ships the scenario text +
# the harness gate ; Phase D ships the executor.
```

Step definitions deferred to Phase D :
- Flutter `bdd_widget_test` for the screen-side scenario steps.
- Rust `cucumber-rs` step definitions for the backend assertions.
- A docker-compose live-run harness asserting traceId consistency
  programmatically.

---

## Anti-Hallucination Pass

For each FR :

- **Testable** : every FR is asserted by at least one grep test in
  `t5-otel-traceparent-e2e.test.sh` (mapping in `tasks.md` during
  `/forge:plan`).
- **Unambiguous** : 2 open questions flagged in `open-questions.md`
  (Q-001 sampled-off semantics + Q-002 Envoy forward-pointer name)
  for `/forge:design` resolution. No inline `[NEEDS CLARIFICATION:]`
  markers in this `specs.md`.
- **Constitution-compliant** : Articles I (TDD), II (BDD scenarios
  shipped), III (specs first), IV (delta — additive only), V
  (audit trail), VIII (infra — Kong declarative-only honored), IX
  (observability — evidence loop closes), XII (governance — no
  standard bump). All honored.
- **Verifiable against Phase B** : symbol names (`HeaderMapExtractor`,
  `MetadataMapCarrier`, `HeaderMapCarrier`) match Phase B's actual
  source (`backend/crates/infrastructure/src/telemetry/propagation.rs`
  lines 21, 34, 49) verbatim.
- **Verifiable against Phase A** : sampler reference
  (`parentbased_traceidratio`) matches `observability.yaml` line 30
  verbatim.

---

## Open Questions

Inline `[NEEDS CLARIFICATION:]` markers : none in this `specs.md`.
All ambiguities tracked in `open-questions.md` :

- **Q-001** (FR-T5-TPE-006, sampled-off path SDK behaviour) → to
  be resolved in `design.md` ADR-T5-TPE-001 via Context7 review of
  `/open-telemetry/opentelemetry-rust` ParentBased sampler.
- **Q-002** (Envoy forward-pointer change name) → to be resolved
  in `design.md` § Out of scope.
