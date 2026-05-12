// Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
//
// AppConfig — env-driven configuration consumed by `setupTelemetry`.
//
// Per ADR-T5-OTA-007, the canonical env var names are the W3C OTel SDK
// names (`OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`,
// `OTEL_RESOURCE_ATTRIBUTES`) plus the Forge-specific `DEPLOYMENT_ENV`.
//
// Flutter mobile reads env via `String.fromEnvironment(...)` from the
// `--dart-define=KEY=VALUE` CLI flag (forwarded by `flutter run` /
// `flutter build`). Native env-var reading on mobile is deferred (see
// ADR-T5-OTA-007 Consequences).

class AppConfig {
  const AppConfig({
    required this.serviceName,
    required this.appVersion,
    required this.environment,
    required this.otlpEndpoint,
  });

  final String serviceName;
  final String appVersion;
  final String environment;
  final String otlpEndpoint;

  /// Build from the `--dart-define` env trio + `DEPLOYMENT_ENV`.
  factory AppConfig.fromEnv() {
    return AppConfig(
      serviceName: const String.fromEnvironment(
        'OTEL_SERVICE_NAME',
        defaultValue: 'fsm-frontend',
      ),
      appVersion: const String.fromEnvironment(
        'APP_VERSION',
        defaultValue: '1.0.0+1',
      ),
      environment: const String.fromEnvironment(
        'DEPLOYMENT_ENV',
        defaultValue: 'dev',
      ),
      otlpEndpoint: const String.fromEnvironment(
        'OTEL_EXPORTER_OTLP_ENDPOINT',
        defaultValue: 'http://fsm-otel-collector:4318',
      ),
    );
  }
}
