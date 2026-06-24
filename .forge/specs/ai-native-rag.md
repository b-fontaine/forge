# Spec: ai-native-rag

<!-- Audit: B.7.1 (b7-1-schema) — ai-native-rag/1.0.0 archetype scaffold schema. -->
<!-- This file accumulates the archived requirements for the ai-native-rag      -->
<!-- archetype (plan §6.2, T7). Source change: `.forge/changes/b7-1-schema/`     -->
<!-- (archived 2026-06-11). First brick of the B.7 chain; B.7.2 (scaffolder),    -->
<!-- B.7.3 (standards), b7-pythia, etc. APPEND to this file as they archive.     -->

**Namespace** : `FR-B7-1-*` / `NFR-B7-1-*` / `ADR-B7-1-*`.

**Constitution** : v2.0.0 (no bump — additive; consumes §VIII.1 Envoy + §VIII.2
Temporal as-is, materialises Article XI AI-First + IX.6 into the archetype process).

**Position** : T7, first of the B.7 incremental chain
(`.forge/_memory/b7-ai-native-rag-exploration.md`, ratified 2026-06-11). Ships the
archetype scaffold schema only — no templates, no standards, no scaffolder, no
version pins. The archetype is `stage: candidate` / `scaffoldable: false`:
`forge init --archetype ai-native-rag` refuses cleanly (exit 2 — unknown
archetype, dispatch-table-gated; B.7.2 registers it + flips the gate to exit 3).

---

## ADDED Requirements (b7-1-schema, archived 2026-06-11)

Deliverable (built at impl): `.forge/schemas/ai-native-rag/1.0.0.yaml`, gated on
landing by `validate-foundations.sh::check_versioned_schema_siblings` (b8-3b) and
the dedicated harness `.forge/scripts/tests/b7-1.test.sh` (18 L1 + 1 L2, in
`forge-ci.yml`).

### Functional

- **FR-B7-1-001** — archetype scaffold-schema shape (parity with
  `full-stack-monorepo/2.0.0.yaml`): name/version/stage/scaffoldable/description/
  tdd_enforced/bdd_required_for_user_facing/coverage_threshold/layers/
  fr_id_prefix_cross_layer/cross_layer/phases. Not a bare workflow schema.
- **FR-B7-1-002** — identity: `name: ai-native-rag`, `version: "1.0.0"`,
  `stage: candidate`; file at the versioned path so the b8-3b filename↔version
  invariant holds.
- **FR-B7-1-003** — `scaffoldable: false` (b8-3b candidate⇒scaffoldable:false).
- **FR-B7-1-004** — `tdd_enforced: true`, `bdd_required_for_user_facing: true`,
  `coverage_threshold: 80`.
- **FR-B7-1-005** — candidate header block documenting candidate semantics, the
  promotion trigger, and additivity (tested by T-018).
- **FR-B7-1-010** — `layers` ⊇ {backend, frontend, infra}, each id/path/
  fr_id_prefix/primary_agent.
- **FR-B7-1-011** — RAG layer roles: backend = Rust (RAG pipeline + in-repo LLM
  gateway proxy + MCP servers, Vulcan); frontend = Qwik streaming UI; infra =
  pgvector/Temporal/Zitadel/observability (Atlas).
- **FR-B7-1-012** — Qwik streaming UI modelled under `frontend.surfaces` (full-stack
  2.0.0 precedent), not a new top-level layer.
- **FR-B7-1-013** — `fr_id_prefix_cross_layer: FR-GL-` + `cross_layer` routing
  ≥2-layer changes to Janus.
- **FR-B7-1-020** — `phases` authored inline (not via `extends`; no loader resolves
  it).
- **FR-B7-1-021** — inlined phases materialise the `ai-first` flow: `ai_brainstorm`
  (Oracle, gate `fallback_strategy_defined`) → proposal → specs → … → archive.
- **FR-B7-1-022** — `embeddings-pipeline` phase added (specs the
  chunking/embeddings/retrieval/re-ranking pipeline before design).
- **FR-B7-1-023** — `prompt-audit` gate added (prompt-audit logging; wires IX.6).
- **FR-B7-1-024** — `ai_specifics`: `fallback_mandatory: true` (XI.5),
  `pii_handling: explicit_consent_required` (XI.6), `token_budget_documented: true`,
  `non_determinism_testing`; `ai_fallback_required: true` top-level.
- **FR-B7-1-030** — declare the component SET by name (pgvector, llm-gateway,
  mcp-servers, rag-pipeline, temporal, zitadel, connect-rpc, qwik, observability).
- **FR-B7-1-031** — reference existing standards, no inline pins
  (pgvector→persistence.yaml, temporal→orchestration.yaml, zitadel→identity.yaml,
  connect→transport.yaml, qwik→web-frontend.yaml, observability→observability.yaml).
- **FR-B7-1-032** — LLM gateway / MCP / RAG patterns reference the deferred B.7.3
  standards (`delivered_by: B.7.3`), no inline pin, no fabricated standard filename
  (Article III.4). `rmcp` / pgvector Rust crate verify-then-pin candidates NOT
  committed here.

### Non-Functional

- **NFR-B7-1-001** — additive only; no existing schema/standard/constitution/CLI/
  template edited (CI-matrix registration excepted).
- **NFR-B7-1-002** — clean non-scaffoldable behaviour: `forge init --archetype
  ai-native-rag` refuses with no scaffold. **Today exit 2** (unknown archetype,
  `init.ts:210` dispatch-table gate, archetype unregistered); shifts to exit 3
  (`selectScaffoldableVersion` null, `init.ts:232`) once B.7.2 registers it (Q-005).
