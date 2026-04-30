# Specs: a7-forge-upgrade

<!-- Audit: Module A.7 — `forge upgrade` non-destructive merge.            -->
<!-- Depends on: b1-foundations + b1-scaffolder + b1-delivery              -->
<!--             + c1-reference-project (all archived).                    -->
<!-- Format: ADDED-only on the new FR-UP-* namespace + 1 MODIFIED on       -->
<!--         scaffold-manifest schema (FR-GL-009 of b1-scaffolder).        -->

This change introduces a new `FR-UP-*` namespace governing the
`forge upgrade` capability. At archive time the namespace will be
consolidated into a new spec file `.forge/specs/upgrade.md` (per
the convention used for `forge-ci.md` after `g1-forge-ci` and
`example-reference.md` after `c1-reference-project`).

The 3 open questions from the proposal are **resolved at spec
time per user validation 2026-04-30** :

- **Q1 — conflict markers** : git-style (`<<<<<<<` / `=======` /
  `>>>>>>>`) for muscle memory + a `.merge-conflicts` companion
  file listing every conflicted path.
- **Q2 — backup strategy on `--force`** : require a clean Git
  working tree (`git status --porcelain` empty) before allowing
  `--force`. Adopters not on Git get an explicit error.
- **Q3 — schema upgrade detection** : compare
  `archetype_version` semver ; **major** version diff aborts with
  `[NEEDS MIGRATION: from X.Y.Z to A.B.C]` ; minor / patch bumps
  proceed normally.

---

## ADDED Requirements

### FR-UP-001: `forge upgrade` CLI subcommand

- **MUST** — a new file `cli/src/commands/upgrade.ts` declares the
  `upgrade` subcommand exposed via `cli/src/cli.ts` argv parsing,
  callable as `npx @sdd-forge/cli upgrade [target-dir]` or via the
  `forge upgrade [target-dir]` alias when the binary is installed.
- **MUST** — positional `target-dir` defaults to the current
  working directory ; when provided, MUST resolve to an existing
  directory containing a `.forge/scaffold-manifest.yaml` file. If
  the manifest is absent, the command exits 2 with the message
  `forge upgrade: target is not a Forge project (missing
  .forge/scaffold-manifest.yaml)`.
- **MUST** — supports the flags `--dry-run` (default `false`),
  `--force` (default `false`), and `--verbose` (default `false`).
  Unknown flags exit 2 with a usage message.
- **MUST** — exit codes follow the convention established by
  `init.sh` (FR-GL-011 of `b1-scaffolder`) :
  `0` success, `2` argument error, `3` regex / format validation
  failure, `4` framework-owned-paths file collision unresolvable,
  `5` missing required tool (`git` for the 3-way merge), `7`
  upgrade aborted (e.g. major-version migration required), `8`
  conflicts produced (when running without `--force`).
- **SHALL** — emits a structured summary at completion :
  ```
  forge upgrade : <project-name>
    archetype:        <id>
    from version:     <BASE>
    to version:       <RIGHT>
    files unchanged:  <N>
    files upgraded:   <N>
    files preserved:  <N>   # local edits, framework unchanged
    files conflicted: <N>   # 3-way merged with conflict markers
    files skipped:    <N>   # excluded paths (specs/, changes/, ...)
  ```

**Constitution reference:** Article V (gates), Article X (CLI
ergonomics). **Testable:** yes — Vitest unit + L1
`test_upgrade_cli_flags_parse` in `a7.test.sh`.

### FR-UP-002: `framework-owned-paths.yml` declares the merge surface

