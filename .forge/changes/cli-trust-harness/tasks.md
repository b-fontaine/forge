# Tasks: cli-trust-harness
<!-- Status: proposed -->
<!-- Schema: default -->
<!-- Audit: T5.1 (docs/new-archetypes-plan.md §0.1) -->

## Convention

- TDD order is **immutable** : write the test, watch it fail (RED),
  write the artefact, watch it pass (GREEN), refactor.
- Audit trail tag `[Story: FR-T51-XXX]` (Article V.1, enforced by
  `f4-linter-extension`) on every task.
- `[P]` marks tasks parallelizable with other `[P]` tasks in the
  **same phase**.
- ADRs from `design.md` (ADR-T51-001..005) are honored verbatim ;
  deviations require a new ADR.

---

## Phase 1 — RED harness + CI registration

Goal : `t5-1.test.sh` exists with **17 L1 + 2 L2 stubs** ; L1 stubs
FAIL (full RED witness for the 17 anchors) ; L2 returns 0 (skip-pass
by default per ADR-T51-001 gating pattern) ; CI registration done.

### T-HAR — Harness skeleton

- [ ] **T-HAR-001** — Create `.forge/scripts/tests/t5-1.test.sh`
      with bash header (`#!/usr/bin/env bash`, `set -uo pipefail`),
      source `_helpers.sh`, PASS/FAIL counters reset, `--level`
      parsing for `1|2|1,2|all`, audit comment
      `# Audit: T5.1 (cli-trust-harness)`, `print_summary`
      close-out. Mirror the `f3.test.sh` / `i6.test.sh` layout.
      [Story: FR-T51-120 / FR-T51-121 / FR-T51-122 / FR-T51-123]
- [ ] **T-HAR-002** — Define path variables at the top of the
      harness :
      - `REPO_ROOT` → resolved via `$(cd "$(dirname "$0")"/../../../ && pwd)`
      - `TASKFILE_TMPL` → `.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl`
      - `HELP_TEST` → `cli/test/e2e/help-snapshots.test.ts`
      - `SMOKE_TEST` → `cli/test/e2e/archetypes-smoke.test.ts`
      - `SNAPSHOTS_DIR` → `cli/test/e2e/__snapshots__/help`
      - `FIXTURES_DIR` → `cli/test/e2e/archetype-fixtures`
      - `LOAD_FIXTURE_HELPER` → `cli/test/e2e/helpers/load-fixture.ts`
      - `PREPUBLISH_SCRIPT` → `cli/scripts/prepublish-smoke.mjs`
      - `CLI_PACKAGE_JSON` → `cli/package.json`
      - `CHANGELOG_MD` → `CHANGELOG.md`
      - `GOVERNANCE_MD` → `GOVERNANCE.md`
      - `CI_WORKFLOW` → `.github/workflows/forge-ci.yml`
      - `DISPATCH_TABLE` → `.forge/scaffolding/dispatch-table.yml`
      [Story: FR-T51-120]
- [ ] **T-HAR-003** — Add **17 L1 test stubs** all returning
      `_not_implemented` covering the 17 anchor IDs in
      `design.md` § "Harness L1 anchor list" (lines 280-300).
      [Story: FR-T51-124]
- [ ] **T-HAR-004** [P] — Add **2 L2 test stubs**
      (`_test_t51_l2_smoke_one_archetype`,
      `_test_t51_l2_pack_isolation`) that return 0 by default
      (skip-pass per ADR-T51-001/005 gate pattern) but actually
      emit `[INFO: ... skipped (FORGE_T51_LIVE / FORGE_T51_PACK
      unset)]` when their env-var is absent.
      [Story: FR-T51-125]
- [ ] **T-HAR-005** — Add the test runner — iterate through the
      17 L1 functions, call `run_test`, gate L2 on `--level`
      containing `2` or `all`, call `print_summary`. Exit 0 if
      `FAIL == 0`, else 1.
      [Story: FR-T51-124 / FR-T51-125]
