// Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
//
// TracingNavigationObserver — emits one span per route push / replace.
// Mirrors `flutter/opentelemetry.md` § Navigation Observer.

import 'package:flutter/widgets.dart';
import 'package:opentelemetry/api.dart';

class TracingNavigationObserver extends NavigatorObserver {
  TracingNavigationObserver()
    : _tracer = globalTracerProvider.getTracer('navigation');

  final Tracer _tracer;
  Span? _currentRouteSpan;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
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
    super.didPop(route, previousRoute);
    _endCurrentSpan();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _endCurrentSpan();
    if (newRoute != null) {
      _currentRouteSpan = _tracer.startSpan(
        'navigation.replace ${newRoute.settings.name ?? "unknown"}',
        attributes: [
          Attribute.fromString(
            'screen.name',
            newRoute.settings.name ?? 'unknown',
          ),
          Attribute.fromString('navigation.action', 'replace'),
        ],
      );
    }
  }

  void _endCurrentSpan() {
    final span = _currentRouteSpan;
    if (span != null) {
      span.setStatus(StatusCode.ok);
      span.end();
    }
    _currentRouteSpan = null;
  }
}
