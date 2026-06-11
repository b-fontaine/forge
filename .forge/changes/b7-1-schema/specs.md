# Specifications: b7-1-schema

<!-- Status: specified -->
<!-- Schema: default -->
<!-- Audit: B.7.1 (docs/new-archetypes-plan.md §6.2 — ai-native-rag/1.0.0 archetype scaffold schema) -->

**Namespace** : `FR-B7-1-*` / `NFR-B7-1-*` / `ADR-B7-1-*`.
**Constitution** : v2.0.0, unchanged. This change is **propose + specify only**.
It authors the requirements + ADRs for the `ai-native-rag / 1.0.0` **candidate**
archetype scaffold schema. It ships **no schema file, no template, no version
pin, and edits no existing schema/standard**. The file is built at the impl
phase (after design); templates + standards arrive in B.7.2 / B.7.3.
**Governing articles** : III.1/III.2 (specs before code), III.4
(Anti-Hallucination), IV (delta-based / additive), XI (AI-First Design — XI.5
fallback, XI.6 PII), IX.6 (AI feature observability), X.1 (80% coverage).

## Source Documents

| Field | Value |
|-------|-------|
| **Plan ref** | `docs/new-archetypes-plan.md` §6.2 B.7.1 (`ai-native-rag/1.0.0.yaml`, extends `ai-first` + phases `embeddings-pipeline`/`prompt-audit`, effort S), §11 (T7) |
| **Exploration** | `.forge/_memory/b7-ai-native-rag-exploration.md` (ratified 2026-06-11): B.7 first, in-repo LLM gateway, incremental chain, Pythia standalone |
| **Taxonomy enum (observed)** | `.forge/schemas/archetype.schema.json:12` already lists `ai-native-rag` — enum NOT touched by this change |
| **Two schema families (observed)** | *workflow* schemas (`ai-first/schema.yaml`: `extends: default` + phases, no layers) vs *archetype scaffold* schemas (`full-stack-monorepo/{schema,2.0.0}.yaml`: layers/components/phases, no `extends`). §6.2 conflates them (→ ADR-B7-1-001). |
| **`extends` resolution (observed gap)** | No scaffold-schema loader resolves `extends`: `grep -rn extends cli/src .forge/scripts` → only Dart-widget hits; `parseSchemaMeta` (schema-version.ts:30) reads version/stage/scaffoldable only; `check_versioned_schema_siblings` reads layers/phases from the file itself. ⇒ phases MUST be inlined. |
| **Versioned validator (observed)** | `validate-foundations.sh:397 check_versioned_schema_siblings` (B.8.3.b) — generic over all archetype dirs; enforces name==dir, version==filename+SemVer, layers ⊇ {backend,frontend,infra} (each id/path/fr_id_prefix/primary_agent), stage∈{draft,candidate,stable}, candidate⇒scaffoldable:false, phases non-empty. **Gates this file on landing.** |
| **schema.yaml requirement (observed)** | `validate-foundations.sh:92` hard-codes `full-stack-monorepo/schema.yaml` only. A non-flagship archetype dir may ship just `1.0.0.yaml`. |
| **CLI selection (observed)** | `selectScaffoldableVersion` (schema-version.ts:68) picks highest stable+scaffoldable; candidate/scaffoldable:false ⇒ null ⇒ `forge init` refuses (exit 3, the B.8.3.b refusal). |
| **Component standards (observed)** | EXIST: `persistence.yaml` (postgres-17 + pgvector-0.8), `orchestration.yaml` v1.2.0 (default_by_language.rust: temporal), `identity.yaml` (zitadel), `transport.yaml` (connect-rpc), `web-frontend.yaml` (qwik, B.8.9), `observability.yaml` v2.1.0. ABSENT: `llm-gateway` / `mcp-servers` / `rag-patterns` → B.7.3 (gap, ADR-B7-1-003). |
| **ai-first phases (observed)** | `ai-first/schema.yaml`: `ai_brainstorm`(gate fallback_strategy_defined)→proposal→specs→features→design→tasks→implementation→review→archive; `ai_specifics`{fallback_mandatory, pii_handling, token_budget_documented, non_determinism_testing}. |
| **Constitution AI articles (observed)** | XI.1 agent-native, XI.3 GenUI schema-driven, XI.4 event-driven frontend, XI.5 mandatory fallback, XI.6 PII protection; IX.6 AI feature observability (token counts, fallback invocations). |
| **Verify-then-pin candidates (NOT pinned here)** | `rmcp` (README 0.16.0 vs Context7 index 0.5.0 — confirm LIVE at B.7.2/B.7.3), pgvector Rust crate (sqlx feature). |
| **Downstream gated by this** | B.7.2 (`b7-2-scaffolder`), B.7.3 (`b7-standards`), `b7-pythia`, `b7-9-janus-ai`, `b7-5-ai-act`, `b7-7-example`, `b7-6-harness` |
| **Release target** | maintainer-set |

