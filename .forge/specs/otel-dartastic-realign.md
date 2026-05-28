# Spec: otel-dartastic-realign

<!-- Audit: T.5.3 (t5-otel-dartastic-realign) — Workiva → Dartastic OTel substitution + flutter/opentelemetry.md v1.1.0 → v2.0.0 breaking bump. -->
<!-- Source change : `.forge/changes/t5-otel-dartastic-realign/` (archived 2026-05-26). -->
<!-- Predecessor : `.forge/specs/otel-app.md` (Phase B Workiva pin, superseded by .forge-update-notes forward-pointers). -->

**Namespace** : `FR-T53-*` / `NFR-T53-*`. **Constitution** :
v1.1.0. No amendment required. **First consumer of T5.2's 3-axis
checklist** — every external dependency pin documented in this
spec MUST tick the 3 axes inline.

## Source Documents — 3-axis verification (T5.2 inaugural application)

The 3 Dartastic packages were verified pre-spec via Context7 +
pub.dev WebFetch on 2026-05-18 :

| Dependency | Existence | API surface | Platform compatibility | Notes |
|---|---|---|---|---|
| `dartastic_opentelemetry_api @ ^1.0.0-beta.2` | [x] pub.dev verified-publisher mindfulsoftware.com | [x] OTelAPI, Tracer, Span, Context, Baggage, Attributes, Status, SpanKind, SpanProcessor, SpanExporter, W3CTraceContextPropagator, W3CBaggagePropagator | [x] Android, iOS, Linux, macOS, Web, Windows | beta line ratified per Q-002 (only resolvable path given SDK 0.9.5 constraint) |
| `dartastic_opentelemetry @ ^1.1.0-beta.6` | [x] pub.dev verified-publisher | [x] OTel.initialize, OtlpGrpcSpanExporter, OtlpHttpSpanExporter, Tracer, Span, Sampler (AlwaysOnSampler/AlwaysOffSampler/ParentBasedSampler/TraceIdRatioBasedSampler), Meter, Counter, Histogram, OTelLogger, LogRecord | [x] All Dart/Flutter targets | OTel spec 1.31.0 alignment |
| `flutterrific_opentelemetry @ ^0.4.0` | [x] pub.dev verified-publisher | [x] OTel-init helper, route observer, lifecycle, error/navigation auto-instrumentation, go_router integration | [x] Android+iOS "Full", Web "Complete OTLP/HTTP", desktop "Beta" | desktop beta not blocking — no archetype targets desktop |

No `[PLATFORM MISMATCH:]` markers raised across the 3 deps.

| Field | Value |
|---|---|
| **Plan ref** | `docs/new-archetypes-plan.md` §0.3 (T5.3 — t5-otel-dartastic-realign) |
| **Predecessor incidents** | Q-004 (Workiva 9 fabricated symbols, 2026-05-11) + Q-006 (Workiva web-only platform mismatch, 2026-05-16) |
| **Methodology source** | `t5-2-platform-verification` (archived 2026-05-18) ; 3-axis checklist applied above |
| **Standard frame** | `global/standards-lifecycle.md` v1.1.0 (T.4 + T5.2) ; T5.3 is the first breaking bump to land under the cadence rules |
| **Open questions** | Q-001 (flutterrific vs SDK), Q-002 (beta API pin), Q-003 (forward-pointer convention) |
| **Release target** | `v0.4.0-rc.1` (pre-GA minor — breaks `flutter/opentelemetry.md`) |
| **Independent review** | MANDATORY pre-archive per T5.2 self-validation lesson |

---

## ADDED Requirements

### Functional Requirements

#### Cluster A — `flutter/opentelemetry.md` v2.0.0 rewrite (FR-T53-A-001..030)

##### FR-T53-A-001 — File path preserved

The file `.forge/standards/flutter/opentelemetry.md` MUST remain
at that path (no rename). Only its content + frontmatter change.

##### FR-T53-A-002 — Frontmatter version bump

The frontmatter MUST declare `version: 2.0.0`.

##### FR-T53-A-003 — `breaking_change: true`

The frontmatter MUST declare `breaking_change: true` per
`global/standards-lifecycle.md` v1.1.0.

##### FR-T53-A-004 — last_reviewed bump

The frontmatter `last_reviewed:` MUST be set to the archive date
(2026-05-18 or later).

##### FR-T53-A-005 — pkg pins refreshed

