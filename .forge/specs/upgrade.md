# Spec: upgrade

<!-- Audit: Module A.7 — `forge upgrade` non-destructive merge.            -->
<!-- This file accumulates archived requirements for the                   -->
<!-- `forge upgrade` capability. It is distinct from                       -->
<!-- `full-stack-monorepo.md` (which governs the **archetype contract**)   -->
<!-- and from `example-reference.md` (which governs the **reference        -->
<!-- example tree**).                                                      -->
<!--                                                                       -->
<!-- Audience here : Forge maintainers + adopters relying on               -->
<!-- `forge upgrade` to mechanize Constitution / standards / agents bumps. -->

This spec is the consolidated contract for the **`forge upgrade`
capability** — the non-destructive 3-way merge of Forge framework
updates into a scaffolded project. It activates whenever the
framework version declared in a project's
`.forge/scaffold-manifest.yaml` differs from the version of the
Forge framework currently invoking `forge upgrade`.

The full standard governing the discipline is
`.forge/standards/global/upgrade-policy.md`.

---

## Archived changes

| Change | Date | Phase | FRs added |
|---|---|---|---|
| [`a7-forge-upgrade`](../changes/a7-forge-upgrade/) | 2026-04-30 | First reference implementation of `forge upgrade` | FR-UP-001..015 + NFR-UP-001..006 ; MODIFIED FR-GL-009 (scaffold-manifest gains `upgrade_history`) |

---

## Requirements

### FR-UP-001: `forge upgrade` CLI subcommand

- **MUST** — `cli/src/commands/upgrade.ts` declares the `upgrade`
  subcommand exposed via `cli/src/cli.ts`. Callable as
  `npx @sdd-forge/cli upgrade [target-dir]` or via the `forge
  upgrade [target-dir]` alias.
- **MUST** — positional `target-dir` defaults to cwd ; resolves
  to a directory containing `.forge/scaffold-manifest.yaml`.
  Missing manifest → exit 2 with explicit message.
- **MUST** — flags : `--dry-run` (no writes), `--force`
  (Git-cleanliness gated), `--verbose` (BASE-recovery
  diagnostics). Unknown flags → exit 2 with usage.
- **MUST** — exit codes : `0` success ; `2` argument error ; `5`
  missing required tool ; `7` upgrade aborted (major-version /
  dirty Git / non-Git target with `--force`) ; `8` conflicts
  produced (without `--force`).
- **SHALL** — emits a structured summary at completion (project
  name + archetype + from/to versions + per-category file counts).

**Constitution reference:** Articles V, X. **Testable:** yes —
Vitest `cli/test/commands/upgrade.test.ts` (5 unit tests) +
`test_upgrade_cli_flags_parse` in `a7.test.sh`.

### FR-UP-002: `framework-owned-paths.yml` declares the merge surface

- **MUST** — `.forge/framework-owned-paths.yml` declares
  `owned:` (managed by upgrade) and `excluded:` (never touched)
  glob lists. Bundled into `cli/assets/.forge/` by the existing
  bundle pipeline.
- **MUST** — every `owned:` glob resolves to at least one file
  in the framework repo. Audit test
  `test_owned_paths_exist_in_framework` enforces.
- **SHALL** — comments inside the YAML explain each section.

**Constitution reference:** Article V. **Testable:** yes —
`test_framework_owned_paths_yml_shape`,
`test_owned_paths_exist_in_framework`.

### FR-UP-003: 3-way merge truth table

