# Tasks: b5-1-init-wizard

<!-- Audit: Module B.5.1 (P1 of T2 — dependency amont of B.2/B.3/B.4). -->
<!-- TDD-ordered. 3 commit clusters per design ADR-009.                 -->
<!--   Phase 1 = scaffolding (table + wrapper + standard + docs + harness) -->
<!--   Phase 2 = TS dispatcher + domain + wizard + Vitest + L2 fixtures   -->
<!--   Phase 3 = e2e + L3 + docs polish + final verification              -->

Implementation is split into **3 commit clusters**.

---

## Phase 0: Bootstrap test harness

- [ ] Create `.forge/scripts/tests/b5.test.sh` skeleton —
  sources `_helpers.sh`, declares the `# MANIFEST: ...` block
  (empty), implements `test_b5_manifest_self_consistency`,
  exits 0 with empty manifest. [Story: FR-IW-011]
- [ ] `chmod +x b5.test.sh`. [Story: FR-IW-011]
- [ ] Wire `b5.test.sh` into `forge-ci.yml` `harness` job
  (named invocation alongside the existing 7 harnesses).
  [Story: FR-IW-011]

---

## Phase 1: Scaffolding cluster

### Phase 1 — RED

- [ ] Add `test_dispatch_table_shape` to manifest : asserts
  `.forge/scaffolding/dispatch-table.yml` parses, has top-level
  `archetypes:` map with `default` + `full-stack-monorepo`
  entries. [Story: FR-IW-002] [P]
- [ ] Add `test_dispatch_scaffolders_exist` : every
  `scaffolder` value is `"<built-in>"` OR resolves to an
  existing file. [Story: FR-IW-002] [P]
- [ ] Add `test_forge_init_fsm_sh_exists_executable` : asserts
  `bin/forge-init-fsm.sh` exists with +x. [Story: FR-IW-004] [P]
- [ ] Add `test_forge_init_fsm_sh_translates_abi` : fixture
  passes the new ABI to the wrapper, asserts the wrapper
  invokes `init.sh` with the right legacy flags (mocked via a
  shim `init.sh` that echoes its argv). [Story: FR-IW-004]
- [ ] Add `test_standard_scaffolding_has_required_sections` :
  asserts `.forge/standards/global/scaffolding.md` has the 6
  H2 sections + 3 Interdictions. [Story: FR-IW-008] [P]
- [ ] Add `test_index_has_scaffolding_entry` : index.yml
  contains the new entry. [Story: FR-IW-010] [P]
- [ ] Add `test_archetypes_decision_matrix_present` : asserts
  `docs/ARCHETYPES.md` H1 + table with 5 rows. [Story: FR-IW-009] [P]
- [ ] Add `test_features_init_wizard_feature_present` : asserts
  the feature file exists with ≥ 5 scenarios. [Story: AC-IW-*] [P]
- [ ] Add `test_reverse_domain_regex` : exercises the regex
  via Python regex equivalent (or via the
  `cli/src/domain/reverse-domain.ts` if compiled by Phase 2).
  [Story: FR-IW-007] [P]
- [ ] Add `test_no_new_third_party_deps` : greps
  `cli/package.json` `dependencies` keys ; asserts no new
  entry vs the b5.1 baseline (snapshot the prior keys).
  [Story: NFR-IW-002]
- [ ] Run b5.test.sh → confirm Phase-1 RED tests FAIL.

### Phase 1 — GREEN

- [ ] Write `.forge/scaffolding/dispatch-table.yml` per ADR-002 :
  2 entries (default + full-stack-monorepo) with `name`,
  `scaffolder`, `description`, `signals`, `since`.
  [Story: FR-IW-002]
- [ ] Write `bin/forge-init-fsm.sh` per FR-IW-004 + ADR-005.
  Translates `--target / --project-name / --reverse-domain
  [--force]` ABI to `init.sh`'s native flags. `chmod +x`.
  [Story: FR-IW-004]
- [ ] Write `.forge/standards/global/scaffolding.md` per
  ADR-002 / ADR-005 / ADR-008 with 6 H2 sections + 3
  Interdictions. [Story: FR-IW-008]
- [ ] Add new entry to `.forge/standards/index.yml` :
  `id: global/scaffolding`, `path:
  standards/global/scaffolding.md`, `scope: all`, `priority:
  high`, triggers `[init, forge init, wizard, archetype,
  dispatch-table, --auto, --wizard]`. [Story: FR-IW-010]