The frontmatter MUST pin the new packages :
- `pkg_name_api: dartastic_opentelemetry_api`
- `pkg_version_api: ^1.0.0-beta.2`
- `pkg_name_sdk: dartastic_opentelemetry`
- `pkg_version_sdk: ^0.9.5`
- `pkg_name_flutter: flutterrific_opentelemetry`
- `pkg_version_flutter: ^0.4.0`
- `pkg_maintainer: mindfulsoftware.com (verified-publisher)`
- `pkg_source: https://pub.dev/packages/dartastic_opentelemetry`

##### FR-T53-A-006 — Audit comment

The file MUST carry `<!-- Audit: T.5.3 (t5-otel-dartastic-realign) ; supersedes Workiva pin from t5-otel-dart-api-realign -->` within the first 5 lines.

##### FR-T53-A-007 — Status banner

The file MUST open with a status banner reflecting Dartastic's
spec coverage : "Traces / Metrics / Logs — all 3 signals
spec-aligned per OTel 1.31.0".

##### FR-T53-A-008 — Inline 3-axis checklist

The standard MUST contain a "Source Documents — 3-axis verification"
H2 section reproducing the 3-axis table from this spec verbatim.
This makes the standard self-auditable per T5.2.

##### FR-T53-A-009 — H2 sections preserved

The 11 H2 sections from v1.1.0 MUST remain (titles stable for
adopter discoverability) : Technology Stack / SDK Initialization /
Sampling / HTTP Instrumentation via Dio Interceptor / Navigation
Observer / BLoC Observer / User Interaction Spans / Error
Instrumentation / Custom Spans / Context Propagation (W3C
traceparent) / Rules.

##### FR-T53-A-010 — Imports canoniques

The standard MUST document the canonical imports :
- `package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart`
- `package:dartastic_opentelemetry/dartastic_opentelemetry.dart`
- `package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart`

##### FR-T53-A-011 — Init API

The "SDK Initialization" H2 MUST document the canonical init
(per Q-001 likely resolution — flutterrific shim) :
- `await OTel.initialize(serviceName: <service>, endpoint: <otlp-http-url>)`
- Followed by route observer registration in the `MaterialApp.router`.

##### FR-T53-A-012 — Sampling section

The "Sampling" H2 MUST preserve the dual-stage Phase A (collector
`processors.probabilistic_sampler` per ADR-OTEL-001) + Phase B
(SDK `ParentBasedSampler(AlwaysOnSampler())`) model. Dartastic
exposes `AlwaysOnSampler`, `AlwaysOffSampler`, `ParentBasedSampler`,
`TraceIdRatioBasedSampler` — symbols documented verbatim.

##### FR-T53-A-013 — Migration from v1.1.0 section

The standard MUST add a NEW H2 "Migration from v1.1.0 (Workiva → Dartastic)"
documenting the symbol-by-symbol substitution for adopters
upgrading from v1.1.0.

##### FR-T53-A-014 — Removed-symbols block

The "Migration from v1.1.0" H2 MUST list the Workiva symbols being
**removed** : `CollectorExporter`, `BatchSpanProcessor` (Workiva),
`ParentBasedSampler` (Workiva), `StatusCode.{ok,error}`,
`contextWithSpan`, `package:opentelemetry/api.dart`,
`package:opentelemetry/sdk.dart`.

##### FR-T53-A-015 — Replaced-by block

The "Migration from v1.1.0" H2 MUST list the Dartastic symbols
that REPLACE them, with a 2-column "from → to" table.

##### FR-T53-A-016 — HTTP Instrumentation via Dio

The "HTTP Instrumentation via Dio Interceptor" H2 MUST document
the canonical interceptor against Dartastic `Tracer`/`Span`/W3C
propagator with concrete code skeleton.

##### FR-T53-A-017 — Navigation Observer

The "Navigation Observer" H2 MUST document the
`flutterrific_opentelemetry` go_router auto-observer registration
+ a manual fallback pattern for adopters using `Navigator 1.0`.

##### FR-T53-A-018 — BLoC Observer

The "BLoC Observer" H2 MUST document a `TracingBlocObserver` that
spans on event/transition/error using Dartastic `Tracer`.

##### FR-T53-A-019 — User Interaction Spans

The "User Interaction Spans" H2 MUST document the manual span
pattern (tap / scroll / form-submit) on top of Dartastic
`tracer.startSpan(...)`.

##### FR-T53-A-020 — Error Instrumentation

