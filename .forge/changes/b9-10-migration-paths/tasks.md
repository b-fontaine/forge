# Tasks — `b9-10-migration-paths`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — establish the facts before writing them down

- [x] **T1.1** Confirm `docs/MIGRATION-PATHS.md` indexes only T.5, and that the
      flagship migration is absent from it.
      [Story: FR-B910-005]
- [x] **T1.2** `sha256sum` the two archetypes' `framework-owned-paths.yml.tmpl` and
      count `web-pwa` occurrences.
      [Story: FR-B910-007]
- [x] **T1.3** Re-probe the migration end-to-end: file count, modified count, the
      diff against a native render, and the three manifest fields.
      [Story: FR-B910-002, NFR-B910-001]
- [x] **T1.4** Provoke every exit code the section will tabulate.
      [Story: FR-B910-003, NFR-B910-001]

## T2 — RED

- [x] **T2.1** `T-028`/`T-029`/`T-030` in `b9-2.test.sh` — positive assertions only
      in the content battery (`b9-2::T-013` trap), no pipe into an early-exiting
      reader.
      [Story: FR-B910-001, FR-B910-005, NFR-B910-002]
- [x] **T2.2** Run against the unedited document. **RED** on the three, naming the
      absent section and the unindexed driver.
      [Story: FR-B910-001]

## T3 — GREEN

- [x] **T3.1** `docs/MIGRATION-PATHS.md`: preamble boundary, index table, B.9
      cross-archetype section. T.5 section left byte-unchanged.
      [Story: FR-B910-001, FR-B910-002, FR-B910-003, FR-B910-004, FR-B910-006,
      FR-B910-007, FR-B910-008, NFR-B910-004]
- [x] **T3.2** `docs/MIGRATIONS.md`: reciprocal cross-reference line.
      [Story: FR-B910-006]
- [x] **T3.3** Run the guards. **GREEN.**
      [Story: FR-B910-001]

## T4 — prove the guards guard

- [x] **T4.1** Mutation-probe each guard: mutate the real document (the guards read
      it by absolute path), run the harness, restore, verify the restore by sha256.
      Four probes. **`T-029` survived the one that deleted the flagship's index row**
      — it grepped the whole file, and the rollback prose names that script. Rescoped
      to the `## Index` table's rows, with an anti-vacuity floor on both driver count
      and row count. Re-run: 4/4 RED.
      [Story: NFR-B910-002, FR-B910-005]
- [x] **T4.2** Confirm the T.5 section is byte-unchanged (`sha256` of the extracted
      range before/after).
      [Story: NFR-B910-004]

## T5 — records

- [x] **T5.1** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-B910-009]
- [x] **T5.2** Plan §5.2 / §0.14 / §11 and `.forge/product/roadmap.md`: B.9 6/11 →
      7/11 — both files (the resync-forgotten lesson).
      [Story: FR-B910-009]

## T6 — regression

- [x] **T6.1** `b9-2`, `b8-10`, `b8-12`, `b8-13` GREEN — the last three assert
      `docs/MIGRATIONS.md` content.
      [Story: NFR-B910-003]
- [x] **T6.2** Full 80-entry CI matrix sweep + shellcheck.
      [Story: NFR-B910-003]
- [x] **T6.3** `verify.sh` + `constitution-linter.sh` **after** the status flip.
      [Story: NFR-B910-003]

## Negative scope guard

- [x] **T7.1** `git diff --stat` shows no file under `bin/`, `.forge/templates/`,
      `.forge/schemas/` or `.forge/scaffolding/`.
      [Story: NFR-B910-003]
