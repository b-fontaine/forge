---
version: 2.0.0
last_reviewed: 2026-05-18
breaking_change: true
pkg_name_api: dartastic_opentelemetry_api
pkg_version_api: ^1.0.0-beta.2
pkg_name_sdk: dartastic_opentelemetry
pkg_version_sdk: ^1.1.0-beta.6
pkg_name_flutter: flutterrific_opentelemetry
pkg_version_flutter: ^0.4.0
pkg_maintainer: mindfulsoftware.com (verified-publisher on pub.dev)
pkg_source: https://pub.dev/packages/dartastic_opentelemetry
forbidden:
  - "opentelemetry: ^0.18"
  - "opentelemetry_sdk"
rationale: >-
  Flutter OpenTelemetry observability via the Dartastic ecosystem
  (mindfulsoftware.com) which is OTel-spec-1.31.0-aligned and
  declares support for all 6 Flutter platforms (Android, iOS, Linux,
  macOS, Web, Windows). Replaces Workiva opentelemetry 0.18.11 which
  was web-only (resolved Q-006 / cli-trust-harness Option B
  validation 2026-05-16).
  WAIVER (T5.3, 2026-05-18) : dartastic_opentelemetry_api transitively
  pins at ^1.0.0-beta.2 (the constraint declared by SDK 1.1.0-beta.6). At
  ratification time the latest published prerelease on pub.dev was
  1.0.0-beta.7 ; pub solver resolves to that automatically given the
  caret constraint. The stable 0.9.0 line is incompatible with SDK
  1.1.0-beta.6. Upgrade trigger : when dartastic_opentelemetry_api 1.0.0 GA
  ships, file a follow-up patch change (target naming :
  t5-3-1-dartastic-api-ga-refresh).
  3-axis checklist re-verification cadence (T5.2 §
  "Platform compatibility re-verification") catches any post-GA
  drift independently. Pattern verbatim from transport.yaml v1.2.0
  WAIVER (t5-cargo-pin-refresh).
---

<!-- Audit: T.5.3 (t5-otel-dartastic-realign) ; supersedes Workiva pin from t5-otel-dart-api-realign -->

<!--
History :
- v1.0.0 (2026-05-04, t4-adr-ratification) — fabricated API names
  from cross-language transposition (JS / Java / Python OTel).
- v1.1.0 (2026-05-11, t5-otel-dart-api-realign) — realigned to the
  actual `opentelemetry: 0.18.11` (Workiva) pub.dev pkg API surface,
  resolving Q-004.
- v2.0.0 (2026-05-18, t5-otel-dartastic-realign) — BREAKING.
  Substitution Workiva → Dartastic ecosystem. Resolves Q-006
  (Workiva web-only platform mismatch). FIRST consumer of the T5.2
  3-axis platform-verification checklist — applied inline in the
  "Source Documents — 3-axis verification" H2 below.
-->

# Flutter OpenTelemetry Standard

> **Status (per Dartastic README, 2026-05-18)** :
>
> | Signal  | Status                                       |
> |---------|----------------------------------------------|
> | Traces  | Spec-aligned (OTel spec 1.31.0)              |
> | Metrics | Spec-aligned                                 |
> | Logs    | Spec-aligned (LogRecord + LogRecordProcessor)|
>
> v2.0.0 scopes to traces in the reference FSM example and mobile-only
> template ; metrics + logs API are documented for adopters who
> want to wire them. All 3 signals are implementable on every
> Flutter target platform Dartastic declares.

## Source Documents — 3-axis verification

> **First consumer of the T5.2 3-axis platform-verification checklist**
> (`.claude/agents/document-specialist.md` §
> `Platform Verification Checklist (3-axis)`). Verified 2026-05-18
> via Context7 + pub.dev WebFetch.