The "Error Instrumentation" H2 MUST document
`FlutterError.onError` + `runZonedGuarded` glue recording errors
on the current span via `span.setStatus(StatusCode.error, ...)`
and `span.recordException(...)`.

##### FR-T53-A-021 — Custom Spans

The "Custom Spans" H2 MUST document
`tracer.startSpan('domain.operation')` with attribute conventions
(`domain.*`, `app.*`, `user.*` namespaces per OTel semantic
conventions).

##### FR-T53-A-022 — Context Propagation

The "Context Propagation (W3C traceparent)" H2 MUST document the
`W3CTraceContextPropagator` symbol and the `traceparent` header
extraction/injection pattern. Required for FSM demo-005
traceparent round-trip continuity.

##### FR-T53-A-023 — Rules section preserved

The "Rules" H2 MUST list MUST/MUST NOT clauses ; at minimum :
- MUST initialise OTel before `runApp`.
- MUST set service.name.
- MUST register the route observer (flutterrific path).
- MUST NOT introduce Workiva `opentelemetry: ^0.18` (now forbidden).
- MUST NOT introduce phantom `opentelemetry_sdk` (the v1.1.0 era
  ghost-pkg).
- MUST NOT skip the 3-axis checklist on any external pkg.

##### FR-T53-A-024 — References

The "References" H2 MUST cite : Dartastic pub.dev pages (3 packages),
OTel specification 1.31.0, ADR-OTEL-001 collector sampling
contract, T5.2 checklist source.

##### FR-T53-A-025 — REVIEW.md ledger entry

`.forge/standards/REVIEW.md` MUST gain an append-only H2 entry
`## 2026-05-18 — Updated flutter/opentelemetry.md to v2.0.0 (t5-otel-dartastic-realign)` documenting :
- `breaking_change: true`
- Q-006 trigger
- 3-axis checklist applied inline
- Migration path documented in v2.0.0 § Migration

##### FR-T53-A-026 — Index trigger refresh

`.forge/standards/index.yml` entry for `flutter/opentelemetry` MUST
have its trigger list refreshed to include `dartastic`,
`flutterrific`, `otlp-http` (in addition to existing `otel`,
`opentelemetry`, `tracing` etc.).

##### FR-T53-A-027 — Forbidden block

The frontmatter `forbidden:` block MUST list the v1.1.0 Workiva
identifiers as forbidden : `opentelemetry: ^0.18`,
`opentelemetry_sdk` (phantom), `CollectorExporter` (Workiva-prefixed
namespace if it appears in adopter code).

##### FR-T53-A-028 — Linter integration (advisory)

The standard MUST note that adopter pubspecs containing the
forbidden Workiva pin SHOULD be caught by a future linter rule
(deferred — T6+ once T5.3 adoption produces enough signal).

##### FR-T53-A-029 — Anti-pattern section

The standard SHOULD carry an "Anti-patterns" subsection citing
the historical Q-004 + Q-006 lessons as concrete examples of what
not to do during ratification.

##### FR-T53-A-030 — Constitution xref

The standard MUST cross-reference Constitution Article III.4
(Ambiguity Protocol — anti-hallucination) and Article IX
(Observability) as its constitutional anchors.

#### Cluster B — FSM frontend rewrite (FR-T53-B-001..015)

##### FR-T53-B-001 — pubspec.yaml dep swap

`examples/forge-fsm-example/frontend/pubspec.yaml` MUST replace
the `opentelemetry: ^0.18.x` line with :
```yaml
dependencies:
  dartastic_opentelemetry: ^1.1.0-beta.6
  flutterrific_opentelemetry: ^0.4.0
```

##### FR-T53-B-002 — pubspec lockfile regen

`examples/forge-fsm-example/frontend/pubspec.lock` MUST be
regenerated via `flutter pub get` and committed (deterministic
across `flutter 3.x` per FSM minimum constraint).

##### FR-T53-B-003 — telemetry_setup.dart rewrite

`lib/core/telemetry/telemetry_setup.dart` MUST :
- Replace Workiva imports with Dartastic + flutterrific.
- Replace Workiva `OTel` provider init with
  `OTel.initialize(serviceName: 'forge-fsm-frontend', endpoint: '<otlp-http>')`.
- Expose a top-level `Future<void> setupTelemetry()` function
  called from `main.dart` before `runApp`.

##### FR-T53-B-004 — error_reporter.dart rewrite

`lib/core/telemetry/error_reporter.dart` MUST :
- Use Dartastic `Span` + `Status.error` + `span.recordException()`.
- Wire `FlutterError.onError` and `runZonedGuarded` callbacks.

