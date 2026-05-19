// Audit: T.5.3 (t5-otel-dartastic-realign) — Workiva → Dartastic substitution
//
// TracingBlocObserver — emits a span per BLoC event + a span per error.
// Mirrors `flutter/opentelemetry.md` v2.0.0 § BLoC Observer.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TracingBlocObserver extends BlocObserver {
  TracingBlocObserver() : _tracer = OTel.tracer();

  final Tracer _tracer;

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    final span = _tracer.startSpan('${bloc.runtimeType}.${event.runtimeType}')
      ..setStringAttribute('bloc.type', bloc.runtimeType.toString())
      ..setStringAttribute('bloc.event', event.runtimeType.toString());
    span.end();
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _tracer.startSpan('${bloc.runtimeType}.error')
      ..recordException(error, stackTrace: stackTrace)
      ..setStatus(SpanStatusCode.Error, error.toString())
      ..end();
  }
}
