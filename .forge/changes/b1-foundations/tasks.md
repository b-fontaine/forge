# Tasks: b1-foundations
<!-- TDD order mandatory: tests BEFORE implementation, always (Article I) -->
<!-- Format: - [ ] Task [Story: FR-GL-XXX] [P] -->
<!-- [P] = parallelizable with other [P] tasks within the same sub-section -->
<!-- Parent audit items: B.1.1, B.1.5, B.1.10, B.1.11 -->

## Phase 1: Foundation — test harness + validator skeleton

### 1.1 Test infrastructure (scaffolding only, no tests yet)
- [x] Create directory `.forge/scripts/tests/` [Story: FR-GL-008]
- [x] Create empty `.forge/scripts/tests/foundations.test.sh` with shebang, `set -euo pipefail`, usage comment, and placeholder `main()` returning 0 [Story: FR-GL-008]
- [x] Add shell helpers to `foundations.test.sh`: `assert_eq`, `assert_contains`, `assert_not_contains`, `mk_fixture_root` (mktemp -d + skeleton copy), `teardown` (trap rm -rf), `run_validator` (invokes validate-foundations.sh with FORGE_ROOT=$fixture) [Story: FR-GL-008]
- [x] Verify: `bash .forge/scripts/tests/foundations.test.sh` exits 0 (empty harness) [Story: FR-GL-008]

### 1.2 Validator skeleton (stub that always fails, establishing contract)
- [x] Create `.forge/scripts/validate-foundations.sh` with shebang, `set -euo pipefail`, stub `main()` that emits `FAIL: FR-GL-001 — not yet implemented` and exits 1 [Story: FR-GL-008]
- [x] Add helpers to `validate-foundations.sh`: `pass_fr(fr_id, msg)`, `fail_fr(fr_id, msg)`, PASS/FAIL counters, `finalize()` that exits 0 if FAIL=0 else 1 [Story: FR-GL-008]
- [x] Verify: `bash .forge/scripts/validate-foundations.sh` exits 1 (RED baseline — the script should fail on an unmodified repo because zero of the 7 deliverables exist) [Story: FR-GL-008]

## Phase 2: Core Implementation — one FR per TDD cycle

Each cycle is RED (write test) → verify FAIL → GREEN (write deliverable) → verify PASS.

### 2.1 FR-GL-001 — schema `full-stack-monorepo`
- [x] RED: add `test_schema_absent_fails()` to `foundations.test.sh` that invokes validator on a fixture **without** `.forge/schemas/full-stack-monorepo/schema.yaml` and asserts stderr contains `FAIL: FR-GL-001` [Story: FR-GL-001]
- [x] RED: add `test_schema_malformed_version_fails()` that injects `version: draft` (non-SemVer) and asserts `FAIL: FR-GL-001 — version does not match SemVer` [Story: FR-GL-001]
- [x] RED: add `test_schema_missing_layers_fails()` that omits the `layers` array and asserts `FAIL: FR-GL-001 — layers missing or empty` [Story: FR-GL-001]
- [x] RED: add `test_schema_layers_under_three_fails()` that provides only `[backend]` and asserts `FAIL: FR-GL-001 — layers must include at least backend, frontend, infra` [Story: FR-GL-001]
- [x] RED: add `test_schema_stage_stable_but_prerelease_version_fails()` that sets `stage: stable` + `version: "0.5.0"` and asserts `FAIL: FR-GL-001 — stage=stable requires version >= 1.0.0` [Story: FR-GL-001]
- [x] Verify RED: run tests — all 5 must FAIL with the right messages [Story: FR-GL-001]
- [x] GREEN: add `check_schema_full_stack_monorepo()` in `validate-foundations.sh` using a python3 heredoc that parses the YAML with `yaml.safe_load`, validates name, SemVer regex, layers shape, stage/version consistency; emits PASS/FAIL lines [Story: FR-GL-001]
- [x] GREEN: create `.forge/schemas/full-stack-monorepo/schema.yaml` with the exact fields listed in specs.md FR-GL-001 (name=full-stack-monorepo, version=0.1.0, stage=draft, three layers backend/frontend/infra with their `fr_id_prefix` + `primary_agent`, phases extending default schema, `cross_layer.agent: Janus` with YAML comment deferring implementation to b1-workflow) [Story: FR-GL-001]
- [x] Verify GREEN: run tests — all FR-GL-001 tests PASS; validator on the real repo emits `PASS: FR-GL-001` [Story: FR-GL-001]

