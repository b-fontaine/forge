# Tasks: g1-forge-ci
<!-- TDD order mandatory: tests BEFORE implementation, always (Article I) -->
<!-- Format: - [x] Task [Story: FR-XXX] [P] -->
<!-- [P] = parallelizable with other [P] tasks in the same sub-section -->
<!-- Parent audit item: G.1 -->
<!-- Depends on: b1-delivery (archived) — workflow conventions inherited -->

## Phase 1: Foundation — harness skeleton

### 1.1 `g1.test.sh` skeleton
- [x] Create `.forge/scripts/tests/g1.test.sh` with shebang, `set -euo pipefail`, MANIFEST comment block listing every `test_*` to come (per FR-CI-010), source `_helpers.sh`, level dispatcher (L1 only — no L2/L3 here, this harness is purely structural), stub `main()` [Story: FR-CI-010, design ADR-004]
- [x] `chmod +x` + verify `bash g1.test.sh` exits 1 (RED baseline — manifest declares functions not yet defined) [Story: FR-CI-010]

### 1.2 Path constants in harness
- [x] Declare in `g1.test.sh` : `WORKFLOW_FILE=$FORGE_ROOT_REAL/.github/workflows/forge-ci.yml`, `NVMRC=$FORGE_ROOT_REAL/cli/.nvmrc`, `STD_SELF_CI=$FORGE_ROOT_REAL/.forge/standards/global/forge-self-ci.md`, `CONTRIBUTING=$FORGE_ROOT_REAL/docs/CONTRIBUTING.md` [Story: FR-CI-010]

## Phase 2: Workflow `.github/workflows/forge-ci.yml` — TDD per FR

### 2.1 FR-CI-001 — workflow shape (skeleton)
- [x] RED: `test_forge_ci_workflow_shape()` in `g1.test.sh` — PyYAML parse, asserts triggers (pull_request branches:[main] + push branches:[main], no other triggers), top-level `permissions: contents: read` exact, exactly 5 jobs (`harness`, `gates`, `cli`, `lint`, `summary`), every `runs-on: ubuntu-latest`, no `continue-on-error: true` anywhere [Story: FR-CI-001, NFR-CI-005]
- [x] Verify RED — file missing [Story: FR-CI-001]
- [x] GREEN: write skeleton `.github/workflows/forge-ci.yml` — YAML header (`name: forge-ci`), triggers, `permissions: contents: read`, 5 jobs each with `runs-on: ubuntu-latest` and a single placeholder step [Story: FR-CI-001, ADR-001]
- [x] Verify GREEN [Story: FR-CI-001]

### 2.2 FR-CI-002 — `harness` job runs the 4 test harnesses
- [x] RED: `test_forge_ci_harness_job_invokes_four_harnesses()` — YAML parse asserts `jobs.harness.steps` includes (in order) checkout → setup-python with PyYAML pip install → bash invocations of `foundations.test.sh`, `scaffolder.test.sh --level 1,2`, `workflow.test.sh --level 1,2`, `delivery.test.sh`. Each invocation prefixed with `bash` (no `./script.sh`) [Story: FR-CI-002]
- [x] Verify RED [Story: FR-CI-002]
- [x] GREEN: write `harness` job body — `actions/checkout@v4`, `actions/setup-python@v5` with python-version 3.11, `pip install pyyaml`, then 4 bash steps invoking each harness [Story: FR-CI-002, ADR-010]
- [x] Verify GREEN [Story: FR-CI-002]

### 2.3 FR-CI-003 — `gates` job runs verify.sh + constitution-linter.sh
- [x] RED: `test_forge_ci_gates_job_invokes_both_scripts()` — YAML asserts `jobs.gates.steps` runs `bash .forge/scripts/verify.sh` then `bash .forge/scripts/constitution-linter.sh` (in order, no other gates) [Story: FR-CI-003]
- [x] Verify RED [Story: FR-CI-003]
- [x] GREEN: write `gates` job body — checkout, setup-python with PyYAML, then the two bash steps [Story: FR-CI-003]
- [x] Verify GREEN [Story: FR-CI-003]