- [ ] **T-HAR-006** [P] — Register `t5-1.test.sh` in
      `.github/workflows/forge-ci.yml` `harness` job matrix
      immediately after `f3.test.sh` with `--level 1`. Add the
      `arduino/setup-task@v2` step before the matrix execution
      (per ADR-T51-001). Keep the file under 300 lines
      (NFR-CI-002 / NFR-T51-005).
      [Story: FR-T51-126 / FR-T51-127]
- [ ] **T-HAR-007** — RED gate — confirm
      `bash .forge/scripts/tests/t5-1.test.sh --level 1` exits 1
      with `Failed: 17 / Passed: 0`.
      [Story: FR-T51-124]

### Phase 1 exit gate

`t5-1.test.sh --level 1` exits 1 with FAIL = 17.
`forge-ci.yml` matrix updated, still under 300 lines.
`verify.sh` overall PASS unchanged. `constitution-linter.sh`
OVERALL PASS unchanged.

---

## Phase 2 — Layer T5.1.0 : Taskfile template sweep

Goal : the bug at line 67 + every sibling unquoted `: ` in `cmds:`
lists across templates is fixed. After this phase, L1 tests
`_test_t51_l1_001_taskfile_line67_quoted` +
`_test_t51_l1_002_no_unquoted_colon_space` flip GREEN.

### T-SWP — Template sweep

- [ ] **T-SWP-001** — RED witness — confirm both L1 tests still FAIL.
      [Story: FR-T51-001 / FR-T51-002]
- [ ] **T-SWP-002** — Enumerate matches via the design.md sweep
      recipe :
      ```
      grep -rn --include='*.tmpl' --include='Taskfile.yml' \
        -E '^[[:space:]]*-[[:space:]]+(echo|printf|"[^"]*: ).*: ' \
        .forge/templates/ examples/ cli/assets/
      ```
      Capture the matches into a temporary file for the maintainer
      to review before quoting.
      [Story: FR-T51-002 / FR-T51-003]
- [ ] **T-SWP-003** — Single-quote line 67 of
      `.forge/templates/archetypes/full-stack-monorepo/Taskfile.yml.tmpl` :
      ```diff
      -      - echo "infra tests: delegated to b1-delivery workflows"
      +      - 'echo "infra tests: delegated to b1-delivery workflows"'
      ```
      [Story: FR-T51-001]
- [ ] **T-SWP-004** [P] — For each additional match found by
      T-SWP-002, apply the same single-quote transform. Document
      each touched file inline in the change's CHANGELOG entry.
      [Story: FR-T51-002]
- [ ] **T-SWP-005** [P] — Fix the example mirror at
      `examples/forge-fsm-example/Taskfile.yml:67` if the same
      pattern exists there.
      [Story: FR-T51-005]
- [ ] **T-SWP-006** — Re-run `npm run bundle` in `cli/` to refresh
      the bundled-asset mirrors at `cli/assets/.forge/...` +
      `cli/assets/examples/...`. Verify `cli/assets/...`
      Taskfile mirrors match the post-fix originals byte-for-byte.
      [Story: FR-T51-004]
- [ ] **T-SWP-007** — Add an `# Audit: T5.1 (cli-trust-harness)`
      comment near the fix(es) in each edited template
      (FR-T51-006). MAY be a single header comment if multiple
      lines are fixed in the same file.
      [Story: FR-T51-006]
- [ ] **T-SWP-008** — Re-run the T-SWP-002 sweep recipe and
      confirm **zero matches** remain.
      [Story: FR-T51-003]
- [ ] **T-SWP-009** — GREEN gate — confirm
      `_test_t51_l1_001_taskfile_line67_quoted` +
      `_test_t51_l1_002_no_unquoted_colon_space` flip GREEN.
      Harness now reports `Failed: 15 / Passed: 2`.
      [Story: FR-T51-001 / FR-T51-002]

### Phase 2 exit gate

The L1 anchors 1 + 2 are GREEN. A manual smoke (`task --list-all`
on a freshly-scaffolded `full-stack-monorepo` project) exits 0.

---