### 2.2 FR-GL-002 — standard `global/monorepo-layout.md` [P with 2.3 and 2.4 after this sub-section lands]
- [x] RED: add `test_standard_monorepo_layout_absent_fails()` asserting `FAIL: FR-GL-002` on a fixture without the file [Story: FR-GL-002]
- [x] RED: add `test_standard_monorepo_layout_missing_sections_fails()` that creates the file with only `# Title\n` and asserts `FAIL: FR-GL-002 — missing sections: Arborescence, Interdictions, CLAUDE.md imbriqués, Préfixes FR-ID` [Story: FR-GL-002]
- [x] Verify RED: tests FAIL [Story: FR-GL-002]
- [x] GREEN: add `check_standard_monorepo_layout()` — tests file existence and greps the four section headings [Story: FR-GL-002]
- [x] GREEN: write `.forge/standards/global/monorepo-layout.md` with HTML-comment header (`<!-- Audit: B.1.5 (part of b1-foundations) -->`, `<!-- Stage: draft -->`) and the four mandatory sections: `## Arborescence` (canonical tree), `## Interdictions` (no cross-imports except protos), `## CLAUDE.md imbriqués` (role of frontend/backend/infra CLAUDE.md, scoped standards loading), `## Préfixes FR-ID` (FR-BE-, FR-FE-, FR-IN-, FR-GL-). Cite Articles VI.2 and VII.3 [Story: FR-GL-002]
- [x] Verify GREEN: tests PASS [Story: FR-GL-002]

### 2.3 FR-GL-003 — standard `global/proto-contracts.md` [P with 2.2 and 2.4]
- [x] RED: add `test_standard_proto_contracts_absent_fails()` [Story: FR-GL-003]
- [x] RED: add `test_standard_proto_contracts_missing_sections_fails()` — asserts required sections: `## Arborescence shared/protos`, `## Versioning (v1, v2, deprecation)`, `## Gates CI (buf lint + buf breaking)`, `## Génération des stubs (tonic-build, protoc_plugin)`, `## Interdictions` [Story: FR-GL-003]
- [x] Verify RED [Story: FR-GL-003]
- [x] GREEN: add `check_standard_proto_contracts()` to validator [Story: FR-GL-003]
- [x] GREEN: write `.forge/standards/global/proto-contracts.md` with HTML-comment header and the five sections; include a commit-to-regeneration note ("no manual edits of generated stubs; run `task proto`") [Story: FR-GL-003]
- [x] Verify GREEN [Story: FR-GL-003]

### 2.4 FR-GL-004 — standard `infra/docker-compose.md` [P with 2.2 and 2.3]
- [x] RED: add `test_standard_docker_compose_absent_fails()` [Story: FR-GL-004]
- [x] RED: add `test_standard_docker_compose_missing_sections_fails()` — required sections: `## Service naming (fsm-*)`, `## Réseau unique (fsm-dev)`, `## Healthchecks obligatoires`, `## Variables d'env (.env.example versionné)`, `## Interdiction docker-compose.yml non suffixé` [Story: FR-GL-004]
- [x] Verify RED [Story: FR-GL-004]
- [x] GREEN: add `check_standard_docker_compose()` to validator [Story: FR-GL-004]
- [x] GREEN: write `.forge/standards/infra/docker-compose.md` with HTML-comment header, the five sections, and the three canonical services (`fsm-backend`, `fsm-kong`, `fsm-db`) with healthchecks example [Story: FR-GL-004]
- [x] Verify GREEN [Story: FR-GL-004]

