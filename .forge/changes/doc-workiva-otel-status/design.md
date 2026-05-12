# Design: doc-workiva-otel-status
<!-- Status: designed -->
<!-- Schema: default -->

## ADR-DWO-001 — Annotate asymmetry rather than hide it

**Status**: Accepted  
**Date**: 2026-05-12

### Context

The Workiva `opentelemetry: 0.18.11` Dart SDK ships three OTel signals
at different maturity levels. ARCHITECTURE-TARGET.md §9 references agents
Argus and Sentinel for OTel instrumentation without disclosing that only
Traces are production-ready in Dart.

Three options were evaluated:

1. **Hide the asymmetry** — leave §9 silent on signal maturity, rely on
   flutter/opentelemetry.md for detail.
2. **Annotate the asymmetry** — insert a dated status block in §9 linking
   signal names to Workiva-stated maturity levels.
3. **Defer** — raise an open question and leave unresolved.

### Decision

Option 2: **annotate the asymmetry**.

### Rationale

- §9 is the canonical architecture cross-reference for agent impact; a
  reader stopping there must not be misled about OTel Dart coverage.
- `t5-otel-dart-api-realign` already established the status data
  (FR-FOT-DA-060); surfacing it here is zero-hallucination (data exists).
- A future-review trigger (2026-11-12 / >= 0.19.0 pkg bump) ensures the
  annotation ages gracefully without manual maintenance overhead.
- Option 1 risks adopters deploying Metrics/Logs instrumentation that
  silently does nothing in 0.18.11.
- Option 3 blocks a trivial, verified change with no upside.

### Consequences

- One small callout block added to §9. No architectural decision is
  changed — the annotation is purely informational status disclosure.
- Future change: when Workiva ships >= 0.19.0 with Metrics at Beta or
  Logs at Alpha, a follow-up change updates this block and FR-FOT-DA-060.
