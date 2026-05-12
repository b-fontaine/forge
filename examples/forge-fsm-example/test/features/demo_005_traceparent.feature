# Audit: T.5 (t5-otel-app) — Phase B SDK instrumentation
#
# Article II.1 BDD scenario for FR-T5-OTA-031 (parent linkage of the
# demo-005 round trip span tree). Step definitions are stubs ; full step
# bodies land in Phase D when the `bdd_widget_test` step harness and the
# `cucumber-rs` Rust harness are wired (separate change). For Phase B,
# the scenario file's existence is the audit-trail anchor.

Feature: Distributed tracing across the demo-005 round trip
  As a developer running the forge-fsm-example flagship project
  I want pressing the "Greet" button to produce a connected backend span tree
  So that I can see the full request path in SigNoz with a single traceId

  Background:
    Given the local dev cluster is running ("task dev")
    And the OTel collector is reachable at "http://fsm-otel-collector:4318"
    And the SigNoz UI is reachable at "http://localhost:3301"

  Scenario: Flutter HTTP request produces a connected backend span tree
    Given the Flutter app is launched and the greeting screen is displayed
    When the user types "Forge" in the name field
    And the user taps the "Greet" button
    Then a span "user.interaction greet" is started in the Flutter SDK
    And a span "POST /connect/greeting.v1.GreeterService/Greet" is started by the TracingInterceptor
    And the outbound request carries a "traceparent" header matching "00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]"
    And the Rust axum middleware extracts the parent context from "traceparent"
    And the connectrpc handler creates a child span "greeter.greet" inheriting that context
    And the application use case (annotated with #[tracing::instrument]) creates a grand-child span
    And all four spans share the same traceId in the OTLP export
    And the SigNoz UI displays a single trace tree connecting Flutter -> axum -> connectrpc -> application

# TODO(#TBD-OTEL-BDD): wire bdd_widget_test step bodies in Phase D and
# the cucumber-rs Rust step bodies in the matching backend harness.
