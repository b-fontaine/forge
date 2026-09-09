# Tasks — `b9-7-web-ci`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — RED

- [x] **T1.1** Write `.forge/scripts/tests/b9-7.test.sh` — 12 L1 tests covering
      FR-B9-7-001..008, with a MANIFEST header and `--level` parsing matching the
      sibling harnesses.
      [Story: FR-B9-7-009]
- [x] **T1.2** Run it. **Confirm RED**, and confirm it reds because the template
      is absent — not because the harness itself is broken. A harness that errors
      out looks exactly like a harness reporting a real failure.
      [Story: FR-B9-7-009]

## T2 — GREEN

- [x] **T2.1** Write `2.0.0/.github/workflows/web-pwa-ci.yml.tmpl`: paths-filter,
      `node-version-file`, gate ordering, artifact upload, summary.
      [Story: FR-B9-7-002, FR-B9-7-003, FR-B9-7-004, FR-B9-7-005, FR-B9-7-006]
- [x] **T2.2** Header states what is absent and why: no format step, no test
      step, no deploy, `npm install` not `npm ci`, and that this surface adds a
      second required check.
      [Story: NFR-B9-7-004]
- [x] **T2.3** Add the `scaffold-plan.yaml` entry in source-path order.
      [Story: FR-B9-7-001]
- [x] **T2.4** Run `b9-7.test.sh --level 1`. **Confirm GREEN 12/12.**
      [Story: FR-B9-7-009]

## T3 — prove the tests are not vacuous

- [x] **T3.1** Mutation-probe each content assertion: break the pin, remove the
      paths-filter, swap two steps out of order, insert `continue-on-error: true`,
      add a deploy secret reference, drop the plan entry. Each MUST red, and red
      *for its own reason*.
      [Story: FR-B9-7-009]
- [x] **T3.2** Probe the ordering test specifically by reordering rather than
      removing — presence and order are different claims and a presence-only
      test passes a reordered file.
      [Story: FR-B9-7-004]

## T4 — prove it renders

- [x] **T4.1** Render via the wrapper under `FORGE_MPF_FORCE_SCAFFOLD=1`; assert
      `.github/workflows/web-pwa-ci.yml` exists in the output and that its
      `<project-name>` placeholders were substituted.
      [Story: FR-B9-7-001]
- [x] **T4.2** Confirm the rendered file is valid YAML.
      [Story: FR-B9-7-001]

## T5 — the byte-equivalence gate

- [x] **T5.1** Add `--exclude=web-pwa-ci.yml` to `b9-2.test.sh::T-007` with the
      basename-at-any-depth warning.
      [Story: FR-B9-7-008]
- [x] **T5.2** Run `b9-2.test.sh --level 1`. Confirm GREEN, and confirm T-007
      still reds if a Flutter file is perturbed — the exclusion must not have
      disabled the gate.
      [Story: FR-B9-7-008, NFR-B9-7-001]

## T6 — CI registration + regression

- [x] **T6.1** Register `b9-7.test.sh --level 1` in `forge-ci.yml`; confirm the
      file is ≤ 420 lines afterwards.
      [Story: FR-B9-7-009, NFR-B9-7-002]
- [x] **T6.2** `CHANGELOG.md` `[Unreleased]` entry.
      [Story: FR-B9-7-010]
- [x] **T6.3** Update `docs/new-archetypes-plan.md` §0.14 + §5.2 and
      `.forge/product/roadmap.md`: B.9 3/11 → 4/11, and record that B.9.7 shipped
      without the deploy job by decision.
      [Story: FR-B9-7-010]
- [x] **T6.4** Full local sweep of the CI-registered harnesses + shellcheck.
      [Story: NFR-B9-7-002]
- [x] **T6.5** `verify.sh` + `constitution-linter.sh` **after** flipping
      `.forge.yaml` to `implemented` — the Article V rule only applies from
      `planned` onward, and running the gates before the flip is what turned CI
      red on the previous change.
      [Story: NFR-B9-7-002]

## Negative scope guard

- [x] **T7.1** `git diff --stat` shows no change under `lib/`, `ios/`,
      `android/`, `test/`, `mobile-ci.yml.tmpl`, `overlay.sh`, `.forge/schemas/`,
      or `cli/src/`.
      [Story: NFR-B9-7-001]
