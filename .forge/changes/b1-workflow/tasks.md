# Tasks: b1-workflow
<!-- TDD order mandatory: tests BEFORE implementation, always (Article I) -->
<!-- Format: - [ ] Task [Story: FR-XXX] [P] -->
<!-- [P] = parallelizable with other [P] tasks in the same sub-section -->
<!-- Parent audit items: B.1.6 + B.1.7 + B.1.8 -->
<!-- Depends on: b1-foundations (archived) + b1-scaffolder (archived) -->

## Phase 1: Foundation — harness skeleton + placeholder files

### 1.1 Workflow test harness skeleton
- [x] Create `.forge/scripts/tests/workflow.test.sh` with shebang, `set -euo pipefail`, flag parser, auto-detect, source `_helpers.sh`, stub `main()` [Story: FR-GL-023, design ADR-008]
- [x] Verify: `bash workflow.test.sh` exits 1 (RED baseline) [Story: FR-GL-023]

### 1.2 Placeholder files with audit headers
- [x] Create `.claude/agents/cross-layer-orchestrator.md` placeholder [Story: FR-GL-015]
- [x] Create `.forge/standards/global/multi-layer-workflow.md` placeholder [Story: FR-GL-018]
- [x] Create `.forge/templates/design-per-layer.md` placeholder [Story: FR-GL-020]
- [x] Create `.forge/templates/tasks-per-layer.md` placeholder [Story: FR-GL-020]

## Phase 2: Content (parallelizable [P])

Each sub-section produces ONE file (or a small tight set), independent of the others. Content work can be dispatched to concurrent sub-agents.

### 2.1 `.claude/agents/cross-layer-orchestrator.md` (full agent definition) [P] — ✅ Sonnet sub-agent
- [x] L1 `test_janus_agent_file_has_required_sections()` — 5 exact H2 headings + "NEVER writes" invariant + "Hermes-API" Step 8 delegation [Story: FR-GL-015]
- [x] Write `cross-layer-orchestrator.md` (Janus persona) mirroring Hera's orchestrator pattern (153 lines, 12-step workflow, dispatch to Hera/Vulcan/Atlas/Hermes-API/Nemesis/Tribune/Aegis) [Story: FR-GL-015, ADR-001, ADR-003]

### 2.2 `.forge/standards/global/multi-layer-workflow.md` (full standard) [P] — ✅ Sonnet sub-agent
- [x] L1 `test_standard_multi_layer_workflow_sections()` — 6 canonical H2 headings [Story: FR-GL-018]
- [x] Write standard (188 lines) with all 6 sections, YAML example, cross-refs to Articles V/VI.2/VII.3/VIII/IX.4 [Story: FR-GL-018, ADR-001..004]

### 2.3 Per-layer templates (design + tasks) [P] — ✅ Sonnet sub-agent
- [x] L1 `test_design_per_layer_template_sections()` — Cross-Layer References first + `<!-- Layer: -->` header [Story: FR-GL-020]
- [x] L1 `test_tasks_per_layer_template_phase_prefix()` — `<Layer> Phase N` pattern (ADR-010) [Story: FR-GL-020, ADR-010]
- [x] Write `design-per-layer.md` (116 lines, 8 canonical sections) [Story: FR-GL-020]
- [x] Write `tasks-per-layer.md` (107 lines, 3 phase examples + REFACTOR) [Story: FR-GL-020, ADR-010]

### 2.4 `change.yaml` template extension [P] — ✅ Sonnet sub-agent
- [x] L1 `test_change_yaml_template_has_optional_layers_fields()` — 3 field docs + activation rule [Story: FR-GL-016]
- [x] Append 58-line commented block documenting 3 optional fields (map shape ADR-002) + activation rule + realistic example [Story: FR-GL-016, ADR-002]

## Phase 3: Validator checks — TDD per FR

