# Tasks — `t7-ci-line-budget-440`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — measure the lock-step set

- [x] **T1.1** Push `forge-ci.yml` one line over the cap; run ten candidate harnesses;
      record which fire; restore. **Five fired**, not the four the standard names.
      [Story: FR-T7CB-003, NFR-T7CB-002]

## T2 — apply

- [x] **T2.1** 420 → 440 in c1, g1, t5-1, t5-otel-live-run, b6-8.
      [Story: FR-T7CB-001]
- [x] **T2.2** `NFR-CI-002` in `.forge/specs/forge-ci.md`, and the clause in
      `forge-self-ci.md` — with the reason, the date, and "four" → "five".
      [Story: FR-T7CB-002, FR-T7CB-003]
- [x] **T2.3** Record the structural remedy and its measured obstacle in both.
      [Story: FR-T7CB-004]

## T3 — prove it

- [x] **T3.1** Re-probe at 421 lines: **0 guards fire**, where 5 fired before.
      [Story: FR-T7CB-001]
- [x] **T3.2** The five harnesses green; no `420` assertion left in any harness.
      [Story: FR-T7CB-001]

## T4 — records

- [x] **T4.1** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-T7CB-005]

## T5 — regression

- [x] **T5.1** Full 81-entry CI matrix.
      [Story: NFR-T7CB-001]
- [x] **T5.2** `verify.sh` + `constitution-linter.sh` after the status flip; shellcheck.
      [Story: NFR-T7CB-001]

## Negative scope guard

- [x] **T6.1** `forge-ci.yml` unchanged — `git diff` shows no edit to the workflow.
      [Story: NFR-T7CB-001]
