# Tasks — `b9-5-bloc-generator`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — establish the ground before writing

- [x] **T1.1** Confirm the archetype has no proto source and is `layer_profile:
      client-only`, so the re-scope is forced rather than chosen.
      [Story: ADR-B95-001]
- [x] **T1.2** Read `lib/presentation/auth/auth_bloc.dart` end to end; extract the
      naming idiom the generator must reproduce.
      [Story: FR-B95-003]
- [x] **T1.3** Confirm `bloc_test` and `mocktail` are declared and used by nothing.
      [Story: FR-B95-006, NFR-B95-002]

## T2 — RED

- [x] **T2.1** `T-032`/`T-033` in `b9-2.test.sh` — shape/envelope, and the output
      battery on a generated fixture.
      [Story: FR-B95-001, NFR-B95-003]
- [x] **T2.2** Run with no script. **RED**, naming the absent generator.
      [Story: FR-B95-001]

## T3 — GREEN

- [x] **T3.1** `bin/forge-gen-bloc.sh`: preflight, descriptor parse, render, collision
      check, write.
      [Story: FR-B95-001..008]
- [x] **T3.2** Run the guards. **GREEN.**
      [Story: FR-B95-001]

## T4 — prove it

- [x] **T4.1** Generate a fixture feature and read all four files; confirm the idiom
      matches `auth_bloc.dart`'s.
      [Story: FR-B95-003, FR-B95-004]
- [x] **T4.2** Provoke every exit code: 0, 2, 5, 7 (each precondition), 8.
      [Story: FR-B95-007, FR-B95-008]
- [x] **T4.3** `--dry-run` writes nothing; a re-run refuses; `--force` overwrites.
      [Story: FR-B95-008]
- [x] **T4.4** Mutation-probe `T-033`: break one generated property at a time in the
      generator, confirm RED, restore.
      [Story: NFR-B95-004]

## T5 — records

- [x] **T5.1** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-B95-009]
- [x] **T5.2** Plan §0.14 / §5.2 / §11 and `.forge/product/roadmap.md`: B.9 8/11 →
      9/11 — both files.
      [Story: FR-B95-009]

## T6 — regression

- [x] **T6.1** `b9-2`, `b9-1`, `b4`, `b8-2` GREEN — the last two pin frozen trees this
      brick must not touch.
      [Story: NFR-B95-001]
- [x] **T6.2** Full 80-entry CI matrix sweep + shellcheck.
      [Story: NFR-B95-002]
- [x] **T6.3** `verify.sh` + `constitution-linter.sh` **after** the status flip.
      [Story: NFR-B95-001]

## Negative scope guard

- [x] **T7.1** `git status` shows no file under `.forge/templates/`,
      `.forge/scaffold-snapshots/`, `.forge/schemas/`; no `pubspec.yaml.tmpl` edited.
      [Story: NFR-B95-001, NFR-B95-002]
