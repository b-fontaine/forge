# Open Questions — t5-otel-live-run

<!--
Tracking file per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`).
Q-NNN is sequential per change, zero-padded to 3 digits, never reused.
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: Protobuf decoding strategy in the fake OTLP collector

- **Status**: answered
- **Raised in**: proposal.md ; specs.md (FR-T5-OLR-003)
- **Raised on**: 2026-05-12
- **Raised by**: @bfontaine

### Question

The fake OTLP collector needs to extract `service.name` and a
`ResourceSpans` count from an incoming OTLP protobuf payload. Two
candidate strategies :

1. **Pip `protobuf` dep + generated stubs**. Full decoding ;
   adopters pay 14 MB install + a `.proto` regen on lib bumps.
2. **Stdlib varint + length-delimited tag walker**. Decodes only
   the tags we assert. Zero install cost ; ≤ 60 lines of Python ;
   lossy for fields outside the assertion set.

Which path do we take ?

### Investigation steps

1. Context7 review of the OTLP wire format reference
   (`https://opentelemetry.io/docs/specs/otlp/#otlphttp`).
2. Protobuf wire-format reference for varint + length-delimited
   tag encoding.
3. Audit Phase B's `setup_telemetry` to confirm `service.name` is
   present in the `Resource.attributes` list (Phase B FR-T5-OTA-005).

### Resolution (2026-05-12, ADR-T5-OLR-001)

**Decision** : Stdlib walker. Zero install cost. Decodes only the
fields the contract asserts. Adopter cost = 0. Implementation
~30 lines for the walker + ~120 lines for the HTTP server +
sanitiser + JSON writer.

The walker is intentionally lossy ; the contract is "did the SDK
emit OTLP traffic carrying the right service.name + traceparent",
not "fully reconstruct the trace tree".

See `design.md` ADR-T5-OLR-001 for full rationale and the wire
format references consulted.
