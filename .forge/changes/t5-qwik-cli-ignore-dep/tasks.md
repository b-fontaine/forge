# Tasks — `t5-qwik-cli-ignore-dep`

Constitution Article I: RED before GREEN, verified by execution at each step.
Article V audit trail: every task carries its `[Story: FR-XXX]` tag.

## T1 — RED

- [x] **T1.1** Add `_test_b89_l1_013_qwik_cli_ignore_dep` to `b8-9.test.sh`
      (discovery sweep + non-empty guard + standard agreement). FR-T5QCI-005.
      [Story: FR-T5QCI-005]
- [x] **T1.2** Register it in `main()`; update the header MANIFEST block
      (12 → 13 L1) and the trailing count comment.
      [Story: FR-T5QCI-005]
- [x] **T1.3** Run `b8-9.test.sh --level 1`. **Confirm RED**, and confirm the
      failure names the three missing surfaces — not a generic failure that
      would also fire for an unrelated reason.
      [Story: FR-T5QCI-005]

## T2 — the pin (standard first, templates after)

- [x] **T2.1** Verify-then-pin LIVE: `npm view ignore version` +
      confirm license and zero transitive deps. Record in `evidence.md`.
      No pin written before this runs (Article III.4).
      [Story: FR-T5QCI-002, NFR-T5QCI-001]
- [x] **T2.2** `web-frontend.yaml`: add `ignore` to `versions:` with the
      workaround rationale; bump `version: 1.1.0` → `1.2.0`; move
      `last_reviewed` to 2026-09-09. FR-T5QCI-002 / FR-T5QCI-004.
      [Story: FR-T5QCI-002, FR-T5QCI-004]
- [x] **T2.3** `.forge/standards/REVIEW.md`: append-only row, 2026-09-09.
      [Story: FR-T5QCI-004]

## T3 — GREEN

- [x] **T3.1** `full-stack-monorepo/2.0.0/frontend/web-public/package.json.tmpl`
      — declaration + `_audit` note. FR-T5QCI-001 / FR-T5QCI-003.
      [Story: FR-T5QCI-001, FR-T5QCI-003]
- [x] **T3.2** `ai-native-rag/1.0.0/frontend/web-public/package.json.tmpl` — idem.
      [Story: FR-T5QCI-001, FR-T5QCI-003]
- [x] **T3.3** `mobile-pwa-first/2.0.0/web-pwa/package.json.tmpl` — idem.
      [Story: FR-T5QCI-001, FR-T5QCI-003]
- [x] **T3.4** Run `b8-9.test.sh --level 1`. **Confirm GREEN 13/13.**
      [Story: FR-T5QCI-001]

## T4 — prove the tests are not vacuous

- [x] **T4.1** Mutation probe: delete the `ignore` line from one template,
      re-run, **confirm RED**, restore, confirm GREEN. A test authored against
      already-passing files proves nothing until it has been made to fail.
      [Story: FR-T5QCI-005]
- [x] **T4.2** Mutation probe the non-empty guard: point the discovery at an
      empty directory, confirm FAIL rather than pass.
      [Story: FR-T5QCI-005]

## T5 — prove the build actually works (NFR-T5QCI-004)

- [x] **T5.1** Render `mobile-pwa-first` via the wrapper under
      `FORGE_MPF_FORCE_SCAFFOLD=1`; `npm install`; `npm run build`; record
      **exit 0** and the emitted `dist/` in `evidence.md`.
      [Story: NFR-T5QCI-004]
- [x] **T5.2** Same for the flagship surface's exact dependency set. The
      flagship is the shipped one; asserting it by analogy with
      `mobile-pwa-first` is exactly the "prose absolute" this repo has been
      bitten by. Execute it.
      [Story: NFR-T5QCI-004]
- [x] **T5.3** Check the fix at the scope the defect actually had — the whole
      CLI, not `build`. **Result, stated as measured:** the CLI now *loads*
      (`npx qwik help` prints the help banner; no `MODULE_NOT_FOUND`), which is
      the defect under test. It still **exits 1**, because this qwik CLI exits
      non-zero on help and treats `--help` as an unrecognised *command* (`qwik
      help` is the valid form). That exit code is upstream convention, unrelated
      to the missing dependency, and is NOT claimed as fixed here. The task as
      first written ("returns 0") asserted the wrong thing; corrected rather than
      ticked.
      [Story: NFR-T5QCI-004]

## T6 — regression + docs

- [x] **T6.1** `b8-9.test.sh --level 1` full; the sibling coupling test T-011
      must stay GREEN.
      [Story: NFR-T5QCI-002]
- [x] **T6.2** `verify.sh` — no net change in FAIL count.
      [Story: NFR-T5QCI-003]
- [x] **T6.3** `constitution-linter.sh` — OVERALL PASS preserved.
      [Story: NFR-T5QCI-003]
- [x] **T6.4** `CHANGELOG.md` `[Unreleased]` entry. FR-T5QCI-006.
      [Story: FR-T5QCI-006]
- [x] **T6.5** Strike the "dette héritée" line in
      `docs/new-archetypes-plan.md` §0.14 — it says `npm run build` is broken in
      *the rendered scaffold*, which understates it on both axes (all commands,
      three archetypes).
      [Story: FR-T5QCI-006]

## Negative scope guard

- [x] **T7.1** `git diff --stat` shows no change under `cli/src/`,
      `.forge/schemas/`, `overlay.sh`, or any `.forge/changes/` archive.
      [Story: FR-T5QCI-001]
