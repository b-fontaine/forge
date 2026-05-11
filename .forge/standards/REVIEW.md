# Standards Review Ledger

This file is **append-only**. Every review event of a `.forge/standards/*.yaml`
file is recorded here as one H2 section, in chronological order. Removing or
amending a past entry is a Constitution violation (Article XII).

The schema for each entry :

```markdown
## YYYY-MM-DD — <one-line summary>

- **Reviewer**: @<github-handle>
- **Reviewed standards**: <table or list>
- **Decision**: KEEP | KEEP-WITH-CHANGES | REPLACE | DEPRECATE
- **Next review due**: <YYYY-MM-DD or "never (structural)">
- **Notes**: optional free text
```

Entries with `Next review due: never (structural)` are subject to Article XII
amendment process (see `.forge/standards/global/standards-lifecycle.md`
§Structural exception).

---

## 2026-05-04 — Initial ratification (t4-adr-ratification)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard               | Version | Decision | Next review due       | Notes                                               |
  |------------------------|---------|----------|-----------------------|-----------------------------------------------------|
  | transport.yaml         | 1.0.0   | KEEP     | never (structural)    | Structural exception per ADR-006 + ADR-009          |
  | state-management.yaml  | 1.0.0   | KEEP     | never (structural)    | Structural exception per ADR-006                    |
  | observability.yaml     | 1.0.0   | KEEP     | 2027-05-04            | OBI eBPF kernel ≥ 5.8 prerequisite                  |
  | orchestration.yaml     | 1.0.0   | KEEP     | 2027-05-04            | DBOS-rs maturity (< 1 year prod) to revisit         |
  | identity.yaml          | 1.0.0   | KEEP     | 2027-05-04            | Zitadel AGPL — confirm licensing fit at review      |
  | persistence.yaml       | 1.0.0   | KEEP     | 2027-05-04            | Citus sharding threshold review (~5 TB)             |

- **Decision**: All 6 standards ratified under Constitution v1.1.0 via change
  `t4-adr-ratification` (2026-05-04). Source : `docs/ARCHITECTURE-TARGET.md`
  ADRs 001 through 010 (sha256
  `cd8fef37ed01de981c8779a79d40234a70a4411387235dd990a86b705f3de925`).
- **Notes**: This is the **seed entry**. Future review events MUST follow
  the schema documented at the top of this file. The structural exceptions
  (`transport.yaml` and `state-management.yaml`) escape the 12-month
  expiry trigger but remain reviewable through Article XII Constitution
  amendments.

---

## 2026-05-05 — Updated transport.yaml to v1.1.0 (t5-connect-codegen)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard       | Version | Decision           | Next review due    | Notes                                                                                                  |
  |----------------|---------|--------------------|--------------------|--------------------------------------------------------------------------------------------------------|
  | transport.yaml | 1.1.0   | KEEP-WITH-CHANGES  | never (structural) | Added `codegen.connect_layout_version: 1` + `codegen.versions:` (11 pins) ; refreshed `codegen.tools:` |

- **Decision**: Updated by `t5-connect-codegen` (Phase 1 ARCHITECTURE-TARGET).
  Additive only — `exception_constitutional: true` preserved, no breaking
  change. Connect codegen plugins added to flagship `buf.gen.yaml` ; Rust
  adapter via `connectrpc` crate (Anthropic OSS) + Axum integration via
  `connectrpc::Router::into_axum_service()`.
- **Notes**: Two stale entries in the v1.0.0 `codegen.tools:` list were
  replaced per Context7 investigation 2026-05-05 :
  `protoc-gen-connect-es` (retired by Connect v2 — replaced by
  `@bufbuild/protoc-gen-es`) ; `protoc-gen-connect-dart-community`
  (skadero plugin abandoned 2022-09 — replaced by the official
  `connectrpc/connect-dart` plugin published by the ConnectRPC governance
  team). Five Rust pins added (`connectrpc`, `buffa`, `buffa-types`,
  `protoc-gen-connect-rust`, `protoc-gen-buffa` — all `=0.3.3` exact pin
  per ADR-T5-002 footnote pre-1.0 caveat). See
  `.forge/changes/t5-connect-codegen/design.md` ADR-T5-001 + ADR-T5-002
  for the full provenance trail.

