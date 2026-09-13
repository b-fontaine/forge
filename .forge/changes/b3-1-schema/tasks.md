# Tasks — `b3-1-schema`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — establish what the plan does and does not say

- [x] **T1.1** Confirm B.3's fourteen-item list is absent from the repository; find the
      only statement of its content (`roadmap.md:202`).
      [Story: ADR-B31-001]
- [x] **T1.2** Confirm B.6.1 / B.7.1 / B.9.1 are each "the schema" — the precedent the
      inference rests on.
      [Story: ADR-B31-001]
- [x] **T1.3** Read the validator's `layer_profile` contract and the taxonomy's ratified
      description of the archetype.
      [Story: FR-B31-003, FR-B31-004]

## T2 — RED

- [x] **T2.1** `b3-1.test.sh`, 18 L1.
      [Story: FR-B31-001..009]
- [x] **T2.2** Run with no schema. **RED on 16**; the two negatives pass, correctly.
      [Story: FR-B31-001]

## T3 — GREEN

- [x] **T3.1** `.forge/schemas/rust-cli-tui/1.0.0.yaml`.
      [Story: FR-B31-001..008]
- [x] **T3.2** Run. **18/18**, live validator included.
      [Story: FR-B31-009]
- [x] **T3.3** Register `b3-1.test.sh` in `forge-ci.yml` (420 → 421, cap 440).
      [Story: FR-B31-010]

## T4 — prove the guards guard

- [x] **T4.1** Nine mutation probes: flip the stage, flip scaffoldable, change the
      profile, strip a layer agent, add an `extends:` key, drop a review gate, sneak in
      a pin, point a `delivered_by` outside B.3, delete the inference note.
      **8/9 RED first pass** — the inference needle survived, because the bare word
      recurs later in the header. Narrowed and re-probed: **9/9**.
      [Story: NFR-B31-003]
- [x] **T4.2** Fix T-009's own failure message, which command-substituted its backticks
      and printed an empty identifier.
      [Story: NFR-B31-003]

## T5 — records

- [x] **T5.1** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-B31-010]

## T6 — regression

- [x] **T6.1** Full 82-entry CI matrix.
      [Story: NFR-B31-001]
- [x] **T6.2** `verify.sh` + `constitution-linter.sh` after the status flip; shellcheck.
      [Story: NFR-B31-001]

## Negative scope guard

- [x] **T7.1** No shipped schema, no taxonomy enum, no dispatch-table edit — asserted by
      T-017 and T-018, not only by inspection.
      [Story: NFR-B31-001, NFR-B31-002]
