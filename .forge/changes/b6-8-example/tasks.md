# Tasks: b6-8-example

<!-- Audit: B.6.8. TDD ordering is per-FR: RED test before GREEN impl.         -->
<!-- Parallel-eligible tasks marked [P]. Toolchain tasks (forge init CLI,       -->
<!-- cargo) flagged [REQUIRES-TOOLS].                                           -->

Implementation is split into **3 commit clusters** (mirrors b7-7,
adapted: b6-8 has no machinery cluster since c1 already shipped it):

| Phase | Cluster | Coverage |
|---|---|---|
| 1 | **tree** | render EDA tree via real `forge init` CLI + framework assets + README + meta-row + CI extension + budget bump |
| 2 | **demos** | 3 demo changes + their lifecycle artefacts |
| 3 | **harness + spec** | b6-8.test.sh + example-reference.md consolidation |

Each phase ends with a RED→GREEN→REFACTOR closure on its subset of
`b6-8.test.sh`.

---

## Phase 0: Bootstrap test harness

- [x] Create `.forge/scripts/tests/b6-8.test.sh` skeleton — sources
  `_helpers.sh`, declares an empty `# MANIFEST:` block, implements
  `test_b6_8_manifest_self_consistency` as the first test.
  [Story: FR-EDAEX-008]
- [x] `chmod +x` the harness. [Story: FR-EDAEX-008]
- [x] Run once → meta-test only. GREEN baseline. [Story: FR-EDAEX-008]

---

## Phase 1: Tree cluster

### Phase 1 — RED

- [x] Add `test_eda_example_tree_canonical_structure` — assert
  `examples/forge-eda-example/` exists with backend/(events,eventstore,
  saga,bin-server), infra/, shared/{asyncapi,protos/v1/events}, .forge/,
  .claude/, Taskfile.yml, docker-compose.dev.yml, .gitignore, CLAUDE.md,
  README.md, .forge.yaml. [Story: FR-EDAEX-001] [P]
- [x] Add `test_eda_example_scaffold_manifest_complete` — parse
  `.forge/scaffold-manifest.yaml`; assert `archetype: event-driven-eu`,
  `archetype_version: "1.0.0"`, `project_name: forge-eda-example`,
  required SHA/date keys. [Story: FR-EDAEX-001] [P]
- [x] Add `test_eda_example_readme_has_required_sections` — 4 H2
  sections + the "does NOT show" note + the `forge init` build path.
  [Story: FR-EDAEX-002] [P]
- [x] Add `test_examples_meta_readme_lists_eda_example` — grep
  `examples/README.md` for a `forge-eda-example` + `event-driven-eu` row.
  [Story: FR-EDAEX-003] [P]
- [x] Add `test_eda_archetype_still_stable_scaffoldable` — assert
  `.forge/schemas/event-driven-eu/1.0.0.yaml` is `stage: stable` /
  `scaffoldable: true` (committing the example must not modify it).
  [Story: FR-EDAEX-009] [P]
- [x] Add `test_forge_ci_example_job_gates_eda_tree` — parse
  `forge-ci.yml`; assert the `example` job contains a step running
  `cd examples/forge-eda-example` + `verify.sh`. [Story: FR-CI-012] [P]
- [x] Add `test_forge_ci_example_job_fsm_rag_blocks_preserved` — assert
  the FSM + RAG `cd examples/forge-{fsm,rag}-example` steps are still
  present unchanged. [Story: FR-CI-012] [P]
- [x] Add `test_forge_ci_harness_loop_has_b6_8` — assert the harness
  loop lists `b6-8.test.sh`. [Story: FR-EDAEX-008] [P]
- [x] Add `test_forge_ci_line_budget_holds` — assert `forge-ci.yml`
  line count ≤ the (bumped) cap. [Story: FR-CI-012] [P]
- [x] Add `test_b6_8_no_archetype_or_schema_edit` — assert the framework
  archetype template tree + schema are not in this change's edit scope.
  [Story: NFR-EDAEX-001] [P]
- [x] Run `b6-8.test.sh` → confirm all new tests FAIL (RED).

### Phase 1 — GREEN

- [x] Render the archetype via `forge init --archetype event-driven-eu`
  (built CLI: `node cli/dist/index.js init forge-eda-example --target … \
  --archetype event-driven-eu --org io.forge.example --force`) into a
  tmpdir. [REQUIRES-TOOLS: node CLI] [Story: FR-EDAEX-001, FR-EDAEX-009]
- [x] Copy the rendered tree to `examples/forge-eda-example/`; verify
  `.forge/scaffold-manifest.yaml` is present + correct
  (archetype event-driven-eu 1.0.0). [Story: FR-EDAEX-001]
- [x] Add the example's own `.forge/` framework assets (constitution,
  standards incl. event-driven/asyncapi-contracts/nats-jetstream, gate
  scripts, templates, schemas) + `.claude/` so the tree self-validates.
  [Story: FR-EDAEX-007]
- [x] Drop into the tree and run `bash .forge/scripts/verify.sh` +
  `constitution-linter.sh` to confirm its own gates pass.
  [REQUIRES-TOOLS: python3] [Story: FR-EDAEX-007]