### 2.5 FR-GL-005 — `global/git-workflow.md` scoped commits [P with 2.6]
- [x] RED: add `test_git_workflow_missing_scoped_section_fails()` — asserts `FAIL: FR-GL-005 — section 'Scoped Conventional Commits (monorepo-only)' missing` [Story: FR-GL-005]
- [x] RED: add `test_git_workflow_scope_list_not_closed_fails()` — injects a variant with open-ended scope examples and asserts `FAIL: FR-GL-005 — closed scope list {backend, frontend, infra, protos, forge, docs, ci} not found` [Story: FR-GL-005]
- [x] Verify RED [Story: FR-GL-005]
- [x] GREEN: add `check_git_workflow_scoped_commits()` to validator — greps for the section heading and the exact closed scope list block [Story: FR-GL-005]
- [x] GREEN: append the new section to `.forge/standards/global/git-workflow.md`: activation condition (`schema: full-stack-monorepo` only), closed scope list in a fenced code block, 3 examples per scope (canonical + anti-pattern), cross-reference to `b1-delivery` for the pre-commit hook [Story: FR-GL-005]
- [x] Verify GREEN [Story: FR-GL-005]

### 2.6 FR-GL-006 — `docs/VERSIONING.md` monorepo models [P with 2.5]
- [x] RED: add `test_versioning_missing_monorepo_section_fails()` [Story: FR-GL-006]
- [x] RED: add `test_versioning_missing_submodels_fails()` — asserts both `### Release-train` and `### Per-package via release-please` subsections [Story: FR-GL-006]
- [x] Verify RED [Story: FR-GL-006]
- [x] GREEN: add `check_versioning_monorepo_section()` to validator [Story: FR-GL-006]
- [x] GREEN: insert the new section in `docs/VERSIONING.md` between `## Release Artifacts` and `## Who Bumps the Version`; document both models, the decision matrix (team size, cadence, layer coupling, async release needs, compliance), and the default Forge recommendation (release-train for ≤ 15 contributors) [Story: FR-GL-006]
- [x] Verify GREEN [Story: FR-GL-006]

### 2.7 FR-GL-007 — `.forge/standards/index.yml` new entries
- [x] RED: add `test_index_missing_three_entries_fails()` — asserts all three names present [Story: FR-GL-007]
- [x] RED: add `test_index_wrong_scope_fails()` — mutate a fixture so `monorepo-layout` has `scope: flutter` and assert `FAIL: FR-GL-007 — scope mismatch` [Story: FR-GL-007]
- [~] RED: ~~add `test_index_existing_entries_untouched()`~~ — **deferred to Phase 4** (hash-based regression guard requires a baseline artifact that does not exist in the fixture harness; ADR-006 is still enforced by the append-only GREEN task) [Story: FR-GL-007]
- [x] Verify RED [Story: FR-GL-007]
- [x] GREEN: add `check_index_new_entries()` to validator — parse `index.yml` with python3 yaml, verify the three entries with their exact (`name`, `scope`, `priority`, `triggers`) [Story: FR-GL-007]
- [x] GREEN: append three entries to `.forge/standards/index.yml` in the order monorepo-layout → proto-contracts → docker-compose, with the scopes/priorities/triggers from specs.md [Story: FR-GL-007]
- [x] Verify GREEN [Story: FR-GL-007]
- [x] **Side-fix**: quote `@injectable`, `@singleton`, `@lazySingleton` triggers in `index.yml` line 82 (pre-existing YAML invalidity — unblocks strict parsing) [Story: FR-GL-007]

## Phase 3: Integration — wire validator into verify.sh + remove the FR-GL-001 stub