- [ ] Write `docs/ARCHETYPES.md` decision matrix per FR-IW-009
  with 5 rows (2 active, 3 placeholder) + the
  `## How forge init chooses` H2 section. [Story: FR-IW-009]
- [ ] Write `.forge/changes/b5-1-init-wizard/features/init-wizard.feature`
  with ≥ 5 Gherkin scenarios mapped to AC-IW-001..005.
  [Story: FR-IW-013]
- [ ] Run b5.test.sh → confirm Phase-1 RED tests now PASS.

### Phase 1 — REFACTOR

- [ ] Run all 8 harnesses (foundations, scaffolder L1+L2,
  workflow L1+L2, delivery, g1, c1, a7, b5) : zero regression.
- [ ] Run `shellcheck bin/forge-init-fsm.sh` : zero warnings.
- [ ] Commit Phase 1 cluster :
  `feat(forge): b5-1-init-wizard Phase 1 — dispatch-table + wrapper + standard + docs`.

---

## Phase 2: TS dispatcher + domain + wizard cluster

### Phase 2 — RED

- [ ] Add Vitest `cli/test/domain/archetype-detect.test.ts` :
  exhaustive cases (full-stack signals → match, pubspec only →
  ambiguous, cargo only → ambiguous, no signals → none).
  [Story: FR-IW-005]
- [ ] Add Vitest `cli/test/domain/reverse-domain.test.ts` :
  valid + invalid cases per ADR-011. [Story: FR-IW-007]
- [ ] Add Vitest `cli/test/commands/init-default.test.ts` :
  preserves the existing `runDefaultInit` behavior (file-copy
  semantics, --force handling). Migrate the relevant tests
  from the existing `init.test.ts`. [Story: FR-IW-003]
- [ ] Add Vitest `cli/test/commands/init.test.ts` (refactored)
  : tests the dispatcher's path selection (--archetype,
  --auto, --wizard, mutual exclusion, non-TTY default).
  [Story: FR-IW-001 + ADR-007]
- [ ] Add Vitest `cli/test/commands/init-wizard.test.ts` :
  scripted stdin via `Readable.from()` ; happy path + 2
  re-prompt scenarios. [Story: FR-IW-006]
- [ ] Add Vitest `cli/test/commands/init-archetype.test.ts` :
  `probeSignalsAndDispatch` reads dispatch table + probes file
  system + delegates to `detectArchetype`. Mocks fs + spawn.
  [Story: FR-IW-005 + FR-IW-001]
- [ ] Add `test_init_cli_flags_parse` to b5.test.sh : static
  text-grep on `cli/src/cli.ts` asserts the 4 new options
  (`--archetype`, `--auto`, `--wizard`, `--org`) are
  registered. [Story: FR-IW-001]
- [ ] Add `test_default_dispatcher_idempotent` (L2) : run the
  default-archetype path twice with same flags ; assert same
  outcome. [Story: NFR-IW-001]
- [ ] Add `test_wizard_skips_when_non_tty` (L2) : invoke the
  CLI with `process.stdin.isTTY = false` (achieved via piping
  /dev/null) ; assert it falls back to silent default.
  [Story: NFR-IW-003 + ADR-007]
- [ ] Add `test_auto_detection_ambiguous_aborts` (L2) :
  fixture with only `pubspec.yaml` ; CLI invoked with `--auto`
  exits 2 + output contains `[NEEDS DECISION:`. [Story: FR-IW-005]
- [ ] Run all tests → confirm Phase-2 RED tests FAIL.

### Phase 2 — GREEN

- [ ] Implement `cli/src/domain/archetype-detect.ts` per
  ADR-003 + FR-IW-005. Pure function over signal record →
  DetectionResult discriminated union. [Story: FR-IW-005]
- [ ] Implement `cli/src/domain/reverse-domain.ts` per ADR-011
  + FR-IW-007. Pure validator returning `{valid, reason?}`.
  [Story: FR-IW-007]
- [ ] Extract the existing file-copy logic from
  `cli/src/commands/init.ts` into
  `cli/src/commands/init-default.ts` per ADR-006. Preserve
  byte-equivalent behavior for `runDefaultInit`. [Story: FR-IW-003]
- [ ] Implement `cli/src/commands/init-archetype.ts` per
  ADR-003. Reads `dispatch-table.yml`, probes signals, builds
  the record, calls `detectArchetype`, on match shells out to
  the wrapper. [Story: FR-IW-005 + FR-IW-004]
- [ ] Implement `cli/src/commands/init-wizard.ts` per ADR-004
  + FR-IW-006. Sequential prompts via Node `readline`,
  numbered menu, regex-validated project name and reverse
  domain, re-prompt × 3, non-TTY skip. [Story: FR-IW-006]
