# Specifications: demo-005-connect-greeting

<!-- Status: archived -->

## Functional Requirements

- **FR-DEMO5-001** : The reference project MUST expose the existing
  `forge.greeter.v1.Greeter/Greet` RPC via Connect-RPC at
  `http://localhost:8080/connect/forge.greeter.v1.Greeter/Greet`.
- **FR-DEMO5-002** : The TypeScript client at
  `examples/forge-fsm-example/clients/connect-client.ts` MUST call the
  Connect endpoint using `@connectrpc/connect@^2.0.0` runtime + a
  `createConnectTransport` HTTP/1.1 transport, default codec
  `application/connect+json`.
- **FR-DEMO5-003** : The TypeScript client MUST seed a W3C
  `traceparent` header per call (random `trace-id` + random
  `span-id`) so the L2 fixture (FR-T5-CC-014) can assert end-to-end
  span correlation.
- **FR-DEMO5-004** : `examples/forge-fsm-example/clients/package.json`
  MUST pin `@connectrpc/connect@^2.0.0` and
  `@connectrpc/connect-web@^2.0.0` (Connect v2 ; v1 packages are
  retired and MUST NOT be pinned).

## BDD Scenarios

```gherkin
Feature: Connect-RPC Greeter — additive transport for Greeter service

  Background:
    Given the bin-server is running with the Connect adapter mounted at /connect
    And the Greeter service is registered with the Connect router

  Scenario: Happy path — Connect+JSON unary call
    Given a TypeScript Connect client built with createConnectTransport
    And the request payload is { "name": "world" }
    When the client calls Greeter.Greet
    Then the response status is 200
    And the response body satisfies { "message": "Hello, world!" }
    And the response Content-Type starts with "application/json"

  Scenario: Traceparent W3C end-to-end propagation invariant
    Given the client seeds a fresh W3C traceparent header
    And the trace-id portion is a 32-hex value
    When the client calls Greeter.Greet over Connect+JSON
    Then the OTel collector records exactly one server span
    And the recorded span carries the same trace-id as the client header
    And the recorded span has a parent spanId equal to the client header span-id
```

## Non-Functional Requirements

- **NFR-DEMO5-001** : Total demo footprint ≤ 100 KB added to the
  example tree (FR-T5-CC-034 budget).
- **NFR-DEMO5-002** : The TypeScript client file MUST parse with
  `node --check` (no TypeScript-only syntax) so the t5 L1 harness can
  validate it without a compile step.