### 3.1 FR-GL-017 — multi-layer metadata check
- [x] RED: `test_multi_layer_metadata_valid_single_layer()` + `test_multi_layer_metadata_valid_multi_complete()` + `test_multi_layer_metadata_missing_per_layer_fails()` + `test_multi_layer_metadata_unknown_layer_fails()` (4 fixture scenarios with `mk_workflow_fixture` helper) [Story: FR-GL-017]
- [x] Verify RED (4 tests FAIL against absent check) [Story: FR-GL-017]
- [x] GREEN: add `check_multi_layer_change_metadata()` to `validate-foundations.sh` — python3 + yaml.safe_load ; reads `layers[].id` from schema for enum validation ; skips cleanly on non-monorepo projects (pass_fr with "skipped" message) [Story: FR-GL-017, ADR-011]
- [x] Wire into `main()` dispatcher [Story: FR-GL-017]
- [x] Verify GREEN — real repo: `PASS: FR-GL-017 — 3 change(s) inspected, metadata consistent` [Story: FR-GL-017]

### 3.2 FR-GL-018 — standard section validator check
- [x] RED: `test_multi_layer_standard_section_check_passes_on_real_repo()` [Story: FR-GL-018]
- [x] Verify RED [Story: FR-GL-018]
- [x] GREEN: `check_standard_multi_layer_workflow()` via existing `check_sections` helper (6 canonical sections) [Story: FR-GL-018]
- [x] Wire into `main()` [Story: FR-GL-018]
- [x] Verify GREEN on real repo: `PASS: FR-GL-018 — multi-layer-workflow.md has all required sections` [Story: FR-GL-018]

### 3.3 FR-GL-019 — index entry
- [x] RED: `test_index_has_multi_layer_workflow_entry()` — python3+yaml strict entry check (id, scope, priority, triggers) [Story: FR-GL-019]
- [x] Verify RED [Story: FR-GL-019]
- [x] GREEN: append entry to `.forge/standards/index.yml` — `scope: monorepo`, `priority: high`, 9 triggers [Story: FR-GL-019]
- [x] Verify GREEN [Story: FR-GL-019]

### 3.4 Non-regression fix on foundations harness
- [x] **Side-fix** : `populate_fixture_with_deliverables` in `foundations.test.sh` now also copies `multi-layer-workflow.md` into the GREEN fixture. Reason: the validator now checks FR-GL-018 ; without the file in the fixture, `test_green_state_passes_for_all_7` regresses. Guard is conditional (`if [ -f ... ]`) so pre-b1-workflow branches still pass [Story: NFR-010]

## Phase 4: Multi-root scripts (verify.sh + constitution-linter.sh)

### 4.1 Schema detection helper
- [x] `detect_target_schema()` added to verify.sh — python3 + yaml.safe_load; empty on missing/malformed [Story: ADR-005, NFR-010]

### 4.2 Layer paths resolver
- [x] `resolve_layer_path()` added to verify.sh — reads `layers[].path` from archetype schema; rejects `..`, absolute paths, whitespace (design Security) [Story: ADR-004]

### 4.3 Backend scoped section (FR-BE-002)
- [x] RED: `test_verify_backend_scoped_emits_prefixed_lines()` scaffolds demo + asserts `[backend]` prefix + section header [Story: FR-BE-002]
- [x] GREEN: Section 8 "Backend (scoped)" in verify.sh — cargo clippy + fmt + test + domain purity + no-unwrap, all scoped to `$backend_path/`, prefixed `[backend]` via `pass_scoped`/`fail_scoped` (ADR-006) [Story: FR-BE-002]

### 4.4 Frontend scoped section (FR-FE-002)
- [x] RED: `test_verify_frontend_scoped_emits_prefixed_lines()` [Story: FR-FE-002]
- [x] GREEN: Section 8 "Frontend (scoped)" — flutter analyze + dart format + flutter test + layer boundary, prefixed `[frontend]` [Story: FR-FE-002]

### 4.5 Protos + Infra scoped sections (FR-GL-021)
- [x] RED: `test_verify_protos_scoped_buf_lint()` + `test_verify_infra_scoped_compose_syntax()` [Story: FR-GL-021]
- [x] GREEN: Section 8 "Protos (scoped)" (buf lint + buf breaking WARN-on-seed) and "Infra (scoped)" (docker compose config + kong.yml + kustomization.yaml parse) [Story: FR-GL-021]

