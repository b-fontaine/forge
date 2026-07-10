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

## 2026-05-11 — Initial ratification (i2-compliance-tiers)

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

---

## 2026-05-12 — Initial ratification (i6-compliance-artefacts)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard                              | Version | Decision | Next review due | Notes                                                                                       |
  |---------------------------------------|---------|----------|-----------------|---------------------------------------------------------------------------------------------|
  | global/compliance-artefacts-bundle.md | 1.0.0   | KEEP     | 2027-05-12      | Initial ratification. Documents the deterministic .tgz hand-off bundle for EU regulators.   |

- **Decision**: KEEP
- **Next review due**: 2027-05-12
- **Notes**: New standard at `global/compliance-artefacts-bundle.md`
  cross-linking the bundle script
  (`.forge/scripts/compliance/bundle.sh`), the DPA template
  (`.forge/templates/compliance/forge-dpa-declared.template`), and
  the audit-ledger snapshot generator (inline inside the bundle
  script). Consumes I.2 (tier matrix), K.3 (DPA ledger format
  ADR-K3-002), J.8 (`bin/forge-sbom.sh` CycloneDX 1.5 SBOM).
  Forward-stable for Themis-territory artefacts (NIS2 / DORA / CRA /
  AI Act) per FR-I6-CA-053. Three ADRs (ADR-I6-CA-001..003) resolve
  archive format (`.tgz` gzip POSIX tar), audit ledger placement
  (`audit/` subdirectory), and script location
  (`.forge/scripts/compliance/bundle.sh`). No constitutional
  amendment required ; Articles III.4, V, XI, XII compliance
  preserved.

---

## 2026-05-12 — Initial ratification (i3-t3-forbidden-linter)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard                                  | Version | Decision | Next review due | Notes                                                                                                                                     |
  |-------------------------------------------|---------|----------|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------|
  | global/forbidden-components-rules.md      | 1.0.0   | KEEP     | 2027-05-12      | Initial ratification. T3-RULE-NNN catalogue (7 seed rules) for the generic forbidden-components linter section ADR-I3-001.                |
  | global/compliance-tiers.md                | 1.0.0   | KEEP-WITH-CHANGES | 2027-05-11 | Frontmatter `enforcement: review` → `enforcement: ci` (forward-pointer resolved). Status note paragraph delta. Article IV.1 delta only.    |

- **Decision**: KEEP / KEEP-WITH-CHANGES
- **Next review due**: 2027-05-12 (new standard) ; 2027-05-11
  (compliance-tiers.md unchanged from I.2 birth)
- **Notes**: New Markdown standard `global/forbidden-components-rules.md`
  catalogues T3-RULE-001..007 (FR-I3-T3F-120..126 ; ADR-I3-002).
  Resolves the `linter_rule: t3-forbidden-components` forward-pointer
  shipped by I.2 on 2026-05-12. Four ADRs (ADR-I3-001..004) resolve
  the design open questions. The
  `constitution-linter.sh::ADR-I3-001 section` is the **first** Forge
  generic enforcement surface of Article XII §enforce on standards'
  `forbidden:` blocks beyond the hard-coded ADR-006 NSMA section
  (`f4-linter-extension`). Sibling rule-catalogue to
  `global/janus-orchestration-rules.md` (J.8) and
  `global/data-stewardship-rules.md` (K.3) ; T3-RULE-NNN namespace
  inherits ADR-J8-004 numbering invariant. Tier-scaled severity per
  ADR-I3-003 (T1/T2 → WARN Phase A ; T3 → FAIL). Phase A → B flip
  at B.8 (T6) via SemVer minor bump 1.0.0 → 1.1.0. No
  constitutional amendment required ; Articles III.4, V, XI, XII
  compliance preserved.

---

## 2026-05-12 — Initial ratification (i5-compliance-workflow)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard                                  | Version | Decision | Next review due | Notes                                                                                                                              |
  |-------------------------------------------|---------|----------|-----------------|------------------------------------------------------------------------------------------------------------------------------------|
  | global/forge-compliance-workflow.md       | 1.0.0   | KEEP     | 2027-05-12      | Initial ratification. Documents the reusable `.github/workflows/forge-compliance.yml` workflow contract for adopter repos.         |

- **Decision**: KEEP
- **Next review due**: 2027-05-12
- **Notes**: New Markdown standard at
  `global/forge-compliance-workflow.md` documenting the I.5 reusable
  GitHub Actions workflow `.github/workflows/forge-compliance.yml`.
  The workflow is triggered by `on: workflow_call:` and exposes three
  inputs (`eu-tier` required ; `target-dir` default `.` ;
  `artefact-name` default `forge-compliance-artefacts`) and one output
  (`artefact-path`). It orchestrates the four EU-compliance scripts
  shipped by I.3 (`constitution-linter.sh::ADR-I3-001 T3-Forbidden
  Components` section), I.6 (`.forge/scripts/compliance/bundle.sh`),
  K.3 (`bin/forge-demeter-scan.sh`), and J.8.d (`bin/forge-sbom.sh`),
  uploading the deterministic `.tgz` via
  `actions/upload-artifact@v4`. Three ADRs (ADR-I5-CW-001..003) lock
  the exit-code aggregation envelope (trust each script's tier
  scaling end-to-end ; SBOM no-lockfile non-fatal),
  `SOURCE_DATE_EPOCH` source (commit timestamp with run-start
  fallback ; no `inputs.epoch`), and L2 act-runner gating (opt-in
  `FORGE_I5_ACT=1` with skip-when-absent semantics mirroring the
  `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1` precedent).
  Forward-stable for Themis-territory regulatory deadline steps
  (NIS2 / DORA / CRA / AI Act) when K.5 (T7+) ships — additive
  expansion. `linter_rule: null` (advisory standard ; the workflow
  itself is the enforcement surface). No constitutional amendment
  required ; Articles III.4, V, XI, XII compliance preserved.

## 2026-05-16 — Updated transport.yaml to v1.2.0 (t5-cargo-pin-refresh)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard       | Version | Decision           | Next review due | Notes                                                                                                                                                                            |
  |----------------|---------|--------------------|-----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | transport.yaml | 1.2.0   | KEEP-WITH-CHANGES  | never (structural) | 1.1.0 → 1.2.0 : corrected `buffa` + `buffa-types` pins from invalid `=0.3.3` (never published) to `=0.3.0` (only resolvable version of their 0.3 series). `connectrpc` and `connectrpc-build` unchanged at `=0.3.3` (valid). |

- **Decision**: Updated by `t5-cargo-pin-refresh` (T5.1.E,
  ADR-T5CPR-001..003). The original `t5-connect-codegen`
  (2026-05-06) pinned all four `connectrpc` family crates at
  `=0.3.3` under the assumption that `buffa` / `buffa-types` shared
  the release cadence of `connectrpc`. That assumption was wrong :
  `buffa` series 0.3.x stops at 0.3.0 on crates.io (verified
  2026-05-16 via the REST API at `https://crates.io/api/v1/crates/buffa`
  and `…/buffa-types`). `connectrpc 0.3.3` declares
  `buffa = "^0.3"` (verified via
  `https://crates.io/api/v1/crates/connectrpc/0.3.3/dependencies`),
  so `=0.3.0` is the unique resolvable exact pin satisfying that
  constraint.
