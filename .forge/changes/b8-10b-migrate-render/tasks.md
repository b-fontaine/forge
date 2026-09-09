# Tasks — `b8-10b-migrate-render`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — RED, against the unfixed script

- [x] **T1.1** Add `_test_b810_l1_013_migration_output_rendered` to
      `b8-10.test.sh`: build a synthetic target (a `.forge/scaffold-manifest.yaml`
      with `project_name`/`reverse_domain`/`root_module` plus a couple of files),
      run a real migration into it, assert zero `.tmpl`, zero placeholders, and no
      `X.tmpl` beside an existing `X`.
      [Story: FR-B810B-005]
- [x] **T1.2** Run it against **today's** `cp`-based script. **Confirm RED**, and
      confirm the failure names actual `.tmpl` paths. A test that passes here tests
      nothing — the defect is present in the tree right now.
      [Story: FR-B810B-001, FR-B810B-002]

## T2 — the migration plan

- [x] **T2.1** Author
      `.forge/templates/archetypes/full-stack-monorepo/migration-plan-2.0.0.yaml`
      with all 36 entries, `substitute: true`, targets in adopter layout.
      [Story: FR-B810B-001]
- [x] **T2.2** Assert the plan covers the tree exactly: entry count == file count
      under `2.0.0/`, no entry pointing at a missing source, no source unlisted.
      A hand-written 36-line list drifts the moment a file is added.
      [Story: FR-B810B-001]

## T3 — GREEN

- [x] **T3.1** In `forge-migrate-flagship.sh`: read the three substitution values
      from the target manifest; exit **7** naming the key if any is missing.
      [Story: FR-B810B-003]
- [x] **T3.2** Render the 2.0.0 set via `overlay.sh --plan migration-plan-2.0.0.yaml`
      into a `mktemp -d`; point RIGHT at it; **exclude its
      `.forge/scaffold-manifest.yaml`** from the merge surface.
      [Story: FR-B810B-001, NFR-B810B-001]
- [x] **T3.3** Retire `_b810_map_relpath` — the plan's `target:` does the mapping.
      [Story: FR-B810B-001]
- [x] **T3.4** Run the harness. **Confirm GREEN**, including the nine previously
      shadowed files now going through `_a7_classify`.
      [Story: FR-B810B-004]

## T4 — the manifest exclusion (re-scoped after measuring)

- [x] **T4.1** ~~Second-run assertion: migrate twice, expect zero `upgraded`.~~
      **Not applicable, established by execution.** A second full run is refused by
      the preflight, which requires `archetype_version: 1.0.0`; the first run sets
      `2.0.0`. And `docs/MIGRATIONS.md:76-81` scopes its idempotence claim to Phase 1
      only. The task was written against an assumption about the script that reading
      it would have corrected. Verified instead: after migration the adopter's
      manifest is intact — `project_name`, `reverse_domain`, `root_module`,
      `upgrade_history` all present, `archetype_version` correctly `2.0.0`.
      [Story: NFR-B810B-003]
- [x] **T4.2** Probe the exclusion both ways on a target seeded with a prior
      `upgrade_history` entry. **Result: preserved with the exclusion, DESTROYED
      without it.** The first attempt at this probe used a freshly-rendered tree,
      which has no history to lose, and came back clean — a passing probe that
      proved nothing. The exposure is data loss, not non-convergence.
      [Story: NFR-B810B-003]

## T5 — prove the tests are not vacuous

- [x] **T5.1** Mutation-probe each assertion of T1.1 independently: reintroduce a
      raw `cp` for one file; leave one placeholder unsubstituted; recreate one
      shadowing `X.tmpl`. Each must red its own assertion.
      [Story: FR-B810B-005]
- [x] **T5.2** Probe the manifest-refusal path: remove `project_name` from the
      target manifest, confirm exit **7** and that the message names the key —
      not an empty substitution (ADR-B810B-001).
      [Story: FR-B810B-003]

## T6 — the real-tree leg

- [x] **T6.1** L2 opt-in test `_test_b810_l2_002_real_migration_rendered`: render a
      real 1.0.0 project via `bin/forge-init-fsm.sh`, migrate, assert on the actual
      result. Gated on the toolchain (flutter + cargo), skip-when-absent.
      [Story: FR-B810B-005]
- [x] **T6.2** Execute it once locally and record the counts in `evidence.md` —
      before/after, so the 36 / 24 / 9 figures have an after column.
      [Story: FR-B810B-005]

## T7 — docs + banner

- [x] **T7.1** Fix the stale banner at `:175` (`scaffoldable: false until B.8.14`).
      [Story: FR-B810B-006]
- [x] **T7.2** `docs/MIGRATIONS.md`: describe what is actually delivered, and add
      the already-migrated-adopter cleanup note (Q-004) — which files are strays and
      that the tool will not delete them.
      [Story: FR-B810B-007]
- [x] **T7.3** `CHANGELOG.md` `[Unreleased]`, calling out the behavioural change:
      nine files that previously landed beside their rendered twin now merge.
      [Story: FR-B810B-007]

## T8 — regression

- [x] **T8.1** `b8-10.test.sh` full; `b8-2.test.sh` (frozen 1.0.0 snapshot must not
      drift); `b9-2.test.sh::T-010` (`overlay.sh` byte-unchanged — this change must
      not touch it).
      [Story: NFR-B810B-004]
- [x] **T8.2** Full 80-entry CI matrix sweep (match the bare-invocation entries too,
      not only `--level` ones) + shellcheck.
      [Story: NFR-B810B-004]
- [x] **T8.3** `verify.sh` + `constitution-linter.sh` **after** flipping
      `.forge.yaml` to `implemented`.
      [Story: NFR-B810B-004]

## Negative scope guard

- [x] **T9.1** `git diff --stat`: no change to `overlay.sh`, the `_a7_*` library in
      `forge-upgrade.sh`, `.forge/scaffold-snapshots/**`, or the migrate script's
      `--target`-only ABI.
      [Story: NFR-B810B-002, NFR-B810B-004]
