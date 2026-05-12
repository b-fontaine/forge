# Tasks: i5-compliance-workflow
<!-- Status: archived -->
<!-- Schema: default -->

## Convention

- TDD order is **immutable** : write the test, watch it fail
  (RED), write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-I5-CW-XXX]` (Article V.1, enforced
  by `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- Each phase ends with a **gate task** that runs
  `bash .forge/scripts/tests/i5.test.sh` (and `verify.sh` /
  `constitution-linter.sh` where relevant) and confirms expected
  counter movement.
- ADRs from `design.md` (ADR-I5-CW-001..003) are honored verbatim
  ; deviations require a new ADR.

---

## Phase 1 — Foundation : RED harness + CI registration

Goal : `i5.test.sh` exists with **16 L1 + 1 L2 stubs** ; L1
stubs FAIL (full RED witness for the 16 L1 anchors) ; L2 returns
0 (skip-pass by default per ADR-I5-CW-003) ; CI registration done.

### T-HAR — `i5.test.sh` skeleton

- [ ] **T-HAR-001** : Create `.forge/scripts/tests/i5.test.sh`
      with bash header (`#!/usr/bin/env bash`,
      `set -uo pipefail`), source `_helpers.sh`, PASS/FAIL
      counters reset, `--level` parsing for `1|2|1,2|all`,
      audit comment `# Audit: I.5 (i5-compliance-workflow)`,
      `print_summary` close-out. Mirror the I.6 / I.3 layout.
      [Story: FR-I5-CW-114 / FR-I5-CW-115 / FR-I5-CW-122]
- [ ] **T-HAR-002** : Define the path variables at the top of the
      harness :
      - `WORKFLOW_YML` → `.github/workflows/forge-compliance.yml`
      - `STD_FILE` → `.forge/standards/global/forge-compliance-workflow.md`
      - `INDEX_YML` → `.forge/standards/index.yml`
      - `REVIEW_MD` → `.forge/standards/REVIEW.md`
      - `COMPLIANCE_DOC` → `docs/COMPLIANCE.md`
      - `CHANGELOG_MD` → `CHANGELOG.md`
      - `FORGE_CI_YML` → `.github/workflows/forge-ci.yml`
      [Story: FR-I5-CW-114]
- [ ] **T-HAR-003** : Add **16 L1 test stubs** all returning
      `_not_implemented` covering the 16 anchor IDs in
      `design.md` § "L1 unit-level" table.
      [Story: FR-I5-CW-116]
- [ ] **T-HAR-004** [P] : Add **1 L2 test stub**
      (`_test_i5_l2_act_workflow_call`) that returns 0 by
      default (skip-pass per ADR-I5-CW-003) but actually emits
      the gated `[INFO: ...]` lines per FR-I5-CW-117.
      [Story: FR-I5-CW-117]
- [ ] **T-HAR-005** : Add the test runner — iterate through the
      16 L1 functions, call `run_test`, gate L2 on `--level`
      containing `2` or `all`, call `print_summary`. Exit 0 if
      `FAIL == 0`, else 1. [Story: FR-I5-CW-121]
