# Changelog

All notable changes to the Forge Framework are documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(see [docs/VERSIONING.md](docs/VERSIONING.md) for our exact policy and its
coupling to the Constitution version).

While Forge is on the `0.y.z` pre-GA track, breaking changes may land in a
minor bump and will be called out under a `### BREAKING` subsection.

## [Unreleased]

### Added

- **Hermes-Async event-driven messenger agent (K.1, `b6-4-hermes-async`)** — a new
  `.claude/agents/hermes-async.md` persona that maintains the AsyncAPI 3.1 event
  contracts, generates NATS/Kafka protocol bindings, and enforces idempotency keys +
  event versioning for the `event-driven-eu` archetype (the B.6 sibling of the K.2
  Sibyl brick). Advisory specialist in the Sibyl/Panoptes mould — **NO scanner, NO
  data file, NO new standard** (consumes the B.6.3 standards `global/event-driven.md`,
  `global/asyncapi-contracts.md`, `infra/nats-jetstream.md` by reference). Ships four
  greppable checklists (AsyncAPI Contract Maintenance / NATS/Kafka Binding Generation
  / Idempotency-Key Enforcement / Event Versioning & Compatibility) grounded in the
  real scaffolded code shapes (`EventEnvelope`, the `Nats-Msg-Id` publish-dedup header,
  `InboxDedup`, the `Saga` compensator), an **Event Contract Readiness Report**
  template, a `K1-RULE-001..006` recommendation catalogue (advisory ladder `Advisory`
  < `Concern` < `Blocking`, the one Blocking rule being end-to-end idempotency /
  exactly-once per Article VIII.2), and an anti-hallucination protocol requiring LIVE
  verification (Context7) of AsyncAPI/NATS/Temporal API details. Registered in
  `CLAUDE.md` + `docs/GUIDE.md` agent tables (disambiguated from **Hermes** (Flutter
  perf) and **Hermes-API** (Connect codegen)). Gated by a new
  `.forge/scripts/tests/b6-4.test.sh` (19 tests: 18 L1 + 1 L2 anchor-integrity),
  registered in `forge-ci.yml`. This brick edits no Janus file and no standards index
  (task-scoped divergence from the b7-pythia precedent).
- **Per-layer CI templates for the `event-driven-eu` archetype (B.6.5, `b6-5-ci-templates`)** —
  three GitHub Actions workflow templates scaffolded into an adopter's
  `.github/workflows/`, mirroring the `full-stack-monorepo` per-layer convention
  and adapted to the event-driven layer decomposition: **`forge-events.yml`**
  (gates the `events` + `eventstore` crates — `task backend:lint` then
  crate-scoped `cargo build/test -p events -p eventstore`), **`forge-workflows.yml`**
  (gates the `saga` crate with default features — the pre-alpha `temporal-sdk`
  feature stays OFF; a separate `saga-temporal-sdk` job runs
  `--features temporal-sdk` only on manual `workflow_dispatch`, clearly
  non-blocking per ADR-B6-2-004), and **`forge-infra.yml`** (NATS JetStream
  config lint via `nats-server -c … -t`, AsyncAPI 3.1 validation via
  `task asyncapi:validate` against the official schema, and a Postgres migration
  check that applies `init-eventstore.sql` twice against an ephemeral
  `postgres:17-alpine` for validity + idempotency). Each workflow uses
  `dorny/paths-filter@v3`, invokes the archetype's own Taskfile targets, ends in
  the Forge gates (`verify.sh` → `constitution-linter.sh`), pins all actions and
  the archetype's `nats:2.10-alpine` / `postgres:17-alpine` images, and uses no
  `continue-on-error`. Registered in
  `.forge/templates/archetypes/event-driven-eu/scaffold-plan.yaml` and gated by a
  new `.forge/scripts/tests/b6-5.test.sh` (10 tests: 9 L1 + 1 L2 render-clean),
  registered in `forge-ci.yml`. Additive — the archetype schema stays
  candidate/`scaffoldable:false` (promotion rides B.6.7).

- **Production Helm charts for the `event-driven-eu` Temporal + NATS clusters (B.6.6, `b6-6-helm`)** —
  the production Kubernetes deployment the B.6.2 scaffolder backbone
  forward-referenced, authored under
  `.forge/templates/archetypes/event-driven-eu/1.0.0/infra/k8s/` as Forge Helm
  **values overlays** on upstream charts (the B.8.7 Zitadel / B.8.4 Envoy
  chart-referenced-hybrid convention — no vendored `Chart.yaml`). **(a)**
  `temporal-cluster/` deploys the four Temporal server roles
  (**history / matching / frontend / worker**) on a **Postgres-backed**
  persistence + visibility store (`server.config.persistence.datastores.*.sql`,
  `pluginName: postgres12`; no removed Cassandra sub-chart), with the schema-setup
  Job wired via Helm hooks; **(b)** `nats-jetstream/` deploys a **3-node
  clustered** NATS with **JetStream** (RAFT quorum, file-store PVCs) + monitoring,
  documenting runtime durable-consumer / queue-group provisioning; **(c)** each
  chart carries a **T1 / T2 / T3 self-host EU** compliance posture citing
  `compliance-tiers.md`, plus an `infra/k8s/README.md` index. Chart pins are
  verify-then-pin LIVE (`temporal/temporal` `1.5.0`/server `1.31.1`; `nats/nats`
  `2.14.2`) and both overlays are `helm template`-validated. The `temporalio-sdk`
  **client** crate pin in `backend/Cargo.toml` (`0.5.0`) is untouched (orthogonal
  to the **server** cluster version — no re-pin). Additive: the dev backbone is
  byte-unchanged. Gated by `.forge/scripts/tests/b6-6.test.sh` (13 L1 + 1 L2
  helm-render), registered in `forge-ci.yml`; the schema stays `candidate`
  (promotion is B.6.7).

