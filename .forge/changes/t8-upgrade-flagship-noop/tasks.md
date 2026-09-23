# Tasks — `t8-upgrade-flagship-noop`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — measure the defect end-to-end

- [x] **T1.1** Render each scaffoldable archetype with its wrapper, commit it, and
      upgrade it both as a dry run and for real. The flagship gives exit 0, 548 skipped
      and a stamped manifest. The pre-`473cd36` driver gives exit 8 on the same kind of
      tree (548 unchanged / 8 conflicts on a render of the final tree; evidence P-1 and
      P-10).
      [Story: FR-T8UFN-002, NFR-T8UFN-002]
- [x] **T1.2** Trace the mechanism: `init.sh:208` copies the root declaration, and
      `_a7_project_archetype` only checks that it exists. The `mobile-pwa-first` skip is
      the Kotlin directory that was never relocated.
      [Story: FR-T8UFN-001, FR-T8UFN-003]

## T2 — RED

- [x] **T2.1** L1 cells for detection, render relocation and the skip report, each
      failing against the driver at the time.
      [Story: FR-T8UFN-001, FR-T8UFN-003, FR-T8UFN-004, NFR-T8UFN-003]
- [x] **T2.2** LIVE: add `files skipped: 0` to the `mobile-pwa-first` cell and add a
      flagship cell. Both must fail against the driver at the time.
      [Story: FR-T8UFN-002, FR-T8UFN-003]

## T3 — GREEN

- [x] **T3.1** Extract `_a7_archetype_plan`, and add the plan-renders-the-declaration
      condition to `_a7_project_archetype`.
      [Story: FR-T8UFN-001]
- [x] **T3.2** Kotlin relocation in `_a7_render_archetype`.
      [Story: FR-T8UFN-003]
- [x] **T3.3** The skip report in `_a7_main`.
      [Story: FR-T8UFN-004]

## T4 — prove it

- [x] **T4.1** Re-run T1.1. The flagship is back in framework mode, `mobile-pwa-first`
      reports 0 skipped, and the other three give the same results as before.
      [Story: FR-T8UFN-002, FR-T8UFN-003, NFR-T8UFN-002]
- [x] **T4.2** Mutation probes: revert each fix in turn and confirm its cell goes red.
      [Story: NFR-T8UFN-003]

## T5 — records

- [x] **T5.1** Correct plan §0.19, FR-T8UAS-001, ADR-T8UAS-001 and Q-002. Update the
      CHANGELOG, add plan §0.20, and update the roadmap's verification-gap paragraph.
      [Story: FR-T8UFN-005]

## T6 — regression

- [x] **T6.1** Replay the full `forge-ci` harness array, the gates and shellcheck, and
      check that `forge-ci.yml`'s line count is unchanged.
      [Story: NFR-T8UFN-001, NFR-T8UFN-002]

## T7 — independent review (Article V)

- [x] **T7.1** Run four review lanes: driver by reproduction, security, tests, and the
      written claims. Verify each finding adversarially. 30 of 33 confirmed, none
      blocking (evidence P-8).
      [Story: NFR-T8UFN-003]
- [x] **T7.2** RED for each confirmed code defect. Eight cells failed against the driver
      at the time: plan traversal, relocation gate, report wording, unreadable plan,
      version, planted snapshot, stamp after conflicts, temp leak.
      [Story: FR-T8UFN-001, FR-T8UFN-003, FR-T8UFN-004, FR-T8UFN-006..009]
- [x] **T7.3** GREEN: gates, single cleanup trap, no stamp on a conflicted run, escaped
      listing. Move the t8 cells out of `main()` and into the MANIFEST block.
      [Story: FR-T8UFN-006..009]
- [x] **T7.4** Eleven mutation probes on a copy of the repository, each caught by its own
      cell (evidence P-9). Re-measure on fresh renders of the final tree (P-10). Correct
      every confirmed documentary finding.
      [Story: NFR-T8UFN-003, FR-T8UFN-005]
- [x] **T7.5** Full regression replay on the final tree (P-11).
      [Story: NFR-T8UFN-001, NFR-T8UFN-002]