| Dependency | Existence | API surface | Platform compatibility | Notes |
|---|---|---|---|---|
| `dartastic_opentelemetry_api @ ^1.0.0-beta.2` | [x] pub.dev verified-publisher mindfulsoftware.com | [x] OTelAPI / Tracer / Span / Context / Baggage / Attributes / Status / SpanKind / SpanProcessor / SpanExporter / W3CTraceContextPropagator / W3CBaggagePropagator | [x] Android, iOS, Linux, macOS, Web, Windows declared | beta line accepted per WAIVER (frontmatter rationale) |
| `dartastic_opentelemetry @ ^1.1.0-beta.6` | [x] pub.dev verified-publisher | [x] OTel.initialize / OtlpGrpcSpanExporter / OtlpHttpSpanExporter / Tracer / Span / AlwaysOnSampler / AlwaysOffSampler / ParentBasedSampler / TraceIdRatioBasedSampler / Meter / Counter / Histogram / OTelLogger / LogRecord | [x] All Dart/Flutter targets | OTel spec 1.31.0 ; published 9 days ago |
| `flutterrific_opentelemetry @ ^0.4.0` | [x] pub.dev verified-publisher | [x] OTel-init helper / route observer / lifecycle / error+navigation auto-instrumentation / go_router integration | [x] Android+iOS "Full" ; Web "Complete OTLP/HTTP" ; desktop "Beta" | desktop Beta not blocking — no current archetype targets desktop |

No `[PLATFORM MISMATCH:]` markers raised. The substitution satisfies
all 3 axes for `mobile-only` (Android+iOS), `full-stack-monorepo`
frontend (Flutter mobile + web), and any future archetype with
matching target sets.

## Technology Stack

Three Dartastic packages used together :

| Package | Role | Forge-pinned version |
|---|---|---|
| `dartastic_opentelemetry_api` | No-op OpenTelemetry API surface | `^1.0.0-beta.2` (transitive via SDK) |
| `dartastic_opentelemetry` | Dart SDK backend (exporters / processors / samplers) | `^1.1.0-beta.6` |
| `flutterrific_opentelemetry` | Flutter integration shim (auto-instrumentation, go_router observer, lifecycle, errors) | `^0.4.0` |

**Publisher** : `mindfulsoftware.com` (verified-publisher on pub.dev).

**Spec alignment** : OpenTelemetry Specification 1.31.0 (Traces /
Metrics / Logs).

**Collector contract** : OTLP HTTP/protobuf on port `:4318` per
**ADR-OTEL-001** (`t5-otel-stack`, 2026-05-10). The collector
contract is unchanged by v2.0.0 — only the SDK pkg substitution
moves.

### Canonical imports

```dart
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';
```

## SDK Initialization

The canonical init uses **flutterrific_opentelemetry** (Option A
per ADR-T53-001). Call `OTel.initialize(...)` before `runApp` and
register the route observer in `MaterialApp.router` :

```dart
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';

Future<void> setupTelemetry() async {
  await OTel.initialize(
    serviceName: 'forge-fsm-frontend',
    endpoint: const String.fromEnvironment(
      'OTEL_EXPORTER_OTLP_ENDPOINT',
      defaultValue: 'http://localhost:4318',
    ),
    sampler: ParentBasedSampler(AlwaysOnSampler()),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupTelemetry();
  runApp(MyApp());
}
```

Then in the app's router setup :

```dart
MaterialApp.router(
  routerConfig: GoRouter(
    routes: [...],
    observers: [FlutterOTel.routeObserver],
  ),
);
```

### Migration off flutterrific (Option B fallback)

Adopters who do NOT want the `flutterrific_opentelemetry` shim drop
it from `pubspec.yaml` and wire the same behaviour manually against
`dartastic_opentelemetry` :

- Implement a custom `NavigatorObserver` subclass that calls
  `tracer.startSpan('navigation.<route>')` on `didPush` / `didPop`.
- Implement a custom `BlocObserver` subclass for state-management
  instrumentation.
- Wire `FlutterError.onError` + `runZonedGuarded` to your error
  reporter.

Adds approximately 50-80 LOC vs the flutterrific path. Documented
as a fallback in case `flutterrific 0.4.0` blocks the build ; not
the Forge default recommendation.

## Sampling

Forge's sampling model is **dual-stage** per ADR-OTEL-001
(unchanged by the substitution) :

- **Phase A — collector-side** : the OTel Collector applies
  `processors.probabilistic_sampler` with env-tier overlays. This
  is where adopter-tunable sampling lives. The SDK does NOT decide
  the sampling rate.
- **Phase B — SDK-side** : `ParentBasedSampler(AlwaysOnSampler())`.
  Every span produced by the app is always emitted ; Phase A
  decides post-hoc. Preserves trace continuity across processes
  while keeping the SDK simple.

Dartastic exposes the canonical OTel sampler types :

