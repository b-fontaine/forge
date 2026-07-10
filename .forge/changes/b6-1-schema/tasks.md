# Tasks: b6-1-schema

<!-- Status: archived -->
<!-- Schema: default -->
<!-- Audit: B.6.1 (docs/new-archetypes-plan.md §6.1 — event-driven-eu/1.0.0 archetype scaffold schema) -->

TDD-ordered (Article I — RED before GREEN, always). The deliverable is one
declarative schema file + its dedicated harness. Per design.md the harness is
authored FIRST and must fail (no schema file) before the schema is written.

## Phase 1: RED — failing harness

- [x] **T1.1** Author `.forge/scripts/tests/b6-1.test.sh` (bash + Python3 inline
  PyYAML, mirroring `b7-1.test.sh`; `--level 1` L1 hermetic). Assertions: schema
  file exists at `.forge/schemas/event-driven-eu/1.0.0.yaml`; `name: event-driven-eu`
  / `version: "1.0.0"` / `stage: candidate` / `scaffoldable: false`; tdd/bdd/coverage
  flags; layers ⊇ {backend,frontend,infra} each with id/path/fr_id_prefix/primary_agent;
  inlined `phases` include `event-design` + `saga-orchestration`; `event_specifics`
  block present (event_versioning/idempotency_keys/saga_compensation); components
  reference-only (no forbidden pin key, no inline `\d+\.\d+` value) and
  `nats-jetstream`/`asyncapi`/`event-patterns` carry `delivered_by: B.6.3`;
  cross_layer.agent Janus + fr_id_prefix_cross_layer FR-GL-; header block documents
  candidate/promotion/additive. [Story: FR-B6-1-001..032, NFR-B6-1-004]
- [x] **T1.2** Run `bash .forge/scripts/tests/b6-1.test.sh --level 1` → **verify
  RED** (schema absent ⇒ content asserts fail-loud). Capture RED evidence.
  [Gate: Article I]

## Phase 2: GREEN — author the schema file

- [x] **T2.1** Create `.forge/schemas/event-driven-eu/1.0.0.yaml` with the candidate
  header block + identity fields (name/version/stage/scaffoldable). [Story:
  FR-B6-1-002/003/005]
- [x] **T2.2** Add tdd/bdd/coverage flags + description. [Story: FR-B6-1-004] [P]
- [x] **T2.3** Add `layers` triple (backend→Vulcan, frontend→Hera with deferred
  ops-console surface, infra→Atlas) + `fr_id_prefix_cross_layer: FR-GL-` +
  `cross_layer.agent: Janus`. [Story: FR-B6-1-010..013, ADR-B6-1-004] [P]
- [x] **T2.4** Add the **inlined** `phases` (proposal → specs → `event-design` →
  features → design → `saga-orchestration` → tasks → implementation → review →
  archive) + `extends: tdd-rust` documentary key + `event_specifics` + `rust_specifics`
  (temporal activity-only bias). [Story: FR-B6-1-020..024, ADR-B6-1-001] [P]
- [x] **T2.5** Add `components` reference-only (existing standards by filename +
  nats-jetstream/asyncapi/event-patterns `delivered_by: B.6.3`, NO inline pin).
  [Story: FR-B6-1-030..032, ADR-B6-1-003] [P]
- [x] **T2.6** Run `b6-1.test.sh --level 1` → **verify GREEN**. [Gate: Article I]

## Phase 3: Integration

- [x] **T3.1** Run `bash .forge/scripts/validate-foundations.sh` → confirm
  `FR-GL-001-versioned:event-driven-eu/1.0.0.yaml` **PASS**. [Story: NFR-B6-1-003]
- [x] **T3.2** Confirm `forge init <name> --archetype event-driven-eu --org <rd>`
  refuses cleanly (exit 2 — unknown archetype, dispatch-table-gated; exit 3 once
  B.6.2 registers it). [Story: NFR-B6-1-002]
- [x] **T3.3** Register `b6-1.test.sh` in `.github/workflows/forge-ci.yml` matrix.
  [Story: NFR-B6-1-004]

## Phase 4: Quality

- [x] **T4.1** Run `verify.sh` + `constitution-linter.sh` → **no regression**.
  [Story: NFR-B6-1-003]
- [x] **T4.2** `git diff --name-only` → only NEW files. [Story: NFR-B6-1-001]
- [x] **T4.3** REFACTOR: tidy header comments / section anchors; re-run full
  `b6-1.test.sh` + `validate-foundations.sh` → still GREEN. [Gate: behavior unchanged]

## Constitution Gate (per task) — summary
- TDD order enforced: harness RED (T1.2) precedes schema GREEN (T2.6). ✓
- No spec bypass: every task cites its FR/NFR/ADR. ✓
- Architecture: additive config schema, no Flutter/Rust/infra code; §VIII consumed
  as-is; VIII.2 materialised by the saga-orchestration phase. ✓
- **No [TASK VIOLATION].**

## Follow-up left open (later B.6 bricks — NOT this change)
- Dispatch registration + templates + real scaffolder → B.6.2.
- nats-jetstream / event-driven / asyncapi-contracts standards → B.6.3.
- Promotion candidate→stable/scaffoldable + ≥35-test snapshot harness → B.6.7.