### 2.4 FR-CI-004 — `cli` job runs the npm pipeline
- [x] RED: `test_forge_ci_cli_job_runs_npm_pipeline()` — YAML asserts `jobs.cli.defaults.run.working-directory == 'cli'`, steps include `actions/setup-node@v4` with `node-version-file: cli/.nvmrc` and `cache: 'npm'` and `cache-dependency-path: cli/package-lock.json`, then `npm ci`, `npm run lint`, `npm test`, `npm run bundle` (in order) [Story: FR-CI-004, ADR-008]
- [x] Verify RED [Story: FR-CI-004]
- [x] GREEN: write `cli` job body using built-in setup-node cache (single step instead of separate cache action per ADR-008) [Story: FR-CI-004, ADR-008]
- [x] Verify GREEN [Story: FR-CI-004]

### 2.5 FR-CI-005 — `lint` job runs shellcheck
- [x] RED: `test_forge_ci_lint_job_invokes_shellcheck_on_target_dirs()` — YAML asserts `jobs.lint.steps` includes `ludeeus/action-shellcheck` pinned to `@2.0.0` (or specific tag), invoked twice : once with `scandir: ./.forge/scripts`, once with `scandir: ./bin`, both with `severity: warning` [Story: FR-CI-005, ADR-005]
- [x] Verify RED [Story: FR-CI-005]
- [x] GREEN: write `lint` job body — checkout, then 2 ludeeus/action-shellcheck steps with the prescribed inputs [Story: FR-CI-005, ADR-005]
- [x] Verify GREEN [Story: FR-CI-005]

### 2.6 FR-CI-006 — `summary` job aggregates needs results
- [x] RED: `test_forge_ci_summary_job_aggregates_needs()` — YAML asserts `jobs.summary.needs == [harness, gates, cli, lint]`, summary always runs (no `if:`), first step is a `run:` containing a bash script that reads `${{ needs.harness.result }}` etc. and exits non-zero if any is not exactly `'success'`, also emits a notice annotation [Story: FR-CI-006, ADR-007]
- [x] Verify RED [Story: FR-CI-006]
- [x] GREEN: write `summary` job — needs declaration, single bash step inspecting `needs.*.result` env vars, exits 1 with annotation `::error::forge-ci: <job> FAILED` on first non-success ; on full success emits `::notice::forge-ci: 4/4 jobs PASS` [Story: FR-CI-006, ADR-007]
- [x] Verify GREEN [Story: FR-CI-006]

### 2.7 FR-CI-007 — concurrency policy
- [x] RED: `test_forge_ci_concurrency_policy()` — YAML asserts top-level `concurrency.group == 'forge-ci-${{ github.ref }}'`, `cancel-in-progress` is the conditional expression `${{ github.event_name == 'pull_request' }}` (per ADR-002 — single workflow, not split) [Story: FR-CI-007, ADR-002]
- [x] Verify RED [Story: FR-CI-007]
- [x] GREEN: add top-level `concurrency:` block to the workflow with the conditional expression and an inline comment explaining the asymmetry [Story: FR-CI-007, ADR-002]
- [x] Verify GREEN [Story: FR-CI-007]

### 2.8 FR-CI-009 — action version pinning audit
- [x] RED: `test_forge_ci_no_unpinned_uses()` — `grep -E 'uses: [^@]+@(main|master|HEAD)'` against `forge-ci.yml` MUST produce zero matches ; no `:latest` tag anywhere ; every `uses:` MUST have an `@<ref>` [Story: FR-CI-009]
- [x] Verify RED if any unpinned reference slipped in during phases 2.1-2.7 — fix immediately [Story: FR-CI-009]
- [x] Verify GREEN — every `uses:` reference pinned [Story: FR-CI-009]

## Phase 3: Supporting files

### 3.1 FR-CI-008 — `cli/.nvmrc`
- [x] RED: `test_forge_ci_nvmrc_present_and_pinned()` — file `cli/.nvmrc` exists, content matches regex `^20\.[0-9]+\.[0-9]+$` (Node 20.x patch-pinned), single line [Story: FR-CI-008]
- [x] Verify RED [Story: FR-CI-008]
- [x] GREEN: write `cli/.nvmrc` with the current LTS 20.x patch (e.g. `20.18.0`) — single line, no comment [Story: FR-CI-008]
- [x] Verify GREEN [Story: FR-CI-008]