---

## ADDED Requirements

### Functional Requirements

#### Cluster 1 — Schema identity & shape (FR-B7-1-001 → 005)

##### FR-B7-1-001 — archetype-scaffold-schema shape (not a workflow schema)
The file, when authored, MUST use the archetype scaffold schema top-level key set
(parity with `full-stack-monorepo/2.0.0.yaml`): `name`, `version`, `stage`,
`scaffoldable`, `description`, `tdd_enforced`, `bdd_required_for_user_facing`,
`coverage_threshold`, `layers`, `fr_id_prefix_cross_layer`, `cross_layer`,
`phases`. It MUST NOT be authored as a bare workflow schema (no layers).

##### FR-B7-1-002 — identity fields + filename↔version invariant
MUST declare `name: ai-native-rag`, `version: "1.0.0"`, `stage: candidate`. The
file MUST be `.forge/schemas/ai-native-rag/1.0.0.yaml` so the b8-3b
filename↔version invariant (`X.Y.Z.yaml` ⇒ `version: "X.Y.Z"`) holds.

##### FR-B7-1-003 — non-scaffoldable candidate
MUST declare `scaffoldable: false` (b8-3b enforces candidate⇒scaffoldable:false).
Consequence (must hold, NFR-B7-1-002): `selectScaffoldableVersion` returns null ⇒
`forge init --archetype ai-native-rag` refuses (exit 3), never a broken scaffold.

##### FR-B7-1-004 — TDD/BDD/coverage flags
MUST carry `tdd_enforced: true`, `bdd_required_for_user_facing: true`,
`coverage_threshold: 80` (Articles I, II, X.1 not relaxed).

##### FR-B7-1-005 — candidate header block
MUST carry a header block stating, for THIS file: what `candidate` means while no
templates exist (not scaffoldable), the promotion trigger to `stable` +
`scaffoldable: true` (the later B.7 scaffolder-flip brick, gated on a green B.7
harness — ADR-B7-1-002), and that it is additive (no existing archetype affected).

#### Cluster 2 — Layers & RAG topology (FR-B7-1-010 → 013)

##### FR-B7-1-010 — minimum layer triple
`layers` MUST be a non-empty list including `backend`, `frontend`, `infra`, each
with `id`/`path`/`fr_id_prefix`/`primary_agent` (b8-3b validator contract).

##### FR-B7-1-011 — RAG layer roles
The layers MUST model the RAG topology: backend = Rust (RAG pipeline + in-repo LLM
gateway proxy + MCP servers; `primary_agent: Vulcan`); frontend = Qwik streaming
UI; infra = pgvector/Temporal/Zitadel/observability (`primary_agent: Atlas`).

##### FR-B7-1-012 — Qwik streaming surface
The Qwik streaming UI MUST be modelled under `frontend.surfaces` (mirroring
`full-stack-monorepo/2.0.0.yaml` `frontend.surfaces`), not as a new top-level
layer (keeps the required-triple invariant intact). Exact shape + the frontend
`primary_agent` are design-decided (ADR-B7-1-004).

##### FR-B7-1-013 — cross-layer routing parity
MUST declare `fr_id_prefix_cross_layer: FR-GL-` and a `cross_layer` block routing
≥2-layer changes to Janus (parity with the flagship schema).

#### Cluster 3 — Phases & AI-First process (FR-B7-1-020 → 024)

