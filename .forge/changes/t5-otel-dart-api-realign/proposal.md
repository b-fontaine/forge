# Proposal: t5-otel-dart-api-realign
<!-- Created: 2026-05-11 -->
<!-- Schema: default -->

## Problem

The standard `.forge/standards/flutter/opentelemetry.md` (v1.0.0, ratified
2026-05-04 by `t4-adr-ratification`) was authored by cross-language
transposition from JS / Java / Python OTel API conventions. It documents
identifiers that **do not exist** in the canonical pub.dev package
`opentelemetry: 0.18.11` (Workiva).

Drift surfaced during the implementation of the sibling change
`t5-otel-app` (currently `status: implemented` on branch
`t5-otel-app`, commit `8bf3865`) — see
`.forge/changes/t5-otel-app/open-questions.md::Q-004`. The L1 grep anchors
of `t5-otel-app.test.sh` are still GREEN (file presence + structural
tokens), but the L2 `flutter analyze` test fails on `undefined_identifier`
/ `uri_does_not_exist` errors for **every** API name introduced by the
standard's snippets :

| Standard v1.0.0 says | `opentelemetry 0.18.11` actually exposes |
|---|---|
| `import 'package:opentelemetry/exporter_otlp_http.dart';` | NOT shipped — pkg exports only `api.dart`, `sdk.dart`, `web_sdk.dart` |
| `OtlpHttpSpanExporter(OtlpHttpExporterConfig(...))` | `CollectorExporter(Uri)` — single positional Uri arg, no config object |
| `BatchSpanProcessor(exporter, BatchSpanProcessorConfig(...))` | `BatchSpanProcessor(exporter, {maxExportBatchSize, scheduledDelayMillis})` — named params, no config object |
| `ParentBasedSampler(TraceIdRatioBasedSampler(1.0))` | `ParentBasedSampler(AlwaysOnSampler())` — `TraceIdRatioBasedSampler` is **not exported** in 0.18.11 |
| `SpanStatusCode.ok` / `SpanStatusCode.error` | `StatusCode.ok` / `StatusCode.error` |
| `setStatus(code, message: '...')` | `setStatus(StatusCode, [String description])` — positional, not `message:` |
| `Context.current.withSpan(...)` | `contextWithSpan(Context.current, span)` — top-level function |

Without realignment :

- Every adopter who copies the standard's code blocks into a Flutter
  project gets uncompilable code.
- The `t5-otel-app` reference example's L2 lane stays xfail (Article I —
  TDD — cannot rachet to GREEN).
- The `flutter/opentelemetry.md` standard fails its own "executable
  documentation" promise (Article X.3 implied — public API docs
  matching reality).
- The Forge premium positioning ("specs are the source code of intent")
  is undermined : the spec lies about the API it pins.

The realign is a **standards-side correction**, not a re-architecture.
The Phase A collector contract (HTTP/protobuf on `:4318`,
parent-based sampler, W3C traceparent propagation, batch processor
with 5 s flush) and the application-side composition order
(setupTelemetry → Bloc.observer → error handlers → runApp) are
unchanged. Only the **API names** in the standard's code blocks shift
to match the Workiva `opentelemetry 0.18.11` pkg actually consumed by
`t5-otel-app`.

## Solution

Single Forge change `t5-otel-dart-api-realign` that ships **three atomic
deliverables** :

1. **`flutter/opentelemetry.md` standard rewrite** — bump
   `version: 1.0.0` → `1.1.0`, `last_reviewed: 2026-05-11`. Replace all
   code blocks that referenced fabricated identifiers with the real
   `opentelemetry 0.18.11` API surface verified via Context7
   (`/websites/opentelemetry_io`) and the upstream GitHub source
   (`https://github.com/Workiva/opentelemetry-dart`). API surface
   documented inline in `design.md` with one citation per symbol.
2. **`.forge/standards/REVIEW.md` ledger entry** — append-only entry
   per Article XII, recording the Q-004 realignment :
   `Updated 2026-05-11 — flutter/opentelemetry.md v1.0.0 → v1.1.0
   (Q-004 realignment per t5-otel-app open question)`.