## Phase 3 — Layer T5.1.A : Golden flag snapshots

Goal : `help-snapshots.test.ts` + 5 snapshot files +
dispatch-table cross-reference. After this phase, L1 anchors 3 + 4
flip GREEN.

### T-HLP — Help snapshots

- [ ] **T-HLP-001** — RED witness — confirm L1 anchors 3 + 4 still
      FAIL.
      [Story: FR-T51-020 / FR-T51-024]
- [ ] **T-HLP-002** — Create `cli/test/e2e/help-snapshots.test.ts`
      skeleton with `// Audit: T5.1 (cli-trust-harness)` header
      comment + vitest import + `CLI` constant resolved to
      `dist/index.js`.
      [Story: FR-T51-020 / FR-T51-021]
- [ ] **T-HLP-003** — Implement the `captureHelp(args)` helper
      strictly per `design.md` (lines ~225-235), forcing
      `NO_COLOR=1` + `FORCE_COLOR=0` and normalising CRLF +
      trailing whitespace.
      [Story: FR-T51-023 / NFR-T51-007]
- [ ] **T-HLP-004** — Implement the `it.each([...])` block
      capturing 5 snapshots (root, init, upgrade, verify, version)
      via `toMatchFileSnapshot('__snapshots__/help/<name>.snap.txt')`.
      [Story: FR-T51-022 / FR-T51-023]
- [ ] **T-HLP-005** — Run `vitest run cli/test/e2e/help-snapshots.test.ts`
      once to populate the 5 snapshot files (initial creation).
      Review each `.snap.txt` for cleanliness (no ANSI, no
      timestamps, no random IDs).
      [Story: NFR-T51-007]
- [ ] **T-HLP-006** [P] — Implement the cross-reference test
      `forge init --help mentions every active archetype` per
      `design.md` lines ~241-256. Use the shipped
      `parseDispatchTable` helper from
      `cli/src/domain/dispatch-table.ts`.
      [Story: FR-T51-025 / FR-T51-026]
- [ ] **T-HLP-007** — Verify the test passes by running
      `vitest run cli/test/e2e/help-snapshots.test.ts` ; both
      snapshot diff + cross-reference must report 0 failures.
      [Story: FR-T51-024 / FR-T51-025]
- [ ] **T-HLP-008** [P] — Add `docs/ARCHETYPES.md` pointer to the
      committed snapshots as the authoritative invocation reference
      (per MR-T51-005 / NFR-T51-010).
      [Story: NFR-T51-010]
- [ ] **T-HLP-009** — GREEN gate — `_test_t51_l1_003_help_snapshots_file`
      + `_test_t51_l1_004_snapshots_dir_5files` flip GREEN.
      Harness reports `Failed: 13 / Passed: 4`.
      [Story: FR-T51-020 / FR-T51-024]

### Phase 3 exit gate

`vitest run cli/test/e2e/help-snapshots.test.ts` exits 0. 5
snapshot files committed under `cli/test/e2e/__snapshots__/help/`.
Cross-reference test passes for the 2 currently active non-default
archetypes (`full-stack-monorepo`, `mobile-only`).

---

## Phase 4 — Layer T5.1.B : Smoke per archetype + fixtures

Goal : `archetypes-smoke.test.ts` + fixture YAML files + the
mini-parser. After this phase, L1 anchors 5 + 6 + 7 + 8 flip
GREEN.

### T-LOAD — Mini YAML parser

- [ ] **T-LOAD-001** — RED witness — confirm
      `_test_t51_l1_008_load_fixture_helper` FAILs.
      [Story: FR-T51-047]
- [ ] **T-LOAD-002** — Create
      `cli/test/e2e/helpers/load-fixture.ts` with audit comment +
      `ArchetypeFixture` interface per `design.md` lines ~272-280.
      [Story: FR-T51-047]
- [ ] **T-LOAD-003** — Implement the mini-parser supporting the
      documented subset (FR-T51-XXX in `specs.md` ADR-T51-002
      block) : key-value scalars, nested mapping one level deep,
      block-style lists of strings, leading `#` comments. Reject
      unsupported syntax with a clear error containing the line
      number.
      [Story: FR-T51-047 / NFR-T51-001]