### 3.2 ADR-003 — Standard `global/forge-self-ci.md`
- [x] RED: `test_standard_forge_self_ci_has_required_sections()` — file exists with 3 canonical H2 sections : `Workflow shape`, `What's intentionally different from infra/ci-workflows.md`, `Branch protection` [Story: ADR-003]
- [x] Verify RED [Story: ADR-003]
- [x] GREEN: write `.forge/standards/global/forge-self-ci.md` (~90 lines) — Workflow shape (5 jobs, summary aggregator, conditional concurrency), differences from archetype (no paths-filter, single workflow, no per-layer split), Branch protection (manual config, required status `forge-ci / summary`, recommended additional protections) [Story: ADR-003]
- [x] Verify GREEN [Story: ADR-003]

### 3.3 Index entry for the new standard
- [x] RED: `test_index_has_forge_self_ci_entry()` — `.forge/standards/index.yml` lists an entry with id `global/forge-self-ci`, scope `meta` (or `global`), priority `medium`, triggers including `forge-ci`, `self-ci`, `branch protection` [Story: ADR-003]
- [x] Verify RED [Story: ADR-003]
- [x] GREEN: append entry to `.forge/standards/index.yml` after the existing global entries [Story: ADR-003]
- [x] Verify GREEN [Story: ADR-003]

### 3.4 FR-CI-011 — `docs/CONTRIBUTING.md` branch protection section
- [x] RED: `test_contributing_documents_branch_protection()` — `docs/CONTRIBUTING.md` contains a section (H2 named "Continuous Integration", "CI", or "Branch protection") that mentions the required status `forge-ci / summary`, names the GitHub UI path (Settings → Branches → Branch protection rules), and lists at least one recommended additional protection (linear history, signed commits, or stale-review dismissal) [Story: FR-CI-011]
- [x] Verify RED [Story: FR-CI-011]
- [x] GREEN: append section to `docs/CONTRIBUTING.md` documenting branch protection requirements, with explicit "configured by maintainer via GitHub UI, NOT automated" note [Story: FR-CI-011]
- [x] Verify GREEN [Story: FR-CI-011]

### 3.5 BDD feature file
- [x] Create `.forge/changes/g1-forge-ci/features/g1-forge-ci.feature` with Background scenario + 7 scenarios mirroring AC-001..007 (clean PR PASS, breaking harness blocks merge, breaking CLI blocks merge, shellcheck warning blocks merge, constitution violation blocks merge, concurrency cancellation, runtime budget) [Story: AC-001..007]

## Phase 4: Quality

### 4.1 NFR-CI-002 — workflow file size
- [x] RED: `test_forge_ci_under_size_budget()` — `wc -l .github/workflows/forge-ci.yml ≤ 250` [Story: NFR-CI-002]
- [x] Verify GREEN — file expected ~180 lines [Story: NFR-CI-002]
- [x] If over budget : REFACTOR by extracting a composite action (least likely scenario, only if duplication grows) [Story: NFR-CI-002]

### 4.2 NFR-CI-003 — failure semantics (already covered by 2.1 test, this is a redundancy guard)
- [x] Spot-check : `grep -E 'continue-on-error\s*:\s*true' .github/workflows/forge-ci.yml` MUST be empty [Story: NFR-CI-003]
- [x] Confirm `if: always()` is used ONLY on log-upload steps (none expected in initial implementation) [Story: NFR-CI-003]

### 4.3 NFR-CI-005 — permissions hygiene (covered by 2.1 test)
- [x] Spot-check : top-level `permissions:` declares only `contents: read` [Story: NFR-CI-005]
- [x] Confirm no per-job `permissions:` overrides [Story: NFR-CI-005]

### 4.4 No-regression — 4 prior harnesses still PASS
- [x] Run `bash .forge/scripts/tests/foundations.test.sh` → 21/21 PASS [Story: NFR-CI-006]
- [x] Run `bash .forge/scripts/tests/scaffolder.test.sh --level 1,2` → 14/14 PASS [Story: NFR-CI-006]
- [x] Run `bash .forge/scripts/tests/workflow.test.sh --level 1,2` → 16/16 PASS [Story: NFR-CI-006]
- [x] Run `bash .forge/scripts/tests/delivery.test.sh` → 24/24 PASS [Story: NFR-CI-006]
- [x] Run `bash .forge/scripts/verify.sh` → RESULT: PASS [Story: NFR-CI-006]
- [x] Run `bash .forge/scripts/constitution-linter.sh` → OVERALL: PASS [Story: NFR-CI-006]

