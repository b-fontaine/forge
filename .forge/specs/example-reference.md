# Spec: example-reference

<!-- Audit: Module C.1 — first public reference project (XL effort).        -->
<!-- This file accumulates archived requirements for the Forge **example    -->
<!-- tree** living under `examples/`. It is distinct from                   -->
<!-- `full-stack-monorepo.md` which governs the **archetype contract**      -->
<!-- shipped to scaffolded projects.                                        -->
<!--                                                                        -->
<!-- Audience here : Forge maintainers + adopters reading the example to    -->
<!-- understand what a Forge-conformant project looks like.                 -->
<!-- Audience for `full-stack-monorepo.md` : adopters scaffolding archetype -->
<!-- projects + framework contributors evolving the contract.               -->

This spec is the consolidated contract for the **reference project
tree** under `examples/`. It declares what the example tree MUST
contain and what guarantees the framework makes about it. It is
populated incrementally as `c1-*` and successor changes land.

The full standard governing the discipline demonstrated by the
example tree is the union of `global/monorepo-layout.md`,
`global/multi-layer-workflow.md`, and the per-stack standards
(Flutter / Rust / infra) — the example **uses** those standards
rather than redefining them.

---

## Archived changes

| Change | Date | Phase | FRs added |
|---|---|---|---|
| [`c1-reference-project`](../changes/c1-reference-project/) | 2026-04-30 | First reference project (full-stack-monorepo) | FR-EX-001..010 + NFR-EX-001..006 |
| [`b7-7-example`](../changes/b7-7-example/) | 2026-06-23 | Second reference project (ai-native-rag, 3 RAG demos) | FR-RAGEX-001..010 + NFR-RAGEX-001..005 + MODIFIED FR-CI-012 |

---

## Requirements

