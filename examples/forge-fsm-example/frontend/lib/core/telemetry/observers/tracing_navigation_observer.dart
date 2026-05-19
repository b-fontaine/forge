// Audit: T.5.3 (t5-otel-dartastic-realign) — Workiva → Dartastic substitution
//
// TracingNavigationObserver — emits one span per route push / replace.
// Mirrors `flutter/opentelemetry.md` v2.0.0 § Navigation Observer.
//
// Note (ADR-T53-001) : the canonical Dartastic path uses
// `FlutterOTel.routeObserver` from `flutterrific_opentelemetry`.
// This custom NavigatorObserver is kept as the Option B fallback for
// adopters using Navigator 1.0 or who want explicit observer code paths.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter/widgets.dart';

class TracingNavigationObserver extends NavigatorObserver {
  TracingNavigationObserver() : _tracer = OTel.tracer();

  final Tracer _tracer;
  Span? _currentRouteSpan;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _endCurrentSpan();
    _currentRouteSpan =
        _tracer.startSpan('navigation.push ${route.settings.name ?? "unknown"}')
          ..setStringAttribute('screen.name', route.settings.name ?? 'unknown')
          ..setStringAttribute('navigation.action', 'push');
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
      )
        ..setStringAttribute('screen.name', newRoute.settings.name ?? 'unknown')
        ..setStringAttribute('navigation.action', 'replace');
    }
  }

  void _endCurrentSpan() {
    final span = _currentRouteSpan;
    if (span != null) {
      span
        ..setStatus(SpanStatusCode.Ok)
        ..end();
    }
    _currentRouteSpan = null;
  }
}
