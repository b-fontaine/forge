# Proposal: b7-1-schema

<!-- Created: 2026-06-11 -->
<!-- Schema: default -->
<!-- Audit: B.7.1 (docs/new-archetypes-plan.md §6.2 — ai-native-rag/1.0.0.yaml archetype scaffold schema) -->

## Problem

T7 opens the two new archetypes (plan §6, §11). `ai-native-rag` is the AI-first
archetype — pgvector + LLM gateway (Mistral-EU / vLLM) + MCP servers + Qwik
streaming UI. Per the ratified exploration (`.forge/_memory/b7-ai-native-rag-exploration.md`,
2026-06-11) it is decomposed into a B.8-grain incremental chain; this change is
**link #1**: the archetype scaffold schema, which every downstream B.7 brick
(standards, scaffolder, Pythia, compliance, example, harness) validates against.

**Ground truth (re-read 2026-06-11, Article III.4):**

- `ai-native-rag` is **already in the taxonomy enum**:
  `.forge/schemas/archetype.schema.json:12` lists it with the description
  "AI-first archetype — pgvector 0.8 + LLM gateway (Mistral-EU / vLLM) + MCP
  servers + Qwik streaming UI." ⇒ this change does **not** touch the enum.

- **There are two distinct schema families** under `.forge/schemas/`:
  - *workflow/process schemas* (`default/`, `rapid/`, `tdd-rust/`, `tdd-flutter/`,
    `ai-first/`, `mobile-only/`) — `schema.yaml` with `extends:` + `phases`, **no
    `layers`/`components`**. They define a change's dev *process*.
  - *archetype scaffold schemas* (`full-stack-monorepo/schema.yaml` 1.0.0 +
    `full-stack-monorepo/2.0.0.yaml`) — `name`/`version`/`stage`/`scaffoldable`/
    `layers`/`components`/`phases`, **no `extends:`**. They define what
    `forge init --archetype <name>` produces.
  Plan §6.2 conflates the two ("`ai-native-rag/1.0.0.yaml` étend `ai-first` avec
  phases"). The file lives at the *scaffold* path but the plan wants the *process*
  semantics of `ai-first`. **Recorded, not normalized** (→ ADR-B7-1-001).

- **`extends:` is resolved by NO scaffold-schema loader.** `grep -rn extends
  cli/src .forge/scripts` returns only Dart-widget matches; `parseSchemaMeta`
  (`cli/src/domain/schema-version.ts:30`) line-parses only `version`/`stage`/
  `scaffoldable`; `check_versioned_schema_siblings` reads `layers`/`phases`
  **directly from the versioned file**. An `extends: ai-first` would NOT inherit
  phases — the validator would fail `phases missing or empty`. ⇒ the AI-First
  phases MUST be **inlined** (→ ADR-B7-1-001).

- **The versioned-schema validator already gates this file ON LANDING** (B.8.3.b,
  `validate-foundations.sh:397 check_versioned_schema_siblings`, generic across
  all archetype dirs). For `<archetype>/<X.Y.Z>.yaml` it enforces: `name` == dir
  name; `version` valid SemVer **and** == filename stem; `layers` non-empty list
  **including backend/frontend/infra**, each with `id`/`path`/`fr_id_prefix`/
  `primary_agent`; `stage` ∈ {draft,candidate,stable}; **`stage: candidate` ⇒
  `scaffoldable: false`**; `phases` non-empty. Unlike B.8.3's 2.0.0.yaml (which
  predated this validator and was invisible), `ai-native-rag/1.0.0.yaml` is
  validated immediately — it MUST satisfy every invariant the moment it lands.

- **No `schema.yaml` is required** for a non-flagship archetype dir: the
  existence guard `validate-foundations.sh:92` is hard-coded to
  `full-stack-monorepo/schema.yaml` only. `ai-native-rag/` may ship with just
  `1.0.0.yaml`.

- **CLI selection** (`selectScaffoldableVersion`, schema-version.ts:68): picks the
  highest `stage: stable` + `scaffoldable: true`. A dir whose only version is
  `candidate`/`scaffoldable:false` returns `null` (the B.8.3.b exit-3 refusal in
  isolation). **NB (verified live, corrected post-review):** `init.ts:210` checks
  the dispatch-table FIRST, so an archetype not registered there refuses earlier
  with **exit 2** (unknown archetype); the exit-3 path is reachable only once B.7.2
  registers `ai-native-rag` (Q-005). Correct for B.7.1 either way: there are no
  templates yet, so the archetype must NOT be scaffoldable and init refuses cleanly.