- **MUST** — a new file `cli/assets/framework-owned-paths.yml`
  declares two top-level keys :
  - `owned:` — list of paths (relative to project root) that
    `forge upgrade` is responsible for merging. Includes :
    `.forge/constitution.md`, `.forge/standards/**`,
    `.forge/templates/**`, `.forge/schemas/**`,
    `.forge/scripts/**`, `.claude/agents/**`,
    `.claude/commands/**`, `.claude/skills/**`,
    `.claude/settings.json`, `.mcp.json`, `bin/forge-install.sh`,
    `bin/forge-lint`, `bin/forge-upgrade.sh`, `docs/GUIDE.md`,
    `docs/ARCHITECTURE.md`, `docs/VERSIONING.md`,
    `docs/CONTRIBUTING.md`, root `CLAUDE.md`, `LICENSE`,
    `NOTICE`.
  - `excluded:` — list of paths the framework MUST NOT touch.
    Includes : `.claude/settings.local.json`, `.forge/changes/**`,
    `.forge/specs/**`, `.forge/product/**`,
    `.forge/scaffold-manifest.yaml` (modified separately, not
    merged), `.omc/**`, anything under `target-dir` not enumerated
    in `owned:` (i.e. user code, project configuration, etc.).
- **MUST** — every path under `owned:` MUST resolve under the
  framework's own tree (validated by an L1 audit test :
  every owned path exists in the Forge framework repo).
- **MUST** — the file is YAML ; the runtime parses it via
  `yaml.safe_load` (Python) or the JS `js-yaml` package.
- **SHALL** — comments inside the YAML explain each section's
  rationale.

**Constitution reference:** Article V (deterministic gate),
Article X. **Testable:** yes — `test_framework_owned_paths_yml_shape`
+ `test_owned_paths_exist_in_framework`.

### FR-UP-003: 3-way merge truth table

- **MUST** — for each path under `owned:`, `forge upgrade` reads
  three contents :
  - **BASE** : the file as it existed in the framework at the
    project's `archetype_version` (resolved from
    `scaffold-manifest.yaml`). **Recovered by re-running the
    scaffolder against a tmpdir at the BASE version** and reading
    the file from that fresh tree. This requires the framework
    repo to keep a versioned archive of past scaffold outputs —
    deferred to FR-UP-008.
  - **LEFT** : the file in the project's current tree.
  - **RIGHT** : the file in the framework's current tree (the
    Forge install running `forge upgrade`).
- **MUST** — merge action follows the exhaustive truth table :
    - **same / same** → no-op, count under `unchanged`.
    - **same / changed** → replace LEFT with RIGHT (clean upgrade),
      count under `upgraded`.
    - **changed / same** → keep LEFT (user customization
      preserved), count under `preserved`.
    - **changed / changed** → run `git merge-file --diff3 LEFT
      BASE RIGHT` ; on success (no conflict markers in output),
      count under `upgraded` ; on conflict, leave conflict markers
      in LEFT and append the path to `.merge-conflicts`, count
      under `conflicted`.
- **MUST** — sameness is determined by SHA-256 of the file's raw
  bytes. No semantic comparison ; binary-level equality.
- **MUST** — when BASE is unavailable (e.g., archived
  `archetype_version` no longer reachable), the truth table
  collapses to a 2-way comparison : if LEFT == RIGHT → no-op,
  else `--force` required to replace, else conflict.

**Constitution reference:** Article V, Article X. **Testable:**
yes — L2 fixture matrix `test_merge_truth_table_exhaustive`
covering all 4 cells.

### FR-UP-004: Conflict markers + `.merge-conflicts` companion

- **MUST** — when `git merge-file --diff3` produces conflict
  markers, the markers are written **in-place** to the LEFT file
  using the standard git format
  (`<<<<<<< HEAD` / `||||||| BASE` / `======= ` / `>>>>>>> NEW`).
- **MUST** — at completion, `forge upgrade` writes a
  `.merge-conflicts` file at the project root listing every
  conflicted path, one per line, prefixed `[CONFLICT] <path>`.
  When zero conflicts, the file is removed if it existed.
- **MUST** — the command exits 8 when conflicts are produced and
  `--force` is NOT set. Adopters resolve conflicts manually, then
  re-run `forge upgrade` (which will see LEFT == RIGHT for the
  resolved files and exit cleanly).

**Constitution reference:** Article V. **Testable:** yes — L2
`test_conflict_markers_written` + `test_merge_conflicts_listing`.

### FR-UP-005: `--force` requires clean Git working tree

- **MUST** — when `--force` is set, `forge upgrade` MUST first
  verify `git status --porcelain` is empty in the target dir.
  Non-empty → exit 7 with the message
  `forge upgrade: --force requires a clean Git working tree (use
  git stash / git commit first)`.