- **NFR-B7-1-003** — validators GREEN on landing: `validate-foundations.sh`
  `FR-GL-001-versioned:ai-native-rag/1.0.0.yaml` PASS; verify.sh +
  constitution-linter.sh no regression.
- **NFR-B7-1-004** — dedicated harness `b7-1.test.sh` (18 L1 + 1 L2 opt-in
  `FORGE_B7_1_LIVE` init-refusal), registered in `forge-ci.yml`.

## ADRs (ratified — maintainer 2026-06-11; independent reviewer APPROVE)

- **ADR-B7-1-001** — AI-First phases INLINED, not inherited via `extends` (no
  scaffold-schema loader resolves `extends`; `extends: ai-first` kept as
  documentary provenance). Resolves the §6.2 conflation.
- **ADR-B7-1-002** — `candidate` + `scaffoldable: false`; promotion to
  stable+scaffoldable deferred to the B.7 scaffolder-completion brick, gated on a
  green b7-6 harness (B.8.14-C2 pattern).
- **ADR-B7-1-003** — components reference-only; llm-gateway/mcp-servers/rag-patterns
  referenced as `delivered_by: B.7.3`, gap recorded, no fabrication.
- **ADR-B7-1-004** — backend/frontend/infra triple; Qwik streaming under
  `frontend.surfaces`; primary_agents Vulcan/Hera/Atlas.

## Open questions (resolved)

- **Q-001..Q-004** resolved at design (ADR-B7-1-001..004).
- **Q-005** (independent review, HIGH): `forge init` refusal is exit 2 (unknown
  archetype) today, not exit 3 — `init.ts:210` dispatch-table gate fires before the
  schema-version layer. Resolved: accept exit 2 for B.7.1; dispatch-table
  registration + the exit-3 flip belong to B.7.2. Lesson (Article III.4): the
  schema-version layer was verified in isolation; the full `init.ts` control flow
  must be traced before claiming an integration outcome.

## Downstream (this schema gates)

B.7.2 (`b7-2-scaffolder` — registers ai-native-rag in dispatch-table.yml, ships
templates + scaffold-plan, flips exit-2→exit-3 then stable+scaffoldable), B.7.3
(`b7-standards` — llm-gateway/mcp-servers/rag-patterns), `b7-pythia` (K.2),
`b7-9-janus-ai` (J.8.c), `b7-5-ai-act`, `b7-7-example`, `b7-6-harness`.

---

## ADDED Requirements (b7-2a-dispatch-register, archived 2026-06-12)

**Namespace** : `FR-B7-2A-*` / `NFR-B7-2A-*` / `ADR-B7-2A-*`. First additive slice
of B.7.2 — registers the archetype in the CLI dispatch table so `forge init
--archetype ai-native-rag` refuses with **exit 3** (registered, no scaffoldable
schema version) instead of exit 2 (unknown archetype). Resolves Q-005. Ships no
templates/scaffold-plan/standards/pins; the schema stays candidate/scaffoldable:false.

Deliverables: `.forge/scaffolding/dispatch-table.yml` (ai-native-rag entry),
`bin/forge-init-ai-native-rag.sh` (refusing wrapper, exit 3, zero writes),
`.forge/scripts/tests/b7-2a.test.sh` (3 L1 + 1 L2, in forge-ci.yml).

### Functional

- **FR-B7-2A-001** — dispatch entry present & well-formed (name/scaffolder/
  description/signals/since/status).
- **FR-B7-2A-002** — refusing wrapper exists, executable, bash, ABI-shaped; refuses
  exit 3 with `[REFUSAL ...]` stderr and zero filesystem writes.
- **FR-B7-2A-003** — CLI refusal flips exit 2 → exit 3 (verified live).
- **FR-B7-2A-004** — `b5.test.sh::test_dispatch_scaffolders_exist` stays GREEN (the
  wrapper is a real file; no b5 edit).
- **FR-B7-2A-005** — `b7-1.test.sh` L2 assertion flipped to exit 3.
- **FR-B7-2A-006** — dedicated harness `b7-2a.test.sh`, registered in forge-ci.yml.
- **FR-B7-2A-007** — CLI e2e couplings kept green (Q-003): `cli/src/cli.ts`
  `--archetype` help text names ai-native-rag + regen `init.snap.txt`;
  `archetypes-smoke.test.ts` partitions `candidate` out of the scaffold matrix and
  asserts exit-3 refusal + no scaffold. `cd cli && npm test` 87 passed / 1 skipped.

### Non-Functional

- **NFR-B7-2A-001** — additive: no templates/standards/pins; schema untouched.
  Existing-file edits confined to dispatch-table (append), b7-1 L2 flip, CI matrix,
  and the tested CLI couplings (cli.ts help + snapshot, archetypes-smoke partition).
- **NFR-B7-2A-002** — runtime flip requires the schema + entry bundled into
  `cli/assets` (`npm run bundle`).
- **NFR-B7-2A-003** — verify.sh / constitution-linter.sh / b5 / full harness suite
  no regression.

### ADRs (ratified — maintainer 2026-06-12; independent reviewer APPROVE)

- **ADR-B7-2A-001** — refusing wrapper, not a `<pending>` sentinel + b5 edit.
- **ADR-B7-2A-002** — refusal exit code 3 (CLI guard + wrapper, consistent).
- **ADR-B7-2A-003** — wrapper: structured `[REFUSAL ...]` stderr, exit 3, zero writes.
- **ADR-B7-2A-004** — `since: "0.5.0"` (VERSIONING.md — new archetype ⇒ MINOR).
- **ADR-B7-2A-005** — documentary `status: candidate`; no b5.test.sh change.

### Open questions (resolved)

- **Q-001** (`since:` value) → 0.5.0 (ADR-B7-2A-004). **Q-002** (`status:` marker)
  → `candidate` (ADR-B7-2A-005). Both at design.