- `AlwaysOnSampler()` — recommended for the SDK (Phase B).
- `AlwaysOffSampler()` — useful for tests.
- `ParentBasedSampler(<delegate>)` — wraps a delegate with parent-respecting decisions.
- `TraceIdRatioBasedSampler(ratio)` — head-based ratio sampler.
  Available but **discouraged for SDK use** ; if used, remove Phase A's
  collector-side sampling to avoid double sampling.

```dart
await OTel.initialize(
  serviceName: '<service>',
  endpoint: '<otlp-http-url>',
  sampler: ParentBasedSampler(AlwaysOnSampler()),
);
```

## HTTP Instrumentation via Dio Interceptor

Pattern : one span per outbound HTTP request ; inject `traceparent`
(and `tracestate`) on every outbound. Continuation across processes
is what makes the distributed trace work.

```dart
import 'package:dio/dio.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

class TracingInterceptor extends Interceptor {
  final Tracer tracer;
  TracingInterceptor(this.tracer);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final span = tracer.startSpan(
      'http.${options.method.toUpperCase()} ${options.uri.path}',
      kind: SpanKind.client,
    )
      ..setAttribute('http.method', options.method)
      ..setAttribute('http.url', options.uri.toString())
      ..setAttribute('net.peer.name', options.uri.host);

    final ctx = Context.current.withSpan(span);
    final propagator = W3CTraceContextPropagator();
    final headers = <String, String>{};
    propagator.inject(ctx, headers, (carrier, key, value) {
      carrier[key] = value;
    });
    options.headers.addAll(headers);
    options.extra['otel.span'] = span;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final span = response.requestOptions.extra['otel.span'] as Span?;
    span
      ?..setAttribute('http.status_code', response.statusCode ?? 0)
      ..setStatus(SpanStatusCode.Ok)
      ..end();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final span = err.requestOptions.extra['otel.span'] as Span?;
    span
      ?..setAttribute('http.status_code', err.response?.statusCode ?? 0)
      ..setStatus(SpanStatusCode.Error, err.message ?? 'http_error')
      ..recordException(err)
      ..end();
    handler.next(err);
  }
}
```

## Navigation Observer

**Default (flutterrific)** : register the built-in observer in
go_router :

```dart
GoRouter(
  routes: [...],
  observers: [FlutterOTel.routeObserver],
);
```

Captures `didPush` / `didPop` / `didReplace` as spans with route
attributes, no glue code in adopter projects.

**Manual fallback (Navigator 1.0 or non-flutterrific adopters)** :

```dart
class TracingNavigationObserver extends NavigatorObserver {
  final Tracer tracer;
  TracingNavigationObserver(this.tracer);

  @override
  void didPush(Route route, Route? previousRoute) {
    tracer.startSpan('navigation.push')
      ..setAttribute('route.name', route.settings.name ?? '<anon>')
      ..end();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    tracer.startSpan('navigation.pop')
      ..setAttribute('route.name', route.settings.name ?? '<anon>')
      ..end();
  }
}
```

## BLoC Observer

Pattern : extend `BlocObserver` (`flutter_bloc`) and create spans on
`onEvent` / `onTransition` / `onError`.

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

class TracingBlocObserver extends BlocObserver {
  final Tracer tracer;
  TracingBlocObserver(this.tracer);

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    tracer.startSpan('bloc.event.${event.runtimeType}')
      ..setAttribute('bloc.name', bloc.runtimeType.toString())
      ..end();
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    tracer.startSpan('bloc.transition')
      ..setAttribute('bloc.name', bloc.runtimeType.toString())
      ..setAttribute('bloc.state', transition.nextState.runtimeType.toString())
      ..end();
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    tracer.startSpan('bloc.error')
      ..setAttribute('bloc.name', bloc.runtimeType.toString())
      ..setStatus(SpanStatusCode.Error, error.toString())
      ..recordException(error, stackTrace: stackTrace)
      ..end();
  }
}

void main() {
  Bloc.observer = TracingBlocObserver(OTel.tracer());
  runApp(MyApp());
}
```

## User Interaction Spans

Manual span creation around user-triggered domain operations (tap,
scroll, form-submit). Use semantic attribute namespaces (`app.*`,
`user.*`, `domain.*`).

```dart
final span = OTel.tracer().startSpan('user.tap.checkout-button');
span
  ..setAttribute('app.screen', '/cart')
  ..setAttribute('user.id', currentUser.id);
