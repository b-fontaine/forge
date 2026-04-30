# Proposal: demo-003-rate-limit

<!-- Audit: C.1 (illustrative demo) -->
<!-- Layers: [backend, infra] — multi-layer, triggers Janus -->
<!-- Depends on: demo-001-greeting-service -->

## Problem

Adopters need a concrete demonstration of how a **multi-layer
change** (touching ≥ 2 layers) flows through the Forge pipeline
under the `Janus` cross-layer orchestrator. Single-layer demos
(001 backend, 002 frontend) cover the simpler case ; this demo
exercises the **per-layer delta semantics**, **per-layer
designs / tasks**, and the cross-layer FR namespacing
(`FR-BE-` + `FR-IN-`).

## Solution

Add **rate limiting** to the `Greeter` service from demo-001.
The change touches two layers :

- **infra/** : a Kong `rate-limiting` plugin declaration on the
  Greeter route, capping calls at **10 per minute per consumer**.
- **backend/** : the Greeter handler emits a structured
  `tracing` event when it observes a `429 Too Many Requests`
  response from upstream, allowing the operator to correlate
  rate-limit hits with downstream telemetry.

The change is deliberately **lightweight** — its didactic value
is in the per-layer artefact split, not in the rate-limit
mechanism itself.

## Scope In

- Kong declarative config update under
  `infra/kong/kong.yml.example` (the file the example ships ;
  adopters rename to `kong.yml` on consumption).
- Backend handler instrumentation : log a `tracing::warn`
  event when the gRPC handler returns `429 ResourceExhausted`.
- Per-layer specs.md, designs (one per layer), tasks (one per
  layer), feature file.
- BDD scenario covering the threshold + the bypass.

## Scope Out

- Real Kong deployment (the demo updates the `kong.yml.example` ;
  testing the live rate limit is left as a follow-up).
- Frontend handling of 429 responses (no frontend impact for this
  demo).
- Database backing for the rate-limit counter (Kong handles it
  in-memory in the example deployment).
- Real production thresholds (the 10 RPM is illustrative).

## Impact

- **Technical impact**: Tiny. ~10 lines of YAML + ~5 lines of
  Rust + the per-layer markdown artefacts.
- **Risk level**: Trivial.

## Constitution compliance

- **Article I (TDD)**: the backend handler change ships with a
  unit test.
- **Article II (BDD)**: `features/rate_limit.feature` covers the
  threshold + bypass.
- **Article III (Specs Before Code)**: this proposal precedes
  spec, design, and tasks.
- **Article IV (Delta-Based)**: `specs.md` uses ADDED-only
  delta semantics with FR-BE-/FR-IN- namespacing.
- **Article V (Conformance Gate)**: the Janus orchestrator
  enforces cross-layer alignment before each layer's
  implementation begins (FR-GL-015 of b1-workflow).
- **Article VIII (Infrastructure)**: Kong is the canonical API
  gateway for the archetype (Article VIII.1).
- **Article IX (Observability)**: the tracing event closes the
  loop with the OTel pipeline shipped by b1-delivery.