- [x] Write `examples/forge-eda-example/README.md` — 4 H2 sections; the
  "How built" section documents the real `forge init` CLI; the "does NOT
  show" note records no-frontend + no-live-broker + no-compliance-demo.
  Demo-changes section empty for now (Phase 2 populates).
  [Story: FR-EDAEX-002]
- [x] Append the `forge-eda-example` row to `examples/README.md`'s table.
  [Story: FR-EDAEX-003]
- [x] Extend the `example` job in `.github/workflows/forge-ci.yml` with
  the EDA gate block (verify.sh + constitution-linter.sh + YAML parse),
  inserted after the RAG steps; preserve FSM + RAG steps + summary
  byte-for-byte. [Story: FR-CI-012]
- [x] Add `"b6-8.test.sh"` to the harness loop (example-tree cluster).
  [Story: FR-EDAEX-008]
- [x] Bump the `forge-ci.yml` line budget 400→420 in lockstep across
  `c1.test.sh`, `g1.test.sh`, `t5-1.test.sh`, `t5-otel-live-run.test.sh`
  + `forge-self-ci.md`. [Story: FR-CI-012]
- [x] Run `b6-8.test.sh` → Phase 1 tests PASS (GREEN).

### Phase 1 — REFACTOR

- [x] Run `bash .forge/scripts/verify.sh` from the Forge repo root —
  confirm the (already-generic) skip-guard covers the new
  `forge-eda-example/` subtree and existing counts are unchanged.
  [Story: FR-EDAEX-001]
- [x] Run all budget-coupled harnesses (`c1`, `g1`, `t5-1`,
  `t5-otel-live-run`) — confirm GREEN after the bump. [Story: FR-CI-012]
- [x] Commit Phase 1: `feat(examples): b6-8 EDA example tree + CI gate`.
  [Story: FR-EDAEX-001]

---

## Phase 2: Demos cluster

### Phase 2 — RED

- [x] Add `test_eda_demos_count_and_status` — exactly 3 demos; all
  `status: archived`. [Story: FR-EDAEX-004] [P]
- [x] Add `test_each_eda_demo_has_five_artefacts` — proposal/specs/
  design(-per-layer)/tasks(-per-layer)/features per demo.
  [Story: FR-EDAEX-004] [P]
- [x] Add `test_eda_demo_003_is_multi_layer` — parse
  `demo-003-order-saga/.forge.yaml`; assert `layers: [backend, infra]`
  (len ≥ 2), `designs/` + `tasks/` per-layer files exist.
  [Story: FR-EDAEX-004] [P]
- [x] Add `test_eda_demos_cover_event_surfaces` — grep the demo specs
  for jetstream / idempotency / projection / saga / compensation
  markers. [Story: FR-EDAEX-005] [P]
- [x] Add `test_eda_demos_manifest_present_and_lists_three_demos`.
  [Story: FR-EDAEX-006] [P]
- [x] Add `test_each_eda_demo_proposal_under_size_budget` — ≤ 200 lines.
  [Story: NFR-EDAEX-004] [P]
- [x] Add `test_eda_demos_cover_distinct_combinations` — distinct layer
  + event-surface combos. [Story: NFR-EDAEX-005] [P]
- [x] Run `b6-8.test.sh` → new tests FAIL (RED).

### Phase 2 — GREEN (chronological)

#### demo-001-ingestion-http-nats (single-layer backend, `events/`)
- [x] Bootstrap the change skeleton inside the EDA tree; set
  `layers: [backend]`. [Story: FR-EDAEX-004]
- [x] Write proposal (≤ 200 lines) — axum HTTP → NATS JetStream publish.
  [Story: FR-EDAEX-004]
- [x] Write specs — FR-BE-* (idempotent versioned `EventEnvelope`,
  `Nats-Msg-Id` dedup, subject namespacing). [Story: FR-EDAEX-005]
- [x] Write design — ADR(s): `EventPublisher` port, idempotency key
  strategy, cucumber-rs. [Story: FR-EDAEX-004]
- [x] Write tasks — TDD-ordered mapping onto the rendered
  `backend/events/`. [Story: Article I]
- [x] Write `features/ingestion_http_nats.feature`. [Story: FR-EDAEX-005]
- [x] Archive (status: archived, timeline populated). [Story: FR-EDAEX-004]

#### demo-002-projection-readmodel (single-layer backend, `eventstore/`)
- [x] Bootstrap; set `layers: [backend]`. [Story: FR-EDAEX-004]
- [x] Write proposal (≤ 200 lines) — fold event store → read model.
  [Story: FR-EDAEX-004]
- [x] Write specs — FR-BE-* (`Projection` trait, deterministic replay,
  inbox dedup / outbox-inbox pattern). [Story: FR-EDAEX-005]
- [x] Write design — ADR(s): projection determinism, inbox guard.
  [Story: FR-EDAEX-004]
- [x] Write tasks — TDD-ordered. [Story: Article I]
- [x] Write `features/projection_readmodel.feature`. [Story: FR-EDAEX-005]
- [x] Archive. [Story: FR-EDAEX-004]

