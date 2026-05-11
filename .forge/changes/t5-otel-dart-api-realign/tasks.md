# Tasks: t5-otel-dart-api-realign
<!-- Status: planned -->
<!-- Schema: default -->

> 14 tasks across 4 phases, all TDD-shaped (RED → GREEN). Story
> tags `[Story: FR-FOT-DA-XXX]` enforced by `f4-linter-extension`
> on commit. Tasks 1-4 create the harness (RED witness with all 12
> grep tests pointing at content not yet written). Tasks 5-12
> rewrite the standard cluster-by-cluster. Tasks 13-14 ship the
> REVIEW.md entry and the CI matrix registration. All tasks land
> in the single Phase 5 impl commit.

## Phase 1 — RED witness (harness + frontmatter scaffolding)

### T-FDA-001 — Create `t5-otel-dart-api-realign.test.sh` harness skeleton
- **Action**: Copy the structural skeleton from `.forge/scripts/tests/t5-otel.test.sh` (arg parser, helper sourcing, PASS/FAIL counters, `print_summary` call, executable bit).
- **Files**: `.forge/scripts/tests/t5-otel-dart-api-realign.test.sh` (new, ~30 lines for the skeleton).
- **Anchor**: `STD_FOT`, `REVIEW_MD`, `WORKFLOW` path variables set ; `source "$HARNESS_DIR/_helpers.sh"`.
- **TDD**: RED — running the harness with `--level 1` shows `PASS=0 FAIL=0` (no tests declared yet, but the skeleton runs cleanly).
- [Story: FR-FOT-DA-090]

### T-FDA-002 — Implement the 12 L1 grep tests
- **Action**: Write 12 `_test_fda_NNN_*` shell functions per the ADR-T5-FOTDA-002 mapping table.
- **Files**: `.forge/scripts/tests/t5-otel-dart-api-realign.test.sh` (~150 lines total).
- **Anchor**: each test grep-asserts the FR-FOT-DA-* invariant ; emits a one-line error message on FAIL.
- **TDD**: RED — running the harness now shows `PASS=0 FAIL=12` because the standard rewrite has not landed yet.
- [Story: FR-FOT-DA-001..FR-FOT-DA-100]

### T-FDA-003 — Add MANIFEST + main() runner
- **Action**: Add the `# ─── Manifest ───` block listing the 12 tests with their FR coverage. Add the `main()` function calling `run_test _test_fda_NNN_*` for each. Append `print_summary` and `exit $((FAIL > 0 ? 1 : 0))`.
- **Files**: same harness file.
- **Anchor**: 12 `run_test` lines in `main()`.
- **TDD**: RED witness — `bash .forge/scripts/tests/t5-otel-dart-api-realign.test.sh --level 1` exits non-zero with 12 ✗ lines.
- [Story: FR-FOT-DA-090..FR-FOT-DA-092]

## Phase 2 — Standard rewrite (frontmatter + body)

### T-FDA-010 — Add YAML frontmatter block at the top of `flutter/opentelemetry.md`
- **Action**: Prepend a `---`-delimited YAML block with keys `version: 1.1.0`, `last_reviewed: 2026-05-11`, `pkg: opentelemetry`, `pkg_version: 0.18.11`, `pkg_maintainer: Workiva`, `pkg_source: https://pub.dev/packages/opentelemetry/versions/0.18.11`. Add a one-line frontmatter comment explaining "Frontmatter is informational (this is an .md standard, not a .yaml standard — see standards-lifecycle.md)".
- **Files**: `.forge/standards/flutter/opentelemetry.md` (top of file).
- **Anchor**: lines 1-8 start with `---` / 6 keys / `---`.
- **TDD**: 4 of 12 tests turn GREEN (`_test_fda_001..004`).
- [Story: FR-FOT-DA-001..FR-FOT-DA-004]

### T-FDA-011 — Add Status callout block (Q-001)
- **Action**: After the frontmatter and H1 `# Flutter OpenTelemetry Standard`, add a `> **Status (per Workiva README, 2026-05-11)**:` blockquote listing `Traces: Beta`, `Metrics: Alpha`, `Logs: Unimplemented`. Add explicit "This v1.1.0 standard scopes to **traces** ; metrics + logs are out of scope until Workiva moves them to Beta."
- **Files**: same standard.
- **Anchor**: blockquote with the six tokens (`Traces:`, `Beta`, `Metrics:`, `Alpha`, `Logs:`, `Unimplemented`) + the scope-to-traces statement.
- **TDD**: 1 test turns GREEN (`_test_fda_060_workiva_status_callout`).
- [Story: FR-FOT-DA-060..FR-FOT-DA-061]