- [ ] **T-LOAD-004** — Create `cli/test/domain/load-fixture.test.ts`
      with ≥ 6 unit tests covering :
      (1) valid minimal fixture parses correctly,
      (2) missing `required_paths` rejects,
      (3) flow style `[a, b]` rejects with line-num,
      (4) anchor `&foo` rejects,
      (5) comment lines skipped,
      (6) trailing whitespace tolerated.
      [Story: FR-T51-047]
- [ ] **T-LOAD-005** — Run `vitest run cli/test/domain/load-fixture.test.ts`
      ; all 6 tests GREEN.
      [Story: FR-T51-047]

### T-FIX — Archetype fixtures

- [ ] **T-FIX-001** — Create
      `cli/test/e2e/archetype-fixtures/full-stack-monorepo.yml`
      with audit comment + the `required_paths` + `forbidden_paths`
      from FR-T51-053. Cross-check against an actual fresh scaffold
      to verify every listed required path actually exists post-init.
      [Story: FR-T51-046 / FR-T51-053]
- [ ] **T-FIX-002** [P] — Create
      `cli/test/e2e/archetype-fixtures/mobile-only.yml` with
      audit comment + FR-T51-054 contents. Cross-check the same
      way.
      [Story: FR-T51-046 / FR-T51-054]

### T-SMK — Smoke test loop

- [ ] **T-SMK-001** — RED witness — confirm L1 anchors 5 + 12
      still FAIL.
      [Story: FR-T51-040 / FR-T51-050]
- [ ] **T-SMK-002** — Create `cli/test/e2e/archetypes-smoke.test.ts`
      skeleton with audit comment + dispatch-table loader + helper
      utilities (`commandOnPath`, `loadFixture`,
      `activeArchetypes`).
      [Story: FR-T51-040 / FR-T51-041]
- [ ] **T-SMK-003** — Implement the `activeArchetypes()` helper
      filtering out `default`, `removed_from_roadmap`, and
      legacy-alias-pointing-to-absent-target entries per
      FR-T51-041.
      [Story: FR-T51-041]
- [ ] **T-SMK-004** — Implement the missing-fixture detection per
      FR-T51-055 — if an active archetype has no fixture file,
      fail with the prescribed error message.
      [Story: FR-T51-055]
- [ ] **T-SMK-005** — Implement the `describe.each(activeArchetypes())`
      block per `design.md` lines ~298-340 :
      mkdtemp + rm + spawnSync invoke + file-matrix assertion +
      conditional `task --list-all` + opt-in tighter checks + try/finally cleanup.
      [Story: FR-T51-042..052]
- [ ] **T-SMK-006** — Run `vitest run cli/test/e2e/archetypes-smoke.test.ts`
      against the local tree (with `task` on PATH). All scaffolds
      exit 0 ; all file matrices satisfied ; `task --list-all` GREEN.
      [Story: FR-T51-044 / FR-T51-048]
- [ ] **T-SMK-007** [P] — Add `[INFO: ...]` log lines per
      ADR-T51-001 (each skip-pass case logs verbosely so CI logs
      have audit trace).
      [Story: ADR-T51-001 / FR-T51-049 / FR-T51-050 / FR-T51-051]
- [ ] **T-SMK-008** — GREEN gate — L1 anchors 5, 6, 7, 8, 12 flip
      GREEN. Harness reports `Failed: 8 / Passed: 9`.
      [Story: FR-T51-040 / FR-T51-046 / FR-T51-050 / FR-T51-051]

### Phase 4 exit gate

`vitest run cli/test/e2e/archetypes-smoke.test.ts` exits 0. Both
fixtures load. Both archetypes scaffold. `task --list-all` runs
on both. Tighter `cargo` / `flutter` checks gated correctly.

---

## Phase 5 — Layer T5.1.C : Pre-publish tarball gate