- **Notes**: Additive minor bump per ADR-T5CPR-002 — the pin
  correction is **corrective** (the previous pin never resolved,
  hence adopters with `=0.3.3` had a non-buildable Cargo manifest)
  not breaking. WAIVER comment block rewritten per ADR-T5CPR-003
  to separate WAIVER (connectrpc / connectrpc-build at `=0.3.3`,
  still pedigree-justified per the original 13-day age waiver) from
  CORRECTION (buffa / buffa-types at `=0.3.0`, error-of-fact fix
  documented inline). Modernisation of the entire `connectrpc`
  family to 0.4.x / 0.5.x / 0.6.x is deferred to B.8 (T6) where
  the broader Connect story is re-evaluated alongside the
  Kong → Envoy flagship migration. RED witness for this change :
  `task validate` 2026-05-16 (cli-trust-harness
  `archetypes-smoke.test.ts` with `FORGE_E2E_TOOLCHAINS=1`).
  `last_reviewed` resets to 2026-05-16 ; `Next review due` stays
  `never (structural)` per ADR-006/ADR-009 (Article XII
  structural exemption preserved). No constitutional amendment.

## 2026-05-18 — standards-lifecycle.md v1.0.0 → v1.1.0

- **Change**: `t5-2-platform-verification`
- **Status**: implemented
- **Trigger**: **Q-006** — Workiva `opentelemetry 0.18.11` ratified
  2026-05-12 (`t5-otel-dart-api-realign`) despite being web-only on
  pub.dev, discovered 2026-05-16 during `cli-trust-harness` Option B
  validation. Q-004 (9 fabricated symbols) had already exposed the
  ratification process gap on Axis 2 ; Q-006 exposed the gap on
  Axis 3 (platform compatibility).
- **Anchor**: new H2 `## Platform compatibility re-verification`
  appended to `.forge/standards/global/standards-lifecycle.md` ;
  cross-references the Forge-local
  `.claude/agents/document-specialist.md` §
  `Platform Verification Checklist (3-axis)` verbatim per
  **ADR-T52-003** drift guard.
- **breaking_change**: false — strictly additive bump. The existing
  H2 sections (Purpose / Frontmatter / 12-month review window /
  Structural exception / Themis hook / Linter integration /
  Automated enforcement) remain byte-identical. The new H2 only
  appends cadence rules for re-verification of external
  dependency-pinning standards.
- **Frontmatter**: this bump also introduces the explicit YAML
  frontmatter block at the top of the standard (the file was
  authored pre-J.7 convention and never carried an explicit
  `version:` field — v1.0.0 was implicit). `version: 1.1.0`,
  `last_reviewed: 2026-05-18`, `expires_at: never`,
  `exception_constitutional: true` (structural exemption preserved
  per ADR-006/ADR-009).
- **Notes**: Cadence introduced — SHOULD at 12-month review, MUST
  on new target platform addition, MUST before first ratification
  of any external dependency-pinning standard. Article III.4
  reinforcement, not amendment. The Workiva → Dartastic
  substitution itself is out of scope here — it ships in T5.3
  (`t5-otel-dartastic-realign`) and will be the first consumer
  ticking the 3-axis checklist inline. RED witness for this
  change : `t5-2.test.sh --level 1` showed 0/8 PASS before the
  agent file + this bump landed ; GREEN witness shows 8/8 PASS
  after.

## 2026-05-18 — Updated flutter/opentelemetry.md to v2.0.0 (t5-otel-dartastic-realign)

- **Change**: `t5-otel-dartastic-realign`
- **Status**: implemented
- **Trigger**: **Q-006** (re-opened Q-004) — Workiva
  `opentelemetry 0.18.11` ratified by `t5-otel-dart-api-realign`
  v1.1.0 (2026-05-12) was discovered 2026-05-16 to be **web-only**
  on pub.dev. The consuming archetypes (`mobile-only` first class
  Android+iOS ; `full-stack-monorepo` frontend Flutter mobile+web)
  cannot use a web-only OTel SDK. Resolved by substitution Workiva
  → Dartastic.
- **Bump**: v1.1.0 → v2.0.0. **breaking_change: true**.
- **Inaugural 3-axis checklist application** : this change is the
  FIRST consumer of the T5.2 platform-verification checklist
  (`.claude/agents/document-specialist.md` §
  `Platform Verification Checklist (3-axis)`, archived 2026-05-18).
  The 3 Dartastic packages were verified inline against all 3 axes
  (existence + API surface + platform compatibility) before
  ratification. Result : no `[PLATFORM MISMATCH:]` markers raised
  — the substitution satisfies every consuming archetype.
- **WAIVER (ADR-T53-002)** : `dartastic_opentelemetry_api`
  transitively pins at `^1.0.0-beta.2` (constraint declared by SDK
  1.1.0-beta.6). At ratification time the latest published prerelease on
  pub.dev was `1.0.0-beta.7` ; pub solver resolves to that
  automatically given the caret constraint. The stable 0.9.0 line
  is incompatible with SDK 1.1.0-beta.6. Upgrade trigger named :
  `t5-3-1-dartastic-api-ga-refresh` (file a follow-up patch when
  `_api 1.0.0` GA ships). Pattern verbatim from `transport.yaml
  v1.2.0` WAIVER (`t5-cargo-pin-refresh` precedent).
- **flutterrific shim primary (ADR-T53-001)** : the integration
  path uses `flutterrific_opentelemetry 0.4.0` for
  auto-instrumentation (route observer / lifecycle / errors).
  Option B fallback (pure `dartastic_opentelemetry` Dart SDK with
  custom Flutter wiring) is documented in the standard's
  "Migration off flutterrific" subsection.
- **Sampling preserved (ADR-T53-004)** : the Phase A (collector
  `processors.probabilistic_sampler` per ADR-OTEL-001) + Phase B
  (SDK `ParentBasedSampler(AlwaysOnSampler())`) dual-stage model
  is preserved verbatim across the substitution. Collector
  contract unchanged (OTLP HTTP/protobuf on `:4318`).
- **Forward-pointers (ADR-T53-003)** : 3 archived changes
  (`b4-mobile-only`, `t5-otel-app`, `t5-otel-dart-api-realign`)
  carry a new `.forge-update-notes` file documenting that their
  Workiva pin has been superseded by Dartastic in T5.3. Existing
  archived files remain byte-identical (Article V immutability).
- **Constitutional anchor** : Article III.4 (Ambiguity Protocol —
  anti-hallucination) + Article IX (Observability). The standard
  cites these verbatim ; the harness asserts the literal `Article
  III.4` string is present (T5.2 self-validation lesson applied —
  no fabricated constitutional citations).
- **Implementation evidence** : `t5-otel-dartastic.test.sh --level 1`
  L1 13/13 GREEN ; L2 opt-in (`FORGE_T53_LIVE=1`) runs
  `flutter pub get` + `flutter analyze` on FSM frontend + fresh
  mobile-only scaffold ; `verify.sh` + `constitution-linter.sh` +
  `t5-1.test.sh::ci_line_budget` (forge-ci.yml ≤ 300) preserved.
  Independent code-reviewer pass (per T5.2 self-validation lesson
  / NFR-T53-010) executed pre-archive.

---