- **event-driven-eu compliance hooks — NIS2 + DORA (B.6.9, `b6-9-compliance`)** —
  the regulatory layer of the `event-driven-eu` archetype (profile "NIS2 + DORA
  (si finance) + CRA", `ARCHITECTURE-TARGET.md` §10.3), the B.6 sibling of the
  B.7.5/B.7.8 AI-Act work. Ships **(B.6.9.a)** NIS2 artefacts under
  `.forge/compliance/nis2/` (`incident-reporting.md` — the significant-incident
  reporting obligation with the grounded **24h/72h** windows verbatim, scoped to
  the NATS JetStream / Temporal / Postgres event-store operational surface, →
  the I.6 audit-ledger + IX.4 Rust OTel evidence surfaces ;
  `incident-report.template.yaml` — an adopter-fillable 24h/72h notification
  skeleton ; `obligations-index.yaml` — the machine-readable obligation→evidence
  map: `incident-reporting` + `supply-chain-security` satisfied, ungrounded
  pillars flagged `needs-clarification`/`themis_owner: K.5`) ; **(B.6.9.b)** the
  DORA Register-of-Information submission helper
  `.forge/scripts/compliance/dora-roi-helper.sh` (drives, never forks, the b7-5
  `dora/roi-register.template.yaml` base and specialises it for the archetype's
  ICT third-party stack — NATS/Temporal/Postgres) ; **(B.6.9.c)** SBOM CycloneDX
  auto-generation wiring documentation — event-driven-eu's SBOM rides the
  existing `bin/forge-sbom.sh` (Rust `Cargo.lock` → CycloneDX 1.5) + the I.6
  bundle `sbom/sbom.cdx.json` member (no new generator) ; **(B.6.9.d)** the I.6
  bundle wired additively — `bundle.sh` walk tuple gains `"nis2"`, the bundle
  contract `global/compliance-artefacts-bundle.md` bumped **1.1.0 → 1.2.0**
  (NIS2 members ride `regulatory/nis2/*`; NIS2 moves reserved → shipped, CRA
  still reserved) ; **(B.6.9.e)** a new standard
  `global/nis2-dora-eda-artefacts.md` v1.0.0 (6 H2 + 5 MUST NOT, Phase A/B
  BDFL→Themis governance) + `index.yml` + `REVIEW.md` entries ; **(B.6.9.f)** a
  new harness `.forge/scripts/tests/b6-9.test.sh` (17 L1 + 3 L2), registered in
  `forge-ci.yml`. Every regulatory specific is **grounded-or-deferred** (Article
  III.4; `_test_b69_030` negative-grep backstop). **Lock-step** (shared-
  reservation discipline): `b7-5.test.sh` dropped its `nis2/`-reserved assertion
  and relaxed its I.6-version pin to semver-validity; `i6.test.sh` frontmatter
  pins updated to 1.2.0 / 2026-07-10; `ai-act-dora-artefacts.md` +
  `docs/COMPLIANCE.md` stale "NIS2 reserved" prose corrected. `forge-compliance.yml`
  unchanged (the artefacts ride the existing `bundle` step).

- **Iris-Web frontend web specialist agent (K.4, `k4-iris-web`)** — a new
  `.claude/agents/iris-web.md` persona that maintains the Qwik / SvelteKit
  web-frontend conventions for the `full-stack-monorepo` `frontend/web-public/`
  surface, distinct from Hera (Flutter). Three sub-modules: **(K.4.a)** the
  persona (Persona / Purpose / Checklists / Output: Web Frontend Readiness
  Report / Rule Catalogue `K4-RULE-001..006` / Integration / Anti-Hallucination
  / Audit cross-references), advisory ladder (`Advisory` < `Concern` <
  `Blocking`, the one Blocking rule being client-bundle secret leakage);
  **(K.4.b)** a new standard `.forge/standards/global/qwik-frontend-patterns.md`
  codifying resumability, `routes/` conventions, SSR/SSG boundaries, Connect-ES
  client usage, streaming UI + cancel-on-unmount (B.7.10 precedent), component
  conventions, and Vitest testing (T5.3.3 precedent) — referencing
  `web-frontend.yaml` for version pins as the single source of truth (no pin
  duplication); **(K.4.c)** integration — `standards/index.yml` registration,
  an **additive** Janus dispatch-table row in `cross-layer-orchestrator.md`
  (Janus arbitrates between Iris-Web (Qwik) and Hera (Flutter) per
  ARCHITECTURE-TARGET §9.2 line 743 — Hera's Flutter scope is untouched), and a
  `CLAUDE.md` + `docs/GUIDE.md` agent-catalogue row. Gated by a new
  `.forge/scripts/tests/k4.test.sh` (22 tests: 20 L1 + 2 L2 cross-surface),
  registered in `forge-ci.yml`. Forward-stable for `mobile-pwa-first` (B.9,
  Pending T8) to adopt additively.
- **Themis compliance-officer agent + `forge review-standards` automation (K.5, `k5-themis`)** —
  the fifth Module-K agent (`.claude/agents/themis.md`), the EU **compliance
  officer** for `tous EU` archetypes (`new-archetypes-plan.md` §9). Themis works
  at **repo-lifecycle-time** (ongoing, ambient), explicitly bounded against
  Demeter's scaffold-time data-stewardship (K.3) — the persona's "Boundary —
  Themis vs Demeter" section keeps the two from ever being confused. Ships
  **`bin/forge-review-standards.sh`** (bash thin + Python 3 inline, mirroring
  `forge-demeter-scan.sh`): walks `.forge/standards/` for `last_reviewed` /
  `expires_at` frontmatter (top-level YAML + fenced ```yaml blocks in `*.md`),
  classifies each standard FRESH / DUE-SOON / EXPIRED / STRUCTURAL against a
  `--window` (default 30d), skips structural exceptions (`expires_at: never` +
  `exception_constitutional: true`), and emits a deterministic
  (`SOURCE_DATE_EPOCH`) Standards Review Report carrying the verbatim NIS2 /
  DORA / CRA / AI Act regulatory-deadline calendar (copied from
  `new-archetypes-plan.md` §7.1 I.6 bullet — never invented). **WARN-only** by
  default (`standards-lifecycle.md` "WARN n'est jamais bloquant"): exit 0
  CLEARED / 1 REVIEW-DUE / 2 usage / 3 BLOCKED (only under `--strict`).
  `--bundle` **drives** (never forks) the I.6 `bundle.sh` after writing a
  regulatory-deadline summary. New standard
  `global/standards-review-rules.md` (`K5-RULE-001..005` catalogue), a sibling
  monthly CI workflow `.github/workflows/forge-standards-review.yml`
  (`on: schedule:` + `workflow_call:`, `continue-on-error: true`), and
  registration parity with Demeter (`CLAUDE.md` + `docs/GUIDE.md` +
  `docs/COMPLIANCE.md`). The `standards-lifecycle.md` "Themis hook (deferred —
  T7)" section flips to "shipped (K.5)". Gated by
  `.forge/scripts/tests/k5.test.sh` (25 L1 + 2 L2). Additive — no constitution
  amendment; `forge-compliance.yml` (I.5) and `bundle.sh` /
  `compliance-artefacts-bundle.md` (I.6) untouched (their harnesses stay GREEN).
- **`ai-native-rag` promoted to stable / scaffoldable — B.7 COMPLETE 9/9 (B.7.6, `b7-6-harness`)** —
  the promotion gate (final B.7 brick) flips `.forge/schemas/ai-native-rag/1.0.0.yaml`
  `stage: candidate → stable`, `scaffoldable: false → true`, so
  `forge init --archetype ai-native-rag` now renders the full RAG tree (was exit 3).
  Gated by a new `.forge/scripts/tests/b7-6.test.sh` (35-test promotion suite:
  end-to-end structural L1 + aggregation of all 8 sibling B.7 harnesses + held/post-flip
  guards) and a new **`harness-rust` CI job** (`bufbuild/buf-action` + `dtolnay/rust-toolchain`
  + node) that runs the **live `buf generate` → Rust+TS codegen → `cargo build`/`test` →
  Qwik `tsc`** path — the deferred B.7.2/B.7.10 codegen legs, now exercised. Connect
  handler stays a documented adopter seam (flagship parity — ai-native-rag ships no
  `grpc-api` crate). Ships a deterministic `SOURCE_DATE_EPOCH` snapshot tarball for
  `forge upgrade`. The flip cascades in lockstep: sibling candidate-guards inverted
  (`b7-1`/`b7-2`/`b7-2a`/`b7-7`), dispatch `status → stable` + a new cli-trust e2e
  fixture (`archetype-fixtures/ai-native-rag.yml`, FR-T51-055), the forge-ci line
  budget bumped 340→380, and the workflow job count 6→7 — all kept in sync.
  Additive: no constitution amendment, no other-archetype edit, frozen full-stack
  1.0.0/2.0.0 trees byte-unchanged.
- **`forge-rag-example` reference project (B.7.7, `b7-7-example`)** — the second
  reference tree under `examples/`, demonstrating the `ai-native-rag` archetype
  (sibling of `forge-fsm-example`). A fully-rendered `ai-native-rag/1.0.0` tree
  (rendered via `overlay.sh` — the archetype is `candidate`, so `forge init`
  still refuses exit 3) with **3 archived demo changes**: `demo-001-doc-ingestion`
  (`rag/` pipeline — chunking, `Embedder`, pgvector HNSW, hybrid retrieval
  vector+BM25+RRF, re-rank, XI.5 embedder fallback), `demo-002-mcp-search-tool`
  (rmcp `search` tool, dual transport, schema-validated input), and
  `demo-003-rag-query-ui` (multi-layer/Janus — Qwik **streaming** query UI
  consuming b7-10's `QueryStream`/`queryStream` with progressive token render +
  IX.6 prompt-audit across the stream + XI.5 `fallbackUsed` degrading the stream
  to unary `Query`). New `FR-RAGEX-*`/`NFR-RAGEX-*` namespace consolidated into
  `.forge/specs/example-reference.md`; the `example` CI job (FR-CI-012) extended
  to gate **both** example trees (parse-only, ADR-B7-7-004); harness
  `b7-7.test.sh` (22 L1 + L2 opt-in) in `forge-ci.yml`. Additive — no archetype/
  schema/standard/CLI edit; the archetype stays `candidate`/`scaffoldable:false`
  (promotion rides `b7-6-harness`). Tree ~1.6 MB (≤ 5 MB budget).
- **Streaming RAG answer surface for `ai-native-rag` (B.7.10, `b7-10-streaming`)** —
  adds a server-streaming answer path to the candidate archetype, layered
  **additively** on the b7-2 unary surface (which is retained as the Article XI.5
  degradation target). Proto: `rag.proto` gains `rpc QueryStream(QueryRequest)
  returns (stream QueryChunk)` + a `QueryChunk` message (reusing `SourceChunk`),
  unary `Query` unchanged. Backend: a new `llm_gateway/src/streaming.rs`
  (`process_query_stream`) with **backpressure** (bounded `tokio::sync::mpsc`,
  named `STREAM_CHANNEL_CAPACITY`), **cancellation** (`JoinHandle::abort` +
  closed-channel signal), **mandatory XI.5 fallback** tested pre-stream
  (fallback-marked terminal chunk) and mid-stream (terminate-with-marker keeping
  partial tokens, ADR-B7-10-003), and a close-time PII-redacted prompt-audit
  (IX.6/XI.6). Frontend: `connect-client.ts` gains `queryStream()` (Connect-ES v2
  server-streaming `for await`) + a named exponential-backoff retry helper;
  `routes/index.tsx` renders progressively (Article XI.4), with a Stop control,
  cancel-on-unmount, and degradation to the unary `query()` path on retry
  exhaustion. WebTransport is documented as a forward alternative only (Connect-ES
  is fetch/HTTP — ADR-B7-10-005). One new pin `tokio-stream = "0.1.18"`
  (verify-then-pin LIVE, in `backend/Cargo.toml.tmpl` only). Harness
  `b7-10.test.sh` (7 L1 + 4 L2) in `forge-ci.yml` after `b7-2.test.sh`. The
  archetype stays **candidate / scaffoldable:false** — promotion remains gated on
  `b7-6-harness`; the streaming contract is consumed by `b7-7-example` (demo-003).
- **Janus LLM-provider rules for `ai-native-rag` (B.7.9 / J.8.c, `b7-9-janus-ai`)** —
  extends the J.8 refusal catalogue with three new rules for the `ai-native-rag`
  LLM gateway: `J8-RULE-004` (Vertex AI refused as default provider, any tier),
  `J8-RULE-005` (AWS Bedrock refused as default provider, any tier), and
  `J8-RULE-006` (`--eu-tier T3` ⇒ US-managed inference refused). The sanctioned
  alternative is **Mistral-EU (Mistral on Scaleway)** or **self-hosted vLLM**
  (OpenAI/Anthropic-via-EU-gateway at T1 only) — verified verbatim against
  `compliance-tiers.md` §10.2 (CLOUD Act forcing). These are provider × tier
  *combination* refusals (the archetype stays permitted): a new
  `dispatch-table.yml::forbidden_combinations:` sibling list (7-key entries) +
  an additive `_refuse_if_forbidden_combination` helper invoked by the
  `ai-native-rag` wrapper (exit 3, `[REFUSAL: <archetype>/<provider>@<tier>: …]`).
  Two complementary surfaces: the scaffold-time Janus refusal above + the
  review-time I.3 `T3-RULE-005` linter (`compliance-tiers.md::forbidden:` now
  lists `vertex-ai` / `bedrock`, with matching `constitution-linter.sh`
  REMEDIATION hints). Harness `b7-9.test.sh` (13 L1 + 2 L2) in `forge-ci.yml`.
  Additive — `_refuse_if_forbidden` and `J8-RULE-001..003` untouched; the
  candidate `ai-native-rag` still refuses a fresh `forge init` with exit 3.
- **K.2 AI/RAG specialist agent `Sibyl` (`b7-pythia`)** — a new advisory
  `.claude/agents/sibyl.md` persona for the `ai-native-rag` archetype: four
  checklists (Embeddings & Retrieval, pgvector HNSW Tuning, MCP Server Hardening,
  Prompt Audit & Fallback) operationalising the three B.7.3 b7-standards
  (`rag-patterns.md` / `llm-gateway.md` / `mcp-servers.md`) verbatim, a `RAG
  Readiness Report` template, and a 6-rule recommendation catalogue
  (`K2-RULE-001..006`) whose only `Blocking` rule is the Article XI.5
  mandatory-fallback gate (`K2-RULE-006`). **Advisory only — NO scanner, NO data
  file, NO new standard** (ADR-K2-003 divergence from the `k3-demeter` precedent;
  HNSW/embeddings tuning is workload-specific and cannot be reduced to a
  deterministic scan). Janus dispatches Sibyl at **Step 3** (design pass, not the
  Step 9 security pass) for `ai-native-rag` projects: delta-edits to
  `cross-layer-orchestrator.md` (Dispatch Table row + Step 3 note + Quality Gates
  bullet + Constitution-compliance bullet, all disjoint from the J8-RULE
  Forbidden-archetypes catalogue). `index.yml` triggers extended additively
  (`sibyl` on rag-patterns/llm-gateway/mcp-servers + `ef-search` /
  `embeddings-tuning` on rag-patterns — no new entry). CLAUDE.md + `forge-master.md`
  roster gain an AI/RAG-Specialist row. The maintainer ratified the name **Sibyl**
  (Q-001 Option B) — the shipped Product-Analyst-Pythia is untouched. Harness
  `b7-pythia.test.sh` (18 L1 + 1 L2) in `forge-ci.yml`. Additive; no regression to
  `j7` / `j8` / `k3` / `b7-1` / `b7-2a` / `b7-3` / `b7-2`.
- **B.7.5 + B.7.8 AI-Act + DORA regulatory artefacts (`b7-5-ai-act`)** — the
  `ai-native-rag` archetype now ships EU **AI Act** + **DORA** regulatory
  artefacts under `.forge/compliance/{ai-act,dora}/`: AI Act
  `risk-classification.md` (grounded transparency posture + deployer escalation
  triggers), `transparency-obligations.md` (duties → Forge evidence surfaces),
  adopter-fillable `model-card.template.md` + `dataset-card.template.md`, an
  `obligations-index.yaml`; and DORA `incident-reporting.md` (grounded "< 24h"
  charter figure + the §10.4 RoI deadline), `roi-register.template.yaml`, an
  `obligations-index.yaml`. New standard `global/ai-act-dora-artefacts.md`
  v1.0.0 governs the content schema + Phase A (BDFL, frozen) → Phase B
  (Themis K.5) governance. The I.6 hand-off bundle (`bundle.sh`) is extended to
  collect the artefacts under `regulatory/{ai-act,dora}/*` — the bundle contract
  `compliance-artefacts-bundle.md` bumps **1.0.0 → 1.1.0** (additive; six base
  members + determinism recipe unchanged; `i6.test.sh` updated in lock-step).
  Every regulatory specific is **grounded-or-deferred** per Article III.4: the
  precise risk-category mapping, finance high-risk determination, bias-eval
  legal trigger, DORA notification windows, and authoritative RoI schema are
  `[NEEDS CLARIFICATION]` Themis Phase-B work items, NOT invented; a negative-grep
  guard (`b7-5.test.sh` `_test_b75_030`) is the deterministic backstop. Harness
  `b7-5.test.sh` (16 L1 + 3 L2, incl. bundle integration / determinism /
  graceful-absence) in `forge-ci.yml`. `index.yml` + `REVIEW.md` registered.
  NIS2 / CRA siblings reserved. Additive (since 0.5.0).

- **`ai-native-rag` pattern standards (B.7.3, `b7-standards`)** — three new
  `global/*.md` pattern standards the archetype schema references as
  `delivered_by: B.7.3`: `rag-patterns.md` (chunking/embeddings, hybrid retrieval
  + RRF, pgvector HNSW tuning, re-ranking, EU sovereignty), `llm-gateway.md`
  (in-repo Rust axum proxy, OpenAI-compatible upstream Mistral-Scaleway/vLLM,
  tier-aware refusal referencing the existing EU machinery, prompt audit, PII +
  fallback), `mcp-servers.md` (rmcp server pattern, least-privilege security,
  OAuth 2.1 + PKCE → Zitadel/Envoy-OIDC, rmcp Tier-3 verify-then-pin caveat).
  **Pattern docs only — no version pins**: rmcp / pgvector-crate / async-openai
  pins ride with the later scaffolder brick (verify-then-pin LIVE; baseline
  recorded in research). `index.yml` + `REVIEW.md` registered; harness
  `b7-3.test.sh` (7 L1, incl. a no-inline-pin guard) in `forge-ci.yml`. Additive.
  Independent reviewer APPROVE (first pass); ADRs ratified.

- **`ai-native-rag` dispatch registration (B.7.2a, `b7-2a-dispatch-register`)** —
  registers the archetype in `.forge/scaffolding/dispatch-table.yml` (since 0.5.0,
  `status: candidate`) + a refusing wrapper `bin/forge-init-ai-native-rag.sh`. This
  flips `forge init --archetype ai-native-rag` from the exit-2 "unknown archetype"
  refusal to the canonical **exit-3** "no scaffoldable schema version" refusal
  (the B.8.3.b guard) — the archetype is now *known but not yet scaffoldable*,
  with **zero** scaffold produced. Resolves the b7-1-schema Q-005 follow-up.
  `--help` lists the archetype; the e2e smoke suite asserts its refusal.
  Harness `b7-2a.test.sh` (3 L1 + 1 L2) in `forge-ci.yml`. Additive — the schema
  stays candidate/scaffoldable:false. Independent reviewer APPROVE; ADRs ratified.

- **`ai-native-rag` archetype scaffold schema (B.7.1, `b7-1-schema`)** — first
  brick of the T7 AI-native RAG archetype chain (plan §6.2). Ships
  `.forge/schemas/ai-native-rag/1.0.0.yaml` as `stage: candidate` /
  `scaffoldable: false`: the archetype is declared but **not yet scaffoldable**, so
  `forge init --archetype ai-native-rag` refuses cleanly (exit 2 — unknown
  archetype, dispatch-table-gated until B.7.2). AI-First phases are materialised
  inline (no scaffold-schema loader resolves `extends`) plus two B.7.1 phases —
  `embeddings-pipeline` and `prompt-audit` (wiring Article XI.5/XI.6 + IX.6).
  Components are reference-only (no inline pins); the LLM gateway / MCP servers /
  RAG-patterns standards are deferred to B.7.3. Harness `b7-1.test.sh` (18 L1 + 1
  L2) in `forge-ci.yml`; validated on landing by the b8-3b versioned-schema gate.
  Additive — no existing schema/standard/constitution/CLI/template touched.
  Independent reviewer APPROVE; ADRs ratified.

## [0.4.0] — 2026-06-06

First **stable** cut of the 0.4.0 line. Headline: the **B.8 flagship migration is
complete (16/16)** — the `full-stack-monorepo` archetype graduates to 2.0.0 (Envoy
Gateway + Connect-RPC, Constitution v2.0.0 §VIII.1) and a fresh
`forge init --archetype full-stack-monorepo` now scaffolds the Kong-less Envoy tree.
Existing 1.0.0 projects are never force-migrated (deprecated, EOL 2026-12-05; the
migrate path stays additive). See the `rc.1 → rc.14` sections below for the full
incremental history that rolls up into this stable release.

### BREAKING — Constitution v2.0.0 · §VIII.1 Kong → Envoy (`b8-14-promotion-flip`, B.8.14)

- **Point of no return.** Constitution **Amendment #2** amends §VIII.1: the
  mandated API gateway is now **Envoy Gateway** (Kubernetes Gateway API), with
  end-to-end **Connect-RPC** replacing gateway-layer REST↔gRPC transcoding.
  Constitution **v1.1.0 → v2.0.0** (breaking; VERSIONING §MAJOR). §VIII.2
  (Temporal) unchanged (B8O). The **framework stays on the 0.4.0 line** (pre-1.0
  carve-out VERSIONING.md:70-73); the framework MAJOR follows at GA.
- The `full-stack-monorepo` **2.0.0** archetype is now `stage: stable` /
  `scaffoldable: true`: `forge init` produces an **Envoy/Connect** tree (no Kong).
  `cli` gains versioned-schema selection + a runtime guard refusing
  `scaffoldable:false` schemas (the deferred B.8.3.b guard).
- The flip landed as **two ordered commits** (auditable ratify→enable): C1 `818ba6b`
  ratifies §VIII.1 + bumps the Constitution to v2.0.0; C2 `e6e0134` enables the
  Kong-less front-door — a backward-compatible `--plan` flag on the overlay engine,
  `scaffold-plan-2.0.0.yaml` (1.0.0 set − Kong + Envoy-gateway manifests),
  `bin/forge-init-fsm-2.0.0.sh`, and the `b8-14-flip.test.sh` harness (incl. a live
  Kong-less-scaffold L2). `migrate-flagship` stays **additive forever** — existing
  1.0.0 projects keep Kong; removal is fresh-scaffold composition only.
- **Governance**: the §VIII.1 ≥7-day public discussion window (Article XII) opened
  2026-06-04 and was **compressed to ~1 day** by BDFL decision (ratified
  2026-06-05) — recorded honestly as a Correction Entry in
  `.forge/standards/REVIEW.md`. `docs/ARCHITECTURE-TARGET.md` §11/§12.1 realigned
  (Kong→Envoy, DBOS→Temporal) via the t4 material-path (rehash + REHASH-LOG).

### Deprecated — `full-stack-monorepo` 1.0.0 (Kong)

- **`full-stack-monorepo` 1.0.0 is deprecated**, EOL **2026-12-05** (T+6 months).
  During the window it remains buildable + migratable via `docs/MIGRATIONS.md`
  (the migrate path stays **additive** — existing 1.0.0 projects keep Kong);
  `docs/ROLLBACK.md` covers reversal. New scaffolds default to 2.0.0 (Envoy).
  `.forge/standards/infra/kong.md` is a deprecation tombstone → `gateway.yaml` +
  `transport.yaml`. After EOL, 1.0.0 is unsupported (VERSIONING support policy).

### Added — B.8.15 forge-upgrade matrix test (`b8-15-upgrade-matrix`)

- **T5.1 Layer D — the v0.4.0-stable publish gate.** New
  `.forge/scripts/tests/b8-15.test.sh` realises the N-1→N upgrade "matrix" as
  harness cells (forge-ci has no GA matrix). Direct e2e cells against the binaries:
  cross-major `forge-upgrade.sh` 1.x→2.0.0 ⇒ exit 7 + literal
  `[NEEDS MIGRATION: from … to …]`; `--force` on a dirty same-major tree ⇒ refused
  (clean-git gate, not version-compat); migrate-flagship `--dry-run` on a copy of
  the c1 example (`examples/forge-fsm-example/`) ⇒ 1.0.0→2.0.0 plan + no mutation;
  a static additive guard (migrate-flagship never `rm`s Kong/REST/Temporal).
- **Driver decision (ADR-B815-001):** the positive 1.0.0→2.0.0 flagship cell drives
  `bin/forge-migrate-flagship.sh` (runnable now); the `forge upgrade` front-door
  auto-resolve to 2.0.0 is **flip-gated** (skip-pass guard until
  `b8-14-promotion-flip` promotes 2.0.0) — it asserts 2.0.0 is still
  `scaffoldable:false`, so a leaked flip flips this guard RED.
- **L2 (`FORGE_B8_15_LIVE`):** the real migrate-flagship overlay on a c1 copy →
  asserts the `upgrade_history` flagship entry (from=1.0.0/to=2.0.0 +
  `kind: flagship-migration`), the Kong-present additive invariant, and the T5.1.B
  fixture matrix (`required_paths`/`forbidden_paths`) on the overlaid tree.
- The same-major / ledger-shape / `.merge-conflicts` machinery is gated via the
  **a7 coupling** (a7 is its authoritative harness; no fixture duplication);
  coupling also re-runs b8-10 + b8-14. No 2.0.0 snapshot tarball is required
  (BASE = `1.0.0.tar.gz`; RIGHT = the live 2.0.0 template-set). No standard/schema/
  constitution/scaffolder/template mutation; `constitution_version` stays 1.1.0.

### Added — B.8.14 promotion prepare-only bundle (`b8-14-promotion-prep`)

- **Governance prep for the point-of-no-return — applies NOTHING breaking.** The
  §VIII.1 (Kong→Envoy) Constitution amendment is process-gated by a ≥7-day public
  discussion window (Article XII + `GOVERNANCE.md §"Amendment Process"`), so
  B.8.14 is split: this brick is step 1 (a Forge change targeting the
  constitution, opening the window) + a staged bundle; a follow-up brick
  (`b8-14-promotion-flip`) ratifies + applies after the window.
- **Staged artifacts** (in the change dir, all inert): `amendment-viii-1.md` (the
  drafted §VIII.1 Envoy-SHALL replacement + Amendments-table row + target
  Constitution v1.1.0→v2.0.0, citing `VERSIONING.md:15-17` + the Amendment
  Process + the `d5-governance` precedent); `removal-manifest.yaml` (the exact,
  verified-real Kong/REST removal targets — `infra/kong/`, `fsm-kong`,
  `FSM_KONG_ADMIN_PORT`, scaffold-plan entry, REST routes, + the live
  `.forge/standards/infra/kong.md` standard → superseded by `gateway.yaml`);
  `flip-runbook.md` (ordered post-window ratify→apply→promote→remove→deprecate
  steps, framework version pinned to the pre-GA carve-out `VERSIONING.md:70-73`,
  t4 material-path note, 1.0.0 T+6-month deprecation draft).
- **`b8-14.test.sh`** — 15 L1 hermetic tests whose load-bearing assertions are
  NEGATIVE held-state guards (constitution still v1.1.0 + §VIII.1 still "Kong
  SHALL"; no Envoy amendment applied; 2.0.0 still `stage: candidate` /
  `scaffoldable: false`; `fsm-kong` + `infra/kong/` + `kong.md` intact; frozen
  snapshot byte-identical) so a premature flip cannot merge green. VIII.2
  (Temporal) NOT amended (B8O). No constitution/schema/standard/scaffolder
  mutation; `constitution_version` stays 1.1.0.

### Added — B.8.13 rollback runbook (`b8-13-rollback-runbook`)

- **`docs/ROLLBACK.md`** — operational rollback runbook for the
  full-stack-monorepo 1.0.0 → 2.0.0 migration: two scenarios (p99 regression
  `> 20 %` after the Envoy cutover → reverse the Kong → Envoy route weights;
  `traceparent` errors `> 1 %` → roll back the OTel SDK overlay only), each with
  Detect/Decide/Execute/Verify/Re-attempt steps, plus a last-resort full-tree
  `forge-migrate-flagship.sh --rollback`. Relative thresholds only — NO committed
  p50/p95/p99 number (ADR-B8-1-002 + CLAUDE.md ANTI-HALLUCINATION PROTOCOL).
  Resolves the `docs/MIGRATIONS.md` "see B.8.13 for the full runbook" forward
  reference. Runbook criteria are byte-consistent with the text embedded in
  `bin/forge-migrate-flagship.sh`.
- **Record-only supersession of `docs/ARCHITECTURE-TARGET.md` §11/§12.1** — the
  arch doc is sha256-pinned by `t4.test.sh::_test_t4_023`, so it is left
  byte-frozen (t4 stays green). `docs/ROLLBACK.md` carries a Supersession note
  enumerating its seven B8O-stale DBOS references (§11.1/§11.2 ×3/§11.3/§11.4 +
  §12.1) as obsolete per B8O, pointing at `orchestration.yaml` v1.2.0 — the same
  record-only pattern B8O itself used. No DBOS/CPU-based rollback criterion.
- **`b8-13.test.sh`** — 18 L1 hermetic tests (grep/diff/shasum, no toolchain),
  registered in `forge-ci.yml`; coupling guards re-run b8-12 + b8-10 + t4; a
  positive guard asserts ARCHITECTURE-TARGET.md's sha256 is unchanged.

## [0.4.0-rc.14] — 2026-06-04

### Added — B.8.12 E2E migration convergence gate (`b8-12-e2e-migration`)

- **2.0.0 after-state golden span inventory** committed at
  `.forge/changes/b8-12-e2e-migration/captures/full-stack-monorepo-2.0.0.span-inventory.yaml`
  — a strict **superset** of the 1.0.0 baseline 3-span set (client `SpanKind.client`,
  `http.request` server, `greeter.greet` internal); the phantom Flutter
  `user.interaction` root is absent from both goldens. NO committed p50/p95/p99
  number anywhere (Article III.4 + ADR-B8-1-002 + ADR-B812-001).
- **Migration E2E driver gate** — `b8-12.test.sh` drives
  `bin/forge-migrate-flagship.sh --target <tmpdir-copy> --dry-run` (L1 hermetic:
  exit 0 + additive-delta plan + no mutation + exit-7 wrong-version negative);
  the real Phase-2 overlay is an opt-in `FORGE_B8_12_LIVE` L2 leg. The committed
  `examples/forge-fsm-example/` stays 1.0.0 (git-clean; ADR-B812-004).
- **Rust S2S Connect client template** `transport_connect_client.rs.tmpl`
  (connectrpc `=0.6.1` client API — `HttpClient`/`ClientConfig`/`CallOptions`;
  auth/TLS/deadline/retry posture). The companion `Cargo.toml.tmpl` adds the
  connectrpc `client` feature (CARRY-1, verified LIVE). 1.0.0 + 2.0.0 server
  adapters stay byte-frozen (ADR-B812-003).
- **Envoy-OIDC wiring** — `security-policy.yaml.tmpl` (Envoy Gateway v1.8
  `gateway.envoyproxy.io/v1alpha1` `SecurityPolicy` with JWT folded into
  `spec.jwt.providers[]` + a `Backend` for the Zitadel jwks upstream;
  `<issuer>/oauth/v2/keys`, CARRY-2/4 verified LIVE) + a backend JWT validation
  middleware template (`jwt_middleware.rs.tmpl`, `jwt-authorizer` 0.15.x, CARRY-3).
  Cross-references `identity.yaml@1.1.0`; kustomization + envoy-gateway README
  updated. Kong preserved (Article VIII.1; ADR-B812-002).
- **Latency methodology** section added to `docs/MIGRATIONS.md` (p50/p95/p99
  measurement procedure anchored to `docs/B8-BASELINE.md §6` + the B.8.13
  rollback thresholds — relative percentages only, no committed ms figure).
- **Harness** `b8-12.test.sh` (~23 L1 hermetic + 4 L2 opt-in
  `FORGE_B8_12_LIVE`/`FORGE_E2E_TOOLCHAINS`) + `forge-ci.yml` registration.
  No standard bumped (transport.yaml/gateway.yaml/identity.yaml consumed only).
  Release target v0.4.0-rc.14.

## [0.4.0-rc.13] — 2026-06-03

### Changed — B.8.11 NSMA linter activation (`b8-11-nsma-linter`)

- **`state-management.yaml` bumped to v1.1.0 — `no-state-management-alternatives`
  (NSMA / ADR-006) rule activated.** `enforcement.ci_blocking` flipped
  `false → true`: the already-existing linter rule now emits `FAIL` (not `WARN`)
  when a `pubspec.yaml` declares a forbidden state-management package
  (`flutter_riverpod`, `riverpod`, `provider`, `get`, `getx`, `mobx`,
  `flutter_mobx`, `states_rebuilder`). Article VI.3 (`flutter_bloc` exclusively)
  is now machine-enforced.
- **Pure data + governance flip — NO new bash.** `constitution-linter.sh` is
  byte-unchanged (FAIL/WARN branch already keyed on `ci_blocking:`). The change
  is the YAML enforcement field, the governance docs, and the harness only.
- **`activation_planned: "B.8 (T6)"` replaced with `activated_by:
  "b8-11-nsma-linter (B.8.11, 2026-06-03)"`** — machine-readable audit trail
  (schema-legal under `enforcement.additionalProperties: true`). In-file
  version-history comment added; `pre_commit_hook` stays `false` (no runner ships).
- **`global/linting-rules.md`** gains an NSMA section (warn→fail activation,
  Article VI.3 + ADR-006 basis, FAIL message, backward-compat note) +
  `FORGE_LINTER_SKIP_NSMA=1` opt-out matrix row.
- **Q-001 ruling: no fresh Article XII amendment** — VI.3 + ADR-006 already
  mandate the blocking gate; B.8.11 is the scheduled activation, not a new rule
  (independent reviewer, 2026-06-03).
- **Backward-compat by construction:** zero scannable `pubspec.yaml` in the live
  tree after `/.forge/` + `/examples/` + `/.dart_tool/` exclusions — the live
  linter stays OVERALL PASS post-flip.
- **`REVIEW.md`** records the v1.1.0 `KEEP-WITH-CHANGES` row (structural exception
  preserved; transport.yaml v1.1.0 precedent). Harness `b8-11.test.sh`
  (16 L1 hermetic + 2 L2 opt-in `FORGE_LINTER_FIXTURE_ROOT`), registered in
  `.github/workflows/forge-ci.yml`. Release target v0.4.0-rc.13.

## [0.4.0-rc.12] — 2026-06-03

### Added — B.8.10 flagship 1.0.0→2.0.0 migration orchestrator (`b8-10-migrate-flagship`)

- **`bin/forge-migrate-flagship.sh` introduced — phased, additive 1.0.0→2.0.0
  migration orchestrator.** Bash-thin + Python-3-inline (mirrors
  `bin/forge-sbom.sh` / `.forge/scripts/compliance/bundle.sh`), `set -uo
  pipefail`. **SOURCEs `bin/forge-upgrade.sh`** and reuses its `_a7_*` 3-way merge
  library (`_a7_check_force_clean_git`, `_a7_classify`, `_a7_three_way_merge`,
  `_a7_append_upgrade_history`) — **one merge engine, no duplication**
  (ADR-B810-001). The `_a7_main` sourcing guard keeps sourcing side-effect-free;
  `_a7_check_version_compat` is deliberately never re-triggered.
- **Four phases.** Phase 0 preflight (manifest `archetype_version: 1.0.0` assert +
  Git-clean gate + frozen-snapshot sha256 verify); Phase 1 obs/contracts
  (assert-or-noop, idempotent); Phase 2 structural overlay (additive 3-way merge of
  the 27-file 2.0.0 template-set: Kong→Envoy, REST→Connect, Zitadel, Qwik web-public,
  pg17+pgvector); Phase 3/4 are forward-reference stubs (print plan, exit 0).
- **Exit envelope aligned to A.7: `0/2/5/7/8`** (ADR-B810-002). Flags:
  `--target --phase --dry-run --force --rollback --help`. `--rollback`/`--phase`
  mutually exclusive; `--dry-run` is default-safe across every phase and rollback
  (no mutation).
- **Additive-only — Kong / Temporal / REST preserved** (VIII.1/VIII.2 SHALL
  clauses binding until B.8.14; FR-B810-031). **No orchestration-swap leg** — the
  2.0.0 set has zero such files and the `temporal→embedded` delta is
  `cancelled: true` per B8O / ADR-B8O-001; Temporal is retained (FR-B810-032).
- **Rollback from the byte-frozen 1.0.0 snapshot** (`tar -xzf` of
  `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`); the snapshot and
  its `.sha256` are never rebuilt or overwritten (FR-B810-041).
- **Ledger:** appends one `upgrade_history` record with
  `kind: flagship-migration` via a thin `_b810_tag_last_history_kind` wrapper
  (identity fields frozen, append-only, `SOURCE_DATE_EPOCH`-deterministic date);
  `bin/forge-upgrade.sh` stays byte-unchanged (ADR-B810-004).
- **`docs/MIGRATIONS.md` 1.0.0→2.0.0 section filled** (the A.7 deferred stub):
  4-phase walkthrough, additive-first posture, B8O no-orchestration-swap note,
  B.8.13 rollback-criteria xref, stay-on-1.0.0 option, `scaffoldable: false`-until-
  B.8.14 caveat, doc-only invocation, manual Kong→Envoy canary-by-route runbook.
- **Harness `b8-10.test.sh`** (12 L1 hermetic ≤ 2 s + L2 opt-in `FORGE_B8_10_LIVE`),
  registered in `.github/workflows/forge-ci.yml`.
- **Pure tooling — no standard bump.** No `.forge/standards/*.yaml` edit;
  `constitution_version: 1.1.0` unchanged (T5.1 precedent).

## [0.4.0-rc.11] — 2026-06-03

### Added — B.8.9 Qwik web-public 2.0.0 frontend brick (`b8-9-qwik-web-public`)

- **2.0.0 web-public surface introduced — Qwik City public-facing web (additive).**
  New versioned subtree under
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/frontend/web-public/` with
  **ten** `.tmpl` files — a minimal, chart-less Qwik City skeleton (ADR-B89-002):
  `package.json` (Qwik + Connect-ES deps, verified scripts), `.nvmrc` (Node 24),
  `vite.config.ts` (`qwikCity()` + `qwikVite()` + `tsconfigPaths`), `tsconfig.json`
  (Qwik JSX, `~/*` alias), `qwik.env.d.ts` (triple-slash refs), `src/entry.ssr.tsx`
  (`renderToStream`), `src/root.tsx` (`QwikCityProvider` + `RouterOutlet`),
  `src/routes/index.tsx` (minimal `component$` landing route), `src/lib/connect-client.ts`
  (Connect-ES v2 browser client — `createConnectTransport` from `@connectrpc/connect-web`
  + `createClient` from `@connectrpc/connect`, one unary Greeter.SayHello example),
  and `README.md` (Status `scaffoldable: false` until B.8.14, Janus arbitration,
  Envoy Connect/HTTP path, web-backoffice-unchanged posture, Node setup, Vite-8
  pitfall, Connect-ES usage with the `protoc-gen-connect-es`-retired note, Zod
  deferral, scope-outs). KEEP Flutter mobile+desktop+backoffice; REPLACE the Flutter
  Web *public* surface → Qwik City (ADR-005, `ARCHITECTURE-TARGET.md:365-374`).
- **Verify-then-pin LIVE 2026-06-03.** Pins re-confirmed with NO drift from the
  design phase: `@builder.io/qwik ^1.20.0` + `@builder.io/qwik-city ^1.20.0`;
  `vite =7.3.5` EXACT (vite 8.0.16 is the npm `latest` but is EXCLUDED by Qwik
  peerDependencies `>=5 <8` — the Vite-8 trap, recorded in the standard + README);
  `@connectrpc/connect ^2.0.0` + `@connectrpc/connect-web ^2.0.0` (cross-referenced
  to `transport.yaml` v1.3.0 — single source of truth, not re-pinned); Node `24`
  (active LTS, satisfies Qwik engines `>=18.11`). The v2 `@qwik.dev/*` line stays
  beta-only (`2.0.0-beta.35`, NO GA) on the `qwik_v2_watch` future-option list.
  Evidence: `.forge/changes/b8-9-qwik-web-public/evidence.md` P-16..P-22.
- **`web-frontend.yaml` v1.0.0 — NEW standard (first web-frontend pin source).**
  Role-named (survives a Qwik→SvelteKit pivot without rename; gateway.yaml/identity.yaml
  precedent). `default: qwik-city`, `alternatives: [sveltekit]`, `forbidden: []`,
  `versions:` map (qwik/qwik_city/vite), `qwik_v2_watch` future-option block,
  `pin_review_cadence` (P30D framework / P12M node), `expires_at: 2027-06-03`
  (`exception_constitutional: false`), enforcement OFF (Iris-Web/K.4 territory).
  `index.yml` gains a `standards/web-frontend` trigger entry; REVIEW.md gains a
  `| web-frontend.yaml | 1.0.0 |` Created ledger row; `validate-standards-yaml.sh`
  (dir mode) PASSes.
- **2.0.0 `buf.gen.yaml.tmpl` es out-path re-pointed** from
  `../../frontend/lib/generated/connect/ts` to
  `../../frontend/web-public/src/lib/generated/connect` (ADR-B89-004) + a
  `B.8.9 delta` header bump-note. b8-6 T-003 greps plugin NAME sentinels only (NOT
  the out-path), so the re-point is coupling-safe; b8-6 stays 12/12 GREEN. The
  frozen 1.0.0 `shared/protos/buf.gen.yaml.tmpl` is byte-UNCHANGED.
- **`2.0.0.yaml` web-public surface** gains a `# B.8.9 — delivered; standard:
  web-frontend.yaml v1.0.0` comment-only annotation (and a `# B.8.9 — delivered`
  comment on the `no-web-public-layer → qwik-web-public` migration_delta, which
  keeps `strategy: additive-first`). Comment-only — the loaded dict is
  byte-identical to a YAML parser; b8-3 (17/17) + b8-3b (12/12) stay GREEN.
- **Frozen 1.0.0 surfaces byte-untouched** (additive-first; NFR-B89-002):
  `schema.yaml`, the flat 1.0.0 template tree, `1.0.0.tar.gz`, and the 1.0.0 buf.gen
  manifest are unchanged. Article VI (Flutter mandate) and Article VIII.1 (Kong
  SHALL) preserved — candidate stays `scaffoldable: false` until B.8.14.
- **Scope-outs DEFERRED (explicit, not silently omitted):** PWA → B.9.2; OIDC/PKCE
  → B.9.3; OTel wiring → B.8.12/B.7; streaming → B.7.10; hosting tiers → B.9.7;
  Iris-Web agent → K.4; web-surface CI workflow → B.8.10; Zod → B.9.2 (ADR-B89-003).
  Janus arbitrates the web-public + web-backoffice surfaces until Iris-Web/K.4.
- New harness `.forge/scripts/tests/b8-9.test.sh` (12 L1, ≤2 s, zero
  net/Docker/npm; registered in `forge-ci.yml` after `b8-7`), with a
  `protoc-gen-connect-es`-active-reference guard, a frozen-1.0.0-buf.gen guard, and
  an exit-code coupling guard re-running b8-3 + b8-3b + b8-6.

## [0.4.0-rc.10] — 2026-06-02

### Added — B.8.7 Zitadel 2.0.0 identity brick (`b8-7-zitadel`)

- **2.0.0 identity delta — Zitadel IdP introduced (ground truth: introduction,
  NOT migration).** The frozen flat 1.0.0 flagship ships NO identity component;
  this brick introduces Zitadel additively. New versioned subtree under
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/zitadel/` with
  **four** `.tmpl` files (chart-referenced hybrid — ADR-B87-001; NO
  `kustomization.yaml.tmpl`, no raw K8s manifests vendored): `values-forge.yaml`
  (Forge Helm values overlay — `masterkeySecretName` ref, DSN `secretKeyRef`,
  `configmapConfig.FirstInstance` first-org/admin/machine-user config,
  `login.enabled: true`, `postgresql.enabled: false`, Aegis pod annotations +
  hardened `securityContext`), `README.md` (chart-referenced delivery model,
  helm install block, T1/T2/T3 compliance table citing `compliance-tiers.md:121`,
  AGPL note, Envoy→Zitadel OIDC delegation doc with verbatim scope-out,
  shared-fsm-db datastore posture, dev-vs-K8s login topology note, J8-RULE-002
  xref), `docker-compose.fragment.yml` (single `fsm-zitadel` dev service,
  built-in login, `127.0.0.1:8123:8080` loopback, `depends_on: fsm-db`,
  `start-from-init --masterkeyFromEnv`), and `bootstrap.md` (FirstInstance
  contract with CHART-MANAGED `MachineKeyPath`/`PatPath` marked do-not-set, chart
  setupJob flow, OIDC client recipe via Management API `POST
  /projects/{project_id}/apps/oidc`, JWT signing-key rotation posture).
- **Chart-referenced hybrid + verify-then-pin LIVE 2026-06-02.** Atlas installs
  the upstream chart `zitadel/zitadel --version 10.0.2`; the brick vendors only
  the values overlay + docs. Pins: chart `10.0.2` ↔ appVersion `v4.14.0`
  (chart-tested pair; the newer `v4.15.0` is NOT chart-tested → not used); images
  `ghcr.io/zitadel/zitadel:v4.14.0` + `ghcr.io/zitadel/zitadel-login:v4.14.0`
  (ghcr.io, NOT docker.io — b8-coroot lesson; v-prefix). Re-verified live at
  implement (evidence.md P-15..P-21); `helm template` of chart 10.0.2 + overlay
  renders cleanly (HELM_RC=0, Aegis annotations + DSN secretKeyRef +
  securityContext effective in the rendered manifests).
- **`identity.yaml` v1.0.0 → v1.1.0 (additive).** First `versions:` map for this
  standard (Zitadel chart `10.0.2` / app `v4.14.0` / login `v4.14.0`, all ghcr.io)
  + `pin_review_cadence:` (chart P30D, images P12M); `last_reviewed`/`expires_at`
  refreshed to 2026-06-02/2027-06-02. `default: zitadel`, `alternatives`,
  `forbidden`, `compliance_tier_aware`, `enforcement`, `linter_rule`, `rationale`
  are **byte-stable**; no `breaking_change`. Machine enforcement stays off.
  REVIEW.md gains a `| identity.yaml | 1.1.0 |` KEEP-WITH-CHANGES ledger row;
  `validate-standards-yaml.sh` (dir mode) PASSes.
- **`2.0.0.yaml` zitadel component** gains a `# … B.8.7 delivered; versions
  (identity.yaml v1.1.0)` annotation on its `standard: identity.yaml` line
  (comment-only; the loaded dict is byte-identical to a YAML parser). The
  `implicit-auth → zitadel` migration_delta with `strategy: additive-first` is
  **intact** (implicit-auth removal only at B.8.14). b8-3 (17/17) + b8-3b (12/12)
  stay GREEN.
- **Frozen 1.0.0 surfaces byte-untouched** (additive-first; NFR-B87-002):
  `schema.yaml`, the flat 1.0.0 template tree, and `1.0.0.tar.gz` are unchanged.
- **Envoy OIDC wiring + backend auth middleware DEFERRED to B.8.10/B.8.12**
  (ADR-B87-006) — explicit verbatim scope-out in the README, not silently omitted.
- New harness `.forge/scripts/tests/b8-7.test.sh` (12 L1, ≤2 s, zero
  net/Docker/Helm; registered in `forge-ci.yml` after `b8-6`), with a secrets
  grep-guard, a CHART-MANAGED-key guard (no `MachineKeyPath`/`PatPath`), and an
  exit-code coupling guard re-running b8-3 + b8-3b.

## [0.4.0-rc.9] — 2026-06-02

### Added — B.8.6 Connect-RPC 2.0.0 transport brick (`b8-6-connect-rpc`)

- **2.0.0 transport delta — modernized Connect-RPC codegen + Rust crate line.**
  New versioned subtree under
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/` with **four** `.tmpl`
  files: `shared/protos/buf.gen.yaml` (full standalone 6-plugin codegen manifest —
  `neoeinstein-tonic`/`-prost`, `protocolbuffers/dart`, `connectrpc/go`,
  `bufbuild/es`, `connectrpc/dart` — connect-go refreshed `v1.19.2 → v1.20.0`,
  every other pin carried verbatim), `shared/protos/README` (Connect-RPC as the
  2.0.0 default transport + the gRPC-Web-via-Envoy fallback doc),
  `backend/crates/grpc-api/src/transport_connect.rs` (the adapter rewritten for the
  connectrpc 0.6.x handler surface — `Context` + `OwnedView<…View<'static>>` →
  `Result<(Resp, Context), ConnectError>`; axum mount `ConnectRouter::new()` +
  `into_axum_service()`, CHANGED from the 0.3.x `into_axum_router()`; build.rs
  path-α codegen preserved), and `backend/crates/grpc-api/Cargo.toml` (the
  modernized pin set).
- **Rust Connect crate pins modernized 0.3.x → 0.6.x (verify-then-pin LIVE
  2026-06-02).** `connectrpc = "=0.6.1"` + `connectrpc-build = "=0.6.1"`
  (build-dep) + `buffa = "=0.6.0"` + `buffa-types = "=0.6.0"` (normal dep, upstream
  `eliza` posture). `connectrpc 0.6.1` declares `buffa = "^0.6"` → only `0.6.0`
  resolves (`0.7.0` out-of-range). `features = ["axum"]` required (non-default).
  Resolved live against the crates.io REST API (evidence.md P-12); BSR
  `buf.build/connectrpc/go:v1.20.0` availability confirmed live (P-13); the 0.6.x
  handler + mount surface confirmed live (P-14). The connectrpc family stays
  pre-1.0 — WAIVER comment records the re-review trigger at the 1.0 milestone.
- **`transport.yaml` v1.2.0 → v1.3.0 (additive).** Added a
  `codegen.versions_2_0_0:` sibling block carrying the 2.0.0-line Rust Connect
  crate pins (+ JS/Dart/Go carry-over annotations; connect-go `1.20.0` in the
  2.0.0 sub-block only); fixed the stale "v1.1.0" header drift. The 1.0.0-line
  `codegen.versions` map is **byte-unchanged**; no breaking change. REVIEW.md gains
  a `| transport.yaml | 1.3.0 |` KEEP-WITH-CHANGES ledger row;
  `validate-standards-yaml.sh` (dir mode) PASSes.
- **`2.0.0.yaml` connect-rpc component** gains a `# … B.8.6 delivered` annotation
  on its `standard: transport.yaml` line (comment-only; the loaded dict is
  byte-identical to a YAML parser). The `rest-bridge → connect-rpc`
  migration_delta with `strategy: additive-first` is **intact** (REST-bridge
  removal only at B.8.14). b8-3 (17/17) + b8-3b (12/12) stay GREEN.
- **Frozen 1.0.0 surfaces byte-untouched** (additive-first; NFR-B86-002): the flat
  `shared/protos/buf.gen.yaml.tmpl` (connect-go `v1.19.2`, connectrpc `=0.3.3`),
  the flat `transport_connect.rs.tmpl` (`into_axum_router()`), the flat
  `Cargo.toml.tmpl`, and `schema.yaml` are all unchanged.
- **Rust S2S Connect client RE-DEFERRED to B.8.12** (ADR-B86-004) — explicit, not
  silently omitted (TLS/auth/deadline/retry belong to the E2E convergence gate).
- New harness `.forge/scripts/tests/b8-6.test.sh` (12 L1, ≤2 s, zero net/Docker;
  registered in `forge-ci.yml` after `b8-5`), with frozen-1.0.0 byte-sentinel
  guards + an exit-code coupling guard re-running b8-3 + b8-3b.
- **Sibling-harness coupling bumps** (full ~45-harness pre-push sweep caught
  both, per the `full_harness_suite_before_push` discipline): `t5.test.sh`
  `_test_t5_009` and `t5-cargo.test.sh` `_test_t5c_l1_004_standard_version`
  hard-pinned `transport.yaml` `version: "1.2.0"` — both bumped to `"1.3.0"`
  with comment trails (ADR-B8-OBI-006 hybrid precedent); the 1.0.0 pin
  assertions they carry are untouched and stay GREEN. Full suite 45/45 GREEN.

### Changed — B.8 orchestration default reconciled with Constitution §VIII.2 (`b8-orchestration-temporal-realign`)

- **Temporal is now the orchestration default for Rust; DBOS demoted to a
  watch-list future-option.** `orchestration.yaml` v1.1.0 → **v1.2.0** (additive):
  the flat `default: dbos` / `fallback` / `fallback_trigger` are replaced by
  `default_by_language: { rust: temporal }` (Constitution §VIII.2 — workflows SHALL
  use Temporal), and DBOS moves to a `dbos:` `future-option` block
  (`available: false`, `requires: rust-sdk-ga`, `revisit: 2027-05-31`) — **NOT
  deleted**. Rationale: DBOS has **no Rust SDK** (crates.io `dbos` 404; Python/TS/
  Go/Java/Kotlin only), and Forge backends are Rust end-to-end, so `default: dbos`
  was unbuildable. **No Constitution amendment** — §VIII.2 already mandates Temporal,
  so this aligns the standard with the Constitution (contrast B.8.4's VIII.1
  Kong→Envoy). ADR-002's Temporal→DBOS swap is **cancelled for Rust** (ADR-B8O-001).
- **`2.0.0.yaml` candidate:** `dbos-embedded` → `status: future-option`; the
  `temporal-intent → dbos-embedded` migration_delta marked `cancelled: true` (kept
  for audit). b8-3 (17/17) + b8-3b (12/12) stay GREEN.
- **`infra/temporal.md` realigned** to the real published `temporalio-sdk` 0.4.0 API
  (attribute macros `temporalio_macros::{workflow,activities}`, `WorkflowContext` /
  `ActivityContext`, `Worker` / `WorkerOptionsBuilder`), replacing fabricated
  community-crate symbols. Added a **pre-alpha stability caveat** (native Rust SDK
  workflow API "very unstable"; activity-only workers are the stable path). Crate
  version verify-then-pin LIVE 2026-06-01: `temporalio-sdk = 0.4.0`,
  `temporalio-client = 0.4.0` (crates.io) — pinned in consuming `Cargo.toml`, not
  the standard. Evidence: `.forge/changes/b8-orchestration-temporal-realign/evidence.md`.
- **Coupled updates:** `b8-5.test.sh` T-006 + T-010 repurposed to guard the realigned
  invariants; `constitution-linter.sh` + `forbidden-components-rules.md` T3-RULE-003
  remediation hints point at Temporal. New harness `b8o.test.sh` (10 L1) registered in
  `forge-ci.yml`. Roadmap (`docs/new-archetypes-plan.md`) B.8.5/B.8.10/B.8.13/B.6.2
  deltas applied (B.6 now uses the native Rust SDK, not a Go-SDK FFI/REST bridge).

### Added — B.8.5 Postgres 17 + pgvector 2.0.0 datastore brick (`b8-5-postgres-pgvector`)

- **2.0.0 datastore delta — Postgres 16 → 17 + pgvector.** New versioned subtree
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/postgres/` with
  three `.tmpl` files: `docker-compose.fragment.yml` (a dev-compose `fsm-db`
  service fragment mirroring the frozen 1.0.0 `fsm-db` shape — env, named
  `fsm-db-data` volume, `pg_isready` healthcheck, `fsm-dev` network — bumped to
  the pgvector image), `init-pgvector.sql` (`CREATE EXTENSION IF NOT EXISTS
  vector;` mounted into `docker-entrypoint-initdb.d`), and a `README`. The image
  is verify-then-pin RESOLVED LIVE 2026-05-31 to `pgvector/pgvector:0.8.2-pg17`
  (Docker Hub; latest pgvector 0.8.x on Postgres 17, deterministic explicit tag,
  satisfies `persistence.yaml` postgres-17 + pgvector-0.8; see
  `.forge/changes/b8-5-postgres-pgvector/evidence.md`). `persistence.yaml` v1.0.0
  is **consumed** as-is (no new standard, no bump). The flat 1.0.0
  `docker-compose.dev.yml.tmpl` (`postgres:16-alpine`) and frozen `schema.yaml`
  are **byte-untouched** (additive-first; ADR-B85-001).
- **DBOS DEFERRED — no Rust SDK; Temporal RETAINED.** The plan's B.8.5
  DBOS-embedded premise is FALSIFIED: DBOS has no Rust SDK (crates.io `dbos`
  404; DBOS Transact = Python/TypeScript/Go/Java only — Context7
  `docs.dbos.dev`). This brick ships **NO** `dbos` crate pin / `Cargo.toml dbos
  = 0.x` / DBOSContext (Article III.4). `orchestration.yaml` 1.0.0 → 1.1.0
  (additive) records the finding in a new `rust_sdk_status.dbos` block
  (`available: false`, `rust_flagship_orchestrator: temporal`,
  `default_is_language_conditional: true`); `default: dbos` is UNCHANGED but
  recorded as a language-conditional aspirational non-Rust target. REVIEW.md
  gains a `| orchestration.yaml | 1.1.0 |` KEEP-WITH-CHANGES ledger row;
  `validate-standards-yaml.sh` (dir mode) PASSes. Article VIII.2 (Temporal SHALL)
  is PRESERVED — no amendment.
- **`2.0.0.yaml` dbos-embedded** gains `status: deferred` + a `note:`; the
  `temporal-intent → dbos-embedded` migration_delta is annotated DEFERRED. The
  `postgres-17-pgvector` component (`standard: persistence.yaml`) + the
  `postgres-16-no-pgvector → postgres-17-pgvector` migration_delta are INTACT
  and now actively delivered. b8-3 (17/17) + b8-3b (12/12) stay GREEN.
- New harness `.forge/scripts/tests/b8-5.test.sh` (12 L1, ≤5 s, zero net/Docker;
  registered in `forge-ci.yml` after `b8-4`), with anti-hallucination grep-guards
  (no fabricated/non-pg17 image; no `dbos` crate token) + an exit-code coupling
  guard re-running b8-3 + b8-3b.

### Added — B.8.4 Envoy Gateway 2.0.0 template brick (`b8-4-envoy-gateway`)

- **First real 2.0.0 template brick of the flagship 1.0.0 → 2.0.0 migration.**
  New versioned subtree
  `.forge/templates/archetypes/full-stack-monorepo/2.0.0/infra/k8s/envoy-gateway/`
  with six `.tmpl` files: `gatewayclass`, `gateway`, `httproute`,
  `backendtlspolicy` (Gateway-API-native, `gateway.networking.k8s.io/v1`),
  `kustomization`, and a `README` documenting the Atlas-provided Helm
  control-plane install. The flat 1.0.0 Kong tree and frozen `schema.yaml` are
  **byte-untouched** (additive-first, Envoy ∥ Kong → `fsm-backend`).
- **New ROOT-level J.7 standard `.forge/standards/gateway.yaml`** — the gateway
  pin source born here. Verify-then-pin (resolved live 2026-05-31, see
  `.forge/changes/b8-4-envoy-gateway/evidence.md`): Envoy Gateway Helm chart
  `v1.8.0` (`oci://docker.io/envoyproxy/gateway-helm`) + Gateway API CRD bundle
  `v1.5.1` (EG `v1.8.0` `go.mod`). `BackendTLSPolicy` is GA at
  `gateway.networking.k8s.io/v1` as of Gateway API `v1.5.1` (Standard channel) —
  all four resources use GA `v1`, no `v1alpha3`/`v1beta1` drift. Registered in
  `index.yml` + a `| gateway.yaml | 1.0.0 |` REVIEW.md birth-ledger row;
  `validate-standards-yaml.sh` (dir mode) PASSes.
- **`2.0.0.yaml` envoy-gateway component** flips `pin_source: B.8.4` →
  `standard: gateway.yaml` (candidate edit; the standard exists first so b8-3
  `standard:`-ref resolution stays GREEN). Control-plane (Envoy Gateway
  controller + Gateway API CRDs) is the upstream OCI Helm chart (Atlas-provided,
  not vendored); data-plane is the kustomize manifests. Connect/gRPC-Web
  pass-through — no gateway-side REST↔gRPC transcoding (that ownership is B.8.6).
- New harness `.forge/scripts/tests/b8-4.test.sh` (12 L1, ≤5 s, zero net/Docker;
  kustomize build is skip-pass). T-012 is an exit-code coupling guard that
  re-runs b8-3 (17/17) + b8-3b (12/12) so the shared-standard sibling harnesses
  stay GREEN under the `2.0.0.yaml` edit. Registered in `forge-ci.yml` after
  `b8-3b.test.sh` (277/300, NFR-CI-002 preserved).

### Changed — bump GitHub Actions off Node 20 (deprecation deadline 2026-06-16)

- Forge's own runnable workflows (`forge-ci.yml`, `forge-compliance.yml`) now
  pin the latest Node24-compatible majors: `actions/checkout@v6`,
  `actions/setup-node@v6`, `actions/setup-python@v6`, `actions/upload-artifact@v7`,
  `dorny/paths-filter@v4`. `ludeeus/action-shellcheck@2.0.0` is a Docker action,
  unaffected. Clears the "Node.js 20 actions are deprecated" warnings ahead of
  GitHub forcing Node 24 on 2026-06-16.
- Coupled assertions updated in lockstep: `c1.test.sh` (forge-ci example-job
  paths-filter pin → v4), `i5.test.sh` (forge-compliance pins → v6/v6/v7);
  `g1.test.sh` error strings made version-agnostic. Specs/standards describing
  these two workflows (`forge-ci.md`, `forge-compliance-workflow.md`,
  `forge-self-ci.md`) synced.
- **Out of scope (follow-up):** the archetype *template* CI workflows
  (`.forge/templates/.../.github/workflows/*.tmpl`) still pin the older majors —
  bumping them touches rendered examples + the frozen b8-2 1.0.0 snapshot
  (sha-guarded), so it is deferred to a dedicated change.

### Added — B.8.3.b validator versioned-schema discovery (`b8-3b-validator-versioned-schema`)

- Makes the B.8.3 candidate (`full-stack-monorepo/2.0.0.yaml`) **gate-visible**.
  `validate-foundations.sh` gains `check_versioned_schema_siblings()`: it
  discovers versioned schema files `<archetype>/<X.Y.Z>.yaml` alongside the
  canonical `schema.yaml` and validates each with the schema rule-set plus two
  new invariants — **filename↔version** (`X.Y.Z.yaml` ⇒ `version: "X.Y.Z"`) and
  **`stage: candidate` ⇒ `scaffoldable: false`** (stable/draft exempt, so the
  frozen 1.0.0 `schema.yaml` keeps validating). Emits
  `PASS/FAIL: FR-GL-001-versioned:<arch>/<file>`.
- **Generic + strict superset**: archetypes with no versioned sibling are a
  no-op (only `full-stack-monorepo/2.0.0.yaml` exists today). `verify.sh` and
  `constitution-linter.sh` are **byte-unchanged** (they only resolve layer
  paths, not validate schema content); the new PASS line surfaces through
  verify.sh's existing aggregation.
- Scaffolder runtime guard for `scaffoldable: false` is **deferred to B.8.14**
  (the scaffolder cannot select a versioned schema today — `cli.ts` hard-codes
  `schema.yaml`); today's enforcement is the validator invariant.
- New harness `.forge/scripts/tests/b8-3b.test.sh` (12 L1, ≤5 s) with
  discriminating negative fixtures (mutate a copy of `2.0.0.yaml` in a tmp
  `FORGE_ROOT`; real schemas never touched). Registered in `forge-ci.yml`.

### Fixed — `validate-foundations.sh` crash silently disabled FR-GL-017

- `validate-foundations.sh` exited 1 standalone with `TypeError: unhashable
  type: 'dict'` in `check_multi_layer_change_metadata` (FR-GL-017). The check
  treated each change's `.forge.yaml` `layers:` as bare id-strings and did
  `l not in known_ids` (set membership), but every multi-layer change uses the
  `{id, path}` mapping shape — hashing a dict crashed. Under `set -e` the
  script aborted mid-run, so FR-GL-017 (the last check) **never actually
  validated multi-layer metadata**; `verify.sh` masked it by grepping
  `PASS:`/`FAIL:` lines instead of the exit code, so CI stayed green.
- Fix: normalise layer entries to ids (`l.get('id')` for mappings, else `l`)
  before the membership test. FR-GL-017 is now live — inspects 43 changes,
  all consistent, zero new failures. `validate-foundations.sh` exits 0
  standalone again. Regression test added (`foundations.test.sh`:
  `test_dict_shaped_layers_do_not_crash_fr_gl_017`).

### Added — B.8.3 flagship 2.0.0 candidate schema (`b8-3-schema-candidate`)

- **First code-bearing brick of the flagship 1.0.0 → 2.0.0 migration.** New
  `.forge/schemas/full-stack-monorepo/2.0.0.yaml` (`stage: candidate`,
  `scaffoldable: false`) — the single target-of-record consumed by the
  downstream migration bricks B.8.4–B.8.12. The frozen 1.0.0 `schema.yaml`
  (B.8.2 maintenance-freeze) is **byte-untouched**; the candidate is a
  versioned sibling.
- **Reference-only component SET** — declares the 6 target components
  (Envoy gateway, DBOS, Connect-RPC, Zitadel, Postgres 17 + pgvector,
  SigNoz/OBI/Coroot) by name + role + owning standard yaml, with **no inline
  version pins** (pins arrive with B.8.4–B.8.7; the Envoy gateway has no
  standard source yet and carries `pin_source: B.8.4`).
- **`migration_deltas[]`** (6) — canonical 1.0.0 → 2.0.0 delta record for the
  B.8.12 zero-regression gate and the B.8.14 version-bump contract.
- **Web surface split** — `frontend.surfaces` declares `web-backoffice`
  (Flutter Web) + `web-public` (Qwik, new in 2.0.0) as sub-paths under the
  `frontend` layer; the backend/frontend/infra triple (FR-GL-001) and Janus
  `layers_count_ge: 2` routing are preserved.
- **Constitutional prohibition recorded in-schema** — Articles VIII.1 (Kong)
  and VIII.2 (Temporal) remain IN FORCE; the candidate declares the target
  only and MUST NOT be scaffolded/deployed before the B.8.14 `GOVERNANCE.md`
  Amendment Process completes (plan §4.2 B.8.14).
- New harness `.forge/scripts/tests/b8-3.test.sh` (17 L1) — the **only** gate
  aware of the candidate; the three shared validators stay unaware until the
  proposed follow-on brick B.8.3.b rewires versioned-schema discovery. L1 ≤ 5 s,
  zero net/Docker. Registered in `forge-ci.yml` after `b8-2.test.sh`.

## [0.4.0-rc.8] — 2026-05-30

### Fixed — `full-stack-monorepo` `task dev:up` dead pins (post-rc.7 hotfix)

- **`kong:3.6-alpine` → `kong:3.6`** — Kong dropped the `-alpine` suffix;
  the pinned tag returned `manifest unknown`, breaking `task dev:up` /
  `task validate`. New pin verified live (verify-then-pin, b8-coroot lesson).
- **`fsm-backend` placeholder healthcheck** — `traefik/whoami` is FROM
  scratch (no shell/curl), so its `CMD-SHELL curl` healthcheck always errored
  → never healthy → `fsm-kong` (depends_on `service_healthy`) blocked. Fixed:
  healthcheck `disable: true` + `fsm-kong` depends_on `fsm-backend` →
  `condition: service_started`.
- **Rendered-example drift** — the two `examples/forge-fsm-example/docker-compose.dev.yml`
  mirrors were stale pre-T5.3.1 (`image: scratch`, which cannot run at all);
  synced to the template (`traefik/whoami:v1.11.0`). Applied across all 6
  mirror copies.
- **Frozen 1.0.0 snapshot regenerated** (audited patch per the B.8.2
  maintenance-freeze carve-out): `1.0.0.tar.gz` sha `1d0b05cd…` → `8d439b94…`,
  `1.0.0.sha256` + REVIEW.md ledger updated in lockstep so the reverse target
  is a working 1.0.0.
- Verified: `task dev-up-matrix` `[PASS] full-stack-monorepo : dev:up`, full
  `task validate` → "ALL CHECKS GREEN"; `b8-2.test.sh` 4/0, `a7.test.sh`
  29/0, `t5-3-1.test.sh` 9/0.

## [0.4.0-rc.7] — 2026-05-30

### Added — B.8.2 flagship 1.0.0 snapshot freeze (`b8-2-legacy-snapshot`)

- **Second Module B.8 brick.** Freezes `full-stack-monorepo / 1.0.0` as the
  immutable reverse target for `forge upgrade` ahead of the 1.0.0 → 2.0.0
  point of no return. The tarball is **not rebuilt** — the existing rc.6
  1.0.0-final artifact is frozen as-is.
- New `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.sha256` integrity
  manifest (`shasum -c` format) pinning the frozen tarball.
- New harness `.forge/scripts/tests/b8-2.test.sh` (4 L1): sha guard (FAILS if
  the tarball drifts/rebuilt/corrupted), extractable re-assert, freeze-section
  + REVIEW.md reachability. Registered in `forge-ci.yml` (300/300 preserved).
- `global/upgrade-policy.md` gains a "Snapshot maintenance-freeze" section +
  REVIEW.md ledger entry: 1.0.0 enters maintenance-freeze (all changes target
  2.0.0; the 2.0.0 snapshot builds to a new `2.0.0.tar.gz`, never overwriting
  1.0.0). **No `legacy/` directory** — the version-keyed path
  `<archetype>/<from_version>.tar.gz` that `forge-upgrade.sh` already reads IS
  the legacy archive (reconciles plan §4.2 wording with the live mechanism).
- New consolidated spec `.forge/specs/b8-legacy-snapshot.md` (`FR-B8-2-*`).

## [0.4.0-rc.6] — 2026-05-30

### Added — B.8.1 flagship baseline audit (`b8-1-audit-baseline`)

- **First item of Module B.8** (flagship `full-stack-monorepo / 1.0.0` →
  `2.0.0` migration). Pure audit artifact — no migration code, no template /
  standard / schema mutation, fully reversible.
- New `docs/B8-BASELINE.md`: deployed component/version matrix, demo-005 W3C
  trace coverage, re-measurement methodology. Consumed by B.8.12 (regression
  gate), B.8.13 (rollback runbook), B.8.5 (DBOS).
- New `.forge/baselines/full-stack-monorepo-1.0.0.span-inventory.yaml`:
  machine-readable, source-cross-checked span inventory (forward-stable for
  B.9 / B.6 / B.7 baselines).
- New harness `.forge/scripts/tests/b8-1.test.sh` (10 L1 + 1 L2 opt-in
  `FORGE_B8_1_DOCKER=1`), registered in `forge-ci.yml`.
- New consolidated spec `.forge/specs/b8-baseline.md` (`FR-B8-1-*` namespace).
- **Four anti-hallucination findings recorded (Article III.4)** against the
  plan's assumptions: (1) no Temporal worker is deployed (documentary only) —
  no MTBF fabricated, guarded by a negative harness test; (2) `fsm-backend`
  is a placeholder (`image: scratch`) so live end-to-end latency is not
  capturable from the example unmodified — latency baseline is methodology,
  not numbers; (3) Postgres is **16** (no pgvector), not the 17 target; (4)
  demo-005 emits **3** code-verified spans, not the doc's claimed 4 (the
  connectrpc handler shares the server span).

### Fixed — `t5-cargo` changelog test release-tolerant

- `_test_t5c_l1_010_changelog_entry` now greps the whole `CHANGELOG.md`
  instead of only the `[Unreleased]` section. `t5-cargo-pin-refresh` shipped
  in v0.3.3, so its entry graduated to `## [0.3.3]` and the old
  `[Unreleased]`-scoped assertion failed on every post-release CI run.

## [0.4.0-rc.5] — 2026-05-29

### Changed — OBI/Beyla major bump 2.0.1 → 3.15.0 (B.8.8, `b8-obi-refresh`)

- **Closes the `b8-observability-rearch` trio** (sibling 3 of 3 — Coroot leg 1
  v0.4.0-rc.3 + SigNoz leg 2 v0.4.0-rc.4 + OBI leg 3 v0.4.0-rc.5). Reserved
  scope held by sibling 2 (NFR-B8-SIG-011 / FR-B8-SIG-J-001) is now consumed.
- Refreshed `templates/full-stack-monorepo/.../infra/k8s/base/obi-daemonset.yaml.tmpl`
  image pin `grafana/beyla:2.0.1` → `grafana/beyla:3.15.0`. Multi-arch
  (amd64+arm64) confirmed live via `docker manifest inspect grafana/beyla:3.15.0`
  on 2026-05-29 (digests captured in `evidence.md` § 1) — verify-then-pin
  discipline (lesson T5.3.2 institutionalised).
- ClusterRole **RBAC widened** (ADR-B8-OBI-003) — added `services` resource
  to the `apiGroups: [""]` rule per Beyla 3.x official docs (Context7
  `/grafana/beyla` cilium-compatibility.md). Read-only verbs preserved
  (`get/list/watch`) ; least-privilege invariant upheld. No new API
  groups ; no write verbs.
- Aegis re-audit pass (per ADR-B8-OBI-002/003/004) :
  - **Linux capabilities UNCHANGED** — the 8-cap set (BPF / SYS_PTRACE /
    NET_RAW / CHECKPOINT_RESTORE / DAC_READ_SEARCH / PERFMON / NET_ADMIN /
    SYS_ADMIN) matches Beyla 3.x distributed-traces.md verbatim. Forge
    flagship enables W3C `traceparent` E2E propagation ⇒ NET_ADMIN
    required + SYS_ADMIN recommended.
  - **Kernel floor UNCHANGED** at 5.8 — Beyla 3.x README Requirements
    section confirms 5.8+ with BTF still mandatory. Opt-in nodeSelector
    `forge.dev/kernel-min-58: "true"` preserved verbatim ; zero migration
    burden for adopters already labelling.
- `.forge/standards/observability.yaml` **v2.0.0 → v2.1.0 additive minor** :
  - UPDATE `versions.beyla: "2.0.1"` → `"3.15.0"` (no v-prefix preserved
    per inline `versions:` block convention).
  - UPDATE `last_reviewed: 2026-05-26 → 2026-05-29` ;
    `expires_at: 2027-05-26 → 2027-05-29`.
  - FLIP `breaking_change: true → false` (sibling 2 ARCH-CHANGE state
    consumed ; additive minor bump per standards-lifecycle.md § Bumps —
    NO WAIVER required, sibling 2 WAIVER block preserved Article V
    append-only).
  - `pin_review_cadence.beyla: "P12M"` preserved (slow OBI cadence).
  - `rationale:` extended with the OBI bump trigger + RBAC widen +
    Aegis re-audit outcomes section.
- `.forge/standards/REVIEW.md` ledger appended 2026-05-29 with the
  `Updated` flag (NOT `ARCH-CHANGE` — reserved for breaking shifts
  per FR-B8-SIG-H-006 precedent).
- **4-copy mirror sync** byte-identical : canonical `.tmpl` + cli-bundle
  `.tmpl` + rendered example + cli-bundle rendered example (no example-side
  `.forge/templates/...` mirror — unlike SigNoz 6-copy, this is K8s-only
  not docker-compose).
- New harness `.forge/scripts/tests/b8-obi.test.sh` — **22 L1 grep tests
  + 2 L2 opt-in** via `FORGE_B8_OBI_DOCKER=1` (manifest pullable + old-pin
  informational). Registered in `.github/workflows/forge-ci.yml::harness`
  matrix ; line budget compressed by 3 audit comments per ADR-B8-OBI-007
  (mirroring ADR-T533-002) ; **300/300 lines preserved** (NFR-CI-002).
- **Sibling-harness coupling break** (ADR-B8-OBI-006 hybrid) — narrowed
  `t5-otel.test.sh:128/233` (pin VALUE ownership transferred to
  `b8-obi.test.sh` ; t5-otel asserts only invariants) + widened
  `b8-coroot.test.sh` + `b8-signoz.test.sh` date / version / breaking_change
  regex windows (1-char widening accepts trio-internal additive bumps
  without future sibling-harness sweep). Closes the institutionalised
  `shared_standard_sibling_harness_coupling.md` debt for this trio.
- Snapshot regenerated (`bin/forge-snapshot.sh build full-stack-monorepo
  1.0.0`) — 675088 B, well under the 716800 B ceiling (ADR-B8-SIG-008,
  ~42 KB headroom remaining) ; cli-bundle mirror byte-identical.
  `a7.test.sh` 29/29 PASS preserved.
- Tracked at `.forge/changes/b8-obi-refresh/` ; 8 ADRs
  (`ADR-B8-OBI-001..008`) ; Q-001..Q-007 all resolved at `/forge:design`.
  Sibling 3 of 3 — release vehicle : **v0.4.0-rc.5** (trio closure
  release).

## [0.4.0-rc.4] — 2026-05-28

### Fixed — SigNoz 3-service → unified arch migration (B.8.8, `b8-signoz-unified`)

- **Debloque the `task validate dev-up-matrix` RED known-issue** carried by
  `v0.4.0-rc.2` / `v0.4.0-rc.3`. The legacy 3-service SigNoz pins
  (`signoz/frontend:0.55.1` + `signoz/query-service:0.55.1` +
  `otel/opentelemetry-collector-contrib:0.96.0`) rotted on Docker Hub
  (`docker manifest inspect` → `no such manifest`, re-confirmed live
  2026-05-27). Every adopter scaffolding the flagship inherited a compose
  that failed ImagePull on the SigNoz services.
- Migrated `docker-compose.dev.yml.tmpl` to the SigNoz **unified
  architecture** (`v0.125.1`) — **6 services** (4 long-running + 2 init,
  ADR-B8-SIG-001/-007) :
  - `fsm-signoz` (`signoz/signoz:v0.125.1`) — unified UI + query-service +
    alertmanager + embedded sqlite app state ; UI host
    `${SIGNOZ_UI_PORT:-3301}` → container `:8080` (ADR-B8-SIG-004 preserves
    the `:3301` default).
  - `fsm-signoz-otel-collector` (`signoz/signoz-otel-collector:v0.144.4`) —
    OTLP `:4317` (gRPC) + `:4318` (HTTP). OPAMP **OFF** in dev
    (ADR-B8-SIG-003) — static config via `SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_*`
    env, mirroring upstream (no `OPAMP_*` vars).
  - `fsm-signoz-clickhouse` (`clickhouse/clickhouse-server:25.5.6`, bumped
    24→25 per ADR-B8-SIG-002) + `fsm-signoz-zookeeper`
    (`signoz/zookeeper:3.7.1`, replication coordinator, ADR-B8-SIG-007).
  - `init-clickhouse` + `fsm-signoz-telemetrystore-migrator` init containers
    (`restart: on-failure`).
- `.forge/standards/observability.yaml` **v1.2.0 → v2.0.0 BREAKING** :
  - ADD `versions.{signoz: "v0.125.1", signoz_otel_collector: "v0.144.4",
    clickhouse: "25.5.6", signoz_zookeeper: "3.7.1"}`. v-prefix MANDATORY on
    the two `signoz/*` repos (evidence § 1.4) — **opposite** of `coroot` /
    `beyla` which carry no prefix.
  - ADD top-level `pin_review_cadence:` map (ISO 8601 durations `P30D` /
    `P12M`). Additive — **no `standard.schema.json` edit** required, accepted
    via the `additionalProperties: true` root posture per **ADR-J7-004**.
  - `breaking_change: true` marker + WAIVER block citing
    `standards-lifecycle.md` § Bumps + ADR-J7-004.
  - `last_reviewed: 2026-05-26` ; `expires_at: 2027-05-26`.
  - `rationale:` extended with the SigNoz CE jurisdiction posture
    (ADR-B8-SIG-006 — SigNoz Inc Delaware-incorporated US ; CE self-host
    T1/T2 OK ; T3 candidate-substitution flag at deployment-time Demeter
    pass ; SigNoz Cloud out of scope). `versions.beyla` UNCHANGED at `2.0.1`
    (reserved for trio sibling 3 `b8-obi-refresh`, NFR-B8-SIG-011).
- `.forge/standards/REVIEW.md` ledger appended 2026-05-26 with the new
  **`ARCH-CHANGE`** flag (NOT `Updated`) — first use, distinguishing a
  breaking architectural shift from a version refresh (FR-B8-SIG-H-006).
- **6-copy mirror sync** byte-identical : canonical `.tmpl` + cli-bundle
  `.tmpl` + example-side `.tmpl` + cli-bundle example `.tmpl` + rendered
  example + cli-bundle rendered example.
- New harness `.forge/scripts/tests/b8-signoz.test.sh` — 17 L1 grep tests +
  6 L2 opt-in via `FORGE_B8_SIGNOZ_DOCKER=1` (4 manifests multi-arch
  pullable + compose-up healthy + rotted 3-svc pins denied). Registered in
  `.github/workflows/forge-ci.yml::harness` matrix (300/300 lines,
  NFR-CI-002).
- Snapshot regenerated (`bin/forge-snapshot.sh build full-stack-monorepo
  1.0.0`) ; cli-bundle mirror byte-identical. A.7 forge-upgrade
  backward-compat preserved (`a7.test.sh` 29/29 PASS across the breaking
  bump).
- Tracked at `.forge/changes/b8-signoz-unified/` ; 7 ADRs
  (`ADR-B8-SIG-001..007`) ; Q-001..Q-006 all resolved. Sibling 2 of the
  `b8-observability-rearch` trio. Release vehicle : `v0.4.0-rc.4`.

### Archived — T5.3 Workiva → Dartastic OTel substitution (`t5-otel-dartastic-realign`)

- Change `t5-otel-dartastic-realign` flipped `implemented` → `archived`
  on 2026-05-26 (timeline entry `archived: 2026-05-26`).
  Constitution version `1.1.0` (no amendment).
- Consolidated spec promoted to `.forge/specs/otel-dartastic-realign.md`
  with the 76 FRs `FR-T53-A-001..030 / B-001..015 / C-001..010 / D-001..006 /
  E-001..018 / F-001..004 / G-001..004` + 10 NFRs `NFR-T53-001..010` +
  3 BDD scenarios `BDD-T53-001..003` preserved verbatim from the
  change's `specs.md`. Article V immutability honored — no edit
  inside `.forge/changes/t5-otel-dartastic-realign/` other than the
  YAML status flip.
- Pre- and post-archive gates re-run from repo root :
  `verify.sh` 282 PASS / 0 FAIL ; `constitution-linter.sh` 42 PASS /
  0 FAIL ; `validate-change-yaml.sh` exit 0.

### Archived — T5 Phase C traceparent E2E validation (`t5-otel-traceparent-e2e`)

- Change `t5-otel-traceparent-e2e` flipped `implemented` → `archived`
  on 2026-05-26 (timeline entry `archived: 2026-05-26`).
  Constitution version `1.1.0` (no amendment).
- Consolidated spec promoted to `.forge/specs/otel-traceparent-e2e.md`
  with the 27 FRs `FR-T5-TPE-001..010 / 020..025 / 040..047 /
  060..062 / 080 / 090..091` + 7 NFRs `NFR-T5-TPE-001..007` + the
  three Article II scenarios (Direct / Kong / Sampled-off) preserved
  verbatim. Article V immutability honored — no edit inside
  `.forge/changes/t5-otel-traceparent-e2e/` other than the YAML
  status flip.
- Pre- and post-archive gates re-run from repo root with the same
  282 / 42 / 0 result as above.

## [0.4.0-rc.3]

### Fixed — Coroot image rehosted ghcr.io (B.8.8, `b8-coroot-rehost`)

- Docker Hub public access on `coroot/coroot:1.4.4` returns
  `denied: unauthorized` (verified 2026-05-24 via
  `docker manifest inspect`). Migrate to
  `ghcr.io/coroot/coroot:1.20.2` (GHCR accepts the unprefixed form,
  same convention as Docker Hub for Beyla — the early proposal
  claimed v-prefix mandatory ; that was a verify-then-pin mis-read
  inverted at implementation time per
  `.forge/changes/b8-coroot-rehost/evidence.md` § 1).
  Lesson institutionalised by T5.3.2 ABANDONED (verify-then-pin
  pass applied to the whole observability triplet ; SigNoz + OBI
  legs follow in sibling sub-changes `b8-signoz-unified` +
  `b8-obi-refresh`).
- `.forge/standards/observability.yaml` v1.1.0 → v1.2.0 additive
  (no breaking change) :
  - `versions.coroot: "1.4.4"` → `versions.coroot: "1.20.2"`.
  - `last_reviewed: 2026-05-04` → `2026-05-25`.
  - `rationale:` block extended with Coroot host-migration note
    and Coroot CE jurisdiction posture (ADR-B8-COR-004 — T1/T2 OK,
    T3 candidate-substitution flag at deployment-time Demeter
    pass ; no new K.3 rule in this sub-change).
  - YAML comment block above `versions:` documents the registry
    migration (docker.io → ghcr.io) and the no-v-prefix discovery
    (ADR-B8-COR-001 — inverted 2026-05-25 at `/forge:implement` :
    GHCR accepts the unprefixed `1.20.2` form, same as Docker Hub
    for Beyla ; early proposal v-prefix-mandatory claim was a
    verify-then-pin mis-read caught by L2 manifest-pull fixture).
- 4-copy mirror sync : canonical `.tmpl` + `cli/assets/...tmpl` +
  `examples/.../coroot-deployment.yaml` rendered +
  `cli/assets/examples/...yaml` rendered. All four carry the new
  pin + audit comment + `forge.dev/standard:
  "observability.yaml@1.2.0"` annotation bump.
- New harness `.forge/scripts/tests/b8-coroot.test.sh` — 13 L1
  grep-based tests + 2 L2 opt-in via `FORGE_B8_COROOT_DOCKER=1`
  (ghcr multi-arch manifest pullable + `--config` flag valid
  per ADR-B8-COR-003 ; docker.io `coroot/coroot:1.4.4` still
  denied per FR-B8-COR-073 verify-then-pin invariant). Registered
  in `.github/workflows/forge-ci.yml::harness` matrix (297/300
  lines per NFR-CI-002).
- `.forge/standards/REVIEW.md` ledger appended 2026-05-25
  (KEEP-WITH-CHANGES, next review 2027-05-04).
- **Pilot of the `b8-observability-rearch` trio** (cf.
  `.forge/_memory/b8-observability-rearch-exploration.md`).
  Sibling sub-changes :
  - `b8-signoz-unified` — SigNoz 4-service 3-component arch → unified
    6-service (4 long-running + 2 init containers) rearch (rc.2 known
    issue blocker).
  - `b8-obi-refresh` — Beyla 2.0.1 → 3.15.0 major bump.
- Tracked at `.forge/changes/b8-coroot-rehost/` ; 4 ADRs
  (`ADR-B8-COR-001..004`) ; 13/13 harness L1 GREEN ; Q-001..Q-004
  all resolved before archive. Release vehicle : next
  `v0.4.0-rc.x` (rc.3 candidate). v0.4.0 final reserved for T6
  complete (b8 trio + B.8.x).

## [0.4.0-rc.2] — 2026-05-20

### Added — vitest globalSetup bundle preflight (T5.3.3, `t5-3-3-vitest-bundle-preflight`)

- `cli/test/global-setup.ts` runs `npm run bundle` once before any
  vitest suite starts (via `cli/vitest.config.ts::test.globalSetup`).
  Closes the bypass where bare `vitest run` / `npx vitest` skipped
  the bundle and the e2e suite rsynced from a stale `cli/assets/`
  mirror — surfaced as a LOW finding in the T5.3.1 independent
  code-reviewer pass and reproduced 2026-05-20.
- `spawnSync` invocation (ADR-T533-001) ; throws on non-zero exit
  so the failure is visible at globalSetup time, not buried inside
  later e2e stderr.
- New harness `t5-3-3.test.sh` (5 L1 grep tests). No L2 needed —
  the inverse proof (running vitest against a stale `cli/assets/`)
  is intrinsically covered by the existing e2e suite.
- `forge-ci.yml` matrix entry adjusted with comment compression
  on the `i5.test.sh` / `f3.test.sh` / `t5-1.test.sh` /
  `t5-cargo.test.sh` / `t5-bin-server.test.sh` blocks per
  ADR-T533-002 to stay ≤ 300 lines (NFR-CI-002, now 294/300).


### Fixed — full-stack-monorepo docker-compose.dev.yml template hygiene (T5.3.1, `b1-1-dev-up-matrix-fixes`)

- Replace `image: scratch` placeholder on `fsm-backend` with
  `traefik/whoami:latest --port 8080` stand-in (per ADR-B1-DUM-001).
  Healthcheck probe path adjusted from `/health` to `/` ; adopter
  comment instructs to restore `/health` when swapping in the real
  backend image. Closes the `dev-up-matrix` smoke leg that T5.3
  exposed once `smoke-with-toolchains` started greening.
- Remove obsolete top-level `version: "3.8"` key (per ADR-B1-DUM-002).
  Replaced with a 1-line `# Compose v2 — ...` forward-defensive
  comment so adopters do not re-add the key.
- Mirror the same edits across the **4 synchronised copies**
  (canonical + `examples/forge-fsm-example/` + `cli/assets/` ×2 via
  `npm run bundle`).
- New harness `.forge/scripts/tests/t5-3-1.test.sh` (9 L1 grep-based
  tests + 1 L2 opt-in `FORGE_B1DUM_DOCKER=1` exercising `forge init`
  → `task dev:up` → `docker compose ps` → `task dev:down` cycle ;
  mirrors `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1` ADR-T5-OLR-005
  pattern). Registered in `forge-ci.yml` `harness` job (299 lines ≤
  NFR-CI-002 300).
- Regenerate `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
  via `bin/forge-snapshot.sh` (deterministic `SOURCE_DATE_EPOCH`) ;
  bundle the `cli/assets/.forge/scaffold-snapshots/...` mirror.
- **No constitution or standard change** ; T5.3.1 is pure template
  hygiene scoped to `full-stack-monorepo / 1.0.0` (mobile-only and
  other archetypes untouched).
- Tracked at `.forge/changes/b1-1-dev-up-matrix-fixes/` ; 3 ADRs
  (`ADR-B1-DUM-001..003`) ; 9/9 harness L1 GREEN ; release vehicle
  `v0.4.0-rc.2` (rc.1 already published on npm 2026-05-19).

### Known issue (v0.4.0-rc.2)

- **`task validate` `dev-up-matrix` leg stays RED** on
  `full-stack-monorepo` because the SigNoz image pins shipped by
  `t5-otel-stack` (2026-05-10) are **rotted upstream** (Docker
  Hub manifest unknown, including the last published 0.76.3).
  SigNoz has completed a full architectural migration
  (3-services → 1 unified `signoz/signoz` image) which makes a
  simple pin refresh impossible. An attempted follow-up
  `t5-otel-stack-image-refresh` (T5.3.2) was ABANDONED
  2026-05-20 after `docker manifest inspect` verification
  surfaced the architecture change. Fix is deferred to
  **B.8 / T6** (flagship 1.0.0 → 2.0.0 observability stack
  re-architecture per ADR-008). Full evidence + rationale in
  `docs/new-archetypes-plan.md` §0.5. T5.3.1's L1 harness
  (template hygiene) remains 9/9 GREEN ; only the L2 docker
  cycle is affected.

## [0.4.0-rc.1] — 2026-05-19

### Changed (BREAKING) — T5.3 Workiva → Dartastic OTel substitution (`t5-otel-dartastic-realign`)

- **`flutter/opentelemetry.md` bumped v1.1.0 → v2.0.0** (breaking).
  Substitution Workiva `opentelemetry 0.18.11` (web-only) → Dartastic
  ecosystem (`dartastic_opentelemetry_api ^1.0.0-beta.2` +
  `dartastic_opentelemetry ^1.1.0-beta.6` + `flutterrific_opentelemetry ^0.4.0`,
  all-platform : Android/iOS/Linux/macOS/Web/Windows). Resolves **Q-006**
  (Workiva web-only platform mismatch discovered 2026-05-16 via
  `cli-trust-harness` Option B validation).
- **Inaugural application of the T5.2 3-axis platform-verification
  checklist** — the 3 Dartastic packages were verified inline against
  existence + API surface (Context7-checked) + platform compatibility
  before ratification. No `[PLATFORM MISMATCH:]` markers raised.
- **WAIVER (ADR-T53-002)** : `dartastic_opentelemetry_api` pins at
  `^1.0.0-beta.2` (the only resolvable version given SDK 1.1.0-beta.6's
  constraint). Upgrade trigger named : `t5-3-1-dartastic-api-ga-refresh`.
  Pattern mirrors `transport.yaml v1.2.0` WAIVER (`t5-cargo-pin-refresh`).
- **FSM example frontend rewritten** : 5 Dart files in
  `examples/forge-fsm-example/frontend/lib/core/telemetry/` ported from
  Workiva imports to Dartastic. Sampler dual-stage preserved
  (ParentBasedSampler(AlwaysOnSampler()) on SDK side per ADR-OTEL-001 /
  ADR-T53-004 ; collector contract unchanged).
- **Mobile-only template rewritten** : `pubspec.yaml.tmpl`,
  `lib/observability/otel_init.dart.tmpl`, `lib/app.dart.tmpl`,
  `lib/data/auth/auth_repository_impl.dart.tmpl` all migrated.
  cli/assets mirror kept byte-identical. The phantom `opentelemetry_sdk`
  pin (never existed on pub.dev) removed. **Closes the v0.3.3 deferred
  `flutter analyze mobile-only` RED status.**
- **3 archived changes superseded** : `b4-mobile-only`, `t5-otel-app`,
  `t5-otel-dart-api-realign` each gain a new `.forge-update-notes`
  forward-pointer file (Article V immutability preserved — existing
  files byte-identical).
- **REVIEW.md append-only ledger entry** 2026-05-18 with
  `breaking_change: true` + Q-006 trigger + 3-axis checklist applied.
- **Harness `t5-otel-dartastic.test.sh`** : 13 L1 grep + 2 L2 opt-in
  (`FORGE_T53_LIVE=1` — `flutter pub get` + `flutter analyze` on FSM
  frontend + fresh mobile-only scaffold). Registered in `forge-ci.yml`
  matrix (forge-ci.yml still ≤ 300 lines per t5-1 budget).
- **Article III.4 (Ambiguity Protocol)** reinforced via the inline 3-axis
  checklist application — Forge no longer ratifies an external pkg
  without ticking all 3 axes (T5.2 self-validation lesson applied).
- **Release target** : v0.4.0-rc.1 (pre-GA minor bump per
  `docs/VERSIONING.md` because the standard breaks). Decoupled from
  the v0.3.4 patch line which carried T5.2.

## [0.3.4] — 2026-05-18

T5.2 release — Anti-Hallucination Platform Verification. One
archived change (`t5-2-platform-verification`) introduces a 3-axis
ratification checklist (Existence / API surface / Platform
compatibility) for external dependency-pinning standards, closing
the Q-006 gap (Workiva `opentelemetry 0.18.11` ratified despite
being web-only on pub.dev). Pure process change — no runtime code,
no CLI surface impact, no new toolchain dependency. Article III.4
(Ambiguity Protocol — anti-hallucination) reinforced procedurally.

### Added — T5.2 Anti-Hallucination Platform Verification (`t5-2-platform-verification`)

- **3-axis platform-verification checklist** added to the new
  Forge-local `.claude/agents/document-specialist.md` override.
  Every ratification of an external dependency-pinning standard
  (e.g. `.forge/standards/flutter/<dep>.md`) MUST now tick three
  axes — Existence, API surface, Platform compatibility — before
  flipping its status to `verified`. Failing Axis 3 emits
  `[PLATFORM MISMATCH: ...]` mirroring the existing
  `[NEEDS CLARIFICATION: ...]` Article III.4 convention and
  escalates to an ADR.
- **`standards-lifecycle.md` bumped v1.0.0 → v1.1.0** (additive
  per ADR-T52-001) with new H2 `## Platform compatibility
  re-verification` codifying the cadence : SHOULD re-run at every
  12-month review, MUST re-run on consuming-archetype target
  platform addition, MUST execute before first ratification.
  Frontmatter introduced explicitly (file was authored
  pre-J.7 convention).
- **REVIEW.md append-only ledger entry** dated 2026-05-18 records
  the bump (Article XII). Existing 27 ledger entries unmodified.
- **New harness `t5-2.test.sh`** — 8 L1 grep assertions + 1 L2
  opt-in via `FORGE_T52_LIVE=1` (pub.dev tooling smoke on
  `flutter_bloc` per ADR-T52-002). Registered in `forge-ci.yml`
  matrix immediately after `t5-otel-live-run.test.sh`.
- **`docs/CONTRIBUTING.md § Adding a Standard`** + **`docs/LINTING.md
  § Informative rules`** updated with cross-references to the
  checklist (option (b) preferred per drift-prevention
  NFR-T52-010).
- Trigger incident : **Q-006** — Workiva `opentelemetry 0.18.11`
  ratified 2026-05-12 (`t5-otel-dart-api-realign`) despite being
  web-only on pub.dev, discovered 2026-05-16 during
  `cli-trust-harness` Option B validation. The Workiva → Dartastic
  substitution itself ships in **T5.3 (`t5-otel-dartastic-realign`,
  target v0.4.0-rc.1)** — T5.2 ships the **process change** that
  prevents the recurrence ; T5.3 will be the first consumer
  ticking the 3-axis checklist inline.
- Article III.4 (Ambiguity Protocol / anti-hallucination)
  reinforced procedurally. No constitution amendment, no new CLI
  flag, no new toolchain dependency, no new Forge agent persona —
  pure process change. *Note*: an earlier draft of this entry and
  the T5.2 spec/design mistakenly cited "Article VIII" (which is
  actually "Infrastructure" in the Forge constitution). Corrected
  in the same review pass — this is exactly the class of
  fabricated-citation bug the T5.2 checklist exists to prevent,
  caught here by an independent code-reviewer pass before archive.

## [0.3.3] — 2026-05-16

T5.1 release — CLI Trust Harness + tactical fix-forwards. Three
archived changes (`cli-trust-harness`, `t5-cargo-pin-refresh`,
`t5-bin-server-deps`) land together to close the v0.3.0 → v0.3.2
regression pattern and make `cargo check --workspace` GREEN
end-to-end on a fresh `forge init --archetype full-stack-monorepo`
scaffold for the first time since `t5-connect-codegen` archived
2026-05-06. The remaining `flutter analyze` failure on the
`mobile-only` archetype (Workiva `opentelemetry` package is
web-only, plus a `opentelemetry_sdk` ghost-package reference) is
**explicitly deferred to T5.3** (`t5-otel-dartastic-realign`,
target v0.4.0-rc.1) per `docs/new-archetypes-plan.md` §0.3.

### Fixed — bin-server deps + workspace HTTP deps + grpc-api API realign (T5.1.E, `t5-bin-server-deps`)

Surgical refactor of the `full-stack-monorepo` Rust backend
scaffold so `cargo check --workspace` exits 0 on a fresh
`forge init` — the first time it has done so since
`t5-connect-codegen` archived 2026-05-06. RED witness chain
unfolded in cascade as each fix unblocked the next layer ; this
change closes all five remaining layers in a single archive.

**Root cause** : `t5-connect-codegen` was archived without ever
running `cargo check` against a freshly-scaffolded tree. Five
distinct bugs landed silently, each masked by the upstream
resolution failure of the buffa pin (now fixed by
`t5-cargo-pin-refresh`).

**Fixes** :

- **Workspace deps** :
  `backend/Cargo.toml.tmpl::[workspace.dependencies]` gains
  `axum = "0.8"` + `tower-http = { version = "0.6", features =
  ["trace"] }` + `http = "1"`. `axum 0.8` is the version
  `connectrpc 0.3.3` declares as `axum = "^0.8"` (verified via
  crates.io REST API 2026-05-16) ; the stale `examples/forge-fsm-example/`
  carries `axum = "0.7"` because it was scaffolded before
  `t5-connect-codegen` and was never regenerated (T5.3
  territory).
- **`bin-server/Cargo.toml.tmpl`** : new file. The scaffolder ran
  `cargo new bin-server` which produced an empty `[dependencies]`
  block ; my template now overlays the deps via the
  `scaffold-plan.yaml::phase: post_cargo_new` mechanism. Inherits
  via `{ workspace = true }` (mirrors the canonical pattern from
  `backend/CLAUDE.md § Strict Dependency Rules`) and adds
  `grpc-api = { path = "../crates/grpc-api" }` so the
  `transport_connect::into_router` symbol resolves.
- **`grpc-api/Cargo.toml.tmpl` axum feature** : the `connectrpc`
  pin gains `features = ["axum"]` so the `Router::into_axum_service()`
  and `into_axum_router()` methods are exposed (the `axum` feature
  is opt-in per connectrpc 0.3.3 docs.rs).
- **`build.rs.tmpl` API realign** : `connectrpc_build::Config`
  exposes `include_file()` + `files()` + `includes()` + zero-arg
  `compile()` (verified via docs.rs 2026-05-16) ; `out_file()`
  and the `compile(&[...], &[...])` 2-arg signature do not exist.
  Build script rewritten to the actual API.
- **`build.rs.tmpl` proto path** : `../../shared/protos/v1` →
  `../../../shared/protos/v1` (the build.rs lives in
  `backend/crates/grpc-api/`, three levels up from the proto
  root, not two).
- **`transport_connect.rs.tmpl` include macro** :
  `connectrpc::include_generated!("_connectrpc.rs")` →
  `include!(concat!(env!("OUT_DIR"), "/_connectrpc.rs"))`. The
  `include_generated!` macro does not exist in `connectrpc 0.3.3`
  (verified via docs.rs) — the canonical pattern is the stdlib
  `include!` macro pointing at the `include_file` aggregator
  written by `connectrpc-build`.
- **`transport_connect.rs.tmpl` generic refactor** : the previous
  `fn into_router<U, L>(use_case, tracing_layer)` signature did
  not satisfy axum 0.8's stricter `Service` bounds (5 E0277
  trait-bound failures). The seed function now takes only
  `use_case` and returns the bare connectrpc-derived
  `axum::Router` via `into_axum_router()`. The bin-server applies
  the tracing layer at the **outer** router via `.layer(...)` at
  call site, which preserves the span-wraps-the-whole-request
  contract (FR-T5-CC-013).
- **Snapshot regenerated** via `bin/forge-snapshot.sh build
  full-stack-monorepo 1.0.0` ; bundled mirror byte-identical.
  A.7 backward-compat `a7.test.sh` 29/29 GREEN preserved.

**Test harness** : `.forge/scripts/tests/t5-bin-server.test.sh`
ships **9 L1 + 1 L2** tests (L2 opt-in via `FORGE_T5BSD_LIVE=1`
runs `forge init` then `cargo check --workspace` against a fresh
scaffold — closes the entire RED chain end-to-end). Registered in
`forge-ci.yml` matrix immediately after `t5-cargo.test.sh`.
Workflow at the NFR-CI-002 boundary (300/300 lines after
trimming a comment block in the t5-1 step).

**Two ADRs** (`ADR-T5BSD-001..002`) resolve the `axum` version
choice (`0.8` from connectrpc constraint, not the stale example's
`0.7`) and the bin-server manifest layout (workspace-inherited
deps + path dep on grpc-api).

**T5.3 sibling note** : the example tree
`examples/forge-fsm-example/backend/` still carries
`axum = "0.7"` and does not pull in `connectrpc` — that
divergence stays until the example is regenerated cohesively as
part of `t5-otel-dartastic-realign` (T5.3) or a sibling refresh.
The build now compiles on the **template** ; the example is
self-consistent at its older state.

### Fixed — Cargo pin refresh (T5.1.E, `t5-cargo-pin-refresh`)

Surgical correction of two dead Cargo pins in the
`full-stack-monorepo` archetype, surfaced by the first run of
`task validate` on 2026-05-16 (the same day the
`cli-trust-harness` harness landed and its `task
smoke-with-toolchains` leg started exercising
`cargo check --workspace` on a fresh scaffold).

**Root cause** : `t5-connect-codegen` (2026-05-06) pinned
`buffa = "=0.3.3"` + `buffa-types = "=0.3.3"` in the template
+ `transport.yaml` v1.1.0, assuming the `connectrpc` family
shared a release cadence across all four crates. The assumption
was wrong : `buffa` and `buffa-types` series 0.3.x stops at
**0.3.0** on crates.io (verified 2026-05-16 via the REST API at
`https://crates.io/api/v1/crates/buffa` and
`…/buffa-types`). The pins never resolved on any fresh Cargo
invocation. The bug went undetected for 10 days because no test
exercised `cargo check`.

**Fix** :

- `buffa = "=0.3.0"` + `buffa-types = "=0.3.0"` in both the
  source template
  (`.forge/templates/archetypes/full-stack-monorepo/backend/crates/grpc-api/Cargo.toml.tmpl`)
  and the bundled-assets mirror (`cli/assets/.forge/…`). The
  `connectrpc 0.3.3` crate declares `buffa = "^0.3"`, so
  `=0.3.0` is the unique resolvable exact pin satisfying that
  caret constraint.
- `connectrpc = "=0.3.3"` and `connectrpc-build = "=0.3.3"`
  unchanged — both versions exist on crates.io ; ADR-T5-001
  (Anthropic OSS pedigree) holds.
- `transport.yaml` bumped **v1.1.0 → v1.2.0** (additive minor
  per ADR-T5CPR-002) with the two corrected pins. WAIVER comment
  block rewritten per ADR-T5CPR-003 to separate WAIVER
  (`connectrpc` family, still pedigree-justified at `=0.3.3`)
  from CORRECTION (`buffa` family, error-of-fact fix at
  `=0.3.0`). REVIEW.md ledger gains an `Updated 2026-05-16` row.
- Snapshot tarball
  `.forge/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
  regenerated via `bin/forge-snapshot.sh build full-stack-monorepo 1.0.0`
  so `forge upgrade` BASE recovery serves the corrected template.
  Bundled mirror refreshed via `npm run bundle` ; byte-identical
  to source.
- A.7 `forge upgrade` backward-compat preserved : `a7.test.sh`
  29/29 GREEN post-regen.

**Modernisation deferred** : bumping the `connectrpc` family
to 0.4.x / 0.5.x / 0.6.x belongs to **B.8 (T6)** flagship
migration, not to this surgical fix.

**Test harness** : `.forge/scripts/tests/t5-cargo.test.sh`
ships **10 L1 + 1 L2** tests (L2 opt-in via `FORGE_T5C_LIVE=1`
queries crates.io REST API to confirm `buffa 0.3.0` /
`buffa-types 0.3.0` are non-yanked and `connectrpc 0.3.3`
declares `buffa = "^0.3"`). Registered in `forge-ci.yml` matrix
immediately after `t5-1.test.sh` ; workflow stays under the
NFR-CI-002 300-line budget.

Three ADRs (`ADR-T5CPR-001..003`) resolve the pin target
(`=0.3.0` minimum edit vs modernisation), the standard bump
strategy (`v1.2.0` additive vs `v2.0.0` breaking), and the
WAIVER comment rewrite. RED witness preserved : `task validate`
2026-05-16 (`archetypes-smoke.test.ts` with
`FORGE_E2E_TOOLCHAINS=1`).

### Added — CLI Trust Harness (T5.1, `cli-trust-harness`)

Four-layer harness that walls `npm publish` off from any `@sdd-forge/cli`
tarball that cannot be demonstrably scaffolded against a fresh machine.
Closes the regression pattern that forced v0.3.1 and v0.3.2 hot-patches
within 24 hours of v0.3.0 publication. The four originating defects
(`--eu-tier` not wired, `spawn bash ENOENT`, empty-target collision
guard, and the 23-day-old `Taskfile.yml.tmpl:67` plain-scalar YAML bug
that broke `task dev:up` on every freshly-scaffolded `full-stack-monorepo`
project) all share a single root cause : no test exercised the published
binary against a clean fresh-machine layout. This change fixes it
structurally :

- **Layer T5.1.0** — Sweep of `.forge/templates/`, `examples/`, and
  `cli/assets/` for unquoted `: ` (colon + space) inside `cmds:` plain
  scalars. Single-quoted 12 lines across 6 Taskfile templates +
  rendered mirrors. `task --list-all` on a fresh scaffold now exits 0.
- **Layer T5.1.A — Golden snapshot of CLI flags.**
  `cli/test/e2e/help-snapshots.test.ts` captures `forge {--help, init
  --help, upgrade --help, verify --help, version --help}` into 5
  `.snap.txt` files under `cli/test/e2e/__snapshots__/help/`. Any
  drift fails CI. Plus a cross-reference assertion : every
  non-`removed_from_roadmap` archetype in `dispatch-table.yml` MUST
  appear by name in `forge init --help`. The `--archetype` option help
  text was extended to mention `mobile-only` (was previously missing,
  detected by this very test). `docs/ARCHETYPES.md` now points to the
  snapshots as the authoritative invocation reference — maintainer
  GitHub Discussions posts should copy from there rather than retyping
  the ABI.
- **Layer T5.1.B — Smoke test per archetype.**
  `cli/test/e2e/archetypes-smoke.test.ts` iterates `dispatch-table.yml`
  (skipping `default`, `removed_from_roadmap`, and `legacy_alias` when
  the target landed). For each remaining archetype : scaffold into a
  non-existent `mkdtemp` path (exercises the v0.3.2 `mkdir -p` fix),
  assert a declarative file matrix loaded from
  `cli/test/e2e/archetype-fixtures/<name>.yml`, run `task --list-all`
  on the scaffolded tree (skip-pass when `task` absent or when the
  archetype ships no Taskfile, per ADR-T51-001). Opt-in `cargo check
  --workspace` / `flutter analyze` gated on `FORGE_E2E_TOOLCHAINS=1`.
  Fixtures ship for `full-stack-monorepo` + `mobile-only` ; future
  archetypes pay the test-coverage tax via cross-reference assertion
  (`T5.1 smoke: archetype 'X' lacks a fixture`). New vendored
  ~80 LOC mini-YAML parser at `cli/test/e2e/helpers/load-fixture.ts`
  + 6 unit tests at `cli/test/domain/load-fixture.test.ts` (zero new
  external dep per NFR-T51-001).
- **Layer T5.1.C — Pre-publish tarball gate.**
  `cli/scripts/prepublish-smoke.mjs` chained into
  `cli/package.json::prepublishOnly` after `lint && test && bundle`.
  Runs `npm pack` → installs the produced tarball into an isolated
  npm prefix (`npm install --prefix=<tmp> --global`) — maintainer's
  global prefix never touched. Re-runs the T5.1.B smoke against the
  **installed binary**, not against `dist/`. Any failure aborts
  `npm publish`, preserves the captured tarball + tmpdir paths on
  stderr for post-mortem. Emergency override
  `FORGE_SKIP_PREPUBLISH=1` is allowed (loud `BYPASS` stderr line per
  ADR-T51-005 ; mandatory follow-up issue documented in
  `GOVERNANCE.md`).
- **Layer T5.1.D — `forge upgrade` matrix test.** Deferred to
  **B.8.15** in T6 (flagship 1.0.0 → 2.0.0 migration) per
  `docs/new-archetypes-plan.md` §0.1 + §4.2 — its critical value is
  the `1.0.0 → 2.0.0` pair which only exists after B.8.2 ships the
  `2.0.0` snapshot tarball.

Test harness `.forge/scripts/tests/t5-1.test.sh` ships **17 L1 + 2 L2**
tests (L2 opt-in via `FORGE_T51_LIVE=1` / `FORGE_T51_PACK=1`),
registered in `.github/workflows/forge-ci.yml` matrix immediately after
`f3.test.sh` with `--level 1`. Workflow stays under the NFR-CI-002
300-line budget (currently 292 lines).

**Local pre-push validation** : a new repo-root `Taskfile.yml`
orchestrates the full gauntlet via `task validate` (build → gates →
harness → vitest → per-archetype `cargo check` + `flutter analyze` →
per-archetype `task dev:up` boot validation with auto teardown via
bash `trap EXIT INT TERM`). Per-step tasks (`task harness`,
`task vitest`, `task pack-smoke`, `task help-snapshots-update`,
`task clean-leaked`, …) are invokable individually for iterative
debugging. Adopters never see this file — it lives at the framework
repo root only. Documented in `docs/CONTRIBUTING.md § Local pre-push
validation`.

Constitution unchanged. No new agent. No new standard YAML. The
`dispatch-table.yml` parser at `cli/src/domain/dispatch-table.ts`
gained `status:` field extraction to support the T5.1.A
cross-reference (additive, no behavior change for existing callers).
The `--archetype` option help text now lists `default |
full-stack-monorepo | mobile-only` (was missing `mobile-only`).

## [0.3.2] — 2026-05-13

Three first-experience bug fixes uncovered when running `forge init` against
the published v0.3.1 tarball. No spec / standard / constitution change ;
behaviour is now what v0.3.0 / v0.3.1 already documented.

### Fixed — `forge init --eu-tier` commander flag wiring

The `--eu-tier <T1|T2|T3>` flag declared by J.8 (`j8-janus-rules`) was
plumbed in `cli/src/commands/init.ts` (validator + `EU_TIER_ENUM` + env-var
propagation) but never wired into commander in `cli/src/cli.ts`. Users
hitting `forge init --eu-tier T2 …` on v0.3.0 / v0.3.1 got
`error: unknown option '--eu-tier'`.

This patch wires the flag :
- `.option("--eu-tier <tier>", ...)` declaration on the `init` command
- `euTier?: string` field on the inline `opts` type
- `euTier: opts.euTier` propagation into `initCommand` options

Regression covered by a new e2e test (`forge init --help` MUST list
`--eu-tier`).

### Fixed — `forge init --target <new-dir>` failed with `spawn bash ENOENT`

When `--target` pointed to a path that did not yet exist, Node `spawn`
inherited `cwd: opts.targetDir` and failed with `spawn bash ENOENT`. The
error message references `bash` but the underlying syscall is the missing
`cwd`. The bash scaffolder itself does `mkdir -p` at line 184, but that
runs **after** the spawn, never reached.

Fix : `cli/src/commands/init-archetype.ts` now does
`await mkdir(opts.targetDir, { recursive: true })` immediately before the
runner call. Idempotent ; no-op when the dir already exists.

### Fixed — `forge init` required `--force` even in an empty target dir

`.forge/scripts/scaffolder/init.sh:168` previously refused to scaffold
when the target dir merely **existed**, regardless of contents. Users
who did the natural `mkdir foo && cd foo && forge init …` hit the
collision guard on a freshly-created empty dir.

Fix : the check now refuses only when the dir exists **and** is
non-empty (`ls -A` skips `.` / `..`). Empty dirs proceed without
`--force`. The collision message also clarifies the non-empty
condition.

## [0.3.1] — 2026-05-12

### Changed — `scripts/release.sh` (renamed + OTP support) (`f3-release-script-fix`)

The maintainer-side release helper has been renamed and refactored to
fix two latent defects discovered during the v0.3.0 release :

- **Renamed** `scripts/release-v0.3.0.sh` → `scripts/release.sh`.
  The new script is generic and accepts a required
  `--version <X.Y.Z>` flag instead of pinning the version in its
  filename. The old file has been **deleted** (no symlink ;
  ADR-F3-001).
- **Subshell isolation (bug 1)**. The original `run()` helper used
  bash `eval` which leaked cumulative `cd` operations into the
  parent shell. Every directory change is now scoped to a subshell
  (`( cd cli && ... )` or `run()` wrapping in `( eval "$@" )`), so
  the script's working directory is invariant across the entire
  run.
- **2FA OTP handling (bug 2)**. `npm publish` now receives the OTP
  via `--otp="$OTP"`. The OTP is resolved through a three-tier
  fallback chain (ADR-F3-004) :
  1. Explicit `--otp <6-digits>` flag (preferred for automation).
  2. Interactive silent `read -rsp` prompt when stdin is a TTY.
  3. `$NPM_OTP` environment variable (CI / scripted contexts).
  The script exits 2 with a clear message if all three sources are
  absent and the publish step is not being skipped. The OTP value
  is never echoed or logged ; dry-run traces redact it as
  `<redacted>`.
- **`GOVERNANCE.md § Release Process`** updated to document the new
  invocation form, the `--otp` fallback chain, and the maintainer-
  only nature of the helper script.
- **Test harness** `.forge/scripts/tests/f3.test.sh` ships 10 L1
  grep-based tests covering : script presence + executable bit +
  audit comment + `set -euo pipefail` + `--version` plumbing +
  `--otp` plumbing + `NPM_OTP` fallback + no bare `eval cd` +
  top-level `cd` count = 1 + `npm publish --otp` forwarding +
  CHANGELOG entry. 1 L2 opt-in fixture (`FORGE_F3_LIVE=1`) drives
  the script in `--dry-run` mode and asserts the OTP literal is
  redacted from the trace. Registered in `forge-ci.yml` `harness`
  matrix after `i5.test.sh` with `--level 1`.

Four ADRs resolve the design open questions :

- **ADR-F3-001** — Old script handling : **delete**, no symlink
  (the new script's required `--version` flag makes a symlink fail
  with the same usage error a missing-file error produces).
- **ADR-F3-002** — `cli/assets/scripts/` adopter template : **out
  of scope** (verified 2026-05-12 — the template does not exist in
  the current tree ; if a future change ships a release helper to
  adopters via `forge init`, it owns the template).
- **ADR-F3-003** — Flag form : **`--version <X.Y.Z>`** over
  `--bump <level>` (the maintainer pins VERSION + CHANGELOG by hand
  at archive time ; the script verifies, it does not decide).
- **ADR-F3-004** — OTP fallback chain : **flag → TTY → env-var**,
  fail loudly with exit 2 if all three absent and publish is not
  skipped (silent OTP omission would re-hang the script on stdin —
  the exact bug F.3 fixes).

This change was **pulled forward from T8** (per the original
`.forge/product/roadmap.md` Phase 3 detail row) so the next v0.3.x
release can be cut with a working release helper. No constitutional
amendment required ; Articles III.4, V, XII compliance preserved.

### Added — I.5 forge-compliance.yml reusable workflow (`i5-compliance-workflow`)

Reusable GitHub Actions workflow `.github/workflows/forge-compliance.yml`
that adopter repos invoke via a single `uses:` reference to gate
their PR + push events against Forge's EU-compliance surface. The
workflow orchestrates the four EU-compliance scripts already
shipped : Demeter (`bin/forge-demeter-scan.sh`, K.3), the
constitution linter incl. its `ADR-I3-001 T3-Forbidden Components`
section (`.forge/scripts/constitution-linter.sh`, I.3), the
CycloneDX 1.5 SBOM (`bin/forge-sbom.sh`, J.8.d), and the compliance
artefacts bundle (`.forge/scripts/compliance/bundle.sh`, I.6). It
uploads the deterministic `.tgz` as a CI artefact via
`actions/upload-artifact@v4`.

- **`.github/workflows/forge-compliance.yml`** — reusable workflow
  triggered by `on: workflow_call:` with three inputs (`eu-tier`
  required ; `target-dir` default `.` ; `artefact-name` default
  `forge-compliance-artefacts`) and one output (`artefact-path`).
  Top-level `permissions: contents: read` (Aegis hygiene per
  NFR-I5-CW-005). Single `compliance` job on `ubuntu-latest`
  pinning `actions/checkout@v4`, `actions/setup-python@v5`, and
  `actions/upload-artifact@v4` (same versions as
  `.github/workflows/forge-ci.yml`). 158 LOC ; well under the
  NFR-I5-CW-002 200-line soft budget.
- **`.forge/standards/global/forge-compliance-workflow.md`
  v1.0.0** — 7 H2 sections (Purpose & EU compliance rationale /
  Workflow inputs and outputs / Step-by-step contract /
  Tier-scaled severity aggregation / Consumption protocol /
  Forward compatibility / Interdictions / Constitutional
  Compliance) + 4 RFC-2119 MUST NOT clauses. Frontmatter pins
  `version: 1.0.0`, `last_reviewed: 2026-05-12`,
  `expires_at: 2027-05-12`, `linter_rule: null` (advisory
  standard ; the workflow itself is the enforcement surface).
  284 LOC ; under the NFR-I5-CW-003 300-line soft budget.
- **`.forge/standards/index.yml` entry** — id
  `global/forge-compliance-workflow`, 8 triggers (`compliance`,
  `forge-compliance.yml`, `reusable-workflow`, `workflow_call`,
  `eu-tier`, `ci-enforcement`, `regulatory-handoff`,
  `github-actions`), scope `all`, priority `high`.
- **`.forge/standards/REVIEW.md` birth entry** dated 2026-05-12,
  Initial ratification, KEEP, next review 2027-05-12.
- **`docs/COMPLIANCE.md`** — new H2 `## Reusable compliance
  workflow` with copy-pasteable `uses:` YAML block, tier
  inheritance notes, and chained-output guidance.
- **`.forge/scripts/tests/i5.test.sh`** — 16 L1 grep-based tests
  validating workflow presence + YAML well-formedness + audit
  comment + `on: workflow_call:` trigger + inputs/outputs schema
  + four script invocations + three action pins + standard
  frontmatter / H2 / MUST NOT clauses + index entry + REVIEW
  birth + docs/COMPLIANCE H2 + CHANGELOG entry. 1 L2 opt-in
  fixture (`FORGE_I5_ACT=1` + `command -v act` gates per
  ADR-I5-CW-003 ; skip-when-absent semantics mirror
  `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1`). Registered in
  `.github/workflows/forge-ci.yml` `harness` matrix after
  `i3.test.sh` with `--level 1` (281 lines total, under the
  NFR-CI-002 300-line budget).

Three ADRs resolve the design open questions :

- **ADR-I5-CW-001** — exit-code aggregation : trust each script's
  tier scaling end-to-end (resolves Q-001). The workflow's
  aggregator step inspects `steps.<id>.outcome` for
  `demeter` / `linter` / `bundle` and exits `1` if any is not
  `'success'`. SBOM no-lockfile (exit 1 on `bin/forge-sbom.sh`)
  is **non-fatal at every tier** via `continue-on-error: true`
  on the SBOM step ; the aggregator emits a `::warning::`
  annotation instead. Mirrors I.6 FR-I6-CA-019.
- **ADR-I5-CW-002** — `SOURCE_DATE_EPOCH` source :
  `github.event.head_commit.timestamp` with
  `github.run_started_at` fallback (resolves Q-002). No
  additional `inputs.epoch` field ; the calling repo's commit
  metadata is the canonical input, matching
  `global/sbom-policy.md::Regeneration cadence` precedent.
- **ADR-I5-CW-003** — L2 act-runner gating : opt-in via
  `FORGE_I5_ACT=1` env var with skip-when-absent semantics
  (resolves Q-003). Verbatim reuse of the
  `t5-otel-live-run::FORGE_LIVE_RUN_DOCKER=1` precedent.

Forward-stable for Themis-territory regulatory deadline steps
(NIS2 / DORA / CRA / AI Act under `.forge/compliance/*/*`) when
K.5 (T7+) ships — additive step additions per FR-I5-CW-083 ; no
breaking change to the v1.0.0 inputs / outputs / step list.

No constitutional amendment required ; Articles III.4
(anti-hallucination — three Q-NNN tracked + resolved at design
time), V (audit trail — workflow header carries `<!-- Audit:
I.5 ... -->` ; CHANGELOG + REVIEW.md ledgers updated), VIII
(infrastructure — declarative YAML on `ubuntu-latest` ; no
service / daemon ; minimum-permissions block), XI (AI-first —
Demeter / Aegis / Janus consume the uploaded bundle), XII
(governance — SemVer + REVIEW.md ledger) compliance preserved.

### Added — T.5 OTel live-run collector contract validation (`t5-otel-live-run`)

Phase D of the T.5 OTel rollout : closes the cross-layer story by adding
a deterministic local-runner that proves a well-formed
`ExportTraceServiceRequest` reaches the collector boundary carrying the
expected `service.name` + W3C `traceparent` (the ADR-T5-OTA-002
contract). Hermetic-by-default (ADR-T5-OLR-002) — no Docker required
in CI ; an opt-in L2 leg gated by `FORGE_LIVE_RUN_DOCKER=1` exercises a
real otel-collector container for adopters.

- **Fake OTLP collector**
  `examples/forge-fsm-example/test/live-run/fake_otlp_collector.py` —
  Python stdlib varint + length-delimited tag walker (ADR-T5-OLR-001),
  no `protobuf` / `grpc` / `requests` pip dep, sanitiser collapses
  timestamps → `<ts:redacted>`, IPv4 → `<ip:redacted>`,
  `host.name` → `<host:redacted>` (ADR-T5-OLR-003).
- **Smoke driver**
  `examples/forge-fsm-example/test/live-run/run_smoke.sh` — boots the
  collector, posts a hex-canned `ExportTraceServiceRequest`
  (ADR-T5-OLR-004), asserts service_name + traceparent +
  resource_spans_count via grep. Exit codes 0 / 1 / 2.
- **Golden captures**
  `.forge/changes/t5-otel-live-run/captures/direct.golden.json` +
  `kong.golden.json` + `captures/README.md` documenting determinism +
  sanitiser + regen flow.
- **BDD feature**
  `examples/forge-fsm-example/test/features/traceparent_live_run.feature`
  — 2 Gherkin scenarios (direct + Kong-hop), Phase B
  `HeaderMapExtractor` symbol forward-pointer, cross-reference to
  Phase C `traceparent_e2e.feature`.
- **Harness** `.forge/scripts/tests/t5-otel-live-run.test.sh` — 8 L1
  + 1 L2 docker leg ; **9/9 GREEN** at `--level 1,2` (L2 skips when
  `FORGE_LIVE_RUN_DOCKER` ≠ `1`). Registered in `forge-ci.yml` matrix
  after `t5-otel-traceparent-e2e.test.sh`.
- **Out of scope** : Envoy gateway live-run (deferred to T6 / B.8 per
  ADR-T5-OLR-005). Zero `.rs` / `.dart` changes (NFR-T5-OLR-004).

New consolidated spec `.forge/changes/t5-otel-live-run/specs.md`
(FR-T5-OLR-001..142 + 6 NFRs + 6 ADRs `ADR-T5-OLR-001..006`).

### Added — T.5 OTel W3C traceparent E2E validation (`t5-otel-traceparent-e2e`)

Phase C of the T.5 OTel rollout : closes the W3C `traceparent` E2E
validation matrix for the `examples/forge-fsm-example/` flagship.
Phase A (`t5-otel-stack`) shipped infra ; Phase B (`t5-otel-app`)
shipped SDK init + middleware + interceptor ; this change closes the
evidence loop for the gateway hop.

- **BDD feature file**
  `examples/forge-fsm-example/test/features/traceparent_e2e.feature`
  with three Gherkin scenarios (Direct / Kong / Sampled-off).
- **Kong traceparent preservation contract comment** in
  `examples/forge-fsm-example/infra/kong/kong.yml.example` —
  declarative anchor + forward-pointer to the future
  `b8-envoy-migration` change.
- **Harness**
  `.forge/scripts/tests/t5-otel-traceparent-e2e.test.sh` (7 L1
  hermetic + 2 L2 inherited toolchain smoke ; L2 inherits the Phase B
  Q-004 `flutter analyze` xfail until `t5-otel-dart-api-realign`
  resolves the standard ↔ pub.dev API drift). CI matrix entry added
  after `t5-otel-app.test.sh` in `.github/workflows/forge-ci.yml`.
- **Phase D (live-run) explicitly deferred** — `docker compose up`
  driver, stub OTLP receiver, programmatic traceId assertion, and
  SigNoz API verification are documented in `tasks.md`
  § "Phase D — DEFERRED" but NOT shipped here. Phase C is harness +
  spec, not live-run.

Spec : `.forge/changes/t5-otel-traceparent-e2e/`
(`FR-T5-TPE-001..091` + `NFR-T5-TPE-001..007` +
`ADR-T5-TPE-001..006`).

### Added — T.5 OTel App SDK instrumentation in flagship example (`t5-otel-app`)

Phase B of the T.5 OTel rollout : the `examples/forge-fsm-example/`
flagship project now emits traces from end to end. Phase A
(`t5-otel-stack`) shipped the infra side ; this change wires the
application-side SDK init in both layers so demo-005-connect-greeting
produces a connected span tree visible in SigNoz with a single
`traceId`.

- **Rust backend SDK init** : new
  `crates/infrastructure/src/telemetry/` module (`mod.rs`,
  `propagation.rs`, `middleware.rs`) with `setup_telemetry`,
  `TelemetryConfig::from_env()`, OTLP HTTP/protobuf exporter (port
  4318), `Resource` attributes (`service.name`, `service.version`,
  `deployment.environment`, `host.name`), and the
  `ParentBased(TraceIdRatioBased(1.0))` sampler per ADR-T5-OTA-003.
  Crate pins per ADR-T5-OTA-001 : `opentelemetry 0.31` family +
  `tracing-opentelemetry 0.32` + `tower-http 0.6 [trace]`.
- **axum + tonic middleware composition** :
  `tower-http::TraceLayer::new_for_http()` with a `make_span_with`
  closure that extracts the W3C `traceparent` header via
  `TraceContextPropagator`, creates a server-kind span, and stitches
  the parent context. `MetadataMapCarrier` ships for tonic gRPC ;
  `HeaderMapCarrier` ships for outbound `reqwest` calls.
- **Flutter frontend SDK init** : new `lib/core/telemetry/`
  (`telemetry_setup.dart`, `observers/tracing_navigation_observer.dart`,
  `observers/tracing_bloc_observer.dart`, `error_reporter.dart`,
  `interceptors/tracing_interceptor.dart`) plus
  `lib/core/config/app_config.dart`. `pubspec.yaml` gains
  `opentelemetry: ^0.18.0` + `dio: ^5.7.0` (resolved at impl-time per
  the T-VER-DART-001 deferred-pin pattern from ADR-T5-OTA-001 ;
  `flutter pub get` confirmed `opentelemetry 0.18.11` + `dio 5.9.2`).
  `lib/main.dart` rewritten per ADR-T5-OTA-005 init order
  (`ensureInitialized` → `AppConfig.fromEnv` → `setupTelemetry` →
  `Bloc.observer` → error handlers → `runApp` with
  `navigatorObservers`). **Aligned to `flutter/opentelemetry.md`
  v1.1.0** (sibling change `t5-otel-dart-api-realign` ; Q-004
  follow-up commit `15b774c` in this change) : `CollectorExporter(Uri)`
  exporter, positional + named `BatchSpanProcessor`,
  `ParentBasedSampler(AlwaysOnSampler())` sampler (the
  `TraceIdRatioBased*` class is not exported by `opentelemetry: 0.18.11`
  — env-tier ratio remains enforced collector-side per ADR-OTEL-001).
- **demo-005-connect-greeting traceparent round-trip** : the Greeter
  use case in `crates/application/src/greet.rs` carries a
  `#[tracing::instrument(name = "greeter.greet", fields(otel.kind = "internal", rpc.system = "connect", ...))]`
  annotation. The Flutter `GreetingRepositoryImpl` builds a `Dio`
  client with `TracingInterceptor` pre-attached so the swap to a real
  Connect/Dart client is a one-line change.
- **Env-driven config trio** :
  `examples/forge-fsm-example/README.md` § "Environment configuration"
  documents `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`,
  `OTEL_RESOURCE_ATTRIBUTES`, `OTEL_TRACES_SAMPLER`,
  `OTEL_TRACES_SAMPLER_ARG`, `DEPLOYMENT_ENV` per ADR-T5-OTA-007
  (W3C OTel SDK env names, no Forge-prefix surface). `NEVER PUT
  SECRETS HERE` warning explicit (FR-T5-OTA-010 / NFR-T5-OTA-006).
- **demo doc** :
  `examples/forge-fsm-example/docs/demo-005-connect-greeting.md`
  ships with a `## Trace this in SigNoz` section enumerating the
  four-span tree (Flutter root → axum server → connectrpc handler →
  application use case).
- **Test harness** : new
  `.forge/scripts/tests/t5-otel-app.test.sh` (16 L1 hermetic + 2 L2
  toolchain-gated). Registered in
  `.github/workflows/forge-ci.yml` `harness` job. Performance budget
  L1 ≤ 8 s, L2 ≤ 90 s (NFR-T5-OTA-005).
- **BDD scenario** :
  `examples/forge-fsm-example/test/features/demo_005_traceparent.feature`
  ships per Article II.1 ; full step bodies are Phase D scope.

Deviation from `rust/opentelemetry.md` § Setup snippet : the standard
shows `with_tonic()` (gRPC). ADR-T5-OTA-002 picks HTTP/protobuf both
layers for symmetry with the Flutter exporter and the Phase A
collector :4318 receiver. Documented inline in `bin-server/main.rs`
and in `crates/infrastructure/src/telemetry/mod.rs` module doc.

`observability.yaml` (T.5 v1.1.0) is consumed, not amended — no
standard bump, no REVIEW.md ledger entry per ADR-T5-OTA proposal.md
§ Article XII. **`flutter/opentelemetry.md` was bumped v1.0.0 → v1.1.0
by the sibling change `t5-otel-dart-api-realign`** to resolve Q-004 ;
this change's Q-004 follow-up commit (`15b774c`) realigned the example
Dart code to v1.1.0 and flipped `_test_ota_l2_002_flutter_analyze`
from xfail to expected-pass (toolchain-gated graceful skip).

Spec consolidation : new `.forge/specs/otel-app.md` (56 ADDED FRs
`FR-T5-OTA-001..103` + 7 NFRs + 7 ADRs `ADR-T5-OTA-001..007`) ships
with the archive.

### Added — I.2 compliance-tiers standard (`i2-compliance-tiers`)

Single human-readable standard codifying the EU compliance gradient
T1 / T2 / T3 from `.forge/schemas/compliance-tier.schema.json`
v1.0.0 (T.4) and `docs/ARCHITECTURE-TARGET.md` §10. Implements the
**I.2** audit slot from `docs/new-archetypes-plan.md` §7.1 line
727-729 + resolves the Demeter forward-pointer shipped by K.3 on
2026-05-10.

- **`.forge/standards/global/compliance-tiers.md` v1.0.0** — 7 H2
  sections (Purpose / Tier definitions / Component eligibility
  matrix / Demeter integration / Adoption path / Extending the
  matrix / Interdictions + Constitutional Compliance). Verbatim
  citation of the schema's `x-tier-descriptions` block (T1 / T2 /
  T3 strings byte-identical to the schema per K.3
  Anti-Hallucination Protocol FR-K3-DEM-020 precedent). 15-row
  component matrix mirroring `ARCHITECTURE-TARGET.md` §10.2
  byte-for-byte (ADR-I2-CT-002). Five RFC-2119 MUST NOT clauses
  under Interdictions (no paraphrase ; no new tier without
  Article XII ; no silent T3 downgrade ; no certification-scheme
  coupling beyond SecNumCloud / HDS / EUCS High ; matrix
  byte-identical to §10.2). Frontmatter pins
  `linter_rule: t3-forbidden-components` as a forward-pointer to
  I.3 (ADR-I2-CT-001 — the matching `constitution-linter.sh`
  section anchor ships with I.3).
- **`.forge/standards/index.yml` entry** — id
  `global/compliance-tiers`, 9 triggers (`compliance, t1, t2, t3,
  eu-tier, dpa, schrems, cloud-act, tier-classification`), scope
  `all`, priority `high`. Registered under the "I.2 — Compliance
  tiers" section immediately after the K.3 entry.
- **`.forge/standards/REVIEW.md` append-only entry** dated
  2026-05-11 (Initial ratification). KEEP decision, next review
  due 2027-05-11.
- **`docs/COMPLIANCE.md`** — adopter-facing intro with 3 H2
  sections (Quick start / Tier picker / Cross-references) +
  decision tree for tier selection. Root placement per
  ADR-I2-CT-003 ; future I.6 grouping into `docs/compliance/`
  deferred to Themis (K.5).
- **`.forge/scripts/tests/i2.test.sh`** — 14 L1 hermetic
  grep-based tests covering frontmatter (audit + trigger
  comments, H1, version, dates, linter_rule), body H2 count,
  schema verbatim citation, 15-row matrix presence, Demeter
  cross-link + FR-K3-DEM-068 citation, ≥ 3 MUST NOT clauses,
  index.yml entry, REVIEW.md entry, docs/COMPLIANCE.md presence
  + H1 + 3 H2 sections, CHANGELOG entry. Performance budget
  ≤ 3 s wall-clock per NFR-I2-CT-001.
- **`.github/workflows/forge-ci.yml` matrix row** registering
  `i2.test.sh --level 1` after `k3.test.sh`.

Three ADRs resolve the design open questions :
ADR-I2-CT-001 (`linter_rule` kebab-case forward-pointer) ;
ADR-I2-CT-002 (verbatim 15-row matrix) ; ADR-I2-CT-003 (root
`docs/COMPLIANCE.md` placement).

Unblocks **I.3** (T3-forbidden linter rule), **I.5**
(`forge-compliance.yml` workflow), **I.6** (regulatory artefacts
— NIS2 / DORA / CRA / AI Act) per `docs/new-archetypes-plan.md`
§7.1 + §10.

No constitutional amendment required ; Articles III.4
(anti-hallucination — verbatim citation), V (audit trail —
REVIEW.md append-only), XI.1 (agent-native — Demeter consumes the
standard), XI.3 (schema-driven — mirrors the JSON Schema), XII
(governance — SemVer + REVIEW.md ledger) compliance preserved.

### Added — I.6 compliance artefacts bundle (`i6-compliance-artefacts`)

Deterministic `.tgz` regulatory hand-off bundle generator for EU
auditor / regulator counter-parties. Implements the **I.6** audit
slot from `docs/new-archetypes-plan.md` §7.1 line 738-743 and
ships the forward-stable contract surface the future I.5
`forge-compliance.yml` workflow consumes.

- **`.forge/scripts/compliance/bundle.sh`** — bash thin + Python 3
  inline (mirrors `bin/forge-sbom.sh` pattern per NFR-I6-CA-004).
  Six bundle members emitted in lexicographic order : `MANIFEST` +
  `tier-matrix/compliance-tiers.md` +
  `templates/forge-dpa-declared.template` +
  `audit/audit-ledger.json` + `audit/audit-ledger.md` +
  `sbom/sbom.cdx.json`. Determinism via `SOURCE_DATE_EPOCH` :
  per-member tar `mtime` / `uid` / `gid` / `mode` pinned, gzip
  header `mtime` pinned via the two-step `io.BytesIO` +
  `gzip.GzipFile(mtime=...)` idiom (ADR-I6-CA-001). Two
  consecutive invocations against the same tree produce
  byte-identical output (NFR-I6-CA-005).
- **`.forge/templates/compliance/forge-dpa-declared.template`** —
  canonical DPA declaration template mirroring K.3 ADR-K3-002
  ledger format. Cross-references K3-RULE-002 (T1 + ⚠️-T1
  without DPA → High finding) and K3-RULE-002a staleness window
  (13 months + 1 month grace per RGPD Article 5(1)(e)). Canonical
  example line `T1: 2026-04-15 LegalOps-Confluence-DPA-2026-Q2`.
- **`.forge/standards/global/compliance-artefacts-bundle.md`
  v1.0.0** — 6 H2 sections (Purpose & EU compliance rationale /
  Bundle content schema / Determinism guarantee / Consumption
  protocol / Regeneration cadence / Interdictions) + Forward
  compatibility + Constitutional Compliance. 4 RFC-2119 MUST NOT
  clauses (no PII / secrets ; no `--no-deterministic` escape
  hatch ; no Themis-territory artefacts before K.5 ships ; no
  post-emission bundle modification). Frontmatter pins
  `version: 1.0.0`, `last_reviewed: 2026-05-12`,
  `expires_at: 2027-05-12`, `linter_rule: null`,
  `exception_constitutional: false`.
- **`.forge/standards/index.yml` entry** — id
  `global/compliance-artefacts-bundle`, 10 triggers (`compliance,
  bundle, auditor, dpa, audit-ledger, nis2, dora, cra, ai-act,
  regulatory-handoff`), scope `all`, priority `high`. Registered
  under the "I.6 — Compliance artefacts bundle" section
  immediately after the I.2 entry.
- **`.forge/standards/REVIEW.md` append-only birth entry** dated
  2026-05-12 (Initial ratification, KEEP, next review 2027-05-12).
- **`docs/COMPLIANCE.md`** — new H2 `## Auditor hand-off bundle`
  cross-linking the bundle script + the standard + the
  determinism recipe via `SOURCE_DATE_EPOCH`.
- **`.forge/scripts/tests/i6.test.sh`** — 14 L1 hermetic tests
  (script presence + executable / `--help` exit 0 / audit
  comment / bogus arg exit 2 / template presence + canonical
  example / standard presence + frontmatter + 6 H2 + MUST NOT
  count / index entry / REVIEW.md entry / docs/COMPLIANCE.md H2 /
  CHANGELOG entry) plus 2 L2 fixture tests (good-fixture bundle
  with 6 members + MANIFEST ; determinism via `SOURCE_DATE_EPOCH=0`
  × 2 invocations + `diff -q`). Performance budget ≤ 5 s L1
  + ≤ 10 s L2 per NFR-I6-CA-001.
- **`.github/workflows/forge-ci.yml` matrix row** registering
  `i6.test.sh --level 1,2` after `i2.test.sh`. File stays under
  NFR-CI-002 300-line budget.

Three ADRs resolve the design open questions :
`.tgz` gzip POSIX tar format (ADR-I6-CA-001) ; `audit/`
subdirectory layout (ADR-I6-CA-002) ; script location
`.forge/scripts/compliance/bundle.sh` (ADR-I6-CA-003).

Forward-stable for Themis-territory artefacts (NIS2 / DORA / CRA /
AI Act regulatory deadlines under
`.forge/compliance/{nis2,dora,cra,ai-act}/`) — additive expansion
under a new `regulatory/` subdirectory + a SemVer minor bump per
FR-I6-CA-053 when Themis (K.5, T7+) ships.

No constitutional amendment required ; Articles III.4, V, XI.1,
XI.3, XI.6, XII compliance preserved.

### Added — K.3 Demeter data-steward agent + CLOUD Act dependency scanner (`k3-demeter`)

Three sub-modules under one umbrella change, implementing the K.3 +
I.4 audit slots from `docs/new-archetypes-plan.md` §1.4 row K.3 +
§7.1 line 733 :

- **K.3.a — Demeter persona file** : `.claude/agents/demeter.md`
  ships the Data Steward EU agent persona with 7 mandatory H2
  sections (Persona, Purpose, Checklists, Output, Rule Catalogue,
  Integration, Anti-Hallucination Protocol). Sibling to Aegis ;
  Aegis owns vulnerability posture, Demeter owns data-stewardship
  posture (jurisdiction, DPA, PII classification). Persona file
  authoring is **deferred to a manual handoff** — see
  `.forge/changes/k3-demeter/open-questions.md` for the blocked
  status. Once the persona ships, 9 L1 tests in
  `.forge/scripts/tests/k3.test.sh` flip GREEN automatically.
- **K.3.b — Deterministic dependency scanner** :
  `bin/forge-demeter-scan.sh` walks Cargo / npm / pubspec
  lockfiles under `--target` (depth ≤ 3) and matches each
  dependency's publisher against the curated deny-list at
  `.forge/data/cloud-act-publishers.yml`. Tier-scaled severity
  per FR-K3-DEM-068 (T1 → Informational ; T2 → High ; T3 →
  Critical). Bash thin + Python 3 inline, F.2 / J.7 / J.8.d
  pattern verbatim. Exit code envelope 0 / 1 / 2 / 3 mirrors the
  J.8 ADR-J8-003 policy-refusal semantics. Determinism via
  `SOURCE_DATE_EPOCH` per NFR-K3-DEM-005. The deny-list seeds 4
  cargo + 4 npm + 2 pub publisher patterns covering the
  AWS / Google Cloud / Azure / Firebase ecosystems with
  citable evidence URLs.
- **K.3.c — Standards + dispatch integration** :
  `.forge/standards/global/data-stewardship-rules.md` ships the
  authoritative standard with 7 H2 sections covering rule
  catalogue (K3-RULE-001..006), adoption path, DPA declaration
  semantics, extending the catalogue, regeneration cadence
  (Phase A interim BDFL / 12-month, Phase B post-T7 Themis /
  6-month per ADR-K3-003), and constitutional compliance.
  Standards index registers the new entry under the
  "Cross-Cutting Standards" section. Repository-level `CLAUDE.md`
  agent table gains the Demeter trigger row alphabetically
  between Oracle and Clio. Janus delta-edit
  (`.claude/agents/cross-layer-orchestrator.md` Step 9 rename +
  dispatch row + Quality Gates bullet per ADR-K3-007) is
  **deferred to a manual handoff** alongside the persona file.

Test harness `.forge/scripts/tests/k3.test.sh` ships with 20 L1 +
2 L2 tests (`forge-ci.yml` matrix registers it after `j8.test.sh`).
The 2 L2 fixtures are GREEN end-to-end : deny-list-hit at T3 →
exit 3 BLOCKED + Critical K3-RULE-001 finding ; clean-tree at T2
→ exit 0 CLEARED + byte-identical re-run with
`SOURCE_DATE_EPOCH=0`. The 11 L1 tests covering the scanner +
publisher list + standard + index + CLAUDE.md trigger +
namespace-collision guard are GREEN. The 9 L1 tests covering
the persona + Janus delta remain RED until the manual handoff
completes.

Open questions Q-001 / Q-002 / Q-003 resolved by ADR-K3-002 /
ADR-K3-003 / ADR-K3-005 (DPA declaration ledger surface,
publisher list two-phase governance, K3-RULE-NNN incremental
growth with 5 seed rules + K3-RULE-006 operational guardrail).

No constitutional amendment required ; all Articles I, II, III,
III.4, IV.1, V, VIII, IX, XI, XII compliance preserved.

### Added — J.8 Janus orchestrator rules + EU compliance tier + SBOM (`j8-janus-rules`)

Three sub-modules under one umbrella change :

- **J.8.a — Janus refusal rules** : the cross-layer orchestrator agent
  (`.claude/agents/cross-layer-orchestrator.md`) gains a "Forbidden
  archetypes & combinations" H2 section enumerating 3 seed rules
  (`J8-RULE-001` flutter-firebase Schrems II / CLOUD Act ;
  `J8-RULE-002` T3 ⇒ self-host Zitadel ; `J8-RULE-003` T3 ⇒
  self-host SigNoz + no Datadog). `.forge/scaffolding/dispatch-table.yml`
  gains a `forbidden_archetypes:` runtime registry. New shared bash
  helper `bin/_forge-init-helpers.sh::_refuse_if_forbidden` provides
  defense-in-depth refusal logic ; sourced by `bin/forge-init-fsm.sh`
  + `bin/forge-init-mobile-only.sh`. The TS dispatcher
  (`cli/src/commands/init-archetype.ts`) is the first line of defense :
  it consults `forbidden_archetypes` before invoking any wrapper and
  throws an Error with the structured `[REFUSAL: ...]` prefix +
  `exitCode: 3`. New standard
  `.forge/standards/global/janus-orchestration-rules.md` codifies the
  rule catalogue + extension procedure.
- **J.8.b — `--eu-tier` flag + T3 enforcement + ledger** : `forge init`
  gains an optional `--eu-tier T1|T2|T3` flag validated against
  `.forge/schemas/compliance-tier.schema.json` (T.4). Validated tier
  passed to wrapper scripts via `FORGE_EU_TIER` env var. When
  `FORGE_EU_TIER=T3`, the fsm wrapper refuses Datadog / SigNoz Cloud /
  cloud-managed identity ; when set to any tier, writes
  `<target>/.forge/.forge-tier` as a one-line plain-text ledger.
  Backward compat preserved : flag absence behaves identically to
  pre-J.8 (NFR-J8-002).
- **J.8.d — SBOM CycloneDX 1.5** : new
  `bin/forge-sbom.sh` generates a CycloneDX 1.5 JSON (or XML) SBOM
  from any combination of `Cargo.lock` / `package-lock.json` /
  `pnpm-lock.yaml` / `yarn.lock` / `pubspec.lock` found under
  `--target` (recursive walk, depth 4, with skip-list for
  `node_modules` / `target` / `.dart_tool` / `.git` / etc.). Bash
  thin + Python 3 inline (F.2 / J.7 pattern, no external CycloneDX
  dependency — handcrafted minimum-viable per Context7-verified
  CycloneDX 1.5 mandatory fields). Reproducible : `SOURCE_DATE_EPOCH`
  controls timestamp + serialNumber for byte-identical output across
  runs (FR-J8-075). New standard
  `.forge/standards/global/sbom-policy.md` documents the format
  choice + regeneration cadence + EU compliance rationale (NIS2 +
  DORA + CRA).

Test harness `j8.test.sh` 20/20 GREEN at `--level 1,2`. Smoke test
on `examples/forge-fsm-example/` produces an SBOM with 74
components (Cargo + pubspec lockfiles).

`docs/ARCHETYPES.md` gains "Forbidden combinations" + "EU
compliance tier" sections.

### Added — T.5 OTel + OBI + Coroot stack templates (`t5-otel-stack`)

- **OBI eBPF DaemonSet** (`infra/k8s/base/obi-daemonset.yaml.tmpl`) for
  the `full-stack-monorepo / 1.0.0` archetype : `grafana/beyla:2.0.1`
  with the **unprivileged-with-capabilities** posture (ADR-OTEL-004) —
  `BPF, SYS_PTRACE, NET_RAW, CHECKPOINT_RESTORE, DAC_READ_SEARCH,
  PERFMON, NET_ADMIN, SYS_ADMIN`, drop ALL otherwise. `hostPID: true`,
  `hostNetwork: true`, `nodeSelector: forge.dev/kernel-min-58: "true"`,
  `metadata.annotations["forge.dev/aegis-audit"]: "required"`. Dedicated
  `ServiceAccount` + `ClusterRole` (read-only on pods/nodes/replicasets)
  + `ClusterRoleBinding` shipped as multi-doc in the same file.
- **Coroot deployment** (`infra/k8s/base/coroot-deployment.yaml.tmpl`) :
  `coroot/coroot:1.4.4` single replica, multi-doc YAML
  (Deployment + Service + ConfigMap, ADR-OTEL-006), local-dev `emptyDir`
  persistence (production rollouts swap to PVC per CLAUDE.md).
- **OTel collector sampler** : `processors.probabilistic_sampler` block
  added to `infra/observability/otel-collector-config.yaml.tmpl`
  (ADR-OTEL-001) — `mode: proportional`, `attribute_source: traceID`,
  `hash_seed: 22`, `sampling_percentage: 100` (dev default). Wired into
  the traces pipeline only (metrics + logs unchanged). Env-tier overlays
  patch the ratio :
  `infra/k8s/overlays/dev/sampler-patch.yaml.tmpl` → 100,
  `infra/k8s/overlays/staging/sampler-patch.yaml.tmpl` → 100,
  `infra/k8s/overlays/prod/sampler-patch.yaml.tmpl` → 10
  (per `observability.yaml::ratios.prod = 0.1`).
- **`observability.yaml` 1.0.0 → 1.1.0** : new `versions:` block
  recording the OBI + Coroot image pins (symmetric with T.5
  `transport.yaml` 1.0.0 → 1.1.0 codegen-pinning pattern). REVIEW.md
  ledger gains an `Updated` entry.
- **Aegis audit documentation** : `infra/CLAUDE.md.tmpl` gains a
  "Privileged DaemonSet — Aegis audit required" section + a "Sampler
  overlay mechanism" section + a "Coroot persistence" section.
  `infra/k8s/base/README.md.tmpl` gains a "Deployment prerequisites"
  checklist (kernel ≥ 5.8, Aegis review, kernel-min node label, Coroot
  persistence).
- **Example mirror** : `examples/forge-fsm-example/infra/` gains the
  six rendered files for parity (FR-OTEL-050).
- **Test harness** `t5-otel.test.sh` : 14/14 GREEN at `--level 1`,
  registered in `forge-ci.yml` matrix immediately after `j7.test.sh`.
- **`docs/ARCHETYPES.md`** flagship row updated to mention OBI eBPF +
  Coroot + sampler overlays.
- **New consolidated spec** `.forge/specs/otel-stack.md` (deferred to
  archive phase ; in-flight in `.forge/changes/t5-otel-stack/`).

### Added — J.7 Standards YAML validation (`j7-validate-standards-yaml`)

- **`bin/validate-standards-yaml.sh`** — deterministic linter for
  `.forge/standards/*.yaml`. Validates the 8-field frontmatter contract
  (FR-J7-002..010) plus 5 lifecycle invariants from
  `global/standards-lifecycle.md` : Article XII coupling
  `expires_at: never` ⇔ `exception_constitutional: true` (FR-J7-020),
  strict `expires_at > last_reviewed` (FR-J7-021), `REVIEW.md` ledger
  drift (FR-J7-023, full ledger scan), `linter_rule` cross-reference
  into `constitution-linter.sh` (FR-J7-030), `index.yml` trigger
  reachability (FR-J7-050). Bash thin + Python 3 inline (F.2 pattern
  reuse, no `jsonschema` lib). Exit codes 0 / 1 / 2 ; output
  `[STD-PASS]` / `[STD-FAIL: <path>:<field>: <reason>]` /
  `[STD-INFO: ...]`.
- **`.forge/schemas/standard.schema.json`** — JSON Schema Draft 2020-12
  encoding the frontmatter contract. Root `additionalProperties: true`
  to accommodate domain-specific bodies (transport / state-management /
  observability / etc.).
- **`verify.sh` § "Standards YAML Schema"** — new section iterates
  the six top-level standards plus the index.yml triggers. Six PASS
  lines + 1 trigger-reachability line on the live tree
  (`136 PASS / 0 FAIL / RESULT: PASS` post-J.7).
- **`j7.test.sh` harness** — 21 tests (17 L1 + 4 L2) registered in
  `forge-ci.yml` matrix. Live-tree validator wall-clock 122 ms (NFR-J7-001
  budget 2 s).
- **`global/standards-lifecycle.md`** — new "Automated enforcement"
  section cross-linking the validator + harness + invariant catalogue.
- **`docs/SCHEMA.md`** — new "Standard YAML schema" section mirroring
  the existing Change YAML schema docs (frontmatter table, invariants,
  CLI usage, common errors, "adding a new standard YAML" recipe).

### Added — T.5 Connect codegen (`t5-connect-codegen`, in flight)

- **5 post_cargo_new templates** for the `full-stack-monorepo / 1.0.0`
  archetype shipping a parallel Connect-RPC adapter alongside the
  existing tonic gRPC server :
  - `backend/crates/grpc-api/Cargo.toml.tmpl` (deps : `connectrpc`,
    `buffa`, `buffa-types` `=0.3.3` ; build-dep : `connectrpc-build`
    `=0.3.3`).
  - `backend/crates/grpc-api/build.rs.tmpl` (Path α codegen via
    `connectrpc_build::Config::new()`).
  - `backend/crates/grpc-api/src/lib.rs.tmpl`.
  - `backend/crates/grpc-api/src/transport_connect.rs.tmpl` (public
    `into_router` + `connectrpc::Router::into_axum_service()` inline
    integration — no separate `connectrpc-axum` crate).
  - `backend/bin-server/src/main.rs.tmpl` (preserves tonic
    `Server::builder()` bind on port 50051 + mounts the Connect
    adapter under `/connect` on port 8080).
- **3 new buf plugins** in
  `templates/full-stack-monorepo/shared/protos/buf.gen.yaml.tmpl` :
  `buf.build/connectrpc/go:v1.19.2`, `buf.build/bufbuild/es:v2.2.0`,
  `buf.build/connectrpc/dart:v1.0.0` (official Dart plugin replaces
  abandoned `skadero/connect-dart-community`).
- **`transport.yaml` v1.0.0 → v1.1.0** : `codegen.connect_layout_version: 1`
  + `codegen.versions:` map (11 pins) + inline `WAIVER 2026-05-05`
  block documenting the 13-day age waiver of ADR-T5-002 #1 for the
  `=0.3.3` Rust crate family.
- **`scaffold-plan.yaml` schema extension** (additive) : optional
  `phase: pre_cargo_new | post_cargo_new` field per template entry.
  Default `pre_cargo_new` (legacy / b1-scaffolder semantics).
- **`overlay.sh` `--phase` flag** : filters templates by phase, with
  implicit `force=true` on `post_cargo_new` and manifest-write skip
  (`scaffold-manifest.yaml` finalised by the `pre_cargo_new` pass).
- **`init.sh` Step 4.5** inserted between `cargo new` (Step 4) and
  `buf lint` (Step 5) : second overlay pass with `--phase post_cargo_new`.
- **`constitution-linter.sh` rule `transport-codegen-coverage`** —
  WARN-only ; opt-out via `FORGE_LINTER_SKIP_TRANSPORT_CODEGEN=1`.
- **Reference demo `demo-005-connect-greeting`** in
  `examples/forge-fsm-example/.forge/changes/` + TS reference client
  `examples/forge-fsm-example/clients/connect-client.ts` seeding a
  W3C `traceparent` header per call.
- **Test harness `t5.test.sh`** : 25 L1 + 5 L2 fixture tests, 25/25
  L1 GREEN at archive time.
- **Snapshot tarball** `full-stack-monorepo / 1.0.0.tar.gz` regenerated
  (~549 KB ; under the post-T.5 budget of 640 KB ; original 500 KB
  budget bumped — see `specs.md::FR-T5-CC-051`).
- **`docs/MIGRATION-PATHS.md`** — new top-level migration index
  (referenced by the WARN-only linter rule).
- **Design docs** : ADR-T5-001 (connectrpc Anthropic OSS), ADR-T5-002
  (toolchain pins resolved at design phase), ADR-T5-003 (TS-only
  client), ADR-T5-004 (`gen/connect/<lang>/<pkg>/...` layout),
  ADR-T5-005 (`transport-codegen-coverage` WARN-only),
  **ADR-T5-006** (`phase: post_cargo_new` template pattern).

### Added — T.4 ratification (`t4-adr-ratification`)

- Six versioned standards under `.forge/standards/*.yaml` ratifying the
  10 ADRs of `docs/ARCHITECTURE-TARGET.md` (sha256 pinned, drift gate
  active in `t4.test.sh`) :
  - `transport.yaml` (Connect-RPC + buf + tonic — structural exception)
  - `state-management.yaml` (flutter_bloc + 8-entry forbidden list — structural exception)
  - `observability.yaml` (OTel + OBI eBPF + Coroot + SigNoz)
  - `orchestration.yaml` (DBOS default + Temporal fallback trigger)
  - `identity.yaml` (Zitadel default + Firebase Auth / Auth0-SaaS-US forbidden)
  - `persistence.yaml` (Postgres 17 + pgvector 0.8 + Citus + DynamoDB / Firestore / Cosmos forbidden in T2/T3 strict)
- Two new JSON schemas :
  - `.forge/schemas/compliance-tier.schema.json` (T1/T2/T3 enum)
  - `.forge/schemas/archetype.schema.json` (5 canonical archetypes + `mobile-only` legacy alias ; `flutter-firebase` REMOVED)
- `.forge/standards/REVIEW.md` ledger (append-only review log) seeded
  with 6 entries (one per standard).
- `.forge/standards/global/standards-lifecycle.md` documenting the
  12-month review cycle + structural-exception escape.
- `.forge/standards/global/source-document-pinning.md` documenting the
  sha256 + rehash convention used to detect drift in external documents
  ratified by Forge changes.
- `bin/forge-rehash-architecture-doc.sh` escape hatch script for
  trivial doc edits (typo fix / formatting).
- New constitution-linter section "ADR-006 (State Management
  Discipline — no-state-management-alternatives)" — **WARN-only** at
  this stage ; transition to FAIL planned for B.8 (T6 — flagship
  migration). Opt-out : `FORGE_LINTER_SKIP_NSMA=1`.
- New test harness `t4.test.sh` (25 L1 + 5 L2 = 30 tests, ≤ 3 s wall-clock).
  Total CI harness count : 14 (was 13).
- Public `docs/STANDARDS-LIFECYCLE.md` for adopter-facing summary of
  the lifecycle policy.

### Changed

- `.forge/standards/index.yml` registers 8 new standards (6 YAML + 2
  global markdown).
- `.forge/scaffolding/dispatch-table.yml` annotates `mobile-only` as
  a legacy alias for the upcoming `mobile-pwa-first` archetype
  (full rename ships with B.9 in T8).
- `.forge/framework-owned-paths.yml` claims
  `bin/forge-rehash-architecture-doc.sh`,
  `docs/ARCHITECTURE-TARGET.md`, and
  `docs/STANDARDS-LIFECYCLE.md`.
- `constitution-linter.sh` summary line now includes a `WARN: <n>`
  counter alongside `PASS / FAIL / N/A`.

### Removed (taxonomy)

- **Archetype `flutter-firebase`** is REMOVED from the roadmap per
  ADR-007 (Schrems II + CLOUD Act incompatible with Forge's EU/premium
  positioning). The dispatch-table slot is annotated
  `status: removed_from_roadmap` to preserve `forge upgrade` history.
  Adopters who insist on Firebase keep the `default` archetype as a
  starting point. See `docs/ARCHETYPES.md` and
  `docs/new-archetypes-plan.md` §3.2.

### Notes

- **Constitution v1.1.0 unchanged.** This change ratifies decisions
  taken in `docs/ARCHITECTURE-TARGET.md` (sha256
  `cd8fef37ed01de981c8779a79d40234a70a4411387235dd990a86b705f3de925`)
  under the existing Article XII delegation — no Constitution
  amendment required.
- **Zero runtime code touched.** No edit under `cli/src/`, `frontend/`,
  `backend/`, `infra/`, `examples/forge-fsm-example/`. Methodology
  change only.
- **Linter rule activation timing.** `no-state-management-alternatives`
  ships in WARN mode now ; transitions to ERROR with B.8 (T6 — flagship
  migration). Adopters using forbidden state-management libraries
  (Riverpod / Provider / GetX / MobX / states_rebuilder) will see WARN
  lines in `verify.sh` from this release onwards but are not blocked.

## [0.3.0] — 2026-05-01

**Module B.1 + G.1 + C.1 + A.7 + B.5.1 + D.5 + B.4 + F.1 + F.2 + F.4
closed.** Thirteen changes accumulated since v0.2.1 (`b1-foundations` →
`b1-scaffolder` → `b1-workflow` → `b1-delivery` → `g1-forge-ci` →
`c1-reference-project` → `a7-forge-upgrade` → `b5-1-init-wizard` →
`d5-governance` → `b4-mobile-only` → `f1-open-questions` →
`f2-yaml-schema` → `f4-linter-extension`).

292/292 test scenarios PASS across 13 harnesses (foundations 21,
scaffolder L1+L2 21, workflow L1+L2 16, delivery 24, g1 14, c1 30,
**a7 29**, **b5 17**, **d5 15**, **b4 47**, **f1 17**, **f2 18**,
**f4 23**) ; verify.sh 108 PASS / 0 FAIL / 1 WARN ; constitution-
linter 18 PASS / 0 FAIL / 9 N/A — OVERALL PASS (1.97s ≤ 3s budget) ;
Vitest 56/56.

**Constitution bumped v1.0.0 → v1.1.0** via amendment #1 (add Article
XII — Governance ; ratified 2026-04-30). **T2 P1 + T2 P2 + T3
robustness all closed** (F.1 + F.2 + F.4 delivered). Guard-rail
"no PR optim → main, no v0.3.x release" is now liftable at user
discretion. The framework is technically ready for v0.3.0.