- **Component standards — partial gap.** pgvector→`persistence.yaml`,
  Temporal→`orchestration.yaml`, Zitadel→`identity.yaml`, Connect→`transport.yaml`,
  Qwik→`web-frontend.yaml`, observability→`observability.yaml` all exist. But
  **`llm-gateway`, `mcp-servers`, `rag-patterns` standards do NOT exist** — they
  are B.7.3 (`b7-standards`). Mirrors the B.8.3 Envoy-pin gap exactly. **Recorded,
  not fabricated** (→ ADR-B7-1-003).

## Solution

Author the **specification for** `.forge/schemas/ai-native-rag/1.0.0.yaml` — its
required content, the AI-First process it materialises, the component set it
references, and the candidate/non-scaffoldable rules. Like B.8.3, this change is
**propose + specify** (the schema file itself is built at the implementation
phase after design); it ships **no template, no version pin, no scaffolder, and
edits no existing schema/standard/constitution**.

The `1.0.0.yaml`, when built, MUST:

1. Use the *archetype scaffold schema* shape (parity with
   `full-stack-monorepo/{schema,2.0.0}.yaml`): `name`, `version`, `stage`,
   `scaffoldable`, `description`, `tdd_enforced`, `bdd_required_for_user_facing`,
   `coverage_threshold`, `layers`, `fr_id_prefix_cross_layer`, `cross_layer`,
   `phases`.
2. Declare `name: ai-native-rag`, `version: "1.0.0"`, `stage: candidate`,
   `scaffoldable: false`.
3. Declare the minimum `layers` triple backend/frontend/infra (validator
   contract), modelling the RAG topology — Rust backend (RAG pipeline + in-repo
   LLM gateway proxy + MCP servers), frontend (Qwik streaming UI via `surfaces:`,
   mirroring full-stack 2.0.0), infra (pgvector/Temporal/Zitadel/observability).
4. **Inline** the AI-First phases (materialised from `ai-first/schema.yaml`, NOT
   via `extends`): `ai_brainstorm` (Oracle, gate `fallback_strategy_defined`) →
   proposal → specs → features → design → tasks → implementation → review →
   archive, PLUS the two B.7.1 additions: **`embeddings-pipeline`** (specs the
   chunking/embeddings/retrieval pipeline before design) and **`prompt-audit`**
   (a gate on prompt-audit logging). Carry the ai-first `ai_specifics`
   (fallback_mandatory, pii_handling, token_budget, non_determinism_testing).
5. Declare the component SET **reference-only** (no inline pins, ADR-B8-3-002
   precedent): pgvector→`persistence.yaml`, Temporal→`orchestration.yaml`,
   Zitadel→`identity.yaml`, Connect→`transport.yaml`, Qwik→`web-frontend.yaml`,
   observability→`observability.yaml`; and **reference the deferred standards**
   for the in-repo LLM gateway, MCP servers, and RAG patterns (delivered by B.7.3)
   — recorded as a gap, never fabricated.
6. Carry a header block documenting candidate semantics: not scaffoldable while no
   templates exist; promotion to `stable` + `scaffoldable: true` happens at the
   later B.7 brick that ships + proves the scaffolder/templates (analogous to the
   B.8.14 flip), gated on the B.7 harness.

Decisions reserved for `/forge:design` (ADRs); leanings stated, genuinely
undecided points in `open-questions.md`:

- **ADR-B7-1-001 — phases: inline (materialised) vs `extends: ai-first`.** Lean:
  **inline** the ai-first phases + add `embeddings-pipeline`/`prompt-audit`,
  because no scaffold-schema loader resolves `extends` (grounded above). Keep an
  `extends: ai-first` key (or a header comment) as documentary provenance only;
  the validator-load path reads the inlined phases. Resolves the §6.2 conflation.
- **ADR-B7-1-002 — stage/scaffoldable for the first cut.** Lean: `candidate` +
  `scaffoldable: false` (validator-enforced; init refuses cleanly — exit 2 today
  via the dispatch-table gate, exit 3 once registered by B.7.2, Q-005).
  Promotion to `stable` deferred to the B.7 scaffolder-flip brick after the B.7
  harness proves a green scaffold (mirrors B.8.14). The exact promotion brick id
  is set when the B.7 chain is sequenced.
- **ADR-B7-1-003 — components reference-only + deferred-standard gap.** Lean:
  reference-only (mirror ADR-B8-3-002). LLM-gateway/MCP/rag standards do not exist
  yet → reference them as `delivered_by: B.7.3` with no inline pin; record the gap
  (Article III.4 — no fabrication).
