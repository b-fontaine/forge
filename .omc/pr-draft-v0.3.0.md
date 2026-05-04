## Summary

- **13 Forge changes archived** on `optim` since v0.2.1, closing T2 Priority-1 (facilitators), T2 Priority-2 (second
  archetype), and T3 robustness phases of the audit roadmap.
- **Constitution amended v1.0.0 → v1.1.0** via amendment #1 (new **Article XII — Governance**, ratified 2026-04-30 via
  `d5-governance`).
- **Test surface : 292/292 PASS across 13 harnesses** ; `verify.sh` 108/0 PASS / 1 WARN ; `constitution-linter.sh`
  18/0/9 OVERALL PASS (1.97s ≤ 3s budget) ; Vitest 56/56.

## Major capabilities added

- **`forge upgrade` CLI** (a7-forge-upgrade) — non-destructive 3-way merge of framework updates into adopter projects,
  with snapshot tarballs for BASE recovery and `[NEEDS MIGRATION:]` abort on major version bumps.
- **`forge init` multi-archetype dispatcher** (b5-1-init-wizard) — explicit / auto-detection / interactive wizard
  modes ; stable per-archetype ABI (`bin/forge-init-<archetype>.sh`) decouples the TS dispatcher from individual
  scaffolders.
- **Second archetype `mobile-only`** (b4-mobile-only) — Flutter iOS+Android with OIDC (`flutter_appauth`), secure token
  storage (Keychain/Keystore + StrongBox), biometric lock (`local_auth`), App Attest + Play Integrity attestation,
  Fastlane per-platform pipelines, `mobile-ci.yml` GitHub Actions workflow. **First validation of B.5.1 ABI :
  zero `cli/src/` edit required to add a new archetype.**
- **First reference project + 4 demo changes** (c1-reference-project) — `examples/forge-fsm-example/` showing the full
  pipeline end-to-end, with skip-guards in `verify.sh` / `constitution-linter.sh` so the framework's gates don't recurse
  into it.
- **GOVERNANCE.md** (d5-governance) — BDFL-with-fallback model, 7-day amendment process, release process,
  `CODE_OF_CONDUCT.md` (Contributor Covenant v2.1), `contact@benoitfontaine.fr` — and a new **Article XII — Governance**
  in the Constitution that delegates operational rules to it.
- **Open Questions tracking** (f1-open-questions) — `open-questions.md` per change, `verify.sh` Open Questions Gate,
  `constitution-linter.sh` Article III.4 rule, `bin/forge-questions.sh` aggregator. Mechanises the anti-hallucination
  protocol that was prose-only before.
- **`.forge.yaml` JSON Schema** (f2-yaml-schema) — `change.schema.json` (Draft 2020-12), `validate-change-yaml.sh`,
  `verify.sh` Change YAML Schema gate ; all 11 pre-F.2 archived changes audited and accommodated.
- **Constitution-linter coverage Articles V/X.3/XI.3/XI.5** (f4-linter-extension) — task↔FR linkage, public API doc
  ratio, GenUI schema warning, fallback test pair ; 4 new env-var opt-outs ; coverage estimated ~70 % → ~85 %.

## 13 changes (in archive order)