#### demo-003-order-saga (multi-layer backend + infra, Janus)
- [x] Bootstrap; set `layers: [backend, infra]`; declare per-layer
  `designs/` + `tasks/` (FR-GL-016). [Story: FR-EDAEX-004]
- [x] Write proposal (≤ 200 lines) — Temporal activity-only 3-step saga.
  [Story: FR-EDAEX-004]
- [x] Write specs — per-layer delta: FR-BE-* (saga coordinator, 3 steps,
  reverse-order compensation, activity registration), FR-IN-* (Temporal
  cluster substrate, docker-compose/Helm). [Story: FR-EDAEX-005]
- [x] Write `designs/design-backend.md` + `designs/design-infra.md`
  (Janus-orchestrated, ≥ 2 layers). [Story: FR-GL-015]
- [x] Write `tasks/tasks-backend.md` + `tasks/tasks-infra.md`.
  [Story: Article I]
- [x] Write `features/order_saga.feature` — happy path + compensation
  path. [Story: FR-EDAEX-005]
- [x] Archive. [Story: FR-EDAEX-004]

#### Manifest + closure
- [x] Write `.forge/changes/MANIFEST.md` — 3 rows (id, status, summary).
  [Story: FR-EDAEX-006]
- [x] Populate the README's `## Demo changes` section with the 3 demos.
  [Story: FR-EDAEX-002]
- [x] Run `b6-8.test.sh` → Phase 2 tests PASS (GREEN). [Story: FR-EDAEX-004]

### Phase 2 — REFACTOR
- [x] Run all harnesses → zero regression. [Story: FR-EDAEX-004]
- [x] Run Forge-root `verify.sh` → skip-guard covers the new demo paths.
  [Story: FR-EDAEX-001]
- [x] Commit Phase 2: `feat(examples): b6-8 — 3 EDA demo changes`.
  [Story: FR-EDAEX-004]

---

## Phase 3: Harness + spec cluster

### Phase 3 — RED
- [x] Add `test_eda_example_tree_byte_budget` — ≤ 5 MB (excluding
  ignored paths). [Story: NFR-EDAEX-002] [P]
- [x] Add `test_example_reference_spec_has_edaex_section_post_archive`
  — archive-gated; assert `.forge/specs/example-reference.md` has the
  `FR-EDAEX-*` section + a b6-8 Archived-changes row. [Story: FR-EDAEX-010]
- [x] Add L2 (opt-in) tests: `test_eda_example_tree_verify_exits_zero`,
  `test_eda_example_tree_constitution_linter_exits_zero`,
  `test_cli_scaffolds_eda_init` (exit 0). Gated on
  `--require-example-tools`. [Story: FR-EDAEX-007, FR-EDAEX-009]
- [x] Run `b6-8.test.sh` → Phase 3 RED tests FAIL.

### Phase 3 — GREEN
- [x] Verify byte budget holds; record the baseline in NFR-EDAEX-002.
  [Story: NFR-EDAEX-002]
- [x] (At archive — handled by /forge:archive) append the `FR-EDAEX-*`
  + `NFR-EDAEX-*` section + the b6-8 row to
  `.forge/specs/example-reference.md`. [Story: FR-EDAEX-010]
- [x] (At archive) merge the MODIFIED FR-CI-012 delta into
  `.forge/specs/forge-ci.md`. [Story: FR-CI-012]
- [x] Run `b6-8.test.sh` → Phase 3 tests PASS (except the archive-gated
  spec test, which passes once status=archived). [Story: FR-EDAEX-010]

### Phase 3 — REFACTOR
- [x] Run all harnesses + verify.sh + constitution-linter.sh → zero
  regression. [Story: FR-EDAEX-008]
- [x] Run `b6-8.test.sh --require-example-tools` (L2) → PASS.
  [Story: FR-EDAEX-007]
- [x] Commit Phase 3: `feat(forge): b6-8 harness + example-reference consolidation`.
  [Story: FR-EDAEX-010]

---

## Phase 4: Quality (pre-archive)
- [x] Verify the rendered backend builds where tools present:
  `cargo test --workspace` from inside the EDA tree.
  [REQUIRES-TOOLS: cargo] [Story: FR-EDAEX-007]
- [x] Confirm the example tree's own gates are GREEN standalone.
  [Story: FR-EDAEX-007]

## Phase 5: Documentation + gate (handled by /forge:archive)
- [ ] /forge:archive merges the `FR-EDAEX-*` namespace into
  `example-reference.md` (FR-EDAEX-010). [Story: FR-EDAEX-010]
- [ ] /forge:archive merges the FR-CI-012 delta into `forge-ci.md`.
  [Story: FR-CI-012]
- [ ] /forge:archive updates `docs/new-archetypes-plan.md` §6.1 / §0.13
  (mark brick #10 done). [Story: FR-EDAEX-001]
- [ ] /forge:archive sets `.forge.yaml` `status: archived`, populates
  `timeline.archived`; confirms every `[ ]` is `[x]`. [Story: FR-EDAEX-001]
