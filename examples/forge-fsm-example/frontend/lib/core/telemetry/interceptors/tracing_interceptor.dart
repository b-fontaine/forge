// Audit: T.5.3 (t5-otel-dartastic-realign) — Workiva → Dartastic substitution
//
// TracingInterceptor — dio interceptor that emits a `client` span per HTTP
// request and injects the W3C `traceparent` header on outbound calls.
// Mirrors `flutter/opentelemetry.md` v2.0.0 § HTTP Instrumentation via Dio
// Interceptor (Dartastic ecosystem).
//
// Dartastic API specifics (verified via pub.dev 2026-05-18) :
//   - `OTel.tracer()` returns the default tracer (no positional name arg).
//   - Span attributes are typed : `setStringAttribute(key, String)` /
//     `setIntAttribute(key, int)` / `setBoolAttribute(key, bool)`. The
//     Workiva collection-style `setAttribute(Attribute.fromString(...))`
//     does not exist.
//   - `SpanStatusCode.Ok` / `SpanStatusCode.Error` (Status enum lives in
//     `SpanStatusCode`, not in a `StatusCode` top-level enum).
//   - W3C propagator's `inject` expects `Map<String, String>` carrier and
//     a typed `TextMapSetter<String>` setter — a `dynamic`-typed closure
//     does NOT type-check. Workaround : build into a `Map<String, String>`
//     scratch buffer, then `addAll` into the request's `Map<String,
//     dynamic>` headers.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dio/dio.dart';

class TracingInterceptor extends Interceptor {
  TracingInterceptor() : _tracer = OTel.tracer();

  final Tracer _tracer;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final span = _tracer.startSpan(
      '${options.method} ${_sanitizePath(options.path)}',
      kind: SpanKind.client,
    )
      ..setStringAttribute('http.method', options.method)
      ..setStringAttribute('http.url', options.uri.toString())
      ..setStringAttribute('http.target', options.path)
      ..setStringAttribute('net.peer.name', options.uri.host);

    // Inject the W3C `traceparent` header into the outbound request.
    // Propagator carrier must be Map<String, String> ; build a scratch
    // map then merge into options.headers (Map<String, dynamic>).
    // `_HeadersSetter` is initialised with the carrier (Dartastic
    // TextMapSetter<T> is stateful — `set(key, value)` takes 2 args).
    final propagator = W3CTraceContextPropagator();
    final Map<String, String> traceHeaders = <String, String>{};
    propagator.inject(
      Context.current.withSpan(span),
      traceHeaders,
      _HeadersSetter(traceHeaders),
    );
    options.headers.addAll(traceHeaders);

    // Stash the span on the request for completion in onResponse / onError.
    options.extra['otel_span'] = span;

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final span = response.requestOptions.extra['otel_span'] as Span?;
    if (span != null) {
      span
        ..setIntAttribute('http.status_code', response.statusCode ?? 0)
        ..setStatus(SpanStatusCode.Ok)
        ..end();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final span = err.requestOptions.extra['otel_span'] as Span?;
    if (span != null) {
      span
        ..setIntAttribute('http.status_code', err.response?.statusCode ?? 0)
        ..setStringAttribute('exception.type', err.type.name)
        ..setStringAttribute('exception.message', err.message ?? '')
        ..recordException(err)
        ..setStatus(SpanStatusCode.Error, err.message ?? '')
        ..end();
    }
    handler.next(err);
  }

  /// Replace UUIDs and numeric IDs with `{id}` to bound span-name
  /// cardinality (per FR-T5-OTA-063).
  String _sanitizePath(String path) {
    return path
        .replaceAll(
          RegExp(
            r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
          ),
          '{id}',
        )
        .replaceAll(RegExp(r'/\d+'), '/{id}');
  }
}

class _HeadersSetter implements TextMapSetter<String> {
  _HeadersSetter(this._carrier);

  final Map<String, String> _carrier;

  @override
  void set(String key, String value) {
    _carrier[key] = value;
  }
}