### Added — `f4-linter-extension` (2026-05-01)

Extends `constitution-linter.sh` to cover four constitutional
articles previously not enforced statically. Closes Audit Module
F.4 (T3 robustness, third and final item). Constitution coverage
estimated ~70% → ~85%.

- **Article V.1 — Task ↔ FR Linkage** : for each change with
  `status` ∈ {planned, implemented, archived}, `tasks.md` MUST
  contain ≥ 1 `[Story: FR-` reference. Proves the audit trail
  exists. V.2 / V.3 (runtime violation handling and escalation)
  remain runtime-only — not statically checkable.
- **Article X.3 — Public API Documentation** : ratio of public
  Dart/Rust symbols carrying `///` doc comments must be ≥ 80%
  (default ; configurable via `FORGE_LINTER_X3_THRESHOLD`). Lists
  the first 5 missing-doc symbols on FAIL. Walks back through
  blank lines and `@`/`#[...]` attributes to detect `///` correctly.
  `not_applicable` when no source dirs found (Forge framework
  itself).
- **Article XI.3 — Generative UI** : heuristic warning (NOT fail)
  when AI imports (`anthropic|openai|gpt-|claude|@google/genai|llm|langchain`)
  + UI rendering (`Widget|render`) coexist without a referenced
  `*.schema.json`. Static linting cannot prove a XI.3 violation
  ; the warning prompts manual audit.
