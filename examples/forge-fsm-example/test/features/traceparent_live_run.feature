# <!-- Audit: T.5 (t5-otel-live-run) — Phase D live-run collector contract validation -->
#
# Complements Phase C's `traceparent_e2e.feature` (FR-T5-TPE-001..010)
# by adding a live-run leg : the smoke driver under
# `test/live-run/run_smoke.sh` boots a fake OTLP collector on
# `127.0.0.1:4318`, posts a hex-canned `ExportTraceServiceRequest`, and
# the harness asserts a capture JSON matches the committed golden.
#
# Phase B symbol forward-pointer : the backend's
# `HeaderMapExtractor` (in `crates/infrastructure/src/telemetry/
# propagation.rs`) is what extracts the W3C `traceparent` header on the
# inbound boundary ; the live-run probe carries the same header shape
# to verify the collector-boundary contract end-to-end.

Feature: T5 Phase D — live OTLP collector boundary contract
  In order to verify that an OTLP SDK emits well-formed exports
  As a Forge maintainer running the framework harness
  I want a deterministic live-run that proves the collector receives
  the expected service.name and forwards W3C traceparent verbatim.

  Background:
    Given the fake OTLP collector binary at `test/live-run/fake_otlp_collector.py`
    And the smoke driver at `test/live-run/run_smoke.sh`
    And committed golden captures under `.forge/changes/t5-otel-live-run/captures/`

  Scenario: Live capture — fake collector receives OTLP export with the expected service.name
    Given a fresh temporary directory for collector output
    And a hex-canned OTLP payload carrying `resource.attributes.service.name = "fsm-backend"`
    When the smoke driver is invoked with `--scenario direct --out <tmpdir>`
    Then the driver exits with code 0
    And the collector writes a `capture-000.json` containing `"service_name": "fsm-backend"`
    And the capture matches `direct.golden.json` byte-for-byte under `diff -q`
    And the timestamp field is sanitised to `"<ts:redacted>"`
    And the capture contains no IPv4 dotted-quad pattern

  Scenario: Live capture — captured trace carries a W3C traceparent linking parent and child spans
    Given the same probe payload with an added `host.name = "fsm-kong-gateway"` resource attribute
    And the `HeaderMapExtractor` shape from Phase B that propagates inbound traceparent
    And the probe carries the W3C header `traceparent: 00-{a×32}-{b×16}-01`
    When the smoke driver is invoked with `--scenario kong --out <tmpdir>`
    Then the driver exits with code 0
    And the collector echoes the traceparent into the capture's `"traceparent"` field
    And the capture matches `kong.golden.json` byte-for-byte under `diff -q`
    And the sanitiser collapses `host.name` to `"<host:redacted>"`