### FR-EX-001: Example tree exists at canonical path

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — directory `examples/forge-fsm-example/` exists at
  the Forge repo root and is a fully-scaffolded
  `full-stack-monorepo` project (validated by running
  `bash .forge/scripts/scaffolder/init.sh forge-fsm-example
  --org io.forge.example --target-dir examples/forge-fsm-example`
  per `b1-scaffolder`'s contract — FR-GL-011).
- **MUST** — the example tree contains the canonical 4-layer
  structure : `frontend/` (Flutter app), `backend/` (Rust
  workspace with the 5 hexagonal crates), `infra/` (k8s + kong
  + observability + docker), `shared/protos/` (buf workspace
  + v1 example proto).
- **MUST** — the example contains its own `.forge/`,
  `.claude/`, `.mcp.json`, `.github/workflows/` (the 4 reference
  workflows shipped by `b1-delivery`), `Taskfile.yml`,
  `docker-compose.dev.yml`, `.env.example`, `.gitignore`, root
  `CLAUDE.md`, `.forge.yaml` declaring `schema:
  full-stack-monorepo`.
- **MUST** — `.forge/scaffold-manifest.yaml` is committed and
  records the canonical scaffolder audit trail (NFR-008 of
  `b1-scaffolder`) : `archetype: full-stack-monorepo`,
  `archetype_version: "1.0.0"` (aligned with the schema's stable
  promotion from `b1-delivery`), `scaffold_plan_sha`,
  `template_set_sha`, `scaffold_date`, `project_name:
  forge-fsm-example`, `reverse_domain: io.forge.example`,
  `root_module: forge_fsm_example`, plus `tools.flutter`,
  `tools.cargo`, `tools.buf`.

**Constitution reference:** Articles V, VI, VII, VIII.
**Testable:** yes — `test_example_tree_canonical_structure`
+ `test_example_scaffold_manifest_complete` in
`.forge/scripts/tests/c1.test.sh`.

### FR-EX-002: Top-of-tree navigation README

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — `examples/forge-fsm-example/README.md` exists and
  contains four canonical H2 sections : `## How this example
  was built`, `## What's in here`, `## Demo changes`, `## Reproducing
  this example`.
- **MUST** — `## How this example was built` lists the exact
  command invocations used (`forge init` / `forge new` /
  `forge specify` / etc.) so an adopter can reproduce the
  example from a clean state.
- **MUST** — `## Demo changes` enumerates the 4 demos shipped
  by c1 (3 archived + 1 specified-only), each with a one-sentence
  summary and a relative link to its change directory.
- **SHALL** — `## What's in here` provides a callout for each
  layer (frontend / backend / infra / shared/protos) with a
  one-sentence description and a pointer to the governing Forge
  standard.

**Constitution reference:** Article X.3 (public docs), Article III.2.
**Testable:** yes — `test_example_readme_has_required_sections`.

### FR-EX-003: Meta-documentation `examples/README.md`

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — `examples/README.md` exists at the Forge repo root
  and explains the directory's purpose and lists the available
  examples as a one-line bullet each.
- **MUST** — currently lists exactly one example
  (`forge-fsm-example`) with its archetype, last-updated date,
  and short description.
- **SHALL** — explains that `examples/` is **excluded from
  Forge's own gates** by FR-GL-026 / FR-GL-027 — the example
  owns its own gates.

**Constitution reference:** Article X.3. **Testable:** yes —
`test_examples_meta_readme_present`.

### FR-EX-004: Three archived demo application changes

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — under `examples/forge-fsm-example/.forge/changes/`,
  three demo changes exist with `status: archived` :
  `demo-001-greeting-service`, `demo-002-greeting-screen`,
  `demo-003-rate-limit`.
- **MUST** — each archived demo's `.forge.yaml` declares
  `status: archived`, a complete `timeline:` block (every phase
  populated), and `parent_audit_items: [C.1]`.
- **MUST** — each archived demo contains the canonical 5
  artefacts : `proposal.md`, `specs.md` (delta format),
  `design.md` (single-layer) or per-layer `design-<layer>.md`
  (multi-layer per FR-GL-016), `tasks.md` (single-layer) or
  per-layer `tasks-<layer>.md` (multi-layer), and a
  `features/<demo-name>.feature` with realistic Gherkin
  scenarios.
- **MUST** — `demo-001-greeting-service` is **single-layer
  backend** (`layers: [backend]`) — minimal gRPC `Greeter`
  service with hexagonal Rust + cucumber-rs BDD.
- **MUST** — `demo-002-greeting-screen` is **single-layer
  frontend** (`layers: [frontend]`) — Flutter screen consuming
  demo-001's contract via Cubit + flutter_bloc + widget tests.
- **MUST** — `demo-003-rate-limit` is **multi-layer backend +
  infra** (`layers: [backend, infra]`) — triggers the Janus
  orchestrator (≥ 2 layers per FR-GL-015), ships per-layer
  `designs_per_layer:` and `tasks_per_layer:` per FR-GL-016.

**Constitution reference:** Articles I, II, III, IV, V, VI,
VII, VIII. **Testable:** yes —
`test_archived_demos_count_and_status`,
`test_each_archived_demo_has_five_artefacts`,
`test_demo_003_is_multi_layer`.

### FR-EX-005: Active demo at status `specified`

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — under `examples/forge-fsm-example/.forge/changes/`,
  the demo `demo-004-user-onboarding` exists with
  `status: specified` and is **multi-layer** (declares
  `layers: [backend, frontend, protos]`).
- **MUST** — `demo-004` ships `proposal.md` + `specs.md` only
  (no `design.md`, no `tasks.md`, no `features/`). The
  `specs.md` MUST contain at least one realistic
  `[NEEDS CLARIFICATION:]` marker per Article III.4.
- **MUST** — `demo-004`'s `.forge.yaml` declares
  `timeline.specified` populated, all later timeline fields
  absent or commented out.

**Constitution reference:** Articles III.2, III.4, IV.4.
**Testable:** yes — `test_demo_004_is_specified_only`,
`test_demo_004_has_needs_clarification_marker`.

### FR-EX-006: Demo discoverability via manifest

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — `examples/forge-fsm-example/.forge/changes/MANIFEST.md`
  enumerates every demo with three columns : demo id, status,
  one-sentence summary.
- **SHOULD** — the manifest lists demos in archive order
  (chronological).

**Constitution reference:** Article IV.4. **Testable:** yes —
`test_demos_manifest_present_and_lists_four_demos`.

### FR-EX-007: Example tree gates pass standalone

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — running `bash .forge/scripts/verify.sh` from
  inside `examples/forge-fsm-example/` exits 0.
- **MUST** — running `bash .forge/scripts/constitution-linter.sh`
  from inside the example tree exits 0.
- **MUST** — the four reference workflow templates of the
  example (`forge-backend.yml.tmpl`, `forge-frontend.yml.tmpl`,
  `forge-infra.yml.tmpl`, `forge-integration.yml.tmpl`) parse
  as valid GitHub-Actions YAML.
- **SHALL** — `task test` from inside the example tree invokes
  `cargo test --workspace` + `flutter test` and passes on a
  contributor machine with the SDK toolchains installed.

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_example_tree_verify_exits_zero`,
`test_example_tree_constitution_linter_exits_zero`,
`test_example_workflows_parse` (L2, opt-in via
`--require-example-tools`).

### FR-EX-008: NFR baselines for `b1-delivery` measured against the example

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — `b1-delivery`'s NFRs that ship without baseline
  values receive measured baselines anchored in this change :
  `NFR-013` (per-layer workflow ≤ 8 min warm) — pointer to
  `standards/infra/ci-workflows.md` § Performance Baselines ;
  `NFR-014` (integration workflow ≤ 30 min) — same target ;
  `NFR-015` (observability stack ≤ 90 s) —
  `standards/infra/observability-local.md` § Startup
  Baselines ; `NFR-017` (overlay diff ≤ 4 KB) —
  `standards/infra/k8s-overlays.md` § Diff Budget.
- **MUST** — measured baselines are appended as
  `Baseline at archive time of c1-reference-project: ...` lines
  inside the corresponding NFR sections of
  `.forge/specs/full-stack-monorepo.md`. NFR-017 has a
  **measured value** at archive time : 2124 bytes (52 % of
  4096-byte budget). NFR-013 / NFR-014 / NFR-015 baselines are
  populated as `TBD` placeholders pending first observed run.

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_nfr_013_baseline_recorded`, `test_nfr_014_baseline_recorded`,
`test_nfr_015_baseline_recorded`, `test_nfr_017_baseline_recorded`.

### FR-EX-009: Test harness `c1.test.sh`

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — `.forge/scripts/tests/c1.test.sh` exists, is
  executable, sources `_helpers.sh` (no new framework, no
  duplication — same convention as `delivery.test.sh` and
  `g1.test.sh`).
- **MUST** — every Testable FR / NFR from this change has at
  least one corresponding `test_*` function. The harness
  follows the manifest pattern (a `# MANIFEST: test_* —
  FR-XX-NNN` comment block + a meta self-check
  `test_c1_manifest_self_consistency`).
- **MUST** — `bash .forge/scripts/tests/c1.test.sh` exits 0
  when every fixture passes ; non-zero with `[FAIL]
  <test-name>: <reason>` lines on first failure.
- **SHALL** — L1 hermetic by default. L2 (`--require-example-tools`)
  runs the example's own gates. L3 (`--require-external-tools`)
  exercises the reproducibility check (re-runs the scaffolder
  and diffs).

**Constitution reference:** Article I (TDD), Article V.
**Testable:** self-testing — 30/30 scenarios PASS at archive
time of c1.

### FR-EX-010: Spec consolidation at `example-reference.md`

<!-- From change: c1-reference-project (2026-04-30) -->

- **MUST** — at archive time of c1, `.forge/specs/example-reference.md`
  exists (this file). Consolidates the `FR-EX-*` namespace per
  the convention used for `forge-ci.md` (FR-CI-* namespace) at
  archive time of `g1-forge-ci`.
- **MUST** — the spec links back to its archived changes in the
  Archived changes table.
- **SHALL** — opens with the audience-distinction note (this
  file vs `full-stack-monorepo.md`).

**Constitution reference:** Articles III.2, IV. **Testable:** yes
— `test_example_reference_spec_present_post_archive` (gated on
c1's `status: archived`).

---

## Non-Functional Requirements

### NFR-EX-001: Example reproducibility from scratch

- **MUST** — running `bash .forge/scripts/scaffolder/init.sh
  forge-fsm-example --org io.forge.example` on a clean tmpdir
  with `SOURCE_DATE_EPOCH` pinning produces a tree
  byte-equivalent to `examples/forge-fsm-example/` modulo
  per-language SDK output (Flutter / Cargo) and timestamps.
- **SHALL** — the README's `## Reproducing this example` section
  documents the exact commands and SDK versions used.

**Constitution reference:** Article V (deterministic gates),
NFR-005 of `b1-scaffolder`. **Testable:** L3 opt-in via
`--require-external-tools`.

### NFR-EX-002: Example tree byte budget

- **SHOULD** — total committed bytes under
  `examples/forge-fsm-example/` (excluding ignored paths from
  FR-GL-028) MUST be ≤ 5 MB. **Baseline at archive time of c1 :
  ~2.3 MB (46 % of budget).**

**Constitution reference:** Article X. **Testable:** yes —
`test_example_tree_byte_budget`.

### NFR-EX-003: Example CI runtime budget

- **MUST** — the new `example` job in `forge-ci.yml`
  (FR-CI-012) MUST complete in ≤ 4 minutes wall-clock on
  warm cache.
- **SHALL** — cold-cache runs MUST complete in ≤ 8 minutes.

**Constitution reference:** Article X. **Testable:** measured at
first archive cycle ; exceedance opens a follow-up change.

### NFR-EX-004: Demo proposal byte budget

- **SHOULD** — each demo's `proposal.md` is ≤ 200 lines.

**Constitution reference:** Article X.3. **Testable:** yes —
`test_each_demo_proposal_under_size_budget`.

### NFR-EX-005: Demo coverage of audit modules

- **MUST** — collectively, the 4 demos exercise distinct layer
  combinations : single-layer backend (demo-001), single-layer
  frontend (demo-002), multi-layer backend+infra (demo-003),
  multi-layer backend+frontend+protos at status: specified
  (demo-004).

**Constitution reference:** Article III. **Testable:** yes —
`test_demos_cover_distinct_layer_combinations`.

### NFR-EX-006: Backwards compatibility on Forge gates

- **MUST** — adding the skip-guards (FR-GL-026 / FR-GL-027)
  produces byte-identical stdout + same exit code on a Forge
  repo without an `examples/` directory.

**Constitution reference:** Article V (gate stability).
**Testable:** yes — `test_verify_no_skip_when_no_examples_dir`.

---

## Scope

**In scope for the example tree (delivered so far):**

- The fully-scaffolded `examples/forge-fsm-example/` tree
  (FR-EX-001) — **c1-reference-project**.
- Top-tree navigation README + meta-doc README (FR-EX-002,
  FR-EX-003) — **c1-reference-project**.
- 3 archived demo application changes covering single-layer
  backend / frontend and multi-layer backend+infra (FR-EX-004) —
  **c1-reference-project**.
- 1 active demo at `status: specified` (FR-EX-005) —
  **c1-reference-project**.
- Demo manifest at `.forge/changes/MANIFEST.md` (FR-EX-006) —
  **c1-reference-project**.
- Standalone gate compliance for the example tree (FR-EX-007) —
  **c1-reference-project**.
- NFR baseline pointers for `b1-delivery`'s NFR-013/014/015/017
  (FR-EX-008) — **c1-reference-project**.
- Test harness `c1.test.sh` with 30 scenarios (FR-EX-009) —
  **c1-reference-project**.
- This consolidated spec (FR-EX-010) — **c1-reference-project**.

**Deferred to future C-series modules (out of scope for C.1):**

- Walkthrough video / interactive tutorial (audit module C.2).
- Anti-patterns gallery (audit module C.3).
- Comparison matrix with BMAD / SpecKit / Agent OS V3
  (audit module C.4).
- Migration guide from ad-hoc projects (audit module C.5).
- Sibling examples for other archetypes (mobile-only B.4,
  flutter-firebase B.2) — pending those archetypes shipping.
- Public deployment of the example to staging / prod
  Kubernetes — local dev only via `task dev`.
- Real grpc-dart wiring in demo-002 (currently uses a fake
  adapter ; tracked as a c1-followup candidate).
- Runtime BDD step wiring for demo-002's `bdd_widget_test` and
  demo-003's `cucumber-rs` scenarios across a live Kong
  instance — feature files exist for adopter inspection but
  steps are not all runtime-wired.

---

## ADDED Requirements (b7-7-example, archived 2026-06-23)

B.7.7 — the **second reference project** under `examples/`:
`forge-rag-example/`, demonstrating the `ai-native-rag` archetype.
Namespace `FR-RAGEX-001..010` / `NFR-RAGEX-001..005` (distinct from c1's
`FR-EX-*`, which governs the shared example-tree machinery b7-7 reuses).
Covered by `.forge/scripts/tests/b7-7.test.sh` (22 L1 + L2 opt-in via
`--require-example-tools`), registered in `forge-ci.yml`. The archetype
stays **candidate / scaffoldable:false** — committing the example does not
promote it (promotion rides `b7-6-harness`); the tree is rendered via
`overlay.sh` (ADR-B7-7-001), NOT the refusing CLI.

### Functional
- **FR-RAGEX-001** — `examples/forge-rag-example/` exists at the repo root,
  a fully-rendered `ai-native-rag/1.0.0` tree (`overlay.sh` of the
  `b7-2-scaffolder` plan, b7-10-extended) with `backend/{rag,mcp,llm_gateway,
  bin-server}`, `frontend/web-public/` (Qwik), `infra/`, `shared/protos/v1/rag/`,
  its own `.forge/`, `.claude/`, `Taskfile.yml`, `docker-compose.dev.yml`,
  `CLAUDE.md`, `README.md`, `.forge.yaml`, and a `.forge/scaffold-manifest.yaml`
  recording `archetype: ai-native-rag` / `archetype_version: "1.0.0"` /
  `stage: candidate` / `project_name: forge-rag-example`.
- **FR-RAGEX-002/003** — top-of-tree `README.md` (4 canonical H2 sections +
  the "does NOT show" note: candidate, no Flutter, no AI-Act/DORA demo, no
  Pythia demo; demo-003 DOES show streaming) + one appended row in the
  meta-`examples/README.md` (FSM row preserved).
- **FR-RAGEX-004** — 3 archived demos: `demo-001-doc-ingestion` `[backend]`
  (`rag/` pipeline: chunking, `Embedder`, pgvector HNSW upsert, hybrid
  retrieval vector+BM25+RRF, re-rank), `demo-002-mcp-search-tool` `[backend]`
  (rmcp `search` tool, dual transport, schema-validated input),
  `demo-003-rag-query-ui` `[backend, frontend]` (Janus multi-layer, per-layer
  designs/tasks; Qwik streaming UI consuming b7-10's `QueryStream`/`queryStream`,
  XI.5 fallback degrading stream → unary `Query`). Each carries the 5
  artefacts + a `features/<demo>.feature`.
- **FR-RAGEX-005** — the demos materialise Article XI: `embeddings-pipeline`
  (demo-001), IX.6 prompt-audit across the stream (demo-003), XI.5 non-AI
  fallback (demo-001 embedder fallback + demo-003 `fallbackUsed` indicator).
- **FR-RAGEX-006** — `.forge/changes/MANIFEST.md` lists the 3 demos.
- **FR-RAGEX-007** — the RAG tree's own `verify.sh` + `constitution-linter.sh`
  exit 0; archetype/workflow YAML parses (L2 opt-in).
- **FR-RAGEX-008** — `b7-7.test.sh` (manifest pattern, mirrors `c1.test.sh`),
  registered in `forge-ci.yml`'s harness loop after `c1.test.sh`.
- **FR-RAGEX-009** — rendered via `overlay.sh` while candidate; committing it
  keeps `ai-native-rag/1.0.0.yaml` `stage: candidate` / `scaffoldable:false`;
  `forge init --archetype ai-native-rag` still refuses exit 3.
- **FR-RAGEX-010** — this consolidation (additive; FR-EX-* untouched).

### Non-Functional
- **NFR-RAGEX-001** additive (no archetype/schema/standard/CLI edit; existing-file
  edits confined to `forge-ci.yml` + `examples/README.md` + the test-budget
  sync in `c1.test.sh`/`g1.test.sh`) · **002** tree ≤ 5 MB (baseline ~1.6 MB) ·
  **003** `example` CI job stays ≤ 4 min (parse-only, ADR-B7-7-004) · **004**
  each demo proposal ≤ 200 lines · **005** demos cover distinct layer + RAG-surface
  combinations.

### ADRs (ratified — maintainer 2026-06-23; orchestrator independent verification GREEN)
- **ADR-B7-7-001** build now via `overlay.sh` (not gated on b7-6). **ADR-B7-7-002**
  demo-003 is the multi-layer (Janus) demo + hard dep on `b7-10-streaming`
  (b7-7 lands after b7-10). **ADR-B7-7-003** exactly 3 archived demos (no 4th
  `specified`). **ADR-B7-7-004** CI is parse-only / own-gates-only (no `cargo
  build` / `npm` / `buf generate` / network), mirroring c1 ADR-006.

### Downstream
The RAG example is the external-validation sibling of `forge-fsm-example`.
The `ai-native-rag` promotion to `scaffoldable:true` (which makes `forge init`
render this tree directly) rides `b7-6-harness` — the final B.7 brick.

---

## ADDED Requirements (b6-8-example, archived 2026-07-12)

B.6.8 — the **third reference project** under `examples/`:
`forge-eda-example/`, demonstrating the `event-driven-eu` archetype.
Namespace `FR-EDAEX-001..010` / `NFR-EDAEX-001..005` (distinct from c1's
`FR-EX-*` machinery and b7-7's `FR-RAGEX-*`). Covered by
`.forge/scripts/tests/b6-8.test.sh` (23 checks: L1 + L2 opt-in via
`--require-example-tools`), registered in `forge-ci.yml`. Unlike b7-7, the
archetype is **already `stable` / `scaffoldable:true`** (promoted by
`b6-7-harness`), so the tree is rendered by the **real
`forge init --archetype event-driven-eu` CLI** (ADR-B6-8-001), NOT via an
`overlay.sh` workaround — a stronger demonstration of the public adopter flow.

### Functional
- **FR-EDAEX-001** — `examples/forge-eda-example/` exists at the repo root, a
  fully-rendered `event-driven-eu/1.0.0` tree (real `forge init`) with
  `backend/{events,eventstore,saga,bin-server}`, `infra/` (NATS JetStream +
  Postgres event store + Temporal cluster), `shared/asyncapi/` (AsyncAPI 3.1) +
  `shared/protos/v1/events/` (`EventService.Publish` + `ReadStream`), its own
  `.forge/`, `.claude/`, `Taskfile.yml`, `docker-compose.dev.yml`, `CLAUDE.md`,
  `README.md`, `.forge.yaml`, and a `.forge/scaffold-manifest.yaml` recording
  `archetype: event-driven-eu` / `archetype_version: "1.0.0"` /
  `project_name: forge-eda-example`.
- **FR-EDAEX-002/003** — top-of-tree `README.md` (4 canonical H2 sections + the
  "does NOT show" note: no ops-console frontend, no live broker/DB/Temporal
  calls, no compliance demo, no Janus-rule demo) + one appended row in the
  meta-`examples/README.md` (FSM + RAG rows preserved).
- **FR-EDAEX-004** — 3 archived demos: `demo-001-ingestion-http-nats` `[backend]`
  (axum HTTP → NATS JetStream publish, versioned idempotent `EventEnvelope`,
  `Nats-Msg-Id` dedup), `demo-002-projection-readmodel` `[backend]` (Postgres
  event store → deterministic replayable read-model projection, inbox dedup /
  outbox-inbox), `demo-003-order-saga` `[backend, infra]` (Janus multi-layer,
  per-layer designs/tasks; Temporal activity-only 3-step saga with reverse-order
  compensation, Article VIII.2). Each carries the 5 artefacts + a
  `features/<demo>.feature`.
- **FR-EDAEX-005** — the demos materialise the event-driven surfaces: NATS
  JetStream publish + idempotency dedup (demo-001), event-store projection +
  inbox dedup (demo-002), Temporal saga + reverse-order compensation (demo-003).
- **FR-EDAEX-006** — `.forge/changes/MANIFEST.md` lists the 3 demos.
- **FR-EDAEX-007** — the EDA tree's own `verify.sh` + `constitution-linter.sh`
  exit 0; the committed AsyncAPI / infra YAML parses (L2 opt-in).
- **FR-EDAEX-008** — `b6-8.test.sh` (manifest pattern, mirrors `b7-7.test.sh`),
  registered in `forge-ci.yml`'s harness loop after `b7-7.test.sh`.
- **FR-EDAEX-009** — rendered by the real `forge init --archetype
  event-driven-eu` CLI (the archetype is `stable`/`scaffoldable:true` since
  `b6-7-harness`); committing the example keeps the schema + archetype template
  tree byte-unchanged (the example carries its own copies under `examples/`).
- **FR-EDAEX-010** — this consolidation (additive; FR-EX-* + FR-RAGEX-* untouched).

### Non-Functional
- **NFR-EDAEX-001** additive (no archetype/schema/standard/CLI edit; existing-file
  edits confined to `forge-ci.yml` + the four budget-asserting harnesses +
  `forge-self-ci.md` + `examples/README.md` + `docs/new-archetypes-plan.md`) ·
  **002** tree ≤ 5 MB (baseline ~0.9 MB) · **003** `example` CI job stays ≤ 4 min
  (parse-only, ADR-B6-8-004) · **004** each demo proposal ≤ 200 lines · **005**
  demos cover distinct layer + event-surface combinations.

### ADRs
- **ADR-B6-8-001** render through the real `forge init` CLI (the archetype is
  promoted/scaffoldable) — the divergence from b7-7's overlay.sh workaround, and
  a stronger demonstration of the public adopter flow. **ADR-B6-8-002** demo-003
  is the multi-layer (Janus) saga demo spanning `[backend, infra]` (the frontend
  layer is deferred — ADR-B6-1-004). **ADR-B6-8-003** exactly 3 archived demos
  (no 4th `specified`, mirroring b7-7). **ADR-B6-8-004** CI is parse-only /
  own-gates-only for all three trees; `forge-ci.yml` line budget bumped 400→420
  in lockstep across c1/g1/t5-1/t5-otel-live-run + `forge-self-ci.md`.

### Downstream
`forge-eda-example` completes the trio of archetype reference projects
(`full-stack-monorepo` / `ai-native-rag` / `event-driven-eu`). Because it renders
through the real CLI, it doubles as an end-to-end proof that the `b6-7-harness`
promotion made `forge init --archetype event-driven-eu` actually work for adopters.