### 4.5 `g1.test.sh` self-consistency
- [x] `test_g1_manifest_self_consistency()` — meta-test parses MANIFEST comment block, asserts every declared `test_*` is a defined function [Story: FR-CI-010]
- [x] Verify GREEN — `bash g1.test.sh` exits 0 [Story: FR-CI-010]

## Phase 5: Spec finalization (executed by `/forge:archive`)

### 5.1 Consolidated spec `.forge/specs/forge-ci.md`
- [x] Author the new file `.forge/specs/forge-ci.md` containing the 11 FRs (FR-CI-001..011) + 6 NFRs (NFR-CI-001..006) verbatim from `g1-forge-ci/specs.md` (no modifications). Header explains the spec's scope (Forge's own CI, distinct from archetype CI). DEFERRED to Phase 6 archive [Story: Article IV]
- [x] Author `Archived changes` table with the single row : `g1-forge-ci`, 2026-04-29, "Forge's own CI workflow", FR-CI-001..011 + NFR-CI-001..006 [Story: Article IV]

### 5.2 Final g1.test.sh smoke
- [x] `bash .forge/scripts/tests/g1.test.sh` exits 0 ; every Testable FR has a matching `test_*` function ; manifest self-consistency PASSES [Story: FR-CI-010]

## Phase 6: Archive

### 6.1 `/forge:archive g1-forge-ci`
- [x] Apply the spec finalization from Phase 5.1 — create `.forge/specs/forge-ci.md` [Story: Article IV]
- [x] Set `.forge/changes/g1-forge-ci/.forge.yaml` `status: archived`, `timeline.archived: <date>` [Story: lifecycle]
- [x] Re-run `g1.test.sh` — still 100% PASS [Story: FR-CI-010]
- [x] Re-run `verify.sh` and `constitution-linter.sh` — both PASS [Story: NFR-CI-006]
- [x] Update `.forge/product/roadmap.md` : G.1 row marked Done with the archive date [Story: lifecycle]
- [x] Update `CHANGELOG.md` `[Unreleased]` block : add `### Added — g1-forge-ci (2026-04-29)` entry [Story: docs]

---

## Constitutional Compliance — per-task gate

| Article                              | How upheld                                                                                                                                       |
|--------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| **I — TDD**                          | Every implementation task is preceded by a RED test in `g1.test.sh`. No GREEN task lacks a matching RED predecessor.                              |
| **III — Specs Before Code**          | Every task carries a `[Story: FR-CI-XXX]` or `[Story: ADR-NNN]` traceability marker.                                                             |
| **IV — Semantic Deltas**             | Phase 5.1 produces the new consolidated spec at archive. No MODIFIED, no REMOVED — purely additive.                                              |
| **V — Conformance Gate**             | The workflow itself becomes the gate after Phase 6 archive. The gate-on-the-gate is `g1.test.sh`.                                                  |
| **VIII — Infrastructure**            | Phase 2 — Atlas-led ; follows ADR-001..010.                                                                                                       |
| **X — Quality**                      | Phase 4 (NFR enforcement) + Aegis security pass (permissions, action pinning, no continue-on-error). Quality is an explicit phase.               |

No task gates pulled forward, no test deferred to "after archive",
no unpinned action allowed anywhere. Compliance gate : **PASS**.

---

## Traceability summary

- **11 FRs** (FR-CI-001..011) → covered by Phases 2 (workflow, FR-CI-001..007 + 009), 3 (FR-CI-008 + 011), 1+2.1+4.5 (FR-CI-010).
- **6 NFRs** (NFR-CI-001..006) → covered by Phases 4.1 (size), 4.2 (failure semantics), 4.3 (permissions), 4.4 (backwards compat), and the workflow runtime budget (NFR-CI-001) and cache hit rate (NFR-CI-004) which are observed at run-time only (aspirational, validated by real CI execution).
- **7 ACs** → captured in `features/g1-forge-ci.feature` (Phase 3.5) ; AC-006 + AC-007 marked aspirational (only observable on real GitHub Actions).
- **10 ADRs** → each ADR is referenced by at least one task's `[Story: ADR-XXX]` link. No orphaned ADR.

Plan is self-contained : every spec artefact has at least one task
that produces it, every task has at least one spec artefact it
serves.