##### FR-T53-B-005 — tracing_interceptor.dart rewrite

`lib/core/telemetry/interceptors/tracing_interceptor.dart` MUST :
- Use Dartastic `Tracer` for span creation.
- Use `W3CTraceContextPropagator` for outbound `traceparent` injection.
- Preserve the existing demo-005 traceparent round-trip behaviour.

##### FR-T53-B-006 — tracing_navigation_observer.dart rewrite

`lib/core/telemetry/observers/tracing_navigation_observer.dart` MUST :
- Use `flutterrific_opentelemetry`'s built-in route observer where
  possible.
- If keeping a custom `NavigatorObserver`, span on
  `didPush`/`didPop`/`didReplace` against Dartastic `Tracer`.

##### FR-T53-B-007 — tracing_bloc_observer.dart rewrite

`lib/core/telemetry/observers/tracing_bloc_observer.dart` MUST :
- Extend `BlocObserver` (flutter_bloc).
- Span on `onEvent`/`onTransition`/`onError` against Dartastic
  `Tracer`.

##### FR-T53-B-008 — main.dart wiring

`examples/forge-fsm-example/frontend/lib/main.dart` MUST call
`await setupTelemetry()` before `runApp(...)`. (May not require
changes if already wired via `telemetry_setup.dart` ; verify and
adjust if the import path or function signature changes.)

##### FR-T53-B-009 — No phantom imports

NO file under `examples/forge-fsm-example/frontend/lib/` MUST
import `package:opentelemetry/...` (Workiva) or
`package:opentelemetry_sdk/...` (phantom). Harness L1 asserts.

##### FR-T53-B-010 — Demo-005 traceparent preserved

The FSM `demo-005` traceparent round-trip behaviour (from
`t5-otel-app` / `t5-otel-traceparent-e2e`) MUST continue to work
post-rewrite. Smoke validation in L2.

##### FR-T53-B-011 — Service name preserved

Service name attribute (`service.name`) MUST stay
`forge-fsm-frontend` (or the equivalent existing value — verify
during implementation, do not silently rename).

##### FR-T53-B-012 — Endpoint configurability

The OTLP endpoint URL MUST be configurable via env var
(`OTEL_EXPORTER_OTLP_ENDPOINT`) per the existing `t5-otel-stack`
convention.

##### FR-T53-B-013 — Sampler choice

The SDK-side sampler MUST be `ParentBasedSampler(AlwaysOnSampler())`
to preserve Phase A (collector) + Phase B (SDK) dual-stage
sampling per ADR-OTEL-001.

##### FR-T53-B-014 — `flutter pub get` GREEN

After the rewrite, `flutter pub get` on FSM frontend MUST exit 0.
Verified in L2 opt-in.

##### FR-T53-B-015 — `flutter analyze` GREEN

After the rewrite, `flutter analyze` on FSM frontend MUST exit 0
with zero warnings (existing project convention). Verified in L2.

#### Cluster C — Mobile-only template rewrite (FR-T53-C-001..010)

##### FR-T53-C-001 — pubspec.yaml.tmpl

`.forge/templates/archetypes/mobile-only/pubspec.yaml.tmpl` MUST :
- REMOVE the phantom `opentelemetry_sdk: ^0.18.x` line (it never
  existed on pub.dev).
- REMOVE the Workiva `opentelemetry: ^0.18.x` line.
- ADD `dartastic_opentelemetry: ^1.1.0-beta.6` + `flutterrific_opentelemetry: ^0.4.0`.

##### FR-T53-C-002 — otel_init.dart.tmpl

`.forge/templates/archetypes/mobile-only/lib/observability/otel_init.dart.tmpl`
MUST :
- Replace Workiva imports with Dartastic + flutterrific.
- Use `OTel.initialize(...)` pattern.

##### FR-T53-C-003 — cli/assets mirror — pubspec.yaml.tmpl

`cli/assets/.forge/templates/archetypes/mobile-only/pubspec.yaml.tmpl`
MUST be byte-identical to FR-T53-C-001 source (cli build pipeline
copies the template into the published tarball).

##### FR-T53-C-004 — cli/assets mirror — otel_init.dart.tmpl

`cli/assets/.forge/templates/archetypes/mobile-only/lib/observability/otel_init.dart.tmpl`
MUST be byte-identical to FR-T53-C-002 source.

