# Specs: t5-otel-dart-api-realign
<!-- Status: specified -->
<!-- Schema: default -->

> Read alongside `proposal.md`, `design.md` (ADR-T5-FOTDA-001..002), and
> `open-questions.md` (Q-001..Q-003). FR / NFR namespace : `FR-FOT-DA-NNN`
> / `NFR-FOT-DA-NNN` (Flutter OTel — Dart API).

## ADDED — `.forge/standards/flutter/opentelemetry.md` v1.1.0

### Cluster 1 — Frontmatter & metadata

- **FR-FOT-DA-001** — The standard MUST carry a YAML frontmatter block
  at the top of the file (between `---` delimiters) with the keys :
  `version`, `last_reviewed`, `pkg`, `pkg_version`, `pkg_maintainer`,
  `pkg_source`. Test : `t5-otel-dart-api-realign.test.sh::_test_fda_001_frontmatter_block`.
- **FR-FOT-DA-002** — `version: 1.1.0` (bumped from v1.0.0 ; minor
  bump per `standards-lifecycle.md` since the rewrite is content-shift,
  not breaking removal). Test :
  `_test_fda_002_frontmatter_version_110`.
- **FR-FOT-DA-003** — `last_reviewed: 2026-05-11` (today, per
  `currentDate`). Test : `_test_fda_003_frontmatter_last_reviewed`.
- **FR-FOT-DA-004** — `pkg: opentelemetry` ;
  `pkg_version: 0.18.11` ; `pkg_maintainer: Workiva` ;
  `pkg_source: https://pub.dev/packages/opentelemetry/versions/0.18.11`.
  Test : `_test_fda_004_frontmatter_pkg_metadata`.

### Cluster 2 — Setup section rewrite

- **FR-FOT-DA-010** — The `## SDK Initialization` H2 section MUST
  declare imports `package:opentelemetry/api.dart` and
  `package:opentelemetry/sdk.dart` only. The legacy
  `package:opentelemetry/exporter_otlp_http.dart` and
  `package:opentelemetry/exporter_otlp_grpc.dart` sub-imports MUST
  be absent (they are not exported by 0.18.11). Test :
  `_test_fda_010_setup_imports`.
- **FR-FOT-DA-011** — The setup snippet MUST use
  `CollectorExporter(Uri.parse(config.otlpEndpoint))` as the
  exporter constructor (single positional `Uri` argument).
  Legacy `OtlpHttpSpanExporter(OtlpHttpExporterConfig(...))` MUST
  NOT appear. Test : `_test_fda_011_setup_collector_exporter`.
- **FR-FOT-DA-012** — The setup snippet MUST use
  `BatchSpanProcessor(exporter, maxExportBatchSize: 512,
  scheduledDelayMillis: 5000)` (positional exporter + named
  params). Legacy `BatchSpanProcessorConfig(...)` MUST NOT appear.
  Test : `_test_fda_012_setup_batch_processor`.
- **FR-FOT-DA-013** — The setup snippet MUST construct
  `Resource([Attribute.fromString(...), ...])` as a positional list
  of `Attribute` objects, using `ResourceAttributes.serviceName`,
  `ResourceAttributes.serviceVersion`, and
  `ResourceAttributes.deploymentEnvironment` keys. Test :
  `_test_fda_013_setup_resource`.
- **FR-FOT-DA-014** — The setup snippet MUST instantiate
  `TracerProviderBase(resource: resource, processors: [processor],
  sampler: ParentBasedSampler(AlwaysOnSampler()))`. Per ADR-T5-FOTDA-001,
  ratio semantics are realised collector-side (no
  `TraceIdRatioBasedSampler` exists in 0.18.11). Test :
  `_test_fda_014_setup_tracer_provider`.
- **FR-FOT-DA-015** — The setup snippet MUST end with
  `registerGlobalTracerProvider(tracerProvider)`. Test :
  `_test_fda_015_setup_register_global`.