- **MUST** — when `--force` is set on a target NOT under Git
  control (no `.git` dir), exit 7 with
  `forge upgrade: --force requires a Git-managed target (initialize
  with git init first)`.
- **MUST** — with `--force`, the merge proceeds and conflicting
  files are written with conflict markers without aborting (exit
  0 instead of 8). Adopters resolve via `git diff` / `git
  checkout -- <path>` / etc.
- **SHALL** — without `--force`, conflicts produce exit 8 ; the
  project's working tree may be partially modified (each
  individual file is written atomically) and the
  `.merge-conflicts` companion is the audit trail.

**Constitution reference:** Article V (gates), Article X
(rollback discipline). **Testable:** yes — L2
`test_force_requires_clean_git` + `test_force_succeeds_when_clean`.

### FR-UP-006: Major-version migration abort

- **MUST** — before any merge, `forge upgrade` parses
  `archetype_version` from the project's
  `.forge/scaffold-manifest.yaml` and the corresponding
  schema's `version` field from the framework's
  `.forge/schemas/<archetype>/schema.yaml`. If the **major**
  version differs (e.g., `1.x.y` → `2.0.0`), the command aborts
  with exit 7 and the message
  `forge upgrade: major-version migration required (1.x.y →
  2.0.0). Manual migration needed — see docs/MIGRATIONS.md.
  [NEEDS MIGRATION: from <BASE> to <RIGHT>]`.
- **MUST** — minor and patch version bumps proceed normally.
- **SHALL** — when the schema's `version` field is absent (e.g.,
  legacy archetype prior to FR-GL-024 of `b1-delivery`), the
  command emits a warning and proceeds (treats as patch bump).

**Constitution reference:** Article III.4 (anti-hallucination —
abort vs guess), Article IV.4 (lifecycle). **Testable:** yes —
L2 fixture `test_major_version_aborts` +
`test_minor_patch_bumps_proceed`.

### FR-UP-007: `scaffold-manifest.yaml` gains `upgrade_history`