##### FR-T53-C-005 — Other mobile-only Dart files

Any other Dart file under `.forge/templates/archetypes/mobile-only/lib/**`
referencing Workiva MUST be rewritten on Dartastic. The harness
L1 must grep zero remaining Workiva imports in the template tree.

##### FR-T53-C-006 — README.md.tmpl mention

If `.forge/templates/archetypes/mobile-only/README.md.tmpl` cites
the observability stack, it MUST mention Dartastic (replacing any
Workiva reference). Otherwise NOP.

##### FR-T53-C-007 — `flutter pub get` on fresh scaffold

A fresh `forge init --archetype mobile-only --target <tmpdir>`
followed by `flutter pub get` MUST exit 0. Verified in L2.

##### FR-T53-C-008 — `flutter analyze` on fresh scaffold

`flutter analyze` on the fresh scaffold MUST exit 0 with zero
warnings. **This is the test that closes the v0.3.3 deferred-RED
status** (CHANGELOG v0.3.3 noted "remaining mobile-only `flutter analyze`
failure deferred to T5.3").

##### FR-T53-C-009 — Test files preserved

Any existing test under `.forge/templates/archetypes/mobile-only/test/`
or `integration_test/` that exercises the observability layer
MUST be rewritten against Dartastic OR explicitly tagged as
"not affected" if Workiva-agnostic.

##### FR-T53-C-010 — analysis_options.yaml

`.forge/templates/archetypes/mobile-only/analysis_options.yaml`
MUST NOT need changes for Dartastic — adopters' analyzer config
is independent of OTel pkg choice. Verified by FR-T53-C-008
analyze run.

#### Cluster D — Forward-pointers in archived changes (FR-T53-D-001..006)

Per Q-003 likely resolution : Option A + C combined.

##### FR-T53-D-001 — b4-mobile-only `.forge-update-notes`

`.forge/changes/b4-mobile-only/.forge-update-notes` MUST be
created with :
- H1 `# Update Notes — b4-mobile-only`
- H2 `## Superseded standard pin (T5.3, 2026-05-18)`
- Body : one paragraph documenting that the Workiva
  `opentelemetry: ^0.18` + phantom `opentelemetry_sdk` pin from
  this archive's template has been superseded by Dartastic in
  T5.3 ; pointer to `.forge/standards/flutter/opentelemetry.md`
  v2.0.0 and `.forge/changes/t5-otel-dartastic-realign/`.

##### FR-T53-D-002 — t5-otel-app `.forge-update-notes`

`.forge/changes/t5-otel-app/.forge-update-notes` — same structure
as FR-T53-D-001 ; supersedes the Workiva SDK init wiring.

##### FR-T53-D-003 — t5-otel-dart-api-realign `.forge-update-notes`

`.forge/changes/t5-otel-dart-api-realign/.forge-update-notes` —
same structure ; supersedes the Workiva v1.1.0 realign itself
(Q-004 resolution made obsolete by Q-006 substitution).

##### FR-T53-D-004 — Archived files byte-identical

The existing `.forge.yaml`, `proposal.md`, `specs.md`, `design.md`,
`tasks.md`, `open-questions.md` files inside the 3 archived
changes MUST remain byte-identical (Article V immutability). Only
the new `.forge-update-notes` file is added.

##### FR-T53-D-005 — Global supersession graph

The new `.forge/changes/t5-otel-dartastic-realign/.forge.yaml`
MUST include a `supersedes:` field (or equivalent comment block)
listing the 3 affected archives.

##### FR-T53-D-006 — `.forge-update-notes` is discoverable

`bin/forge-questions.sh` or similar discovery tool SHOULD surface
`.forge-update-notes` files when present (advisory ; out of scope
for T5.3 implementation, but harness asserts the file is parseable
Markdown).

#### Cluster E — Harness `t5-otel-dartastic.test.sh` (FR-T53-E-001..018)

##### FR-T53-E-001 — File presence

`.forge/scripts/tests/t5-otel-dartastic.test.sh` MUST exist,
executable (`chmod +x`), `set -uo pipefail`, source `_helpers.sh`,
mirror the J.7 / I.5 / K.3 / T5.2 pattern.

##### FR-T53-E-002 — Test name namespace

Each test function MUST be named `_test_t53_l1_NNN_<description>`
or `_test_t53_l2_NNN_<description>`.

##### FR-T53-E-003 — Audit comment

The harness MUST carry `# Audit: T.5.3 (t5-otel-dartastic-realign)`
within the first 5 lines.

##### FR-T53-E-004 — L1.001 — standard file v2.0.0 frontmatter

Asserts `version: 2.0.0` in `flutter/opentelemetry.md` frontmatter.

##### FR-T53-E-005 — L1.002 — breaking_change: true

Asserts `breaking_change: true` in the standard's frontmatter.

##### FR-T53-E-006 — L1.003 — Dartastic imports present

Asserts the standard contains the 3 canonical Dartastic import
strings (`package:dartastic_opentelemetry_api/...`,
`package:dartastic_opentelemetry/...`,
`package:flutterrific_opentelemetry/...`).

##### FR-T53-E-007 — L1.004 — Workiva imports absent

Asserts the standard does NOT contain
`package:opentelemetry/api.dart` or
`package:opentelemetry/sdk.dart` (Workiva paths).

##### FR-T53-E-008 — L1.005 — Phantom symbol absent

Asserts NO file under `.forge/templates/archetypes/mobile-only/**`
or `examples/forge-fsm-example/frontend/lib/**` references
`opentelemetry_sdk` (the phantom). Greps both trees.

##### FR-T53-E-009 — L1.006 — 3-axis checklist embedded

Asserts the standard contains the H2 "Source Documents — 3-axis verification"
AND the 3 axis labels (`Existence`, `API surface`, `Platform compatibility`).

##### FR-T53-E-010 — L1.007 — Migration H2

Asserts the standard contains the H2 "Migration from v1.1.0".

##### FR-T53-E-011 — L1.008 — REVIEW ledger entry

Asserts `.forge/standards/REVIEW.md` contains the H2 line matching
`^## 20[0-9]{2}-[0-9]{2}-[0-9]{2} — Updated flutter/opentelemetry\.md to v2\.0\.0 \(t5-otel-dartastic-realign\)$`.

##### FR-T53-E-012 — L1.009 — FSM pubspec uses Dartastic

Asserts `examples/forge-fsm-example/frontend/pubspec.yaml`
contains `dartastic_opentelemetry:` AND `flutterrific_opentelemetry:`
AND does NOT contain `^0.18` Workiva-version-range.

##### FR-T53-E-013 — L1.010 — Mobile-only pubspec.yaml.tmpl uses Dartastic

Asserts `.forge/templates/archetypes/mobile-only/pubspec.yaml.tmpl`
contains the 2 Dartastic packages AND does NOT contain
`opentelemetry_sdk` or `opentelemetry: ^0.18`.

##### FR-T53-E-014 — L1.011 — cli/assets mirror byte-identical

Asserts
`cli/assets/.forge/templates/archetypes/mobile-only/pubspec.yaml.tmpl`
== source tmpl (diff -q). Similarly for `otel_init.dart.tmpl`.

##### FR-T53-E-015 — L1.012 — Forward-pointer files present

Asserts `.forge/changes/b4-mobile-only/.forge-update-notes`,
`.forge/changes/t5-otel-app/.forge-update-notes`, and
`.forge/changes/t5-otel-dart-api-realign/.forge-update-notes`
all exist with the canonical H2 anchor.

##### FR-T53-E-016 — L1.013 — Article III.4 xref

Asserts the standard contains the literal `Article III.4` (the
correct anti-hallucination article ; T5.2 lesson applied).

##### FR-T53-E-017 — L2.001 — flutter pub get on FSM frontend (opt-in)

Opt-in via `FORGE_T53_LIVE=1`. Runs `flutter pub get` in
`examples/forge-fsm-example/frontend/` ; asserts exit 0.
Skip-pass if `flutter` absent from PATH.

##### FR-T53-E-018 — L2.002 — flutter pub get + analyze on fresh mobile-only scaffold (opt-in)

Opt-in via `FORGE_T53_LIVE=1`. Runs `forge init --archetype mobile-only`
in a `mkdtemp`, then `flutter pub get` + `flutter analyze` ;
asserts both exit 0. Skip-pass if `flutter` absent or `forge`
binary not on PATH.

#### Cluster F — CI matrix + CHANGELOG + cli line budget (FR-T53-F-001..004)

##### FR-T53-F-001 — CI matrix entry

`.github/workflows/forge-ci.yml` matrix MUST register
`t5-otel-dartastic.test.sh --level 1`. Position : immediately
after `t5-2.test.sh` (alphabetical / chronological grouping).

##### FR-T53-F-002 — CI line budget preserved

`.github/workflows/forge-ci.yml` MUST stay ≤ 300 lines per
`t5-1.test.sh::_test_t51_l1_017_ci_line_budget`. Adding the T5.3
entry pushes the line count up ; if needed, compact one
neighbouring comment block (precedent : T5.2 compacted
`t5-otel-traceparent-e2e` + `t5-otel-live-run` comments to fit).

##### FR-T53-F-003 — CHANGELOG.md entry

`CHANGELOG.md [Unreleased]` MUST gain a `### Changed (BREAKING)`
entry citing :
- change name `t5-otel-dartastic-realign`
- standard bump v1.1.0 → v2.0.0
- 3-axis checklist inaugural application
- Q-006 resolution
- target release v0.4.0-rc.1.

##### FR-T53-F-004 — Open Questions resolved

`bin/forge-questions.sh --change t5-otel-dartastic-realign` MUST
return no open questions at archive time. Q-001 + Q-002 + Q-003
resolved by `/forge:design` ADRs.

#### Cluster G — Inaugural T5.2 checklist application (FR-T53-G-001..004)

##### FR-T53-G-001 — Checklist ticked in proposal.md

`.forge/changes/t5-otel-dartastic-realign/proposal.md` § Source
Documents MUST contain the 3-axis checklist table with `[x]` boxes
on all 3 axes for all 3 packages.

##### FR-T53-G-002 — Checklist ticked in specs.md

THIS file (specs.md) § Source Documents MUST contain the same
3-axis table. Verbatim grep enforced.

##### FR-T53-G-003 — Checklist embedded in v2.0.0 standard

Per FR-T53-A-008, the v2.0.0 standard MUST embed the 3-axis table.

##### FR-T53-G-004 — No `[PLATFORM MISMATCH:]` markers

NO `[PLATFORM MISMATCH:]` marker MUST appear inline in this
change's proposal/specs/design. The substitution satisfies all 3
axes for every consuming archetype, so no mismatch escalation is
needed.

### Non-Functional Requirements

##### NFR-T53-001 — Zero new transitive root dependency

T5.3 MUST NOT add any new external dependency beyond the 3
Dartastic packages themselves and their declared transitive
dependencies (resolved by Dart's pub solver). No npm / Cargo /
Maven additions.

##### NFR-T53-002 — Harness wall-clock budget

`t5-otel-dartastic.test.sh --level 1` MUST complete in ≤ 5 s
wall-clock. L2 opt-in (`FORGE_T53_LIVE=1`) MAY add up to 60 s for
`flutter pub get` + `flutter analyze` on 2 surfaces (FSM + mobile-only
scaffold). L2 has a 120 s hard timeout each.

##### NFR-T53-003 — Auditability via REVIEW ledger

The breaking bump v1.1.0 → v2.0.0 MUST appear in REVIEW.md
(FR-T53-A-025) so a future auditor can reconstruct the substitution
without reading git history (Article XII).

##### NFR-T53-004 — Backward compat at framework level

T5.3 MUST NOT break any unrelated harness, CI matrix entry, J.7
validator, or archived change file. `verify.sh` overall PASS
preserved. Only intentional break : adopters using v1.1.0 standard
must migrate (documented).

##### NFR-T53-005 — Cli/assets mirror discipline preserved

The cli/assets mirror discipline (every template change in
`.forge/templates/` mirrored in `cli/assets/.forge/templates/`)
MUST be preserved. Existing precedent : T5.1 archetypes-smoke
test relies on cli/assets being byte-identical to source templates.

##### NFR-T53-006 — Beta dependency formally waived

Pinning `dartastic_opentelemetry_api ^1.0.0-beta.2` (transitive
via SDK 0.9.5) constitutes a beta-line dep ratification. This is
formally waived by ADR-T53-002 (Q-002) ; the waiver MUST be
documented in the v2.0.0 standard's frontmatter `rationale` block
AND in REVIEW.md.

##### NFR-T53-007 — Harness failure message FR ID

Like T5.2, harness failure messages MUST cite the failing FR-T53-*
identifier first.

##### NFR-T53-008 — Article V immutability

Archived changes (`b4-mobile-only`, `t5-otel-app`,
`t5-otel-dart-api-realign`) MUST NOT have ANY of their pre-T5.3
files modified. Only new `.forge-update-notes` files added.
Asserted by FR-T53-D-004 + diff against `main` post-archive.

##### NFR-T53-009 — Article III.4 alignment

T5.3 MUST cite Article III.4 (Ambiguity Protocol — anti-hallucination)
verbatim, NOT "Article VIII" or any other fabricated constitutional
reference (T5.2 self-validation lesson : every constitutional citation
verified against `.forge/constitution.md` before commit). Harness
FR-T53-E-016 enforces.

##### NFR-T53-010 — Independent code-reviewer pre-archive

MANDATORY per T5.2 self-validation lesson : T5.3 MUST go through
an independent `code-reviewer` agent pass BEFORE `/forge:archive`.
The reviewer MUST verify : 3-axis checklist application, Dartastic
symbol accuracy via Context7, no fabricated constitutional refs,
Article V immutability of the 3 archived changes. Skipping this
forfeits T5.2's central learning.

---

## BDD Acceptance Criteria

### BDD-T53-001 — Adopter migrates from v1.1.0 to v2.0.0

```gherkin
Given an adopter project has `flutter/opentelemetry.md` v1.1.0
  in scope and uses Workiva `opentelemetry: ^0.18` in pubspec
And the adopter runs `forge upgrade` (post-T5.3 release)
When the adopter consults `flutter/opentelemetry.md` v2.0.0
  § "Migration from v1.1.0 (Workiva → Dartastic)"
Then the adopter MUST find the symbol-by-symbol from→to table
And the adopter can mechanically replace the Workiva imports
  with Dartastic equivalents
And `flutter pub get` MUST resolve cleanly after the swap.
```

### BDD-T53-002 — Fresh mobile-only scaffold compiles

```gherkin
Given an adopter runs `forge init --archetype mobile-only --target <dir>`
  with the post-T5.3 published CLI
When the adopter runs `flutter pub get` in the scaffolded dir
Then exit code MUST be 0
And `flutter analyze` MUST also exit 0 with zero warnings
And no reference to Workiva `opentelemetry: ^0.18` or
  `opentelemetry_sdk` (phantom) MUST appear anywhere in the
  scaffolded tree.
```

### BDD-T53-003 — FSM example traceparent round-trip preserved

```gherkin
Given the post-T5.3 FSM example frontend
And the backend OTel collector running on `:4318`
When the user clicks the demo-005 "issue traced call" button
Then the outbound HTTP request MUST carry a W3C `traceparent` header
And the response trace must continue the inbound trace context
And the resulting spans in the collector form one trace tree
  (same as pre-T5.3 t5-otel-traceparent-e2e behaviour).
```

---

## Anti-Hallucination Pass

| FR cluster | Testable ? | Ambiguous ? | Constitution-compliant ? | External-dep claim ? |
|---|---|---|---|---|
| A (standard) | YES — grep + frontmatter + H2 | Q-001 + Q-002 open ; resolution in design | Article III.4 + IX + XII | 3 Dartastic pkgs verified inline via 3-axis |
| B (FSM frontend) | YES — file content + L2 pub get + analyze | None | Article VI (Flutter arch) | Same 3 pkgs |
| C (mobile-only template) | YES — file content + L2 fresh scaffold | None | Article VI | Same 3 pkgs |
| D (forward-pointers) | YES — file presence + H2 anchor | Q-003 open ; resolution in design | Article V immutability | None |
| E (harness L1+L2) | YES — each test maps to FR | None | Article I | None (curl + flutter optional) |
| F (CI matrix + CHANGELOG) | YES — grep | None | Article V audit | None |
| G (T5.2 application) | YES — table presence + no MISMATCH marker | None | Article III.4 reinforcement | None — meta-requirement |

No `[NEEDS CLARIFICATION:]` marker inline. 3 open questions
(Q-001..Q-003) deferred to `/forge:design` resolution at design
time and fully resolved before archive.

---

## Out of Scope (asserted negatively)

- No B.8 flagship migration (Kong→Envoy, DBOS, Connect-RPC) — T6.
- No `full-stack-monorepo/2.0.0` schema bump — T6 / B.8.
- No snapshot tarball regen — next bump.
- No `.forge/changes/<archived>/*.md` modification — Article V.
- No new linter rule (T6+ when adoption signal exists).
- No upstream Dartastic PRs (e.g. requesting `_api 1.0.0` GA) —
  external maintainer scope.
- No Metrics + Logs Dart wiring in FSM/mobile-only — Traces only
  in code ; spec covers all 3 signals.
- No desktop platform support in archetypes — flutterrific desktop
  is beta ; T8+ may revisit if archetypes target desktop.
