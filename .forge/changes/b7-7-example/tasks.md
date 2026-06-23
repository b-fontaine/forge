# Tasks: b7-7-example

<!-- Audit: B.7.7. TDD ordering is per-FR: RED test before GREEN impl.        -->
<!-- Parallel-eligible tasks marked [P]. Toolchain tasks (overlay.sh, cargo,  -->
<!-- node, buf) flagged [REQUIRES-TOOLS]. NO production code is written by     -->
<!-- this planning brick — these tasks describe the eventual implementation.  -->

Implementation is split into **3 commit clusters** (mirrors c1 ADR-010,
adapted: b7-7 has no machinery cluster since c1 already shipped it):

| Phase | Cluster | Coverage |
|---|---|---|
| 1 | **tree** | render RAG tree via overlay.sh + README + meta-row + CI extension |
| 2 | **demos** | 3 demo changes + their product code |
| 3 | **harness + spec** | b7-7.test.sh + example-reference.md consolidation |

Each phase ends with a RED→GREEN→REFACTOR closure on its subset of
`b7-7.test.sh`.

---

## Phase 0: Bootstrap test harness

- [x] Create `.forge/scripts/tests/b7-7.test.sh` skeleton — sources
  `_helpers.sh`, declares an empty `# MANIFEST:` block, implements
  `test_b7_7_manifest_self_consistency` as the first test, exits 0.
  [Story: FR-RAGEX-008]
- [x] `chmod +x` the harness. [Story: FR-RAGEX-008]
- [x] Run once → "1/1 PASS" (meta-test only). GREEN baseline.
  [Story: FR-RAGEX-008]

---

## Phase 1: Tree cluster

### Phase 1 — RED

- [x] Add `test_rag_example_tree_canonical_structure` — assert
  `examples/forge-rag-example/` exists with backend/(rag,mcp,llm_gateway,
  bin-server), frontend/web-public/, infra/, shared/protos/v1/rag/,
  .forge/, .claude/, Taskfile.yml, docker-compose.dev.yml, .gitignore,
  CLAUDE.md, README.md, .forge.yaml. [Story: FR-RAGEX-001] [P]
- [x] Add `test_rag_example_scaffold_manifest_complete` — parse
  `.forge/scaffold-manifest.yaml`; assert `archetype: ai-native-rag`,
  `archetype_version: "1.0.0"`, `stage: candidate`,
  `project_name: forge-rag-example`, required SHA/date keys.
  [Story: FR-RAGEX-001] [P]
- [x] Add `test_rag_example_readme_has_required_sections` — 4 H2
  sections + the "does NOT show" note. [Story: FR-RAGEX-002] [P]
- [x] Add `test_examples_meta_readme_lists_rag_example` — grep
  `examples/README.md` for a `forge-rag-example` + `ai-native-rag` row.
  [Story: FR-RAGEX-003] [P]
- [x] Add `test_rag_archetype_still_candidate` — assert
  `.forge/schemas/ai-native-rag/1.0.0.yaml` still declares
  `stage: candidate` / `scaffoldable: false` (committing the example
  must not promote). [Story: FR-RAGEX-009] [P]
- [x] Add `test_forge_ci_example_job_gates_rag_tree` — parse
  `forge-ci.yml`; assert the `example` job contains a step running
  `cd examples/forge-rag-example` + `verify.sh`. [Story: FR-CI-012] [P]
- [x] Add `test_forge_ci_example_job_fsm_block_preserved` — assert the
  FSM `cd examples/forge-fsm-example` steps are still present unchanged.
  [Story: FR-CI-012] [P]
- [x] Add `test_forge_ci_harness_loop_has_b7_7` — assert the harness
  loop lists `b7-7.test.sh`. [Story: FR-RAGEX-008] [P]
- [x] Add `test_b7_7_no_archetype_or_schema_edit` — assert the archetype
  template tree + schema are not in this change's edit scope (grep guard
  / git-diff scope check). [Story: NFR-RAGEX-001] [P]
- [x] Run `b7-7.test.sh` → confirm all new tests FAIL (RED).

### Phase 1 — GREEN

- [x] **Precondition: `b7-10-streaming` has landed** (hard dep,
  ADR-B7-7-002) — the example tree must be rendered from the
  b7-10-extended `ai-native-rag/1.0.0` templates so the streaming
  surface is present for demo-003.
- [x] Render the archetype via `overlay.sh` against the (b7-10-extended)
  `ai-native-rag/1.0.0` scaffold-plan into a tmpdir, with
  `project_name=forge-rag-example`, a reverse-domain + root-module.
  [REQUIRES-TOOLS: bash/overlay.sh] [Story: FR-RAGEX-001, FR-RAGEX-009]
- [x] Copy the rendered tree to `examples/forge-rag-example/`; verify
  `.forge/scaffold-manifest.yaml` is present + correct (stage candidate).
  [Story: FR-RAGEX-001]
- [x] Drop into the tree and run `bash .forge/scripts/verify.sh` once to
  confirm its own gates pass. [REQUIRES-TOOLS: python3] [Story: FR-RAGEX-007]
