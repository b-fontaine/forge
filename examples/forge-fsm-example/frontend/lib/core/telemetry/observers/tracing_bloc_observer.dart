// Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
//
// TracingBlocObserver — emits a span per BLoC event + a span per error.
// Mirrors `flutter/opentelemetry.md` § BLoC Observer.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opentelemetry/api.dart';

class TracingBlocObserver extends BlocObserver {
  TracingBlocObserver() : _tracer = globalTracerProvider.getTracer('bloc');

  final Tracer _tracer;

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    // One span per event ; closed immediately to avoid leaks. The state
    // transition latency is measured by upstream code if needed (out of
    // scope for Phase B).
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
    span.recordException(error, stackTrace: stackTrace);
    span.setStatus(SpanStatusCode.error, description: error.toString());
    span.end();
  }
}