- [ ] **T-HAR-006** [P] : Register `i5.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `i3.test.sh` with `--level 1`. Keep
      the file under 300 lines (NFR-CI-002 / NFR-I5-CW-006).
      [Story: FR-I5-CW-120]
- [ ] **T-HAR-007** : RED gate — confirm
      `bash .forge/scripts/tests/i5.test.sh --level 1` exits 1
      with `Failed: 16 / Passed: 0`. [Story: FR-I5-CW-121]

### Phase 1 exit gate

`i5.test.sh --level 1` exits 1 with FAIL = 16. `forge-ci.yml`
matrix updated, still under 300 lines. `verify.sh` overall PASS
unchanged. `constitution-linter.sh` overall PASS unchanged.

---

## Phase 2 — Workflow + standard (production code)

Goal : the reusable workflow YAML + standard ship. After this
phase, 8-9 of 16 L1 tests flip GREEN.

### T-WF — Reusable workflow

- [ ] **T-WF-001** : RED witness — confirm the 8 workflow-related
      L1 tests still FAIL.
      [Story: FR-I5-CW-001..060]
- [ ] **T-WF-002** : Create
      `.github/workflows/forge-compliance.yml` with :
      - First 10 lines : audit comment
        `# <!-- Audit: I.5 (i5-compliance-workflow) -->` +
        purpose comment.
      - `name: forge-compliance`.
      - `on: workflow_call:` block with the three inputs
        (`eu-tier` required, `target-dir` default `.`,
        `artefact-name` default `forge-compliance-artefacts`)
        and the one output (`artefact-path`).
      - `permissions: contents: read`.
      - `concurrency:` group keyed on
        `forge-compliance-${{ github.ref }}-${{ inputs.eu-tier }}`
        with `cancel-in-progress: false`.
      - Single job `compliance` on `ubuntu-latest` with
        `outputs.artefact-path`.
      - 10 steps : checkout, setup-python, install-pyyaml,
        validate-tier, resolve-epoch, demeter, linter, sbom
        (continue-on-error), bundle (writes
        `path=...` to `$GITHUB_OUTPUT`), upload-artifact,
        aggregate.
      [Story: FR-I5-CW-001..060]
- [ ] **T-WF-003** : Run `bash .forge/scripts/tests/i5.test.sh
      --level 1` ; expect tests 1-8 (workflow-related) flip
      GREEN. [Story: FR-I5-CW-001..060]

### T-STD — Standard file

- [ ] **T-STD-001** : RED witness — confirm
      `_test_i5_009..012` still FAIL.
      [Story: FR-I5-CW-070..085]
- [ ] **T-STD-002** : Create
      `.forge/standards/global/forge-compliance-workflow.md`
      with :
      - First 5 lines : audit comment
        `<!-- Audit: I.5 (i5-compliance-workflow) -->` +
        trigger comment
        `<!-- Trigger: compliance, forge-compliance.yml,
        reusable-workflow, workflow_call, eu-tier,
        ci-enforcement, regulatory-handoff, github-actions -->`.
      - H1 : `# Standard — Forge Compliance Workflow`.
      - Frontmatter narrative block (version 1.0.0,
        last_reviewed 2026-05-12, expires_at 2027-05-12,
        exception_constitutional false, linter_rule null,
        enforcement, forbidden, rationale).
      - 7 H2 sections per FR-I5-CW-075 — Purpose / Inputs and
        outputs (3+1 tables) / Step-by-step contract (4 script
        refs) / Tier-scaled severity aggregation /
        Consumption protocol (uses: snippet) / Interdictions
        (≥ 3 MUST NOT) / Constitutional Compliance.
      - Demeter / Aegis / Janus cross-link, forward-
        compatibility note for Themis-territory expansion.
      [Story: FR-I5-CW-070..085]
- [ ] **T-STD-003** : GREEN witness — run
      `bash .forge/scripts/tests/i5.test.sh --level 1` ; expect
      `_test_i5_009..012` flip GREEN.
      [Story: FR-I5-CW-070..085]

### Phase 2 exit gate

12 of 16 L1 tests GREEN. `verify.sh` overall PASS unchanged.

---

## Phase 3 — Index + REVIEW + docs

### T-IDX — Standards index entry

- [ ] **T-IDX-001** : Edit `.forge/standards/index.yml` to append
      a new entry under a new comment section header
      `# ─── I.5 — Forge compliance workflow
      (i5-compliance-workflow) ───────────────` after the
      existing I.6 section. Entry shape :
      ```yaml
        - id: global/forge-compliance-workflow
          path: standards/global/forge-compliance-workflow.md
          triggers: [compliance, forge-compliance.yml, reusable-workflow, workflow_call, eu-tier, ci-enforcement, regulatory-handoff, github-actions]
          scope: all
          priority: high
      ```
      [Story: FR-I5-CW-090..094]
- [ ] **T-IDX-002** : GREEN witness — run
      `bash .forge/scripts/tests/i5.test.sh --level 1` ; expect
      `_test_i5_013_index_entry` flips GREEN.
      [Story: FR-I5-CW-090]

### T-RVW — REVIEW.md entry