- **Q-003** (independent review, CRITICAL/HIGH): registering an active archetype
  couples to the T5.1 CLI e2e tests (`help-snapshots`, `archetypes-smoke`) that
  enumerate active dispatch-table archetypes — `cd cli && npm test` would fail in
  CI. Resolved: candidate stays discoverable in `--help` + refusal-asserted in
  smoke (partitioned out of the scaffold matrix). Lesson (Article III.4): the
  ground-truth pass must include e2e dispatch-table cross-reference tests, and the
  gate run must include `npm test`. B.7.2-full re-checks these couplings at promotion.

---

## ADDED Requirements (b7-standards, archived 2026-06-13)

**Namespace** : `FR-B7-3-*` / `NFR-B7-3-*` / `ADR-B7-3-*`. Ships the three
`global/*.md` pattern standards the schema references as `delivered_by: B.7.3` —
**pattern docs only, NO version pins** (pins ride with B.7.2-full's
`Cargo.toml.tmpl`, verify-then-pin LIVE; `transport.yaml`/b8-6 precedent).

Deliverables: `global/rag-patterns.md`, `global/llm-gateway.md`,
`global/mcp-servers.md` + `index.yml` (3 entries) + `REVIEW.md` (3 births) +
`.forge/scripts/tests/b7-3.test.sh` (7 L1, in forge-ci.yml) +
`.forge/research/b7-standards-verify-then-pin.md` (LIVE baseline).

### Functional
- **FR-B7-3-001..004** — `rag-patterns.md`: chunking/embeddings, hybrid retrieval
  (vector + BM25 + RRF), coarse→exact re-ranking (binary_quantize), pgvector HNSW
  tuning (`ef_search`/`iterative_scan`), context-window, evaluation, EU sovereignty
  (refs compliance-tiers); no pin.
- **FR-B7-3-010..014** — `llm-gateway.md`: in-repo Rust axum proxy,
  OpenAI-compatible upstream (Mistral-Scaleway/vLLM/OpenAI-fallback-T1), tier-aware
  refusal (refs I.3 + compliance-tiers + Demeter; J.8.c → b7-9), prompt audit
  (IX.6), budgets/kill switch, PII+fallback (XI.6/XI.5); no pin.
- **FR-B7-3-020..024** — `mcp-servers.md`: rmcp server pattern (stdio +
  streamable-HTTP/axum), security (least-priv/input-validation/no-exec), OAuth
  2.1+PKCE+RFC8707 → Zitadel/Envoy-OIDC, rmcp Tier-3/verify-then-pin caveat, schema
  mapping; no pin.
- **FR-B7-3-030..032** — index.yml entries + REVIEW.md births + harness
  (incl. negative-grep no-inline-pin guard T-007).

### Non-Functional
- **NFR-B7-3-001** — additive: only index.yml/REVIEW.md/CI appended; no
  schema/constitution/existing-standard edited.
- **NFR-B7-3-002** — no version pin in any standard (grep-guarded).
- **NFR-B7-3-003** — verify.sh / constitution-linter.sh / validate-standards-yaml
  / j7 no regression.

### ADRs (ratified — maintainer 2026-06-13; independent reviewer APPROVE first pass)
- **ADR-B7-3-001** — `.md` pattern docs, zero pins (transport.yaml/b8-6 precedent;
  pins ride with B.7.2-full).
- **ADR-B7-3-002** — reference existing EU machinery (compliance-tiers /
  forbidden-components I.3 / Demeter), don't duplicate; runtime Janus AI rules
  (J.8.c) → `b7-9-janus-ai`. Resolves Q-001 (pure guidance).
- **ADR-B7-3-003** — record the rmcp Tier-3 / three-conflicting-sources finding
  (README 0.16.0 / Context7 0.5.0 / LIVE 1.7.0) verbatim as the verify-then-pin
  motivating example (III.4).
- **ADR-B7-3-004** — keep `rag-patterns.md` filename + document the schema
  component↔standard mapping in headers (Q-002); no schema edit.

### Verify-then-pin baseline (research, NOT pinned here)
crates.io LIVE 2026-06-13: `rmcp 1.7.0` / `pgvector 0.4.2` / `async-openai 0.41.0`.
B.7.2-full re-verifies LIVE + pins WITH the consuming `Cargo.toml.tmpl`.

---

## ADDED Requirements (b7-2-scaffolder, archived 2026-06-21)

**Namespace** : `FR-B7-2-*` / `NFR-B7-2-*` / `ADR-B7-2-*`. Ships the **scaffolder
backbone** (B.7.2 full) the candidate schema (B.7.1) describes: the
`.forge/templates/archetypes/ai-native-rag/1.0.0/*` tree + scaffold-plan + the
verify-then-pin'd backend (LLM gateway / MCP / RAG) + the gated wrapper. The
archetype stays `candidate`/`scaffoldable:false`; the CLI keeps refusing
(exit 3). Promotion to stable + the ≥35-test promotion suite are b7-6
(ADR-B7-2-001). Independent review (ReviewerB72, 2026-06-21): **APPROVE-WITH-NITS**;
MAJOR (conformance grep) + MINOR (audit-reason fidelity) fixed pre-archive.

Deliverables: `.forge/templates/archetypes/ai-native-rag/{scaffold-plan.yaml,
1.0.0/**}` (56 `.tmpl`: backend rag/llm_gateway/mcp/bin-server + Qwik web-public +
infra + shared/protos), gated real wrapper `bin/forge-init-ai-native-rag.sh`,
`.forge/scripts/tests/b7-2.test.sh` (L1 7 + L2 3, in forge-ci.yml `--level 1`),
`.forge/research/b7-2-verify-then-pin.md`, `features/b7-2-scaffolder.feature` (4).

