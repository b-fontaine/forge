# Flutter OpenTelemetry Standard

## Technology Stack

| Package | Role |
|---|---|
| `opentelemetry_dart` | Core OTel SDK for Dart/Flutter |
| `dio` interceptor | HTTP trace propagation |
| `flutter_bloc` observer | BLoC event/state tracing |

---

## SDK Initialization

```dart
// lib/core/telemetry/telemetry_setup.dart
import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart';
import 'package:opentelemetry/exporter_otlp_grpc.dart';

Future<void> setupTelemetry({required AppConfig config}) async {
  final exporter = OtlpGrpcSpanExporter(
    OtlpGrpcExporterConfig(
      endpoint: config.otlpEndpoint, // e.g. 'http://collector:4317'
      insecure: config.environment != 'production',
    ),
  );

  final processor = BatchSpanProcessor(
    exporter,
    BatchSpanProcessorConfig(
      maxExportBatchSize: 512,
      scheduledDelayMillis: 5000, // 5s flush interval
      exportTimeoutMillis: 30000,
    ),
  );

  final resource = Resource([
    Attribute.fromString(ResourceAttributes.serviceName, config.serviceName),
    Attribute.fromString(ResourceAttributes.serviceVersion, config.appVersion),
    Attribute.fromString(ResourceAttributes.deploymentEnvironment, config.environment),
    Attribute.fromString('device.platform', Platform.operatingSystem),
    Attribute.fromString('device.os.version', Platform.operatingSystemVersion),
  ]);

  final tracerProvider = TracerProviderBase(
    resource: resource,
    processors: [processor],
  );

  registerGlobalTracerProvider(tracerProvider);
}
```

---

## HTTP Instrumentation via Dio Interceptor

```dart
// lib/core/telemetry/interceptors/tracing_interceptor.dart
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

    // Inject W3C traceparent header for context propagation
    final propagator = W3CTraceContextPropagator();
    propagator.inject(
      Context.current.withSpan(span),
      options.headers,
      HttpHeadersSetter(),
    );

    // Store span reference on request for later completion
    options.extra['otel_span'] = span;
    options.extra['otel_context'] = Context.current;

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final span = response.requestOptions.extra['otel_span'] as Span?;
    span
      ?..setAttribute(Attribute.fromInt('http.status_code', response.statusCode ?? 0))
      ..setStatus(SpanStatusCode.ok)
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
      ..setStatus(SpanStatusCode.error, message: err.message)
      ..end();
    handler.next(err);
  }

  String _sanitizePath(String path) {
    // Replace UUIDs and numeric IDs to reduce cardinality
    return path
        .replaceAll(RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'), '{id}')
        .replaceAll(RegExp(r'/\d+'), '/{id}');
  }
}

class HttpHeadersSetter implements TextMapSetter<Map<String, dynamic>> {
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
class TracingNavigationObserver extends NavigatorObserver {
  TracingNavigationObserver()
      : _tracer = globalTracerProvider.getTracer('navigation');

  final Tracer _tracer;
  Span? _currentRouteSpan;

  @override
  void didPush(Route route, Route? previousRoute) {
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
  void didPop(Route route, Route? previousRoute) {
    _endCurrentSpan();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
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
    _currentRouteSpan?.setStatus(SpanStatusCode.ok)..end();
    _currentRouteSpan = null;
  }
}
```

---

## BLoC Observer

```dart
// lib/core/telemetry/observers/tracing_bloc_observer.dart
class TracingBlocObserver extends BlocObserver {
  TracingBlocObserver()
      : _tracer = globalTracerProvider.getTracer('bloc');

  final Tracer _tracer;

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    // Create a span per event; don't keep it open to avoid leaks
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
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    final span = _tracer.startSpan('${bloc.runtimeType}.error');
    span
      ..recordException(error, stackTrace: stackTrace)
      ..setStatus(SpanStatusCode.error, message: error.toString())
      ..end();
  }
}
```

Register in `main.dart`:

```dart
Bloc.observer = TracingBlocObserver();
```

---

## User Interaction Spans

```dart
// lib/core/telemetry/telemetry_service.dart
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
      span.setStatus(SpanStatusCode.ok);
      return result;
    } catch (e, st) {
      span
        ..recordException(e, stackTrace: st)
        ..setStatus(SpanStatusCode.error, message: e.toString());
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
@lazySingleton
class ErrorReporter {
  ErrorReporter()
      : _tracer = globalTracerProvider.getTracer('error');

  final Tracer _tracer;

  void report(Object error, StackTrace stackTrace, {Map<String, String> context = const {}}) {
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
      ..setStatus(SpanStatusCode.error)
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
// Use for business-critical flows
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

    span.setStatus(SpanStatusCode.ok);
  } catch (e, st) {
    span
      ..recordException(e, stackTrace: st)
      ..setStatus(SpanStatusCode.error);
    rethrow;
  } finally {
    span.end();
  }
}
```

---

## Context Propagation (W3C traceparent)

When making requests to your backend, the `TracingInterceptor` automatically injects the `traceparent` header following the W3C Trace Context spec:

```
traceparent: 00-{traceId}-{spanId}-{flags}
```

The backend must extract and use this header to continue the same trace, creating a distributed trace from the Flutter client to backend services.

---

## Rules

- **No PII in span attributes**: no emails, names, passwords, or tokens
- **Sanitize URL paths**: replace IDs with `{id}` to control cardinality
- **Spans must always be ended**: use try/finally to guarantee `span.end()`
- **Use `BatchSpanProcessor`** with 5s interval and 512 max batch
- **Resource attributes are set once at startup**: service name, version, environment, platform
- **`TracingInterceptor` is the only place HTTP spans are created**: never manually create HTTP spans in repositories
- **Error spans use `recordException`**, not just `setStatus(error)`
- **Navigation spans are one per screen**: end previous span before starting next