3. **`t5-otel-dart-api-realign.test.sh` harness** — 12 L1 hermetic grep
   tests that assert (a) the standard carries the new frontmatter
   `version: 1.1.0` + `last_reviewed: 2026-05-11`, (b) every API
   name introduced by the rewrite is present, (c) every legacy
   fabricated name from v1.0.0 is absent, and (d) the REVIEW.md
   entry exists. Registered in `.github/workflows/forge-ci.yml`
   matrix.

The change is **out-of-scope for any non-standard surface** : the
`examples/forge-fsm-example/frontend/lib/core/telemetry/` source files
are NOT touched here ; flipping `t5-otel-app.test.sh`'s
`_test_ota_l2_002_flutter_analyze` from xfail to GREEN is a separate
follow-up commit on the `t5-otel-app` branch AFTER this change
merges (see Q-004 resolution path documented in `t5-otel-app`).

## Scope In

- Rewrite `.forge/standards/flutter/opentelemetry.md` v1.0.0 → v1.1.0
  to match the canonical `opentelemetry: 0.18.11` pub.dev pkg
  (maintainer Workiva, license Apache-2.0) :
  - **Setup section** : `CollectorExporter(Uri.parse(endpoint))` instead
    of `OtlpHttpSpanExporter(OtlpHttpExporterConfig(...))` ; drop the
    `exporter_otlp_http.dart` sub-import.
  - **BatchSpanProcessor section** : positional exporter + named
    `maxExportBatchSize` / `scheduledDelayMillis` instead of a
    `BatchSpanProcessorConfig` wrapper.
  - **Sampler section** : `ParentBasedSampler(AlwaysOnSampler())` as
    the v1.1.0 default — `TraceIdRatioBasedSampler` is **not exported**
    by 0.18.11, so the ratio is enforced collector-side per ADR-OTEL-001
    (Phase A `processors.probabilistic_sampler`). Documented as
    "ratio-via-collector" pattern, with explicit cross-reference to
    `observability.yaml::sampler: parentbased_traceidratio` semantics.
  - **Status code section** : `StatusCode.ok` / `StatusCode.error`
    instead of `SpanStatusCode.*` ; `setStatus(StatusCode, description)`
    positional signature instead of `setStatus(code, message: ...)`.
  - **Context propagation section** : top-level `contextWithSpan(ctx,
    span)` instead of `Context.current.withSpan(span)` ;
    `W3CTraceContextPropagator` is still the propagator (confirmed
    exported by `api.dart`).
  - **Resource section** : `Resource([Attribute.fromString(...)])`
    constructor signature confirmed (positional list of attributes).
  - **Tracer / Span sections** : `globalTracerProvider.getTracer(name)`,
    `tracer.startSpan(name, kind: SpanKind.client, attributes: [...])`
    confirmed exported by `api.dart`.
- Add frontmatter (YAML block at top of `.md`) :
  `version: 1.1.0`, `last_reviewed: 2026-05-11`,
  `pkg: opentelemetry`, `pkg_version: 0.18.11`,
  `pkg_maintainer: Workiva`,
  `pkg_source: https://pub.dev/packages/opentelemetry/versions/0.18.11`.
  This is **documentation frontmatter** (Markdown), not the YAML-spec
  frontmatter required by `standards-lifecycle.md` (which applies to
  `*.yaml` standards). The schema-validated YAML standards
  (`transport.yaml`, `observability.yaml`, etc.) keep their own
  frontmatter via `bin/validate-standards-yaml.sh` — the `.md` flutter
  standards have always been documentation, and the linter does not
  scan them. The frontmatter here is informational + greppable.
- Append entry to `.forge/standards/REVIEW.md` per Article XII
  (append-only). One H2 entry with the schema documented at the top
  of `REVIEW.md`.
- New test harness `.forge/scripts/tests/t5-otel-dart-api-realign.test.sh`
  with 12 L1 hermetic grep tests. No L2 fixture (the standard is
  pure documentation ; the L2 lane that compiles Dart code stays in
  `t5-otel-app.test.sh`).
- Register the harness in `.github/workflows/forge-ci.yml` matrix
  (one new line in `harness:` steps).