Goal : `prepublish-smoke.mjs` + wiring in `package.json` +
emergency override. After this phase, L1 anchors 9 + 10 + 11 flip
GREEN.

### T-PRE — Pre-publish smoke script

- [ ] **T-PRE-001** — RED witness — confirm L1 anchors 9 + 10 + 11
      still FAIL.
      [Story: FR-T51-090 / FR-T51-097 / FR-T51-098]
- [ ] **T-PRE-002** — Create `cli/scripts/prepublish-smoke.mjs`
      skeleton with audit comment header + `#!/usr/bin/env node`
      shebang + ESM imports (`node:fs/promises`, `node:os`,
      `node:path`, `node:child_process`, `node:url`).
      [Story: FR-T51-090]
- [ ] **T-PRE-003** — Implement the emergency override check at
      the top of the script per FR-T51-098 / ADR-T51-005 :
      if `process.env.FORGE_SKIP_PREPUBLISH === '1'`, print the
      `[WARN: T5.1 BYPASS — ...]` line on stderr and `process.exit(0)`.
      [Story: FR-T51-098 / ADR-T51-005]
- [ ] **T-PRE-004** — Implement the `npm pack` invocation +
      tarball path capture per `design.md` lines ~163-167.
      [Story: FR-T51-091]
- [ ] **T-PRE-005** — Implement the `mkdtemp` + `npm install
      --prefix=<tmp> --global` isolation + scaffold-tmp creation
      per `design.md` lines ~168-181.
      [Story: FR-T51-092 / FR-T51-093 / ADR-T51-003]
- [ ] **T-PRE-006** — Implement the inline smoke for the
      `full-stack-monorepo` archetype : `init` invocation +
      `loadFixture` + file matrix assertions + optional
      `task --list-all`. The smoke logic SHOULD reuse the
      `load-fixture.ts` helper from Phase 4 (import via relative
      path).
      [Story: FR-T51-094]
- [ ] **T-PRE-007** — Implement the success path : log
      `[PASS] T5.1 pre-publish smoke`, cleanup both tmpdirs +
      the produced tarball, exit 0.
      [Story: FR-T51-095]
- [ ] **T-PRE-008** — Implement the failure path : log captured
      tarball path + scaffold tmpdir path + the failing assertion
      output to stderr, exit non-zero.
      [Story: FR-T51-096]
- [ ] **T-PRE-009** [P] — Implement the `--dry-run` flag honored
      by the L2 opt-in fixture per FR-T51-125. Dry-run runs the
      full sequence but tolerates cleanup errors.
      [Story: FR-T51-125]
- [ ] **T-PRE-010** — Edit `cli/package.json::scripts.prepublishOnly`
      per MR-T51-001 :
      ```diff
      -    "prepublishOnly": "npm run lint && npm test && npm run bundle"
      +    "prepublishOnly": "npm run lint && npm test && npm run bundle && node scripts/prepublish-smoke.mjs"
      ```
      [Story: FR-T51-097 / MR-T51-001]
- [ ] **T-PRE-011** — Manual smoke : run `node cli/scripts/prepublish-smoke.mjs`
      against the current tree. Expect : `npm pack` produces a
      tarball, isolated install succeeds, `forge init` against the
      tmpdir succeeds, file matrix matches, exit 0.
      [Story: FR-T51-090..097]
- [ ] **T-PRE-012** — Manual smoke (override path) : run
      `FORGE_SKIP_PREPUBLISH=1 node cli/scripts/prepublish-smoke.mjs`.
      Expect : `[WARN: T5.1 BYPASS — ...]` on stderr, no smoke run,
      exit 0.
      [Story: FR-T51-098]
- [ ] **T-PRE-013** — GREEN gate — L1 anchors 9, 10, 11 flip
      GREEN. Harness reports `Failed: 5 / Passed: 12`.
      [Story: FR-T51-090 / FR-T51-097 / FR-T51-098]

### Phase 5 exit gate

`node cli/scripts/prepublish-smoke.mjs` against the current tree
exits 0. Override path exits 0 with the BYPASS log. No global npm
prefix pollution detected.