- [ ] **T-RVW-001** : Edit `.forge/standards/REVIEW.md` to append
      a new H2 section after the last entry :
      `## 2026-05-12 — Initial ratification (i5-compliance-workflow)`
      with the standard's version, decision KEEP, next review
      2027-05-12, and explanatory notes citing the workflow +
      I.3 / I.6 / K.3 / J.8 dependencies.
      [Story: FR-I5-CW-100..101]
- [ ] **T-RVW-002** : GREEN witness — run
      `bash .forge/scripts/tests/i5.test.sh --level 1` ; expect
      `_test_i5_014_review_entry` flips GREEN.
      [Story: FR-I5-CW-100]

### T-DOC — `docs/COMPLIANCE.md` update

- [ ] **T-DOC-001** : Edit `docs/COMPLIANCE.md` to append an H2
      section `## Reusable compliance workflow` after the
      existing `## Auditor hand-off bundle` H2. Include :
      - Cross-links to `.github/workflows/forge-compliance.yml`
        and `.forge/standards/global/forge-compliance-workflow.md`.
      - Copy-pasteable `uses:` YAML code block.
      - Mention of how `eu-tier` is supplied (per-call input,
        independent of any `.forge/.forge-tier` ledger).
      [Story: FR-I5-CW-110..113]
- [ ] **T-DOC-002** : GREEN witness — run
      `bash .forge/scripts/tests/i5.test.sh --level 1` ; expect
      `_test_i5_015_compliance_doc_h2` flips GREEN.
      [Story: FR-I5-CW-110..112]

### Phase 3 exit gate

15 of 16 L1 tests GREEN.

---

## Phase 4 — CHANGELOG + plan + roadmap

### T-LOG — CHANGELOG entry

- [ ] **T-LOG-001** : Edit `CHANGELOG.md` `## [Unreleased]` to
      add (immediately after the existing I.6 entry) :
      ```markdown
      ### Added — I.5 forge-compliance.yml reusable workflow (`i5-compliance-workflow`)

      Reusable GitHub Actions workflow for adopter repos to
      gate PR / push compliance via a single `uses:` reference.

      - **`.github/workflows/forge-compliance.yml`** — reusable
        workflow triggered by `on: workflow_call:` with three
        inputs (`eu-tier` required, `target-dir` default `.`,
        `artefact-name` default `forge-compliance-artefacts`)
        and one output (`artefact-path`). Orchestrates the
        four EU-compliance checks Forge already ships :
        Demeter (`bin/forge-demeter-scan.sh`), constitution
        linter (`.forge/scripts/constitution-linter.sh` incl.
        I.3 ADR-I3-001 T3-Forbidden section), CycloneDX SBOM
        (`bin/forge-sbom.sh`), compliance bundle
        (`.forge/scripts/compliance/bundle.sh`). Uploads the
        deterministic `.tgz` via
        `actions/upload-artifact@v4`. Aggregates the four
        scripts' exit-code envelopes per ADR-I5-CW-001 ;
        SBOM no-lockfile remains non-fatal at every tier.
      - **`.forge/standards/global/forge-compliance-workflow.md`
        v1.0.0** — 7 H2 sections (Purpose / Inputs and outputs
        / Step-by-step contract / Tier-scaled severity
        aggregation / Consumption protocol / Interdictions /
        Constitutional Compliance) + 3 MUST NOT clauses.
        Frontmatter pins `version: 1.0.0`, `last_reviewed:
        2026-05-12`, `expires_at: 2027-05-12`, `linter_rule:
        null`.
      - **`.forge/standards/index.yml` entry** — id
        `global/forge-compliance-workflow`, 8 triggers, scope
        all, priority high.
      - **`.forge/standards/REVIEW.md` birth entry** dated
        2026-05-12, Initial ratification.
      - **`docs/COMPLIANCE.md`** — new H2 `## Reusable
        compliance workflow` with copy-pasteable `uses:`
        block.
      - **`.forge/scripts/tests/i5.test.sh`** — 16 L1 grep-
        based tests + 1 L2 opt-in fixture
        (`FORGE_I5_ACT=1` + `command -v act` gates per
        ADR-I5-CW-003). Registered in `forge-ci.yml`
        `harness` matrix.

      Three ADRs resolve the design open questions :
      exit-code aggregation = trust each script's tier
      scaling end-to-end (ADR-I5-CW-001) ;
      `SOURCE_DATE_EPOCH` source = `github.event.head_commit.timestamp`
      with `github.run_started_at` fallback
      (ADR-I5-CW-002) ; L2 act gating = opt-in via
      `FORGE_I5_ACT=1` (ADR-I5-CW-003).

      Forward-stable for Themis-territory checks (NIS2 /
      DORA / CRA / AI Act regulatory deadlines) — additive
      step additions per FR-I5-CW-083.

      No constitutional amendment required ; Articles III.4,
      V, XI, XII compliance preserved.
      ```
      [Story: FR-I5-CW-142]
