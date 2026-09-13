# Tasks — `t7-qwik-deps-refresh`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — resolve, then read the report critically

- [x] **T1.1** Render the surface, `npm install`, `npm outdated`, `npm audit`.
      [Story: NFR-T7QD-002]
- [x] **T1.2** Three HIGH advisories found; npm's own remedy is a qwik-city downgrade.
      [Story: FR-T7QD-001, NFR-T7QD-001]
- [x] **T1.3** Check each `outdated` row against the installed packages: qwik peers
      exclude vite 8, `.nvmrc` pins node 24, `ignore` still undeclared upstream.
      Three of four suggestions rejected.
      [Story: FR-T7QD-003, FR-T7QD-004]

## T2 — probe

- [x] **T2.1** On a throwaway: the three bumps + `overrides.sharp`. `npm audit` →
      **0 vulnerabilities**; `tsc --noEmit` rc=0 under TypeScript 7.0.2; `qwik build`
      succeeds.
      [Story: FR-T7QD-001, FR-T7QD-002]

## T3 — apply

- [x] **T3.1** `web-pwa/package.json.tmpl`: three pins, the override, and the audit
      notes that land in every project.
      [Story: FR-T7QD-001, FR-T7QD-002]
- [x] **T3.2** `b9-2::T-037` — four constraints on parsed JSON, plus an anti-vacuity
      floor.
      [Story: FR-T7QD-005]

## T4 — prove it

- [x] **T4.1** Render from the **updated template** and repeat install / audit /
      typecheck / build. 0 vulnerabilities, tsc rc=0, build OK.
      [Story: FR-T7QD-001, FR-T7QD-002]
- [x] **T4.2** Mutation-probe T-037: remove the override, sink it below the CVE floor,
      loosen vite, bump vite past the peers, drift `@types/node`, drop `ignore`.
      **6/6 RED.**
      [Story: NFR-T7QD-003]

## T5 — records

- [x] **T5.1** `CHANGELOG.md` `[Unreleased]`.
      [Story: FR-T7QD-006]

## T6 — regression

- [x] **T6.1** Full 81-entry CI matrix; `cli/assets/` re-bundled after the template
      edit.
      [Story: NFR-T7QD-003]
- [x] **T6.2** `verify.sh` + `constitution-linter.sh`, shellcheck.
      [Story: NFR-T7QD-003]

## Negative scope guard

- [x] **T7.1** `web-frontend.yaml` untouched; `vite`, `@builder.io/qwik*`,
      `oauth4webapi` and `ignore` unchanged; no `npm audit fix --force`.
      [Story: FR-T7QD-003, NFR-T7QD-001]
