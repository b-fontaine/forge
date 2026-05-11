---
version: 1.1.0
last_reviewed: 2026-05-11
pkg: opentelemetry
pkg_version: 0.18.11
pkg_maintainer: Workiva
pkg_source: https://pub.dev/packages/opentelemetry/versions/0.18.11
---

<!--
Frontmatter is informational for this .md standard. The YAML-spec
frontmatter contract enforced by `bin/validate-standards-yaml.sh`
(`standards-lifecycle.md` § Automated enforcement) applies only to
`.forge/standards/*.yaml` standards. This `.md` documentation
standard mirrors the field names for greppability and adopter
clarity — the validator does NOT scan it.

History :
- v1.0.0 (2026-05-04, t4-adr-ratification) — fabricated API names
  from cross-language transposition (JS / Java / Python OTel).
- v1.1.0 (2026-05-11, t5-otel-dart-api-realign) — realigned to the
  actual `opentelemetry: 0.18.11` (Workiva) pub.dev pkg API surface,
  resolving Q-004 raised in `t5-otel-app/open-questions.md`.
-->

# Flutter OpenTelemetry Standard

> **Status (per Workiva README, 2026-05-11)** :
>
> | Signal  | Status        |
> |---------|---------------|
> | Traces  | Beta          |
> | Metrics | Alpha         |
> | Logs    | Unimplemented |
>
> **This v1.1.0 standard scopes to traces only.** Metrics (alpha)
> and logs (unimplemented) are out of scope until Workiva moves them
> to Beta. Cross-language adopters expecting a full three-signal SDK
> on Flutter today should run metrics + logs through the Rust
> backend (which uses `opentelemetry-rust 0.31` per
> `rust/opentelemetry.md`) and rely on browser / mobile traces here.

## Technology Stack

| Package | Role |
|---|---|
| `opentelemetry: 0.18.11` (Workiva, Apache-2.0) | Core OTel SDK for Dart/Flutter — traces |
| `dio` (`^5.7.0`) | HTTP client with interceptor for trace propagation |
| `flutter_bloc` | BLoC pattern + `BlocObserver` hook for event/state tracing |

The canonical pub.dev pkg is **`opentelemetry`** (single bundled
package : api + sdk + web_sdk sub-libraries). Workiva is the verified
publisher. The `lib/api.dart` and `lib/sdk.dart` sub-libraries are
the only entry points adopters import. The OTLP wire format is
reached via the `CollectorExporter` class (exported by `sdk.dart`)
which accepts a single `Uri` pointing at an OTLP-compliant endpoint.
The legacy sub-libraries that the v1.0.0 standard incorrectly
imported (paths starting with `exporter_otlp_*`) do not exist in
this pkg layout — see REVIEW.md 2026-05-11 entry for the full list
of legacy identifiers that were removed.

---

## SDK Initialization

