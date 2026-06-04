# Proposal: b8-15-upgrade-matrix

**Audit item**: B.8.15 (docs/new-archetypes-plan.md §4.2, lines 2358-2397)
**Effort**: M · **Status**: proposed → 2026-06-04
**Type**: E2E test harness + forge-ci registration. No standard/schema/constitution mutation.

## Why

B.8.15 is **T5.1 Layer D** — the `forge upgrade` matrix test, the last T5.1 layer
and the **gate before the v0.4.0 stable `npm publish`**. It blocks silent
migration regressions: for each N-1 → N archetype pair it scaffolds the N-1
baseline, upgrades, and asserts the upgrade machinery's invariants (ledger,
merge-conflicts, manifest bump, smoke re-run) plus the negative governance path.

## Ground-Truth (6-mapper + critic workflow `wf_3b8aeb15`)

- **Deliverable = a harness, not a workflow.** `forge-ci.yml` has no GitHub Actions
  matrix — the suite is a hand-rolled bash array (`:68-121`). The "matrix" is
  realised as **cells = harness test functions** in
  `.forge/scripts/tests/b8-15.test.sh`, registered with one line in `forge-ci.yml`.
- **Driver decision (ADR-B815-001):** the positive `1.0.0 → 2.0.0` flagship cell
  drives **`bin/forge-migrate-flagship.sh`** (it bypasses `_a7_check_version_compat`,
  hard-codes 1.0.0→2.0.0, BASE = frozen 1.0.0 snapshot, RIGHT = the **live** 2.0.0
  template-set dir) — runnable today. The `forge upgrade` **front door**
  auto-resolving to 2.0.0 is **flip-gated** (`resolveFrameworkVersion` reads only
  `schema.yaml` = 1.0.0; 2.0.0 stays `candidate`/`scaffoldable:false` until the
  B.8.14 flip — `b8-14.test.sh` guards this).
- **No 2.0.0 snapshot tarball exists** (only `1.0.0.tar.gz`). The plan's "once the
  2.0.0 snapshot exists" framing is **stale** — B.8.15 uses `1.0.0.tar.gz` as BASE
  + the live 2.0.0 template-set as RIGHT; it must not depend on a 2.0.0 tarball.

## What ships

`.forge/scripts/tests/b8-15.test.sh` — hermetic upgrade matrix (git/python3/tar,
no cargo/flutter/docker; git-identity exported per the b8-12 CI lesson):

**L1 (runnable now):**
1. **Negative major-bump** — `forge-upgrade.sh` 1.x.y→2.0.0 (front door) ⇒ exit 7
   + literal stderr marker `[NEEDS MIGRATION: from … to …]` (the governance gate).
2. **Same-major positive** — 1.0.0→1.0.1 and 1.0.0→1.1.0 ⇒ exit 0, 3-way merge,
   `upgrade_history` appended, `archetype_version` bumped in the manifest.
3. **`--force` on a dirty git tree** ⇒ refused (exit 7).
4. **`.merge-conflicts`** — `[CONFLICT] <relpath>` format on a conflicting run +
   auto-deleted on a zero-conflict run.
5. **`upgrade_history` ledger** — entry shape (date/from/to/shas/counts/cli_version)
   + append-only (2 entries after 2 runs); whole-manifest grep (not a section).
6. **Flagship 1.0.0→2.0.0 (via migrate-flagship, on a c1-example copy)** — L1:
   `--dry-run` plan (targets 1.0.0→2.0.0, c1 copy unmutated) + a **static** no-`rm`
   additive guard. The PROJECT base is a copy of `examples/forge-fsm-example/` (the
   scaffolded 1.0.0 project — b8-12 precedent), NOT the framework `1.0.0.tar.gz`
   (which has no project files; it is migrate's internal merge BASE).

**L2 (opt-in `FORGE_B8_15_LIVE`):** the full migrate-flagship **real overlay** on
the c1-example copy → assert the `upgrade_history` entry (from=1.0.0/to=2.0.0 +
`kind: flagship-migration`), the **Kong-present** tree invariant (`fsm-kong` +
the REST routes in `infra/kong/kong.yml` still there), and the **T5.1.B fixture
matrix** (`required_paths`/`forbidden_paths` from
`cli/test/e2e/archetype-fixtures/full-stack-monorepo.yml`) on the overlaid tree
(heavier; skip-passes by default, keeping L1 ≤ a few seconds and CI-green).

**Flip-gated (skip-pass guard now; activate after `b8-14-promotion-flip`):** the
front-door `forge upgrade` auto-resolving to 2.0.0, and the Kong→Envoy **removal**
assertions on the upgraded tree. A single guard cell documents these as pending +
skip-passes, so B.8.15 is green today and completes the front-door path post-flip.

Plus `.github/workflows/forge-ci.yml` registration (`b8-15.test.sh --level 1`).

## Out of scope
- Promoting 2.0.0 / front-door auto-resolve / Kong removal (the B.8.14 flip).
- Cells for B.9 (`mobile-pwa-first`) / T7 (`event-driven-eu`, `ai-native-rag`)
  pairs — those archetypes are not shipped yet; the matrix is structured to add
  them later (the plan's full success criterion spans them).
- The v0.4.0 stable cut itself (B.8.15 is its gate, not the cut).

## Risks

| Risk | Mitigation |
|------|------------|
| Driving the front door for the positive 2.0.0 cell (flip-gated) → false RED | ADR-B815-001: positive flagship cell uses migrate-flagship; front-door auto-resolve is a skip-pass guard. |
| Depending on a non-existent 2.0.0 tarball | BASE = 1.0.0.tar.gz; RIGHT = live 2.0.0 template-set dir (asserted present). |
| Non-hermetic ledger assertions (cli_version "dev", ISO date) | Assert shape/keys, not exact values; tolerate "dev". |
| CI runner has no git identity (b8-12 lesson) | Export `GIT_AUTHOR_*`/`GIT_COMMITTER_*` at harness top. |
| Sibling-harness coupling on a shared standard | No standard touched; coupling guard re-runs a7 + b8-10 + b8-14; full suite before push. |