---

## 2026-05-09 — Updated observability.yaml to v1.1.0 (t5-otel-stack)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard           | Version | Decision           | Next review due | Notes                                                                                                |
  |--------------------|---------|--------------------|-----------------|------------------------------------------------------------------------------------------------------|
  | observability.yaml | 1.1.0   | KEEP-WITH-CHANGES  | 2027-05-04      | Added `versions:` map with `beyla: "2.0.1"` + `coroot: "1.4.4"` — image pins per ADR-OTEL-002.       |

- **Decision**: Updated by `t5-otel-stack` (Phase 1 ARCHITECTURE-TARGET
  ADR-008 — infra side of the SigNoz + OBI eBPF + Coroot triplet on the
  full-stack-monorepo flagship). Additive only — `exception_constitutional:
  false` preserved, no breaking change. Symmetric with T.5
  `transport.yaml` 1.0.0 → 1.1.0 codegen-pinning pattern.
- **Notes**: Pins verified via Context7 review of `/grafana/beyla` and
  `/coroot/coroot` on 2026-05-08. Both > 30 days old per ADR-T5-002 #1
  criterion (no waiver needed). `observability.yaml::ebpf_complement:
  opentelemetry-obi` is satisfied by `grafana/beyla` per the upstream
  Grafana → OpenTelemetry donation lineage (binary-compatible).
  Realised by 6 K8s manifests + 3 overlay sampler-patches + Aegis docs
  in `templates/full-stack-monorepo/1.0.0/infra/`. T-VER-001 + T-VER-002
  drift verification at impl-time per the T.5 T-VER-006 pattern.

---

## 2026-05-05 — Correction note on the v1.1.0 entry above (t5-connect-codegen pivot)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard       | Version | Decision | Next review due    | Notes |
  |----------------|---------|----------|--------------------|-------|
  | transport.yaml | 1.1.0   | KEEP     | never (structural) | Textual correction only — no version bump, no spec change. |

- **Decision**: KEEP the previous v1.1.0 entry as-is (Article XII
  append-only). This entry corrects a textual drift in the previous
  Notes block introduced before the post-T-BUF pivot to Path α
  (`connectrpc-build` build-dep) on 2026-05-05.
- **Notes**: The previous entry's *Notes* section says
  *« Five Rust pins added (`connectrpc`, `buffa`, `buffa-types`,
  `protoc-gen-connect-rust`, `protoc-gen-buffa`) »*. After the T-BUF
  investigation pivoted to **Option 2 / Path α** (`connectrpc-build`
  via `build.rs` build-dependency rather than buf-driven local plugins,
  to preserve the codebase's "remote plugins only" convention — see
  `tasks.md::T-VER-006` evidence and the `fc41e49` commit), the
  effective Rust pin set in `transport.yaml::codegen.versions` is
  **four** entries : `connectrpc`, `buffa`, `buffa-types`,
  `connectrpc-build` (no `protoc-gen-connect-rust`, no
  `protoc-gen-buffa` — those local protoc plugins are not used). The
  previous entry's textual count and naming are stale relative to the
  shipped `transport.yaml` ; this corrective entry records the truth
  without amending the past entry. A `WAIVER 2026-05-05` comment was
  also added inline next to the `=0.3.3` pins in `transport.yaml` to
  document the 13-day age waiver of ADR-T5-002 #1 visibly to reviewers
  reading the standard alone.

---

## 2026-05-11 — Updated flutter/opentelemetry.md to v1.1.0 (t5-otel-dart-api-realign)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard                  | Version | Decision           | Next review due | Notes                                                                                                                                                                            |
  |---------------------------|---------|--------------------|-----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | flutter/opentelemetry.md  | 1.1.0   | KEEP-WITH-CHANGES  | 2027-05-04      | Realigned every OTel-SDK API name to the canonical pub.dev pkg `opentelemetry: 0.18.11` (Workiva). v1.0.0 was fabricated by cross-language transposition (JS / Java / Python). Resolves `t5-otel-app::Q-004`. |