```dart
// lib/core/telemetry/telemetry_setup.dart
import 'dart:io' show Platform;

import 'package:opentelemetry/api.dart'
    show
        Attribute,
        ResourceAttributes,
        registerGlobalTracerProvider;
import 'package:opentelemetry/sdk.dart'
    show
        AlwaysOnSampler,
        BatchSpanProcessor,
        CollectorExporter,
        ParentBasedSampler,
        Resource,
        TracerProviderBase;

Future<void> setupTelemetry({required AppConfig config}) async {
  // 1. OTLP HTTP exporter — single positional Uri argument. The
  //    Workiva CollectorExporter speaks the OTLP wire format ; per
  //    ADR-T5-OTA-002 the Forge stack pins HTTP/protobuf on :4318.
  final exporter = CollectorExporter(Uri.parse('${config.otlpEndpoint}/v1/traces'));

  // 2. Batch processor — positional exporter, named tuning params.
  //    No wrapping config object in 0.18.11 (the v1.0.0 standard
  //    incorrectly assumed one ; see REVIEW.md 2026-05-11 entry).
  final processor = BatchSpanProcessor(
    exporter,
    maxExportBatchSize: 512,
    scheduledDelayMillis: 5000, // 5 s flush interval
  );

  // 3. Resource — positional list of Attribute objects. Use the
  //    semantic-convention constants from `api.dart`.
  final resource = Resource([
    Attribute.fromString(ResourceAttributes.serviceName, config.serviceName),
    Attribute.fromString(ResourceAttributes.serviceVersion, config.appVersion),
    Attribute.fromString(ResourceAttributes.deploymentEnvironment, config.environment),
    Attribute.fromString('device.platform', Platform.operatingSystem),
    Attribute.fromString('device.os.version', Platform.operatingSystemVersion),
  ]);

  // 4. TracerProvider — sampler is `ParentBasedSampler(AlwaysOnSampler())`
  //    in 0.18.11. See the `## Sampling` section below for the ratio
  //    semantics realised collector-side.
  final tracerProvider = TracerProviderBase(
    resource: resource,
    processors: [processor],
    sampler: ParentBasedSampler(AlwaysOnSampler()),
  );

  registerGlobalTracerProvider(tracerProvider);
}
```

---

## Sampling

The Workiva `opentelemetry: 0.18.11` pkg exports the following
samplers (from `lib/sdk.dart`) :

| Class | Behaviour |
|---|---|
| `AlwaysOnSampler` | Sample every span. |
| `AlwaysOffSampler` | Drop every span. |
| `ParentBasedSampler(_root, {remote*Sampled, local*Sampled, ...})` | Respect the W3C `traceparent` `flags` bit ; delegate to `_root` for sampling-decisions on root spans. |
| `Sampler` (interface) | Adopters can implement custom samplers. |

A `TraceIdRatio`-based sampler class is **not exported** by 0.18.11
(the v1.0.0 standard incorrectly assumed one ; see REVIEW.md
2026-05-11 entry). The Forge
stack realises the `observability.yaml::sampler: parentbased_traceidratio`
semantics via the **dual-stage Phase A + Phase B model** documented
in `t5-otel-stack` ADR-OTEL-001 :

- **SDK-side (this standard)** : `ParentBasedSampler(AlwaysOnSampler())`.
  Every span starts. Inherited sampled-already decisions (W3C
  `traceparent` `flags = 01`) are respected through the parent-based
  wrapper.
- **Collector-side** : the OTel collector's
  `processors.probabilistic_sampler` enforces the env-tier ratio
  (10 % prod / 50 % staging / 100 % dev). Spans dropped here never
  reach SigNoz / Coroot.

This split is intentional : adopters can flip dev/staging tools to
"see every span" without rebuilding the Flutter app. A future
`opentelemetry: 0.19.x` shipping a ratio-based sampler class would
be the trigger for a v1.2.0 bump of this standard.

---

## HTTP Instrumentation via Dio Interceptor

```dart
// lib/core/telemetry/interceptors/tracing_interceptor.dart
import 'package:dio/dio.dart';
import 'package:opentelemetry/api.dart'
    show
        Attribute,
        Context,
        Span,
        SpanKind,
        StatusCode,
        TextMapSetter,
        Tracer,
        W3CTraceContextPropagator,
        contextWithSpan,
        globalTracerProvider;

class TracingInterceptor extends Interceptor {
  TracingInterceptor() : _tracer = globalTracerProvider.getTracer('http.client');

  final Tracer _tracer;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final span = _tracer.startSpan(
      '${options.method} ${_sanitizePath(options.path)}',
      kind: SpanKind.client,
      attributes: [
        Attribute.fromString('http.method', options.method),
        Attribute.fromString('http.url', options.uri.toString()),
        Attribute.fromString('http.target', options.path),
        Attribute.fromString('net.peer.name', options.uri.host),
      ],
    );

    // Inject W3C traceparent header for context propagation.
    // `contextWithSpan` is a top-level helper from `api.dart`. The
    // JS/Java-style `withSpan` method on Context does not exist in
    // opentelemetry 0.18.11 — see REVIEW.md 2026-05-11 entry for
    // the full list of legacy identifiers that were removed.
    final propagator = W3CTraceContextPropagator();
    propagator.inject(
      contextWithSpan(Context.current, span),
      options.headers,
      _HttpHeadersSetter(),
    );

    // Store span reference on request for later completion.
    options.extra['otel_span'] = span;

    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final span = response.requestOptions.extra['otel_span'] as Span?;
    span
      ?..setAttribute(Attribute.fromInt('http.status_code', response.statusCode ?? 0))
      ..setStatus(StatusCode.ok)
      ..end();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final span = err.requestOptions.extra['otel_span'] as Span?;
    span
      ?..setAttribute(Attribute.fromInt('http.status_code', err.response?.statusCode ?? 0))
      ..recordException(err, attributes: [
        Attribute.fromString('exception.type', err.type.name),
        Attribute.fromString('exception.message', err.message ?? ''),
      ])
      // setStatus signature in 0.18.11 : `void setStatus(StatusCode, [String description])`
      // — second argument is POSITIONAL, not `message:` named.
      ..setStatus(StatusCode.error, err.message ?? '')
      ..end();
    handler.next(err);
  }

  String _sanitizePath(String path) {
    // Replace UUIDs and numeric IDs to keep span-name cardinality bounded.
    return path
        .replaceAll(RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'), '{id}')
        .replaceAll(RegExp(r'/\d+'), '/{id}');
  }
}

