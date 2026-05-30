# Tasks: b8-3-schema-candidate

<!-- Status: planned -->
<!-- Schema: default -->
<!-- Audit: B.8.3 (docs/new-archetypes-plan.md §4.2 — flagship 1.0.0 → 2.0.0, 2.0.0 candidate schema) -->

TDD order mandatory (Article I). The harness (`b8-3.test.sh`) is authored and
confirmed RED before `2.0.0.yaml` exists; then `2.0.0.yaml` is authored to turn
it GREEN. The frozen `schema.yaml` (1.0.0) is NEVER modified.

## Phase 1: Harness RED

- [ ] **T001** — Scaffold `.forge/scripts/tests/b8-3.test.sh` from the b8-2 frame: `--level` flag, `_helpers.sh` sourcing, standard pass/fail summary, non-zero exit on failure. Define `SCHEMA_20` and `SCHEMA_10` path variables. [Story: FR-B8-3-001, ADR-B8-3-001]
- [ ] **T002** — Write L1 RED T-001: assert `2.0.0.yaml` exists at `$SCHEMA_20`. [Story: FR-B8-3-001/002] [P]
- [ ] **T003** — Write L1 RED T-002: assert file parses as valid YAML mapping root (`python3 yaml.safe_load`). [Story: FR-B8-3-001/002] [P]
- [ ] **T004** — Write L1 RED T-003/T-004/T-005: assert `name == 'full-stack-monorepo'`, `version == '2.0.0'`, `stage == 'candidate'`. [Story: FR-B8-3-002] [P]
- [ ] **T005** — Write L1 RED T-006: assert `d.get('scaffoldable') is False`. [Story: FR-B8-3-041, ADR-B8-3-003/005] [P]
- [ ] **T006** — Write L1 RED T-007: assert `tdd_enforced: true`, `bdd_required_for_user_facing: true`, `coverage_threshold: 80`. [Story: FR-B8-3-003] [P]
- [ ] **T007** — Write L1 RED T-008: assert `layers[]` ids contain `{'backend', 'frontend', 'infra'}` (set check). [Story: FR-B8-3-020] [P]
- [ ] **T008** — Write L1 RED T-009: assert `frontend` layer has `surfaces:` with ids `web-public` and `web-backoffice` (nested key traversal). [Story: FR-B8-3-021, ADR-B8-3-004] [P]
- [ ] **T009** — Write L1 RED T-010: assert every `components[]` entry has a `name` field. [Story: FR-B8-3-010/011] [P]
- [ ] **T010** — Write L1 RED T-011: for each component with a `standard:` field, assert `$FORGE_ROOT/.forge/standards/$ref` exists on disk. [Story: FR-B8-3-011, ADR-B8-3-002] [P]
- [ ] **T011** — Write L1 RED T-012: for each component dict assert `set(c.keys()) & {'version', 'pin', 'image'} == set()` (exact key-set; `pin_source` is NOT in the forbidden set and is allowed). [Story: FR-B8-3-012, ADR-B8-3-002] [P]
- [ ] **T012** — Write L1 RED T-013: assert `len(d.get('migration_deltas', [])) > 0`. [Story: FR-B8-3-030] [P]
- [ ] **T013** — Write L1 RED T-014: assert `$SCHEMA_10` (`schema.yaml`) exists AND its `version` field equals `"1.0.0"` (re-parse via `yaml.safe_load`). [Story: FR-B8-3-004, NFR-B8-3-003] [P]
- [ ] **T014** — Write L1 RED T-015: `yaml.safe_load` value-walk over each component dict scalar values; assert no value matches `^\d+\.\d+` (NOT a textual grep — avoids false-positive on YAML comments embedding `kong:3.6`, `v1.2.0`, etc.). [Story: NFR-B8-3-001] [P]
- [ ] **T015** — Write L1 RED T-016: locate `postgres-17-pgvector` component; assert `'migration_note' in component`; assert `any(delta['from'].startswith('postgres-16') for delta in d['migration_deltas'])`. [Story: FR-B8-3-013] [P]
- [ ] **T016** — Write L1 RED T-017: assert `d.get('bump_at') == 'B.8.14'`. [Story: FR-B8-3-031] [P]
- [ ] **T017** — Run `b8-3.test.sh --level 1` → confirm all 17 assertions fail / error (no `2.0.0.yaml` exists yet). Record RED witness (exit code, failing test names). [Story: Article I — verify RED]