- [ ] **T-LOG-002** : GREEN witness — run
      `bash .forge/scripts/tests/i5.test.sh --level 1` ; expect
      `_test_i5_016_changelog_entry` flips GREEN.
      [Story: FR-I5-CW-142]

### T-INV — Plan + roadmap inventory delta

- [ ] **T-INV-001** [P] : Update `docs/new-archetypes-plan.md`
      row I.5 (line ~574 + line ~962-963 + line ~1093 + line
      ~1270) to record **I.5 Done 2026-05-12** with the change
      name citation. Update the "Modules en cours" /
      "Modules toujours en attente" sections accordingly.
      [Story: FR-I5-CW-140]
- [ ] **T-INV-002** [P] : Update `.forge/product/roadmap.md`
      inventory line ~130 + line ~169 + line ~189 + line ~228
      to record the I.5 delivery, mirroring the existing "I.3
      done" / "I.6 done" line style.
      [Story: FR-I5-CW-141]

### Phase 4 exit gate

16 of 16 L1 tests GREEN. L2 stays gated (skip-pass).
`verify.sh` overall PASS preserved. `constitution-linter.sh`
OVERALL PASS preserved. `forge-ci.yml` ≤ 300 lines. Status
flipped to `implemented`. Ready for `/forge:archive`.

---

## Phase 5 — Final gates + archive

### T-GAT — Final gates

- [ ] **T-GAT-001** : `bash .forge/scripts/verify.sh` — overall
      PASS (additive ; no regression).
      [Story: NFR-I5-CW-004 / NFR-I5-CW-008]
- [ ] **T-GAT-002** : `bash .forge/scripts/constitution-linter.sh`
      — OVERALL PASS (no `[NEEDS CLARIFICATION:]` inline ; no
      new Article touched). [Story: NFR-I5-CW-008]
- [ ] **T-GAT-003** : `bash .forge/scripts/tests/i5.test.sh
      --level 1` — 16/16 GREEN, exit 0.
      [Story: FR-I5-CW-121]
- [ ] **T-GAT-004** : `wc -l .github/workflows/forge-ci.yml`
      under 300 (NFR-CI-002 / NFR-I5-CW-006).
- [ ] **T-GAT-005** : `wc -l .github/workflows/forge-compliance.yml`
      under 200 (NFR-I5-CW-002 soft constraint).
- [ ] **T-GAT-006** : Status flip in `.forge.yaml` from
      `planned` / `implemented` to `archived`. Timeline
      populated with `specified`, `designed`, `planned`,
      `implemented`, `archived` dates all = 2026-05-12.

### Phase 5 exit gate

All gates GREEN. Status `archived`. The change is ready for a
single archive commit.

---

## Task summary

| Phase | Tasks | Notes                                                                                              |
|-------|-------|----------------------------------------------------------------------------------------------------|
| 1     | 7     | RED foundation : harness skeleton + 16 L1 stubs + 1 L2 stub + CI registration. All FAIL.            |
| 2     | 6     | Workflow + standard : 12 L1 tests flip GREEN.                                                       |
| 3     | 6     | Index + REVIEW + docs : 3 more L1 tests flip GREEN.                                                 |
| 4     | 4     | CHANGELOG + plan + roadmap : last L1 test GREEN.                                                    |
| 5     | 6     | Final gates : verify / constitution-linter PASS ; status archived.                                   |
| **Total** | **29** | TDD discipline preserved ; immutable RED→GREEN→REFACTOR cycle ; 16 L1 GREEN tests at end.        |