- Standard 6-file Forge artefacts : `.forge.yaml`, `proposal.md`,
  `specs.md` (`FR-FOT-DA-NNN` / `NFR-FOT-DA-NNN` namespace ; "FOT-DA"
  = "Flutter OTel — Dart API"), `design.md` (1-2 ADRs),
  `tasks.md` (10-20 tasks TDD), `open-questions.md`.

## Scope Out (Explicit Exclusions)

- **No touch to `examples/forge-fsm-example/`** — the example tree is
  `t5-otel-app` territory ; flipping its L2 from xfail to GREEN is a
  separate follow-up commit AFTER this change merges. The realigned
  standard becomes the canonical reference the example aligns to.
- **No touch to `rust/opentelemetry.md`** — the Rust OTel API was
  verified against `opentelemetry-rust 0.31` in `t5-otel-app`
  ADR-T5-OTA-001 and is internally consistent. No drift detected.
- **No touch to other Flutter standards** — `state-management.md`,
  `networking.md`, `architecture.md`, etc. are unaffected by the
  OTel API surface.
- **No touch to `.forge/standards/observability.yaml`** — its v1.1.0
  bump (t5-otel-stack) is orthogonal ; this change only edits the
  `flutter/opentelemetry.md` companion that documents the SDK-side
  shape.
- **No constitution amendment** — Article XII (governance) is honored
  via the REVIEW.md ledger entry. No bump of `constitution_version`.
- **No new agent, no new template, no new archetype** — this is a
  standards-rewrite change.
- **No introduction of a paid scanning service or external dep** —
  Context7 (already configured via `.mcp.json`) + WebFetch
  (already available) are the verification path.
- **No pre-1.0 waiver** — `opentelemetry 0.18.11` was published > 30
  days before this change's `created:` date (2026-05-11) per pub.dev
  metadata ("published 2 months ago" at lookup time 2026-05-11),
  satisfying the ADR-T5-002 #1 criterion automatically. No footnote
  needed.

## Impact

- **Users affected** : every adopter who reads
  `.forge/standards/flutter/opentelemetry.md` to bootstrap an OTel
  setup in a Flutter project. Today, they copy code that does not
  compile. After this change, the snippets match the actual pub.dev
  pkg.
- **Technical impact** : 1 standard file edited
  (`flutter/opentelemetry.md`, ~400 lines rewritten) + 1 ledger entry
  appended (`REVIEW.md`, ~15 lines added) + 1 harness added
  (`t5-otel-dart-api-realign.test.sh`, ~150 lines) + 1 workflow line
  added (`forge-ci.yml`). **Complexity : S.**
- **Dependencies** :
  - `t5-otel-app` (status `implemented`, branch `t5-otel-app`,
    commit `8bf3865`) — raised Q-004, contains the
    `_dart-pin.txt` audit anchor confirming `opentelemetry: 0.18.11`
    as the consumed pin.
  - `t4-adr-ratification` (status `archived`) — ratified the v1.0.0
    standard this change supersedes.
  - External : Context7 MCP (already wired) + WebFetch against
    `pub.dev` and `github.com/Workiva/opentelemetry-dart` (no auth).
- **Risk level** : **Low**.
  - Low : the change is documentation-only ; no runtime code touched ;
    rollback is `git revert`.
  - Medium-low caveat : if Workiva later renames symbols in `0.19.x`,
    the v1.1.0 standard drifts again. Mitigation : `pkg_version:
    0.18.11` is pinned in the frontmatter ; next adopter who upgrades
    is expected to open a follow-up Forge change. The drift is
    detectable by `flutter analyze` in `t5-otel-app.test.sh::L2`
    after the post-merge flip-xfail commit.

## Constitution Compliance

### Article I — TDD

`t5-otel-dart-api-realign.test.sh` ships with 12 L1 hermetic grep
tests written **before** the standard rewrite (RED), turning GREEN
once the rewrite lands. No production code involved (the standard
is documentation), so the cycle reduces to docs-side TDD : write
the assertion, witness RED, edit the doc, witness GREEN. The
realigned standard then unblocks the post-merge flip of
`_test_ota_l2_002_flutter_analyze` in `t5-otel-app.test.sh`.

### Article II — BDD

No user-facing behavior. The standard is internal documentation
read by adopters via `/forge:onboard`. Article II is N/A for
docs-only changes (precedent : `t4-adr-ratification`, which
ratified 6 standards without BDD scenarios).

