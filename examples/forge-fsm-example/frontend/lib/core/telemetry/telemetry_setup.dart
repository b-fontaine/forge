// Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
//
// telemetry_setup.dart — initialise the OpenTelemetry SDK for the Flutter
// frontend. Mirrors the patterns in `flutter/opentelemetry.md` v1.1.0
// § SDK Initialization with the ADR-T5-OTA-002 deviation (OTLP HTTP/protobuf
// transport on port 4318) and ADR-T5-OTA-003 sampler shape.
//
// Per FR-T5-OTA-040 / FR-T5-OTA-046 :
//   - exposes `Future<void> setupTelemetry({required AppConfig config})`.
//   - calls `registerGlobalTracerProvider(provider)` at the end so subsequent
//     code paths can call `globalTracerProvider.getTracer(...)`.
//
// Q-004 follow-up (2026-05-12) : realigned to the actual `opentelemetry: 0.18.11`
// (Workiva) public API surface — `CollectorExporter` replaces fabricated
// `OtlpHttpSpanExporter`, `BatchSpanProcessor` uses positional + named params
// (no wrapping config object), and `ParentBasedSampler(AlwaysOnSampler())`
// replaces the fabricated `TraceIdRatioBasedSampler(1.0)`. The Phase A
// collector `probabilistic_sampler` continues to enforce the env-tier ratio
// downstream per ADR-T5-OTA-003 / ADR-OTEL-001 (dual-stage model).

import 'dart:io' show Platform;

import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart';

import '../config/app_config.dart';

/// Initialise the global tracer provider.
///
/// Call BEFORE `runApp` (per ADR-T5-OTA-005 init order). Also called BEFORE
/// `Bloc.observer = TracingBlocObserver()` so the BLoC observer can resolve
/// the global tracer in its constructor.
Future<void> setupTelemetry({required AppConfig config}) async {
  // 1. Resource — service identity + deployment metadata + device platform.
  //    Per FR-T5-OTA-043. No PII (FR-T5-OTA-010).
  final resource = Resource([
    Attribute.fromString(ResourceAttributes.serviceName, config.serviceName),
    Attribute.fromString(ResourceAttributes.serviceVersion, config.appVersion),
    Attribute.fromString(
      ResourceAttributes.deploymentEnvironment,
      config.environment,
    ),
    Attribute.fromString('device.platform', Platform.operatingSystem),
    Attribute.fromString('device.os.version', Platform.operatingSystemVersion),
  ]);

  // 2. Exporter — OTLP HTTP/protobuf to the collector :4318 receiver
  //    (ADR-T5-OTA-002). `CollectorExporter` (from `sdk.dart`) speaks the
  //    OTLP wire format ; transport security is governed by the Uri scheme
  //    (https in production, http in dev/staging).
  final exporter = CollectorExporter(
    Uri.parse('${config.otlpEndpoint}/v1/traces'),
  );

  // 3. BatchSpanProcessor — positional exporter, named tuning params per
  //    `opentelemetry: 0.18.11` Workiva pkg. No wrapping config object in
  //    this version (FR-T5-OTA-044 + flutter/opentelemetry.md v1.1.0
  //    § SDK Initialization snippet).
  final processor = BatchSpanProcessor(
    exporter,
    maxExportBatchSize: 512,
    scheduledDelayMillis: 5000,
  );

  // 4. Sampler — `ParentBasedSampler(AlwaysOnSampler())` per ADR-T5-OTA-003
  //    (revised after Q-004 realign). The `TraceIdRatioBased*` class is NOT
  //    exported by `opentelemetry: 0.18.11` ; the env-tier ratio is enforced
  //    collector-side via `processors.probabilistic_sampler` (Phase A,
  //    ADR-OTEL-001). See `flutter/opentelemetry.md` v1.1.0 § Sampling.
  final sampler = ParentBasedSampler(AlwaysOnSampler());

  // 5. TracerProvider — wire resource + processor + sampler.
  final tracerProvider = TracerProviderBase(
    resource: resource,
    processors: [processor],
    sampler: sampler,
  );

  // 6. Register globally — every observer / interceptor reads the global
  //    provider via `globalTracerProvider.getTracer(...)` (FR-T5-OTA-046).
  registerGlobalTracerProvider(tracerProvider);
}