## Phase 2: Author `2.0.0.yaml` to GREEN

- [ ] **T018** — Author `.forge/schemas/full-stack-monorepo/2.0.0.yaml` header block: audit comment, `# CONSTITUTIONAL PROHIBITION (Articles VIII.1 + VIII.2 — IN FORCE)` note (both SHALL clauses remain binding until B.8.14 GOVERNANCE.md Amendment Process completes; scaffolding/deploying the candidate before that amendment is a constitutional violation), stage-semantics block (candidate = non-scaffoldable, promoted at B.8.14 after B.8.12 zero-regression), on-disk coexistence note (ADR-B8-3-001), component-references note (ADR-B8-3-002). [Story: FR-B8-3-005, ADR-B8-3-003]
- [ ] **T019** — Author identity + flag fields: `name: full-stack-monorepo`, `version: "2.0.0"`, `stage: candidate`, `scaffoldable: false`, `tdd_enforced: true`, `bdd_required_for_user_facing: true`, `coverage_threshold: 80`, `description:` (2.0.0 summary per design). [Story: FR-B8-3-002/003, ADR-B8-3-005]
- [ ] **T020** — Author `components:` block (6 entries, reference-only — NO inline version pins): `envoy-gateway` (`pin_source: B.8.4`, no `standard:` field — no `*.yaml` standard owns a gateway pin today, ADR-B8-3-002); `dbos-embedded` (`standard: orchestration.yaml`); `connect-rpc` (`standard: transport.yaml`); `zitadel` (`standard: identity.yaml`); `postgres-17-pgvector` (`standard: persistence.yaml`, `migration_note: CROSSING DELTA…`); `signoz-obi-coroot` (`standard: observability.yaml`). [Story: FR-B8-3-010/011/012/013, ADR-B8-3-002]
- [ ] **T021** — Author `migration_deltas:` block (6 deltas: `kong-gateway→envoy-gateway` B.8.4, `temporal-intent→dbos-embedded` B.8.5 with "documented intent not live system" note, `rest-bridge→connect-rpc` B.8.6, `implicit-auth→zitadel` B.8.7, `postgres-16-no-pgvector→postgres-17-pgvector` B.8.5 with pgvector note, `no-web-public-layer→qwik-web-public` B.8.9) and `bump_at: B.8.14`. [Story: FR-B8-3-030/031/032, ADR-B8-3-002]
- [ ] **T022** — Author `layers:` block: `backend` (Vulcan, `[rust, all]`), `frontend` (Hera, `[flutter, all]`, `surfaces: [{id: web-backoffice, path: web-backoffice/, stack: flutter-web}, {id: web-public, path: web-public/, stack: qwik}]`), `infra` (Atlas, `[infra, all]`). `fr_id_prefix_cross_layer: FR-GL-`. [Story: FR-B8-3-020/021/022, ADR-B8-3-004]
- [ ] **T023** — Author `cross_layer:` block (`agent: Janus`, `triggers: [{layers_count_ge: 2}]`, `delivered_by: b1-workflow`) and `phases:` block (7 phases: proposal→specs→design→tasks→implementation→review→archive, unchanged shape from 1.0.0). [Story: FR-B8-3-001/022]
- [ ] **T024** — Run `b8-3.test.sh --level 1` → confirm all 17 assertions pass (GREEN). Record GREEN witness. [Story: Article I — verify GREEN]

## Phase 3: Freeze Verification