### T-FDA-020 — Rewrite the `## SDK Initialization` section (Cluster 2)
- **Action**: Replace the v1.0.0 setup snippet with the verified 0.18.11 API. Use `package:opentelemetry/api.dart` + `package:opentelemetry/sdk.dart` imports only ; `CollectorExporter(Uri.parse(config.otlpEndpoint))` exporter ; `BatchSpanProcessor(exporter, maxExportBatchSize: 512, scheduledDelayMillis: 5000)` processor ; `Resource([Attribute.fromString(ResourceAttributes.serviceName, ...), ...])` ; `TracerProviderBase(resource: resource, processors: [processor], sampler: ParentBasedSampler(AlwaysOnSampler()))` ; `registerGlobalTracerProvider(tracerProvider)` finaliser. Remove the `OtlpHttpSpanExporter`, `OtlpHttpExporterConfig`, `BatchSpanProcessorConfig`, `exporter_otlp_http.dart` / `exporter_otlp_grpc.dart` references.
- **Files**: same standard.
- **Anchor**: 6-symbol verified-API set present + the 5 fabricated identifiers absent.
- **TDD**: tests `_test_fda_011`, `_test_fda_014` turn GREEN ; partial GREEN on `_test_fda_050` (one of 6 sub-needles).
- [Story: FR-FOT-DA-010..FR-FOT-DA-015]

### T-FDA-021 — Add the new `## Sampling` H2 section (Cluster 4 — Q-003)
- **Action**: Insert a new H2 `## Sampling` block between `## SDK Initialization` and `## HTTP Instrumentation via Dio Interceptor`. Document `ParentBasedSampler(AlwaysOnSampler())` as the default. Document explicitly that `TraceIdRatioBasedSampler` is **not exported** by 0.18.11. Cross-reference `observability.yaml::sampler: parentbased_traceidratio` semantics + `t5-otel-stack` ADR-OTEL-001 (collector-side `processors.probabilistic_sampler`).
- **Files**: same standard.
- **Anchor**: `## Sampling` H2 + `ParentBasedSampler(AlwaysOnSampler())` literal + cross-ref to ADR-OTEL-001.
- **TDD**: `_test_fda_014` (already partially green from T-FDA-020) is now solidly GREEN ; partial GREEN on `_test_fda_050` (`TraceIdRatioBasedSampler` legacy-name absence).
- [Story: FR-FOT-DA-030..FR-FOT-DA-031]

### T-FDA-022 — Rewrite the `## HTTP Instrumentation via Dio Interceptor` section (Cluster 3)
- **Action**: Keep the Dio lifecycle structure ; swap API names :
  - `globalTracerProvider.getTracer('http.client')` ✅ unchanged.
  - `_tracer.startSpan(name, kind: SpanKind.client, attributes: [...])` ✅ unchanged.
  - `propagator.inject(contextWithSpan(Context.current, span), options.headers, HttpHeadersSetter())` (replaces `Context.current.withSpan(span)`).
  - `span.setStatus(StatusCode.ok)` (replaces `SpanStatusCode.ok`).
  - `span.setStatus(StatusCode.error, err.message ?? '')` (replaces named `message:`).
- **Files**: same standard.
- **Anchor**: `contextWithSpan(` and `StatusCode.ok` both present ; `Context.current.withSpan(` and `SpanStatusCode` and `message: err.message` all absent.
- **TDD**: tests `_test_fda_023`, `_test_fda_041` turn GREEN. Progress on `_test_fda_050` (multi-needle).
- [Story: FR-FOT-DA-020..FR-FOT-DA-024]

### T-FDA-023 — Realign Navigation Observer + BLoC Observer + ErrorReporter + Custom Spans + User Interaction (Cluster 8)
- **Action**: Sweep the rest of the document for `SpanStatusCode.ok` / `SpanStatusCode.error` → `StatusCode.ok` / `StatusCode.error`. Sweep for `message:` named param adjacent to `setStatus` → positional. Sweep for `Context.current.withSpan` → `contextWithSpan`. Keep all section bodies otherwise intact (lifecycle structures unchanged).
- **Files**: same standard.
- **Anchor**: zero remaining `SpanStatusCode` / `Context.current.withSpan` / `setStatus(..., message:` patterns anywhere.
- **TDD**: tests `_test_fda_040`, `_test_fda_042`, `_test_fda_050` (multi-needle) turn fully GREEN.
- [Story: FR-FOT-DA-040..FR-FOT-DA-042, FR-FOT-DA-070..FR-FOT-DA-074]

### T-FDA-024 — Update the `## Rules` section
- **Action**: Keep the 7 existing bullet rules. Add an 8th rule referencing the Workiva status callout : "**Traces only in v1.1.0**: this standard scopes to traces ; metrics (alpha) and logs (unimplemented) are out of scope until Workiva moves them to Beta — see Status callout at the top".
- **Files**: same standard.
- **Anchor**: `## Rules` H2 still present with at least 7 bullets ; "Traces only" 8th bullet added.
- **TDD**: `_test_fda_074_rules_section` GREEN.
- [Story: FR-FOT-DA-074]

## Phase 3 — REVIEW.md ledger entry

