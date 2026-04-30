# Tasks: demo-002-greeting-screen

<!-- Audit: C.1 (illustrative demo) -->
<!-- TDD-ordered. All tasks marked [x] post-archive. -->

## Phase 1: Foundation — pubspec dependencies

- [x] Add `flutter_bloc`, `bloc_test`, `mocktail` to
  `frontend/pubspec.yaml`. Run `flutter pub get`.
  [Story: FR-FE-001]

## Phase 2: Domain port (TDD)

- [x] **RED** — Add abstract `GreetingRepository` port in
  `frontend/lib/features/greeting/domain/repository/`.
  [Story: FR-FE-002]
- [x] **GREEN** — Implement the port (interface only — no test
  needed at this level since it's an abstract class).
  [Story: FR-FE-002]

## Phase 3: Data adapter (TDD)

- [x] **RED** — Test in
  `frontend/test/features/greeting/data/greeting_repository_impl_test.dart`
  asserting `greet("Alice")` returns `"Hello, Alice!"`.
  Run `flutter test` — confirm fail. [Story: FR-FE-002]
- [x] **GREEN** — Implement `GreetingRepositoryImpl` with the
  fake. Run — confirm pass. [Story: FR-FE-002]
- [x] **RED** — Add test asserting `greet("")` returns
  `"Hello, world!"`. Run — confirm pass (already covered).
  [Story: FR-FE-002]

## Phase 4: Cubit (TDD)

- [x] **RED** — `bloc_test` in
  `frontend/test/features/greeting/cubit/greeting_cubit_test.dart`
  asserting `sayHello("Alice")` emits Loading then
  `Success("Hello, Alice!")`. Run — fail. [Story: FR-FE-001]
- [x] **GREEN** — Implement `GreetingCubit` extending `Cubit`,
  delegating to the repository. Run — pass. [Story: FR-FE-001]

## Phase 5: Widget (TDD)

- [x] **RED** — Widget test in
  `frontend/test/features/greeting/presentation/greeting_screen_test.dart`
  asserting initial render shows TextField + Button. Run — fail.
  [Story: FR-FE-003]
- [x] **GREEN** — Implement `GreetingScreen` consuming
  `GreetingCubit` via `BlocBuilder`. Run — pass.
  [Story: FR-FE-003]
- [x] **RED** — Test asserting `tap("Say hello")` results in
  greeting text appearing. Run — fail. [Story: FR-FE-003]
- [x] **GREEN** — Wire button onPressed to cubit.sayHello. Run —
  pass. [Story: FR-FE-003]

## Phase 6: Golden test (Article VI.8)

- [x] Add a golden test in the same widget-test file rendering
  the initial state. Run `flutter test --update-goldens` once,
  then commit the golden file. Confirm subsequent runs pass.
  [Story: Article VI.8]

## Phase 7: BDD (Article II)

- [x] Author `features/greeting_screen.feature` with the two
  scenarios from `specs.md`.
- [x] Add a placeholder integration test
  (`frontend/integration_test/greeting_bdd_test.dart`) marking
  the BDD scenarios as documented but not yet runtime-wired
  (bdd_widget_test setup is non-trivial and out of scope for this
  demo's runtime — left as a follow-up task tracked in the
  example's `c1-followup` candidate).

## Phase 8: A11y check

- [x] Run `flutter analyze --fatal-infos` from `frontend/`
  — zero warnings.
- [x] Verify semantic labels render correctly via the Flutter
  Inspector / a11y tool.

## Phase 9: Quality gate (Nemesis) + archive

- [x] Run `bash .forge/scripts/verify.sh` from the example tree
  root — frontend section all green.
- [x] /forge:archive merges this demo's specs and updates
  `.forge.yaml` to `status: archived`.