- **Article XI.5 — Mandatory Fallback Tested** : name-based pair
  `lib/**/*[fF]allback*.dart` ↔ `test/**/*[fF]allback*_test*.dart`
  (or `tests/` for Rust). FAIL on missing pair. Special case :
  `schema: ai-first` without any `*fallback*` file → FAIL
  "Article XI.5 requires a fallback implementation".
- **Per-rule opt-out env vars** : `FORGE_LINTER_SKIP_V_1`,
  `_X_3`, `_XI_3`, `_XI_5`. Plus `FORGE_LINTER_X3_THRESHOLD` to
  override the X.3 default.
- **New `warn` helper** in `constitution-linter.sh` + `WARN`
  counter (used by Article XI.3 only — warnings don't affect exit
  code).
- **Standard** — `.forge/standards/global/linting-rules.md` (6 H2 :
  Purpose, Article V.1, Article X.3, Article XI.3, Article XI.5,
  Opt-Out Mechanism). Documents heuristics, limitations, opt-outs,
  and the procedure for adding a new rule (Article XII amendment
  process). Indexed in `standards/index.yml`.
- **Documentation** — `docs/LINTING.md` (~140 lines) walks
  contributors through running the linter, reading FAIL messages,
  fixing common errors, opting out, heuristic limitations.
