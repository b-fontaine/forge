# Tasks — `b9-4-archetype-decision-tree`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — establish the facts before writing them down

- [x] **T1.1** Audit the matrix against the registry under adversarial review; keep
      only what survives refutation.
      [Story: FR-B94-004, FR-B94-005, FR-B94-006]
- [x] **T1.2** Find what establishes the iOS rule in-repo. Result: routing restated in
      four places, platform constraint in none.
      [Story: FR-B94-002, NFR-B94-001]
- [x] **T1.3** Mutation-probe the existing `b5.test.sh` matrix guard, one row deleted
      at a time, using CI's own invocation.
      [Story: FR-B94-007]
- [x] **T1.4** Measure what `forge init --archetype flutter-firebase` actually does.
      [Story: FR-B94-004, NFR-B94-001]
- [x] **T1.5** Confirm Kong and DBOS absence in the fresh-init 2.0.0 plan and
      templates.
      [Story: FR-B94-006]

## T2 — RED

- [x] **T2.1** Rewrite `b5.test.sh`'s FR-IW-009 guard: derived from
      `dispatch-table.yml`, scoped to table rows, anti-vacuity floors.
      [Story: FR-B94-007, NFR-B94-002]
- [x] **T2.2** `T-031` in `b9-2.test.sh` — the decision-tree content battery,
      presence assertions only.
      [Story: FR-B94-001, FR-B94-002, FR-B94-003]
- [x] **T2.3** Run both against the untouched document. **RED.**
      [Story: FR-B94-001, FR-B94-007]

## T3 — GREEN

- [x] **T3.1** The decision-tree section in `docs/ARCHETYPES.md`.
      [Story: FR-B94-001, FR-B94-002, FR-B94-003]
- [x] **T3.2** The `flutter-firebase` and `mobile-only` status cells.
      [Story: FR-B94-004, FR-B94-005]
- [x] **T3.3** The flagship Stack cell: Kong → Envoy, and the cancelled DBOS swap.
      [Story: FR-B94-006]
- [x] **T3.4** Run the guards. **GREEN.**
      [Story: FR-B94-001, FR-B94-007]

## T4 — prove the guards guard

- [x] **T4.1** Re-run the row-deletion probe against the NEW guard: every derived row
      must go RED, and `rust-cli-tui` must stay pinned.
      [Story: NFR-B94-002]
- [x] **T4.2** Simulate B.9.11: flip `mobile-pwa-first` to a non-candidate status in a
      scratch copy of `dispatch-table.yml` and confirm the guard then DEMANDS the row.
      [Story: FR-B94-007, ADR-B94-001]
- [x] **T4.3** Mutation-probe `T-031`: drop a documented fact, confirm RED.
      [Story: NFR-B94-002]

## T5 — records

- [x] **T5.1** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-B94-008]
- [x] **T5.2** Plan §0.14 / §5.2 / §11 and `.forge/product/roadmap.md`: B.9 7/11 →
      8/11 — both files.
      [Story: FR-B94-008]

## T6 — regression

- [x] **T6.1** `b5`, `b4`, `b9-2`, `t4` GREEN — `t4` pins the schema enum this brick
      reasons about.
      [Story: NFR-B94-003]
- [x] **T6.2** Full 80-entry CI matrix sweep + shellcheck.
      [Story: NFR-B94-003]
- [x] **T6.3** `verify.sh` + `constitution-linter.sh` **after** the status flip.
      [Story: NFR-B94-003]

## Negative scope guard

- [x] **T7.1** `git status` shows no file under `cli/`, `bin/`, `.forge/templates/`,
      `.forge/schemas/`, `.forge/scaffolding/`, `.forge/specs/`, and
      `docs/ARCHITECTURE-TARGET.md` unchanged. The `rust-cli-tui` row byte-identical.
      [Story: NFR-B94-003]