- **Decision**: Updated by `t5-otel-dart-api-realign` (Q-004 follow-up
  to `t5-otel-app`). Documentation-only — the Phase A collector
  contract (HTTP/protobuf on `:4318`, parent-based sampler, W3C
  traceparent, batch processor with 5 s flush) is unchanged. Only
  the SDK-call shape in the snippets shifts to match the actual
  pub.dev API. `last_reviewed` resets to 2026-05-11 ; `Next review
  due` inherits the family's 2027-05-04 cadence (12 months from the
  v1.0.0 ratification on 2026-05-04, per `standards-lifecycle.md` §
  12-month review window — no structural exception).
- **Notes**: Canonical pkg `opentelemetry 0.18.11` (Workiva,
  Apache-2.0) verified 2026-05-11 via Context7
  (`/websites/opentelemetry_io` umbrella + WebFetch against
  `https://pub.dev/packages/opentelemetry/versions/0.18.11` and
  `https://github.com/Workiva/opentelemetry-dart`). Six fabricated
  identifiers + two fabricated sub-imports removed :
  `OtlpHttpSpanExporter`, `OtlpHttpExporterConfig`,
  `BatchSpanProcessorConfig`, `TraceIdRatioBasedSampler`,
  `SpanStatusCode`, `Context.current.withSpan(...)` method, the
  `setStatus(..., message:)` named-arg pattern, the
  `package:opentelemetry/exporter_otlp_http.dart` sub-import, and
  the `package:opentelemetry/exporter_otlp_grpc.dart` sub-import.
  Replaced by the verified `lib/api.dart` + `lib/sdk.dart` surface :
  `CollectorExporter(Uri)`, `BatchSpanProcessor(exporter,
  {maxExportBatchSize, scheduledDelayMillis})`,
  `ParentBasedSampler(AlwaysOnSampler())`, `StatusCode.{ok,error}`,
  the top-level `contextWithSpan(Context, Span)` function, and the
  positional `setStatus(StatusCode, [String description])`
  signature. Ratio-sampler semantics from
  `observability.yaml::sampler: parentbased_traceidratio` are
  realised collector-side via `processors.probabilistic_sampler`
  (per `t5-otel-stack` ADR-OTEL-001) because 0.18.11 does NOT ship
  a `TraceIdRatioBasedSampler` — documented in v1.1.0's new
  `## Sampling` section. Status callout `Traces: Beta / Metrics:
  Alpha / Logs: Unimplemented` (per Workiva README) added at the
  top of v1.1.0 ; v1.1.0 explicitly scopes to traces. The flip of
  `t5-otel-app.test.sh::_test_ota_l2_002_flutter_analyze` from
  xfail to GREEN is a follow-up commit on the `t5-otel-app` branch
  AFTER this change merges. See
  `.forge/changes/t5-otel-dart-api-realign/design.md` ADR-T5-FOTDA-001
  for the per-symbol citation table.

---

## 2026-05-12 — Initial ratification (i2-compliance-tiers)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard                   | Version | Decision | Next review due | Notes                                                                                       |
  |----------------------------|---------|----------|-----------------|---------------------------------------------------------------------------------------------|
  | global/compliance-tiers.md | 1.0.0   | KEEP     | 2027-05-11      | Initial ratification. Codifies EU compliance gradient T1/T2/T3 from ARCHITECTURE-TARGET §10. |

- **Decision**: KEEP
- **Next review due**: 2027-05-11
- **Notes**: New Markdown standard at `global/compliance-tiers.md`
  mirroring `.forge/schemas/compliance-tier.schema.json` v1.0.0
  (T.4) verbatim and `docs/ARCHITECTURE-TARGET.md` §10.2 byte-for-byte
  (15-row matrix). Resolves the Demeter forward-pointer (K.3,
  archived 2026-05-12) and unblocks I.3 (T3-forbidden linter rule),
  I.5 (`forge-compliance.yml` workflow), I.6 (regulatory artefacts —
  NIS2 / DORA / CRA / AI Act) per `docs/new-archetypes-plan.md`
  §7.1 line 727-729. `linter_rule: t3-forbidden-components` is a
  forward-pointer ; matching `constitution-linter.sh` section anchor
  ships with I.3. Three ADRs (ADR-I2-CT-001..003) resolve the
  design open questions. No constitutional amendment required ;
  Articles III.4, V, XI, XII compliance preserved.