class _HttpHeadersSetter implements TextMapSetter<Map<String, dynamic>> {
  @override
  void set(Map<String, dynamic> carrier, String key, String value) {
    carrier[key] = value;
  }
}
```

---

## Navigation Observer

```dart
// lib/core/telemetry/observers/tracing_navigation_observer.dart
import 'package:flutter/widgets.dart';
import 'package:opentelemetry/api.dart'
    show Attribute, Span, StatusCode, Tracer, globalTracerProvider;

class TracingNavigationObserver extends NavigatorObserver {
  TracingNavigationObserver()
      : _tracer = globalTracerProvider.getTracer('navigation');

  final Tracer _tracer;
  Span? _currentRouteSpan;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _endCurrentSpan();
    _currentRouteSpan = _tracer.startSpan(
      'navigation.push ${route.settings.name ?? "unknown"}',
      attributes: [
        Attribute.fromString('screen.name', route.settings.name ?? 'unknown'),
        Attribute.fromString('navigation.action', 'push'),
      ],
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _endCurrentSpan();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _endCurrentSpan();
    if (newRoute != null) {
      _currentRouteSpan = _tracer.startSpan(
        'navigation.replace ${newRoute.settings.name ?? "unknown"}',
        attributes: [
          Attribute.fromString('screen.name', newRoute.settings.name ?? 'unknown'),
          Attribute.fromString('navigation.action', 'replace'),
        ],
      );
    }
  }

  void _endCurrentSpan() {
    final span = _currentRouteSpan;
    if (span != null) {
      span
        ..setStatus(StatusCode.ok)
        ..end();
    }
    _currentRouteSpan = null;
  }
}
```

---

## BLoC Observer

```dart
// lib/core/telemetry/observers/tracing_bloc_observer.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opentelemetry/api.dart'
    show Attribute, StatusCode, Tracer, globalTracerProvider;

class TracingBlocObserver extends BlocObserver {
  TracingBlocObserver()
      : _tracer = globalTracerProvider.getTracer('bloc');

  final Tracer _tracer;

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    // Create a one-shot span per event ; close immediately to avoid leaks.
    final span = _tracer.startSpan(
      '${bloc.runtimeType}.${event.runtimeType}',
      attributes: [
        Attribute.fromString('bloc.type', bloc.runtimeType.toString()),
        Attribute.fromString('bloc.event', event.runtimeType.toString()),
      ],
    );
    span.end();
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    final span = _tracer.startSpan('${bloc.runtimeType}.error');
    span
      ..recordException(error, stackTrace: stackTrace)
      ..setStatus(StatusCode.error, error.toString())
      ..end();
  }
}
```

Register in `main.dart` :

```dart
Bloc.observer = TracingBlocObserver();
```

---

## User Interaction Spans

```dart
// lib/core/telemetry/telemetry_service.dart
import 'package:injectable/injectable.dart';
import 'package:opentelemetry/api.dart'
    show Attribute, SpanKind, StatusCode, Tracer, globalTracerProvider;

@lazySingleton
class TelemetryService {
  TelemetryService()
      : _tracer = globalTracerProvider.getTracer('user.interaction');

  final Tracer _tracer;

  /// Wrap a user-initiated action in a span.
  Future<T> trackInteraction<T>(
    String name,
    Future<T> Function() action, {
    Map<String, Object> attributes = const {},
  }) async {
    final span = _tracer.startSpan(
      name,
      kind: SpanKind.internal,
      attributes: attributes.entries
          .map((e) => Attribute.fromString(e.key, e.value.toString()))
          .toList(),
    );
    try {
      final result = await action();
      span.setStatus(StatusCode.ok);
      return result;
    } catch (e, st) {
      span
        ..recordException(e, stackTrace: st)
        ..setStatus(StatusCode.error, e.toString());
      rethrow;
    } finally {
      span.end();
    }
  }
}

// Usage in a BLoC
Future<void> _onSubmitOrder(
  SubmitOrder event,
  Emitter<OrderState> emit,
) async {
  await _telemetry.trackInteraction(
    'user.submit_order',
    () => _placeOrder(event.cart),
    attributes: {'order.item_count': event.cart.items.length},
  );
}
```

---

## Error Instrumentation

```dart
// lib/core/telemetry/error_reporter.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:opentelemetry/api.dart'
    show Attribute, StatusCode, Tracer, globalTracerProvider;

@lazySingleton
class ErrorReporter {
  ErrorReporter()
      : _tracer = globalTracerProvider.getTracer('error');

  final Tracer _tracer;