- **ADR-B7-1-004 — layer / RAG-surface modelling.** Lean: backend/frontend/infra
  triple with the Qwik streaming surface under `frontend.surfaces` (full-stack
  2.0.0 precedent). Exact `layers[]`/`surfaces` shape + `primary_agent` for the AI
  frontend decided at design.

Release vehicle: maintainer-set (additive spec artifact; no runtime change).

## Scope In

- `proposal.md`, `specs.md`, `.forge.yaml`, `open-questions.md` for
  `b7-1-schema` (this change): requirement set + ADRs + open questions for the
  `ai-native-rag / 1.0.0` candidate scaffold schema.
- Requirements `FR-B7-1-*` / `NFR-B7-1-*` defining WHAT the schema file must
  contain and the candidate/non-scaffoldable rules.
- ADRs `ADR-B7-1-001..004` (phases-inline, stage, components, layers).

## Scope Out (Explicit Exclusions)

- **Building the `1.0.0.yaml` file itself** — implementation phase of B.7.1,
  authored AFTER design from these specs. NOT created now.
- **Templates** `templates/ai-native-rag/**` — B.7.2 (`b7-2-scaffolder`).
- **Standards** `llm-gateway.md` / `mcp-servers.md` / `rag-patterns.md` — B.7.3
  (`b7-standards`). This change references them as deferred; it bumps/creates none.
- **Scaffolder + promotion to stable/scaffoldable** — later B.7 brick.
- **Agent Pythia (K.2)** — `b7-pythia`.
- **Janus AI refusal rules / J.8.c** — `b7-9-janus-ai`.
- **Constitution amendment** — none. `ai-native-rag` consumes §VIII.1 (Envoy) +
  §VIII.2 (Temporal) as-is; it changes no invoked article.
- **Component version pins** — owned by the referenced standards; never inlined.

## Impact

- **Users affected**: B.7 archetype authors (the schema is the shared contract
  gating the rest of the B.7 chain). **Zero** effect on existing adopters: no
  current archetype is touched; `ai-native-rag` is not scaffoldable yet, so
  `forge init --archetype ai-native-rag` refuses cleanly (exit 2 today — unknown
  archetype, dispatch-table-gated) rather than emitting a broken scaffold.
- **Technical impact**: spec artifacts only in this change. The schema file is a
  new sibling validated on landing by `check_versioned_schema_siblings`.
- **Dependencies**: B.8.3.b (the generic versioned-schema validator this file
  must satisfy) + B.8.14 (the CLI selection/refusal path). Gates B.7.2, B.7.3 and
  the rest of the B.7 chain.

## Constitution Compliance

- **Article III.1/III.2 (Specs before code)**: propose+specify gate; the schema
  file is built only after design.
- **Article III.4 (Anti-Hallucination)**: every claim about the two schema
  families, `extends` non-resolution, the versioned validator contract, CLI
  selection, and the standard gaps is re-read from live files
  (`schema-version.ts`, `validate-foundations.sh`, `archetype.schema.json`,
  `ai-first/schema.yaml`, `full-stack-monorepo/2.0.0.yaml`). The §6.2 conflation
  and the missing LLM-gateway/MCP/rag standards are **recorded, not normalised**;
  the verify-then-pin candidates (`rmcp`, pgvector Rust crate) are explicitly NOT
  pinned here.
- **Article IV (Delta-based)**: purely additive — no existing schema/standard is
  edited; the file is a new sibling.
- **Article XI (AI-First Design)**: the inlined phases materialise XI.5 (mandatory
  fallback — `ai_brainstorm` gate `fallback_strategy_defined`, `ai_fallback_required`)
  and XI.6 (PII protection — `pii_handling: explicit_consent_required`); the
  `prompt-audit` phase + `token_budget` support Article IX.6 (AI feature
  observability: token counts, fallback invocations).
- **Article V (Compliance gate)**: each open question maps to a design-phase ADR
  resolved by an independent reviewer + maintainer; no work proceeds around an
  unresolved naming/phase/component question.
- **Article XII (Governance)**: no amendment here.

## Open Questions (seed)

- **Q-001** — phases inline-materialised vs `extends: ai-first` (→ ADR-B7-1-001;
  leaning inline, see `open-questions.md`).
- **Q-002** — candidate→stable/scaffoldable promotion trigger + which B.7 brick
  owns the flip (→ ADR-B7-1-002; open, resolved at design).
- **Q-003** — component reference-only + deferred-standard gap handling
  (→ ADR-B7-1-003; leaning reference-only).
- **Q-004** — layer/RAG-surface modelling + AI-frontend `primary_agent`
  (→ ADR-B7-1-004; open, resolved at design).
