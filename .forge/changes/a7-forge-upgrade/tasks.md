# Tasks: a7-forge-upgrade

<!-- Audit: Module A.7 (P1 of T2 facilitateurs).                             -->
<!-- TDD-ordered. Per ADR-001 the work splits across 3 commit clusters :     -->
<!--   Phase 1 = scaffolding (yml + stub shell + standard + index + feature) -->
<!--   Phase 2 = merge logic (BASE recovery + truth table + conflict + force -->
<!--                          + version abort + upgrade_history)             -->
<!--   Phase 3 = TS CLI layer + snapshot tarball + L3 fixture                -->

Implementation is split into **3 commit clusters**. Each phase ends with a
RED→GREEN→REFACTOR closure on its own subset of `a7.test.sh`. The
harness grows phase-by-phase.

---

## Phase 0: Bootstrap test harness

- [ ] Create `.forge/scripts/tests/a7.test.sh` skeleton — sources
  `_helpers.sh`, declares the `# MANIFEST: ...` comment block (empty
  initially), implements `test_a7_manifest_self_consistency` as the
  first test, exits 0 with empty manifest. [Story: FR-UP-014]
- [ ] Make `a7.test.sh` executable (`chmod +x`).
  [Story: FR-UP-014]
- [ ] Run `bash .forge/scripts/tests/a7.test.sh` once : confirm 1/1
  PASS (just the meta-test). [Story: FR-UP-014]
- [ ] Wire `a7.test.sh` into `.forge/scripts/verify.sh` Section 7 at
  L1 (alongside `c1.test.sh` and the existing 5 harnesses).
  [Story: FR-UP-014]
- [ ] Wire `a7.test.sh` into `.github/workflows/forge-ci.yml`
  `harness` job (named invocation for visibility).
  [Story: FR-UP-014]

---

## Phase 1: Scaffolding cluster

### Phase 1 — RED

- [ ] Add `test_framework_owned_paths_yml_shape` to `a7.test.sh`
  manifest : asserts `cli/assets/framework-owned-paths.yml` exists,
  parses as YAML, has top-level keys `owned:` and `excluded:`, both
  are non-empty lists of strings. [Story: FR-UP-002] [P]
- [ ] Add `test_owned_paths_exist_in_framework` : for every glob in
  `owned:`, asserts at least one matching file exists in the Forge
  framework repo. [Story: FR-UP-002] [P]
- [ ] Add `test_forge_upgrade_sh_exists_executable` : asserts
  `bin/forge-upgrade.sh` exists with `+x` permission, is a bash
  script. [Story: FR-UP-009] [P]
- [ ] Add `test_forge_upgrade_sh_uses_find_excluding_examples` :
  static text-grep ; asserts the script sources or implements the
  `find_excluding_examples` pattern when running inside the Forge
  framework repo's own dog-food upgrade scenario.
  [Story: FR-UP-009] [P]
- [ ] Add `test_standard_upgrade_policy_has_required_sections` :
  asserts `.forge/standards/global/upgrade-policy.md` exists and
  contains the 6 H2 sections (Framework-owned paths, Three-way merge
  policy, Conflict resolution discipline, Schema-version migration
  boundary, Upgrade history audit trail, Interdictions).
  [Story: FR-UP-010] [P]
- [ ] Add `test_index_has_upgrade_policy_entry` : asserts
  `.forge/standards/index.yml` contains a new entry
  `id: global/upgrade-policy` with `scope: all`, `priority: high`,
  expected triggers. [Story: FR-UP-011] [P]
- [ ] Add `test_gitignore_covers_merge_conflicts` : asserts root
  `.gitignore` contains `.merge-conflicts`. [Story: FR-UP-012] [P]
- [ ] Add `test_features_upgrade_feature_present` : asserts
  `.forge/changes/a7-forge-upgrade/features/upgrade.feature` exists
  with at least 5 scenarios matching the 5 ACs declared in
  specs.md. [Story: FR-UP-013] [P]
