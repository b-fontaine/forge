# <!-- Audit: T.5 (t5-otel-traceparent-e2e) — Phase C E2E traceparent through Kong gateway -->
# <!-- Complements demo_005_traceparent.feature (Phase B, FR-T5-OTA-031) -->
#
# Phase C BDD scenarios for FR-T5-TPE-001..010. Three scenarios cover
# the W3C traceparent validation matrix :
#   1. Direct path  — Flutter → axum → connectrpc → use case (4 spans).
#   2. Kong path    — Flutter → Kong → axum → handler → use case (5 spans).
#   3. Sampled-off  — incoming traceparent with sampled bit cleared.
#
# Symbol references (HeaderMapExtractor, MetadataMapCarrier) point to
# Phase B's `backend/crates/infrastructure/src/telemetry/propagation.rs`.
#
# Step bodies are deferred to Phase D (see TODO at the bottom). Phase C
# is harness + spec, NOT live-run. The actual stack-run validation
# (docker compose, flutter run, SigNoz API verification) is owned by
# the future `t5-otel-live-run` change.

Feature: W3C traceparent end-to-end validation across the example archetype
  As a Forge full-stack-monorepo archetype consumer
  I want pressing the "Greet" button to produce a connected span tree at every hop
  So that SigNoz shows one traceId from Flutter root span to backend handler span

  Background:
    Given the example flagship stack ships the Phase A OTel collector at "http://fsm-otel-collector:4318"
    And the Phase B Rust SDK init wires "TraceContextPropagator" via "HeaderMapExtractor"
    And the Phase B Flutter SDK init wires "TracingInterceptor" with W3C "traceparent" injection
    And the Kong gateway preserves incoming "traceparent" and "tracestate" headers verbatim

  Scenario: Direct path — Flutter to axum to connectrpc handler to use case
    Given the Flutter app calls the backend directly (no gateway hop)
    When the user taps "Greet" with name "Forge"
    Then the Flutter client emits a span "POST /connect/greeting.v1.GreeterService/Greet"
    And the outbound request carries a "traceparent" header matching "00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]"
    And the Rust axum middleware creates a server span via "TraceLayer::new_for_http().make_span_with"
    And the axum middleware extracts the parent context using "HeaderMapExtractor"
    And the connectrpc handler creates a child span "greeter.greet"
    And the use case "#[tracing::instrument]" creates a grand-child span
    And the four spans share the same "traceId" in the OTLP export

  Scenario: Kong path — Flutter to Kong to axum to handler to use case
    Given the Flutter app calls the backend through the Kong gateway
    And the Kong declarative config (kong.yml.example) has no "request_transformer.remove.headers" entry for "traceparent"
    When the user taps "Greet" with name "Forge"
    Then the Flutter client emits a span with a "traceparent" header
    And the Kong gateway forwards the request preserving "traceparent" and "tracestate" verbatim
    And the Rust axum middleware extracts the parent context from the preserved "traceparent" using "HeaderMapExtractor"
    And for the parallel tonic gRPC path the same extraction happens via "MetadataMapCarrier"
    And the connectrpc handler creates a child span "greeter.greet"
    And the use case "#[tracing::instrument]" creates a grand-child span
    And the five spans (four app + zero Kong, Kong is transparent) share the same "traceId" in the OTLP export

  Scenario: Sampled-off path — incoming traceparent with sampled bit cleared
    Given a client sends a "traceparent" header "00-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-bbbbbbbbbbbbbbbb-00"
    When the request reaches the Rust axum middleware
    Then the server span is recorded by the SDK as a no-op handle ("is_recording" = false)
    But the "BatchSpanProcessor" does NOT export the span because the "ParentBased" sampler honors the cleared sampled flag
    And the OTel collector receives zero spans for "traceId" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    And SigNoz shows no trace tree for that traceId

# TODO(#TBD-OTEL-PHASE-D): Phase D wires the bdd_widget_test step bodies
# (Flutter side), the cucumber-rs step bodies (Rust side), and the
# docker-compose live-run driver. Phase C ships the scenario text +
# the harness gate ; Phase D ships the executor. Tracking change name :
# `t5-otel-live-run` (provisional, set at change creation time).
#
# See also: `.forge/changes/t5-otel-traceparent-e2e/tasks.md` § "Phase D — DEFERRED"
# for the full deferred-deliverables roadmap.
