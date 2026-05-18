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