### Functional
- **FR-B7-2-001..003** — versioned template tree (backend/frontend.web-public/infra/
  shared.protos), `scaffold-plan.yaml` with full plan↔tree coverage, render-clean
  (no `.tmpl`/`{{placeholder}}` survive) via overlay.sh.
- **FR-B7-2-010..014** — backend: Cargo workspace (rendered `cargo check`/`test`
  GREEN, 35 unit tests); axum bin-server reusing 2.0.0 substrate by reference;
  `Embedder` trait + `MistralEmbedder`(default)/`LocalEmbedder`(fastembed, gated)
  with T3⇒Local enforced; RAG pipeline (chunking/hybrid-retrieval vector+BM25+RRF/
  coarse→exact rerank/pgvector HNSW `vector_cosine_ops`); Temporal activity-only
  worker; LLM gateway thin axum proxy (prompt-audit IX.6, budget+kill-switch,
  non-AI fallback XI.5, PII XI.6, tier-aware hooks); rmcp `#[tool_router]` +
  `search` stub + dual transport (stdio default / streamable-HTTP, auth→Zitadel).
- **FR-B7-2-020** — Qwik web-public shell (Connect-ES v2, RAG query UI + XI.5
  `fallbackUsed` indicator), non-streaming baseline (SSE/WebTransport → b7-10);
  no Flutter surface (ADR-B7-2-006).
- **FR-B7-2-030** — infra reuses B.8 substrate by reference (pgvector 0.8.2/Temporal/
  Zitadel/observability) + RAG-specific HNSW init + llm-gateway k8s wiring; no new
  component.
- **FR-B7-2-040..041** — verify-then-pin LIVE (`rmcp 1.7.0`/`pgvector 0.4.2`/
  `async-openai 0.41.1`/`fastembed 5.17.2`), pins ONLY in the rendered
  `backend/Cargo.toml.tmpl` (standards stay pin-free; b7-3 T-007 GREEN).
- **FR-B7-2-050..052** — gated real wrapper (scaffoldability gate → overlay.sh
  render; AMENDED ADR-B7-2-007: overlay.sh not init.sh); CLI + wrapper refuse
  exit 3 while candidate (zero writes); schema+templates+plan+wrapper bundled into
  `cli/assets` (`npm run bundle`), `cd cli && npm test` GREEN (ai-native-rag =
  refusing-candidate partition).