---

## Phase 6 — Documentation + audit-trail flips + final gates

Goal : CHANGELOG, GOVERNANCE, roadmap, plan, ARCHETYPES.md
updates. After this phase, all 17 L1 + 2 L2 tests GREEN.

### T-DOC — Documentation

- [ ] **T-DOC-001** — RED witness — confirm L1 anchors 13 + 14
      still FAIL.
      [Story: FR-T51-150 / FR-T51-154]
- [ ] **T-DOC-002** — Add a `### Added — CLI Trust Harness (T5.1,
      cli-trust-harness)` block to `CHANGELOG.md` `[Unreleased]`
      per FR-T51-150. Describe :
      - the four layers (T5.1.0 / .A / .B / .C),
      - the new test files + harness,
      - the Taskfile sweep,
      - `FORGE_SKIP_PREPUBLISH` override semantics,
      - the Layer D deferral to B.8.15.
      [Story: FR-T51-150]
- [ ] **T-DOC-003** [P] — Augment `GOVERNANCE.md § Release Process`
      step 4 sub-bullet per FR-T51-099 + the override clause from
      ADR-T51-005. Add the GitHub issue template name + the 7-day
      follow-up obligation.
      [Story: FR-T51-099 / FR-T51-154]
- [ ] **T-DOC-004** [P] — Flip `.forge/product/roadmap.md` :
      - "Planned T5.1" row → "Done 2026-05-XX via `cli-trust-harness`"
        with full Done-row body mirroring the `f3-release-script-fix`
        Done row format.
      - Inventory table : add row `| `cli-trust-harness` | archived
        | T5.1 (CLI Trust Harness) |`.
      - Bump archived count 24 → 25.
      [Story: FR-T51-151 / FR-T51-153 / FR-T51-154]
- [ ] **T-DOC-005** [P] — Flip `docs/new-archetypes-plan.md` :
      - §0.1 closing : add "Done 2026-05-XX via `cli-trust-harness`"
        timestamp on the introductory paragraph.
      - §1.4 row : Planned 2026-05-14 → Done 2026-05-XX.
      - §11 row : Planned T5.1 → Done.
      - Inventory table §0.0 : add row + bump count 24 → 25.
      [Story: FR-T51-152 / FR-T51-153 / FR-T51-154]
- [ ] **T-DOC-006** — Update `docs/ARCHETYPES.md` per
      MR-T51-005 + NFR-T51-010 : add a top-of-file or new H2
      section pointing to
      `cli/test/e2e/__snapshots__/help/init.snap.txt` as the
      authoritative invocation reference. Example wording :
      > **Canonical `forge init` invocation** : the authoritative
      > flag set + usage is captured at
      > `cli/test/e2e/__snapshots__/help/init.snap.txt` (regenerated
      > on every CI run). Copy from there rather than retyping.
      [Story: NFR-T51-010 / MR-T51-005]
- [ ] **T-DOC-007** — GREEN gate — L1 anchors 13 + 14 + 16 + 17
      all flip GREEN. All 17 L1 anchors GREEN.
      [Story: FR-T51-150 / FR-T51-154 / FR-T51-126 / NFR-T51-005]

### T-VER — Verification + final gates

- [ ] **T-VER-001** — Run
      `bash .forge/scripts/tests/t5-1.test.sh --level 1` and
      confirm `Failed: 0 / Passed: 17`.
      [Story: FR-T51-124]
- [ ] **T-VER-002** — Run
      `FORGE_T51_LIVE=1 bash .forge/scripts/tests/t5-1.test.sh --level 2`
      and confirm `_test_t51_l2_smoke_one_archetype` PASSes
      (full scaffold + matrix + `task --list-all`).
      [Story: FR-T51-125]
- [ ] **T-VER-003** — Run
      `FORGE_T51_PACK=1 bash .forge/scripts/tests/t5-1.test.sh --level 2`
      and confirm `_test_t51_l2_pack_isolation` PASSes (dry-run
      `prepublish-smoke.mjs` round-trip).
      [Story: FR-T51-125]
