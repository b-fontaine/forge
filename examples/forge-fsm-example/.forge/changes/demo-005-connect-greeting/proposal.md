# Proposal: demo-005-connect-greeting

<!-- Created: 2026-05-05 -->
<!-- Schema: full-stack-monorepo (single-layer backend) -->

## Problem

`t5-connect-codegen` ships Connect-RPC codegen and a Rust adapter, but
the reference project `examples/forge-fsm-example/` does not yet
demonstrate the full Connect path end-to-end. Without a worked demo,
adopters cannot validate that traceparent W3C propagation crosses the
new transport correctly, nor can they copy a canonical TypeScript
client.

## Solution

Single archived demo change in `examples/forge-fsm-example/.forge/changes/demo-005-connect-greeting/`
exposing the existing `Greeter` service from `demo-001-greeting-service`
in parallel via Connect-RPC. A minimal TypeScript client under
`examples/forge-fsm-example/clients/connect-client.ts` consumes the
Connect endpoint and seeds a W3C `traceparent` header so the L2 fixture
test (FR-T5-CC-014 / FR-T5-CC-033) can assert end-to-end propagation.

## Scope In

- Connect adapter mounted at `/connect` on the backend (already shipped
  by t5-connect-codegen template).
- Minimal `clients/` directory with `package.json` (Connect v2 runtime
  pin) and `connect-client.ts` (~40 LOC) calling Greeter via
  `createConnectTransport`.
- Two BDD scenarios in `specs.md` (happy path Connect+JSON, traceparent
  E2E invariant).
- Single-layer change (backend only) — no new infra, no DB, no Flutter.

## Scope Out

- Rust server-to-server Connect client (deferred to B.8 per ADR-T5-003).
- Production deployment templates (DBOS / Envoy stay in B.8).
- Generated Connect stubs are not committed (`.gitignore` excludes
  `gen/connect/`) ; the demo only ships the hand-written client glue.