- **MUST** — after a successful `forge upgrade` run (exit 0 or 8
  with `--force`), the project's
  `.forge/scaffold-manifest.yaml` is updated to record the
  upgrade. New top-level optional key
  `upgrade_history:` is a list ; each entry is a map :
  - `date:` (ISO-8601, UTC).
  - `from_version:` (BASE archetype_version).
  - `to_version:` (RIGHT archetype_version, also written to
    the manifest's top-level `archetype_version` field).
  - `from_template_set_sha:` and `to_template_set_sha:` for
    finer-grained traceability.
  - `counts:` (map with `unchanged / upgraded / preserved /
    conflicted / skipped` keys).
  - `cli_version:` (the `cli/VERSION` running the upgrade).
- **MUST** — the field is **append-only**. Each upgrade adds
  one entry. Existing entries are never edited.
- **MUST** — the manifest's top-level `archetype_version` and
  `scaffold_date` fields are updated to reflect the new state ;
  `scaffold_plan_sha` and `template_set_sha` are recomputed from
  the framework's current state ; the original
  `project_name` / `reverse_domain` / `root_module` fields are
  preserved (project identity is immutable).

**Constitution reference:** Article IV (delta-based history),
Article V (audit trail). **Testable:** yes —
`test_upgrade_history_appended_after_run` +
`test_upgrade_history_append_only`.

### FR-UP-008: BASE recovery via versioned scaffolder snapshots

- **MUST** — to recover BASE for the 3-way merge, `forge
  upgrade` invokes a new helper script
  `bin/forge-snapshot.sh` that, given a target
  `archetype_version`, produces a tmpdir containing the
  framework state at that version. Implementation : reads
  `cli/assets/scaffold-snapshots/<archetype>/<version>.tar.gz`
  (a pre-built tarball of the framework files at that version)
  and extracts it. The tarballs are committed to the framework
  repo and shipped in the CLI tarball.
- **MUST** — at archive time of `a7-forge-upgrade`, the snapshot
  for `full-stack-monorepo / 1.0.0` is committed (the version
  promoted by `b1-delivery`). Future archetype releases
  produce additional snapshots via a new release workflow
  (deferred to a follow-up).
- **MUST** — when the requested snapshot is missing, the 3-way
  merge degrades to 2-way (per FR-UP-003) with a warning. This
  preserves graceful degradation for archetypes not yet
  snapshotted.
- **SHALL** — snapshot tarballs MUST stay under 1 MB
  **gzipped (on-disk)** to keep the CLI bundle reasonable.
  The relevant constraint is the bytes that ship inside the
  CLI tarball — compressed = bundle weight. The
  uncompressed expansion is a transient cost paid at
  `forge upgrade` time only ; not budget-critical.
  Measured at archive time of `a7-forge-upgrade` :
  `cli/assets/scaffold-snapshots/full-stack-monorepo/1.0.0.tar.gz`
  is **~415 KB gzipped** (~1.8 MB uncompressed) — well within
  the gzipped budget.

**Constitution reference:** Article V. **Testable:** yes —
`test_snapshot_tarball_present_and_extractable` +
`test_snapshot_size_under_budget`.

### FR-UP-009: New shell driver `bin/forge-upgrade.sh`

- **MUST** — `bin/forge-upgrade.sh` is the underlying primitive
  invoked by the JS CLI. The TS `upgrade.ts` shells out to this
  script for the actual merge work, mirroring the
  `init.ts → init.sh` separation established by `b1-scaffolder`.
- **MUST** — the script exposes a stable invocation contract :
  `bin/forge-upgrade.sh --target <dir> --to-version <X.Y.Z>
  [--dry-run] [--force] [--verbose]`. The TS layer translates
  user-facing argv into this contract.
- **MUST** — the script passes `shellcheck` (already wired into
  `forge-ci.yml` `lint` job).
- **MUST** — every recursive walk uses the
  `find_excluding_examples` pattern established by `c1-reference-project`
  (FR-GL-027) to avoid recursing into `examples/` when running
  inside the Forge framework repo's own dog-food upgrade
  scenario.

**Constitution reference:** Articles V, VII (shell discipline by
analogy), X. **Testable:** yes — L1 `test_upgrade_sh_invocation_contract`.

### FR-UP-010: Standard `global/upgrade-policy.md`

- **MUST** — file `.forge/standards/global/upgrade-policy.md`
  exists and contains six canonical H2 sections :
  `## Framework-owned paths`, `## Three-way merge policy`,
  `## Conflict resolution discipline`,
  `## Schema-version migration boundary`,
  `## Upgrade history audit trail`,
  `## Interdictions`.
- **MUST** — `## Interdictions` lists the three forbidden
  patterns : (1) hand-editing files under `owned:` without a
  Forge change opening (drift accumulates silently), (2) running
  `forge init --force` when meaning `forge upgrade` (init wipes
  ; upgrade preserves), (3) committing
  `.merge-conflicts` (it's session state, gitignored).
- **MUST** — the standard cites Articles III.4 (anti-hallucination
  — major-version abort), IV.4 (lifecycle), V (gates).

**Constitution reference:** Articles III.4, IV.4, V.
**Testable:** yes — `test_standard_upgrade_policy_has_required_sections`.

### FR-UP-011: Standards index references the new standard

- **MUST** — `.forge/standards/index.yml` contains a new entry :
  `id: global/upgrade-policy`, `path:
  standards/global/upgrade-policy.md`, `scope: all`,
  `priority: high`, triggers including `upgrade`, `forge
  upgrade`, `merge`, `framework-owned`, `archetype_version`,
  `upgrade_history`.
- **SHALL** — purely additive ; no pre-existing entry is
  modified.

**Constitution reference:** Article V (JIT loading).
**Testable:** yes — `test_index_has_upgrade_policy_entry`.

### FR-UP-012: `.gitignore` covers `.merge-conflicts`

- **MUST** — Forge repo's root `.gitignore` adds
  `.merge-conflicts` (no path prefix — applies at any depth).
  Each scaffolded project's `.gitignore` (delivered by the
  scaffolder per FR-GL-009) is updated similarly via a
  `b1-scaffolder` follow-up overlay.
- **SHOULD** — the line is documented inline as `# Forge
  upgrade — session-only conflict listing, never committed`.

**Constitution reference:** Article X. **Testable:** yes —
`test_gitignore_covers_merge_conflicts`.

### FR-UP-013: BDD scenarios for `forge upgrade`

- **MUST** — `features/upgrade.feature` ships the 5 user-facing
  scenarios at the top level of the change directory :
  - Clean upgrade (no local edits)
  - Customized file (local edits + framework unchanged)
  - Conflicting upgrade (both changed)
  - Dry-run (no side effects)
  - Re-run after upgrade (idempotence)
- **SHALL** — each scenario MAY be runtime-wired via the L3
  fixture in `a7.test.sh` (uses `examples/forge-fsm-example/`
  as the target).

**Constitution reference:** Article II. **Testable:** yes —
`test_features_upgrade_feature_present` +
`test_each_bdd_scenario_documented`.

### FR-UP-014: Test harness `a7.test.sh`

- **MUST** — `.forge/scripts/tests/a7.test.sh` exists, is
  executable, sources `_helpers.sh`. Manifest pattern (per the
  convention from `delivery.test.sh` / `g1.test.sh` /
  `c1.test.sh`) ; a meta self-check
  `test_a7_manifest_self_consistency` enforces parity.
- **MUST** — three levels of testing :
  - **L1 (hermetic)** : structural validation of
    `framework-owned-paths.yml` (FR-UP-002), CLI flag parsing
    via static text-grep on `upgrade.ts`, scaffold-manifest
    schema with `upgrade_history` extension (FR-UP-007),
    standard sections (FR-UP-010), index entry (FR-UP-011),
    `.gitignore` (FR-UP-012), feature file (FR-UP-013).
  - **L2 (fixture-based)** : 3-way merge truth table
    (FR-UP-003), conflict markers (FR-UP-004),
    `--force` Git cleanliness gate (FR-UP-005), major-version
    abort (FR-UP-006). Uses tmpdirs with synthetic
    BASE / LEFT / RIGHT trees ; no external tool requirement
    beyond `git`.
  - **L3 (opt-in via `--require-external-tools`)** :
    end-to-end against `examples/forge-fsm-example/` —
    simulates a real upgrade after a synthetic framework bump.
- **MUST** — invoked by `verify.sh` Section 7 at L1 only,
  alongside `c1.test.sh` and the existing 5 harnesses.
- **MUST** — exits 0 when every fixture passes ; non-zero with
  `[FAIL] <test-name>: <reason>` on first failure.

**Constitution reference:** Article I (TDD). **Testable:**
self-testing — manifest self-consistency exercises the harness.

### FR-UP-015: Spec consolidation at `upgrade.md`

- **MUST** — at archive time, `.forge/specs/upgrade.md` exists
  as a new consolidated spec for the `FR-UP-*` namespace
  (consistent with `forge-ci.md` and `example-reference.md`
  conventions).
- **MUST** — links back to `a7-forge-upgrade` in its
  `## Archived changes` table and lists all 15 `FR-UP-*`
  requirements + relevant NFR-UP-*.
- **SHALL** — opens with a one-paragraph audience note : this
  spec governs the `forge upgrade` capability ; it is distinct
  from `cli.md` (which would govern the CLI as a whole, not yet
  present).

**Constitution reference:** Articles III.2, IV. **Testable:** yes
— `test_upgrade_spec_present_post_archive` (gated on `status:
archived`).

---

## MODIFIED Requirements

### FR-GL-009: Archetype template tree under `.forge/templates/archetypes/full-stack-monorepo/`

<!-- MODIFIED by a7-forge-upgrade (2026-04-30) — scaffold-manifest schema gains upgrade_history extension. -->

**Previously (b1-scaffolder):**
> `.forge/templates/archetypes/full-stack-monorepo/scaffold-plan.yaml`
> declares every template with `source`, `target`, `substitute`
> per entry [...] [The scaffolder writes a manifest with]
> `archetype`, `archetype_version`, `scaffold_plan_sha`,
> `template_set_sha`, `scaffold_date`, `project_name`,
> `reverse_domain`, `root_module`, plus tool versions.

**Now:** *(plan structure unchanged)* The scaffold-manifest
schema gains an optional top-level field `upgrade_history:`
populated post-scaffold by `forge upgrade` (FR-UP-007). At
scaffold time the field is absent or empty `[]`. After every
`forge upgrade` run, one entry is appended. The
`archetype_version` and `scaffold_date` fields are mutated by
upgrades (kept in sync with the most recent state) ; identity
fields (`project_name`, `reverse_domain`, `root_module`) are
**immutable** post-scaffold.

**Constitution reference:** Articles VI, VII, VIII, X.
**Testable:** yes — extended scaffolder L1 schema test +
`test_upgrade_history_append_only` (a7.test.sh).

---

## REMOVED Requirements

*(none — purely additive on FR-UP-* + 1 MODIFIED on FR-GL-009.)*

---

## Non-Functional Requirements

### NFR-UP-001: Upgrade idempotence

- **MUST** — running `forge upgrade` twice in a row on the
  same project, with no framework change between the two runs,
  produces zero modifications on the second run (every file
  reads as `unchanged`). Exercised by L2
  `test_upgrade_idempotent_when_no_change`.

### NFR-UP-002: Upgrade performance

- **SHALL** — `forge upgrade` completes in **≤ 10 seconds** on
  a fully-populated `full-stack-monorepo` project (warm cache,
  ~50 framework-owned files). Hard ceiling : 30 seconds.

### NFR-UP-003: Snapshot bundle byte budget

- **MUST** — every snapshot tarball under
  `cli/assets/scaffold-snapshots/<archetype>/<version>.tar.gz`
  is **≤ 1 MB gzipped (on-disk)** per FR-UP-008. The compressed
  size is what affects the CLI bundle weight. Cumulative budget
  for all snapshots in the CLI bundle : ≤ 5 MB gzipped.

### NFR-UP-004: Audit-ID traceability

- **MUST** — every file created or modified by this change
  carries an `<!-- Audit: A.7 (part of a7-forge-upgrade) -->`
  HTML comment in its first five lines, or the YAML / shell
  equivalent (per NFR-004 of `b1-foundations`).

### NFR-UP-005: Backwards compatibility on init flow

- **MUST** — adding the `upgrade_history:` field to
  `scaffold-manifest.yaml` MUST NOT break existing scaffold
  consumers. The field is optional ; legacy manifests without it
  are read as `upgrade_history: []`. Exercised by an extended
  scaffolder L1 fixture.

### NFR-UP-006: Conflict-marker output stability

- **MUST** — when `git merge-file --diff3` is invoked twice on
  the same BASE / LEFT / RIGHT triple, the conflict markers it
  produces are byte-identical (Git's deterministic merge
  property). Exercised by L2 `test_merge_output_deterministic`.

---

## Acceptance Criteria (BDD)

### AC-UP-001: Clean upgrade

```gherkin
Feature: Forge upgrade — clean
  As a Forge adopter
  I want forge upgrade to pull in framework updates without my
  customizations getting lost
  So that I can follow Constitution bumps without manual chores

  Scenario: No local edits, framework changed
    Given a project scaffolded at archetype_version "1.0.0"
    And the framework has bumped to "1.1.0" (new standard added)
    And the adopter has not modified any framework-owned file
    When the adopter runs "forge upgrade"
    Then the new standard appears in .forge/standards/
    And the project's archetype_version is now "1.1.0"
    And upgrade_history has one entry recording the bump
    And the command exits 0
    And the structured summary reports "files upgraded: N" with N >= 1
```

### AC-UP-002: Customized file preserved

```gherkin
Feature: Forge upgrade — local customization preserved
  Scenario: User edited a standard, framework did not change it
    Given a project scaffolded at archetype_version "1.0.0"
    And the adopter has edited .forge/standards/global/naming.md locally
    And the framework has not modified that file in 1.1.0
    When the adopter runs "forge upgrade"
    Then .forge/standards/global/naming.md retains the local edits
    And the structured summary reports "files preserved: 1"
    And no .merge-conflicts file is created
    And the command exits 0
```

### AC-UP-003: Conflict produces markers + companion file

```gherkin
Feature: Forge upgrade — conflict
  Scenario: Both user and framework changed the same file
    Given a project scaffolded at archetype_version "1.0.0"
    And the adopter has edited .forge/standards/rust/error-handling.md
    And the framework's 1.1.0 also modifies that same file
    When the adopter runs "forge upgrade"
    Then .forge/standards/rust/error-handling.md contains git-style conflict markers (<<<<<<<, =======, >>>>>>>)
    And .merge-conflicts at the project root lists that path with "[CONFLICT]" prefix
    And the structured summary reports "files conflicted: 1"
    And the command exits 8
```

### AC-UP-004: Dry-run has no side effects

```gherkin
Feature: Forge upgrade — dry-run
  Scenario: --dry-run prints the plan without writing
    Given a project scaffolded at archetype_version "1.0.0"
    And the framework has bumped to "1.1.0"
    When the adopter runs "forge upgrade --dry-run"
    Then the structured summary is printed
    And no file in the project is modified
    And .forge/scaffold-manifest.yaml retains "1.0.0" as archetype_version
    And no .merge-conflicts file is created
    And the command exits 0
```

### AC-UP-005: Re-run is idempotent

```gherkin
Feature: Forge upgrade — idempotence
  Scenario: Two consecutive runs after a single bump
    Given a project at archetype_version "1.0.0" with framework at "1.1.0"
    And the adopter has run "forge upgrade" successfully (exit 0)
    When the adopter runs "forge upgrade" a second time
    Then the structured summary reports "files unchanged: <total>" and 0 elsewhere
    And no file is modified
    And upgrade_history gains exactly one new entry on the second run with counts all-zero
    And the command exits 0
```

### AC-UP-006: Major-version migration aborts

```gherkin
Feature: Forge upgrade — major-version migration
  Scenario: Major bump 1.x → 2.0
    Given a project at archetype_version "1.5.2"
    And the framework's current version is "2.0.0"
    When the adopter runs "forge upgrade"
    Then the command exits 7
    And the output contains "[NEEDS MIGRATION: from 1.5.2 to 2.0.0]"
    And no file in the project is modified
```

### AC-UP-007: --force without clean Git aborts

```gherkin
Feature: Forge upgrade — force safety
  Scenario: --force on a Git tree with uncommitted changes
    Given a project at archetype_version "1.0.0" with framework at "1.1.0"
    And the adopter has uncommitted modifications in the project
    When the adopter runs "forge upgrade --force"
    Then the command exits 7
    And the output explicitly mentions "clean Git working tree" and suggests "git stash" or "git commit"
    And no file in the project is modified
```

---

## Constitution compliance summary

| Article | Compliance |
|---|---|
| I — TDD | New harness `a7.test.sh` follows manifest pattern. CLI subcommand ships with Vitest unit tests. RED→GREEN order across 3 implementation phases. |
| II — BDD | `features/upgrade.feature` ships 5 (+2 advanced) Gherkin scenarios covering happy path + customization preservation + conflict + dry-run + idempotence + major-version + force-safety. |
| III — Specs Before Code | This spec is the gate before design and tasks. Open Questions resolved at spec time. |
| III.4 — Anti-Hallucination | Major-version migration aborts with `[NEEDS MIGRATION:]` (FR-UP-006). Don't guess — surface and stop. |
| IV — Delta-Based Change Management | All modifications are in delta format. Scaffold-manifest's `upgrade_history` is append-only. |
| IV.4 — Lifecycle | `upgrade_history` array tracks every applied upgrade with date, prior version, new version. |
| V — Conformance Gate | `forge upgrade` IS the mechanism for keeping projects in conformance with bumped Constitutions. The conformance gate governs `forge upgrade` itself. |
| X — Quality | CLI passes ESLint + Vitest. Shell driver passes `shellcheck`. Standard passes `pymarkdown`. NFR-UP-002 caps runtime ≤ 10 s. NFR-UP-003 caps snapshot bundle ≤ 1 MB. |
| VI / VII / VIII / IX / XI | Out of scope — `forge upgrade` is a framework-internal CLI command. No Flutter / Rust / infra / observability / AI surface. |

✅ **No constitutional violation. Proceeding to /forge:design.**
