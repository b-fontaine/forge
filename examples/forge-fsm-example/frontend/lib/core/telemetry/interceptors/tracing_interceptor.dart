// Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
//
// TracingInterceptor — dio interceptor that emits a `client` span per HTTP
// request and injects the W3C `traceparent` header on outbound calls.
// Mirrors `flutter/opentelemetry.md` § HTTP Instrumentation via Dio
// Interceptor.
//
// Per FR-T5-OTA-060..063 :
//   - SpanKind.client per outbound call.
//   - W3CTraceContextPropagator injects `traceparent` (span ends on response
//     or error).
//   - `_sanitizePath` replaces UUIDs and numeric IDs with `{id}` to keep
//     span name cardinality bounded.
//   - `recordException` on error (not just `setStatus(error)`).

import 'package:dio/dio.dart';
import 'package:opentelemetry/api.dart';

class TracingInterceptor extends Interceptor {
  TracingInterceptor()
    : _tracer = globalTracerProvider.getTracer('http.client');

  final Tracer _tracer;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
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

    // Inject the W3C `traceparent` header into the outbound request.
    final propagator = W3CTraceContextPropagator();
    propagator.inject(
      Context.current.withSpan(span),
      options.headers,
      _HttpHeadersSetter(),
    );

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
      span.setAttribute(
        Attribute.fromInt('http.status_code', response.statusCode ?? 0),
      );
      span.setStatus(SpanStatusCode.ok);
      span.end();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final span = err.requestOptions.extra['otel_span'] as Span?;
    if (span != null) {
      span.setAttribute(
        Attribute.fromInt('http.status_code', err.response?.statusCode ?? 0),
      );
      span.recordException(
        err,
        attributes: [
          Attribute.fromString('exception.type', err.type.name),
          Attribute.fromString('exception.message', err.message ?? ''),
        ],
      );
      span.setStatus(SpanStatusCode.error, description: err.message);
      span.end();
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

class _HttpHeadersSetter implements TextMapSetter<Map<String, dynamic>> {
  @override
  void set(Map<String, dynamic> carrier, String key, String value) {
    carrier[key] = value;
  }
}