| #  | Change                 | Highlights                                                                           |
|----|------------------------|--------------------------------------------------------------------------------------|
| 1  | `b1-foundations`       | Constitution v1.0.0 + 11 articles + base standards                                   |
| 2  | `b1-scaffolder`        | First archetype scaffolder (`full-stack-monorepo`), schema 0.1.0 → 1.0.0-rc.1        |
| 3  | `b1-workflow`          | Multi-layer workflow (Janus orchestrator), per-layer designs/tasks                   |
| 4  | `b1-delivery`          | full-stack-monorepo schema 1.0.0 stable, snapshot tarball                            |
| 5  | `g1-forge-ci`          | `forge-ci.yml` reference workflow, branch protection                                 |
| 6  | `c1-reference-project` | `examples/forge-fsm-example/` + 4 demo changes + skip-guards                         |
| 7  | `a7-forge-upgrade`     | `forge upgrade` 3-way merge, scaffold-snapshot tarballs, `framework-owned-paths.yml` |
| 8  | `b5-1-init-wizard`     | `forge init` dispatcher, ABI contract, auto-detect, wizard, dispatch-table           |
| 9  | `d5-governance`        | `GOVERNANCE.md`, `CODE_OF_CONDUCT.md`, Article XII, Constitution → 1.1.0             |
| 10 | `b4-mobile-only`       | Second archetype Flutter mobile, 3 phases (core / runtime / Fastlane+CI)             |
| 11 | `f1-open-questions`    | `open-questions.md` per-change, gates, `forge-questions.sh`                          |
| 12 | `f2-yaml-schema`       | `change.schema.json`, `validate-change-yaml.sh`, `verify.sh` gate                    |
| 13 | `f4-linter-extension`  | Linter Articles V.1 / X.3 / XI.3 / XI.5 + opt-outs + `linting-rules.md`              |

## Constitution v1.1.0

- **New Article XII — Governance** delegates operational rules to `GOVERNANCE.md` while preserving the
  principles-vs-procedures separation. Constitution remains the supreme governing document ; `GOVERNANCE.md` is the live
  procedural reference (BDFL, amendments, releases, CoC).
- **Amendment #1** recorded in the table at the bottom of `.forge/constitution.md`.
- **`change.yaml` template + archetype `.forge.yaml.tmpl` bumped to `constitution_version: "1.1.0"`.** Existing archived
  changes keep `"1.0.0"` per ADR-006 (a change-amendment is ratified UNDER version N and CREATES N+1 — never circular).

## Quality bar

- **TDD discipline** : every change has a manifest-pattern shell harness (RED → GREEN per phase). No production code
  without a corresponding test commit. The 13 harnesses share `_helpers.sh` (`assert_eq`, `assert_contains`, `run_test`,
  `print_summary`).
- **Backward compatibility verified** at every step. NFR-YS-001 (F.2) and the F.4 framework-repo audits explicitly check
  that no pre-existing change regresses on the new gates / linter rules.
- **Heuristic limitations documented** : F.4 X.3 (multi-line decls), XI.3 (warning-only), XI.5 (name-based pair). Each
  rule has an env-var opt-out for adopter-specific contexts.
- **Performance budgets respected** : `verify.sh` < 5s, `constitution-linter.sh` 1.97s ≤ 3s, snapshot tarballs ≤
  budget (FSM 422 KB, mobile-only 465 KB).

## Release process status (per GOVERNANCE.md)

1. ✅ Archive every closing change (`/forge:archive`) — 13/13 done.
2. ✅ `CHANGELOG.md` sealed `## [0.3.0] — 2026-05-01` ; fresh `## [Unreleased]` above (`_No unreleased changes._`).
3. ⏳ Tag git `v0.3.0` on `main` after merge — to be done after this PR lands.
4. ⏳ Publish — `npm publish` from `cli/` (after `npm run bundle`) + `gh release create v0.3.0` with notes pulled from
   CHANGELOG.

## Test plan

- [ ] CI `forge-ci` workflow green : `harness` (13 harnesses), `gates` (verify.sh + constitution-linter), `cli` (Vitest
  56/56), `lint`, `example`.
- [ ] Manual smoke : on a clean checkout of `optim`, run `bash .forge/scripts/verify.sh` — expect 108 PASS / 0 FAIL / 1
  WARN.
- [ ] Manual smoke : `bash .forge/scripts/constitution-linter.sh` — expect OVERALL PASS, ~2s.
- [ ] Manual smoke : `cd cli && npm test` — expect 56/56 PASS.
- [ ] Manual smoke : `bash .forge/scripts/tests/a7.test.sh` — expect 29/29 (forge upgrade trajectory unchanged).
- [ ] Manual smoke : `bash bin/forge-questions.sh` — expect zero output (no open questions across the 13 archived
  changes).
- [ ] Visual review : `GOVERNANCE.md` + `CODE_OF_CONDUCT.md` render correctly on GitHub (Community Standards detection).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