- [ ] Refactor `cli/src/commands/init.ts` into the dispatcher
  per ADR-001 + ADR-007. Mutual exclusion check, TTY-based
  precedence, dispatch table read, delegation to one of
  default/archetype/wizard. [Story: FR-IW-001]
- [ ] Wire the new flags into `cli/src/cli.ts` per ADR-010 :
  `--archetype <name>`, `--auto`, `--wizard`, `--org
  <reverse-domain>`. Pass `process.stdin.isTTY` and stdio
  streams into the dispatcher's deps. [Story: FR-IW-001]
- [ ] Run `npm test --prefix cli` : Vitest GREEN.
- [ ] Run `bash b5.test.sh` : Phase-2 L2 fixtures GREEN.

### Phase 2 — REFACTOR

- [ ] Run all 8 harnesses + Vitest : zero regression.
- [ ] Run `shellcheck` on all modified shell scripts : zero
  warnings.
- [ ] Run `npm run lint --prefix cli` : zero ESLint issues.
- [ ] Commit Phase 2 cluster :
  `feat(cli): b5-1-init-wizard Phase 2 — TS dispatcher + domain + wizard`.

---

## Phase 3: L3 + docs polish + final verification

### Phase 3 — RED + GREEN

- [ ] Add `test_l3_end_to_end_full_stack_monorepo` (gated on
  `--require-external-tools`) : invoke the published-style CLI
  binary against a tmpdir with `--archetype full-stack-monorepo
  my-app --org io.test.myapp`, assert the resulting tree
  matches `b1-scaffolder` L3 happy-path expectations.
  [Story: MODIFIED FR-GL-011]
- [ ] Build the CLI : `npm run build --prefix cli`. Confirm
  `cli/dist/commands/init.js` + `init-default.js` + `init-wizard.js` etc. produced.
- [ ] *(opt-in)* Run `b5.test.sh --require-external-tools`
  L3 against a fresh tmpdir. Confirm GREEN. [Story: FR-IW-011]
- [ ] Update `docs/GUIDE.md` § Init flow with the dispatcher
  documentation. [Story: housekeeping]
- [ ] Update `cli/package.json` description to mention the
  wizard. [Story: housekeeping]
- [ ] Update README adoption section : `forge init` is the
  canonical entry point with archetype dispatch. [Story:
  housekeeping]

### Phase 3 — REFACTOR

- [ ] Run all 8 harnesses + Vitest + verify.sh +
  constitution-linter.sh : zero regression.
- [ ] Smoke test : `node cli/dist/index.js init --archetype default --target <tmp>`
  on an empty tmpdir → file-copy succeeds.
- [ ] Smoke test : `node cli/dist/index.js init --archetype default --wizard`
  in interactive shell — verify the wizard prompts correctly.
- [ ] Smoke test : `node cli/dist/index.js init --auto --target <tmp>`
  on an empty tmpdir → exits 2 with NEEDS DECISION.
- [ ] Commit Phase 3 cluster :
  `feat(cli): b5-1-init-wizard Phase 3 — L3 fixture + docs polish`.

---

## Phase 4: Quality

- [ ] Run `cargo test --workspace` from
  `examples/forge-fsm-example/backend/` : zero regression.
- [ ] Run `flutter test` from
  `examples/forge-fsm-example/frontend/` : zero regression.
- [ ] Verify the new wrapper passes the existing
  `forge-ci.yml` shellcheck job (named scandir `./bin`
  already covers `forge-init-fsm.sh`).

---

## Phase 5: Documentation (handled by /forge:archive)

- [ ] /forge:archive merges the delta from `specs.md` into a
  new spec `.forge/specs/init-wizard.md` (FR-IW-012).
- [ ] /forge:archive merges MODIFIED FR-GL-011 update into
  `.forge/specs/full-stack-monorepo.md`.
- [ ] /forge:archive updates `CHANGELOG.md` with the
  `b5-1-init-wizard` entry under [Unreleased].
- [ ] /forge:archive marks Audit Module B.5.1 as Done in
  `.forge/product/roadmap.md`.

---

## Phase 6: Constitutional gate (handled by /forge:archive)

- [ ] /forge:archive runs all 8 harnesses + Vitest +
  verify.sh + constitution-linter.sh : confirm green.
- [ ] /forge:archive sets `.forge.yaml` to `status: archived`
  with `timeline.archived` populated.
- [ ] /forge:archive runs a final repository-wide check :
  every `[ ]` task in this file is now `[x]`.