- [ ] **T-VER-004** [P] — Run `bash .forge/scripts/verify.sh` and
      confirm OVERALL PASS preserved (no new FAIL ; new harness
      registered).
      [Story: NFR-T51-006]
- [ ] **T-VER-005** [P] — Run `bash .forge/scripts/constitution-linter.sh`
      and confirm OVERALL PASS preserved.
      [Story: NFR-T51-006]
- [ ] **T-VER-006** [P] — Run `bash bin/validate-standards-yaml.sh`
      (J.7 contract) and confirm STD-PASS preserved (T5.1 does not
      touch any `.forge/standards/*.yaml`).
      [Story: NFR-T51-006]
- [ ] **T-VER-007** [P] — Run
      `bash .forge/scripts/validate-change-yaml.sh
      .forge/changes/cli-trust-harness/.forge.yaml` and confirm exit 0.
      [Story: F.2]
- [ ] **T-VER-008** — Verify the inline `[NEEDS CLARIFICATION:]`
      gate : `grep -n '\[NEEDS CLARIFICATION:' .forge/changes/cli-trust-harness/*.md`
      MUST return zero matches (per Article III.4 + F.1 archive
      gate).
      [Story: Article III.4]
- [ ] **T-VER-009** [P] — Run vitest suite end-to-end :
      `cd cli && npm test`. Expect 0 failures. Includes the
      existing 5 e2e tests + 5 + 1 from help-snapshots + 1 ×
      N-archetypes from smoke + 6 from load-fixture.
      [Story: NFR-T51-002]
- [ ] **T-VER-010** — Update `.forge.yaml` timeline :
      `specified: 2026-05-14`, `designed: 2026-05-14`,
      `planned: 2026-05-14`, `implemented: 2026-05-XX` (the
      `/forge:implement` runner date).
      [Story: F.2]

### Phase 6 exit gate

- All 17 L1 + 2 L2 (when env-gated) tests GREEN.
- `verify.sh` OVERALL PASS.
- `constitution-linter.sh` OVERALL PASS.
- `validate-change-yaml.sh` exit 0.
- No `[NEEDS CLARIFICATION:]` markers in change files.
- Vitest e2e green end-to-end.

---

## Release wiring (out-of-scope of this change but documented for the maintainer)

Once this change is archived, the maintainer tags **v0.3.3** :

```bash
# 1. Bump VERSION + cli/package.json + seal CHANGELOG section
echo "0.3.3" > VERSION
# (edit cli/package.json + CHANGELOG.md by hand or via tooling)

# 2. Commit + push the bump

# 3. Run the release helper from f3-release-script-fix
bash scripts/release.sh --version 0.3.3 --otp <6-digits-from-2FA-app>
```

The `prepublishOnly` hook installed by this change exercises the
T5.1.C gate on the very tarball being published. If the gate flags
anything, the maintainer either fixes-forward in a new change or
uses `FORGE_SKIP_PREPUBLISH=1` per ADR-T51-005 + files the
mandatory follow-up issue.

---

## Sequencing summary

```
Phase 1 (RED + CI)           → 17 L1 stubs FAIL ; 2 L2 skip-pass ; harness registered
Phase 2 (T5.1.0 Taskfile)    → L1 anchors 1+2 GREEN ; 15 L1 still FAIL
Phase 3 (T5.1.A snapshots)   → L1 anchors 3+4 GREEN ; 13 L1 still FAIL
Phase 4 (T5.1.B smoke)       → L1 anchors 5,6,7,8,12 GREEN ; 8 L1 still FAIL
Phase 5 (T5.1.C prepublish)  → L1 anchors 9,10,11 GREEN ; 5 L1 still FAIL
Phase 6 (docs + gates)       → L1 anchors 13,14,15,16,17 GREEN ; ALL 17 L1 GREEN
```

Parallelizable `[P]` tasks within each phase MAY be batched. Tasks
across phase boundaries MUST stay sequential per the TDD discipline.