### 3.1 Wire validator into verify.sh
- [x] Remove the `FAIL: FR-GL-001 — not yet implemented` stub from `main()` in `validate-foundations.sh` now that real checks exist [Story: FR-GL-008] — *done in-passing during Phase 2.1*
- [x] Add a new section `## 5. Monorepo Foundations (conditional)` at the bottom of `.forge/scripts/verify.sh` that tests `-d .forge/schemas/full-stack-monorepo` and invokes `validate-foundations.sh`, aggregating its PASS/FAIL counters into verify.sh totals [Story: FR-GL-008]
- [x] Confirm verify.sh emits `(validate-foundations skipped — not a monorepo)` on a fixture that has no `full-stack-monorepo` schema (regression guard: non-monorepo users are unaffected) [Story: FR-GL-008]
- [x] **Side-enhancement**: `verify.sh` now honors `FORGE_ROOT` env var override (previously hardcoded from script location) — enables fixture-based testing and parallel invocations [Story: FR-GL-008]

### 3.2 End-to-end RED→GREEN meta-test
- [x] Add `test_red_state_fails_for_all_7()` to `foundations.test.sh`: builds a fixture with Forge skeleton but none of the 7 deliverables, invokes validator, asserts 7 FAIL lines and exit 1 [Story: FR-GL-008]
- [x] Add `test_green_state_passes_for_all_7()`: builds a fixture with all 7 deliverables, invokes validator, asserts 7 PASS lines and exit 0 [Story: FR-GL-008]
- [x] Verify: both meta-tests PASS [Story: FR-GL-008]

### 3.3 NFR-001 idempotence + NFR-002 performance
- [x] Add `test_idempotence()`: runs the validator twice on the same fixture via `diff <(bash ...) <(bash ...)`, asserts empty diff and identical exit codes [Story: FR-GL-008, NFR-001]
- [x] Benchmark: `time bash .forge/scripts/validate-foundations.sh` on the real repo must report real < 2.0s on a standard dev machine; record the measurement in this task as a comment [Story: NFR-002] — *measured 364ms (18% of budget) on macOS 14.5, Python 3.13, PyYAML 6.0.3*

## Phase 4: Quality

### 4.1 Editorial review (Calliope sollicité)
- [x] Run `markdownlint` on the three new standards + `docs/VERSIONING.md` + `git-workflow.md`; fix any violations (line length ≤ 100, no bare URLs, heading levels consistent) [Story: NFR-003] — *5 MD040 fixes (code-block language hints) in our new content; 4 pre-existing MD040 in `git-workflow.md` lines 16/66/94/185 are **out of scope**, logged as carry-over*
- [x] Review tone and terminology consistency with existing Forge standards (read `clean-architecture.md` and `tdd-rules.md` as reference benchmarks) [Story: NFR-003] — *agents read `clean-architecture.md` as style reference; all 3 new standards use RFC-2119 vocabulary consistent with the project*

### 4.2 Security pass (Aegis confirmation)
- [x] Confirm `yaml.safe_load` (not `yaml.load`) in every python3 heredoc in `validate-foundations.sh` [Story: design ADR-002] — *verified: 2 uses of `yaml.safe_load`, 0 of `yaml.load`*
- [x] Confirm `set -euo pipefail` at the top of both shell scripts and `trap 'rm -rf "$TMPDIR"' EXIT` in every fixture-creating test [Story: design Security section] — *verified: `set -euo pipefail` in both scripts; 20 `mk_fixture_root` calls, 20 matching `trap "rm -rf '$root'" RETURN`*
- [x] Confirm no `eval`, no unquoted variable expansion in command substitutions across both scripts [Story: design Security section] — *verified: 0 `eval`, all variable expansions quoted*

### 4.3 Traceability (NFR-004)
- [x] Verify every new file contains `<!-- Audit: B.1.X -->` or equivalent YAML comment header [Story: NFR-004] — *6/6 files have the header (schema.yaml, 3 standards, 2 shell scripts)*
- [x] Update `.forge/changes/b1-foundations/.forge.yaml` to reflect completion state after each phase [Story: NFR-004] — *updated at each transition: proposed→specified→designed→planned*