- **MUST** — for each path under `owned:`, the upgrade reads
  three contents : BASE (recovered via snapshot), LEFT (project's
  current file), RIGHT (framework's current file). Sameness is
  binary SHA-256.
- **MUST** — merge action follows the exhaustive truth table :
  `same/same → unchanged`, `same/changed → upgraded`,
  `changed/same → preserved`, `changed/changed → 3-way merge`.
- **MUST** — when BASE is unavailable, degrade to 2-way
  comparison (same → unchanged, different → conflict / replace
  with `--force`).

**Constitution reference:** Article V. **Testable:** yes —
`test_merge_truth_table_exhaustive` (5 cells covered).

### FR-UP-004: Conflict markers + `.merge-conflicts` companion

- **MUST** — `git merge-file --diff3` writes git-style markers
  (`<<<<<<<` / `|||||||` / `=======` / `>>>>>>>`) in-place to LEFT.
- **MUST** — at completion, `<project-root>/.merge-conflicts`
  lists every conflicted path prefixed `[CONFLICT]`. Removed when
  zero conflicts remain.
- **MUST** — exit 8 when conflicts produced and `--force` is NOT
  set.

**Constitution reference:** Article V. **Testable:** yes —
`test_conflict_markers_written` + `test_merge_conflicts_listing`.

### FR-UP-005: `--force` requires clean Git working tree

- **MUST** — with `--force`, verify `git -C <target> status
  --porcelain` is empty. Non-empty → exit 7 with explicit message
  suggesting `git stash` / `git commit`.
- **MUST** — non-Git target (no `.git/`) → exit 7 with message
  suggesting `git init`.
- **MUST** — with `--force`, conflicts land in-place ; exit 0
  (not 8).

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_force_requires_clean_git` + `test_force_succeeds_when_clean`
+ `test_force_aborts_on_non_git`.

### FR-UP-006: Major-version migration abort

- **MUST** — before any merge, parse `archetype_version` from the
  manifest and the framework's schema's `version`. If the **major**
  components differ, exit 7 with `[NEEDS MIGRATION: from X.Y.Z
  to A.B.C]`.
- **MUST** — minor and patch bumps proceed normally.
- **SHALL** — schema without a `version` field → warning + treat
  as patch (graceful degradation for legacy archetypes pre-FR-GL-024).

**Constitution reference:** Articles III.4, IV.4. **Testable:**
yes — `test_major_version_aborts` + `test_minor_patch_bumps_proceed`.

### FR-UP-007: `scaffold-manifest.yaml` gains `upgrade_history`

- **MUST** — after a successful run, the project's
  `.forge/scaffold-manifest.yaml` is updated. New optional
  top-level field `upgrade_history:` is **append-only**, recording
  each upgrade with `date`, `from_version`, `to_version`,
  `from_template_set_sha`, `to_template_set_sha`, `counts`,
  `cli_version`.
- **MUST** — canonical fields (`archetype_version`,
  `scaffold_date`, `template_set_sha`, `tools`) are mutated to
  the most recent state.
- **MUST** — identity fields (`project_name`, `reverse_domain`,
  `root_module`) are **immutable post-scaffold**.

**Constitution reference:** Articles IV (delta-based history), V.
**Testable:** yes — `test_upgrade_history_appended_after_run` +
`test_upgrade_history_append_only` + `test_identity_fields_immutable`.

### FR-UP-008: BASE recovery via committed snapshot tarballs

- **MUST** — `.forge/scaffold-snapshots/<archetype>/<version>.tar.gz`
  contains the framework's `owned:` paths at that version. Bundled
  into the CLI tarball via the existing bundle pipeline.
- **MUST** — at archive time of `a7-forge-upgrade`, the snapshot
  for `full-stack-monorepo / 1.0.0` is committed (~422 KB
  gzipped, well under NFR-UP-003 1 MB on-disk budget).
- **MUST** — when the requested snapshot is missing, the merge
  degrades to 2-way (per FR-UP-003) with a `[BASE unavailable
  for X.Y.Z, falling back to 2-way merge]` warning when
  `--verbose`.
- **SHALL** — snapshots are produced by `bin/forge-snapshot.sh
  build <archetype> <version>`.

**Constitution reference:** Article V. **Testable:** yes —
`test_snapshot_tarball_present_and_extractable` +
`test_snapshot_size_under_budget` + `test_base_recovery_via_snapshot`.

### FR-UP-009: New shell driver `bin/forge-upgrade.sh`

- **MUST** — the underlying primitive invoked by the JS CLI via
  `spawn`. Library + main : sourcing exposes `_a7_*` helpers for
  unit-style testing ; direct invocation runs `_a7_main()`
  end-to-end.
- **MUST** — invocation contract :
  `bin/forge-upgrade.sh --target <dir> --to-version <X.Y.Z>
  [--dry-run] [--force] [--verbose]`.
- **MUST** — `find` walks honour the `find_excluding_examples`
  pattern from FR-GL-027 (skip-guard discipline).

**Constitution reference:** Articles V, X. **Testable:** yes —
`test_forge_upgrade_sh_exists_executable` +
`test_forge_upgrade_sh_uses_find_excluding_examples`.

### FR-UP-010: Standard `global/upgrade-policy.md`

- **MUST** — file `.forge/standards/global/upgrade-policy.md`
  exists with six canonical H2 sections : Framework-owned paths,
  Three-way merge policy, Conflict resolution discipline,
  Schema-version migration boundary, Upgrade history audit
  trail, Interdictions.
- **MUST** — Interdictions list 3 forbidden patterns : (1)
  hand-editing `owned:` files outside a Forge change, (2)
  `forge init --force` instead of `forge upgrade`, (3)
  committing `.merge-conflicts`.

**Constitution reference:** Articles III, IV.4, V, X.
**Testable:** yes — `test_standard_upgrade_policy_has_required_sections`.

### FR-UP-011: Standards index entry

- **MUST** — `.forge/standards/index.yml` contains
  `id: global/upgrade-policy`, `scope: all`, `priority: high`,
  triggers including `upgrade`, `forge upgrade`, `merge`,
  `framework-owned`, `archetype_version`, `upgrade_history`,
  `scaffold-snapshot`, `three-way merge`, `NEEDS MIGRATION`.

**Constitution reference:** Article V. **Testable:** yes —
`test_index_has_upgrade_policy_entry`.

### FR-UP-012: `.gitignore` covers `.merge-conflicts`

- **MUST** — root `.gitignore` contains `.merge-conflicts`.
  Documented inline as session-only state.

**Constitution reference:** Article X. **Testable:** yes —
`test_gitignore_covers_merge_conflicts`.

### FR-UP-013: BDD scenarios for `forge upgrade`

- **MUST** — `features/upgrade.feature` ships ≥ 5 Gherkin
  scenarios covering the 5 ACs from `specs.md` (clean upgrade,
  preservation, conflict, dry-run, idempotence) plus advanced
  cases (major-version abort, force-on-dirty-Git).

**Constitution reference:** Article II. **Testable:** yes —
`test_features_upgrade_feature_present`.

### FR-UP-014: Test harness `a7.test.sh`

- **MUST** — `.forge/scripts/tests/a7.test.sh` exists, executable,
  sources `_helpers.sh`. Manifest pattern with meta self-check.
- **MUST** — three levels :
  - L1 (hermetic) — structural / static / YAML checks.
  - L2 (no flag) — fixture-based merge truth-table tests using
    git merge-file in tmpdirs.
  - L3 (`--require-external-tools`) — end-to-end against
    `examples/forge-fsm-example/`.
- **MUST** — invoked from `forge-ci.yml` `harness` job alongside
  the existing 6 harnesses.

**Constitution reference:** Article I. **Testable:**
self-testing — `test_a7_manifest_self_consistency`.

### FR-UP-015: Spec consolidation at `upgrade.md`

- **MUST** — at archive time, `.forge/specs/upgrade.md` exists
  (this file). Consistent with `forge-ci.md` and
  `example-reference.md` per-namespace spec convention.
- **MUST** — links back to archived changes in the table above.

**Constitution reference:** Articles III.2, IV. **Testable:** yes
— `test_upgrade_spec_present_post_archive` (gated on c1's
`status: archived`).

---

## Non-Functional Requirements

### NFR-UP-001: Upgrade idempotence

- **MUST** — running `forge upgrade` twice in a row with no
  framework change between runs produces zero file mutation on
  the second run (every owned file reads as `unchanged`). The
  `upgrade_history` IS appended on each invocation (audit
  trail) ; this is per design, not a regression.

### NFR-UP-002: Upgrade performance

- **SHALL** — `forge upgrade` completes in **≤ 10 seconds** on
  a fully-populated `full-stack-monorepo` project, warm cache,
  ~50 framework-owned files. Hard ceiling : 30 seconds. Smoke
  test against `examples/forge-fsm-example/` at archive time of
  `a7-forge-upgrade` : ~1 second wall-clock for 175-file walk.

### NFR-UP-003: Snapshot bundle byte budget

- **MUST** — every snapshot tarball under
  `.forge/scaffold-snapshots/<archetype>/<version>.tar.gz` is
  **≤ 1 MB gzipped (on-disk)**. The compressed size is what
  affects the CLI bundle weight ; uncompressed expansion is a
  transient cost paid at upgrade time only. Cumulative budget for
  all snapshots in the CLI bundle : ≤ 5 MB gzipped.
- **Baseline at archive time of `a7-forge-upgrade`** :
  `full-stack-monorepo / 1.0.0` is **422 KB gzipped** (~1.8 MB
  uncompressed) — 41% of the per-snapshot budget.

### NFR-UP-004: Audit-ID traceability

- **MUST** — every file created or modified by this change
  carries an `<!-- Audit: A.7 (part of a7-forge-upgrade) -->`
  HTML comment in its first five lines, or the YAML / shell
  equivalent.

### NFR-UP-005: Backwards compatibility on init flow

- **MUST** — adding the optional `upgrade_history:` field to
  `scaffold-manifest.yaml` MUST NOT break existing scaffold
  consumers. Legacy manifests without it are read as
  `upgrade_history: []`.

### NFR-UP-006: Conflict-marker output stability

- **MUST** — `git merge-file --diff3` invoked twice on the same
  BASE / LEFT / RIGHT triple produces byte-identical conflict
  markers (Git's deterministic merge property).

---

## Scope

**In scope for `forge upgrade` (delivered so far):**

- The TS CLI subcommand (FR-UP-001) — **a7-forge-upgrade**.
- `framework-owned-paths.yml` (FR-UP-002) — **a7-forge-upgrade**.
- 3-way merge truth table + git merge-file (FR-UP-003) — **a7**.
- Conflict markers + `.merge-conflicts` (FR-UP-004) — **a7**.
- `--force` Git-cleanliness gate (FR-UP-005) — **a7**.
- Major-version migration abort (FR-UP-006) — **a7**.
- `upgrade_history` append-only ledger (FR-UP-007) — **a7**.
- Snapshot tarball BASE recovery (FR-UP-008) — **a7** with the
  `full-stack-monorepo / 1.0.0` snapshot committed.
- Shell driver `bin/forge-upgrade.sh` (FR-UP-009) — **a7**.
- Standard `global/upgrade-policy.md` (FR-UP-010) — **a7**.
- Index entry (FR-UP-011) — **a7**.
- `.gitignore` covers `.merge-conflicts` (FR-UP-012) — **a7**.
- `features/upgrade.feature` 7 scenarios (FR-UP-013) — **a7**.
- Test harness `a7.test.sh` 29 tests (FR-UP-014) — **a7**.
- This consolidated spec (FR-UP-015) — **a7**.

**Deferred to future changes (out of scope for A.7):**

- Cross-archetype upgrade (e.g. `default → full-stack-monorepo`).
- Automated snapshot production on framework version bumps
  (currently produced by hand at archive time of each release).
- `docs/MIGRATIONS.md` content for major-bump migrations
  (referenced by FR-UP-006 ; created with a stub at archive time
  of A.7, populated as major bumps land).
- Merge surface extension to a project's local additions
  (e.g. project-specific standards under
  `.forge/standards/project/`).
- Forge Guardian GitHub App (G.3) automating `forge upgrade`
  invocations on PRs.
