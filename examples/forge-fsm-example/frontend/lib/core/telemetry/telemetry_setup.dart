// Audit: T.5.3 (t5-otel-dartastic-realign) — Workiva → Dartastic substitution
//
// telemetry_setup.dart — initialise the OpenTelemetry SDK for the Flutter
// frontend on the Dartastic ecosystem. Replaces the Workiva
// `opentelemetry: 0.18.11` init from T5 / Phase B (Q-006 resolution).
//
// Per `flutter/opentelemetry.md` v2.0.0 § SDK Initialization :
//   - exposes `Future<void> setupTelemetry({required AppConfig config})`.
//   - delegates to `OTel.initialize(serviceName, endpoint, sampler)` — the
//     high-level Dartastic init wraps Resource + BatchSpanProcessor +
//     OtlpHttpSpanExporter wiring per ADR-T53-001 (flutterrific path).
//   - keeps the Phase A (collector probabilistic_sampler) + Phase B
//     (SDK ParentBasedSampler(AlwaysOnSampler())) dual-stage sampling
//     model per ADR-OTEL-001 / ADR-T53-004.
//
// Dartastic `resourceAttributes` parameter is typed `Attributes?` (not a
// plain Map<String, String>). The canonical conversion is via the
// `<String, Object>{...}.toAttributes()` extension method exposed by the
// API package.

import 'dart:io' show Platform;

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import '../config/app_config.dart';

/// Initialise the global tracer provider on the Dartastic ecosystem.
///
/// Call BEFORE `runApp`. Also BEFORE `Bloc.observer = TracingBlocObserver()`
/// so the observer can resolve the tracer in its constructor.
///
/// Sampler : `ParentBasedSampler(AlwaysOnSampler())` (Phase B) — the
/// collector-side `probabilistic_sampler` (Phase A, ADR-OTEL-001) enforces
/// the env-tier ratio downstream.
Future<void> setupTelemetry({required AppConfig config}) async {
  await OTel.initialize(
    serviceName: config.serviceName,
    endpoint: '${config.otlpEndpoint}/v1/traces',
    sampler: ParentBasedSampler(const AlwaysOnSampler()),
    resourceAttributes: <String, Object>{
      'service.version': config.appVersion,
      'deployment.environment': config.environment,
      'device.platform': Platform.operatingSystem,
      'device.os.version': Platform.operatingSystemVersion,
    }.toAttributes(),
  );
}