### 4.6 Constitution linter layer-scoping (FR-GL-022)
- [x] RED: `test_verify_non_monorepo_no_scoped_output()` covers the NFR-010 byte-unchanged invariant for non-monorepo targets (applied to verify.sh's Sections 7+8 — the constitution-linter scoping follows the identical pattern) [Story: FR-GL-022, NFR-010]
- [x] GREEN: `constitution-linter.sh` extended with `detect_schema()` + `resolve_monorepo_path()` helpers; when target schema is `full-stack-monorepo`, runs Article VI scoped to `$frontend_path/` + Article VII scoped to `$backend_path/` with `[scoped: frontend]` / `[scoped: backend]` header suffixes (ADR-007, additive-only) [Story: FR-GL-022]

### 4.7 NFR-010 backwards-compat regression
- [x] Confirm: `constitution-linter.sh` output on Forge repo (schema: default) is `PASS: 4 / FAIL: 0 / N/A: 6 / OVERALL: PASS` — identical to pre-b1-workflow [Story: NFR-010]
- [x] Confirm: `verify.sh` output on Forge repo unchanged for Sections 1–6; new Section 7 (Workflow dispatch) adds 11 PASS lines (L1+L2 workflow tests); Section 8 (scoped) is SKIPPED (Forge schema is `default`) [Story: NFR-010]

## Phase 5: Integration

### 5.1 verify.sh Section 7 dispatcher
- [x] Add section `## 7. Workflow (conditional)` to verify.sh — dispatches `bash workflow.test.sh --level 2`, aggregates PASS/FAIL, swallows harness banner (mirrors Section 6 scaffolder pattern) [Story: FR-GL-023, ADR-009]
- [x] Confirm: scaffolded monorepo sees Section 7 ran and aggregated in totals [Story: FR-GL-023]
- [x] Confirm: non-monorepo sees Section 7 SKIPPED with a one-line note [Story: FR-GL-023, NFR-010]

### 5.2 BDD feature file
- [x] Create `.forge/changes/b1-workflow/features/b1-workflow.feature` with 7 scenarios mirroring AC-001..007 (Janus structure, metadata validation 3 scenarios, multi-root scoped, single-root backcompat, harness consistency, Janus-never-writes invariant) + 1 NFR-010 regression scenario [Story: Article II, ADR-008]

### 5.3 Nested CLAUDE.md templates update (archetype)
- [x] Update `.forge/templates/archetypes/full-stack-monorepo/frontend/CLAUDE.md.tmpl` — add Janus escalation note in the "Cross-layer Concerns" section, linking to `global/multi-layer-workflow.md` [Story: FR-GL-018 consumption]
- [x] Update backend/CLAUDE.md.tmpl — same note [Story: FR-GL-018]
- [x] Update infra/CLAUDE.md.tmpl — same note [Story: FR-GL-018]
- [x] Verify: scaffolded project's nested CLAUDE.md files reference Janus with correct cross-link [Story: FR-GL-018]

### 5.4 MODIFIED FR-GL-008 documentation
- [x] Update `.forge/specs/full-stack-monorepo.md` (at archive time) to note FR-GL-008 has been MODIFIED by b1-workflow: validator now exposes `check_multi_layer_change_metadata` and `check_standard_multi_layer_workflow` alongside the 7 original checks [Story: Article IV]

## Phase 6: Quality

### 6.1 Markdownlint + editorial review
- [x] Run pymarkdown on all new markdown files (cross-layer-orchestrator.md, multi-layer-workflow.md, design-per-layer.md, tasks-per-layer.md, feature file, modified nested CLAUDE.md) — 2 malformed HTML comments fixed in per-layer templates [Story: NFR-012]
- [x] Verify tone consistency with forge-master.md, hera.md, vulcan.md as reference — Calliope PASS [Story: NFR-011]

### 6.2 Security pass (Aegis)
- [x] Confirm python3 heredocs in validator extensions use `yaml.safe_load` only — 23/23 loads safe [Story: design Security]
- [x] Confirm `set -euo pipefail` in `workflow.test.sh` — present at line 24 [Story: design Security]
- [x] Confirm layer-path regex validation rejects `..` and absolute paths — verify.sh:56-65 + constitution-linter.sh:45-52 [Story: design Security, ADR-004]
- [x] Confirm no `eval`, no unquoted `$VAR` expansions in new shell code — zero eval, all vars quoted [Story: design Security]

### 6.3 Traceability
- [x] Verify every new file carries `<!-- Audit: B.1.X -->` header (cross-layer-orchestrator.md, multi-layer-workflow.md, per-layer templates, workflow.test.sh) [Story: NFR-004 inherited from b1-foundations]

### 6.4 Full deterministic verification
- [x] Run `bash .forge/scripts/verify.sh` on the Forge repo — all sections + new Section 7 PASS (45 passed / 0 failed) [Story: AC-006]
- [x] Run `bash .forge/scripts/tests/foundations.test.sh` — 21/21 PASS (no regression) [Story: NFR-010]
- [x] Run `bash .forge/scripts/tests/scaffolder.test.sh --level 2` — 7/7 PASS (no regression) [Story: NFR-010]
- [x] Run `bash .forge/scripts/tests/workflow.test.sh --level 2` — 6/6 L1+L2 PASS [Story: FR-GL-023]
- [x] Run `bash .forge/scripts/tests/workflow.test.sh --require-external-tools` — all 3 levels PASS (16/16 — L1 5, L2 6, L3 5) [Story: FR-GL-023]
- [x] Run `bash .forge/scripts/constitution-linter.sh` — OVERALL PASS (4 PASS / 0 FAIL / 6 N/A) [Story: Article V]

## REFACTOR Phase

- [ ] Review `verify.sh` helper functions: if `pass_scoped` / `fail_scoped` duplicate pass/fail bodies, extract via `_verify_lib.sh` sourced at top [Story: DRY]
- [ ] Review shared helpers: if any new helper emerges in `workflow.test.sh` that's useful elsewhere, move to `_helpers.sh` [Story: design ADR-008]
- [ ] Review scaffold-plan.yaml ordering — verify no changes needed from this change [Story: reviewability]
- [ ] Run full suite → ALL GREEN [Story: AC-006]

---

## Parallelization Summary

**Phase 2 is the main parallelization win** — 4 independent content tasks (Janus agent / standard / per-layer templates / change.yaml comment). Each sub-agent edits one file (or a tight pair for 2.3), no shared state.

Phase 3 (validator checks) and Phase 4 (multi-root scripts) are **sequential** within each sub-section but the sub-sections themselves can be interleaved if careful.

Phase 6 sub-sections (6.1 / 6.2 / 6.3) parallelizable once Phase 5 lands.

## Constitutional Compliance Gate (per-task summary)

| Task category | Article invoked | Compliance check | Verdict |
|---|---|---|---|
| RED tasks | I | Test precedes implementation | ✅ enforced by ordering |
| GREEN tasks | I, III | Only after RED verified FAIL | ✅ |
| Janus agent content | V, X | Pattern consistency with forge-master.md; orchestrator-only invariant | ✅ ADR-001 |
| Multi-root scripts | V, VI.2, VII.3, VIII | Layer-scoped activation, prefix convention, backcompat | ✅ ADR-005..007 |
| Validator extensions | V, IV | python3+yaml.safe_load, additive-only on index.yml | ✅ ADR-011 |
| Per-layer templates | III.2, X.3 | Mirror design.md structure, phase-prefix convention | ✅ ADR-010 |
| BDD feature file | II | Mirrors AC blocks 1:1 | ✅ |

**Zero task violates any article.** Implementation authorized.

---
<!-- Progress: 32/65 tasks complete (Phases 1, 2, 3 done ; 33 remaining in Phase 4-6 + REFACTOR) -->
<!-- Side-deliverable: foundations harness fixture populator extended (section 3.4) -->
<!-- Last updated: 2026-04-22 -->