### Cluster 3 — HTTP Instrumentation (Dio Interceptor) section

- **FR-FOT-DA-020** — The interceptor MUST initialise via
  `globalTracerProvider.getTracer('http.client')`. Test :
  `_test_fda_020_interceptor_get_tracer`.
- **FR-FOT-DA-021** — On request, the interceptor MUST call
  `_tracer.startSpan(name, kind: SpanKind.client, attributes: [...])`.
  Attribute helpers `Attribute.fromString(key, value)` and
  `Attribute.fromInt(key, value)` are used. Test :
  `_test_fda_021_interceptor_start_span`.
- **FR-FOT-DA-022** — Context propagation MUST use
  `W3CTraceContextPropagator()` instance + its `.inject(...)` method
  with **`contextWithSpan(Context.current, span)`** as the first
  argument (top-level helper from `api.dart`). Legacy
  `Context.current.withSpan(span)` MUST NOT appear. Test :
  `_test_fda_022_interceptor_context_propagation`.
- **FR-FOT-DA-023** — On response, the interceptor MUST call
  `span.setStatus(StatusCode.ok)` (zero-arg `description`). Legacy
  `SpanStatusCode.ok` MUST NOT appear. Test :
  `_test_fda_023_interceptor_status_ok`.
- **FR-FOT-DA-024** — On error, the interceptor MUST call
  `span.setStatus(StatusCode.error, err.message ?? '')` (positional
  description, not `message:`). Legacy `setStatus(...code, message:
  ...)` MUST NOT appear. Test :
  `_test_fda_024_interceptor_status_error_positional`.

### Cluster 4 — Sampler section (new H2)

- **FR-FOT-DA-030** — A new H2 section `## Sampling` MUST exist
  documenting the SDK-side sampler shape. Default :
  `ParentBasedSampler(AlwaysOnSampler())`. Test :
  `_test_fda_030_sampling_section`.
- **FR-FOT-DA-031** — The Sampling section MUST explicitly note
  that `TraceIdRatioBasedSampler` is **not exported** by
  `opentelemetry 0.18.11`, and that the env-tier ratio is realised
  collector-side via `processors.probabilistic_sampler` per
  `t5-otel-stack` ADR-OTEL-001. Test :
  `_test_fda_031_sampling_collector_side_ratio_note`.

### Cluster 5 — Status / Context / Span sections

- **FR-FOT-DA-040** — All `SpanStatusCode` references in v1.0.0 MUST
  be replaced with `StatusCode` (the actual enum exported by
  `api.dart`). The standard MUST NOT contain the token
  `SpanStatusCode` anywhere. Test :
  `_test_fda_040_no_legacy_span_status_code`.
- **FR-FOT-DA-041** — All `Context.current.withSpan(...)` references
  in v1.0.0 MUST be replaced with `contextWithSpan(Context.current,
  ...)`. The standard MUST NOT contain `Context.current.withSpan`
  anywhere. Test : `_test_fda_041_no_legacy_with_span_method`.
- **FR-FOT-DA-042** — All `setStatus(..., message:` references in
  v1.0.0 MUST be replaced with the positional
  `setStatus(StatusCode.error, '...')` form. The standard MUST NOT
  contain the literal `message:` named-argument pattern adjacent
  to a `setStatus` call. Test :
  `_test_fda_042_no_legacy_message_named_param`.

### Cluster 6 — Forbidden legacy identifiers (anti-regression)

- **FR-FOT-DA-050** — The standard MUST NOT contain the literal
  string `OtlpHttpSpanExporter`. Test :
  `_test_fda_050_no_otlp_http_span_exporter`.
- **FR-FOT-DA-051** — The standard MUST NOT contain the literal
  string `OtlpHttpExporterConfig`. Test :
  `_test_fda_051_no_otlp_http_exporter_config`.
- **FR-FOT-DA-052** — The standard MUST NOT contain the literal
  string `BatchSpanProcessorConfig`. Test :
  `_test_fda_052_no_batch_span_processor_config`.
