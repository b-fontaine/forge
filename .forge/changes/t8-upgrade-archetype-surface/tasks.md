# Tasks — `t8-upgrade-archetype-surface`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — measure the defect end-to-end

- [x] **T1.1** Render `mobile-pwa-first` with its wrapper, commit it, run
      `forge upgrade --dry-run`: 49 conflicts, 507 preserved, exit 8, and neither
      `pubspec.yaml` nor `web-pwa/package.json` mentioned.
      [Story: FR-T8UAS-001, FR-T8UAS-002]
- [x] **T1.2** Confirm the mechanism at the source: the framework list resolves 556
      paths; the project declares 10 that are never read.
      [Story: FR-T8UAS-002, FR-T8UAS-005]

## T2 — RED

- [x] **T2.1** New `a7.test.sh` cells: an archetype project upgrades with zero conflicts;
      its declared paths are the ones considered; a framework path is NOT merged into it.
      All must fail against the current driver.
      [Story: FR-T8UAS-001, FR-T8UAS-002, FR-T8UAS-005, NFR-T8UAS-003]

## T3 — GREEN

- [x] **T3.1** Archetype detection per ADR-T8UAS-001.
      [Story: FR-T8UAS-006]
- [x] **T3.2** Owned set from the project's declaration; RIGHT rendered via `overlay.sh`;
      the rendered manifest discarded.
      [Story: FR-T8UAS-002, FR-T8UAS-003, FR-T8UAS-007]
- [x] **T3.3** BASE rendered from the snapshot's template tree, degrading to the 2-way
      fallback when absent.
      [Story: FR-T8UAS-004, NFR-T8UAS-001]

## T4 — prove it

- [x] **T4.1** Re-run the T1.1 scenario: zero conflicts, exit 0.
      [Story: FR-T8UAS-001]
- [x] **T4.2** A framework pin bump reaches an untouched project as `upgraded`, and an
      adopter-edited file is `preserved`.
      [Story: FR-T8UAS-002, FR-T8UAS-004]
- [x] **T4.3** Mutation probes, including the degrade path (render made to fail) and the
      manifest-clobber guard.
      [Story: NFR-T8UAS-001, NFR-T8UAS-003, FR-T8UAS-007]
- [x] **T4.4** `a7.test.sh` green as a whole; the framework-shaped cells unchanged.
      [Story: FR-T8UAS-006]

## T5 — records

- [x] **T5.1** Retract the `t7-flutter-deps-refresh` claim where stated; answer
      `t7-qwik-deps-refresh` Q-007; CHANGELOG, roadmap, plan §0.N.
      [Story: FR-T8UAS-008]

## T6 — regression

- [x] **T6.1** Full `forge-ci` replay on the committed tree, gates, shellcheck,
      `forge-ci.yml` still 421 lines.
      [Story: NFR-T8UAS-002, NFR-T8UAS-003]

## Negative scope guard

- [x] **T7.1** No behaviour change for framework-shaped projects; no snapshot rewritten;
      no raw `.tmpl` reaching a target; a failed render degrades rather than merging an
      empty set.
      [Story: FR-T8UAS-006, NFR-T8UAS-001]