- [x] Write `examples/forge-rag-example/README.md` — 4 H2 sections; the
  "How built" section documents `overlay.sh` (NOT `forge init`); the
  "does NOT show" note records candidate status + no-Flutter + no
  AI-Act/Pythia demo (demo-003 DOES show streaming via b7-10).
  Demo-changes section empty for now (Phase 2 populates).
  [Story: FR-RAGEX-002]
- [x] Append the `forge-rag-example` row to `examples/README.md`'s table.
  [Story: FR-RAGEX-003]
- [x] Extend the `example` job in `.github/workflows/forge-ci.yml` with
  the RAG gate block (verify.sh + constitution-linter.sh + infra YAML
  parse), inserted after the FSM steps; preserve FSM steps + summary
  byte-for-byte. [Story: FR-CI-012]
- [x] Add `"b7-7.test.sh"` to the harness loop (after `"c1.test.sh"`).
  [Story: FR-RAGEX-008]
- [x] Run `b7-7.test.sh` → Phase 1 tests PASS (GREEN).

### Phase 1 — REFACTOR

- [x] Run `bash .forge/scripts/verify.sh` from the Forge repo root —
  confirm the (already-generic) `[skipped: examples]` guard covers the
  new `forge-rag-example/` subtree and existing counts are unchanged.
  [Story: FR-GL-026 reused]
- [x] Run all existing harnesses (incl. `c1.test.sh`) — confirm zero
  regression. [Story: backwards compatibility]
- [x] Commit Phase 1: `feat(examples): b7-7 RAG example tree + CI gate`.

---

## Phase 2: Demos cluster

### Phase 2 — RED

- [x] Add `test_rag_demos_count_and_status` — exactly 3 demos; all
  `status: archived`. [Story: FR-RAGEX-004] [P]
- [x] Add `test_each_rag_demo_has_five_artefacts` — proposal/specs/
  design(-per-layer)/tasks(-per-layer)/features per demo. [Story: FR-RAGEX-004] [P]
- [x] Add `test_rag_demo_003_is_multi_layer` — parse
  `demo-003-rag-query-ui/.forge.yaml`; assert `layers: [backend,
  frontend]` (len ≥ 2), `designs/` + `tasks/` per-layer files exist.
  [Story: FR-RAGEX-004 + FR-GL-016] [P]
- [x] Add `test_rag_demos_cover_ai_first_surfaces` — grep the demo specs
  for fallback / prompt-audit / embeddings markers. [Story: FR-RAGEX-005] [P]
- [x] Add `test_rag_demos_manifest_present_and_lists_three_demos`.
  [Story: FR-RAGEX-006] [P]
- [x] Add `test_each_rag_demo_proposal_under_size_budget` — ≤ 200 lines.
  [Story: NFR-RAGEX-004] [P]
- [x] Add `test_rag_demos_cover_distinct_combinations` — distinct layer
  + RAG-surface combos. [Story: NFR-RAGEX-005] [P]
- [x] Run `b7-7.test.sh` → 7 new tests FAIL (RED).

### Phase 2 — GREEN (chronological)

#### demo-001-doc-ingestion (single-layer backend, `rag/`)
- [x] Bootstrap the change skeleton inside the RAG tree; set
  `layers: [backend]`. [Story: FR-RAGEX-004]
- [x] Write proposal (≤ 200 lines) — document ingestion + RAG query.
- [x] Write specs — FR-BE-* (chunking, `Embedder`, pgvector HNSW upsert,
  hybrid retrieval vector+BM25+RRF, re-rank) + XI.5 fallback + XI.6
  in-process local path. [Story: FR-RAGEX-004, FR-RAGEX-005]
- [x] Write design — ADR(s): cucumber-rs, `Embedder` trait selection
  (tier-aware), pgvector `vector_cosine_ops`.
- [x] Write tasks — TDD-ordered (RED chunking test → GREEN, RED
  retrieval test → GREEN). [Story: Article I]
- [x] Implement TDD in `backend/rag/` per the rendered scaffolding.
  [REQUIRES-TOOLS: cargo]
- [x] Write `features/doc_ingestion.feature` — ingest → query →
  grounded answer + fallback path; cucumber-rs steps. [REQUIRES-TOOLS: cargo]
- [x] Mark tasks `[x]`, archive (status: archived, timeline populated).

#### demo-002-mcp-search-tool (single-layer backend, `mcp/`)
- [x] Bootstrap; set `layers: [backend]`. [Story: FR-RAGEX-004]
- [x] Write proposal (≤ 200 lines) — expose retriever as MCP `search`.
- [x] Write specs — FR-BE-* (rmcp `#[tool_router]` `search` tool,
  schema-validated input, dual transport stdio/http, OAuth→Zitadel hook).
- [x] Write design — ADR(s): rmcp transport feature-gating, least-priv.
- [x] Write tasks — TDD-ordered. [Story: Article I]
- [x] Implement TDD in `backend/mcp/`. [REQUIRES-TOOLS: cargo]
- [x] Write `features/mcp_search.feature` — search happy + bounded
  paths. [REQUIRES-TOOLS: cargo]
- [x] Archive.