- **FR-FOT-DA-053** — The standard MUST NOT contain the literal
  string `TraceIdRatioBasedSampler`. Test :
  `_test_fda_053_no_trace_id_ratio_based_sampler`.
- **FR-FOT-DA-054** — The standard MUST NOT contain the import
  `package:opentelemetry/exporter_otlp_http.dart`. Test :
  `_test_fda_054_no_exporter_otlp_http_subimport`.
- **FR-FOT-DA-055** — The standard MUST NOT contain the import
  `package:opentelemetry/exporter_otlp_grpc.dart`. Test :
  `_test_fda_055_no_exporter_otlp_grpc_subimport`.

### Cluster 7 — Status callout (Q-001 resolution)

- **FR-FOT-DA-060** — The standard MUST carry a "Status (per Workiva
  README, 2026-05-11)" callout block (`> Status:` blockquote or
  similar) at the top, documenting :
  `Traces: Beta`, `Metrics: Alpha`, `Logs: Unimplemented`. Test :
  `_test_fda_060_workiva_status_callout`.
- **FR-FOT-DA-061** — The Status callout MUST explicitly scope the
  v1.1.0 standard to **traces only** (metrics and logs out of scope
  for this revision per Q-001 resolution). Test :
  `_test_fda_061_scope_traces_only`.

### Cluster 8 — Preserved sections (Navigation / BLoC / Error / Custom Spans / Rules)

- **FR-FOT-DA-070** — The `## Navigation Observer` H2 section MUST
  exist with `TracingNavigationObserver extends NavigatorObserver`
  body using `StatusCode.ok` (not `SpanStatusCode.ok`) and
  `span.end()` calls. Test : `_test_fda_070_navigation_observer`.
- **FR-FOT-DA-071** — The `## BLoC Observer` H2 section MUST
  exist with `TracingBlocObserver extends BlocObserver` body using
  `StatusCode.error` (not `SpanStatusCode.error`). Test :
  `_test_fda_071_bloc_observer`.
- **FR-FOT-DA-072** — The `## Error Instrumentation` H2 section
  MUST exist with `ErrorReporter` body using
  `recordException(error, stackTrace: stackTrace)` and
  `setStatus(StatusCode.error)`. Test :
  `_test_fda_072_error_reporter`.
- **FR-FOT-DA-073** — The `## Custom Spans` H2 section MUST exist
  with the try/finally pattern preserved (`span.end()` in finally).
  Test : `_test_fda_073_custom_spans`.
- **FR-FOT-DA-074** — The `## Rules` H2 section MUST exist with the
  five preserved rules : no PII in spans, sanitize URL paths,
  spans always ended via try/finally, BatchSpanProcessor with 5 s
  interval + 512 max batch, resource attributes set once at
  startup. Test : `_test_fda_074_rules_section`.

## ADDED — `.forge/standards/REVIEW.md` ledger entry

- **FR-FOT-DA-080** — A new H2 entry MUST be appended to
  `.forge/standards/REVIEW.md` at the bottom of the file
  (append-only per Article XII), titled `## 2026-05-11 — Updated
  flutter/opentelemetry.md to v1.1.0 (t5-otel-dart-api-realign)`.
  Test : `_test_fda_080_review_entry_present`.
- **FR-FOT-DA-081** — The entry MUST follow the schema documented
  at the top of `REVIEW.md` : Reviewer, Reviewed standards (table
  with Version `1.1.0`, Decision `KEEP-WITH-CHANGES`), Decision
  paragraph, Notes paragraph. Test :
  `_test_fda_081_review_entry_schema`.
- **FR-FOT-DA-082** — The Notes section MUST explicitly reference
  `Q-004` (the open question this change resolves) and the
  Context7 + WebFetch verification path. Test :
  `_test_fda_082_review_entry_q004_reference`.

## ADDED — `.forge/scripts/tests/t5-otel-dart-api-realign.test.sh` harness