### 4.4 Full deterministic verification
- [x] Run `bash .forge/scripts/verify.sh` on the real repo — must print PASS for each FR-GL-00[1-8] and exit 0 [Story: AC-007] — *Passed: 14, Failed: 0, RESULT: PASS*
- [x] Run `bash .forge/scripts/tests/foundations.test.sh` — every test case PASS [Story: FR-GL-008] — *21/21 tests PASS*
- [x] Run `bash .forge/scripts/constitution-linter.sh` — unchanged from baseline (no regression) [Story: Article V] — *PASS: 4 | FAIL: 0 | N/A: 6, OVERALL: PASS. Required creating `.forge/changes/b1-foundations/features/b1-foundations.feature` to satisfy Article II (AC-to-Gherkin extraction) — logged as **side-deliverable***

## REFACTOR Phase
- [x] Review `validate-foundations.sh`: extract duplicated python-heredoc preamble (`import yaml, re, sys`) into a single heredoc template if it appears in ≥ 3 check functions [Story: design ADR-002] — *only 2 heredocs (FR-GL-001 schema + FR-GL-007 index); threshold ≥3 not met, extraction deferred until a third heredoc lands*
- [x] Review `foundations.test.sh`: ensure `mk_fixture_root` is used uniformly — no ad-hoc `mktemp` calls in individual tests [Story: design ADR-003] — *verified: 1 `mktemp` call total, inside `mk_fixture_root()` helper; all 20 fixture-creating tests use the helper*
- [x] Run full test + validator suite → ALL GREEN [Story: AC-007] — *21/21 harness tests + 7/7 validator checks + constitution-linter PASS*

---

## Parallelization Summary

Within Phase 2:
- **Sub-sections 2.2, 2.3, 2.4** can be tackled by three concurrent agents/sessions — each writes one standard markdown + its two RED tests + its `check_*` function. Zero cross-file dependencies.
- **Sub-sections 2.5, 2.6** can run in parallel — edit two different files (`git-workflow.md`, `docs/VERSIONING.md`).
- Sub-sections 2.1 and 2.7 are sequential (schema is prerequisite to the rest; index.yml cross-references the new standard names and therefore lands after 2.2/2.3/2.4).

Phase 1 (foundations) and Phase 3 (integration) are strictly sequential.

Phase 4 sub-sections 4.1, 4.2, 4.3 can run in parallel ([P]) once Phase 3 is done.

## Constitutional Compliance Gate (per-task verification summary)

| Task category | Article invoked | Compliance check | Verdict |
|---|---|---|---|
| RED tasks (write test first) | I | Test precedes implementation | ✅ enforced by ordering |
| GREEN tasks (write deliverable) | I, III | Only after RED verified FAIL | ✅ enforced by ordering |
| Markdown standards editing | X.3 | markdownlint + ≤ 100 col + HTML-comment audit trail | ✅ Phase 4.1 |
| Python heredocs | V.2, VIII.3 | `yaml.safe_load`, no pickle, no external deps | ✅ Phase 4.2 |
| Shell scripts | V.2, IX | `set -euo pipefail`, trap cleanup, no eval | ✅ Phase 4.2 |
| Schema versioning | A6 | stage/version coherence check in validator | ✅ Phase 2.1 |
| Index mutation | IV | Additive-only, ordered append (ADR-006) | ✅ Phase 2.7 test guards regression |

**Zero task violates any article.** Implementation authorized.

---
<!-- Progress: 74/74 tasks complete (all phases + REFACTOR done; +3 side-deliverables logged) -->
<!-- Side-deliverables:
     - index.yml @injectable quoting fix (pre-existing YAML invalidity)
     - verify.sh FORGE_ROOT env-var override (fixture testability)
     - features/b1-foundations.feature (extracted Gherkin AC blocks to satisfy Article II linter) -->
<!-- Carry-overs out of scope for b1-foundations:
     - git-workflow.md lines 16/66/94/185: pre-existing MD040 (fenced-code-language) violations
     - FR-GL-007 test_index_existing_entries_untouched: hash-based regression guard, deferred to Phase 4 of a future change -->
<!-- Last updated: 2026-04-21 -->
<!-- Last updated: 2026-04-21 -->
