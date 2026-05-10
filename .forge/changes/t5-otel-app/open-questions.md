# Open Questions — t5-otel-app

<!--
Tracking file per Article III.4 mechanisation
(`.forge/standards/global/open-questions.md`).
Q-NNN is sequential per change, zero-padded to 3 digits, never reused.
The change cannot be archived while any question is `Status: open`.
-->

## Q-001: Canonical Dart OTel package name + version + OTLP exporter sub-package?

- **Status**: answered
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

**Resolved by ADR-T5-OTA-001** (`design.md`). Canonical pub.dev pkg name :
`opentelemetry` (single bundled package — api + sdk + OTLP exporter
sub-imports under the same `package:opentelemetry/...` prefix consistent
with `flutter/opentelemetry.md` L17-19). Pin resolved at impl-time via
the T-VER-DART-001 deferred-pin pattern : `opentelemetry: ^0.18.0` +
`dio: ^5.7.0`. `flutter pub get` confirmed `opentelemetry 0.18.11` and
`dio 5.9.2` (recorded in `.forge/changes/t5-otel-app/_dart-pin.txt`
and `pubspec.yaml`). OTLP HTTP exporter sub-import path :
`package:opentelemetry/exporter_otlp_http.dart` (matches ADR-T5-OTA-002
HTTP/protobuf transport choice ; bundled in the same pkg, no separate
pub package).

---

## Q-002: OTLP transport — gRPC (port 4317) or HTTP/protobuf (port 4318) per layer?

- **Status**: answered
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

**Resolved by ADR-T5-OTA-002** (`design.md`). Both layers ship
**HTTP/protobuf** on port `4318`. Rust : `SpanExporter::builder().with_http()
.with_protocol(Protocol::HttpBinary).with_endpoint(...)`. Flutter :
`OtlpHttpSpanExporter`. Rationale : Flutter mobile constraints favour
HTTP/2 over HTTP transport ; symmetry across both layers simplifies adopter
mental-model ; no measurable perf gap at demo-005 scale. The deviation
from `rust/opentelemetry.md` § Setup snippet (which uses `with_tonic()`)
is documented inline in `bin-server/main.rs` and in
`crates/infrastructure/src/telemetry/mod.rs` module doc. The standard's
snippet is illustrative, not a hard pin.

---

## Q-003: SDK-side sampler — `AlwaysOn` or `ParentBased(TraceIdRatioBased(1.0))`?

- **Status**: answered
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

**Resolved by ADR-T5-OTA-003** (`design.md`). Option **B** —
`ParentBased(TraceIdRatioBased(1.0))` on both layers. Matches the
`observability.yaml::sampler: parentbased_traceidratio` standard name
literally ; respects the W3C `traceparent` `flags` bit for sampled-already
traces ; lets a future Phase D drop the SDK ratio (e.g. mobile-saver
mode at 0.1) by toggling one env var (`OTEL_TRACES_SAMPLER_ARG`) without
rewriting init code. Default ratio `1.0` ; the Phase A collector
`processors.probabilistic_sampler` enforces the env-tier ratio
downstream (dual-stage Phase A + Phase B model documented in
`t5-otel-stack/design.md` ADR-OTEL-001 "Consequences").

---

## Q-004: `flutter/opentelemetry.md` standard vs `opentelemetry: ^0.18.11` pub.dev pkg API drift

- **Status**: open
- **Raised in**: impl-time discovery (T-FE-009 / T-L2-002)
- **Raised on**: 2026-05-10
- **Raised by**: @bfontaine

### Question

The Dart `opentelemetry: ^0.18.11` pub.dev pkg shipped at impl-time has
a different public API surface than what `flutter/opentelemetry.md`
documents :

| Standard says | `0.18.11` actually exposes |
|---|---|
| `import 'package:opentelemetry/exporter_otlp_http.dart';` | NOT shipped — pkg has only `api.dart`, `sdk.dart`, `web_sdk.dart` |
| `OtlpHttpSpanExporter(OtlpHttpExporterConfig(...))` | undefined |
| `BatchSpanProcessor(exporter, BatchSpanProcessorConfig(...))` | `BatchSpanProcessorConfig` undefined ; ctor takes 1 positional arg only |
| `ParentBasedSampler(TraceIdRatioBasedSampler(1.0))` | `TraceIdRatioBasedSampler` undefined |
| `SpanStatusCode.ok / SpanStatusCode.error` | `SpanStatusCode` undefined |
| `setStatus(code, message: ...)` | param `description:` not `message:` |
| `Context.current.withSpan(...)` | deprecated, removed in `0.19.0` ; use `contextWithSpan` |

The L1 grep anchors are still GREEN (file presence + structural tokens
per the standard) ; the L2 `flutter analyze` test fails on
`undefined_identifier` / `uri_does_not_exist` errors per the table.

### Resolution

DEFERRED to `/forge:archive` triage. Two paths :

1. **Bump `flutter/opentelemetry.md`** to track the `0.18.x` actual API
   (single-pkg sub-imports collapsed into `api.dart` / `sdk.dart`,
   different exporter ctor names). Standards bump → REVIEW.md ledger
   entry → minor version bump on the standard.
2. **Pin a different pub.dev pkg** if a maintained fork matches the
   standard's documented API (e.g. `dartastic_opentelemetry`,
   `opentelemetry_api` if any exist with the documented surface).

L2 `_test_ota_l2_002_flutter_analyze` is gated to xfail until Q-004
is resolved. The L1 structural anchors do not regress — the impl
files exist with the right shape per the standard's intent ; only the
runtime API names need reconciliation.

This residual is captured rather than guessed (Article III.4) — the
ANTI-HALLUCINATION protocol forbids picking API names without
verification, and Context7 returned no Dart-specific docs index that
could verify them.
