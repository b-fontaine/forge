# Tasks — `t6-fsm-2-0-0-wiring`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — RED

- [x] **T1.1** Three guards in `b8-14-flip.test.sh` (it owns `scaffold-plan-2.0.0.yaml`
      and is CI-registered): tree/plan agreement for the two wired subtrees, compose
      content, `.env` variables.
      [Story: FR-T6W-006, FR-T6W-002, FR-T6W-004]
- [x] **T1.2** Run against the unwired tree. **RED**, naming all 7 absent plan
      entries, `postgres:16-alpine`, and each missing `ZITADEL_*`.
      [Story: FR-T6W-001]

## T2 — GREEN

- [x] **T2.1** `scaffold-plan-2.0.0.yaml` +7 entries, generated from `git ls-files`.
      [Story: FR-T6W-001]
- [x] **T2.2** Splice the B.8.5 fragment into `fsm-db`: pgvector image + init-SQL mount.
      [Story: FR-T6W-002]
- [x] **T2.3** Splice the B.8.7 fragment: `fsm-zitadel` with its healthcheck dependency.
      [Story: FR-T6W-003]
- [x] **T2.4** `.env.example`: the three `ZITADEL_*` variables, with a note that two
      have no default.
      [Story: FR-T6W-004]
- [x] **T2.5** Re-run the guards. **GREEN 12/12.**
      [Story: FR-T6W-001]

## T3 — prove the guards are not vacuous

- [x] **T3.1** Revert the image → RED "still pins postgres:16-alpine".
      [Story: FR-T6W-002]
- [x] **T3.2** Delete the `fsm-zitadel` service → RED "no fsm-zitadel service".
      [Story: FR-T6W-003]
- [x] **T3.3** The negative assertion first fired on its own explanatory comment
      (b9-2 T-013 trap); comment-stripped. The stripping was first written as a
      pipe — the `pipefail` shape swept out yesterday — and rewritten as a process
      substitution.
      [Story: FR-T6W-002]

## T4 — prove it renders

- [x] **T4.1** `forge init --archetype full-stack-monorepo` through the real CLI.
      First attempt showed none of the changes: the CLI renders from `cli/assets/`,
      a bundled mirror. `npm run bundle`, then re-render.
      [Story: FR-T6W-001]
- [x] **T4.2** Verified on the rendered project: the 7 files present,
      `fsm-db: pgvector/pgvector:0.8.2-pg17`, `fsm-zitadel` present, compose parses.
      [Story: FR-T6W-002, FR-T6W-003, NFR-T6W-003]

## T5 — the dangling reference

- [x] **T5.1** `security-policy.yaml:22` cited `infra/zitadel/values-forge.yaml.tmpl`.
      The `.tmpl` suffix exists only in the framework tree, so the pointer was wrong
      from the adopter's side even once `infra/zitadel/` ships. Corrected.
      [Story: FR-T6W-005]

## T6 — records

- [x] **T6.1** `CHANGELOG.md` `[Unreleased]`, stating what still diverges.
      [Story: FR-T6W-007]
- [x] **T6.2** `docs/ARCHETYPES.md` — what fresh-init delivers vs migration.
      [Story: FR-T6W-007]

## T7 — regression

- [x] **T7.1** `b8-14-flip`, `b8-5`, `b8-2` (frozen 1.0.0), `c1`, `delivery` GREEN.
      [Story: NFR-T6W-002]
- [x] **T7.2** Full 80-entry CI matrix sweep + `cli/` vitest (templates changed →
      bundled assets change).
      [Story: NFR-T6W-002]
- [x] **T7.3** `verify.sh` + `constitution-linter.sh` after the status flip.
      [Story: NFR-T6W-002]

## Negative scope guard

- [x] **T8.1** No edit to `scaffold-plan.yaml`, the frozen 1.0.0 templates, or
      `migration-plan-2.0.0.yaml`.
      [Story: NFR-T6W-001, NFR-T6W-002]
