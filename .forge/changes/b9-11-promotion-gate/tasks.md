# Tasks — `b9-11-promotion-gate`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — map the cascade before moving anything

- [x] **T1.1** Sweep every assertion of `candidate` / `scaffoldable: false` for this
      archetype; separate real assertions from comments.
      [Story: FR-B911-005]
- [x] **T1.2** Read the `b7-6` precedent (`d21dda1`): the cli Vitest job is
      data-driven off the dispatch `status`, and there is no green state that keeps
      `status: candidate`.
      [Story: FR-B911-003, NFR-B911-002]
- [x] **T1.3** Confirm the wrapper's gate reads the schema, so the flip needs no
      `bin/` edit.
      [Story: FR-B911-007]
- [x] **T1.4** Confirm `forge-ci.yml` is 419/420 and one entry fits.
      [Story: FR-B911-008]

## T2 — RED

- [x] **T2.1** `.forge/scripts/tests/b9.test.sh` — 28 L1 + 2 L2 asserting the
      **promoted** state.
      [Story: FR-B911-001]
- [x] **T2.2** Run against the unpromoted tree. **RED**, every cell that depends on
      the flip, for the stated reason.
      [Story: FR-B911-001]

## T3 — GREEN, atomically

- [x] **T3.1** Flip the schema (`stage`, `scaffoldable`, header block).
      [Story: FR-B911-002]
- [x] **T3.2** Flip the dispatch status in the same edit — no green state in between.
      [Story: FR-B911-003, NFR-B911-001]
- [x] **T3.3** Invert the six held sibling guards; none deleted.
      [Story: FR-B911-005, ADR-B911-001]
- [x] **T3.4** `cli/test/e2e/archetype-fixtures/mobile-pwa-first.yml`.
      [Story: FR-B911-004]
- [x] **T3.5** Discharge the two planted tripwires: the `docs/ARCHETYPES.md` row, and
      the `MIGRATION-PATHS.md` status paragraph + `T-028`'s battery.
      [Story: FR-B911-006]
- [x] **T3.6** Register `b9.test.sh` in `forge-ci.yml` (419 → 420).
      [Story: FR-B911-008]

## T4 — prove it

- [x] **T4.1** The wrapper scaffolds **without** `FORGE_MPF_FORCE_SCAFFOLD`.
      [Story: FR-B911-007]
- [x] **T4.2** `forge init --archetype mobile-pwa-first` renders instead of exiting 3.
      [Story: FR-B911-002, FR-B911-003]
- [x] **T4.3** Mutation-probe `b9.test.sh`: revert each flipped field in turn, confirm
      RED, restore.
      [Story: NFR-B911-004]
- [x] **T4.4** Confirm `forge-ci.yml` is exactly 420 lines and the budget guards pass.
      [Story: FR-B911-008]

## T5 — records

- [x] **T5.1** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-B911-009]
- [x] **T5.2** Plan §0.14 / §5.2 / §11 and `.forge/product/roadmap.md`: B.9
      **11/11 COMPLETE** — both files.
      [Story: FR-B911-009]

## T6 — regression

- [x] **T6.1** `b9`, `b9-1`, `b9-2`, `b9-3`, `b5`, `b4`, `b8-2`, `t5-1`, `c1`, `b6-8`
      GREEN.
      [Story: NFR-B911-001]
- [x] **T6.2** Full 81-entry CI matrix sweep + shellcheck.
      [Story: NFR-B911-002]
- [x] **T6.3** **`cd cli && npm test`** — the job `b7-6`'s shell-only repro missed.
      [Story: NFR-B911-002]
- [x] **T6.4** `verify.sh` + `constitution-linter.sh` **after** the status flip.
      [Story: NFR-B911-001]

## Negative scope guard

- [x] **T7.1** `git status` shows no file under `.forge/templates/`,
      `.forge/scaffold-snapshots/`, and no `bin/` source change.
      [Story: NFR-B911-003]