### T-FDA-030 — Append the H2 ledger entry to `.forge/standards/REVIEW.md`
- **Action**: Append the full H2 entry per ADR-T5-FOTDA-002 verbatim (Reviewer, table with v1.1.0 KEEP-WITH-CHANGES row, Decision paragraph, Notes paragraph referencing Q-004 + Context7 + WebFetch verification + the 9 removed identifiers + the 6 added identifiers).
- **Files**: `.forge/standards/REVIEW.md` (append-only — at the bottom, after the last existing entry).
- **Anchor**: H2 `## 2026-05-11 — Updated flutter/opentelemetry.md to v1.1.0 (t5-otel-dart-api-realign)` present + `Q-004` token + `1.1.0` + `KEEP-WITH-CHANGES`.
- **TDD**: `_test_fda_080_review_entry_present` GREEN.
- [Story: FR-FOT-DA-080..FR-FOT-DA-082]

## Phase 4 — CI workflow registration

### T-FDA-040 — Register the harness in `.github/workflows/forge-ci.yml`
- **Action**: Insert a new step in the `harness:` job, after `t5-otel.test.sh`, before `j8.test.sh`. One step : `name: t5-otel-dart-api-realign.test.sh` + `run: bash .forge/scripts/tests/t5-otel-dart-api-realign.test.sh --level 1`.
- **Files**: `.github/workflows/forge-ci.yml`.
- **Anchor**: the new step name appears in the workflow.
- **TDD**: `_test_fda_100_workflow_registers_harness` GREEN.
- [Story: FR-FOT-DA-100]

## Phase 5 — Verification + impl commit

### T-FDA-050 — Run the harness, witness all-GREEN
- **Action**: `bash .forge/scripts/tests/t5-otel-dart-api-realign.test.sh --level 1` ; expect `PASS=12 FAIL=0`. Capture the runtime ≤ 3 s (NFR-FOT-DA-005).
- **Files**: N/A (verification only).
- **Anchor**: `Passed: 12` + `Failed: 0` in the summary block ; exit code 0.
- **TDD**: full GREEN cycle complete.
- [Story: NFR-FOT-DA-005]

### T-FDA-051 — Run `verify.sh` + `constitution-linter.sh`, expect PASS
- **Action**: `bash .forge/scripts/verify.sh && bash .forge/scripts/constitution-linter.sh` ; expect both `RESULT: PASS` (verify) and `OVERALL: PASS` (linter). The pre-existing T.5 transport-codegen-coverage WARN is unrelated to this change and stays at 1.
- **Files**: N/A (verification only).
- **Anchor**: stdout shows `RESULT: PASS` + `OVERALL: PASS`.
- **TDD**: gate verification complete.
- [Story: NFR-FOT-DA-002, NFR-FOT-DA-006]

### T-FDA-052 — Bump `.forge.yaml::status: planned → implemented` + timeline.implemented
- **Action**: Edit `.forge/changes/t5-otel-dart-api-realign/.forge.yaml` to set `status: implemented` and add `implemented: 2026-05-11` to `timeline`.
- **Files**: `.forge/changes/t5-otel-dart-api-realign/.forge.yaml`.
- **Anchor**: status line transitions ; timeline gains the `implemented:` key.
- **TDD**: gate `verify.sh::Change YAML Schema` still PASS.
- [Story: N/A — Forge framework convention]

## Story-tag coverage matrix

| Task     | FR / NFR covered                              |
|----------|-----------------------------------------------|
| T-FDA-001 | FR-FOT-DA-090                                 |
| T-FDA-002 | FR-FOT-DA-001..FR-FOT-DA-100 (all gates)      |
| T-FDA-003 | FR-FOT-DA-090, FR-FOT-DA-091, FR-FOT-DA-092   |
| T-FDA-010 | FR-FOT-DA-001..FR-FOT-DA-004                  |
| T-FDA-011 | FR-FOT-DA-060, FR-FOT-DA-061                  |
| T-FDA-020 | FR-FOT-DA-010..FR-FOT-DA-015                  |
| T-FDA-021 | FR-FOT-DA-030, FR-FOT-DA-031                  |
| T-FDA-022 | FR-FOT-DA-020..FR-FOT-DA-024                  |
| T-FDA-023 | FR-FOT-DA-040..FR-FOT-DA-042, FR-FOT-DA-050..FR-FOT-DA-055, FR-FOT-DA-070..FR-FOT-DA-073 |
| T-FDA-024 | FR-FOT-DA-074                                 |
| T-FDA-030 | FR-FOT-DA-080..FR-FOT-DA-082                  |
| T-FDA-040 | FR-FOT-DA-100                                 |
| T-FDA-050 | NFR-FOT-DA-005                                |
| T-FDA-051 | NFR-FOT-DA-002, NFR-FOT-DA-006                |
| T-FDA-052 | Forge framework convention                    |

Every FR-FOT-DA-* and NFR-FOT-DA-* (except NFR-FOT-DA-001 — fulfilled by `design.md`'s citation table, not by an impl task ; NFR-FOT-DA-003 — fulfilled by scope discipline, not by an impl task ; NFR-FOT-DA-004 — fulfilled by no `pubspec.yaml` edit, not by an impl task) has at least one task reference.

## Out-of-scope reminders

- **NO** edit to `examples/forge-fsm-example/**`.
- **NO** edit to `t5-otel-app` branch or worktree.
- **NO** constitution amendment.
- **NO** new external dep.
- **NO** push, **NO** PR — local commits only on `t5-otel-dart-api-realign` branch.