- **Harness `f4.test.sh`** — manifest pattern, 16 L1 + 7 L2
  fixture-based tests. L2 covers : V.1 fail, V.1 pass, X.3 fail,
  X.3 threshold env override, XI.3 warn, XI.5 fail, opt-out env
  var. Registered in `forge-ci.yml`.
- **Bug fix discovered along the way** — the X.3 Python heredoc
  initially conflicted with stdin (heredoc + pipe both targeting
  python3 stdin). Fixed by passing files as argv instead of
  reading sys.stdin.
- **Spec consolidated** at `.forge/specs/linter-extension.md`
  (FR-LE-001..022 + NFR-LE-001..004 + 6 BDD scenarios).

### Added — `f2-yaml-schema` (2026-05-01)

Formal JSON Schema for per-change `.forge.yaml` + standalone
validator + `verify.sh` gate. Closes Audit Module F.2 (T3
robustness). Second F-cluster delivery on optim.

- **Schema** — `.forge/schemas/change.schema.json` (JSON Schema
  Draft 2020-12). Required : `name` (slug pattern), `status` (6-value
  enum), `created` (ISO 8601), `schema` (archetype enum),
  `constitution_version` (semver). Optional : `timeline` (per-phase
  ISO dates), b1-workflow extensions (`layers`, `designs_per_layer`,
  `tasks_per_layer`), historical extended fields (`parent_audit_items`,
  `depends_on`, `archived_to`, `schema_promotion`, `promotes_schema`)
  for backward-compatibility with pre-F.2 archived changes.
