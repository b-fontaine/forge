# Specs: demo-003-rate-limit

<!-- Audit: C.1 (illustrative multi-layer demo) -->
<!-- Layers: [backend, infra] -->
<!-- Format: ADDED-only delta with per-layer FR-BE-/FR-IN- namespacing. -->

## ADDED Requirements

### FR-IN-001: Kong rate-limit plugin on the Greeter route

- **MUST** — `infra/kong/kong.yml.example` declares a `services`
  entry for `greeter` pointing at the gRPC backend, with a
  `routes` entry mapping `/greeting.v1.GreeterService/*` to the
  service.
- **MUST** — under that route, a `plugins` entry of type
  `rate-limiting` with `config.minute: 10` and
  `config.policy: local`.
- **MUST** — `kong.yml.example` parses as valid YAML (existing
  invariant from `b1-foundations` FR-GL-004 ; reaffirmed here).
- **SHALL** — the plugin's `config.fault_tolerant: true` so a
  Kong restart never wipes the counter mid-flight.

**Constitution reference:** Article VIII.1 (Kong is the canonical
gateway), Article VIII.5 (IaC). **Testable:** yes — `python -c
"yaml.safe_load(open('infra/kong/kong.yml.example'))"` succeeds and the
plugin entry can be located via simple key lookups.

### FR-BE-001: Greeter handler emits tracing event on 429 upstream

- **MUST** — when an upstream client signals `429
  ResourceExhausted` to the Greeter, the handler emits
  `tracing::warn!(target: "greeter.rate_limit", consumer = ?id,
  "rate-limit hit")`.
- **MUST** — the event includes the `consumer.id` field (or
  `"<unknown>"` if absent), the `tonic::Code::ResourceExhausted`
  status code as a numeric attribute.
- **SHALL** — the event does NOT include the request body or
  any PII (Article XI.6 — privacy).

**Constitution reference:** Articles IX.4 (request-handler
spans), XI.6. **Testable:** yes — unit test in
`crates/grpc-api/src/greeter.rs` asserting the event is emitted
when a synthetic 429 response is observed.

## Acceptance Criteria (BDD)

```gherkin
Feature: Rate-limited Greeter
  As an operator
  I want the Greeter service to be rate-limited at the gateway
  So that misbehaving clients cannot overwhelm the backend

  Scenario: Within-threshold calls succeed
    Given the Greeter service is fronted by Kong with a 10/minute rate limit
    When I call Greet 5 times in 1 minute as consumer "alice"
    Then all 5 calls receive a successful response

  Scenario: Above-threshold calls receive 429
    Given the Greeter service is fronted by Kong with a 10/minute rate limit
    When I call Greet 12 times in 1 minute as consumer "alice"
    Then 10 calls receive a successful response
    And the remaining 2 calls receive a 429 ResourceExhausted

  Scenario: Backend tracing event records the rate-limit hit
    Given the Greeter handler is observing the upstream stream
    When a 429 ResourceExhausted is observed for consumer "alice"
    Then a tracing event "greeter.rate_limit" is emitted
    And the event's consumer attribute equals "alice"
```
