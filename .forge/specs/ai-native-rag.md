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
