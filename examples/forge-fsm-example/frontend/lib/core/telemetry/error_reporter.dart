// Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
//
// ErrorReporter — emits an error span via the global tracer.
// Mirrors `flutter/opentelemetry.md` § Error Instrumentation.
//
// Plain class (not `@lazySingleton`) per ADR-T5-OTA-005 — `get_it`-clean
// DI is deferred to a future feature change. The TODO marker uses the
// Forge issue-ID convention from Article X.4.

import 'package:opentelemetry/api.dart';

// TODO(#TBD-OTEL-DI): promote ErrorReporter to @lazySingleton via
// `get_it` + `injectable` per Article VI.4 once the example pulls
// `injectable`. For Phase B, instantiated inline in main.dart.
class ErrorReporter {
  ErrorReporter() : _tracer = globalTracerProvider.getTracer('error');

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
    span.recordException(error, stackTrace: stackTrace);
    // setStatus signature in opentelemetry 0.18.11 :
    //   void setStatus(StatusCode, [String description])
    // The description is optional and positional — pass the error string
    // so SigNoz / Coroot pivot the error analytics UI on the right field.
    span.setStatus(StatusCode.error, error.toString());
    span.end();
  }
}
