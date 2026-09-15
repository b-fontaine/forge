# Tasks — `t7-qwik-deps-refresh`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — resolve, then read the report critically

- [x] **T1.1** Render the surface, `npm install`, `npm outdated`, `npm audit`.
      [Story: NFR-T7QD-002]
- [x] **T1.2** Two HIGH `sharp` advisories found (`npm audit`: 3 high); npm's own remedy is a qwik-city downgrade.
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

## Extension (reopened 2026-09-14) — sibling Qwik surfaces

- [x] **T8.1** Render `ai-native-rag` from the HEAD template; install, audit, typecheck,
      build. Record the advisories. Lockfile-resolve the flagship 2.0.0 manifest too.
      [Story: FR-T7QD-007, NFR-T7QD-002]
- [x] **T8.2** RED: `b8-9::T-014` (discovery, parsed JSON, standard read inside
      `versions:`). Run it; it MUST fail on the standard and on both siblings, and pass
      nothing vacuously.
      [Story: FR-T7QD-010]
- [x] **T8.3** GREEN: `web-frontend.yaml` 1.3.0 (`versions.sharp`, cadence,
      `last_reviewed`) + `REVIEW.md` row; `overrides.sharp` and `vite =7.3.6` on both
      sibling templates, their `_audit` notes and README pin tables.
      [Story: FR-T7QD-007, FR-T7QD-008, FR-T7QD-009]
- [x] **T8.4** Re-render from the updated template: `npm audit --audit-level=high` exits
      0; tsc, build and `qwik --help` unchanged. Re-resolve the flagship manifest.
      [Story: FR-T7QD-007, FR-T7QD-008]
- [x] **T8.5** Mutation-probe T-014 (six probes planned in design.md; nine run, P-11),
      template and standard restored byte-identical each time.
      [Story: NFR-T7QD-003, FR-T7QD-010]
- [x] **T8.6** Records: CHANGELOG Security entry (every surface + manual workaround),
      roadmap verification-gap row, plan §0.15 row.
      [Story: FR-T7QD-011]
- [x] **T8.7** Regression: `b8-9`, `b9-2`, `b7-2`, `b7-6`, `k4`; full CI array on the
      committed tree; `verify.sh` + `constitution-linter.sh`; `forge-ci.yml` line count
      unchanged.
      [Story: NFR-T7QD-003, NFR-T7QD-004]

## Review round 1 (2026-09-15) — independent lanes: CHANGES REQUIRED, 11 findings confirmed

- [x] **T9.1** RED first: five new mutation probes that T-014 let through — qwik in
      `devDependencies` with the override dropped, a `qwik-city`-only surface, a README vite
      row reverted, a README sharp row deleted, a README sharp row below the floor. All
      five GREEN against the round-0 guard.
      [Story: FR-T7QD-010, NFR-T7QD-003]
- [x] **T9.2** GREEN: widen discovery and the surface test; add the README pin-row check
      and its floor. 14/14 probes RED, restored byte-identical; `b8-9` 14/14.
      [Story: FR-T7QD-008, FR-T7QD-010]
- [x] **T9.3** Records corrected: two advisories (npm counts 3 high), four minors back,
      examples still affected (Q-004), the flagship web surface not rendered in 0.5.1, the
      real `forge upgrade` mechanism (Q-007), the CHANGELOG build claim qualified with a
      *Known issues* entry, the CI-audit remedy scoped to what each workflow sees, the
      `harness-rust` skip-pass (Q-005), the REVIEW.md ledger fields.
      [Story: FR-T7QD-011]

## Review round 2 (2026-09-15) — closure + new-claims lanes: 5 findings confirmed, 1 refuted

- [x] **T10.1** RED first: three probes the round-1 README check let through — both pin
      rows of one table deleted, a de-backticked stale vite row with the sharp row
      deleted, a stale Pin cell whose Provenance quotes the current pin. All GREEN.
      [Story: FR-T7QD-008, FR-T7QD-010]
- [x] **T10.2** GREEN: README pin tables parsed as cells, found by header, Pin cell only
      compared. **17/17** probes RED, restored byte-identical; `b8-9` 14/14.
      [Story: FR-T7QD-008, FR-T7QD-010, NFR-T7QD-003]
- [x] **T10.3** Records: Q-001 (`npm install`; a `web-pwa-ci.yml` audit sees one surface),
      the `t5-qwik` CHANGELOG sentence (flagship web surface not renderable from 0.5.1;
      correction dated 2026-09-15), plan §0.16's T-014 bullet (17/17, README cells), a
      Q-007 cross-reference where the `t7-flutter-deps-refresh` claim is still stated, and
      the roadmap B.7 row's `harness-rust` claim pointed at Q-005.
      [Story: FR-T7QD-011]

## Negative scope guard

- [x] **T7.1** `web-frontend.yaml` untouched; `vite`, `@builder.io/qwik*`,
      `oauth4webapi` and `ignore` unchanged; no `npm audit fix --force`.
      [Story: FR-T7QD-003, NFR-T7QD-001]
      *(First pass only. The 2026-09-14 extension deliberately edits
      `web-frontend.yaml` — ADR-T7QD-003.)*
- [x] **T7.2** Extension: no `@builder.io/qwik*`, `typescript`, `@types/node`,
      `vite-tsconfig-paths` or `ignore` change on the siblings; `examples/` untouched;
      no snapshot tarball regenerated; no `npm audit fix --force`.
      [Story: FR-T7QD-003, NFR-T7QD-001]