try {
  await processCheckout();
  span.setStatus(SpanStatusCode.Ok);
} catch (e, st) {
  span
    ..setStatus(SpanStatusCode.Error, e.toString())
    ..recordException(e, stackTrace: st);
  rethrow;
} finally {
  span.end();
}
```

## Error Instrumentation

Wire `FlutterError.onError` + `runZonedGuarded` so every uncaught
error becomes a span on the active context.

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runZonedGuarded(() async {
    await setupTelemetry();
    FlutterError.onError = (details) {
      final span = OTel.tracer().startSpan('error.flutter');
      span
        ..setStatus(SpanStatusCode.Error, details.exceptionAsString())
        ..recordException(details.exception, stackTrace: details.stack)
        ..end();
    };
    runApp(MyApp());
  }, (error, stack) {
    final span = OTel.tracer().startSpan('error.zone');
    span
      ..setStatus(SpanStatusCode.Error, error.toString())
      ..recordException(error, stackTrace: stack)
      ..end();
  });
}
```

## Custom Spans

`tracer.startSpan('<namespace>.<operation>')` with semantic
attributes. Namespace conventions :

- `domain.*` — business logic operations (e.g. `domain.order.create`).
- `app.*` — application-level operations (e.g. `app.cache.invalidate`).
- `user.*` — user-initiated operations (e.g. `user.tap.checkout`).
- `http.*`, `db.*`, `messaging.*` — follow upstream OTel semantic
  conventions verbatim.

```dart
final span = OTel.tracer().startSpan('domain.order.create');
span.setAttribute('order.items.count', order.items.length);
try {
  final result = await orderRepository.create(order);
  span.setAttribute('order.id', result.id);
  span.setStatus(SpanStatusCode.Ok);
  return result;
} catch (e, st) {
  span
    ..setStatus(SpanStatusCode.Error, e.toString())
    ..recordException(e, stackTrace: st);
  rethrow;
} finally {
  span.end();
}
```

## Context Propagation (W3C traceparent)

Use `W3CTraceContextPropagator` to inject/extract the `traceparent`
header. Required for FSM `demo-005` traceparent round-trip and any
cross-service trace.

**Outbound (injection)** :

```dart
final propagator = W3CTraceContextPropagator();
final headers = <String, String>{};
propagator.inject(Context.current, headers, (carrier, key, value) {
  carrier[key] = value;
});
// headers now contains 'traceparent' (and optionally 'tracestate').
```

**Inbound (extraction)** — for Dart isolates / WebSocket streams /
any inbound HTTP context :

```dart
final propagator = W3CTraceContextPropagator();
final ctx = propagator.extract(
  Context.current,
  request.headers,
  (carrier, key) => carrier[key],
);
final span = OTel.tracer().startSpan('inbound', context: ctx);
```

The W3C `traceparent` header format is
`00-<32 hex trace-id>-<16 hex span-id>-<2 hex flags>`. Validation
is done by the propagator.

## Migration from v1.1.0 (Workiva → Dartastic)

This is a **breaking bump** (`breaking_change: true`). Adopters
using v1.1.0 MUST migrate pubspec + import paths + a handful of
symbol names.

### pubspec.yaml diff

```yaml
# REMOVE
dependencies:
  opentelemetry: ^0.18.11  # Workiva

# ADD
dependencies:
  dartastic_opentelemetry: ^1.1.0-beta.6
  flutterrific_opentelemetry: ^0.4.0
```

### Symbol substitution

| v1.1.0 (Workiva) | v2.0.0 (Dartastic) | Notes |
|---|---|---|
| `package:opentelemetry/api.dart` | `package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart` | API surface only ; no-op implementation |
| `package:opentelemetry/sdk.dart` | `package:dartastic_opentelemetry/dartastic_opentelemetry.dart` | Dart SDK backend |
| (none in Workiva) | `package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart` | Flutter integration shim (new in v2.0.0) |
| `CollectorExporter(Uri)` | `OtlpHttpSpanExporter()` (or use `OTel.initialize(endpoint: ...)`) | Dartastic's high-level init wraps exporter creation |
| `BatchSpanProcessor(exporter, {...})` | `BatchSpanProcessor` (Dartastic, same name) | API matches OTel spec |
| `ParentBasedSampler(AlwaysOnSampler())` | `ParentBasedSampler(AlwaysOnSampler())` | Identical |
| `SpanStatusCode.Ok` / `SpanStatusCode.Error` | `SpanStatusCode.Ok` / `SpanStatusCode.Error` | Identical |
| `setStatus(SpanStatusCode.Error, description)` | `setStatus(SpanStatusCode.Error, description)` | Identical |
| `contextWithSpan(Context, Span)` | `Context.current.withSpan(span)` (instance method) | Dartastic uses method instead of free function |
| `TraceIdRatioBasedSampler` — **ABSENT in Workiva 0.18.11** | `TraceIdRatioBasedSampler(ratio)` | Now available |
| `package:opentelemetry/exporter_otlp_http.dart` | Top-level SDK import | No sub-path import in Dartastic |
| `package:opentelemetry/exporter_otlp_grpc.dart` | Top-level SDK import | No sub-path import in Dartastic |