- **Validator** — `.forge/scripts/validate-change-yaml.sh` standalone
  bash + Python 3 inline (PyYAML stdlib only ; no `jsonschema`
  dependency, decision Q-001). Phase 1 = schema validation (required,
  enum, pattern, type, additionalProperties). Phase 2 = timeline
  coherence (FR-YS-008/009 : `status >= phase` requires
  `timeline.<phase>` ; `archived` requires the full timeline).
  Date coercion : unquoted YAML dates (parsed as `datetime.date`) are
  stringified before pattern check.
- **`verify.sh` Open Questions Gate** — new section `── Change YAML
  Schema ──` iterates over `.forge/changes/*/.forge.yaml` and invokes
  the validator. Skip-guard `examples/` honored.
- **Backward-compat audit** (ADR-007 — critical step) — validator
  was run against the 11 pre-F.2 archived changes BEFORE wiring the
  gate. Initial run flagged 2 systemic issues : (1) PyYAML parses
  unquoted dates as `datetime.date` not `string` — fixed via
  date-coercion in the validator ; (2) historical extended fields
  not in schema — fixed by adding optional schema entries that
  document these legacy fields. Final result : 11/11 PASS.
- **Standard** — `.forge/standards/global/change-yaml-schema.md`
  (5 H2 sections : Purpose, Schema Reference, Required Fields,
  Timeline Coherence Rules, Extending the Schema). Indexed in
  `standards/index.yml` with triggers `change.yaml`, `.forge.yaml`,
  `schema validation`, `JSON Schema`, `status enum`,
  `timeline coherence`.
- **Documentation** — `docs/SCHEMA.md` (~95 lines) — required shape,
  manual validation, common errors with fix recipes, how to add a
  new archetype to the enum, how to add a new status (Constitution
  amendment workflow per Article XII).
- **Harness `f2.test.sh`** — manifest pattern, 13 L1 + 5 L2
  fixture-based. L2 covers : valid YAML PASS, invalid name (uppercase)
  FAIL, invalid status (`closed`) FAIL, archived without
  `timeline.archived` FAIL, all 11 archived changes PASS (NFR-YS-001
  audit). Drift detector test (`_test_f2_006`) catches schema enum
  drift when a new archetype is added without a schema bump.
  Registered in `forge-ci.yml` job `harness` after `f1.test.sh`.
