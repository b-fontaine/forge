# Specs: b6-8-example

<!-- Audit: B.6.8 (docs/new-archetypes-plan.md §6.1 / §0.13 T7 brick #10).       -->
<!-- Depends on: b6-1-schema + b6-2-scaffolder + b6-3-standards +                 -->
<!--             b6-7-harness (promotion) + c1-reference-project (all archived).  -->
<!-- Format: new FR-EDAEX-* namespace for the EDA example tree, consolidated into -->
<!--         .forge/specs/example-reference.md at archive time (alongside the     -->
<!--         FR-EX-* (c1) + FR-RAGEX-* (b7-7) namespaces). No archetype/schema/    -->
<!--         standard edit. -->

This change ships the **third reference project tree** under `examples/`
— `forge-eda-example/` — demonstrating the `event-driven-eu` archetype,
in a single archive cycle:

1. The fully-rendered `examples/forge-eda-example/` tree (rendered via
   the real `forge init --archetype event-driven-eu` CLI, then committed
   verbatim).
2. Three archived demo application changes
   (`demo-001-ingestion-http-nats`, `demo-002-projection-readmodel`,
   `demo-003-order-saga`).
3. A top-of-tree navigation `README.md` for the EDA example + one
   appended row in the meta-`examples/README.md`.
4. An extension of the existing `example` job in `forge-ci.yml`
   (FR-CI-012) so it also gates `examples/forge-eda-example/`, plus the
   `forge-ci.yml` line-budget bump if the third gate block exceeds the
   current cap.
5. A test harness `b6-8.test.sh` validating the EDA example structure.

## Namespace

- `FR-EDAEX-001..010` — EDA example tree contract (new namespace,
  mirrors b7-7's `FR-RAGEX-*` but scoped to `forge-eda-example/`).
- `NFR-EDAEX-001..005` — EDA example non-functional budgets.
- `ADR-B6-8-001..004` — design decisions (in `design.md`).

The `FR-EDAEX-*` namespace is **new** (distinct from c1's generic
`FR-EX-*` machinery and b7-7's `FR-RAGEX-*`). All three consolidate into
`.forge/specs/example-reference.md` at archive time.

## Format note

This document follows the **delta convention** of Article IV. The target
specs (edited at archive) are:

- `.forge/specs/example-reference.md` (extended with the new
  `FR-EDAEX-*` + `NFR-EDAEX-*` namespace + a new Archived-changes row
  for `b6-8-example`).
- `.forge/specs/forge-ci.md` (MODIFIED `FR-CI-012` — the `example` job
  now gates **three** trees, not two; + the line-budget bump note).

No edit to `.forge/specs/event-driven-eu.md` (the archetype contract),
`.forge/schemas/event-driven-eu/1.0.0.yaml`, the `global/*.md` /
`infra/*.md` standards, or any CLI code — the example **uses** the
archetype, it does not redefine it (NFR-EDAEX-001).

---

## ADDED Requirements

### FR-EDAEX-001: EDA example tree exists at canonical path

<!-- New in b6-8-example (2026-07-12) -->

- **MUST** — directory `examples/forge-eda-example/` exists at the Forge
  repo root and is a fully-rendered `event-driven-eu/1.0.0` project,
  produced by running `forge init --archetype event-driven-eu` (the
  promoted, scaffoldable public CLI path — ADR-B6-8-001), then committed
  verbatim.
- **MUST** — the tree contains the archetype's canonical structure:
  `backend/` (Rust workspace with `events/`, `eventstore/`, `saga/`,
  `bin-server/`), `infra/` (NATS JetStream + Postgres event store +
  Temporal cluster Helm/compose), `shared/asyncapi/` (AsyncAPI 3.1) and
  `shared/protos/v1/events/` (the seed `events.proto` with
  `EventService.Publish` + `ReadStream`).
- **MUST** — the tree contains its own `.forge/`, `.claude/`,
  `Taskfile.yml`, `docker-compose.dev.yml`, `.gitignore`, root
  `CLAUDE.md`, `README.md`, and `.forge.yaml` declaring
  `schema: event-driven-eu`.
- **MUST** — `.forge/scaffold-manifest.yaml` is committed and records
  `archetype: event-driven-eu`, `archetype_version: "1.0.0"`,
  `scaffold_plan_sha`, `template_set_sha`, `scaffold_date`,
  `project_name: forge-eda-example`, `reverse_domain`, `root_module`.

**Constitution reference:** Articles III.2, V, VII, VIII.
**Testable:** yes — `test_eda_example_tree_canonical_structure`
+ `test_eda_example_scaffold_manifest_complete` in
`.forge/scripts/tests/b6-8.test.sh`.

### FR-EDAEX-002: Top-of-tree navigation README

<!-- New in b6-8-example (2026-07-12) -->

- **MUST** — `examples/forge-eda-example/README.md` exists and contains
  the four canonical H2 sections (same contract as FR-EX-002):
  `## How this example was built`, `## What's in here`,
  `## Demo changes`, `## Reproducing this example`.
- **MUST** — `## How this example was built` documents that the tree was
  rendered via the real `forge init --archetype event-driven-eu` CLI
  (the archetype is `stable` / `scaffoldable: true`, promoted by
  `b6-7-harness`), so an adopter can reproduce it with the exact same
  command.
- **MUST** — `## Demo changes` enumerates the 3 demos, each with a
  one-sentence summary and a relative link to its change directory.
- **MUST** — a `## What this example does NOT show` note (or equivalent)
  records the known gaps: no ops-console frontend (the `frontend` layer
  is deferred — ADR-B6-1-004), no live NATS/Temporal/Postgres calls, no
  compliance demo (→ b6-9-compliance).
- **SHALL** — `## What's in here` provides a callout per layer
  (backend `events`/`eventstore`/`saga`, infra, shared asyncapi/protos)
  with a pointer to the governing standard (`event-driven.md`,
  `asyncapi-contracts.md`, `nats-jetstream.md`).

**Constitution reference:** Articles X.3, III.2.
**Testable:** yes — `test_eda_example_readme_has_required_sections`.

### FR-EDAEX-003: Meta-`examples/README.md` lists the EDA example

<!-- New in b6-8-example (2026-07-12) -->

- **MUST** — `examples/README.md` (which already exists from c1,
  FR-EX-003) gains a third row in its "Available examples" table:
  `forge-eda-example` | `event-driven-eu` | last-updated date | short
  description.
- **MUST** — b6-8 does NOT re-create `examples/README.md`; it appends
  one table row (the file was designed for multiple examples). The
  `forge-fsm-example` + `forge-rag-example` rows stay untouched.

**Constitution reference:** Article X.3. **Testable:** yes —
`test_examples_meta_readme_lists_eda_example`.

### FR-EDAEX-004: Three archived demo application changes

<!-- New in b6-8-example (2026-07-12) -->

- **MUST** — under `examples/forge-eda-example/.forge/changes/`, three
  demo changes exist with `status: archived`:
  `demo-001-ingestion-http-nats`, `demo-002-projection-readmodel`,
  `demo-003-order-saga`.
- **MUST** — each archived demo's `.forge.yaml` declares
  `status: archived`, a complete `timeline:` block (every phase
  populated), and `parent_audit_items: [B.6.8]`.
- **MUST** — each archived demo contains the canonical 5 artefacts:
  `proposal.md`, `specs.md` (delta format), `design.md` (single-layer)
  or per-layer `designs/design-<layer>.md` (multi-layer per FR-GL-016),
  `tasks.md` (single-layer) or per-layer `tasks/tasks-<layer>.md`
  (multi-layer), and a `features/<demo>.feature` with realistic Gherkin.
- **MUST** — `demo-001-ingestion-http-nats` is **single-layer backend**
  (`layers: [backend]`) — axum HTTP ingestion → idempotent, versioned
  `EventEnvelope` → publish to NATS JetStream (`Nats-Msg-Id` dedup) with
  cucumber-rs BDD.
- **MUST** — `demo-002-projection-readmodel` is **single-layer backend**
  (`layers: [backend]`) — fold the persisted event stream into a
  deterministic, replayable read-model projection, guarded by the inbox
  dedup (outbox/inbox pattern).
- **MUST** — `demo-003-order-saga` is **multi-layer backend + infra**
  (`layers: [backend, infra]`) — triggers the Janus orchestrator (≥ 2
  layers per FR-GL-015), ships per-layer `designs/` and `tasks/` per
  FR-GL-016; a Temporal **activity-only** 3-step saga (reserve stock →
  charge payment → confirm shipment) with reverse-order compensation.
- **MUST** — demo-003 demonstrates Article VIII.2: the durable
  orchestration is Temporal (activity-only; the native SDK is behind the
  OFF-by-default `temporal-sdk` feature), and the in-process saga
  coordinator is the unit-testable compensation-ordering core — NO
  ad-hoc saga logic in application code.

**Constitution reference:** Articles I, II, III, IV, V, VII, VIII.2.
**Testable:** yes — `test_eda_demos_count_and_status`,
`test_each_eda_demo_has_five_artefacts`,
`test_eda_demo_003_is_multi_layer`.

### FR-EDAEX-005: Demos materialise the event-driven surfaces

<!-- New in b6-8-example (2026-07-12) -->

- **MUST** — collectively the 3 demos demonstrate the archetype's
  event-driven surfaces: NATS JetStream publish with idempotency-key
  dedup (demo-001), the Postgres event store + read-model projection +
  inbox dedup / outbox-inbox pattern (demo-002), and the Temporal
  activity-only saga with reverse-order compensation (demo-003).
- **MUST** — demo-001's `specs.md` declares event versioning +
  idempotency keys (`Nats-Msg-Id`) as explicit requirements.
- **SHALL** — at least one demo's design references the archetype's
  EU-sovereignty posture (`event-driven.md` — sovereign brokers
  NATS/Redpanda; no US-managed Kafka SaaS).

**Constitution reference:** Articles IV.4, VII, VIII.2.
**Testable:** yes — `test_eda_demos_cover_event_surfaces`
(grep-based: jetstream/idempotency/projection/saga/compensation markers
present across the demo specs).

### FR-EDAEX-006: Demo discoverability via manifest

<!-- New in b6-8-example (2026-07-12) -->

- **MUST** — `examples/forge-eda-example/.forge/changes/MANIFEST.md`
  enumerates every demo with three columns: demo id, status,
  one-sentence summary.
- **SHOULD** — the manifest lists demos in archive order (chronological).

**Constitution reference:** Article IV.4. **Testable:** yes —
`test_eda_demos_manifest_present_and_lists_three_demos`.

### FR-EDAEX-007: EDA example tree gates pass standalone

<!-- New in b6-8-example (2026-07-12) -->

- **MUST** — running `bash .forge/scripts/verify.sh` from inside
  `examples/forge-eda-example/` exits 0.
- **MUST** — running `bash .forge/scripts/constitution-linter.sh` from
  inside the EDA example tree exits 0.
- **MUST** — the EDA tree's committed YAML (AsyncAPI, buf config, infra,
  CI workflows) parses as valid YAML where present.
- **SHALL** — `task test` from inside the EDA tree invokes the backend
  `cargo test --workspace` and passes on a contributor machine with the
  Rust toolchain installed (L2, opt-in).

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_eda_example_tree_verify_exits_zero`,
`test_eda_example_tree_constitution_linter_exits_zero` (L2, opt-in via
`--require-example-tools`).

### FR-EDAEX-008: Test harness `b6-8.test.sh`

<!-- New in b6-8-example (2026-07-12) -->

- **MUST** — `.forge/scripts/tests/b6-8.test.sh` exists, is executable,
  sources `_helpers.sh` (no new framework — same convention as
  `b7-7.test.sh`).
- **MUST** — every Testable FR / NFR from this change has at least one
  corresponding `test_*` function. The harness follows the manifest
  pattern (a `# MANIFEST: test_* — FR-EDAEX-NNN` comment block + a meta
  self-check `test_b6_8_manifest_self_consistency`).
- **MUST** — `bash .forge/scripts/tests/b6-8.test.sh` exits 0 when every
  fixture passes; non-zero with `[FAIL] <test-name>: <reason>` on first
  failure.
- **MUST** — `b6-8.test.sh` is registered in `forge-ci.yml`'s harness
  loop as a one-line entry.
- **SHALL** — L1 hermetic by default; L2 (`--require-example-tools`)
  runs the EDA tree's own gates.

**Constitution reference:** Articles I, V. **Testable:** self-testing —
the manifest self-consistency check.

### FR-EDAEX-009: Example renders via the real CLI (archetype is scaffoldable)

<!-- New in b6-8-example (2026-07-12) -->

- **MUST** — the EDA example is generated by running
  `forge init --archetype event-driven-eu` (the promoted CLI path —
  `event-driven-eu/1.0.0.yaml` is `stage: stable` / `scaffoldable: true`
  since `b6-7-harness`), NOT via a `overlay.sh` workaround. This is the
  divergence from b7-7-example's ADR-B7-7-001, and a stronger
  demonstration (it proves the public adopter flow).
- **MUST** — committing this example MUST NOT modify the archetype:
  `.forge/schemas/event-driven-eu/1.0.0.yaml`, the archetype template
  tree, and the CLI stay byte-unchanged by b6-8's diff scope.
- **SHALL** — the example's README documents the exact `forge init`
  reproduction command so adopters can regenerate the tree.

**Constitution reference:** Articles III.4, V. **Testable:** yes —
`test_eda_archetype_still_stable_scaffoldable` (asserts the schema is
`stable`/`scaffoldable:true` and unchanged),
`test_b6_8_no_archetype_or_schema_edit`,
`test_cli_scaffolds_eda_init` (L2 opt-in — asserts `forge init`
renders, exit 0).

### FR-EDAEX-010: Spec consolidation into `example-reference.md`

<!-- New in b6-8-example (2026-07-12) -->

- **MUST** — at archive time of b6-8, `.forge/specs/example-reference.md`
  gains the `FR-EDAEX-*` + `NFR-EDAEX-*` namespace section and a new row
  in its `## Archived changes` table linking to
  `.forge/changes/b6-8-example/`.
- **MUST** — the consolidation is **additive**: the existing `FR-EX-*`
  (c1) + `FR-RAGEX-*` (b7-7) content is untouched.

**Constitution reference:** Articles III.2, IV. **Testable:** yes —
`test_example_reference_spec_has_edaex_section_post_archive`
(archive-gated on b6-8's `status: archived`).

---

## MODIFIED Requirements

### MODIFIED FR-CI-012: `example` job gates ALL THREE example trees

<!-- Modified by b6-8-example (2026-07-12). Original from c1; extended by b7-7. -->

- **WAS** (b7-7): the `example` job, on PRs touching `examples/**`, runs
  the FSM tree's gates + parse, then the RAG tree's gates + parse.
- **NOW**: the `example` job keeps its `examples/**` paths-filter (which
  already covers `examples/forge-eda-example/**`) and gains a **third**
  per-tree gate block: `cd examples/forge-eda-example && verify.sh +
  constitution-linter.sh` + a structural YAML parse of the EDA tree's
  committed YAML (AsyncAPI / infra) where present. The FSM + RAG blocks
  are unchanged.
- **MUST** — the edit is **additive**: the FSM + RAG gate steps and the
  summary aggregation (`needs: [...example]`, the skip-as-success rule)
  are byte-preserved; only new EDA-gate steps are inserted.
- **MUST** — all three trees gate under the same `examples/**` filter; a
  PR touching only one tree still runs all gates (cheap; parse-only).
- **MUST** — if the third gate block pushes `forge-ci.yml` past its
  current ≤ 400-line budget (NFR-CI-002), the cap is bumped in lockstep
  across the four asserting harnesses (`c1`, `g1`, `t5-1`,
  `t5-otel-live-run`) + the `forge-self-ci.md` standard, in the SAME
  commit.

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_forge_ci_example_job_gates_eda_tree`,
`test_forge_ci_example_job_fsm_rag_blocks_preserved`,
`test_forge_ci_harness_loop_has_b6_8`,
`test_forge_ci_line_budget_holds`.

---

## Non-Functional Requirements

### NFR-EDAEX-001: Additive — no archetype/schema/standard/CLI edit

- **MUST** — b6-8 edits NO archetype template, NO
  `event-driven-eu/1.0.0.yaml` schema, NO `global/*.md` / `infra/*.md`
  standard, and NO CLI code. Existing-file edits are confined to:
  `forge-ci.yml` (the `example` job extension + one harness-loop entry +
  the line-budget bump), the four budget-asserting harnesses +
  `forge-self-ci.md` (the lockstep bump), `examples/README.md` (one
  appended row), `docs/new-archetypes-plan.md` (mark B.6.8 done), and
  `.forge/specs/example-reference.md` + `.forge/specs/forge-ci.md` (at
  archive, additive deltas).

**Constitution reference:** Article IV. **Testable:** yes —
`test_b6_8_no_archetype_or_schema_edit` (asserts the schema +
template tree are byte-unchanged by this change's diff scope).

### NFR-EDAEX-002: EDA example tree byte budget

- **SHOULD** — total committed bytes under
  `examples/forge-eda-example/` (excluding ignored paths from FR-GL-028)
  MUST be ≤ 5 MB (mirrors NFR-EX-002 / NFR-RAGEX-002). The baseline is
  recorded at archive time.

**Constitution reference:** Article X. **Testable:** yes —
`test_eda_example_tree_byte_budget`.

### NFR-EDAEX-003: `example` CI job runtime budget unchanged

- **MUST** — adding the EDA gate block to the `example` job MUST NOT
  push the job's warm-cache runtime above NFR-EX-003's ≤ 4 min budget
  (all three trees are parse-only / own-gates-only; no Docker, no build).

**Constitution reference:** Article X. **Testable:** measured at first
archive cycle (mirrors NFR-EX-003).

### NFR-EDAEX-004: Demo proposal byte budget

- **SHOULD** — each demo's `proposal.md` is ≤ 200 lines (mirrors
  NFR-EX-004 / NFR-RAGEX-004).

**Constitution reference:** Article X.3. **Testable:** yes —
`test_each_eda_demo_proposal_under_size_budget`.

### NFR-EDAEX-005: Demos cover distinct layer + event-surface combinations

- **MUST** — the 3 demos cover distinct layer combinations and distinct
  event surfaces: single-layer backend NATS ingestion (demo-001),
  single-layer backend event-store projection (demo-002), multi-layer
  backend+infra Temporal saga (demo-003).

**Constitution reference:** Article III. **Testable:** yes —
`test_eda_demos_cover_distinct_combinations`.

---

## Acceptance Criteria (Gherkin)

### AC-EDAEX-001: EDA example tree is inspectable

```gherkin
Given the Forge repo with the promoted event-driven-eu archetype
When a contributor browses examples/forge-eda-example/
Then they find a fully-rendered event-driven project (backend
  events/eventstore/saga/bin-server, infra, shared asyncapi/protos)
  with a scaffold-manifest declaring archetype event-driven-eu version 1.0.0
And the framework's own verify.sh skips the example tree (FR-GL-026 reused)
```

### AC-EDAEX-002: Three EDA demos demonstrate the event backbone

```gherkin
Given examples/forge-eda-example/.forge/changes/
When a contributor reads the demos in archive order
Then demo-001-ingestion-http-nats shows HTTP → NATS JetStream publish (single-layer backend)
And demo-002-projection-readmodel shows event store → read model (single-layer backend)
And demo-003-order-saga shows a Temporal 3-step saga with compensation (multi-layer backend+infra, Janus)
And each demo carries proposal + specs + design + tasks + a feature file
```

### AC-EDAEX-003: Event-driven surfaces are materialised

```gherkin
Given the three EDA demos
When a contributor inspects their specs and designs
Then NATS JetStream publish with idempotency-key dedup is exercised (demo-001)
And the Postgres event store + read-model projection + inbox dedup is exercised (demo-002)
And the Temporal activity-only saga with reverse-order compensation is exercised (demo-003)
```

### AC-EDAEX-004: CI gates the EDA tree without modifying the archetype

```gherkin
Given a PR touching examples/forge-eda-example/**
When forge-ci.yml runs
Then the example job runs the EDA tree's own verify.sh + constitution-linter.sh
And the FSM + RAG gate blocks are preserved unchanged
And the event-driven-eu schema is still stage stable / scaffoldable true and byte-unchanged
And forge-ci.yml stays within its line budget
```

---

## Scope

**In scope (delivered by b6-8-example):**

- The fully-rendered `examples/forge-eda-example/` tree (FR-EDAEX-001).
- Top-tree navigation README + meta-README row (FR-EDAEX-002, 003).
- 3 archived demo changes covering the NATS/event-store backend surfaces
  and the multi-layer saga surface (FR-EDAEX-004, 005).
- Demo manifest (FR-EDAEX-006).
- Standalone gate compliance for the EDA tree (FR-EDAEX-007).
- Test harness `b6-8.test.sh` (FR-EDAEX-008).
- Real-CLI rendering (FR-EDAEX-009).
- Spec consolidation into `example-reference.md` (FR-EDAEX-010).
- The `example` CI job extension + line-budget bump (MODIFIED FR-CI-012).

**Deferred (out of scope for b6-8):**

- An ops-console frontend demo (the `frontend` layer is deferred —
  ADR-B6-1-004; the multi-layer demo spans `[backend, infra]`).
- A 4th `specified`-only demo (Q-3 → future followup).
- A compliance demo (NIS2/DORA/SBOM — `b6-9-compliance`, archived).
- A Janus-rule refusal demo (`b6-10-janus-rule`, archived).
