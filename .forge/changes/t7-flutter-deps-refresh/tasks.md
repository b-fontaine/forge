# Tasks — `t7-flutter-deps-refresh`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — establish the ground

- [x] **T1.1** Read `_a7_resolve_owned_paths`: `forge upgrade` merges only `owned:`
      matches; `excluded:` is a subtractive filter. `pubspec.yaml` is in neither.
      [Story: FR-T7FD-005]
- [x] **T1.2** Map the guard collision: T-004 (git-clean) vs T-007 (byte-equivalence).
      Put the choice to the maintainer.
      [Story: FR-T7FD-007, ADR-T7FD-001]
- [x] **T1.3** Confirm the Flutter toolchain is present, so bumps can be proven.
      [Story: NFR-T7FD-003]
- [x] **T1.4** `flutter pub outdated` on a real render for the resolvable set.
      [Story: FR-T7FD-001, NFR-T7FD-003]
- [x] **T1.5** Read the two breaking changelogs and the installed sources for the new
      signatures.
      [Story: FR-T7FD-003]

## T2 — probe before writing

- [x] **T2.1** Bump on a throwaway render; `flutter analyze` → exactly 3 errors, all in
      two files, none from `flutter_appauth` despite five majors.
      [Story: FR-T7FD-003]
- [x] **T2.2** `flutter test` fails — and fails identically on a **pristine** render.
      Pre-existing, not caused here.
      [Story: FR-T7FD-006]

## T3 — apply

- [x] **T3.1** Nine pins + the SDK floor, both archetypes.
      [Story: FR-T7FD-001, FR-T7FD-002]
- [x] **T3.2** `local_auth` 3.x and `flutter_secure_storage` 11.x call sites.
      [Story: FR-T7FD-003]
- [x] **T3.3** The 9 → 11 storage note in the pubspec template.
      [Story: FR-T7FD-004]
- [x] **T3.4** `owned:` += the dependency manifests.
      [Story: FR-T7FD-005]
- [x] **T3.5** The smoke test initialises OTel; `BiometricLockWidget` moves inside
      `MaterialApp` via `builder:`.
      [Story: FR-T7FD-006]
- [x] **T3.6** Re-scope `b9-2` T-004, `b9-3` T-022; exclude the owned-paths file from
      T-007; add T-034/035/036.
      [Story: FR-T7FD-007, FR-T7FD-008]

## T4 — prove it

- [x] **T4.1** Both archetypes: render, `pub get`, `flutter analyze` **clean**,
      `flutter test` **passes**.
      [Story: FR-T7FD-001, FR-T7FD-006]
- [x] **T4.2** T-007 green — the two renders still byte-identical.
      [Story: NFR-T7FD-001]
- [x] **T4.3** `b4` green — the frozen snapshot still matches its `.sha256`.
      [Story: NFR-T7FD-002]
- [x] **T4.4** Mutation-probe T-034/035/036: un-own a manifest, diverge the sets, slide
      a pin back a major. 5/5 RED.
      [Story: NFR-T7FD-004]

## T5 — records

- [x] **T5.1** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-T7FD-009]

## T6 — regression

- [x] **T6.1** Full 81-entry CI matrix. Two further coupled guards surfaced and were
      handled: `t5-otel-dartastic` (re-bundle `cli/assets/`) and `b9-3` T-022.
      [Story: FR-T7FD-007]
- [x] **T6.2** `verify.sh` + `constitution-linter.sh` **after** the status flip.
      [Story: NFR-T7FD-001]
- [x] **T6.3** shellcheck.
      [Story: NFR-T7FD-001]

## Negative scope guard

- [x] **T7.1** The frozen snapshot is untouched; no re-scoped guard became a
      tautology; `web-pwa/` source ownership unchanged.
      [Story: NFR-T7FD-002, ADR-T7FD-002]
