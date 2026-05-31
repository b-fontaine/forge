<!-- Audit: B.8.3.b (b8-3b-validator-versioned-schema) -->
# Tasks: b8-3b-validator-versioned-schema

TDD-ordered. Prerequisite landed: commit `6175a61` (FR-GL-017 crash fix) — so
`validate-foundations.sh` exits 0 standalone and the new check, appended last in
`main()`, actually runs.

## Phase 1 — Harness RED
- [x] **T001** Author `.forge/scripts/tests/b8-3b.test.sh` from the `b8-3.test.sh`
  frame (`--level`, `_helpers.sh`, `run_test`, `print_summary`). [Story: FR-B83B-030]
- [x] **T002** Write the 13 L1 assertions (T-001..T-013 per design.md), incl. the
  discriminating negatives (assert the specific `FAIL: FR-GL-001-versioned:<file>`
  line + message, NOT bare exit code) via fully-controlled tmp `FORGE_ROOT`
  fixtures; real schema files never mutated. [Story: FR-B83B-010/011/012/004/032]
- [x] **T003** Run harness → confirm RED (the `check_versioned_schema_siblings`
  assertions T-001/T-002/T-004 + the negatives fail; function absent). [Story: FR-B83B-001]

## Phase 2 — Validator GREEN
- [x] **T004** Add `check_versioned_schema_siblings()` to `validate-foundations.sh`
  (generic glob `[0-9]*.[0-9]*.[0-9]*.yaml` per archetype dir; python3 invariant
  check: existing name/SemVer/stage/triple/phases + filename↔version + candidate⇒
  scaffoldable:false; emit `PASS:`/`FAIL: FR-GL-001-versioned:<arch>/<file>`).
  [Story: FR-B83B-001/002/010/011/012/013]
- [x] **T005** Wire one call to `check_versioned_schema_siblings` in `main()`
  (appended last, before `finalize`). [Story: FR-B83B-001]
- [x] **T006** Run harness → 13/13 GREEN. [Story: FR-B83B-*]

## Phase 3 — Backward-compat verification
- [x] **T007** `validate-foundations.sh` exits 0 standalone; emits the `2.0.0.yaml`
  PASS line + canonical `FR-GL-001` PASS. [Story: NFR-B83B-001/003]
- [x] **T008** `verify.sh` + `constitution-linter.sh` still PASS (candidate now
  visible, no regression); `verify.sh`/`constitution-linter.sh` byte-unchanged.
  [Story: NFR-B83B-001/002]
- [x] **T009** `git diff` shows ONLY `validate-foundations.sh` + the new harness +
  CI + CHANGELOG touched; frozen `schema.yaml` + `2.0.0.yaml` byte-unchanged.
  [Story: NFR-B83B-003]

## Phase 4 — Integration
- [x] **T010** Register `b8-3b.test.sh` as a one-line entry in the `forge-ci.yml`
  harness bash-array loop. [Story: FR-B83B-032]
- [x] **T011** CHANGELOG `[Unreleased]` entry. [Story: FR-B83B-042]
- [x] **T012** Ratify B.8.3.b in `docs/new-archetypes-plan.md` §4.2 + roadmap
  (proposed → committed/done). [Story: FR-B83B-042]

## Phase 5 — Review
- [x] **T013** Independent reviewer validates impl (separate context) before archive.