### Configuration env var

Both v1.1.0 and v2.0.0 read `OTEL_EXPORTER_OTLP_ENDPOINT` for the
collector URL. No env var change.

## Anti-patterns

Drawn from the historical Q-004 + Q-006 incidents :

- **DON'T** ratify a Flutter OTel package without ticking the
  T5.2 3-axis checklist (existence + API surface + platform
  compatibility). Skipping platform compatibility caused Q-006.
- **DON'T** cross-language transpose API names from JS / Java /
  Python OTel into Dart. Workiva v1.0.0 fabricated 9 symbols this
  way and shipped them as "verified" (Q-004). Always verify each
  symbol against the actual pub.dev API page or Context7-fetched
  docs.
- **DON'T** pin `opentelemetry: ^0.18` (Workiva) — it is web-only.
- **DON'T** reference `opentelemetry_sdk` — that package never
  existed on pub.dev (phantom typo from b4-mobile-only era).
- **DON'T** skip the WAIVER documentation when a pkg pin lands on
  a `-beta.N` / `-alpha.N` line. Beta acceptance MUST be
  transparent + carry a named upgrade trigger.

## Rules

- **MUST** initialise OTel via `OTel.initialize(...)` before `runApp`.
- **MUST** set `serviceName` to a stable, deployment-scoped value
  (e.g. `forge-fsm-frontend`).
- **MUST** register the route observer (flutterrific
  `FlutterOTel.routeObserver` or a custom
  `NavigatorObserver`).
- **MUST** use Phase A + Phase B dual-stage sampling per
  ADR-OTEL-001 (`ParentBasedSampler(AlwaysOnSampler())` on the
  SDK side, collector-side probabilistic sampler in deployment).
- **MUST** propagate W3C `traceparent` on all outbound HTTP calls
  via `W3CTraceContextPropagator`.
- **MUST NOT** introduce Workiva `opentelemetry: ^0.18` (forbidden
  in frontmatter — web-only).
- **MUST NOT** introduce the phantom `opentelemetry_sdk` (never
  existed on pub.dev).
- **MUST NOT** ratify any new external Flutter OTel dependency
  without applying the T5.2 3-axis checklist.

## Constitutional basis

Anchored on **Article III.4** (Ambiguity Protocol — anti-hallucination)
and **Article IX** (Observability). The v2.0.0 bump is the inaugural
application of the T5.2 procedural reinforcement of Article III.4 —
every symbol cited was verified against the actual pub.dev API
surface (not cross-language transposed), and every platform claim
was verified against the package's declared support matrix on
pub.dev (Q-006 prevention).

## References

- Dartastic packages :
  - https://pub.dev/packages/dartastic_opentelemetry_api
  - https://pub.dev/packages/dartastic_opentelemetry
  - https://pub.dev/packages/flutterrific_opentelemetry
- OpenTelemetry Specification 1.31.0 :
  https://github.com/open-telemetry/opentelemetry-specification/tree/v1.31.0
- ADR-OTEL-001 (collector sampling contract) :
  `.forge/changes/t5-otel-stack/design.md`
- T5.2 3-axis checklist :
  `.claude/agents/document-specialist.md` §
  `Platform Verification Checklist (3-axis)`
- T5.2 re-verification cadence :
  `.forge/standards/global/standards-lifecycle.md` §
  `Platform compatibility re-verification`
- Q-004 (Workiva fabricated symbols, resolved 2026-05-12) :
  `.forge/changes/t5-otel-dart-api-realign/`
- Q-006 (Workiva web-only platform mismatch, this change) :
  `.forge/changes/t5-otel-dartastic-realign/proposal.md`