- [ ] **T025** — Scope guard: run `git diff --name-only -- .forge/schemas/` → MUST show ONLY `2.0.0.yaml` added; `schema.yaml` MUST NOT appear in the diff. [Story: FR-B8-3-004, NFR-B8-3-002/003]
- [ ] **T026** — Backward-compat guard: run `validate-foundations.sh` (FR-GL-001) and `verify.sh` → both MUST stay GREEN (they read `schema.yaml` by literal filename; adding `2.0.0.yaml` is invisible to them). Run `constitution-linter.sh` → OVERALL PASS. [Story: NFR-B8-3-004, ADR-B8-3-001]

## Phase 4: Integration

- [ ] **T027** — Register `b8-3.test.sh` in `.github/workflows/forge-ci.yml` harness job, after the `b8-2.test.sh` step. Verify total line count ≤ 300 (3-comment compression per ADR-T533-002 if needed). NOTE: `forge-ci.yml` is the only file edited outside the change dir and `.forge/schemas/` in this change. [Story: NFR-CI-002, NFR-B8-3-002]
- [ ] **T028** — Add `[Unreleased]` CHANGELOG entry citing `b8-3-schema-candidate` + B.8.3 (grep whole file per changelog-test lesson, not section-only). [Story: FR-B8-3, NFR-B8-3-002]

## Phase 5: REFACTOR

- [ ] **T029** — Tighten `b8-3.test.sh` error messages: each failing assertion emits the test ID (e.g. `FAIL T-006: scaffoldable != false`) and the actual value. Confirm ≤ 5 s wall-clock on a laptop. No logic change — behaviour unchanged. [Story: NFR-B8-2-001 precedent, Article I REFACTOR]
- [ ] **T030** — Final `b8-3.test.sh --level 1` run after refactor → 17/17 GREEN, ≤ 5 s. [Story: NFR-B8-3 performance budget]

## Phase 6: Quality & Verification

- [ ] **T031** — Perf: `b8-3.test.sh --level 1` timed (`time`) → assert ≤ 5 s. [Story: NFR-B8-3 performance] [P]
- [ ] **T032** — Scope: `git diff --name-only` → confirms only: `b8-3-schema-candidate/` change dir + `.forge/schemas/full-stack-monorepo/2.0.0.yaml` (new) + `.forge/scripts/tests/b8-3.test.sh` (new) + `.github/workflows/forge-ci.yml` (amended) + CHANGELOG. No `.forge/standards/**`, `.forge/templates/**`, `schema.yaml`. [Story: NFR-B8-3-002/003] [P]
- [ ] **T033** — Constitutional check: confirm `2.0.0.yaml` carries `scaffoldable: false` + the VIII.1+VIII.2 prohibition header (no live stack touched, no Kong/Temporal removed — no VIII.1/VIII.2 violation at B.8.3 itself). [Story: Articles VIII.1/VIII.2 in-force check, ADR-B8-3-003]
- [ ] **T034** — Independent reviewer gate (SEPARATE context — not the author; no transcript trust): reviewer re-runs `b8-3.test.sh --level 1`; re-reads `2.0.0.yaml` against design.md field-by-field; confirms `schema.yaml` version still `"1.0.0"` and byte-unchanged; confirms all 6 `standard:` references resolve to existing files; confirms `scaffoldable: false` present; confirms VIII.1+VIII.2 prohibition note in header; confirms no inline version pin in any component dict; confirms RED witness recorded. [Story: Author/Reviewer separation — t5-2 lesson]

## Constitutional Compliance Gate (per task)

Phase 1 precedes Phase 2 (TDD RED before GREEN — Article I). Every task carries
an FR/NFR/ADR story. `2.0.0.yaml` is a candidate spec with `scaffoldable: false`
and an explicit VIII.1+VIII.2 prohibition header — no live Kong or Temporal
component is removed; no Article VIII violation occurs at B.8.3.
`schema.yaml` (1.0.0) is never modified (NFR-B8-3-002/003). `forge-ci.yml` is
the only file outside the change dir + schemas dir that is edited (T027, noted).

No `[TASK VIOLATION]`. Gate PASS.