- **FR-B7-2-060** — `b7-2.test.sh` (L1: tree/plan-coverage/verify-then-pin/
  pins-only/wrapper/wrapper-refuses/**standards-conformance**; L2: render-clean/
  cargo-check/wrapper-render), registered in forge-ci.yml `--level 1`.

### Non-Functional
- **NFR-B7-2-001** — additive: schema/constitution/archetype.schema.json/B.7.3
  standards/other archetypes untouched. (Plan-doc resync is a separate maintainer
  task, committed separately.)
- **NFR-B7-2-002** — no regression: verify.sh PASS (442/0), constitution-linter
  PASS, validate-foundations PASS, b5/b7-1/b7-2a/b7-3 GREEN.
- **NFR-B7-2-003** — modules ship `#[cfg(test)]` scaffolding (TDD-ready), not bare
  stubs. **NFR-B7-2-004** — byte-stable re-render.

### ADRs (ratified — maintainer 2026-06-21; independent reviewer APPROVE-WITH-NITS)
- **ADR-B7-2-001** — promotion (stage flip) deferred to b7-6 (b8-3b invariant +
  ADR-B7-1-002, B.8.14-C2 pattern); validated by direct overlay/wrapper fixture.
- **ADR-B7-2-002** — single change (full backbone), not split b7-2b/c.
- **ADR-B7-2-003** — pins only in rendered `Cargo.toml.tmpl`; standards pin-free.
- **ADR-B7-2-004** — `Embedder` trait dual impl (Mistral default / fastembed local),
  T3 forces Local (zero egress, XI.5 fallback).
- **ADR-B7-2-005** — MCP dual transport feature-gated (`mcp-stdio` default /
  `mcp-http` streamable-HTTP + server-side-http + tower).
- **ADR-B7-2-006** — frontend = Qwik web-public only (no Flutter).
- **ADR-B7-2-007** — wrapper renders via **overlay.sh, not init.sh** (init.sh is
  flagship-hardcoded; amends FR-B7-2-050; init.sh untouched, zero flagship risk).

### Deviations recorded (verify-then-pin caught at impl, III.4)
`sqlx` pinned **0.9** (pgvector 0.4.2 requires it, not flagship's 0.8);
`async-openai` needs feature `embedding`; `fastembed`/`local-embeddings` OFF by
default (heavy ONNX); `async-openai` drifted 0.41.0→0.41.1 since the B.7.3 baseline.

### Downstream (b7-6 picks up)
Promotion candidate→stable/scaffoldable:true + ≥35-test promotion suite + snapshot
tarball; `buf generate` + `cargo fetch` wiring (Qwik `rag_pb` import + Connect
handler registration); Temporal activity contract (currently name-only markers);
re-verify all 4 pins LIVE at promotion.

---

## ADDED Requirements (b7-pythia, archived 2026-06-22)

K.2 / B.7.4 — the **Sibyl** AI/RAG specialist agent (advisory, NOT a scanner —
ADR-K2-003). Namespace `FR-K2-PYT-*` / `NFR-K2-PYT-*` / `ADR-K2-*`. Persona name
**Sibyl** ratified by the maintainer (ADR-K2-001 / Q-001 — the shipped
Product-Analyst-Pythia is left untouched). Covered by
`.forge/scripts/tests/b7-pythia.test.sh` (18 L1 + 1 L2, registered in `forge-ci.yml`).

### Functional
- **FR-K2-PYT-001..003 / 010** — persona `.claude/agents/sibyl.md` : audit comments, H1 `# Agent: AI/RAG Specialist (Sibyl)`, `## Persona`, `## Purpose` (cites K.2 + B.7.4 + the 3 b7-standards ; `ai-native-rag`-scoped).
- **FR-K2-PYT-004 / 020..027** — `## Checklists` H2 with 4 H3 (Embeddings & Retrieval ; pgvector HNSW `ef_search` tuning ; MCP server hardening ; Prompt-audit IX.6 + mandatory fallback XI.5 + PII XI.6), each citing the consumed b7-standard.
- **FR-K2-PYT-005** — `## Output: RAG Readiness Report` H2 (advisory, Demeter-shaped : Summary counts + Findings template + status line — BLOCKED only on the XI.5 gate / TUNING-NEEDED on any Concern / READY otherwise).
- **FR-K2-PYT-006 / 120..125** — `## Recommendation Catalogue` H2 with `K2-RULE-001..006` (severity Advisory / Concern / Blocking ; K2-RULE-006 = Blocking, the XI.5 mandatory-fallback gate ; ADR-J8-004 numbering invariant, never reused).
- **FR-K2-PYT-007** — `## Integration` H2 : Janus Step 3 dispatch for `ai-native-rag` ; relationships to Oracle (brainstorm vs tune), Demeter (disjoint surfaces), Vulcan/Hera (advise vs implement).
- **FR-K2-PYT-008** — `## Anti-Hallucination Protocol` H2 (Article III.4) : emit `[NEEDS CLARIFICATION:]` + STOP on an unspecified tuning target ; never fabricate `ef_search` / chunk-size / recall@k.
- **FR-K2-PYT-011** — file footer with the audit cross-references (plan §9 / §6.2 / §0.12 + ARCHITECTURE-TARGET §9.2 + the 3 b7-standards).
- **FR-K2-PYT-080 / 081** — additive `triggers:` on the `global/{rag-patterns,llm-gateway,mcp-servers}` index entries (+ `ef-search` / `embeddings-tuning`) ; NO new standard, NO new index entry (ADR-K2-005).
- **FR-K2-PYT-082 / 083** — Janus delta (ADR-K2-004, Article IV.1) : Dispatch Table row + Step 3 design-pass paragraph + Quality-Gates AI/RAG-readiness bullet + Constitution-compliance Article XI bullet — all in sections DISJOINT from `b7-9-janus-ai`.
- **FR-K2-PYT-084** — repo `CLAUDE.md` agent-delegation row routing AI/RAG tuning to Sibyl.
- **FR-K2-PYT-086** — namespace guard : no `K2-RULE` token leaks into the J8 / K3 surfaces ; no scanner script / data file.

### Non-Functional
- **NFR-K2-PYT-001** — additive only.
- **NFR-K2-PYT-002** — NO scanner / data file / new standard (ADR-K2-003 ; guarded by `_test_b7p_013` + `_test_b7p_018`).
- **NFR-K2-PYT-003** — Article V audit trail (`[Story: FR-K2-PYT-*]` task tags).
- **NFR-K2-PYT-004** — J.7 standards-yaml GREEN (the `index.yml` edit is additive).
- **NFR-K2-PYT-005** — no regression (`j7` / `j8` / `k3` / `b7-1` / `b7-2a` / `b7-2` / `b7-3` GREEN).
- **NFR-K2-PYT-006** — collision guard (Step 9 Aegis+Demeter narrative + the J8-RULE Forbidden-archetypes catalogue byte-untouched).
- **NFR-K2-PYT-007** — name-agnostic harness (single `PYTHIA_AGENT` var → `.claude/agents/sibyl.md`) + a fresh-checkout anchor-integrity L2 fixture.

### ADRs (ratified — maintainer 2026-06-22; orchestrator independent verification GREEN)
- **ADR-K2-001** — persona name **Sibyl** (Option B — name the new K.2 agent, keep Product-Analyst-Pythia ; supersedes the design's "Delphi" recommendation).
- **ADR-K2-002** — incremental `K2-RULE` growth (6 seed rules ; mirrors ADR-K3-005).
- **ADR-K2-003** — advisory agent : NO scanner / data file / new standard (Panoptes mould ; `ef_search`/embeddings tuning is workload-specific, not deterministically scannable).
- **ADR-K2-004** — Janus integration by delta-edit (Article IV.1) in sections disjoint from `b7-9-janus-ai`.
- **ADR-K2-005** — standards-index additive triggers only (Sibyl consumes the B.7.3 b7-standards ; no new standard file).

### Open questions (resolved)
- **Q-001** (name collision) → ADR-K2-001 (Sibyl). **Q-002** (rule count) → ADR-K2-002 (6, incremental). **Q-003** (scanner vs advisory) → ADR-K2-003 (advisory).

### Downstream
Janus dispatches Sibyl at Step 3 for `ai-native-rag` projects. The archetype's
promotion to `scaffoldable: true` remains gated on a green `b7-6-harness`
(unchanged by this brick).

---

## ADDED Requirements (b7-5-ai-act, archived 2026-06-22)

B.7.5 + B.7.8 — EU AI-Act + DORA regulatory artefacts for the `ai-native-rag`
archetype. Namespace `FR-B75-AA-*` (AI-Act) / `FR-B75-DO-*` (DORA) /
`FR-B75-BD-*` (bundle + standard + harness + docs) / `NFR-B75-*` / `ADR-B75-*`.
Constitution v2.0.0 — no amendment. **Anti-hallucination is LOAD-BEARING**
(NFR-B75-004) : no fabricated legal article / recital / deadline ; ungrounded
obligations carry `status: needs-clarification` + `themis_owner: K.5`. Covered by
`.forge/scripts/tests/b7-5.test.sh` (≥14 L1 + 3 L2, registered in `forge-ci.yml`).

### Functional
**Cluster 1 — AI-Act artefacts `.forge/compliance/ai-act/` (FR-B75-AA-001..030)**
- **AA-001/002** — directory presence + audit comment on every member.
- **AA-010/011** — `risk-classification.md` : grounded posture + escalation triggers ; `[NEEDS CLARIFICATION]` markers for ungrounded category mapping.
- **AA-012** — `transparency-obligations.md` : evidence linkage (prompt-audit IX.6 + Qwik `fallbackUsed`).
- **AA-020/021** — `model-card.template.md` + `dataset-card.template.md` skeletons (no legal assertion).
- **AA-025/026** — `obligations-index.yaml` obligation→evidence map + schema shape (`regulation: ai-act`).
- **AA-030** — no fabricated legal citation (enforced by FR-B75-BD-102).

**Cluster 2 — DORA artefacts `.forge/compliance/dora/` (FR-B75-DO-001..020)**
- **DO-001/002** — directory + audit comment.
- **DO-010/011** — `incident-reporting.md` : grounded obligation + NEEDS-CLARIFICATION markers (incident windows).
- **DO-015** — `roi-register.template.yaml` skeleton.
- **DO-016** — `obligations-index.yaml` (`regulation: dora`).
- **DO-020** — no fabricated legal citation.

**Cluster 3 — Bundle wiring (FR-B75-BD-001..015)**
- **BD-001** — `bundle.sh` collects `regulatory/{ai-act,dora}/*` members.
- **BD-002/003/004** — additive (existing 6 members unchanged) ; `SOURCE_DATE_EPOCH` determinism preserved ; graceful absence (no dirs → base 6, exit 0).
- **BD-010/011** — I.6 standard `compliance-artefacts-bundle.md` bundle-schema table + forward-compat note (1.0.0 → 1.1.0) ; `i6.test.sh` member-count assertion updated in lock-step.
- **BD-015** — `forge-compliance.yml` gains NO new step (ADR-B75-005).

**Cluster 4 — Standard `global/ai-act-dora-artefacts.md` (FR-B75-BD-020..031)**
- **BD-020..027** — file + H1 + anchors + frontmatter narrative + ≥6 H2 + artefact-content-schema table + two-phase governance (BDFL Phase A frozen → Themis Phase B) + Consumption protocol (cites the I.6 bundle) + ≥3 MUST NOT + RFC-2119 + Themis cross-link.
- **BD-030/031** — `index.yml` entry + `REVIEW.md` birth + the I.6-amendment REVIEW entry.

**Cluster 5 — Test harness (FR-B75-BD-100..115)**
- **BD-100/101** — `b7-5.test.sh` skeleton + ≥14 L1 coverage.
- **BD-102** — L1 anti-hallucination negative-grep (fails on `Article N` / `Art. N` / `recital` outside a NEEDS-CLARIFICATION marker).
- **BD-110** — L2 bundle-integration + `SOURCE_DATE_EPOCH` determinism (`diff -q` byte-identical) + graceful-absence.

### Non-Functional
- **NFR-B75-001** additive/backward-compatible · **002** determinism · **003** no external dependency · **004** **anti-hallucination (Article III.4) — LOAD-BEARING** (ungrounded → `needs-clarification` + `themis_owner: K.5`) · **005** I.6 release-version bump deferred to maintainer · **006** standard file-size budget · **007** CI line budget · **008** harness perf budget.

### ADRs (ratified — maintainer 2026-06-22; orchestrator independent verification GREEN, anti-hallucination CLEAN)
- **ADR-B75-001** — per-regulation `.forge/compliance/{ai-act,dora}/` layout + bundle `regulatory/` subdir (mirrors ADR-I6-CA-002 ; `nis2/` + `cra/` reserved, not created).
- **ADR-B75-002** — bundle wiring lands now ; I.6 `compliance-artefacts-bundle.md` 1.0.0 → 1.1.0 + `i6.test.sh` count assertion updated in lock-step.
- **ADR-B75-003** — new standard `global/ai-act-dora-artefacts.md` (not folded into an existing standard).
- **ADR-B75-004** — harness `b7-5.test.sh` placed after `i5.test.sh` in CI.
- **ADR-B75-005** — `forge-compliance.yml` gains NO new step (the bundle already aggregates the regulatory members).

### Open questions
- **Legal (Themis Phase B)** : `Q-001..Q-005` (AI-Act risk-category mapping + article numbers ; DORA incident windows ; finance-sector high-risk determination ; bias-evaluation obligation ; obligation-class grounding) — all `[NEEDS CLARIFICATION]`, deferred to Themis (K.5) ; **not fabricated, not blocking**. Design `Q-010..014` resolved at design.

### Downstream
Unblocks **K.5 Themis** — the frozen v1.0.0 `.forge/compliance/{ai-act,dora}/` artefacts Themis maintains on a Phase-B rolling cadence. The archetype's promotion to `scaffoldable: true` remains gated on `b7-6-harness`.

---

## ADDED Requirements (b7-10-streaming, archived 2026-06-23)

B.7.10 — streaming RAG answer surface for the `ai-native-rag` archetype: a
server-streaming RPC + streaming gateway pipeline + Qwik progressive-render UI,
layered **additively** on the b7-2 unary surface (which is retained as the
documented Article XI.5 degradation target). Namespace `FR-B7-10-*` /
`NFR-B7-10-*` / `ADR-B7-10-*`. Constitution v2.0.0 — no amendment. Covered by
`.forge/scripts/tests/b7-10.test.sh` (7 L1 + 4 L2, registered in `forge-ci.yml`
after `b7-2.test.sh`). Schema stays **candidate / scaffoldable:false** — promotion
remains gated on `b7-6-harness`.

### Functional
**Streaming proto contract (FR-B7-10-001..003)**
- **001** — `rag.proto` adds server-streaming `rpc QueryStream(QueryRequest) returns (stream QueryChunk)`; unary `Query` retained unchanged.
- **002** — `QueryChunk { string token_delta; repeated SourceChunk sources; bool done; bool fallback_used; }` reusing the b7-2 `SourceChunk` (no duplicate type).
- **003** — additive/backward-compatible: `buf lint` clean + `buf breaking` reports no breaking change vs the b7-2 baseline (asserted structurally at L1; live at L2 when `buf` present).

**Backend streaming pipeline `backend/llm_gateway/src/streaming.rs` (FR-B7-10-010..015)**
- **010** — `process_query_stream(...)` yields incremental chunks; reuses `decide_route` so kill-switch / tier-refusal / budget guards run before any upstream call; unary `process_query` retained.
- **011** — `StreamingUpstream::generate_stream(...)` trait port; `FailingUpstream` + `MidStreamFailingUpstream` test doubles exercise the XI.5 branch.
- **012** — **backpressure**: bounded `tokio::sync::mpsc` channel with named constant `STREAM_CHANNEL_CAPACITY` (no magic literal).
- **013** — **cancellation**: producer in a spawned task; `StreamHandle::cancel()` aborts via `JoinHandle::abort`; consumer-drop also cancels (closed-channel signal). Close-time audit emitted on cancel.
- **014** — **mandatory fallback (XI.5)**: pre-stream upstream failure → single fallback-marked terminal chunk (ranked sources, `fallback_used=true`, `done=true`); mid-stream failure → terminate-with-fallback-marker keeping partial tokens (ADR-B7-10-003). Both unit-tested with a failing upstream.
- **015** — **prompt-audit (IX.6)** at stream close with final token counts + `fallback_invoked` + `cancelled`; `redact_pii` (XI.6) on the prompt path.

**Frontend streaming UI `frontend/web-public` (FR-B7-10-020..023)**
- **020** — `connect-client.ts` adds `queryStream(question, topK?, signal?)` async generator over the Connect-ES v2 server-streaming client (`for await`); unary `query()` retained; transport pins owned by `transport.yaml` (not re-pinned).
- **021** — `routes/index.tsx` renders progressively (token deltas append to a `useSignal`, Article XI.4); surfaces `fallbackUsed`.
- **022** — Stop control + cancel-on-unmount via `AbortController` threaded into the Connect call (`useVisibleTask$` cleanup); no orphaned stream on navigation.
- **023** — named exponential-backoff retry helper (`DEFAULT_RETRY_POLICY` + `exponentialBackoffMs`); on exhaustion degrades to unary `query()` (UI-layer XI.5: SSE-class → unary → non-AI fallback).

**WebTransport (FR-B7-10-030)** — documented forward alternative in `README.md` + a marked non-default scaffold note; **NOT** wired (Connect-ES is fetch/HTTP, not WebTransport — ADR-B7-10-005).

**Harness (FR-B7-10-040)** — `b7-10.test.sh` L1 (proto streaming + unary-retained, backend markers, Qwik markers, WebTransport-documented, baseline-intact, no-inline-pin) + L2 (overlay render-clean, `buf lint`/`breaking`, Qwik `tsc`, `cargo check` — toolchain-gated, skip when absent); registered after `b7-2.test.sh`.

### Non-Functional
- **NFR-B7-10-001** additive (no edit to constitution / `archetype.schema.json` / the `ai-native-rag/1.0.0` schema / B.7.3 standards / `transport.yaml` / `web-frontend.yaml` / other archetypes) · **002** no regression (b7-2 L1 7 / L2 3, b7-1, b7-2a, b7-3, verify, linter all GREEN) · **003** rendered streaming modules ship `#[cfg(test)]` with the pre-stream + mid-stream fallback tested against a failing upstream · **004** determinism (byte-stable render) · **005** pin discipline — `tokio-stream = "0.1.18"` verify-then-pinned LIVE, ONLY in `backend/Cargo.toml.tmpl`.

### ADRs (ratified — maintainer 2026-06-23; orchestrator independent verification GREEN)
- **ADR-B7-10-001** — add server-streaming `QueryStream`, keep unary `Query` (the XI.5 degradation target).
- **ADR-B7-10-002** — default streaming transport = Connect server-streaming (SSE-class), not WebTransport (Context7-confirmed Connect-ES v2 `for await`).
- **ADR-B7-10-003** — mid-stream failure policy = terminate-with-fallback-marker (keep partial tokens).
- **ADR-B7-10-004** — backend streaming seam = bounded `mpsc` → `tokio_stream::wrappers::ReceiverStream`; new crate `tokio-stream` pinned LIVE only in `Cargo.toml.tmpl`; `async-stream`/`tokio-util` deliberately avoided.
- **ADR-B7-10-005** — WebTransport = documented forward alternative, not default-wired (Q-1 resolved: option a, documented-only).

### Open questions (resolved)
- **Q-1 (WebTransport depth)** — RESOLVED: option (a) documented-only forward alternative (ADR-B7-10-005). **Q-2** terminate-with-fallback-marker (ADR-B7-10-003). **Q-3** seam + `tokio-stream` resolved at IMPLEMENT (verify-then-pin LIVE, `0.1.18`). **Q-4** adding an RPC/message is non-breaking under the archetype `buf.yaml` `FILE` rules.

### Downstream
The streaming contract (`QueryStream` / `queryStream`) is **consumed by `b7-7-example`** (demo-003, RAG query UI in streaming mode). Live `buf generate` + Connect handler registration + `cargo fetch` + the ≥35-test promotion suite + the `candidate → stable` / `scaffoldable:true` flip remain in **`b7-6-harness`**.

---

## ADDED Requirements (b7-6-harness, archived 2026-06-23)

B.7.6 — **the promotion gate** (final B.7 brick): flips `ai-native-rag` `candidate → stable` / `scaffoldable:false → true` so `forge init --archetype ai-native-rag` renders the tree (was exit 3). Namespace `FR-B7-6-*` / `NFR-B7-6-*` / `ADR-B7-6-*`. Single change (no constitution amendment forces a B.8.14-style prep/flip split). Covered by `.forge/scripts/tests/b7-6.test.sh` (35 tests at L1,2) + a new `harness-rust` CI job; the flip is the suite-gated final commit.

### Functional
- **FR-B7-6-001/002/003** — `b7-6.test.sh` (≥35 tests): an **L1 end-to-end structural tier** (layer roots; proto carries BOTH unary `Query` + streaming `QueryStream`/`QueryChunk`; codegen manifest; Connect-handler seam; scaffold-plan coverage; standards conformance; pins only in `Cargo.toml.tmpl`) + an **aggregation tier** re-running the 8 sibling B.7 harnesses (b7-1/2/2a/3/5/9/10/pythia, absent ⇒ clean SKIP) as a superset gate.
- **FR-B7-6-004/005** — **L2 live-codegen tier** (SKIP-when-absent locally; RUN in the `harness-rust` CI job): render via `overlay.sh`, then `buf generate` → Rust+TS codegen → `cargo build`/`test` of the existing 4-crate workspace → Qwik `tsc` (the b7-10 `rag_pb` import now resolves). The deferred `forge-init-ai-native-rag.sh` TODOs (`buf generate`, `cargo fetch`) are realised + verified. **Connect handler = flagship parity (ADR — Option A)**: ai-native-rag ships NO `grpc-api` crate; the Connect line stays a documented adopter seam exactly as the stable flagship 2.0.0 (`ConnectRouter::new()` + `TODO(adopter)`); the gate proves the real end-to-end build (codegen + workspace build + Qwik tsc), not a compiled Connect handler.
- **FR-B7-6-010** — deterministic `SOURCE_DATE_EPOCH` snapshot `.forge/scaffold-snapshots/ai-native-rag/1.0.0.tar.gz` (913 KB, byte-stable) for `forge upgrade` BASE recovery.

### MODIFIED (the promotion — suite-gated, final commit)
- **FR-B7-6-020** — `.forge/schemas/ai-native-rag/1.0.0.yaml` `stage: candidate→stable`, `scaffoldable: false→true` (the sole source-of-truth promotion edit; satisfies `validate-foundations.sh::check_versioned_schema_siblings`).
- **FR-B7-6-021** — lockstep candidate-guard inversions (b8-14-flip break-cascade) in the SAME commit: `b7-1` T-005/006/L2, `b7-2` T-006, `b7-2a` T-003/L2, and **`b7-7`** `test_rag_archetype_still_candidate` (b7-7 was already merged; its candidate assertion is inverted to the promoted state).
- **FR-B7-6-022** — `cli/assets` regen via `npm run bundle` (gitignored, CI-fresh) so `selectScaffoldableVersion` returns 1.0.0 and the CLI stops refusing.
- **cli-trust cascade (mandatory, surfaced by the cli Vitest)** — the schema flip forces the dispatch `status: candidate→stable` flip (b7-2a T-001) + a new `cli/test/e2e/archetype-fixtures/ai-native-rag.yml` (FR-T51-055): `archetypes-smoke.test.ts` is data-driven off dispatch `status` (`scaffoldable = status != candidate`), so a scaffoldable schema with `status: candidate` breaks its exit-3 refusal assertion. ai-native-rag joins the cli-trust scaffold matrix (toolchain-gated on buf+cargo).
- **FR-B7-6-030/031** — forge-ci line budget bumped **340→380** in lock-step across the four asserting harnesses (g1, c1, t5-1, t5-otel-live-run) + `forge-ci.md` + `forge-self-ci.md`; the **6→7 job-count cascade** for the new `harness-rust` job (g1/c1 shape asserts, `forge-ci.md` FR-CI-001, `forge-self-ci.md`, summary `needs:`).

### Non-Functional
- **NFR-B7-6-001** suite GATES the flip (held-guard before, inverted by the flip) · **002** no regression (full suite + verify + constitution-linter + validate-foundations GREEN; constitution / other standards / `archetype.schema.json` / frozen full-stack 1.0.0+2.0.0 trees byte-unchanged) · **003** CI-safe (L1+aggregation in the buf-less `harness` job; live legs in `harness-rust`) · **004** determinism · **005/006** pin discipline + honest justification (the live build is verified by `harness-rust` in CI, recorded in `.forge/research/b7-6-live-codegen.md`, not faked).

### ADRs (ratified — maintainer 2026-06-23; orchestrator independent verification GREEN, live build GREEN in CI)
- **ADR-B7-6-001** single change. **002** suite = aggregate siblings + net-new e2e. **003** bundle regen = `npm run bundle` (gitignored). **004** deterministic snapshot tarball. **005** **`harness-rust` buf+cargo+node CI job** runs the live legs as a permanent gate (Q-B option b). **006** flip is the LAST task, only if green. **007** the forge-ci budget lives in 4 places + 2 docs — bump in lock-step.

### Downstream
**B.7 is complete (9/9).** `forge init --archetype ai-native-rag` renders the full RAG tree. Follow-up (tracked, not a regression): the pre-existing `b8-1` shared-tree snapshot-rebuild flake (b8-1/12/13/14/15; passes in isolation, green in CI, untouched by B.7).
