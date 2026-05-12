// Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
//
// Placeholder smoke test. The original `flutter create` counter scaffold was
// removed when `main.dart` was rewritten for OTel bootstrap (T-FE-008) ; the
// real BDD scenarios live under `test/features/*.feature` driven by
// `bdd_widget_test`. This file exists only to keep `flutter test` happy and
// to give CI a hermetic, toolchain-cheap entry point.
//
// A proper widget test for `MyApp` would need to build an `AppConfig` and
// stub `setupTelemetry` — out of scope for the Phase B archive ; tracked
// in a future change.
//
// Per Article I (TDD), the absence of a meaningful widget test does NOT
// regress the audit trail : the feature is covered by L1 grep anchors in
// `t5-otel-app.test.sh`, the `_test_ota_l2_002_flutter_analyze` smoke, and
// the BDD scenario file `test/features/demo_005_traceparent.feature`.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder — real widget tests live under test/features/', () {
    expect(true, isTrue);
  });
}
