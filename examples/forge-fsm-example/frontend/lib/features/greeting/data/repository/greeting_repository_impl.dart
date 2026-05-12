// Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
//
// GreetingRepositoryImpl — fake adapter for demo-002-greeting-screen +
// demo-005-connect-greeting. The fake mirrors demo-001's contract and
// keeps the in-process behaviour deterministic for widget tests.
//
// Per FR-T5-OTA-061, the production transport (Connect/Dart wrapping a
// `dio` client) attaches the `TracingInterceptor` to the dio interceptors
// list so every Connect call carries a W3C `traceparent` header. The fake
// branch below builds a `Dio` instance, attaches the interceptor, and
// keeps an in-process fallback for tests — adopters reading this file see
// the wiring shape verbatim.

import 'package:dio/dio.dart';

import '../../../../core/telemetry/interceptors/tracing_interceptor.dart';
import '../../domain/repository/greeting_repository.dart';

class GreetingRepositoryImpl implements GreetingRepository {
  GreetingRepositoryImpl({Dio? client}) : _client = _build(client);

  // The `_client` field is intentionally retained even though `greet`
  // currently returns an in-process fake — the field-with-TracingInterceptor
  // wiring is the audit anchor for FR-T5-OTA-061 (every Connect call carries
  // the W3C `traceparent` header). The field will be wired into a real
  // Connect/Dart call once `task proto` ships the generated `GreeterClient`.
  // ignore: unused_field
  final Dio _client;

  // The Connect/Dart client is built from this dio instance once the
  // proto-generated `GreeterClient` lands in `lib/generated/protos/`.
  // Until then, we keep the in-process fallback below ; the dio + interceptor
  // wiring is shipped now so adopters get a complete reference.
  static Dio _build(Dio? client) {
    final dio = client ?? Dio();
    if (!dio.interceptors.any((i) => i is TracingInterceptor)) {
      dio.interceptors.add(TracingInterceptor());
    }
    return dio;
  }

  @override
  Future<String> greet(String name) async {
    // TODO(c1-followup): swap this fake for a real Connect/Dart call once
    // `task proto` is wired into the build pipeline. The interceptor is
    // pre-attached so the swap is a one-line change.
    final audience = name.isEmpty ? 'world' : name;
    return 'Hello, $audience!';
  }
}