  void report(
    Object error,
    StackTrace stackTrace, {
    Map<String, String> context = const {},
  }) {
    final span = _tracer.startSpan(
      'error.reported',
      attributes: [
        Attribute.fromString('error.type', error.runtimeType.toString()),
        Attribute.fromString('error.message', error.toString()),
        ...context.entries.map((e) => Attribute.fromString(e.key, e.value)),
      ],
    );
    span
      ..recordException(error, stackTrace: stackTrace)
      ..setStatus(StatusCode.error, error.toString())
      ..end();
  }
}

// In main.dart
FlutterError.onError = (details) {
  getIt<ErrorReporter>().report(details.exception, details.stack ?? StackTrace.empty);
  FlutterError.presentError(details);
};

PlatformDispatcher.instance.onError = (error, stack) {
  getIt<ErrorReporter>().report(error, stack);
  return true;
};
```

---

## Custom Spans

```dart
// Use for business-critical flows.
import 'package:opentelemetry/api.dart'
    show Attribute, StatusCode, globalTracerProvider;

Future<void> _processCheckout(Cart cart) async {
  final tracer = globalTracerProvider.getTracer('checkout');
  final span = tracer.startSpan(
    'checkout.process',
    attributes: [
      Attribute.fromInt('checkout.item_count', cart.items.length),
      Attribute.fromString('checkout.currency', cart.currency),
    ],
  );

  try {
    span.addEvent('payment.started');
    await _paymentService.charge(cart.total);
    span.addEvent('payment.completed');

    span.addEvent('inventory.reserving');
    await _inventoryService.reserve(cart.items);
    span.addEvent('inventory.reserved');

    span.setStatus(StatusCode.ok);
  } catch (e, st) {
    span
      ..recordException(e, stackTrace: st)
      ..setStatus(StatusCode.error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
```

---

## Context Propagation (W3C traceparent)

When making requests to your backend, the `TracingInterceptor`
automatically injects the `traceparent` header following the W3C
Trace Context spec :

```
traceparent: 00-{traceId}-{spanId}-{flags}
```

The backend must extract and use this header to continue the same
trace, creating a distributed trace from the Flutter client to
backend services. The `W3CTraceContextPropagator` class is exported
by `package:opentelemetry/api.dart`. The carrier setter implements
`TextMapSetter<Map<String, dynamic>>` (the Dio header map type).

The `contextWithSpan(Context, Span)` top-level function from
`api.dart` builds the context the propagator injects — it is the
canonical replacement for the JS/Java-style `withSpan` method on
Context (which does NOT exist in the Dart `opentelemetry: 0.18.11`
API ; see REVIEW.md 2026-05-11 entry).

---

## Rules

- **No PII in span attributes** : no emails, names, passwords, or
  tokens. NFR-FOT-DA aligns with Article XI.6 (privacy).
- **Sanitize URL paths** : replace IDs with `{id}` to bound span-name
  cardinality.
- **Spans must always be ended** : use try/finally to guarantee
  `span.end()`.
- **Use `BatchSpanProcessor`** with a 5 s `scheduledDelayMillis` and
  a 512 `maxExportBatchSize`. Tune via the named ctor params.
- **Resource attributes are set once at startup** : service name,
  version, environment, platform.
- **`TracingInterceptor` is the only place HTTP spans are created** :
  never manually create HTTP spans in repositories. The interceptor
  guarantees `traceparent` injection on every outgoing call.
- **Error spans use `recordException`**, not just
  `setStatus(StatusCode.error)`. The exception attribute set
  (`exception.type`, `exception.message`, `exception.stacktrace`)
  is what SigNoz / Coroot pivot off for the error analytics UI.
- **Traces only in v1.1.0** : this standard scopes to traces.
  Metrics (alpha per Workiva) and logs (unimplemented per Workiva)
  are out of scope until upstream moves them to Beta — see the
  Status callout at the top of this file. Cross-language adopters
  needing metrics + logs today should rely on the Rust backend (per
  `rust/opentelemetry.md`) for those signals.

---

## References

- Workiva pub.dev page : <https://pub.dev/packages/opentelemetry>
- Workiva 0.18.11 page : <https://pub.dev/packages/opentelemetry/versions/0.18.11>
- Workiva GitHub repo : <https://github.com/Workiva/opentelemetry-dart>
- `lib/api.dart` export list : <https://github.com/Workiva/opentelemetry-dart/blob/master/lib/api.dart>
- `lib/sdk.dart` export list : <https://github.com/Workiva/opentelemetry-dart/blob/master/lib/sdk.dart>
- `t5-otel-app::open-questions.md::Q-004` (origin of this realign).
- `t5-otel-stack::ADR-OTEL-001` (collector-side `probabilistic_sampler`
  ratio enforcement).
