// Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
//
// telemetry_setup.dart — initialise the OpenTelemetry SDK for the Flutter
// frontend. Mirrors the patterns in `flutter/opentelemetry.md` § SDK
// Initialization with the ADR-T5-OTA-002 deviation (OTLP HTTP/protobuf
// transport on port 4318) and ADR-T5-OTA-003 sampler shape.
//
// Per FR-T5-OTA-040 / FR-T5-OTA-046 :
//   - exposes `Future<void> setupTelemetry({required AppConfig config})`.
//   - calls `registerGlobalTracerProvider(provider)` at the end so subsequent
//     code paths can call `globalTracerProvider.getTracer(...)`.

import 'dart:io' show Platform;

import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart';
import 'package:opentelemetry/exporter_otlp_http.dart';

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
    Attribute.fromString(
      'device.os.version',
      Platform.operatingSystemVersion,
    ),
  ]);

  // 2. Exporter — OTLP HTTP/protobuf to the collector :4318 receiver
  //    (ADR-T5-OTA-002). `insecure: true` for dev/staging ; production MUST
  //    set DEPLOYMENT_ENV=production so insecure flips to false.
  final exporter = OtlpHttpSpanExporter(
    OtlpHttpExporterConfig(
      endpoint: '${config.otlpEndpoint}/v1/traces',
      insecure: config.environment != 'production',
    ),
  );

  // 3. BatchSpanProcessor — standard defaults per FR-T5-OTA-044 + the
  //    flutter/opentelemetry.md § SDK Initialization snippet.
  final processor = BatchSpanProcessor(
    exporter,
    BatchSpanProcessorConfig(
      maxExportBatchSize: 512,
      scheduledDelayMillis: 5000,
      exportTimeoutMillis: 30000,
    ),
  );

  // 4. Sampler — `ParentBased(TraceIdRatioBased(1.0))` per ADR-T5-OTA-003.
  //    Default ratio 1.0 ; collector-side `probabilistic_sampler` (Phase A)
  //    reduces to env-tier ratio downstream.
  final sampler = ParentBasedSampler(TraceIdRatioBasedSampler(1.0));

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
