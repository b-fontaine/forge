# Design (backend layer): demo-003-rate-limit

<!-- Layer: backend -->
<!-- Audit: C.1 — per-layer design under Janus orchestration -->

## Cross-Layer References

This is the **backend half** of demo-003-rate-limit. The infra
half (Kong plugin declaration) lives at `design-infra.md`.

Cross-layer FRs :
- `FR-IN-001` — Kong plugin (drives FR-BE-001 — handler observes
  the resulting 429 responses).
- `FR-BE-001` — handler tracing event (this layer's only FR).

## Architecture Decisions

### ADR-BE-001: Tracing event via `tracing::warn!` macro

**Context.** The handler must emit an observable event when it
sees a 429 Upstream response. Article IX.4 mandates that request
handlers create root spans ; this is finer-grained — an event
*within* the handler's existing root span.

**Decision.**

- Use the `tracing::warn!` macro with `target =
  "greeter.rate_limit"` so operators can filter by target in
  SigNoz / Tempo.
- Include `consumer = ?id` (the consumer ID extracted from the
  request metadata, falls back to `"<unknown>"`).
- Include `code = tonic::Code::ResourceExhausted as i32` as a
  numeric attribute for dashboards.

**Consequences.**

- ✅ Attribute-rich event ; queryable in any OTLP backend.
- ✅ No new dependency — `tracing` is already a workspace
  dependency.
- ⚠️ The handler does NOT currently observe upstream responses
  (it's the server side of the RPC, not the client). The "observe
  429 from upstream" is a forward-looking pattern for when the
  Greeter calls another service. For the demo, we synthesize the
  observation in tests.

## Standards Applied

- `rust/opentelemetry.md` — `tracing` is the canonical bridge.
- `rust/error-handling.md` — `tonic::Status` already conveys the
  error category ; we only add observability.

✅ Backend constitutional gate green.