### Article III — Specs Before Code

`specs.md` ships with `FR-FOT-DA-001..N` IDs declaring every
section of the standard that must be rewritten + the REVIEW.md
ledger entry. Implementation only after `/forge:plan` produces
`tasks.md`.

### Article III.4 — Anti-hallucination

Critical for this change. **Every** API name written into v1.1.0
is sourced from one of :
- The Workiva GitHub raw `lib/api.dart` or `lib/sdk.dart` export
  lists (citations in `design.md`).
- The pub.dev `opentelemetry/versions/0.18.11` README example
  block.
- The src files under `lib/src/api/` and `lib/src/sdk/` directly
  inspected via WebFetch.

If any section cannot be verified (e.g. a piece of the v1.0.0
standard is irrelevant to 0.18.11 and has no replacement), the
section is documented as `[NEEDS CLARIFICATION: ...]` in
`open-questions.md` rather than fabricated. The proposal explicitly
recommends Option C (defer + document drift) in that scenario
rather than fabrication.

### Article IV — Delta Specifications

`specs.md` opens with `## ADDED` (the new v1.1.0 standard text,
the REVIEW.md entry, the harness, the workflow registration) and
`## MODIFIED` (`flutter/opentelemetry.md` v1.0.0 → v1.1.0).
`## REMOVED` lists every fabricated identifier removed from the
v1.0.0 text. F.4 linter validates the delta shape.

### Article V — Constitution Gate

`/forge:design` and `/forge:review` re-run the gate. No
architectural change ; no new dependency ; no privilege escalation.
The realign honors Article IX (observability — still three signals,
still W3C traceparent, still HTTP/protobuf to `:4318`).

### Article VI — Flutter Architecture

The standard documents the `core/telemetry/` slice (cross-cutting
concerns), unchanged. Observers (TracingInterceptor,
TracingNavigationObserver, TracingBlocObserver, ErrorReporter)
unchanged. Only the SDK-call shape changes inside their
implementations.

### Article VII — Rust Architecture

N/A — Rust side untouched.

### Article VIII — Infrastructure

N/A — no infra YAML touched.

### Article IX — Security / Observability

✅ The realign preserves Article IX semantics : three signals
(traces, metrics — alpha, logs — unimplemented per Workiva's own
README), W3C traceparent propagation,
`OTEL_EXPORTER_OTLP_ENDPOINT` env-driven config. Only the SDK-call
shape moves. NFR-T5-OTA-006 (no PII in span attributes) re-stated
in v1.1.0.

### Article X — Code Quality

The standard becomes "executable documentation" : every snippet
now compiles against the pinned pkg. Article X.3 (public API doc
ratio) satisfied at the standard level by the citations table in
`design.md`.

### Article XI — Privacy / AI-First

N/A — no AI feature ; the "no PII" rule stays in v1.1.0's Rules
section.

### Article XII — Governance

The standard is **not** structural (not in the
`standards-lifecycle.md::Structural exception` table — only
`transport.yaml` and `state-management.yaml` are). The
`flutter/opentelemetry.md` document is amendable via the standard
review flow. Article XII satisfied via the REVIEW.md
append-only entry — no Constitution amendment, no version bump
of the Constitution itself.

## Open Questions

See `open-questions.md`. Pre-flagged decisions to resolve in
specs / design phase :

- **Q-001** (design) : Does `opentelemetry 0.18.11` actually expose
  a viable replacement for **every** v1.0.0 section, or are some
  sections (e.g. metrics, logs) intentionally documented as
  "alpha / unimplemented" per Workiva's own status table? If the
  latter, v1.1.0 explicitly scopes to **traces** with an explicit
  callout block per Article III.4.
- **Q-002** (specs) : Should v1.1.0 keep the `TracingInterceptor`
  full body (it's Dio-based, not OTel-pkg-dependent on the
  exporter side — only on the API side) or refactor it to match
  any new convention surfaced by the Workiva README? Default
  proposal : keep the body as-is, only adjust API name refs
  (`SpanStatusCode` → `StatusCode`, `Context.current.withSpan` →
  `contextWithSpan`).