##### FR-B7-1-020 — phases inlined, not inherited
`phases` MUST be a non-empty list authored **inline**. The schema MUST NOT rely on
`extends: ai-first` to supply phases (no loader resolves it; the validator reads
the file's own `phases`). An `extends: ai-first` key MAY be retained as
documentary provenance only (ADR-B7-1-001).

##### FR-B7-1-021 — AI-First phases materialised
The inlined phases MUST materialise the `ai-first/schema.yaml` flow:
`ai_brainstorm` (agent Oracle, gate `fallback_strategy_defined`) → proposal →
specs → features → design → tasks → implementation → review → archive.

##### FR-B7-1-022 — `embeddings-pipeline` phase (B.7.1 addition)
MUST add an `embeddings-pipeline` phase (per §6.2) that specs the
chunking/embeddings/retrieval/re-ranking pipeline **before** design.

##### FR-B7-1-023 — `prompt-audit` phase/gate (B.7.1 addition)
MUST add a `prompt-audit` gate (per §6.2) requiring prompt-audit logging — wiring
Article IX.6 (token counts, fallback invocations traced).

##### FR-B7-1-024 — ai_specifics carried
MUST carry the ai-first `ai_specifics` block: `fallback_mandatory: true` (XI.5),
`pii_handling: explicit_consent_required` (XI.6), `token_budget_documented: true`,
`non_determinism_testing` strategy. `ai_fallback_required: true` at top level.

#### Cluster 4 — Component set (reference-only) (FR-B7-1-030 → 032)

##### FR-B7-1-030 — declare the component SET by name
MUST declare the components by name + role: pgvector (persistence), LLM gateway
(in-repo proxy, AI inference), MCP servers (tooling), Temporal (orchestration),
Zitadel (identity), Connect-RPC (transport), Qwik (web-public surface),
SigNoz/OBI/Coroot (observability).

##### FR-B7-1-031 — reference source standards, no inline pins
For each component with an existing standard the schema MUST reference it (no
inline pin, ADR-B8-3-002 precedent): pgvector→`persistence.yaml`,
Temporal→`orchestration.yaml`, Zitadel→`identity.yaml`, Connect→`transport.yaml`,
Qwik→`web-frontend.yaml`, observability→`observability.yaml`.

##### FR-B7-1-032 — deferred-standard gap recorded, not fabricated
For LLM gateway / MCP servers / RAG patterns (no standard today) the schema MUST
reference them as `delivered_by: B.7.3` with **no** inline version pin and **no**
fabricated standard filename presented as existing (Article III.4). The
verify-then-pin candidates (`rmcp`, pgvector Rust crate) MUST NOT be pinned in
this schema.

### Non-Functional Requirements

##### NFR-B7-1-001 — additive only / zero edit to existing surfaces
The change MUST NOT modify any existing schema, standard, the constitution, the
CLI, or any template. `git diff --name-only` MUST show only new files under
`.forge/changes/b7-1-schema/` (+ the schema file + its harness at impl phase).

##### NFR-B7-1-002 — clean non-scaffoldable behaviour (no broken init)
After the schema lands, `forge init --archetype ai-native-rag` MUST refuse via the
existing `selectScaffoldableVersion` null path (exit 3), never emit a partial
scaffold. No other archetype's init behaviour changes.

##### NFR-B7-1-003 — validators stay GREEN on landing
After the schema file lands (impl phase), `validate-foundations.sh`
(`check_versioned_schema_siblings`) MUST emit
`FR-GL-001-versioned:ai-native-rag/1.0.0.yaml` PASS, and `verify.sh` +
`constitution-linter.sh` MUST stay GREEN (no regression). The schema MUST satisfy
every b8-3b invariant the moment it is committed.

##### NFR-B7-1-004 — dedicated harness
The impl phase MUST add `.forge/scripts/tests/b7-1.test.sh` asserting the
AI-specific content not covered by the generic validator: the inlined AI-First
phases incl. `ai_brainstorm`/`embeddings-pipeline`/`prompt-audit`, the
`ai_specifics` block, the reference-only component set, and the deferred-standard
gap. Registered in `forge-ci.yml`. (Authored at impl; specified here.)

---

## ADRs (seeded — resolved at /forge:design by independent reviewer + maintainer)

- **ADR-B7-1-001** — phases inline-materialised (lean) vs `extends: ai-first`.
  Grounded: no scaffold-schema loader resolves `extends`. Resolves §6.2 conflation.
- **ADR-B7-1-002** — `candidate` + `scaffoldable: false` (lean); promotion to
  stable deferred to the B.7 scaffolder-flip brick (mirrors B.8.14). Which brick
  owns the flip = open.
- **ADR-B7-1-003** — components reference-only (lean); LLM-gateway/MCP/rag
  standards referenced as `delivered_by: B.7.3`, gap recorded, no fabrication.
- **ADR-B7-1-004** — layer/RAG-surface modelling + AI-frontend `primary_agent` =
  design-decided (Qwik surface under `frontend.surfaces`, full-stack 2.0.0
  precedent).

## Acceptance Criteria (for the impl phase, summarised)

1. `.forge/schemas/ai-native-rag/1.0.0.yaml` exists; `name`/`version`/`stage`/
   `scaffoldable` = ai-native-rag/1.0.0/candidate/false.
2. `validate-foundations.sh` → `FR-GL-001-versioned:ai-native-rag/1.0.0.yaml` PASS.
3. `forge init --archetype ai-native-rag` → exit 3 (refused, not scaffoldable).
4. `layers` ⊇ {backend,frontend,infra}; Qwik surface under `frontend.surfaces`.
5. Inlined phases include `ai_brainstorm` + `embeddings-pipeline` + `prompt-audit`;
   `ai_specifics` present.
6. Components reference-only; no inline pin; LLM-gateway/MCP/rag marked
   `delivered_by: B.7.3`.
7. `b7-1.test.sh` GREEN; `verify.sh` + `constitution-linter.sh` no regression.
8. No existing schema/standard/constitution/CLI/template modified.