- [ ] Add `test_snapshot_tarball_present_and_extractable` :
  asserts `cli/assets/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
  exists, is gzip-valid, extracts cleanly into a tmpdir, contains a
  `.forge/` subtree. [Story: FR-UP-008]
- [ ] Add `test_snapshot_size_under_budget` : asserts the snapshot
  tarball's uncompressed size ≤ 1 MB. [Story: NFR-UP-003]
- [ ] Run `a7.test.sh` once → confirm all Phase-1 RED tests FAIL.
  [Story: TDD discipline]

### Phase 1 — GREEN

- [ ] Write `cli/assets/framework-owned-paths.yml` per ADR-003 :
  `owned:` enumerating `.forge/{constitution.md,standards/**,
  templates/**,schemas/**,scripts/**}`, `.claude/{agents/**,
  commands/**,skills/**,settings.json}`, `.mcp.json`,
  `bin/{forge-install.sh,forge-lint,forge-upgrade.sh}`,
  `docs/{GUIDE,ARCHITECTURE,VERSIONING,CONTRIBUTING}.md`,
  root `CLAUDE.md`, `LICENSE`, `NOTICE` ; `excluded:` enumerating
  `.claude/settings.local.json`, `.forge/{changes,specs,product}/**`,
  `.forge/scaffold-manifest.yaml`, `.omc/**`. Comments per section.
  [Story: FR-UP-002]
- [ ] Create `bin/forge-upgrade.sh` stub : sources `_helpers.sh`,
  shebang + `set -euo pipefail`, parses `--target` / `--to-version`
  / `--dry-run` / `--force` / `--verbose` flags, no logic yet
  (echoes "TBD : phase 2 GREEN"). [Story: FR-UP-009]
- [ ] `chmod +x bin/forge-upgrade.sh`. [Story: FR-UP-009]
- [ ] Write `.forge/standards/global/upgrade-policy.md` per ADR-010
  with the 6 H2 sections + 3 Interdictions + Article III.4 / IV.4 /
  V / X citations. [Story: FR-UP-010]
- [ ] Add new entry to `.forge/standards/index.yml` :
  `id: global/upgrade-policy`, `path: standards/global/upgrade-policy.md`,
  `scope: all`, `priority: high`, `triggers: [upgrade, forge upgrade,
  merge, framework-owned, archetype_version, upgrade_history]`.
  [Story: FR-UP-011]
- [ ] Append `.merge-conflicts` to root `.gitignore` with the
  documented inline comment. [Story: FR-UP-012]
- [ ] Write `.forge/changes/a7-forge-upgrade/features/upgrade.feature`
  with the 5 BDD scenarios from specs.md AC-UP-001..005 (additional
  AC-UP-006 + AC-UP-007 in the spec are advanced cases — included
  in the feature file as separate scenarios). [Story: FR-UP-013]
- [ ] Build the snapshot tarball for `full-stack-monorepo / 1.0.0` :
    - Create a new helper `bin/forge-snapshot.sh build <archetype>
      <version>` : walks the framework's `owned:` paths, tars +
      gzips them, writes to
      `cli/assets/scaffold-snapshots/<archetype>/<version>.tar.gz`.
    - Run `bash bin/forge-snapshot.sh build full-stack-monorepo 1.0.0`.
    - Verify size ≤ 1 MB. [Story: FR-UP-008]
- [ ] Run `a7.test.sh` → confirm all Phase-1 RED tests now PASS.
  [Story: TDD]

### Phase 1 — REFACTOR

- [ ] Run `bash .forge/scripts/verify.sh` : confirm zero regression
  on the 6 prior harnesses + the new `a7.test.sh` L1 entry passes.
- [ ] Run `bash .forge/scripts/constitution-linter.sh` : zero new
  warnings.
- [ ] Run `shellcheck bin/forge-upgrade.sh bin/forge-snapshot.sh` :
  zero issues at severity `warning`. [Story: Article X.5]
- [ ] Commit Phase 1 cluster : `feat(forge): a7-forge-upgrade
  Phase 1 — scaffolding (yml + standard + stub shell + snapshot
  tarball)`.

---

## Phase 2: Merge logic cluster

### Phase 2 — RED

- [ ] Add `test_merge_truth_table_exhaustive` : 5 fixtures (4 cells
  of the 3-way table + 1 cell for 2-way fallback when BASE is
  unavailable). Each fixture builds tmpdir BASE / LEFT / RIGHT
  trees, invokes `bin/forge-upgrade.sh` against a minimal target,
  asserts the resulting LEFT state matches the truth table.
  [Story: FR-UP-003]
- [ ] Add `test_conflict_markers_written` : fixture exercises
  changed/changed cell → asserts LEFT contains `<<<<<<<` /
  `|||||||` / `=======` / `>>>>>>>` markers. [Story: FR-UP-004]
- [ ] Add `test_merge_conflicts_listing` : same fixture →
  asserts `.merge-conflicts` contains the conflicted path with
  `[CONFLICT]` prefix. [Story: FR-UP-004]
- [ ] Add `test_force_requires_clean_git` : fixture has uncommitted
  changes → invokes with `--force` → asserts exit 7 + message
  contains "clean Git working tree". [Story: FR-UP-005]
- [ ] Add `test_force_succeeds_when_clean` : fixture is a Git repo
  with empty `git status --porcelain` → invokes with `--force` →
  proceeds normally, conflict produces exit 0 (not 8).
  [Story: FR-UP-005]
- [ ] Add `test_force_aborts_on_non_git` : fixture without `.git/`
  → invokes with `--force` → asserts exit 7 + message contains
  "Git-managed". [Story: FR-UP-005]
- [ ] Add `test_major_version_aborts` : fixture has manifest
  declaring `archetype_version: "1.5.2"` ; framework's schema
  declares `2.0.0` → invokes → asserts exit 7 + output contains
  `[NEEDS MIGRATION: from 1.5.2 to 2.0.0]`. [Story: FR-UP-006]
- [ ] Add `test_minor_patch_bumps_proceed` : fixture has manifest
  `1.0.0`, framework `1.1.0` → proceeds normally. [Story: FR-UP-006]
- [ ] Add `test_upgrade_history_appended_after_run` : fixture
  scaffolded at `1.0.0` ; after a successful merge to `1.1.0`,
  asserts `upgrade_history[]` has one entry with all required
  keys (`date`, `from_version`, `to_version`,
  `from_template_set_sha`, `to_template_set_sha`, `counts`,
  `cli_version`). [Story: FR-UP-007]
- [ ] Add `test_upgrade_history_append_only` : fixture has
  pre-existing history (`[entry1]`) ; after another successful
  merge, asserts history is `[entry1, entry2]` (not replaced).
  [Story: FR-UP-007]
- [ ] Add `test_identity_fields_immutable` : fixture before
  upgrade has `project_name` / `reverse_domain` / `root_module` ;
  after upgrade, asserts those three fields are byte-identical.
  [Story: FR-UP-007]
- [ ] Add `test_upgrade_idempotent_when_no_change` : fixture
  scaffolded at framework's current version ; runs upgrade once,
  asserts exit 0 with all-zero counts (everything `unchanged` or
  `preserved`). Runs upgrade again, asserts no project file
  mutation, but `upgrade_history` gains a second entry.
  [Story: NFR-UP-001]
- [ ] Add `test_legacy_manifest_without_upgrade_history_parses` :
  fixture has manifest without `upgrade_history:` key ; upgrade
  reads it as `[]` and appends successfully. [Story: NFR-UP-005]
- [ ] Add `test_merge_output_deterministic` : same input twice →
  same conflict markers + same `.merge-conflicts` content +
  same exit code. [Story: NFR-UP-006]
- [ ] Add `test_base_recovery_via_snapshot` : fixture exercises
  the snapshot extraction path ; asserts the BASE files in the
  tmpdir match what the framework's `1.0.0` should look like
  (compare to a checked-in expected SHA). [Story: FR-UP-008]
- [ ] Run `a7.test.sh` → confirm Phase-2 RED tests FAIL.
  [Story: TDD]

### Phase 2 — GREEN

- [ ] Implement BASE recovery in `bin/forge-upgrade.sh` :
  - Function `recover_base <archetype> <version> <tmpdir>` that
    extracts the snapshot tarball (or returns 1 if missing,
    triggering 2-way fallback).
  - Calls a new helper `find cli/assets/scaffold-snapshots/...`
    relative to the framework root (where the script's enclosing
    repo lives — recover via `BASH_SOURCE[0]` and `cd ..`).
  [Story: FR-UP-008]
- [ ] Implement framework-owned-paths parsing :
  - Function `parse_owned_paths` reads `cli/assets/framework-owned-paths.yml`
    (via Python `yaml.safe_load`) and emits the resolved list of
    glob-expanded paths to stdout. [Story: FR-UP-002]
- [ ] Implement SHA-256 sameness :
  - Function `sha256 <file>` echoes the SHA-256 hex (or empty if
    file missing). [Story: FR-UP-003]
- [ ] Implement the merge truth table :
  - For each owned path in the project, compute `sha_l` (LEFT),
    `sha_b` (BASE — empty if BASE recovery failed for this version),
    `sha_r` (RIGHT). Apply the 4-cell table per ADR-002 ; on
    `changed/changed` invoke `git merge-file --diff3 LEFT BASE RIGHT`.
  - Track counts in associative arrays
    (`COUNTS[unchanged]`, `[upgraded]`, etc.).
  [Story: FR-UP-003]
- [ ] Implement conflict tracking :
  - Append `[CONFLICT] <path>` to `<target>/.merge-conflicts` for
    every path where `git merge-file` returned non-zero.
  - On zero conflicts at end, remove any pre-existing
    `.merge-conflicts`. [Story: FR-UP-004]
- [ ] Implement `--force` Git cleanliness gate :
  - Before any merge, if `--force` is set : run
    `git -C <target> status --porcelain` ; non-empty → exit 7.
  - If no `.git/` in target → exit 7. [Story: FR-UP-005]
- [ ] Implement major-version migration abort :
  - Parse `archetype_version` from the manifest (semver) and
    `version` from the framework's schema.yaml. If majors differ,
    exit 7 with `[NEEDS MIGRATION: from X.Y.Z to A.B.C]`.
  [Story: FR-UP-006]
- [ ] Implement scaffold-manifest update :
  - Function `update_manifest <target> <to_version> <counts...>`
    : reads existing manifest via Python, mutates canonical fields
    (`archetype_version`, `scaffold_date`, `scaffold_plan_sha`,
    `template_set_sha`, `tools`), appends one entry to
    `upgrade_history[]`, writes back via `yaml.safe_dump`.
  - Identity fields (`project_name`, `reverse_domain`,
    `root_module`) MUST NOT be touched. [Story: FR-UP-007]
- [ ] Implement final summary print to stdout per FR-UP-001
  format. Exit code per the rules : 0 if no conflicts, 8 if
  conflicts without `--force`, 0 if conflicts with `--force`.
  [Story: FR-UP-001]
- [ ] Implement `--dry-run` short-circuit : after computing the
  truth table, print the summary but do NOT mutate anything.
  Exit 0. [Story: FR-UP-001]
- [ ] Run `a7.test.sh` → confirm Phase-2 RED tests now PASS.
  [Story: TDD]

### Phase 2 — REFACTOR

- [ ] Run all 7 harnesses (foundations + scaffolder + workflow +
  delivery + g1 + c1 + a7) : zero regression.
- [ ] Run `shellcheck bin/forge-upgrade.sh bin/forge-snapshot.sh`
  : zero issues at severity `warning`.
- [ ] Run `bash .forge/scripts/verify.sh` + `constitution-linter.sh`
  : zero new failures.
- [ ] Commit Phase 2 cluster : `feat(forge): a7-forge-upgrade
  Phase 2 — merge logic (BASE + truth table + conflict + force +
  version abort + upgrade_history)`.

---

## Phase 3: TS CLI layer + L3 fixture

### Phase 3 — RED

- [ ] Add Vitest `cli/test/upgrade.test.ts` :
  - `parses --dry-run / --force / --verbose flags correctly`
  - `defaults target to cwd when omitted`
  - `validates manifest presence (exits 2 with message when missing)`
  - `propagates shell driver exit codes (0 / 7 / 8)`
  - `forwards verbose stderr to user verbatim`
  Run `npm test --prefix cli` → fail (no upgrade.ts yet).
  [Story: FR-UP-001]
- [ ] Add `test_upgrade_cli_flags_parse` to `a7.test.sh` :
  static text-grep on `cli/src/commands/upgrade.ts` asserts
  flag names + commander chain. [Story: FR-UP-001]
- [ ] Add L3 opt-in test (gated on `--require-external-tools`) :
  `test_l3_end_to_end_against_example` — builds a synthetic
  framework bump in a tmpdir copy, runs `forge upgrade` against
  the copy of `examples/forge-fsm-example/`, asserts exit code +
  summary counts match expectations. [Story: FR-UP-014]
- [ ] Run all tests → confirm Phase-3 RED tests FAIL.

### Phase 3 — GREEN

- [ ] Write `cli/src/commands/upgrade.ts` :
  - Commander program with `[target-dir]` positional + flags.
  - Reads manifest at `<target>/.forge/scaffold-manifest.yaml`.
  - Resolves framework's RIGHT version from `cli/VERSION` +
    schema's `version` field (using `assetsRoot()` helper from
    `cli.ts`).
  - Spawns `bin/forge-upgrade.sh` (via `node:child_process.spawn`)
    with the resolved arguments, inherits stdio.
  - Returns the shell's exit code as the CLI's exit code.
  [Story: FR-UP-001]
- [ ] Wire `upgradeCommand` into `cli/src/cli.ts` :
  - Import + register on the program (mirrors `initCommand` and
    `verifyCommand`).
  [Story: FR-UP-001]
- [ ] Update `cli/package.json` `description` field if needed
  (already mentions "upgrade" — verify no edit needed).
  [Story: housekeeping]
- [ ] Build the CLI : `npm run build --prefix cli` ; confirm
  `cli/dist/commands/upgrade.js` is produced.
- [ ] Run `npm test --prefix cli` → Vitest GREEN.
- [ ] Run `a7.test.sh` → all FRs GREEN (L1 + L2). L3 stays
  gated unless `--require-external-tools`.
- [ ] *(opt-in)* Run `a7.test.sh --require-external-tools` for the
  L3 against `examples/forge-fsm-example/`. Confirm GREEN.
  [Story: FR-UP-014]

### Phase 3 — REFACTOR

- [ ] Run all 7 harnesses + `npm test --prefix cli` + verify.sh
  + constitution-linter.sh : zero regression.
- [ ] `shellcheck bin/forge-upgrade.sh bin/forge-snapshot.sh` :
  zero issues.
- [ ] `npm run lint --prefix cli` : zero issues. [Story: Article X.5]
- [ ] Update `docs/GUIDE.md` § Upgrade flow with the new
  command's user-facing usage. [Story: housekeeping]
- [ ] Update `docs/CONTRIBUTING.md` § How upgrades affect your
  local Forge customizations.
- [ ] Update README adoption section to mention `forge upgrade`.
- [ ] Commit Phase 3 cluster : `feat(cli): a7-forge-upgrade
  Phase 3 — TS CLI layer + L3 fixture against example tree`.

---

## Phase 4: Quality

- [ ] Run `cargo test --workspace` from
  `examples/forge-fsm-example/backend/` : zero regression.
- [ ] Run `flutter test` from
  `examples/forge-fsm-example/frontend/` : zero regression.
- [ ] *(post-merge, opt-in)* Run a real upgrade against a fresh
  `forge init` target after a synthetic framework bump (e.g.,
  add a new agent, run `forge-snapshot.sh build`, run `forge
  upgrade`). Confirm the structured summary matches expectations
  + Git diff in the target shows only the expected changes.

---

## Phase 5: Documentation (handled by /forge:archive)

- [ ] /forge:archive merges the delta from `specs.md` into a
  new spec file `.forge/specs/upgrade.md` (FR-UP-015).
- [ ] /forge:archive merges the MODIFIED FR-GL-009 update into
  `.forge/specs/full-stack-monorepo.md` (scaffold-manifest gains
  `upgrade_history` field).
- [ ] /forge:archive updates `CHANGELOG.md` with the
  `a7-forge-upgrade` entry under [Unreleased].
- [ ] /forge:archive updates `.forge/product/roadmap.md` :
  mark Audit Module A.7 as Done.

---

## Phase 6: Constitutional gate (handled by /forge:archive)

- [ ] /forge:archive runs all 7 harnesses + verify.sh +
  constitution-linter.sh + Vitest : confirm green.
- [ ] /forge:archive sets `.forge.yaml` to `status: archived`
  with `timeline.archived` populated.
- [ ] /forge:archive runs a final repository-wide check :
  every `[ ]` task in this file is now `[x]`.
