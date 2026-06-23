# Specs: b7-7-example

<!-- Audit: B.7.7 (docs/new-archetypes-plan.md §0.12 T7 brick #8).            -->
<!-- Depends on: b7-1-schema + b7-2a-dispatch-register + b7-standards +        -->
<!--             b7-2-scaffolder + c1-reference-project (all archived).        -->
<!-- Format: new FR-RAGEX-* namespace for the RAG example tree, consolidated   -->
<!--         into .forge/specs/example-reference.md at archive time (alongside -->
<!--         the FR-EX-* namespace from c1). No archetype/schema/standard edit. -->

This change ships the **second reference project tree** under
`examples/` — `forge-rag-example/` — demonstrating the `ai-native-rag`
archetype, in a single archive cycle:

1. The fully-rendered `examples/forge-rag-example/` tree (rendered via
   `overlay.sh` against the `ai-native-rag/1.0.0` scaffold-plan, then
   committed verbatim).
2. Three archived demo application changes
   (`demo-001-doc-ingestion`, `demo-002-mcp-search-tool`,
   `demo-003-rag-query-ui`).
3. A top-of-tree navigation `README.md` for the RAG example + one
   appended row in the meta-`examples/README.md`.
4. An extension of the existing `example` job in `forge-ci.yml`
   (FR-CI-012) so it also gates `examples/forge-rag-example/`.
5. A test harness `b7-7.test.sh` validating the RAG example structure.

## Namespace

- `FR-RAGEX-001..010` — RAG example tree contract (new namespace,
  mirrors c1's `FR-EX-*` but scoped to `forge-rag-example/`).
- `NFR-RAGEX-001..005` — RAG example non-functional budgets.
- `ADR-B7-7-001..004` — design decisions (in `design.md`).

The `FR-RAGEX-*` namespace is **new** (distinct from c1's `FR-EX-*`,
which is generic example-tree machinery). Both consolidate into
`.forge/specs/example-reference.md` at archive time: the FR-EX-* section
governs the shared machinery (skip-guards, gitignore, the `example`
job's existence); the FR-RAGEX-* section governs the RAG tree's content.

## Format note

This document follows the **delta convention** of Article IV. The
target specs are:

- `.forge/specs/example-reference.md` (extended with the new
  `FR-RAGEX-*` + `NFR-RAGEX-*` namespace + a new Archived-changes row
  for `b7-7-example`).
- `.forge/specs/forge-ci.md` (MODIFIED `FR-CI-012` — the `example` job
  now gates **two** trees, not one).

No edit to `.forge/specs/ai-native-rag.md` (the archetype contract),
`.forge/schemas/ai-native-rag/1.0.0.yaml`, the `global/*.md` standards,
or any CLI code — the example **uses** the archetype, it does not
redefine it (NFR-RAGEX-001).

---

## ADDED Requirements

### FR-RAGEX-001: RAG example tree exists at canonical path

<!-- New in b7-7-example (2026-06-22) -->

- **MUST** — directory `examples/forge-rag-example/` exists at the Forge
  repo root and is a fully-rendered `ai-native-rag/1.0.0` project,
  produced by rendering the `b7-2-scaffolder` scaffold-plan via
  `overlay.sh` (the renderer of record for this archetype per
  ADR-B7-2-007), then committed verbatim.
- **MUST** — the tree contains the archetype's canonical structure:
  `backend/` (Rust workspace with `rag/`, `mcp/`, `llm_gateway/`,
  `bin-server/`), `frontend/web-public/` (Qwik), `infra/` (k8s +
  pgvector init + observability), `shared/protos/v1/rag/` (the seed
  `rag.proto` with `RagService.Query`).
- **MUST** — the tree contains its own `.forge/`, `.claude/`,
  `Taskfile.yml`, `docker-compose.dev.yml`, `.gitignore`, root
  `CLAUDE.md`, `README.md`, and `.forge.yaml` declaring
  `schema: ai-native-rag`.
- **MUST** — `.forge/scaffold-manifest.yaml` is committed and records
  `archetype: ai-native-rag`, `archetype_version: "1.0.0"`,
  `stage: candidate`, `scaffold_plan_sha`, `template_set_sha`,
  `scaffold_date`, `project_name: forge-rag-example`,
  plus the verify-then-pin'd tool/crate versions where the manifest
  records them.

**Constitution reference:** Articles III.2, V, VII, XI.
**Testable:** yes — `test_rag_example_tree_canonical_structure`
+ `test_rag_example_scaffold_manifest_complete` in
`.forge/scripts/tests/b7-7.test.sh`.

### FR-RAGEX-002: Top-of-tree navigation README

<!-- New in b7-7-example (2026-06-22) -->

- **MUST** — `examples/forge-rag-example/README.md` exists and contains
  the four canonical H2 sections (same contract as FR-EX-002):
  `## How this example was built`, `## What's in here`,
  `## Demo changes`, `## Reproducing this example`.
- **MUST** — `## How this example was built` documents that the tree
  was rendered via `overlay.sh` against the `ai-native-rag/1.0.0`
  scaffold-plan (NOT via `forge init`, which refuses while the archetype
  is `candidate`), so an adopter can reproduce it.
- **MUST** — `## Demo changes` enumerates the 3 demos, each with a
  one-sentence summary and a relative link to its change directory.
- **MUST** — a `## What this example does NOT show` note (or equivalent)
  records the known gaps: candidate/non-scaffoldable status, no Flutter
  surface (ADR-B7-2-006), no AI-Act/DORA compliance demo (→ b7-5-ai-act),
  no Pythia agent demo (→ b7-pythia). (demo-003 DOES show the streaming
  UI via b7-10's `QueryStream`/`queryStream`.)
- **SHALL** — `## What's in here` provides a callout per layer
  (backend `rag`/`mcp`/`llm_gateway`, frontend Qwik, infra) with a
  pointer to the governing standard (`rag-patterns.md`,
  `mcp-servers.md`, `llm-gateway.md`).

**Constitution reference:** Articles X.3, III.2.
**Testable:** yes — `test_rag_example_readme_has_required_sections`.

### FR-RAGEX-003: Meta-`examples/README.md` lists the RAG example

<!-- New in b7-7-example (2026-06-22) -->

- **MUST** — `examples/README.md` (which already exists from c1,
  FR-EX-003) gains a second row in its "Available examples" table:
  `forge-rag-example` | `ai-native-rag` | last-updated date | short
  description.
- **MUST** — b7-7 does NOT re-create `examples/README.md`; it appends
  one table row (the file was designed for multiple examples).

**Constitution reference:** Article X.3. **Testable:** yes —
`test_examples_meta_readme_lists_rag_example`.

### FR-RAGEX-004: Three archived demo application changes

<!-- New in b7-7-example (2026-06-22) -->

- **MUST** — under `examples/forge-rag-example/.forge/changes/`, three
  demo changes exist with `status: archived`: `demo-001-doc-ingestion`,
  `demo-002-mcp-search-tool`, `demo-003-rag-query-ui`.
- **MUST** — each archived demo's `.forge.yaml` declares
  `status: archived`, a complete `timeline:` block (every phase
  populated), and `parent_audit_items: [B.7.7]`.
- **MUST** — each archived demo contains the canonical 5 artefacts:
  `proposal.md`, `specs.md` (delta format), `design.md` (single-layer)
  or per-layer `designs/design-<layer>.md` (multi-layer per FR-GL-016),
  `tasks.md` (single-layer) or per-layer `tasks/tasks-<layer>.md`
  (multi-layer), and a `features/<demo>.feature` with realistic Gherkin.
- **MUST** — `demo-001-doc-ingestion` is **single-layer backend**
  (`layers: [backend]`) — document ingestion + RAG query exercising the
  `rag/` pipeline (chunking, the `Embedder` trait, pgvector HNSW upsert,
  hybrid retrieval vector+BM25+RRF, re-ranking) with cucumber-rs BDD.
- **MUST** — `demo-002-mcp-search-tool` is **single-layer backend**
  (`layers: [backend]`) — the rmcp `search` tool exposing the retriever,
  dual transport (stdio + streamable-HTTP), schema-validated input.
- **MUST** — `demo-003-rag-query-ui` is **multi-layer backend +
  frontend** (`layers: [backend, frontend]`) — triggers the Janus
  orchestrator (≥ 2 layers per FR-GL-015), ships per-layer
  `designs/` and `tasks/` per FR-GL-016; the Qwik UI consumes
  `b7-10-streaming`'s **`RagService.QueryStream`** server-stream through
  the LLM gateway and **progressively renders answer tokens** via the
  `queryStream` client helper, surfacing the grounding sources and the
  XI.5 `fallbackUsed` indicator.
- **MUST** — demo-003's XI.5 fallback path **degrades the streaming
  `QueryStream` exchange to the unary `RagService.Query` path** when the
  AI upstream is unavailable or the budget is exceeded — consistent with
  `b7-10-streaming`'s ADR-B7-10-001 ("unary retained as degradation
  target"). This is the demo's hard coupling to b7-10 (b7-7 depends on
  b7-10; see `.forge.yaml depends_on` + ADR-B7-7-002).

**Constitution reference:** Articles I, II, III, IV, V, VII, IX.6, XI.
**Testable:** yes — `test_rag_demos_count_and_status`,
`test_each_rag_demo_has_five_artefacts`,
`test_rag_demo_003_is_multi_layer`.

### FR-RAGEX-005: Demos materialise Article XI (AI-First)

<!-- New in b7-7-example (2026-06-22) -->

- **MUST** — collectively the 3 demos demonstrate the archetype's
  AI-First surfaces: the `embeddings-pipeline` phase (demo-001), the
  `prompt-audit` gate / IX.6 audit span (demo-003, audited across the
  streaming `QueryStream` path), and the Article XI.5 non-AI fallback
  (demo-001 embedder fallback + demo-003 `fallbackUsed` indicator with
  the stream degrading to unary `Query`).
- **MUST** — demo-001's `specs.md` declares the XI.5 fallback path and
  XI.6 (the local in-process embedder keeps text in-process for
  sovereign tiers) as explicit requirements.
- **SHALL** — at least one demo's design references `compliance-tiers`
  for the tier-aware embedder selection (T3 ⇒ local).

**Constitution reference:** Articles IX.6, XI.5, XI.6.
**Testable:** yes — `test_rag_demos_cover_ai_first_surfaces`
(grep-based: fallback/prompt-audit/embeddings markers present across
the demo specs).

### FR-RAGEX-006: Demo discoverability via manifest

<!-- New in b7-7-example (2026-06-22) -->

- **MUST** — `examples/forge-rag-example/.forge/changes/MANIFEST.md`
  enumerates every demo with three columns: demo id, status,
  one-sentence summary.
- **SHOULD** — the manifest lists demos in archive order (chronological).

**Constitution reference:** Article IV.4. **Testable:** yes —
`test_rag_demos_manifest_present_and_lists_three_demos`.

### FR-RAGEX-007: RAG example tree gates pass standalone

<!-- New in b7-7-example (2026-06-22) -->

- **MUST** — running `bash .forge/scripts/verify.sh` from inside
  `examples/forge-rag-example/` exits 0.
- **MUST** — running `bash .forge/scripts/constitution-linter.sh` from
  inside the RAG example tree exits 0.
- **MUST** — the RAG tree's archetype template / workflow files parse as
  valid YAML where present.
- **SHALL** — `task test` from inside the RAG tree invokes the backend
  `cargo test --workspace` + the Qwik test suite and passes on a
  contributor machine with the SDK toolchains installed (L2, opt-in).

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_rag_example_tree_verify_exits_zero`,
`test_rag_example_tree_constitution_linter_exits_zero` (L2, opt-in via
`--require-example-tools`).

### FR-RAGEX-008: Test harness `b7-7.test.sh`

<!-- New in b7-7-example (2026-06-22) -->

- **MUST** — `.forge/scripts/tests/b7-7.test.sh` exists, is executable,
  sources `_helpers.sh` (no new framework — same convention as
  `c1.test.sh`).
- **MUST** — every Testable FR / NFR from this change has at least one
  corresponding `test_*` function. The harness follows the manifest
  pattern (a `# MANIFEST: test_* — FR-RAGEX-NNN` comment block + a meta
  self-check `test_b7_7_manifest_self_consistency`).
- **MUST** — `bash .forge/scripts/tests/b7-7.test.sh` exits 0 when every
  fixture passes; non-zero with `[FAIL] <test-name>: <reason>` on first
  failure.
- **MUST** — `b7-7.test.sh` is registered in `forge-ci.yml`'s harness
  loop as a one-line entry.
- **SHALL** — L1 hermetic by default; L2 (`--require-example-tools`)
  runs the RAG tree's own gates.

**Constitution reference:** Articles I, V. **Testable:** self-testing —
the manifest self-consistency check.

### FR-RAGEX-009: Example renders via `overlay.sh` while archetype is candidate

<!-- New in b7-7-example (2026-06-22) -->

- **MUST** — the RAG example is generated by rendering the
  `ai-native-rag/1.0.0` scaffold-plan via `overlay.sh` (ADR-B7-2-007),
  NOT via `forge init --archetype ai-native-rag` (which MUST keep
  refusing with exit 3 while the archetype is `candidate`, per
  `b7-2a-dispatch-register` / NFR-B7-1-002).
- **MUST** — committing this example MUST NOT promote the archetype:
  `.forge/schemas/ai-native-rag/1.0.0.yaml` stays `stage: candidate` /
  `scaffoldable: false`; no `cli/assets` re-bundle is required by b7-7.
- **SHALL** — the example's README documents the candidate caveat so
  adopters understand that `forge init` will refuse until `b7-6-harness`
  promotes the archetype.

**Constitution reference:** Articles III.4, V. **Testable:** yes —
`test_rag_archetype_still_candidate` (asserts the schema is unchanged),
`test_cli_still_refuses_rag_init` (L2 opt-in — asserts exit 3).

### FR-RAGEX-010: Spec consolidation into `example-reference.md`

<!-- New in b7-7-example (2026-06-22) -->

- **MUST** — at archive time of b7-7, `.forge/specs/example-reference.md`
  gains the `FR-RAGEX-*` + `NFR-RAGEX-*` namespace section and a new
  row in its `## Archived changes` table linking to
  `.forge/changes/b7-7-example/`.
- **MUST** — the consolidation is **additive**: the existing `FR-EX-*`
  content (from c1) is untouched.

**Constitution reference:** Articles III.2, IV. **Testable:** yes —
`test_example_reference_spec_has_ragex_section_post_archive`
(archive-gated on b7-7's `status: archived`).

---

## MODIFIED Requirements

### MODIFIED FR-CI-012: `example` job gates BOTH example trees

<!-- Modified by b7-7-example (2026-06-22). Original from c1-reference-project. -->

- **WAS** (c1): the `example` job, on PRs touching `examples/**`, runs
  `cd examples/forge-fsm-example && verify.sh + constitution-linter.sh`
  and parses the FSM archetype workflow templates.
- **NOW**: the `example` job keeps its `examples/**` paths-filter (which
  already covers `examples/forge-rag-example/**`) and gains a **second**
  per-tree gate block: `cd examples/forge-rag-example && verify.sh +
  constitution-linter.sh` + a structural YAML parse of the RAG tree's
  archetype/workflow templates where present. The FSM block is
  unchanged.
- **MUST** — the edit is **additive**: the FSM gate steps and the
  summary aggregation (`needs: [...example]`, the skip-as-success rule)
  are byte-preserved; only new RAG-gate steps are inserted.
- **MUST** — both trees gate under the same `examples/**` filter; a PR
  touching only one tree still runs both gates (cheap; parse-only).

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_forge_ci_example_job_gates_rag_tree`,
`test_forge_ci_example_job_fsm_block_preserved`.

---

## Non-Functional Requirements

### NFR-RAGEX-001: Additive — no archetype/schema/standard/CLI edit

- **MUST** — b7-7 edits NO archetype template, NO
  `ai-native-rag/1.0.0.yaml` schema, NO `global/*.md` standard, and NO
  CLI code. Existing-file edits are confined to: `forge-ci.yml` (the
  `example` job extension + one harness-loop entry), `examples/README.md`
  (one appended row), and `.forge/specs/example-reference.md` +
  `.forge/specs/forge-ci.md` (at archive, additive deltas).

**Constitution reference:** Article IV. **Testable:** yes —
`test_b7_7_no_archetype_or_schema_edit` (asserts the schema +
template tree are byte-unchanged by this change's diff scope).

### NFR-RAGEX-002: RAG example tree byte budget

- **SHOULD** — total committed bytes under
  `examples/forge-rag-example/` (excluding ignored paths from
  FR-GL-028) MUST be ≤ 5 MB (mirrors NFR-EX-002). The baseline is
  recorded at archive time.

**Constitution reference:** Article X. **Testable:** yes —
`test_rag_example_tree_byte_budget`.

### NFR-RAGEX-003: `example` CI job runtime budget unchanged

- **MUST** — adding the RAG gate block to the `example` job MUST NOT
  push the job's warm-cache runtime above NFR-EX-003's ≤ 4 min budget
  (both trees are parse-only / own-gates-only; no Docker, no build).

**Constitution reference:** Article X. **Testable:** measured at first
archive cycle (mirrors NFR-EX-003).

### NFR-RAGEX-004: Demo proposal byte budget

- **SHOULD** — each demo's `proposal.md` is ≤ 200 lines (mirrors
  NFR-EX-004).

**Constitution reference:** Article X.3. **Testable:** yes —
`test_each_rag_demo_proposal_under_size_budget`.

### NFR-RAGEX-005: Demos cover distinct layer + RAG-surface combinations

- **MUST** — the 3 demos cover distinct layer combinations and distinct
  RAG surfaces: single-layer backend `rag/` pipeline (demo-001),
  single-layer backend `mcp/` server (demo-002), multi-layer
  backend+frontend gateway + **streaming** Qwik UI (demo-003).

**Constitution reference:** Article III. **Testable:** yes —
`test_rag_demos_cover_distinct_combinations`.

---

## Acceptance Criteria (Gherkin)

### AC-RAGEX-001: RAG example tree is inspectable

```gherkin
Given the Forge repo with the ai-native-rag archetype templates
When a contributor browses examples/forge-rag-example/
Then they find a fully-rendered RAG project (backend rag/mcp/llm_gateway,
  frontend Qwik, infra, shared/protos) with a scaffold-manifest declaring
  archetype ai-native-rag version 1.0.0 stage candidate
And the framework's own verify.sh skips the example tree (FR-GL-026 reused)
```

### AC-RAGEX-002: Three RAG demos demonstrate the pipeline

```gherkin
Given examples/forge-rag-example/.forge/changes/
When a contributor reads the demos in archive order
Then demo-001-doc-ingestion shows the rag/ pipeline (single-layer backend)
And demo-002-mcp-search-tool shows the mcp/ search tool (single-layer backend)
And demo-003-rag-query-ui shows the streaming Qwik UI (QueryStream/queryStream)
  + LLM gateway (multi-layer, Janus)
And each demo carries proposal + specs + design + tasks + a feature file
```

### AC-RAGEX-003: AI-First surfaces are materialised

```gherkin
Given the three RAG demos
When a contributor inspects their specs and designs
Then the XI.5 non-AI fallback is exercised (demo-001 embedder fallback,
  demo-003 fallbackUsed indicator with QueryStream degrading to unary Query)
And the IX.6 prompt-audit span is exercised (demo-003 gateway, across the
  streaming path)
And the embeddings-pipeline phase is exercised (demo-001)
```

### AC-RAGEX-004: CI gates the RAG tree without promoting the archetype

```gherkin
Given a PR touching examples/forge-rag-example/**
When forge-ci.yml runs
Then the example job runs the RAG tree's own verify.sh + constitution-linter.sh
And the FSM gate block is preserved unchanged
And the ai-native-rag schema is still stage candidate / scaffoldable false
And forge init --archetype ai-native-rag still refuses with exit 3
```

---

## Scope

**In scope (delivered by b7-7-example):**

- The fully-rendered `examples/forge-rag-example/` tree (FR-RAGEX-001).
- Top-tree navigation README + meta-README row (FR-RAGEX-002, 003).
- 3 archived demo changes covering the `rag`/`mcp` backend surfaces and
  the multi-layer gateway+UI surface (FR-RAGEX-004, 005).
- Demo manifest (FR-RAGEX-006).
- Standalone gate compliance for the RAG tree (FR-RAGEX-007).
- Test harness `b7-7.test.sh` (FR-RAGEX-008).
- Candidate-safe rendering via `overlay.sh` (FR-RAGEX-009).
- Spec consolidation into `example-reference.md` (FR-RAGEX-010).
- The `example` CI job extension (MODIFIED FR-CI-012).

**Deferred (out of scope for b7-7):**

- A 4th `specified`-only RAG demo (Q-2 → future `b7-7-followup`).
- The Qwik streaming **transport** itself (SSE/WebTransport +
  `QueryStream`/`queryStream`) — delivered by `b7-10-streaming`; b7-7's
  demo-003 **consumes** it (hard dep, b7-7 lands after b7-10).
- A Flutter mobile demo (archetype is web-public only, ADR-B7-2-006).
- An AI-Act / DORA compliance demo (gated on `b7-5-ai-act`).
- A Pythia agent demo (gated on `b7-pythia`).
- Promotion of `ai-native-rag` to stable (gated on `b7-6-harness`).
