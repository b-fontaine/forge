# Open Questions — t5-otel-dart-api-realign

<!--
Tracking file per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`).
Q-NNN is sequential per change, zero-padded to 3 digits, never reused.
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: Does `opentelemetry 0.18.11` expose a viable replacement for every v1.0.0 section?

- **Status**: answered
- **Raised in**: proposal.md
- **Raised on**: 2026-05-11
- **Raised by**: @bfontaine

### Question

The v1.0.0 standard documents 11 sections : SDK Initialization, HTTP
Instrumentation via Dio Interceptor, Navigation Observer, BLoC Observer,
User Interaction Spans, Error Instrumentation, Custom Spans, Context
Propagation (W3C traceparent), and Rules.

Workiva's own README declares the package status :

> Traces : Beta
> Metrics : Alpha
> Logs : Unimplemented

For the realign to be coherent at v1.1.0 :

- **Traces** : every snippet rewritten against the actual API.
- **Metrics** : if mentioned in v1.0.0, must be flagged as Alpha and
  not commit to a public adopter promise.
- **Logs** : if mentioned in v1.0.0, must be flagged as Unimplemented
  and either removed or documented as "Forge does NOT yet provide a
  Workiva-backed log SDK ; use the Rust side via OTLP HTTP for now".

Decide at `/forge:design` whether v1.1.0 explicitly scopes to traces
(with a callout box) or attempts to document metrics-alpha.

### Resolution

**Resolved by ADR-T5-FOTDA-001** (`design.md`). Path A — scope v1.1.0
explicitly to **traces**. v1.1.0 carries a Status callout at the top
(`Traces: Beta`, `Metrics: Alpha`, `Logs: Unimplemented`) per the
Workiva README 2026-05-11. Metrics + logs are out of scope for this
revision and will be documented when Workiva moves them to Beta.

---

## Q-002: Does the `TracingInterceptor` body need any restructuring beyond API name swaps?

- **Status**: answered
- **Raised in**: proposal.md
- **Raised on**: 2026-05-11
- **Raised by**: @bfontaine

### Question

The v1.0.0 `TracingInterceptor` (lines 60-132 of
`flutter/opentelemetry.md`) is Dio-based and references three
OTel-pkg identifiers that need realignment :

| Line | v1.0.0 reference | v1.1.0 fix |
|---|---|---|
| 80   | `W3CTraceContextPropagator()` | KEEP — confirmed exported by `api.dart` |
| 81-86 | `propagator.inject(Context.current.withSpan(span), options.headers, HttpHeadersSetter())` | rewrite `Context.current.withSpan(span)` → `contextWithSpan(Context.current, span)` |
| 99   | `setStatus(SpanStatusCode.ok)` | rewrite `SpanStatusCode.ok` → `StatusCode.ok` |
| 113  | `setStatus(SpanStatusCode.error, message: err.message)` | rewrite `setStatus(StatusCode.error, err.message ?? '')` — positional |

No structural change. The Dio interceptor pattern (`onRequest` / `onResponse` /
`onError` lifecycle) is unchanged.

Decide at `/forge:specify` whether to keep the body intact (preferred —
minimum-change realign) or refactor it as a separate concern. Default :
keep intact, only swap API names.

### Resolution

**Resolved by ADR-T5-FOTDA-001** (`design.md`). Minimum-change realign
— the Dio interceptor body keeps its `onRequest / onResponse / onError`
lifecycle. Only API-name swaps land : `SpanStatusCode` → `StatusCode`,
`Context.current.withSpan` → `contextWithSpan`, `setStatus(..., message:)`
→ positional `setStatus(...)`.

---

## Q-003: How are sampler ratio semantics preserved without `TraceIdRatioBasedSampler`?

- **Status**: answered
- **Raised in**: proposal.md
- **Raised on**: 2026-05-11
- **Raised by**: @bfontaine

### Question

The Workiva `opentelemetry 0.18.11` `lib/sdk.dart` exports exactly :
- `AlwaysOnSampler`
- `AlwaysOffSampler`
- `ParentBasedSampler`
- `Sampler` (the interface)

`TraceIdRatioBasedSampler` is **not exported**. The v1.0.0 standard
indirectly implied a ratio capability through the `ParentBased(TraceIdRatioBased(1.0))`
pattern matching `observability.yaml::sampler: parentbased_traceidratio`.

Two paths for v1.1.0 :

- **Path A (default)** : `ParentBasedSampler(AlwaysOnSampler())` SDK-side,
  with the env-tier ratio enforced collector-side per
  `t5-otel-stack` ADR-OTEL-001 (`processors.probabilistic_sampler`).
  This matches the actual `t5-otel-app` implementation (`sample_rate: 1.0`
  default) and the dual-stage Phase A + Phase B model. Document
  explicitly : "the `parentbased_traceidratio` semantics from
  `observability.yaml` are realised by AlwaysOnSampler SDK + probabilistic_sampler
  collector, due to the 0.18.11 pkg not exporting a TraceIdRatio sampler".
- **Path B** : Implement a custom `Sampler` subclass in the example
  tree that mirrors TraceIdRatioBased semantics. **Out of scope** for
  this realign (would belong to a `t5-otel-app` follow-up).

### Resolution

**Resolved by ADR-T5-FOTDA-001** (`design.md`). Path A — SDK-side ships
`ParentBasedSampler(AlwaysOnSampler())` and the env-tier ratio is
enforced collector-side via `processors.probabilistic_sampler` per
`t5-otel-stack` ADR-OTEL-001 (dual-stage Phase A + Phase B model).
v1.1.0 documents this explicitly in a new H2 `## Sampling` section
(FR-FOT-DA-030 / 031). A future `opentelemetry 0.19.x` shipping a
`TraceIdRatioBasedSampler` would be the trigger for a v1.2.0 bump.
