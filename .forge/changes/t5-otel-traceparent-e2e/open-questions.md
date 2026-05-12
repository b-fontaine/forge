# Open Questions — t5-otel-traceparent-e2e

<!--
Tracking file per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`).
Q-NNN is sequential per change, zero-padded to 3 digits, never reused.
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: Sampled-off path exporter semantics under `opentelemetry 0.31`

- **Status**: answered
- **Raised in**: proposal.md ; specs.md (Scenario 3 — sampled-off path)
- **Raised on**: 2026-05-11
- **Raised by**: @bfontaine

### Question

When an incoming HTTP request carries a W3C traceparent header with
the sampled bit cleared (`traceparent: 00-{traceId}-{spanId}-00`),
what is the exact behaviour of the Rust pipeline at the pinned
versions (`opentelemetry 0.31` + `tracing-opentelemetry 0.32` +
`tower-http 0.6 [trace]`) wired by Phase B (`t5-otel-app`) ?

Three candidate behaviours surveyed :

1. **Created, recorded, not-exported** — the span exists in memory,
   `tracing::info_span!` returns a valid `Span` handle, attributes
   are recorded, but the `BatchSpanProcessor` drops the span at
   export time because the parent sample-flag propagates through
   `Sampler::ParentBased(...)`. This is the OTel-spec intent.
2. **Not created at all** — `Sampler::ParentBased(...)` returns
   `Drop` and the SDK skips span construction entirely. Closer to a
   zero-overhead optimisation but less faithful to the spec.
3. **Created and exported** — sampling-flag is ignored at the SDK
   level and the collector decides. Phase A's collector-side
   `probabilistic_sampler` would then drop the span. Possible if
   Phase B accidentally shipped `Sampler::AlwaysOn` somewhere.

The BDD scenario MUST quote the right behaviour. Wrong scenario
text = future false-positive on live-run Phase D.

### Investigation steps

1. Context7 query `/open-telemetry/opentelemetry-rust` for
   "ParentBased sampler behaviour with traceparent flags=00".
2. Read Phase B's `setup_telemetry` source at
   `examples/forge-fsm-example/backend/crates/infrastructure/src/telemetry/mod.rs`
   to confirm the actual sampler pinned (per ADR-T5-OTA-003 it
   should be `Sampler::ParentBased(Box::new(Sampler::TraceIdRatioBased(rate)))`).
3. Cross-reference the OTel spec
   (https://opentelemetry.io/docs/specs/otel/trace/sdk/#parentbasedsampler).

### Resolution

**Resolved at `/forge:design` 2026-05-11 via ADR-T5-TPE-001.**

Per the OTel spec (`https://opentelemetry.io/docs/specs/otel/trace/sdk/#parentbasedsampler`),
the `ParentBased` sampler delegates to the parent context's
`SampledFlag`. When `flags=00`, the sampler returns `Decision::Drop` :
the span exists as a non-recording handle (`is_recording() == false`)
but the `BatchSpanProcessor` skips it. Collector receives zero spans
for that traceId.

The BDD scenario text in `traceparent_e2e.feature` uses the
"recorded by the SDK as a no-op handle / BatchSpanProcessor does NOT
export it / collector receives zero spans" phrasing per
ADR-T5-TPE-001 § Decision.

---

## Q-002: Envoy forward-pointer change name

- **Status**: answered
- **Raised in**: proposal.md § Scope Out ; design.md § Out of scope
- **Raised on**: 2026-05-11
- **Raised by**: @bfontaine

### Question

The Envoy gateway validation is deferred to a future change in the
T6 / B.8 flagship migration per `docs/ARCHITECTURE-TARGET.md`
ADR-001. What working name does this change quote in its
forward-pointer ? Candidates :

- `b8-envoy-migration` — matches the ARCHITECTURE-TARGET working
  name.
- `t6-envoy-traceparent` — would mirror this change's naming
  pattern (`t5-otel-traceparent-e2e`).
- `b8-flagship-envoy` — generic flagship-migration name covering
  more than just Envoy.

The forward-pointer is documentation only ; the future change can
be renamed at its creation time without breaking this change's
audit trail (the citation is a free-form string, not a code link).

### Investigation steps

1. Re-read `docs/ARCHITECTURE-TARGET.md` ADR-001 for the canonical
   name.
2. Check `docs/new-archetypes-plan.md` for a referenced future
   phase name.

### Resolution

**Resolved at `/forge:design` 2026-05-11 via ADR-T5-TPE-002.**

Working name `b8-envoy-migration` (matches
`docs/ARCHITECTURE-TARGET.md` ADR-001 terminology). The name is
documented as **provisional** in `design.md` § Out of scope and the
`kong.yml.example` comment block. The future change can rename
itself at creation time without breaking this change's audit trail
(citations are documentation strings, not code links).