#### demo-003-rag-query-ui (multi-layer backend + frontend, Janus, STREAMING)
- [x] Bootstrap; set `layers: [backend, frontend]`; declare per-layer
  `designs/` + `tasks/` (FR-GL-016). [Story: FR-RAGEX-004]
- [x] Write proposal (≤ 200 lines) — STREAMING Qwik query UI consuming
  b7-10's `RagService.QueryStream` via the gateway.
- [x] Write specs — per-layer delta: FR-BE-* (gateway prompt-audit
  IX.6 across the stream, budget/kill-switch, XI.5 fallback degrading
  `QueryStream` → unary `Query` per b7-10 ADR-B7-10-001), FR-FE-* (Qwik
  query screen, progressive token render via `queryStream`, sources
  render, `fallbackUsed` indicator). [Story: FR-RAGEX-004, FR-RAGEX-005]
- [x] Write `designs/design-backend.md` + `designs/design-frontend.md`
  (Janus-orchestrated, ≥ 2 layers). [Story: FR-GL-015]
- [x] Write `tasks/tasks-backend.md` + `tasks/tasks-frontend.md`.
- [x] Implement TDD: backend `QueryStream` gateway path; Qwik
  `queryStream` progressive-render component + component test.
  [REQUIRES-TOOLS: cargo, node, buf]
- [x] Write `features/rag_query_ui.feature` — streaming query happy path
  (progressive tokens) + fallbackUsed path (degrade to unary).
  [REQUIRES-TOOLS: node]
- [x] Archive.

#### Manifest + closure
- [x] Write `.forge/changes/MANIFEST.md` — 3 rows (id, status, summary).
  [Story: FR-RAGEX-006]
- [x] Populate the README's `## Demo changes` section with the 3 demos.
  [Story: FR-RAGEX-002]
- [x] Run `b7-7.test.sh` → Phase 2 tests PASS (GREEN).

### Phase 2 — REFACTOR
- [x] Run all harnesses → zero regression.
- [x] Run Forge-root `verify.sh` → `[skipped: examples]` covers the new
  demo paths.
- [x] Commit Phase 2: `feat(examples): b7-7 — 3 RAG demo changes`.

---

## Phase 3: Harness + spec cluster

### Phase 3 — RED
- [x] Add `test_rag_example_tree_byte_budget` — ≤ 5 MB (excluding
  ignored paths). [Story: NFR-RAGEX-002] [P]
- [x] Add `test_example_reference_spec_has_ragex_section_post_archive`
  — archive-gated; assert `.forge/specs/example-reference.md` has the
  `FR-RAGEX-*` section + a b7-7 Archived-changes row. [Story: FR-RAGEX-010]
- [x] Add L2 (opt-in) tests: `test_rag_example_tree_verify_exits_zero`,
  `test_rag_example_tree_constitution_linter_exits_zero`,
  `test_cli_still_refuses_rag_init` (exit 3). Gated on
  `--require-example-tools`. [Story: FR-RAGEX-007, FR-RAGEX-009]
- [x] Run `b7-7.test.sh` → Phase 3 RED tests FAIL.

### Phase 3 — GREEN
- [x] Verify byte budget holds; record the baseline in NFR-RAGEX-002.
  [Story: NFR-RAGEX-002]
- [x] (At archive — handled by /forge:archive) append the `FR-RAGEX-*`
  + `NFR-RAGEX-*` section + the b7-7 row to
  `.forge/specs/example-reference.md`. [Story: FR-RAGEX-010]
- [x] (At archive) merge the MODIFIED FR-CI-012 delta into
  `.forge/specs/forge-ci.md`.
- [x] Run `b7-7.test.sh` → Phase 3 tests PASS (except the archive-gated
  spec test, which passes once status=archived).

### Phase 3 — REFACTOR
- [x] Run all harnesses + verify.sh + constitution-linter.sh → zero
  regression.
- [x] Run `b7-7.test.sh --require-example-tools` (L2) → PASS.
- [x] Commit Phase 3: `feat(forge): b7-7 harness + example-reference consolidation`.

---

## Phase 4: Quality (pre-archive)
- [x] Verify Article VII for demo-001/002: `cargo clippy --workspace
  --all-targets -- -D warnings` from inside the RAG tree.
  [REQUIRES-TOOLS: cargo]
- [x] Verify demo-003 frontend: Qwik lint/type-check + component test.
  [REQUIRES-TOOLS: node]
- [x] Confirm coverage ≥ 80% (Article X.1) for the demo code where
  toolchains are available. [REQUIRES-TOOLS: cargo, node]

## Phase 5: Documentation + gate (handled by /forge:archive)
- [ ] /forge:archive merges the `FR-RAGEX-*` namespace into
  `example-reference.md` (FR-RAGEX-010).
- [ ] /forge:archive merges the FR-CI-012 delta into `forge-ci.md`.
- [ ] /forge:archive updates `CHANGELOG.md` + `docs/new-archetypes-plan.md`
  §0.12 (mark brick #8 done).
- [ ] /forge:archive sets `.forge.yaml` `status: archived`, populates
  `timeline.archived`; confirms every `[ ]` is `[x]`.
