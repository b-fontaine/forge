# Open Questions — t5-otel-app

<!--
Tracking file per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`).
Q-NNN is sequential per change, zero-padded to 3 digits, never reused.
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: Canonical Dart OTel package name + version + OTLP exporter sub-package?

- **Status**: open
- **Raised in**: proposal.md ; specs.md (Cluster 4)
- **Raised on**: 2026-05-10
- **Raised by**: @bfontaine

### Question

`flutter/opentelemetry.md` standard imports
`package:opentelemetry/api.dart`,
`package:opentelemetry/sdk.dart`, and
`package:opentelemetry/exporter_otlp_grpc.dart`. Several historical
naming candidates exist on pub.dev :

- `opentelemetry` (single bundled package — what the standard's code
  block imports).
- `opentelemetry_api` + `opentelemetry_sdk` +
  `opentelemetry_exporter_otlp_grpc` (split layout used by some
  forks).
- `opentelemetry_dart` (community fork name, sometimes shadowed).

Resolve via Context7 at `/forge:design` :
1. Confirm the canonical pub.dev package name (the one the standard
   compiles against, i.e. matches the `package:opentelemetry/` import
   path).
2. Pick a stable version pin (≥ 30 days old per ADR-T5-002 #1
   criterion ; if no version meets the criterion, document a
   waiver per the T.5 footnote pattern).
3. Decide whether the OTLP exporter ships in a sub-package
   (`exporter_otlp_grpc.dart` or `exporter_otlp_http.dart`) or as a
   separate pub.dev package.

### Resolution

To be filled in at `/forge:design` (will become ADR-T5-OTA-001).

---

## Q-002: OTLP transport — gRPC (port 4317) or HTTP/protobuf (port 4318) per layer?

- **Status**: open
- **Raised in**: proposal.md ; specs.md (Cluster 1, Cluster 4)
- **Raised on**: 2026-05-10
- **Raised by**: @bfontaine

### Question

The OTel collector deployed in Phase A
(`infra/observability/otel-collector-config.yaml`) listens on both :

- **gRPC** : `0.0.0.0:4317` (canonical OTel transport, lower overhead,
  better backpressure, but TLS / HTTP/2 setup mandatory in some
  environments).
- **HTTP/protobuf** : `0.0.0.0:4318` (works behind any HTTP proxy /
  ingress, simpler setup, slightly higher per-span overhead).

Two layers, two transport choices :

- **Rust backend** : the upstream `opentelemetry-otlp` crate has full
  gRPC support via `tonic` (`with_tonic()` per
  `rust/opentelemetry.md`). HTTP path is `with_http()` via `reqwest`.
  Recommended : **gRPC** (`:4317`, `tonic` already in workspace).
- **Flutter frontend** : `opentelemetry_exporter_otlp_grpc` works on
  Dart/Linux/macOS but mobile platforms (Android / iOS) historically
  hit issues with HTTP/2 + grpc-dart 3rd-party CA stores. HTTP/protobuf
  via `package:opentelemetry/exporter_otlp_http.dart` (or its
  equivalent — Q-001) is friendlier across all Flutter targets.
  Recommended : **HTTP/protobuf** (`:4318`).

Resolve at `/forge:design` after Context7 review of both crate / pub
package docs.

### Resolution

To be filled in at `/forge:design` (will become ADR-T5-OTA-002).

---

## Q-003: SDK-side sampler — `AlwaysOn` or `ParentBased(TraceIdRatioBased(1.0))`?

- **Status**: open
- **Raised in**: proposal.md ; specs.md (Cluster 1, Cluster 4)
- **Raised on**: 2026-05-10
- **Raised by**: @bfontaine

### Question

`observability.yaml::sampler: parentbased_traceidratio` is the
standard's intent. Phase A enforces the env-tier ratio collector-side
(`processors.probabilistic_sampler`, ADR-OTEL-001). Two SDK-side
options :

- **A — `Sampler::AlwaysOn`** : every span is exported by the SDK ;
  the collector applies the env-tier ratio. Simpler ; matches the
  Phase A-only-decides architecture ; means dev/staging tools see
  every span before sampling regardless of env. Slightly higher
  network egress (10x more spans on prod compared to head-side
  ratio).
- **B — `ParentBased(TraceIdRatioBased(1.0))`** : SDK respects the
  parent's sampling decision (matches W3C `traceparent` `flags`
  bit) and falls back to ratio 1.0 for root spans. Identical
  behavioural result to A on a fresh trace, but :
  - matches the standard `parentbased_traceidratio` *literally*,
  - lets a future Phase D change drop the SDK ratio to 0.1 on prod
    without rewriting init code (just env-var tweak),
  - costs ≈ 5 extra LOC per layer.

Resolve at `/forge:design` after weighing the dual-stage Phase A +
Phase B model documented in `t5-otel-stack/design.md` ADR-OTEL-001
"Consequences" section.

### Resolution

To be filled in at `/forge:design` (will become ADR-T5-OTA-003).
