// Audit: T.5.3 (t5-otel-dartastic-realign) — Workiva → Dartastic substitution
//
// ErrorReporter — emits an error span via the Dartastic tracer.
// Mirrors `flutter/opentelemetry.md` v2.0.0 § Error Instrumentation.
//
// Dartastic API notes (verified via pub.dev 2026-05-18) :
//   - `OTel.tracer()` returns the default tracer (no positional name arg) ;
//     for a named scope, use `OTel.tracerProvider(name: ...).getTracer()`.
//   - Span attributes are typed : `setStringAttribute(key, String)`,
//     `setIntAttribute(key, int)`, `setBoolAttribute(key, bool)`,
//     `setDoubleAttribute(key, double)`. The Workiva
//     `span.setAttribute(Attribute)` collection-style does not exist.
//   - Status code is `SpanStatusCode` (capital S enum name) with
//     `SpanStatusCode.Ok` and `SpanStatusCode.Error` values.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

class ErrorReporter {
  ErrorReporter() : _tracer = OTel.tracer();

  final Tracer _tracer;

  void report(
    Object error,
    StackTrace stackTrace, {
    Map<String, String> context = const {},
  }) {
    final span = _tracer.startSpan('error.reported')
      ..setStringAttribute('error.type', error.runtimeType.toString())
      ..setStringAttribute('error.message', error.toString());
    for (final entry in context.entries) {
      span.setStringAttribute(entry.key, entry.value);
    }
    span
      ..recordException(error, stackTrace: stackTrace)
      ..setStatus(SpanStatusCode.Error, error.toString())
      ..end();
  }
}