## 2026-05-25 — Updated observability.yaml to v1.2.0 (b8-coroot-rehost)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard           | Version | Decision           | Next review due | Notes                                                                                                                                          |
  |--------------------|---------|--------------------|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------|
  | observability.yaml | 1.2.0   | KEEP-WITH-CHANGES  | 2027-05-04      | Bumped `versions.coroot` `1.4.4` → `1.20.2` ; host migrated `docker.io/coroot/coroot` → `ghcr.io/coroot/coroot` (no v-prefix per ADR-B8-COR-001 — inverted at impl after L2 manifest-pull caught proposal's mis-read). |

- **Decision**: Updated by `b8-coroot-rehost` (pilot of the
  `b8-observability-rearch` trio, B.8.8 in
  `docs/new-archetypes-plan.md` §4.2). Additive only —
  `exception_constitutional: false` preserved, no breaking change.
- **Notes**: Coroot host migration surfaced 2026-05-24 by verify-then-pin
  pass institutionalised after T5.3.2 ABANDONED. `docker manifest
  inspect coroot/coroot:1.4.4` returns `denied: requested access to
  the resource is denied / unauthorized: authentication required` ;
  `docker manifest inspect ghcr.io/coroot/coroot:1.20.2` returns a
  valid multi-arch OCI index (amd64 + arm64). The early proposal of
  this change claimed v-prefix mandatory on GHCR — that was an
  inverted verify-then-pin transcript (background-task outputs
  mis-labelled during `/forge:explore`), caught at `/forge:implement`
  Phase 6 by the L2 manifest-pull fixture, which failed against
  `ghcr.io/coroot/coroot:v1.20.2` ("manifest unknown") and passed
  against the unprefixed `1.20.2`. The true convention is **uniform
  no-v-prefix** across `versions.*` — Coroot on GHCR and Beyla on
  Docker Hub both accept the unprefixed form. Pin convention note
  inline above `versions:` block documents the registry migration
  + the no-v-prefix discovery with a pointer to
  `.forge/changes/b8-coroot-rehost/evidence.md` § 1 for the corrected
  transcripts. ADR-B8-COR-001 rewritten 2026-05-25 (original draft
  preserved in git history per Article V). `rationale:` block
  extended with Coroot CE jurisdiction posture per ADR-B8-COR-004
  (Coroot Inc US-incorporated but CE is Apache-2.0 with no upstream
  phone-home — T1/T2 OK, T3 SHOULD flag candidate-substitution at
  deployment-time Demeter pass ; no new K.3 rule in this sub-change).
  Realised by 4 manifest copies (canonical .tmpl + cli bundle .tmpl
  + example rendered + cli bundle example) all carrying the new pin
  + audit comment + `forge.dev/standard: "observability.yaml@1.2.0"`
  annotation bump. Harness `b8-coroot.test.sh --level 1` 13/13 GREEN
  + L2 opt-in (`FORGE_B8_COROOT_DOCKER=1`) asserts manifest pullable
  + `--config` flag valid + verify-then-pin invariant
  (`docker.io/coroot/coroot:1.4.4` still denied).

---

## 2026-05-26 — ARCH-CHANGE observability.yaml v1.2.0 → v2.0.0 (b8-signoz-unified)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard           | Version | Decision    | Next review due | Notes                                                                                                                                                                            |
  |--------------------|---------|-------------|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | observability.yaml | 2.0.0   | ARCH-CHANGE | 2027-05-26      | BREAKING. SigNoz 3-svc → unified arch : ADD versions.{signoz "v0.125.1", signoz_otel_collector "v0.144.4", clickhouse "25.5.6", signoz_zookeeper "3.7.1"} ; new top-level `pin_review_cadence:` (ISO 8601, ADR-J7-004 additive) ; `breaking_change: true`. Beyla stays 2.0.1 pending trio sibling 3. |

- **Decision**: ARCH-CHANGE (NOT Updated). Updated by `b8-signoz-unified`
  (sibling 2 of the `b8-observability-rearch` trio, B.8.8 in
  `docs/new-archetypes-plan.md` §4.2). This is the **first** use of the
  `ARCH-CHANGE` ledger flag, introduced here to semantically distinguish a
  breaking architectural shift on a ratified standard from a `Updated`
  version refresh (FR-B8-SIG-H-006 precedent). The shift is BREAKING (major
  bump v1.2.0 → v2.0.0) because SigNoz upstream collapsed the 3-service
  architecture into the unified `signoz/signoz` + `signoz/signoz-otel-collector`
  layout — a structural rearch, not a version refresh.
- **Next review due**: 2027-05-26 (12-month window from `last_reviewed:
  2026-05-26`, preserving `expires_at > last_reviewed` per FR-J7-021).
- **Notes**: SigNoz migration surfaced by the institutionalised
  verify-then-pin pass — the old 3-service pins (`signoz/frontend:0.55.1`,
  `signoz/query-service:0.55.1`) rotted on Docker Hub (`docker manifest
  inspect` → "no such manifest", re-confirmed live 2026-05-27). The 4 unified
  pins (`signoz/signoz:v0.125.1` amd64 sha256:e56541… / arm64 sha256:f2e0ce… ;
  `signoz/signoz-otel-collector:v0.144.4` amd64 sha256:9b2cc1… / arm64
  sha256:42727e… ; `clickhouse/clickhouse-server:25.5.6` amd64 sha256:5dcbe5… /
  arm64 sha256:03c712… ; `signoz/zookeeper:3.7.1` amd64 sha256:1e6c92… / arm64
  sha256:a123ea…) are all `docker manifest inspect` exit-0 multi-arch
  (evidence.md § 2). The new top-level `pin_review_cadence:` field uses ISO
  8601 durations (P30D / P12M) and needs **no** `standard.schema.json` edit —
  the schema declares `additionalProperties: true` at root per **ADR-J7-004**
  (the schema-location + additionalProperties policy in
  `j7-validate-standards-yaml/design.md`), NOT ADR-J7-008 which the frozen
  proposal/specs mis-cited. `breaking_change: true` marker added to the
  frontmatter as the machine-readable signal. WAIVER block added to the
  standard frontmatter citing `standards-lifecycle.md` § Bumps + ADR-J7-004.
  SigNoz CE jurisdiction posture extended in `rationale:` per ADR-B8-SIG-006
  (SigNoz Inc Delaware-incorporated, US ; CE self-host T1/T2 OK ; T3
  candidate-substitution flag at deployment-time Demeter pass ; SigNoz Cloud
  out of scope). `forbidden:` list UNCHANGED (SigNoz NOT added) ;
  `linter_rule: null` UNCHANGED ; no new K.3 rule ; no `cloud-act-publishers.yml`
  entry ; `versions.beyla` UNCHANGED at 2.0.1 (NFR-B8-SIG-011 trio coupling —
  the Beyla 2.0.1 → 3.15.0 major bump is **reserved** for trio sibling 3
  `b8-obi-refresh`, FR-B8-SIG-J-001/-J-002). Realised across 6 docker-compose
  mirror copies (canonical .tmpl + cli-bundle .tmpl + example-side .tmpl +
  cli-bundle example .tmpl + rendered example + cli-bundle rendered example)
  all carrying the 4 unified pins + 6-service layout (4 long-running + 2
  init) + audit comment. Harness `b8-signoz.test.sh --level 1` 17/17 GREEN +
  L2 opt-in (`FORGE_B8_SIGNOZ_DOCKER=1`) asserts the 4 manifests multi-arch
  pullable + compose-up healthy + rotted 3-svc pins denied. `a7.test.sh`
  29/29 PASS preserved across the breaking bump.

---

## 2026-05-29 — Updated observability.yaml to v2.1.0 (b8-obi-refresh)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard           | Version | Decision | Next review due | Notes                                                                                                                                                                                                                                              |
  |--------------------|---------|----------|-----------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | observability.yaml | 2.1.0   | Updated  | 2027-05-29      | Additive minor bump (`b8-obi-refresh` — trio sibling 3 closure). versions.beyla 2.0.1 → 3.15.0 (no v-prefix). ClusterRole RBAC WIDENED — `services` resource added per Beyla 3.x docs (ADR-B8-OBI-003). Caps + kernel-58 UNCHANGED. `breaking_change: false` flipped back from sibling 2 ARCH-CHANGE state. |

- **Decision**: Updated (NOT ARCH-CHANGE). This entry closes the
  `b8-observability-rearch` trio (Coroot leg 1 v0.4.0-rc.3 → SigNoz leg 2
  v0.4.0-rc.4 → OBI leg 3 v0.4.0-rc.5). The bump is additive : single
  versions.beyla string change + read-only ClusterRole resource widening +
  rationale extension. No new top-level fields, no schema surgery, no
  WAIVER. Article XII compliance preserved per standards-lifecycle.md
  § Bumps additive-only default.
- **Next review due**: 2027-05-29 (12-month window from `last_reviewed:
  2026-05-29`, preserving `expires_at > last_reviewed` per FR-J7-021).
- **Notes**: Beyla 3.15.0 multi-arch (amd64+arm64) verified live via
  `docker manifest inspect grafana/beyla:3.15.0` 2026-05-29 (digests
  captured in `.forge/changes/b8-obi-refresh/evidence.md` § 1 :
  amd64 sha256:8ff0dcb4aa31fab39ba0b40715d0c0441d4522b43fb7886768ec280cc401dd69
  + arm64 sha256:ac770096bcb51bde0a810a1ef5009ddaed5b3b08dacdec856cccd1be6e65e30d
  + 2 attestation manifests `unknown/unknown` cosign/SLSA).
  Aegis re-audit (ADR-B8-OBI-002/003/004) : 8-cap distributed-traces
  set UNCHANGED per Beyla 3.x docs/distributed-traces.md (Forge flagship
  enables W3C traceparent E2E ⇒ NET_ADMIN required + SYS_ADMIN
  recommended) ; ClusterRole apiGroups:[""] resources widened from
  {pods, nodes} → {pods, nodes, services} per Beyla 3.x docs/cilium-
  compatibility.md (read-only verbs only, least-privilege invariant
  preserved) ; kernel floor 5.8 UNCHANGED per Beyla 3.x README
  Requirements. Realised across 4 mirror copies (canonical .tmpl +
  cli-bundle .tmpl + rendered example + cli-bundle rendered example,
  byte-identical). Harness `b8-obi.test.sh --level 1` 22/22 GREEN +
  L2 opt-in (`FORGE_B8_OBI_DOCKER=1`) asserts the 3.15.0 manifest
  multi-arch pullable. `a7.test.sh` 29/29 PASS preserved across the
  bump. Sibling harnesses updated per ADR-B8-OBI-006 hybrid : narrow
  `t5-otel.test.sh:128/233` (pin ownership transferred to
  b8-obi.test.sh), widen `b8-coroot.test.sh:196` + `b8-signoz.test.sh:295`
  date regex `2026-05-2[6789]`. `forge-ci.yml` compressed by 3 trim-
  comments per ADR-B8-OBI-007 ; matrix registered ; stays at 300/300
  (NFR-CI-002 plafond preserved).

## 2026-05-30 — Updated upgrade-policy.md (snapshot maintenance-freeze, b8-2-legacy-snapshot)

  | Standard          | Version | Status  | Next review due | Notes |
  |-------------------|---------|---------|-----------------|-------|
  | global/upgrade-policy.md | n/a (stage: stable, no semver) | Updated | 2027-05-30 | Additive section "## Snapshot maintenance-freeze (point-of-no-return migrations)". No `version:` frontmatter on this markdown standard → section addition only, no semver increment. |

- **Decision**: Updated by `b8-2-legacy-snapshot` (B.8.2). Codifies the
  freeze of `full-stack-monorepo / 1.0.0` as the frozen reverse target for
  `forge upgrade` ahead of the 1.0.0 → 2.0.0 point of no return.
- **Rationale**: The version-keyed BASE-recovery path
  (`.forge/scaffold-snapshots/<archetype>/<from_version>.tar.gz`, read by
  `forge-upgrade.sh`) is the legacy archive — there is **no `legacy/`
  directory** (ADR-B8-2-001, reconciling plan §4.2 wording with the live
  mechanism). A committed sibling manifest `1.0.0.sha256`
  (`1d0b05cd…cd45`) pins the frozen tarball ; the harness
  `b8-2.test.sh --level 1` FAILS if it drifts (rebuilt / corrupted /
  accidentally overwritten with 2.0.0 content). The 2.0.0 snapshot MUST
  build to a new `2.0.0.tar.gz` file. A deliberate audited 1.0.0 patch
  updates tarball + manifest + this ledger together. The tarball itself was
  **not rebuilt** (ADR-B8-2-005 — SOURCE_DATE_EPOCH would churn bytes for no
  gain) ; the frozen artifact is the rc.6 1.0.0-final that `a7.test.sh`
  already exercises (29/29 PASS preserved). Flagship-only ; `mobile-only /
  1.0.0` freeze deferred to B.9 (ADR-B8-2-004).

## 2026-05-30 — AUDITED PATCH to frozen 1.0.0 snapshot (dev:up dead-pin hygiene)

  | Artifact | Old | New | Notes |
  |----------|-----|-----|-------|
  | `full-stack-monorepo/1.0.0.tar.gz` | sha `1d0b05cd…cd45` | sha `8d439b94…4ca9` | Regenerated after the dead-pin/healthcheck fix below. |
  | `full-stack-monorepo/1.0.0.sha256` | `1d0b05cd…` | `8d439b94…` | Manifest updated in lockstep (B.8.2 audited-patch protocol). |

- **Decision**: AUDITED PATCH to the frozen `full-stack-monorepo / 1.0.0`
  reverse target — the exact carve-out the B.8.2 maintenance-freeze section
  allows ("a deliberate, audited 1.0.0 patch updates tarball + manifest +
  this ledger together; the guard catches accidental drift, not audited
  bumps").
- **Rationale**: `task dev:up` failed on a fresh 1.0.0 scaffold (surfaced by
  `task validate` dev-up-matrix). Two dead-pin / placeholder bugs fixed in
  `docker-compose.dev.yml(.tmpl)` across all 6 mirror copies:
  (1) `kong:3.6-alpine` → `kong:3.6` — Kong dropped the `-alpine` suffix
  (`manifest unknown` ; verify-then-pin per b8-coroot lesson, `kong:3.6`
  confirmed live). (2) `fsm-backend` placeholder `traefik/whoami:v1.11.0` is
  FROM scratch (no shell/curl) so its `CMD-SHELL curl` healthcheck always
  errored → never healthy → `fsm-kong` (depends_on service_healthy) blocked.
  Fixed: healthcheck `disable: true` + `fsm-kong` depends_on `fsm-backend`
  → `condition: service_started`. (3) Bonus drift fixed — the two rendered
  examples were stale pre-T5.3.1 (`image: scratch`, which cannot run at
  all) ; synced to the template (whoami). Verified GREEN: `task dev-up-matrix`
  `[PASS] full-stack-monorepo : dev:up`, then full `task validate` →
  "ALL CHECKS GREEN". `b8-2.test.sh` sha guard re-points at the new manifest ;
  `a7.test.sh` extract preserved.

---

## 2026-05-31 — Initial ratification (b8-4-envoy-gateway)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard     | Version | Decision | Next review due | Notes |
  |--------------|---------|----------|-----------------|-------|
  | gateway.yaml | 1.0.0   | KEEP     | 2027-05-31      | First *.yaml gateway pin source (pin_source: B.8.4 born here). Envoy Gateway chart v1.8.0 + Gateway API CRD bundle v1.5.1 verify-then-pin (resolved live 2026-05-31, evidence.md). BackendTLSPolicy GA at gateway.networking.k8s.io/v1 as of GW-API v1.5.1 — all four resources use GA v1 (no v1alpha3/v1beta1). controllerName gateway.envoyproxy.io/gatewayclass-controller. |

- **Decision**: KEEP
- **Next review due**: 2027-05-31
- **Notes**: New standard `.forge/standards/gateway.yaml` (ROOT-level — required
  by the non-recursive J.7 gate, ADR-B84-002). Realised by the
  `2.0.0/infra/k8s/envoy-gateway/` template tree (additive-first, Envoy ∥ Kong,
  HTTPRoute → `fsm-backend`). The `2.0.0.yaml` `envoy-gateway` component flips
  `pin_source: B.8.4` → `standard: gateway.yaml`. No constitutional amendment
  (VIII.1 Kong SHALL preserved; amendment deferred to B.8.14). Concrete pins
  verify-then-pin LIVE at implement (Article III.4) — `helm`/OCI for the chart
  (v1.8.0), EG v1.8.0 `go.mod` for the bundle (v1.5.1), Context7 for the GA `v1`
  apiVersion + the Envoy controllerName. Evidence:
  `.forge/changes/b8-4-envoy-gateway/evidence.md`.

---

## 2026-05-31 — Updated orchestration.yaml to v1.1.0 (b8-5-postgres-pgvector)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard           | Version | Decision           | Next review due | Notes                                                                                                                                                                                                                                                                                                                                                                  |
  |--------------------|---------|--------------------|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | orchestration.yaml | 1.1.0   | KEEP-WITH-CHANGES  | 2027-05-31      | Additive. Added `rust_sdk_status.dbos` block recording DBOS has NO Rust SDK (crates.io dbos 404; DBOS Transact = Python/TypeScript/Go/Java only — Context7 docs.dbos.dev). Temporal RETAINED for the Rust flagship (Article VIII.2 preserved). `default: dbos` UNCHANGED — recorded as a language-conditional aspirational non-Rust target, not a deployed Rust default. Closes the seed-entry "DBOS-rs maturity to revisit" concern. |

- **Decision**: KEEP-WITH-CHANGES
- **Next review due**: 2027-05-31
- **Notes**: Updated by `b8-5-postgres-pgvector` (B.8.5). Additive minor bump
  mirroring `transport.yaml` 1.0.0 → 1.1.0. `exception_constitutional: false`
  preserved (dated expiry, FR-J7-020); `last_reviewed` resets to 2026-05-31,
  `expires_at` to 2027-05-31 (FR-J7-021 ordering). The DBOS-Rust-absent finding
  was verified 2026-05-31 (Context7 `docs.dbos.dev`; crates.io `dbos` 404). No
  constitutional amendment — Article VIII.2 (Temporal SHALL) is PRESERVED by
  retaining Temporal (a compliance positive over the abandoned DBOS plan, which
  would have replaced Temporal and thus needed the B.8.14 VIII.2 amendment).
  Evidence: `.forge/changes/b8-5-postgres-pgvector/evidence.md`.

---

## 2026-06-01 — Updated orchestration.yaml to v1.2.0 (b8-orchestration-temporal-realign)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard           | Version | Decision          | Next review due | Notes                                                                                                                                                                                                                                                                                                                                       |
  |--------------------|---------|-------------------|-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | orchestration.yaml | 1.2.0   | KEEP-WITH-CHANGES | 2027-05-31      | Additive. Reconciles the default with Constitution §VIII.2 (Temporal). Replaces flat `default: dbos`/`fallback`/`fallback_trigger` with `default_by_language: { rust: temporal }`; folds the v1.1.0 `rust_sdk_status.dbos` facts into a `dbos:` watch-list `future-option` block (`available: false`); adds a `temporal:` crate-family block (`temporalio-sdk`, `stability: pre-alpha` — NO version, verify-then-pin downstream). ADR-002's Temporal→DBOS swap CANCELLED for Rust (ADR-B8O-001). |

- **Decision**: KEEP-WITH-CHANGES
- **Next review due**: 2027-05-31
- **Notes**: Updated by `b8-orchestration-temporal-realign` (B.8.5 follow-on).
  Additive minor bump (transport.yaml precedent). `exception_constitutional: false`
  preserved (dated expiry, FR-J7-020); `last_reviewed` resets to 2026-06-01,
  `expires_at` 2027-05-31 (FR-J7-021 ordering). **No constitutional amendment** —
  §VIII.2 already mandates Temporal, so making Temporal the Rust default ALIGNS the
  standard with the Constitution (contrast B.8.4 VIII.1 Kong→Envoy, which needs a
  deferred amendment). DBOS demoted from default to a watch-list future-option, NOT
  deleted — re-evaluate if a production-grade Rust DBOS SDK ships. Crate verify-then-pin
  (LIVE 2026-06-01): `temporalio-sdk = 0.4.0` (crates.io), API realigned in
  `infra/temporal.md`. Evidence:
  `.forge/changes/b8-orchestration-temporal-realign/evidence.md`.

---

## 2026-06-02 — Updated transport.yaml to v1.3.0 (b8-6-connect-rpc)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard       | Version | Decision          | Next review due | Notes |
  |----------------|---------|-------------------|-----------------|-------|
  | transport.yaml | 1.3.0   | KEEP-WITH-CHANGES | never           | Additive. Added `codegen.versions_2_0_0` block with the modernized 2.0.0-line Rust Connect crate pins (connectrpc / connectrpc-build `=0.6.1`, buffa / buffa-types `=0.6.0` — driven by connectrpc 0.6.1's `buffa = "^0.6"` constraint; 0.7.0 out-of-range). connect-go bumped `1.19.2 → 1.20.0` (BSR-confirmed) in the 2.0.0 sub-block only. Fixed the stale "v1.1.0" header drift. 1.0.0-line pins (`codegen.versions`) byte-unchanged. No breaking change. |

- **Decision**: KEEP-WITH-CHANGES
- **Next review due**: never (exception_constitutional: true — structural, Article XII)
- **Notes**: Updated by `b8-6-connect-rpc` (B.8.6). Additive minor bump
  (transport.yaml 1.2.0 → 1.3.0). `exception_constitutional: true` preserved
  (`expires_at: never`); `last_reviewed` resets to 2026-06-02. No constitutional
  amendment — `protocol: connect-rpc`, `fallback: grpc-web`, `server_runtime`, and
  the existing `codegen.versions` map are all unchanged. The new `versions_2_0_0`
  block is a sibling of the existing `versions:` map under `codegen:`, separately
  addressable per schema version (ADR-B86-005) — the 1.0.0 flat templates resolve
  `versions:`, the 2.0.0 subtree resolves `versions_2_0_0:`. Rust pins verified
  LIVE 2026-06-02 (evidence.md P-12; final re-verify clause ADR-B86-001 /
  b8-coroot lesson); connect-go BSR `v1.20.0` availability confirmed live
  (evidence.md P-13). The connectrpc family stays pre-1.0 (0.6.x) — a WAIVER
  comment block records the re-review trigger at the 1.0 milestone. Realised
  alongside the `2.0.0/shared/protos/` + `2.0.0/backend/crates/grpc-api/` template
  subtree. Evidence: `.forge/changes/b8-6-connect-rpc/evidence.md`.

---

## 2026-06-02 — Updated identity.yaml to v1.1.0 (b8-7-zitadel)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard       | Version | Decision          | Next review due | Notes |
  |----------------|---------|-------------------|-----------------|-------|
  | identity.yaml  | 1.1.0   | KEEP-WITH-CHANGES | 2027-06-02      | Additive. First `versions:` map (Zitadel chart 10.0.2 / app v4.14.0 / login v4.14.0 — all ghcr.io; chart-tested pair per evidence.md P-15..P-17). Added `pin_review_cadence:` (zitadel_chart P30D, images P12M). `default`/`alternatives`/`forbidden` byte-unchanged. No breaking change. Machine enforcement stays off (`ci_blocking: false`, `linter_rule: null`). |

- **Decision**: KEEP-WITH-CHANGES
- **Next review due**: 2027-06-02
- **Notes**: Updated by `b8-7-zitadel` (B.8.7). Additive minor bump (the
  `gateway.yaml` first-`versions:`-map precedent). `exception_constitutional: false`
  preserved (dated expiry, FR-J7-020); `last_reviewed` resets to 2026-06-02,
  `expires_at` to 2027-06-02 (FR-J7-021 ordering). identity.yaml becomes the second
  standard (after `gateway.yaml`) to carry a `versions:` map — Zitadel becomes a pin
  source. `default: zitadel`, `alternatives: [keycloak, authentik]`, and
  `forbidden: [firebase-auth, auth0-saas-us]` are byte-unchanged. No
  `breaking_change` field added (FR-B87-047). No constitutional amendment. Pins
  verified LIVE 2026-06-02 — chart-tested pair chart 10.0.2 ↔ appVersion v4.14.0
  (NOT the newer v4.15.0, which is not chart-tested); registry `ghcr.io` (NOT
  docker.io, b8-coroot lesson); v-prefix `v4.14.0`. Final re-verify at implement:
  evidence.md P-15..P-21. Realised alongside the `2.0.0/infra/zitadel/` identity
  subtree (4 files: values-forge.yaml.tmpl + README.md.tmpl +
  docker-compose.fragment.yml.tmpl + bootstrap.md.tmpl — chart-referenced hybrid,
  no kustomization). Evidence: `.forge/changes/b8-7-zitadel/evidence.md`.

---

## 2026-06-03 — Initial ratification (b8-9-qwik-web-public)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard          | Version | Decision | Next review due | Notes |
  |-------------------|---------|----------|-----------------|-------|
  | web-frontend.yaml | 1.0.0   | Created  | 2027-06-03      | Birth: first web-frontend pin source — Qwik City default (ADR-005 ratification), `@builder.io/qwik ^1.20.0` + `@builder.io/qwik-city ^1.20.0` + `vite 7.3.5` EXACT (vite 8 EXCLUDED by Qwik peer `>=5 <8`), `qwik_v2_watch` future-option (`@qwik.dev/core` 2.0.0-beta.35 — NOT GA), `pin_review_cadence` P30D, `expires_at 2027-06-03` (`exception_constitutional: false`), enforcement OFF (Iris-Web/K.4 territory). |

- **Decision**: Created
- **Next review due**: 2027-06-03
- **Notes**: New standard `.forge/standards/web-frontend.yaml` (ROOT-level —
  required by the non-recursive J.7 gate; gateway.yaml precedent). Role-named
  (NOT framework-named) so it survives a Qwik→SvelteKit pivot without rename
  (ADR-B89-005; gateway.yaml / identity.yaml convention). `default: qwik-city`,
  `alternatives: [sveltekit]`, `forbidden: []` ratifying ADR-005
  (`docs/ARCHITECTURE-TARGET.md:365-374` — KEEP Flutter mobile+desktop+backoffice,
  REPLACE Flutter Web public → Qwik City; SEO/resumability/LCP/TTI). `index.yml`
  gains a `standards/web-frontend` trigger entry (qwik / qwik-city / web-public /
  connect-es / vite / ssr / seo / sveltekit). Pins verify-then-pin LIVE
  2026-06-03 (evidence.md P-16..P-22) — re-confirmed the design-phase pins
  P-01..P-09 with NO drift; the v2 `@qwik.dev/*` line stays beta-only
  (2.0.0-beta.35, no GA) on the `qwik_v2_watch` future-option list (B.8.O DBOS
  watch-list precedent). The Connect-ES `^2.0.0` runtime pins are cross-referenced
  only (transport.yaml v1.3.0 `codegen.versions_2_0_0` is the single source of
  truth — NOT re-pinned here). No constitutional amendment (Article VI Flutter
  mandate PRESERVED — Qwik is an additive public-web surface; Article VIII.1 Kong
  SHALL untouched — candidate stays `scaffoldable: false` until B.8.14). Realised
  alongside the `2.0.0/frontend/web-public/` Qwik City skeleton (10 .tmpl files),
  the 2.0.0 buf.gen es out-path re-point (ADR-B89-004), and the 2.0.0.yaml
  comment-only delivered annotation (ADR-B89-007). Evidence:
  `.forge/changes/b8-9-qwik-web-public/evidence.md`.

---

## 2026-06-03 — Updated state-management.yaml to v1.1.0 (b8-11-nsma-linter)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard | Version | Decision | Next review due | Notes |
  |----------|---------|----------|-----------------|-------|
  | state-management.yaml | 1.1.0 | KEEP-WITH-CHANGES | never (structural) | NSMA warn→fail activation per B.8.11/ADR-006; ci_blocking false→true. Evidence: .forge/changes/b8-11-nsma-linter/evidence.md |

- **Decision**: KEEP-WITH-CHANGES — `ci_blocking: false → true` activates the
  ratified-blocking `no-state-management-alternatives` (NSMA / ADR-006) gate in
  `constitution-linter.sh` (the FAIL/WARN branch already keyed on `ci_blocking:`;
  NO new bash — data flip only). `activation_planned: "B.8 (T6)"` replaced with
  `activated_by: "b8-11-nsma-linter (B.8.11, 2026-06-03)"` (machine-readable audit
  trail, schema-legal under `enforcement.additionalProperties: true`). Version
  bumped 1.0.0 → 1.1.0 (additive minor: enforcement fields only; `forbidden:` (8
  pkgs), `flutter:` block, `linter_rule:`, `rationale:`, and the structural-exception
  pair `expires_at: never` + `exception_constitutional: true` byte-unchanged).
  Enforces Article VI.3 — no fresh Article XII amendment (Q-001 ruling (a),
  independent reviewer 2026-06-03). Precedent: transport.yaml v1.1.0
  (t5-connect-codegen, REVIEW.md:51-58). Satisfies J.7 FR-J7-023 (version⇔REVIEW
  coupling) + FR-J7-020 (structural-exception pair).
- **Next review due**: never (structural exception preserved).
- **Notes**: `pre_commit_hook` stays `false` (no dep-linting runner ships; runner
  is G.2 territory — ADR-B811-002). Backward-compat by construction: zero scannable
  pubspec.yaml in the live tree after `/.forge/` + `/examples/` + `/.dart_tool/`
  exclusions — live linter stays OVERALL PASS post-flip.

---

## 2026-06-05 — Correction Entry: §VIII.1 amendment (Kong→Envoy) + BDFL window waiver + kong.md deprecation (b8-14-promotion-flip)

- **Reviewer**: @bfontaine (BDFL, Phase actuelle)
- **Reviewed standards**:

  | Standard | Version | Decision | Next review due | Notes |
  |----------|---------|----------|-----------------|-------|
  | infra/kong.md | 1.0.0 | DEPRECATE | EOL 2026-12-05 | Superseded by gateway.yaml (Envoy) + transport.yaml (Connect) at the §VIII.1 amendment. Tombstone-redirect kept for the T+6-month 1.0.0 deprecation window; index.yml trigger removed. |
  | gateway.yaml | (B.8.4) | KEEP | per its own review | Now the §VIII.1 API-gateway standard of record (Envoy Gateway API). |
  | transport.yaml | 1.3.0 | KEEP | per its own review | Now the §VIII.1 client/S2S transport of record (Connect-RPC; replaces gateway REST↔gRPC transcoding). |

- **Decision**: KEEP-WITH-CHANGES / DEPRECATE — ratifies **Constitution Amendment
  #2** (§VIII.1 Kong → Envoy Gateway + Connect-RPC; Constitution v1.1.0 → **v2.0.0**,
  breaking per VERSIONING §MAJOR). §VIII.2 (Temporal) unchanged (B8O retained
  Temporal). The framework stays on the **0.4.0** MINOR line with a `### BREAKING`
  CHANGELOG note (pre-1.0 carve-out VERSIONING.md:70-73); framework MAJOR deferred
  to GA.
- **⚠️ GOVERNANCE WAIVER (honest record — NOT a completed window)**: the
  GOVERNANCE.md §"Amendment Process" ≥7-day public discussion window for the §VIII.1
  amendment **opened 2026-06-04** (when `b8-14-promotion-prep` landed the proposal +
  staged amendment-viii-1.md publicly on `main`) and was **compressed to ~1 day**,
  **ratified 2026-06-05** by BDFL decision. This is a deliberate deviation from the
  full 7-day window, recorded here for audit. **Authority**: GOVERNANCE.md grants
  the BDFL (Phase actuelle) sole ratification authority. **Rationale**: solo-maintainer
  project; the Kong→Envoy migration has been publicly tracked since project inception
  (docs/new-archetypes-plan.md + docs/ARCHITECTURE-TARGET.md §11) and additively
  delivered + zero-regression-proven across B.8.4–B.8.12. No fabricated claim of a
  completed 7-day window is made anywhere.
- **t4 supersession**: this change supersedes the Kong/DBOS narrative parts of
  `t4-adr-ratification`'s ADRs in `docs/ARCHITECTURE-TARGET.md` §11/§12.1 (realigned
  DBOS→Temporal, Kong→Envoy) via the **material-path**:
  `bin/forge-rehash-architecture-doc.sh` re-pins the sha256 in
  `.forge/changes/t4-adr-ratification/specs.md` + appends `REHASH-LOG.md`.
- **Next review due**: never (structural — constitutional amendment).
- **Notes**: 1.0.0 (Kong) deprecated, EOL 2026-12-05. Existing 1.0.0 projects keep
  Kong via the **additive** migrate path (`forge-migrate-flagship.sh` stays additive
  forever); Kong removal applies ONLY to fresh 2.0.0 scaffolds (new
  scaffold-plan-2.0.0). The frozen 1.0.0 base/snapshot are never edited (b8-2 guard).

## 2026-06-13 — Initial ratification (b7-standards, B.7.3)

  | Standard                      | Version | Decision | Next review due | Notes                                                                                                          |
  |-------------------------------|---------|----------|-----------------|----------------------------------------------------------------------------------------------------------------|
  | global/rag-patterns.md        | 1.0.0   | KEEP     | 2027-06-13      | Birth: RAG patterns for ai-native-rag — chunking/embeddings, hybrid retrieval + RRF, re-ranking, pgvector HNSW tuning, EU sovereignty. |
  | global/llm-gateway.md         | 1.0.0   | KEEP     | 2027-06-13      | Birth: in-repo Rust axum LLM gateway proxy — OpenAI-compatible upstream, tier-aware refusal (refs I.3 + compliance-tiers), prompt audit, PII/fallback. |
  | global/mcp-servers.md         | 1.0.0   | KEEP     | 2027-06-13      | Birth: rmcp MCP server patterns — security, OAuth 2.1+PKCE → Zitadel/Envoy-OIDC, rmcp Tier-3 verify-then-pin caveat. |

- **Decision**: KEEP (three new Markdown pattern standards).
- **Next review due**: 2027-06-13 (12-month cycle; `.md` standards carry no
  `version:` frontmatter — section/content review, not semver).
- **Notes**: Three new `global/*.md` pattern standards for the `ai-native-rag`
  archetype (T7, B.7.3), resolving the `delivered_by: B.7.3` forward-references in
  `.forge/schemas/ai-native-rag/1.0.0.yaml`. **No version pins** are shipped here —
  rmcp / pgvector-crate / async-openai pins ride with B.7.2-full's `Cargo.toml.tmpl`
  (verify-then-pin LIVE; transport.yaml/b8-6 precedent). Baseline recorded in
  `.forge/research/b7-standards-verify-then-pin.md` (crates.io LIVE 2026-06-13:
  rmcp 1.7.0 / pgvector 0.4.2 / async-openai 0.41.0 — rmcp version differed across
  README 0.16.0 / Context7 index 0.5.0 / LIVE 1.7.0, the verify-then-pin trap).
  Tier-aware refusal references the existing EU machinery (`forbidden-components-rules.md`
  I.3, `compliance-tiers.md`, `data-stewardship-rules.md` K.3); runtime Janus AI
  rules (J.8.c) deferred to `b7-9-janus-ai`. MCP auth couples to `identity.yaml`
  (Zitadel) + Envoy SecurityPolicy JWT (B.8.12).

## 2026-06-22 — Janus LLM-provider rules (b7-9-janus-ai, J.8.c / B.7.9)

- **Reviewer**: @bfontaine
- **Reviewed standards**:

  | Standard                            | Version       | Decision          | Next review due | Notes                                                                                                          |
  |-------------------------------------|---------------|-------------------|-----------------|----------------------------------------------------------------------------------------------------------------|
  | global/janus-orchestration-rules.md | (md, no semver) | KEEP-WITH-CHANGES | 2027-06-22      | +3 catalogue rows (J8-RULE-004/005/006) ; "Extending the catalogue" step 1 prose updated (sibling `forbidden_combinations:` list now exists) ; "Refusal vs warning semantics" notes the new refusals. Content review (no `version:` frontmatter — `.md` pattern standard). |
  | global/compliance-tiers.md          | 1.0.0 → 1.1.0 | KEEP-WITH-CHANGES | 2027-06-22      | `forbidden:` `[]` → `[vertex-ai, bedrock]` (LLM-provider tokens) so the generic I.3 T3-RULE-005 review-time linter catches them ; §10.2 matrix UNCHANGED (no row/cell shift — byte-identical-to-ARCHITECTURE-TARGET Interdiction 5 preserved). **SemVer-minor bump 1.0.0 → 1.1.0** (`last_reviewed`/`expires_at` → 2026-06-22 / 2027-06-22) per standards-lifecycle for the additive token edit (FR-B7-9-062). `i2.test.sh::_test_i2_005` was relaxed from exact version/date pins to frontmatter-validity checks (maintainer "Option B", 2026-06-22 — a mutable versioned field must not be exact-pinned by a sibling change's gate). |
  | global/forbidden-components-rules.md| 1.0.0 → 1.1.0 | KEEP-WITH-CHANGES | 2027-06-22      | New "LLM-provider `forbidden:` coupling" interim-gap subsection documenting the `compliance-tiers.md::forbidden:` token approach + the `J8-RULE-004..006` scaffold-time cross-reference. **SemVer-minor bump 1.0.0 → 1.1.0** (`last_reviewed`/`expires_at` → 2026-06-22 / 2027-06-22) for the additive subsection. `i3.test.sh::_test_i3_008` was relaxed from the exact 1.0.0 version pin to a semver-validity check (maintainer "Option B", 2026-06-22). |

- **Decision**: KEEP-WITH-CHANGES — all three edits are additive (Article XII
  "Extending the catalogue" protocol, NOT amendments ; no `[T1,T2,T3]` enum
  change, no refusal-semantics change).
- **Next review due**: 2027-06-22 (12-month cycle).
- **Notes**: J.8.c lands the Janus refusal rules for the `ai-native-rag`
  LLM gateway — `J8-RULE-004` (Vertex AI default refused), `J8-RULE-005`
  (AWS Bedrock default refused), `J8-RULE-006` (`--eu-tier T3` ⇒ Mistral-EU /
  vLLM ; US-managed inference refused). Two complementary enforcement surfaces
  (ADR-B7-9-005) : scaffold-time Janus refusal (exit 3, `_refuse_if_forbidden_combination`)
  + review-time I.3 T3-RULE-005 (`forbidden:` token, tier-scaled WARN/FAIL).
  EU alternatives verified verbatim against `compliance-tiers.md` §10.2
  (ADR-B7-9-006). Rule-ID block `J8-RULE-004..006` allocated sequentially after
  the live `J8-RULE-003` (ADR-J8-004 numbering invariant ; never reused).

## 2026-06-22 — Initial ratification (b7-5-ai-act, B.7.5 + B.7.8)

  | Standard                              | Version       | Decision | Next review due | Notes                                                                                                          |
  |---------------------------------------|---------------|----------|-----------------|----------------------------------------------------------------------------------------------------------------|
  | global/ai-act-dora-artefacts.md       | 1.0.0         | KEEP     | 2027-06-22      | Birth: governs the EU AI Act + DORA regulatory-artefact content schema + Phase A (BDFL, frozen) → Phase B (Themis K.5) governance for the `.forge/compliance/{ai-act,dora}/` members shipped by the `ai-native-rag` archetype. |
  | global/compliance-artefacts-bundle.md | 1.0.0 → 1.1.0 | AMEND    | 2027-06-22      | Additive minor bump: the I.6 hand-off bundle now collects the B.7.5/B.7.8 AI-Act + DORA artefacts under `regulatory/{ai-act,dora}/*` (graceful absence). Six base members unchanged; determinism recipe untouched; NIS2/CRA siblings still reserved. Realises FR-I6-CA-053. |

- **Decision**: KEEP (new `global/ai-act-dora-artefacts.md` v1.0.0) +
  AMEND (`global/compliance-artefacts-bundle.md` `1.0.0 → 1.1.0`).
- **Next review due**: 2027-06-22 (12-month cycle).
- **Notes**: B.7.5 (AI Act risk-classification / transparency / model+dataset
  cards) + B.7.8 (DORA incident-reporting / RoI) regulatory artefacts for the
  `ai-native-rag` archetype, shipped under `.forge/compliance/{ai-act,dora}/`
  and wired into the I.6 bundle (`bundle.sh` directory-walk, additive). Every
  regulatory specific is **grounded-or-deferred** per Article III.4: the
  archetype profile (`ARCHITECTURE-TARGET.md` §10.3), the DORA RoI deadline
  (§10.4), the Themis charter "< 24h" figure (§9.2), and the prompt-audit
  transparency surface (`llm-gateway.md`) are cited; the precise AI Act
  risk-category mapping, the finance high-risk determination, the bias-eval
  legal trigger, the DORA notification windows, and the authoritative RoI schema
  are left as `[NEEDS CLARIFICATION]` markers tagged **Themis (K.5)** Phase-B
  work items (NOT invented). The negative-grep guard (`b7-5.test.sh`
  `_test_b75_030`) is the deterministic anti-hallucination backstop. The I.6
  bundle contract bumped `1.0.0 → 1.1.0` in lock-step (the `i6.test.sh` count
  assertion stays GREEN — its L2 fixture stages only the 4 canonical surfaces
  into a tmpdir, so it is hermetic to the new live artefacts).

## 2026-07-10 — Initial ratification (k5-themis, K.5)

  | Standard                             | Version | Decision | Next review due | Notes                                                                                                                                                                                          |
  |--------------------------------------|---------|----------|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | global/standards-review-rules.md     | 1.0.0   | KEEP     | 2027-07-10      | Birth: the `K5-RULE-001..005` catalogue + EU regulatory-deadline calendar for the Themis compliance-officer agent (K.5) and its `forge review-standards` automation (`bin/forge-review-standards.sh`). |

- **Reviewer**: @bfontaine
- **Decision**: KEEP (new `global/standards-review-rules.md` v1.0.0).
- **Next review due**: 2027-07-10 (12-month cycle).
- **Notes**: K.5 ships the Themis compliance officer
  (`.claude/agents/themis.md`) + the `forge review-standards` cadence
  automation. The CLI walks `.forge/standards/` for `last_reviewed` /
  `expires_at` frontmatter, classifies FRESH / DUE-SOON / EXPIRED /
  STRUCTURAL against a `--window`, skips structural exceptions
  (`expires_at: never` + `exception_constitutional: true`), and carries
  the NIS2 / DORA / CRA / AI Act calendar copied **verbatim** from
  `new-archetypes-plan.md` §7.1 I.6 bullet (Article III.4 — never
  invented). WARN-only default (`standards-lifecycle.md` "WARN n'est
  jamais bloquant") ; `--strict` opt-in blocking. `--bundle` DRIVES the
  I.6 `bundle.sh` (never forks it) — `compliance-artefacts-bundle.md`
  stays v1.1.0 (i6 pin untouched), `forge-compliance.yml` untouched (i5
  pin untouched). The `standards-lifecycle.md` "Themis hook (deferred —
  T7)" section flips to "shipped (K.5)" (delta, structural-exception
  table preserved for `t4.test.sh::_test_t4_025`). This standard ships
  as Markdown, so `bin/validate-standards-yaml.sh` (J.7) does not gate
  it ; the frontmatter block is narrative.