- **Constitution-linter robustness fix** — improved the "Article
  III.4 — no NEEDS CLARIFICATION inline" rule to detect markers
  inside any inline-code-span (\`...\`) on the same line, not only
  immediately backtick-prefixed. Awk-based backtick parity counter
  before the marker position. Fixes a documentary false-positive in
  `f1-open-questions/design.md` line 353.
- **Spec consolidated** at `.forge/specs/change-yaml-schema.md`
  (FR-YS-001..022 + NFR-YS-001..004 + 5 BDD scenarios).

### Added — `f1-open-questions` (2026-05-01)

Mechanisation of Article III.4 (Anti-Hallucination Protocol). Adds
the per-change `open-questions.md` convention with `Q-NNN` sequential
identifiers, status enum (`open` / `answered` / `wontfix`), resolution
block; new `verify.sh` Open Questions Gate that blocks archive on
lingering open questions; new `constitution-linter.sh` rule that
blocks `[NEEDS CLARIFICATION:` inline in `implemented` or `archived`
changes (with smart exclusions for documentary mentions inside
backticks / HTML comments / fenced code blocks); new
`bin/forge-questions.sh` aggregator script with `--change` and
`--status` filters. Closes Audit Module F.1 (T3 robustness). First
T3 change ; F.2 + F.4 still pending.

- **Standard** — `.forge/standards/global/open-questions.md`
  (8 H2 sections : Purpose, File Location and Lifecycle, Question
  Schema, Status Enum, Resolution Block, Verify Gate, Linter Rule,
  Discovery + 3 Interdictions: no modify answered, no reuse Q-NNN,
  no inline marker in implemented/archived). Indexed in
  `standards/index.yml`.
- **Template** — `.forge/templates/open-questions.md.tmpl` with
  documentation header explaining the schema. New changes are
  expected to start with this stub at `/forge:propose` time.
- **`verify.sh` Open Questions Gate** — new section
  `── Open Questions Gate ──` ; for each change with
  `status: archived` and `open-questions.md` present,
  `grep -cE '^- \*\*Status\*\*: open$'` ; FAIL if count > 0.
  Skip-guard `examples/` honoured. Backwards-compatible : absent
  file = SKIP (no FAIL).
- **`constitution-linter.sh` rule** — new "Article III.4
  (Anti-Hallucination — no NEEDS CLARIFICATION inline)" check
  scoped to `implemented` and `archived` changes only. Uses awk
  with code-fence state tracking (\`\`\`...\`\`\`) + HTML comment
  exclusion (`<!-- ... -->`) + backtick-wrapped marker exclusion
  (`\`[NEEDS CLARIFICATION...\``). Avoids false positives on
  documentary uses of the marker.
- **`bin/forge-questions.sh`** — bash + awk aggregator (no new
  dep). Default lists every `Status: open` question across
  `.forge/changes/*/open-questions.md`, sorted by `Raised on`
  asc. `--change <name>` filters to one change ;
  `--status <enum>` filters by status (`open`, `answered`,
  `wontfix`). Output : `<change>:Q-NNN  <title>  (raised
  <date> by <handle>)`.
- **Harness `f1.test.sh`** — manifest pattern, 12 L1 +
  5 L2 fixture-based (the L2 tests build temp `.forge/`
  trees, scope `FORGE_ROOT` to the tmpdir, exercise the gate
  / linter / aggregator end-to-end). Registered in
  `forge-ci.yml` job `harness` after `b4.test.sh`.
- **Backwards compatibility verified** — 10 pre-F.1 archived
  changes (b1-*, g1, c1, a7, b5-1, d5, b4) untouched and stay
  green : verify.sh 84/0, constitution-linter OVERALL PASS,
  a7.test.sh 29/29 (NFR-OQ-007 — forge upgrade unaffected).
- **Documentation** — `docs/OPEN_QUESTIONS.md` (~110 lines)
  walks contributors through raising / resolving / aggregating
  questions, with concrete examples and the in-flight emergence
  workflow ("if a question surfaces while implemented, demote
  status back to planned, resolve, re-promote").
- **Spec consolidated** at `.forge/specs/open-questions.md`
  (FR-OQ-001..022 + NFR-OQ-001..004 + 6 BDD scenarios).

### Added — `b4-mobile-only` (2026-04-30)

Second archetype premium. **Flutter iOS + Android** with OIDC via
`flutter_appauth` (PKCE), secure token storage (Keychain /
EncryptedSharedPreferences + StrongBox), biometric lock with
re-prompt-after-backgrounding, App Attest (iOS) + Play Integrity
(Android) device attestation, Fastlane per-platform pipelines,
GitHub Actions CI. Closes Audit Module B.4. Delivered in 3 phases
on `optim` (Phase A core scaffold, Phase B runtime + standard,
Phase C Fastlane + CI + archive).

**First validation of the B.5.1 dispatcher ABI** : zero TypeScript
edit. Adding `mobile-only` = 1 entry in `dispatch-table.yml` + 1
`bin/forge-init-mobile-only.sh` wrapper. **First change ratified
under Constitution v1.1.0** (post-D.5).

- **Schema** — `.forge/schemas/mobile-only/schema.yaml` declares
  single-layer `app`, iOS deployment 15.0, Android `minSdk 26 /
  targetSdk 34 / compileSdk 34`. Bound to Articles I, II, III, IV,
  V, VI, IX, X, XII (VII, VIII, XI explicitly NA).
- **Wrapper** — `bin/forge-init-mobile-only.sh` stable ABI per
  B.5.1 (`--target / --project-name / --reverse-domain / --force`).
  Validates `project-name = [a-z][a-z0-9_]+` and reverse-domain
  FQDN. Substitutes `{{project_name}}`, `{{reverse_domain}}`,
  `{{reverse_domain_path}}` (slash-separated) via `rsync + sed`.
  Idempotent with `--force`.
- **Templates** — `.forge/templates/archetypes/mobile-only/` with
  Flutter project skeleton (pubspec pinned `flutter_bloc`,
  `flutter_appauth`, `flutter_secure_storage`, `local_auth`,
  `opentelemetry_api/sdk`, `bloc_test`, `mocktail`, `gherkin` ;
  `analysis_options.yaml` strict with 5 lints), 4-layer `lib/`
  (domain / data / presentation / infrastructure), iOS native
  config (`Info.plist` with `MinimumOSVersion 15.0` +
  `NSFaceIDUsageDescription`, `Podfile` pinned, `AppDelegate`),
  Android native config (`build.gradle.kts` minSdk 26 + Play
  Integrity dep, `AndroidManifest.xml` with `USE_BIOMETRIC` +
  `INTERNET` + `FlutterFragmentActivity` + OIDC redirect
  intent-filter, `MainActivity.kt`).
- **OIDC + Auth + secure storage + biometric + attestation** —
  Phase B runtime modules : `OidcConfig` (provider-neutral with
  `TODO_REPLACE_*` placeholders pointing Auth0 / Keycloak / Okta /
  Cognito), `AuthRepository` interface + `AuthRepositoryImpl`
  (PKCE via `FlutterAppAuth` + secure storage + DeviceAttestor +
  OTel `auth.login` / `auth.refresh` / `auth.logout` spans, NEVER
  logs token), `AuthBloc` (5 states + 4 events),
  `SecureStorageAdapter` (Keychain + EncryptedSharedPreferences +
  StrongBox preference), `BiometricService` (`local_auth`
  `biometricOnly: true / stickyAuth: true`), `BiometricLockWidget`
  (WidgetsBindingObserver, default 60s timeout, overlay), three
  `DeviceAttestor` impls (iOS App Attest via `DCAppAttestService`,
  Android Play Integrity via `IntegrityManager`, Fake for tests),
  Swift `AppAttestService.swift` (channel
  `forge.attestation/app_attest`), Kotlin `PlayIntegrityService.kt`
  (channel `forge.attestation/play_integrity`).
- **Observability** — `lib/observability/otel_init.dart` with
  OTLP HTTP exporter, default endpoint `http://localhost:4318`,
  configurable. `lib/main.dart` wires `BlocObserver` + `initOtel()`
  + `runApp(App())`.
- **Fastlane** — `ios/fastlane/{Fastfile, Appfile, Matchfile}` and
  `android/fastlane/{Fastfile, Appfile}` with lanes `:beta` (TestFlight /
  Play Internal), `:release` (App Store manual / Play Production
  draft), `:screenshots` (snapshot / screengrab). All secrets flow
  through `ENV[...]` ; `.envrc.example` documents `MATCH_PASSWORD`,
  `APP_STORE_CONNECT_API_KEY_PATH`, `PLAY_STORE_JSON_KEY`,
  `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`, etc.
- **CI workflow** — `.github/workflows/mobile-ci.yml.tmpl` with
  `ios` job (macos-latest, no codesign), `android` job
  (ubuntu-latest, debug APK + 70 % coverage threshold via lcov +
  awk), `summary` required check, `e2e-android` opt-in via
  `workflow_dispatch`. Cache `~/.pub-cache` keyed on
  `pubspec.lock` hash.
- **Standard** — `.forge/standards/global/flutter-mobile.md` (7 H2
  sections : Lifecycle / Permissions / OIDC and Token Storage /
  Biometric Lock / Device Attestation / Native Configuration / CI
  and Fastlane) + 3 explicit Interdictions (no SharedPreferences /
  NSUserDefaults for tokens, no token logging, no biometric bypass
  in non-debug). Indexed in `standards/index.yml`.
- **Archetype-specific framework-owned-paths** — per ADR-014, the
  archetype ships its own `framework-owned-paths.yml.tmpl`
  scaffolded into the project root. Lists OIDC config, OTel init,
  native bridges, Fastfile lanes, `mobile-ci.yml` as owned (3-way
  merged on `forge upgrade`). Excludes adopter-tuned files
  (`Appfile`, `Info.plist`, `AndroidManifest.xml` post-scaffold).
- **Snapshot** — `.forge/scaffold-snapshots/mobile-only/1.0.0.tar.gz`
  (219 files, 465 KB gzipped, 23 % of NFR-MO-001 budget 2 MB).
- **Harness `b4.test.sh`** — manifest pattern with 42 L1 + 5 L2
  fixture-based tests (scaffolds tmp project via wrapper, asserts
  substitutions + idempotence + `--force` protection +
  reverse_domain propagation to Info.plist and build.gradle.kts).
  Registered in `.github/workflows/forge-ci.yml` job `harness`.
  `docs/ARCHETYPES.md` updated : `mobile-only` is now Active in the
  decision matrix.
- **Spec consolidated** at `.forge/specs/mobile-only.md`
  (FR-MO-001..040 + NFR-MO-001..008 + 7 BDD scenarios).

### Added — `d5-governance` (2026-04-30)

Operational governance model and Code of Conduct. Closes Audit
Module D.5 (last T2 P1 facilitator). Constitution amended
v1.0.0 → v1.1.0 (Article XII delegates operational rules to
`GOVERNANCE.md`, principles vs. procedures delimitation).

- **`GOVERNANCE.md`** at repo root — BDFL-with-fallback model :
  current phase (Constitution `1.x` ∧ < 5 regular contributors)
  has Benoit Fontaine (`@bfontaine`) as BDFL ; mature phase
  (activated by future amendment) has a 3-7 member maintainer
  committee with majority vote, BDFL keeping veto on amendments
  only. Documents Roles and Responsibilities, Amendment Process
  (≥ 4 numbered steps, **7-day public discussion** minimum),
  Release Process (4 steps, semver `vX.Y.Z` tag), Code of
  Conduct delegation, Contact (`contact@benoitfontaine.fr` +
  GitHub Discussions/Issues).
- **`CODE_OF_CONDUCT.md`** at repo root — verbatim
  **Contributor Covenant v2.1** fetched from
  `contributor-covenant.org`, only the official
  `[INSERT CONTACT METHOD]` placeholder substituted with the
  governance contact email. ADR-002 forbids any other edit.
- **Constitution amendment** — new **Article XII — Governance**
  inserted between Article XI and the `## Amendments` table.
  Article XII delegates Process Gate ownership to `GOVERNANCE.md`,
  preserves the principles-vs-procedures separation, and forbids
  diluting Constitutional guarantees through `GOVERNANCE.md`
  edits. `**Version**: v1.1.0` shown in the header block ;
  amendment row #1 dated `2026-04-30` ratified by Benoit Fontaine
  (BDFL).
- **Template bumps** — `.forge/templates/change.yaml` × 2
  (active line + commented example block) and
  `.forge/templates/archetypes/full-stack-monorepo/.forge.yaml.tmpl`
  bumped to `"1.1.0"`. **Archived changes are not modified** — they
  keep `"1.0.0"` for historical traceability. **The d5-governance
  change itself stays at `"1.0.0"`** in its `.forge.yaml` (ADR-006
  precedent : a change-amendment is ratified UNDER version N and
  CREATES version N+1, never circular).
- **README** — `## Governance` section gains a `[Governance model]`
  link as the first bullet, leading the existing CoC / Security /
  Changelog / Versioning links.
- **Harness `d5.test.sh`** — 15 manifest-pattern tests,
  one per FR-GOV-*, registered in
  `.github/workflows/forge-ci.yml` under the `harness` job.
  `b5.test.sh` was also added to the same job (regression spotted
  during D.5 review : the b5.1 archive shipped without CI
  registration). Both register nominally next to `a7.test.sh`.
- **Spec** consolidated at `.forge/specs/governance.md` with the
  full `FR-GOV-*` namespace + 4 NFR-GOV-* + 5 BDD scenarios.

**Article XII implications for future contributors** — any
operational tweak (appoint a co-maintainer, refine the release
checklist, update contact channels) lands via a regular PR to
`GOVERNANCE.md`. Any structural change (BDFL → committee, change
the discussion window, change veto rules) requires a Constitution
amendment, recorded in the Amendments table with a fresh
`**Version**:` bump.

### Added — `b5-1-init-wizard` (2026-04-30)

`forge init` becomes the **canonical entry point** for project
scaffolding with three selection modes : `--archetype <name>`
(explicit), `--auto` (signals heuristic), `--wizard` (interactive
prompt). Closes Audit Module B.5.1. Dependency amont of
B.2 / B.3 / B.4 (T3 second-archetype work) — adding a future
archetype = registering one row in the dispatch table + one
`bin/forge-init-<archetype>.sh` wrapper, NO TS edits.

- **TS dispatcher** — `cli/src/commands/init.ts` refactored
  into a pure dispatcher routing argv to one of four code
  paths : explicit archetype, auto-detection, wizard, or silent
  default (no flags + non-TTY stdin → preserves legacy
  behavior, NFR-IW-004). Mutual exclusion of selection flags ;
  exits 2 on conflicting flags or unknown archetype.
- **Domain pure functions** — `cli/src/domain/archetype-detect.ts`
  (heuristic over a signal record, returns
  match/ambiguous/none), `cli/src/domain/reverse-domain.ts`
  (regex validator), `cli/src/domain/dispatch-table.ts`
  (minimal YAML subset parser, zero new third-party deps per
  NFR-IW-002).
- **Wizard via Node `readline`** — sequential prompts
  (numbered archetype menu, project name, reverse domain),
  re-prompt × 3 on invalid input, auto-skip when stdin is
  non-TTY. NO `inquirer` / `prompts` / `enquirer` etc.
- **Stable per-archetype scaffolder ABI** —
  `bin/forge-init-<archetype>.sh --target <dir> --project-name
  <slug> --reverse-domain <fqdn> [--force]`. The TS dispatcher
  shells out via this ABI ; the wrapper translates to the
  underlying scaffolder's native flags. At archive : one
  wrapper shipped (`bin/forge-init-fsm.sh` for
  `full-stack-monorepo`, translates to `init.sh` of
  `b1-scaffolder`).
- **Dispatch table** at `.forge/scaffolding/dispatch-table.yml`
  with 2 active archetypes (`default`, `full-stack-monorepo`).
  Forward-compatible : new optional fields can be added without
  breaking parsers. The dispatcher reads it at runtime ; no
  hard-coded archetype names in TS source (Interdiction).
- **Strict ambiguity abort** (Article III.4) — `--auto` on a
  target with ambiguous signals emits `[NEEDS DECISION: ...]`
  and exits 2. Today, `pubspec.yaml`-only or `Cargo.toml`-only
  is ambiguous because no Flutter-only or Rust-only archetype
  ships yet ; abort message guides adopters to
  `--archetype default`.
- **Standard** `.forge/standards/global/scaffolding.md` with
  6 H2 sections + 3 Interdictions covering : dispatch table
  contract, per-archetype scaffolder ABI, auto-detection
  heuristic, wizard mode, adding a new archetype.
- **Decision matrix** at `docs/ARCHETYPES.md` with 5 rows
  (2 active + 3 planned). Public-facing onboarding doc.
- **Test harness `b5.test.sh`** — 17/17 PASS at L1 + L2.
  L1 hermetic (yml shape, scaffolder paths, standard sections,
  index entry, decision matrix, feature file, regex, no new
  third-party deps). L2 fixture-based (CLI flag parsing,
  default-dispatcher idempotence, wizard non-TTY skip,
  ambiguous auto abort). L3 deferred to scaffolder.test.sh
  (same scaffolder under the hood).
- **Vitest** — 16 new unit tests (5 archetype-detect cases,
  9 reverse-domain cases, 7 dispatcher path-selection tests,
  5 init-default migrated tests preserving file-copy
  semantics). Total Vitest 56/56.
- **MODIFIED FR-GL-011** in
  `.forge/specs/full-stack-monorepo.md` : the npm CLI is now
  the canonical entry point ; direct invocation of `init.sh`
  remains supported as an escape hatch.

Cumulative test status : foundations 21, scaffolder L1+L2 14,
workflow L1+L2 11, delivery 24, g1 14, c1 30, a7 29, b5 17.
**160 total**. Vitest 56/56. Verify.sh 64 PASS / 0 FAIL.

Smoke tests on the built CLI :
- `forge init --archetype default --target <tmp>` →
  exit 0 + "forge init: copied N, scaffolded M, skipped K — OK".
- `forge init --auto --target <pubspec-only-dir>` →
  exit 2 + "[NEEDS DECISION: ...]".
- `forge init --archetype default --auto` →
  exit 2 + "--archetype, --auto, --wizard are mutually exclusive".

### Added — `a7-forge-upgrade` (2026-04-30)

`forge upgrade` — non-destructive 3-way merge of framework
updates into scaffolded projects. Closes Audit Module A.7. The
single biggest blocker for the first wave of adopters : without
this, every Constitution / standards / agents bump becomes a
manual copy-paste chore that destroys local customizations.

- **New CLI subcommand** `forge upgrade [target]` —
  `cli/src/commands/upgrade.ts` (TypeScript thin orchestrator
  with dependency-injected runner / readManifest /
  resolveFrameworkVersion). Spawns the underlying shell driver
  via `node:child_process.spawn`. Flags : `--target <dir>`,
  `--dry-run`, `--force`, `--verbose`. Exit codes : 0 success,
  2 argument error, 5 missing tool, 7 upgrade aborted (major-
  version migration / dirty Git tree / non-Git target with
  `--force`), 8 conflicts produced (without `--force`).
- **Shell driver** `bin/forge-upgrade.sh` — library + main
  pattern. Sourcing exposes `_a7_*` helpers for unit-style
  testing (truth-table classify, three-way merge, conflict
  recording, force gate, version compat, manifest history
  append). Direct invocation runs `_a7_main()` end-to-end.
- **3-way merge** — for each path in `.forge/framework-owned-paths.yml`
  `owned:` list : SHA-256 sameness comparison drives a 4-cell
  truth table (unchanged, upgraded, preserved, merge_candidate)
  + 1 cell for 2-way fallback when BASE is unavailable. The
  merge_candidate cell delegates to `git merge-file --diff3`
  which is battle-tested and writes git-style conflict markers
  in-place.
- **BASE recovery** — `.forge/scaffold-snapshots/<archetype>/<version>.tar.gz`
  contains the framework's `owned:` paths at that version.
  Bundled into the CLI tarball via the existing
  bundle-assets.mjs pipeline. First snapshot at archive time :
  `full-stack-monorepo / 1.0.0` is 422 KB gzipped (41 % of
  NFR-UP-003 1 MB on-disk budget). Built via the new helper
  `bin/forge-snapshot.sh build <archetype> <version>`.
- **Conflict resolution** — git-style markers (`<<<<<<<` /
  `|||||||` / `=======` / `>>>>>>>`) in-place + a
  `.merge-conflicts` companion file at the project root listing
  every conflicted path with `[CONFLICT]` prefix. The companion
  is gitignored (FR-UP-012).
- **`--force` discipline** — requires a clean Git working tree
  (`git status --porcelain` empty) ; rejects with exit 7 on
  dirty trees (suggests `git stash` / `git commit`) and on
  non-Git targets (suggests `git init`).
- **Major-version migration boundary** (Article III.4
  anti-hallucination) — same major → proceed ; major diff →
  exit 7 with `[NEEDS MIGRATION: from X.Y.Z to A.B.C]`.
  Future `docs/MIGRATIONS.md` will document each major bump's
  required adopter actions.
- **`upgrade_history`** — new optional top-level field in
  `scaffold-manifest.yaml`. Append-only list of upgrades :
  date, from_version, to_version, from/to template_set_sha,
  per-category counts, cli_version. Identity fields
  (`project_name`, `reverse_domain`, `root_module`) are
  immutable post-scaffold. MODIFIED FR-GL-009 of `b1-scaffolder`.
- **Standard** `.forge/standards/global/upgrade-policy.md` —
  6 H2 sections (Framework-owned paths, Three-way merge policy,
  Conflict resolution discipline, Schema-version migration
  boundary, Upgrade history audit trail, Interdictions). Three
  Interdictions : (1) hand-editing `owned:` files outside a
  Forge change, (2) `forge init --force` instead of
  `forge upgrade`, (3) committing `.merge-conflicts`.
- **Test harness `a7.test.sh`** — 29/29 PASS. L1 hermetic
  (yml shape, owned paths exist, snapshot extractability +
  size budget, standard sections, index entry, .gitignore,
  feature file, CLI flags, archive-gated spec). L2 fixture-based
  (truth table 5 cells, conflict markers, .merge-conflicts
  listing, --force × 3 cases, version compat × 2, history
  append + append-only + identity-immutable, idempotence,
  legacy compat, deterministic merge, BASE recovery). L3 opt-in
  against `examples/forge-fsm-example/`. Manifest pattern with
  meta self-check.
- **Vitest unit tests** — `cli/test/commands/upgrade.test.ts`
  (5 tests : flag forwarding, missing manifest, version
  resolution failure, exit code propagation, dry-run / force /
  verbose flag wiring).
- **forge-ci.yml** harness job extended with
  `g1.test.sh` + `c1.test.sh` + `a7.test.sh` (catching up an
  oversight from g1/c1 archive — the two prior harnesses were
  not invoked from CI). Workflow now at 211 lines (under 250
  NFR-CI-002 budget).
- **Smoke test** against `examples/forge-fsm-example/` —
  `forge upgrade --dry-run` reports 160 unchanged + 15
  preserved + 0 upgraded/conflicted/skipped, exit 0. The 15
  preserved files are the c1 demo customizations
  (READMEs, demo Cargo.toml entries, demo source files) — the
  framework correctly identifies them as user-edited and
  preserves them.

Spec consolidation : new `.forge/specs/upgrade.md` (15 FR-UP-*
+ 6 NFR-UP-*). MODIFIED FR-GL-009 in
`.forge/specs/full-stack-monorepo.md` (scaffold-manifest gains
`upgrade_history`).

**Module B.1 closed + Module G.1 closed + Module C.1 closed.**
Six changes accumulated since v0.2.1 :
`b1-foundations` → `b1-scaffolder` → `b1-workflow` → `b1-delivery`
shipped the flagship archetype `full-stack-monorepo` end-to-end
(Flutter + Rust + Infra with multi-layer change orchestration,
4 reference CI workflows, Kustomize base + 3 deployment overlays,
local OTel + SigNoz observability stack — scaffoldable via
`/forge:init --archetype full-stack-monorepo`). Schema promoted
from `draft / 0.1.0` → `candidate / 1.0.0-rc.1` →
**`stable / 1.0.0`** with `promoted_from / promoted_in /
promoted_on` traceability fields.

`g1-forge-ci` then closed the dog-fooding gap : Forge runs its
own gates in CI on every PR via `forge-ci.yml` (now 6-job
workflow with single required status `forge-ci / summary`).

`c1-reference-project` closed Module C.1 : the first public
reference project lives at `examples/forge-fsm-example/` —
fully-scaffolded `full-stack-monorepo` tree (~2.3 MB) with 4 demo
changes (3 archived single + multi-layer demos + 1 in-flight
`status: specified` demo with `[NEEDS CLARIFICATION:]` markers).
Skip-guards in `verify.sh` + `constitution-linter.sh` ; new
`example` job in `forge-ci.yml` (paths-filter on `examples/**`).
NFR-017 (overlay diff) measured at 2124 bytes (52 % of 4 KB
budget) ; NFR-013/014/015 standardized as `TBD`-pending ledgers
in their target standards.

114/114 test scenarios PASS across 6 harnesses (foundations 21,
scaffolder 14, workflow 11 at L1+L2, delivery 24, g1 14, c1 30).

### Added — `c1-reference-project` (2026-04-30)

First public reference project scaffolded via the actual
`forge init --archetype full-stack-monorepo` command and committed
verbatim under `examples/forge-fsm-example/`. Closes Audit Module
C.1.

- **Reference tree** at `examples/forge-fsm-example/` —
  fully-scaffolded `full-stack-monorepo` project (frontend +
  backend + infra + shared/protos + .forge + .claude +
  .github/workflows + Taskfile + docker-compose + scaffold-manifest).
  Tree size ≈ 2.3 MB (52 % of NFR-EX-002 5 MB budget). Tools at
  scaffold time : flutter 3.41.7, cargo 1.91.0, buf 1.68.4.
- **4 demo application changes** under
  `examples/forge-fsm-example/.forge/changes/` :
    * `demo-001-greeting-service` (single-layer backend, archived) —
      gRPC Greeter service with hexagonal Rust, proto contract
      under `shared/protos/v1/greeting/`, 5 unit tests pass on
      domain + application crates.
    * `demo-002-greeting-screen` (single-layer frontend, archived) —
      Flutter Cubit + screen consuming demo-001's contract via a
      fake adapter, 8 widget + bloc_test tests pass.
    * `demo-003-rate-limit` (multi-layer backend+infra, archived) —
      triggers Janus orchestration with per-layer designs / tasks
      (FR-GL-016) ; adds Kong rate-limiting plugin to
      `kong.yml.example`.
    * `demo-004-user-onboarding` (multi-layer specified-only) —
      illustrates Article III.4 anti-hallucination protocol with
      4 realistic `[NEEDS CLARIFICATION:]` markers on
      product/security decisions ; intentionally not advanced
      past the spec phase.
- **Demo manifest** at
  `examples/forge-fsm-example/.forge/changes/MANIFEST.md` listing
  the 4 demos chronologically.
- **Skip-guards on Forge gates** (FR-GL-026 / FR-GL-027 /
  FR-GL-028) :
    * `verify.sh` adds the `FORGE_REPO_DETECTED` signature check +
      defensive `is_under_examples` helper. `[skipped: examples]`
      lines emitted on framework-repo invocations.
    * `constitution-linter.sh` mirrors the signature check + adds
      the `find_excluding_examples` wrapper applied to the two
      recursive walks (`*.feature` files at line ~123,
      `Dockerfile*` at line ~335). `FORGE_ROOT` is now
      env-overridable for testability (parity with `verify.sh`).
    * Root `.gitignore` covers `examples/*/{build,target,
      .dart_tool,node_modules,.cargo,coverage,cli}/`.
- **Forge's own CI extension** (FR-CI-012 + FR-CI-013, MODIFIED
  FR-CI-001 + FR-CI-006) : new `example` job in `forge-ci.yml`
  with `dorny/paths-filter@v3` on `examples/**` ; on a filter
  miss, the job emits `skipped` (treated as success by the
  summary). When the filter matches, the job runs the example
  tree's `verify.sh` + `constitution-linter.sh` + a structural
  YAML parse over archetype workflow `.tmpl` files. Workflow
  shape modified from 5 to 6 top-level jobs ;
  `summary.needs` extended from 4 to 5 ; success message bumped
  to `5/5 jobs PASS`.
- **NFR baselines** (FR-EX-008, MODIFIED NFR-013/014/015/017) :
    * `standards/infra/ci-workflows.md` § Performance Baselines
      added (TBD ledgers for NFR-013 + NFR-014 — populated on
      first observed PR / nightly run).
    * `standards/infra/observability-local.md` § Startup
      Baselines added (TBD ledger for NFR-015).
    * `standards/infra/k8s-overlays.md` § Diff Budget added
      with **measured** NFR-017 baseline : **2124 bytes (52 % of
      4096-byte budget)** via
      `kubectl kustomize overlays/{dev,prod}` against
      `examples/forge-fsm-example/infra/k8s/`.
    * `specs/full-stack-monorepo.md` gains a "Baseline at
      archive time of c1-reference-project" pointer line under
      each of the 4 affected NFR sections.
- **Test harness `c1.test.sh`** (FR-EX-009) — manifest pattern,
  L1 hermetic by default, L2 opt-in `--require-example-tools`
  (runs the example's own gates), L3 opt-in
  `--require-external-tools` (reproducibility check by re-running
  the scaffolder). 30 tests covering all FR-EX-* / MODIFIED
  FR-CI-* / FR-GL-026..028 / NFR-EX-* / NFR-013/014/015/017
  baselines. Invoked from `verify.sh` Section 7 alongside the
  existing 5 harnesses.
- **Spec consolidation** at `.forge/specs/example-reference.md`
  (FR-EX-010) — new consolidated spec for the `FR-EX-*`
  namespace, mirrors the convention used for `forge-ci.md` after
  `g1-forge-ci`. Distinct audience from `full-stack-monorepo.md`
  (archetype contract) — this new spec governs the example tree
  itself.
- **Drift fix** : `scaffold-plan.yaml` bumped from `0.1.0` →
  `1.0.0` to align with the schema's stable promotion at
  `b1-delivery`. The drift was surfaced by c1 — `b1-delivery`
  promoted the schema but the plan version was not bumped at the
  time, so manifests carried 0.1.0.

Constitutional compliance : ✅ all 11 articles. Tests :
foundations 21/21, scaffolder L1+L2 14/14, workflow L1+L2 11/11,
delivery 24/24, g1 14/14, c1 30/30 (including the archive-gated
`test_example_reference_spec_present_post_archive`). Verify.sh :
59 PASS. Constitution-linter.sh : 4 PASS / 0 FAIL.

### Added — `g1-forge-ci` (2026-04-29)

Forge's own CI workflow — `.github/workflows/forge-ci.yml`. Closes
the dog-fooding gap left after B.1 : Forge will finally enforce
its own constitutional gates in CI rather than relying on
maintainer discipline.

- **Single workflow with 5 jobs** : `harness` (4 shell test
  harnesses), `gates` (`verify.sh` + `constitution-linter.sh`),
  `cli` (`npm ci` + lint + test + bundle), `lint` (shellcheck ×
  2 scandirs), `summary` (aggregator).
- **Triggers** : `pull_request: branches:[main]` +
  `push: branches:[main]`. No `paths-filter` (Forge is a flat
  repo, ADR-001 of g1-forge-ci) ; no `workflow_dispatch`.
- **Concurrency policy** with conditional `cancel-in-progress :
  ${{ github.event_name == 'pull_request' }}` — PRs cancel
  superseded runs, main pushes do not (ADR-002).
- **Permissions hygiene** : top-level `contents: read` only ;
  no per-job overrides ; principle of least privilege (Aegis pass).
- **Action pinning** : `actions/checkout@v4`,
  `actions/setup-node@v4`, `actions/setup-python@v5`,
  `ludeeus/action-shellcheck@2.0.0` — every `uses:` pinned, no
  `@main` / `@master` / `@HEAD`, no `:latest`.
- **Built-in `setup-node@v4` cache** keyed on `cli/package-lock.json`
  (ADR-008). NFR-CI-004 cache hit rate target ≥ 95%.
- **Summary aggregator** : always runs (`if: always()`), reads
  each `needs.<job>.result` via `env:` indirection (avoids
  mixing `${{ }}` with bash heredocs), exits 1 on any non-success
  with `::error::forge-ci: <job>=<result> FAILED`, emits
  `::notice::forge-ci: 4/4 jobs PASS` on full success (ADR-007).
- **`cli/.nvmrc`** — Node 20.18.0 patch-pinned (LTS), satisfies
  `cli/package.json engines.node: ">=20"`. Local maintainer
  tooling and CI read the same file for byte-identical Node
  across environments.
- **New standard `global/forge-self-ci.md`** (~150 lines, 3 H2
  sections) — Workflow shape, Differences from
  `infra/ci-workflows.md`, Branch protection. Documents
  deliberate deviations from the archetype workflows
  (no paths-filter, single workflow, no per-layer split — Forge
  is not a `full-stack-monorepo` project) and the manual
  branch-protection setup. Audience : Forge maintainers.
- **`docs/CONTRIBUTING.md`** gains a § Continuous Integration
  with branch-protection setup steps (manual GitHub UI config,
  not automated by Forge — least privilege).
- **`g1.test.sh` harness** (~440 lines, 14 tests at L1) —
  validates workflow shape (5 jobs, summary's `needs:`, no
  `continue-on-error: true`, paths-filter NOT used,
  `permissions: contents: read` only, every `uses:` pinned),
  `cli/.nvmrc` content, standard sections, index entry,
  `CONTRIBUTING.md` branch-protection text. Sources `_helpers.sh`
  per ADR-010 of `b1-delivery`. Manifest comment block enforces
  test ↔ FR parity via meta self-check.
- **6 NFRs** (NFR-CI-001..006) — workflow runtime ≤ 5 min warm
  / ≤ 8 min cold, file size ≤ 250 lines, no `continue-on-error`,
  cache hit rate ≥ 95%, permissions minimal, harnesses
  unmodified by CI usage (backwards-compat invariant).
- **BDD feature file** (`features/g1-forge-ci.feature`) with 7
  scenarios mirroring AC-001..007.
- **New consolidated spec** `.forge/specs/forge-ci.md` (created
  at archive time) — distinct namespace `FR-CI-*` from the
  archetype `FR-GL-*` work, separate audiences.

Residual risk : `shellcheck` was not available locally during
implementation, so the lint job's first CI run may surface
warnings on existing scripts (`foundations.test.sh`, `verify.sh`,
etc.). Acceptable per Aegis : discovery-via-CI is the design
intent of the lint job ; if findings arise, follow-up change
`g1-shellcheck-cleanup` (or similar) addresses them.

### Added — `b1-delivery` (2026-04-29)

Final B.1 brick — runtime delivery surface (CI + deployment +
observability). Templates live under
`.forge/templates/archetypes/full-stack-monorepo/`, inert until a
project is scaffolded. Zero scaffolder code change ;
`scaffold-plan.yaml` gains 18 entries and removes 3 obsolete
`.gitkeep` placeholders.

- **4 reference GitHub Actions workflows** under `.github/workflows/`
  (FR-IN-002..005) :
    - `forge-backend.yml` — `dorny/paths-filter@v3` on `backend/**`
      OR `shared/protos/**` ; `cargo fmt → clippy -D warnings →
      test → verify.sh → constitution-linter.sh`. Two-job split
      (filter + build gated on output) for clean PASS-with-skip
      semantics on out-of-scope PRs ; `actions/cache@v4` keyed on
      `Cargo.lock` per ADR-011.
    - `forge-frontend.yml` — same shape on `frontend/**` ; Flutter
      SDK pinned via `.flutter-version` consumed by
      `subosito/flutter-action@v2` ; `pub get → dart format
      --set-exit-if-changed → flutter analyze --fatal-infos
      --fatal-warnings → flutter test --coverage → Forge gates`.
    - `forge-infra.yml` — `dorny/paths-filter@v3` on `infra/**` ;
      `kustomize build × 3 overlays → kubeconform --summary
      --strict × 3 → Forge gates`. `imranismail/setup-kustomize@v2`
      pinned to 5.4.2, kubeconform 0.6.7 from upstream tarball
      (ADR-008).
    - `forge-integration.yml` — triggers ONLY on `push: main` +
      nightly cron `'0 3 * * *'` UTC + `workflow_dispatch` (NFR-014
      protection). `docker compose up -d --wait` (ADR-012) → cargo
      integration tests → Patrol Android E2E on
      `reactivecircus/android-emulator-runner@v2` API 34 →
      `if: always()` teardown.

- **Kustomize base + 3 overlays** under `infra/k8s/` (FR-IN-006) :
    - `base/` — Deployment (gRPC :50051 + HTTP :8080, /healthz +
      /readyz probes, OTLP env from optional ConfigMap, resource
      requests/limits) + Service (ClusterIP, named ports) +
      ServiceAccount (`automountServiceAccountToken: false`) +
      Ingress (host placeholder).
    - `overlays/dev` — namespace `<project>-dev`, image
      `dev-latest`, replicas: 1, ConfigMapGenerator with
      `OTEL_EXPORTER_OTLP_ENDPOINT` + `APP_ENV=dev`,
      commonAnnotations `forge.io/managed-by`, `forge.io/overlay`,
      `forge.io/project`.
    - `overlays/staging` — namespace `<project>-staging`, image
      `sha-replace-at-deploy`, replicas: 2.
    - `overlays/prod` — namespace `<project>-prod`, image
      `v0.0.0-replace-at-release`, replicas: 3 baseline +
      `HorizontalPodAutoscaler` (autoscaling/v2, min=3, max=10,
      CPU averageUtilization 70%).

- **Local OTel + SigNoz observability stack** in
  `docker-compose.dev.yml.tmpl` (FR-IN-007 + FR-IN-008) — 4 new
  services on the existing `fsm-dev` network with the existing
  `fsm-` prefix convention :
    - `fsm-otel-collector` —
      `otel/opentelemetry-collector-contrib:0.96.0`. OTLP gRPC
      :4317 + OTLP HTTP :4318 + health :13133. Config in
      `infra/observability/otel-collector-config.yaml` declares
      `memory_limiter` (256 MiB cap) → `batch` processors and
      `traces / metrics / logs` pipelines (Article IX three
      signals).
    - `fsm-signoz-clickhouse` —
      `clickhouse/clickhouse-server:24.1.2-alpine`. Internal-only.
      Named volume `signoz-clickhouse-data` for persistence.
    - `fsm-signoz-query` — `signoz/query-service:0.55.1`.
      Internal-only. Auth disabled in dev (with explicit
      MUST-flip-on comment for staging/prod).
    - `fsm-signoz-frontend` — `signoz/frontend:0.55.1`. Only
      observability service host-exposing a port (3301).
      `depends_on` chain : `query → clickhouse: service_healthy`,
      `frontend → query: service_healthy`. `restart:
      unless-stopped` on every SigNoz service.

- **App-side OTLP defaults** (FR-IN-009) — `backend/.env.dev` and
  `frontend/.env.dev` ship 7 `OTEL_*` env vars. Backend uses
  gRPC :4317 ; frontend uses HTTP/protobuf :4318 (Dart SDK
  constraint documented inline). Both files header-flagged "no
  secrets — use `.env.local`" (gitignored by scaffolder).

- **`task observe`** target in `Taskfile.yml.tmpl` (FR-IN-008) —
  opens `http://localhost:3301` in the default browser via `open`
  (macOS) or `xdg-open` (Linux), echo fallback otherwise.

- **3 new infra standards** (FR-IN-010..012) :
    - `standards/infra/ci-workflows.md` (~180 lines) — 7 canonical
      H2 sections (paths filter, gate ordering, integration scope,
      concurrency, caching, tool pinning, failure semantics) +
      tables + extension budget (max 2 extra steps before Forge
      gates).
    - `standards/infra/k8s-overlays.md` (~150 lines) — 6 canonical
      H2 sections, per-overlay diff table, image tag policy table,
      resource budget table, secret management Allowed/Forbidden,
      promotion-gating mapping (Forge change status → eligible
      environments).
    - `standards/infra/observability-local.md` (~150 lines) — 5
      canonical H2 sections, version table as single source of
      truth for the 4 pinned images, 5-step migration runbook to
      production-grade observability (managed collector → tail
      sampling → auth flip → retention → alerts).
    - `.forge/standards/index.yml` extended with 3 entries
      (scope: infra, priority: high).

- **Schema promotion** (FR-GL-001 MODIFIED + FR-GL-024) —
  `.forge/schemas/full-stack-monorepo/schema.yaml` flips
  `stage: candidate / version: "1.0.0-rc.1"` →
  `stage: stable / version: "1.0.0"` and gains
  `promoted_from: "1.0.0-rc.1"`, `promoted_in: b1-delivery`,
  `promoted_on: "2026-04-29"`. Spec `Schema evolution` table
  records the event.

- **`delivery.test.sh` harness** (FR-GL-025) — 24 tests across L1
  structural / L2 fixture / L3 long-mode levels, sharing
  `_helpers.sh` with the prior 3 harnesses (ADR-010). Manifest
  comment block declares every `test_*` ;
  `test_manifest_self_consistency` is the meta self-check.
  `test_schema_header_post_archive` is gated on
  `.forge.yaml status: archived` per ADR-009 (SKIPS during
  implementation, PASSES post-archive).

- **6 NFRs** (NFR-013..018) — per-layer workflow runtime budgets
  (≤8min warm / ≤15min cold), integration ≤30min, observability
  stack startup ≤90s, workflow file ≤250 lines, overlay diff
  ≤4KB, image pinning audit trail (no `:latest` anywhere,
  enforced by `test_no_latest_tag_anywhere`).

- **BDD feature file** at `.forge/changes/b1-delivery/features/`
  with 5 scenarios mirroring AC-001/002/006/007/008.

### Added — `b1-workflow` (2026-04-23)

Multi-layer change workflow + cross-layer orchestration. Adds the
ability for a single change to span backend + frontend + infra
with per-layer designs and tasks, coordinated by a new agent.

- **Janus agent** (`.claude/agents/cross-layer-orchestrator.md`,
  FR-GL-015) — Roman mythology persona for the cross-layer
  orchestrator. Pure orchestrator (NEVER writes application code,
  ADR-001) ; dispatches Hera (frontend), Vulcan (backend), Atlas
  (infra), Hermes-API (protos contracts) ; aggregates outputs ;
  enforces cross-layer contract alignment ; surfaces conflicts as
  `[NEEDS CLARIFICATION]` rather than silently resolving them.
  12-step workflow.

- **Multi-layer change metadata** (FR-GL-016) —
  `.forge/templates/change.yaml` gains 3 optional top-level fields :
  `layers:` (subset of archetype schema's `layers[].id`),
  `designs_per_layer:` (map layer-id → filename),
  `tasks_per_layer:` (same shape). Required when `layers:` has ≥ 2
  entries ; backwards-compatible when single-layer or absent.

- **Validator multi-layer check** (FR-GL-017) —
  `validate-foundations.sh` gains `check_multi_layer_change_metadata`
  inspecting every `.forge/changes/*/.forge.yaml`. Validates layer
  ids against schema, requires per-layer files when multi-layer,
  rejects unknown layer ids. Skips cleanly on non-monorepo
  projects.

- **Standard `global/multi-layer-workflow.md`** (FR-GL-018) — 6
  canonical H2 sections covering routing policy (single-layer vs
  multi-layer), per-layer deliverable conventions, cross-layer
  contract alignment rules, Hermes-API delegation (ADR-003).

- **Multi-root `verify.sh` and `constitution-linter.sh`**
  (FR-BE-002, FR-FE-002, FR-GL-021, FR-GL-022) — when the target
  declares the `full-stack-monorepo` schema, the scripts walk
  `frontend/`, `backend/`, `shared/protos/`, `infra/` separately
  and prefix every output line with `[backend]`, `[frontend]`,
  `[protos]`, `[infra]`. Layer paths read dynamically from the
  schema's `layers[].path` (ADR-004), preserving single-root mode
  on non-monorepo projects (NFR-010 backwards compatibility).

- **Per-layer templates** (FR-GL-020) —
  `.forge/templates/{design,tasks}-per-layer.md` with cross-layer
  references first, layer-prefixed phase numbering (ADR-010).

- **Index extension** — `global/multi-layer-workflow` added to
  `.forge/standards/index.yml` (scope: monorepo, priority: high).

- **`workflow.test.sh` harness** (FR-GL-023) — 16 tests across L1
  structural + L2 fixture-based + L3 multi-root E2E levels.

- **Spec change** : MODIFIED FR-GL-008 — validator gains the
  Section 7 dispatch for multi-layer checks. 11 ADDED FRs, 4
  ADDED NFRs (NFR-009..012).

### Added — `b1-scaffolder` (2026-04-22)

- `.forge/templates/archetypes/full-stack-monorepo/` — complete
  archetype template tree : root (CLAUDE.md, Taskfile.yml,
  docker-compose.dev.yml, .env.example, .gitignore, .forge.yaml,
  README.md), nested `CLAUDE.md` per layer (Flutter/Rust/infra scope
  declarations), backend workspace (Cargo.toml + rust-toolchain),
  proto seed (buf.yaml + buf.gen.yaml + example.proto), infra stubs
  (kong.yml.example + distroless Dockerfile.backend.example),
  `.gitkeep` markers — 25 templates, ~1400 lines.
- `.forge/templates/archetypes/full-stack-monorepo/scaffold-plan.yaml`
  — single source of truth consumed by the overlay renderer and the
  init orchestrator. Declares the 7 official scaffolder invocations,
  the 24 template entries (source → target, substitute yes/no), and
  2 post-steps (write manifest, run validator).
- `.forge/scripts/scaffolder/overlay.sh` — template overlay renderer.
  Python 3 + PyYAML. Regex-validates `<project-name>` and
  `<reverse-domain>` before any interpolation. Writes
  `.forge/scaffold-manifest.yaml` with SHA of plan + SHA of template
  set + scaffold date (honors `SOURCE_DATE_EPOCH` for reproducible
  builds).
- `.forge/scripts/scaffolder/init.sh` — end-to-end orchestrator. 7
  non-negotiable steps : validate args + tool versions (flutter ≥ 3.24,
  cargo ≥ 1.80, buf ≥ 1.30), copy framework assets, `flutter create
  frontend`, overlay templates, `cargo new` for 5 crates (auto-joining
  the pre-written workspace manifest), `buf lint` (WARN), run
  `validate-foundations.sh`. Exit 7 with tree preserved if the
  scaffolded target fails the contract.
- `.forge/scripts/tests/scaffolder.test.sh` — three-level test harness.
  L1 = plan shape (7 scenarios, hermetic). L2 = overlay rendering with
  substitution/force/idempotence/manifest/regex checks (7 scenarios,
  hermetic). L3 = E2E (7 scenarios, requires flutter + cargo + buf on
  PATH — auto-skipped otherwise unless `--require-external-tools`).
- `.forge/scripts/tests/_helpers.sh` — shared helpers
  (`assert_eq`/`assert_contains`/`run_test`/`print_summary`/`mk_tmpdir_with_trap`)
  sourced by both foundations and scaffolder harnesses. Eliminates
  duplication.
- `.forge/changes/b1-scaffolder/features/b1-scaffolder.feature` —
  9 Gherkin scenarios (7 AC + NFR-005 idempotence + NFR-006 perf).

### Changed

- `.forge/schemas/full-stack-monorepo/schema.yaml` — promoted from
  `draft / 0.1.0` to **`candidate / 1.0.0-rc.1`**. Promotion trigger
  per `b1-foundations` ADR-004 : successful end-to-end scaffold via
  b1-scaffolder (21/21 tests + manual smoke). Further promotion to
  `stable / 1.0.0` requires 3 external adopters publicly scaffolded
  (audit C.1).
- `.claude/commands/forge/init.md` — new `## Archetype Branch`
  section documenting `--archetype full-stack-monorepo` usage,
  prerequisites, the 7-step sequence, flags, exit codes, and testing
  matrix.
- `.forge/scripts/verify.sh` — new conditional section
  `## 6. Scaffolder (conditional)` invokes the scaffolder harness at
  `--level 2` (hermetic) when the archetype template tree exists ;
  aggregates PASS/FAIL into verify.sh totals.
- `.forge/scripts/tests/foundations.test.sh` — now sources the shared
  `_helpers.sh` (Phase 1.1 refactor of b1-scaffolder). Zero regression
  (21/21 tests still green).
- `.forge/specs/full-stack-monorepo.md` — 9 new FRs appended
  (FR-GL-009..014 + FR-BE-001 + FR-FE-001 + FR-IN-001) + 4 new NFRs
  (NFR-005..008). Archived-changes table and schema-evolution log
  updated.

### Fixed

- `.forge/scripts/tests/scaffolder.test.sh` L3 revealed that the
  scaffolded project was missing `docs/VERSIONING.md`, which caused
  FR-GL-006 to FAIL on the scaffolded-target validator. Fix : `init.sh`
  now copies the entire `docs/` directory from the source Forge repo
  into the scaffolded project. Adopters replace the content with
  project-specific docs over time.
- Rogue `.omc/state/` artifact cleaned out of the archetype template
  directory (sub-agent orchestration metadata that had leaked during
  the Phase 3 parallel write).

### Known carry-overs

- **proto-contracts.md ↔ Buf STANDARD reconciliation** — the Forge
  standard prescribes version-first directory layout (`v1/<svc>/`) ;
  Buf STANDARD lint expects service-first (`<svc>/v1/`). `buf.yaml`
  excludes `PACKAGE_DIRECTORY_MATCH` with documented justification
  pointing to a future Forge change that reconciles the two.
- **`_scaffolder_lib.sh` extraction** — still deferred after
  `b1-workflow` and `b1-delivery` archive. Per `b1-delivery`
  ADR-010, the 4 test harnesses (`foundations`, `scaffolder`,
  `workflow`, `delivery`) all source the existing shared
  `_helpers.sh` and otherwise duplicate ~50 lines of harness
  scaffolding ; pulling the duplication into a `_scaffolder_lib.sh`
  remains a future cleanup, re-evaluated if a fifth harness lands
  with material overlap.

### Performance baseline

Full scaffold of a demo project on macOS 14.5 / Flutter 3.41.7 /
Cargo 1.91.0 / Buf 1.68.3 : **~3 seconds** (NFR-006 warm budget : 30s,
hard ceiling : 60s). Validator performance unchanged : ~360 ms (NFR-002
budget : 2000 ms).

---

### Added — `b1-foundations` (2026-04-21)

First delivery of the flagship archetype `full-stack-monorepo` — the
foundation layer (contract + validator + standards). Scaffolder, workflow,
and delivery layers are tracked separately and will follow in
`b1-scaffolder`, `b1-workflow`, `b1-delivery` respectively.

Template set :

- `.forge/schemas/full-stack-monorepo/schema.yaml` — monorepo schema
  declaring the 3 canonical layers (`backend`/`frontend`/`infra`), their
  agent routing (Vulcan/Hera/Atlas), cross-layer orchestration via `Janus`
  (agent to be delivered by `b1-workflow`), FR-ID prefixes, and the
  `stage: draft → candidate → stable` bump policy. Stage `draft`,
  `version: 0.1.0`.
- `.forge/standards/global/monorepo-layout.md` — canonical directory tree,
  isolation rules between layers, nested `CLAUDE.md` pattern for JIT
  context scoping, FR-ID prefix convention (180 lines).
- `.forge/standards/global/proto-contracts.md` — Protobuf as single
  source of truth for cross-layer contracts: `shared/protos/` layout,
  versioning via namespaced `v1/`/`v2/`, blocking `buf lint` +
  `buf breaking` gates, stub generation via `tonic-build` (Rust) +
  `protoc_plugin` (Dart) (169 lines).
- `.forge/standards/infra/docker-compose.md` — local-dev orchestration
  discipline: `fsm-` service prefix, single named network `fsm-dev`,
  mandatory healthchecks, `.env.example` hygiene, ban on unsuffixed
  `docker-compose.yml` (239 lines).
- `.forge/scripts/validate-foundations.sh` — deterministic structural
  validator for the archetype contract (Python 3 + PyYAML). Exits 0/1,
  emits `PASS: FR-GL-XXX — msg` / `FAIL: FR-GL-XXX — msg` lines.
  Runs in ~360 ms on the real repo (NFR-002 budget: 2000 ms).
- `.forge/scripts/tests/foundations.test.sh` — shell test harness with
  21 scenarios (unit checks + RED/GREEN meta-tests + idempotence +
  performance).
- `.forge/specs/full-stack-monorepo.md` — archived requirements (8 FRs +
  4 NFRs) for the archetype, accumulating across future B.1 changes.
- `.forge/changes/b1-foundations/features/b1-foundations.feature` —
  10 Gherkin scenarios materialising the spec acceptance criteria
  (satisfies Article II check in `constitution-linter.sh`).

### Changed — `b1-foundations`

- `.forge/standards/global/git-workflow.md` — new section
  `## Scoped Conventional Commits (monorepo-only)` defining the closed
  scope list `{backend, frontend, infra, protos, forge, docs, ci}`,
  activated only when the root `.forge.yaml` uses
  `schema: full-stack-monorepo`. Other schemas keep free-form scopes.
  +89 lines, non-breaking.
- `docs/VERSIONING.md` — new section `## Monorepo Versioning Models`
  documenting the two supported models (release-train vs per-package
  via `release-please`), the decision matrix, and the Forge default
  recommendation (release-train for teams ≤ 15 contributors). +101 lines.
- `.forge/standards/index.yml` — three new entries for the monorepo
  standards with new scopes `monorepo`, `protos`, `infra`.
- `.forge/scripts/verify.sh` — new conditional section
  `## 5. Monorepo Foundations` that invokes `validate-foundations.sh`
  on monorepo projects and aggregates its PASS/FAIL counters; emits
  `(validate-foundations skipped — not a monorepo)` on other projects.
  `FORGE_ROOT` is now overridable via environment variable (enables
  fixture-based testing).

### Fixed — `b1-foundations`

- `.forge/standards/index.yml` line 82 — quoted `@injectable`,
  `@singleton`, `@lazySingleton` triggers. The unquoted `@` was a latent
  YAML invalidity (reserved character in flow context) that blocked any
  strict parser from reading the index.

### Documentation — `b1-foundations`

- `.forge/product/roadmap.md` — Module B.1 marked **In Progress** with
  `b1-foundations` called out as the first delivery; remaining sub-changes
  (`b1-scaffolder`, `b1-workflow`, `b1-delivery`) enumerated.

## [0.2.1] — 2026-04-21

Packaging patch: the CLI is now actually usable when installed from npm.
The previous publish shipped a three-file tarball that could not scaffold
anything. Also completes the npm-scope rename started in `8fea01e`.

### Fixed

- **`forge init` from a published tarball now scaffolds the framework.**
  `@sdd-forge/cli@0.2.0` only embedded `dist/`, `VERSION`, and `README.md`
  in its npm tarball, so `npx @sdd-forge/cli init` produced an empty-ish
  project (three files, no `.forge/`, no `.claude/`, no `bin/`). The CLI
  now bundles all scaffoldable repo assets into `cli/assets/` via a
  `prepack` hook, and `init` resolves its default `--source` to that
  directory when it exists (falling back to the repo root for local dev).

### Added

- `cli/src/domain/bundle.ts` — pure `bundlePlan` function with five unit
  tests covering the exclusion rules (`cli/` itself, dev/build/editor
  dirs, `.claude/settings.local.json`, `.forge` runtime state
  `product/`, `_memory/`, `changes/`, `specs/`).
- `cli/scripts/bundle-assets.mjs` — walker that applies `bundlePlan` and
  copies the result into `cli/assets/`. Wired as `npm run bundle`,
  `prepack`, and `prepublishOnly` so published tarballs always contain
  fresh assets.
- `cli/src/cli.ts` now exposes an internal `assetsRoot()` resolver:
  `<pkg>/assets/` when present (published mode), `<pkg>/..` otherwise
  (repo-local dev mode).
- New e2e suite `published-tarball layout (bundled assets/)` that runs
  the bundle script, invokes `forge init` without `--source`, and
  asserts that `.forge/constitution.md`, `.claude/settings.json`,
  `bin/forge-install.sh`, `.mcp.json`, `LICENSE`, and `NOTICE` are
  scaffolded, with `cli/` and `settings.local.json` confirmed absent.
- `cli/.gitignore` — ignores the generated `assets/` directory.

### Changed

- **npm package renamed from `@forge/cli` to `@sdd-forge/cli`.** The
  `@forge` scope on npm is already taken. All references updated across
  `package.json`, lockfile, READMEs, `CHANGELOG`, `SECURITY`,
  `docs/VERSIONING`, the roadmap, and the bug-report template. Users
  must `npm uninstall -g @forge/cli` (if installed) and install the new
  package: `npm i -g @sdd-forge/cli`.
- `cli/package.json` — `files` now includes `assets/`; added `bundle`,
  `prepack`, and updated `prepublishOnly` so `npm publish` always
  rebuilds and re-bundles before shipping.
- `cli/README.md` — Development section documents the new `bundle`
  step and the generated `assets/` layout.

### Packaging

- Published tarball grows from 3 files / ~5 kB to 158 files / 290 kB
  compressed (896 kB unpacked) — the first figure that actually
  contains a functional Forge install.

## [0.2.0] — 2026-04-21

T1 milestone: packaging, distribution, and governance. Forge becomes
installable via three independent channels (shell, npm, Docker) and ships
the minimum governance paperwork required for open contribution.

### Added

- `VERSION` file at the repo root, SemVer-bound to the Constitution (A6).
- `docs/VERSIONING.md` — versioning policy, Constitution coupling, release
  artifact checklist (A6).
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1, enforcement routed to
  benoit.fontaine@septeo.com (D1).
- `SECURITY.md` — supported versions, private reporting channels, SLAs,
  coordinated disclosure, safe harbour (D2).
- `CHANGELOG.md` — this file, backfilled with T0 (D3).
- `.github/ISSUE_TEMPLATE/` — bug, feature, and spec-clarification issue
  forms plus `config.yml` pointing security reports at the private
  advisory channel (D4).
- `.github/pull_request_template.md` — Constitution / TDD / Context7
  compliance checklist (D4).
- `bin/forge-install.sh` — idempotent installer that copies `.forge/`,
  `.claude/`, `.mcp.json`, `CLAUDE.md`, `VERSION` into a target project
  and scaffolds `.forge/product/*` from `.forge/templates/product/*`.
  Implements A3.0 — the source repo's own `.forge/product/` content is
  never copied. Never copies `.claude/settings.local.json` (A3).
- `Dockerfile.linter` — multi-stage Alpine image bundling `verify.sh` and
  `constitution-linter.sh` for CI (`forge/linter:latest`). Satisfies
  Article VIII.3 (multi-stage with minimal runtime). Entry point
  `bin/forge-lint` aggregates both scripts' exit codes (A5).
- `bin/forge-lint` — thin wrapper that runs both deterministic scripts and
  aggregates their exit codes. Usable locally and from the Docker image.
- `.forge/templates/product/tech-stack.md` — missing template added so the
  installer can scaffold all three product artifacts (gap revealed by the
  A3 smoke test).
- `cli/` — TypeScript CLI package `@sdd-forge/cli` with `init`, `verify`,
  and `version` commands. Node ≥ 20, strict TypeScript, commander parser,
  24 Vitest tests (domain + integration + e2e). Built via
  `npm run build`; binary installed as `forge` (A4).

### Changed

- `README.md` — quickstart replaced the single `cp -r forge/` recipe with
  three install channels (shell, npm, Docker). License footer updated to
  Apache-2.0 (was still claiming proprietary). Added governance links.

### Fixed

- Installer smoke-test revealed that `.forge/templates/product/` was
  missing `tech-stack.md` despite `.forge/product/tech-stack.md` existing
  in the source. The template is now in place so scaffolded projects get
  all three product documents.

## [0.1.0-t0] — 2026-04-18

T0 milestone: Forge moves from a private reference implementation to an
openly-licensed framework and begins dog-fooding itself.

### Added

- `LICENSE` — Apache License 2.0, replacing the prior "all rights reserved"
  proprietary text.
- `NOTICE` — attribution to upstream sources (BMAD Method, GitHub SpecKit,
  OpenSpec, Agent OS v3, Superpowers, oh-my-claudecode, Context7).
- `.forge/product/mission.md` — real mission, replacing the empty
  HTML-comment template.
- `.forge/product/roadmap.md` — public roadmap aligned with the T0–T4+
  modules of the audit.
- `.forge/templates/product/{mission,roadmap}.md` — the original empty
  templates, preserved so `/forge:init` and the installer can scaffold a
  fresh product file for each target project without leaking Forge's own
  product content (A3.0).

### Changed

- `.claude/settings.json` — removed the project-level
  `defaultMode: plan` override (it was a user preference, not a framework
  rule). Fulfils audit item F7.

## [0.0.0] — 2026-04-09

Initial framework drop. Constitution v1.0.0 ratified, 19 commands, 28
agents, 39 standards, 5 schemas, 4 templates, 3 skills, 2 deterministic
scripts. Private license at the time.

[Unreleased]: https://github.com/b-fontaine/forge/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/b-fontaine/forge/compare/v0.1.0-t0...v0.2.0
[0.1.0-t0]: https://github.com/b-fontaine/forge/releases/tag/v0.1.0-t0
[0.0.0]: https://github.com/b-fontaine/forge/releases/tag/v0.0.0