- **FR-FOT-DA-090** — The harness MUST exist at
  `.forge/scripts/tests/t5-otel-dart-api-realign.test.sh`, executable,
  with the `--level 1` flag parser shared with the other harnesses
  (copy from `t5-otel.test.sh` skeleton). Test :
  `_test_fda_090_harness_exists` (self-meta — the harness checks its
  own presence is N/A ; this FR's gate is filesystem `[ -x ... ]`).
- **FR-FOT-DA-091** — The harness MUST source `_helpers.sh` and call
  `run_test` for each of the 12 declared tests. Test :
  shellcheck + harness self-run with `PASS=12 FAIL=0`.
- **FR-FOT-DA-092** — The harness MUST complete L1 in ≤ 3 s
  wall-clock on a hot disk cache (NFR budget). Test :
  performance check at impl time.

## ADDED — `.github/workflows/forge-ci.yml` matrix registration

- **FR-FOT-DA-100** — `forge-ci.yml::harness` job MUST gain a new
  step `t5-otel-dart-api-realign.test.sh` running with `--level 1`.
  Test : `_test_fda_100_workflow_registers_harness`.

## NFR

- **NFR-FOT-DA-001** — The realigned standard MUST cite every public
  symbol it uses to at least one of : Workiva GitHub
  `lib/api.dart` / `lib/sdk.dart` export lists, pub.dev README
  example, or Workiva src/ files. Citations land in `design.md` § ADR-T5-FOTDA-002.
- **NFR-FOT-DA-002** — Article III.4 (anti-hallucination) MUST be
  honored : no API name written into v1.1.0 without a Context7 /
  WebFetch source.
- **NFR-FOT-DA-003** — The change MUST NOT modify any file under
  `examples/forge-fsm-example/` (scope guard ; that tree is
  `t5-otel-app` territory).
- **NFR-FOT-DA-004** — The change MUST NOT introduce any new
  external dependency (no new pkg in `pubspec.yaml`, no new crate,
  no new MCP server).
- **NFR-FOT-DA-005** — L1 harness wall-clock ≤ 3 s on the CI runner
  (hermetic grep tests over a single ~400-line markdown file).
- **NFR-FOT-DA-006** — REVIEW.md edit MUST be **append-only** (no
  alteration of past entries). Verified by `verify.sh::F.4` lint.

## MODIFIED

- `.forge/standards/flutter/opentelemetry.md` — v1.0.0 → v1.1.0
  rewrite (~400 lines, ~30 % content shift in code blocks). Diff
  scope per cluster 2 + 3 + 4 + 5 + 7.
- `.forge/standards/REVIEW.md` — append one H2 entry (~25 lines).
- `.github/workflows/forge-ci.yml` — append one step line to the
  `harness:` job (~2 lines).

## REMOVED

The following identifiers (fabricated in v1.0.0 by cross-language
transposition) MUST be absent from v1.1.0 :

- `OtlpHttpSpanExporter` (replaced by `CollectorExporter(Uri)`)
- `OtlpHttpExporterConfig` (no equivalent — `CollectorExporter` takes
  a single `Uri` arg)
- `BatchSpanProcessorConfig` (replaced by named params on the
  `BatchSpanProcessor` ctor)
- `TraceIdRatioBasedSampler` (not exported by 0.18.11 ; ratio
  enforced collector-side)
- `SpanStatusCode.ok` / `SpanStatusCode.error` (replaced by
  `StatusCode.ok` / `StatusCode.error`)
- `Context.current.withSpan(span)` (replaced by the top-level
  `contextWithSpan(Context.current, span)` function)
- `setStatus(..., message: ...)` named-arg pattern (replaced by
  the positional `setStatus(StatusCode, [String description])`)
- `import 'package:opentelemetry/exporter_otlp_http.dart';` (sub-pkg
  does not exist)
- `import 'package:opentelemetry/exporter_otlp_grpc.dart';` (sub-pkg
  does not exist)
